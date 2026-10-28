#!/usr/bin/env python3
"""Stage 2 read stack: stage 1's bridges, reads and ranker, rebuilt for ANY per-chat node and ask vectors (any dim d).

Nothing here is a new choice. Every step calls or copies the stage 1 code in ../stage1 (common.py, s11_rank.py,
s111_baselines.py, s112_ranker_keys.py), so tests 2.2 and 2.3 can swap the encoder (or plug in a fixed scorer) and keep
the whole stage 1 protocol.

(a) Bridges, the s11_rank.py protocol at rank 16. For outer fold f (test pair common.FOLDS[f], 8 training chats), every
    learning rate in s11_rank.LRS (3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2) and every dev pair p in common.inner_pairs: a
    bridge is trained with common.train on the 6 other training chats (rank 16, alpha 20, forward-only L_mask, 40 epochs,
    one AdamW step per chat per epoch, 0.01 ||W - I||^2 per head, seed 1000 + 10 f + p[0]) and scored by dense recall@10
    on p. The fold's lr is the one with the best mean dev recall over the 4 pairs' questions (unrounded), ties to the
    smaller lr. The outer bridge is trained on the 8 training chats at that lr, seed f. The inner bridges that s111 uses
    for the features of training chats are those dev bridges at the fold's lr (the same chats, lr and seed as s111's
    "bridge" job, so they are the same bridges). LongMemEval-S uses one bridge trained on all 10 chats (seed 0) at the lr
    with the best pooled held-out LoCoMo recall when every fold uses that lr (s11's heldout_<lr>, compared after rounding
    to 4 decimals as s11 does, ties to the smaller lr).
(b) Reads, recall@10 per question: frozen (node . ask), bridge (LoCoMo chat i read by the outer bridge of fold i // 2;
    LongMemEval-S by the all-chat bridge), each alone ("dense") and fused with BM25 by reciprocal rank (k 60, common.fuse).
(c) Ranker, the s111_baselines.py protocol: LightGBM over each question's top 50 of the BM25 + bridge fused list, s111's
    25 features (s111_baselines.qfeats), labels 1 for a marked evidence node, objective {lambdarank, binary} x num_leaves
    {7, 31} x trees {50, 100, 200, 400} (s111_baselines.rk_fit / rk_score / job, unchanged). Per outer fold the config is
    picked on the dev pair FOLDS[(f + 1) % 5] (fit on the 6 training chats outside it, best mean dev recall, ties first
    in grid order), then fit on the 8 training chats and scored on the test pair. A training chat's bridge features come
    from the inner bridge that held its pair out; the test pair uses the outer bridge. LongMemEval-S: fit on all 10
    LoCoMo chats (outer-bridge features), config with the best pooled dev recall over the 5 folds. The "bridge" and
    "frozen" score sources are inputs (ranker(cb_of, cf_of, ...)), so a fixed scorer (CLM in 2.3) can fill them; a fixed
    scorer gives every tag the same scores (fixed=True), since it has no training chats to hold out.

Statistics (used by s22 and s23b): paired per-question differences; chat-clustered bootstrap (common.cluster_boot, 4,000
draws, seed 0); the exact chat sign-flip test over all 2^10 = 1,024 sign vectors with s112_ranker_keys' statistic
T(e) = sum_j e_j D_j / N (D_j chat j's summed difference, N questions). s112's convention is ONE-SIDED: p = share of sign
vectors with T(e) >= T(observed), the observed included. The two-sided p (share with |T(e)| >= |T(observed)|) is
computed next to it. LongMemEval-S: cluster_boot with every question its own cluster.

Determinism: bridges are trained in single-threaded worker processes (torch.set_num_threads(1), OMP 1) and LightGBM runs
with deterministic=True, n_jobs=1 (40 fits gave the same result in any order); --procs only sets how many single-threaded
workers run. One stage 1 detail was not repeatable across processes: common.BM25.scores adds the query terms in
Python's string-hash order, which hash randomisation changes per process, and two LoCoMo BM25 lists depend on that order
(see bm25_scores). load_data recomputes every BM25 score and list with the terms in sorted order (the same formula), which
gives the lists stage 1's reported numbers came from; the regression below checks it against stage 1.

Regression (--regress, must pass before s22 or s23b are trusted): with the stage 1 bge-small vectors this rebuild must
give the stage 1 numbers per question: rank-16 bridge read on LoCoMo 0.6622 (identical per question to the s11 outer
read with s11_models.npz), fused 0.6553, ranker 0.7492 on LoCoMo and 0.9187 on LongMemEval-S (per question equal to the
s111 ranker recomputed through s111's own feature code on the stage 1 bridges), with s11's lr picks and s111's ranker
picks. Writes a JSON report to the scratch directory, never to results/.

Usage: /tmp/e1/bin/python -I pipeline.py --regress [--procs 2] [--out /tmp/claude-0/stage2/pipe/regress.json]
       [--cache-dir /tmp/claude-0/stage2/pipe/cache]   (paths are fixed defaults or flags; no environment variable is read)
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ[_v] = "1"  # written, never read: single-threaded workers

import argparse, hashlib, json, math, sys, time  # noqa: E402
import multiprocessing as mp  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
STAGE1 = os.path.normpath(os.path.join(HERE, "..", "stage1"))
sys.path.insert(0, STAGE1)
import common as C  # noqa: E402
import s11_rank as S11  # noqa: E402
import s111_baselines as S111  # noqa: E402

RANK = 16
LRS = S11.LRS
GRID = [(o, lv, k) for o in S111.RK_OBJ for lv in S111.RK_LEAVES for k in S111.RK_TREES]
FITS = [(o, lv) for o in S111.RK_OBJ for lv in S111.RK_LEAVES]
SCRATCH = "/tmp/claude-0/stage2/pipe"  # fixed default (no environment variable is read); --cache-dir / --out override
CACHE_DIR = os.path.join(SCRATCH, "cache")
CODE = [os.path.abspath(__file__)] + [os.path.join(STAGE1, f) for f in ("common.py", "s11_rank.py", "s111_baselines.py")]
_G = {}  # filled in the parent before a worker pool forks


def train_ids(f):
    return S111.train_ids(f)


def dev_pair(f):
    return S111.dev_pair(f)


def log(*a):
    print(*a, flush=True)


def _pool(fn, specs, procs, what=""):
    """Run fn over specs in `procs` forked single-threaded workers; returns {spec: result}."""
    t0, out = time.time(), {}
    with mp.get_context("fork").Pool(procs) as pool:
        for n, (spec, res) in enumerate(pool.imap_unordered(fn, specs, chunksize=1)):
            out[spec] = res
            if what and ((n + 1) % 25 == 0 or n + 1 == len(specs)):
                log(f"  {what}: {n + 1}/{len(specs)} ({time.time() - t0:.0f}s)")
    return out


# ---------------------------------------------------------------- data and vector spaces

def bm25_scores(b, query):
    """common.BM25.scores with the query's terms added in sorted order (same formula, same terms). common's version adds
    them in the iteration order of set(query), i.e. Python's per-process string-hash order, and on two LoCoMo questions
    (chat 4 question 98 and chat 6 question 105) the BM25 list then depends on that order: in about 8% of term orders
    each swaps two near-tied turns (in the top 10 for both). A process that hits a swap builds other ranker rows and fits
    another ranker (seen once in four smoke runs). The sorted order gives the majority lists, the ones stage 1 ran on."""
    out = np.zeros(b.n)
    norm = 1.2 * (0.25 + 0.75 * b.len / b.avg)
    for w in sorted(set(query)):
        if w not in b.df:
            continue
        idf = math.log(1 + (b.n - b.df[w] + 0.5) / (b.df[w] + 0.5))
        for i, f in b.post[w]:
            out[i] += idf * f * 2.2 / (f + norm[i])
    return out


def load_data(lme=True):
    """LoCoMo chats (common.load_locomo, bge-small vectors attached) and optionally LongMemEval-S (common.load_lme), with
    s111's per-node static features and every question's BM25 scores cached on them. The BM25 scores and lists
    ("lexorder", ranked as common.BM25.rank) are recomputed with bm25_scores so that every process gets the same ones;
    data["bm25_lists_changed"] counts the lists that differ from the ones common built in this process (0 or 1 or 2)."""
    chats = C.load_locomo(); changed = 0
    for ch in chats:
        sess = [int(C.EVID.match(x).group(1)) if C.EVID.match(x) else -1 for x in ch["ids"]]
        ch["_static"] = S111.chat_static(ch["ids"], ch["docs"], sess)
        ch["_bm"] = []
        for r, q in enumerate(ch["qs"]):
            qt = C.tokens(q[0]); sc = bm25_scores(ch["bm25"], qt); ch["_bm"].append((qt, sc))
            lex = np.lexsort((np.arange(len(sc)), -sc))
            changed += not np.array_equal(lex, ch["lexorder"][r]); ch["lexorder"][r] = lex
    data = dict(chats=chats, items=None, texts=None, vec=None)
    if lme:
        items, texts, vec = C.load_lme()
        for it in items:
            it["_static"] = S111.chat_static(it["rows"], it["docs"], it["sess"])
            qt = C.tokens(it["question"]); sc = bm25_scores(it["bm25"], qt); it["_bm"] = (qt, sc)
            lex = np.lexsort((np.arange(len(sc)), -sc))
            changed += not np.array_equal(lex, it["lexorder"]); it["lexorder"] = lex
        data.update(items=items, texts=texts, vec=vec)
    data["bm25_lists_changed"] = int(changed)
    return data


def _space(tag, data, nodes, asks, lme):
    chats = [dict(ch, nodes=n, asks=a) for ch, n, a in zip(data["chats"], nodes, asks)]
    for ch in chats:
        assert ch["nodes"].shape[0] == len(ch["ids"]) and ch["asks"].shape[0] == len(ch["qs"])
    return dict(tag=tag, dim=int(nodes[0].shape[1]), chats=chats, lme=lme)


def space_stage1(data):
    """The stage 1 bge-small space (common.load_locomo / load_lme caches)."""
    lme = None
    if data["items"] is not None:
        lme = dict(V=data["vec"], pos=np.arange(len(data["vec"])), Q=np.array([it["q"] for it in data["items"]]))
    return _space("bge-small", data, [c["nodes"] for c in data["chats"]], [c["asks"] for c in data["chats"]], lme)


def space_npz(tag, enc_dir, data):
    """An encoder's space from encode_texts.py output: <enc_dir>/<tag>/locomo.npz (rows = index over all LoCoMo turns
    concatenated in chat order, v, q = questions in chat order) and, when LongMemEval-S is loaded and the file exists,
    lme.npz (rows = LME text indices, v, q = the 428 questions). Returns None if locomo.npz is missing; the space's
    "lme" is None if lme.npz is missing."""
    p = os.path.join(enc_dir, tag, "locomo.npz")
    if not os.path.exists(p):
        return None
    z = np.load(p)
    v, q, rows = z["v"].astype(np.float32), z["q"].astype(np.float32), z["rows"]
    nn = [len(c["ids"]) for c in data["chats"]]; nq = [len(c["qs"]) for c in data["chats"]]
    assert np.array_equal(rows, np.arange(sum(nn))) and len(q) == sum(nq) == 1536, f"{p}: unexpected rows or q"
    cn, cq = np.cumsum([0] + nn), np.cumsum([0] + nq)
    nodes = [v[cn[i]:cn[i + 1]] for i in range(10)]; asks = [q[cq[i]:cq[i + 1]] for i in range(10)]
    lme = None
    pl = os.path.join(enc_dir, tag, "lme.npz")
    if data["items"] is not None and os.path.exists(pl):
        z = np.load(pl)
        pos = np.full(len(data["texts"]), -1, dtype=np.int64); pos[z["rows"]] = np.arange(len(z["rows"]))
        assert all((pos[it["rows"]] >= 0).all() for it in data["items"]), f"{pl}: a used LME row is missing"
        assert len(z["q"]) == len(data["items"]) == 428, f"{pl}: expected 428 questions"
        lme = dict(V=z["v"].astype(np.float32), pos=pos, Q=z["q"].astype(np.float32))
    return _space(tag, data, nodes, asks, lme)


def lme_nodes(sp, it):
    return sp["lme"]["V"][sp["lme"]["pos"][it["rows"]]]


def fingerprint(sp, use_lme):
    h = hashlib.sha256()
    for f in CODE:
        h.update(open(f, "rb").read())
    h.update(f"{sp['tag']}|{sp['dim']}|{use_lme}".encode())
    for ch in sp["chats"]:
        h.update(np.ascontiguousarray(ch["nodes"]).tobytes()); h.update(np.ascontiguousarray(ch["asks"]).tobytes())
    if use_lme:
        for k in ("V", "pos", "Q"):
            h.update(np.ascontiguousarray(sp["lme"][k]).tobytes())
    return h.hexdigest()


# ---------------------------------------------------------------- (a) bridges

def _bridge_job(spec):
    torch.set_num_threads(1)
    kind, f, lr, pair = spec
    CH, dim = _G["chats"], _G["dim"]
    if kind == "dev":
        fit, seed = [j for j in train_ids(f) if j not in pair], 1000 + 10 * f + pair[0]
    elif kind == "test":
        fit, seed = train_ids(f), f
    else:
        fit, seed = list(range(10)), 0
    b = C.train([CH[j] for j in fit], RANK, lr, seed=seed, dim=dim)
    out = dict(state={k: v.numpy() for k, v in b.state_dict().items()})
    if kind == "dev":
        xs = [x for j in pair for x in C.chat_recalls(b, CH[j])]
        out.update(sum=float(np.sum(xs)), n=len(xs))
    elif kind == "test":
        out["per"] = {j: C.chat_recalls(b, CH[j]) for j in C.FOLDS[f]}
    return spec, out


def to_bridge(state, dim):
    b = C.Bridge(dim, RANK)
    b.load_state_dict({k: torch.as_tensor(v) for k, v in state.items()})
    return b


def bridges(chats, dim, procs=2, lme=True):
    """s11's rank-16 bridges for one vector space. Returns picks, LME lr, dev and held-out tables, bridge states
    (outer<f>, inner<f>_<pair[0]>, all) and the outer bridges' per-question dense recall at the picked lr."""
    _G.update(chats=chats, dim=dim)
    specs = [("dev", f, lr, p) for f in range(5) for lr in LRS for p in C.inner_pairs(train_ids(f))]
    specs += [("test", f, lr, None) for f in range(5) for lr in LRS]
    res = _pool(_bridge_job, specs, procs, f"bridges d={dim}")
    picks, dev = [], {}
    for f in range(5):
        pairs = C.inner_pairs(train_ids(f))
        d = {lr: sum(res[("dev", f, lr, p)]["sum"] for p in pairs) / sum(res[("dev", f, lr, p)]["n"] for p in pairs)
             for lr in LRS}
        picks.append(max(LRS, key=lambda lr: (d[lr], -lr))); dev[f"fold{f}"] = {str(lr): round(v, 4) for lr, v in d.items()}
    held = {lr: round(float(np.array([x for f in range(5) for i in C.FOLDS[f]
                                      for x in res[("test", f, lr, None)]["per"][i]]).mean()), 4) for lr in LRS}
    lme_lr = max(LRS, key=lambda lr: (held[lr], -lr))
    states = {f"outer{f}": res[("test", f, picks[f], None)]["state"] for f in range(5)}
    states.update({f"inner{f}_{p[0]}": res[("dev", f, picks[f], p)]["state"]
                   for f in range(5) for p in C.inner_pairs(train_ids(f))})
    if lme:
        states["all"] = _bridge_job(("all", -1, lme_lr, None))[1]["state"]
    dense = np.array([x for f in range(5) for i in C.FOLDS[f] for x in res[("test", f, picks[f], None)]["per"][i]])
    return dict(picks=picks, lme_lr=lme_lr if lme else None, dev=dev, heldout={str(k): v for k, v in held.items()},
                states=states, outer_dense=dense)


