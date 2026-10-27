#!/usr/bin/env python3
"""Reviewer's independent re-implementation of the non-learned arms of second_hop.py, plus per-question outputs for
chat-level (cluster) bootstrap and an oracle-start diagnostic. Session mapping is taken from the dia_id prefix (D<n>:),
not from the session_N keys, as a cross-check. The learned hop is rebuilt with the per-fold settings that the original
script's inner CV chose (read from the original results.json), using the verify copy's train_hop.
"""
import collections, json, os, pickle, re, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from e5_bridges import train, tokens, bm25_rank, fuse  # noqa: E402
import second_hop as sh  # noqa: E402  (verify copy, byte-identical to the original)

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
chats = pickle.load(open(sys.argv[1] if len(sys.argv) > 1 else "/tmp/claude-0/sm/fix-second-hop/chats.pkl", "rb"))
chosen = {s["fold"]: s["chosen"] for s in json.load(open("/tmp/claude-0/sm/fix-second-hop/results.json"))["selection"]}
dim = chats[0]["nodes"].shape[1]


def rec(order, ev, k=10):
    return len(set(list(order)[:k]) & set(ev)) / len(ev)


def rrf(lists, ws, k=60):
    s = collections.defaultdict(float)
    for l, w in zip(lists, ws):
        for p, d in enumerate(l):
            s[int(d)] += w / (k + p + 1)
    return sorted(s, key=lambda d: (-s[d], d))


out = collections.defaultdict(list); chat_of = []; cat_of = []; oracle = collections.defaultdict(list)
for fold in range(5):
    test = [2 * fold, 2 * fold + 1]; tr = [i for i in range(10) if i not in test]
    b = train([chats[i] for i in tr], dim, 40, fold, rank=16)
    with torch.no_grad():
        P = {i: (b.a(torch.tensor(chats[i]["nodes"])).numpy(), b.s(torch.tensor(chats[i]["asks"])).numpy()) for i in tr + test}
    cfg = dict(chosen[fold]); w = cfg.pop("w")
    head = sh.train_hop([chats[i] for i in tr], [P[i] for i in tr], dim, seed=fold, **cfg)
    for i in test:
        c = chats[i]; K, S = P[i]; n = len(c["ids"])
        sess = np.array([int(re.match(r"D(\d+):", d).group(1)) for d in c["ids"]])
        snames = sorted(set(sess.tolist()))
        sdocs = {s: sum((c["docs"][d] for j, d in enumerate(c["ids"]) if sess[j] == s), []) for s in snames}
        for r, (q, ev, cat) in enumerate(c["qs"]):
            chat_of.append(i); cat_of.append(cat)
            sc = K @ S[r]; low = np.argsort(-sc, kind="stable").tolist()
            h1 = low[0]
            # hop-avg-key
            q2 = S[r] + K[h1]; q2 = q2 / np.linalg.norm(q2)
            sec = [h1] + [v for v in np.argsort(-(K @ q2), kind="stable").tolist() if v != h1]
            hk = rrf([low, sec], [1, 1])
            # hop-avg-enc
            x = c["asks"][r] + c["nodes"][h1]; x = x / np.linalg.norm(x)
            with torch.no_grad():
                q2e = b.s(torch.tensor(x)[None]).numpy()[0]
            sec = [h1] + [v for v in np.argsort(-(K @ q2e), kind="stable").tolist() if v != h1]
            he = rrf([low, sec], [1, 1])
            # hop-learned with the fold's chosen setting
            with torch.no_grad():
                q2l = head(torch.tensor(S[r])[None], torch.tensor(K[h1])[None]).numpy()[0]
            sec = [h1] + [v for v in np.argsort(-(K @ q2l), kind="stable").tolist() if v != h1]
            hl = rrf([low, sec], [1, w])
            # pyramid: 3 best sessions by BM25 over concatenated session tokens
            opened = set(bm25_rank(sdocs, snames, tokens(q))[:3])
            pyr = [v for v in low if sess[v] in opened] + [v for v in low if sess[v] not in opened]
            pl = fuse(pyr, low)
            for name, o in (("lowrank", low), ("hop-avg-key", hk), ("hop-avg-enc", he), ("hop-learned", hl),
                            ("pyramid", pyr), ("pyramid|lowrank", pl)):
                out[name].append(rec(o, ev))
            out["_hop1_ok"].append(float(h1 in ev))
            out["_ev_in_opened"].append(float(np.mean([sess[e] in opened for e in ev])))
            # oracle-start diagnostic (scoring only, uses this question's own evidence as hop 1; NOT an arm):
            # for each gold turn g of a >=2-evidence question, does q2 = f(s, k_g) rank the OTHER evidence higher
            # than the plain ask state does? both lists drop g.
            if len(ev) >= 2:
                for g in ev:
                    rest = [e for e in ev if e != g]
                    base_l = [v for v in low if v != g]
                    q2g = S[r] + K[g]; q2g /= np.linalg.norm(q2g)
                    key_l = [v for v in np.argsort(-(K @ q2g), kind="stable").tolist() if v != g]
                    with torch.no_grad():
                        q2gl = head(torch.tensor(S[r])[None], torch.tensor(K[g])[None]).numpy()[0]
                    lrn_l = [v for v in np.argsort(-(K @ q2gl), kind="stable").tolist() if v != g]
                    oracle["cat"].append(cat); oracle["base"].append(rec(base_l, rest))
                    oracle["key"].append(rec(key_l, rest)); oracle["learned"].append(rec(lrn_l, rest))
                    oracle["key_fused"].append(rec(rrf([base_l, key_l], [1, 1]), rest))
    print(f"fold {fold} done", flush=True)

