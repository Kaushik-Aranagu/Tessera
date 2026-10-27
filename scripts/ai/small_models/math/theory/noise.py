"""Check of the noisy-feedback analysis (section A1) on LoCoMo held-out chats, rank-16 bridges, e6 protocol.

Replays e6's memory-plane learning (3 visit orders per test chat, same permutations as e6) with common random
numbers across cite conditions, for several step sizes eta, and decomposes the recall change by visit type:
  related   the visited ask shares an evidence node with an EARLIER visited ask (a re-ask)
  unrelated no evidence overlap with any earlier ask (any change here is intrusion = the hub cost H)
Also measures the per-update margin change of the correct node on re-ask pairs (exact and first order).
"""
import json, sys, time
import numpy as np

sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats, folds, orders, recall, topk, unit  # noqa: E402

K = 10


def replay(K0, S, qs, order, cond, eta, rule, mu_train, U, V):
    keys = K0.copy()
    seen_ev, seen_s = set(), []
    rows = []
    n_ok = n_wrong = 0
    win = {}
    for t, r in enumerate(order):
        ev = qs[r][1]
        sc = keys @ S[r]
        top = topk(sc, 11)
        base_top = topk(K0 @ S[r], K)
        rec = recall(top, ev)
        rec0 = recall(base_top, ev)
        related = bool(set(ev) & seen_ev)
        newfp = len([v for v in top[:K] if v not in set(base_top) and v not in ev])
        rows.append((t, rec, rec0, related, newfp))
        win[int(top[0])] = win.get(int(top[0]), 0) + 1
        if cond == "self":
            cited = [int(top[0])]
        elif cond == "visible":
            cited = [v for v in ev if v in set(top[:K])]
        else:
            wrong = [int(v) for v in top[:K] if v not in ev]
            cited = [wrong[int(V[r, j] * len(wrong))] if (wrong and U[r, j] < cond) else v for j, v in enumerate(ev)]
        seen_s.append(S[r])
        for v in cited:
            if v in ev:
                n_ok += 1
            else:
                n_wrong += 1
            if rule == "move":
                tgt = S[r]
            elif rule == "centered":
                mu = (10 * mu_train + np.sum(seen_s, 0)) / (10 + len(seen_s))
                tgt = unit(S[r] - mu)
            keys[v] = unit(keys[v] + eta * (tgt - keys[v]))
        seen_ev |= set(ev)
    return rows, n_ok, n_wrong, win


def margin_pairs(K0, S, qs, eta):
    """Exact and first-order change of m_q(e) = <k_e,q> - theta_K(q,e) for one update made at ask s (re-ask pairs)."""
    out = []
    for i1, (_, ev1, _) in enumerate(qs):
        s = S[i1]
        sc_s = K0 @ s
        top_s = topk(sc_s, K + len(ev1))
        wrong = [int(v) for v in top_s if v not in ev1][:K]
        for i2, (_, ev2, _) in enumerate(qs):
            if i2 == i1:
                continue
            shared = set(ev1) & set(ev2)
            if not shared:
                continue
            q = S[i2]
            scq = K0 @ q
            for e in shared:
                others = np.delete(scq, e)
                theta = np.sort(others)[-K]
                m0 = scq[e] - theta
                ke = unit(K0[e] + eta * (s - K0[e]))
                dm_c = ke @ q - scq[e]
                a, c, rho = K0[e] @ q, K0[e] @ s, s @ q
                fo = eta * (rho - a * c)
                dms = []
                for d in wrong:
                    kd = unit(K0[d] + eta * (s - K0[d]))
                    sq2 = scq.copy(); sq2[d] = kd @ q
                    th2 = np.sort(np.delete(sq2, e))[-K]
                    dms.append(-(th2 - theta))
                out.append((m0, dm_c, fo, float(np.mean(dms)) if dms else 0.0, rho, a, c))
    return np.array(out)


