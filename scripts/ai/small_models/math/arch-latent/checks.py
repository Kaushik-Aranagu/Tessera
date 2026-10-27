"""Numerical checks for the architecture section (read-only use of the cached LoCoMo embeddings and e5's train()).

C1  rank(S^T A - I) <= 2r for identity + rank-r heads (Prop. 1).
C2  modality gap inside Z: ask-ask vs ask-turn vs turn-turn cosines, frozen and after low-rank bridges.
C3  decodability of a head's output by the nearest-neighbour decoder over the chat's own texts (asks + turns):
    does n(S x_q) still decode to its own ask? does n(A e_v) still decode to its own turn?  low-rank vs full-rank.
C4  parent routing: sessions as parents. Score a session by cos(q, normalise(mean children)) vs max_i cos(q, c_i)
    vs log-sum-exp; session hit-rate of evidence turns at top-1 / top-3 (Prop. 2: single vector cannot do OR routing).
C5  extreme-value bias of max-pooling: mean over asks of max over m random unrelated turns vs mu + sigma*sqrt(2 ln m).
"""
import os, pickle, sys, collections
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import train  # noqa: E402  (read-only import; file untouched)

torch.set_num_threads(1)
D = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
dim = 384
out = {}


def n(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


# ---------- C1 + C2 + C3 on fold 0 (train chats 2..9, test chats 0,1) and all folds for C3
c1 = []; gap = collections.defaultdict(list); dec = collections.defaultdict(list)
for fold in range(5):
    test = {2 * fold, 2 * fold + 1}
    tr = [c for i, c in enumerate(D) if i not in test]
    heads = {"lowrank": train(tr, dim, 40, fold, rank=16), "full": train(tr, dim, 40, fold)}
    with torch.no_grad():
        W = heads["lowrank"]
        M = (W.state.weight.T @ W.action.weight - torch.eye(dim)).numpy()
        sv = np.linalg.svd(M, compute_uv=False)
        c1.append(int((sv > 1e-5 * sv[0]).sum()))
        for i in sorted(test):
            c = D[i]
            X, E = c["asks"], c["nodes"]
            views = {"frozen": (X, E)}
            for name, b in heads.items():
                views[name] = (b.s(torch.tensor(X)).numpy(), b.a(torch.tensor(E)).numpy())
            for name, (S, K) in views.items():
                aa = S @ S.T; iu = np.triu_indices(len(S), 1)
                tt = K @ K.T; ju = np.triu_indices(len(K), 1)
                gap[name + " ask-ask"].append(aa[iu].mean())
                gap[name + " ask-turn"].append((S @ K.T).mean())
                gap[name + " turn-turn"].append(tt[ju].mean())
                gap[name + " |mean(ask)-mean(turn)|"].append(np.linalg.norm(S.mean(0) - K.mean(0)))
                # C3: nearest-neighbour decoder over the chat's own text bank, encoded by the frozen f
                bank = np.vstack([X, E])  # rows 0..Q-1 asks, Q.. turns
                Q = len(X)
                ds = np.argmax(S @ bank.T, axis=1)
                dk = np.argmax(K @ bank.T, axis=1)
                dec[name + " state->own ask"].append((ds == np.arange(Q)).mean())
                dec[name + " key->own turn"].append((dk == Q + np.arange(len(E))).mean())
                dec[name + " cos(view, anchor) ask"].append((S * X).sum(1).mean())
                dec[name + " cos(view, anchor) turn"].append((K * E).sum(1).mean())
out["C1 rank(S^T A - I) per fold (r=16)"] = c1
out["C2"] = {k: round(float(np.mean(v)), 4) for k, v in gap.items()}
out["C3"] = {k: round(float(np.mean(v)), 4) for k, v in dec.items()}

# ---------- C4 parent routing with sessions as parents (frozen f, no training)
hits = collections.defaultdict(float); tot = 0
for c in D:
    sess = [i.split(":")[0] for i in c["ids"]]
    names = sorted(set(sess), key=lambda s: int(s[1:]))
    idx = {s: [j for j, x in enumerate(sess) if x == s] for s in names}
    E = c["nodes"]
    cent = n(np.stack([E[idx[s]].mean(0) for s in names]))
    for r, (_, ev, _) in enumerate(c["qs"]):
        q = c["asks"][r]
        sims = E @ q
        sc = {
            "mean-centroid": cent @ q,
            "max": np.array([sims[idx[s]].max() for s in names]),
            "lse tau=0.05": np.array([0.05 * np.log(np.exp(sims[idx[s]] / 0.05).sum()) for s in names]),
        }
        evs = {sess[e] for e in ev}
        tot += 1
        for k, v in sc.items():
            order = [names[j] for j in np.argsort(-v, kind="stable")]
            for top in (1, 3):
                hits[f"{k} top{top}"] += len(evs & set(order[:top])) / len(evs)
out["C4 session hit-rate (frozen f)"] = {k: round(v / tot, 4) for k, v in hits.items()}
out["C4 sessions per chat"] = [len({i.split(':')[0] for i in c["ids"]}) for c in D]
out["C4 mean turns per session"] = round(float(np.mean([len(c["ids"]) / len({i.split(':')[0] for i in c["ids"]}) for c in D])), 1)

# ---------- C5 max-pooling bias over unrelated turns (frozen f)
rng = np.random.default_rng(0); rows = {}
for m in (1, 2, 4, 8, 16, 32, 64):
    emp, pred = [], []
    for c in D:
        E, X = c["nodes"], c["asks"]
        for r, (_, ev, _) in enumerate(c["qs"]):
            pool = np.setdiff1d(np.arange(len(E)), ev)
            s = E[pool] @ X[r]
            mu, sd = s.mean(), s.std()
            pick = rng.choice(len(pool), size=min(m, len(pool)), replace=False)
            emp.append(s[pick].max() - mu)
            pred.append(sd * np.sqrt(2 * np.log(m)) if m > 1 else 0.0)
    rows[m] = (round(float(np.mean(emp)), 4), round(float(np.mean(pred)), 4))
out["C5 m -> (empirical E[max]-mu, sigma*sqrt(2 ln m))"] = rows
# ask-ask vs ask-turn: an alias key (a stored ask state) vs the node's own key, for an unrelated ask
aa, at = [], []
for c in D:
    X, E = c["asks"], c["nodes"]
    S = X @ X.T; np.fill_diagonal(S, np.nan)
    aa.append(np.nanmean(S)); at.append((X @ E.T).mean())
out["C5b frozen mean cos ask-ask vs ask-turn"] = (round(float(np.mean(aa)), 4), round(float(np.mean(at)), 4))

import json
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/arch-latent/checks.json", "w"), indent=1)
