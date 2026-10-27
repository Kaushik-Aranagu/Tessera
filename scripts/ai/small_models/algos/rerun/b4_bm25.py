#!/usr/bin/env python3
"""B4: BM25 over 1e3 / 1e4 / 1e5 leaves, three implementations, plus reciprocal-rank fusion. One CPU thread.

Docs are real LoCoMo turns (5882); 1e4 and 1e5 add recombined turns (first half of one turn + second half of
another) so vocabulary and lengths stay realistic. Queries are real LoCoMo questions.
  e1-loop     the current e1_retriever.BM25.rank: Python scoring of every doc, then a full sort
  postings    inverted index with precomputed per-posting tf-norm weights; score only docs containing a query term
              (np.add.at into a dense accumulator), idf applied at query time, then argpartition top-k
  csc         the same weights as a scipy CSC matrix (docs x vocab); score = sum of the query's columns
Also: the cost of adding / removing one leaf in the postings index, and RRF over full rankings vs top-50 lists.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, "/tmp/claude-0/sm")
from common import Recorder, load_locomo, timeit, np  # noqa: E402
from e1_retriever import BM25, tokens, fuse  # noqa: E402
from bm25lib import Postings  # noqa: E402
import scipy.sparse as sp  # noqa: E402

rec = Recorder(__file__)
chats = load_locomo()
turns = [t for c in chats for t in c["text"].values()]
asks = [q[0] for c in chats for q in c["qs"]]
qtoks = [tokens(a) for a in asks]
rng = np.random.default_rng(0)


def corpus(n):
    out = list(turns[:n])
    while len(out) < n:
        a, b = turns[rng.integers(len(turns))].split(), turns[rng.integers(len(turns))].split()
        out.append(" ".join(a[: len(a) // 2] + b[len(b) // 2:]))
    return [tokens(t) for t in out]


def csc_matrix(p):
    words = list(p.arr); col = {w: j for j, w in enumerate(words)}
    rows = np.concatenate([p.arr[w][0] for w in words]); vals = np.concatenate([p.arr[w][1] for w in words])
    cols = np.concatenate([np.full(len(p.arr[w][0]), j) for j, w in enumerate(words)])
    idf = np.array([math.log(1 + (p.n - len(p.arr[w][0]) + 0.5) / (len(p.arr[w][0]) + 0.5)) for w in words], np.float32)
    m = sp.csc_matrix((vals * idf[cols], (rows, cols)), shape=(p.n, len(words)))
    return m, col


for n in (1_000, 10_000, 100_000):
    docs = corpus(n)
    p = Postings(docs)
    m, col = csc_matrix(p)
    i = [0]

    def nextq():
        i[0] = (i[0] + 1) % len(qtoks)
        return qtoks[i[0]]

    if n <= 10_000:
        bm = BM25({d: docs[d] for d in range(n)})
        rec.add(f"BM25 N={n:.0e}: e1-loop (score every doc in Python + full sort)",
                timeit(lambda: bm.rank(nextq()), repeat=30 if n > 1000 else 100), n=n)
    rec.add(f"BM25 N={n:.0e}: postings + argpartition top-50", timeit(lambda: p.top(nextq()), repeat=300), n=n)

    def csc_top(k=50):
        cols = [col[w] for w in set(nextq()) if w in col]
        s = np.asarray(m[:, cols].sum(axis=1)).ravel()
        sel = np.argpartition(-s, k)[:k]
        return sel[np.argsort(-s[sel])]

    rec.add(f"BM25 N={n:.0e}: scipy CSC column sum + top-50", timeit(csc_top, repeat=300), n=n)
    newdoc = tokens(turns[123])
    j = [0]

    def add_remove():
        k = p.add_doc(newdoc)
        p.remove_doc(k, newdoc); p.n -= 1

    rec.add(f"BM25 N={n:.0e}: add + remove one leaf in postings (write/forget)", timeit(add_remove, repeat=200), n=n)
    if n == 10_000:
        a = list(range(n)); rng.shuffle(a); b = list(range(n)); rng.shuffle(b)
        rec.add("RRF fuse two full rankings of N=1e4 (e1/e5 fuse today)", timeit(lambda: fuse(a, b), repeat=50))
        rec.add("RRF fuse two top-50 lists", timeit(lambda: fuse(a[:50], b[:50]), repeat=2000))
rec.save()
