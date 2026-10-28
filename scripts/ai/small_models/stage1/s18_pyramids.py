#!/usr/bin/env python3
"""Stage 1.8 (predictions P7 and P8): deeper pyramids (turn -> session -> week -> month) on LoCoMo and LongMemEval-S,
with every routing table recomputed in ONE stated log-sum-exp form.

Pre-registered (this docstring) before any d', exponent, gain or coverage was computed on the new setup.

Front matter test 1.8, pass bar (copied): "mean pooling loses detectability per level as roughly n^-0.4 to n^-0.5;
log-sum-exp keeps at least 90% of the leaf value; no fixed pool beats the mean by more than sqrt(n/n_eff); no top-3
router exceeds 0.939 on multi-hop". Fails if "any of these is beaten". Predictions P7 (query-dependent pooling) and P8
(coverage ceiling E[min(n+, b)/n+], 0.939 for LoCoMo multi-hop at b = 3; recomputed here with the 1,536-question parser).

THE LSE FORM (method section 8, error 12: the old tables mixed the sum form and the mean form). One form, used for
every LSE number in this script and nothing else called LSE:
    normalised (size-neutral) LSE   LSE_w(u) = w * log( (1/|leaves(u)|) * sum_{v in leaves(u)} exp(<s, k_v>/w) ),  w = 0.05
computed over all leaves under the parent u. It composes across levels only with size weights (method Prop. 6.8 (iii)):
LSE_w(u) = w log sum_c (|leaves(c)|/|leaves(u)|) exp(LSE_w(c)/w); the script checks this identity numerically at every
level. Why this form: the sum form carries a prior w log |leaves(u)| that grows with depth (0.05 log 70 = 0.21 at a
LoCoMo month, larger than the score spread), so it would mix subtree size into detectability; the normalised form is
size-neutral and tends to the mean of the leaf scores as w -> infinity. w = 0.05 is the value every earlier script used;
it is fixed here, not tuned. "max" (the w -> 0 limit) is reported as a reference router, never called LSE.

Data and keys. LoCoMo: chat i is read with the tuned rank-16 bridge of the fold that held it out (retrieval.Reader:
R.keys[i] = keys, ask states). LongMemEval-S: the 428 questions with user-turn evidence, each question's own haystack of
user turns, keys and states under the rank-16 bridge trained on all 10 LoCoMo chats (R.lme_keys, R.lme_state).
The frozen bge-small space (raw vectors) is run through the same code as a secondary reference, with no verdict.

Pyramid (a strict tree; levels 0 leaf, 1 session, 2 week, 3 month).
  leaf     a turn (LoCoMo: every turn; LongMemEval-S: every user turn).
  session  LoCoMo: the dia_id prefix D<k>; LongMemEval-S: a maximal run of consecutive user turns with the same
           (haystack session id, haystack date).
  week     the session's ISO week intersected with its calendar month: key (year, month, ISO week number) of the
           session's date. So a week never straddles two months and the tree is strict (method Prop. 6.9).
  month    (year, month) of the session date.
  Dates: LoCoMo "1:56 pm on 8 May, 2023" (the session's date_time, carried per turn in common.load_locomo's date);
  LongMemEval-S "2023/05/20 (Sat) 02:21" (haystack_dates). Every date must parse; the script stops otherwise.
  n = the number of children of a parent (turns per session, sessions per week, weeks per month); N = leaves under it.

Parent scores for a state s (all in the bridge space; leaf keys and states are unit vectors).
  mean    recursive mean pooling, the pyramid's construction: key(u) = n(mean of its children's keys), children at
          level 1 are leaf keys, above that the children's mean-pooled keys. Score <s, key(u)>.
  lse     the normalised LSE above, over the leaves of u.
  max     max over the leaves of u (reference).
  Fixed (query-independent) pools, P7's third part. At level l each is built on the MEAN-pooled keys of level l-1 and
  changes only the level-l pooling: key(u) = n(sum_c beta_c key(c)), beta independent of the query.
    attn    beta = softmax_c(<w_l, key(c)>) within u; w_l (one 384-vector per level) trained as math/theory/pool.py did:
            Adam lr 1e-2, 60 epochs, w_l = 0 at start (so it starts at the mean), loss = soft-target cross-entropy of
            softmax(20 <s, key(u)>) over the parents of a chat against the uniform distribution over the question's
            evidence parents, all questions of the TRAINING chats only. LoCoMo: per outer fold, the 8 training chats
            under that fold's bridge. LongMemEval-S: all 10 LoCoMo chats under the all-chat bridge (as its bridge).
            Settings fixed in advance, not tuned.
    size    beta_c = size of the child: whitespace tokens of the turn at level 1, number of leaves of c above.
    oracle  beta_c = pi_u(c), the empirical distribution of evidence over u's children: the count of the corpus's
            d'-set questions (below) whose evidence leaf lies in child c. Parents that hold no such evidence keep the
            mean. This uses the test questions' labels on purpose: it is the equality case of method Prop. 6.10, the
            strongest fixed pool the bound allows (in-sample diagnostic, not a usable router).
  bm25    common.BM25 over the concatenated tokens of the parent's leaves, query = the question's tokens. Routing only.

Detectability (P7). d'-set Q_l: questions with exactly ONE evidence leaf (Prop. 6.7's setting: one evidence child)
whose corpus (chat or haystack) has at least 2 nodes at level l. For such a question and a pool p at level l, the
positive is the parent holding the evidence leaf and the negatives are all other level-l nodes of the corpus:
    Delta_q = score(positive) - mean(score(negatives)),  SS_q = sum of squared deviations of the negatives, df_q = #neg - 1
    d'_l(p) over a question set = mean_q Delta_q / sigma,  sigma = sqrt(sum_q SS_q / sum_q df_q)  (pooled within-question
    sd of the negatives, so levels with few parents per corpus are not dominated by small-sample sd).
Level 0 (leaf): the evidence turn against all other turns of the corpus, the same formula. d' at levels l and l-1 and
the leaf are always computed on the same questions (Q_l).
  Old per-question form (math/theory/pool.py; secondary, no verdict): d'_q = Delta_q / sd(negatives), questions with at
  least 5 negatives at both levels compared.

P7a, mean pooling loses detectability per level as n^-gamma, gamma about 0.4 to 0.5. For each dataset and level
l in {session, week, month}: bin Q_l by n of the evidence parent (one bin per value if there are at most 6 distinct
values, else 4 quantile bins at the 25/50/75% points of n; bins with fewer than 15 questions dropped). Per bin
rho_b = d'_l(mean) / d'_{l-1}(mean) on the bin's questions (level 0 = leaf; sigmas pooled over all of Q_l), and
gamma = -(OLS slope of log rho_b on log mean-n_b), bins unweighted (as the old n^-0.43 fit). Estimable: at least 2
bins and a finite slope in at least 90% of bootstrap draws. The same fit is reported for lse (P7 implies a small gamma).
  Decision (bridge space, every estimable cell = dataset x level):
    FAIL         some cell's 95% CI of gamma lies entirely outside [0.3, 0.6] ("roughly" = 0.1 either side of the range).
    PASS         every estimable cell has its point estimate in [0.3, 0.6] and its CI intersects [0.4, 0.5], and the
                 LoCoMo session cell is estimable.
    INCONCLUSIVE otherwise.
P7b, LSE keeps at least 90% of the leaf d': share_l = d'_l(lse) / d'_0(leaf) on Q_l, every cell with at least 15
  questions. FAIL if some cell's CI upper bound is below 0.90; PASS if every cell's point estimate is at least 0.90;
  INCONCLUSIVE otherwise.
P7c, no fixed pool beats the mean by more than sqrt(n/n_eff): gain_l(p) = d'_l(p) / d'_l(mean) on Q_l for p in
  {attn, size, oracle}; bound B_l = mean over q in Q_l of sqrt(n_u * sum_c pi_u(c)^2) for q's evidence parent u
  (n_eff = 1 / sum pi^2, the inverse participation of the empirical evidence distribution over u's children; on
  LongMemEval-S each haystack has one question, so n_eff = 1 and the bound is sqrt(n)). excess = gain - B_l, computed
  inside every bootstrap draw. FAIL if some (cell, pool) has the excess CI entirely above 0; PASS if every point excess
  is at most 0; INCONCLUSIVE otherwise. Cells with at least 15 questions.
P8, coverage ceiling. Every question (all evidence counts), each level, each router in {mean, lse, max, attn, size,
  bm25}: coverage = |top-3 parents intersect evidence parents| / n+, ceiling = min(n+, 3) / n+ (per question, then
  averaged), for all questions and for multi-hop (LoCoMo category 1; LongMemEval-S "multi-session" as its analog).
  Per question coverage cannot exceed the ceiling, so P8 holds by construction; the test is that no router's mean
  coverage exceeds the mean ceiling (by more than 1e-9) at any cell, which would mean a code error. FAIL if it does,
  PASS otherwise. Reported: the recomputed LoCoMo session multi-hop ceiling (method: 0.939) and each router's gap to it.
  Secondary, no verdict ("only an adaptive b can pass it"): LoCoMo bridge only, open every parent whose lse score is
  within theta_l of the top one, theta_l picked per fold on the 8 TRAINING chats (grid 0 to 0.3 by 0.001) so the mean
  number opened is closest to 3; report its mean opened count and coverage against the fixed-b ceiling.
Overall: PASS only if P7a, P7b, P7c and P8 all pass; FAIL if any fails; else INCONCLUSIVE.

Statistics. LoCoMo: chats are the clusters; LongMemEval-S: questions are. 4,000 draws, seed 0, generated exactly as
common.cluster_boot generates them (rng.integers over the cluster ids), and the SAME draws for every pool, level and
statistic within a dataset (common random numbers). Every ratio, sigma, bound and slope is recomputed inside each draw
from cluster sums; CIs are 2.5 and 97.5 percentiles over the finite draws. Simple paired differences (P8 gaps) use
common.cluster_boot. Nothing is tuned on test chats: w = 0.05 and b = 3 are fixed, attn is trained on training chats,
theta on training chats.

Scope cuts (stated before running): the k-means and soft-OR-distilled prototype rows of method Empirical result 6.2 are
not recomputed (multi-vector parents, not single pools); one seed for attn (deterministic start at w = 0).

Looked at before writing this (structure only, no scores): LoCoMo has 1,536 questions, 1,123 with one evidence turn,
282 multi-hop (5 with one evidence turn); 272 sessions, 207 weeks, 86 months over the 10 chats (19 to 32 sessions per
chat). LongMemEval-S: 428 questions, 133 with one evidence turn; 38 to 61 sessions per haystack (median 47), 5.1 user
turns per session on average; the median haystack spans 10 days, so most have 1 month and about 3 weeks.

Usage: python s18_pyramids.py   (writes results/s18_pyramids.json; tee stdout to results/s18_pyramids.log)
"""
import collections, datetime, json, math, os, sys, time

