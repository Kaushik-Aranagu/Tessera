#!/usr/bin/env python3
"""Stage 2, test 2.4, PILOT DIAGNOSTIC s24c: does Pi's hidden-state read grow with more LongMemEval-S training text?

Label: pilot diagnostic. It decides nothing and is not part of the plan's bars (docs/research/two-plane-memory/
5-stage2-plan.md, section 2.4, C3 and P11 stay exactly as written there). Added on Oct 28, 2026, before any Qwen3-8B 2.4
result exists; the design and the reading rule below were fixed in this docstring before the script was first run.
Purpose: to tell a later P11 failure apart, "the projector is short of training text" versus "hidden states do not carry
the read". Starting point, the committed pilot results/s24_tap_pilot_qwen3-0.6b.json (Qwen/Qwen3-0.6B, torch backend,
LongMemEval-S sample 2,000, --pi-fit refit): hidden-state bridge read 0.375 against the text read's 0.662; best tap (by
held-out cosine) the final one.

Design (fixed before running):
  Model Qwen/Qwen3-0.6B at its pinned revision (lm_states.REVISIONS), torch backend, fp32, CPU. ONE tap only: "final",
    the post-norm last-token state (the committed pilot's best tap). No other tap is trained or read.
  Everything else is s24_tap.py's protocol and code, imported, unchanged: Pi (S.Pi, n(W2 GELU(W1 LN(h))), 1024 -> 384),
    the symmetric InfoNCE loss (logit scale 20), AdamW lr 1e-3 wd 0.01, batch 256, at most 30 epochs, early stopping on
    the dev pair's loss with patience 3 (S.train_pi, init seed 1000 + f, shuffle seed f), then the refit (s24's default
    --pi-fit refit, the committed pilot's mode): Pi retrained from the same seeds on all 8 training chats plus the
    LongMemEval-S turns for exactly the dev-out fit's stopping epoch e*; that Pi is read on the test pair. Outer folds
    common.FOLDS and dev pairs S.dev_pair; the stage 1 rank-16 bridges (results/r16_bridges.npz); the reads (hidden-state
    bridge read s = n(S Pi(h_q)) against keys A f(turn), RRF fusion with BM25 (k 60), the frozen read without bridge);
    statistics S.compare (chat-clustered bootstrap, 4,000 draws, seed 0; exact one-sided chat sign-flip p). The per-fold
    loop in run_size() is s24's per-tap loop for the one tap, line for line.
  The only thing varied is N, the number of LongMemEval-S user turns added to Pi's training text (both fits):
    N = 0, 2,000, 8,000, 32,000. The turns are nested prefixes of s24's fixed seed-0 order (S.lme_sample: the sorted
    unique non-empty user-turn texts of lme_s.json, np.random.default_rng(0).permutation), so N = 2,000 is exactly the
    committed pilot's sample. The LoCoMo training text of every fold is unchanged. Test chats never reach Pi.
  Vectors and states. The first 2,000 turns use s24's own pilot caches under <cache>/qwen3-0.6b__torch (bge_lme2000.npz
    and the lme2000 hidden-state store, the LoCoMo store "locomo"), read only, checked by text SHA-256. The other 30,000
    turns: bge-small vectors are the stage 1 vectors of the same texts (/tmp/claude-0/data/lme_emb.npz, common.encoder
    with normalize_embeddings, the file s24 cross-checks its own vectors against; the agreement with s24's cache on the
    first 2,000 is recorded); hidden states come from lm_states.encode (same backend and text handling: no template,
    first 512 tokens, last real token) into two new stores, lme2000-8000 and lme8000-32000 (all taps stored, only "final"
    read; flushed every 128 rows, resumable).
  Reported per N: the mean held-out cosine <Pi(h_q), f(q)> over the 1,536 test questions (and over the test turns); the
    hidden-state bridge read's recall@10 on LoCoMo (all 1,536 questions, each chat read with the Pi of the outer fold
    that held it out) and its paired difference from the text read (mean, chat-clustered 95% CI, sign-flip p); the fused
    read (RRF with BM25) and its paired difference from the fused text read; the frozen read without bridge; per fold
    e* (the refit's epoch count), epochs run by the dev-out fit, dev loss, training pairs. Reported, deciding nothing:
    the paired differences between consecutive sizes (chat CI).

Reading rule (fixed before running). It is for this 0.6B pilot only and says nothing by itself about Qwen3-8B or about
  P11. Let r(N) be the mean hidden-state bridge read recall@10 over the 1,536 questions at size N (unrounded):
    "data-limited" if r(32,000) - r(8,000) >= 0.02 AND r(8,000) > r(2,000);
    "flat"         if r(32,000) - r(8,000) < 0.01;
    "unclear"      otherwise.

Sanity checks:
  1. As s24 (the run stops, exit 2): the text read with this machine's bge-small vectors reproduces stage 1 (0.6622)
     within 0.005.
  2. Reproduction of the committed pilot (reported; the run goes on either way): at N = 2,000 every final-tap statistic
     must equal the committed pilot's taps_detail.final at the JSON's 6-digit precision: held-out cosines, test read,
     fused read, frozen read, and per fold dev loss (and its per-epoch history), e*, epochs run, dev cosines, training
     pairs. The pilot's P11 picked "final" on folds 0, 1, 2 and 4 and b27 on fold 3 (b27 is not run here); the committed
     file stores the final tap's read only over all five folds, so that all-fold read (whose Pi per fold is fixed by the
     per-fold statistics above) is the check, and the read restricted to folds 0, 1, 2, 4 is reported as a number with
     no stored counterpart.

Run order: N = 2,000 and 0 first (they need only the pilot's caches), then the hidden-state pass for turns 2,000-8,000,
  N = 8,000, the pass for turns 8,000-32,000, N = 32,000, the reading. --max-seconds stops the hidden-state pass cleanly
  (exit 3) and a re-run resumes it; --states-only runs only the pass. The JSON is rewritten after every size, with
  "complete": false until the end. Threads: --threads for torch (default 2).

Outputs: results/s24c_pi_scaling_pilot_qwen3-0.6b.json and results/s24c_pi_scaling_pilot_qwen3-0.6b.log (appended per
  run, short). Hidden-state caches under --cache (default /tmp/claude-0/stage2/lm).
Usage: python -I s24c_pi_scaling.py --threads 2 [--max-seconds S] [--states-only]
"""
import argparse, json, os, sys, time
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "stage1"))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import get_data  # noqa: E402
import lm_states as L  # noqa: E402
import s24_tap as S  # noqa: E402
from retrieval import load_bridge  # noqa: E402

