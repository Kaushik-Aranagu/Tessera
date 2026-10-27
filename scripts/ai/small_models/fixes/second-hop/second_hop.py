#!/usr/bin/env python3
"""Second hop for multi-hop asks: a learned read-again loop between the planes, on LoCoMo held-out chats (public only).

Failure mode: multi-hop questions (LoCoMo category 1, 281 questions, 3.1 evidence turns on average) need several
turns, and one read of memory misses the second piece. The design's answer is a read-again loop: what the first read
returned re-enters memory together with the ask. There is no LLM here, so the "new state" is built from vectors.

Base: the low-rank (identity + rank-16) bridge of e5_bridges.py, trained exactly as in e6_fixes.py (same folds, same
seeds), frozen. No key learning at all in this experiment (memory-plane rule "none"), so the visit order of a test
chat's questions cannot change any score; every question is scored once.

Arms (recall@10 of the marked evidence turns, 5 folds x 2 held-out chats, trained on the other 8 chats):
  lowrank           baseline: rank all turns by bridge key . bridge state of the ask (one read)
  hop-avg-key       untrained second hop (pre-registered A): q2 = normalise(s + k_h1), where s is the ask's bridge
                    state and k_h1 the bridge key of the hop-1 node (hop 1 = lowrank top-1, never the gold evidence)
  hop-avg-enc       untrained second hop (pre-registered B): q2 = state_head(normalise(ask_vec + node_vec_h1)), i.e.
                    average in the frozen encoder's space, then re-enter through the trained state bridge
  hop-learned       learned hop bridge: q2 = normalise(s + g(s,k) k_h1 + U V [s; k_h1]), a gated evidence vector plus
                    a low-rank correction of the concatenation (U: dim x r, V: r x 2dim; g in (0, 2)). It starts
                    exactly at hop-avg-key (g = 1, U = 0) and is trained with InfoNCE over a chat's turns (the hop-1
                    node masked out) on the TRAINING chats only; positives are the question's OTHER evidence turns.
  pyramid           open the 3 best sessions by BM25 (session = all turns of one session_N), rank inside them with
                    the lowrank bridge; turns of unopened sessions follow in lowrank order
  pyramid+hop-avg   same, ranking inside with hop-avg-key (hop 1 and hop 2 restricted to the opened sessions)
  pyramid+hop       same, ranking inside with hop-learned
  pyramid|lowrank   POST-HOC (added after run 1 showed the pyramid trades multi-hop for single-hop; no parameters):
                    plain reciprocal-rank fusion of the pyramid list and the lowrank list
Diagnostic (scoring only): the hop arms' change vs lowrank, split by whether hop 1 (lowrank top-1) was an evidence turn.
For every hop arm the hop-2 list is [h1] + the other turns ranked by key . q2 (the node read in hop 1 stays read), and
the final ranking is weighted reciprocal-rank fusion (k = 60) of the hop-1 list (weight 1) and the hop-2 list
(weight w). The untrained arms use w = 1 (plain fusion, fixed in advance).

Hyperparameters of hop-learned (rank, epochs, training pairs, fusion weight w) are tuned ONLY on training chats: within
each outer fold the 8 training chats are split into 4 inner pairs; for each pair a bridge and the hop heads are trained
on the other 6 and scored on the pair; the setting with the best pooled overall recall@10 over all 8 training chats is
then retrained on the 8 and run once on the 2 test chats. Test-chat evidence is used only for scoring.
Training pairs: "gold" = for each question with >= 2 evidence turns, each evidence turn as hop 1 and the others as
positives (teacher forcing); "gold+top1" adds the bridge's own top-1 as hop 1 with the remaining evidence as positives
(in-sample on the training chats, so it is a weaker stand-in for the test-time mistakes of hop 1).

Usage: python -I second_hop.py --data locomo10.json [--cache chats.pkl]
"""
import argparse, collections, hashlib, itertools, json, math, os, pickle, sys, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import SHA, load, train, tokens, bm25_rank, fuse  # noqa: E402

CATS = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
GRID = [dict(rank=r, epochs=e, pairs=p) for r, e, p in itertools.product((4, 16), (20, 60), ("gold", "gold+top1"))]
WEIGHTS = (0.5, 1.0)


def recall(order, ev, k=10):
    return len(set(order[:k]) & set(ev)) / len(ev)


