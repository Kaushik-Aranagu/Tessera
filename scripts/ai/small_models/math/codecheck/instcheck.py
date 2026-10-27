"""Does the frozen baseline use bge-small-en-v1.5 as intended? e5.load() encodes asks without BGE's recommended
query instruction. Re-encode asks (a) exactly as e5 does (must match the cache) and (b) with the instruction;
compare frozen recall@10 and rank-16 bridged recall@10 (5 folds, e5 train() unmodified) on held-out chats.
"""
import sys, json, pickle, copy
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
import e5_bridges as E  # noqa: E402
from sentence_transformers import SentenceTransformer

torch.set_num_threads(1)
D = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
enc = SentenceTransformer("BAAI/bge-small-en-v1.5", device="cpu")
INST = "Represent this sentence for searching relevant passages: "
out = {}
plain_err = 0.0
DI = []
for c in D:
    qs = [q for q, _, _ in c["qs"]]
    a0 = enc.encode(qs, normalize_embeddings=True, batch_size=64)
    plain_err = max(plain_err, float(np.abs(a0 - c["asks"]).max()))
    ci = dict(c); ci["asks"] = enc.encode([INST + q for q in qs], normalize_embeddings=True, batch_size=64)
    DI.append(ci)
out["re-encoded plain asks vs cache maxabs"] = plain_err


def frozen(data):
    xs = []
    for c in data:
        for r, (_, ev, _) in enumerate(c["qs"]):
            xs.append(E.recall(list(np.argsort(-(c["nodes"] @ c["asks"][r]), kind="stable")), ev))
    return np.array(xs)


def bridged(data):
    xs = []
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        b = E.train([c for i, c in enumerate(data) if i not in test], 384, 40, fold, rank=16)
        with torch.no_grad():
            for i in sorted(test):
                c = data[i]
                K = b.a(torch.tensor(c["nodes"])).numpy(); S = b.s(torch.tensor(c["asks"])).numpy()
                for r, (_, ev, _) in enumerate(c["qs"]):
                    xs.append(E.recall(list(np.argsort(-(K @ S[r]), kind="stable")), ev))
    return np.array(xs)


rng = np.random.default_rng(0)


def ci(d):
    bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
    return [float(d.mean()), float(np.percentile(bs, 2.5)), float(np.percentile(bs, 97.5))]


f0, f1 = frozen(D), frozen(DI)
b0, b1 = bridged(D), bridged(DI)
out["frozen plain"] = float(f0.mean()); out["frozen +instruction"] = float(f1.mean()); out["frozen inst - plain"] = ci(f1 - f0)
out["bridged r16 plain"] = float(b0.mean()); out["bridged r16 +instruction"] = float(b1.mean()); out["bridged inst - plain"] = ci(b1 - b0)
out["bridge gain plain (bridged - frozen)"] = ci(b0 - f0); out["bridge gain with instruction"] = ci(b1 - f1)
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/codecheck/instcheck.json", "w"), indent=1)
