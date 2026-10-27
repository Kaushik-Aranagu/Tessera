#!/usr/bin/env python3
"""Descent fidelity inside ONE persona's history (what a personal store looks like): fan-out 8, depth 3, N=512 turns
of a single LoCoMo chat, that chat's own asks; balanced k-means tree, parents = unit(mean of children).
Compared with the same tree over 512 synthetic leaf-shaped keys and cross-chat asks (the b3k setting)."""
import sys
sys.path.insert(0, "/tmp/claude-0/algos/review/rerun")
from common import load_locomo, real_asks, synthetic_keys, np, unit  # noqa: E402
F = 8


def split(X, k=F, iters=6, seed=0):
    n = len(X); cap = n // k; rng = np.random.default_rng(seed); C = X[rng.choice(n, k, replace=False)].copy()
    for _ in range(iters):
        S = X @ C.T; pref = np.argsort(-S, 1); order = np.argsort(-S.max(1)); cnt = np.zeros(k, int); lab = np.empty(n, int)
        for i in order:
            for c in pref[i]:
                if cnt[c] < cap:
                    lab[i] = c; cnt[c] += 1; break
        C = unit(np.stack([X[lab == c].mean(0) for c in range(k)]))
    return lab


def order(X, idx):
    if len(idx) <= F: return idx
    lab = split(X[idx]); return np.concatenate([order(X, idx[lab == c]) for c in range(F)])


def levels_of(leaves):
    lv = [leaves]
    while len(lv[0]) > F: lv.insert(0, unit(lv[0].reshape(-1, F, lv[0].shape[1]).mean(1)))
    return lv


def descend(lv, s, B, k=10):
    sc = lv[0] @ s; beam = np.argsort(-sc)[:B]
    for l in range(1, len(lv)):
        idx = (beam[:, None] * F + np.arange(F)).ravel(); sc = lv[l][idx] @ s
        beam = idx[np.argsort(-sc)[: (B if l < len(lv) - 1 else k)]]
    return beam


def fid(keys, asks, Bs=(1, 2, 4, 8, 16)):
    leaves = keys[order(keys, np.arange(len(keys)))]; lv = levels_of(leaves)
    ex = [set(np.argsort(-(leaves @ q))[:10]) for q in asks]
    return {B: np.mean([len(set(descend(lv, q, B)) & e) / 10 for q, e in zip(asks, ex)]) for B in Bs}


chats = load_locomo(); res = []
for c in chats:
    if len(c["nodes"]) < 512: continue
    res.append(fid(c["nodes"][:512].astype(np.float32), c["asks"].astype(np.float32)))
print(f"[C2] within one chat, N=512, F=8, depth 3, {len(res)} chats: " + "  ".join(f"B={B}:{np.mean([r[B] for r in res]):.2f}" for B in res[0]))
print(f"     per-chat B=8 range: {min(r[8] for r in res):.2f}-{max(r[8] for r in res):.2f}")
syn = fid(synthetic_keys(512, seed=3), real_asks()[:200])
print(f"[C2] synthetic leaf-shaped, N=512, F=8, depth 3, cross-chat asks: " + "  ".join(f"B={B}:{v:.2f}" for B, v in syn.items()))
