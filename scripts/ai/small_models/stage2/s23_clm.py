#!/usr/bin/env python3
"""Stage 2, test 2.3, the Mac part: CLM-v0.1-8B's heads on Qwen3-8B (MLX, 8-bit) as a zero-shot bridge on LoCoMo.

Plan (docs/research/two-plane-memory/5-stage2-plan.md, section 2.3, committed before any stage 2 number), quoted:
  "s23_clm.py on the Mac: Qwen3-8B (MLX, 8-bit) last-token final hidden state, no chat template, through CLM-v0.1-8B's
  state head (questions) and action head (turns); score = cosine of the 512-d projections. Zero-shot, so every chat is
  held out. A raw arm uses the 4096-d cosine without the heads.
  - Calibration first: on 64 fixed LoCoMo texts, the 8-bit final vectors have mean cosine at least 0.99 against a bf16
    reference (s20_calib_ref.py, computed in the cloud, or on the Mac if the cloud cannot), and so do their CLM
    projections. If this fails, the run continues but every 2.3 result is labelled "8-bit form only".
  - Pass (measured against the ranker): the s111 ranker built on the CLM list (s23b_clm_ranker.py, cloud, from the
    exported score matrices; CLM scores fill the bridge features and the raw cosine fills the frozen ones) beats the
    bge-small ranker read (0.7492) on LoCoMo with CI > 0 and sign-flip p below 0.05.
  - Front matter's bar, reported: CLM fused with BM25 against bge-small rank-16 fused with BM25 (0.6553), same test.
  - Reported, no bar: CLM alone, raw cosine, CLM added as a third list to the bge-small fused read and to the ranker's
    features. LongMemEval-S only if the Mac has time (about 83,000 turns, 3 to 5 hours)."
This script makes the score matrices and the reported numbers. The pass verdict (the ranker) is s23b_clm_ranker.py's.

Protocol details fixed here:
  Texts. As contrastive-lm 0.1.0's build_pairs lays out a 'choice' question with instructions None (clm_heads.py):
    the state head sees question.strip() (one LoCoMo question loses a trailing space) and the action head sees the
    turn text verbatim, as common.load_locomo builds it. The raw arm uses the same two vectors.
  Vectors. lm_states.py, tap "final": the post-norm state at the last real token, no chat template, no BOS/EOS, first
    512 tokens (CLM's own embedder cuts at 2,048; no LoCoMo text is longer than 112 Qwen3 tokens, some LongMemEval-S
    turns are). MLX activations: --mlx-act native (default, bf16 as mlx-lm runs the 8-bit model) or float32; the choice
    is recorded and has its own cache. Heads (clm_heads.CLMHeads, checked equal to the package): input L2-normalised,
    output L2-normalised.
  Scores. clm = 100 * cos(state(q), action(turn)) (the checkpoint's scale exp(4.6132) clamped at 100), raw = cos of the
    4096-d vectors, both rounded to float16 (the shared file's storage) before any ranking, so every recall here comes
    from the same scores s23b_clm_ranker.py reads (its / 100 in float32 keeps every order and tie). Recall@10 per
    question; fused = RRF (k 60) with the question's BM25 list (common.fuse).
  Calibration. results/s20_calib_ref.npz ("texts" 64, "ref" Qwen/Qwen3-8B bf16 weights with fp32 compute, unit,
    "ref_bf16" with bf16 compute, "kind" 'q' for the 32 questions and 't' for the 32 turns): per text, cos(this
    machine's final vector, ref), and the same after the state head and after the action head. Two readings of the
    plan's "and so do their CLM projections", chosen with --calib-rule (recorded; the lead fixes one before the Mac
    run):
    all-texts (default): calib_ok = mean >= 0.99 for the final vectors, for all 64 through the state head and for all 64
      through the action head.
    role-matched: calib_ok = mean >= 0.99 for the final vectors and for the role-matched projections (the 32 questions
      through the state head and the 32 turns through the action head, as 2.3 uses them; one mean over the 64).
    Both readings' means are always reported; minima and the ref_bf16 comparisons are reported, not used. If the file is
    missing, calib_ok = -1, the run continues and is labelled "calibration not run". If calib_ok is false, every result
    is labelled "8-bit form only".
  bge-small side. This machine's common.load_locomo vectors and the stage 1 rank-16 bridges (results/r16_bridges.npz),
    chat i read with fold i // 2's bridge, fused with BM25. Its mean must be within 0.005 of 0.6553; if not, the run is
    flagged (bge_check.ok false) and continues.
  Front matter's bar (reported, not the 2.3 verdict): a preview only, per question CLM fused - bge-small fused with
    its chat-clustered bootstrap (common.cluster_boot, 4,000 draws, seed 0) and exact one-sided chat sign-flip p (all
    1,024 sign patterns, as s112). No met flag here: the single source of this bar's verdict is s23b_clm_ranker.json
    (arm FRONT), which reads the same float16 scores against the stage 1 bge-small vectors.
  LongMemEval-S (--lme). The 428 questions as common.load_lme builds them (read from the JSON directly, no embedding
    file needed); each question's own haystack user turns. The one empty user-turn text (8 rows) has no tokens and gets
    the floor scores (clm -100, raw -1). CLM, raw and their BM25-fused recall@10 are reported.

Outputs: results/s23_clm_scores.npz ("clm{i}", "raw{i}" float16 [n_questions_i, n_nodes_i] for chat i in
common.load_locomo order; "model", "quant", "calib_ok"); with --lme also results/s23_clm_scores_lme.npz ("lme_clm{j}",
"lme_raw{j}" float16 [n_rows_j] and the same three scalars), split so each file stays under 3 MB (s23b reads both:
--scores results/s23_clm_scores.npz,results/s23_clm_scores_lme.npz). Should the LoCoMo file itself exceed 3 MB, its
raw{i} keys move to results/s23_clm_scores_raw.npz; the run prints, and s23_clm.json records (scores_files), the exact
--scores argument for s23b. And results/s23_clm.json. Hidden states are cached under --cache and shared with s24_tap.py;
a stopped run resumes.
--dry-run: Qwen/Qwen3-0.6B through the torch backend, its 1024-d vectors zero-padded to 4096, to exercise the code and
the file format only; it writes to /tmp/claude-0/stage2/dryrun/ (or --out-dir), never to results/.
Usage:
  Mac:     python s23_clm.py [--lme] [--max-seconds S] [--calib-rule role-matched]
  dry run: python s23_clm.py --dry-run [--calib <npz>] [--out-dir <scratch dir>]
"""
import argparse, json, os, sys, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "stage1"))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import get_data  # noqa: E402
import lm_states as L  # noqa: E402
from clm_heads import CLMHeads, action_text, state_text  # noqa: E402
from retrieval import load_bridge  # noqa: E402
from s24_tap import compare, rnd  # noqa: E402

