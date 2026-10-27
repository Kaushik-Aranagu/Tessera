#!/usr/bin/env python3
"""Why mean-pooled parents route badly: session routing on LoCoMo with different parent representations.

A parent = a LoCoMo session (its turns are the children). For each ask, rank the chat's sessions and report the share
of evidence sessions found in the top-b (b = 3), i.e. the level-1 coverage that bounds the pyramid's recall.
Parent scores compared (frozen bge-small vectors, and rank-16 bridge vectors trained on the other 8 chats):
  mean      cos(q, unit(mean of children))                     one vector per parent (the failing design)
  proto-m   max over m k-means prototypes of the children      m vectors per parent, query-independent
  lse-tau   tau * log sum_c exp(cos(q, c)/tau)                  needs every child score (upper reference)
  max       max_c cos(q, c)                                     needs every child score (upper reference)
Also prints the dilution numbers of the mean: children per session, |mean of children|, the evidence margin
(c* - mean_c cos)/(n |mean|) and the spread of the mean-pool score across sessions for the same ask.
"""
import collections, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/math/objectives")
from multipos import train  # noqa: E402

torch.set_num_threads(1)
rng = np.random.default_rng(0)


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def kmeans(X, m, iters=20):
    if len(X) <= m:
        return X.copy()
    C = X[rng.choice(len(X), m, replace=False)].copy()
    for _ in range(iters):
        a = np.argmax(X @ C.T, 1)
        for j in range(m):
            if (a == j).any():
                C[j] = unit(X[a == j].sum(0))
    return C


def main():
    chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
    dim = chats[0]["nodes"].shape[1]
    res = collections.defaultdict(list); dil = collections.defaultdict(list); b = 3
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        br = train([c for i, c in enumerate(chats) if i not in test], dim, 40, fold, 16, "lout", True, False)
        for i in sorted(test):
            c = chats[i]
            with torch.no_grad():
                views = {"frozen": (c["nodes"], c["asks"]),
                         "bridge": (br.a(torch.tensor(c["nodes"])).numpy(), br.s(torch.tensor(c["asks"])).numpy())}
            sess = np.array([int(x.split(":")[0][1:]) for x in c["ids"]]); S = sorted(set(sess))
            members = {s: np.where(sess == s)[0] for s in S}
            for vname, (K, Q) in views.items():
                reps = {"mean": {s: unit(K[members[s]].mean(0))[None] for s in S}}
                for m in (2, 4, 8):
                    reps[f"proto-{m}"] = {s: kmeans(K[members[s]], m) for s in S}
                for r, (_, ev, cat) in enumerate(c["qs"]):
                    q = Q[r]; evs = sorted(set(sess[ev]))
                    child = K @ q
                    scores = {name: np.array([(R[s] @ q).max() for s in S]) for name, R in reps.items()}
                    scores["max"] = np.array([child[members[s]].max() for s in S])
                    for tau in (0.02, 0.05):
                        scores[f"lse-{tau}"] = np.array([tau * np.log(np.exp(child[members[s]] / tau).sum()) for s in S])
                    for name, sc in scores.items():
                        top = set(np.array(S)[np.argsort(-sc, kind="stable")[:b]])
                        hit = len(top & set(evs)) / len(evs)
                        res[(vname, name)].append(hit); res[(vname, name, "mh")].append(hit) if cat == 1 else None
                    if vname == "frozen" or vname == "bridge":
                        mp = scores["mean"]; e0 = evs[0]; n = len(members[e0])
                        mn = np.linalg.norm(K[members[e0]].mean(0))
                        cstar = child[ev].max(); cbar = child[members[e0]].mean()
                        dil[(vname, "n")].append(n); dil[(vname, "norm")].append(mn)
                        dil[(vname, "margin")].append((cstar - cbar) / (n * mn))
                        dil[(vname, "spread")].append(mp.std())
                        dil[(vname, "evidence child gap")].append(cstar - np.median(child))
        print(f"fold {fold} done", flush=True)
    print(f"session routing on LoCoMo held-out chats: share of evidence sessions in the top-{b} sessions")
    for key in sorted({k[:2] for k in res}):
        print(f"  {key[0]:<7} {key[1]:<10} all {np.mean(res[key]):.3f}   multi-hop {np.mean(res[key + ('mh',)]):.3f}")
    for v in ("frozen", "bridge"):
        print(f"  dilution ({v}): children/session {np.mean(dil[(v, 'n')]):.1f}, |mean| {np.mean(dil[(v, 'norm')]):.3f}, "
              f"evidence margin in mean-pool (c*-cbar)/(n|mean|) {np.mean(dil[(v, 'margin')]):.4f}, "
              f"std of mean-pool score across sessions {np.mean(dil[(v, 'spread')]):.4f}, "
              f"evidence child minus median child {np.mean(dil[(v, 'evidence child gap')]):.3f}")


if __name__ == "__main__":
    main()
