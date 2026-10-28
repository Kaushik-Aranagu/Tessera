#!/usr/bin/env python3
"""Stage 2.3, ranker side: CLM-8B's heads as the bridge, scored through the s111 ranker (cloud; public data only).

Plan: docs/research/two-plane-memory/5-stage2-plan.md, test 2.3. Its bars were committed before any stage 2 number
existed and are quoted here verbatim:

  "`s23_clm.py` on the Mac: Qwen3-8B (MLX, 8-bit) last-token final hidden state, no chat template, through
  CLM-v0.1-8B's state head (questions) and action head (turns); score = cosine of the 512-d projections. Zero-shot, so
  every chat is held out. A raw arm uses the 4096-d cosine without the heads."
  "**Calibration first:** on 64 fixed LoCoMo texts, the 8-bit final vectors have mean cosine at least 0.99 against a
  bf16 reference (`s20_calib_ref.py`, computed in the cloud, or on the Mac if the cloud cannot), and so do their CLM
  projections. If this fails, the run continues but every 2.3 result is labelled "8-bit form only"."
  "**Pass (measured against the ranker):** the s111 ranker built on the CLM list (`s23b_clm_ranker.py`, cloud, from the
  exported score matrices; CLM scores fill the bridge features and the raw cosine fills the frozen ones) beats the
  bge-small ranker read (0.7492) on LoCoMo with CI > 0 and sign-flip p below 0.05."
  "**Front matter's bar, reported:** CLM fused with BM25 against bge-small rank-16 fused with BM25 (0.6553), same test."
  "Reported, no bar: CLM alone, raw cosine, CLM added as a third list to the bge-small fused read and to the ranker's
  features. LongMemEval-S only if the Mac has time (about 83,000 turns, 3 to 5 hours)."
  Common rules: "Statistics: paired difference per question; chat-clustered bootstrap (4,000 draws, seed 0) and the
  exact chat sign-flip test (all 1,024 sign patterns). "CI > 0" means the 95% interval's lower end is above zero."
  "LongMemEval-S: 428 questions, question-clustered bootstrap. A "loss" there is a point estimate below −0.005."

Input: results/s23_clm_scores.npz from s23_clm.py (Mac): for LoCoMo chat i in 0..9 (common.load_locomo order) "clm{i}"
float16 [n_questions_i, n_nodes_i] = 100 * cos(state-head projection of the question, action-head projection of the
turn) and "raw{i}" float16 (cosine of the raw 4096-d final vectors); scalars "model", "quant", "calib_ok" (bool, or -1
if not run); optional "lme_clm{j}", "lme_raw{j}" float16 [n_rows_j] for LongMemEval-S item j (common.load_lme order).
The keys may be split over several files (--scores a.npz,b.npz; each matrix key in one file, equal scalars in each),
since the LoCoMo matrices alone are about 3.7 MB in float16 (3.1 MB with np.savez_compressed).
Scale: the x100 is the storage scale only. s23b reads every score as float64 (exact for float16) and divides clm by 100,
so every arm and the ranker get the cosine the plan defines ("score = cosine of the 512-d projections"), on the scale of
the bge-small cosines s111's features were built for. It matters for one of s111's 25 features: qfeats' "session best
minus own" (feature 23) starts each session's best at a -9.0 sentinel, which no cosine reaches but 100 x a cosine below
-0.09 would (on the FAKE file below, 116 candidate rows in 101 LoCoMo questions; s23_clm.py's floor score -100 for an
empty LongMemEval-S turn could hit it too). Why float64: qfeats computes gaps and z-scores of the scores in the inputs'
precision and stores float32. From float64 inputs the gaps are exact functions of the stored values rounded once, so
their order and ties are those of the x100 values (checked on the FAKE and dry-run files: every feature has the same
cross-row order and ties as at x100 except the z-score, feature 11, whose last bits differ, and the FAKE's sentinel rows
of feature 23). Dividing in float32 instead rounds each score first and splits gap ties (on the s23_clm.py dry-run
file the distinct values of feature 8 went from 1,725 to 3,592, of feature 23 from 1,604 to 2,985), which moved the
ranker by up to 0.0045 recall@10, although LightGBM gives identical results on features rescaled with their ties kept
(checked). With float64 the primary arm on the FAKE equals the x100 features with only the 116 sentinel rows corrected
(0.751807, same picks); the z-score's last bits moved the dry-run primary arm by 0.00013 (one fold's pick) and
ranker_plus_clm's LongMemEval-S read on the FAKE by 0.0027. The s111 ranker is that sensitive to last-bit changes.
The load stops if a divided clm value or a raw value lies outside [-1.001, 1.001] (not a cosine).
The bge-small side is pipeline.run_space on the stage 1 vectors, which must reproduce stage 1 (bridge 0.6622, fused
0.6553, ranker 0.7492) or the run stops.

Arms (LoCoMo, 1,536 questions; recall@10):
  PRIMARY  clm_ranker: pipeline.ranker, i.e. s111's protocol unchanged (top 50 of BM25 fused with the CLM list, s111's
           25 features, dev-chosen grid per outer fold, fit on training chats, scored on the test pair) with the CLM
           cosine matrix as the "bridge" score source and the raw cosine as the "frozen" source. CLM is zero-shot, so
           the same scores serve training, dev and test chats (no inner bridges; no feature comes from anything fit on
           labels). Compared per question with the bge-small ranker read (0.7492).
  FRONT    clm_fused: BM25 fused with the CLM list (RRF k 60) against bge-small rank-16 fused with BM25 (0.6553).
  Reported, no bar: clm_alone (dense CLM list) against the bge-small rank-16 bridge read (0.6622); raw_alone and
           raw_fused against the bge-small frozen read (dense and fused); clm_third_list (RRF k 60 of the BM25 list, the
           bge-small rank-16 bridge list and the CLM list) against the bge-small fused read AND against a control,
           control_bridge_twice_fused (RRF k 60 of the BM25 list and the bge-small rank-16 bridge list counted twice,
           common.fuse(lex, bridge, bridge)): any third dense list doubles the dense side's weight against BM25, so only
           the difference to the control says whether the CLM list adds information (the control was added before any
           CLM number existed); ranker_plus_clm (the bge-small ranker with its own candidates, 25 features and inner
           bridges, plus 4 CLM columns: CLM cosine, log(1 + rank in the full CLM list), gap to the best of the 50,
           z-score among the 50; the columns mirror s111's bridge-score columns and were fixed before any CLM number
           existed) against the bge-small ranker.
Decision (mechanical, unrounded), for the two barred arms only (PRIMARY and FRONT): an arm "beats" its bge-small
reference iff the lower end of the chat-clustered 95% interval of the per-question difference is above 0 AND the exact
chat sign-flip p is below 0.05. Sign-flip: all 1,024 sign vectors, s112's statistic and convention, ONE-SIDED (share of
sign vectors whose statistic is >= the observed, observed included); the two-sided p and the verdict it would give are
stored too. PASS of 2.3's ranker-level bar iff the PRIMARY arm beats; the front matter's bar is reported with the same
test. The no-bar comparisons carry the same statistics (mean, CI, p) but no "beats" flag. If calib_ok is false, every
result carries the label "8-bit form only"; if it is -1, the label "calibration not run".
LongMemEval-S (only if every one of the 428 items has lme_clm and lme_raw): the same arms (ranker fit on all 10 LoCoMo
chats, config of best pooled dev recall), question-clustered CI against bge-small (ranker 0.9187); no bar.
Known limit of the shared format (recorded in the JSON, not changed here): float16 storage makes some scores in a row
tie, and common.order_of breaks ties toward the lowest turn index, a small systematic bias in the CLM and raw lists and
in their rank features. The JSON's scores.float16_ties gives, for the file read, the mean share of distinct values per
row and the turns outside the top 10 that tie with the 10th-place score. On the FAKE file (below), float16 storage moved
raw_alone by +0.000034 and raw_fused by -0.00013 against the float32 frozen reads; clm_alone and clm_fused were exact.

Outputs: results/s23b_clm_ranker.json and a final log line "s23b VERDICT: ...". Compute: about 5 min with 2 workers
once the bge-small run is cached (pipeline.py --regress fills the cache), about 20 min otherwise.
Smoke test (scratch only, decides nothing): --make-fake <path> writes a FAKE scores file from bge-small (outer rank-16
bridge cosines x 100 as "clm", frozen cosines as "raw", LongMemEval-S from the all-chat bridge); then --scores <path>
--out <scratch json>. A FAKE file (model "FAKE ...") or a dry run of s23_clm.py (quant "DRY RUN ...") never writes
under results/.
Usage: /tmp/e1/bin/python -I s23b_clm_ranker.py [--scores results/s23_clm_scores.npz] [--out results/s23b_clm_ranker.json]
       [--procs 2] [--cache-dir /tmp/claude-0/stage2/pipe/cache] [--locomo-only]
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ[_v] = "1"  # written, never read: single-threaded workers

import argparse, hashlib, json, sys, time  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pipeline as P  # noqa: E402
import common as C  # noqa: E402  (stage 1, on the path through pipeline)
import s111_baselines as S111  # noqa: E402

RESULTS = os.path.join(HERE, "results")
SCALE = 100.0  # the shared format stores clm as 100 x cosine; s23b works on the cosine, in float64 (see protocol)
COS_TOL = 1e-3
CONTROL = "control_bridge_twice_fused"


def clm_cols(s):
    """The 4 extra ranker columns of one question's CLM score vector s, for its candidates."""
    rk = S111.inv(C.order_of(s))

    def cols(cand):
        c = s[cand]
        return np.column_stack([c, np.log1p(rk[cand]), c - c.max(), (c - c.mean()) / (c.std() + 1e-9)]).astype(np.float32)
    return cols


