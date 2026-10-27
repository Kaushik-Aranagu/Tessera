"""Extra numbers: common-mode drift per clean update (move vs centered target), cites per node, Gaussian prediction of
the raw alias entry rate, and the per-update threshold-crossing count n_cross = (theta_10 - <k,mu>)/h."""
import sys, json
import numpy as np
from math import erf, sqrt
sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats, folds, unit
C, B = chats(), bridges()
drift_m, drift_c, cites, ent_pred, ent_n, gap = [], [], [], [], [], []
for fold, i in folds():
    K, S, qs = B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"], C[i]["qs"]
    mu = S.mean(0)
    cnt = np.zeros(len(K))
    for j, (_, ev, _) in enumerate(qs):
        s = S[j]; d = unit(s - mu)
        for e in ev:
            cnt[e] += 1
            drift_m.append(s @ mu - (K[e] @ s) * (K[e] @ mu))
            drift_c.append(d @ mu - (K[e] @ d) * (K[e] @ mu))
    cites.append(cnt[cnt > 0])
    G = S @ S.T
    ev = [set(q[1]) for q in qs]
    sc = S @ K.T
    th = np.sort(sc, 1)[:, -10]
    un = np.array([[not (ev[a] & ev[b]) and a != b for b in range(len(S))] for a in range(len(S))])
    m, sd = G[un].mean(), G[un].std()
    ent_pred.extend([0.5 * (1 - erf((t - m) / sd / sqrt(2))) for t in th])
    gap.extend(th - sc.mean(1))
c = np.concatenate(cites)
res = dict(drift_move=float(np.mean(drift_m)), drift_centered=float(np.mean(drift_c)), cites_per_cited_node=float(c.mean()),
           frac_nodes_ge2=float((c >= 2).mean()), frac_nodes_ge3=float((c >= 3).mean()), max_cites=float(c.max()),
           entry_pred_gauss=float(np.mean(ent_pred)), gap_theta_minus_mean=float(np.mean(gap)))
res["n_cross_eta01"] = res["gap_theta_minus_mean"] / (0.1 * res["drift_move"])
res["n_cross_eta002"] = res["gap_theta_minus_mean"] / (0.02 * res["drift_move"])
print(json.dumps(res, indent=1))
json.dump(res, open("/tmp/claude-0/math/theory/extra.json", "w"), indent=1)
