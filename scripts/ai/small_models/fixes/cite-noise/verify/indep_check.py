#!/usr/bin/env python3
"""Independent re-implementation (does NOT import fix_cite_noise.py) of the baseline, E6 move, contrastive,
centered and combo arms, using the per-fold settings the claim reports. Deterministic conditions (clean, self,
visible) must match the claim exactly; noisy ones (wrong30/wrong60) use a different RNG (E6 style), so they should
match only within noise. Also checks the baseline against the E5 fuse() hybrid and E6's Plane for move.
"""
import argparse, collections, os, pickle, sys, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import bm25_rank, fuse, tokens, train  # noqa: E402
from e6_fixes import Plane as E6Plane, recall  # noqa: E402

CONTRASTIVE = [(0.05, 0.03), (0.05, 0.03), (0.05, 0.01), (0.1, 0.03), (0.05, 0.01)]
CENTERED = [0.05, 0.2, 0.2, 0.1, 0.05]
COMBO = [(0.1, 50, 0.02), (0.1, None, 0.02), (0.2, None, 0.02), (0.2, 10, 0.02), (0.1, 20, 0.02)]


def unit(v):
    return v / np.linalg.norm(v)


class Rule:
    """pull: toward s (c=0) or toward unit(s - mu) (c=1); push: opened top-10 not reported, away from the same d."""
    def __init__(self, keys, eta, eta_neg=0.0, c=0.0, agree=None, mu0=None):
        self.k = keys.copy(); self.eta, self.eta_neg, self.c, self.agree = eta, eta_neg, c, agree
        self.sum = 10 * mu0.astype(np.float64) if mu0 is not None else None; self.n = 10

    def see(self, s):
        if self.sum is not None:
            self.sum = self.sum + s; self.n += 1

    def update(self, s, top, reported, lexpos):
        acc = [v for v in reported if self.agree is None or lexpos[v] < self.agree]
        if not acc:
            return
        d = unit(s - self.c * self.sum / self.n).astype(np.float32) if self.c else s
        for v in acc:
            self.k[v] = unit(self.k[v] + self.eta * (d - self.k[v]))
        if self.eta_neg:
            rep = set(int(v) for v in reported)
            for u in top[:10]:
                if int(u) not in rep:
                    self.k[u] = unit(self.k[u] - self.eta_neg * d)


def main():
    p = argparse.ArgumentParser(); p.add_argument("--cache", required=True); a = p.parse_args()
    t0 = time.time()
    chats = pickle.load(open(a.cache, "rb")); dim = chats[0]["nodes"].shape[1]
    per = collections.defaultdict(list); hyb = collections.defaultdict(list); cats = []
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]
        b = train(tr, dim, 40, fold, rank=16)
        with torch.no_grad():
            mu0 = np.concatenate([b.s(torch.tensor(c["asks"])).numpy() for c in tr]).mean(0)
        for i in sorted(test):
            c = chats[i]
            with torch.no_grad():
                keys = b.a(torch.tensor(c["nodes"])).numpy(); states = b.s(torch.tensor(c["asks"])).numpy()
            lex = [[c["ids"].index(d) for d in bm25_rank(c["docs"], c["ids"], tokens(q))] for q, _, _ in c["qs"]]
            lexpos = []
            for L in lex:
                pp = np.empty(len(L), dtype=np.int64); pp[L] = np.arange(len(L)); lexpos.append(pp)
            for o in range(3):
                rng = np.random.default_rng(100 * fold + 10 * i + o)
                order = rng.permutation(len(c["qs"]))
                noise_rng = np.random.default_rng(555 + 100 * fold + 10 * i + o)
                arms = {}
                for cond in ("clean", "self", "visible"):
                    arms[f"move|{cond}"] = ("e6", E6Plane(keys, "move", 0.1, 0.3, 0.0))
                    e, en = CONTRASTIVE[fold]
                    arms[f"contrastive|{cond}"] = ("r", Rule(keys, e, en))
                    arms[f"centered|{cond}"] = ("r", Rule(keys, CENTERED[fold], 0.0, 1.0, None, mu0))
                    e, ag, en = COMBO[fold]
                    arms[f"combo|{cond}"] = ("r", Rule(keys, e, en, 1.0, ag, mu0))
                for cond in ("wrong30", "wrong60"):  # own RNG: comparable only within noise
                    arms[f"move|{cond}"] = ("e6", E6Plane(keys, "move", 0.1, 0.3, 0.0))
                    e, en = CONTRASTIVE[fold]
                    arms[f"contrastive|{cond}"] = ("r", Rule(keys, e, en))
                    e, ag, en = COMBO[fold]
                    arms[f"combo|{cond}"] = ("r", Rule(keys, e, en, 1.0, ag, mu0))
                for r in order:
                    _, ev, cat = c["qs"][r]; s = states[r]; cats.append(cat)
                    base_top = list(np.argsort(-(keys @ s), kind="stable"))
                    per["baseline"].append(recall(base_top, ev)); hyb["baseline"].append(recall(fuse(lex[r], base_top), ev))
                    u = noise_rng.random((2, len(ev)))
                    for name, (kind, pl) in arms.items():
                        cond = name.split("|")[1]
                        if kind == "r":
                            pl.see(s); sc = pl.k @ s
                        else:
                            sc = pl.scores(s)
                        top = np.argsort(-sc, kind="stable")
                        per[name].append(recall(top, ev)); hyb[name].append(recall(fuse(lex[r], list(top)), ev))
                        if cond == "clean":
                            rep = list(ev)
                        elif cond == "self":
                            rep = [int(top[0])]
                        elif cond == "visible":
                            op = set(top[:10].tolist()); rep = [v for v in ev if v in op]
                        else:
                            pw = 0.3 if cond == "wrong30" else 0.6
                            wrong = [int(v) for v in top[:10] if int(v) not in ev]
                            rep = [wrong[int(u[1, j] * len(wrong))] if (wrong and u[0, j] < pw) else v for j, v in enumerate(ev)]
                        if kind == "r":
                            pl.update(s, top, rep, lexpos[r])
                        else:
                            for v in rep:
                                pl.learn(int(v), s)
        print(f"fold {fold} done {time.time() - t0:.0f}s", flush=True)
    base = np.array(per["baseline"]); cats = np.array(cats[: len(base)])
    # cats was appended once per arm-loop? no: once per visit (outside the arm loop) -> length == len(base)
    rng = np.random.default_rng(0)
    print(f"{len(base)} visits; baseline {base.mean():.4f} mh {base[cats == 1].mean():.4f} +bm25 {np.mean(hyb['baseline']):.4f}")
    for name in sorted(k for k in per if k != "baseline"):
        x = np.array(per[name]); d = x - base
        bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
        print(f"  {name:<22} {x.mean():.4f}  delta {d.mean():+.4f} [{np.percentile(bs, 2.5):+.4f},{np.percentile(bs, 97.5):+.4f}]"
              f"  mh {x[cats == 1].mean():.4f}  +bm25 {np.mean(hyb[name]):.4f}")


if __name__ == "__main__":
    main()
