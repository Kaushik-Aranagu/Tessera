#!/usr/bin/env python3
"""E8: one shared internode encoder over a LoCoMo session pyramid (public data only, CPU, no API call, no Tessera data).

Claim under test. A parent embedding computed from its children by ONE shared learned encoder (UpEncoder: spherical
k-means seeds plus one 4-head attention block, ~100k weights), trained jointly with low-rank bridges:
  (i)   beats mean pooling and matches or beats BM25 session choice, with the inside ranker held fixed;
  (ii)  adds recall when fused with the flat leaf bridge, at least on multi-hop;
  (iii) stays exact and about as useful under streaming inserts, forgetting and merges, with no retraining;
  (iv)  survives a weight update by a cheap full recompute of derived vectors only.
Also reported: whether learned slots beat the exact, non-learned late-pooled score (S5).

Tree per chat: leaves = turns (bge-small vectors, frozen), level 1 = sessions, level 2 = a root over all session slot
rows (never scored; it exists to test path propagation and deletion). Hashes: leaf = HMAC-SHA256(device key, dia_id ||
text) with a random per-run key; node = SHA256(level || weight version || sorted child hashes). Each pyramid keeps a
cache {hash: K} that holds only reachable entries.

Two code paths for the up-encoder: a padded torch batch (training only) and encode_parent, the canonical per-node fp32
path (a numpy export of the weights, as a device would run it), used for every evaluation and every dynamic test.

Folds: fold f tests chats {2f, 2f+1} and trains on the other 8 (never on a test chat). Variants per fold:
  R2  e5.train(rank=16, seed=f): leaf-only low-rank bridges, the comparator for every CI
  V1  joint bridges + UpEncoder, structure augmentation on          V2  V1 + L_heap
  V3  V1 without augmentation (inductive merge test)                V1' V1 with seed f+1000 (weight-update test)
Arms, dynamic tests (a)-(d), statistics and pass lines P0-P5 follow the E8 spec; see the printed report.

Usage: python -I e8_pyramid_encoder.py --data locomo10.json [--model BAAI/bge-small-en-v1.5] [--epochs 40]
       [--cache-dir DIR] [--out results.json] [--quick] [--workers N]
Needs numpy, torch (CPU) and sentence-transformers. bge vectors are cached to <cache-dir>, never inside the repo.
Exits non-zero if any exactness assertion fails or the P0 reproductions miss.
"""
import argparse, collections, hashlib, hmac, json, math, os, re, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
for _p in (HERE, os.path.dirname(HERE), "/tmp/claude-0/sm"):
    if os.path.exists(os.path.join(_p, "e5_bridges.py")):
        sys.path.insert(0, _p)
        break

import numpy as np  # noqa: E402
import torch  # noqa: E402
import torch.nn.functional as F  # noqa: E402
from e5_bridges import SHA, Bridge, LowRank, bm25_rank, fuse, tokens  # noqa: E402,F401
from e5_bridges import train as e5_train  # noqa: E402

DIM = 384
CATS = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
TOL = {"R0": (0.563, 0.002), "R1": (0.575, 0.005), "R2": (0.657, 0.01), "S0": (0.649, 0.005), "S1": (0.386, 0.005)}
ALL_ARMS = ["R0", "R1", "R2", "R3", "R4", "S0", "S1", "S1h", "S2", "S3", "S4", "S5", "S6", "S6h", "S6a", "S7",
            "H1", "H2", "H2-lse", "H2(l=0.5)", "H2(l=2)"]
S_ARMS = ["S0", "S1", "S1h", "S2", "S3", "S4", "S5", "S6", "S6h", "S6a", "S7"]
H_ARMS = ["H1", "H2", "H2-lse", "H2(l=0.5)", "H2(l=2)"]
DYN_ARMS = ["R2", "R3", "S2", "S3", "S4", "S5", "S6", "S6a", "S7", "H1", "H2", "H2-lse"]
TAU_GRID, BETA_GRID = (0.02, 0.05, 0.1), (0.0, 0.5, 1.0)
BGE_CALLS = [0]
FAILS = []


def check(ok, what):
    if not ok:
        FAILS.append(what)
        print(f"  EXACTNESS FAIL: {what}", flush=True)
    return bool(ok)


# ----------------------------------------------------------------------------------------------------------- data
def load_tree(path, model, cache_dir):
    raw = open(path, "rb").read()
    sha = hashlib.sha256(raw).hexdigest()
    if sha != SHA:
        sys.exit(f"sha256 {sha}: not the pinned LoCoMo file")
    chats = []
    for cid, sample in enumerate(json.loads(raw)):
        conv = sample["conversation"]
        sess = sorted((int(k.split("_")[1]), k) for k, v in conv.items() if re.fullmatch(r"session_\d+", k) and isinstance(v, list))
        ids, text, snum = [], [], []
        for num, k in sess:
            for t in conv[k]:
                cap = t.get("blip_caption")
                ids.append(t["dia_id"]); text.append(f"{t['speaker']}: {t['text']}" + (f" {cap}" if cap else "")); snum.append(num)
        assert len(set(ids)) == len(ids), "duplicate dia_id"
        index = {d: i for i, d in enumerate(ids)}
        qs = []
        for q in sample["qa"]:
            if q["category"] == 5 or not q.get("evidence"):
                continue
            ev = [index[e.strip()] for e in q["evidence"] if e.strip() in index]
            if ev:
                qs.append((q["question"], sorted(set(ev)), q["category"]))
        sessions = [(f"session_{num}", [i for i in range(len(ids)) if snum[i] == num]) for num, _ in sess]
        strrank = np.empty(len(ids), np.int64); strrank[sorted(range(len(ids)), key=ids.__getitem__)] = np.arange(len(ids))
        chats.append(dict(cid=cid, ids=ids, text=text, docs=[tokens(t) for t in text], snum=snum, index=index, qs=qs,
                          sessions=sessions, strrank=strrank, qtok=[tokens(q[0]) for q in qs],
                          lastsess=[max(snum[e] for e in ev) for _, ev, _ in qs]))
    os.makedirs(cache_dir, exist_ok=True)
    fname = os.path.join(cache_dir, f"locomo_{sha[:12]}_{model.replace('/', '_')}.npz")
    if os.path.exists(fname):
        z = np.load(fname)
        for c in chats:
            c["nodes"], c["asks"] = z[f"n{c['cid']}"], z[f"a{c['cid']}"]
            assert c["nodes"].shape[0] == len(c["ids"]) and c["asks"].shape[0] == len(c["qs"])
        print(f"bge vectors from cache {fname}", flush=True)
    else:
        from sentence_transformers import SentenceTransformer
        threads = torch.get_num_threads(); torch.set_num_threads(max(2, threads))
        enc = SentenceTransformer(model); t0 = time.time(); out = {}
        for c in chats:  # same calls as e5.load: per chat, batch 64, unit norm
            c["nodes"] = enc.encode(c["text"], normalize_embeddings=True, batch_size=64, show_progress_bar=False).astype(np.float32)
            c["asks"] = enc.encode([q[0] for q in c["qs"]], normalize_embeddings=True, batch_size=64, show_progress_bar=False).astype(np.float32)
            BGE_CALLS[0] += len(c["text"]) + len(c["qs"])
            out[f"n{c['cid']}"], out[f"a{c['cid']}"] = c["nodes"], c["asks"]
        np.savez(fname, **out)
        torch.set_num_threads(threads)
        print(f"bge encode {time.time() - t0:.0f}s, cached to {fname}", flush=True)
    return chats


# ------------------------------------------------------------------------------------------------------------ BM25
class BM25Index:
    """Incremental BM25 (same formula as e5.bm25_rank / e1.BM25): add and remove keep tf, df, N and total length
    exact, so the statistics after any sequence of forgets equal a fresh build over the survivors."""

    def __init__(self):
        self.tf, self.ln, self.df, self.post, self.total = {}, {}, collections.Counter(), collections.defaultdict(set), 0

    def add(self, d, toks):
        self.tf[d] = collections.Counter(toks); self.ln[d] = len(toks); self.total += len(toks)
        for w in self.tf[d]:
            self.df[w] += 1; self.post[w].add(d)

    def remove(self, d):
        for w in self.tf[d]:
            self.df[w] -= 1; self.post[w].discard(d)
            if not self.df[w]:
                del self.df[w]; del self.post[w]
        self.total -= self.ln.pop(d); del self.tf[d]

    def stats(self):
        return len(self.tf), self.total, dict(self.df), {d: dict(c) for d, c in self.tf.items()}

    def scores(self, toks, pos, n):
        N = len(self.tf); avg = self.total / N; out = np.zeros(n)
        for w in sorted(set(toks)):
            df = self.df.get(w)
            if not df:
                continue
            idf = math.log(1 + (N - df + 0.5) / (df + 0.5))
            for d in self.post[w]:
                f = self.tf[d][w]
                out[pos[d]] += idf * f * 2.2 / (f + 1.2 * (0.25 + 0.75 * self.ln[d] / avg))
        return out


def fuse_np(orders, n, tie):
    """e5/e1 fuse (RRF k=60) with ties broken by `tie` (dia_id string rank): same float sums, same order."""
    sc = np.zeros(n); present = np.zeros(n, bool)
    for o in orders:
        sc[o] += 1.0 / (61.0 + np.arange(len(o))); present[o] = True
    items = np.nonzero(present)[0]
    return items[np.lexsort((tie[items], -sc[items]))]


def glse(Z, starts):
    """Row-wise log-sum-exp over column groups [starts[i], starts[i+1])."""
    mx = np.maximum.reduceat(Z, starts, axis=1)
    owner = np.repeat(np.arange(len(starts)), np.diff(np.r_[starts, Z.shape[1]]))
    return mx + np.log(np.add.reduceat(np.exp(Z - mx[:, owner]), starts, axis=1))