def inner_name(f, j):
    """The inner bridge of fold f that held training chat j's pair out."""
    return f"inner{f}_{C.FOLDS[j // 2][0]}"


# ---------------------------------------------------------------- (b) score matrices and reads

def score_rows(K, S):
    """Row r = K @ S[r], computed per question exactly as stage 1 does (matrix-vector, float32)."""
    return np.stack([K @ S[r] for r in range(len(S))])


def space_mats(sp, B, items=None):
    """Score matrices of a space under its bridges B (name -> Bridge): outer[i], inner[(f, j)], frozen[i]; for
    LongMemEval-S (items given) per item lme_cb (all-chat bridge, states in one batch as retrieval.Reader) and lme_cf."""
    ch = sp["chats"]
    m = dict(outer=[score_rows(*B[f"outer{i // 2}"].views(ch[i]["nodes"], ch[i]["asks"])) for i in range(10)],
             frozen=[score_rows(ch[i]["nodes"], ch[i]["asks"]) for i in range(10)], inner={})
    for f in range(5):
        for j in train_ids(f):
            m["inner"][(f, j)] = score_rows(*B[inner_name(f, j)].views(ch[j]["nodes"], ch[j]["asks"]))
    if items is not None:
        Q = sp["lme"]["Q"]; b = B["all"]; st = b.state_np(Q)
        m["lme_cb"] = [b.key_np(lme_nodes(sp, it)) @ st[t] for t, it in enumerate(items)]
        m["lme_cf"] = [lme_nodes(sp, it) @ Q[t] for t, it in enumerate(items)]
    return m


