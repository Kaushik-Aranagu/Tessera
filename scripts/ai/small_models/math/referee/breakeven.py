#!/usr/bin/env python3
"""Independent replay of the e6 noisy-cite protocol on the cached rank-16 bridges (read-only inputs), to check the
Analysis section's affine law Delta(p) = (1-p) Delta(0) + p Delta(1) and the break-even formula, and to measure the
Monte-Carlo spread of Delta(p) over coin seeds (which the R^2-on-3-points claim ignores)."""
import json, pickle, sys
import numpy as np

C = pickle.load(open("/tmp/claude-0/math/theory/chats.pkl", "rb"))
B = np.load("/tmp/claude-0/math/theory/bridges_r16.npz")
K = 10


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def run(eta, p, seed, self_cite=False):
    tot = 0.0; base = 0.0; n = 0; n_ok = n_wr = 0
    for fold in range(5):
        for i in (2 * fold, 2 * fold + 1):
            K0 = B[f"f{fold}_k{i}"].astype(np.float64); S = B[f"f{fold}_s{i}"].astype(np.float64); qs = C[i]["qs"]
            for o in range(3):
                order = np.random.default_rng(100 * fold + 10 * i + o).permutation(len(qs))
                g = np.random.default_rng(seed * 100003 + 1000 * fold + 10 * i + o)
                U = g.random((len(qs), 40)); V = g.random((len(qs), 40))
                keys = K0.copy()
                for r in order:
                    ev = qs[r][1]
                    sc = keys @ S[r]; top = np.argsort(-sc, kind="stable")[:K]
                    top0 = np.argsort(-(K0 @ S[r]), kind="stable")[:K]
                    tot += len(set(top) & set(ev)) / len(ev); base += len(set(top0) & set(ev)) / len(ev); n += 1
                    if self_cite:
                        cited = [int(top[0])]
                    else:
                        wrong = [int(v) for v in top if v not in ev]
                        cited = [wrong[int(V[r, j] * len(wrong))] if (wrong and U[r, j] < p) else v for j, v in enumerate(ev)]
                    for v in cited:
                        if v in ev: n_ok += 1
                        else: n_wr += 1
                        keys[v] = unit(keys[v] + eta * (S[r] - keys[v]))
    return (tot - base) / n, base / n, n_ok, n_wr


out = {}
for eta in (0.02, 0.1):
    rows = {}
    for seed in (1, 2, 3):
        rows[seed] = {p: run(eta, p, seed)[0] for p in (0.0, 0.3, 0.6, 1.0)}
    sf = run(eta, 0, 1, self_cite=True)
    mean = {p: float(np.mean([rows[s][p] for s in rows])) for p in (0.0, 0.3, 0.6, 1.0)}
    sd = {p: float(np.std([rows[s][p] for s in rows], ddof=1)) for p in (0.0, 0.3, 0.6, 1.0)}
    ep = {p: (1 - p) * mean[0.0] + p * mean[1.0] for p in (0.3, 0.6)}
    pstar_end = mean[0.0] / (mean[0.0] - mean[1.0])
    out[eta] = dict(delta_mean=mean, delta_sd_over_coin_seeds=sd, endpoint_pred=ep,
                    endpoint_miss={p: abs(ep[p] - mean[p]) for p in ep}, pstar_endpoint=pstar_end,
                    self_delta=sf[0], self_realised_wrong_share=sf[3] / (sf[2] + sf[3]), baseline=sf[1])
    print(eta, json.dumps(out[eta], indent=1), flush=True)
json.dump(out, open("/tmp/claude-0/math/referee/breakeven.json", "w"), indent=1)
