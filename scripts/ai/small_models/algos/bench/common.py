"""Shared helpers for the two-plane memory micro-benchmarks.

Every script imports this first: it pins BLAS/OpenMP/torch to one thread before numpy or torch load, so numbers are
single-thread x86 (Intel Xeon, Sapphire-Rapids class, 2.1 GHz, AVX-512/AMX present, shared with other jobs).
Timings are wall-clock medians and p95 over repeated runs after warm-up.
"""
import json
import os
import sys
import time

for var in ("OMP_NUM_THREADS", "MKL_NUM_THREADS", "OPENBLAS_NUM_THREADS", "NUMEXPR_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    os.environ[var] = "1"
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(HERE, "vendor"))  # hnswlib, installed with pip --target (appended: env numpy wins)

import numpy as np  # noqa: E402

try:
    import torch  # noqa: E402
    torch.set_num_threads(1)
    torch.set_num_interop_threads(1)
except Exception:  # torch is optional for a few scripts
    torch = None

RESULTS = os.path.join(HERE, "results")
os.makedirs(RESULTS, exist_ok=True)
LOCOMO_CACHE = "/tmp/claude-0/sm/fix-cite-noise/chats.pkl"  # LoCoMo turns, asks and bge-small vectors from E5/E6


def timeit(fn, repeat=50, warmup=3, min_time=0.0):
    """Run fn() warmup times, then `repeat` timed runs (more if min_time seconds not reached). Returns ms list."""
    for _ in range(warmup):
        fn()
    out, start = [], time.perf_counter()
    while len(out) < repeat or (time.perf_counter() - start) < min_time:
        t0 = time.perf_counter_ns()
        fn()
        out.append((time.perf_counter_ns() - t0) / 1e6)
        if len(out) >= 20 * repeat:
            break
    return out


def stats(ms):
    a = np.asarray(ms)
    return {"median_ms": float(np.median(a)), "p95_ms": float(np.percentile(a, 95)), "n": int(a.size)}


class Recorder:
    def __init__(self, script):
        self.script, self.rows = script, []

    def add(self, what, ms, note="", **extra):
        if "n" in extra:  # problem size, not the run count
            extra["N"] = extra.pop("n")
        row = {"script": self.script, "what": what, **stats(ms), "note": note, **extra}
        self.rows.append(row)
        print(f"  {what:<62} median {row['median_ms']:>10.4f} ms   p95 {row['p95_ms']:>10.4f} ms   n={row['n']}"
              + (f"   {note}" if note else ""), flush=True)
        return row

    def save(self):
        path = os.path.join(RESULTS, os.path.splitext(os.path.basename(self.script))[0] + ".json")
        json.dump(self.rows, open(path, "w"), indent=1)
        print(f"saved {path}")


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def load_locomo():
    import pickle
    return pickle.load(open(LOCOMO_CACHE, "rb"))


def synthetic_keys(n, seed=0, dim=384):
    """n keys shaped like real bge-small leaf vectors: convex mix of two real LoCoMo turn vectors plus noise, unit."""
    chats = load_locomo()
    real = np.concatenate([c["nodes"] for c in chats]).astype(np.float32)
    rng = np.random.default_rng(seed)
    out = np.empty((n, dim), np.float32)
    step = 200_000
    for s in range(0, n, step):
        m = min(step, n - s)
        a, b = real[rng.integers(0, len(real), m)], real[rng.integers(0, len(real), m)]
        w = rng.random((m, 1), dtype=np.float32)
        x = w * a + (1 - w) * b + 0.03 * rng.standard_normal((m, dim), dtype=np.float32)
        out[s:s + m] = unit(x)
    return out


def real_asks():
    chats = load_locomo()
    return np.concatenate([c["asks"] for c in chats]).astype(np.float32)
