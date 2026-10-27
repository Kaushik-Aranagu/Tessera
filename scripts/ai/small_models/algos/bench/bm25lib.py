"""Postings-list BM25 shared by b4_bm25.py and b7_paths.py (precomputed tf-norm weights, idf at query time)."""
import collections
import math

import numpy as np


class Postings:
    def __init__(self, docs, k1=1.2, b=0.75):
        self.k1, self.b = k1, b
        self.n = len(docs)
        self.lens = np.array([len(d) for d in docs], np.float32)
        self.avg = float(self.lens.mean())
        self.vocab, self.post = {}, collections.defaultdict(lambda: ([], []))
        for i, d in enumerate(docs):
            self._add(i, d)
        self.freeze()

    def _add(self, i, d):
        for w, tf in collections.Counter(d).items():
            ids, wts = self.post[w]
            ids.append(i)
            wts.append(tf * (self.k1 + 1) / (tf + self.k1 * (1 - self.b + self.b * len(d) / self.avg)))

    def freeze(self):
        self.arr = {w: (np.asarray(ids, np.int32), np.asarray(wts, np.float32)) for w, (ids, wts) in self.post.items()}

    def add_doc(self, d):  # write path: append postings, avgdl left stale until the nightly rebuild
        i = self.n; self.n += 1
        for w, tf in collections.Counter(d).items():
            ids, wts = self.arr.get(w, (np.empty(0, np.int32), np.empty(0, np.float32)))
            wt = tf * (self.k1 + 1) / (tf + self.k1 * (1 - self.b + self.b * len(d) / self.avg))
            self.arr[w] = (np.append(ids, i), np.append(wts, np.float32(wt)))
        return i

    def remove_doc(self, i, d):  # forget path: drop the doc's postings (tombstone-free)
        for w in set(d):
            ids, wts = self.arr[w]
            keep = ids != i
            self.arr[w] = (ids[keep], wts[keep])

    def top(self, q, k=50):
        acc = np.zeros(self.n, np.float32)
        for w in set(q):
            if w in self.arr:
                ids, wts = self.arr[w]
                idf = math.log(1 + (self.n - len(ids) + 0.5) / (len(ids) + 0.5))
                np.add.at(acc, ids, idf * wts)
        k = min(k, self.n - 1)
        sel = np.argpartition(-acc, k)[:k]
        return sel[np.argsort(-acc[sel])]
