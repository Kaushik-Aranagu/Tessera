#!/usr/bin/env python3
"""Stage 1.6 (prediction P4): is the hub cost convex in the step size eta? Method Remark 6.1 tested on LongMemEval-S.

Pre-registered (this docstring) before any cost, gap, drift or spread was measured on the new setup.

Question. Remark 6.1 models the hub cost of the move rule k_v <- n(k_v + eta (s - k_v)) with clean cites: a node with
n_v cites rises by h_bar * eta * n_v / 2 on unrelated asks and enters an unrelated ask's top 10 with probability
Pbar((g_gap - h_bar eta n_v / 2) / spread), Pbar = 1 - Phi. Up to a constant the predicted cost at eta is
    P(eta) = sum over cited nodes v of [ Pbar((g_gap - h_bar eta n_v / 2) / spread) - Pbar(g_gap / spread) ]
(exactly math/theory/hmodel.py), and the predicted ratios are P(eta) / P(0.02). On LoCoMo (old bridges) it gave 2.69,
6.08, 15.5 at eta 0.05, 0.1, 0.2 against measured 2.67, 6.43, 19.0; linear would be 2.5, 5, 10. P4: on a second
dataset, with that dataset's own h_bar, gap, spread and cite counts, the Remark predicts the ratios within 25%;
falsified by linear ratios. Front matter test 1.6: pass bar "cost ratios within 25% of method Remark 6.1"; fails if
"ratios grow linearly (2.5, 5, 10)".

Data and read. LongMemEval-S, the 428 questions with user-turn evidence (common.load_lme). One global key table over the
93,931 unique user-turn texts: K0[g] = n(A x_g) under the rank-16 bridge trained on all 10 LoCoMo chats (R.lme_bridge);
states s_q = R.lme_state[q]. A question reads only its own haystack positions (rows into the shared table): dense
scores <k_rows[p], s_q>, ranked by common.order_of, top 10; the fused read is common.fuse(BM25 order, dense order). A
text that recurs in several haystacks has one key, so moving it touches every haystack that holds it.

Stream (move rule, clean cites; s12's run_order on one shared table). In each order the 428 questions are visited once;
at each visit the question reads with the current keys, then each of its evidence keys (the unique table rows under its
has_answer positions) moves once: k <- n(k + eta (s_q - k)). eta in {0.02, 0.05, 0.1, 0.2, 0.4}, the same orders for
every eta (common random numbers). Orders: np.random.default_rng([10, o, 2027]).permutation(428), o = 0..499 (s12's
seeding, stream index 10 after LoCoMo chats 0-9). 500 orders because the stream is cheap and few evidence texts recur
across haystacks (see below); more orders only remove order noise, not the question sampling noise.

Measured cost (definitions fixed here).
  moved set M_t   table rows moved before visit t.
  unrelated visit none of the visited question's evidence rows is in M_t (as noise.py on LoCoMo: no evidence overlap
                  with any earlier visited question). It depends only on the order, so it is the same for every eta.
  intrusions      PRIMARY. On an unrelated visit, the number of positions in the learned dense top 10 whose row is in
                  M_t and which are not in the question's no-learning dense top 10.
  recall loss     secondary. No-learning recall@10 minus learned recall@10 on unrelated visits, dense and fused.
  cost(eta)       sum over orders and unrelated visits / number of unrelated visits. Measured ratio
                  r_m(eta) = cost(eta) / cost(0.02) (the denominators cancel).

Remark inputs, measured on LongMemEval-S itself with the frozen table K0 (no learning). Fixed here:
  s_bar   mean of the 428 question states (the stream's asks; on LoCoMo it was the chat's asks).
  h_bar   mean over cite events (question q, each unique evidence row g of q) of <s_q, s_bar> - <k_g, s_q><k_g, s_bar>
          (eq. 6.1, as math/theory/extra.py).
  g_gap   mean over questions of theta_10(q) minus the mean dense score over q's haystack positions (as extra.py).
  spread  sd of the dense scores <k, s_q> pooled over all (question, haystack position) pairs (as hub.py's sd of
          ask-node scores pooled over asks x nodes). Sensitivity only: mean within-question sd; pooled sd of the score
          minus the question's own theta_10.
  n_v     number of questions whose unique evidence rows include v, over the cited rows.
Prediction r_p(eta) = P(eta) / P(0.02) with these inputs (primary form, hmodel.py's formula).
Secondary forms, reported and not used for the verdict: order-averaged (number of earlier cites j uniform on 0..n_v in
place of n_v / 2); exposure-weighted (each v weighted by the number of other haystacks that hold it and do not cite it).

Statistics. Clusters are the visited questions (question-clustered, as for LongMemEval-S throughout stage 1): per
question, sums over the 500 orders. Ratio CI: 2.5 and 97.5 percentiles of the ratio of resampled sums, 4,000 draws,
seed 0, the same draws for every eta (common.cluster_boot's resampling of whole clusters). A draw with no intrusion at
0.02 gives an infinite ratio. The paired differences cost(eta) - r_p cost(0.02) and cost(eta) - lin cost(0.02) are
also reported with common.cluster_boot.

Decision rule (fixed before running). lin(eta) = eta / 0.02 (2.5, 5, 10; 20 at 0.4). band(eta) = [0.75 r_p, 1.25 r_p].
Method grid: eta in {0.05, 0.1, 0.2}; 0.4 is an added point.
  within(eta)  r_m(eta) is inside band(eta).
  off(eta)     the CI of r_m(eta) misses band(eta) entirely.
  disc(eta)    lin(eta) is outside band(eta): the linear falsifier can be told apart from the prediction at eta.
  unresolved   more than 2.5% of draws have no intrusion at 0.02 (the upper CI is unbounded).
  1. unresolved -> INCONCLUSIVE (the ratios cannot be measured on this dataset).
  2. FAIL if off(eta) at some grid eta; or, when no grid eta discriminates, off(0.4) with 20 inside the CI at 0.4
     (measured linear where the Remark predicts convex).
  3. PASS if within(eta) at every grid eta and, at some discriminating eta (a grid eta, or 0.4 when no grid eta
     discriminates), within(eta) holds and lin(eta) is outside the CI.
  4. Otherwise INCONCLUSIVE.
Why 0.4 is added: with LoCoMo's old constants and n_v = 1 the Remark gives about 2.6, 5.4, 12.3 on the grid, which is
within 25% of linear, so the grid may not separate convex from linear where nodes are cited once; at 0.4 it gives about
31 against linear 20.

Looked at before writing this (structure only, no scores): the 428 haystacks hold 104,508 positions over 83,032 unique
texts; 816 rows are cited (790 once, 26 twice); a cited row sits in a mean of 0.43 other haystacks (32% in at least
one, max 6). So on LongMemEval-S hub cost can only come from evidence texts that recur in other questions' haystacks.

Secondary, reported without a verdict:
  - recall-loss ratios (dense, fused); ratios against eta 0.1; how many distinct (question, row) pairs carry the
    intrusions at each eta;
  - the prediction's sensitivity to the spread definition, and its interval when questions are resampled (h_bar, g_gap,
    spread recomputed per draw, cite counts held fixed);
  - exposure pairs: for each cited row v and each question q whose haystack holds v without citing it, the gap
    theta_10(q) - <k_v, s_q>, the first-order rise per unit eta <s_c, s_q> - <k_v, s_c><k_v, s_q> from each citer c,
    and a pair-level prediction of intrusions per order (exact moves, every order of q among v's citers equally likely,
    theta_10 held fixed, q's own related visits not removed);
  - LoCoMo reference on the new setup: the same Remark inputs (in-chat s_bar; spread pooled per chat, averaged over
    chats; as extra.py and hub.py) under the tuned rank-16 bridge of the fold that held each chat out, s12's three
    orders per chat (default_rng([chat, order, 2027])), measured C_+ (unrelated-visit dense recall loss) and intrusion
    ratios with chat-clustered intervals. It checks that the Remark still holds where it was fitted; it is not the bar.
Changes after the first run (run 1 printed the same primary numbers; nothing in the protocol, the measured cost, the
prediction or the decision rule changed): (a) the JSON is written strictly (infinite ratios as the string "inf");
(b) POST HOC, secondary only: the pair-level gap is taken from the stream's own float32 base scores and a pair counts
only if v is outside q's base top 10 (run 2 found that a float64 recomputation put a tenth-place row just below theta_10
and counted it); and a pair-level variant that drops orders where a citer of v that shares evidence with q
comes before q (q's visit is then related, so it is not hub cost); run 1 showed the plain pair-level count at 0.02 was
3x the measured count, from these two causes; (c) POST HOC, reference only: the same decision rule applied to LoCoMo's
own intrusion and C_+ ratios. Runs 1 to 3 gave identical primary numbers and the same verdict (log and JSON: run 3).
Usage: python s16_hubcost.py > results/s16_hubcost.log
"""
import collections, itertools, json, os, sys, time
import numpy as np
import torch
from scipy.stats import norm

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

