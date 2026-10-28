#!/usr/bin/env python3
"""Post hoc, exploratory (NOT pre-registered): the stage 1.2 rules on Haiku's real cites, with the key-view target
n(A e_q) that passed test 1.4 (P2) in place of the state-view target s_q.

Written after s12_cites.py and s14_keyview.py results were seen, so any gain here is a lead for a fresh test, not a result.
Same protocol, cites, orders and statistics as s12_cites.py (imports its pieces). Centred variants subtract the mean
key-view question vector of the fold's training chats (frozen per bridge version).
Usage: python s12b_keyview_cites.py
"""
import collections, json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
from retrieval import Reader  # noqa: E402

RULES = {
    "move→key η0.1": dict(eta=0.1),
    "move→key η0.05": dict(eta=0.05),
    "centred→key": dict(eta=0.1, c=1.0),
    "combo→key": dict(eta=0.1, c=1.0, eta_neg=0.02),
}
CONDS = ("haiku", "visible", "clean", "self")


def run_order(K0, S, T, lexorder, qs, cites, opened, order, cfg, mu):
    """As s12_cites.run_order, but the pull and push direction is built from T[r] (key view) instead of S[r]."""
    keys = K0.copy(); dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    eta, c, neg = cfg.get("eta", 0.0), cfg.get("c", 0.0), cfg.get("eta_neg", 0.0)
    for r in order:
        top = C.order_of(keys @ S[r])
        dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        if not eta:
            continue
        cited = [int(top[0])] if cites[r] is None else cites[r]
        d = S12.unit1(T[r] - c * mu) if c else T[r]
        for v in cited:
            keys[v] = S12.unit1(keys[v] + eta * (d - keys[v]))
        if neg:
            for u in opened[r]:
                if u not in cited:
                    keys[u] = S12.unit1(keys[u] - neg * d)
    return dense, fused


def main():
    R = Reader(with_lme=False)
    tasks = {t["id"]: t for t in S12.read(os.path.join(HERE, "runs", "tasks_hop0.jsonl.gz"))}
    reads = {r["id"]: r for r in S12.read(os.path.join(HERE, "runs", "answers_hop0.jsonl"))
             if r["kind"] == "read" and "error" not in r}
    rows = collections.defaultdict(list); base = {"dense": [], "fused": []}; chat_of = []; cat_of = []
    for i, ch in enumerate(R.chats):
        K0, S = R.keys[i]; f = i // 2; br = R.bridges[f]
        T = br.key_np(ch["asks"]).astype(np.float32)
        tr = [j for j in range(10) if j not in C.FOLDS[f]]
        mu = np.concatenate([br.key_np(R.chats[j]["asks"]) for j in tr]).mean(0)
        nq = len(ch["qs"]); opened, cites = [], {c: [] for c in CONDS}
        for r in range(nq):
            task = tasks[f"locomo:{i}:{r}"]; rd = reads.get(f"locomo:{i}:{r}")
            node = {s["n"]: s["node"] for s in task["snippets"]}; op = list(node.values()); opened.append(op)
            cites["haiku"].append([node[n] for n in rd["cites"] if n in node] if rd else [])
            ev = ch["qs"][r][1]
            cites["visible"].append([v for v in ev if v in set(op)]); cites["clean"].append(list(ev)); cites["self"].append(None)
        orders = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(S12.ORDERS)]
        d0 = np.zeros(nq); f0 = np.zeros(nq)
        for order in orders:
            d, fu = run_order(K0, S, T, ch["lexorder"], ch["qs"], cites["clean"], opened, order, {}, mu)
            d0 += d / S12.ORDERS; f0 += fu / S12.ORDERS
        base["dense"] += d0.tolist(); base["fused"] += f0.tolist(); chat_of += [i] * nq; cat_of += [q[2] for q in ch["qs"]]
        for rule, cfg in RULES.items():
            for cond in CONDS:
                dd = np.zeros(nq); ff = np.zeros(nq)
                for order in orders:
                    d, fu = run_order(K0, S, T, ch["lexorder"], ch["qs"], cites[cond], opened, order, cfg, mu)
                    dd += d / S12.ORDERS; ff += fu / S12.ORDERS
                rows[(rule, cond, "dense")] += dd.tolist(); rows[(rule, cond, "fused")] += ff.tolist()
    chat_of = np.array(chat_of); cat_of = np.array(cat_of); b_d = np.array(base["dense"]); b_f = np.array(base["fused"])
    out = {"note": "post hoc, exploratory", "baseline": dict(dense=round(float(b_d.mean()), 4), fused=round(float(b_f.mean()), 4)), "rules": {}}
    for rule in RULES:
        for cond in CONDS:
            v_d = np.array(rows[(rule, cond, "dense")]); v_f = np.array(rows[(rule, cond, "fused")])
            dd, cd = C.cluster_boot(v_d - b_d, chat_of); df, cf = C.cluster_boot(v_f - b_f, chat_of)
            per_chat = [float((v_d - b_d)[chat_of == j].mean()) for j in range(10)]
            out["rules"][f"{rule} | {cond}"] = dict(gain=round(dd, 4), ci=[round(x, 4) for x in cd], fused_gain=round(df, 4),
                                                    fused_ci=[round(x, 4) for x in cf],
                                                    multi_hop_gain=round(float((v_d - b_d)[cat_of == 1].mean()), 4),
                                                    chats_up=sum(x > 0 for x in per_chat))
            r = out["rules"][f"{rule} | {cond}"]
            print(f"  {rule + ' | ' + cond:<26} gain {r['gain']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused {r['fused_gain']:+.4f} "
                  f"[{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  mh {r['multi_hop_gain']:+.4f}  chats up {r['chats_up']}/10")
    json.dump(out, open(os.path.join(HERE, "results", "s12b_keyview_cites.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
