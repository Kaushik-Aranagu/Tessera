#!/usr/bin/env python3
"""Repeat the b2b int8 batching rows 3 times (fresh process state each block) to see whether Q=4 ~ Q=1 holds."""
import sys
sys.path.insert(0, "/tmp/claude-0/algos/review/rerun")
from common import real_asks, synthetic_keys, timeit, torch, np  # noqa: E402
asks = real_asks(); n = 100_000
K = synthetic_keys(n, seed=2); tK = torch.from_numpy(K)
lin = torch.nn.Linear(384, n, bias=False); lin.weight.data = tK.clone()
qlin = torch.ao.quantization.quantize_dynamic(torch.nn.Sequential(lin), {torch.nn.Linear}, dtype=torch.qint8)
q1 = asks[0]
with torch.inference_mode():
    for rep in range(3):
        row = []
        for Q in (1, 4, 16):
            tS = torch.from_numpy(np.ascontiguousarray(asks[:Q]))
            row.append(f"Q={Q}: {np.median(timeit(lambda: qlin(tS), repeat=60)):.2f}")
        row.append(f"fp32 GEMV Q=1: {np.median(timeit(lambda: K @ q1, repeat=60)):.2f}")
        tS16 = torch.from_numpy(np.ascontiguousarray(asks[:16]))
        row.append(f"fp32 torch Q=16 per query: {np.median(timeit(lambda: tS16 @ tK.T, repeat=30)) / 16:.2f}")
        print(f"[int8 batch, N=1e5, round {rep}] " + "  ".join(row) + " (ms)", flush=True)
