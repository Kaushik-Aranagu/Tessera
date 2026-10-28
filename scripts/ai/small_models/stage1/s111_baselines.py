#!/usr/bin/env python3
"""Stage 1.11: prior-art baselines on the same cites (required for the paper).

Question. Does our best use-driven key rule (s12_cites.RULES, run with s12_cites.run_order) at least match two prior-art
baselines: (a) RMM-style residual heads trained online by REINFORCE from the reader's cites (Tan et al., ACL 2025), and
(b) an LLM-free learned ranker in the AgentMemRec style (a LightGBM ranker trained on gold evidence)?

Data. Public only: LoCoMo (1,536 questions, sha-pinned) and LongMemEval-S (428 questions with user-turn evidence).
Cites come from runs/answers_hop0.jsonl (Haiku's hop-0 reads; rows with kind "read", "cites" are snippet numbers n,
mapped to nodes through the hop-0 task's snippets). The opened set of a question is the 10 snippet nodes of its hop-0
task (the fused rank-16 top 10 the reader saw). Cite sources (option --cites):
  haiku    what Haiku cited (the real signal; used only if the answers file has at least 3,900 rows)
  visible  the marked evidence inside the opened top 10 (reference oracle)
If the answers file is missing or short, only "visible" is run and the report says so. --answers points at another
answers file, so the test can be re-run on new Haiku cites.

Shared protocol (from s12_cites.py, unchanged). LoCoMo chat i is read with the rank-16 bridge of the outer fold that
held it out (retrieval.Reader keys). Each chat is run in the same 3 shuffled orders,
np.random.default_rng([chat, order, 2027]).permutation; after each question the method learns from that question's cites
(static cites: what was cited from the hop-0 opened top 10, not re-read after anything moves); recall@10 of the dense
list and of the dense list fused with BM25 (RRF k 60) is scored before that question's update; per question the 3 orders
are averaged. Every learner is reset at the start of each chat and order (learning is within a held-out chat only).

Arms on LoCoMo (per cite source):
  base    no learning: the rank-16 read (dense 0.662, fused 0.655 in s11/s12; recomputed here)
  ours    each of the 5 s12 rules (move η0.1, move η0.05, contrastive, centred, combo; settings fixed in s12), the mean
          state of the centred rules frozen per bridge (mean ask state of that bridge's training chats).
  RMM     residual linear heads on the question state and on the memory keys, in the tuned rank-16 bridge space:
          q' = n(s + W_q s), k'_v = n(k_v + W_k k_v), W_q and W_k 384 x 384, initialised at zero (so the first read is
          exactly the base read). Dense list: order of q'.k'. After each question one REINFORCE step on the cites:
          reward r_v = +1 for an opened node that was cited, -1 for an opened node not cited (REINFORCE baseline b = 0),
          policy pi = softmax(alpha q'.k') with alpha = 20 (the bridges' fixed logit scale) over a pool P, objective
          J = sum over opened v of r_v log pi(v), one plain SGD ascent step W <- W + lr dJ/dW on both heads.
          Off-policy note: the opened set is the logged hop-0 read, not a sample from the current heads (as for our
          rules). Tuned on dev chats only: pool P in {opened (softmax over the 10 opened, RMM's reranker over its
          retrieved set), chat (softmax over every node)} x lr in {1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1}.
          Gradients are written by hand (numpy) and checked against torch autograd at start-up (reported).
  ranker  LightGBM over the top 50 candidates of each question's fused rank-16 read; the reranked top 10 is scored, so
          it can only reorder those 50. Labels: 1 for a marked evidence node, else 0. Features (25, all LLM-free):
            bridge cosine, frozen bge cosine, BM25 score; log(1 + rank) in the bridge, frozen and BM25 lists; position in
            the fused list; RRF score; bridge cosine minus the best candidate's; frozen cosine minus the best
            candidate's; BM25 over the best candidate's BM25; z-score of the bridge cosine among the 50; log(1 + turn
            length in BM25 tokens); position in the whole history (0..1); session index (0..1, oldest 0); position
            inside the session (0..1); query-token overlap count; overlap fraction; query length in tokens; best bridge
            cosine of the turn's neighbours in its session (itself if none); same session as the fused top 1;
            share of the 50 candidates in the turn's session; log(history size); bridge cosine of the session's best
            turn among the 50 minus the turn's; neighbour in the fused top 10.
          LoCoMo: for outer fold f, trained on the gold evidence of its 8 training chats, scored on the test pair. The
          bridge features of a training chat come from an inner rank-16 bridge that held that chat's pair out (trained
          on the other 6 training chats with fold f's tuned lr and s11's dev seed 1000 + 10 f + pair[0]); the test pair
          uses the outer bridge, as the read does. So no feature of any chat comes from a bridge that saw its labels.
          Hyperparameters, chosen on dev chats only: objective {lambdarank, binary} x num_leaves {7, 31} x trees
          {50, 100, 200, 400} (learning rate 0.05, min 20 rows per leaf, no subsampling, deterministic, one thread),
          fit on the 6 training chats outside the dev pair, scored on the dev pair.
          LongMemEval-S: trained on all 10 LoCoMo chats (bridge features from the bridge that held each chat out); the
          config with the best pooled dev recall over the 5 LoCoMo folds; scored on the 428 questions with features from
          the rank-16 bridge trained on all 10 LoCoMo chats (the read of retrieval.Reader).

Dev chats and selection (no test chat is used to choose anything). For outer fold f the dev chats are the test pair of
fold (f + 1) mod 5 (they are training chats of fold f). Dev runs read them with fold f's inner bridge that held that pair
out (never trained on fold f's test chats), centred rules use that inner bridge's mean ask state, and the cites and
opened sets are the same logged hop-0 ones. Per fold, cite source and metric (dense or fused recall@10): "ours" is the
s12 rule with the best mean dev recall (ties: first in s12's RULES order) and RMM's config is the one with the best mean
dev recall (ties: first in grid order, pool then lr). The ranker's config per fold is its best dev fused recall.

Pre-registered decision rule (front matter table, test 1.11: "our best rule at least matches them, [chat]"; fails if "a
baseline wins"). PRIMARY: LoCoMo, cite source haiku (visible if haiku is unavailable), metric fused recall@10 (the list the
reader opens), ours = the dev-selected rule. d_RMM = ours - RMM(dev-selected), d_RK = ours - ranker, per question, with
a chat-clustered paired bootstrap (common.cluster_boot, 4,000 draws, seed 0) for the 95% interval.
  PASS iff the point estimates of d_RMM and d_RK are both >= 0.
  FAIL otherwise; a failing baseline whose interval for (ours - baseline) lies wholly below zero is reported as a clear win
  for that baseline, otherwise as a win by point estimate only.
Secondary, reported, not part of the verdict: the visible-oracle cites; dense recall (ours vs RMM, each dev-selected on
dense); every fixed rule against each baseline; the post-hoc best rule on the test chats (optimistic for ours); RMM with
its config picked on the test chats (optimistic for RMM); multi-hop means; per-chat signs. LongMemEval-S: one question per
haystack, so neither our rules nor online RMM can learn there (nothing is asked twice; RMM is not run on it); "ours" is the
fused rank-16 read itself, and the ranker is compared with it under a question-clustered bootstrap. If the ranker beats
the fused read there with an interval above zero, the report says a baseline wins on LongMemEval-S, where our rules
cannot act. Compute: about 25 CPU minutes; nothing cut from the plan above.

POST-HOC (added after the pre-registered run had produced its verdict; never part of the verdict; --posthoc, written
into the same JSON under "post_hoc"): the ranker's gain was much larger than expected, so it is checked for leaks: the
recall@50 ceiling of the fused read; the same ranker trained with each training question's labels swapped for another
training question's (keeps the position prior, breaks the link to content); feature-group ablations (scores only, no
context features) and LightGBM gain importances. RMM's dev picks sat at the bottom of its lr grid, so RMM is re-run with
lr 1e-5 and 3e-5 added and re-selected on dev chats by the same rule.

Usage: python s111_baselines.py [--cites auto|haiku,visible|visible] [--answers runs/answers_hop0.jsonl] [--procs 3]
       python s111_baselines.py --posthoc --cache <runs.pkl>   (after a full run with --cache)
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(_v, "1")

import argparse, collections, json, re, sys, time  # noqa: E402
from multiprocessing import Pool  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
from retrieval import Reader, load_bridge  # noqa: E402

RMM_POOLS = ("opened", "chat")
RMM_LRS = (1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1)
RK_OBJ = ("lambdarank", "binary")
RK_LEAVES = (7, 31)
RK_TREES = (50, 100, 200, 400)
TOPN = 50
MIN_ANSWER_ROWS = 3900

# globals filled in the parent before the worker pools fork
R = CH = OPENED = CITES = ORDERS = KEYS = FEAT = FEAT_LME = LR16 = None


def train_ids(f):
    return [j for j in range(10) if j not in C.FOLDS[f]]


def dev_pair(f):
    return C.FOLDS[(f + 1) % 5]


# ---------------------------------------------------------------- RMM heads

def rmm_grad(K, A, s, Wq, O, rew, pool, alpha=C.ALPHA):
    """dJ/dW_q and dJ/dA over the pool rows, J = sum_{v in O} r_v log softmax_P(alpha q'.k')_v.
    A = K + K W_k^T (so dJ/dW_k = dA^T K[P]); q' = n(s + W_q s)."""
    b = s + Wq @ s; nb = np.linalg.norm(b); qp = b / nb
    P = O if pool == "opened" else np.arange(len(K))
    AP = A[P]; na = np.linalg.norm(AP, axis=1); KP = AP / na[:, None]
    lg = alpha * (KP @ qp); lg = lg - lg.max(); pi = np.exp(lg); pi /= pi.sum()
    g = -rew.sum() * pi
    if pool == "opened":
        g = g + rew
    else:
        g[O] += rew
    dqp = alpha * (g @ KP); dKP = alpha * np.outer(g, qp)
    db = (dqp - qp * (qp @ dqp)) / nb
    dA = (dKP - KP * (KP * dKP).sum(1, keepdims=True)) / na[:, None]
    return np.outer(db, s), dA, P


