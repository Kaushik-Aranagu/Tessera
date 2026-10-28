#!/usr/bin/env python3
"""Stage 2, test 2.4: first steps of stage A. Hidden states of a frozen Qwen3 LM, the state projector Pi, the tap layer.

Plan (docs/research/two-plane-memory/5-stage2-plan.md, section 2.4, committed before any stage 2 number), quoted:
  "Qwen3-8B (MLX, 8-bit), hidden state at the last token of the raw text, at the embedding output and after every third
  block (3, 6, ..., 36), plus the final normed state: 14 taps. Pi is the method's n(W_2 GELU(W_1 LN(h))), width 1024,
  output 384, trained on the symmetric InfoNCE alignment loss against bge-small's vector of the same text (logit scale
  20, AdamW lr 1e-3, weight decay 0.01, batch 256, at most 30 epochs, stopping on the dev pair's loss).
  - Training text for each outer fold: every turn and question of its 8 training chats, plus 12,000 LongMemEval-S user
    turns (fixed sample, seed 0). Test chats never reach Pi. The read uses the stage 1 rank-16 bridges, unchanged:
    s = n(S Pi(h_q)) against keys A f(turn).
  - Sanity first: the Mac's own bge-small text read must reproduce the stage 1 bridge read (0.6622) within 0.005, or the
    run stops.
  - C3 passes if the tap with the best mean held-out cosine <Pi(h_q), f(q)> sits between 55% and 80% of the depth (taps
    21, 24 or 27 of 36) and beats the last tap with CI > 0 on per-question cosine.
  - P11 passes if, at the tap chosen on dev pairs only, the hidden-state bridge read's LoCoMo recall@10 is at least the
    lower end of the text-state read's chat-clustered 95% interval. The paired difference and its CI are reported, and
    the same comparison after BM25 fusion.
  - A cloud pilot with Qwen3-0.6B (torch, fp32) runs the same script first to check the code. It is labelled a pilot and
    decides nothing."

Protocol details fixed here, before the Mac run (nothing below is tuned on test chats):
  Folds. LoCoMo outer folds common.FOLDS (test pair 2f, 2f + 1). The dev pair of fold f is the test pair of fold
    (f + 1) mod 5, as in s111/s112. The test pair never reaches Pi. The plan's training text ("every turn and question
    of its 8 training chats" with "stopping on the dev pair's loss") has two readings; --pi-fit picks one, the JSON
    records it. The lead fixed refit as the default on Oct 28, 2026 (before any Mac run), because the plan names all 8
    training chats; dev-out stays available and was the first pilot's mode:
    dev-out (the build task's text): Pi's gradient steps use the 6 training chats outside the dev pair plus the
      LongMemEval-S sample. The dev pair's turns and questions give only the stopping loss and the tap choice; they
      contribute no gradients. This Pi is the one read on the test pair.
    refit (default; stage 1's s11 pattern: tune on dev, then train on all 8): the dev-out fit above sets the stopping epoch e*
      and gives every dev statistic, including the tap choice. Pi is then retrained from the same init and shuffle
      seeds on all 8 training chats plus the LongMemEval-S sample for exactly e* epochs (last weights kept). That Pi is
      read on the test pair: C3's held-out cosines and every test read.
  Texts. LoCoMo turns as common.load_locomo builds them ("Speaker: text" plus the image caption) and questions verbatim
    (no prompt), each paired with its own bge-small vector (common.load_locomo's normalised sentence-transformers
    vectors, computed on the machine that runs this). LongMemEval-S: the sorted unique non-empty user-turn texts of
    lme_s.json (read directly, SHA-256 checked by get_data), permuted with np.random.default_rng(0).permutation, first
    N taken (N = 12,000; the pilot's 2,000 are the first 2,000 of the same permutation); their bge-small vectors are
    computed here the same way. Identical strings within a split are one pair.
  LM states. lm_states.py: no chat template, no BOS/EOS, first 512 tokens, last real token; taps emb, b3 ... bL, final.
    MLX activations: --mlx-act native (default, bf16 as mlx-lm runs the 8-bit model) or float32, recorded in the JSON.
  Pi. LayerNorm(d_h) (elementwise affine), W_1 d_h -> 1024 and W_2 1024 -> 384 without bias, exact GELU, L2 norm.
    Loss: symmetric InfoNCE over the batch, logits 20 <Pi(h_i), f(x_j)> (method L_align). AdamW lr 1e-3, weight decay
    0.01 (betas and eps at torch defaults, no schedule), batch 256 reshuffled every epoch (last partial batch kept), at
    most 30 epochs. After every epoch the dev loss is the same loss over the dev pair's texts in fixed batches of 256
    (one fixed shuffle), size-weighted. Early stopping: PATIENCE = 3 epochs without a lower dev loss; the weights of
    the best dev-loss epoch are kept, and that epoch's dev loss is the fold's held-out L_align (dev_loss). Init seed
    1000 + f and shuffle seed f, the same for every tap (common random numbers across taps) and for the refit.
  Reads. LoCoMo chat i is read with the Pi of the outer fold that held it out (fold i // 2) and that fold's rank-16
    bridge (results/r16_bridges.npz, the stage 1 bridges). Text-state read: s = n(S f(q)) against keys n(A f(turn)) (the
    stage 1 read, recomputed). Hidden-state read: s = n(S Pi(h_q)), same keys. Fused: RRF (k 60) with the question's
    BM25 list. Recall@10 per question.
  C3. Per tap, the mean over the 1,536 questions of the held-out cosine <Pi(h_q), f(q)>. The best tap passes the depth
    window if it is a block tap b_k with 0.55 <= k / L <= 0.80 (L = 36: b21, b24, b27, as the plan lists; L = 28: b18,
    b21). "The last tap" is the final normed state (the last of the taps); the comparison with the last block's raw output
    is reported too. CI: common.cluster_boot (chat-clustered, 4,000 draws, seed 0) of the per-question cosine difference
    best - last. PASS iff the best tap is in the window AND the CI's lower end is above 0.
  P11. Per outer fold the tap j* is the one with the lowest held-out L_align on the dev pair (dev_loss above: the
    symmetric InfoNCE over the dev pair's turns and questions at the kept epoch of the dev-out fit, unrounded; ties: the
    earlier tap). This is the method's rule, "Choose j* on held-out L_align" (2-method.md section 4.3; 3-algos.md
    algorithm E, step 1). PASS iff the mean hidden-state bridge read recall@10 over the 1,536 questions >= the lower end
    of the text-state read's chat-clustered 95% interval (cluster_boot of its per-question recall). Reported: the paired
    difference hidden - text with its chat CI and the exact one-sided chat sign-flip p (as s112); the same after BM25
    fusion; every tap's test recall (no choice made on it). Reported as a secondary line, deciding nothing: the picks by
    the highest mean dev cosine <Pi(h_q), f(q)> over the dev pair's questions, and their read.
  Sanity (the run stops, exit 2): the text-state read's mean recall@10 with this machine's bge-small vectors must be
    within 0.005 of 0.6622.

Outputs: results/s24_tap.json, or with --pilot results/s24_tap_pilot_<model tag>.json (labelled pilot, decides
nothing). Hidden states are cached under --cache (default $STAGE2_CACHE/lm, STAGE2_CACHE default /tmp/claude-0/stage2)
and shared with s23_clm.py (same LoCoMo text set); a stopped run resumes.
Usage:
  Mac:   python s24_tap.py --backend mlx --model mlx-community/Qwen3-8B-8bit --threads 8 --device cpu
  pilot: python s24_tap.py --pilot --backend torch --model Qwen/Qwen3-0.6B --lme-n 2000 --threads 2
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
from retrieval import load_bridge  # noqa: E402

TEXT_READ = 0.6622
SANITY_TOL = 0.005
WIDTH, OUT, ALPHA, LR, WD, BATCH, EPOCHS, PATIENCE = 1024, 384, 20.0, 1e-3, 0.01, 256, 30, 3
WINDOW = (0.55, 0.80)


def dev_pair(f):
    return C.FOLDS[(f + 1) % 5]


def lme_sample(path, n):
    """First n of the seed-0 permutation of the sorted unique non-empty LongMemEval-S user-turn texts."""
    data = json.load(open(path))
    pool = sorted({t["content"] for x in data for s in x["haystack_sessions"] for t in s
                   if t["role"] == "user" and t["content"].strip()})
    del data
    perm = np.random.default_rng(0).permutation(len(pool))
    return [pool[i] for i in perm[:n]], len(pool)


def bge(texts, path):
    """Unit bge-small vectors of texts (common.encoder, as stage 1), cached by text hash."""
    sha = L.texts_sha(texts)
    if os.path.exists(path):
        z = np.load(path)
        if str(z["sha"]) == sha:
            return z["v"].astype(np.float32)
    v = C.encoder().encode(list(texts), normalize_embeddings=True, batch_size=64).astype(np.float32)
    np.savez(path, v=v, sha=sha)
    return v


class Pi(torch.nn.Module):
    """n(W2 GELU(W1 LN(h)))."""

    def __init__(self, d_in):
        super().__init__()
        self.ln = torch.nn.LayerNorm(d_in)
        self.w1 = torch.nn.Linear(d_in, WIDTH, bias=False); self.w2 = torch.nn.Linear(WIDTH, OUT, bias=False)

    def forward(self, h):
        return torch.nn.functional.normalize(self.w2(torch.nn.functional.gelu(self.w1(self.ln(h)))), dim=-1)


def sym_infonce(p, y):
    logits = ALPHA * p @ y.T
    tgt = torch.arange(len(p), device=p.device)
    return 0.5 * (torch.nn.functional.cross_entropy(logits, tgt) + torch.nn.functional.cross_entropy(logits.T, tgt))


def train_pi(X, Y, Xd, Yd, f, device, epochs=None):
    """Pi on (X, Y). With dev data: early stopping on the dev loss over (Xd, Yd), the best dev-loss weights kept; returns
    the model and its log (dev_loss unrounded). With epochs=n (the refit; Xd, Yd None): exactly n epochs, last weights.
    The same init and shuffle seeds either way."""
    torch.manual_seed(1000 + f)
    pi = Pi(X.shape[1]).to(device)
    opt = torch.optim.AdamW(pi.parameters(), lr=LR, weight_decay=WD)
    g = torch.Generator().manual_seed(f)
    X, Y = torch.as_tensor(X).to(device), torch.as_tensor(Y).to(device)

    def epoch():
        perm = torch.randperm(len(X), generator=g)
        for i in range(0, len(perm), BATCH):
            b = perm[i:i + BATCH]
            if len(b) < 2:
                continue
            b = b.to(device)
            loss = sym_infonce(pi(X[b]), Y[b])
            opt.zero_grad(); loss.backward(); opt.step()
    if epochs is not None:
        for _ in range(epochs):
            epoch()
        pi.eval()
        return pi, dict(refit_epochs=epochs, refit_train_pairs=len(X))
    dperm = torch.as_tensor(np.random.default_rng(0).permutation(len(Xd)))
    Xd, Yd = torch.as_tensor(Xd).to(device), torch.as_tensor(Yd).to(device)

    def dev_loss():
        pi.eval(); tot = 0.0
        with torch.no_grad():
            for i in range(0, len(dperm), BATCH):
                b = dperm[i:i + BATCH].to(device)
                tot += float(sym_infonce(pi(Xd[b]), Yd[b])) * len(b)
        pi.train()
        return tot / len(dperm)
    best, best_state, best_ep, since, hist = float("inf"), None, 0, 0, []
    for ep in range(1, EPOCHS + 1):
        epoch()
        d = dev_loss(); hist.append(round(d, 5))
        if d < best:
            best, best_ep, since = d, ep, 0
            best_state = {k: v.detach().clone() for k, v in pi.state_dict().items()}
        else:
            since += 1
            if since >= PATIENCE:
                break
    pi.load_state_dict(best_state); pi.eval()
    return pi, dict(best_epoch=best_ep, epochs_run=len(hist), dev_loss=best, dev_loss_by_epoch=hist)


def project(pi, X, device, batch=4096):
    out = []
    with torch.no_grad():
        for i in range(0, len(X), batch):
            out.append(pi(torch.as_tensor(X[i:i + batch]).to(device)).cpu().numpy())
    return np.concatenate(out)


def signflip_p(diff, cl):
    """Exact one-sided sign-flip p over clusters (s112): share of the 2^G sign vectors with sum_j e_j D_j / N >= observed."""
    diff = np.asarray(diff, dtype=np.float64)
    ids, inv_ = np.unique(np.asarray(cl), return_inverse=True)
    D = np.bincount(inv_, weights=diff); G = len(ids)
    E = 1.0 - 2.0 * ((np.arange(2 ** G)[:, None] >> np.arange(G)[None, :]) & 1)
    T = E @ D / len(diff); obs = D.sum() / len(diff)
    return float((T >= obs - 1e-12).mean())


def compare(diff, cl):
    """Paired per-question difference: mean, chat-clustered 95% CI (cluster_boot) and one-sided sign-flip p (unrounded)."""
    m, ci = C.cluster_boot(diff, cl)
    return dict(mean=m, ci=ci, signflip_p_one_sided=signflip_p(diff, cl))


def rnd(x, k=6):
    """Round floats for the JSON only; every decision is taken on unrounded values."""
    if isinstance(x, dict):
        return {a: rnd(b, k) for a, b in x.items()}
    if isinstance(x, (list, tuple)):
        return [rnd(b, k) for b in x]
    if isinstance(x, (float, np.floating)):
        return round(float(x), k)
    return x


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--backend", choices=["mlx", "torch"], default="mlx")
    ap.add_argument("--model", default="mlx-community/Qwen3-8B-8bit")
    ap.add_argument("--pilot", action="store_true", help="label the run a pilot (decides nothing)")
    ap.add_argument("--lme-n", type=int, default=12000)
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--device", default="cpu", help="cpu or mps, for Pi training")
    ap.add_argument("--cache", default=os.path.join(os.environ.get("STAGE2_CACHE", "/tmp/claude-0/stage2"), "lm"))
    ap.add_argument("--token-budget", type=int, default=8192)
    ap.add_argument("--mlx-act", choices=["native", "float32"], default="native",
                    help="MLX activation dtype: native (bf16, as mlx-lm runs the 8-bit model) or float32")
    ap.add_argument("--max-seconds", type=float, default=None, help="stop the hidden-state pass cleanly after this long")
    ap.add_argument("--pi-fit", choices=["dev-out", "refit"], default="refit",
                    help="training-text reading (see Folds): dev-out (6 chats for gradients) or refit (all 8 for e* epochs)")
    ap.add_argument("--out", default=None)
    a = ap.parse_args()
    torch.set_num_threads(a.threads)
    tag = a.model.split("/")[-1].lower()
    out = a.out or os.path.join(HERE, "results", f"s24_tap_pilot_{tag}.json" if a.pilot else "s24_tap.json")
    t0 = time.time()
    res = dict(test="2.4", pilot=a.pilot, label="pilot, decides nothing" if a.pilot else "stage 2 test 2.4",
               model=a.model, backend=a.backend, revision=L.REVISIONS.get(a.model), lme_n=a.lme_n, device=a.device,
               mlx_act=a.mlx_act if a.backend == "mlx" else None, threads=a.threads, pi_fit=a.pi_fit,
               protocol=dict(width=WIDTH, out=OUT, alpha=ALPHA, lr=LR, weight_decay=WD, batch=BATCH, max_epochs=EPOCHS,
                             patience=PATIENCE, window=WINDOW, max_len=L.MAX_LEN))

    def write():
        res["seconds"] = round(time.time() - t0)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump(rnd(res), open(out + ".tmp", "w"), indent=1); os.replace(out + ".tmp", out)

    # ---- data and the sanity check (first)
    get_data.ensure("locomo"); lme_path = get_data.ensure("lme")
    chats = C.load_locomo()
    zb = np.load(os.path.join(HERE, "results", "r16_bridges.npz"))
    bridges = {f: load_bridge(zb, f"f{f}_r16") for f in range(5)}
    chat_of = np.array([i for i in range(10) for _ in chats[i]["qs"]])
    text_d, text_h = [], []
    for i, c in enumerate(chats):
        text_d += C.chat_recalls(bridges[i // 2], c); text_h += C.chat_recalls(bridges[i // 2], c, hybrid=True)
    text_d, text_h = np.array(text_d), np.array(text_h)
    res["sanity"] = dict(text_read=round(float(text_d.mean()), 6), stage1=TEXT_READ, tol=SANITY_TOL,
                         ok=bool(abs(text_d.mean() - TEXT_READ) <= SANITY_TOL), text_read_fused=round(float(text_h.mean()), 6))
    print("sanity", res["sanity"], flush=True)
    if not res["sanity"]["ok"]:
        res["stopped"] = "sanity check failed: the text read does not reproduce stage 1"; write(); sys.exit(2)

    lme_texts, pool = lme_sample(lme_path, a.lme_n)
    res["lme_pool"] = pool
    root = os.path.join(a.cache, f"{tag}__{a.backend}" + ("-f32act" if a.backend == "mlx" and a.mlx_act == "float32" else ""))
    os.makedirs(root, exist_ok=True)
    F_lme = bge(lme_texts, os.path.join(root, f"bge_lme{a.lme_n}.npz"))
    old = "/tmp/claude-0/data/lme_emb.npz"  # cloud only: the stage 1 vectors of the same texts, as a cross-check
    if os.path.exists(old):
        allt = sorted({t["content"] for x in json.load(open(lme_path)) for s in x["haystack_sessions"] for t in s
                       if t["role"] == "user"})
        ix = {t: i for i, t in enumerate(allt)}
        V = np.load(old)["v"][[ix[t] for t in lme_texts]].astype(np.float32)
        res["lme_bge_vs_stage1_min_cos"] = round(float((V * F_lme).sum(1).min()), 6)

    # ---- hidden states (resumable, shared with s23)
    loc_texts = L.locomo_text_set(chats)
    sets = {"locomo": loc_texts, f"lme{a.lme_n}": lme_texts}
    dirs, lm = {}, None
    for name, texts in sets.items():
        dirs[name] = os.path.join(root, name)
        if not L.is_done(dirs[name]):
            lm = lm or L.make_backend(a.backend, a.model, threads=a.threads, act=a.mlx_act)
            print(f"hidden states: {name} ({len(texts)} texts)", flush=True)
            if not L.encode(texts, dirs[name], lm=lm, model_id=a.model, token_budget=a.token_budget,
                            max_seconds=a.max_seconds):
                res["stopped"] = "hidden-state pass stopped by --max-seconds; re-run to resume"; write(); sys.exit(3)
    del lm
    meta = L.meta(dirs["locomo"]); taps = meta["taps"]; n_layers = meta["n_layers"]
    res.update(n_layers=n_layers, taps=taps, hidden=meta["dim"])
    res["lm_states"] = {name: L.stats(d) for name, d in dirs.items()}

    # ---- pairs
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

    # ---- per tap: 5 folds of Pi, held-out and dev statistics, reads
    per = {}
    for tap in taps:
        Xl = L.load(dirs["locomo"], tap); Xm = L.load(dirs[f"lme{a.lme_n}"], tap)
        cos_q, rd, rh, rf = (np.zeros(len(chat_of)) for _ in range(4))
        folds, tsum, tn = [], 0.0, 0
        for f in range(5):
            test = C.FOLDS[f]; dev = dev_pair(f); fit = [i for i in range(10) if i not in test and i not in dev]
            tr, dv = rows_of(fit), rows_of(dev)
            X = np.concatenate([Xl[tr], Xm]); Y = np.concatenate([F_loc[tr], F_lme])
            pi, log = train_pi(X, Y, Xl[dv], F_loc[dv], f, a.device)  # dev-out fit: every dev statistic comes from it
            dq = np.concatenate([q_rows[i] for i in dev]); dt = np.concatenate([t_rows[i] for i in dev])
            log["dev_cos_q"] = float((project(pi, Xl[dq], a.device) * F_loc[dq]).sum(1).mean())
            log["dev_cos_turn"] = float((project(pi, Xl[dt], a.device) * F_loc[dt]).sum(1).mean())
            log["train_pairs"] = len(X)
            if a.pi_fit == "refit":  # all 8 training chats, the dev-out fit's stopping epoch, same seeds
                tr8 = rows_of([i for i in range(10) if i not in test])
                pi, rlog = train_pi(np.concatenate([Xl[tr8], Xm]), np.concatenate([F_loc[tr8], F_lme]), None, None, f,
                                    a.device, epochs=log["best_epoch"])
                log.update(rlog)
            for i in test:
                sel = chat_of == i; c = chats[i]; b = bridges[f]
                P = project(pi, Xl[q_rows[i]], a.device)
                cos_q[sel] = (P * c["asks"]).sum(1)
                ct = (project(pi, Xl[t_rows[i]], a.device) * c["nodes"]).sum(1); tsum += float(ct.sum()); tn += len(ct)
                K, S = b.key_np(c["nodes"]), b.state_np(P)
                for r, q in enumerate(c["qs"]):
                    o = C.order_of(K @ S[r]); j = np.flatnonzero(sel)[r]
                    rd[j] = C.recall(o, q[1]); rh[j] = C.recall(C.fuse(c["lexorder"][r], o), q[1])
                    rf[j] = C.recall(C.order_of(c["nodes"] @ P[r]), q[1])
            folds.append(log)
            print(f"{tap} fold {f}: epochs {log['epochs_run']} (best {log['best_epoch']}), dev loss {log['dev_loss']:.4f}, "
                  f"dev cos q {log['dev_cos_q']:.4f}", flush=True)
        per[tap] = dict(cos_q=cos_q, recall=rd, recall_fused=rh, recall_frozen=rf, folds=folds)
        res.setdefault("taps_detail", {})[tap] = dict(
            heldout_cos_q=round(float(cos_q.mean()), 6), heldout_cos_turn=round(tsum / tn, 6),
            dev_cos_q=[round(x["dev_cos_q"], 6) for x in folds], dev_cos_turn=[round(x["dev_cos_turn"], 6) for x in folds],
            dev_loss=[x["dev_loss"] for x in folds], best_epoch=[x["best_epoch"] for x in folds],
            epochs_run=[x["epochs_run"] for x in folds], dev_loss_by_epoch=[x["dev_loss_by_epoch"] for x in folds],
            train_pairs=[x["train_pairs"] for x in folds], refit_train_pairs=[x.get("refit_train_pairs") for x in folds],
            test_recall=round(float(rd.mean()), 6), test_recall_fused=round(float(rh.mean()), 6),
            test_recall_frozen_no_bridge=round(float(rf.mean()), 6),
            test_recall_minus_text=compare(rd - text_d, chat_of), test_recall_fused_minus_text=compare(rh - text_h, chat_of))
        write()

    # ---- C3
    def depth(t):
        return int(t[1:]) / n_layers if t.startswith("b") else None
    window = [t for t in taps if depth(t) is not None and WINDOW[0] <= depth(t) <= WINDOW[1]]
    if n_layers == 36:
        assert window == ["b21", "b24", "b27"]
    means = {t: float(per[t]["cos_q"].mean()) for t in taps}
    best = max(taps, key=lambda t: (means[t], -taps.index(t)))
    last, last_block = taps[-1], taps[-2]
    vs_last = compare(per[best]["cos_q"] - per[last]["cos_q"], chat_of) if best != last else None
    vs_block = compare(per[best]["cos_q"] - per[last_block]["cos_q"], chat_of) if best != last_block else None
    c3 = dict(best_tap=best, best_mean=round(means[best], 6), window=window, in_window=best in window, last_tap=last,
              best_minus_last=vs_last, best_minus_last_block=vs_block,
              heldout_cos_by_tap={t: round(means[t], 6) for t in taps})
    c3["pass"] = bool(best in window and vs_last is not None and vs_last["ci"][0] > 0)
    res["C3"] = c3

    # ---- P11 (tap per fold from dev pairs only: lowest held-out L_align; dev cosine as a secondary line)
    def read_at(picks):
        hd, hh = np.zeros(len(chat_of)), np.zeros(len(chat_of))
        for i in range(10):
            sel = chat_of == i; t = picks[i // 2]
            hd[sel] = per[t]["recall"][sel]; hh[sel] = per[t]["recall_fused"][sel]
        return hd, hh
    picks = [min(taps, key=lambda t: (per[t]["folds"][f]["dev_loss"], taps.index(t))) for f in range(5)]
    picks_cos = [max(taps, key=lambda t: (per[t]["folds"][f]["dev_cos_q"], -taps.index(t))) for f in range(5)]
    hid_d, hid_h = read_at(picks); cos_d, cos_h = read_at(picks_cos)
    tm, tci = C.cluster_boot(text_d, chat_of); hm, hci = C.cluster_boot(text_h, chat_of)
    p11 = dict(pick_rule="per fold, the tap of lowest held-out L_align on the dev pair (dev_loss; ties: earlier tap)",
               picks_by_fold=picks, hidden_read=round(float(hid_d.mean()), 6), text_read=round(tm, 6),
               text_read_ci=[round(x, 6) for x in tci], diff=compare(hid_d - text_d, chat_of),
               fused=dict(hidden=round(float(hid_h.mean()), 6), text=round(hm, 6), text_ci=[round(x, 6) for x in hci],
                          at_least_text_ci_low=bool(hid_h.mean() >= hci[0]), diff=compare(hid_h - text_h, chat_of)),
               secondary_by_dev_cos_q=dict(
                   note="reported, decides nothing: per fold the tap of highest mean dev cosine <Pi(h_q), f(q)>",
                   picks_by_fold=picks_cos, hidden_read=round(float(cos_d.mean()), 6),
                   at_least_text_ci_low=bool(cos_d.mean() >= tci[0]), diff=compare(cos_d - text_d, chat_of),
                   fused=dict(hidden=round(float(cos_h.mean()), 6), diff=compare(cos_h - text_h, chat_of))))
    p11["pass"] = bool(hid_d.mean() >= tci[0])
    res["P11"] = p11
    res["verdict"] = dict(C3=("pass" if c3["pass"] else "fail"), P11=("pass" if p11["pass"] else "fail"),
                          note="pilot, decides nothing" if a.pilot else "stage 2 test 2.4")
    write()
    print(json.dumps(rnd(dict(C3={k: c3[k] for k in ("best_tap", "best_mean", "in_window", "best_minus_last", "pass")},
                              P11={k: p11[k] for k in ("picks_by_fold", "hidden_read", "text_read", "text_read_ci", "pass")},
                              by_tap=c3["heldout_cos_by_tap"], label=res["label"])), indent=1))


if __name__ == "__main__":
    main()
