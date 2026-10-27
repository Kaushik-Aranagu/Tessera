#!/usr/bin/env python3
"""B1: frozen encoder cost (bge-small-en-v1.5, 33M params, 384-d) on one CPU thread.

Measures: one short ask (single item, not batched) end to end through sentence-transformers; the same split into
tokenizer and transformer forward; forward cost by input length (the read-again loop re-encodes a longer state);
per-leaf cost batched (64 LoCoMo turns) and unbatched; dynamic int8 and bf16 variants with fidelity to fp32.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Recorder, load_locomo, timeit, torch, np  # noqa: E402

os.environ.setdefault("HF_HUB_OFFLINE", "1")
from sentence_transformers import SentenceTransformer  # noqa: E402

rec = Recorder(__file__)
chats = load_locomo()
turns = [t for c in chats for t in c["text"].values()]
asks = [q[0] for c in chats for q in c["qs"]]
model = SentenceTransformer("BAAI/bge-small-en-v1.5", device="cpu")
model.eval()
tok, bert = model.tokenizer, model[0].auto_model
print(f"threads={torch.get_num_threads()}  params={sum(p.numel() for p in bert.parameters()) / 1e6:.1f}M")

ask = asks[0]  # 'When did Caroline go to the LGBTQ support group?'
ntok = len(tok(ask)["input_ids"])
rec.add(f"encode 1 ask, sentence-transformers end to end ({ntok} tokens)",
        timeit(lambda: model.encode([ask], normalize_embeddings=True, show_progress_bar=False), repeat=100))
i = [0]


def many_asks():
    i[0] = (i[0] + 1) % len(asks)
    model.encode([asks[i[0]]], normalize_embeddings=True, show_progress_bar=False)


rec.add("encode 1 ask, rotating over 1531 LoCoMo asks (median ~10 words)", timeit(many_asks, repeat=300))
rec.add("tokenizer only, 1 ask", timeit(lambda: tok([ask], return_tensors="pt"), repeat=200))
with torch.inference_mode():
    for L in (16, 32, 64, 128, 256, 512):
        ids = torch.randint(1000, 20000, (1, L)); ids[0, 0] = 101; ids[0, -1] = 102
        mask = torch.ones_like(ids)
        rec.add(f"transformer forward only, 1 sequence of {L} tokens",
                timeit(lambda: bert(input_ids=ids, attention_mask=mask), repeat=40 if L <= 128 else 15), tokens=L)

# per leaf, batched like ingestion (sentence-transformers sorts by length and pads per batch)
sample = turns[:640]
ms = timeit(lambda: model.encode(sample, batch_size=64, normalize_embeddings=True, show_progress_bar=False),
            repeat=5, warmup=1)
rec.add("encode 640 LoCoMo turns, batch 64 -> per leaf", [m / len(sample) for m in ms], note="per-leaf ms")
j = [0]


def one_leaf():
    j[0] = (j[0] + 1) % len(turns)
    model.encode([turns[j[0]]], normalize_embeddings=True, show_progress_bar=False)


rec.add("encode 1 LoCoMo turn unbatched (write path), rotating", timeit(one_leaf, repeat=300))

# int8 dynamic quantization of all Linear layers (fbgemm/x86) and bf16 autocast: speed and fidelity
ref = model.encode(turns[:300] + asks[:300], normalize_embeddings=True, show_progress_bar=False, batch_size=64)
c0 = chats[0]
nodes0 = list(c0["text"].values()); asks0 = [q[0] for q in c0["qs"]]


def top10_overlap(enc_nodes, enc_asks, ref_nodes, ref_asks):
    a = np.argsort(-(enc_asks @ enc_nodes.T), axis=1)[:, :10]
    b = np.argsort(-(ref_asks @ ref_nodes.T), axis=1)[:, :10]
    return float(np.mean([len(set(x) & set(y)) / 10 for x, y in zip(a, b)]))


rn = model.encode(nodes0, normalize_embeddings=True, show_progress_bar=False, batch_size=64)
ra = model.encode(asks0, normalize_embeddings=True, show_progress_bar=False, batch_size=64)
qmodel = torch.ao.quantization.quantize_dynamic(SentenceTransformer("BAAI/bge-small-en-v1.5", device="cpu"),
                                                {torch.nn.Linear}, dtype=torch.qint8)
nq = sum(1 for m in qmodel.modules() if "quantized" in type(m).__module__)
print(f"int8: {nq} quantized Linear modules")
assert nq > 0
qv = qmodel.encode(turns[:300] + asks[:300], normalize_embeddings=True, show_progress_bar=False, batch_size=64)
cos = float(np.mean(np.sum(qv * ref, 1)))
ov = top10_overlap(qmodel.encode(nodes0, normalize_embeddings=True, show_progress_bar=False, batch_size=64),
                   qmodel.encode(asks0, normalize_embeddings=True, show_progress_bar=False, batch_size=64), rn, ra)
rec.add("encode 1 ask, int8 dynamic-quantized Linear layers",
        timeit(lambda: qmodel.encode([ask], normalize_embeddings=True, show_progress_bar=False), repeat=100),
        note=f"mean cos to fp32 {cos:.4f}; top-10 overlap on chat 0 {ov:.3f}", cos_to_fp32=cos, top10_overlap=ov)
ms = timeit(lambda: qmodel.encode(sample, batch_size=64, normalize_embeddings=True, show_progress_bar=False),
            repeat=5, warmup=1)
rec.add("encode 640 turns batch 64, int8 dynamic -> per leaf", [m / len(sample) for m in ms], note="per-leaf ms")


def bf16(texts, bs=64):
    with torch.autocast("cpu", dtype=torch.bfloat16):
        return model.encode(texts, normalize_embeddings=True, show_progress_bar=False, batch_size=bs)


bv = bf16(turns[:300] + asks[:300]).astype(np.float32)
cosb = float(np.mean(np.sum(bv * ref, 1) / np.linalg.norm(bv, axis=1)))
rec.add("encode 1 ask, bf16 autocast (AMX on this CPU)", timeit(lambda: bf16([ask]), repeat=100),
        note=f"mean cos to fp32 {cosb:.4f}", cos_to_fp32=cosb)
ms = timeit(lambda: bf16(sample), repeat=5, warmup=1)
rec.add("encode 640 turns batch 64, bf16 autocast -> per leaf", [m / len(sample) for m in ms], note="per-leaf ms")
# A 4-thread reference run was tried and dropped: the CPUs are shared, so it was oversubscribed (~1 s per ask).
rec.save()
