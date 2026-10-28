#!/usr/bin/env python3
"""Stage 2, test 2.3, POST HOC check (decides nothing): did CLM-8B fail on LoCoMo because of how its heads were used?

Written Oct 28, 2026, after test 2.3 failed as pre-registered and before any number of the variants below existed.
Not in the plan (docs/research/two-plane-memory/5-stage2-plan.md, section 2.3); it changes no verdict, and 2.3 stays
failed whatever this prints. What failed (results/s23_clm.json, results/s23b_clm_ranker.json, Mac, Qwen3-8B MLX 8-bit,
calibrated: 8-bit against bf16 mean cosine 0.9998): CLM-8B with its state head on the question and its action head on
the turn, plain texts, reads LoCoMo at recall@10 0.193 alone (bge-small's rank-16 bridge read 0.662) and 0.500 fused
with BM25 (bge-small 0.655); its s111 ranker reads 0.641 against bge-small's 0.749.

Variants, fixed here before running anything. Plain texts are s23's (clm_heads): question = q.strip() (state_text),
turn = the turn text verbatim (action_text). Every hidden state is s23's kind: Qwen3-8B (MLX 8-bit, native activations)
post-norm state at the last real token, no chat template (lm_states tap "final").
  V0_plain        state head on the question, action head on the turn: s23's own read, recomputed here as a check.
  V1_swapped      action head on the question, state head on the turn.
  V2_state_both   state head on both sides.
  V3_action_both  action head on both sides.
  V4_instruction  state head on question.strip() + "\\n\\n" + "Which earlier message in this conversation answers the
                  question?", action head on the plain turn. This is contrastive-lm 0.1.0's
                  clm.schema.state_text(state, instructions) with the question as the state (context) and that sentence
                  as the instructions: each part stripped of outer whitespace, context first, joined by one blank line
                  ("\\n\\n"); build_pairs gives the same string for a 'choice' question. Checked against the
                  installed package's clm/schema.py (loaded by file path, so clm/__init__ and its client imports never
                  run) when it is present; any mismatch stops the run.
Score = 100 * cos of the two unit 512-d projections (clm_heads.CLMHeads, inputs L2-normalised), rounded to float16
before ranking, exactly as s23 stores and ranks it. Projections are made per chat, as in s23, so V0 repeats s23's
arithmetic operation for operation.

Reads per variant (LoCoMo, 1,536 questions, every chat held out since nothing is fit): recall@10 of the dense list
alone and fused with the chat's BM25 list of the plain question (RRF k 60, common.fuse with c["lexorder"]); the mean,
the mean per category (common.CATS), and the paired per-question difference against the s23 plain read (alone against
alone, fused against fused), with the chat-clustered bootstrap (common.cluster_boot, 4,000 draws, seed 0) and the exact
one-sided chat sign-flip p (all 1,024 sign patterns), both through s24_tap.compare as s23 reports them. The s23 plain
read is the clm{i} matrices of s23's own score file (--s23-scores), ranked as s23 ranks them. No ranker (it is a cloud
step and this check does not need it).

Reading rule, fixed here: "the head use was the problem" only if some variant V1 to V4 reaches an alone recall@10 of at
least 0.50 (against 0.193 for the plain read and 0.662 for bge-small's bridge read); otherwise "zero-shot CLM is the
wrong tool for this memory, however its heads are used". The unrounded means decide; fused reads, CIs and categories
are reported only.

Hidden states, and no new LM pass for the plain texts. s23_clm.py keeps its LoCoMo states in
<cache>/<tag>__<backend>[-f32act]/locomo, where <cache> is --cache (default $STAGE2_CACHE/lm, else
/tmp/claude-0/stage2/lm), <tag> is the model id's last part lower-cased and "-f32act" is added only for MLX with
--mlx-act float32. On the Mac (STAGE2_CACHE=$HOME/stage2_cache, default model, native activations) that is
~/stage2_cache/lm/qwen3-8b-8bit__mlx/locomo. The store holds lm_states.locomo_text_set(chats) (7,406 texts: every turn,
every question verbatim and every question stripped, deduplicated and sorted) and its meta.json records the texts'
SHA-256 (lm_states.texts_sha), the model, the revision and the quantisation. This script only reads it: it stops if
the store is missing or unfinished, or holds other texts or another model. V4's state texts (1,525 distinct strings for
the 1,536 questions) are new: one LM pass, final tap only, same backend, model and activation setting, into
<v4-cache>/s23c_v4_questions_<sha12> (default: next to s23's store; a stopped pass resumes). Its quantisation and
revision must equal the LoCoMo store's, or the run stops. With Qwen3's tokenizer the pass is 33,873 tokens.
Check: V0's float16 matrices are compared entry by entry with s23's clm{i}, and V0's per-question recalls and its means
(overall and per category, against s23_clm.json, --s23-json) with s23's; "v0_reproduces_s23" is true only if all agree.
If not, the run continues (the baseline stays s23's stored read) and the flag says so.

Output: results/s23c_clm_variants.json (a few kB, no per-question arrays).
--dry-run: Qwen/Qwen3-0.6B through the torch backend with s23 --dry-run's cache convention (<cache>/qwen3-0.6b__torch/
locomo, 1024-d vectors zero-padded to 4096) and s23's dry-run score file, to exercise every code path; it writes only
under /tmp/claude-0/stage2/s23c/ (or --out-dir; its V4 store goes to <out-dir>/lm/), never under results/. Its numbers
mean nothing.
Usage:
  Mac (env B, from ~/pilot-stage2/scripts/ai/small_models/stage2, STAGE2_CACHE exported as for s23; about 6 to 10 min):
           python -I s23c_clm_variants.py --threads 8
  dry run: python -I s23c_clm_variants.py --dry-run --cache <s23 dry-run cache> --s23-scores <s23 dry-run scores npz>
"""
import argparse, importlib.util, json, os, sys, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "stage1"))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import get_data  # noqa: E402
import lm_states as L  # noqa: E402
from clm_heads import CLMHeads, action_text, state_text  # noqa: E402
from s24_tap import compare, rnd  # noqa: E402

