#!/usr/bin/env python3
"""B5: internode encoder (shared-weight attention pooling, parent state from up to 16 children). One CPU thread.

  a_i = softmax_i( (q + W_q mean(c)) . (W_k c_i) / sqrt(d) ),   p = unit( W_o sum_i a_i W_v c_i + mean(c) + e_level )
Shared across all parents and levels (e_level is a per-level vector). Measured:
  path    recompute the parents on one root-to-leaf path after a write (depth 3 / 4 / 5), with and without a cache
          of the children's projected keys/values (W_k c, W_v c)
  tree    recompute every parent bottom-up after a weight update, N = 1e4 / 1e5 / 1e6 leaves (full 384x384
          projections, fp32 and bf16-autocast), and with low-rank I + U V^T projections (r = 32)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, synthetic_keys, timeit, torch, np  # noqa: E402

rec = Recorder(__file__)
F, D, R = 16, 384, 32
torch.manual_seed(0)


class Pool(torch.nn.Module):
    def __init__(self, rank=0):
        super().__init__()
        self.rank = rank
        if rank:
            self.u = torch.nn.Parameter(torch.randn(3, D, rank) * 0.02)
            self.v = torch.nn.Parameter(torch.randn(3, rank, D) * 0.02)
        else:
            self.k = torch.nn.Linear(D, D, bias=False); self.vv = torch.nn.Linear(D, D, bias=False)
        self.qw = torch.nn.Linear(D, D, bias=False); self.o = torch.nn.Linear(D, D, bias=False)
        self.q0 = torch.nn.Parameter(torch.randn(D) * 0.02); self.lvl = torch.nn.Parameter(torch.zeros(8, D))

    def proj(self, c):  # c: (..., D) -> keys, values
        if self.rank:
            return c + (c @ self.v[0].T) @ self.u[0].T, c + (c @ self.v[1].T) @ self.u[1].T
        return self.k(c), self.vv(c)

    def pool(self, kc, vc, c, level):  # kc, vc, c: (P, F, D)
        m = c.mean(1)
        a = torch.softmax(((self.q0 + self.qw(m))[:, None, :] * kc).sum(-1) / D ** 0.5, dim=1)
        return torch.nn.functional.normalize(self.o((a[..., None] * vc).sum(1)) + m + self.lvl[level], dim=-1)

    def forward(self, c, level):
        kc, vc = self.proj(c)
        return self.pool(kc, vc, c, level)


def whole_tree(model, leaves):
    x, level = leaves, 0
    while x.shape[0] > 1:
        p = x.shape[0] // F
        x = model(x[: p * F].reshape(p, F, D), level)
        level += 1
    return x


def main():
    for rank in (0, R):
        model = Pool(rank).eval()
        tag = "full 384x384" if not rank else f"low-rank r={R}"
        with torch.inference_mode():
            for depth in (3, 4, 5):
                kids = [torch.randn(1, F, D) for _ in range(depth)]
                cache = [model.proj(k) for k in kids]
                rec.add(f"internode path recompute, depth {depth}, {tag}, no cache",
                        timeit(lambda: [model(k, i) for i, k in enumerate(kids)], repeat=300), depth=depth)
                rec.add(f"internode path recompute, depth {depth}, {tag}, cached child K/V",
                        timeit(lambda: [model.pool(kv[0], kv[1], k, i) for i, (k, kv) in enumerate(zip(kids, cache))],
                               repeat=300), depth=depth)
            for n in (10_000, 100_000, 1_000_000):
                n16 = (n // F ** 2) * F ** 2  # whole number of grand-parents keeps the reshape simple
                leaves = torch.from_numpy(synthetic_keys(n16, seed=4))
                rep = 5 if n <= 1e4 else (3 if n <= 1e5 else 1)
                ms = timeit(lambda: whole_tree(model, leaves), repeat=rep, warmup=1 if n < 1e6 else 0)
                rec.add(f"internode whole-tree recompute N={n:.0e}, {tag}, fp32", ms, n=n)
                if not rank:
                    def bf():
                        with torch.autocast("cpu", dtype=torch.bfloat16):
                            return whole_tree(model, leaves)
                    rec.add(f"internode whole-tree recompute N={n:.0e}, {tag}, bf16 autocast",
                            timeit(bf, repeat=rep, warmup=1 if n < 1e6 else 0), n=n)
                del leaves
    rec.save()


if __name__ == "__main__":
    main()