# ----------------------------------------------------------------------------------------------------------- model
class UpEncoder(torch.nn.Module):
    """One module for every parent at every level: k-means seeds B (m = min(4, n), 8 at the root), one MAB with 4 heads
    of 16: K_p = rownorm(B + concat_h(softmax((B + e_level) W_Q (X W_K)^T / 4) X W_V) W_O). W_O and e_level start at 0."""

    def __init__(self, dim=DIM, heads=4, hd=16, levels=3):
        super().__init__()
        self.h, self.hd = heads, hd
        self.q = torch.nn.Linear(dim, heads * hd, bias=False)
        self.k = torch.nn.Linear(dim, heads * hd, bias=False)
        self.v = torch.nn.Linear(dim, heads * hd, bias=False)
        self.o = torch.nn.Linear(heads * hd, dim, bias=False)
        torch.nn.init.zeros_(self.o.weight)
        self.e = torch.nn.Parameter(torch.zeros(levels, dim))

    def batch(self, X, mask, mcap, level, seeds_only=False):
        """Padded batch path (training only). X: P x N x D (padding rows zero), mask: P x N."""
        P, N, D = X.shape
        m = mask.sum(1).clamp(max=mcap); M = int(m.max())
        slot = torch.arange(M)[None] < m[:, None]
        ar = torch.arange(P)
        with torch.no_grad():
            Xd = X.detach()
            mu = (Xd * mask[..., None]).sum(1)
            c = torch.einsum("pnd,pd->pn", Xd, mu).masked_fill(~mask, float("-inf")).argmax(1)
            chosen = [c]; taken = torch.zeros(P, N, dtype=torch.bool); taken[ar, c] = True
            mx = torch.einsum("pnd,pd->pn", Xd, Xd[ar, c])
            for _ in range(1, M):
                j = mx.masked_fill(~mask | taken, float("inf")).argmin(1)
                chosen.append(j); taken[ar, j] = True
                mx = torch.maximum(mx, torch.einsum("pnd,pd->pn", Xd, Xd[ar, j]))
            idx = torch.stack(chosen, 1)
        C = X[ar[:, None], idx]
        for _ in range(3):
            with torch.no_grad():
                sims = torch.einsum("pnd,pmd->pnm", Xd, C.detach()).masked_fill(~slot[:, None, :], float("-inf"))
                oh = F.one_hot(sims.argmax(2), M).to(X.dtype) * mask[..., None]
                cnt = oh.sum(1)
            C = torch.where((cnt > 0)[..., None], F.normalize(torch.einsum("pnm,pnd->pmd", oh, X), dim=-1), C)
        if seeds_only:  # S4: W_O forced to 0 (diagnostics only)
            return F.normalize(C, dim=-1), slot
        Qh =self.q(C + self.e[level]).view(P, M, self.h, self.hd).transpose(1, 2)
        Kh = self.k(X).view(P, N, self.h, self.hd).transpose(1, 2)
        Vh = self.v(X).view(P, N, self.h, self.hd).transpose(1, 2)
        att = (Qh @ Kh.transpose(-1, -2) / math.sqrt(self.hd)).masked_fill(~mask[:, None, None, :], float("-inf")).softmax(-1)
        H = (att @ Vh).transpose(1, 2).reshape(P, M, self.h * self.hd)
        return F.normalize(C + self.o(H), dim=-1), slot


def kmeans_np(X, m):
    """Canonical spherical k-means seeds: first the row closest to the mean, then farthest-point (min of max cosine),
    ties to the lowest index; 3 Lloyd steps by cosine; centroids are normalised means; an empty cluster keeps its seed."""
    n = len(X)
    c0 = int(np.argmax(X @ X.sum(0)))
    chosen = [c0]; taken = np.zeros(n, bool); taken[c0] = True
    mx = X @ X[c0]
    for _ in range(1, m):
        j = int(np.argmin(np.where(taken, np.inf, mx)))
        chosen.append(j); taken[j] = True
        mx = np.maximum(mx, X @ X[j])
    C = X[chosen].copy()
    for _ in range(3):
        assign = np.argmax(X @ C.T, 1)
        new = C.copy()
        for k in range(m):
            sel = assign == k
            if sel.any():
                s = X[sel].sum(0); new[k] = s / np.linalg.norm(s)
        C = new
    return C


class NPModel:
    """Numpy fp32 export of one trained model (the device path): bridges, and optionally the UpEncoder + scale_p."""

    def __init__(self, tag, version, bridge, up=None, sp=None):
        g = lambda t: np.ascontiguousarray(t.detach().numpy().astype(np.float32))  # noqa: E731
        self.tag, self.version = tag, version
        self.svT, self.suT = g(bridge.state.v.T), g(bridge.state.u.T)
        self.avT, self.auT = g(bridge.action.v.T), g(bridge.action.u.T)
        self.scale = float(bridge.scale.detach().exp())
        self.has_up = up is not None
        if up is not None:
            self.WQ, self.WK, self.WV = g(up.q.weight.T), g(up.k.weight.T), g(up.v.weight.T)
            self.WO, self.E = g(up.o.weight.T), g(up.e)
            self.scale_p = float(sp.detach().exp())

    def key(self, x):  # canonical per-row leaf key a_i
        a = x + (x @ self.avT) @ self.auT
        return a / np.linalg.norm(a)

    def keys_batch(self, X):
        A = X + (X @ self.avT) @ self.auT
        return A / np.linalg.norm(A, axis=1, keepdims=True)

    def states(self, Q):
        S = Q + (Q @ self.svT) @ self.suT
        return S / np.linalg.norm(S, axis=1, keepdims=True)

    def encode_parent(self, X, level, zero_o=False):
        """Canonical per-node fp32 path. X: children rows in index order."""
        C = kmeans_np(X, min(4 if level == 1 else 8, len(X)))
        if zero_o:
            return C / np.linalg.norm(C, axis=1, keepdims=True)
        Q = (C + self.E[level]) @ self.WQ; K = X @ self.WK; V = X @ self.WV
        H = np.empty((len(C), self.WQ.shape[1]), np.float32)
        for h in range(4):
            sl = slice(16 * h, 16 * h + 16)
            z = (Q[:, sl] @ K[:, sl].T) / np.float32(4.0)
            z = np.exp(z - z.max(1, keepdims=True))
            H[:, sl] = (z / z.sum(1, keepdims=True)) @ V[:, sl]
        out = C + H @ self.WO
        return out / np.linalg.norm(out, axis=1, keepdims=True)


class Enc:
    """A parent encoder over one model's leaf keys: 'mean' (S3), 'kmeans' (S4: W_O forced to 0) or 'up' (S6)."""

    def __init__(self, kind, model):
        self.kind, self.model, self.keytag = kind, model, model.tag
        self.version = f"{model.version}/{kind}"
        self.calls = 0

    def __call__(self, X, level):
        self.calls += 1
        if self.kind == "mean":
            v = X.mean(0)
            return (v / np.linalg.norm(v))[None]
        return self.model.encode_parent(X, level, zero_o=self.kind == "kmeans")


# ---------------------------------------------------------------------------------------------- memory + pyramid
class Pyramid:
    """Content-addressed parent vectors for one encoder: node hash = SHA256(level|version|sorted child hashes);
    the cache maps hash -> K and records each entry's child-hash set (for the tests). Only reachable entries stay."""

    def __init__(self, enc):
        self.enc, self.cache, self.nh, self.root = enc, {}, {}, None

    def h(self, level, children, version=None):
        v = self.enc.version if version is None else version
        return hashlib.sha256(f"{level}|{v}|{','.join(sorted(children))}".encode()).hexdigest()

    def _put(self, h, level, children, X):
        if h not in self.cache:
            self.cache[h] = dict(K=self.enc(X, level), children=frozenset(children), level=level, version=self.enc.version)

    def update_node(self, mem, nd):
        ch = [mem.hm[d] for d in nd.leaves]; h = self.h(1, ch)
        if h not in self.cache:
            self._put(h, 1, ch, mem.stack(self.enc.keytag, nd.leaves))
        old = self.nh.get(nd.name); self.nh[nd.name] = h
        if old is not None and old != h:
            self.evict(old)

    def remove_node(self, name):
        self.evict(self.nh.pop(name))

    def update_root(self, mem):
        old = self.root
        if not mem.nodes:
            self.root = None
        else:
            ch = [self.nh[nd.name] for nd in mem.nodes]; h = self.h(2, ch)
            if h not in self.cache:
                self._put(h, 2, ch, np.concatenate([self.cache[x]["K"] for x in ch]))
            self.root = h
        if old is not None and old != self.root:
            self.evict(old)

    def evict(self, h):
        if h in self.cache and h != self.root and h not in self.nh.values():
            del self.cache[h]

    def K(self, name):
        return self.cache[self.nh[name]]["K"]

    def reachable(self):
        return set(self.nh.values()) | ({self.root} if self.root else set())


class Node:
    __slots__ = ("name", "leaves")

    def __init__(self, name, leaves):
        self.name, self.leaves = name, list(leaves)


def _redact(obj, h):
    if isinstance(obj, dict):
        return {k: _redact(v, h) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_redact(v, h) for v in obj]
    return "redacted" if obj == h else obj


