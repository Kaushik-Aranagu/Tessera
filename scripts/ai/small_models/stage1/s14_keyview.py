#!/usr/bin/env python3
"""Stage 1.4 (prediction P2): a view-consistent target for the move rule.

Why. The move rule pulls a cited node's key k_v, which lives in the key view (k_v = n(A e_v)), toward the question's
state s_q = n(S e_q), which lives in the state view (method section 8, error 9). P2 says that using the key-view target
n(A e_q) instead shrinks the self-feedback loss without lowering the clean gain.

Protocol (pre-registered before any test number was produced; the s12_cites.py protocol, LoCoMo only):
  - keys: the tuned rank-16 bridges (retrieval.Reader), chat i read with the bridge of the outer fold that held it out
    (fold i // 2). K0 = n(A e_v) for every node, S = n(S e_q) for every question, T = n(A e_q) for every question
    (same bridge, key view applied to the question's frozen bge-small vector).
  - per held-out chat, the same 3 shuffled orders as s12: np.random.default_rng([chat, order, 2027]).permutation(nq).
    Every arm sees the same orders (common random numbers). At each question the current keys score the question
    through its state S[r] (the read never changes); recall@10 is taken dense and fused with BM25 (RRF k 60); then the
    question's cites move their keys: k_v <- n(k_v + eta (d - k_v)), with
        old  d = S[r]          (state-view target, the current rule)
        new  d = T[r]          (key-view target n(A e_q), the P2 rule)
    Cite conditions: clean (all marked evidence of the question is cited) and self (the current dense top 1 is cited).
  - eta 0.1 (primary, the step the front matter's -0.023 / +0.020 refer to) and eta 0.05 (secondary).
  - arms: no learning; old; new. Per question the 3 orders are averaged. Differences are paired per question and
    the 95% interval is the chat-clustered paired bootstrap (common.cluster_boot, 4,000 draws, seed 0, the same
    resamples for every comparison). Nothing is tuned: eta values are fixed in advance; no test chat chooses anything.
  - the old rule's numbers are recomputed here on the tuned rank-16 bridges and the 1,536-question parser (the front
    matter's -0.023 self and +0.020 clean came from the old untuned bridges); the comparison is within this run.
  - self-check: the old arm must reproduce s12_cites.run_order exactly (asserted for every chat, order 0, eta 0.1,
    both conditions) before any number is reported.
  - LongMemEval-S is not used: one question per haystack, nothing is asked twice (as in s12).

Pass bar (front matter table, test 1.4): "the self-feedback loss shrinks from -0.023 at step 0.1, while the clean gain
stays near +0.020"; fails if "the clean gain falls, or the self-feedback loss does not shrink". Made exact here, on the
dense recall@10 at eta 0.1:
  D_self  = mean over questions of (new - old) under self, with its chat-clustered 95% CI.
  D_clean = mean over questions of (new - old) under clean, with its chat-clustered 95% CI.
  "shrinks": the CI of D_self lies entirely above zero.
  "near":    |D_clean| <= 0.005 (the new rule's clean gain is within 0.005 of the old rule's clean gain).
Decision rule (mechanical, written into the verdict):
  PASS          shrinks and near; also counted as PASS if D_clean > +0.005 (the clean gain rises; flagged "rises").
  FAIL          D_clean < -0.005 (the clean gain falls), or D_self <= 0 (the self loss does not shrink).
  INCONCLUSIVE  otherwise (D_self > 0 but its CI reaches zero, with the clean gain not falling).
Secondary, reported but not part of the verdict: the same quantities at eta 0.05; fused (BM25) gains; multi-hop gains;
an equivalence reading of the clean difference (is its CI inside [-0.005, +0.005]); per-chat differences; and
diagnostics: mean cos(S[r], T[r]); the common-mode drift h = <d, s_bar> - <k, d><k, s_bar> of eq. 6.1 at the initial
keys for clean cites (s_bar = the held-out chat's own mean question state, used only as a descriptive number); in the
self condition the realised wrong-cite share (self cites that are not marked evidence) and the leader's share of
self cites (the most-cited node's cites over the chat's questions, averaged over orders and chats).
Usage: python s14_keyview.py
"""
import json, os, sys, time
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
from retrieval import Reader  # noqa: E402

ETAS = (0.1, 0.05)
CONDS = ("clean", "self")
TARGETS = ("old", "new")
ORDERS = S12.ORDERS  # 3
NEAR = 0.005


def unit1(x):
    return x / np.linalg.norm(x)


def run_order(K0, S, T, lexorder, qs, cites, order, eta):
    """One pass over a chat. Scores with S (state view); moves cited keys toward T[r] (S for old, n(A e_q) for new).
    cites[r] is a node list, or None for self (the current dense top 1). Returns dense, fused, self-cite stats."""
    keys = K0.copy(); dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    counts = np.zeros(len(K0), dtype=np.int64); wrong = 0; n_cites = 0
    for r in order:
        top = C.order_of(keys @ S[r])
        dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        if not eta:
            continue
        cited = [int(top[0])] if cites[r] is None else cites[r]
        d = T[r]
        for v in cited:
            keys[v] = unit1(keys[v] + eta * (d - keys[v]))
            counts[v] += 1; n_cites += 1; wrong += v not in qs[r][1]
    return dense, fused, dict(wrong_share=wrong / max(n_cites, 1), leader_share=counts.max() / len(qs) if n_cites else 0.0)


