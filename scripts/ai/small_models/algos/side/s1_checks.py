#!/usr/bin/env python3
"""Reviewer side checks (single thread). Each section prints one block; numbers feed the review, not the doc."""
import os, sys, time, collections
sys.path.insert(0, "/tmp/claude-0/algos/review/rerun")
sys.path.insert(0, "/tmp/claude-0/sm")
from common import load_locomo, real_asks, synthetic_keys, timeit, torch, np, unit  # noqa: E402

which = set(sys.argv[1:]) or set("ABCDEFGHIJ")
chats = load_locomo()

if "A" in which:  # filter threshold s.k >= 0.2: is it ever binding?
    from e5_bridges import train
    b = train(chats[:8], 384, 40, 0, rank=16)
    allv, top10, gold, gold_out = [], [], [], []
    with torch.no_grad():
        for c in chats[8:]:
            K = b.a(torch.tensor(c["nodes"])).numpy(); S = b.s(torch.tensor(c["asks"])).numpy()
            F = c["nodes"] @ c["asks"].T
            for r, (_, ev, _) in enumerate(c["qs"]):
                sc = K @ S[r]; o = np.argsort(-sc)[:10]
                allv.append(sc); top10.append(sc[o]); gold.append(sc[ev])
                gold_out.append(sc[[e for e in ev if e not in set(o)]] if any(e not in set(o) for e in ev) else np.empty(0))
    allv, top10, gold, go = map(np.concatenate, (allv, top10, gold, gold_out))
    q = lambda a: " ".join(f"p{p}={np.percentile(a, p):.3f}" for p in (1, 5, 50, 95))
    print(f"[A] bridged rank-16 s.k, held-out chats 8-9")
    print(f"    all (ask,node) pairs  {q(allv)}  share>=0.2 {np.mean(allv >= 0.2):.3f}")
    print(f"    opened top-10         {q(top10)}  share>=0.2 {np.mean(top10 >= 0.2):.4f}")
    print(f"    gold evidence         {q(gold)}  share>=0.2 {np.mean(gold >= 0.2):.4f}")
    print(f"    gold NOT in top-10    n={go.size}  share>=0.2 {np.mean(go >= 0.2) if go.size else float('nan'):.4f}")
    fz = np.concatenate([(c['nodes'] @ c['asks'].T).ravel() for c in chats[8:]])
    print(f"    frozen cosine, all pairs {q(fz)}")

if "B" in which:  # does b6 'online' actually move keys, or does the filter skip them?
    keys = synthetic_keys(10_000, seed=5); s = real_asks()[7]
    rng = np.random.default_rng(0)
    opened = set(rng.choice(10_000, 10, replace=False).tolist()); cited = list(opened)[:3]
    print(f"[B] b6 online(): s.k of the 3 cited keys before any update: {[round(float(keys[v] @ s), 3) for v in cited]}")

if "C" in which:  # k-means tree fidelity on REAL turn vectors vs synthetic leaf-shaped keys, N=4096
    from b3_pyramid import descend, flat, build_levels
    def balanced_split(X, k=16, iters=6, seed=0):  # copied from b3k_kmeans_tree.py (that module runs on import)
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
        if len(idx) <= 16:
            return idx
        lab = balanced_split(X[idx])
        return np.concatenate([tree_order(X, idx[lab == c]) for c in range(16)])
    real = np.concatenate([c["nodes"] for c in chats]).astype(np.float32)
    rng = np.random.default_rng(0)
    qs = real_asks()[:200]
    for name, keys in (("real LoCoMo turns", real[rng.permutation(len(real))[:4096]]),
                       ("synthetic leaf-shaped", synthetic_keys(4096, seed=3))):
        perm = tree_order(keys, np.arange(4096)); leaves = keys[perm]; levels = build_levels(leaves)
        exact = [set(flat(leaves, q)) for q in qs]
        ov = {B: float(np.mean([len(set(descend(levels, q, B)[0]) & e) / 10 for q, e in zip(qs, exact)])) for B in (1, 4, 8, 16, 32, 64)}
        print(f"[C] k-means tree N=4096 {name:<24} " + "  ".join(f"B={B}:{v:.2f}" for B, v in ov.items()))

if "D" in which:  # int8 scan + top-100 + fp32 rerank, the path Algorithm R actually specifies
    D = 384
    for n in (10_000, 100_000):
        K = synthetic_keys(n, seed=2); asks = real_asks(); tK = torch.from_numpy(K)
        lin = torch.nn.Linear(D, n, bias=False); lin.weight.data = tK.clone()
        qlin = torch.ao.quantization.quantize_dynamic(torch.nn.Sequential(lin), {torch.nn.Linear}, dtype=torch.qint8)
        exact = np.argsort(-(asks[:50] @ K.T), axis=1)[:, :10]

        def path(qv, k=10, pool=100):
            with torch.inference_mode():
                s8 = qlin(torch.from_numpy(qv)[None])[0].numpy()
            cand = np.argpartition(-s8, pool)[:pool]
            sc = K[cand] @ qv
            return cand[np.argsort(-sc)[:k]]
        ov = np.mean([len(set(path(a)) & set(e)) / 10 for a, e in zip(asks[:50], exact)])
        i = [0]
        def one():
            i[0] = (i[0] + 1) % 50; path(asks[i[0]])
        ms = timeit(one, repeat=200 if n <= 1e4 else 60)
        print(f"[D] N={n:.0e} int8 scan + top-100 + fp32 rerank: median {np.median(ms):.3f} ms p95 {np.percentile(ms,95):.3f}  overlap {ov:.3f}")
        del K, tK, lin, qlin

