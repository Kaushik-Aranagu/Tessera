#!/usr/bin/env python3
"""fix-alias-hub: why the 'alias' memory-plane rule collapses on LoCoMo, and hubness fixes for it (public data only).

Setting (same as /tmp/claude-0/sm/e6_fixes.py): rank-16 bridge heads (e5_bridges.train, seed = fold) on a frozen
bge-small encoder; 5 folds, 2 held-out test chats per fold, train on the other 8. Inside a test chat the questions are
visited in 3 shuffled orders (same permutations as e6); after each question the memory plane learns from that
question's cites. Cites are the evidence turns (oracle), or with a share p of them swapped for a wrong top-10 node
(p = 0.3, 0.6), or 'self' (the system's own top-1 hit, no outside signal). Noise uses common random numbers, so every
rule sees the same coin flips. Test-chat evidence is used only (a) to score and (b) as the cites of EARLIER visits.

Part 1, diagnostic (confirms or refutes the hubness explanation):
  cosines   mean ask-to-ask cosine (same chat; pairs that share evidence vs not; across chats) against ask-to-node and
            ask-to-evidence cosine, in the bridge space; 'entry rate' = share of unrelated asks whose state would beat
            the ask's own 10th-best key (an alias made from that unrelated ask would enter the top 10); pooled AUCs.
  intrusion in each test run, 'new FP' = non-evidence nodes in the top 10 that are not in the no-learning top 10,
            and recall by position in the visit order (aliases pile up over the order).

Part 2, memory-plane rules (k = node key from the action head, s = ask state, a = a stored alias):
  lowrank              no learning; the baseline every arm is compared with (paired, same visits)
  move                 k_v <- normalise(k_v + eta (s - k_v)); 'move eta=0.1 (e6)' is the reference rule
  alias raw (e6)       keep k_v, store s as an alias of v; score = max(k.s, max_a a.s)
  F1 margin            score = max(k.s, max_a a.s - m)
  F2 csls              CSLS hub correction on both sides: score = max(2 k.s - r(k), max_a 2 a.s - r(a)); r(x) = mean of
                       x's K largest cosines with a reference set of OTHER asks = the training chats' ask states plus
                       this chat's asks visited EARLIER (never the current or later ones; an alias never counts itself)
  F2c csls keys only   control for F2: the CSLS key score with no learning (separates the hub-corrected base ranking)
  F3 bonus             additive, never replaces the key: score = k.s + beta * max(0, max_a (a.s - r(a)))
  F4 action-view       store the bridge's action-side view of the ask, a = action_head(ask encoding), instead of its
                       state; score = max(k.s, max_a a.s - m). Asks seen through the action head look like nodes.
  F5 action+bonus      F4's alias vectors with F3's additive, hub-corrected bonus
Hyperparameters: tuned only on training chats. In each fold, 2 of the 8 training chats are dev chats, an inner bridge
is trained on the other 6, every grid setting is run on the dev chats (2 orders x the 4 cite conditions), and each
family keeps the setting with the best dev recall@10 averaged over the 4 cite conditions (one setting for all
conditions, since the deployed system does not know its cite noise). 'move tuned' gets the same treatment.
Usage: python alias_hub.py --data /tmp/locomo10.json
"""
import argparse, collections, hashlib, json, os, pickle, sys, time
import numpy as np
import torch

E5 = "/tmp/claude-0/sm"
sys.path.insert(0, E5)
from e5_bridges import SHA, bm25_rank, fuse, load, tokens, train  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CATS = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
CONDS = (0.0, 0.3, 0.6, "self")


def recall(top, ev, k=10):
    return len(set(top[:k]) & set(ev)) / len(ev)


def cfg(name, rule="none", **kw):
    d = dict(name=name, rule=rule, eta=0.1, view="state", combine="max", margin=0.0, hubk=0, csls=False, beta=1.0)
    d.update(kw)
    return d


