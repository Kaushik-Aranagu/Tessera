"""Reviewer checks for E8 (does not modify the original). Imports an unmodified copy of e8_pyramid_encoder.py.
1. leakage asserts (train chats vs test chats; S5 tuning chats)
2. extra control R3v = RRF(BM25, R4) (same V1 leaf keys as H2) so H2 - R3v isolates the tree term
3. untuned S5 (tau 0.05, beta 0) to see whether S6 - S5 depends on tuning
4. chat-clustered bootstrap (10 chats) for the key pairs, next to the question-level bootstrap
5. independent recompute of every parent K after forgetting, straight from raw bge rows (no Memory/Pyramid code)
6. leaf-perturbation test: after forgetting, scrambling a forgotten leaf's raw vector changes nothing
"""
import collections, os, sys, multiprocessing as mp
import numpy as np
import torch
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import e8_orig_copy as E  # noqa: E402

torch.set_num_threads(1)
chats = E.load_tree("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5", "/tmp/claude-0/sm/dyn-pyramid/cache")
folds = list(range(5))
dkey = os.urandom(32)

# 1. leakage: train_fold's split, re-derived
for f in folds:
    test = {2 * f, 2 * f + 1}
    tr = [c for i, c in enumerate(chats) if i not in test]
    assert not ({c["cid"] for c in tr} & test) and len(tr) == 8
    # no shared question text or turn text between train and test chats
    tq = {q[0] for i in test for q in chats[i]["qs"]}
    trq = {q[0] for c in tr for q in c["qs"]}
    tt = {t for i in test for t in chats[i]["text"]}; trt = {t for c in tr for t in c["text"]}
    print(f"fold {f}: shared question strings {len(tq & trq)}, shared turn strings {len(tt & trt)}", flush=True)

with mp.get_context("fork").Pool(3) as pool:
    trained = pool.map(E.train_fold, [(chats, f, 40) for f in folds])
ctxs = {}
for fold, sd, _ in trained:
    ctxs[fold] = E.Ctx(fold, E.restore(fold, sd))
    tr = [c for i, c in enumerate(chats) if i not in {2 * fold, 2 * fold + 1}]
    ctxs[fold].s5["V1"], _ = E.tune_s5(ctxs[fold]["V1"], tr)
print({f: ctxs[f].s5["V1"] for f in folds}, flush=True)

