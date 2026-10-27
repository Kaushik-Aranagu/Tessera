"""Why the mean of children is a poor parent key (section A3): LoCoMo sessions as parents, turns as children.

Per session P with m children x_i (unit vectors): mean pairwise cosine rho_c, |xbar| against the exact identity
|xbar|^2 = 1/m + (1 - 1/m) rho_c. Routing an ask q to its evidence session(s), parent score by
  mean     cos(q, xbar)                     (the parent key = normalised mean of children)
  attn     cos(q, sum_i alpha_i x_i), alpha = softmax(w . x_i)  (query-independent learned pool, w trained per fold)
  lse      T log mean_i exp(<q,x_i>/T), T = 0.05   (query-dependent soft max)
  max      max_i <q, x_i>
  bm25     BM25 over the session's concatenated turns
Detectability d' = (score of the evidence session - mean of other sessions) / sd of other sessions, for asks with one
evidence session, compared with the variance-components prediction for the mean pool:
  d'_mean ~= (Delta/m) / sqrt(tau^2 + sigma^2/m), Delta = evidence-child score - session mean of child scores,
  tau^2 = between-session variance of session-mean scores, sigma^2 = within-session variance of child scores.
"""
import json, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
sys.path.insert(0, "/tmp/claude-0/math/theory")
from e5_bridges import bm25_rank, tokens  # noqa: E402
from common import bridges, chats  # noqa: E402

torch.set_num_threads(1)


def sessions(c):
    sid = [d.split(":")[0] for d in c["ids"]]
    names = list(dict.fromkeys(sid))
    return [[i for i, s in enumerate(sid) if s == n] for n in names], {i: names.index(s) for i, s in enumerate(sid)}


def train_attn(train_chats, view, epochs=60, seed=0):
    torch.manual_seed(seed)
    w = torch.zeros(384, requires_grad=True)
    opt = torch.optim.Adam([w], lr=1e-2)
    data = []
    for c in train_chats:
        X, S = view(c)
        sess, of = sessions(c)
        tgt = [sorted({of[e] for e in q[1]}) for q in c["qs"]]
        data.append((torch.tensor(X), torch.tensor(S), sess, tgt))
    for _ in range(epochs):
        for X, S, sess, tgt in data:
            P = []
            for ch in sess:
                a = torch.softmax(X[ch] @ w, 0)
                P.append(torch.nn.functional.normalize((a[:, None] * X[ch]).sum(0), dim=0))
            P = torch.stack(P)
            logits = 20 * S @ P.T
            pos = torch.zeros_like(logits)
            for r, t in enumerate(tgt):
                pos[r, t] = 1 / len(t)
            loss = -(pos * logits.log_softmax(1)).sum(1).mean()
            opt.zero_grad(); loss.backward(); opt.step()
    return w.detach().numpy()


