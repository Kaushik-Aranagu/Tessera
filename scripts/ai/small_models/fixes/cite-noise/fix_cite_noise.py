#!/usr/bin/env python3
"""Fix cite noise: can use-driven key learning keep its gain with clean cites without hurting under wrong cites
or a self-loop? LoCoMo only (public data; 10 chats, 1531 questions after dropping category 5).

Setup, reused from e6_fixes.py: rank-16 bridge heads (e5_bridges.train(..., rank=16), 40 epochs, seed = fold) on a
frozen bge-small encoder. 5 folds, 2 held-out test chats per fold, bridges trained on the other 8. In a test chat the
questions are visited in 3 shuffled orders (same permutations as e6_fixes.py); after each question the memory plane
learns from that question's cites. Only earlier questions' cites ever affect a later question.

Cite conditions (what the memory plane is told was cited):
  clean     the question's marked evidence turns (oracle cites, as in E6)
  wrong30   each evidence cite is swapped, with p=0.3, for a random non-evidence node of the current top-10 (E6)
  wrong60   the same with p=0.6
  self      no outside signal: the current top-1 is treated as cited (E6)
  audit conditions, reported but NOT used for tuning:
  far30/60  like wrong30/60 but the wrong node is drawn from the top-50 (so most wrong cites sit at ranks 11-50);
            this checks whether a fix only works because E6 draws wrong cites from the top-10
  visible   clean cites restricted to evidence the reasoning plane actually opened (in the top-10)
The random numbers behind every swap and every verifier decision are drawn once per (chat, order, question) and
shared by all arms (common random numbers), so arms are compared on identical noise.

Arms (memory-plane learning rules; all start from the same rank-16 keys):
  baseline         no learning (the 0.657 low-rank number)
  move             E6's rule, eta 0.1 fixed: k_v <- unit(k_v + eta (s - k_v)) for each cited v
  move-tuned       the same rule with eta tuned on dev chats (control: is a smaller step alone a fix?)
  contrastive      (1) pull cited nodes as in move, and push the opened-but-not-cited top-10 away:
                   k_u <- unit(k_u - eta_neg s)
  agree-bm25       (2) learn from a cite only if BM25 (an independent lexical signal) also ranks it in its top-k
  surprise         (3) step scaled by how surprising the cite is: w = 1 - p(v|ask) under the bridge softmax,
                   or w = min(1, rank_v / g) (rank 0 = current top-1 gets no step)
  centered         (own idea, de-hubbing) asks are very similar to each other (|mean ask| ~ 0.75), so pulling a key
                   toward an ask also pulls it toward every other ask and makes it a hub. Pull toward the ask's
                   specific part only: d = unit(s - c mu), k_v <- unit(k_v + eta (d - k_v)), where mu is the running
                   mean of this chat's ask states seen so far (questions only, never evidence) blended with
                   10 pseudo-asks at the training chats' mean
  slow-adapter     (4) no fast key moves: log (ask, cited node) pairs and every 10 asks refit a per-chat linear
                   residual on the state head in closed form (ridge regression of k_v - s on s, lambda pulls the
                   residual back to zero = back to the trained head); query = unit(s + alpha s A)
  verifier+move    (5) a simulated answer check before learning: a wrong cite is caught (dropped) with p=0.7, a
                   correct cite is wrongly dropped with p=0.1; then E6's move with eta 0.1
  combo            centered pull + BM25 agreement + optional centered push of opened-but-not-cited nodes
                   (combination fixed before any test result was seen)
  verifier+combo   the combo behind the simulated verifier

Hyperparameters: tuned only on training chats. In fold f the dev chats are the test pair of fold f+1 (mod 5), which
are training chats for fold f; a dev bridge is trained on the remaining 6 chats, every grid setting is run on the dev
chats (3 orders, 4 main conditions), and the setting with the highest J = mean(delta) + min(delta) over the 4 main
conditions (delta vs no learning on the same dev visits) is used for fold f's test chats. Arms with one setting are
not tuned. The audit conditions play no part in tuning.

Statistics: recall@10 of marked evidence turns (dense ranking; +BM25 RRF hybrid shown too), multi-hop = category 1.
Paired bootstrap 95% CI vs the baseline over visits (as e6_fixes.py), and a stricter one that resamples questions
(the 3 orders of a question are not independent).
Usage: python3 fix_cite_noise.py --data /tmp/locomo10.json [--cache chats.pkl] [--orders 3] [--folds 5]
"""
import argparse, collections, hashlib, itertools, json, os, pickle, sys, time
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))  # /tmp/claude-0/sm: e5_bridges.py and e6_fixes.py
from e5_bridges import SHA, bm25_rank, load, tokens, train  # noqa: E402
from e6_fixes import recall  # noqa: E402

