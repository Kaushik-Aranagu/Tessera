#!/usr/bin/env python3
"""Stage 1.1 (prediction P9): does bridge rank matter once the learning rate is tuned per rank on dev chats?

LoCoMo, 5 outer folds (test pair 2f, 2f+1; train on the other 8). Inside each outer fold the 8 training chats form 4
dev pairs; for every rank in {1, 16, 64, full} and every learning rate in the grid, a bridge is trained on 6 chats and
scored on the held-out dev pair. The learning rate with the best mean dev recall@10 is the fold's pick for that rank.
Test chats are never seen by the pick. Seeds are shared across learning rates (common random numbers).
Loss: forward-only L_mask, alpha fixed at 20, 40 epochs, AdamW, 0.01 ||W - I||^2 per head (common.train).

LongMemEval-S transfer: per rank, the learning rate with the best pooled held-out LoCoMo recall over the 5 outer folds
(LoCoMo is pure training data for this test), then one bridge trained on all 10 chats, scored on the 428 questions.
Label-free centring on LongMemEval-S: each haystack's keys minus that haystack's mean user-turn vector; the question
minus the mean of the other 427 questions; both renormalised. No labels, no training.

Pass bar (front matter 1.1): LoCoMo held-out recall varies by less than 0.01 across ranks and the LongMemEval-S gap
closes; centring beats frozen on LongMemEval-S (above 0.860). Fails if a rank effect above 0.01 survives tuning with a
chat-clustered interval.
Usage: python s11_rank.py [--procs 4] [--out results/s11_rank.json]
"""
import argparse, collections, json, os, sys, time
from multiprocessing import Pool
import numpy as np
import torch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

RANKS = [1, 16, 64, 0]
LRS = [3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2]
CH = None


def name(rank):
    return "full" if rank == 0 else f"r{rank}"


def job(spec):
    kind, f, rank, lr, extra = spec
    torch.set_num_threads(1)
    test = C.FOLDS[f]; tr = [i for i in range(10) if i not in test]
    if kind == "dev":
        pair = extra; fit = [i for i in tr if i not in pair]
        b = C.train([CH[i] for i in fit], rank, lr, seed=1000 + 10 * f + pair[0])
        xs = [x for i in pair for x in C.chat_recalls(b, CH[i])]
        return spec, dict(sum=float(np.sum(xs)), n=len(xs))
    if kind == "test":
        b = C.train([CH[i] for i in tr], rank, lr, seed=f)
        out = {}
        for i in test:
            out[i] = dict(dense=C.chat_recalls(b, CH[i]), hybrid=C.chat_recalls(b, CH[i], hybrid=True))
        return spec, dict(per=out, drift=b.drift(), state={k: v.numpy() for k, v in b.state_dict().items()})
    if kind == "all":
        b = C.train(CH, rank, lr, seed=0)
        return spec, dict(drift=b.drift(), state={k: v.numpy() for k, v in b.state_dict().items()})
    raise ValueError(kind)


def lme_eval(items, texts, vec, b=None, center=False):
    """Per-question turn recall@10 (dense and fused with BM25) on the 428 LongMemEval-S questions."""
    allq = np.array([it["q"] for it in items]); qsum = allq.sum(0)
    dense, hybrid = [], []
    for it in items:
        K = vec[it["rows"]]; q = it["q"]
        if center:
            K = C.unit(K - K.mean(0)); q = C.unit(q - (qsum - q) / (len(items) - 1))
        if b is not None:
            K = b.key_np(K); q = b.state_np(q)[0]
        o = C.order_of(K @ q)
        dense.append(C.recall(o, it["ev"])); hybrid.append(C.recall(C.fuse(it["lexorder"], o), it["ev"]))
    return dense, hybrid