if "E" in which:  # hot vs cold cache scans (the timed loop re-scans the same K, so small N sits in L2/L3)
    junk = np.ones(192_000_000, np.float32)  # 768 MB, larger than the 260 MiB L3
    for n in (10_000, 100_000):
        K = synthetic_keys(n, seed=2); q = real_asks()[0]
        hot = timeit(lambda: K @ q, repeat=200)
        cold = []
        for _ in range(60):
            junk += 1.0  # evict caches
            t0 = time.perf_counter_ns(); K @ q; cold.append((time.perf_counter_ns() - t0) / 1e6)
        print(f"[E] fp32 GEMV N={n:.0e}: hot median {np.median(hot):.3f} ms, cold (after 768 MB sweep) median {np.median(cold):.3f} ms p95 {np.percentile(cold,95):.3f}")

if "F" in which:  # re-key at 1e5: one-shot (b2) vs chunked in place
    R, D = 16, 384; rng = np.random.default_rng(0)
    U = (rng.standard_normal((D, R)) * 0.05).astype(np.float32); V = (rng.standard_normal((R, D)) * 0.05).astype(np.float32)
    X = synthetic_keys(100_000, seed=1); out = np.empty_like(X)
    oneshot = timeit(lambda: unit(X + (X @ V.T) @ U.T), repeat=10)
    def chunked(step=4096):
        for s0 in range(0, len(X), step):
            x = X[s0:s0 + step]; y = x + (x @ V.T) @ U.T
            y /= np.linalg.norm(y, axis=1, keepdims=True); out[s0:s0 + step] = y
    ch = timeit(chunked, repeat=10)
    print(f"[F] re-key N=1e5: one-shot median {np.median(oneshot):.1f} ms, chunked 4096 in place median {np.median(ch):.1f} ms")

if "G" in which:  # forget: how much of the 12-17 ms is the naive log purge?
    rng = np.random.default_rng(0); n = 65536
    log = [(int(rng.integers(n)), rng.integers(0, n, 10)) for _ in range(10_000)]
    vi = [0]
    def purge():
        vi[0] = (vi[0] + 7919) % n; v = vi[0]
        log[:] = [(c, o[o != v]) for c, o in log if c != v]
    ms = timeit(purge, repeat=40)
    idx = collections.defaultdict(list)
    for j, (c, o) in enumerate(log):
        for x in set(o.tolist()) | {c}:
            idx[x].append(j)
    dead = set()
    def purge_indexed():
        vi[0] = (vi[0] + 7919) % n; v = vi[0]
        for j in idx.pop(v, ()):
            dead.add(j)
    ms2 = timeit(purge_indexed, repeat=400)
    print(f"[G] log purge 1e4 entries: naive median {np.median(ms):.2f} ms; with node->entries index median {np.median(ms2)*1000:.1f} us")

if "H" in which:  # BM25 postings vs e1 BM25: same ranking?
    from e1_retriever import BM25, tokens
    from bm25lib import Postings
    turns = [t for c in chats for t in c["text"].values()][:5000]
    docs = [tokens(t) for t in turns]
    bm = BM25({d: docs[d] for d in range(len(docs))}); p = Postings(docs)
    asks = [q[0] for c in chats for q in c["qs"]][:200]
    ov = []
    for a in asks:
        qt = tokens(a); e = bm.rank(qt)[:10]; g = p.top(qt, 50)[:10]
        ov.append(len(set(e) & set(int(x) for x in g)) / 10)
    print(f"[H] BM25 postings vs e1 loop, top-10 agreement over 200 asks (N=5000): mean {np.mean(ov):.3f}, min {np.min(ov):.1f}")

if "I" in which:  # whole-tree recompute 1e6: one-shot vs per-subtree chunks (allocation-bound claim)
    from b5_internode import Pool, whole_tree, F
    model = Pool(0).eval()
    n16 = (1_000_000 // 256) * 256
    leaves = torch.from_numpy(synthetic_keys(n16, seed=4))
    with torch.inference_mode():
        t0 = time.perf_counter()
        # level 1 in chunks of 4096 parents (65536 leaves), then the small upper levels in one go
        parts = [model(leaves[s:s + 65536].reshape(-1, F, 384), 0) for s in range(0, n16, 65536)]
        x = torch.cat(parts); lvl = 1
        while x.shape[0] > 1:
            p = x.shape[0] // F
            if p == 0: break
            x = model(x[: p * F].reshape(p, F, 384), lvl); lvl += 1
        t1 = time.perf_counter()
    print(f"[I] whole-tree N=1e6 chunked by 65536-leaf blocks: {1000*(t1-t0):.0f} ms (b5 one-shot reported 28352 ms)")