INSTRUCTION = "Which earlier message in this conversation answers the question?"
BAR = 0.50
S23_PLAIN_ALONE = 0.192646  # results/s23_clm.json (Mac), locomo.recall10.clm
BGE_BRIDGE = 0.66217  # the same file's bge_check.bge_dense (stage 1's rank-16 bridge read, 0.6622)
VARIANTS = (  # name, head on the question side, head on the turn side, question text
    ("V0_plain", "state", "action", "plain"),
    ("V1_swapped", "action", "state", "plain"),
    ("V2_state_both", "state", "state", "plain"),
    ("V3_action_both", "action", "action", "plain"),
    ("V4_instruction", "state", "action", "v4"),
)
YES, NO = "the head use was the problem", "zero-shot CLM is the wrong tool for this memory, however its heads are used"


def v4_text(question):
    """clm.schema.state_text(question, INSTRUCTION): the context (the question) first, the instruction last, each
    stripped, joined by one blank line."""
    s, i = question.strip(), INSTRUCTION.strip()
    return f"{s}\n\n{i}" if s and i else (s or i)


def schema_check(path, chats):
    """V4's state text (and the plain texts) against contrastive-lm's own clm/schema.py, loaded by file path."""
    version = None
    if path is None:
        spec = importlib.util.find_spec("clm")  # finds the package without running its __init__
        locs = list(spec.submodule_search_locations or []) if spec else []
        path = os.path.join(locs[0], "schema.py") if locs else None
        if path:
            try:  # the installed distribution's version (0.1.0 in env B), recorded only
                from importlib import metadata
                version = metadata.version("contrastive-lm")
            except Exception:
                version = None
    elif not os.path.exists(path):
        raise SystemExit(f"--clm-schema {path} does not exist")
    if not path or not os.path.exists(path):
        return dict(checked=False, note="contrastive-lm's clm/schema.py is not here; V4 uses the copy in v4_text")
    sp = importlib.util.spec_from_file_location("clm_schema_for_s23c", path)
    m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    n = bad = 0
    for c in chats:
        turns = c["text"][:5]
        for q in c["qs"]:
            s4, _, t4 = m.build_pairs(q[0], {"q": {"type": "choice", "instructions": INSTRUCTION,
                                                   "criteria": {str(j): t for j, t in enumerate(turns)}}})["q"]
            s0 = m.build_pairs(q[0], {"q": {"type": "choice", "instructions": None,
                                            "criteria": {"0": turns[0]}}})["q"][0]
            n += 1
            bad += ((m.state_text(q[0], INSTRUCTION) != v4_text(q[0])) + (s4 != v4_text(q[0]))
                    + (s0 != state_text(q[0])) + sum(a != action_text(b) for a, b in zip(t4, turns)))
    out = dict(checked=True, file=os.path.basename(os.path.dirname(path)) + "/schema.py", package_version=version,
               questions=n, mismatches=int(bad), example=v4_text(chats[0]["qs"][0][0]))
    if bad:
        raise SystemExit(f"V4's text differs from clm.schema in {bad} places; not run")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=["mlx", "torch"], default="mlx")
    ap.add_argument("--model", default="mlx-community/Qwen3-8B-8bit")
    ap.add_argument("--mlx-act", choices=["native", "float32"], default="native",
                    help="must be the setting s23 ran with (its store directory depends on it)")
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--cache", default=os.path.join(os.environ.get("STAGE2_CACHE", "/tmp/claude-0/stage2"), "lm"),
                    help="s23's hidden-state cache (same default as s23_clm.py)")
    ap.add_argument("--v4-cache", default=None,
                    help="where V4's question store goes (default: s23's store directory; dry run: <out-dir>/lm/...)")
    ap.add_argument("--s23-scores", default=None,
                    help="s23's LoCoMo score file (default results/s23_clm_scores.npz; dry run: "
                         "/tmp/claude-0/stage2/dryrun/s23_clm_scores.npz)")
    ap.add_argument("--s23-json", default=None, help="s23's JSON (default: s23_clm.json next to --s23-scores)")
    ap.add_argument("--clm-schema", default=None,
                    help="path of contrastive-lm's clm/schema.py for the V4 text check (default: the installed one)")
    ap.add_argument("--token-budget", type=int, default=8192)
    ap.add_argument("--max-seconds", type=float, default=None, help="stop V4's LM pass cleanly after this long")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--out-dir", default=None, help="default results/ (dry run: /tmp/claude-0/stage2/s23c)")
    a = ap.parse_args()
    if a.dry_run:
        a.backend, a.model = "torch", "Qwen/Qwen3-0.6B"
        out_dir = a.out_dir or "/tmp/claude-0/stage2/s23c"
        s23_scores = a.s23_scores or "/tmp/claude-0/stage2/dryrun/s23_clm_scores.npz"
    else:
        out_dir = a.out_dir or os.path.join(HERE, "results")
        s23_scores = a.s23_scores or os.path.join(HERE, "results", "s23_clm_scores.npz")
    s23_json = a.s23_json or os.path.join(os.path.dirname(os.path.abspath(s23_scores)), "s23_clm.json")
    tag = a.model.split("/")[-1].lower()
    sub = f"{tag}__{a.backend}" + ("-f32act" if a.backend == "mlx" and a.mlx_act == "float32" else "")
    root = os.path.join(a.cache, sub)
    v4_root = a.v4_cache or (os.path.join(out_dir, "lm", sub) if a.dry_run else root)
    if a.dry_run:
        res_dir = os.path.realpath(os.path.join(HERE, "results"))
        if any(os.path.realpath(p).startswith(res_dir) for p in (out_dir, v4_root)):
            raise SystemExit("a dry run never writes under results/")
    if not os.path.exists(s23_scores):
        raise SystemExit(f"s23's score file {s23_scores} is missing; the plain read is defined by it")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "s23c_clm_variants.json")
    import torch
    torch.set_num_threads(a.threads)
    t0 = time.time()
    res = dict(test="2.3 post hoc (s23c): CLM-8B head-use variants on LoCoMo", decides="nothing (post hoc, written "
               "Oct 28, 2026 after 2.3 failed and before any variant number existed); 2.3 stays failed",
               dry_run=a.dry_run, model=a.model, backend=a.backend, mlx_act=a.mlx_act if a.backend == "mlx" else None,
               variants={n: dict(question_side=f"{qh} head on the " + ("question" if qt == "plain" else
                                                                      "question + instruction (V4 text)"),
                                 turn_side=f"{th} head on the turn") for n, qh, th, qt in VARIANTS},
               instruction=INSTRUCTION)
    res["label"] = ("DRY RUN (Qwen3-0.6B, zero-padded): plumbing only, the numbers and the reading mean nothing"
                    if a.dry_run else "post hoc, decides nothing")

    # ---- s23's LoCoMo store (read only)
    get_data.ensure("locomo")
    chats = C.load_locomo()
    loc_texts = L.locomo_text_set(chats); idx = {t: i for i, t in enumerate(loc_texts)}
    d = os.path.join(root, "locomo")
    if not L.is_done(d):
        raise SystemExit(f"s23's LoCoMo hidden-state store is missing or unfinished at {d}; export STAGE2_CACHE as for "
                         "s23 (or pass --cache). This script does not redo the plain texts.")
    m0 = L.meta(d)
    if m0["sha"] != L.texts_sha(loc_texts) or m0["model"] != a.model or m0["n"] != len(loc_texts):
        raise SystemExit(f"{d} holds other texts or another model; not s23's store")
    res["schema_check"] = schema_check(a.clm_schema, chats)

    # ---- V4's question texts: the one new LM pass (final tap only), resumable
    v4_texts = sorted({v4_text(q[0]) for c in chats for q in c["qs"]}); i4 = {t: i for i, t in enumerate(v4_texts)}
    d4 = os.path.join(v4_root, f"s23c_v4_questions_{L.texts_sha(v4_texts)[:12]}")
    new_pass = not L.is_done(d4)
    if new_pass:
        lm = L.make_backend(a.backend, a.model, threads=a.threads, act=a.mlx_act)
        if lm.quant != m0["quant"]:
            raise SystemExit(f"this backend runs '{lm.quant}' but s23's store was made with '{m0['quant']}'")
        print(f"hidden states: V4 questions ({len(v4_texts)} texts)", flush=True)
        if not L.encode(v4_texts, d4, lm=lm, model_id=a.model, token_budget=a.token_budget,
                        max_seconds=a.max_seconds, keep=["final"]):
            res["stopped"] = "V4's hidden-state pass stopped by --max-seconds; re-run to resume"
            json.dump(rnd(res), open(out_path, "w"), indent=1); sys.exit(3)
        del lm
    m4 = L.meta(d4)
    if (m4["model"], m4["quant"], m4.get("revision"), m4["max_len"]) != (m0["model"], m0["quant"], m0.get("revision"),
                                                                        m0["max_len"]):
        raise SystemExit(f"{d4} was made with another model, revision or precision than s23's store")
    res["hidden_states"] = dict(
        cache_layout="<cache>/<tag>__<backend>[-f32act]/<store>", locomo_store=f"<cache>/{sub}/locomo",
        locomo_sha=m0["sha"], quant=m0["quant"], revision=m0.get("revision"), locomo=L.stats(d),
        v4_store=(f"<cache>/{sub}/" if v4_root == root else "<v4-cache>/") + os.path.basename(d4),
        v4_new_lm_pass=new_pass, v4=dict(L.stats(d4), n_texts=len(v4_texts)))

    V, V4 = L.load(d, "final"), L.load(d4, "final")
    if a.dry_run:  # 1024-d -> 4096-d by zero padding, plumbing only (as s23 --dry-run)
        V, V4 = (np.concatenate([x, np.zeros((len(x), 4096 - x.shape[1]), np.float32)], 1) for x in (V, V4))

    # ---- scores, recalls and the s23 baseline
    heads = CLMHeads()
    assert heads.scale == 100.0
    z = np.load(s23_scores, allow_pickle=False)
    if str(z["model"]) != a.model:
        raise SystemExit(f"{s23_scores} was made with {z['model']}, not {a.model}")
    names = [v[0] for v in VARIANTS]
    rec = {n: dict(alone=[], fused=[]) for n in names}; base = dict(alone=[], fused=[])
    chk = dict(entries=0, entries_differ=0, max_abs_diff=0.0)
    for i, c in enumerate(chats):
        Q = dict(plain=V[[idx[state_text(q[0])] for q in c["qs"]]], v4=V4[[i4[v4_text(q[0])] for q in c["qs"]]])
        T = V[[idx[action_text(t)] for t in c["text"]]]
        P = {("state", "plain"): heads.state(Q["plain"]), ("action", "plain"): heads.action(Q["plain"]),
             ("state", "v4"): heads.state(Q["v4"])}
        PT = dict(state=heads.state(T), action=heads.action(T))
        S16 = {n: (100.0 * P[(qh, qt)] @ PT[th].T).astype(np.float16) for n, qh, th, qt in VARIANTS}
        B16 = z[f"clm{i}"]
        assert B16.dtype == np.float16 and B16.shape == S16["V0_plain"].shape, f"clm{i} has another shape or type"
        chk["entries"] += int(B16.size); chk["entries_differ"] += int((S16["V0_plain"] != B16).sum())
        chk["max_abs_diff"] = max(chk["max_abs_diff"], float(np.abs(S16["V0_plain"].astype(np.float32)
                                                                     - B16.astype(np.float32)).max()))
        S = {n: s.astype(np.float32) for n, s in S16.items()}; B = B16.astype(np.float32)  # rank what s23 ranks
        for r, q in enumerate(c["qs"]):
            lex = c["lexorder"][r]
            o = C.order_of(B[r])
            base["alone"].append(C.recall(o, q[1])); base["fused"].append(C.recall(C.fuse(lex, o), q[1]))
            for n in names:
                o = C.order_of(S[n][r])
                rec[n]["alone"].append(C.recall(o, q[1])); rec[n]["fused"].append(C.recall(C.fuse(lex, o), q[1]))
    rec = {n: {k: np.array(v) for k, v in x.items()} for n, x in rec.items()}
    base = {k: np.array(v) for k, v in base.items()}
    chat_of = np.array([i for i in range(len(chats)) for _ in chats[i]["qs"]])
    cat_of = np.array([q[2] for c in chats for q in c["qs"]])

    def cats(x):
        return {C.CATS[k]: {m: float(x[m][cat_of == k].mean()) for m in ("alone", "fused")} for k in C.CATS}

    res["locomo"] = dict(
        n_questions=int(len(chat_of)),
        s23_plain_read=dict(alone=float(base["alone"].mean()), fused=float(base["fused"].mean()),
                            by_category=cats(base), source=os.path.basename(s23_scores) + " clm{i}"),
        recall10={n: dict(alone=float(rec[n]["alone"].mean()), fused=float(rec[n]["fused"].mean())) for n in names},
        by_category={n: cats(rec[n]) for n in names},
        vs_s23_plain={n: {k: compare(rec[n][k] - base[k], chat_of) for k in ("alone", "fused")} for n in names})

    # ---- check: V0 is s23's read
    v0 = rec["V0_plain"]
    chk.update(questions_alone_differ=int((v0["alone"] != base["alone"]).sum()),
               questions_fused_differ=int((v0["fused"] != base["fused"]).sum()))
    ok = chk["entries_differ"] == 0 and chk["questions_alone_differ"] == 0 and chk["questions_fused_differ"] == 0
    if os.path.exists(s23_json):
        js = json.load(open(s23_json)); jl = js["locomo"]
        mine = dict(clm=v0["alone"].mean(), clm_fused=v0["fused"].mean())
        mine.update({f"{cat}/{m}": v0[k][cat_of == key].mean() for key, cat in C.CATS.items()
                     for m, k in (("clm", "alone"), ("clm_fused", "fused"))})
        theirs = dict(clm=jl["recall10"]["clm"], clm_fused=jl["recall10"]["clm_fused"])
        theirs.update({f"{cat}/{m}": jl["by_category"][cat][m] for cat in C.CATS.values()
                       for m in ("clm", "clm_fused")})
        diff = {k: [round(float(mine[k]), 6), theirs[k]] for k in mine if round(float(mine[k]), 6) != theirs[k]}
        chk.update(s23_json=os.path.basename(s23_json), s23_json_model=js.get("model"),
                   s23_json_means_compared=len(mine), s23_json_means_differ=diff)
        ok = ok and not diff and js.get("model") == a.model
    else:
        chk.update(s23_json=None, note=f"{os.path.basename(s23_json)} not found; means not compared")
    chk.update(s23_scores=os.path.basename(s23_scores), s23_scores_quant=str(z["quant"]),
               s23_calib_ok=z["calib_ok"].item(), v0_reproduces_s23=bool(ok))
    res["s23_check"] = chk
    if not ok:
        print("WARNING: V0 does not reproduce s23's plain read exactly (see s23_check); the baseline stays s23's "
              "stored scores", flush=True)

    # ---- reading (unrounded means)
    alone = {n: float(rec[n]["alone"].mean()) for n in names if n != "V0_plain"}
    best = max(alone, key=alone.get); met = alone[best] >= BAR
    res["reading"] = dict(rule=f"'{YES}' only if some variant V1..V4 has alone recall@10 >= {BAR} (plain "
                               f"{S23_PLAIN_ALONE}, bge-small bridge read {BGE_BRIDGE}); otherwise '{NO}'",
                          best_variant=best, best_alone=alone[best], bar=BAR, met=bool(met),
                          reading=YES if met else NO,
                          label=res["label"])
    res["seconds"] = round(time.time() - t0)
    json.dump(rnd(res), open(out_path, "w"), indent=1)
    print(json.dumps(rnd(dict(label=res["label"], recall10=res["locomo"]["recall10"],
                              s23_plain_read={k: res["locomo"]["s23_plain_read"][k] for k in ("alone", "fused")},
                              v0_reproduces_s23=chk["v0_reproduces_s23"], reading=res["reading"]["reading"],
                              best=[best, alone[best]], out=out_path)), indent=1))


if __name__ == "__main__":
    main()