def recalls(rows, evs, lexorders):
    """Per-question recall@10 of the dense order of each score row, and of it fused with BM25 (RRF k 60)."""
    dense, fused = [], []
    for s, ev, lex in zip(rows, evs, lexorders):
        o = C.order_of(s)
        dense.append(C.recall(o, ev)); fused.append(C.recall(C.fuse(lex, o), ev))
    return np.array(dense), np.array(fused)


def loc_recalls(chats, mats):
    """recalls() over the 10 LoCoMo chats in order (mats: one [nq, n] matrix per chat), concatenated."""
    d, f = zip(*[recalls(m, [q[1] for q in ch["qs"]], ch["lexorder"]) for ch, m in zip(chats, mats)])
    return np.concatenate(d), np.concatenate(f)


def lme_recalls(items, rows):
    return recalls(rows, [it["ev"] for it in items], [it["lexorder"] for it in items])


# ---------------------------------------------------------------- (c) ranker

def qrows(cb, cf, bm, lex, st, qt, ev, extra=None):
    """s111's feature rows for one question's fused top 50 (s111_baselines.qfeats), plus optional extra columns."""
    X, cand, fused = S111.qfeats(cb, cf, bm, lex, st, qt)
    if extra is not None:
        X = np.hstack([X, extra(cand)]).astype(np.float32)
    return (X, cand, np.isin(cand, ev).astype(np.float32), ev, fused)