SCALARS = ("model", "quant", "calib_ok")


def open_scores(paths):
    """The keys of one or more score files, merged (the format may be split over files to keep each under 3 MB); a
    matrix key may appear in one file only, the scalars must agree."""
    z = {}
    for path in paths:
        f = np.load(path, allow_pickle=False)
        for k in f.files:
            if k in z and (k not in SCALARS or str(z[k]) != str(f[k])):
                raise SystemExit(f"{k} appears twice (or differs) across the score files")
            z[k] = f[k]
    missing = [k for k in SCALARS if k not in z]
    if missing:
        raise SystemExit(f"score files lack {missing}")
    return z


def cosine(x, name):
    """x unchanged, stopping unless it is finite and within [-1 - tol, 1 + tol] (a cosine)."""
    if not np.isfinite(x).all() or np.abs(x).max() > 1 + COS_TOL:
        raise SystemExit(f"{name} is not a cosine (clm is stored as 100 x cosine): max |value| {np.abs(x).max()}")
    return x


def tie_stats(rows):
    """float16 ties per score row: mean share of distinct values, and the turns outside the top 10 that tie with the
    10th-place score (common.order_of ranks them after the tied turns of lower index)."""
    dist, extra = [], []
    for s in rows:
        s = np.asarray(s); ss = np.sort(s)[::-1]; k = min(10, len(s)); v = ss[k - 1]
        dist.append(len(np.unique(s)) / len(s)); extra.append(int((s == v).sum() - (ss[:k] == v).sum()))
    return dict(rows=len(dist), distinct_share_mean=float(np.mean(dist)), extra_ties_at_10th_mean=float(np.mean(extra)),
                extra_ties_at_10th_max=int(np.max(extra)))


