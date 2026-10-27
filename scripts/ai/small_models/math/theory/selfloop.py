"""Self-feedback (top-1 treated as cited) as a positive-feedback loop: loop-gain estimate vs long-horizon replay.

For each held-out chat (rank-16 bridge of its fold):
  W_v      share of the chat's asks for which node v is the top-1 (its win rate)
  dW1      change in W_v caused by ONE self-cite of v (v moved toward one of the asks it wins), averaged over its wins
  h_v      first-order drift of v's mean score over all asks per win: <s,mu> - c <k_v,mu>  (mu = mean ask state)
  t*       1/dW1 for the top-winning node = predicted e-folding time (in asks) of its win count
Long horizon: 10 passes over the chat's asks in fresh random orders, no reset, self-feedback; track the top node's
win share and recall@10 (vs no learning) in windows.
"""
import json, sys
import numpy as np

sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats, folds, recall, topk, unit  # noqa: E402


def step(k, s, eta, rule, mu):
    tgt = s if rule == "move" else unit(s - mu)
    return unit(k + eta * (tgt - k))


def win_rates(keys, S):
    top1 = np.argmax(S @ keys.T, axis=1)
    return np.bincount(top1, minlength=len(keys)) / len(S), top1


def loop_gain(K0, S, eta, rule, mu, n_top=5):
    W, top1 = win_rates(K0, S)
    out = []
    for v in np.argsort(-W)[:n_top]:
        won = np.where(top1 == v)[0]
        dws, hs = [], []
        for j in won:
            K1 = K0.copy(); K1[v] = step(K0[v], S[j], eta, rule, mu)
            W1, _ = win_rates(K1, S)
            dws.append(W1[v] - W[v])
            c = K0[v] @ S[j]
            tgt = S[j] if rule == "move" else unit(S[j] - mu)
            hs.append(eta * (tgt @ mu - (K0[v] @ tgt) * (K0[v] @ mu)))
        out.append((W[v], np.mean(dws), np.mean(hs)))
    return out


def long_run(K0, S, qs, eta, rule, mu, passes, seed, cap=None):
    rng = np.random.default_rng(seed)
    keys = K0.copy()
    log = []
    for p in range(passes):
        for r in rng.permutation(len(S)):
            sc = keys @ S[r]
            top = topk(sc, 10)
            base = topk(K0 @ S[r], 10)
            v = int(top[0])
            log.append((v, recall(top, qs[r][1]) - recall(base, qs[r][1])))
            k = step(keys[v], S[r], eta, rule, mu)
            if cap is not None:
                d = k - K0[v]; n = np.linalg.norm(d)
                if n > cap:
                    k = unit(K0[v] + d * cap / n)
            keys[v] = k
    return log


def main():
    C, B = chats(), bridges()
    arms = [("move", 0.1, None), ("move", 0.02, None), ("centered", 0.1, None), ("move", 0.1, 0.3)]
    gains = {}
    traj = {}
    stats = dict(beta_gap=[], mu_norm=[], ss_unrel=[], W0max=[], W0top5=[])
    for fold, i in folds():
        K0, S, qs = B[f"f{fold}_k{i}"], B[f"f{fold}_s{i}"], C[i]["qs"]
        mu = S.mean(0)
        sc = S @ K0.T
        srt = np.sort(sc, 1)
        stats["beta_gap"].append(np.mean(srt[:, -1] - srt[:, -2]))
        stats["mu_norm"].append(np.linalg.norm(mu))
        G = S @ S.T
        stats["ss_unrel"].append((G.sum() - np.trace(G)) / (len(S) * (len(S) - 1)))
        W, _ = win_rates(K0, S)
        stats["W0max"].append(W.max()); stats["W0top5"].append(np.sort(W)[-5:].sum())
        for rule, eta, cap in arms:
            name = f"{rule} eta={eta}" + (f" cap={cap}" if cap else "")
            if cap is None:
                gains.setdefault(name, []).extend(loop_gain(K0, S, eta, rule, mu))
            log = long_run(K0, S, qs, eta, rule, mu, 10, 1000 + 10 * fold + i, cap)
            traj.setdefault(name, []).append(log)
    print("geometry (mean over 10 held-out chats): top1-top2 score gap %.4f, |mean ask state| %.3f, mean <s,s'> %.3f, "
          "max initial win share %.3f, top-5 initial share %.3f" % tuple(np.mean(stats[k]) for k in ("beta_gap", "mu_norm", "ss_unrel", "W0max", "W0top5")))
    res = dict(stats={k: float(np.mean(v)) for k, v in stats.items()})
    print("\nloop gain for the 5 top-winning nodes of each chat: W0, dW per win, h (first-order drift of mean score per win), t* = 1/dW")
    for name, g in gains.items():
        g = np.array(g)
        pos = g[:, 1] > 0
        tstar = np.median(1 / g[pos, 1]) if pos.any() else float("inf")
        res[name] = dict(W0=g[:, 0].mean(), dW1=g[:, 1].mean(), h=g[:, 2].mean(), frac_dW_pos=pos.mean(), tstar_median=tstar)
        print(f"  {name:<16} W0 {g[:, 0].mean():.3f}  dW1 {g[:, 1].mean():+.4f}  (positive for {pos.mean():.2f})  h {g[:, 2].mean():+.4f}  median t* {tstar:.0f} asks")
    print("\nlong horizon (10 passes, ~1500 self-cited asks per chat): per window of 150 visits, share of visits whose top-1 is the window's "
          "most frequent top-1 node, and recall@10 change vs no learning")
    for name, logs in traj.items():
        shares, drs = [], []
        for w in range(10):
            sh, dr = [], []
            for log in logs:
                n = len(log) // 10
                seg = log[w * n:(w + 1) * n]
                vs = [v for v, _ in seg]
                sh.append(np.bincount(vs).max() / len(vs)); dr.append(np.mean([d for _, d in seg]))
            shares.append(np.mean(sh)); drs.append(np.mean(dr))
        res[name] = dict(res.get(name, {}), shares=shares, drecall=drs)
        print(f"  {name:<16} top share " + " ".join(f"{x:.2f}" for x in shares) + " | d recall " + " ".join(f"{x:+.3f}" for x in drs))
    json.dump(res, open("/tmp/claude-0/math/theory/selfloop.json", "w"), indent=1, default=float)


if __name__ == "__main__":
    main()
