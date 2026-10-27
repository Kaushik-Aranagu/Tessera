#!/usr/bin/env python3
"""Can ONE learned vector per parent route like max/LSE? Label-free distillation of the soft-OR score.

For each session u of a held-out chat, fit w_u = argmin_w sum_q (<s_q, w> - LSE_tau_u(q))^2 + lam |w|^2 where the
queries s_q are the TRAINING chats' ask states (never the test chat's asks) and LSE_tau_u(q) = tau log sum_c exp(<s_q,k_c>/tau)
is the soft-OR of the session's children scores. No evidence labels are used. Then route the held-out asks with
<s, w_u> and report the share of evidence sessions in the top-3 (as sessions.py). Also reports how many asks have
evidence in more than 3 sessions (no top-3 router can reach full coverage for them).
"""
import collections, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/math/objectives")
from multipos import train  # noqa: E402

torch.set_num_threads(1)


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def lse(x, tau, axis):
    m = x.max(axis, keepdims=True)
    return (m + tau * np.log(np.exp((x - m) / tau).sum(axis, keepdims=True))).squeeze(axis)


def main():
    chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
    dim = chats[0]["nodes"].shape[1]; b = 3; tau = 0.05
    res = collections.defaultdict(list); spread = []
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]
        br = train(tr, dim, 40, fold, 16, "lout", True, False)
        with torch.no_grad():
            Qtr = {"bridge": np.concatenate([br.s(torch.tensor(c["asks"])).numpy() for c in tr]),
                   "frozen": np.concatenate([c["asks"] for c in tr])}
        for i in sorted(test):
            c = chats[i]
            with torch.no_grad():
                views = {"frozen": (c["nodes"], c["asks"]),
                         "bridge": (br.a(torch.tensor(c["nodes"])).numpy(), br.s(torch.tensor(c["asks"])).numpy())}
            sess = np.array([int(x.split(":")[0][1:]) for x in c["ids"]]); S = sorted(set(sess))
            for vname, (K, Q) in views.items():
                X = Qtr[vname]
                Y = np.stack([lse(X @ K[sess == s].T, tau, 1) for s in S], 1)       # |Qtr| x |S|
                for lam in (0.1, 1.0, 10.0):
                    W = np.linalg.solve(X.T @ X + lam * np.eye(dim), X.T @ Y)       # dim x |S|
                    for r, (_, ev, cat) in enumerate(c["qs"]):
                        evs = set(sess[ev]); sc = Q[r] @ W
                        top = set(np.array(S)[np.argsort(-sc, kind="stable")[:b]])
                        hit = len(top & evs) / len(evs)
                        res[(vname, f"distilled lam={lam}")].append(hit)
                        if cat == 1:
                            res[(vname, f"distilled lam={lam}", "mh")].append(hit)
            for r, (_, ev, cat) in enumerate(c["qs"]):
                spread.append((len(set(sess[ev])), cat))
        print(f"fold {fold} done", flush=True)
    print(f"one distilled vector per session (label-free, LSE tau={tau}); share of evidence sessions in top-{b}")
    for key in sorted({k[:2] for k in res}):
        print(f"  {key[0]:<7} {key[1]:<20} all {np.mean(res[key]):.3f}   multi-hop {np.mean(res[key + ('mh',)]):.3f}")
    sp = np.array(spread)
    for name, msk in (("all", np.ones(len(sp), bool)), ("multi-hop", sp[:, 1] == 1)):
        n = sp[msk, 0]
        print(f"  evidence sessions per ask ({name}): mean {n.mean():.2f}; share with >{b} sessions {np.mean(n > b):.3f}; "
              f"coverage ceiling for a top-{b} router {np.mean(np.minimum(n, b) / n):.3f}")


if __name__ == "__main__":
    main()
