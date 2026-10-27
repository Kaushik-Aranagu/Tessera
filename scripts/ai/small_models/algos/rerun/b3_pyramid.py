#!/usr/bin/env python3
"""B3: beam descent down a pyramid (branching 16, depth 3/4/5) vs flat scoring of every leaf. One CPU thread.

Pyramid layout: one contiguous fp32 array per level; children of node i at level l are rows 16i..16i+15 of level l+1,
so a beam step is one gather plus one small GEMV. Parent keys are unit(mean of children) (a stand-in gist; the
internode encoder's cost is B5). The stop bridge is a logistic on (score, depth) per beam node, evaluated every level.

Fidelity (top-10 overlap with exact flat search on the same keys) is bracketed by two synthetic layouts:
  clustered  leaves generated down the tree (child = unit(parent + noise)), so the tree matches the geometry (best case)
  random     leaf-shaped keys assigned to the tree at random, so parents carry almost no signal (worst case)
Real gists sit between; their effect on task recall has to be measured on LoCoMo / LongMemEval, not here.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, real_asks, synthetic_keys, timeit, np, unit  # noqa: E402

rec = Recorder(__file__)
F, D = 16, 384
AR = np.arange(F)


def build_levels(leaves):
    levels = [leaves]
    while len(levels[0]) > F:
        c = levels[0]
        levels.insert(0, unit(c.reshape(-1, F, D).mean(1)).astype(np.float32))
    return levels  # levels[0] has F nodes (children of the root)


def clustered(depth, seed=0):
    rng = np.random.default_rng(seed)
    base = real_asks()
    lv = unit(base[rng.choice(len(base), F, replace=False)])
    for d in range(1, depth):
        sigma = 0.6 / (d + 1)  # children spread around their parent, tighter deeper down
        lv = np.repeat(lv, F, axis=0)
        lv = unit(lv + sigma * rng.standard_normal(lv.shape, dtype=np.float32) / np.sqrt(D) * 4).astype(np.float32)
    return lv


def descend(levels, s, B, k=10, w=(4.0, -2.0)):
    sc = levels[0] @ s
    beam = np.argpartition(-sc, B)[:B] if B < len(sc) else np.arange(len(sc))
    stop = 1 / (1 + np.exp(-(w[0] * sc[beam] + w[1])))  # stop bridge (not acted on here; cost only)
    for lvl in range(1, len(levels)):
        idx = (beam[:, None] * F + AR).ravel()
        sc = levels[lvl][idx] @ s
        if lvl < len(levels) - 1:
            sel = np.argpartition(-sc, B)[:B] if B < len(sc) else np.arange(len(sc))
            beam = idx[sel]
            stop = 1 / (1 + np.exp(-(w[0] * sc[sel] + w[1] * lvl)))
        else:
            kk = min(k, len(idx))
            sel = np.argpartition(-sc, kk - 1)[:kk]
            return idx[sel[np.argsort(-sc[sel])]], stop


def flat(leaves, s, k=10):
    sc = leaves @ s
    sel = np.argpartition(-sc, k)[:k]
    return sel[np.argsort(-sc[sel])]


def main():
    for depth in (3, 4, 5):
        n = F ** depth
        for layout in ("clustered", "random"):
            if layout == "clustered":
                leaves = clustered(depth)
                rng = np.random.default_rng(1)
                queries = unit(leaves[rng.integers(0, n, 100)] + 0.3 * rng.standard_normal((100, D), dtype=np.float32)
                               / np.sqrt(D) * 4).astype(np.float32)
            else:
                leaves = synthetic_keys(n, seed=3)
                queries = real_asks()[:100]
            levels = build_levels(leaves)
            exact = [set(flat(leaves, qq)) for qq in queries]
            q = queries[0]
            if layout == "clustered":
                rep = 300 if n <= 70_000 else 15
                rec.add(f"flat score + top-10, N=16^{depth}={n}", timeit(lambda: flat(leaves, q), repeat=rep), n=n)
            for B in (1, 4, 8, 16):
                ov = float(np.mean([len(set(descend(levels, qq, B)[0]) & e) / 10 for qq, e in zip(queries, exact)]))
                scored = F + sum(min(B, F ** lv) * F for lv in range(1, depth))
                if layout == "clustered":
                    rec.add(f"beam descent B={B}, depth {depth} (N={n}), {scored} dot products",
                            timeit(lambda: descend(levels, q, B), repeat=1000), n=n, beam=B, depth=depth,
                            scored=scored, note=f"overlap vs flat: clustered {ov:.2f}", overlap_clustered=ov)
                else:
                    for row in rec.rows:
                        if row.get("N") == n and row.get("beam") == B:
                            row["overlap_random"] = ov
                            row["note"] += f", random {ov:.2f}"
                    print(f"    random layout N={n} B={B}: overlap vs flat {ov:.2f}")
            del levels, leaves
    rec.save()


if __name__ == "__main__":
    main()