def grad_check():
    """Compare the hand-written gradients with torch autograd on random data (both pools)."""
    rng = np.random.default_rng(7); n, d = 40, 16; out = {}
    K = C.unit(rng.standard_normal((n, d))); s = C.unit(rng.standard_normal(d))
    Wq = 0.1 * rng.standard_normal((d, d)); Wk = 0.1 * rng.standard_normal((d, d))
    O = rng.choice(n, 10, replace=False); rew = np.where(rng.random(10) < 0.3, 1.0, -1.0)
    for pool in RMM_POOLS:
        A = K + K @ Wk.T
        gq, dA, P = rmm_grad(K, A, s, Wq, O, rew, pool)
        gk = dA.T @ K[P]
        tq = torch.tensor(Wq, requires_grad=True); tk = torch.tensor(Wk, requires_grad=True)
        tK = torch.tensor(K); ts = torch.tensor(s)
        q = torch.nn.functional.normalize(ts + tq @ ts, dim=0)
        keys = torch.nn.functional.normalize(tK + tK @ tk.T, dim=1)
        Pi = torch.as_tensor(P); lp = torch.log_softmax(C.ALPHA * keys[Pi] @ q, 0)
        pos = torch.arange(len(O)) if pool == "opened" else torch.as_tensor(O)
        J = (torch.tensor(rew) * lp[pos]).sum(); J.backward()
        err = max(np.abs(gq - tq.grad.numpy()).max() / np.abs(tq.grad.numpy()).max(),
                  np.abs(gk - tk.grad.numpy()).max() / np.abs(tk.grad.numpy()).max())
        out[pool] = float(err)
    return out