def main():
    global CH
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--procs", type=int, default=4)
    p.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "results", "s11_rank.json"))
    a = p.parse_args()
    t0 = time.time()
    CH = C.load_locomo()
    specs = []
    for f in range(5):
        tr = [i for i in range(10) if i not in C.FOLDS[f]]
        for rank in RANKS:
            for lr in LRS:
                specs += [("dev", f, rank, lr, pair) for pair in C.inner_pairs(tr)]
                specs.append(("test", f, rank, lr, None))
    with Pool(a.procs) as pool:
        res = dict(pool.imap_unordered(job, specs, chunksize=1))
    print(f"{len(specs)} trainings in {time.time() - t0:.0f} s", flush=True)

    # per question bookkeeping, in fixed chat order
    chat_of = np.array([i for i in range(10) for _ in CH[i]["qs"]])
    cat_of = np.array([q[2] for i in range(10) for q in CH[i]["qs"]])
    nev_of = np.array([len(q[1]) for i in range(10) for q in CH[i]["qs"]])

    def pooled(get):
        """Concatenate per-question values over the 10 chats, each from the outer fold that held it out."""
        return np.array([x for f in range(5) for i in C.FOLDS[f] for x in get(f)[i]])

    out = dict(grid=LRS, ranks=[name(r) for r in RANKS], picks={}, locomo={}, lme={}, untuned_lr1e3={}, by_lr={})
    tuned = {}
    for rank in RANKS:
        picks = []
        for f in range(5):
            tr = [i for i in range(10) if i not in C.FOLDS[f]]
            dev = {lr: sum(res[("dev", f, rank, lr, pair)]["sum"] for pair in C.inner_pairs(tr))
                   / sum(res[("dev", f, rank, lr, pair)]["n"] for pair in C.inner_pairs(tr)) for lr in LRS}
            picks.append(max(LRS, key=lambda lr: (dev[lr], -lr)))
            out["by_lr"].setdefault(name(rank), {})[f"fold{f}_dev"] = {str(lr): round(v, 4) for lr, v in dev.items()}
        out["picks"][name(rank)] = picks
        for mode in ("dense", "hybrid"):
            tuned[(rank, mode)] = pooled(lambda f, m=mode: {i: res[("test", f, rank, picks[f], None)]["per"][i][m] for i in C.FOLDS[f]})
            fixed = pooled(lambda f, m=mode: {i: res[("test", f, rank, 1e-3, None)]["per"][i][m] for i in C.FOLDS[f]})
            out["untuned_lr1e3"].setdefault(name(rank), {})[mode] = round(float(fixed.mean()), 4)
        for lr in LRS:
            v = pooled(lambda f, lr=lr: {i: res[("test", f, rank, lr, None)]["per"][i]["dense"] for i in C.FOLDS[f]})
            out["by_lr"][name(rank)][f"heldout_{lr}"] = round(float(v.mean()), 4)
        out["by_lr"][name(rank)]["drift_at_pick"] = [round(res[("test", f, rank, picks[f], None)]["drift"], 3) for f in range(5)]

    frozen = {m: pooled(lambda f, m=m: {i: C.chat_recalls(None, CH[i], hybrid=(m == "hybrid")) for i in C.FOLDS[f]})
              for m in ("dense", "hybrid")}
    own_center = []
    for i in range(10):
        K = C.unit(CH[i]["nodes"] - CH[i]["nodes"].mean(0)); S = C.unit(CH[i]["asks"] - CH[i]["asks"].mean(0))
        own_center += [C.recall(C.order_of(K @ S[r]), q[1]) for r, q in enumerate(CH[i]["qs"])]
    out["locomo"]["n_questions"] = int(len(chat_of))
    out["locomo"]["frozen"] = {m: round(float(v.mean()), 4) for m, v in frozen.items()}
    out["locomo"]["center_own_chat"] = round(float(np.mean(own_center)), 4)
    for rank in RANKS:
        row = {}
        for mode in ("dense", "hybrid"):
            v = tuned[(rank, mode)]
            row[mode] = round(float(v.mean()), 4)
            row[f"{mode}_by_cat"] = {C.CATS[k]: round(float(v[cat_of == k].mean()), 4) for k in C.CATS}
            row[f"{mode}_multi_evidence"] = round(float(v[nev_of >= 2].mean()), 4)
            d, ci = C.cluster_boot(v - tuned[(16, mode)], chat_of)
            row[f"{mode}_minus_r16"] = [round(d, 4), [round(x, 4) for x in ci]]
            d, ci = C.cluster_boot(v - frozen[mode], chat_of)
            row[f"{mode}_minus_frozen"] = [round(d, 4), [round(x, 4) for x in ci]]
        out["locomo"][name(rank)] = row
    dense_means = [out["locomo"][name(r)]["dense"] for r in RANKS]
    out["locomo"]["spread_dense"] = round(max(dense_means) - min(dense_means), 4)
    worst = []
    for r1 in RANKS:
        for r2 in RANKS:
            if r1 < r2 or (r2 == 0 and r1 != 0):
                d, ci = C.cluster_boot(tuned[(r1, "dense")] - tuned[(r2, "dense")], chat_of)
                worst.append((abs(d), name(r1), name(r2), round(d, 4), [round(x, 4) for x in ci]))
    out["locomo"]["pairs_dense"] = [w[1:] for w in sorted(worst, reverse=True)]

    # LongMemEval-S transfer
    items, texts, vec = C.load_lme()
    lme_lr = {}
    for rank in RANKS:
        lme_lr[rank] = max(LRS, key=lambda lr: (out["by_lr"][name(rank)][f"heldout_{lr}"], -lr))
    with Pool(a.procs) as pool:
        allres = dict(pool.imap_unordered(job, [("all", -1, r, lme_lr[r], None) for r in RANKS]))
    qid = np.arange(len(items))
    base = {}
    fz_d, fz_h = lme_eval(items, texts, vec)
    ce_d, ce_h = lme_eval(items, texts, vec, center=True)
    base["frozen"] = (np.array(fz_d), np.array(fz_h)); base["center"] = (np.array(ce_d), np.array(ce_h))
    bm = np.array([C.recall(it["lexorder"], it["ev"]) for it in items])
    out["lme"]["n_questions"] = len(items)
    out["lme"]["bm25"] = round(float(bm.mean()), 4)
    for nm in ("frozen", "center"):
        out["lme"][nm] = {"dense": round(float(base[nm][0].mean()), 4), "hybrid": round(float(base[nm][1].mean()), 4)}
    d, ci = C.cluster_boot(base["center"][0] - base["frozen"][0], qid)
    out["lme"]["center_minus_frozen"] = [round(d, 4), [round(x, 4) for x in ci]]
    lme_r = {}
    for rank in RANKS:
        st = allres[("all", -1, rank, lme_lr[rank], None)]
        b = C.Bridge(384, rank); b.load_state_dict({k: torch.as_tensor(v) for k, v in st["state"].items()})
        dd, hh = lme_eval(items, texts, vec, b)
        lme_r[rank] = (np.array(dd), np.array(hh))
        row = {"lr": lme_lr[rank], "drift": round(st["drift"], 3), "dense": round(float(np.mean(dd)), 4), "hybrid": round(float(np.mean(hh)), 4)}
        for j, mode in enumerate(("dense", "hybrid")):
            d, ci = C.cluster_boot(lme_r[rank][j] - base["frozen"][j], qid)
            row[f"{mode}_minus_frozen"] = [round(d, 4), [round(x, 4) for x in ci]]
        out["lme"][name(rank)] = row
    for rank in RANKS:
        for j, mode in enumerate(("dense", "hybrid")):
            d, ci = C.cluster_boot(lme_r[rank][j] - lme_r[16][j], qid)
            out["lme"][name(rank)][f"{mode}_minus_r16"] = [round(d, 4), [round(x, 4) for x in ci]]
    lme_dense = [out["lme"][name(r)]["dense"] for r in RANKS]
    out["lme"]["spread_dense"] = round(max(lme_dense) - min(lme_dense), 4)

    # verdict, mechanical
    sig = [p for p in out["locomo"]["pairs_dense"] if abs(p[2]) > 0.01 and (p[3][0] > 0 or p[3][1] < 0)]
    out["verdict"] = dict(
        locomo_spread_below_0_01=out["locomo"]["spread_dense"] < 0.01,
        locomo_rank_effect_above_0_01_with_chat_ci=bool(sig),
        lme_spread_below_0_01=out["lme"]["spread_dense"] < 0.01,
        lme_center_above_0_860=out["lme"]["center"]["dense"] > 0.860,
    )
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump(out, open(a.out, "w"), indent=1)
    np.savez(os.path.join(C.CACHE, "s11_models.npz"),
             **{f"f{f}_{name(r)}_{k}": res[("test", f, r, out['picks'][name(r)][f], None)]["state"][k]
                for f in range(5) for r in RANKS for k in res[("test", f, r, out['picks'][name(r)][f], None)]["state"]},
             **{f"all_{name(r)}_{k}": v for r in RANKS for k, v in allres[("all", -1, r, lme_lr[r], None)]["state"].items()})
    print(json.dumps(dict(picks=out["picks"], locomo={k: out["locomo"][k] for k in ["frozen", "spread_dense"]},
                          lme={k: out["lme"][k] for k in ["frozen", "center", "spread_dense"]}, verdict=out["verdict"]), indent=1))


if __name__ == "__main__":
    main()
