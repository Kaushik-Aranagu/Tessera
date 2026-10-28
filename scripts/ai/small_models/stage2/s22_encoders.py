#!/usr/bin/env python3
"""Stage 2.2: bigger frozen encoders through the whole stage 1 read stack (cloud; public data only).

Plan: docs/research/two-plane-memory/5-stage2-plan.md, test 2.2. Its bars were committed before any stage 2 number
existed and are quoted here verbatim:

  "For each encoder, the whole stage 1 pipeline is rebuilt in that encoder's space with no new choices: rank-16 bridges
  with the learning rate tuned on dev pairs (s11 protocol), the BM25-fused read, and the s111 ranker (same 25 features,
  same dev-chosen hyperparameter grid, same inner bridges for training chats).
  - **Pass:** for an encoder X, the ranker read with X beats the ranker read with bge-small on LoCoMo with CI > 0 and
    Holm sign-flip p below 0.05; no loss on LongMemEval-S; and X meets the 2.1 speed bar on the Mac Neural Engine (or on
    the GPU if that is faster).
  - If X wins on quality but misses the speed bar, the verdict is "fail: better but too slow", reported as such.
  - Reported, no bar: frozen read, bridge read and fused read per encoder, with CIs against bge-small (the front
    matter's bar is "beats bge-small with bridges", i.e. the bridge and fused reads)."
  Common rules: "Statistics: paired difference per question; chat-clustered bootstrap (4,000 draws, seed 0) and the
  exact chat sign-flip test (all 1,024 sign patterns). "CI > 0" means the 95% interval's lower end is above zero."
  "LongMemEval-S: 428 questions, question-clustered bootstrap. A "loss" there is a point estimate below −0.005."
  "Two new encoders are tested in 2.2, so their sign-flip p values get Holm's correction."

Encoders. bge-small (BAAI/bge-small-en-v1.5, the reference: the stage 1 caches; it must reproduce stage 1 exactly, LoCoMo
bridge 0.6622 and fused 0.6553 equal per question to the stored stage 1 bridges' reads, ranker 0.7492 and LongMemEval-S
ranker 0.9187, or the run stops; pipeline.check_reference), bge-base
(BAAI/bge-base-en-v1.5) and qwen3-emb-0.6b (Qwen/Qwen3-Embedding-0.6B, its stored query prompt on questions, none on
turns). Vectors from encode_texts.py: <enc-dir>/<tag>/locomo.npz (rows = index over all LoCoMo turns concatenated in chat
order, q = questions in chat order) and lme.npz (rows = LongMemEval-S text indices, q = the 428 questions). An encoder
whose locomo.npz is missing is reported as pending; one whose lme.npz is missing has its LongMemEval-S part pending.

Pipeline per encoder: pipeline.run_space, i.e. s11's rank-16 bridges with the lr tuned per outer fold on dev pairs (and
the all-chat bridge for LongMemEval-S by s11's rule), the frozen, bridge and BM25-fused reads, and s111's ranker (25
features, dev-chosen grid, inner bridges for training chats; LongMemEval-S fit on all 10 chats with the config of best
pooled dev recall). Nothing is chosen on test chats.

The bar, computed mechanically from unrounded values, for each new encoder X:
  LoCoMo   d = ranker read of X minus ranker read of bge-small, per question (1,536). "CI > 0": the lower end of the
           chat-clustered 95% bootstrap interval (common.cluster_boot, 4,000 draws, seed 0) is above 0. Sign-flip p:
           exact over all 1,024 chat sign vectors with s112's statistic (sum_j e_j D_j / N). s112's convention, used for
           the verdict, is ONE-SIDED (share of sign vectors whose statistic is >= the observed, observed included); the
           two-sided p (|T| >= |observed|) and the verdict it would give are stored next to it. Holm over the family of
           the two new encoders {bge-base, qwen3-emb-0.6b} (m = 2; any extra tag passed for a smoke test joins the
           family). An encoder not run yet has an unknown p, so the Holm p of the other is an interval (here [p, 2p]):
           the condition holds if its upper end is below 0.05, fails if its lower end is at least 0.05, else pending.
  LongMemEval-S  the same difference over 428 questions, question-clustered CI reported; a loss iff the point estimate is
           below -0.005 (with --locomo-only or no lme.npz this condition is pending).
  Speed    results/s21_coreml.json (written by s21_coreml.py on the Mac), field models.<tag>.speed_ok (true or false).
           A missing file, encoder or field leaves speed pending.
  quality  pass iff CI > 0 and Holm p < 0.05 and no LongMemEval-S loss; fail if any of the three fails; else pending.
  verdict  quality pass and speed_ok true: "pass"; quality pass and speed_ok false: "fail: better but too slow"; quality
           fail and speed known: "fail"; speed unknown: "quality <pass|fail|pending>; speed pending 2.1"; quality
           pending and speed known: "quality pending; speed ok" (or "speed not ok").
Reported, no bar: frozen (dense and fused), bridge and fused reads and the ranker per encoder on both benchmarks, each
with its paired difference against bge-small (LoCoMo: chat CI and sign-flip p; LongMemEval-S: question CI).

Outputs: results/s22_encoders.json and a final log line "s22 VERDICT: ...". Compute (2 single-threaded workers): about
7 min per encoder at d 384 (measured), about 12 at d 768 and 18 at d 1024 (bridge training scales with d), plus 2 min
to load the data; every finished run is cached in the pipeline cache (bge-small is filled by pipeline.py --regress).
Smoke test (writes only to the scratch directory): --write-fake <dir> writes the stage 1 bge-small vectors in
encode_texts.py's format as <dir>/fake-bge-small/; then --enc-dir <dir> --encoders bge-small,fake-bge-small --out
<scratch json> must give differences of exactly 0.
Usage: /tmp/e1/bin/python -I s22_encoders.py [--encoders bge-small,bge-base,qwen3-emb-0.6b] [--locomo-only]
       [--enc-dir /tmp/claude-0/stage2/enc] [--procs 2] [--out results/s22_encoders.json]
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ[_v] = "1"  # written, never read: single-threaded workers

import argparse, json, sys, time  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pipeline as P  # noqa: E402

REF = "bge-small"
PLAN_NEW = ("bge-base", "qwen3-emb-0.6b")
LOSS = -0.005
RESULTS = os.path.join(HERE, "results")
ENC_DIR = "/tmp/claude-0/stage2/enc"  # encode_texts.py's output; fixed default, --enc-dir overrides (no env read)


def speed_of(path, tag):
    """models.<tag>.speed_ok from s21_coreml.json: True, False or None (pending)."""
    if not os.path.exists(path):
        return None, "results/s21_coreml.json missing"
    try:
        v = json.load(open(path))["models"][tag]["speed_ok"]
    except (KeyError, TypeError, ValueError):
        return None, f"no models.{tag}.speed_ok in s21_coreml.json"
    return (v if isinstance(v, bool) else None), "read"


def quality(ci_ok, holm_iv, lme_mean):
    """Each condition True, False or None (pending); quality pass / fail / pending."""
    c = dict(locomo_ci_above_0=ci_ok,
             holm_p_below_0_05=None if holm_iv is None else (True if holm_iv[1] < 0.05 else
                                                             (False if holm_iv[0] >= 0.05 else None)),
             lme_no_loss=None if lme_mean is None else bool(lme_mean >= LOSS))
    vals = list(c.values())
    q = "fail" if any(v is False for v in vals) else ("pass" if all(v is True for v in vals) else "pending")
    return q, c


def verdict(q, speed_ok):
    if speed_ok is None:
        return f"quality {q}; speed pending 2.1"
    if q == "pass":
        return "pass" if speed_ok else "fail: better but too slow"
    if q == "fail":
        return "fail"
    return f"quality pending; speed {'ok' if speed_ok else 'not ok'}"


def write_fake(d):
    """Smoke helper: the stage 1 bge-small vectors in encode_texts.py's format as <d>/fake-bge-small/{locomo,lme}.npz."""
    d = os.path.abspath(d)
    if d.startswith(RESULTS) or d.startswith(ENC_DIR):
        raise SystemExit("write the fake encoder to a scratch directory, not results/ or the live enc/ folder")
    data = P.load_data(lme=True); out = os.path.join(d, "fake-bge-small"); os.makedirs(out, exist_ok=True)
    v = np.concatenate([c["nodes"] for c in data["chats"]]); q = np.concatenate([c["asks"] for c in data["chats"]])
    np.savez(os.path.join(out, "locomo.npz"), rows=np.arange(len(v)), v=v, q=q, model="stage1 bge-small (fake)")
    rows = np.array(sorted({int(r) for it in data["items"] for r in it["rows"]}))
    np.savez(os.path.join(out, "lme.npz"), rows=rows, v=data["vec"][rows], q=np.array([it["q"] for it in data["items"]]),
             model="stage1 bge-small (fake)")
    print(f"wrote {out}/locomo.npz ({v.shape}) and lme.npz ({len(rows)} rows)")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--encoders", default=",".join((REF,) + PLAN_NEW))
    p.add_argument("--locomo-only", action="store_true")
    p.add_argument("--enc-dir", default=ENC_DIR)
    p.add_argument("--procs", type=int, default=2, help="single-threaded worker processes")
    p.add_argument("--cache-dir", default=P.CACHE_DIR)
    p.add_argument("--s21", default=os.path.join(RESULTS, "s21_coreml.json"))
    p.add_argument("--out", default=os.path.join(RESULTS, "s22_encoders.json"))
    p.add_argument("--write-fake", default="", help="smoke helper: write the fake encoder to this scratch dir and exit")
    a = p.parse_args()
    if a.write_fake:
        return write_fake(a.write_fake)
    tags = [t for t in a.encoders.split(",") if t]
    new = [t for t in tags if t != REF]
    if any(t not in PLAN_NEW for t in new) and os.path.abspath(a.out).startswith(RESULTS):
        raise SystemExit("an encoder outside the plan (smoke test) writes only to the scratch directory: pass --out")
    t0 = time.time()
    data = P.load_data(lme=not a.locomo_only)
    chat_of = np.concatenate([[i] * len(c["qs"]) for i, c in enumerate(data["chats"])])
    qcl = None if a.locomo_only else np.arange(len(data["items"]))

    ref = P.run_space(P.space_stage1(data), data, a.procs, a.cache_dir)
    ok, check = P.check_reference(ref, data)
    print(f"bge-small reference vs stage 1: {json.dumps(check)}", flush=True)
    if not ok:
        raise SystemExit("bge-small does not reproduce stage 1; stopping")

    out = dict(test="2.2 bigger frozen encoders", protocol=__doc__.split("Usage:")[0].strip(),
               sign_flip=("s112 convention: one-sided, p = share of the 1,024 chat sign vectors with statistic >= "
                          "observed (observed included); two-sided p stored too"),
               encoders_requested=tags, locomo_only=a.locomo_only, reference_check=check,
               encoders={REF: dict(status="reference", dim=ref["dim"], means=ref["means"], bridge_lr=ref["bridges"],
                                   ranker=ref["ranker"])})
    runs = {}
    for tag in new:
        sp = P.space_npz(tag, a.enc_dir, data)
        if sp is None:
            out["encoders"][tag] = dict(status=f"pending: {a.enc_dir}/{tag}/locomo.npz missing")
            print(f"{tag}: pending (no vectors)", flush=True)
            continue
        runs[tag] = r = P.run_space(sp, data, a.procs, a.cache_dir)
        e = dict(status="run", dim=r["dim"], means=r["means"], bridge_lr=r["bridges"], ranker=r["ranker"],
                 lme_status="run" if r["use_lme"] else (
                     "off (--locomo-only)" if a.locomo_only else f"pending: {a.enc_dir}/{tag}/lme.npz missing"))
        vs = dict(locomo={}, lme={})
        for k in P.READS:
            vs["locomo"][k] = P.compare(r["reads"][f"locomo_{k}"] - ref["reads"][f"locomo_{k}"], chat_of)
            if r["use_lme"]:
                vs["lme"][k] = P.compare(r["reads"][f"lme_{k}"] - ref["reads"][f"lme_{k}"], qcl, exact=False)
        e["vs_bge_small"] = vs
        out["encoders"][tag] = e
        del sp

    family = list(PLAN_NEW) + [t for t in new if t not in PLAN_NEW]
    verd = {}
    for side in ("one", "two"):
        pv = {t: (out["encoders"][t]["vs_bge_small"]["locomo"]["ranker"][f"signflip_p_{side}_sided"] if t in runs else None)
              for t in family}
        H = P.holm(pv)
        for t in new:
            if t not in runs:
                verd.setdefault(t, {})[side] = dict(quality="pending", verdict="pending: no vectors", holm_p=None)
                continue
            vs = out["encoders"][t]["vs_bge_small"]
            lme_mean = vs["lme"]["ranker"]["mean"] if "ranker" in vs["lme"] else None
            q, cond = quality(vs["locomo"]["ranker"]["ci_above_0"], H[t], lme_mean)
            sp_ok, sp_note = speed_of(a.s21, t)
            verd.setdefault(t, {})[side] = dict(quality=q, conditions=cond, holm_p=H[t], speed_ok=sp_ok, speed_note=sp_note,
                                                verdict=verdict(q, sp_ok))
    out["verdicts"] = {t: dict(verdict=verd[t]["one"]["verdict"],
                               **{k: v for k, v in verd[t]["one"].items() if k != "verdict"},
                               verdict_if_two_sided=verd[t]["two"]["verdict"], holm_p_two_sided=verd[t]["two"]["holm_p"])
                       for t in new}
    out["holm_family"] = family
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    json.dump(P.rnd(out), open(a.out, "w"), indent=1, ensure_ascii=False)

    print(f"\n{'encoder':<16} " + " ".join(f"{k:>13}" for k in P.READS) + "   (LoCoMo recall@10; LongMemEval-S below)")
    for t in [REF] + new:
        m = out["encoders"][t].get("means")
        if m is None:
            print(f"{t:<16} {out['encoders'][t]['status']}")
            continue
        print(f"{t:<16} " + " ".join(f"{m.get('locomo_' + k, float('nan')):>13.4f}" for k in P.READS))
        print(f"{'':<16} " + " ".join(f"{m.get('lme_' + k, float('nan')):>13.4f}" for k in P.READS))
    for t in runs:
        c = out["encoders"][t]["vs_bge_small"]["locomo"]["ranker"]
        lm = out["encoders"][t]["vs_bge_small"]["lme"].get("ranker")
        print(f"{t}: ranker - bge-small LoCoMo {c['mean']:+.4f} [{c['ci'][0]:+.4f}, {c['ci'][1]:+.4f}] sign-flip p "
              f"one-sided {c['signflip_p_one_sided']:.4f} two-sided {c['signflip_p_two_sided']:.4f}; LongMemEval-S "
              + (f"{lm['mean']:+.4f} [{lm['ci'][0]:+.4f}, {lm['ci'][1]:+.4f}]" if lm else "pending"))
    print(f"wrote {a.out} ({out['seconds']}s)")
    print("s22 VERDICT: " + "; ".join(f"{t}: {out['verdicts'][t]['verdict']}" for t in new), flush=True)


if __name__ == "__main__":
    main()