def rmm_run(K0, S, lexorder, qs, cites, opened, order, pool, lr):
    """One pass of online RMM heads over a chat; returns dense and fused recall per question (scored before update)."""
    K = K0.astype(np.float32); A = K.copy(); d = K.shape[1]
    Wq = np.zeros((d, d), dtype=np.float32)
    dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    for r in order:
        s = S[r].astype(np.float32)
        b = s + Wq @ s; qp = b / np.linalg.norm(b)
        Kp = A / np.linalg.norm(A, axis=1, keepdims=True)
        top = C.order_of(Kp @ qp)
        dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        O = np.asarray(opened[r], dtype=np.int64)
        if not len(O):
            continue
        cset = set(cites[r]); rew = np.array([1.0 if v in cset else -1.0 for v in O], dtype=np.float32)
        gq, dA, P = rmm_grad(K, A, s, Wq, O, rew, pool)
        Wq += np.float32(lr) * gq.astype(np.float32)
        dA = dA.astype(np.float32)
        if pool == "opened":
            A += np.float32(lr) * ((K @ K[P].T) @ dA)  # = K (lr dW_k)^T with dW_k = dA^T K[P]
        else:
            A += np.float32(lr) * (K @ (K.T @ dA))
    return dense, fused


# ---------------------------------------------------------------- ranker features

def chat_static(ids, docs, sess):
    """Per node: session index (0..1), position inside the session (0..1), session id, token length, doc token sets."""
    n = len(ids); first = {}
    for sid in sess:
        first.setdefault(sid, len(first))
    sidx = np.array([first[x] for x in sess]); ns = len(first)
    pos = np.zeros(n); cnt = collections.Counter(sidx.tolist()); seen = collections.Counter()
    for v in range(n):
        pos[v] = seen[sidx[v]] / max(cnt[sidx[v]] - 1, 1); seen[sidx[v]] += 1
    return dict(sidx=sidx, srel=sidx / max(ns - 1, 1), pos=pos, toklen=np.log1p([len(x) for x in docs]),
                sets=[set(x) for x in docs], n=n)


def inv(order):
    p = np.empty(len(order), dtype=np.int64); p[np.asarray(order)] = np.arange(len(order)); return p


def qfeats(cb, cf, bm, lexorder, st, qtok):
    """Feature rows for the fused top 50 of one question. Returns (X, cand, fused)."""
    n = len(cb); dorder = C.order_of(cb); fused = C.fuse(lexorder, dorder)
    pb, pf, pl = inv(dorder), inv(C.order_of(cf)), inv(lexorder)
    m = min(TOPN, n); cand = fused[:m]; sid = st["sidx"]
    rrf = 1.0 / (61 + pl) + 1.0 / (61 + pb)
    cbc = cb[cand]; mb = bm[cand].max()
    nb = np.empty(m); top10 = set(fused[:10].tolist()); nb10 = np.zeros(m)
    best_in_sess = collections.defaultdict(lambda: -9.0)
    for v in cand:
        best_in_sess[sid[v]] = max(best_in_sess[sid[v]], cb[v])
    scount = collections.Counter(sid[cand].tolist())
    q = set(qtok); X = np.zeros((m, 25), dtype=np.float32)
    for j, v in enumerate(cand):
        ns = [u for u in (v - 1, v + 1) if 0 <= u < n and sid[u] == sid[v]]
        nb[j] = max(cb[u] for u in ns) if ns else cb[v]
        nb10[j] = float(any(u in top10 for u in ns))
        ov = len(q & st["sets"][v])
        X[j] = [cb[v], cf[v], bm[v], np.log1p(pb[v]), np.log1p(pf[v]), np.log1p(pl[v]), j, rrf[v],
                cb[v] - cbc.max(), cf[v] - cf[cand].max(), bm[v] / mb if mb > 0 else 0.0,
                (cb[v] - cbc.mean()) / (cbc.std() + 1e-9), st["toklen"][v], v / max(n - 1, 1), st["srel"][v],
                st["pos"][v], ov, ov / max(len(q), 1), len(q), nb[j], float(sid[v] == sid[cand[0]]),
                scount[sid[v]] / m, np.log(n), best_in_sess[sid[v]] - cb[v], nb10[j]]
    return X, cand, fused


def chat_feats(i, K, S):
    """Feature rows of every question of LoCoMo chat i under keys K and states S."""
    ch = CH[i]; st = ch["_static"]; out = []
    for r, q in enumerate(ch["qs"]):
        qt = C.tokens(q[0])
        cb = K @ S[r]; cf = ch["nodes"] @ ch["asks"][r]; bm = ch["bm25"].scores(qt)
        X, cand, fused = qfeats(cb, cf, bm, ch["lexorder"][r], st, qt)
        out.append((X, cand, np.isin(cand, q[1]).astype(np.float32), q[1], fused))
    return out


# ---------------------------------------------------------------- jobs

def job(spec):
    torch.set_num_threads(1)
    kind = spec[0]
    if kind == "bridge":
        _, f, pair = spec
        fit = [j for j in train_ids(f) if j not in pair]
        b = C.train([CH[j] for j in fit], 16, LR16[f], seed=1000 + 10 * f + pair[0])
        return spec, {k: v.numpy() for k, v in b.state_dict().items()}
    if kind == "rules":
        _, tag, i, src = spec
        K0, S, mu = KEYS[(tag, i)]; ch = CH[i]; nq = len(ch["qs"]); res = {}
        for name, cfg in [("base", {})] + list(S12.RULES.items()):
            dd = np.zeros(nq); ff = np.zeros(nq)
            for order in ORDERS[i]:
                d, fu = S12.run_order(K0, S, ch["lexorder"], ch["qs"], CITES[src][i], OPENED[i], order, cfg, mu)
                dd += d / len(ORDERS[i]); ff += fu / len(ORDERS[i])
            res[name] = (dd, ff)
        return spec, res
    if kind == "rmm":
        _, tag, i, src, pool, lr = spec
        K0, S, _ = KEYS[(tag, i)]; ch = CH[i]; nq = len(ch["qs"])
        dd = np.zeros(nq); ff = np.zeros(nq)
        for order in ORDERS[i]:
            d, fu = rmm_run(K0, S, ch["lexorder"], ch["qs"], CITES[src][i], OPENED[i], order, pool, lr)
            dd += d / len(ORDERS[i]); ff += fu / len(ORDERS[i])
        return spec, (dd, ff)
    if kind == "rk_diag":
        _, f, variant, obj, leaves, k = spec
        if f >= 0:
            fit = [x for j in train_ids(f) for x in FEAT[(("inner", f), j)]]
            ev = [x for j in C.FOLDS[f] for x in FEAT[("outer", j)]]
        else:
            fit = [x for j in range(10) for x in FEAT[("outer", j)]]; ev = FEAT_LME
        cols = DIAG_COLS[variant]
        if variant == "perm":  # each training question gets another training question's labels
            perm = np.random.default_rng(100 + f).permutation(len(fit))
            fit = [(x[0], x[1], fit[perm[t]][2], x[3], x[4]) for t, x in enumerate(fit)]
        sub = lambda rows: [(x[0][:, cols], x[1], x[2], x[3], x[4]) for x in rows]  # noqa: E731
        model = rk_fit(sub(fit), obj, leaves)
        imp = model.booster_.feature_importance("gain") if variant == "all" else None
        return spec, (rk_score(model, sub(ev), obj, k), imp)
    if kind in ("rk_dev", "rk_test", "rk_lme"):
        _, f, obj, leaves = spec
        if kind == "rk_dev":
            fit = [FEAT[(("inner", f), j)] for j in train_ids(f) if j not in dev_pair(f)]
            ev = [FEAT[(("inner", f), j)] for j in dev_pair(f)]
        elif kind == "rk_test":
            fit = [FEAT[(("inner", f), j)] for j in train_ids(f)]
            ev = [FEAT[("outer", j)] for j in C.FOLDS[f]]
        else:
            fit = [FEAT[("outer", j)] for j in range(10)]
            ev = [FEAT_LME]
        model = rk_fit([x for chat in fit for x in chat], obj, leaves)
        return spec, {k: rk_score(model, [x for chat in ev for x in chat], obj, k) for k in RK_TREES}
    raise ValueError(kind)