def chat_rows(ch, CB, CF, xf=None):
    """s111_baselines.chat_feats for any score matrices; xf(r) gives question r's extra-column function or None."""
    return [qrows(CB[r], CF[r], ch["_bm"][r][1], ch["lexorder"][r], ch["_static"], ch["_bm"][r][0], q[1],
                  None if xf is None else xf(r)) for r, q in enumerate(ch["qs"])]


def ranker(chats, cb_of, cf_of, items=None, lme_cb=None, lme_cf=None, xf_of=None, lme_xf=None, fixed=False, procs=2,
           what="ranker"):
    """s111's ranker on any score sources. cb_of(tag, j) -> bridge-score matrix [nq, n] of LoCoMo chat j under tag
    "outer" or ("inner", f); cf_of(j) -> frozen-score matrix. fixed=True: the scorer does not depend on the tag (no
    training chats), so inner rows are the outer rows. xf_of(tag, j) -> function r -> (cand -> extra columns), optional.
    LongMemEval-S is scored if items and lme_cb, lme_cf (one score vector per item) are given.
    Returns per-question recall@10 (LoCoMo in chat order, LongMemEval-S in item order), picks and dev tables."""
    t0 = time.time()
    FEAT = {}
    for i in range(10):
        FEAT[("outer", i)] = chat_rows(chats[i], cb_of("outer", i), cf_of(i), xf_of and xf_of("outer", i))
    for f in range(5):
        for j in train_ids(f):
            FEAT[(("inner", f), j)] = FEAT[("outer", j)] if fixed else chat_rows(
                chats[j], cb_of(("inner", f), j), cf_of(j), xf_of and xf_of(("inner", f), j))
    FEAT_LME = None
    if items is not None and lme_cb is not None:
        FEAT_LME = [qrows(lme_cb[t], lme_cf[t], it["_bm"][1], it["lexorder"], it["_static"], it["_bm"][0], it["ev"],
                          None if lme_xf is None else lme_xf(t)) for t, it in enumerate(items)]
    log(f"  {what}: features built ({time.time() - t0:.0f}s)")
    S111.FEAT, S111.FEAT_LME = FEAT, FEAT_LME
    specs = [(k, f, o, lv) for k in ("rk_dev", "rk_test") for f in range(5) for o, lv in FITS]
    if FEAT_LME is not None:
        specs += [("rk_lme", -1, o, lv) for o, lv in FITS]
    RES = _pool(S111.job, specs, procs, what)
    out = select(RES, FEAT_LME is not None)
    out["base_fused"] = np.array([C.recall(x[4], x[3]) for i in range(10) for x in FEAT[("outer", i)]])
    out["feature_sha256_12"] = feature_digest(FEAT, FEAT_LME)
    out["feat"] = FEAT
    out["feat_lme"] = FEAT_LME
    return out