BGE_FUSED = 0.6553
TOL = 0.005
CALIB_MIN_MEAN = 0.99


def unit(x):
    return x / (np.linalg.norm(x, axis=-1, keepdims=True) + 1e-12)


def lme_items(path):
    """common.load_lme's 428 items (question, rows into the sorted unique user-turn texts, evidence) without vectors."""
    data = json.load(open(path))
    texts = sorted({t["content"] for x in data for s in x["haystack_sessions"] for t in s if t["role"] == "user"})
    index = {t: i for i, t in enumerate(texts)}
    items = []
    for x in data:
        rows, ev = [], []
        for s in x["haystack_sessions"]:
            for t in s:
                if t["role"] != "user":
                    continue
                if t.get("has_answer"):
                    ev.append(len(rows))
                rows.append(index[t["content"]])
        if ev:
            items.append(dict(qid=x["question_id"], question=x["question"], rows=np.array(rows), ev=sorted(ev)))
    assert len(items) == 428
    return items, texts


def lme_scores(items, texts, used, Vt, Vq, heads):
    """Per item: CLM and raw scores over its haystack rows (floor scores for the empty text) and recall@10 of CLM, raw,
    their BM25 fusions and BM25 alone."""
    pos = {r: j for j, r in enumerate(used)}
    At, Sq = heads.action(Vt), heads.state(Vq); Ut, Uq = unit(Vt), unit(Vq)
    scores, rec = {}, {k: [] for k in ("clm", "raw", "clm_fused", "raw_fused", "bm25")}
    for j, it in enumerate(items):
        ok = np.array([texts[r] != "" for r in it["rows"]]); p = [pos[r] for r in it["rows"] if texts[r] != ""]
        clm = np.full(len(it["rows"]), -100.0); raw = np.full(len(it["rows"]), -1.0)
        clm[ok] = 100.0 * At[p] @ Sq[j]; raw[ok] = Ut[p] @ Uq[j]
        scores[f"lme_clm{j}"] = clm.astype(np.float16); scores[f"lme_raw{j}"] = raw.astype(np.float16)
        clm, raw = scores[f"lme_clm{j}"].astype(np.float32), scores[f"lme_raw{j}"].astype(np.float32)  # as stored
        lex = C.BM25([C.tokens(texts[r]) for r in it["rows"]]).rank(C.tokens(it["question"]))
        oc, orw = C.order_of(clm), C.order_of(raw)
        for k, o in (("clm", oc), ("raw", orw), ("clm_fused", C.fuse(lex, oc)), ("raw_fused", C.fuse(lex, orw)), ("bm25", lex)):
            rec[k].append(C.recall(o, it["ev"]))
    return scores, rec