ETAS = (0.02, 0.05, 0.1, 0.2, 0.4)
BASE = 0.02
GRID = (0.05, 0.1, 0.2)
EXT = 0.4
K = 10
N_ORDERS_LME = 500
ORDERS_LOCOMO = 3
LME_STREAM = 10
BAND = 0.25
NBOOT = 4000
NBOOT_PRED = 1000


def unit1(x):
    return x / np.linalg.norm(x)


def lin(eta):
    return eta / BASE


# ---------------------------------------------------------------- Remark 6.1

def remark(nv, h, g, sd, eta, form="half", w=None):
    nv = np.asarray(nv, dtype=np.float64); w = np.ones_like(nv) if w is None else np.asarray(w, dtype=np.float64)
    p0 = norm.sf(g / sd)
    if form == "half":
        return float((w * (norm.sf((g - h * eta * nv / 2) / sd) - p0)).sum())
    tot = 0.0  # order-averaged: j earlier cites uniform on 0..n_v
    for n, wt in zip(nv.astype(int), w):
        j = np.arange(n + 1)
        tot += wt * float((norm.sf((g - h * eta * j) / sd) - p0).mean())
    return tot


def ratios(f):
    b = f(BASE)
    return {eta: f(eta) / b for eta in ETAS}


# ---------------------------------------------------------------- the stream

