import sys, numpy as np
sys.path.insert(0, "/tmp/claude-0/sm/dyn-pyramid"); sys.path.insert(0, "/tmp/claude-0/sm")
import e8_pyramid_encoder as E
from e5_bridges import bm25_rank, fuse, tokens
chats = E.load_tree("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5", "/tmp/claude-0/sm/dyn-pyramid/cache")
mism_bm = mism_fuse = tot = 0; r0 = []
for c in chats:
    idx = E.BM25Index(); pos = {d: i for i, d in enumerate(c["ids"])}
    for i, d in enumerate(c["ids"]): idx.add(d, c["docs"][i])
    docs = {d: c["docs"][i] for i, d in enumerate(c["ids"])}
    for qi, (q, ev, cat) in enumerate(c["qs"]):
        ref = bm25_rank(docs, c["ids"], tokens(q))
        mine = [c["ids"][j] for j in np.lexsort((c["strrank"], -idx.scores(tokens(q), pos, len(c["ids"]))))]
        mism_bm += ref != mine; tot += 1
        dense = [c["ids"][j] for j in np.argsort(-(c["nodes"] @ c["asks"][qi]), kind="stable")]
        f_ref = fuse(ref, dense)
        f_mine = [c["ids"][j] for j in E.fuse_np([np.array([pos[d] for d in ref]), np.array([pos[d] for d in dense])], len(c["ids"]), c["strrank"])]
        mism_fuse += f_ref != f_mine
        r0.append(len(set(ref[:10]) & {c["ids"][e] for e in ev}) / len(ev))
print(f"questions {tot}; bm25 order mismatches vs e5.bm25_rank {mism_bm}; fuse mismatches vs e5.fuse {mism_fuse}; R0 via e5.bm25_rank {np.mean(r0):.4f}")