MODEL, BACKEND, TAP = "Qwen/Qwen3-0.6B", "torch", "final"
TAG = "qwen3-0.6b"
SIZES = (0, 2000, 8000, 32000)
PILOT_N = 2000
PILOT_JSON = os.path.join(HERE, "results", "s24_tap_pilot_qwen3-0.6b.json")
STAGE1_LME_EMB = "/tmp/claude-0/data/lme_emb.npz"
GAIN_DATA_LIMITED, GAIN_FLAT = 0.02, 0.01
CHUNK = 128


def reading(r):
    """The reading rule of the docstring, on unrounded means r[N]."""
    _, n2, n8, n32 = SIZES
    d = r[n32] - r[n8]
    if d >= GAIN_DATA_LIMITED and r[n8] > r[n2]:
        return "data-limited"
    if d < GAIN_FLAT:
        return "flat"
    return "unclear"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--cache", default="/tmp/claude-0/stage2/lm")
    ap.add_argument("--token-budget", type=int, default=8192)
    ap.add_argument("--max-seconds", type=float, default=None,
                    help="wall-clock budget of this run; the hidden-state pass stops cleanly (exit 3) when it is spent")
    ap.add_argument("--states-only", action="store_true", help="only (re)run the hidden-state pass of the extra turns")
    ap.add_argument("--out", default=os.path.join(HERE, "results", f"s24c_pi_scaling_pilot_{TAG}.json"))
    a = ap.parse_args()
    torch.set_num_threads(a.threads)
    t0 = time.time()
    deadline = t0 + a.max_seconds if a.max_seconds else None
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    logf = open(os.path.splitext(a.out)[0] + ".log", "a")

    def log(m):
        print(m, flush=True); logf.write(m + "\n"); logf.flush()
    log(f"--- {time.strftime('%Y-%m-%d %H:%M:%S')} s24c {'states only' if a.states_only else 'full run'}; "
        f"threads {a.threads}, torch {torch.__version__}")

    res = dict(test="2.4 pilot diagnostic s24c (Pi training-text scaling)", pilot=True,
               label="pilot diagnostic, decides nothing; not part of the plan's bars",
               added="Oct 28, 2026, before any Qwen3-8B 2.4 result; design and reading rule fixed in the docstring first",
               model=MODEL, backend=BACKEND, revision=L.REVISIONS.get(MODEL), tap=TAP, sizes=list(SIZES),
               pi_fit="refit", threads=a.threads, torch=torch.__version__, complete=False,
               protocol=dict(width=S.WIDTH, out=S.OUT, alpha=S.ALPHA, lr=S.LR, weight_decay=S.WD, batch=S.BATCH,
                             max_epochs=S.EPOCHS, patience=S.PATIENCE, max_len=L.MAX_LEN),
               reading_rule=dict(
                   statistic="r(N): mean hidden-state bridge read recall@10 over the 1,536 LoCoMo questions",
                   data_limited="r(32000) - r(8000) >= 0.02 and r(8000) > r(2000)",
                   flat="r(32000) - r(8000) < 0.01", unclear="otherwise",
                   scope="the Qwen3-0.6B pilot only"),
               sizes_detail={})

    def write():
        if a.states_only:
            return
        res["seconds_this_run"] = round(time.time() - t0)
        os.makedirs(os.path.dirname(a.out), exist_ok=True)
        json.dump(S.rnd(res), open(a.out + ".tmp", "w"), indent=1); os.replace(a.out + ".tmp", a.out)

    def stop(why, code):
        res["stopped"] = why; write(); log(f"stopped: {why}"); logf.close(); sys.exit(code)

    # ---- data and the text-read sanity check (as s24)
    get_data.ensure("locomo"); lme_path = get_data.ensure("lme")
    chats = C.load_locomo()
    zb = np.load(os.path.join(HERE, "results", "r16_bridges.npz"))
    bridges = {f: load_bridge(zb, f"f{f}_r16") for f in range(5)}
    chat_of = np.array([i for i in range(10) for _ in chats[i]["qs"]])
    text_d, text_h = [], []
    for i, c in enumerate(chats):
        text_d += C.chat_recalls(bridges[i // 2], c); text_h += C.chat_recalls(bridges[i // 2], c, hybrid=True)
    text_d, text_h = np.array(text_d), np.array(text_h)
    res["sanity_text_read"] = dict(text_read=round(float(text_d.mean()), 6), stage1=S.TEXT_READ, tol=S.SANITY_TOL,
                                   ok=bool(abs(text_d.mean() - S.TEXT_READ) <= S.SANITY_TOL),
                                   text_read_fused=round(float(text_h.mean()), 6))
    log(f"sanity (text read) {res['sanity_text_read']}")
    if not res["sanity_text_read"]["ok"]:
        stop("sanity check failed: the text read does not reproduce stage 1", 2)

    # ---- LongMemEval-S turns: nested prefixes of s24's seed-0 order; vectors
    nmax = max(SIZES)
    lme_texts, pool = S.lme_sample(lme_path, nmax)
    res["lme_pool"] = pool
    assert len(set(lme_texts)) == nmax
    root = os.path.join(a.cache, f"{TAG}__{BACKEND}")
    zp = np.load(os.path.join(root, f"bge_lme{PILOT_N}.npz"))  # s24's pilot cache, read only
    assert str(zp["sha"]) == L.texts_sha(lme_texts[:PILOT_N]), "the pilot's bge cache holds other texts"
    F_pre = zp["v"].astype(np.float32)
    allt = sorted({t["content"] for x in json.load(open(lme_path)) for s in x["haystack_sessions"] for t in s
                   if t["role"] == "user"})
    V = np.load(STAGE1_LME_EMB)["v"]
    assert V.shape[0] == len(allt)
    ix = {t: i for i, t in enumerate(allt)}
    V = V[[ix[t] for t in lme_texts]].astype(np.float32)
    del allt, ix
    F_all = np.concatenate([F_pre, V[PILOT_N:]])
    nrm = np.linalg.norm(V[PILOT_N:], axis=1)
    res["lme_vectors"] = dict(
        first_2000="s24 pilot cache bge_lme2000.npz", rest="stage 1 lme_emb.npz rows of the same texts",
        stage1_vs_s24_cache_on_first_2000=dict(min_cos=float((V[:PILOT_N] * F_pre).sum(1).min()),
                                               max_abs_diff=float(np.abs(V[:PILOT_N] - F_pre).max())),
        rest_norm_min=float(nrm.min()), rest_norm_max=float(nrm.max()))
    log(f"LME vectors: {res['lme_vectors']}")

    # ---- hidden-state stores: LoCoMo and the pilot's 2,000 (read only), the extra turns (made here, resumable)
    loc_texts = L.locomo_text_set(chats)
    d_loc, d_pre = os.path.join(root, "locomo"), os.path.join(root, f"lme{PILOT_N}")
    for d, tx in ((d_loc, loc_texts), (d_pre, lme_texts[:PILOT_N])):
        assert L.is_done(d) and L.meta(d)["sha"] == L.texts_sha(tx) and L.meta(d)["model"] == MODEL, d
    _, n2, n8, n32 = SIZES
    assert n2 == PILOT_N
    extra = [(f"lme{n2}-{n8}", lme_texts[n2:n8]), (f"lme{n8}-{n32}", lme_texts[n8:n32])]
    lm = [None]

    def states(name, texts):
        d = os.path.join(root, name)
        if L.is_done(d):
            assert L.meta(d)["sha"] == L.texts_sha(texts), d
            return d
        left = None
        if deadline is not None:
            left = deadline - time.time()
            if left <= 0:
                stop("hidden-state pass stopped by --max-seconds; re-run to resume", 3)
        if lm[0] is None:
            lm[0] = L.make_backend(BACKEND, MODEL, threads=a.threads)
        n = len(texts); dp = os.path.join(d, "done.npy")
        todo = int((~np.load(dp)).sum()) if os.path.exists(dp) else n
        log(f"hidden states: {name} ({n} texts, {todo} to do)")

        def enc_log(m):
            print(m, flush=True)
            if "time limit" in m or m.strip().startswith(f"{n}/{n} rows"):
                logf.write(m + "\n"); logf.flush()
        ok = L.encode(texts, d, lm=lm[0], model_id=MODEL, token_budget=a.token_budget, chunk=CHUNK, log=enc_log,
                      max_seconds=left)
        if not ok:
            stop("hidden-state pass stopped by --max-seconds; re-run to resume", 3)
        return d

    if a.states_only:
        for name, texts in extra:
            states(name, texts)
        log("states complete"); logf.close(); return

    # ---- pairs (as s24)
    idx = {t: i for i, t in enumerate(loc_texts)}
    F_loc = np.full((len(loc_texts), 384), np.nan, np.float32)
    for c in chats:
        for t, v in zip(c["text"], c["nodes"]):
            F_loc[idx[t]] = v
        for q, v in zip(c["qs"], c["asks"]):
            F_loc[idx[q[0]]] = v

    def rows_of(chat_ids):
        r = sorted({idx[t] for i in chat_ids for t in chats[i]["text"]} | {idx[q[0]] for i in chat_ids for q in chats[i]["qs"]})
        assert not np.isnan(F_loc[r]).any()
        return r
    q_rows = {i: [idx[q[0]] for q in chats[i]["qs"]] for i in range(10)}
    t_rows = {i: [idx[t] for t in chats[i]["text"]] for i in range(10)}
    Xl = L.load(d_loc, TAP)
    Xparts = [L.load(d_pre, TAP)]
    per = {}

    # ---- one size: s24's per-tap loop for the one tap, with the first N LongMemEval-S turns
    def run_size(N):
        ts = time.time()
        Xm = np.concatenate(Xparts)[:N]; Fm = F_all[:N]
        assert len(Xm) == N and len(Fm) == N
        cos_q, rd, rh, rf = (np.zeros(len(chat_of)) for _ in range(4))
        folds, tsum, tn = [], 0.0, 0
        for f in range(5):
            test = C.FOLDS[f]; dev = S.dev_pair(f); fit = [i for i in range(10) if i not in test and i not in dev]
            tr, dv = rows_of(fit), rows_of(dev)
            X = np.concatenate([Xl[tr], Xm]); Y = np.concatenate([F_loc[tr], Fm])
            pi, flog = S.train_pi(X, Y, Xl[dv], F_loc[dv], f, "cpu")  # dev-out fit: every dev statistic comes from it
            dq = np.concatenate([q_rows[i] for i in dev]); dt = np.concatenate([t_rows[i] for i in dev])
            flog["dev_cos_q"] = float((S.project(pi, Xl[dq], "cpu") * F_loc[dq]).sum(1).mean())
            flog["dev_cos_turn"] = float((S.project(pi, Xl[dt], "cpu") * F_loc[dt]).sum(1).mean())
            flog["train_pairs"] = len(X)
            tr8 = rows_of([i for i in range(10) if i not in test])  # refit: all 8 training chats, e* epochs, same seeds
            pi, rlog = S.train_pi(np.concatenate([Xl[tr8], Xm]), np.concatenate([F_loc[tr8], Fm]), None, None, f, "cpu",
                                  epochs=flog["best_epoch"])
            flog.update(rlog)
            for i in test:
                sel = chat_of == i; c = chats[i]; b = bridges[f]
                P = S.project(pi, Xl[q_rows[i]], "cpu")
                cos_q[sel] = (P * c["asks"]).sum(1)
                ct = (S.project(pi, Xl[t_rows[i]], "cpu") * c["nodes"]).sum(1); tsum += float(ct.sum()); tn += len(ct)
                K, Sq = b.key_np(c["nodes"]), b.state_np(P)
                for r, q in enumerate(c["qs"]):
                    o = C.order_of(K @ Sq[r]); j = np.flatnonzero(sel)[r]
                    rd[j] = C.recall(o, q[1]); rh[j] = C.recall(C.fuse(c["lexorder"][r], o), q[1])
                    rf[j] = C.recall(C.order_of(c["nodes"] @ P[r]), q[1])
            folds.append(flog)
            log(f"N={N} fold {f}: e* {flog['best_epoch']} (epochs run {flog['epochs_run']}), dev loss {flog['dev_loss']:.4f}, "
                f"dev cos q {flog['dev_cos_q']:.4f}, pairs {flog['train_pairs']} / refit {flog['refit_train_pairs']}")
        per[N] = dict(cos_q=cos_q, rd=rd, rh=rh, rf=rf)
        det = dict(
            lme_n=N, heldout_cos_q=float(cos_q.mean()), heldout_cos_turn=tsum / tn,
            hidden_read=float(rd.mean()), hidden_minus_text=S.compare(rd - text_d, chat_of),
            fused_read=float(rh.mean()), fused_minus_text_fused=S.compare(rh - text_h, chat_of),
            frozen_no_bridge_read=float(rf.mean()),
            hidden_read_by_chat=[float(rd[chat_of == i].mean()) for i in range(10)],
            best_epoch=[x["best_epoch"] for x in folds], epochs_run=[x["epochs_run"] for x in folds],
            dev_loss=[x["dev_loss"] for x in folds], dev_loss_by_epoch=[x["dev_loss_by_epoch"] for x in folds],
            dev_cos_q=[x["dev_cos_q"] for x in folds], dev_cos_turn=[x["dev_cos_turn"] for x in folds],
            train_pairs=[x["train_pairs"] for x in folds], refit_train_pairs=[x["refit_train_pairs"] for x in folds],
            seconds=round(time.time() - ts))
        res["sizes_detail"][str(N)] = det
        dm = det["hidden_minus_text"]
        log(f"N={N}: held-out cos q {det['heldout_cos_q']:.4f}; hidden read {det['hidden_read']:.4f} "
            f"(minus text {dm['mean']:+.4f}, CI [{dm['ci'][0]:+.4f}, {dm['ci'][1]:+.4f}]); fused {det['fused_read']:.4f}; "
            f"e* {det['best_epoch']}; {det['seconds']}s")
        write()

    def pilot_check():
        """Sanity 2: N = 2,000 against the committed pilot's final tap (6-digit JSON precision)."""
        pj = json.load(open(PILOT_JSON)); pf = pj["taps_detail"][TAP]; m = S.rnd(res["sizes_detail"][str(PILOT_N)])
        pairs = dict(heldout_cos_q="heldout_cos_q", heldout_cos_turn="heldout_cos_turn", test_recall="hidden_read",
                     test_recall_fused="fused_read", test_recall_frozen_no_bridge="frozen_no_bridge_read",
                     dev_loss="dev_loss", dev_loss_by_epoch="dev_loss_by_epoch", best_epoch="best_epoch",
                     epochs_run="epochs_run", dev_cos_q="dev_cos_q", dev_cos_turn="dev_cos_turn",
                     train_pairs="train_pairs", refit_train_pairs="refit_train_pairs")
        fields = {k: dict(pilot=pf[k], here=m[v], equal=pf[k] == m[v]) for k, v in pairs.items()}
        fields["test_recall_minus_text_mean"] = dict(pilot=pf["test_recall_minus_text"]["mean"],
                                                     here=m["hidden_minus_text"]["mean"],
                                                     equal=pf["test_recall_minus_text"]["mean"] == m["hidden_minus_text"]["mean"])
        picks = pj["P11"]["picks_by_fold"]; fin = [f for f, t in enumerate(picks) if t == TAP]
        sel = np.isin(chat_of, [i for f in fin for i in C.FOLDS[f]])
        rd = per[PILOT_N]["rd"]
        other = ~sel  # folds the pilot read at another tap: the committed P11 read implies their mean there
        implied = (pj["P11"]["hidden_read"] * len(rd) - rd[sel].sum()) / other.sum() if other.any() else None
        res["sanity_vs_pilot"] = dict(
            ok=all(x["equal"] for x in fields.values()), fields=fields,
            pilot_p11_picks=picks, folds_picked_final=fin,
            hidden_read_on_folds_picked_final=float(rd[sel].mean()), questions_on_those_folds=int(sel.sum()),
            fused_read_on_folds_picked_final=float(per[PILOT_N]["rh"][sel].mean()),
            note=("the committed JSON stores the final tap's reads over all 5 folds only; the per-fold dev statistics and "
                  "the all-fold read pin each fold's Pi, so the restricted read has no stored counterpart"),
            implied_pilot_b27_read_on_other_folds=implied,
            final_tap_read_on_other_folds_here=float(rd[other].mean()) if other.any() else None)
        log(f"sanity vs pilot: ok {res['sanity_vs_pilot']['ok']}; "
            + ", ".join(f"{k} {'=' if x['equal'] else '!='}" for k, x in fields.items())
            + f"; read on folds {fin} {res['sanity_vs_pilot']['hidden_read_on_folds_picked_final']:.6f}")
        if not res["sanity_vs_pilot"]["ok"]:
            for k, x in fields.items():
                if not x["equal"]:
                    log(f"  differs: {k}: pilot {x['pilot']} here {x['here']}")
        write()

    run_size(n2); pilot_check()
    run_size(SIZES[0])
    Xparts.append(L.load(states(*extra[0]), TAP))
    run_size(n8)
    Xparts.append(L.load(states(*extra[1]), TAP))
    lm[0] = None
    run_size(n32)
    res["lm_states"] = {n: L.stats(os.path.join(root, n)) for n in ("locomo", f"lme{PILOT_N}", extra[0][0], extra[1][0])}

    # ---- table, between-size differences, the reading
    r = {N: float(per[N]["rd"].mean()) for N in SIZES}
    res["table"] = [dict(lme_n=N, heldout_cos_q=res["sizes_detail"][str(N)]["heldout_cos_q"], hidden_read=r[N],
                         hidden_minus_text=res["sizes_detail"][str(N)]["hidden_minus_text"],
                         fused_read=res["sizes_detail"][str(N)]["fused_read"],
                         fused_minus_text_fused=res["sizes_detail"][str(N)]["fused_minus_text_fused"],
                         best_epoch=res["sizes_detail"][str(N)]["best_epoch"],
                         epochs_run=res["sizes_detail"][str(N)]["epochs_run"]) for N in SIZES]
    res["between_sizes"] = {f"{b}_minus_{a_}": dict(hidden=S.compare(per[b]["rd"] - per[a_]["rd"], chat_of),
                                                    fused=S.compare(per[b]["rh"] - per[a_]["rh"], chat_of),
                                                    heldout_cos_q=S.compare(per[b]["cos_q"] - per[a_]["cos_q"], chat_of))
                            for a_, b in zip(SIZES[:-1], SIZES[1:])}
    res["between_sizes"]["note"] = "reported, decides nothing"
    res["reading"] = dict(result=reading(r), r=r, gain_32000_minus_8000=r[n32] - r[n8],
                          gain_8000_minus_2000=r[n8] - r[n2], gain_2000_minus_0=r[n2] - r[SIZES[0]],
                          text_read=float(text_d.mean()), scope="Qwen3-0.6B pilot only; decides nothing")
    res["complete"] = True
    res.pop("stopped", None)
    write()
    log("N      cos_q   hidden  minus_text [CI]            fused   e* per fold")
    for row in res["table"]:
        dm = row["hidden_minus_text"]
        log(f"{row['lme_n']:<6d} {row['heldout_cos_q']:.4f}  {row['hidden_read']:.4f}  {dm['mean']:+.4f} "
            f"[{dm['ci'][0]:+.4f}, {dm['ci'][1]:+.4f}]  {row['fused_read']:.4f}  {row['best_epoch']}")
    log(f"reading: {res['reading']['result']} (32000-8000 {res['reading']['gain_32000_minus_8000']:+.4f}, "
        f"8000-2000 {res['reading']['gain_8000_minus_2000']:+.4f}); pilot diagnostic, 0.6B only, decides nothing")
    logf.close()


if __name__ == "__main__":
    main()