def stream(K0, S, rows, evg, evpos, base_top, base_rec, base_frec, lexorder, order, eta):
    """One pass. Returns per question: unrelated flag, intrusions, dense and fused recall at its visit, exposed flag,
    and the set of intruding rows."""
    cur = {}; moved = np.zeros(len(K0), dtype=bool); nq = len(rows)  # cur: current keys of moved rows (K0 is not copied)
    unrel = np.zeros(nq, dtype=bool); intr = np.zeros(nq); rec = np.array(base_rec, dtype=np.float64)
    frec = np.array(base_frec, dtype=np.float64); exposed = np.zeros(nq, dtype=bool); who = {}
    for q in order:
        r = rows[q]; mv = moved[r]
        unrel[q] = not moved[evg[q]].any()
        if mv.any():
            exposed[q] = True
            kr = K0[r]
            for p in np.flatnonzero(mv):
                kr[p] = cur[int(r[p])]
            o = C.order_of(kr @ S[q])
            rec[q] = C.recall(o, evpos[q]); frec[q] = C.recall(C.fuse(lexorder[q], o), evpos[q])
            if unrel[q]:
                hit = [int(p) for p in o[:K] if mv[p] and int(p) not in base_top[q]]
                intr[q] = len(hit)
                if hit:
                    who[q] = {int(r[p]) for p in hit}
        for g in evg[q].tolist():
            k = cur.get(g, K0[g])
            cur[g] = unit1(k + eta * (S[q] - k)) if eta else k
        moved[evg[q]] = True
    return unrel, intr, rec, frec, exposed, who


def base_reads(K0, S, rows, evpos, lexorder):
    top, rec, frec, theta, mean, sd, scores = [], [], [], [], [], [], []
    for q in range(len(rows)):
        sc = K0[rows[q]] @ S[q]; o = C.order_of(sc)
        top.append(set(o[:K].tolist())); rec.append(C.recall(o, evpos[q])); frec.append(C.recall(C.fuse(lexorder[q], o), evpos[q]))
        theta.append(float(sc[o[K - 1]])); mean.append(float(sc.mean())); sd.append(float(sc.std())); scores.append(sc)
    return top, np.array(rec), np.array(frec), np.array(theta), np.array(mean), np.array(sd), scores


# ---------------------------------------------------------------- statistics

def ratio_boot(num, den, cluster, n=NBOOT, seed=0):
    """Ratio of sums, resampling whole clusters as common.cluster_boot does (same seed, same draws for every call)."""
    num = np.asarray(num, dtype=np.float64); den = np.asarray(den, dtype=np.float64); cluster = np.asarray(cluster)
    ids = np.unique(cluster)
    ns = np.array([num[cluster == c].sum() for c in ids]); ds = np.array([den[cluster == c].sum() for c in ids])
    pick = np.random.default_rng(seed).integers(0, len(ids), (n, len(ids)))
    a, b = ns[pick].sum(1), ds[pick].sum(1)
    zero = float((b == 0).mean())
    r = np.full(n, np.inf); r[b > 0] = a[b > 0] / b[b > 0]
    if np.isfinite(r).all():
        lo, hi = np.percentile(r, [2.5, 97.5])
    else:
        lo, hi = np.percentile(r, [2.5, 97.5], method="nearest")
    point = float(num.sum() / den.sum()) if den.sum() > 0 else float("inf")
    return point, [float(lo), float(hi)], zero


def fmt(x):
    return "inf" if not np.isfinite(x) else f"{x:.2f}"