import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

torch.set_num_threads(1)

OMEGA = 0.05
BUDGET = 3
NBOOT = 4000
SEED = 0
MIN_BIN = 15
MIN_CELL = 15
GAMMA_BAND = (0.3, 0.6)
GAMMA_CORE = (0.4, 0.5)
LSE_SHARE = 0.90
LEVELS = ("leaf", "session", "week", "month")
POOLS = ("mean", "lse", "max", "attn", "size", "oracle")
FIXED = ("attn", "size", "oracle")
ROUTERS = ("mean", "lse", "max", "attn", "size", "bm25")
THETA_GRID = np.round(np.arange(0.0, 0.3005, 0.001), 3)


def parse_locomo(s):
    return datetime.datetime.strptime(s.strip(), "%I:%M %p on %d %B, %Y").date()


def parse_lme(s):
    return datetime.datetime.strptime(s.split(" (")[0].strip(), "%Y/%m/%d").date()


# ---------------------------------------------------------------- the tree

def build_tree(session_of_leaf, date_of_session):
    """ups[l][i] = parent at level l of node i of level l-1; leafmap[l][v] = level-l ancestor of leaf v."""
    names = list(dict.fromkeys(session_of_leaf)); at = {s: i for i, s in enumerate(names)}
    up1 = np.array([at[s] for s in session_of_leaf])
    wk = [(d.year, d.month, d.isocalendar()[1]) for d in (date_of_session[s] for s in names)]
    wn = list(dict.fromkeys(wk)); up2 = np.array([wn.index(w) for w in wk])
    mo = [(w[0], w[1]) for w in wn]; mn = list(dict.fromkeys(mo)); up3 = np.array([mn.index(m) for m in mo])
    ups = [None, up1, up2, up3]
    leafmap = [np.arange(len(up1)), up1, up2[up1], up3[up2[up1]]]
    return ups, leafmap