def analyse(c, X, S, w):
    sess, of = sessions(c)
    m = np.array([len(ch) for ch in sess])
    G = X @ X.T
    rho_c = np.array([(G[np.ix_(ch, ch)].sum() - len(ch)) / (len(ch) * (len(ch) - 1)) for ch in sess])
    xbar = np.array([X[ch].mean(0) for ch in sess])
    nrm = np.linalg.norm(xbar, axis=1)
    pred = np.sqrt(1 / m + (1 - 1 / m) * rho_c)
    P = xbar / nrm[:, None]
    cosP = P @ P.T
    off = ~np.eye(len(sess), dtype=bool)
    turn_cross = np.mean([G[np.ix_(a, b)].mean() for ia, a in enumerate(sess) for ib, b in enumerate(sess) if ia != ib])
    att = []
    for ch in sess:
        a = np.exp(X[ch] @ w - (X[ch] @ w).max()); a /= a.sum()
        v = (a[:, None] * X[ch]).sum(0); att.append(v / np.linalg.norm(v))
    att = np.array(att)
    meff = np.mean([1 / np.sum((lambda a: a / a.sum())(np.exp(X[ch] @ w - (X[ch] @ w).max())) ** 2) / len(ch) for ch in sess])
    docs = {j: sum((tokens(c["text"][c["ids"][i]]) for i in ch), []) for j, ch in enumerate(sess)}
    out = dict(rec={k: {1: [], 3: []} for k in ("mean", "attn", "lse", "max", "bm25")}, dprime={k: [] for k in ("leaf", "mean", "attn", "lse", "max")},
               dpred=[], dcat=[], m=m.tolist(), rho_c=rho_c.tolist(), nrm=nrm.tolist(), nrm_pred=pred.tolist(),
               cosP=float(cosP[off].mean()), turn_cross=float(turn_cross), meff_frac=float(meff))
    for r, (q, ev, cat) in enumerate(c["qs"]):
        s = S[r]
        ys = X @ s
        sc = dict(mean=P @ s, attn=att @ s, max=np.array([ys[ch].max() for ch in sess]),
                  lse=np.array([0.05 * np.log(np.mean(np.exp((ys[ch] - ys[ch].max()) / 0.05))) + ys[ch].max() for ch in sess]))
        order_bm = bm25_rank(docs, list(range(len(sess))), tokens(q))
        evs = sorted({of[e] for e in ev})
        for k in ("mean", "attn", "lse", "max", "bm25"):
            o = order_bm if k == "bm25" else list(np.argsort(-sc[k], kind="stable"))
            for kk in (1, 3):
                out["rec"][k][kk].append(len(set(o[:kk]) & set(evs)) / len(evs))
        if len(evs) == 1:
            j = evs[0]
            others = [t for t in range(len(sess)) if t != j]
            for k in ("mean", "attn", "lse", "max"):
                out["dprime"][k].append((sc[k][j] - sc[k][others].mean()) / sc[k][others].std())
            e = ev[0]
            rest = [t for t in range(len(X)) if t not in ev]
            out["dprime"]["leaf"].append((ys[e] - ys[rest].mean()) / ys[rest].std())
            smeans = np.array([ys[ch].mean() for ch in sess])
            tau2 = smeans[others].var()
            sig2 = np.mean([ys[ch].var() for ch in sess])
            delta = ys[e] - ys[sess[j]].mean()
            mj = len(sess[j])
            out["dpred"].append((delta / mj) / np.sqrt(tau2 + sig2 / mj))
            out["dcat"].append((cat, mj, out["dprime"]["leaf"][-1], out["dprime"]["mean"][-1], out["dprime"]["max"][-1], out["dprime"]["lse"][-1],
                                int(np.argmax(sc["mean"]) == j), int(np.argmax(sc["max"]) == j)))
    return out


