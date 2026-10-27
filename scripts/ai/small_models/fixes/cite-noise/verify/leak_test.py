#!/usr/bin/env python3
"""Leakage test on the claimed script's own run_chat: perturb the evidence of the question visited at position k
(same number of evidence turns, so the shared random streams are unchanged) and check that recall of every visit
before k is bit-identical and the ranking at visit k is identical. Any use of a question's evidence before it is
scored, or of a later question's evidence, would break this."""
import os, pickle, sys
import numpy as np

sys.path.insert(0, "/tmp/claude-0/sm/fix-cite-noise/verify"); sys.path.insert(0, "/tmp/claude-0/sm")
import fix_cite_noise_copy as F  # noqa: E402
from e5_bridges import bm25_rank, tokens, train  # noqa: E402

chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/chats.pkl", "rb"))
for ch in chats[:2]:
    idx = {d: i for i, d in enumerate(ch["ids"])}; ch["lexpos"] = []
    for q, _, _ in ch["qs"]:
        pos = np.empty(len(ch["ids"]), dtype=np.int64)
        pos[[idx[d] for d in bm25_rank(ch["docs"], ch["ids"], tokens(q))]] = np.arange(len(ch["ids"])); ch["lexpos"].append(pos)
    ch["evset"] = [set(ev) for _, ev, _ in ch["qs"]]
b = train([c for i, c in enumerate(chats) if i not in (0, 1)], 384, 40, 0, rank=16)
import torch  # noqa: E402
with torch.no_grad():
    mu0 = np.concatenate([F.project(b, chats[i])[1] for i in range(2, 10)]).mean(0)
scale = float(b.scale.exp().detach())
ch = chats[0]; keys, states = F.project(b, ch)
order = np.random.default_rng(0).permutation(len(ch["qs"])); stream = F.streams_for(ch, 0, 1)[0]
cfgs = {name: cfgs[-1] for name, cfgs in F.ARMS}
cfgs["contrastive"] = dict(eta=0.05, eta_neg=0.03); cfgs["combo"] = dict(eta=0.1, agree=50, eta_neg=0.02, c=1.0)
cfgs["slow-adapter"] = dict(kind="adapter", lam=1.0, alpha=0.5)
fails = 0; checks = 0
for k in (5, 40, 120):
    r = order[k]
    q, ev, cat = ch["qs"][r]
    others = [v for v in range(len(keys)) if v not in ev]
    fake = sorted(np.random.default_rng(k).choice(others, len(ev), replace=False).tolist())
    ch2 = dict(ch); ch2["qs"] = list(ch["qs"]); ch2["qs"][r] = (q, fake, cat)
    ch2["evset"] = list(ch["evset"]); ch2["evset"][r] = set(fake)
    for name, cfg in [("baseline", None)] + list(cfgs.items()):
        for cond in F.MAIN + F.AUDIT:
            x1, h1, _ = F.run_chat(ch, keys, states, cfg, cond, order, stream, mu0, scale, True)
            x2, h2, _ = F.run_chat(ch2, keys, states, cfg, cond, order, stream, mu0, scale, True)
            checks += 1
            if not (np.array_equal(x1[:k], x2[:k]) and np.array_equal(h1[:k], h2[:k])):
                fails += 1; print("LEAK?", k, name, cond)
            if cfg is None:
                break
print(f"{checks} (arm, cond, k) checks, {fails} failures")
