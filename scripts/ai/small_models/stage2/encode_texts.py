#!/usr/bin/env python3
"""Encode the stage 1 texts with another frozen encoder, in resumable shards (stage 2, test 2.2).

Sets: "locomo" (every chat's turn texts, then its questions, in common.load_locomo order) and "lme" (the unique
LongMemEval-S user turns referenced by the 428 kept questions, in common.load_lme's sorted order, then the 428
questions). Turns get no prompt; questions get the encoder's query prompt (none for the bge family, the stored "query"
prompt for Qwen3-Embedding). fp32, max sequence 512 for every encoder, unit vectors.

Output: $STAGE2_CACHE/enc/<tag>/<set>_<shard>.npy (4,000 texts each) and, when all shards exist, <set>.npz with
rows (index into the set's text list) and v (float32). Re-running skips finished shards.
"""
import argparse, json, os, sys, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "stage1"))
import common as C  # noqa: E402

CACHE = os.environ.get("STAGE2_CACHE", "/tmp/claude-0/stage2")
MODELS = {"bge-small": ("BAAI/bge-small-en-v1.5", None), "bge-base": ("BAAI/bge-base-en-v1.5", None),
          "qwen3-emb-0.6b": ("Qwen/Qwen3-Embedding-0.6B", "query")}
SHARD = 4000


def texts_of(which):
    if which == "locomo":
        chats = C.load_locomo()
        turns = [t for c in chats for t in c["text"]]
        qs = [q[0] for c in chats for q in c["qs"]]
        return turns, qs
    items, texts, _ = C.load_lme()
    rows = sorted({int(r) for it in items for r in it["rows"]})
    return [texts[r] for r in rows], [it["question"] for it in items], rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=sorted(MODELS), required=True)
    ap.add_argument("--set", choices=["locomo", "lme"], required=True)
    ap.add_argument("--threads", type=int, default=3)
    ap.add_argument("--max-seconds", type=float, default=6600, help="stop cleanly after this many seconds")
    a = ap.parse_args()
    import torch
    torch.set_num_threads(a.threads)
    from sentence_transformers import SentenceTransformer
    name, qprompt = MODELS[a.model]
    out = os.path.join(CACHE, "enc", a.model); os.makedirs(out, exist_ok=True)
    got = texts_of(a.set)
    docs, qs = got[0], got[1]
    rows = got[2] if a.set == "lme" else list(range(len(docs)))
    model = SentenceTransformer(name, device="cpu", model_kwargs={"dtype": torch.float32})
    model.max_seq_length = 512
    t0 = time.time(); n = (len(docs) + SHARD - 1) // SHARD
    for s in range(n):
        f = os.path.join(out, f"{a.set}_{s:03d}.npy")
        if os.path.exists(f):
            continue
        if time.time() - t0 > a.max_seconds:
            print("time limit; re-run to continue", flush=True); return
        v = model.encode(docs[s * SHARD:(s + 1) * SHARD], normalize_embeddings=True, batch_size=32)
        np.save(f + ".tmp.npy", v.astype(np.float32)); os.replace(f + ".tmp.npy", f)
        print(f"{a.model} {a.set} shard {s + 1}/{n} ({time.time() - t0:.0f}s)", flush=True)
    fq = os.path.join(out, f"{a.set}_q.npy")
    if not os.path.exists(fq):
        kw = {"prompt_name": qprompt} if qprompt else {}
        np.save(fq, model.encode(qs, normalize_embeddings=True, batch_size=32, **kw).astype(np.float32))
    v = np.concatenate([np.load(os.path.join(out, f"{a.set}_{s:03d}.npy")) for s in range(n)])
    assert len(v) == len(docs)
    np.savez(os.path.join(out, f"{a.set}.npz"), rows=np.asarray(rows), v=v, q=np.load(fq), model=name,
             qprompt=str(qprompt), max_seq=512)
    print(f"done {a.model} {a.set}: {v.shape} ({time.time() - t0:.0f}s)", flush=True)


if __name__ == "__main__":
    main()
