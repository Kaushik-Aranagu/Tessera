#!/usr/bin/env python3
"""Label-free soft-OR distillation with m prototypes per parent (bridge view), versus k-means prototypes and max.

For each held-out session u: prototypes K_u (m x d) start at k-means of the children and are trained to minimise
mean_q (tau_p * LSE_j(<s_q, K_u[j]>/tau_p) - LSE_tau(<s_q, k_c>))^2 over TRAINING-chat ask states (no labels). Prototypes
are kept unit length. Routing score = tau_p LSE over prototypes. Also the single-vector ridge at small lambda.
"""
import collections, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/math/objectives")
from multipos import train  # noqa: E402
from sessions import kmeans  # noqa: E402

torch.set_num_threads(1)


def lse_np(x, tau, axis):
    m = x.max(axis, keepdims=True)
    return (m + tau * np.log(np.exp((x - m) / tau).sum(axis, keepdims=True))).squeeze(axis)


def fit_protos(X, Kc, m, tau, steps=150):
    init = kmeans(Kc, m)
    P = torch.tensor(init, requires_grad=True)
    Xt = torch.tensor(X); y = torch.tensor(lse_np(X @ Kc.T, tau, 1))
    opt = torch.optim.Adam([P], lr=0.01)
    for _ in range(steps):
        Pu = torch.nn.functional.normalize(P, dim=-1)
        pred = tau * torch.logsumexp(Xt @ Pu.T / tau, 1)
        loss = ((pred - y) ** 2).mean()
        opt.zero_grad(); loss.backward(); opt.step()
    return torch.nn.functional.normalize(P, dim=-1).detach().numpy(), init


def main():
    chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
    dim = chats[0]["nodes"].shape[1]; b = 3; tau = 0.05
    res = collections.defaultdict(list)
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]
        br = train(tr, dim, 40, fold, 16, "lout", True, False)
        with torch.no_grad():
            X = np.concatenate([br.s(torch.tensor(c["asks"])).numpy() for c in tr]).astype(np.float64)
        for i in sorted(test):
            c = chats[i]
            with torch.no_grad():
                K = br.a(torch.tensor(c["nodes"])).numpy().astype(np.float64)
                Q = br.s(torch.tensor(c["asks"])).numpy().astype(np.float64)
            sess = np.array([int(x.split(":")[0][1:]) for x in c["ids"]]); S = sorted(set(sess))
            Y = np.stack([lse_np(X @ K[sess == s].T, tau, 1) for s in S], 1)
            reps = {}
            for lam in (0.001, 0.01):
                W = np.linalg.solve(X.T @ X + lam * np.eye(dim), X.T @ Y)
                reps[f"ridge-1 lam={lam}"] = ("lin", W)
            for m in (4, 8):
                fitted, init = {}, {}
                for s in S:
                    fitted[s], init[s] = fit_protos(X, K[sess == s], m, tau)
                reps[f"kmeans-{m}"] = ("proto", init); reps[f"distilled-{m}"] = ("proto", fitted)
            for r, (_, ev, cat) in enumerate(c["qs"]):
                evs = set(sess[ev]); q = Q[r]
                for name, (kind, R) in reps.items():
                    if kind == "lin":
                        sc = q @ R
                    else:
                        sc = np.array([tau * np.log(np.exp((R[s] @ q) / tau).sum()) for s in S])
                    top = set(np.array(S)[np.argsort(-sc, kind="stable")[:b]])
                    hit = len(top & evs) / len(evs)
                    res[name].append(hit)
                    if cat == 1:
                        res[name + " mh"].append(hit)
            print(f"fold {fold} chat {i} done", flush=True)
    print(f"bridge view, share of evidence sessions in top-{b}; prototypes scored by LSE tau={tau}")
    for name in sorted(k for k in res if not k.endswith(" mh")):
        print(f"  {name:<22} all {np.mean(res[name]):.3f}   multi-hop {np.mean(res[name + ' mh']):.3f}")


if __name__ == "__main__":
    main()