def load_scores(paths, data):
    """The score file(s) as float64: clm as the cosine (stored value / 100), raw as stored; per LoCoMo chat a matrix, per
    LongMemEval-S item a vector."""
    z = open_scores(paths)
    chats, items = data["chats"], data["items"]
    clm, raw = [], []
    for i, ch in enumerate(chats):
        a, b = z[f"clm{i}"].astype(np.float64) / SCALE, z[f"raw{i}"].astype(np.float64)
        shape = (len(ch["qs"]), len(ch["ids"]))
        if a.shape != shape or b.shape != shape:
            raise SystemExit(f"clm{i}/raw{i} must be {shape}, got {a.shape} {b.shape}")
        clm.append(cosine(a, f"clm{i} / 100")); raw.append(cosine(b, f"raw{i}"))
    info = dict(model=str(z["model"]), quant=str(z["quant"]), calib_ok=z["calib_ok"].item(),
                sha256={os.path.basename(x): hashlib.sha256(open(x, "rb").read()).hexdigest() for x in paths},
                scale="float64; clm read as stored / 100 (the cosine), raw as stored (the cosine)")
    ties = dict(locomo_clm=tie_stats([r for m in clm for r in m]), locomo_raw=tie_stats([r for m in raw for r in m]))
    lme_clm = lme_raw = None
    have = [f"lme_clm{j}" in z and f"lme_raw{j}" in z for j in range(len(items or []))]
    if items is not None and have and all(have):
        lme_clm = [cosine(z[f"lme_clm{j}"].astype(np.float64) / SCALE, f"lme_clm{j} / 100") for j in range(len(items))]
        lme_raw = [cosine(z[f"lme_raw{j}"].astype(np.float64), f"lme_raw{j}") for j in range(len(items))]
        for j, it in enumerate(items):
            if lme_clm[j].shape != (len(it["rows"]),) or lme_raw[j].shape != (len(it["rows"]),):
                raise SystemExit(f"lme item {j} must have {len(it['rows'])} scores")
        info["lme"] = "all 428 items"
        ties.update(lme_clm=tie_stats(lme_clm), lme_raw=tie_stats(lme_raw))
    else:
        part = f"partial ({sum(have)} of {len(have)} items): skipped" if any(have) else "not in the file"
        info["lme"] = "off (--locomo-only)" if items is None else part
    info["float16_ties"] = ties
    return clm, raw, lme_clm, lme_raw, info


