#!/usr/bin/env python3
"""B3k: the middle bracket for B3. Same leaf-shaped keys and real LoCoMo asks as the 'random' layout, but the tree is
built by recursive balanced k-means (16 equal children per node, 6 Lloyd iterations with capacity-constrained greedy
assignment), so parents summarise geometrically coherent groups, as topic-grouped gists would. Parent key =
unit(mean of children). Reports top-10 overlap of beam descent with exact flat search, and descent time.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, real_asks, synthetic_keys, timeit, np, unit  # noqa: E402
from b3_pyramid import descend, flat, build_levels, F  # noqa: E402

rec = Recorder(__file__)


def balanced_split(X, k=F, iters=6, seed=0):
    n = len(X); cap = n // k
    rng = np.random.default_rng(seed)
    C = X[rng.choice(n, k, replace=False)].copy()
    for _ in range(iters):
        S = X @ C.T
        pref = np.argsort(-S, axis=1)
        order = np.argsort(-S.max(1))
        cnt = np.zeros(k, int); lab = np.empty(n, int)
        for i in order:
            for c in pref[i]:
                if cnt[c] < cap:
                    lab[i] = c; cnt[c] += 1
                    break
        C = unit(np.stack([X[lab == c].mean(0) for c in range(k)]))
    return lab


def tree_order(X, idx):
    """Return idx reordered so every aligned block of 16^j rows is one subtree."""
    if len(idx) <= F:
        return idx
    lab = balanced_split(X[idx])
    return np.concatenate([tree_order(X, idx[lab == c]) for c in range(F)])


queries = real_asks()[:200]
for depth in (3, 4):
    n = F ** depth
    keys = synthetic_keys(n, seed=3)
    perm = tree_order(keys, np.arange(n))
    leaves = keys[perm]
    levels = build_levels(leaves)
    exact = [set(flat(leaves, q)) for q in queries]
    for B in (1, 4, 8, 16, 32, 64):
        ov = float(np.mean([len(set(descend(levels, q, B)[0]) & e) / 10 for q, e in zip(queries, exact)]))
        rec.add(f"beam descent B={B}, depth {depth} (N={n}), k-means tree, {F + sum(min(B, F ** lv) * F for lv in range(1, depth))} dots", timeit(lambda: descend(levels, queries[0], B),
                repeat=500), n=n, beam=B, note=f"overlap vs flat {ov:.2f}", overlap=ov)
rec.save()