def summarize(per_q, cluster, label, pred=None):
    """per_q[eta]: per question sum over orders. Ratios to BASE with cluster CIs, and to 0.1."""
    out = {"total": {str(e): round(float(per_q[e].sum()), 4) for e in ETAS}}
    out["ratio"] = {}
    for eta in ETAS[1:]:
        pt, ci, zero = ratio_boot(per_q[eta], per_q[BASE], cluster)
        row = dict(ratio=round(pt, 3), ci=[round(ci[0], 3), round(ci[1], 3) if np.isfinite(ci[1]) else "inf"],
                   zero_base_draws=round(zero, 4), linear=lin(eta))
        if pred is not None:
            row["predicted"] = round(pred[eta], 3)
            d, dci = C.cluster_boot(per_q[eta] - pred[eta] * per_q[BASE], cluster)
            row["diff_vs_predicted"] = [round(d, 5), [round(x, 5) for x in dci]]
        d, dci = C.cluster_boot(per_q[eta] - lin(eta) * per_q[BASE], cluster)
        row["diff_vs_linear"] = [round(d, 5), [round(x, 5) for x in dci]]
        out["ratio"][str(eta)] = row
    out["ratio_to_0.1"] = {}
    for eta in (0.2, 0.4):
        pt, ci, zero = ratio_boot(per_q[eta], per_q[0.1], cluster)
        row = dict(ratio=round(pt, 3), ci=[round(ci[0], 3), round(ci[1], 3) if np.isfinite(ci[1]) else "inf"], linear=eta / 0.1)
        if pred is not None:
            row["predicted"] = round(pred[eta] / pred[0.1], 3)
        out["ratio_to_0.1"][str(eta)] = row
    line = "  ".join(f"{e}: {fmt(out['ratio'][str(e)]['ratio'])} [{fmt(ratio_boot(per_q[e], per_q[BASE], cluster)[1][0])},"
                     f"{fmt(ratio_boot(per_q[e], per_q[BASE], cluster)[1][1])}]" for e in ETAS[1:])
    print(f"  {label:<28} totals {' '.join(f'{per_q[e].sum():.1f}' for e in ETAS)} | ratios to 0.02 {line}")
    return out


def verdict(meas, pred):
    """Mechanical rule from the docstring. meas[eta] = (ratio, [lo, hi]), zero share at BASE in meas['zero']."""
    rows, why = {}, []
    if meas["zero"] > 0.025:
        return "inconclusive", dict(reason=f"unresolved: {meas['zero']:.3f} of draws have no intrusion at 0.02")
    for eta in GRID + (EXT,):
        r, (lo, hi) = meas[eta]; p = pred[eta]; band = (0.75 * p, 1.25 * p)
        rows[eta] = dict(measured=round(r, 3), ci=[round(lo, 3), round(hi, 3) if np.isfinite(hi) else "inf"],
                         predicted=round(p, 3), band=[round(band[0], 3), round(band[1], 3)], linear=lin(eta),
                         within=bool(band[0] <= r <= band[1]), off=bool(hi < band[0] or lo > band[1]),
                         disc=bool(not band[0] <= lin(eta) <= band[1]), linear_in_ci=bool(lo <= lin(eta) <= hi))
    grid_disc = [e for e in GRID if rows[e]["disc"]]
    if any(rows[e]["off"] for e in GRID):
        v = "fail"; why.append("the CI misses the 25% band at " + ", ".join(str(e) for e in GRID if rows[e]["off"]))
    elif not grid_disc and rows[EXT]["off"] and rows[EXT]["linear_in_ci"]:
        v = "fail"; why.append("grid not discriminating; at 0.4 the CI misses the band and holds the linear 20")
    else:
        cands = grid_disc if grid_disc else [EXT]
        ok = all(rows[e]["within"] for e in GRID) and any(rows[e]["within"] and not rows[e]["linear_in_ci"] for e in cands)
        v = "pass" if ok else "inconclusive"
        why.append(f"grid within band: {[rows[e]['within'] for e in GRID]}; discriminating points used: {cands}; "
                   f"within and linear outside CI there: {[rows[e]['within'] and not rows[e]['linear_in_ci'] for e in cands]}")
    return v, dict(points={str(k): x for k, x in rows.items()}, grid_discriminating=grid_disc, reason="; ".join(why))


# ---------------------------------------------------------------- main