test_chats = [c for c in chats if c["cid"] // 2 in folds]
glob = [(c["cid"], qi) for c in test_chats for qi in range(len(c["qs"]))]
cats = np.array([chats[ci]["qs"][qi][2] for ci, qi in glob])
chat_of = np.array([ci for ci, _ in glob])


def encs_main(ctx):
    return {"S3": E.Enc("mean", ctx["V1"]), "S4": E.Enc("kmeans", ctx["V1"]), "S6": E.Enc("up", ctx["V1"]), "S6h": E.Enc("up", ctx["V2"])}


res, extra, untuned = {}, collections.defaultdict(dict), {}
mems = {}
for c in test_chats:
    ctx = ctxs[c["cid"] // 2]
    mem = E.build(c, E.orig_struct(c), {t: ctx[t] for t in ("R2", "V1", "V2")}, encs_main(ctx), dkey)
    mems[c["cid"]] = mem
    res[c["cid"]] = E.evaluate(mem, ctx)
    # R3v = RRF(BM25, R4): exactly hyb_m inside evaluate, over all leaves
    n = len(mem.ids); strk = c["strrank"][np.array([c["index"][d] for d in mem.ids])]
    dM = mem.mat("V1") @ ctx.states("V1", c).T
    for qi in range(len(c["qs"])):
        lex = np.lexsort((strk, -mem.bm25.scores(c["qtok"][qi], mem.pos, n)))
        o = E.fuse_np([lex, np.argsort(-dM[:, qi], kind="stable")], n, strk)
        extra[c["cid"]][qi] = tuple(mem.ids[j] for j in o[:10])
    # untuned S5
    keep = ctx.s5["V1"]; ctx.s5["V1"] = (0.05, 0.0)
    untuned[c["cid"]] = E.evaluate(mem, ctx, arms=["S5", "H2-lse"])
    ctx.s5["V1"] = keep


def ev(ci, qi):
    return [chats[ci]["ids"][e] for e in chats[ci]["qs"][qi][1]]


rec = {a: np.array([E.recall(res[ci][a][qi][0], ev(ci, qi)) for ci, qi in glob]) for a in E.ALL_ARMS}
rec["R3v"] = np.array([E.recall(extra[ci][qi], ev(ci, qi)) for ci, qi in glob])
rec["S5u"] = np.array([E.recall(untuned[ci]["S5"][qi][0], ev(ci, qi)) for ci, qi in glob])
rec["H2-lse-u"] = np.array([E.recall(untuned[ci]["H2-lse"][qi][0], ev(ci, qi)) for ci, qi in glob])


def cboot(d, B=10000):
    """Chat-clustered paired bootstrap: resample the 10 test chats with replacement, question-weighted mean."""
    rng = np.random.default_rng(0); ids = np.unique(chat_of)
    sums = np.array([d[chat_of == i].sum() for i in ids]); cnts = np.array([(chat_of == i).sum() for i in ids])
    pick = rng.integers(0, len(ids), (B, len(ids)))
    means = sums[pick].sum(1) / cnts[pick].sum(1)
    return float(d.mean()), float(np.percentile(means, 2.5)), float(np.percentile(means, 97.5))


print("\narm recall@10 (reproduced):", {a: round(float(v.mean()), 4) for a, v in rec.items()}, flush=True)
print("multi-hop:", {a: round(float(v[cats == 1].mean()), 4) for a, v in rec.items()}, flush=True)
pairs = [("S4", "S3"), ("S6", "S5"), ("S6", "S4"), ("S6", "S2"), ("S6", "S5u"), ("S5u", "S5"), ("H2", "R3"), ("H2", "R3v"),
         ("H2-lse", "R3"), ("H2-lse", "R3v"), ("R3v", "R3"), ("S2", "R2"), ("H2-lse", "H2"), ("S6h", "S6"), ("H2-lse-u", "R3v")]
print("\npair                 question-bootstrap            chat-clustered bootstrap", flush=True)
for a, b in pairs:
    d = rec[a] - rec[b]
    q = E.boot(d); cc = cboot(d)
    dm = d[cats == 1]
    print(f"  {a:>8}-{b:<8} {E.fmt(q)}   {E.fmt(cc)}   multi-hop q {E.fmt(E.boot(dm))}", flush=True)
print("per-chat H2-R3:", {int(i): round(float((rec['H2'] - rec['R3'])[chat_of == i].mean()), 3) for i in np.unique(chat_of)}, flush=True)
print("per-chat S6-S4:", {int(i): round(float((rec['S6'] - rec['S4'])[chat_of == i].mean()), 3) for i in np.unique(chat_of)}, flush=True)

# 5./6. forget: independent recompute and perturbation
bad_direct = bad_root = changed_after_perturb = checked = 0
for c in test_chats:
    ctx = ctxs[c["cid"] // 2]; V1, V2 = ctx["V1"], ctx["V2"]
    mem = E.build(c, E.orig_struct(c), {t: ctx[t] for t in ("R2", "V1", "V2")}, encs_main(ctx), dkey)
    rng = np.random.default_rng([0, c["cid"]]); n = len(c["ids"])
    victims = [c["ids"][j] for j in rng.choice(n, int(round(0.2 * n)), replace=False)]
    for d in victims:
        mem.forget(d)
    vs = set(victims)
    for name, g in c["sessions"]:
        surv = [c["ids"][i] for i in g if c["ids"][i] not in vs]
        if not surv:
            assert name not in mem.pyr["S6"].nh
            continue
        raw = np.stack([c["nodes"][c["index"][d]] for d in surv])
        k1 = np.stack([V1.key(x) for x in raw]); k2 = np.stack([V2.key(x) for x in raw])
        direct = {"S6": V1.encode_parent(k1, 1), "S4": V1.encode_parent(k1, 1, zero_o=True),
                  "S3": (lambda v: (v / np.linalg.norm(v))[None])(k1.mean(0)), "S6h": V2.encode_parent(k2, 1)}
        for t, Kd in direct.items():
            checked += 1
            bad_direct += not np.array_equal(Kd, mem.pyr[t].K(name))
    # root, from the direct session Ks
    for t in ("S6", "S4"):
        rows = np.concatenate([mem.pyr[t].K(nd.name) for nd in mem.nodes])
        Kr = V1.encode_parent(rows, 2, zero_o=(t == "S4"))
        bad_root += not np.array_equal(Kr, mem.pyr[t].cache[mem.pyr[t].root]["K"])
    # perturb forgotten leaves' raw vectors: rankings must not change
    before = E.evaluate(mem, ctx)
    saved = {d: c["nodes"][c["index"][d]].copy() for d in victims}
    for d in victims:
        c["nodes"][c["index"][d]] = np.random.default_rng(1).standard_normal(E.DIM).astype(np.float32)
    after = E.evaluate(mem, ctx)
    for d, x in saved.items():
        c["nodes"][c["index"][d]] = x
    changed_after_perturb += sum(before[a][qi][0] != after[a][qi][0] for a in E.ALL_ARMS for qi in before[a])
print(f"\nforget independent check: {checked} session K compared to direct recompute from raw rows, mismatches {bad_direct}; "
      f"root mismatches {bad_root}; top-10 changes after scrambling forgotten raw vectors {changed_after_perturb}", flush=True)