def feature_digest(FEAT, FEAT_LME=None):
    """sha256[:12] of the ranker's input rows (features, candidates, labels) over every tag, and over LongMemEval-S, so two
    runs can be checked for identical inputs."""
    h = hashlib.sha256()
    for k in sorted(FEAT, key=str):
        for x in FEAT[k]:
            h.update(x[0].tobytes()); h.update(np.asarray(x[1]).tobytes()); h.update(x[2].tobytes())
    out = dict(locomo=h.hexdigest()[:12])
    if FEAT_LME is not None:
        h = hashlib.sha256()
        for x in FEAT_LME:
            h.update(x[0].tobytes()); h.update(np.asarray(x[1]).tobytes()); h.update(x[2].tobytes())
        out["lme"] = h.hexdigest()[:12]
    return out


def select(RES, with_lme):
    """s111's selection: per fold the config with the best mean dev recall (ties first in grid order); LongMemEval-S the
    config with the best pooled dev recall over the 5 folds."""
    rk_dev = {(f,) + g: RES[("rk_dev", f, g[0], g[1])][g[2]] for f in range(5) for g in GRID}
    pick = {f: max(GRID, key=lambda g: (float(rk_dev[(f,) + g].mean()), -GRID.index(g))) for f in range(5)}
    pooled = {g: float(np.concatenate([rk_dev[(f,) + g] for f in range(5)]).mean()) for g in GRID}
    lme_pick = max(GRID, key=lambda g: (pooled[g], -GRID.index(g)))
    loc = np.concatenate([RES[("rk_test", f, pick[f][0], pick[f][1])][pick[f][2]] for f in range(5)])
    out = dict(locomo=loc, picks={str(f): list(map(str, pick[f])) for f in range(5)},
               dev={f"fold{f}": {"/".join(map(str, g)): round(float(rk_dev[(f,) + g].mean()), 4) for g in GRID}
                    for f in range(5)},
               pooled={"/".join(map(str, g)): round(pooled[g], 4) for g in GRID}, lme_pick=list(map(str, lme_pick)),
               lme=None)
    if with_lme:
        out["lme"] = RES[("rk_lme", -1, lme_pick[0], lme_pick[1])][lme_pick[2]]
    return out


# ---------------------------------------------------------------- one whole space

READS = ("frozen_dense", "frozen_fused", "bridge_dense", "bridge_fused", "ranker")


def run_space(sp, data, procs=2, cache_dir=CACHE_DIR, use_lme=True, keep=False):
    """Bridges, reads and ranker for one vector space. Cached in cache_dir by a fingerprint of the vectors and the code.
    Returns dict(tag, dim, bridges (picks, tables, states), ranker (picks, tables), reads {locomo_<read>, lme_<read>})."""
    use_lme = bool(use_lme and sp["lme"] is not None and data["items"] is not None)
    fp = fingerprint(sp, use_lme)
    path = os.path.join(cache_dir, f"{sp['tag']}_{fp[:16]}.npz") if cache_dir else None
    if path and os.path.exists(path) and not keep:
        log(f"{sp['tag']}: cached run {path}")
        return load_result(path)
    t0 = time.time()
    log(f"{sp['tag']}: d = {sp['dim']}, LongMemEval-S {'on' if use_lme else 'off'}")
    br = bridges(sp["chats"], sp["dim"], procs, lme=use_lme)
    B = {k: to_bridge(v, sp["dim"]) for k, v in br["states"].items()}
    m = space_mats(sp, B, data["items"] if use_lme else None)
    reads = {}
    reads["locomo_frozen_dense"], reads["locomo_frozen_fused"] = loc_recalls(sp["chats"], m["frozen"])
    reads["locomo_bridge_dense"], reads["locomo_bridge_fused"] = loc_recalls(sp["chats"], m["outer"])
    assert np.array_equal(reads["locomo_bridge_dense"], br["outer_dense"])
    if use_lme:
        reads["lme_frozen_dense"], reads["lme_frozen_fused"] = lme_recalls(data["items"], m["lme_cf"])
        reads["lme_bridge_dense"], reads["lme_bridge_fused"] = lme_recalls(data["items"], m["lme_cb"])
    rk = ranker(sp["chats"], lambda tag, j: m["outer"][j] if tag == "outer" else m["inner"][(tag[1], j)],
                lambda j: m["frozen"][j], items=data["items"] if use_lme else None,
                lme_cb=m.get("lme_cb"), lme_cf=m.get("lme_cf"), procs=procs, what=f"ranker {sp['tag']}")
    assert np.array_equal(rk["base_fused"], reads["locomo_bridge_fused"])
    reads["locomo_ranker"] = rk["locomo"]
    if use_lme:
        reads["lme_ranker"] = rk["lme"]
    res = dict(tag=sp["tag"], dim=sp["dim"], fingerprint=fp, use_lme=use_lme, seconds=round(time.time() - t0),
               bridges={k: br[k] for k in ("picks", "lme_lr", "dev", "heldout")}, states=br["states"],
               ranker={k: rk[k] for k in ("picks", "dev", "pooled", "lme_pick", "feature_sha256_12")}, reads=reads)
    res["means"] = {k: round(float(v.mean()), 4) for k, v in reads.items()}
    if path:
        save_result(path, res)
    if keep:
        res["_mats"], res["_feat"], res["_feat_lme"] = m, rk["feat"], rk["feat_lme"]
    log(f"{sp['tag']}: {json.dumps(res['means'])} ({res['seconds']}s)")
    return res


