#!/usr/bin/env python3
"""E1 (docs: small-models research lane): does a small contrastive encoder retrieve LoCoMo evidence better than BM25?

Same data, questions and recall@k as scripts/ai/pyramid_locomo_check.py (flat arm, so BM25 must read 0.563 at 10; the
script exits if it does not). Arms over the same turns:
  bm25      every turn scored by BM25 (the floor)
  dense     cosine of the encoder's vectors
  hybrid    reciprocal rank fusion of bm25 and dense (k=60)
  session   the --sessions best sessions by dense score over their turns' mean vector, then dense over their turns
It prints recall@5/10/20, recall@10 by category, and encode time per turn. Nothing but the public LoCoMo file is read
(CC BY-NC 4.0, downloaded to a temporary folder, sha256 checked, removed after). No Tessera data, no API call.

Usage:
  python3 e1_retriever.py --model hashing                       # no download; plumbing check and a weak dense floor
  python3 e1_retriever.py --model BAAI/bge-small-en-v1.5        # needs: pip install sentence-transformers
  python3 e1_retriever.py --model google/embeddinggemma-300m --query-prefix "task: question answering | query: " \
      --doc-prefix "title: none | text: "
Needs numpy. Models other than "hashing" download from Hugging Face on first use.
"""
import argparse
import collections
import hashlib
import json
import math
import os
import re
import shutil
import sys
import tempfile
import time
import urllib.request

import numpy as np

DATA_URL = "https://raw.githubusercontent.com/snap-research/locomo/3eb6f2c585f5e1699204e3c3bdf7adc5c28cb376/data/locomo10.json"
DATA_SHA256 = "79fa87e90f04081343b8c8debecb80a9a6842b76a7aa537dc9fdf651ea698ff4"
STOP = set("a about am an and are at be been did do does far for how i in is it many me much my of on or so that the to was we were what when you".split())
CATEGORIES = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
FLAT_AT_10 = 0.563


def tokens(text):
    return [w for w in re.split(r"[^a-z0-9]+", text.lower()) if len(w) >= 2 and any(c.isalpha() for c in w) and w not in STOP]


class BM25:
    def __init__(self, docs):
        self.ids = list(docs)
        self.n = len(docs)
        self.len = {i: len(d) for i, d in docs.items()}
        self.avg = sum(self.len.values()) / max(1, self.n)
        self.df = collections.Counter(w for d in docs.values() for w in set(d))
        self.tf = {i: collections.Counter(d) for i, d in docs.items()}

    def rank(self, query):
        def score(doc):
            tf, out = self.tf[doc], 0.0
            for w in set(query):
                if w in tf:
                    idf = math.log(1 + (self.n - self.df[w] + 0.5) / (self.df[w] + 0.5))
                    out += idf * tf[w] * 2.2 / (tf[w] + 1.2 * (0.25 + 0.75 * self.len[doc] / self.avg))
            return out
        return sorted(self.ids, key=lambda d: (-score(d), d))


class Hashing:
    """No-download stand-in: hashed bag of words, L2-normalised. A weak dense floor, not a trained encoder."""
    def __init__(self, dim=1024):
        self.dim = dim

    def encode(self, texts, prefix=""):
        out = np.zeros((len(texts), self.dim), dtype=np.float32)
        for row, text in enumerate(texts):
            for w in tokens(text):
                out[row, int(hashlib.md5(w.encode()).hexdigest(), 16) % self.dim] += 1
        return out / np.maximum(np.linalg.norm(out, axis=1, keepdims=True), 1e-9)


class Sentence:
    def __init__(self, name):
        from sentence_transformers import SentenceTransformer
        self.model = SentenceTransformer(name)

    def encode(self, texts, prefix=""):
        return self.model.encode([prefix + t for t in texts], batch_size=64, normalize_embeddings=True, show_progress_bar=False)


def conversations(path):
    for sample in json.load(open(path)):
        turns, session = {}, {}
        for name, value in sample["conversation"].items():
            if name.startswith("session_") and isinstance(value, list):
                for turn in value:
                    caption = turn.get("blip_caption")
                    turns[turn["dia_id"]] = f"{turn['speaker']}: {turn['text']}" + (f" {caption}" if caption else "")
                    session[turn["dia_id"]] = name
        yield turns, session, [q for q in sample["qa"] if q["category"] != 5 and q.get("evidence")]


