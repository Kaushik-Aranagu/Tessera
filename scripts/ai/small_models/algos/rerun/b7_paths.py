#!/usr/bin/env python3
"""B7: the read, read-again, write and forget paths end to end, memory plane only (no LLM), one CPU thread.

Memory: a pyramid of N = 16^3 = 4096 and 16^4 = 65536 leaves (keys leaf-shaped, synthetic; text = LoCoMo turns and
recombined turns), cached action keys at every level, a postings BM25 index, internode attention pooling with cached
child K/V. Reasoning state = a real LoCoMo question (hop 1) or question + top-2 retrieved snippets (hops 2, 3).
  read hop     encode state -> state head -> beam descent (B=8) + stop bridge -> BM25 top-50 -> RRF -> top-10 ids+text
  read flat    the same with flat scoring of all leaves instead of the descent
  read-again   1, 2, 3 hops (each later hop re-encodes the question plus the two best new snippets)
  write        encode leaf -> action head -> write bridge places it (descent to a level-1 parent) -> append ->
               recompute ancestors on the path (cached K/V) -> dirty flags up the path -> BM25 add
  forget       tombstone + zero the key, remove BM25 postings, recompute ancestors, purge the leaf from a 1e4-entry
               ask log, mark the path's gists for re-distillation (the re-distillation itself is an LLM call: external)
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "/tmp/claude-0/sm")
os.environ.setdefault("HF_HUB_OFFLINE", "1")
from common import Recorder, load_locomo, synthetic_keys, timeit, torch, np, unit  # noqa: E402
from bm25lib import Postings  # noqa: E402
from e1_retriever import tokens  # noqa: E402
from b5_internode import Pool  # noqa: E402
from sentence_transformers import SentenceTransformer  # noqa: E402

rec = Recorder(__file__)
F, D, R = 16, 384, 16
rng = np.random.default_rng(0)
chats = load_locomo()
turns = [t for c in chats for t in c["text"].values()]
asks = [q[0] for c in chats for q in c["qs"]]
enc = SentenceTransformer("BAAI/bge-small-en-v1.5", device="cpu")
U = (rng.standard_normal((D, R)) * 0.05).astype(np.float32); V = (rng.standard_normal((R, D)) * 0.05).astype(np.float32)
pool = Pool(0).eval()


def head(x):
    return unit(x + (x @ V.T) @ U.T)


def encode(text):
    return enc.encode([text], normalize_embeddings=True, show_progress_bar=False)[0]


def rrf(*lists, k=60):
    s = collections.defaultdict(float)
    for lst in lists:
        for r, d in enumerate(lst):
            s[int(d)] += 1 / (k + r + 1)
    return sorted(s, key=lambda d: -s[d])


for depth in (3, 4):
    n = F ** depth
    texts = list(turns[:n])
    while len(texts) < n:
        a, b = turns[rng.integers(len(turns))].split(), turns[rng.integers(len(turns))].split()
        texts.append(" ".join(a[: len(a) // 2] + b[len(b) // 2:]))
    leaves = head(synthetic_keys(n, seed=8)).astype(np.float32)
    levels = [leaves]
    while len(levels[0]) > F:
        levels.insert(0, unit(levels[0].reshape(-1, F, D).mean(1)).astype(np.float32))
    alive = np.ones(n, bool)
    dirty = [np.zeros(len(lv), bool) for lv in levels]
    bm = Postings([tokens(t) for t in texts])
    log = [(int(rng.integers(n)), rng.integers(0, n, 10)) for _ in range(10_000)]  # (cited, opened) per logged ask
    with torch.inference_mode():
        kv_cache = [pool.proj(torch.from_numpy(lv.reshape(-1, F, D)[:1].copy())) for lv in levels[1:]]

    def descend(s, B=8, k=10):
        sc = levels[0] @ s
        beam = np.argpartition(-sc, B)[:B]
        for lvl in range(1, len(levels)):
            idx = (beam[:, None] * F + np.arange(F)).ravel()
            sc = levels[lvl][idx] @ s
            if lvl < len(levels) - 1:
                beam = idx[np.argpartition(-sc, B)[:B]]
                _stop = 1 / (1 + np.exp(-(4 * sc.max() - 2)))  # stop bridge
            else:
                sc = np.where(alive[idx], sc, -9)
                sel = np.argpartition(-sc, 50)[:50]
                return idx[sel[np.argsort(-sc[sel])]]

    def flat(s, k=50):
        sc = np.where(alive, leaves @ s, -9)
        sel = np.argpartition(-sc, k)[:k]
        return sel[np.argsort(-sc[sel])]

    def read_hop(text, q_toks, use_flat=False):
        s = head(encode(text))
        dense = flat(s) if use_flat else descend(s)
        lex = bm.top(q_toks, 50)
        top = rrf(dense, lex)[:10]
        return top, [(i, texts[i]) for i in top]

    qi = [0]

    def nq():
        qi[0] = (qi[0] + 1) % len(asks)
        return asks[qi[0]]

    def read(hops, use_flat=False):
        q = nq(); qt = tokens(q); seen = set(); text = q
        for _ in range(hops):
            top, ctx = read_hop(text, qt, use_flat)
            new = [c for c in ctx if c[0] not in seen][:2]
            seen.update(t for t, _ in ctx)
            text = q + " " + " ".join(t for _, t in new)
        return seen

    rec.add(f"read hop, pyramid descent B=8, N={n}", timeit(lambda: read(1), repeat=100), n=n)
    rec.add(f"read hop, flat scoring, N={n}", timeit(lambda: read(1, True), repeat=100), n=n)
    q0 = asks[0]; s0 = head(encode(q0)); qt0 = tokens(q0)
    rec.add(f"  read hop minus encoder (descent + BM25 + RRF + context), N={n}",
            timeit(lambda: rrf(descend(s0), bm.top(qt0, 50))[:10], repeat=500), n=n)
    rec.add(f"  read hop minus encoder, flat, N={n}", timeit(lambda: rrf(flat(s0), bm.top(qt0, 50))[:10], repeat=300),
            n=n)
    for hops in (2, 3):
        rec.add(f"read-again loop, {hops} hops, pyramid, N={n}", timeit(lambda: read(hops), repeat=60), n=n, hops=hops)

    wi = [0]

    def write():
        wi[0] = (wi[0] + 1) % len(turns)
        t = turns[wi[0]]
        k = head(encode(t))
        # write bridge: descend to the best level-(depth-1) parent (the leaf's would-be parent)
        sc = levels[0] @ k; node = int(np.argmax(sc))
        for lvl in range(1, len(levels) - 1):
            idx = node * F + np.arange(F)
            node = int(idx[np.argmax(levels[lvl][idx] @ k)])
        # append: overwrite a tombstoned/oldest slot under that parent (fixed-fanout stand-in for an append)
        slot = node * F + int(wi[0] % F)
        levels[-1][slot] = k
        with torch.inference_mode():
            for lvl in range(len(levels) - 2, -1, -1):  # recompute ancestors bottom-up (cached sibling K/V)
                kc, vc = kv_cache[min(lvl, len(kv_cache) - 1)]
                c = torch.from_numpy(levels[lvl + 1][node * F:(node + 1) * F].copy())[None]
                levels[lvl][node] = pool.pool(kc, vc, c, len(levels) - 2 - lvl)[0].numpy()
                dirty[lvl][node] = True
                node //= F
        bm.add_doc(tokens(t))

    rec.add(f"write path (encode + place + ancestors + dirty + BM25), N={n}", timeit(write, repeat=100), n=n)
    k_pre = head(encode(turns[5]))

    def write_no_enc():
        sc = levels[0] @ k_pre; node = int(np.argmax(sc))
        for lvl in range(1, len(levels) - 1):
            idx = node * F + np.arange(F)
            node = int(idx[np.argmax(levels[lvl][idx] @ k_pre)])
        with torch.inference_mode():
            for lvl in range(len(levels) - 2, -1, -1):
                kc, vc = kv_cache[min(lvl, len(kv_cache) - 1)]
                c = torch.from_numpy(levels[lvl + 1][node * F:(node + 1) * F].copy())[None]
                levels[lvl][node] = pool.pool(kc, vc, c, len(levels) - 2 - lvl)[0].numpy()
                dirty[lvl][node] = True
                node //= F

    rec.add(f"  write path minus encoder and BM25 (place + ancestors + dirty), N={n}", timeit(write_no_enc, repeat=300),
            n=n)
    fi = [0]

    def forget():
        fi[0] = (fi[0] + 7919) % n
        v = fi[0]
        alive[v] = False; levels[-1][v] = 0.0
        bm.remove_doc(v, tokens(texts[v]))
        node = v // F
        with torch.inference_mode():
            for lvl in range(len(levels) - 2, -1, -1):
                kc, vc = kv_cache[min(lvl, len(kv_cache) - 1)]
                c = torch.from_numpy(levels[lvl + 1][node * F:(node + 1) * F].copy())[None]
                levels[lvl][node] = pool.pool(kc, vc, c, len(levels) - 2 - lvl)[0].numpy()
                dirty[lvl][node] = True
                node //= F
        log[:] = [(c, o[o != v]) for c, o in log if c != v]

    rec.add(f"forget path (tombstone + BM25 + ancestors + purge 1e4-entry log), N={n}", timeit(forget, repeat=40), n=n)
rec.save()
