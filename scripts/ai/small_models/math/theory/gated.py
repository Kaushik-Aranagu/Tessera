"""Rank-gated learning (a rule derived from section 5.1.7): move only nodes that were NOT in the visit's top-K.
Conditions (move, eta 0.1, e6 protocol, rank-16 bridges, common random numbers):
  all        e6 clean cites (reference, +0.020)
  invisible  clean cites restricted to evidence ranked > K at the visit (what a deeper second read could find)
  inv+far p  invisible cites, each swapped with prob. p for a random non-evidence node ranked 11..50
Decomposition into re-ask / unrelated visits as in noise.py."""
import json, sys
import numpy as np

sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats, folds, orders, recall, topk, unit  # noqa: E402

K = 10


def replay(K0, S, qs, order, cond, p, eta, U, V):
    keys = K0.copy(); seen = set(); rows = []
    for t, r in enumerate(order):
        ev = qs[r][1]
        top = topk(keys @ S[r], 50)
        rows.append((recall(top, ev), recall(topk(K0 @ S[r], K), ev), bool(set(ev) & seen)))
        if cond == "all":
            cited = list(ev)
        else:
            inv = [v for v in ev if v not in set(top[:K])]
            far = [int(v) for v in top[K:50] if v not in ev]
            cited = [far[int(V[r, j] * len(far))] if (far and U[r, j] < p) else v for j, v in enumerate(inv)]
        for v in cited:
            keys[v] = unit(keys[v] + eta * (S[r] - keys[v]))
        seen |= set(ev)
    return rows


def main():
    C, B = chats(), bridges()
    arms = [("all", 0.0), ("invisible", 0.0), ("invisible", 0.3), ("invisible", 0.6)]
    per = {}
    for fold, i in folds():
        c = C[i]; K0, S = B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"]
        nq = len(c["qs"]); mx = max(len(q[1]) for q in c["qs"])
        for o, order in enumerate(orders(fold, i, nq)):
            g = np.random.default_rng(7000 + 100 * fold + 10 * i + o)
            U, V = g.random((nq, mx)), g.random((nq, mx))
            for cond, p in arms:
                per.setdefault(f"{cond} p={p}", []).extend(replay(K0, S, c["qs"], order, cond, p, 0.1, U, V))
    rng = np.random.default_rng(0); out = {}
    for k, rows in per.items():
        a = np.array(rows, float); d = a[:, 0] - a[:, 1]; rel = a[:, 2] > 0
        bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(500)]
        out[k] = dict(delta=d.mean(), ci=[np.percentile(bs, 2.5), np.percentile(bs, 97.5)], rel=d[rel].sum() / len(d), unrel=d[~rel].sum() / len(d))
        print(f"  {k:<16} delta {d.mean():+.4f} [{out[k]['ci'][0]:+.3f},{out[k]['ci'][1]:+.3f}]  re-ask part {out[k]['rel']:+.4f}  unrelated part {out[k]['unrel']:+.4f}")
    json.dump(out, open("/tmp/claude-0/math/theory/gated.json", "w"), indent=1, default=float)


if __name__ == "__main__":
    main()