def fuse(*rankings, k=60):
    score = collections.defaultdict(float)
    for order in rankings:
        for place, doc in enumerate(order):
            score[doc] += 1 / (k + place + 1)
    return sorted(score, key=lambda d: (-score[d], d))


def run(args):
    encoder = Hashing() if args.model == "hashing" else Sentence(args.model)
    arms = ("bm25", "dense", "hybrid", "session")
    ks = (5, 10, 20)
    total, asked, encoded, spent = collections.defaultdict(float), 0, 0, 0.0
    for turns, session, questions in conversations(args.data):
        ids = list(turns)
        docs = {d: tokens(turns[d]) for d in ids}
        bm25 = BM25(docs)
        start = time.time()
        vectors = encoder.encode([turns[d] for d in ids], args.doc_prefix)
        spent += time.time() - start
        encoded += len(ids)
        row = {d: i for i, d in enumerate(ids)}
        by_session = collections.defaultdict(list)
        for d in ids:
            by_session[session[d]].append(d)
        names = list(by_session)
        centers = np.stack([vectors[[row[d] for d in by_session[s]]].mean(axis=0) for s in names])
        queries = encoder.encode([q["question"] for q in questions], args.query_prefix)
        for question, qv in zip(questions, queries):
            evidence = {e.strip() for e in question["evidence"]} & set(turns)
            if not evidence:
                continue
            asked += 1
            lexical = bm25.rank(tokens(question["question"]))
            sims = vectors @ qv
            dense = [ids[i] for i in np.argsort(-sims, kind="stable")]
            top = [names[i] for i in np.argsort(-(centers @ qv), kind="stable")[: args.sessions]]
            pool = [d for s in top for d in by_session[s]]
            inside = sorted(pool, key=lambda d: (-sims[row[d]], d))
            ranked = {"bm25": lexical, "dense": dense, "hybrid": fuse(lexical, dense), "session": inside}
            category = question["category"]
            total[f"n{category}"] += 1
            for arm, order in ranked.items():
                for k in ks:
                    total[f"{arm}@{k}"] += len(evidence & set(order[:k])) / len(evidence)
                total[f"{arm}@10 c{category}"] += len(evidence & set(order[:10])) / len(evidence)
    base = total["bm25@10"] / asked
    print(f"{asked} questions, model {args.model}, encode {1000 * spent / encoded:.1f} ms per turn")
    for k in ks:
        print(f"recall@{k:<2}  " + "  ".join(f"{a} {total[f'{a}@{k}'] / asked:.3f}" for a in arms))
    for category, name in CATEGORIES.items():
        count = total[f"n{category}"]
        print(f"  @10 {name} ({count:.0f})  " + "  ".join(f"{a} {total[f'{a}@10 c{category}'] / count:.3f}" for a in arms))
    if abs(base - FLAT_AT_10) > 0.002:
        sys.exit(f"bm25 recall@10 is {base:.3f}, expected {FLAT_AT_10}: this is not the same data or tokens as #1482")
    print("bm25 matches the #1482 flat baseline (0.563)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--model", default="hashing")
    p.add_argument("--query-prefix", default="")
    p.add_argument("--doc-prefix", default="")
    p.add_argument("--sessions", type=int, default=3)
    p.add_argument("--data")
    args = p.parse_args()
    folder = None
    try:
        if not args.data:
            folder = tempfile.mkdtemp(prefix="locomo-")
            args.data = os.path.join(folder, "locomo10.json")
            urllib.request.urlretrieve(DATA_URL, args.data)
        digest = hashlib.sha256(open(args.data, "rb").read()).hexdigest()
        if digest != DATA_SHA256:
            sys.exit(f"sha256 {digest}, expected {DATA_SHA256}")
        run(args)
    finally:
        if folder:
            shutil.rmtree(folder, ignore_errors=True)


if __name__ == "__main__":
    main()
