#!/usr/bin/env python3
"""Stage 1.7 (prediction P6): an alias bonus calibrated only on the same user's EARLIER questions.

Pre-registered (written before any test-chat number of this check existed; not changed after).

Data: LoCoMo only (pinned file, 1,536 questions, common.load_locomo). LongMemEval-S is not used: each of its haystacks
has one question, so there are no earlier questions of the same user to calibrate on and no later question for an
alias to help. No Tessera data.

Protocol (s12_cites.py's, so numbers are comparable): tuned rank-16 keys of the fold that held the chat out
(retrieval.Reader: R.keys[i], R.bridges[i // 2]); 3 shuffled orders per held-out chat,
np.random.default_rng([chat, order, 2027]).permutation; clean cites (every marked evidence node of the question);
after each question is scored, the plane learns from its cites; recall@10 dense, and fused with BM25 (RRF k 60);
the 3 orders averaged per question. Aliases never move keys: score(v) = <k_v, s_q> + beta * bonus_v(q).

Arms (alias = vector a stored for each cited node v of an earlier question q'; bonus_v(q) = max over the aliases of v
of max(0, <a, s_q> - r(a)); an alias's own question is never one of its references):
  none      no learning (must reproduce s12's baseline: dense 0.6622, fused 0.6553)
  F3        the alias-hub fix's rule F3, recomputed: a = s_q' (state view); r(a) = mean of the K largest cosines of a with
            the references = the fold's training-chat question states plus this chat's questions already visited.
  SU-key    the test arm (P6): a = n(A e_q') (key view, method section 8 error 8); r(a) = r_K(a) = the K-th largest
            cosine of a with this chat's questions already visited (the same user's earlier asks, nothing else);
            the bonus cannot fire while fewer than K references exist (n_ref < K).
  F5, SU-state  diagnostics only (not in the decision): key-view alias with F3's references and mean-of-K threshold
            (the alias-hub fix's F5 form), and state-view alias with SU's same-user K-th-largest threshold.
  F3 fixed  secondary reference only: F3 at beta 1, K 10 (the alias-hub fix's modal dev pick), all folds.
Hyperparameters, tuned on dev chats only (never test chats), per outer fold, one pick per family:
  grid beta in {0.5, 1, 2}; K in {3, 10, 50} for F3 and F5 (the alias-hub grid), K in {1, 3, 10, 30} for SU-key and
  SU-state. Dev runs: the fold's 8 training chats form 4 dev pairs (common.inner_pairs); for each pair an inner rank-16
  bridge is trained on the other 6 chats with the fold's tuned rank-16 lr (s11_rank.json picks) and s11's dev seed
  (1000 + 10 f + pair[0]); F3/F5 training references are the 6 fit chats' states under that inner bridge; 2 orders
  per dev chat, default_rng([chat, order, 2027, 17]); clean cites. Objective: mean dense recall@10 over all dev visits.
  Ties go to the first setting in grid order (K ascending, then beta ascending).

Measurements:
  fire rate   for SU-key at its tuned K, over every (alias, visit) pair in the test streams where the alias's source
              question shares NO evidence with the visited question ("unrelated") and the threshold exists (n_ref >= K;
              n_ref = number of earlier visited questions other than the alias's own, i.e. visit position - 1).
              One alias per source question (all aliases of a question share one vector). A fire is <a, s_q> > r_K(a).
              Bound per pair: min(1, 2K/(n_ref + 1)); the exact rank bound K/(n_ref + 1) is reported too, as is the
              all-pairs rate (what Prop. 6.20 bounds directly) and the related-pairs rate (true fires).
  recall gain dense recall@10 per question (orders averaged) minus none, and SU-key minus F3; chat-clustered paired
              bootstrap (common.cluster_boot, 4,000 draws, seed 0, same draws for every comparison). Fused gains,
              multi-hop gains and per-chat differences reported alongside.

Pass bar (front matter test 1.7, P6): fires on unrelated questions at most 2K/(n_ref+1) of the time AND beats F3.
Decision rule, mechanical:
  A (calibration) passes iff the pooled unrelated fire rate <= the pooled mean of min(1, 2K/(n_ref+1)) over the same
    pairs, AND in every n_ref bin ([K,20), [20,50), [50,100), [100,inf)) holding at least 500 unrelated pairs the bin's
    fire rate <= the bin's mean bound. The chat-clustered CI of (fire - bound) is reported, not used.
  B (beats F3) passes iff the mean over the 1,536 questions of (SU-key - F3) dense recall@10 is above zero (point
    estimate, as pre-registered by the task); its chat-clustered 95% interval is reported, and whether it excludes 0.
  Verdict: pass iff A and B; fail if either fails. Whether SU-key's own gain exceeds the old F3 figure (+0.029) is
  reported as information only.
CPU: one thread; about 20 inner bridge trainings (about 4 s each) plus the streams.
Usage: python s17_alias.py [--out results/s17_alias.json]   (stdout goes to results/s17_alias.log)
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(_v, "1")
import argparse, collections, json, sys, time  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

FAMILIES = {
    "F3": dict(view="state", refs="train+chat", thr="mean", Ks=(3, 10, 50), role="reference: alias-hub F3, recomputed"),
    "SU-key": dict(view="key", refs="chat", thr="kth", Ks=(1, 3, 10, 30), role="test arm (P6)"),
    "F5": dict(view="key", refs="train+chat", thr="mean", Ks=(3, 10, 50), role="diagnostic"),
    "SU-state": dict(view="state", refs="chat", thr="kth", Ks=(1, 3, 10, 30), role="diagnostic"),
}
BETAS = (0.5, 1.0, 2.0)
ORDERS, DEV_ORDERS, TOPT = 3, 2, 50
BINS = [(None, 20), (20, 50), (50, 100), (100, 10 ** 9)]
MIN_BIN = 500
OLD_F3 = 0.029


def grid(fam):
    return [(K, b) for K in FAMILIES[fam]["Ks"] for b in BETAS]


def prep(K0, S, AV, train_states, qs, lexorder):
    """Everything about one chat under one bridge that does not depend on the visit order."""
    nq = len(S)
    ev = [list(q[1]) for q in qs]; evs = [set(e) for e in ev]
    share = np.array([[bool(evs[a] & evs[b]) for b in range(nq)] for a in range(nq)])
    X = {"state": S, "key": AV}
    P = dict(nq=nq, N=len(K0), ev=ev, share=share, lex=lexorder,
             base=[K0 @ S[r] for r in range(nq)],                       # same float32 matvec as s12.run_order
             M={v: (X[v] @ S.T).astype(np.float32) for v in X},      # M[v][q', q] = <a_q', s_q>
             n_train=0 if train_states is None else len(train_states))
    if train_states is not None:
        P["Ttop"] = {v: -np.sort(-(X[v] @ train_states.T).astype(np.float32), axis=1)[:, :TOPT] for v in X}
    return P


def stream(P, order, fam, settings, fused=False, fires=False):
    """One pass over a chat in one visit order for one alias family. settings: [(K, beta)].
    Returns per-question dense and fused recall for each setting, and fire records per K (if asked)."""
    F = FAMILIES[fam]; nq, N = P["nq"], P["N"]
    Mo = P["M"][F["view"]][np.ix_(order, order)]
    Sho = P["share"][np.ix_(order, order)]
    Tt = P["Ttop"][F["view"]][order] if F["refs"] == "train+chat" else None
    Ks = sorted({k for k, _ in settings})
    dense = {s: np.zeros(nq) for s in settings}; fus = {s: np.zeros(nq) for s in settings}
    rec = {K: dict(fire=[], nref=[], rel=[]) for K in Ks}
    for t in range(nq):
        r = order[t]; base = P["base"][r]; bon = dict.fromkeys(Ks)
        if t >= 1:
            cur = Mo[:t, t]                                   # each earlier alias against the current question
            sub = Mo[:t, :t].copy(); np.fill_diagonal(sub, -np.inf)   # references: earlier questions, not its own
            srt = -np.sort(-sub, axis=1)                      # descending; the -inf (own question) sorts last
            for K in Ks:
                if F["thr"] == "kth":
                    if t - 1 < K:
                        continue                              # fewer than K references: no threshold, no fire
                    thr = srt[:, K - 1]; nref = t - 1
                else:
                    m = min(K, t - 1)
                    pool = np.concatenate([Tt[:t, :K], srt[:, :m]], axis=1)
                    thr = -np.sort(-pool, axis=1)[:, :K].mean(1); nref = P["n_train"] + t - 1
                gap = cur - thr
                b = np.zeros(N, np.float32)
                for tp in np.nonzero(gap > 0)[0]:
                    g = gap[tp]
                    for v in P["ev"][order[tp]]:
                        if g > b[v]:
                            b[v] = g
                bon[K] = b
                if fires:
                    rec[K]["fire"].append(gap > 0); rec[K]["rel"].append(Sho[:t, t])
                    rec[K]["nref"].append(np.full(t, nref, dtype=np.int32))
        ev = P["ev"][r]
        for s in settings:
            K, beta = s
            sc = base if bon[K] is None else base + np.float32(beta) * bon[K]
            top = C.order_of(sc)
            dense[s][r] = C.recall(top, ev)
            if fused:
                fus[s][r] = C.recall(C.fuse(P["lex"][r], top), ev)
    if fires:
        for K in Ks:
            for k in ("fire", "rel", "nref"):
                rec[K][k] = np.concatenate(rec[K][k]) if rec[K][k] else np.zeros(0)
    return dense, fus, rec


def dev_tune(chats, picks, t0):
    chosen = {fam: [] for fam in FAMILIES}; table = {fam: {} for fam in FAMILIES}; dev_base = []
    for f in range(5):
        tr = [i for i in range(10) if i not in C.FOLDS[f]]
        acc = {fam: {s: [0.0, 0] for s in grid(fam)} for fam in FAMILIES}
        for pair in C.inner_pairs(tr):
            fit = [i for i in tr if i not in pair]
            b = C.train([chats[i] for i in fit], 16, picks[f], seed=1000 + 10 * f + pair[0])
            refs = np.concatenate([b.views(chats[i]["nodes"], chats[i]["asks"])[1] for i in fit])
            for j in pair:
                ch = chats[j]; K0, S = b.views(ch["nodes"], ch["asks"]); AV = b.key_np(ch["asks"])
                P = prep(K0, S, AV, refs, ch["qs"], ch["lexorder"])
                dev_base += [C.recall(C.order_of(P["base"][r]), q[1]) for r, q in enumerate(ch["qs"])] * DEV_ORDERS
                for o in range(DEV_ORDERS):
                    order = np.random.default_rng([j, o, 2027, 17]).permutation(P["nq"])
                    for fam in FAMILIES:
                        d, _, _ = stream(P, order, fam, grid(fam))
                        for s in grid(fam):
                            acc[fam][s][0] += d[s].sum(); acc[fam][s][1] += P["nq"]
        for fam in FAMILIES:
            means = {s: acc[fam][s][0] / acc[fam][s][1] for s in grid(fam)}
            best = grid(fam)[int(np.argmax([means[s] for s in grid(fam)]))]
            chosen[fam].append(best)
            for s, m in means.items():
                table[fam].setdefault(f"K={s[0]} beta={s[1]}", []).append(round(float(m), 4))
        print(f"fold {f}: dev tuned ({time.time() - t0:.0f}s): "
              + "; ".join(f"{fam} -> K {chosen[fam][-1][0]}, beta {chosen[fam][-1][1]}" for fam in FAMILIES), flush=True)
    return chosen, table, float(np.mean(dev_base))


def fire_summary(fire, rel, nref, chat, K_of, bound_mult=2):
    """fire, rel, nref, chat: per (alias, visit) pair; K_of: per pair K. Unrelated pairs only for the bound check."""
    un = ~rel
    bound = np.minimum(1.0, bound_mult * K_of / (nref + 1.0)); exact = np.minimum(1.0, K_of / (nref + 1.0))
    out = dict(pairs_unrelated=int(un.sum()), pairs_related=int(rel.sum()),
               rate_unrelated=float(fire[un].mean()), bound_2K=float(bound[un].mean()), bound_K=float(exact[un].mean()),
               rate_all=float(fire.mean()), bound_K_all=float(exact.mean()),
               rate_related=float(fire[rel].mean()) if rel.any() else None)
    d, ci = C.cluster_boot(fire[un].astype(np.float64) - bound[un], chat[un])
    out["unrelated_minus_bound_2K"] = [round(d, 4), [round(x, 4) for x in ci]]
    d, ci = C.cluster_boot(fire.astype(np.float64) - exact, chat)
    out["all_minus_bound_K"] = [round(d, 4), [round(x, 4) for x in ci]]
    bins = []
    for lo, hi in BINS:
        lo_eff = K_of if lo is None else lo
        m = un & (nref >= lo_eff) & (nref < hi)
        if m.any():
            bins.append(dict(n_ref=f"[{'K' if lo is None else lo},{'inf' if hi > 10 ** 8 else hi})", pairs=int(m.sum()),
                             rate=round(float(fire[m].mean()), 4), bound_2K=round(float(bound[m].mean()), 4),
                             bound_K=round(float(exact[m].mean()), 4),
                             judged=bool(m.sum() >= MIN_BIN), within=bool(fire[m].mean() <= bound[m].mean())))
    out["bins"] = bins
    for k in ("rate_unrelated", "bound_2K", "bound_K", "rate_all", "bound_K_all", "rate_related"):
        if out[k] is not None:
            out[k] = round(out[k], 4)
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--out", default=os.path.join(HERE, "results", "s17_alias.json"))
    a = p.parse_args()
    torch.set_num_threads(1); t0 = time.time()
    R = Reader(with_lme=False); chats = R.chats
    picks = json.load(open(os.path.join(HERE, "results", "s11_rank.json")))["picks"]["r16"]
    print(f"loaded {len(chats)} chats, {sum(len(c['qs']) for c in chats)} questions; rank-16 lr picks {picks}", flush=True)

    # ---- dev tuning (training chats only)
    chosen, dev_table, dev_base = dev_tune(chats, picks, t0)

    # ---- test streams on the held-out chats
    arms = ["F3", "SU-key", "F5", "SU-state", "F3 fixed"]
    per = {m: collections.defaultdict(list) for m in ("dense", "fused")}
    chat_of, cat_of = [], []
    fires = {arm: collections.defaultdict(list) for arm in arms}
    pos_gain = collections.defaultdict(lambda: np.zeros((3, 2)))
    for i, ch in enumerate(chats):
        f = i // 2; K0, S = R.keys[i]; br = R.bridges[f]; AV = br.key_np(ch["asks"])
        tr = [j for j in range(10) if j not in C.FOLDS[f]]
        refs = np.concatenate([br.views(chats[j]["nodes"], chats[j]["asks"])[1] for j in tr])
        P = prep(K0, S, AV, refs, ch["qs"], ch["lexorder"]); nq = P["nq"]
        base_d = np.array([C.recall(C.order_of(P["base"][r]), q[1]) for r, q in enumerate(ch["qs"])])
        base_f = np.array([C.recall(C.fuse(ch["lexorder"][r], C.order_of(P["base"][r])), q[1]) for r, q in enumerate(ch["qs"])])
        per["dense"]["none"] += base_d.tolist(); per["fused"]["none"] += base_f.tolist()
        chat_of += [i] * nq; cat_of += [q[2] for q in ch["qs"]]
        orders = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(ORDERS)]
        sums = {arm: (np.zeros(nq), np.zeros(nq)) for arm in arms}
        for order in orders:
            third = np.empty(nq, int); third[order] = np.arange(nq) * 3 // nq
            for fam in FAMILIES:
                sets = [chosen[fam][f]] + ([(10, 1.0)] if fam == "F3" and (10, 1.0) != chosen[fam][f] else [])
                d, fu, rec = stream(P, order, fam, sets, fused=True, fires=True)
                todo = [(fam, chosen[fam][f])] + ([("F3 fixed", (10, 1.0))] if fam == "F3" else [])
                for arm, s in todo:
                    sums[arm][0][:] += d[s] / ORDERS; sums[arm][1][:] += fu[s] / ORDERS
                    K = s[0]
                    for k in ("fire", "rel", "nref"):
                        fires[arm][k].append(rec[K][k])
                    fires[arm]["chat"].append(np.full(len(rec[K]["fire"]), i)); fires[arm]["K"].append(np.full(len(rec[K]["fire"]), K))
                    for k in range(3):
                        g = (d[s] - base_d)[third == k]; pos_gain[arm][k] += (g.sum(), len(g))
        for arm in arms:
            per["dense"][arm] += sums[arm][0].tolist(); per["fused"][arm] += sums[arm][1].tolist()
        print(f"chat {i} (fold {f}) done ({time.time() - t0:.0f}s): "
              + "  ".join(f"{arm} {sums[arm][0].mean() - base_d.mean():+.4f}" for arm in arms), flush=True)

    # ---------------------------------------------------------------- report
    chat_of = np.array(chat_of); cat_of = np.array(cat_of)
    V = {m: {arm: np.array(v) for arm, v in per[m].items()} for m in per}
    b_d, b_f = V["dense"]["none"], V["fused"]["none"]
    out = dict(check="1.7 / P6 same-user alias calibration", n_questions=int(len(chat_of)), orders=ORDERS,
               families={k: {kk: vv for kk, vv in v.items()} for k, v in FAMILIES.items()}, betas=BETAS,
               chosen={fam: [dict(K=s[0], beta=s[1]) for s in chosen[fam]] for fam in FAMILIES},
               dev=dict(no_learning=round(dev_base, 4), table=dev_table),
               baseline=dict(dense=round(float(b_d.mean()), 4), fused=round(float(b_f.mean()), 4),
                             dense_multi_hop=round(float(b_d[cat_of == 1].mean()), 4)))
    out["baseline_matches_s12"] = bool(abs(b_d.mean() - 0.6622) < 6e-5 and abs(b_f.mean() - 0.6553) < 6e-5)
    out["arms"] = {}
    for arm in arms:
        vd, vf = V["dense"][arm], V["fused"][arm]
        dd, cd = C.cluster_boot(vd - b_d, chat_of); df, cf = C.cluster_boot(vf - b_f, chat_of)
        per_chat = [round(float((vd - b_d)[chat_of == j].mean()), 4) for j in range(10)]
        pg = pos_gain[arm][:, 0] / pos_gain[arm][:, 1]
        out["arms"][arm] = dict(dense=round(float(vd.mean()), 4), gain=round(dd, 4), ci=[round(x, 4) for x in cd],
                                fused=round(float(vf.mean()), 4), fused_gain=round(df, 4), fused_ci=[round(x, 4) for x in cf],
                                multi_hop_gain=round(float((vd - b_d)[cat_of == 1].mean()), 4),
                                gain_by_cat={C.CATS[k]: round(float((vd - b_d)[cat_of == k].mean()), 4) for k in C.CATS},
                                chats_up=int(sum(x > 0 for x in per_chat)), per_chat=per_chat,
                                gain_by_visit_third=[round(float(x), 4) for x in pg])
    cmp = {}
    for x, y in (("SU-key", "F3"), ("SU-key", "F3 fixed"), ("SU-key", "F5"), ("SU-key", "SU-state"), ("F5", "F3")):
        dd, cd = C.cluster_boot(V["dense"][x] - V["dense"][y], chat_of)
        df, cf = C.cluster_boot(V["fused"][x] - V["fused"][y], chat_of)
        per_chat = [round(float((V["dense"][x] - V["dense"][y])[chat_of == j].mean()), 4) for j in range(10)]
        cmp[f"{x} - {y}"] = dict(dense=round(dd, 4), ci=[round(v, 4) for v in cd], fused=round(df, 4),
                                 fused_ci=[round(v, 4) for v in cf], chats_up=int(sum(v > 0 for v in per_chat)),
                                 per_chat=per_chat,
                                 multi_hop=round(float((V["dense"][x] - V["dense"][y])[cat_of == 1].mean()), 4))
    out["comparisons"] = cmp
    out["fire"] = {}
    for arm in arms:
        Fr = {k: np.concatenate(v) for k, v in fires[arm].items()}
        out["fire"][arm] = fire_summary(Fr["fire"].astype(bool), Fr["rel"].astype(bool), Fr["nref"].astype(np.float64),
                                        Fr["chat"], Fr["K"].astype(np.float64))
        if FAMILIES.get(arm, FAMILIES["F3"])["refs"] == "train+chat":
            out["fire"][arm]["note"] = "references include training chats (not exchangeable); n_ref counts them"

    # ---- verdict, mechanical
    fs = out["fire"]["SU-key"]
    bins_ok = all(b["within"] for b in fs["bins"] if b["judged"])
    A = bool(fs["rate_unrelated"] <= fs["bound_2K"] and bins_ok)
    B = bool(cmp["SU-key - F3"]["dense"] > 0)
    out["verdict"] = dict(
        A_fire_rate_within_2K_bound=A, A_detail=dict(rate=fs["rate_unrelated"], bound=fs["bound_2K"], bins_ok=bins_ok),
        B_beats_F3=B, B_detail=dict(diff=cmp["SU-key - F3"]["dense"], ci=cmp["SU-key - F3"]["ci"],
                                    ci_excludes_zero=bool(cmp["SU-key - F3"]["ci"][0] > 0 or cmp["SU-key - F3"]["ci"][1] < 0)),
        su_key_gain_above_old_F3_0_029=bool(out["arms"]["SU-key"]["gain"] > OLD_F3),
        result="pass" if (A and B) else "fail")
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump(out, open(a.out, "w"), indent=1)

    print(f"\nbaseline dense {out['baseline']['dense']:.4f} fused {out['baseline']['fused']:.4f} "
          f"(matches s12: {out['baseline_matches_s12']}); dev no-learning {dev_base:.4f}")
    print("chosen per fold:", json.dumps(out["chosen"]))
    for arm, r in out["arms"].items():
        print(f"  {arm:<9} dense {r['dense']:.4f} gain {r['gain']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused "
              f"{r['fused_gain']:+.4f} [{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  mh {r['multi_hop_gain']:+.4f}  "
              f"chats up {r['chats_up']}/10  by visit third {r['gain_by_visit_third']}")
    for k, r in cmp.items():
        print(f"  {k:<20} dense {r['dense']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused {r['fused']:+.4f} "
              f"[{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  chats up {r['chats_up']}/10  per chat {r['per_chat']}")
    for arm, r in out["fire"].items():
        print(f"  fire {arm:<9} unrelated {r['rate_unrelated']:.4f} (bound 2K/(n+1) {r['bound_2K']:.4f}, K/(n+1) {r['bound_K']:.4f}, "
              f"{r['pairs_unrelated']} pairs)  all {r['rate_all']:.4f} vs K/(n+1) {r['bound_K_all']:.4f}  related {r['rate_related']}")
        for b in r["bins"]:
            print(f"      n_ref {b['n_ref']:<10} pairs {b['pairs']:>7} rate {b['rate']:.4f} bound2K {b['bound_2K']:.4f} "
                  f"boundK {b['bound_K']:.4f} judged {b['judged']} within {b['within']}")
    print(json.dumps(out["verdict"], indent=1))
    print(f"{out['seconds']} s")


if __name__ == "__main__":
    main()