def make_fake(path, data, ref):
    """Smoke helper: a FAKE scores file in s23_clm.py's format (clm stored x 100), built from bge-small."""
    if os.path.abspath(path).startswith(RESULTS):
        raise SystemExit("the FAKE scores file goes to the scratch directory, not results/")
    m = P.mats_of(ref, P.space_stage1(data), data["items"])
    arrs = {f"clm{i}": (100 * m["outer"][i]).astype(np.float16) for i in range(10)}
    arrs.update({f"raw{i}": m["frozen"][i].astype(np.float16) for i in range(10)})
    if data["items"] is not None:
        arrs.update({f"lme_clm{j}": (100 * v).astype(np.float16) for j, v in enumerate(m["lme_cb"])})
        arrs.update({f"lme_raw{j}": v.astype(np.float16) for j, v in enumerate(m["lme_cf"])})
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    np.savez(path, model="FAKE bge-small (smoke test)", quant="none", calib_ok=-1, **arrs)
    print(f"wrote FAKE scores {path}")


def beats(c):
    """The decision on one comparison: CI > 0 and sign-flip p < 0.05 (one-sided, s112), and the two-sided variant."""
    return dict(beats=bool(c["ci"][0] > 0 and c["signflip_p_one_sided"] < 0.05),
                beats_if_two_sided=bool(c["ci"][0] > 0 and c["signflip_p_two_sided"] < 0.05))


