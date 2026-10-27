#!/usr/bin/env python3
"""E7: do bridges trained on LoCoMo carry over to a different benchmark? LongMemEval-S (public, no Tessera data).

Bridges (CLM-style state and action heads on a frozen encoder, as in e5_bridges.py) are trained on all ten LoCoMo
chats, then used unchanged on LongMemEval-S. The memory plane for each question is its own haystack's user turns
(LongMemEval's evidence turns are marked has_answer, and 94% of them are user turns; questions whose evidence is only
in assistant turns are left out). Arms: bm25, frozen, bridged (full heads), bridged-lowrank (identity plus rank-16),
and each fused with bm25. Prints turn recall@5/10 and session recall@5 by question type.
Usage: python3 e7_longmemeval.py --lme longmemeval_s_cleaned.json --locomo locomo10.json [--cache emb.npz]
"""
import argparse, collections, hashlib, json, os, sys
import numpy as np
import torch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from e5_bridges import load, train, tokens, bm25_rank, fuse  # noqa: E402


def recall(order, ev, k):
    return len(set(order[:k]) & ev) / len(ev)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--lme", required=True); p.add_argument("--locomo", required=True)
    p.add_argument("--model", default="BAAI/bge-small-en-v1.5"); p.add_argument("--cache", default="lme_emb.npz")
    p.add_argument("--epochs", type=int, default=40)
    a = p.parse_args()
    from sentence_transformers import SentenceTransformer
    enc = SentenceTransformer(a.model)
    data = json.load(open(a.lme))
    texts = sorted({t["content"] for x in data for s in x["haystack_sessions"] for t in s if t["role"] == "user"})
    index = {t: i for i, t in enumerate(texts)}
    if os.path.exists(a.cache):
        vec = np.load(a.cache)["v"]
    else:
        vec = enc.encode(texts, normalize_embeddings=True, batch_size=128, show_progress_bar=False)
        np.savez(a.cache, v=vec)
    chats = load(a.locomo, a.model)
    dim = vec.shape[1]
    heads = {"bridged": train(chats, dim, a.epochs, 0), "bridged-lowrank": train(chats, dim, a.epochs, 0, rank=16)}
    with torch.no_grad():
        keys = {n: b.a(torch.tensor(vec)).numpy() for n, b in heads.items()}
    tot = collections.defaultdict(float); count = collections.Counter(); used = 0
    for x in data:
        rows, sess, ev = [], [], set()
        for sid, s in zip(x["haystack_session_ids"], x["haystack_sessions"]):
            for t in s:
                if t["role"] != "user":
                    continue
                if t.get("has_answer"):
                    ev.add(len(rows))
                rows.append(index[t["content"]]); sess.append(sid)
        if not ev:
            continue
        used += 1; kind = x["question_type"]; count[kind] += 1
        evs = {sess[i] for i in ev}
        q = enc.encode([x["question"]], normalize_embeddings=True)[0]
        ids = list(range(len(rows)))
        docs = {i: tokens(texts[rows[i]]) for i in ids}
        lex = bm25_rank(docs, ids, tokens(x["question"]))
        orders = {"bm25": lex, "frozen": list(np.argsort(-(vec[rows] @ q), kind="stable"))}
        with torch.no_grad():
            for n, b in heads.items():
                s = b.s(torch.tensor(q[None])).numpy()[0]
                orders[n] = list(np.argsort(-(keys[n][rows] @ s), kind="stable"))
        for n in ("frozen", "bridged", "bridged-lowrank"):
            orders[n + "+hybrid"] = fuse(lex, orders[n])
        for n, o in orders.items():
            for k in (5, 10):
                r = recall(o, ev, k); tot[f"{n}@{k}"] += r; tot[f"{n}@{k} {kind}"] += r
            seen = []
            for i in o:
                if sess[i] not in seen:
                    seen.append(sess[i])
            tot[f"{n} s@5"] += len(set(seen[:5]) & evs) / len(evs)
    print(f"{used} LongMemEval-S questions (user-turn evidence), bridges trained on LoCoMo only, model {a.model}")
    for n in orders:
        print(f"  {n:<24} turn@5 {tot[n + '@5'] / used:.3f}  turn@10 {tot[n + '@10'] / used:.3f}  session@5 {tot[n + ' s@5'] / used:.3f}")
    print("  turn@10 by type:")
    for kind in sorted(count):
        print(f"    {kind:<26} ({count[kind]:>3}) " + "  ".join(f"{n} {tot[f'{n}@10 {kind}'] / count[kind]:.3f}" for n in ("bm25", "frozen+hybrid", "bridged+hybrid", "bridged-lowrank+hybrid")))


if __name__ == "__main__":
    main()