def locomo_tree(c):
    sess = [d.split(":")[0] for d in c["ids"]]
    dates = {}
    for s, d in zip(sess, c["date"]):
        dd = parse_locomo(d)
        assert dates.setdefault(s, dd) == dd, "a session with two dates"
    return build_tree(sess, dates)


def lme_tree(it):
    keys = list(zip(it["sess"], it["dates"])); run = 0; lab = []
    for i, k in enumerate(keys):
        if i and k != keys[i - 1]:
            run += 1
        lab.append(run)
    dates = {lab[i]: parse_lme(keys[i][1]) for i in range(len(keys))}
    return build_tree(lab, dates)


def segsum(x, idx, n):
    out = np.zeros((n,) + x.shape[1:]); np.add.at(out, idx, x)
    return out


# ---------------------------------------------------------------- attn pool training (training chats only)

def train_attn(sets, epochs=60, lr=1e-2):
    """sets: (child keys, parent index, n parents, ask states, target matrix). Returns w (384,)."""
    w = torch.zeros(384, requires_grad=True)
    opt = torch.optim.Adam([w], lr=lr)
    data = [(torch.as_tensor(ck, dtype=torch.float32), torch.as_tensor(par, dtype=torch.long), npar,
             torch.as_tensor(S, dtype=torch.float32), torch.as_tensor(T, dtype=torch.float32)) for ck, par, npar, S, T in sets]
    for _ in range(epochs):
        for ck, par, npar, S, T in data:
            z = ck @ w
            mx = torch.full((npar,), -1e30).scatter_reduce(0, par, z.detach(), "amax", include_self=True)
            e = torch.exp(z - mx[par])
            den = torch.zeros(npar).index_add(0, par, e)
            a = e / den[par]
            P = torch.nn.functional.normalize(torch.zeros(npar, ck.shape[1]).index_add(0, par, a[:, None] * ck), dim=-1)
            loss = -(T * torch.log_softmax(20.0 * S @ P.T, 1)).sum(1).mean()
            opt.zero_grad(); loss.backward(); opt.step()
    return w.detach().numpy().astype(np.float64)


def mean_keys(K, ups):
    out = [np.asarray(K, dtype=np.float64)]
    for l in (1, 2, 3):
        out.append(C.unit(segsum(out[l - 1], ups[l], int(ups[l].max()) + 1)))
    return out


def attn_sets(corpora, level):
    """corpora: list of (K, S, ups, leafmap, evidence lists)."""
    sets = []
    for K, S, ups, leafmap, evs in corpora:
        mk = mean_keys(K, ups); npar = int(ups[level].max()) + 1
        T = np.zeros((len(evs), npar))
        for r, ev in enumerate(evs):
            ps = sorted(set(leafmap[level][ev].tolist())); T[r, ps] = 1.0 / len(ps)
        sets.append((mk[level - 1], ups[level], npar, S, T))
    return sets


def train_levels(corpora):
    return {l: train_attn(attn_sets(corpora, l)) for l in (1, 2, 3)}


# ---------------------------------------------------------------- one corpus (a chat or a haystack)

def lse_scores(X, leafmap_l, npar):
    mx = X.max(1, keepdims=True); E = np.exp((X - mx) / OMEGA)
    M = np.zeros((X.shape[1], npar)); M[np.arange(X.shape[1]), leafmap_l] = 1.0
    cnt = M.sum(0)
    return mx + OMEGA * np.log((E @ M) / cnt[None, :])