def rk_fit(rows, obj, leaves):
    import lightgbm as lgb
    X = np.concatenate([r[0] for r in rows]); y = np.concatenate([r[2] for r in rows]).astype(np.int32)
    kw = dict(n_estimators=max(RK_TREES), learning_rate=0.05, num_leaves=leaves, min_child_samples=20, subsample=1.0,
              colsample_bytree=1.0, reg_lambda=0.0, random_state=0, n_jobs=1, deterministic=True, force_row_wise=True,
              verbose=-1)
    if obj == "lambdarank":
        m = lgb.LGBMRanker(objective="lambdarank", **kw); m.fit(X, y, group=[len(r[0]) for r in rows])
    else:
        m = lgb.LGBMClassifier(objective="binary", **kw); m.fit(X, y)
    return m


def rk_score(model, rows, obj, k):
    out = np.zeros(len(rows))
    X = np.concatenate([r[0] for r in rows]); cut = np.cumsum([0] + [len(r[0]) for r in rows])
    p = model.predict(X, num_iteration=k) if obj == "lambdarank" else model.predict(X, raw_score=True, num_iteration=k)
    for t, r in enumerate(rows):
        s = p[cut[t]:cut[t + 1]]; cand = r[1]
        out[t] = C.recall(cand[np.lexsort((np.arange(len(cand)), -s))], r[3])
    return out


# ---------------------------------------------------------------- post hoc (not pre-registered)

FEATURE_NAMES = ["bridge cos", "frozen cos", "bm25", "log rank bridge", "log rank frozen", "log rank bm25",
                 "fused position", "rrf", "bridge gap to best", "frozen gap to best", "bm25 / best", "bridge z",
                 "log turn length", "history position", "session index", "position in session", "overlap count",
                 "overlap fraction", "query length", "neighbour bridge cos", "same session as top 1",
                 "session share of 50", "log history size", "session best minus own", "neighbour in top 10"]
CONTEXT = [13, 14, 15, 19, 20, 21, 23, 24]
DIAG_COLS = {"all": list(range(25)), "perm": list(range(25)), "scores": list(range(12)),
             "nocontext": [c for c in range(25) if c not in CONTEXT]}
EXTRA_LRS = (1e-5, 3e-5)