GRID = {  # fixed before any test-chat result; every setting is reported (dev table). Widened once (more margins,
          # K=3, eta=0.02) after fold 0's DEV-only tuning picked grid edges; no test result existed at that point.
    "move": [cfg(f"move eta={e}", "move", eta=e) for e in (0.02, 0.05, 0.1, 0.2, 0.3)],
    "F1 margin": [cfg(f"alias margin={m}", "alias", margin=m) for m in (0.1, 0.2, 0.3, 0.4, 0.5, 0.6)],
    "F2 csls": [cfg(f"alias csls K={k}", "alias", hubk=k, csls=True) for k in (3, 10, 50)],
    "F3 bonus": [cfg(f"alias bonus beta={b} K={k}", "alias", combine="add", hubk=k, beta=b)
                 for b in (0.5, 1.0, 2.0) for k in (3, 10, 50)],
    "F4 action-view": [cfg(f"alias action-view margin={m}", "alias", view="action", margin=m) for m in (0.0, 0.1, 0.2, 0.3)],
    "F5 action+bonus": [cfg(f"alias action-view bonus beta={b} K=10", "alias", view="action", combine="add", hubk=10, beta=b)
                        for b in (0.5, 1.0, 2.0)],
}
LOWRANK = cfg("lowrank")
MOVE_E6 = cfg("move eta=0.1 (e6)", "move", eta=0.1)
ALIAS_E6 = cfg("alias raw (e6)", "alias")


class Plane:
    """The memory plane of one chat under one rule. Aliases live in preallocated arrays; r(x) (the hub score: mean of
    x's K largest cosines with the reference asks) is kept up to date incrementally as asks join the reference."""

    def __init__(self, keys, c, ref, cap):
        self.keys, self.c = keys.copy(), c
        d = keys.shape[1]
        self.A, self.owner, self.origin, self.m = np.zeros((cap, d), np.float32), np.zeros(cap, int), np.zeros(cap, int), 0
        self.learned = set()
        self.K = c["hubk"]
        if self.K:
            self.ref = ref                                            # training-chat ask states (fixed)
            self.chat_ref = []                                        # earlier asks of this chat
            self.rk = np.partition(keys @ ref.T, -self.K, axis=1)[:, -self.K:]
            self.ra = np.zeros((cap, self.K), np.float32)

    def scores(self, s):
        base = self.keys @ s
        c = self.c
        key = 2 * base - self.rk.mean(1) if c["csls"] else base
        if c["rule"] != "alias" or self.m == 0:
            return key
        at = self.A[:self.m] @ s
        if c["csls"]:
            al = 2 * at - self.ra[:self.m].mean(1)
        elif self.K:
            al = at - self.ra[:self.m].mean(1)
        else:
            al = at
        al = al - c["margin"]
        if c["combine"] == "max":
            best = np.full(len(key), -np.inf, np.float32); np.maximum.at(best, self.owner[:self.m], al)
            return np.maximum(key, best)
        best = np.zeros(len(key), np.float32); np.maximum.at(best, self.owner[:self.m], np.maximum(al, 0))
        return key + c["beta"] * best

    def learn(self, v, s, aview, t):
        c = self.c
        self.learned.add(v)
        if c["rule"] == "move":
            k = self.keys[v] + c["eta"] * (s - self.keys[v]); self.keys[v] = k / np.linalg.norm(k)
        elif c["rule"] == "alias":
            a = aview if c["view"] == "action" else s
            self.A[self.m], self.owner[self.m], self.origin[self.m] = a, v, t
            if self.K:  # reference so far: training asks + this chat's asks before t (s itself not yet added)
                sims = self.ref @ a
                if self.chat_ref:
                    sims = np.concatenate([sims, np.array(self.chat_ref) @ a])
                self.ra[self.m] = np.partition(sims, -self.K)[-self.K:]
            self.m += 1

    def observe(self, s, t):
        """The ask of visit t joins the reference set (after it was scored and learned from)."""
        if not self.K:
            return
        self.chat_ref.append(s)
        self.rk = np.partition(np.concatenate([self.rk, (self.keys @ s)[:, None]], 1), 0, axis=1)[:, 1:]
        if self.m:
            rows = np.nonzero(self.origin[:self.m] != t)[0]           # an alias never counts its own ask
            col = self.A[rows] @ s
            self.ra[rows] = np.partition(np.concatenate([self.ra[rows], col[:, None]], 1), 0, axis=1)[:, 1:]


