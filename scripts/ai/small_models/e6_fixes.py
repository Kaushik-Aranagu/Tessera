#!/usr/bin/env python3
"""E6: known failure modes of learned memory, and the fixes, on LoCoMo held-out chats (public data only).

Bridges as in e5_bridges.py (5 folds, 2 test chats each). Within a test chat, questions are taken in a shuffled order
(3 orders, averaged) and the memory plane learns from each question's cites before the next question.
Failure modes probed:
  overwrite   moving a node's key toward an ask (E5's rule) can push it away from what it said, hurting other asks
  noisy cites real cites are sometimes wrong; a share p of each question's cites is swapped for a wrong top-10 node
  self-loop   no outside signal at all: the system treats its own top hit as cited (the rich-get-richer risk)
  overfit     full 384x384 heads on 8 chats; compared with identity plus rank-16 heads
Memory-plane update rules:
  move        k_v <- normalise(k_v + eta (s - k_v))                     (E5)
  alias       keep k_v; add the ask's state as an extra key of v; score = max(k_v . s, best alias . s - margin)
  anchored    like move, but the total shift from the original key is capped at --cap
Usage: python3 e6_fixes.py --data locomo10.json
"""
import argparse, collections, os, sys
import numpy as np
import torch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from e5_bridges import load, train, tokens, bm25_rank, fuse  # noqa: E402


def recall(order, ev, k=10):
    return len(set(order[:k]) & set(ev)) / len(ev)


class Plane:
    def __init__(self, keys, rule, eta, cap, margin):
        self.base = keys.copy(); self.keys = keys.copy(); self.rule = rule
        self.eta, self.cap, self.margin = eta, cap, margin
        self.alias = collections.defaultdict(list)

    def scores(self, s):
        out = self.keys @ s
        if self.rule == "alias":
            for v, al in self.alias.items():
                out[v] = max(out[v], max(a @ s for a in al) - self.margin)
        return out

    def learn(self, v, s):
        if self.rule == "none":
            return
        if self.rule == "alias":
            self.alias[v].append(s); return
        k = self.keys[v] + self.eta * (s - self.keys[v]); k /= np.linalg.norm(k)
        if self.rule == "anchored":
            d = k - self.base[v]; n = np.linalg.norm(d)
            if n > self.cap:
                k = self.base[v] + d * self.cap / n; k /= np.linalg.norm(k)
        self.keys[v] = k


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", required=True); p.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    p.add_argument("--eta", type=float, default=0.1); p.add_argument("--cap", type=float, default=0.3)
    p.add_argument("--margin", type=float, default=0.0); p.add_argument("--orders", type=int, default=3)
    a = p.parse_args()
    chats = load(a.data, a.model); dim = chats[0]["nodes"].shape[1]
    arms = [("frozen", None, "none", 0.0), ("bridged", 0, "none", 0.0), ("bridged-lowrank", 16, "none", 0.0)]
    for rule in ("move", "alias", "anchored"):
        for cites in (0.0, 0.3, 0.6, "self"):
            arms.append((f"{rule} cites={cites}", 16, rule, cites))
    tot = collections.defaultdict(float); per = collections.defaultdict(list); n = 0
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        train_set = [c for i, c in enumerate(chats) if i not in test]
        heads = {0: train(train_set, dim, 40, fold), 16: train(train_set, dim, 40, fold, rank=16)}
        for i in sorted(test):
            c = chats[i]
            with torch.no_grad():
                proj = {r: (b.a(torch.tensor(c["nodes"])).numpy(), b.s(torch.tensor(c["asks"])).numpy()) for r, b in heads.items()}
            lex = [[c["ids"].index(d) for d in bm25_rank(c["docs"], c["ids"], tokens(q))] for q, _, _ in c["qs"]]
            for o in range(a.orders):
                rng = np.random.default_rng(100 * fold + 10 * i + o)
                order = rng.permutation(len(c["qs"]))
                for name, rank, rule, cites in arms:
                    keys, states = (c["nodes"], c["asks"]) if rank is None else proj[rank]
                    plane = Plane(keys, rule, a.eta, a.cap, a.margin)
                    for r in order:
                        _, ev, cat = c["qs"][r]
                        sc = plane.scores(states[r]); top = list(np.argsort(-sc, kind="stable"))
                        x = recall(top, ev); h = recall(fuse(lex[r], top), ev)
                        tot[name] += x; tot[name + " hyb"] += h; tot[f"{name} c{cat}"] += x; per[name].append(x)
                        if name == "frozen":
                            n += 1; tot[f"n{cat}"] += 1
                        if cites == "self":
                            cited = top[:1]
                        else:
                            wrong = [v for v in top[:10] if v not in ev]
                            cited = [rng.choice(wrong) if (wrong and rng.random() < cites) else v for v in ev]
                        for v in cited:
                            plane.learn(int(v), states[r])
    cats = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
    print(f"{n} question visits (1531 x {a.orders} orders), held-out chats, recall@10; eta {a.eta}, cap {a.cap}")
    base = np.array(per["bridged-lowrank"]); rng = np.random.default_rng(0)
    for name, *_ in arms:
        d = np.array(per[name]) - base
        b = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(1000)]
        print(f"  {name:<22} {tot[name] / n:.3f}  +bm25 {tot[name + ' hyb'] / n:.3f}  vs lowrank {d.mean():+.3f} "
              f"[{np.percentile(b, 2.5):+.3f},{np.percentile(b, 97.5):+.3f}]  "
              + " ".join(f"{cats[k]} {tot[f'{name} c{k}'] / tot[f'n{k}']:.3f}" for k in cats))


if __name__ == "__main__":
    main()