class Memory:
    """One chat's memory plane: leaf rows (frozen x and one key row per bridge model, compacted on delete), the BM25
    index, level-1 nodes, one Pyramid per parent encoder, and an op log that references leaves only by HMAC."""

    def __init__(self, chat, keyers, encs, dkey):
        self.c, self.keyers, self.dkey = chat, dict(keyers), dkey
        self.ids, self.pos = [], {}
        self.rows = {t: [] for t in ["X", *self.keyers]}
        self._mat = {}
        self.hm, self.leaf_of = {}, {}
        self.bm25 = BM25Index()
        self.nodes, self.byname, self.node_of = [], {}, {}
        self.pyr = {t: Pyramid(e) for t, e in encs.items()}
        self.oplog, self.logrefs = [], collections.defaultdict(list)
        self.vec_time = 0.0

    def mat(self, t):
        if t not in self._mat:
            self._mat[t] = np.stack(self.rows[t]) if self.rows[t] else np.zeros((0, DIM), np.float32)
        return self._mat[t]

    def stack(self, t, leaves):
        return np.stack([self.rows[t][self.pos[d]] for d in leaves])

    def _log(self, row, hashes):
        self.oplog.append(row)
        for h in hashes:
            self.logrefs[h].append(len(self.oplog) - 1)

    def insert(self, d, name, update=True):
        i = self.c["index"][d]; x = self.c["nodes"][i]
        t0 = time.perf_counter()
        self.pos[d] = len(self.ids); self.ids.append(d)
        self.rows["X"].append(x)
        for t, k in self.keyers.items():
            self.rows[t].append(k.key(x))
        h = hmac.new(self.dkey, (d + "\x1f" + self.c["text"][i]).encode(), hashlib.sha256).hexdigest()
        self.hm[d] = h; self.leaf_of[h] = d
        self._mat = {}
        nd = self.byname.get(name)
        if nd is None:
            nd = Node(name, []); self.nodes.append(nd); self.byname[name] = nd
        nd.leaves.append(d); self.node_of[d] = name
        if update:
            for p in self.pyr.values():
                p.update_node(self, nd); p.update_root(self)
        self.vec_time += time.perf_counter() - t0
        self.bm25.add(d, self.c["docs"][i])
        self._log({"op": "insert", "leaf": h, "node": name}, [h])

    def forget(self, d):
        p = self.pos.pop(d); self.ids.pop(p)
        for t in self.rows:
            self.rows[t].pop(p)
        for j in range(p, len(self.ids)):
            self.pos[self.ids[j]] = j
        self._mat = {}
        self.bm25.remove(d)
        h = self.hm.pop(d); del self.leaf_of[h]
        for r in self.logrefs.pop(h, []):
            self.oplog[r] = _redact(self.oplog[r], h)
        name = self.node_of.pop(d); nd = self.byname[name]; nd.leaves.remove(d)
        deleted = not nd.leaves
        if deleted:
            self.nodes.remove(nd); del self.byname[name]
        for py in self.pyr.values():
            if deleted:
                py.remove_node(name)
            else:
                py.update_node(self, nd)
            py.update_root(self)
        self.oplog.append({"op": "forget", "node": name})
        return deleted

    def merge(self, names, new_name):
        old = [self.byname.pop(nm) for nm in names]
        i = self.nodes.index(old[0])
        new = Node(new_name, sorted((d for nd in old for d in nd.leaves), key=self.pos.get))
        self.nodes[i] = new
        for nd in old[1:]:
            self.nodes.remove(nd)
        self.byname[new_name] = new
        for d in new.leaves:
            self.node_of[d] = new_name
        for py in self.pyr.values():
            py.update_node(self, new)
            for nm in names:
                py.remove_node(nm)
            py.update_root(self)
        parts = [[nd.name, [self.hm[d] for d in nd.leaves]] for nd in old]
        self._log({"op": "merge", "into": new_name, "parts": parts}, [h for _, hs in parts for h in hs])

    def split(self, name, parts):
        """parts: [(new name, [dia_ids])] partitioning the node's leaves."""
        nd = self.byname.pop(name); i = self.nodes.index(nd)
        assert sorted(d for _, ls in parts for d in ls) == sorted(nd.leaves)
        news = [Node(nm, sorted(ls, key=self.pos.get)) for nm, ls in parts]
        self.nodes[i:i + 1] = news
        for nn in news:
            self.byname[nn.name] = nn
            for d in nn.leaves:
                self.node_of[d] = nn.name
        for py in self.pyr.values():
            for nn in news:
                py.update_node(self, nn)
            py.remove_node(name)
            py.update_root(self)
        logged = [[nn.name, [self.hm[d] for d in nn.leaves]] for nn in news]
        self._log({"op": "split", "node": name, "parts": logged}, [h for _, hs in logged for h in hs])

    def undo_last(self):
        """Undo the last merge or split from the op log alone (the logged partition, by HMAC)."""
        row = next(r for r in reversed(self.oplog) if r["op"] in ("merge", "split") and not r.get("undone"))
        row["undone"] = True
        if row["op"] == "merge":
            self.split(row["into"], [(nm, [self.leaf_of[h] for h in hs]) for nm, hs in row["parts"]])
        else:
            self.merge([nm for nm, _ in row["parts"]], row["node"])
        self.oplog[-1]["undo"] = True
        self.oplog[-1]["undone"] = True

    def structure(self):
        return [(nd.name, list(nd.leaves)) for nd in self.nodes]


def build(chat, struct, keyers, encs, dkey):
    """Batch (fresh) build: all leaves, then every node once, then the root: sessions + 1 encoder calls."""
    m = Memory(chat, keyers, encs, dkey)
    flat = [chat["index"][d] for _, ls in struct for d in ls]
    assert flat == sorted(flat), "structure must list leaves in time order"
    for name, ls in struct:
        for d in ls:
            m.insert(d, name, update=False)
    for py in m.pyr.values():
        for nd in m.nodes:
            py.update_node(m, nd)
        py.update_root(m)
    return m


def same_memory(a, b, tags=None):
    """Exact identity of two memories: ids, leaf rows, hashes, every K (np.array_equal), and BM25 statistics."""
    bad = []
    if a.ids != b.ids:
        bad.append("ids")
    for t in a.rows:
        if t in b.rows and not np.array_equal(a.mat(t), b.mat(t)):
            bad.append(f"rows {t}")
    if [nd.name for nd in a.nodes] != [nd.name for nd in b.nodes]:
        bad.append("node names")
    for t in (tags or a.pyr):
        pa, pb = a.pyr[t], b.pyr[t]
        if pa.nh != pb.nh or pa.root != pb.root:
            bad.append(f"{t} hashes")
            continue
        for h in pa.reachable():
            if not np.array_equal(pa.cache[h]["K"], pb.cache[h]["K"]):
                bad.append(f"{t} K {h[:8]}")
    if a.bm25.stats() != b.bm25.stats():
        bad.append("bm25 stats")
    return bad


# -------------------------------------------------------------------------------------------------------- training
def pad_index(groups, n):
    P = len(groups); N = max(len(g) for g in groups)
    idx = torch.full((P, N), n, dtype=torch.long); mask = torch.zeros(P, N, dtype=torch.bool)
    for p, g in enumerate(groups):
        idx[p, :len(g)] = torch.tensor(g); mask[p, :len(g)] = True
    return idx, mask


def pad(a, groups):
    idx, mask = pad_index(groups, a.shape[0])
    return torch.cat([a, a.new_zeros(1, a.shape[1])])[idx], mask


def score_parents(s, K, slot):
    z = torch.einsum("qd,pmd->qpm", s, K) / 0.05
    return 0.05 * z.masked_fill(~slot[None], float("-inf")).logsumexp(-1)


def augment_groups(groups, rng):
    out, i = [], 0
    while i < len(groups):
        if i + 1 < len(groups) and rng.random() < 0.3:
            out.append(list(groups[i]) + list(groups[i + 1])); i += 2
        else:
            out.append(list(groups[i])); i += 1
    res = []
    for g in out:
        if len(g) > 20 and rng.random() < 0.3:
            h = len(g) // 2; res += [g[:h], g[h:]]
        else:
            res.append(g)
    return res


def parent_pos(qs, groups, n):
    g_of = np.empty(n, np.int64)
    for p, g in enumerate(groups):
        g_of[g] = p
    pp = np.zeros((len(qs), len(groups)), np.float32)
    for r, (_, ev, _) in enumerate(qs):
        for e in ev:
            pp[r, g_of[e]] += 1 / len(ev)
    return torch.tensor(pp), g_of