def run_chat(ch, keys, states, aviews, ref, c, cond, order, draws, lex=None):
    """One pass over a chat in one visit order. Returns per-visit arrays: recall, hybrid recall, new false positives."""
    cap = sum(max(len(ev), 1) for _, ev, _ in ch["qs"])
    plane = Plane(keys, c, ref, cap)
    base10 = ch["_base10"]
    rec, hyb, nfp, lfp = [], [], [], []
    for t, r in enumerate(order):
        _, ev, _ = ch["qs"][r]
        top = np.argsort(-plane.scores(states[r]), kind="stable")
        tl = top.tolist()
        rec.append(recall(tl, ev))
        hyb.append(recall(fuse(lex[r], tl), ev) if lex is not None else np.nan)
        evs = set(ev)
        new = [v for v in tl[:10] if v not in evs and v not in base10[r]]
        nfp.append(len(new)); lfp.append(sum(v in plane.learned for v in new))
        if cond == "self":
            cited = tl[:1]
        else:
            wrong = [v for v in tl[:10] if v not in evs]
            u = draws[r]
            cited = [wrong[int(u[j, 1] * len(wrong))] if (wrong and u[j, 0] < cond) else e for j, e in enumerate(ev)]
        for v in cited:
            plane.learn(int(v), states[r], aviews[r], t)
        plane.observe(states[r], t)
    return np.array(rec), np.array(hyb), np.array(nfp), np.array(lfp)


def project(b, ch):
    with torch.no_grad():
        nodes, asks = torch.tensor(ch["nodes"]), torch.tensor(ch["asks"])
        return b.a(nodes).numpy(), b.s(asks).numpy(), b.a(asks).numpy()


def prepare(ch, keys, states):
    ch["_base10"] = [set(np.argsort(-(keys @ s), kind="stable")[:10].tolist()) for s in states]


def draws_for(ch, seed):
    rng = np.random.default_rng(seed)
    return [rng.random((len(ev), 2)) for _, ev, _ in ch["qs"]]


def auc(pos, neg):
    """Mann-Whitney AUC of a score separating pos from neg."""
    x = np.concatenate([pos, neg]); rk = np.empty(len(x)); rk[np.argsort(x, kind="stable")] = np.arange(1, len(x) + 1)
    return (rk[:len(pos)].sum() - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg))


def diagnose(ch, keys, states, aviews, ref):
    """Cosine geometry of one test chat in the bridge space (uses evidence only to label pairs for measurement)."""
    n = len(states); ss, sk, sa = states @ states.T, states @ keys.T, states @ aviews.T
    ev = [set(q[1]) for q in ch["qs"]]
    share = np.array([[bool(ev[i] & ev[j]) for j in range(n)] for i in range(n)]); off = ~np.eye(n, dtype=bool)
    unrel, rel = off & ~share, off & share
    evmask = np.zeros_like(sk, dtype=bool)
    for r in range(n):
        evmask[r, list(ev[r])] = True
    tenth = np.sort(sk, 1)[:, -10][:, None].repeat(n, 1)
    fz = ch["asks"] @ ch["asks"].T; fk = ch["asks"] @ ch["nodes"].T
    return {
        "ask-ask same chat, unrelated": ss[unrel].mean(), "ask-ask same chat, sharing evidence": ss[rel].mean(),
        "ask-ask across chats": (states @ ref.T).mean(), "ask-node (all)": sk.mean(), "ask-own-evidence": sk[evmask].mean(),
        "ask's 10th-best key": tenth[:, 0].mean(),
        "entry rate unrelated (state alias)": (ss[unrel] > tenth[unrel]).mean(),
        "entry rate sharing (state alias)": (ss[rel] > tenth[rel]).mean(),
        "entry rate unrelated (action-view alias)": (sa[unrel] > tenth[unrel]).mean(),
        "entry rate sharing (action-view alias)": (sa[rel] > tenth[rel]).mean(),
        "action-view ask-ask unrelated": sa[unrel].mean(), "action-view ask-ask sharing": sa[rel].mean(),
        "AUC ask-ask (sharing vs unrelated pairs)": auc(ss[rel], ss[unrel]),
        "AUC ask-node (evidence vs not)": auc(sk[evmask], sk[~evmask]),
        "AUC ask-action-view (sharing vs unrelated)": auc(sa[rel], sa[unrel]),
        "frozen: ask-ask same chat unrelated": fz[unrel].mean(), "frozen: ask-node": fk.mean(),
        "frozen: ask-own-evidence": fk[evmask].mean(),
        "share of ask pairs that share evidence": rel.sum() / off.sum(),
    }


