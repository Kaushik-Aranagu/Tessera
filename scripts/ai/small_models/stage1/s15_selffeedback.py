#!/usr/bin/env python3
"""Stage 1.5 (prediction P5, method Proposition 6.16): the self-feedback loop on a long stream of self-cited questions.

PRE-REGISTERED (written before any run of this script; not changed after seeing results).

Data and memory. Public LoCoMo only (1,536 questions, fixed parser). LongMemEval-S is not used: each of its haystacks
has one question, so no stream of re-asks can be built from it. Memory of held-out chat i = that chat's tuned rank-16
keys under the bridge of the fold that held it out (retrieval.Reader: R.keys[i] = (K0, S)).

Stream. For each chat i and order o in {0, 1, 2}: rng = np.random.default_rng([i, o, 2027]); the stream concatenates
fresh shuffled passes rng.permutation(n_q) of the chat's own questions and is cut at T = 1,500 visits (8 to 19 passes;
about 10 for most chats). The first pass is exactly s12_cites' order o for that chat, so pass 1 is comparable with
s12's "self" condition (checked in the run by replaying s12_cites.run_order). All arms use the same streams (common
random numbers). At each visit: dense read order_of(keys @ s), recall@10 against the marked evidence (dense, and fused
with BM25 by RRF k 60 as a secondary), then cite = the current dense top 1 and the cited key takes one step:
  plain    k <- n(k + eta (s - k))                                         (move rule, method 3.7)
  centred  k <- n(k + eta (n(s - mu) - k)), mu = mean ask state of that fold's 8 training chats under that fold's
           bridge, frozen (method fix #10; same mu as s12_cites)
  capped   plain step, then if ||k - k0|| > zeta: k <- n(k0 + zeta (k - k0)/||k - k0||), zeta = 0.3 (the anchored rule).
           Invariant (Prop. 6.13, fix #7): <k, k0> >= sqrt(1 - zeta^2) = 0.9539; ||k - k0|| <= zeta is NOT claimed.
           The run reports the minimum <k, k0> over all keys to check the invariant.
  eta in {0.05, 0.1, 0.2} for every rule: 9 arms.
Loss against no learning at visit t = recall@10(current keys) - recall@10(K0) for the same question (no learning keeps
K0, so its recall does not depend on the order). Reported as a function of t in windows of 150 visits (and windows of
25 for t < 300), averaged over the 3 orders, per chat; every chat has exactly 1,500 visits per order, so chats weigh
equally.

Take-off, operational definition (fixed now). Prop. 6.16: while a node's win share varpi << 1, varpi(n) = varpi0
e^{kappa n} with kappa = eta h / beta, and the win count obeys dn/dt = varpi0 e^{lambda n}, so
varpi(t) = varpi0 / (1 - t/t*) and the win count diverges at t* = beta / (eta h varpi0). The prediction's varpi0 = 0.034
is the mean initial share of each chat's top 5 winners, so the population is those nodes.
  W_v(t) = share of the chat's n_q questions whose dense top 1 is v under the keys after t self-cite steps (the win
           probability of a uniformly drawn next question; computed exactly at every t from the full score matrix).
  Top 5 winners = the 5 nodes with the largest W_v(0) under K0 (ties by node index).
  e-fold time tau_v = first t >= 1 with W_v(t) >= e * W_v(0) (in counts: wins >= ceil(e * wins0)); infinity if never
           within the 1,500 visits.
  Node take-off t*_v = tau_v / (1 - 1/e)  (under the model varpi reaches e varpi0 at t = (1 - 1/e) t*).
  Stream take-off t*(eta) = median of t*_v over all (chat, order, top-5 node) triples (10 x 3 x 5 = 150), censored
           values counted as infinity; the median is infinity ("no take-off") if half or more never e-fold.
  Interval: chat-clustered bootstrap of that median (4,000 draws, the same chat draws as common.cluster_boot seed 0).
  Secondary (reported, not used in the verdict): thresholds M = 2 and M = 4 (t*_v = tau_v / (1 - 1/M)); the first
  e-fold per stream among its top 5; the leader-share e-fold (first t with max_v W_v(t) >= e max_v W_v(0)).
Recomputed on this setup (in the run, from K0 before any learning; nothing tuned):
  beta_G = mean top1 - top2 score gap over a chat's questions (mean over chats); varpi0 = mean top-5 initial share;
  h = <tgt, sbar> - <k, tgt><k, sbar> (eq. 6.1) per won question of each top-5 node, sbar = the chat's own mean ask
  state (as in the old selfloop.py), tgt = s (plain, capped) or n(s - mu) (centred);
  predicted t*(eta) = beta_G / (eta h varpi0);
  direct estimate = median over top-5 nodes with dW1 > 0 of 1/dW1, dW1 = mean change in W_v from one step toward
  one of v's won questions; share_dW_pos = fraction of top-5 nodes with dW1 > 0 (the "Delta varpi > 0" qualifier).

Pass bar (front matter table, test 1.5): "take-off at about 60 questions at step 0.1 (method 6.4: predicted 61, direct
estimate 60), scaling as 1/step within a factor of 3; the plain rule's loss grows without bound; centred saturates
near -0.04 and capped near -0.08". Fails if "take-off scale or saturation outside these". Operational parts, each
judged with its 95% chat-clustered interval: PASS if the whole interval is inside the pass region, FAIL if the whole
interval is outside it, INCONCLUSIVE otherwise.
  (a) take-off scale: plain t*(0.1) in [61/2, 61*2] = [30.5, 122] ("about 61", a factor of 2).
  (b) 1/eta scaling: over the eta with share_dW_pos > 0.5 (P5's qualifier "for eta where most top winners have
      Delta varpi > 0"), max/min of eta * t*(eta) (plain) <= 3. If an eligible eta has t* = infinity, (b) fails. If
      fewer than two eta are eligible, (b) is inconclusive (cannot be tested).
  (c) plain grows without bound, at every eta in {0.05, 0.1, 0.2}: the late change D = mean loss over t in
      [1200, 1500) minus mean loss over t in [600, 900) is below -0.01 (still falling by more than 0.01 recall over
      the last 600 visits). Pass region D < -0.01. (c) passes if all three eta pass, fails if any fails.
  (d) centred at eta 0.1 saturates near -0.04: final level L = mean loss over t in [1200, 1500) in [-0.06, -0.02]
      (+-50%) AND levelled off, D in [-0.01, +0.01]. Fails if either part fails.
  (e) capped (zeta 0.3) at eta 0.1 saturates near -0.08: L in [-0.12, -0.04] (+-50%) AND D in [-0.01, +0.01].
  P5 passes only if (a) to (e) all pass; it fails if any part fails; otherwise it is inconclusive.
The centred and capped arms at eta 0.05 and 0.2, the fused losses and all secondary take-off measures are reported but
do not enter the verdict.

Compute: 9 arms x 10 chats x 3 orders x 1,500 visits, one CPU thread. Usage: python s15_selffeedback.py

POST HOC (added after the first run on 2026-10-28; reported under "post_hoc", never used in the verdict; the
pre-registered arms and verdict are unchanged and deterministic, and the rerun reproduced them exactly):
  1. The primary take-off was censored (fewer than half of the top-5 winners ever e-fold), so the 1/eta ratio
     max/min of eta * t*(eta) is also computed, with the same chat draws, for the two secondary measures (first e-fold
     among the top 5 per stream; leader-share e-fold).
  2. Arm "centred_own eta=0.1": the centred rule with mu = the held-out chat's own mean ask state (label-free, but it
     uses the chat's future questions and is not a frozen per-version mean, so it breaks fix #10). It asks whether the
     frozen training-chat mean is why the centred rule did not level off (its h on held-out questions is > 0).
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(_v, "1")
import json, math, sys, time  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
from retrieval import Reader  # noqa: E402

T = 1500
WIN = 150
EARLY = 25
ETAS = (0.05, 0.1, 0.2)
RULES = ("plain", "centred", "capped")
ZETA = 0.3
ORDERS = 3
TOP = 5
NBOOT = 4000
MID, LATE = (600, 900), (1200, 1500)
STATED = dict(t_star_pred_eta01=61, t_star_direct_eta01=60, varpi0=0.034, beta_G=0.048, h=0.229,
              loss_plain_eta01_after_10_passes=-0.169, loss_centred_eta01=-0.037, loss_capped_eta01=-0.075)
BARS = dict(a=(61 / 2, 61 * 2), b=3.0, c=-0.01, d_level=(-0.06, -0.02), e_level=(-0.12, -0.04), level_D=(-0.01, 0.01))


def unit1(x):
    return x / np.linalg.norm(x)


def target(s, rule, mu):
    return unit1(s - 1.0 * mu) if rule in ("centred", "centred_own") else s


def step(k, k0, s, rule, eta, mu):
    """One self-cite step; same float operations as s12_cites.run_order for plain and centred (c = 1)."""
    d = target(s, rule, mu)
    k = unit1(k + eta * (d - k))
    if rule == "capped":
        diff = k - k0; n = float(np.linalg.norm(diff))
        if n > ZETA:
            k = unit1(k0 + ZETA * diff / n)
    return k


def visits_of(i, o, nq):
    rng = np.random.default_rng([i, o, 2027]); seq = []
    while len(seq) < T:
        seq += rng.permutation(nq).tolist()
    return np.array(seq[:T])


def initial(K0, S):
    SC = S @ K0.T
    cnt = np.bincount(SC.argmax(1), minlength=len(K0))
    top5 = np.argsort(-cnt, kind="stable")[:TOP]
    srt = np.sort(SC, 1)
    return SC, cnt, top5, float(np.mean(srt[:, -1] - srt[:, -2]))


def loop_gain(K0, S, SC, cnt, top5, rule, eta, mu, sbar):
    """Per top-5 node: initial share W0, mean dW from one step toward one of its won questions, mean h (eq. 6.1)."""
    nq = len(S); top1 = SC.argmax(1); out = []
    for v in top5:
        won = np.where(top1 == v)[0]; dws, hs = [], []
        for j in won:
            k1 = step(K0[v], K0[v], S[j], rule, eta, mu)
            SC1 = SC.copy(); SC1[:, v] = S @ k1
            dws.append(float((SC1.argmax(1) == v).sum() - cnt[v]) / nq)
            tgt = target(S[j], rule, mu)
            hs.append(float(tgt @ sbar - (K0[v] @ tgt) * (K0[v] @ sbar)))
        out.append((cnt[v] / nq, float(np.mean(dws)), float(np.mean(hs))))
    return out


def stream(K0, S, lexorder, ev, visits, rule, eta, mu, base_d, base_f, SC0, top5):
    keys = K0.copy(); nq, n = len(S), len(K0); SC = SC0.copy()
    dense = np.empty(T); fused = np.empty(T); cite = np.empty(T, dtype=np.int64); wrong = np.empty(T, dtype=bool)
    wtop = np.empty((T + 1, TOP), dtype=np.int64); lead = np.empty(T + 1, dtype=np.int64)
    c0 = np.bincount(SC.argmax(1), minlength=n); wtop[0] = c0[top5]; lead[0] = c0.max()
    for t, r in enumerate(visits):
        s = S[r]; top = C.order_of(keys @ s)
        dense[t] = C.recall(top, ev[r]) - base_d[r]
        fused[t] = C.recall(C.fuse(lexorder[r], top), ev[r]) - base_f[r]
        v = int(top[0]); cite[t] = v; wrong[t] = v not in ev[r]
        keys[v] = step(keys[v], K0[v], s, rule, eta, mu)
        SC[:, v] = S @ keys[v]
        c = np.bincount(SC.argmax(1), minlength=n); wtop[t + 1] = c[top5]; lead[t + 1] = c.max()
    cos0 = float(np.min(np.sum(keys * K0, 1)))
    return dict(dense=dense, fused=fused, cite=cite, wrong=wrong, wtop=wtop, lead=lead, cos0=cos0)


def fold_time(series, c0, M):
    """First t >= 1 with count >= ceil(M c0); inf if never."""
    need = math.ceil(M * c0 - 1e-9)
    hit = np.nonzero(series[1:] >= need)[0]
    return float(hit[0] + 1) if len(hit) else math.inf


def picks():
    rng = np.random.default_rng(0)
    return rng.integers(0, 10, (NBOOT, 10))  # the same draws as common.cluster_boot(seed 0) over 10 chats


PICK = picks()


def pct(b, q):
    """Percentile; nearest rank when some draws are infinite (linear interpolation would give nan)."""
    return float(np.percentile(b, q, method="linear" if np.isfinite(b).all() else "nearest"))


def boot_median(vals):
    """vals: (10 chats, m) array -> (median of all, 95% CI of the median, chats resampled)."""
    vals = np.asarray(vals, dtype=np.float64)
    b = np.median(vals[PICK].reshape(NBOOT, -1), axis=1)
    return float(np.median(vals)), [pct(b, 2.5), pct(b, 97.5)], b


def judge(ci, lo, hi):
    """PASS if the interval is inside [lo, hi], FAIL if it does not touch it, INCONCLUSIVE otherwise."""
    if lo <= ci[0] and ci[1] <= hi:
        return "pass"
    if ci[1] < lo or ci[0] > hi:
        return "fail"
    return "inconclusive"


def combine(parts):
    if all(p == "pass" for p in parts):
        return "pass"
    if any(p == "fail" for p in parts):
        return "fail"
    return "inconclusive"


def fin(x):
    return None if not np.isfinite(x) else round(float(x), 2)


def main():
    t_start = time.time()
    R = Reader(with_lme=False)
    arms = [(rule, eta) for rule in RULES for eta in ETAS] + [("centred_own", 0.1)]  # last one: post hoc diagnostic
    geo = dict(beta_G=[], varpi0=[], lead0=[], n_q=[], passes=[])
    gains = {a: [] for a in arms}
    res = {a: dict(dense=np.zeros((10, T)), fused=np.zeros((10, T)), wrong=np.zeros(10), tau={}, first=[], lead_t=[],
                   top_share=np.zeros((10, T // WIN)), cos0=1.0) for a in arms}
    repro = {}
    for i, ch in enumerate(R.chats):
        K0, S = R.keys[i]; f = i // 2; nq = len(S); ev = [q[1] for q in ch["qs"]]
        tr = [j for j in range(10) if j not in C.FOLDS[f]]
        mu = np.concatenate([R.bridges[f].views(R.chats[j]["nodes"], R.chats[j]["asks"])[1] for j in tr]).mean(0)
        sbar = S.mean(0)
        SC0, cnt0, top5, gap = initial(K0, S)
        geo["beta_G"].append(gap); geo["varpi0"].append(float(cnt0[top5].mean() / nq)); geo["lead0"].append(float(cnt0.max() / nq))
        geo["n_q"].append(nq); geo["passes"].append(math.ceil(T / nq))
        base_d = np.array([C.recall(C.order_of(K0 @ S[r]), ev[r]) for r in range(nq)])
        base_f = np.array([C.recall(C.fuse(ch["lexorder"][r], C.order_of(K0 @ S[r])), ev[r]) for r in range(nq)])
        streams = [visits_of(i, o, nq) for o in range(ORDERS)]
        for a in arms:
            rule, eta = a; mu_a = sbar if rule == "centred_own" else mu
            gains[a] += loop_gain(K0, S, SC0, cnt0, top5, rule, eta, mu_a, sbar)
            for o, vis in enumerate(streams):
                out = stream(K0, S, ch["lexorder"], ev, vis, rule, eta, mu_a, base_d, base_f, SC0, top5)
                rr = res[a]
                rr["dense"][i] += out["dense"] / ORDERS; rr["fused"][i] += out["fused"] / ORDERS
                rr["wrong"][i] += out["wrong"].mean() / ORDERS; rr["cos0"] = min(rr["cos0"], out["cos0"])
                for w in range(T // WIN):
                    seg = out["cite"][w * WIN:(w + 1) * WIN]
                    rr["top_share"][i, w] += np.bincount(seg).max() / len(seg) / ORDERS
                for M, key in ((math.e, "e"), (2.0, "2"), (4.0, "4")):
                    taus = [fold_time(out["wtop"][:, j], out["wtop"][0, j], M) / (1 - 1 / M) for j in range(TOP)]
                    rr["tau"].setdefault(key, [[] for _ in range(10)])[i] += taus
                    if key == "e":
                        rr["first"].append((i, min(taus)))
                rr["lead_t"].append((i, fold_time(out["lead"], out["lead"][0], math.e) / (1 - 1 / math.e)))
                # reproduction check: pass 1 of this stream against s12_cites.run_order (plain and centred at 0.1)
                if eta == 0.1 and rule in ("plain", "centred"):
                    cfg = dict(eta=0.1) if rule == "plain" else dict(eta=0.1, c=1.0)
                    d12, f12 = S12.run_order(K0, S, ch["lexorder"], ch["qs"], [None] * nq, [[]] * nq, vis[:nq], cfg, mu)
                    mine_d = np.empty(nq); mine_f = np.empty(nq)
                    mine_d[vis[:nq]] = out["dense"][:nq] + base_d[vis[:nq]]
                    mine_f[vis[:nq]] = out["fused"][:nq] + base_f[vis[:nq]]
                    e = max(float(np.abs(mine_d - d12).max()), float(np.abs(mine_f - f12).max()))
                    repro[rule] = max(repro.get(rule, 0.0), e)
        print(f"chat {i}: n_q {nq}, nodes {len(K0)}, passes {math.ceil(T / nq)}, top-5 share {cnt0[top5].mean() / nq:.3f}, "
              f"gap {gap:.4f}, {time.time() - t_start:.0f}s", flush=True)

    out = dict(setup=dict(T=T, window=WIN, etas=ETAS, rules=RULES, zeta=ZETA, orders=ORDERS, top=TOP,
                          n_q=geo["n_q"], passes=geo["passes"], boot=NBOOT),
               stated_old=STATED, bars=BARS,
               reproduce_s12_pass1_max_abs_diff=repro,
               geometry=dict(beta_G=round(float(np.mean(geo["beta_G"])), 4), varpi0=round(float(np.mean(geo["varpi0"])), 4),
                             leader_share0=round(float(np.mean(geo["lead0"])), 4)),
               arms={})
    beta, varpi0, lead0 = np.mean(geo["beta_G"]), np.mean(geo["varpi0"]), np.mean(geo["lead0"])
    chat_ids = np.arange(10)
    print(f"\nreproduction of s12 pass 1 (max abs recall diff): {repro}")
    print(f"geometry: beta_G {beta:.4f} (stated 0.048), varpi0 {varpi0:.4f} (stated 0.034), leader share {lead0:.4f} (0.047)")
    boots = {}; boots2 = {}
    for a in arms:
        rule, eta = a; name = f"{rule} eta={eta}"; rr = res[a]
        g = np.array(gains[a]); pos = g[:, 1] > 0
        h = float(g[:, 2].mean())
        pred = beta / (eta * h * varpi0) if h > 0 else math.inf
        direct = float(np.median(1 / g[pos, 1])) if pos.any() else math.inf
        med, ci, b = boot_median(np.array(rr["tau"]["e"]))
        boots[a] = b
        tau_e = np.array(rr["tau"]["e"])
        sens = {M: boot_median(np.array(rr["tau"][M]))[:2] for M in ("2", "4")}
        first = np.array([[v for c, v in rr["first"] if c == j] for j in range(10)])
        lead_t = np.array([[v for c, v in rr["lead_t"] if c == j] for j in range(10)])
        mf, cf, bf = boot_median(first); ml, cl, bl = boot_median(lead_t)
        boots2[a] = dict(first_of_top5=(mf, bf), leader_share=(ml, bl))
        dense, fused = rr["dense"], rr["fused"]
        curve = []
        for w in range(T // WIN):
            m, cc = C.cluster_boot(dense[:, w * WIN:(w + 1) * WIN].mean(1), chat_ids)
            mfu, _ = C.cluster_boot(fused[:, w * WIN:(w + 1) * WIN].mean(1), chat_ids)
            curve.append(dict(t=[w * WIN, (w + 1) * WIN], dense=round(m, 4), ci=[round(x, 4) for x in cc], fused=round(mfu, 4)))
        early = [round(float(dense[:, w * EARLY:(w + 1) * EARLY].mean()), 4) for w in range(300 // EARLY)]
        D_chat = dense[:, LATE[0]:LATE[1]].mean(1) - dense[:, MID[0]:MID[1]].mean(1)
        L_chat = dense[:, LATE[0]:LATE[1]].mean(1)
        Df_chat = fused[:, LATE[0]:LATE[1]].mean(1) - fused[:, MID[0]:MID[1]].mean(1)
        D, Dci = C.cluster_boot(D_chat, chat_ids); L, Lci = C.cluster_boot(L_chat, chat_ids)
        Lf, Lfci = C.cluster_boot(fused[:, LATE[0]:LATE[1]].mean(1), chat_ids); Df, Dfci = C.cluster_boot(Df_chat, chat_ids)
        out["arms"][name] = dict(
            loop=dict(h=round(h, 4), share_dW_pos=round(float(pos.mean()), 3), dW1=round(float(g[:, 1].mean()), 5),
                      t_star_pred=fin(pred), t_star_direct=fin(direct)),
            take_off=dict(t_star=fin(med), ci=[fin(x) for x in ci], efold_share=round(float(np.isfinite(tau_e).mean()), 3),
                          efold_time_median=fin(med * (1 - 1 / math.e)),
                          M2=dict(t_star=fin(sens["2"][0]), ci=[fin(x) for x in sens["2"][1]]),
                          M4=dict(t_star=fin(sens["4"][0]), ci=[fin(x) for x in sens["4"][1]]),
                          first_of_top5=dict(t_star=fin(mf), ci=[fin(x) for x in cf]),
                          leader_share=dict(t_star=fin(ml), ci=[fin(x) for x in cl],
                                            pred=fin(beta / (eta * h * lead0)) if h > 0 else None)),
            loss=dict(curve=curve, early_25=early, final=round(L, 4), final_ci=[round(x, 4) for x in Lci],
                      late_change=round(D, 4), late_change_ci=[round(x, 4) for x in Dci],
                      fused_final=round(Lf, 4), fused_final_ci=[round(x, 4) for x in Lfci],
                      fused_late_change=round(Df, 4), fused_late_change_ci=[round(x, 4) for x in Dfci],
                      final_per_chat=[round(float(x), 4) for x in L_chat]),
            realised_wrong_cite_share=round(float(rr["wrong"].mean()), 4),
            window_top_share=[round(float(x), 3) for x in rr["top_share"].mean(0)],
            min_cos_to_base_key=round(rr["cos0"], 5))

    # ---- verdict, mechanical
    A = out["arms"]; v = {}
    p01 = A["plain eta=0.1"]["take_off"]
    ci_a = [x if x is not None else math.inf for x in p01["ci"]]
    v["a_take_off_scale"] = dict(t_star=p01["t_star"], ci=p01["ci"], bar=BARS["a"], result=judge(ci_a, *BARS["a"]))
    elig = [e for e in ETAS if A[f"plain eta={e}"]["loop"]["share_dW_pos"] > 0.5]
    if len(elig) < 2:
        vb = dict(eligible=elig, result="inconclusive")
    else:
        prods = {e: (A[f"plain eta={e}"]["take_off"]["t_star"] or math.inf) * e for e in elig}
        if any(not np.isfinite(x) for x in prods.values()):
            vb = dict(eligible=elig, eta_times_t_star={str(e): fin(x) for e, x in prods.items()}, result="fail")
        else:
            bmat = np.stack([boots[("plain", e)] * e for e in elig])
            ratio_b = np.where(np.isfinite(bmat).all(0), bmat.max(0) / bmat.min(0), np.inf)
            ratio = max(prods.values()) / min(prods.values())
            rci = [pct(ratio_b, 2.5), pct(ratio_b, 97.5)]
            vb = dict(eligible=elig, eta_times_t_star={str(e): round(x, 2) for e, x in prods.items()}, max_over_min=round(ratio, 3),
                      ci=[round(x, 3) if np.isfinite(x) else None for x in rci], bar=BARS["b"],
                      result=judge(rci, 0.0, BARS["b"]))
    v["b_one_over_eta"] = vb
    vc = {}
    for e in ETAS:
        L_ = A[f"plain eta={e}"]["loss"]
        vc[str(e)] = dict(late_change=L_["late_change"], ci=L_["late_change_ci"], result=judge(L_["late_change_ci"], -math.inf, BARS["c"]))
    v["c_plain_unbounded"] = dict(per_eta=vc, result=combine([x["result"] for x in vc.values()]))
    for key, rule, band in (("d_centred", "centred", BARS["d_level"]), ("e_capped", "capped", BARS["e_level"])):
        L_ = A[f"{rule} eta=0.1"]["loss"]
        lv = judge(L_["final_ci"], *band); fl = judge(L_["late_change_ci"], *BARS["level_D"])
        v[key] = dict(final=L_["final"], final_ci=L_["final_ci"], band=band, level=lv,
                      late_change=L_["late_change"], late_change_ci=L_["late_change_ci"], flat_band=BARS["level_D"], flat=fl,
                      result=combine([lv, fl]))
    v["P5"] = combine([v[k]["result"] for k in ("a_take_off_scale", "b_one_over_eta", "c_plain_unbounded", "d_centred", "e_capped")])
    out["verdict"] = v
    # ---- post hoc (see docstring): 1/eta ratio for the secondary take-off measures, plain rule, all three eta
    ph = {}
    for key in ("first_of_top5", "leader_share"):
        pt = {e: boots2[("plain", e)][key][0] * e for e in ETAS}
        bm = np.stack([boots2[("plain", e)][key][1] * e for e in ETAS])
        rb = np.where(np.isfinite(bm).all(0), bm.max(0) / bm.min(0), np.inf)
        ph[key] = dict(eta_times_t_star={str(e): fin(x) for e, x in pt.items()},
                       max_over_min=fin(max(pt.values()) / min(pt.values())), ci=[fin(pct(rb, 2.5)), fin(pct(rb, 97.5))],
                       t_star_eta01=A["plain eta=0.1"]["take_off"][key]["t_star"], ci_eta01=A["plain eta=0.1"]["take_off"][key]["ci"])
    ph["centred_own_eta01"] = A["centred_own eta=0.1"]
    out["post_hoc"] = ph
    out["seconds"] = round(time.time() - t_start, 1)
    path = os.path.join(HERE, "results", "s15_selffeedback.json")
    json.dump(out, open(path, "w"), indent=1)

    print("\narm               h       dW>0   t*pred  t*direct | stream t* [CI]        e-folded | M2    M4    first  leader"
          " | final [CI]                late change [CI]          | p_self  min<k,k0>")
    for name, r in A.items():
        lo, to, ls = r["loop"], r["take_off"], r["loss"]
        print(f"{name:<17} {lo['h']:+.3f}  {lo['share_dW_pos']:.2f}  {str(lo['t_star_pred']):>7} {str(lo['t_star_direct']):>8} | "
              f"{str(to['t_star']):>6} [{to['ci'][0]}, {to['ci'][1]}]  {to['efold_share']:.2f} | {to['M2']['t_star']} {to['M4']['t_star']} "
              f"{to['first_of_top5']['t_star']} {to['leader_share']['t_star']} | {ls['final']:+.4f} [{ls['final_ci'][0]:+.4f},{ls['final_ci'][1]:+.4f}]"
              f"  {ls['late_change']:+.4f} [{ls['late_change_ci'][0]:+.4f},{ls['late_change_ci'][1]:+.4f}] | "
              f"{r['realised_wrong_cite_share']:.3f}  {r['min_cos_to_base_key']:.4f}")
    print("\nloss vs no learning (dense recall@10), windows of 150 visits:")
    for name, r in A.items():
        print(f"  {name:<17} " + " ".join(f"{c['dense']:+.3f}" for c in r["loss"]["curve"]))
    print("first 300 visits, windows of 25:")
    for name, r in A.items():
        print(f"  {name:<17} " + " ".join(f"{x:+.3f}" for x in r["loss"]["early_25"]))
    print("window top share (share of visits whose top 1 is the window's most frequent top 1):")
    for name, r in A.items():
        print(f"  {name:<17} " + " ".join(f"{x:.2f}" for x in r["window_top_share"]))
    print("\nverdict:\n" + json.dumps(v, indent=1))
    print("\npost hoc (not in the verdict): 1/eta ratio of the secondary take-off measures, plain rule")
    for key in ("first_of_top5", "leader_share"):
        print(f"  {key}: " + json.dumps({k: ph[key][k] for k in ("eta_times_t_star", "max_over_min", "ci", "t_star_eta01", "ci_eta01")}))
    print(f"seconds {out['seconds']}")


if __name__ == "__main__":
    main()