def infonce(logits, pos):
    fwd = -(pos * logits.log_softmax(1)).sum(1).mean()
    cols = pos.sum(0) > 0
    bwd = -(pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
    return fwd + bwd


def train_joint(chats_tr, seed, epochs, augment, heap, probe=None):
    """probe(b, up, sp, epoch) is an optional diagnostic hook; it runs under no_grad and uses no RNG."""
    torch.manual_seed(seed)
    b = Bridge(DIM, 16); up = UpEncoder(); sp = torch.nn.Parameter(torch.tensor(math.log(20.0)))
    opt = torch.optim.AdamW([{"params": list(b.parameters()) + [sp], "weight_decay": 0.0},
                             {"params": list(up.parameters()), "weight_decay": 0.01}], lr=1e-3)
    params = list(b.parameters()) + [sp] + list(up.parameters())
    eye = torch.eye(DIM)
    data = []
    for c in chats_tr:
        X, Q = torch.tensor(c["nodes"]), torch.tensor(c["asks"])
        pos = torch.zeros(len(c["qs"]), len(c["ids"]))
        for r, (_, ev, _) in enumerate(c["qs"]):
            pos[r, ev] = 1 / len(ev)
        data.append((X, Q, pos, c))
    others = [torch.cat([d[1] for j, d in enumerate(data) if j != i]) for i in range(len(data))]
    log = []
    for ep in range(epochs):
        rng = np.random.default_rng([seed, ep])
        tot = collections.defaultdict(float)
        for ci, (X, Q, pos, c) in enumerate(data):
            n = X.shape[0]
            groups = [g for _, g in c["sessions"]]
            if augment and rng.random() < 0.5:
                groups = augment_groups(groups, rng)
            a, s = b.a(X), b.s(Q)
            logits = b.scale.exp() * s @ a.T
            near = ((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum()
            l_leaf = infonce(logits, pos) + 0.01 * near
            Xp, mask = pad(a, groups)
            K, slot = up.batch(Xp, mask, 4, 1)
            r = score_parents(s, K, slot)
            lp = sp.exp() * r
            ppos, g_of = parent_pos(c["qs"], groups, n)
            l_par = infonce(lp, ppos)
            multi = (ppos > 0).sum(1) >= 2
            if multi.any():
                worst = r.detach().masked_fill(ppos <= 0, float("inf")).argmin(1)
                l_cov = -lp.log_softmax(1)[multi, worst[multi]].mean()
            else:
                l_cov = lp.new_zeros(())
            loss = l_leaf + 0.5 * l_par + 0.2 * l_cov
            if heap:
                hr = np.random.default_rng([seed, ep, ci, 7])
                ti = hr.choice(n, size=min(64, n), replace=False)
                oi = hr.choice(len(others[ci]), size=min(64, len(others[ci])), replace=False)
                with torch.no_grad():
                    sq = torch.cat([b.s(X[ti]), b.s(others[ci][oi])])
                    idx, gmask = pad_index(groups, n)
                    z = torch.cat([sq @ b.a(X).T / 0.05, torch.full((len(sq), 1), float("-inf"))], 1)[:, idx]
                    t = 0.05 * z.logsumexp(-1)
                own = torch.zeros(len(sq), len(groups), dtype=torch.bool)
                own[torch.arange(len(ti)), torch.tensor(g_of[ti])] = True
                lt = (t / 0.05).masked_fill(own, -1e9); lr_ = (score_parents(sq, K, slot) / 0.05).masked_fill(own, -1e9)
                pt = lt.softmax(1)
                l_heap = (pt * (lt.log_softmax(1) - lr_.log_softmax(1))).sum(1).mean()
                loss = loss + 0.5 * l_heap
                tot["heap"] += float(l_heap)
            opt.zero_grad(); loss.backward()
            torch.nn.utils.clip_grad_norm_(params, 1.0)
            opt.step()
            tot["leaf"] += float(l_leaf); tot["par"] += float(l_par); tot["cov"] += float(l_cov)
        log.append({k: v / len(data) for k, v in tot.items()})
        if probe is not None:
            with torch.no_grad():
                probe(b, up, sp, ep + 1)
    return b, up, sp, log


def train_fold(args_tuple):
    """Train every variant of one fold (runs in a worker process when --workers > 1)."""
    chats, fold, epochs = args_tuple
    torch.set_num_threads(1)
    test = {2 * fold, 2 * fold + 1}
    tr = [c for i, c in enumerate(chats) if i not in test]
    out, times = {}, {}
    t0 = time.time(); out["R2"] = (e5_train(tr, DIM, epochs, fold, rank=16).state_dict(),); times["R2"] = time.time() - t0
    for tag, seed, aug, heap in (("V1", fold, True, False), ("V2", fold, True, True), ("V3", fold, False, False),
                                 ("V1p", fold + 1000, True, False)):
        t0 = time.time()
        b, up, sp, log = train_joint(tr, seed, epochs, aug, heap)
        out[tag] = (b.state_dict(), up.state_dict(), float(sp.detach()), log[-1])
        times[tag] = time.time() - t0
    return fold, out, times


def restore(fold, sd):
    models = {}
    b = Bridge(DIM, 16); b.load_state_dict(sd["R2"][0]); models["R2"] = NPModel("R2", f"f{fold}/R2", b)
    for tag in ("V1", "V2", "V3", "V1p"):
        bsd, usd, spv, _ = sd[tag]
        b = Bridge(DIM, 16); b.load_state_dict(bsd); up = UpEncoder(); up.load_state_dict(usd)
        models[tag] = NPModel(tag, f"f{fold}/{tag}", b, up, torch.tensor(spv))
        models[tag].torch_up = up
    return models


# ------------------------------------------------------------------------------------------------------ evaluation
class Ctx:
    """One fold's exported models, the S5 choices, and per-chat query states (computed once per model)."""

    def __init__(self, fold, models):
        self.fold, self.m, self.s5, self._st = fold, models, {}, {}

    def __getitem__(self, tag):
        return self.m[tag]

    def states(self, tag, c):
        k = (tag, c["cid"])
        if k not in self._st:
            self._st[k] = self.m[tag].states(c["asks"])
        return self._st[k]


def tune_s5(model, chats_tr):
    """Pick tau, beta for S5 on the TRAINING chats only, by session recall@3."""
    pre = []
    for c in chats_tr:
        D = model.states(c["asks"]) @ model.keys_batch(c["nodes"]).T
        groups = [g for _, g in c["sessions"]]
        sizes = np.array([len(g) for g in groups]); perm = np.concatenate(groups)
        starts = np.r_[0, np.cumsum(sizes)[:-1]]
        nidx = np.empty(len(c["ids"]), np.int64); nidx[perm] = np.repeat(np.arange(len(groups)), sizes)
        pre.append((D[:, perm], sizes, starts, nidx, c["qs"]))
    table = {}
    for tau in TAU_GRID:
        for beta in BETA_GRID:
            tot = cnt = 0
            for Dp, sizes, starts, nidx, qs in pre:
                L = tau * glse(Dp / tau, starts) - beta * tau * np.log(sizes)
                top = np.argsort(-L, axis=1, kind="stable")[:, :3]
                for r, (_, ev, _) in enumerate(qs):
                    evn = set(nidx[ev].tolist()); tot += len(evn & set(top[r].tolist())) / len(evn); cnt += 1
            table[f"tau={tau},beta={beta}"] = tot / cnt
    best = max(table, key=lambda k: table[k])  # first in grid order on ties
    tau, beta = (float(x.split("=")[1]) for x in best.split(","))
    return (tau, beta), table


def evaluate(mem, ctx, qsel=None, M="V1", budget=None, state_from=None, arms=ALL_ARMS, forbid=None, evmap=None):
    """Rank every leaf for each question under each arm on the memory's CURRENT state. Returns
    {arm: {qi: (top10 dia_ids, parents opened, leaves scanned, session recall@3, multi-hop all covered)}}.
    budget None = open top-3 parents; budget B = open parents in score order until >= B leaves are open."""
    c = mem.c; ids = mem.ids; n = len(ids); P = len(mem.nodes); pos = mem.pos
    qsel = range(len(c["qs"])) if qsel is None else qsel
    want = set(arms)
    if "S6h" in want and (M != "V1" or "S6h" not in mem.pyr):
        want.discard("S6h")
    strk = c["strrank"][np.array([c["index"][d] for d in ids])]
    sizes = np.array([len(nd.leaves) for nd in mem.nodes])
    perm = np.array([pos[d] for nd in mem.nodes for d in nd.leaves]); starts = np.r_[0, np.cumsum(sizes)[:-1]]
    nidx = np.empty(n, np.int64); nidx[perm] = np.repeat(np.arange(P), sizes)
    names = [nd.name for nd in mem.nodes]
    nrank = np.empty(P, np.int64); nrank[sorted(range(P), key=names.__getitem__)] = np.arange(P)
    ident = list(range(P)); ptie = np.arange(P)
    X = mem.mat("X"); Q = c["asks"]
    mdl = ctx[M]; SM = ctx.states(state_from or M, c)
    dM = mem.mat(M) @ SM.T
    fro = X @ Q.T
    if want & {"R2", "R3", "H1"}:
        d2 = mem.mat("R2") @ ctx.states("R2", c).T
    if want & {"S0", "S2", "S7"}:
        sb = BM25Index()
        for p, nd in enumerate(mem.nodes):
            sb.add(p, [w for d in nd.leaves for w in c["docs"][c["index"][d]]])
    if want & {"S1", "S1h"}:
        cen = np.stack([X[[pos[d] for d in nd.leaves]].mean(0) for nd in mem.nodes]) @ Q.T

    def slot_scores(tag, S):
        Ks = [mem.pyr[tag].K(nd.name) for nd in mem.nodes]
        st = np.r_[0, np.cumsum([len(k) for k in Ks])[:-1]]
        return 0.05 * glse(S @ np.concatenate(Ks).T / 0.05, st)

    r3 = slot_scores("S3", SM) if "S3" in want else None
    r4 = slot_scores("S4", SM) if "S4" in want else None
    r6 = slot_scores("S6", SM) if want & {"S6", "S6a", "S7", "H1", "H2", "H2(l=0.5)", "H2(l=2)"} else None
    r6h = slot_scores("S6h", ctx.states("V2", c)) if "S6h" in want else None
    if want & {"S5", "H2-lse"}:
        tau, beta = ctx.s5[M]
        L5 = tau * glse(dM.T[:, perm] / tau, starts) - beta * tau * np.log(sizes)
    fb = np.array([d in forbid for d in ids]) if forbid else None

    def opened(order):
        if budget is None:
            return order[:3]
        k = int(np.searchsorted(np.cumsum(sizes[order]), budget)) + 1
        return order[:min(k, P)]

    def filt(order, op):
        keep = np.zeros(P, bool); keep[op] = True
        return order[keep[nidx[order]]]

    def lsm(v):
        v = v - v.max()
        return v - np.log(np.exp(v).sum())

    out = {a: {} for a in arms}
    for qi in qsel:
        evd = evmap[qi] if evmap is not None else [c["ids"][e] for e in c["qs"][qi][1]]
        evp = [pos[d] for d in evd if d in pos]
        evn = set(nidx[evp].tolist()); cat = c["qs"][qi][2]
        lex = np.lexsort((strk, -mem.bm25.scores(c["qtok"][qi], pos, n)))
        o, ops = {}, {}
        dense_f = np.argsort(-fro[:, qi], kind="stable")
        dense_m = np.argsort(-dM[:, qi], kind="stable")
        o["R0"], o["R1"], o["R4"] = lex, dense_f, dense_m
        if want & {"R2", "R3", "H1"}:
            o["R2"] = np.argsort(-d2[:, qi], kind="stable")
            o["R3"] = fuse_np([lex, o["R2"]], n, strk)
        hyb_f = fuse_np([lex, dense_f], n, strk) if want & {"S0", "S1h"} else None
        hyb_m = fuse_np([lex, dense_m], n, strk)
        if want & {"S0", "S2", "S7"}:
            sorder = np.lexsort((nrank, -sb.scores(c["qtok"][qi], ident, P)))
        if "S0" in want:
            ops["S0"] = opened(sorder); o["S0"] = filt(hyb_f, ops["S0"])
        if want & {"S1", "S1h"}:
            op = opened(np.argsort(-cen[:, qi], kind="stable")); ops["S1"] = ops["S1h"] = op
            pool = filt(np.arange(n), op)
            o["S1"] = pool[np.lexsort((strk[pool], -fro[pool, qi]))]
            o["S1h"] = filt(hyb_f, op)
        if "S2" in want:
            ops["S2"] = opened(sorder); o["S2"] = filt(hyb_m, ops["S2"])
        for arm, r in (("S3", r3), ("S4", r4), ("S6", r6), ("S6h", r6h)):
            if r is not None and arm in want or (arm == "S6" and r is not None):
                ops[arm] = opened(np.argsort(-r[qi], kind="stable")); o[arm] = filt(hyb_m, ops[arm])
        if "S5" in want:
            ops["S5"] = opened(np.argsort(-L5[qi], kind="stable")); o["S5"] = filt(hyb_m, ops["S5"])
        if "S6a" in want:
            order = np.argsort(-r6[qi], kind="stable"); p = np.exp(lsm(mdl.scale_p * r6[qi]))
            k = min(max(int(np.searchsorted(np.cumsum(p[order]), 0.9)) + 1, 1), 6)
            ops["S6a"] = order[:k]; o["S6a"] = filt(hyb_m, ops["S6a"])
        if "S7" in want:
            ops["S7"] = opened(fuse_np([np.argsort(-r6[qi], kind="stable"), sorder], P, ptie)); o["S7"] = filt(hyb_m, ops["S7"])
        if "H1" in want:
            o["H1"] = fuse_np([o["S6"], o["R2"]], n, strk); ops["H1"] = ops["S6"]
        for arm, lam, src in (("H2", 1.0, r6), ("H2(l=0.5)", 0.5, r6), ("H2(l=2)", 2.0, r6),
                              ("H2-lse", 1.0, L5 if want & {"H2-lse"} else None)):
            if arm in want:
                sc = mdl.scale * dM[:, qi] + lam * lsm(mdl.scale_p * src[qi])[nidx]
                o[arm] = fuse_np([lex, np.argsort(-sc, kind="stable")], n, strk)
        for arm in arms:
            if arm not in want:
                continue
            od = o[arm]
            if fb is not None:
                check(len(od) <= n and (len(od) == 0 or int(od.max()) < n) and not fb[od].any(), f"forgotten id in {arm}")
            op = ops.get(arm)
            if op is None:
                rec = (tuple(ids[j] for j in od[:10]), 0, 1.0, float("nan"), float("nan"))
            else:
                ops_set = set(op.tolist())
                srec = len(evn & ops_set) / len(evn) if evn else float("nan")
                cov = float(evn <= ops_set) if (cat == 1 and evn) else float("nan")
                rec = (tuple(ids[j] for j in od[:10]), len(op), float(sizes[op].sum()) / n, srec, cov)
                if arm == "H1":
                    rec = rec[:2] + (1.0,) + rec[3:]
            out[arm][qi] = rec
    return out


def recall(top, ev):
    return len(set(top) & set(ev)) / len(ev)


def boot(d, B=10000):
    d = np.asarray(d, float); n = len(d)
    if n == 0:
        return float("nan"), float("nan"), float("nan")
    rng = np.random.default_rng(0); means = np.empty(B)
    for s in range(0, B, 500):
        k = min(500, B - s); means[s:s + k] = d[rng.integers(0, n, (k, n))].mean(1)
    return float(d.mean()), float(np.percentile(means, 2.5)), float(np.percentile(means, 97.5))


def fmt(t):
    return f"{t[0]:+.3f} [{t[1]:+.3f},{t[2]:+.3f}]"


def orig_struct(c):
    return [(name, [c["ids"][i] for i in g]) for name, g in c["sessions"]]


# ------------------------------------------------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", required=True); ap.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    ap.add_argument("--epochs", type=int, default=40)
    ap.add_argument("--cache-dir", default=os.path.join(tempfile.gettempdir(), "e8-cache"))
    ap.add_argument("--out", default=os.path.join(tempfile.gettempdir(), "e8_results.json"))
    ap.add_argument("--quick", action="store_true", help="1 fold, 5 epochs: plumbing check only")
    ap.add_argument("--workers", type=int, default=1, help="train folds in parallel processes")
    args = ap.parse_args()
    torch.set_num_threads(1)
    T0 = time.time()
    folds = [0] if args.quick else list(range(5))
    epochs = 5 if args.quick else args.epochs
    chats = load_tree(args.data, args.model, args.cache_dir)
    nq = sum(len(c["qs"]) for c in chats)
    print(f"{len(chats)} chats, {sum(len(c['ids']) for c in chats)} turns, {sum(len(c['sessions']) for c in chats)} sessions, "
          f"{nq} questions " + " ".join(f"c{k}={sum(q[2] == k for c in chats for q in c['qs'])}" for k in CATS), flush=True)
    R = {"config": dict(model=args.model, epochs=epochs, folds=folds, quick=args.quick)}
    dkey = os.urandom(32)

    # ---------------------------------------------------------------- training
    t0 = time.time()
    jobs = [(chats, f, epochs) for f in folds]
    if args.workers > 1 and BGE_CALLS[0]:
        print("bge ran in this process (threads started): training folds sequentially to keep fork safe", flush=True)
        args.workers = 1
    if args.workers > 1:
        import multiprocessing as mp
        with mp.get_context("fork").Pool(min(args.workers, len(jobs))) as pool:
            trained = pool.map(train_fold, jobs)
    else:
        trained = [train_fold(j) for j in jobs]
    ctxs, ttimes = {}, {}
    for fold, sd, times in trained:
        ctxs[fold] = Ctx(fold, restore(fold, sd)); ttimes[fold] = times
        ctxs[fold].final_loss = {t: sd[t][3] for t in ("V1", "V2", "V3", "V1p")}
    train_s = time.time() - t0
    print(f"training {train_s:.0f}s (wall), per fold: " + "; ".join(
        f"f{f} " + " ".join(f"{k} {v:.0f}s" for k, v in ttimes[f].items()) for f in folds), flush=True)
    R["train"] = dict(wall_s=train_s, per_fold=ttimes, final_loss={f: ctxs[f].final_loss for f in folds})
    up_params = sum(p.numel() for p in UpEncoder().parameters())
    print(f"UpEncoder parameters: {up_params}", flush=True)
    R["up_params"] = up_params

    # ---------------------------------------------------------------- S5 tuning (training chats only)
    s5 = {}
    for f in folds:
        tr = [c for i, c in enumerate(chats) if i not in {2 * f, 2 * f + 1}]
        for M in ("V1", "V3", "V1p"):
            ctxs[f].s5[M], table = tune_s5(ctxs[f][M], tr)
            s5[f"f{f}/{M}"] = dict(choice=ctxs[f].s5[M], table=table)
        print(f"  fold {f} S5 choice (V1) tau={ctxs[f].s5['V1'][0]} beta={ctxs[f].s5['V1'][1]}", flush=True)
    R["s5"] = s5

    test_chats = [c for c in chats if c["cid"] // 2 in folds]
    fold_of = {c["cid"]: c["cid"] // 2 for c in test_chats}
    glob = [(c["cid"], qi) for c in test_chats for qi in range(len(c["qs"]))]
    cats = np.array([chats[ci]["qs"][qi][2] for ci, qi in glob])

    def keyers_for(ctx, tags):
        return {t: ctx[t] for t in tags}

    def encs_main(ctx):
        return {"S3": Enc("mean", ctx["V1"]), "S4": Enc("kmeans", ctx["V1"]), "S6": Enc("up", ctx["V1"]), "S6h": Enc("up", ctx["V2"])}

    def encs_for(ctx, M):
        return {"S3": Enc("mean", ctx[M]), "S4": Enc("kmeans", ctx[M]), "S6": Enc("up", ctx[M])}

    # ---------------------------------------------------------------- main evaluation (batch builds)
    t0 = time.time()
    main_mem, main_res = {}, {}
    for c in test_chats:
        ctx = ctxs[fold_of[c["cid"]]]
        main_mem[c["cid"]] = build(c, orig_struct(c), keyers_for(ctx, ["R2", "V1", "V2"]), encs_main(ctx), dkey)
        main_res[c["cid"]] = evaluate(main_mem[c["cid"]], ctx)
    # batch path vs canonical path, once per fold (identical inputs: the canonical leaf keys)
    bvc = {}
    for f in folds:
        ctx = ctxs[f]; worst = 0.0
        for cid in (2 * f, 2 * f + 1):
            mem = main_mem[cid]
            groups = [[mem.pos[d] for d in nd.leaves] for nd in mem.nodes]
            with torch.no_grad():
                K, slot = ctx["V1"].torch_up.batch(*pad(torch.tensor(mem.mat("V1")), groups), 4, 1)
            for p, nd in enumerate(mem.nodes):
                kc = mem.pyr["S6"].K(nd.name)
                worst = max(worst, float(np.abs(K[p, :len(kc)].numpy() - kc).max()))
        bvc[f] = worst
        check(worst <= 1e-5, f"fold {f}: batch vs canonical max|diff| {worst:.2e} > 1e-5")
    R["batch_vs_canonical_maxdiff"] = bvc
    print(f"main evaluation {time.time() - t0:.0f}s; batch vs canonical max|diff| per fold: "
          + " ".join(f"{v:.1e}" for v in bvc.values()), flush=True)

    def arm_vec(res, arm, ev_of=None, keys=None):
        keys = glob if keys is None else keys
        return np.array([recall(res[ci][arm][qi][0], ev_of[(ci, qi)] if ev_of else [chats[ci]["ids"][e] for e in chats[ci]["qs"][qi][1]])
                         for ci, qi in keys])

    def col(res, arm, j, keys=None):
        keys = glob if keys is None else keys
        return np.array([res[ci][arm][qi][j] for ci, qi in keys], float)

    rec = {a: arm_vec(main_res, a) for a in ALL_ARMS}
    table = {}
    print("\nrecall@10 on held-out chats (each chat held out once); CI = paired bootstrap 10k, seed 0", flush=True)
    print(f"  {'arm':<10} {'r@10':>6} {'multi':>6} {'when':>6} {'infer':>6} {'single':>6} {'open':>5} {'scan':>5} "
          f"{'sess@3':>6} {'mhcov':>6}  vs R2                 vs R3 / vs S2", flush=True)
    for a in ALL_ARMS:
        row = dict(recall10=float(rec[a].mean()), by_cat={CATS[k]: float(rec[a][cats == k].mean()) for k in CATS},
                   opened=float(np.nanmean(col(main_res, a, 1))), scanned=float(np.nanmean(col(main_res, a, 2))))
        sr = col(main_res, a, 3); cv = col(main_res, a, 4)
        row["sess_recall3"] = float(np.nanmean(sr)) if not np.all(np.isnan(sr)) else None
        row["mh_covered3"] = float(np.nanmean(cv)) if not np.all(np.isnan(cv)) else None
        row["vs_R2"] = boot(rec[a] - rec["R2"]); row["vs_R2_multihop"] = boot((rec[a] - rec["R2"])[cats == 1])
        extra = ""
        if a in H_ARMS:
            row["vs_R3"] = boot(rec[a] - rec["R3"]); row["vs_R3_multihop"] = boot((rec[a] - rec["R3"])[cats == 1])
            extra = f"R3 {fmt(row['vs_R3'])} mh {fmt(row['vs_R3_multihop'])}"
        if a in S_ARMS:
            row["vs_S2"] = boot(rec[a] - rec["S2"]); extra = f"S2 {fmt(row['vs_S2'])}"
        table[a] = row
        bc = row["by_cat"]
        print(f"  {a:<10} {row['recall10']:.3f}  {bc['multi-hop']:.3f}  {bc['when']:.3f}  {bc['inference']:.3f}  "
              f"{bc['single-hop']:.3f}  {row['opened']:4.2f} {row['scanned']:5.2f}  "
              f"{(row['sess_recall3'] if row['sess_recall3'] is not None else float('nan')):.3f}  "
              f"{(row['mh_covered3'] if row['mh_covered3'] is not None else float('nan')):.3f}  {fmt(row['vs_R2'])}  {extra}", flush=True)
    R["main"] = table
    R["n_questions"] = len(glob)
    pairs = {"S4-S3": boot(rec["S4"] - rec["S3"]), "S6-S5": boot(rec["S6"] - rec["S5"]), "S6-S2": boot(rec["S6"] - rec["S2"]),
             "S1h-S1": boot(rec["S1h"] - rec["S1"]), "S6-S3": boot(rec["S6"] - rec["S3"]), "S6h-S6": boot(rec["S6h"] - rec["S6"]),
             "S6-S4": boot(rec["S6"] - rec["S4"]), "R4-R2": boot(rec["R4"] - rec["R2"]), "H2-lse-H2": boot(rec["H2-lse"] - rec["H2"])}
    R["pairs"] = pairs
    print("  pairs: " + "; ".join(f"{k} {fmt(v)}" for k, v in pairs.items()), flush=True)

    # ---------------------------------------------------------------- (a) streaming build
    t0 = time.time()
    st = dict(identical_K=True, identical_hash=True, identical_top10=True, cache_only_reachable=True)
    calls_per_insert, batch_calls, vec_ms, s6_ms, early = [], [], [], [], collections.defaultdict(list)
    n_inserts = 0
    for c in test_chats:
        ctx = ctxs[fold_of[c["cid"]]]
        encs = encs_main(ctx)
        mem = Memory(c, keyers_for(ctx, ["R2", "V1", "V2"]), encs, dkey)
        ok_counts = True
        last_by_sess = collections.defaultdict(list)
        for qi, s in enumerate(c["lastsess"]):
            last_by_sess[s].append(qi)
        for name, g in c["sessions"]:
            for i in g:
                before = {t: e.calls for t, e in encs.items()}
                t1 = time.perf_counter(); mem.insert(c["ids"][i], name); dt = time.perf_counter() - t1
                vec_ms.append(dt * 1000); n_inserts += 1
                diff = {t: e.calls - before[t] for t, e in encs.items()}
                ok_counts &= all(v == 2 for v in diff.values())
                calls_per_insert.append(diff["S6"])
            snum = int(name.split("_")[1])
            if last_by_sess.get(snum):  # 'ask early': right after the question's last evidence session arrives
                er = evaluate(mem, ctx, qsel=last_by_sess[snum], arms=["R2", "S6", "H2"])
                for qi in last_by_sess[snum]:
                    ev = [c["ids"][e] for e in c["qs"][qi][1]]
                    for a in ("R2", "S6", "H2"):
                        early[a].append(recall(er[a][qi][0], ev))
        check(ok_counts, f"chat {c['cid']}: streaming recompute count != 2 per insert per encoder")
        bm = main_mem[c["cid"]]
        batch_calls.append(len(c["sessions"]) + 1)
        bad = same_memory(mem, bm)
        st["identical_K"] &= check(not [b for b in bad if " K " in b or b.startswith("rows")], f"chat {c['cid']} stream K/rows: {bad}")
        st["identical_hash"] &= check(not [b for b in bad if not (" K " in b or b.startswith("rows"))], f"chat {c['cid']} stream hashes/structure: {bad}")
        for t, py in mem.pyr.items():
            st["cache_only_reachable"] &= check(set(py.cache) == py.reachable(), f"chat {c['cid']} {t}: cache holds unreachable keys")
        sr = evaluate(mem, ctx)
        same = all(sr[a][qi][0] == main_res[c["cid"]][a][qi][0] for a in ALL_ARMS for qi in range(len(c["qs"])))
        st["identical_top10"] &= check(same, f"chat {c['cid']}: streaming top-10 differs from batch")
    st.update(inserts=n_inserts, up_calls_per_insert=float(np.mean(calls_per_insert)), batch_up_calls_per_chat=float(np.mean(batch_calls)),
              stream_up_calls_total=int(np.sum(calls_per_insert)), batch_up_calls_total=int(np.sum(batch_calls)),
              mean_ms_vector_work_per_insert=float(np.mean(vec_ms)), note_ms="all 4 parent encoders + 3 leaf-key models + hashing",
              wall_s=time.time() - t0)
    ea = {a: float(np.mean(v)) for a, v in early.items()}
    st["ask_early"] = dict(n=len(early["R2"]), recall=ea, S6_vs_R2=boot(np.array(early["S6"]) - np.array(early["R2"])),
                           H2_vs_R2=boot(np.array(early["H2"]) - np.array(early["R2"])))
    R["stream"] = st
    print(f"\n(a) streaming: {n_inserts} inserts, up-encoder calls/insert {st['up_calls_per_insert']:.2f} (batch: sessions+1 = "
          f"{st['batch_up_calls_per_chat']:.1f}/chat), {st['mean_ms_vector_work_per_insert']:.2f} ms vector work/insert; "
          f"identical K {st['identical_K']}, hashes {st['identical_hash']}, top-10 {st['identical_top10']}, "
          f"cache reachable-only {st['cache_only_reachable']}; ask-early n={st['ask_early']['n']} "
          + " ".join(f"{a} {v:.3f}" for a, v in ea.items()) + f"  ({time.time() - t0:.0f}s)", flush=True)

    # ---------------------------------------------------------------- (b) forget 20% of leaves
    t0 = time.time()
    fg = dict(no_forgotten_in_rankings=True, no_forgotten_hash_in_cache=True, no_forgotten_hmac_in_oplog=True,
              K_equals_fresh=True, bm25_equals_fresh=True, recompute_counts=True, session_subtest=True)
    unchanged = collections.Counter(); lost_total = 0
    prim_f, prim_i, sec_f, sec_i = (collections.defaultdict(list) for _ in range(4))
    n_forgets = 0; n_prim = n_sec = n_none = 0
    for seed in (0, 1, 2):
        for c in test_chats:
            ctx = ctxs[fold_of[c["cid"]]]
            encs = encs_main(ctx)
            mem = build(c, orig_struct(c), keyers_for(ctx, ["R2", "V1", "V2"]), encs, dkey)
            before = {t: {nd.name: py.K(nd.name).copy() for nd in mem.nodes} for t, py in mem.pyr.items()}
            rng = np.random.default_rng([seed, c["cid"]])
            n = len(c["ids"]); victims = [c["ids"][j] for j in rng.choice(n, int(round(0.2 * n)), replace=False)]
            vh = {mem.hm[d] for d in victims}; lost = set()
            for d in victims:
                cb = {t: e.calls for t, e in encs.items()}; lost.add(mem.node_of[d])
                deleted = mem.forget(d); n_forgets += 1
                want = 1 if deleted else 2
                fg["recompute_counts"] &= check(all(e.calls - cb[t] == want for t, e in encs.items()), f"forget count {c['cid']} {d}")
            surv = mem.structure()
            fresh = build(c, surv, keyers_for(ctx, ["R2", "V1", "V2"]), encs_main(ctx), dkey)
            bad = same_memory(mem, fresh)
            fg["K_equals_fresh"] &= check(not [b for b in bad if b != "bm25 stats"], f"forget vs fresh {c['cid']}: {bad}")
            fg["bm25_equals_fresh"] &= check("bm25 stats" not in bad, f"forget bm25 {c['cid']}")
            for t, py in mem.pyr.items():
                fg["no_forgotten_hash_in_cache"] &= check(set(py.cache) == py.reachable() and all(not (e["children"] & vh) for e in py.cache.values()),
                                                          f"forgotten hash in cache {c['cid']} {t}")
                for nm in lost & set(py.nh):
                    if t in ("S3", "S6", "S4", "S6h"):
                        lost_total += t == "S6"
                        if np.array_equal(py.K(nm), before[t][nm]):
                            unchanged[t] += 1
            blob = json.dumps(mem.oplog)
            fg["no_forgotten_hmac_in_oplog"] &= check(not any(h in blob for h in vh), f"forgotten HMAC in op log {c['cid']}")
            forb = set(victims)
            fr = evaluate(mem, ctx, forbid=forb)
            fg["no_forgotten_in_rankings"] &= not any("forgotten id" in x for x in FAILS)
            for qi, (_, ev, cat) in enumerate(c["qs"]):
                evd = [c["ids"][e] for e in ev]; alive = [d for d in evd if d not in forb]
                if len(alive) == len(evd):
                    n_prim += 1
                    for a in ALL_ARMS:
                        prim_f[a].append(recall(fr[a][qi][0], evd)); prim_i[a].append(recall(main_res[c["cid"]][a][qi][0], evd))
                    prim_f["cat"].append(cat)
                elif alive:
                    n_sec += 1
                    for a in ALL_ARMS:
                        sec_f[a].append(recall(fr[a][qi][0], alive)); sec_i[a].append(recall(main_res[c["cid"]][a][qi][0], alive))
                else:
                    n_none += 1
    # sub-test: forget one entire session per chat
    sub = []
    for c in test_chats:
        ctx = ctxs[fold_of[c["cid"]]]; encs = encs_main(ctx)
        mem = build(c, orig_struct(c), keyers_for(ctx, ["R2", "V1", "V2"]), encs, dkey)
        name, g = c["sessions"][int(np.random.default_rng([9, c["cid"]]).integers(len(c["sessions"])))]
        cb = {t: e.calls for t, e in encs.items()}
        for i in g:
            mem.forget(c["ids"][i])
        calls_ok = all(e.calls - cb[t] == 2 * len(g) - 1 for t, e in encs.items())
        fresh = build(c, mem.structure(), keyers_for(ctx, ["R2", "V1", "V2"]), encs_main(ctx), dkey)
        ok = name not in mem.byname and all(name not in py.nh for py in mem.pyr.values()) and not same_memory(mem, fresh) and calls_ok
        fg["session_subtest"] &= check(ok, f"session forget {c['cid']} {name}")
        sub.append(name)
    fg["unchanged_K_after_losing_child"] = dict(unchanged); fg["sessions_that_lost_a_child"] = lost_total
    check(unchanged["S6"] == 0 and unchanged["S3"] == 0, f"S6/S3 sessions unchanged after losing a child: {dict(unchanged)}")
    pf = {a: np.array(v) for a, v in prim_f.items()}; pi = {a: np.array(v) for a, v in prim_i.items()}
    sf = {a: np.array(v) for a, v in sec_f.items()}; si = {a: np.array(v) for a, v in sec_i.items()}
    fres = {}
    for a in ALL_ARMS:
        fres[a] = dict(primary_forgotten=float(pf[a].mean()), primary_intact=float(pi[a].mean()),
                       delta_forgotten=boot(pf[a] - pf["R2"]), delta_intact=boot(pi[a] - pi["R2"]),
                       did=boot((pf[a] - pf["R2"]) - (pi[a] - pi["R2"])),
                       secondary_forgotten=float(sf[a].mean()), secondary_intact=float(si[a].mean()),
                       sec_delta_forgotten=boot(sf[a] - sf["R2"]), sec_delta_intact=boot(si[a] - si["R2"]))
    fg.update(forgets=n_forgets, primary_n=n_prim, secondary_n=n_sec, no_evidence_left_n=n_none, sessions_forgotten=sub,
              arms=fres, wall_s=time.time() - t0)
    R["forget"] = fg
    print(f"\n(b) forget 20% x 3 seeds: {n_forgets} forgets; checks " + ", ".join(f"{k} {v}" for k, v in fg.items() if isinstance(v, bool))
          + f"; unchanged K after losing a child {dict(unchanged)} (of {lost_total} S6 sessions)", flush=True)
    print(f"  primary n={n_prim} (all evidence survived), secondary n={n_sec}, none left {n_none}", flush=True)
    for a in ("R2", "R3", "S2", "S3", "S4", "S5", "S6", "S7", "H1", "H2", "H2-lse"):
        x = fres[a]
        print(f"  {a:<7} forgotten {x['primary_forgotten']:.3f} intact {x['primary_intact']:.3f}  "
              f"d(arm-R2) forgotten {fmt(x['delta_forgotten'])} intact {fmt(x['delta_intact'])}  diff {fmt(x['did'])}  "
              f"| secondary {x['secondary_forgotten']:.3f} d {fmt(x['sec_delta_forgotten'])}", flush=True)
    print(f"  ({time.time() - t0:.0f}s)", flush=True)

    # ---------------------------------------------------------------- (c) merge adjacent sessions (and midpoint split)
    t0 = time.time()
    mg = dict(merge_equals_fresh=True, undo_merge_exact=True, merge_counts=True, split_equals_fresh=True, undo_split_exact=True,
              split_counts=True)
    MERGE_ARMS = ["S0", "S1h", "S2", "S3", "S4", "S5", "S6", "S6a", "S7", "R2", "R3", "H1", "H2", "H2-lse"]
    mres = {}
    for M in ("V1", "V3"):
        acc = collections.defaultdict(list)
        for c in test_chats:
            ctx = ctxs[fold_of[c["cid"]]]; encs = encs_for(ctx, M)
            mem = build(c, orig_struct(c), keyers_for(ctx, ["R2", M]), encs, dkey)
            snap = {t: (dict(py.nh), py.root, {h: py.cache[h]["K"].copy() for h in py.reachable()}) for t, py in mem.pyr.items()}
            B = 3 * float(np.median([len(g) for _, g in c["sessions"]]))
            ev_of = {qi: [c["ids"][e] for e in ev] for qi, (_, ev, _) in enumerate(c["qs"])}
            res = {}
            res["orig/top3"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS)
            res["orig/budget"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS, budget=B)
            names = [nd.name for nd in mem.nodes]
            for k in range(0, len(names) - 1, 2):
                cb = {t: e.calls for t, e in encs.items()}
                mem.merge([names[k], names[k + 1]], f"{names[k]}+{names[k + 1].split('_')[1]}")
                mg["merge_counts"] &= check(all(e.calls - cb[t] == 2 for t, e in encs.items()), f"merge count {c['cid']}")
            fresh = build(c, mem.structure(), keyers_for(ctx, ["R2", M]), encs_for(ctx, M), dkey)
            mg["merge_equals_fresh"] &= check(not same_memory(mem, fresh), f"merge vs fresh {M} {c['cid']}")
            res["merged/top3"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS)
            res["merged/budget"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS, budget=B)
            while any(r["op"] == "merge" and not r.get("undone") for r in mem.oplog):
                mem.undo_last()
            mg["undo_merge_exact"] &= check(all((py.nh, py.root) == snap[t][:2] and all(np.array_equal(py.cache[h]["K"], snap[t][2][h]) for h in py.reachable())
                                                for t, py in mem.pyr.items()), f"undo merge {M} {c['cid']}")
            # optional: split every session at its midpoint, then undo
            for nm, ls in list(mem.structure()):
                h = len(ls) // 2; cb = {t: e.calls for t, e in encs.items()}
                mem.split(nm, [(nm + ".a", ls[:h]), (nm + ".b", ls[h:])])
                mg["split_counts"] &= check(all(e.calls - cb[t] == 3 for t, e in encs.items()), f"split count {c['cid']}")
            fresh = build(c, mem.structure(), keyers_for(ctx, ["R2", M]), encs_for(ctx, M), dkey)
            mg["split_equals_fresh"] &= check(not same_memory(mem, fresh), f"split vs fresh {M} {c['cid']}")
            res["split/top3"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS)
            res["split/budget"] = evaluate(mem, ctx, M=M, arms=MERGE_ARMS, budget=B)
            while any(r["op"] == "split" and not r.get("undone") for r in mem.oplog):
                mem.undo_last()
            mg["undo_split_exact"] &= check(all((py.nh, py.root) == snap[t][:2] and all(np.array_equal(py.cache[h]["K"], snap[t][2][h]) for h in py.reachable())
                                                for t, py in mem.pyr.items()), f"undo split {M} {c['cid']}")
            for key, r_ in res.items():
                for a in MERGE_ARMS:
                    acc[(key, a)] += [recall(r_[a][qi][0], ev_of[qi]) for qi in range(len(c["qs"]))]
                    acc[(key, a, "scan")] += [r_[a][qi][2] for qi in range(len(c["qs"]))]
                    acc[(key, a, "open")] += [r_[a][qi][1] for qi in range(len(c["qs"]))]
        out = {}
        for a in MERGE_ARMS:
            v = {k: np.array(acc[(k, a)]) for k in ("orig/top3", "orig/budget", "merged/top3", "merged/budget", "split/top3", "split/budget")}
            out[a] = {k: float(x.mean()) for k, x in v.items()}
            out[a].update({f"scan {k}": float(np.mean(acc[(k, a, 'scan')])) for k in v})
            out[a].update({f"open {k}": float(np.mean(acc[(k, a, 'open')])) for k in v})
            out[a]["drop_budget"] = boot(v["orig/budget"] - v["merged/budget"])
            out[a]["drop_top3"] = boot(v["orig/top3"] - v["merged/top3"])
            out[a]["drop_split_budget"] = boot(v["orig/budget"] - v["split/budget"])
        d2 = np.array(acc[("orig/budget", "S2")]) - np.array(acc[("merged/budget", "S2")])
        for a in ("S6", "S3", "S4", "S5", "S7", "H2"):
            da = np.array(acc[("orig/budget", a)]) - np.array(acc[("merged/budget", a)])
            out[a]["drop_minus_S2_drop_budget"] = boot(da - d2)
        mres[M] = out
    mg.update(arms=mres, wall_s=time.time() - t0)
    R["merge"] = mg
    print("\n(c) merge adjacent sessions: checks " + ", ".join(f"{k} {v}" for k, v in mg.items() if isinstance(v, bool)), flush=True)
    for M in ("V1", "V3"):
        for a in ("S2", "S3", "S4", "S5", "S6", "S7", "H1", "H2", "H2-lse", "S0", "S1h"):
            x = mres[M][a]
            print(f"  {M} {a:<7} orig top3 {x['orig/top3']:.3f} budget {x['orig/budget']:.3f} | merged top3 {x['merged/top3']:.3f} "
                  f"budget {x['merged/budget']:.3f} (scan {x['scan merged/budget']:.2f} vs {x['scan orig/budget']:.2f}) | split budget "
                  f"{x['split/budget']:.3f} | drop@budget {fmt(x['drop_budget'])}", flush=True)
    print(f"  ({time.time() - t0:.0f}s)", flush=True)

    # ---------------------------------------------------------------- (d) weight update V1 -> V1'
    t0 = time.time()
    wu = dict(bge_calls_zero=True, all_entries_v1p=True, v1_lookup_misses=True, guard_refuses_mixed=True)
    wt_leaf = wt_node = 0.0; n_leaf = n_node = 0
    wres, mixres, v1p_res = {}, {}, {}
    refused = 0
    for c in test_chats:
        ctx = ctxs[fold_of[c["cid"]]]
        mem = build(c, orig_struct(c), keyers_for(ctx, ["R2", "V1"]), {"S6": Enc("up", ctx["V1"])}, dkey)
        mixres[c["cid"]] = evaluate(mem, ctx, M="V1", state_from="V1p", arms=["R2", "S6", "H2"])
        # the version guard: a V1' query must not read a V1 cache
        try:
            for py in mem.pyr.values():
                if py.enc.version.split("/")[1] != ctx["V1p"].tag:
                    raise RuntimeError("version mismatch")
        except RuntimeError:
            refused += 1
        old_versions = {py.enc.version for py in mem.pyr.values()}
        bge0 = BGE_CALLS[0]
        t1 = time.perf_counter()
        new = ctx["V1p"]
        mem.rows["V1p"] = [new.key(x) for x in mem.rows["X"]]; del mem.rows["V1"]
        mem.keyers = {"R2": ctx["R2"], "V1p": new}; mem._mat = {}
        t2 = time.perf_counter()
        for py in mem.pyr.values():
            py.enc = Enc("up", new)
            for nd in mem.nodes:
                py.update_node(mem, nd)
            py.update_root(mem)
        t3 = time.perf_counter()
        wt_leaf += t2 - t1; wt_node += t3 - t2; n_leaf += len(mem.ids); n_node += len(mem.nodes) + 1
        wu["bge_calls_zero"] &= check(BGE_CALLS[0] == bge0, "bge called during weight update")
        for py in mem.pyr.values():
            wu["all_entries_v1p"] &= check(all(e["version"] == py.enc.version for e in py.cache.values()) and set(py.cache) == py.reachable(),
                                           f"stale entry after weight update {c['cid']}")
            for ov in old_versions:
                hs = [py.h(1, [mem.hm[d] for d in nd.leaves], version=ov) for nd in mem.nodes]
                wu["v1_lookup_misses"] &= check(not any(h in py.cache for h in hs), f"v1 lookup hit a v1' entry {c['cid']}")
        v1p_res[c["cid"]] = evaluate(mem, ctx, M="V1p", arms=["R2", "S6", "H2"])
    wu["guard_refuses_mixed"] &= check(refused == len(test_chats), "version guard did not refuse every mixed read")
    total = wt_leaf + wt_node
    wu.update(full_recompute_s=total, leaf_s=wt_leaf, node_s=wt_node, leaves=n_leaf, nodes=n_node,
              extrapolated_100k_leaves_20k_nodes_s=wt_leaf / n_leaf * 100000 + wt_node / n_node * 20000,
              under_1s=total < 1.0, refused=refused)
    check(total < 1.0, f"weight-update recompute {total:.2f}s >= 1s")
    for a in ("S6", "H2"):
        v1 = rec[a]; v1p = arm_vec(v1p_res, a); mix = arm_vec(mixres, a)
        ov = np.array([len(set(main_res[ci][a][qi][0]) & set(v1p_res[ci][a][qi][0])) / 10 for ci, qi in glob])
        wres[a] = dict(V1=float(v1.mean()), V1p=float(v1p.mean()), V1p_minus_V1=boot(v1p - v1), V1p_vs_R2=boot(v1p - rec["R2"]),
                       top10_overlap=float(ov.mean()), mixed=float(mix.mean()), mixed_minus_V1=boot(mix - v1))
    wu["arms"] = wres; wu["wall_s"] = time.time() - t0
    R["weight_update"] = wu
    print(f"\n(d) weight update V1 -> V1': full recompute {total * 1000:.0f} ms ({n_leaf} a_i {wt_leaf * 1000:.0f} ms, {n_node} nodes "
          f"{wt_node * 1000:.0f} ms); extrapolated 100k leaves + 20k nodes {wu['extrapolated_100k_leaves_20k_nodes_s']:.1f}s; checks "
          + ", ".join(f"{k} {v}" for k, v in wu.items() if isinstance(v, bool)), flush=True)
    for a, x in wres.items():
        print(f"  {a}: V1 {x['V1']:.3f} V1' {x['V1p']:.3f} diff {fmt(x['V1p_minus_V1'])} top-10 overlap {x['top10_overlap']:.2f}; "
              f"mixed (V1' asks vs V1 cache) {x['mixed']:.3f} ({fmt(x['mixed_minus_V1'])})", flush=True)

    # ---------------------------------------------------------------- pass lines
    T = table
    P = {}
    repro = {a: (T[a]["recall10"], *TOL[a]) for a in TOL}
    P["P0"] = dict(passed=all(abs(v - e) <= tol + 1e-9 for v, e, tol in repro.values()), values=repro)
    s43 = pairs["S4-S3"]
    P["P1"] = dict(passed=s43[0] >= 0.05 and s43[1] > 0 and T["S6"]["recall10"] >= T["S2"]["recall10"] - 0.005,
                   S4_minus_S3=s43, S6=T["S6"]["recall10"], S2=T["S2"]["recall10"])
    s65 = pairs["S6-S5"]
    P["P2"] = dict(passed=s65[0] >= 0.01 and s65[1] > 0, S6_minus_S5=s65)
    h = T["H2"]["vs_R3"]; hm = T["H2"]["vs_R3_multihop"]
    P["P3"] = dict(passed=(h[0] >= 0.010 and h[1] > 0) or (hm[0] >= 0.03 and hm[1] > 0), H2_minus_R3=h, H2_minus_R3_multihop=hm,
                   H1_vs_R2=T["H1"]["vs_R2"], H2_vs_R2=T["H2"]["vs_R2"])
    P["P4"] = dict(passed=not FAILS and total < 1.0, failures=list(FAILS), recompute_s=total)
    did = fres["H2"]["did"][0]
    mdrops = {M: (mres[M]["S6"]["drop_budget"][0], mres[M]["S2"]["drop_budget"][0]) for M in ("V1", "V3")}
    p5 = dict(forget_H2_did=did, forget_ok=abs(did) <= 0.01,
              merge_drops=mdrops, merge_ok={M: d6 <= d2 + 0.01 for M, (d6, d2) in mdrops.items()},
              v1p_minus_v1={a: wres[a]["V1p_minus_V1"][0] for a in wres},
              v1p_ok=all(abs(wres[a]["V1p_minus_V1"][0]) <= 0.01 for a in wres))
    p5["passed"] = p5["forget_ok"] and all(p5["merge_ok"].values()) and p5["v1p_ok"]
    P["P5"] = p5
    R["pass"] = P
    R["s1h_minus_s1"] = pairs["S1h-S1"]
    R["wall_s"] = time.time() - T0
    print("\nPASS LINES", flush=True)
    for k, v in P.items():
        print(f"  {k}: {'PASS' if v['passed'] else 'FAIL'}  " + json.dumps({kk: vv for kk, vv in v.items() if kk != 'passed'}, default=str)[:400], flush=True)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w") as fh:
        json.dump(R, fh, indent=1, default=lambda o: o.tolist() if hasattr(o, "tolist") else str(o))
    print(f"\nwrote {args.out}; total {R['wall_s']:.0f}s", flush=True)
    if FAILS:
        print(f"{len(FAILS)} exactness failures", flush=True)
        sys.exit(1)
    if not args.quick and not P["P0"]["passed"]:
        print("P0 failed: not the same pipeline", flush=True)
        sys.exit(2)


if __name__ == "__main__":
    main()