def boot(d, rng, n=1000):
    b = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(n)]
    return float(np.percentile(b, 2.5)), float(np.percentile(b, 97.5))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", required=True); p.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    p.add_argument("--orders", type=int, default=3); p.add_argument("--dev-orders", type=int, default=2)
    p.add_argument("--cache", default=os.path.join(HERE, "chats.pkl"), help="pickled e5_bridges.load output (speed only)")
    a = p.parse_args()
    torch.set_num_threads(1); t0 = time.time()
    sha = hashlib.sha256(open(a.data, "rb").read()).hexdigest()
    if sha != SHA:
        sys.exit("not the pinned LoCoMo file")
    if os.path.exists(a.cache) and pickle.load(open(a.cache, "rb"))["sha"] == sha:
        chats = pickle.load(open(a.cache, "rb"))["chats"]
    else:
        chats = load(a.data, a.model); pickle.dump(dict(sha=sha, chats=chats), open(a.cache, "wb"))
    dim = chats[0]["nodes"].shape[1]
    print(f"loaded {len(chats)} chats, {sum(len(c['qs']) for c in chats)} questions ({time.time() - t0:.0f}s)", flush=True)

    dev_tab = collections.defaultdict(list)          # setting name -> per-fold dev mean over the 4 conditions
    dev_cond = collections.defaultdict(list)         # (setting, cond) -> per-fold dev mean
    chosen = collections.defaultdict(list)           # family -> chosen setting per fold
    per = collections.defaultdict(list)              # test arm -> per-visit recall
    hyb, nfp, lfp = (collections.defaultdict(list) for _ in range(3))
    by_pos = collections.defaultdict(lambda: np.zeros((3, 2)))
    cat_v, qid_v = [], []
    diag = collections.defaultdict(list)

    for fold in range(5):
        test = [2 * fold, 2 * fold + 1]
        dev = [(2 * fold + 2) % 10, (2 * fold + 3) % 10]
        train_ids = [i for i in range(10) if i not in test]
        inner_ids = [i for i in train_ids if i not in dev]
        # ---- tuning on the dev chats with an inner bridge that never saw them (nor the test chats)
        bi = train([chats[i] for i in inner_ids], dim, 40, fold, rank=16)
        with torch.no_grad():
            ref_i = np.concatenate([bi.s(torch.tensor(chats[i]["asks"])).numpy() for i in inner_ids])
        score = collections.defaultdict(list)
        for i in dev:
            ch = chats[i]; keys, states, aviews = project(bi, ch); prepare(ch, keys, states)
            for o in range(a.dev_orders):
                order = np.random.default_rng(7000 + 100 * fold + 10 * i + o).permutation(len(ch["qs"]))
                draws = draws_for(ch, [fold, i, o, 7])
                for fam, settings in GRID.items():
                    for c in settings:
                        for cond in CONDS:
                            r = run_chat(ch, keys, states, aviews, ref_i, c, cond, order, draws)[0]
                            score[(c["name"], cond)].extend(r)
        for fam, settings in GRID.items():
            means = []
            for c in settings:
                m = np.mean([np.mean(score[(c["name"], cond)]) for cond in CONDS]); means.append(m)
                dev_tab[c["name"]].append(m)
                for cond in CONDS:
                    dev_cond[(c["name"], cond)].append(np.mean(score[(c["name"], cond)]))
            chosen[fam].append(settings[int(np.argmax(means))])
        print(f"fold {fold}: dev chats {dev} tuned ({time.time() - t0:.0f}s): "
              + "; ".join(f"{f} -> {chosen[f][-1]['name']}" for f in GRID), flush=True)

        # ---- test: outer bridge on the 8 training chats, the 2 held-out chats
        b = train([chats[i] for i in train_ids], dim, 40, fold, rank=16)
        with torch.no_grad():
            ref = np.concatenate([b.s(torch.tensor(chats[i]["asks"])).numpy() for i in train_ids])
        csls_k = chosen["F2 csls"][-1]["hubk"]
        arms = [("lowrank", LOWRANK, 0.0), ("F2c csls keys only", cfg("csls keys only", hubk=csls_k, csls=True), 0.0)]
        for cond in CONDS:
            arms += [(f"move eta=0.1 (e6) cites={cond}", MOVE_E6, cond), (f"alias raw (e6) cites={cond}", ALIAS_E6, cond)]
            arms += [(f"{fam} [dev-tuned] cites={cond}", chosen[fam][-1], cond) for fam in GRID]
        for i in test:
            ch = chats[i]; keys, states, aviews = project(b, ch); prepare(ch, keys, states)
            for k, v in diagnose(ch, keys, states, aviews, ref).items():
                diag[k].append(v)
            lex = [[ch["ids"].index(d) for d in bm25_rank(ch["docs"], ch["ids"], tokens(q))] for q, _, _ in ch["qs"]]
            for o in range(a.orders):
                order = np.random.default_rng(100 * fold + 10 * i + o).permutation(len(ch["qs"]))  # e6's orders
                draws = draws_for(ch, [fold, i, o])
                cat_v.extend(ch["qs"][r][2] for r in order); qid_v.extend(1000 * i + r for r in order)
                third = np.arange(len(order)) * 3 // len(order)
                for name, c, cond in arms:
                    r, h, nf, lf = run_chat(ch, keys, states, aviews, ref, c, cond, order, draws, lex)
                    per[name].extend(r); hyb[name].extend(h); nfp[name].extend(nf); lfp[name].extend(lf)
                    for k in range(3):
                        by_pos[name][k] += (r[third == k].sum(), (third == k).sum())
        print(f"fold {fold}: test chats {test} done ({time.time() - t0:.0f}s)", flush=True)

    # ---------------------------------------------------------------- report
    cat_v, qid_v = np.array(cat_v), np.array(qid_v); n = len(cat_v)
    base = np.array(per["lowrank"]); move_by = {cond: np.array(per[f"move eta=0.1 (e6) cites={cond}"]) for cond in CONDS}
    print(f"\n{n} question visits (1531 x {a.orders} orders), held-out chats, recall@10 ({time.time() - t0:.0f}s)")
    print("\nDIAGNOSTIC: cosine geometry in the rank-16 bridge space (mean over the 10 test chats, each with its fold's bridge)")
    for k, v in diag.items():
        print(f"  {k:<48} {np.mean(v):.3f}")
    print("\nDEV GRID (training chats only; mean over folds; columns: mean of 4 conditions | 0.0 0.3 0.6 self)")
    for fam, settings in GRID.items():
        for c in settings:
            print(f"  {fam:<16} {c['name']:<38} {np.mean(dev_tab[c['name']]):.3f} | "
                  + " ".join(f"{np.mean(dev_cond[(c['name'], cond)]):.3f}" for cond in CONDS))
        print(f"  {'':<16} chosen per fold: {[c['name'] for c in chosen[fam]]}")
    print("\nTEST ARMS (paired vs lowrank, same visits; CI = e6-style visit bootstrap, then question-cluster bootstrap)")
    rng = np.random.default_rng(0); results = []
    uq, inv = np.unique(qid_v, return_inverse=True)
    for name in per:
        x = np.array(per[name]); d = x - base
        ci = boot(d, rng)
        dq = np.bincount(inv, weights=d) / np.bincount(inv)
        ciq = boot(dq, rng)
        cond = next((cnd for cnd in CONDS if name.endswith(f"cites={cnd}")), None)
        vs_move = ""
        if cond is not None and not name.startswith("move eta=0.1"):
            dm = x - move_by[cond]; cm = boot(dm, rng)
            vs_move = f" vs move {dm.mean():+.3f} [{cm[0]:+.3f},{cm[1]:+.3f}]"
        mh = x[cat_v == 1].mean()
        pos = by_pos[name][:, 0] / by_pos[name][:, 1]
        line = (f"  {name:<40} {x.mean():.3f} [mh {mh:.3f}] +bm25 {np.nanmean(hyb[name]):.3f}  vs lowrank {d.mean():+.3f} "
                f"[{ci[0]:+.3f},{ci[1]:+.3f}] qclust [{ciq[0]:+.3f},{ciq[1]:+.3f}]{vs_move}  newFP/ask {np.mean(nfp[name]):.2f} "
                f"(on learned nodes {np.mean(lfp[name]):.2f})  by position {pos[0]:.3f}/{pos[1]:.3f}/{pos[2]:.3f}  "
                + " ".join(f"{CATS[k]} {x[cat_v == k].mean():.3f}" for k in CATS))
        print(line)
        results.append(dict(name=name, recall10=float(x.mean()), multihop10=float(mh), hybrid=float(np.nanmean(hyb[name])),
                            delta=float(d.mean()), ci=ci, ci_question=ciq, newfp=float(np.mean(nfp[name])),
                            newfp_learned=float(np.mean(lfp[name])), by_position=pos.tolist(), vs_move=vs_move))
    json.dump(dict(results=results, diag={k: float(np.mean(v)) for k, v in diag.items()},
                   dev={k: float(np.mean(v)) for k, v in dev_tab.items()},
                   chosen={f: [c["name"] for c in cs] for f, cs in chosen.items()}),
              open(os.path.join(HERE, "results.json"), "w"), indent=1)
    # ---- VERIFY additions: save per-visit arrays; paired CIs vs dev-tuned move; per-chat deltas; chat-cluster CI
    np.savez(os.path.join(HERE, "per_visit.npz"), cat=cat_v, qid=qid_v,
             **{f"r::{k}": np.array(v) for k, v in per.items()}, **{f"h::{k}": np.array(v) for k, v in hyb.items()})
    chat_v = qid_v // 1000
    rng2 = np.random.default_rng(1)
    print("\nVERIFY: paired vs DEV-TUNED move (same visits, same cite draws)")
    for cond in CONDS:
        mt = np.array(per[f"move [dev-tuned] cites={cond}"])
        for fam in ("F1 margin", "F3 bonus", "F4 action-view", "F5 action+bonus"):
            x = np.array(per[f"{fam} [dev-tuned] cites={cond}"]); dd = x - mt
            ci = boot(dd, rng2)
            print(f"  cites={cond!s:<5} {fam:<16} {x.mean():.3f} vs move-tuned {mt.mean():.3f}: {dd.mean():+.4f} [{ci[0]:+.4f},{ci[1]:+.4f}]")
    print("\nVERIFY: per-chat deltas vs lowrank (mean over that chat's visits) and chat-cluster bootstrap")
    for name in [n for n in per if n != "lowrank"]:
        x = np.array(per[name]); d = x - base
        pc = np.array([d[chat_v == ci_].mean() for ci_ in range(10)])
        bs = [pc[rng2.integers(0, 10, 10)].mean() for _ in range(2000)]
        print(f"  {name:<40} chats>0: {(pc > 0).sum():2d}/10  mean-of-chats {pc.mean():+.4f} chatCI [{np.percentile(bs, 2.5):+.4f},{np.percentile(bs, 97.5):+.4f}]"
              f"  per-chat: " + " ".join(f"{v:+.3f}" for v in pc))


if __name__ == "__main__":
    main()
