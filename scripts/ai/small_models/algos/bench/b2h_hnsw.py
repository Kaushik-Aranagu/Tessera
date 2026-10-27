#!/usr/bin/env python3
"""B2h: HNSW (hnswlib 0.8, M=16, ef_construction=100, inner product) vs exact fp32 scan. One CPU thread.

Same synthetic leaf-shaped keys and real LoCoMo ask queries as B2. Reports build time (offline cost), query time at
several ef, and top-10 overlap with the exact fp32 top-10 for 200 queries.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, real_asks, synthetic_keys, timeit, np  # noqa: E402
import hnswlib  # noqa: E402

rec = Recorder(__file__)
asks = real_asks()[:200]
for n in (10_000, 100_000, 1_000_000):
    K = synthetic_keys(n, seed=2)
    exact = np.empty((len(asks), 10), np.int64)
    for s in range(0, len(asks), 50):
        exact[s:s + 50] = np.argsort(-(asks[s:s + 50] @ K.T), axis=1)[:, :10]
    idx = hnswlib.Index(space="ip", dim=K.shape[1])
    idx.init_index(max_elements=n, ef_construction=100, M=16)
    idx.set_num_threads(1)
    t0 = time.perf_counter()
    idx.add_items(K, np.arange(n))
    build = time.perf_counter() - t0
    print(f"N={n:.0e} build {build:.1f} s single thread")
    rec.add(f"HNSW build N={n:.0e} (M=16, efC=100), whole index", [build * 1000], n=n,
            note=f"{1e6 * build / n:.0f} us per insert")
    for ef in (32, 64, 128):
        idx.set_ef(ef)
        got, _ = idx.knn_query(asks, k=10)
        ov = float(np.mean([len(set(a) & set(b)) / 10 for a, b in zip(got, exact)]))
        i = [0]

        def one():
            i[0] = (i[0] + 1) % len(asks)
            idx.knn_query(asks[i[0]][None], k=10)

        rec.add(f"HNSW query N={n:.0e} ef={ef}, top-10", timeit(one, repeat=400), n=n, ef=ef,
                note=f"top-10 overlap with exact {ov:.3f}", overlap=ov)
    del idx, K
rec.save()