def corpus(K, S, evs, ups, leafmap, w_attn, leaf_len, docs, qtok, comp_err):
    """Per question: d' pieces per level and pool, and routing per level and router. evs: evidence leaf lists."""
    K = np.asarray(K, dtype=np.float64); S = np.asarray(S, dtype=np.float64)
    X = S @ K.T; nq, nl = X.shape
    mk = mean_keys(K, ups)
    rows = [dict(single=len(ev) == 1, lv={}) for ev in evs]
    # level 0
    for r, ev in enumerate(evs):
        if len(ev) == 1:
            rows[r]["lv"][0] = {"leaf": _dp(X[r], ev[0])}
    lse_prev = X; size_prev = np.asarray(leaf_len, dtype=np.float64); nl_prev = np.ones(nl)
    out_scores = {}
    for l in (1, 2, 3):
        npar = int(ups[l].max()) + 1; nlow = len(ups[l])
        nchild = np.bincount(ups[l], minlength=npar); nleaf = np.bincount(leafmap[l], minlength=npar)
        low = mk[l - 1]
        # oracle counts from this corpus's d'-set questions at level l
        cnt = np.zeros((npar, nlow))
        if npar >= 2:
            for ev in evs:
                if len(ev) == 1:
                    cnt[leafmap[l][ev[0]], leafmap[l - 1][ev[0]]] += 1
        sc = {"mean": S @ mk[l].T}
        za = low @ w_attn[l]; beta_a = np.zeros(nlow)
        for u in range(npar):
            ch = np.where(ups[l] == u)[0]; e = np.exp(za[ch] - za[ch].max()); beta_a[ch] = e / e.sum()
        beta_s = np.maximum(size_prev if l == 1 else nl_prev, 1.0)
        beta_o = np.ones(nlow)
        for u in range(npar):
            ch = np.where(ups[l] == u)[0]
            if cnt[u, ch].sum() > 0:
                beta_o[ch] = cnt[u, ch]
        for name, beta in (("attn", beta_a), ("size", beta_s), ("oracle", beta_o)):
            sc[name] = S @ C.unit(segsum(beta[:, None] * low, ups[l], npar)).T
        sc["lse"] = lse_scores(X, leafmap[l], npar)
        # composition check: normalised LSE from the children's with size weights
        wsz = nl_prev / nleaf[ups[l]]
        mx = lse_prev.max(1, keepdims=True)
        comp = mx + OMEGA * np.log(segsum((wsz[None, :] * np.exp((lse_prev - mx) / OMEGA)).T, ups[l], npar).T)
        comp_err[0] = max(comp_err[0], float(np.abs(comp - sc["lse"]).max()))
        sc["max"] = np.stack([X[:, leafmap[l] == u].max(1) for u in range(npar)], 1)
        bm = C.BM25([sum((docs[v] for v in np.where(leafmap[l] == u)[0]), []) for u in range(npar)])
        out_scores[l] = sc
        for r, ev in enumerate(evs):
            evp = sorted(set(leafmap[l][ev].tolist())); k = len(evp)
            route = {}
            for name in ROUTERS:
                o = bm.rank(qtok[r]) if name == "bm25" else C.order_of(sc[name][r])
                top = set(np.asarray(o[:BUDGET]).tolist())
                route[name] = (len(top & set(evp)) / k, float(int(o[0]) in evp) / k)
            rows[r].setdefault("route", {})[l] = dict(r=route, nplus=k, ceil=min(k, BUDGET) / k, npar=npar)
            if len(ev) == 1 and npar >= 2:
                pos = int(leafmap[l][ev[0]]); c = cnt[pos][cnt[pos] > 0]; pi = c / c.sum()
                d = {p: _dp(sc[p][r], pos) for p in POOLS}
                d["_n"] = int(nchild[pos]); d["_N"] = int(nleaf[pos]); d["_bound"] = math.sqrt(nchild[pos] * float((pi ** 2).sum()))
                rows[r]["lv"][l] = d
        lse_prev = sc["lse"]; size_prev = None; nl_prev = nleaf.astype(np.float64)
    return rows, out_scores


def _dp(sc, pos):
    neg = np.delete(sc, pos); m = neg.mean()
    return (float(sc[pos] - m), float(((neg - m) ** 2).sum()), len(neg) - 1,
            float((sc[pos] - m) / neg.std()) if len(neg) >= 5 else float("nan"))


# ---------------------------------------------------------------- bootstrap machinery (common random numbers)

class Draws:
    """The same cluster resampling as common.cluster_boot (rng.integers over the unique cluster ids), held as a count
    matrix so any statistic built from cluster sums is recomputed in every draw."""

    def __init__(self, cluster, n=NBOOT, seed=SEED):
        ids = np.unique(cluster); self.k = len(ids); self.pos = np.searchsorted(ids, cluster)
        pick = np.random.default_rng(seed).integers(0, self.k, (n, self.k))
        self.W = np.stack([np.bincount(p, minlength=self.k) for p in pick]).astype(np.float64)

    def tot(self, v):
        cs = np.bincount(self.pos, weights=np.nan_to_num(np.asarray(v, dtype=np.float64)), minlength=self.k)
        return np.concatenate([[cs.sum()], self.W @ cs])  # index 0 = full sample, 1.. = draws