def posthoc(a, t0, srcs):
    import pickle
    RES, _, srcs0, primary, _ = pickle.load(open(a.cache, "rb"))
    res_json = json.load(open(a.out))
    picks = res_json["picks"]["ranker"]; lme_pick = res_json["picks"]["ranker_lme"]
    tags = [("outer", i) for i in range(10)] + [(("inner", f), j) for f in range(5) for j in dev_pair(f)]
    specs = [("rmm", tg, i, s, pl, lr) for pl in ("chat", "opened") for s in srcs0 for tg, i in tags for lr in EXTRA_LRS]
    for f in range(5):
        o, lv, k = picks[str(f)]
        specs += [("rk_diag", f, v, o, int(lv), int(k)) for v in DIAG_COLS]
    specs += [("rk_diag", -1, v, lme_pick[0], int(lme_pick[1]), int(lme_pick[2])) for v in DIAG_COLS]
    with Pool(a.procs) as pool:
        for spec, res in pool.imap_unordered(job, specs, chunksize=1):
            RES[spec] = res
    print(f"post-hoc runs done ({time.time() - t0:.0f}s)", flush=True)
    chat_of = np.concatenate([[i] * len(CH[i]["qs"]) for i in range(10)])
    mh = np.concatenate([[q[2] == 1 for q in CH[i]["qs"]] for i in range(10)])
    base = np.concatenate([[C.recall(x[4], x[3]) for x in FEAT[("outer", i)]] for i in range(10)])
    ph = dict(note="post hoc, added after the pre-registered verdict; not part of it")
    ceil = np.concatenate([[C.recall(x[4], x[3], k=TOPN) for x in FEAT[("outer", i)]] for i in range(10)])
    ceil10 = np.concatenate([[C.recall(x[1][np.argsort(-x[2], kind="stable")], x[3]) for x in FEAT[("outer", i)]]
                             for i in range(10)])
    lme_base = np.array([C.recall(x[4], x[3]) for x in FEAT_LME])
    ph["ceiling"] = dict(locomo_fused_recall_at_50=round(float(ceil.mean()), 4),
                         locomo_best_reorder_of_50_recall_at_10=round(float(ceil10.mean()), 4),
                         lme_fused_recall_at_50=round(float(np.mean([C.recall(x[4], x[3], k=TOPN) for x in FEAT_LME])), 4))
    rk = {}
    for v in DIAG_COLS:
        loc = np.concatenate([RES[("rk_diag", f, v) + (picks[str(f)][0], int(picks[str(f)][1]), int(picks[str(f)][2]))][0]
                              for f in range(5)])
        lme = RES[("rk_diag", -1, v, lme_pick[0], int(lme_pick[1]), int(lme_pick[2]))][0]
        rk[v] = dict(locomo=round(float(loc.mean()), 4), locomo_minus_base=boot(loc - base, chat_of),
                     locomo_multi_hop=round(float(loc[mh].mean()), 4),
                     lme=round(float(lme.mean()), 4), lme_minus_fused=boot(lme - lme_base, np.arange(len(lme))))
    ph["ranker_variants"] = rk
    ph["ranker_variants_note"] = ("all = the pre-registered ranker refit (same config); perm = labels of another training "
                                  "question; scores = the 12 score and rank features; nocontext = all but " +
                                  ", ".join(FEATURE_NAMES[c] for c in CONTEXT))
    imp = np.mean([RES[("rk_diag", f, "all") + (picks[str(f)][0], int(picks[str(f)][1]), int(picks[str(f)][2]))][1]
                   for f in range(5)], 0)
    imp = imp / imp.sum()
    ph["feature_gain_share"] = {FEATURE_NAMES[c]: round(float(imp[c]), 4) for c in np.argsort(-imp)}
    # RMM with the extended lr grid, re-selected on dev
    M = {"dense": 0, "fused": 1}; grid = [(pl, lr) for pl in RMM_POOLS for lr in EXTRA_LRS + RMM_LRS]
    ph["rmm_extended"] = {}
    for s in srcs0:
        rd = {(f, g, m): float(np.concatenate([RES[("rmm", ("inner", f), j, s) + g][M[m]] for j in dev_pair(f)]).mean())
              for f in range(5) for g in grid for m in M}
        pk = {(f, m): max(grid, key=lambda g: (rd[(f, g, m)], -grid.index(g))) for f in range(5) for m in M}
        so = res_json["locomo"]["by_source"][s]; d = {}
        ours = {m: np.concatenate([RES[("rules", "outer", i, s)][so["picks"]["ours"][m][i // 2]][M[m]] for i in range(10)])
                for m in M}
        for m in M:
            rmm = np.concatenate([RES[("rmm", "outer", i, s) + pk[(i // 2, m)]][M[m]] for i in range(10)])
            d[m] = dict(picks=[f"{pk[(f, m)][0]} lr {pk[(f, m)][1]:g}" for f in range(5)], rmm=round(float(rmm.mean()), 4),
                        ours_minus_rmm=boot(ours[m] - rmm, chat_of), rmm_minus_base=boot(
                            rmm - (base if m == "fused" else np.concatenate(
                                [RES[("rules", "outer", i, s)]["base"][0] for i in range(10)])), chat_of))
        d["test_means_extra_lrs"] = {f"{g[0]} {g[1]:g}": [round(float(np.concatenate(
            [RES[("rmm", "outer", i, s) + g][M[m]] for i in range(10)]).mean()), 4) for m in M]
            for g in grid if g[1] in EXTRA_LRS}
        ph["rmm_extended"][s] = d
    res_json["post_hoc"] = ph
    json.dump(res_json, open(a.out, "w"), indent=1, ensure_ascii=False)
    print("\nPOST HOC (not part of the pre-registered verdict)")
    print(json.dumps(ph, indent=1, ensure_ascii=False))
    print(f"post-hoc seconds {round(time.time() - t0)}")


# ---------------------------------------------------------------- main

def boot(diff, cl):
    m, ci = C.cluster_boot(diff, cl)
    return dict(mean=round(m, 4), ci=[round(ci[0], 4), round(ci[1], 4)])


def main():
    global R, CH, OPENED, CITES, ORDERS, KEYS, FEAT, FEAT_LME, LR16
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--tasks", default=os.path.join(HERE, "runs", "tasks_hop0.jsonl.gz"))
    p.add_argument("--answers", default=os.path.join(HERE, "runs", "answers_hop0.jsonl"))
    p.add_argument("--cites", default="auto")
    p.add_argument("--procs", type=int, default=3)
    p.add_argument("--out", default=os.path.join(HERE, "results", "s111_baselines.json"))
    p.add_argument("--cache", default="", help="pickle of the finished runs; with --reuse, skip straight to the summary")
    p.add_argument("--reuse", action="store_true")
    p.add_argument("--posthoc", action="store_true", help="post-hoc checks after the pre-registered run (needs --cache)")
    a = p.parse_args()
    t0 = time.time()
    if a.reuse and a.cache and os.path.exists(a.cache):
        import pickle
        R = Reader(); CH = R.chats
        RES, FEAT_LME, srcs, primary, out = pickle.load(open(a.cache, "rb"))
        print("reusing finished runs from", a.cache, flush=True)
        return summarise(a, t0, RES, srcs, primary, out)
    out = dict(test="1.11 prior-art baselines", protocol=__doc__.split("Usage:")[0].strip(), checks={})
    out["checks"]["grad_check_max_rel_err"] = grad_check()
    print("gradient check (max relative error vs torch):", out["checks"]["grad_check_max_rel_err"], flush=True)
    assert max(out["checks"]["grad_check_max_rel_err"].values()) < 1e-6

    R = Reader(); CH = R.chats
    LR16 = json.load(open(os.path.join(HERE, "results", "s11_rank.json")))["picks"]["r16"]
    tasks = {t["id"]: t for t in S12.read(a.tasks)}
    reads = {}
    n_rows = 0
    if os.path.exists(a.answers) or os.path.exists(a.answers + ".gz"):
        rows = S12.read(a.answers); n_rows = len(rows)
        reads = {r["id"]: r for r in rows if "error" not in r and r.get("kind") == "read"}
    have_haiku = n_rows >= MIN_ANSWER_ROWS
    srcs = ["haiku", "visible"] if (a.cites == "auto" and have_haiku) else (
        ["visible"] if a.cites == "auto" else a.cites.split(","))
    if "haiku" in srcs and not have_haiku:
        raise SystemExit(f"{a.answers}: {n_rows} rows, fewer than {MIN_ANSWER_ROWS}; run with --cites visible")
    primary = "haiku" if "haiku" in srcs else "visible"
    out["cites"] = dict(answers=os.path.basename(a.answers), answer_rows=n_rows, sources=srcs, primary=primary,
                        note=None if have_haiku else "answers file missing or short: visible oracle only")
    print("cite sources", srcs, "primary", primary, "answer rows", n_rows, flush=True)

    # opened sets, cites, orders; check the opened set is the fused rank-16 top 10
    OPENED, CITES, ORDERS = {}, {s: {} for s in srcs}, {}
    mism = 0; ncites = collections.Counter()
    for i, ch in enumerate(CH):
        nq = len(ch["qs"]); OPENED[i] = []
        for s in srcs:
            CITES[s][i] = []
        for r in range(nq):
            tid = f"locomo:{i}:{r}"; node = {sn["n"]: sn["node"] for sn in tasks[tid]["snippets"]}
            op = list(node.values()); OPENED[i].append(op)
            mism += op != R.first(("locomo", i, r))[:10].tolist()
            if "haiku" in srcs:
                rd = reads.get(tid); hc = [node[n] for n in rd["cites"] if n in node] if rd else []
                CITES["haiku"][i].append(hc); ncites["haiku"] += len(hc)
            if "visible" in srcs:
                vc = [v for v in ch["qs"][r][1] if v in set(op)]; CITES["visible"][i].append(vc); ncites["visible"] += len(vc)
        ORDERS[i] = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(S12.ORDERS)]
        sess = [int(C.EVID.match(x).group(1)) if C.EVID.match(x) else -1 for x in ch["ids"]]
        ch["_static"] = chat_static(ch["ids"], ch["docs"], sess)
    out["checks"]["opened_not_equal_fused_top10"] = mism
    out["checks"]["cites_per_question"] = {s: round(ncites[s] / 1536, 3) for s in srcs}
    print("opened sets that differ from the fused top 10:", mism, "| cites per question:",
          out["checks"]["cites_per_question"], flush=True)

    # inner bridges (fold f, held-out pair), reproducing s11's dev bridges at fold f's picked lr
    specs = [("bridge", f, pr) for f in range(5) for pr in C.inner_pairs(train_ids(f))]
    INNER = {}
    with Pool(a.procs) as pool:
        for spec, sd in pool.imap_unordered(job, specs):
            b = C.Bridge(384, 16); b.load_state_dict({k: torch.as_tensor(v) for k, v in sd.items()}); INNER[spec[1:]] = b
    print(f"inner bridges trained ({time.time() - t0:.0f}s)", flush=True)
    # reproduction check against s11's dev score at the picked lr (dense recall on the held-out pair)
    s11 = json.load(open(os.path.join(HERE, "results", "s11_rank.json")))["by_lr"]["r16"]
    rep = {}
    for f in range(5):
        xs = [x for pr in C.inner_pairs(train_ids(f)) for j in pr for x in C.chat_recalls(INNER[(f, pr)], CH[j])]
        rep[f] = dict(here=round(float(np.mean(xs)), 4), s11=s11[f"fold{f}_dev"][str(LR16[f])])
    out["checks"]["inner_bridge_dev_dense_vs_s11"] = rep
    print("inner bridge dev recall vs s11:", rep, flush=True)

    # keys: outer (test) and inner (dev pair of each fold), with frozen centring means
    KEYS = {}
    for i in range(10):
        f = i // 2
        mu = np.concatenate([R.bridges[f].views(CH[j]["nodes"], CH[j]["asks"])[1] for j in train_ids(f)]).mean(0)
        KEYS[("outer", i)] = (R.keys[i][0], R.keys[i][1], mu)
    for f in range(5):
        dp = dev_pair(f); b = INNER[(f, dp)]
        fit = [j for j in train_ids(f) if j not in dp]
        mu = np.concatenate([b.views(CH[j]["nodes"], CH[j]["asks"])[1] for j in fit]).mean(0)
        for j in dp:
            K, S = b.views(CH[j]["nodes"], CH[j]["asks"]); KEYS[(("inner", f), j)] = (K, S, mu)

    # ranker features
    FEAT = {}
    for i in range(10):
        FEAT[("outer", i)] = chat_feats(i, *R.keys[i])
        assert all(np.array_equal(x[4], R.first(("locomo", i, r))) for r, x in enumerate(FEAT[("outer", i)]))
    for f in range(5):
        for j in train_ids(f):
            b = INNER[(f, C.FOLDS[j // 2])]
            FEAT[(("inner", f), j)] = chat_feats(j, *b.views(CH[j]["nodes"], CH[j]["asks"]))
    FEAT_LME = []
    for t, it in enumerate(R.items):
        st = chat_static(it["rows"], it["docs"], it["sess"]); qt = C.tokens(it["question"])
        cb = R.lme_keys[t] @ R.lme_state[t]; cf = R.vec[it["rows"]] @ it["q"]; bm = it["bm25"].scores(qt)
        X, cand, fused = qfeats(cb, cf, bm, it["lexorder"], st, qt)
        assert np.array_equal(fused, R.first(("lme", t)))
        FEAT_LME.append((X, cand, np.isin(cand, it["ev"]).astype(np.float32), it["ev"], fused))
    print(f"features built ({time.time() - t0:.0f}s)", flush=True)
    if a.posthoc:
        return posthoc(a, t0, srcs)

    # all runs
    tags = [("outer", i) for i in range(10)] + [(("inner", f), j) for f in range(5) for j in dev_pair(f)]
    specs = [("rmm", tg, i, s, pl, lr) for pl in ("chat", "opened") for s in srcs for tg, i in tags for lr in RMM_LRS]
    specs += [("rules", tg, i, s) for s in srcs for tg, i in tags]
    specs += [(k, f, o, lv) for k in ("rk_dev", "rk_test") for f in range(5) for o in RK_OBJ for lv in RK_LEAVES]
    specs += [("rk_lme", -1, o, lv) for o in RK_OBJ for lv in RK_LEAVES]
    RES = {}
    with Pool(a.procs) as pool:
        for k, (spec, res) in enumerate(pool.imap_unordered(job, specs, chunksize=1)):
            RES[spec] = res
            if (k + 1) % 50 == 0:
                print(f"  {k + 1}/{len(specs)} jobs ({time.time() - t0:.0f}s)", flush=True)
    print(f"runs done ({time.time() - t0:.0f}s)", flush=True)
    if a.cache:
        import pickle
        pickle.dump((RES, FEAT_LME, srcs, primary, out), open(a.cache, "wb"))
    return summarise(a, t0, RES, srcs, primary, out)


def summarise(a, t0, RES, srcs, primary, out):

    # ---------------------------------------------------------------- assemble
    chat_of = np.concatenate([[i] * len(CH[i]["qs"]) for i in range(10)])
    cat_of = np.concatenate([[q[2] for q in CH[i]["qs"]] for i in range(10)])
    mh = cat_of == 1
    M = {"dense": 0, "fused": 1}

    def test_vec(fn):  # concatenate per-chat test arrays in chat order
        return np.concatenate([fn(i) for i in range(10)])

    def dev_mean(arrs):
        return float(np.mean(np.concatenate(arrs)))

    # ranker: per fold config pick on dev, LME config by pooled dev
    rk_dev = {(f, o, lv, k): RES[("rk_dev", f, o, lv)][k] for f in range(5) for o in RK_OBJ for lv in RK_LEAVES
              for k in RK_TREES}
    grid = [(o, lv, k) for o in RK_OBJ for lv in RK_LEAVES for k in RK_TREES]
    rk_pick = {f: max(grid, key=lambda g: (float(rk_dev[(f,) + g].mean()), -grid.index(g))) for f in range(5)}
    pooled = {g: float(np.concatenate([rk_dev[(f,) + g] for f in range(5)]).mean()) for g in grid}
    lme_pick = max(grid, key=lambda g: (pooled[g], -grid.index(g)))
    per_fold = {}
    for f in range(5):
        o, lv, k = rk_pick[f]; v = RES[("rk_test", f, o, lv)][k]; n0 = len(CH[2 * f]["qs"])
        per_fold[2 * f], per_fold[2 * f + 1] = v[:n0], v[n0:]
    ranker = test_vec(lambda i: per_fold[i])
    base = {m: test_vec(lambda i: RES[("rules", "outer", i, srcs[0])]["base"][M[m]]) for m in M}
    out["picks"] = dict(ranker={f: list(map(str, rk_pick[f])) for f in range(5)}, ranker_lme=list(map(str, lme_pick)),
                        ranker_dev={f: {"/".join(map(str, g)): round(float(rk_dev[(f,) + g].mean()), 4) for g in grid}
                                    for f in range(5)})
    rk_lme = RES[("rk_lme", -1, lme_pick[0], lme_pick[1])][lme_pick[2]]
    lme_base = np.array([C.recall(x[4], x[3]) for x in FEAT_LME])
    lme_dense = np.array([C.recall(C.order_of(R.lme_keys[t] @ R.lme_state[t]), it["ev"]) for t, it in enumerate(R.items)])
    qcl = np.arange(len(lme_base))
    out["lme"] = dict(n_questions=len(lme_base), fused_rank16=round(float(lme_base.mean()), 4),
                      dense_rank16=round(float(lme_dense.mean()), 4), ranker=round(float(rk_lme.mean()), 4),
                      ranker_minus_fused=boot(rk_lme - lme_base, qcl), ranker_config=list(map(str, lme_pick)),
                      ranker_by_config={"/".join(map(str, g)): round(float(RES[("rk_lme", -1, g[0], g[1])][g[2]].mean()), 4)
                                        for g in grid},
                      note="one question per haystack: our rules and online RMM cannot learn here, so ours = the fused read")
    out["locomo"] = dict(n_questions=int(len(chat_of)), base=dict(dense=round(float(base["dense"].mean()), 4),
                                                                  fused=round(float(base["fused"].mean()), 4),
                                                                  fused_multi_hop=round(float(base["fused"][mh].mean()), 4)),
                         ranker=dict(fused=round(float(ranker.mean()), 4), multi_hop=round(float(ranker[mh].mean()), 4),
                                     minus_base=boot(ranker - base["fused"], chat_of)), by_source={})
    verdict = {}
    rules = list(S12.RULES)
    rmm_grid = [(pl, lr) for pl in RMM_POOLS for lr in RMM_LRS]
    for s in srcs:
        so = {}
        rule_dev = {(f, rn, m): dev_mean([RES[("rules", ("inner", f), j, s)][rn][M[m]] for j in dev_pair(f)])
                    for f in range(5) for rn in rules for m in M}
        rmm_dev = {(f, g, m): dev_mean([RES[("rmm", ("inner", f), j, s) + g][M[m]] for j in dev_pair(f)])
                   for f in range(5) for g in rmm_grid for m in M}
        pick_rule = {(f, m): max(rules, key=lambda rn: (rule_dev[(f, rn, m)], -rules.index(rn))) for f in range(5) for m in M}
        pick_rmm = {(f, m): max(rmm_grid, key=lambda g: (rmm_dev[(f, g, m)], -rmm_grid.index(g))) for f in range(5) for m in M}
        rule_test = {(rn, m): test_vec(lambda i: RES[("rules", "outer", i, s)][rn][M[m]]) for rn in rules for m in M}
        rmm_test = {(g, m): test_vec(lambda i: RES[("rmm", "outer", i, s) + g][M[m]]) for g in rmm_grid for m in M}
        ours = {m: test_vec(lambda i: RES[("rules", "outer", i, s)][pick_rule[(i // 2, m)]][M[m]]) for m in M}
        rmm = {m: test_vec(lambda i: RES[("rmm", "outer", i, s) + pick_rmm[(i // 2, m)]][M[m]]) for m in M}
        # RMM with its config picked per fold on the test chats themselves (optimistic for RMM)
        rmm_or = {}
        for m in M:
            best = {f: max(rmm_grid, key=lambda g: float(np.concatenate(
                [RES[("rmm", "outer", j, s) + g][M[m]] for j in C.FOLDS[f]]).mean())) for f in range(5)}
            rmm_or[m] = (test_vec(lambda i: RES[("rmm", "outer", i, s) + best[i // 2]][M[m]]), best)
        posthoc = max(rules, key=lambda rn: float(rule_test[(rn, "fused")].mean()))
        so["picks"] = dict(ours={m: [pick_rule[(f, m)] for f in range(5)] for m in M},
                           rmm={m: [f"{pick_rmm[(f, m)][0]} lr {pick_rmm[(f, m)][1]:g}" for f in range(5)] for m in M},
                           rmm_test_oracle={m: [f"{rmm_or[m][1][f][0]} lr {rmm_or[m][1][f][1]:g}" for f in range(5)] for m in M},
                           posthoc_best_rule_fused=posthoc)
        so["dev"] = dict(rules={f"fold{f}": {rn: [round(rule_dev[(f, rn, m)], 4) for m in M] for rn in rules} for f in range(5)},
                         rmm={f"fold{f}": {f"{g[0]} {g[1]:g}": [round(rmm_dev[(f, g, m)], 4) for m in M] for g in rmm_grid}
                              for f in range(5)}, columns=["dense", "fused"])
        so["means"] = dict(ours={m: round(float(ours[m].mean()), 4) for m in M},
                           rmm={m: round(float(rmm[m].mean()), 4) for m in M},
                           rmm_test_oracle={m: round(float(rmm_or[m][0].mean()), 4) for m in M},
                           ranker_fused=round(float(ranker.mean()), 4),
                           rules={rn: {m: round(float(rule_test[(rn, m)].mean()), 4) for m in M} for rn in rules},
                           rmm_grid={f"{g[0]} {g[1]:g}": {m: round(float(rmm_test[(g, m)].mean()), 4) for m in M}
                                     for g in rmm_grid},
                           multi_hop_fused=dict(ours=round(float(ours["fused"][mh].mean()), 4),
                                                rmm=round(float(rmm["fused"][mh].mean()), 4),
                                                ranker=round(float(ranker[mh].mean()), 4),
                                                base=round(float(base["fused"][mh].mean()), 4)))
        cmp = {}
        cmp["ours - RMM (fused)"] = boot(ours["fused"] - rmm["fused"], chat_of)
        cmp["ours - ranker (fused)"] = boot(ours["fused"] - ranker, chat_of)
        cmp["ours - RMM (dense)"] = boot(ours["dense"] - rmm["dense"], chat_of)
        cmp["ours - base (fused)"] = boot(ours["fused"] - base["fused"], chat_of)
        cmp["ours - base (dense)"] = boot(ours["dense"] - base["dense"], chat_of)
        cmp["RMM - base (fused)"] = boot(rmm["fused"] - base["fused"], chat_of)
        cmp["RMM - base (dense)"] = boot(rmm["dense"] - base["dense"], chat_of)
        cmp["ranker - base (fused)"] = boot(ranker - base["fused"], chat_of)
        cmp["ours - RMM test-oracle (fused)"] = boot(ours["fused"] - rmm_or["fused"][0], chat_of)
        cmp["ours - RMM test-oracle (dense)"] = boot(ours["dense"] - rmm_or["dense"][0], chat_of)
        cmp[f"post-hoc best rule ({posthoc}) - RMM (fused)"] = boot(rule_test[(posthoc, "fused")] - rmm["fused"], chat_of)
        cmp[f"post-hoc best rule ({posthoc}) - ranker (fused)"] = boot(rule_test[(posthoc, "fused")] - ranker, chat_of)
        for rn in rules:
            cmp[f"{rn} - RMM (fused)"] = boot(rule_test[(rn, "fused")] - rmm["fused"], chat_of)
            cmp[f"{rn} - ranker (fused)"] = boot(rule_test[(rn, "fused")] - ranker, chat_of)
        so["comparisons"] = cmp
        so["per_chat"] = {nm: [round(float(d[chat_of == j].mean()), 4) for j in range(10)]
                          for nm, d in (("ours - RMM (fused)", ours["fused"] - rmm["fused"]),
                                        ("ours - ranker (fused)", ours["fused"] - ranker))}
        out["locomo"]["by_source"][s] = so
        v = {}
        for nm, key in (("RMM", "ours - RMM (fused)"), ("ranker", "ours - ranker (fused)")):
            c = cmp[key]
            v[nm] = dict(diff=c["mean"], ci=c["ci"], ours_at_least_matches=c["mean"] >= 0,
                         baseline_clear_win=c["ci"][1] < 0)
        v["pass"] = all(v[nm]["ours_at_least_matches"] for nm in ("RMM", "ranker"))
        verdict[s] = v
    out["verdict"] = dict(primary_source=primary, primary=verdict[primary], all_sources=verdict,
                          result="pass" if verdict[primary]["pass"] else "fail",
                          lme_ranker_beats_fused_read=out["lme"]["ranker_minus_fused"]["ci"][0] > 0)
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump(out, open(a.out, "w"), indent=1, ensure_ascii=False)

    # ---------------------------------------------------------------- print
    L = out["locomo"]
    print(f"\nLoCoMo base: dense {L['base']['dense']:.4f} fused {L['base']['fused']:.4f}  |  ranker fused "
          f"{L['ranker']['fused']:.4f}, minus base {L['ranker']['minus_base']}")
    print("ranker picks per fold:", out["picks"]["ranker"])
    for s in srcs:
        so = L["by_source"][s]
        print(f"\n== cites: {s} ==")
        print("picks:", json.dumps(so["picks"], ensure_ascii=False))
        print("means:", json.dumps({k: so["means"][k] for k in ("ours", "rmm", "rmm_test_oracle", "ranker_fused",
                                                                "multi_hop_fused")}, ensure_ascii=False))
        for nm, r in so["means"]["rules"].items():
            print(f"  rule {nm:<12} dense {r['dense']:.4f} fused {r['fused']:.4f}")
        for nm, r in so["means"]["rmm_grid"].items():
            print(f"  RMM {nm:<14} dense {r['dense']:.4f} fused {r['fused']:.4f}")
        for nm, c in so["comparisons"].items():
            print(f"  {nm:<46} {c['mean']:+.4f} [{c['ci'][0]:+.4f}, {c['ci'][1]:+.4f}]")
        print("  per chat:", json.dumps(so["per_chat"]))
    print(f"\nLongMemEval-S: fused rank-16 {out['lme']['fused_rank16']:.4f}, ranker {out['lme']['ranker']:.4f}, "
          f"ranker - fused {out['lme']['ranker_minus_fused']} (config {out['lme']['ranker_config']})")
    print("\nverdict:", json.dumps(out["verdict"], indent=1, ensure_ascii=False))
    print(f"seconds {out['seconds']}")


if __name__ == "__main__":
    main()