def save_result(path, res):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    meta = {k: v for k, v in res.items() if k not in ("reads", "states")}
    arrs = {f"r__{k}": v for k, v in res["reads"].items()}
    arrs.update({f"s__{b}__{p}": v for b, st in res["states"].items() for p, v in st.items()})
    np.savez(path + ".tmp.npz", meta=json.dumps(meta), **arrs)
    os.replace(path + ".tmp.npz", path)


def load_result(path):
    z = np.load(path, allow_pickle=False)
    res = json.loads(str(z["meta"])); res["reads"], res["states"] = {}, {}
    for k in z.files:
        if k.startswith("r__"):
            res["reads"][k[3:]] = z[k]
        elif k.startswith("s__"):
            _, b, p = k.split("__"); res["states"].setdefault(b, {})[p] = z[k]
    return res


def mats_of(res, sp, items=None):
    """Rebuild a finished run's score matrices from its stored bridge states (LongMemEval-S too if items are given)."""
    B = {k: to_bridge(v, sp["dim"]) for k, v in res["states"].items()}
    return space_mats(sp, B, items if (items is not None and "all" in B) else None)


# ---------------------------------------------------------------- statistics

def signflip(diff, cl):
    """Exact chat sign-flip p over all 2^G sign vectors, s112's statistic T(e) = sum_j e_j D_j / N.
    Returns (one-sided p = share with T >= observed [s112's convention], two-sided p = share with |T| >= |observed|)."""
    diff = np.asarray(diff, dtype=np.float64)
    _, inv_ = np.unique(np.asarray(cl), return_inverse=True)
    D = np.bincount(inv_, weights=diff); G = len(D)
    E = 1.0 - 2.0 * ((np.arange(2 ** G)[:, None] >> np.arange(G)[None, :]) & 1)
    T = E @ D / len(diff); obs = D.sum() / len(diff)
    return float((T >= obs - 1e-12).mean()), float((np.abs(T) >= abs(obs) - 1e-12).mean())


def compare(diff, cl, exact=True):
    """Paired difference: mean, cluster bootstrap 95% CI and (exact=True) the chat sign-flip p values and per-chat means."""
    m, ci = C.cluster_boot(diff, cl)
    d = dict(n=int(len(diff)), mean=m, ci=ci, ci_above_0=bool(ci[0] > 0))
    if exact:
        d["signflip_p_one_sided"], d["signflip_p_two_sided"] = signflip(diff, cl)
        cl = np.asarray(cl)
        d["per_chat"] = [float(np.asarray(diff)[cl == j].mean()) for j in np.unique(cl)]
    return d


def holm(pvals, m=None):
    """Holm-adjusted p values. pvals: {name: p or None (not run yet)}; m: family size (default len(pvals)).
    An unknown p makes the adjusted p of the others an interval: [value with unknowns at 0, value with unknowns at 1]
    (Holm's adjusted p is non-decreasing in every raw p)."""
    names = list(pvals); m = m or len(names)

    def adj(ps):
        order = sorted(range(len(ps)), key=lambda i: ps[i]); out = [0.0] * len(ps); run = 0.0
        for rank, i in enumerate(order):
            run = max(run, min(1.0, (m - rank) * ps[i])); out[i] = run
        return out
    lo = adj([0.0 if pvals[n] is None else pvals[n] for n in names] + [0.0] * (m - len(names)))
    hi = adj([1.0 if pvals[n] is None else pvals[n] for n in names] + [1.0] * (m - len(names)))
    return {n: (None if pvals[n] is None else [lo[i], hi[i]]) for i, n in enumerate(names)}


def rnd(x, k=6):
    if isinstance(x, dict):
        return {a: rnd(b, k) for a, b in x.items()}
    if isinstance(x, (list, tuple)):
        return [rnd(b, k) for b in x]
    if isinstance(x, (float, np.floating)):
        return round(float(x), k)
    if isinstance(x, np.integer):
        return int(x)
    if isinstance(x, np.bool_):
        return bool(x)
    return x


# ---------------------------------------------------------------- regression against stage 1

def stage1_reads(data):
    """Per-question rank-16 bridge reads (dense and fused) with the stored stage 1 bridges (s11_models.npz), computed as
    retrieval.Reader does: LoCoMo, and LongMemEval-S when it is loaded."""
    from retrieval import load_bridge
    z = np.load(os.path.join(C.CACHE, "s11_models.npz")); chats, items = data["chats"], data["items"]
    out = {}
    out["locomo_bridge_dense"], out["locomo_bridge_fused"] = loc_recalls(
        chats, [score_rows(*load_bridge(z, f"f{i // 2}_r16").views(c["nodes"], c["asks"])) for i, c in enumerate(chats)])
    if items is not None:
        lb = load_bridge(z, "all_r16"); st = lb.state_np(np.array([it["q"] for it in items]))
        out["lme_bridge_dense"], out["lme_bridge_fused"] = lme_recalls(
            items, [lb.key_np(data["vec"][it["rows"]]) @ st[t] for t, it in enumerate(items)])
    return out