MAIN = ("clean", "wrong30", "wrong60", "self")
AUDIT = ("far30", "far60", "visible")
NOISE = {"clean": (0.0, 10), "wrong30": (0.3, 10), "wrong60": (0.6, 10), "far30": (0.3, 50), "far60": (0.6, 50)}
OPENED = 10                          # the reasoning plane reads the top-10
CATCH, FALSE_DROP = 0.7, 0.1         # simulated verifier
REFIT_EVERY = 10                     # slow path refit period (asks)
MU_PRIOR_N = 10                      # pseudo-asks at the training mean in the running ask mean


def grid(**axes):
    names = list(axes)
    return [dict(zip(names, vals)) for vals in itertools.product(*(axes[n] for n in names))]


ARMS = [
    ("move", [dict(eta=0.1)]),
    ("move-tuned", grid(eta=[0.02, 0.05, 0.1, 0.2])),
    ("contrastive", grid(eta=[0.05, 0.1, 0.2], eta_neg=[0.01, 0.03, 0.1])),
    ("agree-bm25", grid(eta=[0.1, 0.2, 0.3], agree=[5, 10, 20, 50])),
    ("surprise", grid(eta=[0.1, 0.2, 0.3], weight=["prob", 1, 5, 10, 20])),
    ("centered", grid(eta=[0.05, 0.1, 0.2, 0.3], c=[0.5, 1.0])),
    ("slow-adapter", grid(kind=["adapter"], lam=[0.3, 1.0, 3.0, 10.0], alpha=[0.5, 1.0])),
    ("verifier+move", [dict(eta=0.1, verifier=True)]),
    ("combo", grid(eta=[0.1, 0.2, 0.3], agree=[10, 20, 50, None], eta_neg=[0.0, 0.02], c=[1.0])),
    ("verifier+combo", grid(eta=[0.1, 0.2, 0.3], agree=[10, 20, 50, None], eta_neg=[0.0, 0.02], c=[1.0],
                            verifier=[True])),
]
DEFAULT = dict(kind="key", eta=0.1, c=0.0, eta_neg=0.0, agree=None, weight=None, verifier=False, lam=1.0, alpha=1.0)


