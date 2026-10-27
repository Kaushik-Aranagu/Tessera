#!/usr/bin/env python3
"""Compare multi-positive contrastive formulations for the read bridge on LoCoMo held-out chats.

Same setup as e5_bridges.train(rank=16): identity + rank-16 heads, AdamW lr 1e-3, 40 epochs, one step per chat,
0.01 * ||W - I||_F^2 per head, learned log-scale initialised at log 20. Only the loss changes.
  lout_bi    e5's loss: uniform soft-target CE (= asymmetric SupCon L_out) both directions   [the current code]
  lout_fwd   forward (ask -> node) term only
  lin_bi     SupCon L_in / MIL-NCE: -log sum_{p in P} softmax_p, both directions
  mask_bi    per-positive InfoNCE, other positives removed from the denominator, both directions; scale <= 100
  mask_fwd   forward only
Reads the cached embeddings (chats.pkl written by fix_cite_noise.py from e5_bridges.load). Never edits sm/.
"""
import collections, math, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import Bridge  # noqa: E402

torch.set_num_threads(1)


def loss_terms(logits, P, kind):
    """logits: |Q| x |V|; P: bool mask of positives. Returns the per-direction mean loss."""
    if kind == "lout":
        y = P.float() / P.float().sum(1, keepdim=True)
        return -(y * logits.log_softmax(1)).sum(1).mean()
    if kind == "lin":
        lp = logits.log_softmax(1)
        return -(torch.logsumexp(lp.masked_fill(~P, -1e9), 1)).mean()
    if kind == "mask":
        neg = logits.masked_fill(P, -1e9)                     # negatives only
        lse_neg = torch.logsumexp(neg, 1, keepdim=True)       # log Z_N
        per = torch.logaddexp(logits, lse_neg.expand_as(logits)) - logits   # log(e^l_p + Z_N) - l_p
        per = per.masked_fill(~P, 0.0)
        return (per.sum(1) / P.float().sum(1)).mean()
    raise ValueError(kind)


def train(chats, dim, epochs, seed, rank, kind, bidir, clamp):
    torch.manual_seed(seed)
    b = Bridge(dim, rank); opt = torch.optim.AdamW(b.parameters(), lr=1e-3, weight_decay=0.0)
    eye = torch.eye(dim)
    data = []
    for c in chats:
        P = torch.zeros(len(c["qs"]), len(c["ids"]), dtype=torch.bool)
        for r, (_, ev, _) in enumerate(c["qs"]):
            P[r, ev] = True
        data.append((torch.tensor(c["nodes"]), torch.tensor(c["asks"]), P))
    for _ in range(epochs):
        for nodes, asks, P in data:
            if clamp:
                with torch.no_grad():
                    b.scale.clamp_(max=math.log(100.0))
            logits = b.scale.exp() * b.s(asks) @ b.a(nodes).T
            loss = loss_terms(logits, P, kind)
            if bidir and kind == "lout":                              # e5's exact backward term (joint coupling)
                pos = P.float() / P.float().sum(1, keepdim=True)
                cols = pos.sum(0) > 0
                loss = loss - (pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
            elif bidir:
                cols = P.any(0)
                loss = loss + loss_terms(logits[:, cols].T, P[:, cols].T, kind)
            near = ((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum()
            loss = loss + 0.01 * near
            opt.zero_grad(); loss.backward(); opt.step()
    return b


def recall(order, ev, k=10):
    return len(set(order[:k]) & set(ev)) / len(ev)


def main():
    chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
    dim = chats[0]["nodes"].shape[1]
    arms = {"lout_bi": ("lout", True, False), "lout_fwd": ("lout", False, False), "lin_bi": ("lin", True, False),
            "mask_bi": ("mask", True, True), "mask_fwd": ("mask", False, True)}
    seeds = [0, 100]
    per = collections.defaultdict(list); meta = []
    scales = collections.defaultdict(list)
    for s0 in seeds:
        for fold in range(5):
            test = {2 * fold, 2 * fold + 1}
            tr = [c for i, c in enumerate(chats) if i not in test]
            heads = {a: train(tr, dim, 40, fold + s0, 16, *cfg) for a, cfg in arms.items()}
            for a, b in heads.items():
                scales[a].append(float(b.scale.exp()))
            for i in sorted(test):
                c = chats[i]
                with torch.no_grad():
                    proj = {a: (b.a(torch.tensor(c["nodes"])).numpy(), b.s(torch.tensor(c["asks"])).numpy())
                            for a, b in heads.items()}
                for r, (_, ev, cat) in enumerate(c["qs"]):
                    if s0 == seeds[0]:
                        meta.append((cat, len(ev)))
                    for a, (K, S) in proj.items():
                        per[(a, s0)].append(recall(list(np.argsort(-(K @ S[r]), kind="stable")), ev))
            print(f"seed {s0} fold {fold} done", flush=True)
    cat = np.array([m[0] for m in meta]); npos = np.array([m[1] for m in meta])
    rng = np.random.default_rng(0)
    print(f"{len(meta)} held-out asks, recall@10, rank-16 heads, mean over seeds {seeds}")
    base = np.mean([per[("lout_bi", s)] for s in seeds], 0)
    for a in arms:
        x = np.mean([per[(a, s)] for s in seeds], 0)
        d = x - base
        boots = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
        seed_means = [np.mean(per[(a, s)]) for s in seeds]
        print(f"  {a:<9} all {x.mean():.3f} (seeds {' '.join(f'{m:.3f}' for m in seed_means)})  "
              f"multi-hop {x[cat == 1].mean():.3f}  |P|=1 {x[npos == 1].mean():.3f}  |P|>=2 {x[npos >= 2].mean():.3f}  "
              f"vs lout_bi {d.mean():+.3f} [{np.percentile(boots, 2.5):+.3f},{np.percentile(boots, 97.5):+.3f}]  "
              f"|P|>=2 delta {d[npos >= 2].mean():+.3f}  final scale {np.mean(scales[a]):.1f}")


if __name__ == "__main__":
    main()