def main():
    C, B = chats(), bridges()
    agg = {}
    for space in ("frozen", "bridge"):
        rows = []
        for fold in range(5):
            test = (2 * fold, 2 * fold + 1)
            if space == "frozen":
                view = lambda c, i=None: (c["nodes"], c["asks"])
                tv = {i: (C[i]["nodes"], C[i]["asks"]) for i in test}
                trv = lambda c: (c["nodes"], c["asks"])
            else:
                tv = {i: (B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"]) for i in test}
                idx = {id(C[j]): j for j in range(10)}
                trv = lambda c, fold=fold: (B[f"f{fold}_k{idx[id(c)]}"], B[f"f{fold}_s{idx[id(c)]}"])
            w = train_attn([C[j] for j in range(10) if j not in test], trv, seed=fold)
            for i in test:
                rows.append(analyse(C[i], *tv[i], w))
        m = np.concatenate([r["m"] for r in rows]); rc = np.concatenate([r["rho_c"] for r in rows])
        nr = np.concatenate([r["nrm"] for r in rows]); npred = np.concatenate([r["nrm_pred"] for r in rows])
        res = dict(m_mean=float(m.mean()), rho_c=float(rc.mean()), nrm=float(nr.mean()), nrm_pred=float(npred.mean()),
                   nrm_maxabs_err=float(np.abs(nr - npred).max()), cos_between_parents=float(np.mean([r["cosP"] for r in rows])),
                   cos_between_turns_of_diff_sessions=float(np.mean([r["turn_cross"] for r in rows])),
                   attn_meff_frac=float(np.mean([r["meff_frac"] for r in rows])))
        for k in ("mean", "attn", "lse", "max", "bm25"):
            res[f"rec1_{k}"] = float(np.mean(sum((r["rec"][k][1] for r in rows), [])))
            res[f"rec3_{k}"] = float(np.mean(sum((r["rec"][k][3] for r in rows), [])))
        for k in ("leaf", "mean", "attn", "lse", "max"):
            res[f"dprime_{k}"] = float(np.mean(sum((r["dprime"][k] for r in rows), [])))
        res["dprime_mean_pred"] = float(np.mean(sum((r["dpred"] for r in rows), [])))
        dc = np.array(sum((r["dcat"] for r in rows), []), dtype=float)
        res["by_cat"] = {}
        for k, nm in ((1, "multi-hop"), (2, "when"), (3, "inference"), (4, "single-hop")):
            sel = dc[:, 0] == k
            res["by_cat"][nm] = dict(n=int(sel.sum()), leaf=dc[sel, 2].mean(), mean=dc[sel, 3].mean(), max=dc[sel, 4].mean(), lse=dc[sel, 5].mean(),
                                     hit1_mean=dc[sel, 6].mean(), hit1_max=dc[sel, 7].mean())
        res["by_m"] = {}
        for lo, hi in ((0, 17), (17, 22), (22, 27), (27, 100)):
            sel = (dc[:, 1] >= lo) & (dc[:, 1] < hi)
            res["by_m"][f"{lo}-{hi - 1}"] = dict(n=int(sel.sum()), leaf=dc[sel, 2].mean(), mean=dc[sel, 3].mean(), max=dc[sel, 4].mean(),
                                                 ratio_mean=dc[sel, 3].mean() / dc[sel, 2].mean(), ratio_max=dc[sel, 4].mean() / dc[sel, 2].mean())
        print("   d' by category (n, leaf/mean/max/lse, hit@1 mean/max): " + "; ".join(
            f"{k} {v['n']} {v['leaf']:.2f}/{v['mean']:.2f}/{v['max']:.2f}/{v['lse']:.2f} {v['hit1_mean']:.2f}/{v['hit1_max']:.2f}" for k, v in res["by_cat"].items()))
        print("   d' by evidence-session size m (n, leaf/mean/max, mean/leaf, max/leaf): " + "; ".join(
            f"m {k}: {v['n']} {v['leaf']:.2f}/{v['mean']:.2f}/{v['max']:.2f} {v['ratio_mean']:.2f} {v['ratio_max']:.2f}" for k, v in res["by_m"].items()))
        agg[space] = res
        print(f"{space}: {len(m)} sessions, mean m {m.mean():.1f}, mean child-child cos {rc.mean():.3f}, |xbar| {nr.mean():.3f} "
              f"(identity {npred.mean():.3f}, max abs err {np.abs(nr - npred).max():.1e}); cos between parent keys {res['cos_between_parents']:.3f} "
              f"vs between turns of different sessions {res['cos_between_turns_of_diff_sessions']:.3f}")
        print("   session recall@1 / @3: " + "  ".join(f"{k} {res[f'rec1_{k}']:.3f}/{res[f'rec3_{k}']:.3f}" for k in ("mean", "attn", "lse", "max", "bm25")))
        print("   d' (one-evidence-session asks): " + "  ".join(f"{k} {res[f'dprime_{k}']:.2f}" for k in ("leaf", "mean", "attn", "lse", "max"))
              + f"  | variance-components prediction for mean {res['dprime_mean_pred']:.2f}; attention participation ratio m_eff/m {res['attn_meff_frac']:.2f}")
    json.dump(agg, open("/tmp/claude-0/math/theory/pool.json", "w"), indent=1)


if __name__ == "__main__":
    main()
