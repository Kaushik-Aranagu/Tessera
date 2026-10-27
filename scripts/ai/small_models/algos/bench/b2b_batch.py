#!/usr/bin/env python3
"""B2b: does batching several read states into one pass over the keys pay? (beam/parallel reads, read + stop
decisions together). One pass over N keys for Q = 1, 4, 16 queries, fp32 numpy / torch and int8 fbgemm. One thread."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, real_asks, synthetic_keys, timeit, torch, np  # noqa: E402

rec = Recorder(__file__)
asks = real_asks()
for n in (100_000, 1_000_000):
    K = synthetic_keys(n, seed=2); tK = torch.from_numpy(K)
    lin = torch.nn.Linear(384, n, bias=False); lin.weight.data = tK.clone()
    qlin = torch.ao.quantization.quantize_dynamic(torch.nn.Sequential(lin), {torch.nn.Linear}, dtype=torch.qint8)
    rep = 40 if n <= 1e5 else 8
    for Q in (1, 4, 16):
        S = np.ascontiguousarray(asks[:Q]); tS = torch.from_numpy(S)
        with torch.inference_mode():
            for name, fn in (("numpy K @ S.T", lambda: K @ S.T), ("numpy S @ K.T", lambda: S @ K.T),
                             ("torch S @ K.T", lambda: tS @ tK.T), ("int8 fbgemm", lambda: qlin(tS))):
                ms = timeit(fn, repeat=rep)
                rec.add(f"N={n:.0e}, Q={Q} queries in one pass, {name}", ms, n=n, q=Q,
                        note=f"{np.median(ms) / Q:.2f} ms per query")
    del K, tK, lin, qlin
rec.save()
