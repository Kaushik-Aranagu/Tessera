"""Hubness of alias keys (section A2): geometry and a static leave-one-out check on LoCoMo held-out chats.

Means: rho_ss = E<s,s'> over distinct asks of a chat, rho_sk = E<s,k> over asks x nodes, in the frozen bge space
and in the rank-16 bridge space (state head on asks, action head on nodes). Exact identities checked:
  E_{i!=j}<s_i,s_j> = (n |mu_s|^2 - 1)/(n - 1),   E<s,k> = <mu_s, mu_k>.
Static alias check: every node v gets as aliases the states of the OTHER asks that cite it (leave-one-out: an ask
never sees its own aliases); for each ask q we score
  keys      <k_v,q>
  raw       max(<k_v,q>, max_a <a,q>)                       (e6 'alias')
  csls      max(2<k_v,q> - r(k_v), max_a 2<a,q> - r(a))     r(x) = mean of x's 10 largest cosines with reference asks
  zmax      max(z_k, max_a z_a), each channel z-scored by its own mean and sd over the reference asks
  bonus     <k_v,q> + max(0, max_a (<a,q> - r(a)))          thresholded at the alias's own 10-NN level
Reference asks = the fold's 8 training chats' ask states (never the test chat). Reported: recall@10, skewness of the
10-occurrence N_10(v) = #asks with v in their top 10, and the entry rate = share of (alias, unrelated ask) pairs where
the alias channel alone beats the ask's 10th-best key.
"""
import json, sys
import numpy as np

sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats, folds, recall, topk  # noqa: E402


def skew(x):
    x = np.asarray(x, float)
    return ((x - x.mean()) ** 3).mean() / x.std() ** 3


def geometry(S, Kn, qs):
    n = len(S)
    G = S @ S.T
    ev = [set(q[1]) for q in qs]
    share = np.array([[bool(ev[i] & ev[j]) for j in range(n)] for i in range(n)])
    off = ~np.eye(n, dtype=bool)
    mus, muk = S.mean(0), Kn.mean(0)
    sk = S @ Kn.T
    own = np.mean([sk[i, list(q[1])].mean() for i, q in enumerate(qs)])
    th10 = np.mean(np.sort(sk, 1)[:, -10])
    return dict(ss_all=G[off].mean(), ss_identity=(n * mus @ mus - 1) / (n - 1), ss_unrel=G[off & ~share].mean(),
                ss_share=G[off & share].mean(), sk_all=sk.mean(), sk_identity=mus @ muk, s_own_ev=own, theta10=th10,
                mu_s=np.linalg.norm(mus), mu_k=np.linalg.norm(muk), cos_mus_muk=mus @ muk / np.linalg.norm(mus) / np.linalg.norm(muk),
                sd_ss_unrel=G[off & ~share].std(), sd_sk=sk.std())


def rK(X, ref, k=10):
    c = X @ ref.T
    return np.sort(c, 1)[:, -k:].mean(1)


def static_alias(Kn, S, qs, ref):
    n, N = len(S), len(Kn)
    ev = [list(q[1]) for q in qs]
    r_key = rK(Kn, ref)
    r_ask = rK(S, ref)
    ck = Kn @ ref.T; ca = S @ ref.T
    zk_mu, zk_sd = ck.mean(1), ck.std(1)
    za_mu, za_sd = ca.mean(1), ca.std(1)
    A = S @ S.T  # alias (ask j) to ask q cosines
    KS = Kn @ S.T  # node x ask
    out = {m: dict(rec=[], occ=np.zeros(N), intr=[]) for m in ("keys", "raw", "csls", "zmax", "bonus", "bonus_in")}
    entry, entry_bonus, entry_in = [], [], []
    shareq = [[bool(set(ev[j]) & set(ev[q])) for q in range(n)] for j in range(n)]
    owners = [[j for j in range(n) if v in set(ev[j])] for v in range(N)]
    for q in range(n):
        base = KS[:, q]
        th10 = np.sort(base)[-10]
        sc = {m: base.copy() for m in out}
        sc["csls"] = 2 * base - r_key
        sc["zmax"] = (base - zk_mu) / zk_sd
        keep = [j for j in range(n) if j != q]
        r_in = np.sort(A[:, keep], 1)[:, -11:-1].mean(1)  # each alias's 10-NN level among the OTHER in-chat asks (not q, not itself)
        for v in range(N):
            js = [j for j in owners[v] if j != q]
            if not js:
                continue
            al = A[js, q]
            sc["raw"][v] = max(base[v], al.max())
            sc["csls"][v] = max(sc["csls"][v], (2 * al - r_ask[js]).max())
            sc["zmax"][v] = max(sc["zmax"][v], ((al - za_mu[js]) / za_sd[js]).max())
            sc["bonus"][v] = base[v] + max(0.0, (al - r_ask[js]).max())
            sc["bonus_in"][v] = base[v] + max(0.0, (al - r_in[js]).max())
            for j, a in zip(js, al):
                if not shareq[j][q]:
                    entry.append(a > th10)
                    entry_bonus.append(a > r_ask[j])
                    entry_in.append(a > r_in[j])
        for m in out:
            t = topk(sc[m], 10)
            out[m]["rec"].append(recall(t, ev[q]))
            out[m]["occ"][t] += 1
            out[m]["intr"].append(sum(1 for v in t if v not in set(ev[q]) and any(j != q for j in owners[v])))
    return out, np.mean(entry), np.mean(entry_bonus), np.mean(entry_in)