# (comparison key, arm, reference: a bge-small read or the control, barred?)
COMPARISONS = [("clm_ranker", "clm_ranker", "ranker", True), ("clm_fused", "clm_fused", "bridge_fused", True),
               ("clm_alone", "clm_alone", "bridge_dense", False), ("raw_alone", "raw_alone", "frozen_dense", False),
               ("raw_fused", "raw_fused", "frozen_fused", False),
               ("clm_third_list", "clm_third_list", "bridge_fused", False),
               ("clm_third_list_vs_control", "clm_third_list", CONTROL, False),
               ("ranker_plus_clm", "ranker_plus_clm", "ranker", False)]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--scores", default=os.path.join(RESULTS, "s23_clm_scores.npz"),
                   help="the scores file, or several comma-separated files that together hold the format's keys")
    p.add_argument("--out", default=os.path.join(RESULTS, "s23b_clm_ranker.json"))
    p.add_argument("--procs", type=int, default=2, help="single-threaded worker processes")
    p.add_argument("--cache-dir", default=P.CACHE_DIR)
    p.add_argument("--locomo-only", action="store_true")
    p.add_argument("--make-fake", default="", help="smoke helper: write a FAKE scores file here and exit")
    a = p.parse_args()
    t0 = time.time()
    data = P.load_data(lme=not a.locomo_only)
    chats, items = data["chats"], data["items"]
    ref = P.run_space(P.space_stage1(data), data, a.procs, a.cache_dir)
    ok, check = P.check_reference(ref, data)
    if not ok:
        raise SystemExit(f"bge-small does not reproduce stage 1 ({check}); stopping")
    if a.make_fake:
        return make_fake(a.make_fake, data, ref)
    paths = [x for x in a.scores.split(",") if x]
    if not paths or not all(os.path.exists(x) for x in paths):
        raise SystemExit(f"{a.scores} missing: run s23_clm.py on the Mac first")
    clm, raw, lme_clm, lme_raw, info = load_scores(paths, data)
    fake = info["model"].startswith("FAKE") or info["quant"].startswith("DRY RUN")  # s23_clm.py --dry-run marks quant
    if fake and os.path.abspath(a.out).startswith(RESULTS):
        raise SystemExit("a FAKE or DRY RUN scores file writes only to the scratch directory: pass --out")
    cal = info["calib_ok"]
    label = "calibration not run" if cal == -1 else ("" if cal is True or cal == 1 else "8-bit form only")
    if fake:
        label = f"{'FAKE' if info['model'].startswith('FAKE') else 'DRY RUN'} smoke test; decides nothing" + (
            f"; {label}" if label else "")
    print(f"scores: {info['model']} ({info['quant']}), calib_ok {cal}, LongMemEval-S {info['lme']}"
          + (f"  [{label}]" if label else ""), flush=True)
    use_lme = lme_clm is not None
    sp = P.space_stage1(data)
    M = P.mats_of(ref, sp, items if use_lme else None)
    R = ref["reads"]
    chat_of = np.concatenate([[i] * len(c["qs"]) for i, c in enumerate(chats)])

    # reads without a ranker; the third-list arm and its control (bge-small's bridge list counted twice)
    A = {}
    A["clm_alone"], A["clm_fused"] = P.loc_recalls(chats, clm)
    A["raw_alone"], A["raw_fused"] = P.loc_recalls(chats, raw)
    loc_q = [(ch["lexorder"][r], C.order_of(M["outer"][i][r]), C.order_of(clm[i][r]), q[1])
             for i, ch in enumerate(chats) for r, q in enumerate(ch["qs"])]
    A["clm_third_list"] = np.array([C.recall(C.fuse(lex, ob, oc), ev) for lex, ob, oc, ev in loc_q])
    A[CONTROL] = np.array([C.recall(C.fuse(lex, ob, ob), ev) for lex, ob, _, ev in loc_q])
    L = {}
    if use_lme:
        L["clm_alone"], L["clm_fused"] = P.lme_recalls(items, lme_clm)
        L["raw_alone"], L["raw_fused"] = P.lme_recalls(items, lme_raw)
        lme_q = [(it["lexorder"], C.order_of(M["lme_cb"][t]), C.order_of(lme_clm[t]), it["ev"])
                 for t, it in enumerate(items)]
        L["clm_third_list"] = np.array([C.recall(C.fuse(lex, ob, oc), ev) for lex, ob, oc, ev in lme_q])
        L[CONTROL] = np.array([C.recall(C.fuse(lex, ob, ob), ev) for lex, ob, _, ev in lme_q])
    # PRIMARY: the s111 ranker on the CLM list (CLM cosine -> bridge features, raw -> frozen features), zero-shot (fixed)
    rk = P.ranker(chats, lambda tag, j: clm[j], lambda j: raw[j], items=items if use_lme else None,
                  lme_cb=lme_clm, lme_cf=lme_raw, fixed=True, procs=a.procs, what="CLM ranker")
    A["clm_ranker"] = rk["locomo"]
    if use_lme:
        L["clm_ranker"] = rk["lme"]
    # secondary: bge-small ranker plus 4 CLM columns, same candidates and inner bridges as the bge-small ranker
    rx = P.ranker(chats, lambda tag, j: M["outer"][j] if tag == "outer" else M["inner"][(tag[1], j)],
                  lambda j: M["frozen"][j], items=items if use_lme else None, lme_cb=M.get("lme_cb"),
                  lme_cf=M.get("lme_cf"), xf_of=lambda tag, j: (lambda r: clm_cols(clm[j][r])),
                  lme_xf=(lambda t: clm_cols(lme_clm[t])) if use_lme else None, procs=a.procs, what="bge ranker + CLM")
    assert np.array_equal(rx["base_fused"], R["locomo_bridge_fused"])
    A["ranker_plus_clm"] = rx["locomo"]
    if use_lme:
        L["ranker_plus_clm"] = rx["lme"]

    control_name = "control: BM25 + bge-small rank-16 bridge list counted twice (RRF k 60)"
    out = dict(test="2.3 CLM-8B heads as the bridge (ranker side)", protocol=__doc__.split("Usage:")[0].strip(),
               scores=dict(paths=[os.path.relpath(x, HERE) for x in paths], **info), label=label, reference_check=check,
               sign_flip=("s112 convention: one-sided, p = share of the 1,024 chat sign vectors with statistic >= "
                          "observed (observed included); two-sided p stored too"),
               known_limits=["float16 storage (the shared format) ties some scores in a row; common.order_of breaks "
                             "ties toward the lowest turn index, a small systematic bias in the CLM and raw lists and "
                             "their rank features; measured for this file under scores.float16_ties",
                             "clm_third_list has no bar; compare it with the control (clm_third_list_vs_control), since "
                             "a third dense list alone doubles the dense side's RRF weight against BM25",
                             "the s111 ranker moves when last-bit changes split or merge ties among its derived "
                             "features (on the dry-run file, dividing by 100 in float32 instead of float64 moved the "
                             "primary arm by 0.0045, float32 instead of float64 z-scores by 0.00013); scores are read "
                             "in float64 so the stored values decide the ties"],
               bge_small=dict(locomo={k: float(R[f"locomo_{k}"].mean()) for k in P.READS},
                              lme={k: float(R[f"lme_{k}"].mean()) for k in P.READS if f"lme_{k}" in R}),
               locomo=dict(means={k: float(v.mean()) for k, v in A.items()}, comparisons={}),
               lme=dict(means={k: float(v.mean()) for k, v in L.items()}, comparisons={}) if use_lme else info["lme"],
               ranker_picks=dict(clm_ranker={k: rk[k] for k in ("picks", "lme_pick", "dev", "pooled", "feature_sha256_12")},
                                 ranker_plus_clm={k: rx[k] for k in ("picks", "lme_pick", "dev", "pooled",
                                                                     "feature_sha256_12")}))
    for key, arm, base, barred in COMPARISONS:
        name, bl, bm = ((control_name, A[CONTROL], L.get(CONTROL)) if base == CONTROL else
                        (f"bge-small {base}", R[f"locomo_{base}"], R.get(f"lme_{base}")))
        c = P.compare(A[arm] - bl, chat_of)
        c.update(beats(c) if barred else dict(bar="none (reported, no bar)")); c["arm"], c["against"] = arm, name
        out["locomo"]["comparisons"][key] = c
        if use_lme:
            cl = P.compare(L[arm] - bm, np.arange(len(items)), exact=False)
            cl["loss_below_minus_0_005"] = bool(cl["mean"] < -0.005); cl["arm"], cl["against"] = arm, name
            out["lme"]["comparisons"][key] = cl
    pr, fm = out["locomo"]["comparisons"]["clm_ranker"], out["locomo"]["comparisons"]["clm_fused"]
    out["verdict"] = dict(
        result="pass" if pr["beats"] else "fail", result_if_two_sided="pass" if pr["beats_if_two_sided"] else "fail",
        label=label, primary=dict(diff=pr["mean"], ci=pr["ci"], signflip_p_one_sided=pr["signflip_p_one_sided"],
                                  signflip_p_two_sided=pr["signflip_p_two_sided"]),
        front_matter_bar=dict(beats=fm["beats"], beats_if_two_sided=fm["beats_if_two_sided"], diff=fm["mean"], ci=fm["ci"],
                              signflip_p_one_sided=fm["signflip_p_one_sided"]))
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    json.dump(P.rnd(out), open(a.out, "w"), indent=1, ensure_ascii=False)

    print("\nbge-small LoCoMo: " + "  ".join(f"{k} {v:.4f}" for k, v in out["bge_small"]["locomo"].items()))
    print(f"control (BM25 + bge-small bridge list twice): {out['locomo']['means'][CONTROL]:.4f}")
    for key, c in out["locomo"]["comparisons"].items():
        flag = f"beats {c['beats']}" if "beats" in c else "(no bar)"
        print(f"  {key:<26} {out['locomo']['means'][c['arm']]:.4f}  - {c['against'][:28]:<28} {c['mean']:+.4f} "
              f"[{c['ci'][0]:+.4f}, {c['ci'][1]:+.4f}]  p one-sided {c['signflip_p_one_sided']:.4f} "
              f"two-sided {c['signflip_p_two_sided']:.4f}  {flag}")
    if use_lme:
        print("LongMemEval-S (no bar): " + "  ".join(f"{k} {v:.4f}" for k, v in out["lme"]["means"].items()))
        for key, c in out["lme"]["comparisons"].items():
            print(f"  {key:<26} - {c['against'][:28]:<28} {c['mean']:+.4f} [{c['ci'][0]:+.4f}, {c['ci'][1]:+.4f}]")
    print("float16 ties: " + json.dumps(P.rnd(info["float16_ties"], 4)))
    print(f"wrote {a.out} ({out['seconds']}s)")
    print(f"s23b VERDICT: {out['verdict']['result'].upper()} (CLM ranker - bge-small ranker {pr['mean']:+.4f} "
          f"[{pr['ci'][0]:+.4f}, {pr['ci'][1]:+.4f}], sign-flip p one-sided {pr['signflip_p_one_sided']:.4f}); front "
          f"matter's bar (CLM fused - bge-small fused {fm['mean']:+.4f}): {'beats' if fm['beats'] else 'does not beat'}"
          + (f"  [{label}]" if label else ""), flush=True)


if __name__ == "__main__":
    main()
