#!/usr/bin/env python3
"""B2: bridge projection, scoring N cached keys, quantized scoring, top-k selection. One CPU thread.

Keys are synthetic but shaped like real bge-small leaf vectors (common.synthetic_keys); queries are real LoCoMo ask
vectors. Recall columns compare a quantized arm's top-10 with the exact fp32 top-10 for the same query (fidelity to
exact search, not task recall).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, real_asks, synthetic_keys, timeit, torch, np, unit  # noqa: E402

rec = Recorder(__file__)
D, R = 384, 16
rng = np.random.default_rng(0)
asks = real_asks()
q = asks[0].copy()

# ---- bridge heads: identity plus rank-16 (I + U V^T) and a full 384x384 head ----
U = (rng.standard_normal((D, R)) * 0.05).astype(np.float32); V = (rng.standard_normal((R, D)) * 0.05).astype(np.float32)
W = (np.eye(D) + U @ V).astype(np.float32)
rec.add("state head, low-rank r=16, 1 vector (numpy) + normalise", timeit(lambda: unit(q + (V @ q) @ U.T), repeat=2000))
rec.add("state head, full 384x384, 1 vector (numpy) + normalise", timeit(lambda: unit(W @ q), repeat=2000))
tU, tV, tq = torch.from_numpy(U), torch.from_numpy(V), torch.from_numpy(q)
with torch.inference_mode():
    rec.add("state head, low-rank r=16, 1 vector (torch eager)",
            timeit(lambda: torch.nn.functional.normalize(tq + (tV @ tq) @ tU.T, dim=0), repeat=2000))
for n in (10_000, 100_000):
    X = synthetic_keys(n, seed=1)
    rec.add(f"action head, low-rank r=16, recompute N={n:.0e} keys (after refit)",
            timeit(lambda: unit(X + (X @ V.T) @ U.T), repeat=10 if n > 10_000 else 30), n=n)

# ---- scoring N cached keys ----
ks = [10, 100]
for n in (1_000, 10_000, 100_000, 1_000_000):
    K = synthetic_keys(n, seed=2)
    rep = 400 if n <= 1e4 else (60 if n <= 1e5 else 12)
    exact = np.argsort(-(asks[:50] @ K.T), axis=1)[:, :10] if n <= 1e5 else None
    rec.add(f"score N={n:.0e}: fp32 GEMV numpy (OpenBLAS)", timeit(lambda: K @ q, repeat=rep), n=n,
            bytes_per_key=4 * D)
    S4 = np.ascontiguousarray(asks[:4].T)
    rec.add(f"score N={n:.0e}: fp32, 4 queries in one GEMM (batched reads)", timeit(lambda: K @ S4, repeat=rep), n=n)
    tK = torch.from_numpy(K)
    with torch.inference_mode():
        rec.add(f"score N={n:.0e}: fp32 torch.mv", timeit(lambda: torch.mv(tK, tq), repeat=rep), n=n)
        hK, hq = tK.half(), tq.half()
        rec.add(f"score N={n:.0e}: fp16 torch.mv (CPU)", timeit(lambda: torch.mv(hK, hq), repeat=rep), n=n,
                bytes_per_key=2 * D)
        bK, bq = tK.bfloat16(), tq.bfloat16()
        rec.add(f"score N={n:.0e}: bf16 torch.mv (CPU)", timeit(lambda: torch.mv(bK, bq), repeat=rep), n=n,
                bytes_per_key=2 * D)
        # int8: keys as the weight of a dynamically quantized Linear (fbgemm x86 int8 GEMM)
        lin = torch.nn.Linear(D, n, bias=False); lin.weight.data = tK.clone()
        qlin = torch.ao.quantization.quantize_dynamic(torch.nn.Sequential(lin), {torch.nn.Linear}, dtype=torch.qint8)
        tq2 = tq[None]
        note = ""
        if exact is not None:
            got = qlin(torch.from_numpy(asks[:50])).numpy()
            ov = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(np.argsort(-got, axis=1)[:, :10], exact)])
            note = f"top-10 overlap with fp32 {ov:.3f}"
        rec.add(f"score N={n:.0e}: int8 keys, fbgemm dynamic-quant Linear", timeit(lambda: qlin(tq2), repeat=rep),
                n=n, bytes_per_key=D, note=note)
        del lin, qlin, hK, bK
    # binary (sign) codes: 384 bits = 6 x uint64 per key, Hamming via popcount, then fp32 rerank of the top 200
    Kb = np.packbits(K > 0, axis=1).view(np.uint64)
    qb = np.packbits(q > 0).view(np.uint64)

    def binary_then_rerank(qq=q, qqb=qb):
        ham = np.bitwise_count(Kb ^ qqb).sum(1, dtype=np.int32)
        cand = np.argpartition(ham, 200)[:200]
        sc = K[cand] @ qq
        return cand[np.argsort(-sc)[:10]]

    note = ""
    if exact is not None:
        ov = np.mean([len(set(binary_then_rerank(a, np.packbits(a > 0).view(np.uint64))) & set(e)) / 10
                      for a, e in zip(asks[:50], exact)])
        note = f"top-10 overlap with fp32 {ov:.3f}"
    rec.add(f"score N={n:.0e}: 1-bit codes popcount + fp32 rerank top-200", timeit(binary_then_rerank, repeat=rep),
            n=n, bytes_per_key=D // 8, note=note)
    # top-k selection over N scores
    s = K @ q
    ts = torch.from_numpy(s)
    for k in ks:
        rec.add(f"top-{k} of N={n:.0e}: argpartition + sort k",
                timeit(lambda: (lambda i: i[np.argsort(-s[i])])(np.argpartition(-s, k)[:k]), repeat=rep), n=n, k=k)
        rec.add(f"top-{k} of N={n:.0e}: torch.topk", timeit(lambda: torch.topk(ts, k), repeat=rep), n=n, k=k)
    if n <= 100_000:
        rec.add(f"full argsort of N={n:.0e} (what e5/e6 do today)", timeit(lambda: np.argsort(-s, kind="stable"),
                                                                         repeat=max(10, rep // 4)), n=n)
    del K, tK
rec.save()