def wfuse(orders, weights, k=60):
    """Weighted reciprocal-rank fusion; ties broken by node id like e5's fuse (identical to fuse when weights are 1)."""
    s = collections.defaultdict(float)
    for o, w in zip(orders, weights):
        for p, d in enumerate(o):
            s[d] += w / (k + p + 1)
    return sorted(s, key=lambda d: (-s[d], d))


def add_sessions(chats, path):
    """load() drops sessions; re-read the raw file and map each turn (dia_id) to its session_N."""
    for c, sample in zip(chats, json.load(open(path))):
        sess = {}
        for name, value in sample["conversation"].items():
            if name.startswith("session_") and isinstance(value, list):
                for t in value:
                    sess[t["dia_id"]] = int(name.split("_")[1])
        c["sess"] = np.array([sess[d] for d in c["ids"]])
        names = sorted(set(c["sess"].tolist()))
        sdocs = {n: [w for i, d in enumerate(c["ids"]) if c["sess"][i] == n for w in c["docs"][d]] for n in names}
        c["opened"] = [bm25_rank(sdocs, names, tokens(q))[:3] for q, _, _ in c["qs"]]  # 3 best sessions per ask


class HopHead(torch.nn.Module):
    """Second-hop state: ask state + gated hop-1 evidence key + low-rank correction of [s; k]."""

    def __init__(self, dim, rank):
        super().__init__()
        self.u = torch.nn.Parameter(torch.zeros(dim, rank))
        self.v = torch.nn.Parameter(torch.randn(rank, 2 * dim) * 0.01)
        self.gw = torch.nn.Parameter(torch.zeros(2 * dim)); self.gb = torch.nn.Parameter(torch.tensor(0.0))
        self.scale = torch.nn.Parameter(torch.tensor(math.log(20.0)))

    def forward(self, s, k):
        x = torch.cat([s, k], -1)
        g = 2 * torch.sigmoid(x @ self.gw + self.gb)
        return torch.nn.functional.normalize(s + g[..., None] * k + (x @ self.v.T) @ self.u.T, dim=-1)


def project(b, c):
    with torch.no_grad():
        return b.a(torch.tensor(c["nodes"])).numpy(), b.s(torch.tensor(c["asks"])).numpy()


def hop_pairs(c, keys, states, mode):
    """(question row, hop-1 node, positives) on a training chat; positives never include the hop-1 node."""
    out = {}
    for r, (_, ev, _) in enumerate(c["qs"]):
        if len(ev) >= 2:
            for h in ev:
                out[(r, h)] = [e for e in ev if e != h]
        if mode == "gold+top1":
            h = int(np.argmax(keys @ states[r])); pos = [e for e in ev if e != h]
            if pos:
                out[(r, h)] = pos
    return [(r, h, p) for (r, h), p in out.items()]


def train_hop(chats, projs, dim, rank, epochs, pairs, seed):
    torch.manual_seed(seed)
    head = HopHead(dim, rank); opt = torch.optim.AdamW(head.parameters(), lr=1e-3, weight_decay=0.0)
    data = []
    for c, (keys, states) in zip(chats, projs):
        ps = hop_pairs(c, keys, states, pairs)
        if not ps:
            continue
        rows = torch.tensor([r for r, _, _ in ps]); hs = torch.tensor([h for _, h, _ in ps])
        pos = torch.zeros(len(ps), len(keys))
        for j, (_, _, p) in enumerate(ps):
            pos[j, p] = 1 / len(p)
        data.append((torch.tensor(keys), torch.tensor(states)[rows], hs, pos))
    for _ in range(epochs):
        for K, S, hs, pos in data:
            logits = head.scale.exp() * head(S, K[hs]) @ K.T
            logits = logits.masked_fill(torch.nn.functional.one_hot(hs, len(K)).bool(), -1e4)  # hop-1 node is read
            loss = -(pos * logits.log_softmax(1)).sum(1).mean() + 0.01 * ((head.u @ head.v) ** 2).sum()
            opt.zero_grad(); loss.backward(); opt.step()
    return head