class Plane:
    """The memory plane of one test chat: keys (action-head vectors of its turns) plus a learning rule."""

    def __init__(self, keys, cfg, mu0, scale):
        self.cfg = {**DEFAULT, **cfg}; self.base = keys; self.keys = keys.copy(); self.scale = scale
        self.mu_sum = MU_PRIOR_N * mu0.astype(np.float64); self.mu_n = MU_PRIOR_N
        self.seen = 0; self.learned = [0, 0]  # [correct, wrong] cites that changed the plane
        self.log_s, self.log_r, self.fit = [], [], None  # slow path: logged (ask, k_v - ask) pairs and last fit

    def query(self, s):
        """Every ask is seen (its text is known); the running ask mean uses only asks, never evidence."""
        self.mu_sum += s; self.mu_n += 1; self.seen += 1
        if self.fit is not None:  # q = s + alpha s A with A = (S'S + lam I)^-1 S'R, computed in its dual form
            S, B = self.fit; q = s + self.cfg["alpha"] * ((S @ s) @ B)
            return (q / np.linalg.norm(q)).astype(np.float32)
        return s

    def learn(self, s, sc, top, lexpos, reported, accepted):
        """reported: nodes the reasoning plane said it cited; accepted: (node, is_correct) that passed the verifier."""
        cfg = self.cfg
        acc = [(v, ok) for v, ok in accepted if cfg["agree"] is None or lexpos[v] < cfg["agree"]]
        if cfg["kind"] == "adapter":
            for v, ok in acc:
                self.log_s.append(s.astype(np.float64)); self.log_r.append(self.base[v] - s)
                self.learned[0 if ok else 1] += 1
            if self.seen % REFIT_EVERY == 0 and self.log_s:  # periodic refit, ridge pulls the residual to zero
                S = np.array(self.log_s); R = np.array(self.log_r, dtype=np.float64)
                self.fit = (S, np.linalg.solve(S @ S.T + cfg["lam"] * np.eye(len(S)), R))
            return
        if not acc:
            return
        if cfg["c"]:
            d = s - cfg["c"] * self.mu_sum / self.mu_n; d = (d / np.linalg.norm(d)).astype(np.float32)
        else:
            d = s
        if cfg["weight"] == "prob":
            z = np.exp(self.scale * (sc - sc.max())); p = z / z.sum()
        elif cfg["weight"]:
            pos = np.empty(len(top), dtype=np.int64); pos[top] = np.arange(len(top))
        for v, ok in acc:
            w = 1.0
            if cfg["weight"] == "prob":
                w = 1.0 - float(p[v])
            elif cfg["weight"]:
                w = min(1.0, pos[v] / cfg["weight"])
            if w <= 0:
                continue
            k = self.keys[v] + cfg["eta"] * w * (d - self.keys[v]); k /= np.linalg.norm(k)
            self.keys[v] = k; self.learned[0 if ok else 1] += 1
        if cfg["eta_neg"]:
            rep = set(reported)
            for u in top[:OPENED]:
                if int(u) not in rep:
                    k = self.keys[u] - cfg["eta_neg"] * d; self.keys[u] = k / np.linalg.norm(k)


def make_cites(cond, ev, evset, top, u):
    """What the reasoning plane reports as cited, with a correctness flag per cite (for the verifier and counts)."""
    if cond == "self":
        v = int(top[0]); return [v], [v in evset]
    if cond == "visible":
        opened = set(top[:OPENED].tolist()); rep = [v for v in ev if v in opened]; return rep, [True] * len(rep)
    p, pool = NOISE[cond]
    wrong = [int(v) for v in top[:pool] if int(v) not in evset] if p else []
    rep, ok = [], []
    for j, v in enumerate(ev):
        if wrong and u[0, j] < p:
            rep.append(wrong[int(u[1, j] * len(wrong))]); ok.append(False)
        else:
            rep.append(v); ok.append(True)
    return rep, ok


def run_chat(ch, keys, states, cfg, cond, order, stream, mu0, scale, hybrid):
    """One pass over a chat in a given order. Returns per-visit dense recall, hybrid recall, learned counts."""
    plane = Plane(keys, cfg or {}, mu0, scale) if cfg is not None else None
    n = len(keys); ar = np.arange(n); x = np.zeros(len(order)); h = np.zeros(len(order))
    for t, r in enumerate(order):
        _, ev, _ = ch["qs"][r]
        s = states[r]
        q = plane.query(s) if plane else s
        sc = plane.keys @ q if plane else keys @ q
        top = np.argsort(-sc, kind="stable")
        x[t] = recall(top, ev)
        if hybrid:  # reciprocal rank fusion with BM25 (k=60), same ties as e5_bridges.fuse
            pos = np.empty(n, dtype=np.int64); pos[top] = ar
            f = 1.0 / (61 + ch["lexpos"][r]) + 1.0 / (61 + pos)
            h[t] = recall(np.lexsort((ar, -f)), ev)
        if plane is None:
            continue
        u = stream[r]
        rep, ok = make_cites(cond, ev, ch["evset"][r], top, u)
        if plane.cfg["verifier"]:
            acc = [(v, k) for j, (v, k) in enumerate(zip(rep, ok)) if (u[2, j] >= FALSE_DROP if k else u[2, j] < 1 - CATCH)]
        else:
            acc = list(zip(rep, ok))
        plane.learn(s, sc, top, ch["lexpos"][r], rep, acc)
    return x, h, (plane.learned if plane else [0, 0])