def main():
    t0 = time.time()
    R = Reader()
    out = {"etas": ETAS, "orders_lme": N_ORDERS_LME, "orders_locomo": ORDERS_LOCOMO}
    print(f"loaded in {time.time() - t0:.0f}s")

    # ============ LongMemEval-S: inputs
    items = R.items; nq = len(items)
    K0 = R.lme_bridge.key_np(R.vec).astype(np.float32)
    S = np.asarray(R.lme_state, dtype=np.float32)
    rows = [np.asarray(it["rows"]) for it in items]
    evpos = [list(it["ev"]) for it in items]
    evg = [np.array(sorted({int(it["rows"][e]) for e in it["ev"]}), dtype=np.int64) for it in items]
    lex = [it["lexorder"] for it in items]
    keydiff = max(float(np.abs(K0[rows[j]] - R.lme_keys[j]).max()) for j in range(nq))
    btop, brec, bfrec, theta, smean, ssd, scores = base_reads(K0, S, rows, evpos, lex)
    print(f"LongMemEval-S: {nq} questions, table {K0.shape[0]} keys (max diff to Reader keys {keydiff:.1e}); "
          f"no-learning recall dense {brec.mean():.4f} fused {bfrec.mean():.4f} (s11 rank 16: 0.8839 / 0.8982)")
    sbar = S.mean(0)
    events = [(q, int(g)) for q in range(nq) for g in evg[q]]
    drift = np.array([S[q] @ sbar - (K0[g] @ S[q]) * (K0[g] @ sbar) for q, g in events])
    h = float(drift.mean())
    gq = theta - smean; g_gap = float(gq.mean())
    allsc = np.concatenate(scores); sd_pool = float(allsc.std())
    sd_within = float(ssd.mean()); sd_gapdiff = float(np.concatenate([scores[q] - theta[q] for q in range(nq)]).std())
    cites = collections.Counter(g for q in range(nq) for g in evg[q].tolist())
    cited = np.array(sorted(cites)); nv = np.array([cites[g] for g in cited])
    holders = collections.defaultdict(list)
    cset = set(cited.tolist())
    for q in range(nq):
        for g in set(rows[q].tolist()) & cset:
            holders[g].append(q)
    evsets = [set(e.tolist()) for e in evg]
    expo = np.array([sum(1 for q in holders[g] if g not in evsets[q]) for g in cited])
    inputs = dict(h_bar=round(h, 4), g_gap=round(g_gap, 4), spread=round(sd_pool, 4), spread_within=round(sd_within, 4),
                  spread_score_minus_theta=round(sd_gapdiff, 4), norm_s_bar=round(float(np.linalg.norm(sbar)), 4),
                  cite_events=len(events), cited_rows=int(len(cited)), cite_counts=dict(sorted(collections.Counter(nv.tolist()).items())),
                  mean_cites=round(float(nv.mean()), 4), exposure_mean=round(float(expo.mean()), 4),
                  exposed_frac=round(float((expo > 0).mean()), 4), exposure_pairs=int(expo.sum()),
                  theta10_mean=round(float(theta.mean()), 4), mean_score=round(float(smean.mean()), 4),
                  base_dense=round(float(brec.mean()), 4), base_fused=round(float(bfrec.mean()), 4), key_table_max_diff=keydiff)
    print("Remark inputs on LongMemEval-S:", json.dumps(inputs))
    pred = ratios(lambda e: remark(nv, h, g_gap, sd_pool, e))
    sec = {"order_averaged": ratios(lambda e: remark(nv, h, g_gap, sd_pool, e, "order")),
           "exposure_weighted": ratios(lambda e: remark(nv, h, g_gap, sd_pool, e, w=expo)),
           "spread_within": ratios(lambda e: remark(nv, h, g_gap, sd_within, e)),
           "spread_score_minus_theta": ratios(lambda e: remark(nv, h, g_gap, sd_gapdiff, e))}
    # interval of the prediction: resample questions for h_bar, g_gap, spread (cite counts fixed)
    ev_q = np.array([q for q, _ in events]); n_pos = np.array([len(s) for s in scores])
    s1 = np.array([s.sum() for s in scores]); s2 = np.array([(s.astype(np.float64) ** 2).sum() for s in scores])
    dsum = np.bincount(ev_q, weights=drift, minlength=nq); dcnt = np.bincount(ev_q, minlength=nq)
    pick = np.random.default_rng(1).integers(0, nq, (NBOOT_PRED, nq)); pb = {e: [] for e in ETAS[1:]}
    for p in pick:
        hh = dsum[p].sum() / dcnt[p].sum(); gg = gq[p].mean()
        m = s1[p].sum() / n_pos[p].sum(); ss = np.sqrt(s2[p].sum() / n_pos[p].sum() - m * m)
        b = remark(nv, hh, gg, ss, BASE)
        for e in ETAS[1:]:
            pb[e].append(remark(nv, hh, gg, ss, e) / b)
    pred_ci = {str(e): [round(float(np.percentile(pb[e], 2.5)), 3), round(float(np.percentile(pb[e], 97.5)), 3)] for e in ETAS[1:]}
    print("predicted ratios to 0.02 (primary): " + "  ".join(f"{e}: {pred[e]:.2f} {pred_ci[str(e)]}" for e in ETAS[1:]))
    for k, v in sec.items():
        print(f"  secondary form {k:<26} " + "  ".join(f"{e}: {v[e]:.2f}" for e in ETAS[1:]))

    # exposure pairs: gaps, first-order rises, pair-level prediction
    citers = collections.defaultdict(list)
    for q in range(nq):
        for g in evg[q].tolist():
            citers[g].append(q)
    pairs = []
    for g in cited.tolist():
        for q in holders[g]:
            if g in evsets[q]:
                continue
            k = K0[g].astype(np.float64); sq = S[q].astype(np.float64)
            pos = np.flatnonzero(rows[q] == g)  # gap from the stream's own float32 base scores (fix after run 2)
            gap = float(theta[q] - scores[q][pos[0]]); inb = any(int(x) in btop[q] for x in pos)
            rise = [float(S[c] @ sq - (k @ S[c]) * (k @ sq)) for c in citers[g]]
            pairs.append((g, q, gap, rise, inb))
    gaps = np.array([p[2] for p in pairs]); rises = np.array([np.mean(p[3]) for p in pairs])
    outside = ~np.array([p[4] for p in pairs])

    def pair_pred(eta, drop_related=False):
        tot = 0.0
        for g, q, gap, _, inb in pairs:
            cs = citers[g]; sq = S[q].astype(np.float64); hits = []
            for perm in itertools.permutations(cs + [q]):
                k = K0[g].astype(np.float64); a0 = k @ sq; rel = False
                for c in perm:
                    if c == q:
                        break
                    rel |= bool(evsets[c] & evsets[q])
                    k = k + eta * (S[c] - k); k = k / np.linalg.norm(k)
                hits.append((not inb) and (k @ sq - a0) > gap and not (drop_related and rel))
            tot += np.mean(hits)
        return tot
    pp = {e: pair_pred(e) for e in ETAS}
    pp2 = {e: pair_pred(e, True) for e in ETAS}  # post hoc (after run 1): a citer that shares evidence with q makes q's visit related
    diag = dict(pairs=len(pairs), gap_mean=round(float(gaps.mean()), 4), gap_sd=round(float(gaps.std()), 4),
                gap_frac_le0=round(float((gaps <= 0).mean()), 4), frac_in_base_top10=round(float((~outside).mean()), 4),
                gap_quantiles=[round(float(x), 4) for x in np.percentile(gaps, [5, 10, 25, 50])],
                rise_per_eta_mean=round(float(rises.mean()), 4), rise_per_eta_sd=round(float(rises.std()), 4),
                pairs_with_gap_in_0_to_eta_rise={str(e): int((outside & (gaps < e * rises)).sum()) for e in ETAS},
                pair_level_intrusions_per_order={str(e): round(pp[e], 3) for e in ETAS},
                pair_level_ratio={str(e): round(pp[e] / pp[BASE], 3) if pp[BASE] > 0 else "inf" for e in ETAS[1:]},
                posthoc_pairs_citer_shares_evidence_with_q=int(sum(1 for g, q, _, _, _ in pairs if any(evsets[c] & evsets[q] for c in citers[g]))),
                posthoc_pair_level_related_dropped_per_order={str(e): round(pp2[e], 3) for e in ETAS},
                posthoc_pair_level_related_dropped_ratio={str(e): round(pp2[e] / pp2[BASE], 3) if pp2[BASE] > 0 else "inf" for e in ETAS[1:]})
    print("exposure pairs:", json.dumps(diag))

    # ============ LongMemEval-S: the streams
    t1 = time.time()
    orders = [np.random.default_rng([LME_STREAM, o, 2027]).permutation(nq) for o in range(N_ORDERS_LME)]
    intr = {e: np.zeros(nq) for e in ETAS}; dl = {e: np.zeros(nq) for e in ETAS}; fl = {e: np.zeros(nq) for e in ETAS}
    n_unrel = np.zeros(nq); n_exp_unrel = np.zeros(nq); who = {e: collections.Counter() for e in ETAS}
    # check: eta 0 changes nothing
    u0, i0, r0, f0, _, _ = stream(K0, S, rows, evg, evpos, btop, brec, bfrec, lex, orders[0], 0.0)
    assert i0.sum() == 0 and np.allclose(r0, brec) and np.allclose(f0, bfrec)
    for o, order in enumerate(orders):
        ref = None
        for e in ETAS:
            u, i, r, f, ex, w = stream(K0, S, rows, evg, evpos, btop, brec, bfrec, lex, order, e)
            if ref is None:
                ref = u; n_unrel += u; n_exp_unrel += u & ex
            assert (u == ref).all()
            intr[e] += i; dl[e] += (brec - r) * u; fl[e] += (bfrec - f) * u
            for q, rs in w.items():
                for g in rs:
                    who[e][(q, g)] += 1
    print(f"streams: {N_ORDERS_LME} orders x {len(ETAS)} etas in {time.time() - t1:.0f}s; unrelated visits "
          f"{n_unrel.sum():.0f} of {N_ORDERS_LME * nq}; unrelated visits whose haystack holds a moved row {n_exp_unrel.sum():.0f}")
    qid = np.arange(nq)
    per_unrel = n_unrel.sum()
    lme = dict(inputs=inputs, predicted={str(e): round(pred[e], 3) for e in ETAS[1:]}, predicted_ci=pred_ci,
               predicted_secondary={k: {str(e): round(v[e], 3) for e in ETAS[1:]} for k, v in sec.items()},
               exposure_pairs=diag, unrelated_visits=int(per_unrel), exposed_unrelated_visits=int(n_exp_unrel.sum()),
               intrusions_per_unrelated_visit={str(e): float(intr[e].sum() / per_unrel) for e in ETAS},
               dense_loss_per_unrelated_visit={str(e): float(dl[e].sum() / per_unrel) for e in ETAS},
               fused_loss_per_unrelated_visit={str(e): float(fl[e].sum() / per_unrel) for e in ETAS},
               intrusions_per_order={str(e): round(float(intr[e].sum() / N_ORDERS_LME), 4) for e in ETAS},
               distinct_intruding_pairs={str(e): len(who[e]) for e in ETAS},
               distinct_intruded_questions={str(e): len({q for q, _ in who[e]}) for e in ETAS},
               top_pairs_share_at_base=round(sum(c for _, c in who[BASE].most_common(3)) / max(sum(who[BASE].values()), 1), 4))
    print("measured on LongMemEval-S (question-clustered):")
    lme["intrusions"] = summarize(intr, qid, "intrusions (primary)", pred)
    lme["dense_loss"] = summarize(dl, qid, "dense recall loss", pred)
    lme["fused_loss"] = summarize(fl, qid, "fused recall loss", pred)
    print("  per unrelated visit, intrusions: " + " ".join(f"{e}: {intr[e].sum() / per_unrel:.5f}" for e in ETAS))
    print("  distinct (question, row) pairs that intrude: " + " ".join(f"{e}: {len(who[e])}" for e in ETAS))
    meas = {"zero": ratio_boot(intr[BASE + 0], intr[BASE], qid)[2]}
    for e in GRID + (EXT,):
        pt, ci, _ = ratio_boot(intr[e], intr[BASE], qid)
        meas[e] = (pt, ci)
    v, detail = verdict(meas, pred)
    lme["verdict"] = dict(verdict=v, **detail)
    out["lme"] = lme
    print(f"VERDICT P4 on LongMemEval-S: {v.upper()} -- {detail['reason']}")

    # ============ LoCoMo reference on the new setup
    t2 = time.time()
    drift_l, gap_l, sd_l, nv_l = [], [], [], []
    li = {e: [] for e in ETAS}; ll = {e: [] for e in ETAS}; lf = {e: [] for e in ETAS}; chat_of = []; lun = []
    base_d, base_f = [], []
    for i, ch in enumerate(R.chats):
        Kc, Sc = R.keys[i]; Kc = np.asarray(Kc, dtype=np.float32); Sc = np.asarray(Sc, dtype=np.float32)
        nqc = len(ch["qs"]); N = len(Kc)
        mu = Sc.mean(0); cnt = np.zeros(N)
        for r, q in enumerate(ch["qs"]):
            for e in q[1]:
                cnt[e] += 1
                drift_l.append(Sc[r] @ mu - (Kc[e] @ Sc[r]) * (Kc[e] @ mu))
        nv_l.extend(cnt[cnt > 0].tolist())
        sk = Sc @ Kc.T; th = np.sort(sk, 1)[:, -K]
        gap_l.extend((th - sk.mean(1)).tolist()); sd_l.append(float(sk.std()))
        rows_c = [np.arange(N)] * nqc; evg_c = [np.array(q[1], dtype=np.int64) for q in ch["qs"]]; ev_c = [q[1] for q in ch["qs"]]
        bt, br, bf, _, _, _, _ = base_reads(Kc, Sc, rows_c, ev_c, ch["lexorder"])
        base_d += br.tolist(); base_f += bf.tolist()
        acc = {e: [np.zeros(nqc), np.zeros(nqc), np.zeros(nqc)] for e in ETAS}; un = np.zeros(nqc)
        for o in range(ORDERS_LOCOMO):
            order = np.random.default_rng([i, o, 2027]).permutation(nqc); ref = None
            for e in ETAS:
                u, it_, r, f, _, _ = stream(Kc, Sc, rows_c, evg_c, ev_c, bt, br, bf, ch["lexorder"], order, e)
                if ref is None:
                    ref = u; un += u
                acc[e][0] += it_; acc[e][1] += (br - r) * u; acc[e][2] += (bf - f) * u
        for e in ETAS:
            li[e] += acc[e][0].tolist(); ll[e] += acc[e][1].tolist(); lf[e] += acc[e][2].tolist()
        chat_of += [i] * nqc; lun += un.tolist()
    chat_of = np.array(chat_of); li = {e: np.array(x) for e, x in li.items()}; ll = {e: np.array(x) for e, x in ll.items()}
    lf = {e: np.array(x) for e, x in lf.items()}
    hl, gl, sl, nvl = float(np.mean(drift_l)), float(np.mean(gap_l)), float(np.mean(sd_l)), np.array(nv_l)
    pred_l = ratios(lambda e: remark(nvl, hl, gl, sl, e))
    pred_l_order = ratios(lambda e: remark(nvl, hl, gl, sl, e, "order"))
    old = ratios(lambda e: remark(nvl, 0.266, 0.253, 0.127, e))
    loc = dict(inputs=dict(h_bar=round(hl, 4), g_gap=round(gl, 4), spread=round(sl, 4), mean_cites=round(float(nvl.mean()), 4),
                           frac_ge2=round(float((nvl >= 2).mean()), 4), max_cites=int(nvl.max()), cited_nodes=int(len(nvl)),
                           base_dense=round(float(np.mean(base_d)), 4), base_fused=round(float(np.mean(base_f)), 4),
                           unrelated_share=round(float(np.sum(lun) / (ORDERS_LOCOMO * len(lun))), 4)),
               predicted={str(e): round(pred_l[e], 3) for e in ETAS[1:]},
               predicted_order_averaged={str(e): round(pred_l_order[e], 3) for e in ETAS[1:]},
               predicted_old_constants_new_cites={str(e): round(old[e], 3) for e in ETAS[1:]},
               C_plus_per_unrelated_visit={str(e): round(float(ll[e].sum() / np.sum(lun)), 5) for e in ETAS})
    print(f"\nLoCoMo reference (new bridges, s12 orders), inputs: {json.dumps(loc['inputs'])}")
    print("  predicted ratios to 0.02: " + "  ".join(f"{e}: {pred_l[e]:.2f}" for e in ETAS[1:]) +
          " | order-averaged " + "  ".join(f"{e}: {pred_l_order[e]:.2f}" for e in ETAS[1:]))
    print("  C_+ per unrelated visit: " + " ".join(f"{e}: {ll[e].sum() / np.sum(lun):.4f}" for e in ETAS))
    loc["C_plus"] = summarize(ll, chat_of, "C_+ (dense recall loss)", pred_l)
    loc["intrusions"] = summarize(li, chat_of, "intrusions", pred_l)
    loc["fused_loss"] = summarize(lf, chat_of, "fused recall loss", pred_l)
    # post hoc (after run 1), reference only: the same mechanical rule applied to LoCoMo's own prediction
    for name, arr in (("intrusions", li), ("C_plus", ll)):
        m = {"zero": ratio_boot(arr[BASE], arr[BASE], chat_of)[2]}
        for e in GRID + (EXT,):
            pt, ci, _ = ratio_boot(arr[e], arr[BASE], chat_of)
            m[e] = (pt, ci)
        rv, rd = verdict(m, pred_l)
        loc[f"posthoc_rule_on_{name}"] = dict(verdict=rv, **rd)
        print(f"  post hoc, same rule on LoCoMo {name}: {rv} -- {rd['reason']}")
    out["locomo_reference"] = loc
    out["verdict"] = v
    out["seconds"] = round(time.time() - t0)
    print(f"LoCoMo reference in {time.time() - t2:.0f}s; total {out['seconds']}s")
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    json.dump(clean(out), open(os.path.join(HERE, "results", "s16_hubcost.json"), "w"), indent=1)


def clean(o):
    """Strict JSON: numpy scalars to Python, infinite values to the string "inf"."""
    if isinstance(o, dict):
        return {str(k): clean(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [clean(v) for v in o]
    if isinstance(o, np.generic):
        o = o.item()
    if isinstance(o, float) and not np.isfinite(o):
        return "inf" if o > 0 else ("-inf" if o < 0 else "nan")
    return o


if __name__ == "__main__":
    main()
