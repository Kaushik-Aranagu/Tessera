"""Low-rank vs full-rank bridge heads (section A4).

(a) Spike-vs-noise count at initialisation. At W_s = W_a = I the per-ask gradient of the forward InfoNCE term is
      g_q(W_a) = tau sum_v (p_v - y_v) (s_q - <s_q,x_v> x_v) x_v^T,
      g_q(W_s) = tau (I - s_q s_q^T) (sum_v (p_v - y_v) x_v) s_q^T,
    with p = softmax_v(tau <s_q, x_v>), y = evidence indicator / |E_q|. G = mean_q g_q. For n training asks the noise
    in G is estimated by a sign-flip bootstrap E* = (1/n) sum_q eps_q (g_q - G); its spectral norm is the noise edge.
    r_detect(n) = number of singular values of G (all asks) above edge(n): directions a head can learn from n asks.
(b) Rank sweep: held-out recall@10 of e5 heads with rank r in {1,..,128, full}, trained on 2, 4 or 8 chats per fold
    with the total number of optimiser steps fixed at 320 (epochs = 320 / chats), seed = fold.
"""
import json, sys, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
sys.path.insert(0, "/tmp/claude-0/math/theory")
from e5_bridges import train  # noqa: E402
from common import chats, recall  # noqa: E402

torch.set_num_threads(1)
TAU = 20.0


def per_ask_grads(c):
    X, S = c["nodes"].astype(np.float64), c["asks"].astype(np.float64)
    ga, gs = [], []
    for q, (_, ev, _) in enumerate(c["qs"]):
        s = S[q]
        z = TAU * X @ s
        p = np.exp(z - z.max()); p /= p.sum()
        y = np.zeros(len(X)); y[ev] = 1 / len(ev)
        w = p - y
        cs = X @ s
        ga.append((TAU * ((w[:, None] * (s[None, :] - cs[:, None] * X)).T @ X)).astype(np.float32))
        u = X.T @ w
        gs.append((TAU * np.outer(u - (s @ u) * s, s)).astype(np.float32))
    return np.array(ga), np.array(gs)


def spike_count():
    C = chats()
    GA, GS = [], []
    for c in C:
        a, s = per_ask_grads(c)
        GA.append(a); GS.append(s)
    out = {}
    rng = np.random.default_rng(0)
    for name in ("action", "state"):
        G = np.concatenate(GA if name == "action" else GS)
        n_all = len(G)
        Gm = G.astype(np.float64).mean(0)
        sv = np.linalg.svd(Gm, compute_uv=False)
        edges = {}
        for n in (150, 300, 600, 1200, 2400, 4800):
            norms = []
            for _ in range(5):
                idx = rng.integers(0, n_all, n)
                eps = rng.choice([-1.0, 1.0], n)
                w = np.zeros(n_all); np.add.at(w, idx, eps)
                E = (np.tensordot(w.astype(np.float32), G, 1).astype(np.float64) - w.sum() * Gm) / n
                norms.append(np.linalg.norm(E, 2))
            edges[n] = float(np.mean(norms))
        del G
        # spike count: singular values of the all-ask mean above the noise edge at n (noise in G_all itself removed in quadrature)
        e_all = edges[1200] * np.sqrt(1200 / n_all)
        sig = np.sqrt(np.maximum(sv ** 2 - e_all ** 2, 0))
        counts = {n: int((sig > e).sum()) for n, e in edges.items()}
        # power-law fit of the signal spectrum over the detectable range
        k = max(3, counts[1200])
        ii = np.arange(1, k + 1)
        gamma = -np.polyfit(np.log(ii), np.log(sig[:k]), 1)[0]
        out[name] = dict(sv_top=[float(x) for x in sv[:40]], edges=edges, r_detect=counts, gamma=float(gamma),
                         edge_slope=float(np.polyfit(np.log(list(edges)), np.log(list(edges.values())), 1)[0]),
                         frob_share_top16=float((sig[:16] ** 2).sum() / (sig ** 2).sum()))
        print(f"{name} head: top singular values {np.round(sv[:8], 3).tolist()}; noise edge by n asks "
              + ", ".join(f"{n}:{e:.3f}" for n, e in edges.items()) + f" (log-log slope {out[name]['edge_slope']:.2f})")
        print(f"   detectable directions r_detect(n): " + ", ".join(f"{n}:{c}" for n, c in counts.items())
              + f"; signal spectrum power law gamma {gamma:.2f}; top-16 share of signal energy {out[name]['frob_share_top16']:.2f}")
    return out


def sweep():
    C = chats()
    dim = C[0]["nodes"].shape[1]
    ranks = (1, 2, 4, 8, 16, 32, 64, 128, 0)
    res = {}
    t0 = time.time()
    for fold in range(5):
        test = (2 * fold, 2 * fold + 1)
        pool = [i for i in range(10) if i not in test]
        perm = list(np.random.default_rng(50 + fold).permutation(pool))
        for nch in (2, 4, 8):
            tr = [C[i] for i in perm[:nch]]
            for r in ranks:
                b = train(tr, dim, 320 // nch, fold, rank=r)
                recs, trs = [], []
                with torch.no_grad():
                    for i in test:
                        k = b.a(torch.tensor(C[i]["nodes"])).numpy(); s = b.s(torch.tensor(C[i]["asks"])).numpy()
                        for j, (_, ev, _) in enumerate(C[i]["qs"]):
                            recs.append(recall(list(np.argsort(-(k @ s[j]), kind="stable")), ev))
                    for c in tr:
                        k = b.a(torch.tensor(c["nodes"])).numpy(); s = b.s(torch.tensor(c["asks"])).numpy()
                        for j, (_, ev, _) in enumerate(c["qs"]):
                            trs.append(recall(list(np.argsort(-(k @ s[j]), kind="stable")), ev))
                    dW = np.linalg.norm(b.action.weight.numpy() - np.eye(dim)) + np.linalg.norm(b.state.weight.numpy() - np.eye(dim))
                d = res.setdefault(f"{nch}:{r}", dict(test=[], train=[], ntrain_asks=[], dW=[]))
                d["test"].append(float(np.mean(recs))); d["train"].append(float(np.mean(trs)))
                d["ntrain_asks"].append(sum(len(c["qs"]) for c in tr)); d["dW"].append(float(dW))
        print(f"fold {fold} swept ({time.time() - t0:.0f}s)", flush=True)
    frozen = []
    for fold in range(5):
        for i in (2 * fold, 2 * fold + 1):
            c = C[i]
            for j, (_, ev, _) in enumerate(c["qs"]):
                frozen.append(recall(list(np.argsort(-(c["nodes"] @ c["asks"][j]), kind="stable")), ev))
    print(f"frozen held-out recall@10 {np.mean(frozen):.3f}")
    for nch in (2, 4, 8):
        row = []
        for r in ranks:
            d = res[f"{nch}:{r}"]
            row.append(f"{'full' if r == 0 else r}:{np.mean(d['test']):.3f}/{np.mean(d['train']):.3f}")
        print(f"  {nch} chats (~{np.mean(res[f'{nch}:1']['ntrain_asks']):.0f} asks)  rank:test/train  " + "  ".join(row))
    return res, float(np.mean(frozen))


if __name__ == "__main__":
    out = dict(spikes=spike_count())
    json.dump(out, open("/tmp/claude-0/math/theory/rank_spikes.json", "w"), indent=1)
    if "--sweep" in sys.argv:
        res, fr = sweep()
        out["sweep"], out["frozen"] = res, fr
        json.dump(out, open("/tmp/claude-0/math/theory/rank.json", "w"), indent=1)