def streams_for(ch, tag, orders):
    """Shared random numbers per (chat, order, question): rows = swap?, which wrong node, verifier."""
    out = []
    for o in range(orders):
        g = np.random.default_rng([tag, o, 7919])
        out.append([g.random((3, max(len(ev), 1))) for _, ev, _ in ch["qs"]])
    return out


def project(b, ch):
    with torch.no_grad():
        return b.a(torch.tensor(ch["nodes"])).numpy(), b.s(torch.tensor(ch["asks"])).numpy()


def evaluate(cases, cfg, conds, hybrid=False):
    """cases: list of (chat, keys, states, orders, streams, mu0, scale). Returns {cond: (x, h, learned)}."""
    res = {}
    for cond in conds:
        xs, hs, lr = [], [], [0, 0]
        for ch, keys, states, orders, streams, mu0, scale in cases:
            for order, stream in zip(orders, streams):
                x, h, l = run_chat(ch, keys, states, cfg, cond, order, stream, mu0, scale, hybrid)
                xs.append(x); hs.append(h); lr[0] += l[0]; lr[1] += l[1]
        res[cond] = (np.concatenate(xs), np.concatenate(hs), lr)
    return res


def boot(d, rng, groups=None, n=2000):
    """Paired bootstrap 95% CI of the mean of d; with groups, resample whole groups (questions)."""
    if groups is not None:
        keys, inv = np.unique(groups, return_inverse=True)
        d = np.bincount(inv, weights=d) / np.bincount(inv)
    m = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(n)]
    return float(np.percentile(m, 2.5)), float(np.percentile(m, 97.5))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", required=True); p.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    p.add_argument("--cache", default=os.path.join(HERE, "chats.pkl"))
    p.add_argument("--orders", type=int, default=3); p.add_argument("--folds", type=int, default=5)
    p.add_argument("--out", default=os.path.join(HERE, "results.json"))
    a = p.parse_args()
    t0 = time.time()
    if hashlib.sha256(open(a.data, "rb").read()).hexdigest() != SHA:
        sys.exit("not the pinned LoCoMo file")
    if os.path.exists(a.cache):
        chats = pickle.load(open(a.cache, "rb"))
    else:
        chats = load(a.data, a.model); pickle.dump(chats, open(a.cache, "wb"))
    dim = chats[0]["nodes"].shape[1]
    for ch in chats:  # BM25 rank position of every node for every question (question text only)
        idx = {d: i for i, d in enumerate(ch["ids"])}; ch["lexpos"] = []
        for q, _, _ in ch["qs"]:
            pos = np.empty(len(ch["ids"]), dtype=np.int64)
            pos[[idx[d] for d in bm25_rank(ch["docs"], ch["ids"], tokens(q))]] = np.arange(len(ch["ids"]))
            ch["lexpos"].append(pos)
        ch["evset"] = [set(ev) for _, ev, _ in ch["qs"]]
    print(f"data ready {time.time() - t0:.0f}s", flush=True)

    def cases_for(chat_ids, train_ids, seed, tag0):
        b = train([chats[i] for i in train_ids], dim, 40, seed, rank=16)
        with torch.no_grad():
            mu0 = np.concatenate([project(b, chats[i])[1] for i in train_ids]).mean(0)
        out = []
        for i in chat_ids:
            keys, states = project(b, chats[i])
            orders = [np.random.default_rng(tag0 + 10 * i + o).permutation(len(chats[i]["qs"])) for o in range(a.orders)]
            out.append((chats[i], keys, states, orders, streams_for(chats[i], tag0 + 10 * i, a.orders), mu0,
                        float(b.scale.exp().detach())))
        return out

    tests, meta = [], []  # canonical visit order: fold, chat, order, visit
    chosen = collections.defaultdict(list); devlog = collections.defaultdict(list)
    test_res = collections.defaultdict(lambda: collections.defaultdict(list))
    for fold in range(a.folds):
        test = [2 * fold, 2 * fold + 1]; g = (fold + 1) % 5; dev = [2 * g, 2 * g + 1]
        train_ids = [i for i in range(10) if i not in test]
        dev_cases = cases_for(dev, [i for i in train_ids if i not in dev], fold, 100000 + 100 * fold)
        test_cases = cases_for(test, train_ids, fold, 100 * fold)  # same orders as e6_fixes.py
        dbase = evaluate(dev_cases, None, ("clean",))["clean"][0].mean()
        for name, configs in ARMS:  # tune on the dev chats only
            if len(configs) == 1:
                best = configs[0]
            else:
                scored = []
                for cfg in configs:
                    r = evaluate(dev_cases, cfg, MAIN)
                    dl = [r[c][0].mean() - dbase for c in MAIN]
                    scored.append((np.mean(dl) + min(dl), cfg, dl))
                    devlog[name].append(dict(fold=fold, cfg=cfg, deltas=[round(x, 4) for x in dl]))
                best = max(scored, key=lambda z: z[0])[1]
            chosen[name].append(best)
        print(f"fold {fold} tuned {time.time() - t0:.0f}s: " + "; ".join(f"{n}={chosen[n][-1]}" for n, _ in ARMS), flush=True)
        r = evaluate(test_cases, None, ("clean",), hybrid=True)["clean"]
        test_res["baseline"]["x"].append(r[0]); test_res["baseline"]["h"].append(r[1])
        for name, _ in ARMS:
            r = evaluate(test_cases, chosen[name][-1], MAIN + AUDIT, hybrid=True)
            for cond, (x, h, lr) in r.items():
                test_res[(name, cond)]["x"].append(x); test_res[(name, cond)]["h"].append(h)
                test_res[(name, cond)]["lr"].append(lr)
        for ci, (ch, _, _, orders, _, _, _) in zip(test, test_cases):
            for order in orders:
                meta += [(ci, int(r), ch["qs"][r][2]) for r in order]
        print(f"fold {fold} tested {time.time() - t0:.0f}s", flush=True)

    qid = np.array([1000 * c + r for c, r, _ in meta]); cat = np.array([k for _, _, k in meta])
    chat = np.array([c for c, _, _ in meta])
    base = np.concatenate(test_res["baseline"]["x"]); hbase = np.concatenate(test_res["baseline"]["h"])
    rng = np.random.default_rng(0)
    rows = [dict(arm="baseline", cond="-", recall=base.mean(), mh=base[cat == 1].mean(), hyb=hbase.mean())]
    print(f"\n{len(base)} test visits (1531 questions x {a.orders} orders), recall@10, rank-16 bridges")
    print(f"  baseline (no learning)  {base.mean():.3f}  multi-hop {base[cat == 1].mean():.3f}  +bm25 {hbase.mean():.3f}")
    for name, _ in ARMS:
        print(f"  {name}: per-fold settings {chosen[name]}")
        for cond in MAIN + AUDIT:
            x = np.concatenate(test_res[(name, cond)]["x"]); h = np.concatenate(test_res[(name, cond)]["h"])
            lr = np.sum(test_res[(name, cond)]["lr"], axis=0)
            d = x - base; lo, hi = boot(d, rng); qlo, qhi = boot(d, rng, groups=qid)
            per_chat = [round(float(d[chat == k].mean()), 4) for k in sorted(set(chat.tolist()))]
            row = dict(arm=name, cond=cond, recall=x.mean(), mh=x[cat == 1].mean(), hyb=h.mean(), delta=d.mean(),
                       ci=(lo, hi), ci_q=(qlo, qhi), hyb_delta=(h - hbase).mean(), learned_ok=int(lr[0]),
                       learned_wrong=int(lr[1]), settings=chosen[name], per_chat=per_chat)
            rows.append(row)
            print(f"    {cond:<8} {x.mean():.3f}  {d.mean():+.3f} [{lo:+.3f},{hi:+.3f}] q-CI [{qlo:+.3f},{qhi:+.3f}]  "
                  f"mh {row['mh']:.3f}  +bm25 {h.mean():.3f} ({row['hyb_delta']:+.3f})  "
                  f"learned {lr[0]} ok / {lr[1]} wrong  chats +{sum(v > 0 for v in per_chat)}/-{sum(v < 0 for v in per_chat)} "
                  f"(worst {min(per_chat):+.3f})", flush=True)
    json.dump(dict(rows=rows, dev=devlog, seconds=time.time() - t0), open(a.out, "w"), indent=1, default=str)
    print(f"done {time.time() - t0:.0f}s -> {a.out}")


if __name__ == "__main__":
    main()