def check_reference(ref, data):
    """The bge-small run against stage 1: per-question bridge reads equal to the stored stage 1 bridges' reads, and the
    stage 1 means (bridge 0.6622, fused 0.6553, ranker 0.7492, LongMemEval-S ranker 0.9187). Returns (ok, report)."""
    s1 = stage1_reads(data)
    dev = {k: float(np.abs(ref["reads"][k] - v).max()) for k, v in s1.items()}
    want = dict(locomo_bridge_dense=0.6622, locomo_bridge_fused=0.6553, locomo_ranker=0.7492)
    if data["items"] is not None:
        want["lme_ranker"] = 0.9187
    means = {k: round(float(ref["reads"][k].mean()), 4) for k in want}
    ok = all(v == 0 for v in dev.values()) and means == want
    return ok, dict(max_abs_dev_per_question_vs_stage1_bridges=dev, means=means, stage1=want, ok=ok)


def regress(procs, out_path, cache_dir=CACHE_DIR):
    from retrieval import load_bridge
    t0 = time.time()
    data = load_data(lme=True); CH = data["chats"]; items = data["items"]
    sp = space_stage1(data)
    res = run_space(sp, data, procs, cache_dir=None, keep=True)
    rep = dict(seconds_pipeline=round(time.time() - t0))
    s11 = json.load(open(os.path.join(STAGE1, "results", "s11_rank.json")))
    s111 = json.load(open(os.path.join(STAGE1, "results", "s111_baselines.json")))
    rep["lr_picks"] = dict(here=res["bridges"]["picks"], s11=s11["picks"]["r16"], lme_here=res["bridges"]["lme_lr"],
                           lme_s11=s11["lme"]["r16"]["lr"])
    dev_ok = all(res["bridges"]["dev"][f"fold{f}"][str(lr)] == s11["by_lr"]["r16"][f"fold{f}_dev"][str(lr)]
                 for f in range(5) for lr in LRS)
    held_ok = all(res["bridges"]["heldout"][str(lr)] == s11["by_lr"]["r16"][f"heldout_{lr}"] for lr in LRS)
    rep["s11_tables_equal"] = dict(dev=dev_ok, heldout=held_ok)
    # bridge weights against the stage 1 models and stage2/results/r16_bridges.npz
    z = np.load(os.path.join(C.CACHE, "s11_models.npz")); z2 = np.load(os.path.join(HERE, "results", "r16_bridges.npz"))
    names = [(f"outer{f}", f"f{f}_r16") for f in range(5)] + [("all", "all_r16")]
    wdiff = lambda zz: max(float(np.abs(res["states"][a][k] - zz[f"{b}_{k}"]).max())  # noqa: E731
                           for a, b in names for k in res["states"][a])
    rep["bridge_weights_max_abs_diff"] = dict(s11_models=wdiff(z), r16_bridges=wdiff(z2))
    # stage 1 reads per question with the stored stage 1 bridges (retrieval.Reader's computation)
    sb = {f: load_bridge(z, f"f{f}_r16") for f in range(5)}
    ref_d, ref_f = [], []
    for i, c in enumerate(CH):
        K, S = sb[i // 2].views(c["nodes"], c["asks"])
        for r, q in enumerate(c["qs"]):
            o = C.order_of(K @ S[r])
            ref_d.append(C.recall(o, q[1])); ref_f.append(C.recall(C.fuse(c["lexorder"][r], o), q[1]))
    ref_d, ref_f = np.array(ref_d), np.array(ref_f)
    lb = load_bridge(z, "all_r16"); lst = lb.state_np(np.array([it["q"] for it in items]))
    lkeys = [lb.key_np(data["vec"][it["rows"]]) for it in items]
    lref = lme_recalls(items, [lkeys[t] @ lst[t] for t in range(len(items))])
    R = res["reads"]

    def vs(k, ref_, **pub):
        return dict(here=float(R[k].mean()), stage1=float(ref_.mean()), max_abs_dev=float(np.abs(R[k] - ref_).max()), **pub)
    rep["reads"] = dict(
        locomo_bridge_dense=vs("locomo_bridge_dense", ref_d, s11=s11["locomo"]["r16"]["dense"]),
        locomo_bridge_fused=vs("locomo_bridge_fused", ref_f, s11=s11["locomo"]["r16"]["hybrid"]),
        locomo_frozen=dict(dense=float(R["locomo_frozen_dense"].mean()), fused=float(R["locomo_frozen_fused"].mean()),
                           s11=s11["locomo"]["frozen"]),
        lme_bridge_dense=vs("lme_bridge_dense", lref[0], s111=s111["lme"]["dense_rank16"]),
        lme_bridge_fused=vs("lme_bridge_fused", lref[1], s111=s111["lme"]["fused_rank16"]),
        lme_frozen=dict(dense=float(R["lme_frozen_dense"].mean()), fused=float(R["lme_frozen_fused"].mean()),
                        s11=s11["lme"]["frozen"]))
    log("reads vs stage 1:", json.dumps(rnd(rep["reads"], 4)))
    # reference ranker: s111's own code (chat_feats, bridge job, rk jobs) on the stored stage 1 bridges
    S111.CH = CH; S111.LR16 = s11["picks"]["r16"]
    specs = [("bridge", f, p) for f in range(5) for p in C.inner_pairs(train_ids(f))]
    inner = {s[1:]: to_bridge(v, 384) for s, v in _pool(S111.job, specs, procs, "s111 inner bridges").items()}
    rep["inner_bridge_max_abs_diff_vs_s111_job"] = max(
        float(np.abs(res["states"][f"inner{f}_{p[0]}"][k] - inner[(f, p)].state_dict()[k].numpy()).max())
        for (f, p) in inner for k in res["states"][f"inner{f}_{p[0]}"])
    RF = {}
    for i in range(10):
        RF[("outer", i)] = S111.chat_feats(i, *sb[i // 2].views(CH[i]["nodes"], CH[i]["asks"]))
    for f in range(5):
        for j in train_ids(f):
            b = inner[(f, C.FOLDS[j // 2])]
            RF[(("inner", f), j)] = S111.chat_feats(j, *b.views(CH[j]["nodes"], CH[j]["asks"]))
    RFL = []
    for t, it in enumerate(items):
        qt = C.tokens(it["question"]); cb = lkeys[t] @ lst[t]; cf = data["vec"][it["rows"]] @ it["q"]
        X, cand, fused = S111.qfeats(cb, cf, it["bm25"].scores(qt), it["lexorder"], it["_static"], qt)
        RFL.append((X, cand, np.isin(cand, it["ev"]).astype(np.float32), it["ev"], fused))
    mine = res["_feat"]
    rep["bm25_lists_changed_vs_this_process_common"] = data["bm25_lists_changed"]
    rep["feature_max_abs_diff"] = dict(
        locomo=max(float(np.abs(a[0] - b[0]).max()) for k in RF for a, b in zip(RF[k], mine[k])),
        locomo_candidates_equal=all(np.array_equal(a[1], b[1]) for k in RF for a, b in zip(RF[k], mine[k])),
        lme=max(float(np.abs(a[0] - b[0]).max()) for a, b in zip(RFL, res["_feat_lme"])))
    S111.FEAT, S111.FEAT_LME = RF, RFL
    specs = [(k, f, o, lv) for k in ("rk_dev", "rk_test") for f in range(5) for o, lv in FITS]
    specs += [("rk_lme", -1, o, lv) for o, lv in FITS]
    ref = select(_pool(S111.job, specs, procs, "s111 reference ranker"), True)
    rep["ranker"] = dict(
        picks_here=res["ranker"]["picks"], picks_s111=s111["picks"]["ranker"], lme_pick_here=res["ranker"]["lme_pick"],
        lme_pick_s111=s111["picks"]["ranker_lme"], picks_reference=ref["picks"],
        locomo=dict(here=float(R["locomo_ranker"].mean()), reference=float(ref["locomo"].mean()),
                    s111=s111["locomo"]["ranker"]["fused"],
                    max_abs_dev=float(np.abs(R["locomo_ranker"] - ref["locomo"]).max())),
        lme=dict(here=float(R["lme_ranker"].mean()), reference=float(ref["lme"].mean()), s111=s111["lme"]["ranker"],
                 max_abs_dev=float(np.abs(R["lme_ranker"] - ref["lme"]).max())))
    rep["check_reference"] = check_reference(res, data)[1]
    rk = rep["ranker"]
    ok = (rep["lr_picks"]["here"] == rep["lr_picks"]["s11"] and rep["lr_picks"]["lme_here"] == rep["lr_picks"]["lme_s11"]
          and dev_ok and held_ok
          and all(rep["reads"][k]["max_abs_dev"] == 0 for k in ("locomo_bridge_dense", "locomo_bridge_fused",
                                                                "lme_bridge_dense", "lme_bridge_fused"))
          and round(rep["reads"]["locomo_bridge_dense"]["here"], 4) == 0.6622
          and round(rep["reads"]["locomo_bridge_fused"]["here"], 4) == 0.6553
          and rk["picks_here"] == s111["picks"]["ranker"] and rk["lme_pick_here"] == s111["picks"]["ranker_lme"]
          and rk["locomo"]["max_abs_dev"] == 0 and rk["lme"]["max_abs_dev"] == 0
          and round(rk["locomo"]["here"], 4) == 0.7492 and round(rk["lme"]["here"], 4) == 0.9187
          and rep["check_reference"]["ok"])
    rep["pass"] = bool(ok); rep["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    json.dump(rnd(rep, 6), open(out_path, "w"), indent=1)
    # keep the verified bge-small run in the cache so s22 and s23b reuse it
    res_c = {k: v for k, v in res.items() if not k.startswith("_")}
    save_result(os.path.join(cache_dir, f"bge-small_{res['fingerprint'][:16]}.npz"), res_c)
    log(json.dumps(rnd(rep, 6), indent=1))
    log(f"REGRESSION {'PASS' if ok else 'FAIL'} ({rep['seconds']}s); wrote {out_path}")
    if not ok:
        raise SystemExit(1)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--regress", action="store_true", help="reproduce stage 1 with the bge-small vectors")
    p.add_argument("--procs", type=int, default=2, help="single-threaded worker processes")
    p.add_argument("--out", default=os.path.join(SCRATCH, "regress.json"))
    p.add_argument("--cache-dir", default=CACHE_DIR, help="where the verified bge-small run is cached for s22 and s23b")
    a = p.parse_args()
    if os.path.abspath(a.out).startswith(os.path.join(HERE, "results")):
        raise SystemExit("the regression report goes to the scratch directory, not results/")
    if a.regress:
        regress(a.procs, a.out, a.cache_dir)
    else:
        p.print_help()


if __name__ == "__main__":
    main()