def ci(v):
    d = v[1:][np.isfinite(v[1:])]
    if not len(d):
        return [round(float(v[0]), 4), None, None]
    return [round(float(v[0]), 4), round(float(np.percentile(d, 2.5)), 4), round(float(np.percentile(d, 97.5)), 4)]


class Table:
    """Per-question arrays for one dataset and space."""

    def __init__(self, rows, cluster, cat, multi):
        self.rows = rows; self.D = Draws(cluster); self.cluster = np.asarray(cluster); self.cat = cat
        self.multi = np.asarray(multi, dtype=bool); self.nq = len(rows)

    def arr(self, l, key, part=None):
        out = np.full(self.nq, np.nan)
        for i, r in enumerate(self.rows):
            d = r["lv"].get(l)
            if d is None:
                continue
            v = d[key] if key in d else d.get("leaf")
            out[i] = v if part is None else v[part]
        return out

    def mask(self, l):
        return np.array([l in r["lv"] for r in self.rows]) & np.array([0 in r["lv"] for r in self.rows])

    def dprime(self, l, pool, m):
        p = "leaf" if l == 0 else pool
        delta, ss, df = (self.arr(l, p, j) for j in range(3))
        mm = m.astype(float)
        num = self.D.tot(delta * mm) / self.D.tot(mm)
        sig = np.sqrt(self.D.tot(ss * mm) / self.D.tot(np.where(df > 0, df, 0) * mm))
        return num / sig

    def fit(self, l, pool, m, old=False):
        nvals = self.arr(l, "_n")
        if old:
            a = self.arr(l, "leaf" if l == 0 else pool, 3); b = self.arr(l - 1, "leaf" if l == 1 else pool, 3)
            m = m & np.isfinite(a) & np.isfinite(b)
        vals = nvals[m]
        if not len(vals):
            return dict(estimable=False, questions=0)
        u = np.unique(vals)
        if len(u) <= 6:
            bins = [(nvals == v) & m for v in u]
        else:
            edges = np.unique(np.quantile(vals, [0.25, 0.5, 0.75]))
            bid = np.searchsorted(edges, nvals, side="left")
            bins = [(bid == j) & m for j in range(len(edges) + 1)]
        bins = [b for b in bins if b.sum() >= MIN_BIN]
        if len(bins) < 2:
            return dict(estimable=False, questions=int(m.sum()), bins=[int(b.sum()) for b in bins])
        if old:
            num = [self.D.tot(np.where(b, a, 0)) for b in bins]; den = [self.D.tot(np.where(b, self.arr(l - 1, "leaf" if l == 1 else pool, 3), 0)) for b in bins]
            rho = [x / y for x, y in zip(num, den)]
        else:
            dl = self.dprime_parts(l, pool, m); dk = self.dprime_parts(l - 1, pool, m)
            rho = []
            for b in bins:
                bb = b.astype(float)
                rho.append((self.D.tot(dl[0] * bb) / dl[1]) / (self.D.tot(dk[0] * bb) / dk[1]))
        nbar = [self.D.tot(np.where(b, nvals, 0)) / self.D.tot(b.astype(float)) for b in bins]
        x = np.log(np.stack(nbar, 1)); y = np.full_like(x, np.nan)
        R = np.stack(rho, 1); ok = np.isfinite(R) & (R > 0) & np.isfinite(x)
        y[ok] = np.log(R[ok]); v = ok.astype(float); x0 = np.where(ok, x, 0); y0 = np.where(ok, y, 0)
        cnt = v.sum(1); xm = (x0 * v).sum(1) / np.maximum(cnt, 1); ym = (y0 * v).sum(1) / np.maximum(cnt, 1)
        sxx = (v * (x0 - xm[:, None]) ** 2).sum(1); sxy = (v * (x0 - xm[:, None]) * (y0 - ym[:, None])).sum(1)
        slope = np.where((cnt >= 2) & (sxx > 1e-12), sxy / np.where(sxx > 1e-12, sxx, 1), np.nan)
        gamma = -slope
        finite = float(np.isfinite(gamma[1:]).mean())
        return dict(estimable=bool(np.isfinite(gamma[0]) and finite >= 0.9), questions=int(m.sum()), gamma=ci(gamma),
                    finite_draw_share=round(finite, 4),
                    bins=[dict(n=round(float(nb[0]), 2), questions=int(b.sum()), rho=round(float(r[0]), 4))
                          for nb, b, r in zip(nbar, bins, rho)])

    def dprime_parts(self, l, pool, m):
        p = "leaf" if l == 0 else pool
        delta, ss, df = (self.arr(l, p, j) for j in range(3))
        mm = m.astype(float)
        sig = np.sqrt(self.D.tot(ss * mm) / self.D.tot(np.where(df > 0, df, 0) * mm))
        return np.nan_to_num(delta), sig

    def level(self, l):
        m = self.mask(l); out = dict(questions=int(m.sum()))
        if m.sum() == 0:
            return out
        nv = self.arr(l, "_n"); Nv = self.arr(l, "_N")
        out["mean_children_n"] = round(float(nv[m].mean()), 3); out["mean_leaves_N"] = round(float(Nv[m].mean()), 2)
        leaf = self.dprime(0, "leaf", m)
        dp = {p: self.dprime(l, p, m) for p in POOLS}
        out["dprime"] = {"leaf": ci(leaf), **{p: ci(v) for p, v in dp.items()}}
        out["share_of_leaf"] = {p: ci(v / leaf) for p, v in dp.items()}
        out["rho_vs_child_level"] = {p: ci(dp[p] / self.dprime(l - 1, "leaf" if l == 1 else p, m)) for p in ("mean", "lse")}
        nbar = float(nv[m].mean())
        out["implied_exponent_mean_whole_level"] = (round(float(-np.log(out["rho_vs_child_level"]["mean"][0]) / np.log(nbar)), 3)
                                                    if nbar > 1.2 and out["rho_vs_child_level"]["mean"][0] > 0 else None)
        Nbar = float(Nv[m].mean())
        r0 = float(dp["mean"][0] / leaf[0])
        out["implied_exponent_mean_vs_leaves"] = round(float(-np.log(r0) / np.log(Nbar)), 3) if Nbar > 1.2 and r0 > 0 else None
        out["fit"] = {"mean": self.fit(l, "mean", m), "lse": self.fit(l, "lse", m),
                      "mean_old_per_question_form": self.fit(l, "mean", m, old=True)}
        bnd = self.D.tot(self.arr(l, "_bound") * m) / self.D.tot(m.astype(float))
        out["fixed_pools"] = {}
        for p in FIXED:
            g = dp[p] / dp["mean"]
            out["fixed_pools"][p] = dict(gain_over_mean=ci(g), bound=ci(bnd), excess=ci(g - bnd))
        return out

    def routing(self, l):
        out = {}
        for part, sel in (("all", np.ones(self.nq, bool)), ("multi", self.multi)):
            idx = np.where(sel)[0]
            ceil = np.array([self.rows[i]["route"][l]["ceil"] for i in idx])
            res = dict(questions=int(len(idx)), ceiling=round(float(ceil.mean()), 4),
                       questions_with_more_than_b_parents=int(sum(self.rows[i]["route"][l]["npar"] > BUDGET for i in idx)))
            worst = -1.0
            for name in ROUTERS:
                cov = np.array([self.rows[i]["route"][l]["r"][name][0] for i in idx])
                top1 = np.array([self.rows[i]["route"][l]["r"][name][1] for i in idx])
                worst = max(worst, float((cov - ceil).max()))
                g, gci = C.cluster_boot(ceil - cov, self.cluster[idx])
                res[name] = dict(coverage3=round(float(cov.mean()), 4), top1=round(float(top1.mean()), 4),
                                 gap_to_ceiling=[round(g, 4)] + [round(x, 4) for x in gci],
                                 above_ceiling=bool(cov.mean() > ceil.mean() + 1e-9))
            res["max_per_question_excess"] = worst
            out[part] = res
        return out