def main():
    torch.set_num_threads(1)
    t0 = time.time()
    R = Reader(with_lme=False)
    vals = {}  # (eta, target, cond, mode) -> per question values in chat order
    base = {"dense": [], "fused": []}; chat_of = []; cat_of = []
    stats = {(eta, tg): {"wrong_share": [], "leader_share": []} for eta in ETAS for tg in TARGETS}
    diag = {"cos_s_t": [], "h_old": [], "h_new": [], "s_bar_dot_old": [], "s_bar_dot_new": []}
    for i, ch in enumerate(R.chats):
        K0, S = R.keys[i]; br = R.bridges[i // 2]
        T = br.key_np(ch["asks"]).astype(np.float32)
        assert T.shape == S.shape and np.allclose(np.linalg.norm(T, axis=1), 1, atol=1e-5)
        nq = len(ch["qs"]); qs = ch["qs"]; lex = ch["lexorder"]
        cites = {"clean": [list(q[1]) for q in qs], "self": [None] * nq}
        orders = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(ORDERS)]
        tgt = {"old": S, "new": T}
        # self-check against s12's run_order (old target), order 0, eta 0.1, both conditions
        for cond in CONDS:
            a_d, a_f, _ = run_order(K0, S, S, lex, qs, cites[cond], orders[0], 0.1)
            b_d, b_f = S12.run_order(K0, S, lex, qs, cites[cond], [[]] * nq, orders[0], {"eta": 0.1}, None)
            assert np.array_equal(a_d, b_d) and np.array_equal(a_f, b_f), f"old arm differs from s12, chat {i} {cond}"
        # diagnostics at the initial keys
        sbar = S.mean(0)
        diag["cos_s_t"] += (S * T).sum(1).tolist()
        for r, q in enumerate(qs):
            for v in q[1]:
                k = K0[v]
                for name, d in (("old", S[r]), ("new", T[r])):
                    diag[f"h_{name}"].append(float(d @ sbar - (k @ d) * (k @ sbar)))
                    diag[f"s_bar_dot_{name}"].append(float(d @ sbar))
        # no learning
        d0 = np.zeros(nq); f0 = np.zeros(nq)
        for order in orders:
            d, fu, _ = run_order(K0, S, S, lex, qs, cites["clean"], order, 0.0)
            d0 += d / ORDERS; f0 += fu / ORDERS
        base["dense"] += d0.tolist(); base["fused"] += f0.tolist()
        chat_of += [i] * nq; cat_of += [q[2] for q in qs]
        for eta in ETAS:
            for tg in TARGETS:
                for cond in CONDS:
                    dd = np.zeros(nq); ff = np.zeros(nq)
                    for order in orders:
                        d, fu, st = run_order(K0, S, tgt[tg], lex, qs, cites[cond], order, eta)
                        dd += d / ORDERS; ff += fu / ORDERS
                        if cond == "self":
                            for k_ in st:
                                stats[(eta, tg)][k_].append(st[k_])
                    vals.setdefault((eta, tg, cond, "dense"), []).extend(dd.tolist())
                    vals.setdefault((eta, tg, cond, "fused"), []).extend(ff.tolist())
        print(f"chat {i}: {nq} questions, {len(K0)} nodes  ({time.time() - t0:.0f}s)", flush=True)

    chat_of = np.array(chat_of); cat_of = np.array(cat_of)
    b_d = np.array(base["dense"]); b_f = np.array(base["fused"])
    out = dict(check="stage 1.4, P2: move rule toward the key-view target n(A e_q) instead of the state s_q",
               n_questions=int(len(b_d)), orders=ORDERS, etas=list(ETAS), self_check_against_s12="passed",
               baseline=dict(dense=round(float(b_d.mean()), 4), fused=round(float(b_f.mean()), 4),
                             dense_multi_hop=round(float(b_d[cat_of == 1].mean()), 4)))

    def ci(x):
        m, c = C.cluster_boot(x, chat_of)
        return round(m, 4), [round(c[0], 4), round(c[1], 4)]

    arms = {}
    for eta in ETAS:
        for tg in TARGETS:
            for cond in CONDS:
                v_d = np.array(vals[(eta, tg, cond, "dense")]); v_f = np.array(vals[(eta, tg, cond, "fused")])
                g, gc = ci(v_d - b_d); fg, fc = ci(v_f - b_f)
                per_chat = [round(float((v_d - b_d)[chat_of == j].mean()), 4) for j in range(10)]
                arms[f"{tg} η{eta} | {cond}"] = dict(
                    dense=round(float(v_d.mean()), 4), gain=g, ci=gc, fused=round(float(v_f.mean()), 4),
                    fused_gain=fg, fused_ci=fc, multi_hop_gain=round(float((v_d - b_d)[cat_of == 1].mean()), 4),
                    chats_up=int(sum(x > 0 for x in per_chat)), per_chat=per_chat)
    out["arms"] = arms
    comps = {}
    for eta in ETAS:
        for cond in CONDS:
            n_d = np.array(vals[(eta, "new", cond, "dense")]); o_d = np.array(vals[(eta, "old", cond, "dense")])
            n_f = np.array(vals[(eta, "new", cond, "fused")]); o_f = np.array(vals[(eta, "old", cond, "fused")])
            m, c = ci(n_d - o_d); fm, fc = ci(n_f - o_f)
            per_chat = [round(float((n_d - o_d)[chat_of == j].mean()), 4) for j in range(10)]
            comps[f"new - old η{eta} | {cond}"] = dict(
                diff=m, ci=c, fused_diff=fm, fused_ci=fc,
                multi_hop_diff=round(float((n_d - o_d)[cat_of == 1].mean()), 4),
                chats_new_better=int(sum(x > 0 for x in per_chat)), per_chat=per_chat)
    out["new_minus_old"] = comps
    out["self_condition_stats"] = {f"{tg} η{eta}": {k: round(float(np.mean(v)), 4) for k, v in st.items()}
                                   for (eta, tg), st in stats.items()}
    out["diagnostics"] = dict(
        cos_state_vs_keyview_target=dict(mean=round(float(np.mean(diag["cos_s_t"])), 4),
                                         min=round(float(np.min(diag["cos_s_t"])), 4)),
        h_eq_6_1_clean_cites=dict(old=round(float(np.mean(diag["h_old"])), 4), new=round(float(np.mean(diag["h_new"])), 4)),
        target_dot_mean_state=dict(old=round(float(np.mean(diag["s_bar_dot_old"])), 4),
                                   new=round(float(np.mean(diag["s_bar_dot_new"])), 4)),
        note="h and <d, s_bar> use the held-out chat's own mean question state (descriptive only, nothing chosen on it)")

    # ---- verdicts, mechanical (primary at eta 0.1; eta 0.05 reported the same way as secondary)
    verdict = {}
    for eta in ETAS:
        ds = comps[f"new - old η{eta} | self"]; dc = comps[f"new - old η{eta} | clean"]
        shrinks = ds["ci"][0] > 0
        clean_state = "near" if abs(dc["diff"]) <= NEAR else ("rises" if dc["diff"] > NEAR else "falls")
        if shrinks and clean_state in ("near", "rises"):
            call = "pass"
        elif clean_state == "falls" or ds["diff"] <= 0:
            call = "fail"
        else:
            call = "inconclusive"
        verdict[f"η{eta}"] = dict(
            role="primary" if eta == 0.1 else "secondary",
            old_self_loss=arms[f"old η{eta} | self"]["gain"], old_self_ci=arms[f"old η{eta} | self"]["ci"],
            new_self_loss=arms[f"new η{eta} | self"]["gain"], new_self_ci=arms[f"new η{eta} | self"]["ci"],
            old_clean_gain=arms[f"old η{eta} | clean"]["gain"], old_clean_ci=arms[f"old η{eta} | clean"]["ci"],
            new_clean_gain=arms[f"new η{eta} | clean"]["gain"], new_clean_ci=arms[f"new η{eta} | clean"]["ci"],
            D_self=ds["diff"], D_self_ci=ds["ci"], shrinks=bool(shrinks),
            D_clean=dc["diff"], D_clean_ci=dc["ci"], clean=clean_state,
            clean_ci_inside_pm_0_005=bool(dc["ci"][0] >= -NEAR and dc["ci"][1] <= NEAR), call=call)
    out["verdict"] = verdict
    out["seconds"] = round(time.time() - t0, 1)
    path = os.path.join(HERE, "results", "s14_keyview.json")
    json.dump(out, open(path, "w"), indent=1, ensure_ascii=False)

    print(f"\nbaseline (no learning): dense {out['baseline']['dense']:.4f}  fused {out['baseline']['fused']:.4f}  "
          f"multi-hop {out['baseline']['dense_multi_hop']:.4f}")
    print("\narms, gain against no learning (dense recall@10, chat-clustered 95% CI):")
    for k, r in arms.items():
        print(f"  {k:<18} gain {r['gain']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused {r['fused_gain']:+.4f} "
              f"[{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  mh {r['multi_hop_gain']:+.4f}  chats up {r['chats_up']}/10")
    print("\nnew minus old (paired, chat-clustered 95% CI):")
    for k, r in comps.items():
        print(f"  {k:<22} {r['diff']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused {r['fused_diff']:+.4f} "
              f"[{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  mh {r['multi_hop_diff']:+.4f}  "
              f"new better in {r['chats_new_better']}/10 chats")
    print("\nself-condition stats:", json.dumps(out["self_condition_stats"], ensure_ascii=False))
    print("diagnostics:", json.dumps(out["diagnostics"], ensure_ascii=False))
    print("\nverdict:", json.dumps(verdict, indent=1, ensure_ascii=False))
    print(f"\n{out['seconds']}s")


if __name__ == "__main__":
    main()