def rank_chat(c, keys, states, b, head, w, pyramid=False, hop="learned"):
    """Final ranking per question. hop in {None, 'key', 'enc', 'learned'}; pyramid restricts hops to 3 BM25 sessions."""
    out = []
    for r in range(len(c["qs"])):
        full = np.argsort(-(keys @ states[r]), kind="stable")
        if pyramid:
            inside = np.isin(c["sess"], c["opened"][r])
            cand = full[inside[full]]; rest = full[~inside[full]]
        else:
            cand, rest = full, full[:0]
        if hop is None:
            out.append(cand.tolist() + rest.tolist()); continue
        h1 = int(cand[0])
        if hop == "key":
            q2 = states[r] + keys[h1]; q2 /= np.linalg.norm(q2)
        elif hop == "enc":
            x = c["asks"][r] + c["nodes"][h1]; x /= np.linalg.norm(x)
            with torch.no_grad():
                q2 = b.s(torch.tensor(x)[None]).numpy()[0]
        else:
            with torch.no_grad():
                q2 = head(torch.tensor(states[r])[None], torch.tensor(keys[h1])[None]).numpy()[0]
        sc = keys[cand] @ q2
        second = [h1] + [int(v) for v in cand[np.argsort(-sc, kind="stable")] if v != h1]
        out.append(wfuse([cand.tolist(), second], [1.0, w if hop == "learned" else 1.0]) + rest.tolist())
    return out


def select(train_idx, chats, dim, fold, log):
    """Inner CV on the 8 training chats only: returns the best (setting, w) by pooled overall recall@10."""
    score = collections.defaultdict(list); base = []
    pairs = [train_idx[j:j + 2] for j in range(0, len(train_idx), 2)]
    for j, dev in enumerate(pairs):
        inner = [i for i in train_idx if i not in dev]
        b = train([chats[i] for i in inner], dim, 40, 1000 + 10 * fold + j, rank=16)
        projs = {i: project(b, chats[i]) for i in inner + dev}
        for i in dev:
            base += [recall(o, ev) for o, (_, ev, _) in zip(rank_chat(chats[i], *projs[i], b, None, 1.0, hop=None), chats[i]["qs"])]
        for g, cfg in enumerate(GRID):
            head = train_hop([chats[i] for i in inner], [projs[i] for i in inner], dim, seed=1000 + 10 * fold + j, **cfg)
            for w in WEIGHTS:
                for i in dev:
                    orders = rank_chat(chats[i], *projs[i], b, head, w)
                    score[(g, w)] += [recall(o, ev) for o, (_, ev, _) in zip(orders, chats[i]["qs"])]
    best = max(score, key=lambda k: (np.mean(score[k]), -k[0], -k[1]))
    log.append(dict(fold=fold, dev_lowrank=float(np.mean(base)),
                    dev=[dict(**GRID[g], w=w, recall10=float(np.mean(v))) for (g, w), v in sorted(score.items())],
                    chosen=dict(**GRID[best[0]], w=best[1])))
    print(f"  fold {fold} dev (8 training chats): lowrank {np.mean(base):.3f}; best hop {np.mean(score[best]):.3f} "
          f"with {GRID[best[0]]} w={best[1]}", flush=True)
    return GRID[best[0]], best[1]