np.savez(os.path.join(HERE, "indep_perq.npz"), chat=np.array(chat_of), cat=np.array(cat_of),
         **{k.replace("|", "_or_"): np.array(v) for k, v in out.items()})
chat_of = np.array(chat_of); cat = np.array(cat_of); mh = cat == 1; base = np.array(out["lowrank"])
rng = np.random.default_rng(0)
print(f"{len(cat)} questions; multi-hop {mh.sum()}")
for name in ("lowrank", "hop-avg-key", "hop-avg-enc", "hop-learned", "pyramid", "pyramid|lowrank"):
    x = np.array(out[name]); d = x - base
    # question-level paired bootstrap
    qb = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
    qbm = [d[mh][rng.integers(0, mh.sum(), mh.sum())].mean() for _ in range(2000)]
    # chat-level (cluster) paired bootstrap: resample the 10 chats
    cb, cbm = [], []
    for _ in range(2000):
        pick = rng.integers(0, 10, 10)
        idx = np.concatenate([np.where(chat_of == p)[0] for p in pick])
        cb.append(d[idx].mean()); m = idx[mh[idx]]; cbm.append(d[m].mean())
    print(f"  {name:<16} {x.mean():.3f} [mh {x[mh].mean():.3f}] d {d.mean():+.3f} q-CI [{np.percentile(qb, 2.5):+.3f},"
          f"{np.percentile(qb, 97.5):+.3f}] chat-CI [{np.percentile(cb, 2.5):+.3f},{np.percentile(cb, 97.5):+.3f}]"
          f"  mh d {d[mh].mean():+.3f} q-CI [{np.percentile(qbm, 2.5):+.3f},{np.percentile(qbm, 97.5):+.3f}]"
          f" chat-CI [{np.percentile(cbm, 2.5):+.3f},{np.percentile(cbm, 97.5):+.3f}]  "
          + " ".join(f"{sh.CATS[k]} {x[cat == k].mean():.3f}" for k in sh.CATS), flush=True)
    per_chat = [round(float(d[chat_of == j].mean()), 3) for j in range(10)]
    print(f"      per-chat delta: {per_chat}")
h = np.array(out["_hop1_ok"]); e = np.array(out["_ev_in_opened"])
print(f"  hop1 is evidence: all {h.mean():.3f} mh {h[mh].mean():.3f}; evidence in opened sessions: all {e.mean():.3f} mh {e[mh].mean():.3f}")
# evidence-pooled share (vs question-averaged)
oc = np.array(oracle["cat"])
for nm in ("base", "key", "learned", "key_fused"):
    v = np.array(oracle[nm]); print(f"  oracle-start {nm:<9} all {v.mean():.3f} mh {v[oc == 1].mean():.3f}  (n pairs {len(v)}, mh {int((oc == 1).sum())})")