def main():
    t0 = time.time()
    C, B = chats(), bridges()
    etas = (0.02, 0.05, 0.1, 0.2)
    conds = (0.0, 0.3, 0.6, 1.0, "self", "visible")
    res = {}
    per = {}
    wins_all = {}
    for fold, i in folds():
        c = C[i]
        K0, S = B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"]
        mu_train = np.mean(np.concatenate([B[f"f{fold}_s{j}"] for j in range(10) if j not in (2 * fold, 2 * fold + 1)]), 0)
        nq = len(c["qs"])
        maxev = max(len(q[1]) for q in c["qs"])
        for o, order in enumerate(orders(fold, i, nq)):
            g = np.random.default_rng(7000 + 100 * fold + 10 * i + o)
            U, V = g.random((nq, maxev)), g.random((nq, maxev))
            runs = [(eta, "move", cd) for eta in etas for cd in conds] + [(0.1, "centered", cd) for cd in conds]
            for eta, rule, cd in runs:
                rows, ok, wr, win = replay(K0, S, c["qs"], order, cd, eta, rule, mu_train, U, V)
                key = f"{rule} eta={eta} cites={cd}"
                per.setdefault(key, []).extend(rows)
                r = res.setdefault(key, dict(ok=0, wrong=0))
                r["ok"] += ok; r["wrong"] += wr
                if cd == "self" and eta == 0.1:
                    wins_all.setdefault(rule, []).append(sorted(win.values(), reverse=True))
    rng = np.random.default_rng(0)
    summary = {}
    for key, rows in per.items():
        a = np.array(rows, dtype=float)
        d = a[:, 1] - a[:, 2]
        rel = a[:, 3] > 0
        boots = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(500)]
        thirds = [d[(a[:, 0] >= lo) & (a[:, 0] < hi)].mean() for lo, hi in ((0, 50), (50, 100), (100, 1e9))]
        summary[key] = dict(n=len(d), base=a[:, 2].mean(), learned=a[:, 1].mean(), delta=d.mean(),
                            ci=[float(np.percentile(boots, 2.5)), float(np.percentile(boots, 97.5))],
                            frac_related=rel.mean(), d_related=d[rel].mean(), d_unrelated=d[~rel].mean(),
                            contrib_related=d[rel].sum() / len(d), contrib_unrelated=d[~rel].sum() / len(d),
                            newfp=a[:, 4].mean(), newfp_unrel=a[~rel, 4].mean(), by_position=thirds, **res[key])
    print(f"{summary['move eta=0.1 cites=0.0']['n']} visits, baseline recall@10 {summary['move eta=0.1 cites=0.0']['base']:.3f}")
    print(f"share of visits that are re-asks (related): {summary['move eta=0.1 cites=0.0']['frac_related']:.3f}")
    hdr = "  {:<30} {:>7} {:>16} {:>9} {:>9} {:>9} {:>6} {:>11}  {}"
    print(hdr.format("arm", "delta", "95% CI", "rel-part", "unrel-pt", "d|unrel", "newFP", "ok/wrong", "delta by visit position <50/50-99/100+"))
    for key, s in summary.items():
        print(hdr.format(key, f"{s['delta']:+.4f}", f"[{s['ci'][0]:+.3f},{s['ci'][1]:+.3f}]", f"{s['contrib_related']:+.4f}",
                         f"{s['contrib_unrelated']:+.4f}", f"{s['d_unrelated']:+.4f}", f"{s['newfp']:.2f}",
                         f"{s['ok']}/{s['wrong']}", " ".join(f"{x:+.3f}" for x in s["by_position"])))
    # fits
    fits = {}
    print("\nLinear model Delta(p) = alpha - beta p (least squares on p = 0, 0.3, 0.6), and endpoint model (p = 0, 1 only)")
    for eta in etas:
        ps = np.array([0.0, 0.3, 0.6])
        ys = np.array([summary[f"move eta={eta} cites={p}"]["delta"] for p in ps])
        A = np.vstack([np.ones(3), -ps]).T
        (al, be), *_ = np.linalg.lstsq(A, ys, rcond=None)
        pred = al - be * ps
        ss = ((ys - pred) ** 2).sum(); st = ((ys - ys.mean()) ** 2).sum()
        y0, y1 = summary[f"move eta={eta} cites=0.0"]["delta"], summary[f"move eta={eta} cites=1.0"]["delta"]
        endpoint = [y0 + p * (y1 - y0) for p in (0.3, 0.6)]
        # self prediction from per-cite endpoint components
        sf = summary[f"move eta={eta} cites=self"]
        n_clean = summary[f"move eta={eta} cites=0.0"]["ok"]
        p_self = sf["wrong"] / (sf["ok"] + sf["wrong"])
        self_pred = (sf["ok"] + sf["wrong"]) / n_clean * (y0 + p_self * (y1 - y0))
        self_pred_lin = (sf["ok"] + sf["wrong"]) / n_clean * (al - be * p_self)
        fits[eta] = dict(alpha=al, beta=be, p_star=al / be, r2=1 - ss / st, endpoint_pred=endpoint,
                         measured=[float(y) for y in ys], p1=y1, p_star_endpoint=y0 / (y0 - y1),
                         p_self=p_self, self_pred_endpoint=self_pred, self_pred_linfit=self_pred_lin, self_meas=sf["delta"])
        print(f"  eta {eta:<5} alpha {al:+.4f} beta {be:.4f} p*={al / be:.3f} R2={1 - ss / st:.3f} | measured p=.3,.6: "
              f"{ys[1]:+.4f} {ys[2]:+.4f}; endpoint-model prediction {endpoint[0]:+.4f} {endpoint[1]:+.4f}; p*(endpoint)={y0 / (y0 - y1):.3f}"
              f" | self: p_self={p_self:.3f} predicted {self_pred:+.4f} (lin {self_pred_lin:+.4f}) measured {sf['delta']:+.4f}")
    ps = np.array([0.0, 0.3, 0.6])
    ys = np.array([summary[f"centered eta=0.1 cites={p}"]["delta"] for p in ps])
    A = np.vstack([np.ones(3), -ps]).T
    (al, be), *_ = np.linalg.lstsq(A, ys, rcond=None)
    fits["centered"] = dict(alpha=al, beta=be, p_star=al / be)
    print(f"  centered eta 0.1: alpha {al:+.4f} beta {be:.4f} p*={al / be:.3f}")
    # component decomposition B, D, H per cite event from p=0 and p=1, split by visit type
    print("\nComponents (sum over visits / visits), from the endpoint arms: B-H_e = related part at p=0 etc.")
    comp = {}
    for eta in etas:
        z, o = summary[f"move eta={eta} cites=0.0"], summary[f"move eta={eta} cites=1.0"]
        comp[eta] = dict(rel0=z["contrib_related"], unrel0=z["contrib_unrelated"], rel1=o["contrib_related"], unrel1=o["contrib_unrelated"])
        print(f"  eta {eta:<5} p=0: related {z['contrib_related']:+.4f} unrelated {z['contrib_unrelated']:+.4f} | "
              f"p=1: related {o['contrib_related']:+.4f} unrelated {o['contrib_unrelated']:+.4f}")
    # margin per update on re-ask pairs
    print("\nMargin change of the correct node per update, re-ask pairs (ask s and later ask q share evidence e)")
    marg = {}
    for eta in (0.02, 0.1):
        allm = []
        for fold, i in folds():
            allm.append(margin_pairs(B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"], C[i]["qs"], eta))
        m = np.concatenate(allm)
        m0, dmc, fo, dmw, rho, a, cc = m.T
        rel_err = np.abs(dmc - fo).mean() / np.abs(dmc).mean()
        pstar_m = dmc.mean() / (dmc.mean() - dmw.mean())
        near = np.abs(m0) < 0.05
        marg[eta] = dict(pairs=len(m), m0_mean=m0.mean(), frac_m0_neg=(m0 < 0).mean(), dm_correct=dmc.mean(),
                         dm_wrong=dmw.mean(), first_order=fo.mean(), rel_err_first_order=rel_err, p_star_margin=pstar_m,
                         rho=rho.mean(), a=a.mean(), c=cc.mean(), dm_correct_near=dmc[near].mean(), dm_wrong_near=dmw[near].mean(),
                         p_star_margin_near=dmc[near].mean() / (dmc[near].mean() - dmw[near].mean()))
        print(f"  eta {eta}: {len(m)} (s,q,e) triples; mean margin before {m0.mean():+.3f} ({(m0 < 0).mean():.2f} negative); "
              f"rho=<s,q> {rho.mean():.3f}, a=<k_e,q> {a.mean():.3f}, c=<k_e,s> {cc.mean():.3f}")
        print(f"    E[dm | correct] {dmc.mean():+.4f} (first order eta(rho - a c) {fo.mean():+.4f}, mean rel. error {rel_err:.3f}); "
              f"E[dm | wrong] {dmw.mean():+.4f};  margin break-even p*_m = {pstar_m:.3f}; near the boundary (|m|<.05): "
              f"{dmc[near].mean():+.4f} / {dmw[near].mean():+.4f} -> p*_m {marg[eta]['p_star_margin_near']:.3f}")
    # win concentration under self-feedback
    print("\nTop-1 win concentration under self-feedback (eta 0.1), mean over runs: share of visits won by the top node / top 5")
    conc = {}
    for rule, ws in wins_all.items():
        top1 = np.mean([w[0] / sum(w) for w in ws]); top5 = np.mean([sum(w[:5]) / sum(w) for w in ws])
        conc[rule] = dict(top1=top1, top5=top5)
        print(f"  {rule}: top-1 node {top1:.3f}, top-5 nodes {top5:.3f}")
    json.dump(dict(summary=summary, fits={str(k): v for k, v in fits.items()}, comp={str(k): v for k, v in comp.items()},
                   margin={str(k): v for k, v in marg.items()}, conc=conc), open("/tmp/claude-0/math/theory/noise.json", "w"),
              indent=1, default=float)
    print(f"done {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