LOCOMO_FILE, RAW_FILE, LME_FILE, MAX_MB = "s23_clm_scores.npz", "s23_clm_scores_raw.npz", "s23_clm_scores_lme.npz", 3.0


def write_scores(out_dir, scalars, scores, rel=True, max_mb=MAX_MB):
    """The shared format, split so each file stays under max_mb: LoCoMo keys in s23_clm_scores.npz (if that file would
    exceed max_mb, the raw{i} keys move to s23_clm_scores_raw.npz), LongMemEval-S keys (if any) in
    s23_clm_scores_lme.npz; the three scalars in each (s23b's open_scores merges them). Returns, per file written, its
    path, key count and size, and s23b's --scores argument for exactly these files."""
    sc = {k: np.array(v) for k, v in scalars.items()}

    def save(name, keys):
        path = os.path.join(out_dir, name)
        np.savez_compressed(path + ".tmp.npz", **sc, **keys); os.replace(path + ".tmp.npz", path)
        return path, os.path.getsize(path) / 1e6
    loc = {k: v for k, v in scores.items() if not k.startswith("lme_")}
    lme = {k: v for k, v in scores.items() if k.startswith("lme_")}
    written = [(LOCOMO_FILE, loc, *save(LOCOMO_FILE, loc))]
    if written[0][3] > max_mb:
        clm = {k: v for k, v in loc.items() if k.startswith("clm")}
        raw = {k: v for k, v in loc.items() if k.startswith("raw")}
        written = [(LOCOMO_FILE, clm, *save(LOCOMO_FILE, clm)), (RAW_FILE, raw, *save(RAW_FILE, raw))]
    elif os.path.exists(os.path.join(out_dir, RAW_FILE)):
        print(f"note: {RAW_FILE} in {out_dir} is from an earlier run; do not pass it to s23b", flush=True)
    if lme:
        written.append((LME_FILE, lme, *save(LME_FILE, lme)))
    info = []
    for name, keys, path, mb in written:
        info.append(dict(path=os.path.relpath(path, HERE) if rel else path, keys=len(keys), mb=round(mb, 3)))
        if mb > max_mb:
            print(f"note: {path} is {mb:.3f} MB (over the {max_mb} MB limit for files returned through git)", flush=True)
    arg = ",".join(x["path"] for x in info)
    print(f"s23b input: --scores {arg}", flush=True)
    return dict(files=info, s23b_scores_arg=arg)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=["mlx", "torch"], default="mlx")
    ap.add_argument("--model", default="mlx-community/Qwen3-8B-8bit")
    ap.add_argument("--calib", default=os.path.join(HERE, "results", "s20_calib_ref.npz"))
    ap.add_argument("--lme", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--cache", default=os.path.join(os.environ.get("STAGE2_CACHE", "/tmp/claude-0/stage2"), "lm"))
    ap.add_argument("--token-budget", type=int, default=8192)
    ap.add_argument("--mlx-act", choices=["native", "float32"], default="native",
                    help="MLX activation dtype: native (bf16, as mlx-lm runs the 8-bit model) or float32")
    ap.add_argument("--max-seconds", type=float, default=None)
    ap.add_argument("--calib-rule", choices=["all-texts", "role-matched"], default="all-texts",
                    help="which projections set calib_ok (see Calibration); both are reported")
    ap.add_argument("--out-dir", default=None, help="default results/ (dry run: /tmp/claude-0/stage2/dryrun)")
    a = ap.parse_args()
    if a.dry_run:
        a.backend, a.model = "torch", "Qwen/Qwen3-0.6B"
        out_dir = a.out_dir or "/tmp/claude-0/stage2/dryrun"
        if os.path.realpath(out_dir).startswith(os.path.realpath(os.path.join(HERE, "results"))):
            raise SystemExit("a dry run never writes under results/")
    else:
        out_dir = a.out_dir or os.path.join(HERE, "results")
    os.makedirs(out_dir, exist_ok=True)
    import torch
    torch.set_num_threads(a.threads)
    t0 = time.time()
    tag = a.model.split("/")[-1].lower()
    root = os.path.join(a.cache, f"{tag}__{a.backend}" + ("-f32act" if a.backend == "mlx" and a.mlx_act == "float32" else ""))
    os.makedirs(root, exist_ok=True)
    res = dict(test="2.3 (Mac part: CLM score matrices; the pass verdict is s23b's)", dry_run=a.dry_run, model=a.model,
               backend=a.backend, revision=L.REVISIONS.get(a.model), mlx_act=a.mlx_act if a.backend == "mlx" else None)
    lm = None

    def states(name, texts, keep=None):
        nonlocal lm
        d = os.path.join(root, name)
        if not L.is_done(d):
            lm = lm or L.make_backend(a.backend, a.model, threads=a.threads, act=a.mlx_act)
            print(f"hidden states: {name} ({len(texts)} texts)", flush=True)
            if not L.encode(texts, d, lm=lm, model_id=a.model, token_budget=a.token_budget, max_seconds=a.max_seconds,
                            keep=keep):
                res["stopped"] = "hidden-state pass stopped by --max-seconds; re-run to resume"
                json.dump(rnd(res), open(os.path.join(out_dir, "s23_clm.json"), "w"), indent=1); sys.exit(3)
        v = L.load(d, "final")
        if a.dry_run:  # 1024-d -> 4096-d by zero padding, plumbing only
            v = np.concatenate([v, np.zeros((len(v), 4096 - v.shape[1]), np.float32)], 1)
        return v, d

    heads = CLMHeads()
    assert heads.scale == 100.0
    # ---- calibration first
    calib_ok = -1
    if os.path.exists(a.calib):
        try:
            z = np.load(a.calib, allow_pickle=False)
            texts = [str(t) for t in z["texts"]]
        except ValueError as e:
            raise SystemExit(f"{a.calib} needs pickle to load ({e}); expected plain string and float arrays")
        V, d = states(f"calib_{L.texts_sha(texts)[:12]}", texts, keep=["final"])
        ref, ref16 = z["ref"].astype(np.float32), z["ref_bf16"].astype(np.float32)
        kind = np.array([str(k) for k in z["kind"]]) if "kind" in z.files else None
        if a.calib_rule == "role-matched" and (kind is None or sorted(set(kind)) != ["q", "t"]):
            raise SystemExit(f"--calib-rule role-matched needs 'kind' ('q'/'t' per text) in {a.calib}")
        cal, means = {}, {}
        for nm, R in (("ref", ref), ("ref_bf16", ref16)):
            raw = (unit(V) * unit(R)).sum(1)
            st = (heads.state(V) * heads.state(R)).sum(1); ac = (heads.action(V) * heads.action(R)).sum(1)
            parts = [("final", raw), ("state_head", st), ("action_head", ac)]
            if kind is not None:  # role-matched: questions through the state head, turns through the action head
                parts += [("role_matched", np.where(kind == "q", st, ac)), ("state_head_on_questions", st[kind == "q"]),
                          ("action_head_on_turns", ac[kind == "t"])]
            cal[nm] = {k: dict(mean=round(float(x.mean()), 6), min=round(float(x.min()), 6)) for k, x in parts}
            means[nm] = {k: float(x.mean()) for k, x in parts}
        m = means["ref"]
        ok_all = bool(all(m[k] >= CALIB_MIN_MEAN for k in ("final", "state_head", "action_head")))
        ok_role = bool(m["final"] >= CALIB_MIN_MEAN and m["role_matched"] >= CALIB_MIN_MEAN) if kind is not None else None
        calib_ok = ok_all if a.calib_rule == "all-texts" else ok_role
        rules = {"all-texts": "mean cos >= 0.99 vs ref for the final vectors and for all 64 through each head",
                 "role-matched": "mean cos >= 0.99 vs ref for the final vectors and for the role-matched projections "
                                 "(questions through the state head, turns through the action head)"}
        # token counts against the reference's (the Mac tokenizer comes from transformers 5.19, the cloud's from 5.21)
        ntok = dict(mismatches=int((np.asarray(L._mm(d, "ntok")) != z["ntok"]).sum())) if "ntok" in z.files else None
        res["calibration"] = dict(file=a.calib, revision=str(z["revision"]) if "revision" in z else None,
                                  n=len(texts), rule=a.calib_rule, rule_text=rules[a.calib_rule], **cal, ntok=ntok,
                                  ok_all_texts=ok_all, ok_role_matched=ok_role, calib_ok=calib_ok, lm_states=L.stats(d))
    res["calib_ok"] = calib_ok
    res["label"] = ("8-bit form only" if calib_ok is False else "calibration not run" if calib_ok == -1 else "calibrated")
    if a.dry_run:
        res["label"] = "DRY RUN (Qwen3-0.6B, zero-padded): plumbing only, " + res["label"]
    print("calibration:", res["label"], flush=True)

    # ---- LoCoMo
    get_data.ensure("locomo")
    chats = C.load_locomo()
    loc_texts = L.locomo_text_set(chats); idx = {t: i for i, t in enumerate(loc_texts)}
    V, d = states("locomo", loc_texts)
    res["lm_states"] = L.stats(d)
    zb = np.load(os.path.join(HERE, "results", "r16_bridges.npz"))
    chat_of = np.array([i for i in range(10) for _ in chats[i]["qs"]])
    rec = {k: [] for k in ("clm", "raw", "clm_fused", "raw_fused", "bge", "bge_fused", "bge_fused_plus_clm", "bm25")}
    scores = {}
    for i, c in enumerate(chats):
        Q = V[[idx[state_text(q[0])] for q in c["qs"]]]; T = V[[idx[action_text(t)] for t in c["text"]]]
        scores[f"clm{i}"] = (100.0 * heads.state(Q) @ heads.action(T).T).astype(np.float16)
        scores[f"raw{i}"] = (unit(Q) @ unit(T).T).astype(np.float16)
        clm, raw = scores[f"clm{i}"].astype(np.float32), scores[f"raw{i}"].astype(np.float32)  # rank what s23b reads
        b = load_bridge(zb, f"f{i // 2}_r16"); K, S = b.views(c["nodes"], c["asks"])
        for r, q in enumerate(c["qs"]):
            lex = c["lexorder"][r]
            oc, orw, ob = C.order_of(clm[r]), C.order_of(raw[r]), C.order_of(K @ S[r])
            for k, o in (("clm", oc), ("raw", orw), ("clm_fused", C.fuse(lex, oc)), ("raw_fused", C.fuse(lex, orw)),
                         ("bge", ob), ("bge_fused", C.fuse(lex, ob)), ("bge_fused_plus_clm", C.fuse(lex, ob, oc)),
                         ("bm25", lex)):
                rec[k].append(C.recall(o, q[1]))
    rec = {k: np.array(v) for k, v in rec.items()}
    res["locomo"] = dict(n_questions=int(len(chat_of)), recall10={k: round(float(v.mean()), 6) for k, v in rec.items()})
    bm = float(rec["bge_fused"].mean())
    res["bge_check"] = dict(bge_fused=round(bm, 6), stage1=BGE_FUSED, tol=TOL, ok=bool(abs(bm - BGE_FUSED) <= TOL),
                            bge_dense=round(float(rec["bge"].mean()), 6))
    fm = compare(rec["clm_fused"] - rec["bge_fused"], chat_of)
    res["front_matter_bar"] = dict(what="CLM fused with BM25 minus bge-small rank-16 fused with BM25, per question "
                                        "(preview with this machine's bge-small vectors)",
                                   verdict="s23b_clm_ranker.json, arm FRONT (the single source of this bar's verdict)",
                                   **fm, label=res["label"])
    res["reported"] = {k: compare(rec[x] - rec[y], chat_of) for k, x, y in (
        ("clm_minus_bge_dense", "clm", "bge"), ("raw_minus_bge_dense", "raw", "bge"),
        ("bge_fused_plus_clm_minus_bge_fused", "bge_fused_plus_clm", "bge_fused"), ("clm_minus_raw", "clm", "raw"))}
    cat_of = np.array([q[2] for c in chats for q in c["qs"]])
    res["locomo"]["by_category"] = {C.CATS[k]: {m: round(float(rec[m][cat_of == k].mean()), 6)
                                                for m in ("clm", "raw", "clm_fused", "bge_fused")} for k in C.CATS}

    # ---- LongMemEval-S (optional)
    if a.lme:
        items, texts = lme_items(get_data.ensure("lme"))
        used = sorted({int(r) for it in items for r in it["rows"] if texts[r] != ""})
        Vt, dt = states("lme_turns", [texts[r] for r in used], keep=["final"])  # final tap only (680 MB, not 9.5 GB)
        Vq, dq = states("lme_questions", [state_text(it["question"]) for it in items], keep=["final"])
        lsc, lrec = lme_scores(items, texts, used, Vt, Vq, heads)
        scores.update(lsc)
        res["lme"] = dict(n_questions=len(items), recall10={k: round(float(np.mean(v)), 6) for k, v in lrec.items()},
                          empty_turn_rows=int(sum(texts[r] == "" for it in items for r in it["rows"])),
                          lm_states=dict(turns=L.stats(dt), questions=L.stats(dq)))

    quant = getattr(lm, "quant", None) or L.meta(d).get("quant", "")
    if a.dry_run:
        quant = f"DRY RUN {quant}, 1024-d zero-padded to 4096"
    res["quant"] = quant
    res["scores_files"] = write_scores(out_dir, dict(model=a.model, quant=quant, calib_ok=calib_ok), scores,
                                       rel=not a.dry_run)
    if not a.lme and os.path.exists(os.path.join(out_dir, LME_FILE)):
        print(f"note: {LME_FILE} in {out_dir} is from an earlier --lme run and was not rewritten", flush=True)
    res["seconds"] = round(time.time() - t0)
    json.dump(rnd(res), open(os.path.join(out_dir, "s23_clm.json"), "w"), indent=1)
    print(json.dumps(rnd(dict(label=res["label"], recall10=res["locomo"]["recall10"], bge_check=res["bge_check"],
                              front_matter_bar=res["front_matter_bar"])), indent=1))


if __name__ == "__main__":
    main()
