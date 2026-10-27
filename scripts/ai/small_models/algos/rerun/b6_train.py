#!/usr/bin/env python3
"""B6: training-side costs on one CPU thread: per-ask online key update, nightly head refit, replay eval.

  online   after an answer: cite filter (cited node must have been opened, and its key must still agree with the ask)
           then the anchored move  k <- unit(k + eta (s - k)), total shift from the shipped key capped (E6 'anchored')
  refit    low-rank (r=16) state + action heads, InfoNCE over [cited positives | opened-not-cited hard negatives |
           1024 sampled negatives], CLM's backward term, plus an L2 pull to the shipped weights; ms per step of 64 asks
  e5       the actual E5 pretraining loop (8 LoCoMo chats, 40 epochs, rank 16), wall time for one fold
  replay   the nightly accept/reject gate: score 500 held-out logged asks against all N keys and compute recall@10
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "/tmp/claude-0/sm")
from common import Recorder, load_locomo, real_asks, synthetic_keys, timeit, torch, np, unit  # noqa: E402
from e5_bridges import train as e5_train, LowRank  # noqa: E402

rec = Recorder(__file__)
D = 384
rng = np.random.default_rng(0)

# ---- online update after one answer ----
keys = synthetic_keys(10_000, seed=5); base = keys.copy()
s = real_asks()[7]
opened = set(rng.choice(10_000, 10, replace=False).tolist())
cited = list(opened)[:3]


def online(eta=0.1, cap=0.3, agree=0.2):
    for v in cited:
        if v not in opened or keys[v] @ s < agree:  # cite filter
            continue
        k = keys[v] + eta * (s - keys[v]); k /= np.linalg.norm(k)
        d = k - base[v]; n = np.linalg.norm(d)
        if n > cap:
            k = base[v] + d * cap / n; k /= np.linalg.norm(k)
        keys[v] = k


rec.add("online key update after one answer (3 cites, filter + anchored move)", timeit(online, repeat=2000))

# ---- nightly refit of the heads on logged (ask, cited, opened) triples ----
for rank in (16, 0):
    torch.manual_seed(0)
    if rank:
        S, A = LowRank(D, rank), LowRank(D, rank)
        shipped = [p.detach().clone() for p in list(S.parameters()) + list(A.parameters())]
    else:
        S, A = torch.nn.Linear(D, D, bias=False), torch.nn.Linear(D, D, bias=False)
        torch.nn.init.eye_(S.weight); torch.nn.init.eye_(A.weight)
        shipped = [p.detach().clone() for p in list(S.parameters()) + list(A.parameters())]
    params = list(S.parameters()) + list(A.parameters())
    opt = torch.optim.AdamW(params, lr=1e-3)
    leaves = torch.from_numpy(synthetic_keys(20_000, seed=6))
    asks = torch.from_numpy(real_asks()[:64])
    B, H, NEG = 64, 10, 1024

    def step():
        pos = leaves[torch.randint(0, len(leaves), (B,))]                  # one cited node per ask (most have 1-2)
        hard = leaves[torch.randint(0, len(leaves), (B, H))]               # opened but not cited
        neg = leaves[torch.randint(0, len(leaves), (NEG,))]                # shared sampled negatives
        sq = torch.nn.functional.normalize(S(asks), dim=-1)
        kp = torch.nn.functional.normalize(A(pos), dim=-1)
        kh = torch.nn.functional.normalize(A(hard), dim=-1)
        kn = torch.nn.functional.normalize(A(neg), dim=-1)
        t = 20.0
        logits = torch.cat([t * sq @ kp.T, t * (sq[:, None, :] * kh).sum(-1), t * sq @ kn.T], 1)  # in-batch + hard + neg
        fwd = torch.nn.functional.cross_entropy(logits, torch.arange(B))
        bwd = torch.nn.functional.cross_entropy((t * sq @ kp.T).T, torch.arange(B))       # CLM node -> ask term
        reg = sum(((p - p0) ** 2).sum() for p, p0 in zip(params, shipped))
        loss = fwd + bwd + 0.01 * reg
        opt.zero_grad(); loss.backward(); opt.step()

    tag = f"low-rank r={rank}" if rank else "full 384x384"
    ms = timeit(step, repeat=50)
    rec.add(f"nightly refit step, {tag}, 64 asks x (64 in-batch + 10 hard + 1024 neg)", ms,
            note=f"=> 1e4 logged asks x 5 epochs ~ {np.median(ms) * 10_000 / 64 * 5 / 1000:.1f} s")

# ---- the real E5 pretraining loop on LoCoMo (one fold: 8 chats, 40 epochs, rank 16) ----
chats = load_locomo()
t0 = time.perf_counter()
e5_train(chats[:8], D, 40, 0, rank=16)
rec.add("E5 pretraining, one fold (8 LoCoMo chats ~4.7k nodes, 40 epochs, r=16)", [(time.perf_counter() - t0) * 1000])

# ---- replay eval gate: score held-out logged asks against all keys ----
Q = real_asks()[:500]
for n in (10_000, 100_000):
    K = synthetic_keys(n, seed=7)
    gold = rng.integers(0, n, 500)

    def replay():
        sc = Q @ K.T
        top = np.argpartition(-sc, 10, axis=1)[:, :10]
        return np.mean([g in t for g, t in zip(gold, top)])

    rec.add(f"replay eval gate: 500 asks x N={n:.0e} keys, recall@10", timeit(replay, repeat=5 if n > 1e4 else 20), n=n)
rec.save()