def main():
    C, B = chats(), bridges()
    geo = {"frozen": [], "bridge": []}
    agg = {}
    ent = []
    for fold, i in folds():
        c = C[i]
        geo["frozen"].append(geometry(c["asks"], c["nodes"], c["qs"]))
        Kn, S = B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"]
        geo["bridge"].append(geometry(S, Kn, c["qs"]))
        ref = np.concatenate([B[f"f{fold}_s{j}"] for j in range(10) if j not in (2 * fold, 2 * fold + 1)])
        out, e_raw, e_bonus, e_in = static_alias(Kn, S, c["qs"], ref)
        ent.append((e_raw, e_bonus, e_in))
        for m, d in out.items():
            a = agg.setdefault(m, dict(rec=[], skew=[], maxocc=[], intr=[]))
            a["rec"].extend(d["rec"]); a["skew"].append(skew(d["occ"])); a["maxocc"].append(d["occ"].max() / len(S)); a["intr"].extend(d["intr"])
    res = {}
    for space, rows in geo.items():
        m = {k: float(np.mean([r[k] for r in rows])) for k in rows[0]}
        res[space] = m
        print(f"{space:>6}: E<s,s'> all {m['ss_all']:.3f} (identity {m['ss_identity']:.3f}), unrelated {m['ss_unrel']:.3f} (sd {m['sd_ss_unrel']:.3f}), "
              f"sharing evidence {m['ss_share']:.3f} | E<s,k> {m['sk_all']:.3f} (identity {m['sk_identity']:.3f}, sd {m['sd_sk']:.3f}), "
              f"own evidence {m['s_own_ev']:.3f}, 10th-best key {m['theta10']:.3f} | |mu_s| {m['mu_s']:.3f} |mu_k| {m['mu_k']:.3f} cos(mu_s,mu_k) {m['cos_mus_muk']:.3f}")
    print("\nstatic leave-one-out alias scoring, bridge space (all other asks' cites as aliases):")
    for m, a in agg.items():
        res[m] = dict(recall=float(np.mean(a["rec"])), skew_N10=float(np.mean(a["skew"])), max_occ=float(np.mean(a["maxocc"])), intrusions=float(np.mean(a["intr"])))
        print(f"  {m:<8} recall@10 {np.mean(a['rec']):.3f}   top-10 slots held by non-evidence aliased nodes {np.mean(a['intr']):.2f}   skewness of N_10 {np.mean(a['skew']):5.2f}   busiest node in top-10 of {np.mean(a['maxocc']):.2f} of asks")
    e = np.array(ent).mean(0)
    res["entry_raw"], res["entry_bonus"], res["entry_bonus_in"] = float(e[0]), float(e[1]), float(e[2])
    print(f"  entry rate of an unrelated alias: raw (beats the ask's 10th-best key) {e[0]:.3f}; bonus fires above its 10-NN level among "
          f"training-chat asks {e[1]:.4f}; among the other in-chat asks {e[2]:.4f}")
    json.dump(res, open("/tmp/claude-0/math/theory/hub.json", "w"), indent=1)


if __name__ == "__main__":
    main()