def boot(d, rng, n=2000):
    b = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(n)]
    return float(np.percentile(b, 2.5)), float(np.percentile(b, 97.5))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", required=True); p.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    p.add_argument("--cache", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "chats.pkl"))
    a = p.parse_args()
    torch.set_num_threads(1); t0 = time.time()
    if hashlib.sha256(open(a.data, "rb").read()).hexdigest() != SHA:
        sys.exit("not the pinned LoCoMo file")
    if os.path.exists(a.cache):  # this script's own cache of load(a.data, a.model) (encoding takes minutes on 1 CPU)
        chats = pickle.load(open(a.cache, "rb"))
    else:
        chats = load(a.data, a.model); pickle.dump(chats, open(a.cache, "wb"))
    add_sessions(chats, a.data); dim = chats[0]["nodes"].shape[1]
    arms = ["lowrank", "hop-avg-key", "hop-avg-enc", "hop-learned", "pyramid", "pyramid+hop-avg", "pyramid+hop",
            "pyramid|lowrank"]
    per = collections.defaultdict(list); cat = []; log = []; diag = collections.defaultdict(list)
    for fold in range(5):
        test = [2 * fold, 2 * fold + 1]; train_idx = [i for i in range(10) if i not in test]
        cfg, w = select(train_idx, chats, dim, fold, log)
        b = train([chats[i] for i in train_idx], dim, 40, fold, rank=16)  # identical to e6's bridged-lowrank
        projs = {i: project(b, chats[i]) for i in train_idx + test}
        head = train_hop([chats[i] for i in train_idx], [projs[i] for i in train_idx], dim, seed=fold, **cfg)
        for i in test:
            c = chats[i]; keys, states = projs[i]
            ranked = {"lowrank": rank_chat(c, keys, states, b, None, 1.0, hop=None),
                      "hop-avg-key": rank_chat(c, keys, states, b, None, 1.0, hop="key"),
                      "hop-avg-enc": rank_chat(c, keys, states, b, None, 1.0, hop="enc"),
                      "hop-learned": rank_chat(c, keys, states, b, head, w),
                      "pyramid": rank_chat(c, keys, states, b, None, 1.0, pyramid=True, hop=None),
                      "pyramid+hop-avg": rank_chat(c, keys, states, b, None, 1.0, pyramid=True, hop="key"),
                      "pyramid+hop": rank_chat(c, keys, states, b, head, w, pyramid=True)}
            ranked["pyramid|lowrank"] = [fuse(x, y) for x, y in zip(ranked["pyramid"], ranked["lowrank"])]
            lex = [[c["ids"].index(d) for d in bm25_rank(c["docs"], c["ids"], tokens(q))] for q, _, _ in c["qs"]]
            for r, (_, ev, k) in enumerate(c["qs"]):
                cat.append(k)
                for arm in arms:
                    o = ranked[arm][r]
                    per[arm].append(recall(o, ev)); per[arm + " +bm25"].append(recall(fuse(lex[r], o), ev))
                diag["hop1 is evidence"].append(float(ranked["lowrank"][r][0] in ev))
                diag["evidence inside 3 opened sessions"].append(float(np.isin(c["sess"][ev], c["opened"][r]).mean()))
                diag["turns opened"].append(float(np.isin(c["sess"], c["opened"][r]).sum()))
    cat = np.array(cat); mh = cat == 1; n = len(cat); rng = np.random.default_rng(0)
    base = np.array(per["lowrank"]); res = {}
    print(f"\n{n} held-out questions (each scored once: no key learning, so visit order is irrelevant), recall@10")
    for arm in arms:
        x = np.array(per[arm]); d = x - base
        lo, hi = boot(d, rng); mlo, mhi = boot(d[mh], rng)
        res[arm] = dict(recall10=float(x.mean()), multihop10=float(x[mh].mean()), delta=float(d.mean()), ci=[lo, hi],
                        delta_mh=float(d[mh].mean()), ci_mh=[mlo, mhi], bm25=float(np.mean(per[arm + " +bm25"])),
                        by_cat={CATS[k]: float(x[cat == k].mean()) for k in CATS})
        print(f"  {arm:<16} {x.mean():.3f} [mh {x[mh].mean():.3f}]  vs lowrank {d.mean():+.3f} [{lo:+.3f},{hi:+.3f}]"
              f"  mh {d[mh].mean():+.3f} [{mlo:+.3f},{mhi:+.3f}]  +bm25 {np.mean(per[arm + ' +bm25']):.3f}  "
              + " ".join(f"{CATS[k]} {x[cat == k].mean():.3f}" for k in CATS))
    for k, v in diag.items():
        v = np.array(v); print(f"  diag {k}: all {v.mean():.3f}, multi-hop {v[mh].mean():.3f}")
    hit = np.array(diag["hop1 is evidence"]) > 0; split = {}
    for arm in ("hop-avg-key", "hop-avg-enc", "hop-learned", "pyramid+hop"):
        d = np.array(per[arm]) - base
        split[arm] = {f"{who} hop1 {ok}": [int((sel & (hit == okv)).sum()), float(d[sel & (hit == okv)].mean())]
                      for who, sel in (("all", np.ones(n, bool)), ("multi-hop", mh))
                      for ok, okv in (("right", True), ("wrong", False))}
        print(f"  diag {arm} vs lowrank by hop-1 correctness (n, delta): {split[arm]}")
    json.dump(dict(arms=res, selection=log, hop1_split=split, diag={k: [float(np.mean(v)), float(np.mean(np.array(v)[mh]))]
                                                  for k, v in diag.items()}, seconds=time.time() - t0),
              open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "results.json"), "w"), indent=1)
    print(f"done in {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