# ---------------------------------------------------------------- main

def main():
    t0 = time.time()
    R = Reader()
    print(f"loaded in {time.time() - t0:.0f}s", flush=True)
    comp_err = [0.0]
    trees = [locomo_tree(c) for c in R.chats]
    ltrees = [lme_tree(it) for it in R.items]
    structure = dict(
        locomo=dict(questions=sum(len(c["qs"]) for c in R.chats),
                    single_evidence=sum(len(q[1]) == 1 for c in R.chats for q in c["qs"]),
                    multi_hop=sum(q[2] == 1 for c in R.chats for q in c["qs"]),
                    sessions=sum(int(t[0][1].max()) + 1 for t in trees), weeks=sum(int(t[0][2].max()) + 1 for t in trees),
                    months=sum(int(t[0][3].max()) + 1 for t in trees)),
        lme=dict(questions=len(R.items), single_evidence=sum(len(it["ev"]) == 1 for it in R.items),
                 multi_session=sum(it["type"] == "multi-session" for it in R.items),
                 sessions_per_haystack=round(float(np.mean([int(t[0][1].max()) + 1 for t in ltrees])), 2),
                 weeks_per_haystack=round(float(np.mean([int(t[0][2].max()) + 1 for t in ltrees])), 2),
                 months_per_haystack=round(float(np.mean([int(t[0][3].max()) + 1 for t in ltrees])), 2),
                 haystacks_with_2plus_weeks=sum(int(t[0][2].max()) >= 1 for t in ltrees),
                 haystacks_with_2plus_months=sum(int(t[0][3].max()) >= 1 for t in ltrees)))
    print(json.dumps(structure), flush=True)
    evs = [[q[1] for q in c["qs"]] for c in R.chats]
    lens = [[len(t.split()) for t in c["text"]] for c in R.chats]
    qtok = [[C.tokens(q[0]) for q in c["qs"]] for c in R.chats]
    views = {}
    for space in ("bridge", "frozen"):
        for f in range(5):
            br = R.bridges[f]
            for j in range(10):
                c = R.chats[j]
                views[(space, f, j)] = br.views(c["nodes"], c["asks"]) if space == "bridge" else (c["nodes"], c["asks"])
    results = {"locomo": {}, "lme": {}}
    tables = {}
    adaptive = None
    for space in ("bridge", "frozen"):
        # ---- LoCoMo
        rows, cluster, cat, multi = [], [], [], []
        ad_rows = []
        for f, test in enumerate(C.FOLDS):
            tr = [j for j in range(10) if j not in test]
            w = train_levels([(views[(space, f, j)][0], views[(space, f, j)][1], trees[j][0], trees[j][1], evs[j]) for j in tr])
            if space == "bridge":
                theta = {}
                for l in (1, 2, 3):
                    opened = np.zeros(len(THETA_GRID)); nq = 0
                    for j in tr:
                        K, S = views[(space, f, j)]
                        X = np.asarray(S, dtype=np.float64) @ np.asarray(K, dtype=np.float64).T
                        L = lse_scores(X, trees[j][1][l], int(trees[j][0][l].max()) + 1)
                        gap = L.max(1, keepdims=True) - L
                        opened += (gap[:, :, None] <= THETA_GRID[None, None, :] + 1e-12).sum(1).sum(0); nq += len(L)
                    theta[l] = float(THETA_GRID[int(np.argmin(np.abs(opened / nq - BUDGET)))])
            for i in test:
                K, S = views[(space, f, i)]
                r_i, sc = corpus(K, S, evs[i], *trees[i], w, lens[i], R.chats[i]["docs"], qtok[i], comp_err)
                rows += r_i; cluster += [i] * len(r_i)
                cat += [q[2] for q in R.chats[i]["qs"]]; multi += [q[2] == 1 for q in R.chats[i]["qs"]]
                if space == "bridge":
                    for r, ev in enumerate(evs[i]):
                        a = {}
                        for l in (1, 2, 3):
                            L = sc[l]["lse"][r]; op = set(np.where(L.max() - L <= theta[l] + 1e-12)[0].tolist())
                            evp = set(trees[i][1][l][ev].tolist())
                            a[l] = (len(op), len(op & evp) / len(evp), theta[l])
                        ad_rows.append(a)
            print(f"{space} locomo fold {f} done {time.time() - t0:.0f}s", flush=True)
        T = Table(rows, cluster, cat, multi); tables[("locomo", space)] = T
        results["locomo"][space] = {LEVELS[l]: dict(dprime=T.level(l), routing=T.routing(l)) for l in (1, 2, 3)}
        if space == "bridge":
            adaptive = {}
            mh = np.array(multi)
            for l in (1, 2, 3):
                nb = np.array([a[l][0] for a in ad_rows]); cv = np.array([a[l][1] for a in ad_rows])
                adaptive[LEVELS[l]] = dict(theta_per_fold=sorted({round(a[l][2], 3) for a in ad_rows}),
                                           mean_opened_all=round(float(nb.mean()), 3), coverage_all=round(float(cv.mean()), 4),
                                           mean_opened_multi=round(float(nb[mh].mean()), 3), coverage_multi=round(float(cv[mh].mean()), 4),
                                           fixed_b_ceiling_multi=results["locomo"][space][LEVELS[l]]["routing"]["multi"]["ceiling"])
            results["locomo"][space]["adaptive_b_secondary"] = adaptive
        # ---- LongMemEval-S
        allc = [(R.lme_bridge.views(c["nodes"], c["asks"]) if space == "bridge" else (c["nodes"], c["asks"])) for c in R.chats]
        w = train_levels([(allc[j][0], allc[j][1], trees[j][0], trees[j][1], evs[j]) for j in range(10)])
        rows, cluster, cat, multi = [], [], [], []
        for j, it in enumerate(R.items):
            if space == "bridge":
                K, S = R.lme_keys[j], R.lme_state[j][None, :]
            else:
                K, S = C.unit(R.vec[it["rows"]].astype(np.float64)), it["q"][None, :]
            ln = [len(R.texts[g].split()) for g in it["rows"]]
            r_j, _ = corpus(K, S, [it["ev"]], *ltrees[j], w, ln, it["docs"], [C.tokens(it["question"])], comp_err)
            rows += r_j; cluster.append(j); cat.append(it["type"]); multi.append(it["type"] == "multi-session")
        print(f"{space} lme done {time.time() - t0:.0f}s", flush=True)
        T = Table(rows, cluster, cat, multi); tables[("lme", space)] = T
        results["lme"][space] = {LEVELS[l]: dict(dprime=T.level(l), routing=T.routing(l)) for l in (1, 2, 3)}

    # ---- verdicts (bridge space only), mechanical
    v = {}
    cells = [(ds, LEVELS[l]) for ds in ("locomo", "lme") for l in (1, 2, 3)]
    # P7a
    rows7a = {}; fail = False; allok = True; any_est = False
    for ds, lv in cells:
        f = results[ds]["bridge"][lv]["dprime"].get("fit", {}).get("mean", {})
        if not f.get("estimable"):
            rows7a[f"{ds} {lv}"] = "not estimable"; continue
        any_est = True
        g, lo, hi = f["gamma"]
        outside = hi < GAMMA_BAND[0] or lo > GAMMA_BAND[1]
        ok = GAMMA_BAND[0] <= g <= GAMMA_BAND[1] and not (hi < GAMMA_CORE[0] or lo > GAMMA_CORE[1])
        fail |= outside; allok &= ok
        rows7a[f"{ds} {lv}"] = dict(gamma=[g, lo, hi], ci_outside_band=outside, consistent=ok)
    loc_sess = results["locomo"]["bridge"]["session"]["dprime"].get("fit", {}).get("mean", {}).get("estimable", False)
    v["P7a_mean_exponent"] = dict(cells=rows7a, band=GAMMA_BAND, core=GAMMA_CORE,
                                  verdict="FAIL" if fail else ("PASS" if allok and any_est and loc_sess else "INCONCLUSIVE"))
    # P7b
    rows7b = {}; fail = False; allok = True
    for ds, lv in cells:
        d = results[ds]["bridge"][lv]["dprime"]
        if d["questions"] < MIN_CELL:
            rows7b[f"{ds} {lv}"] = f"too few questions ({d['questions']})"; continue
        s = d["share_of_leaf"]["lse"]
        fail |= s[2] is not None and s[2] < LSE_SHARE; allok &= s[0] >= LSE_SHARE
        rows7b[f"{ds} {lv}"] = s
    v["P7b_lse_share_of_leaf"] = dict(cells=rows7b, bar=LSE_SHARE, verdict="FAIL" if fail else ("PASS" if allok else "INCONCLUSIVE"))
    # P7c
    rows7c = {}; fail = False; allok = True
    for ds, lv in cells:
        d = results[ds]["bridge"][lv]["dprime"]
        if d["questions"] < MIN_CELL:
            rows7c[f"{ds} {lv}"] = f"too few questions ({d['questions']})"; continue
        for p in FIXED:
            e = d["fixed_pools"][p]["excess"]
            fail |= e[1] is not None and e[1] > 0; allok &= e[0] <= 0
            rows7c[f"{ds} {lv} {p}"] = dict(gain=d["fixed_pools"][p]["gain_over_mean"], bound=d["fixed_pools"][p]["bound"], excess=e)
    v["P7c_fixed_pool_bound"] = dict(cells=rows7c, verdict="FAIL" if fail else ("PASS" if allok else "INCONCLUSIVE"))
    # P8
    above = []
    for ds, lv in cells:
        for part in ("all", "multi"):
            rr = results[ds]["bridge"][lv]["routing"][part]
            above += [f"{ds} {lv} {part} {n}" for n in ROUTERS if rr[n]["above_ceiling"]]
    sm = results["locomo"]["bridge"]["session"]["routing"]["multi"]
    v["P8_coverage_ceiling"] = dict(locomo_session_multi_hop_ceiling=sm["ceiling"], method_value=0.939,
                                    best_router_multi_hop=max(ROUTERS, key=lambda n: sm[n]["coverage3"]),
                                    best_coverage_multi_hop=max(sm[n]["coverage3"] for n in ROUTERS),
                                    routers_above_ceiling=above, verdict="FAIL" if above else "PASS")
    vs = [v[k]["verdict"] for k in ("P7a_mean_exponent", "P7b_lse_share_of_leaf", "P7c_fixed_pool_bound", "P8_coverage_ceiling")]
    v["overall"] = "FAIL" if "FAIL" in vs else ("PASS" if all(x == "PASS" for x in vs) else "INCONCLUSIVE")
    out = dict(lse_form="normalised: w log((1/|leaves(u)|) sum_v exp(<s,k_v>/w)), w = 0.05", budget_b=BUDGET,
               structure=structure, checks=dict(lse_composition_max_abs_err=comp_err[0]),
               results=results, verdict=v, runtime_s=round(time.time() - t0, 1))
    assert comp_err[0] < 1e-8, comp_err
    path = os.path.join(HERE, "results", "s18_pyramids.json")
    json.dump(out, open(path, "w"), indent=1)

    # ---- printout
    print(f"\nLSE form: {out['lse_form']}; composition identity max abs error {comp_err[0]:.2e}")
    for ds in ("locomo", "lme"):
        for space in ("bridge", "frozen"):
            print(f"\n=== {ds} / {space}")
            for l in (1, 2, 3):
                d = results[ds][space][LEVELS[l]]["dprime"]
                if d["questions"] == 0:
                    print(f"  {LEVELS[l]:<8} no d' questions"); continue
                print(f"  {LEVELS[l]:<8} d' set {d['questions']:4d}  mean n {d['mean_children_n']:.2f}  mean N {d['mean_leaves_N']:.1f}  "
                      + "  ".join(f"{p} {d['dprime'][p][0]:.2f}" for p in ("leaf",) + POOLS))
                print(f"           share of leaf: " + "  ".join(f"{p} {d['share_of_leaf'][p][0]:.3f} [{_f(d['share_of_leaf'][p][1])},{_f(d['share_of_leaf'][p][2])}]" for p in ("mean", "lse", "max")))
                print(f"           rho vs child level: mean {d['rho_vs_child_level']['mean']}  lse {d['rho_vs_child_level']['lse']}  "
                      f"implied mean exponent (level) {d['implied_exponent_mean_whole_level']}  (vs leaves N) {d['implied_exponent_mean_vs_leaves']}")
                for k, fr in d["fit"].items():
                    if fr.get("estimable") or "gamma" in fr:
                        print(f"           fit {k:<27} gamma {fr['gamma']}  finite {fr['finite_draw_share']}  bins "
                              + "; ".join(f"n {b['n']} ({b['questions']}) rho {b['rho']}" for b in fr["bins"]))
                    else:
                        print(f"           fit {k:<27} not estimable {fr}")
                for p in FIXED:
                    fp = d["fixed_pools"][p]
                    print(f"           fixed {p:<7} gain {fp['gain_over_mean']}  bound {fp['bound']}  excess {fp['excess']}")
                for part in ("all", "multi"):
                    rr = results[ds][space][LEVELS[l]]["routing"][part]
                    print(f"           route {part:<5} ({rr['questions']} q, ceiling {rr['ceiling']:.3f}): "
                          + "  ".join(f"{n} {rr[n]['coverage3']:.3f}/{rr[n]['top1']:.3f}" for n in ROUTERS))
    print("\nadaptive b (LoCoMo bridge, lse, secondary):", json.dumps(adaptive))
    print("\nVERDICT", json.dumps(v, indent=1))
    print(f"runtime {out['runtime_s']}s")


def _f(x):
    return "nan" if x is None else f"{x:.3f}"


if __name__ == "__main__":
    main()
