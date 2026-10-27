#!/usr/bin/env python3
"""Brute-force check of alias_hub.Plane's incremental hub scores r(k), r(a): recompute from scratch at every visit and
compare the score vectors. Uses one held-out chat with the fold's real bridge."""
import os, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from e5_bridges import train  # noqa: E402
import alias_hub_verify as ah  # noqa: E402

torch.set_num_threads(1)
chats = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
dim = chats[0]["nodes"].shape[1]
fold = 1; test = [2, 3]; train_ids = [i for i in range(10) if i not in test]
b = train([chats[i] for i in train_ids], dim, 40, fold, rank=16)
with torch.no_grad():
    ref = np.concatenate([b.s(torch.tensor(chats[i]["asks"])).numpy() for i in train_ids])


def brute_scores(keys, A, owner, origin, states, order, t, c, s):
    K = c["hubk"]
    chat = np.array([states[order[u]] for u in range(t)]) if t else np.zeros((0, keys.shape[1]), np.float32)
    base = keys @ s
    if c["csls"]:
        R = np.concatenate([ref, chat]) if t else ref
        rk = np.sort(keys @ R.T, 1)[:, -K:].mean(1)
        key = 2 * base - rk
    else:
        key = base
    if not len(A):
        return key
    al = []
    for m in range(len(A)):
        if K:
            rows = [u for u in range(t) if u != origin[m]]
            R = np.concatenate([ref, np.array([states[order[u]] for u in rows])]) if rows else ref
            ra = np.sort(R @ A[m])[-K:].mean()
        else:
            ra = 0.0
        x = A[m] @ s
        al.append((2 * x - ra if c["csls"] else x - ra) - c["margin"])
    al = np.array(al)
    if c["combine"] == "max":
        best = np.full(len(key), -np.inf); np.maximum.at(best, owner, al); return np.maximum(key, best)
    best = np.zeros(len(key)); np.maximum.at(best, owner, np.maximum(al, 0)); return key + c["beta"] * best


worst = 0.0
for i in test[:1]:
    ch = chats[i]; keys, states, aviews = ah.project(b, ch)
    order = np.random.default_rng(100 * fold + 10 * i).permutation(len(ch["qs"]))[:60]
    for c in [ah.cfg("bonus", "alias", combine="add", hubk=10, beta=1.0), ah.cfg("csls", "alias", hubk=3, csls=True),
              ah.cfg("act bonus", "alias", view="action", combine="add", hubk=10, beta=2.0),
              ah.cfg("margin", "alias", margin=0.3)]:
        plane = ah.Plane(keys, c, ref, 10000)
        A, owner, origin = [], [], []
        for t, r in enumerate(order):
            s = states[r]
            inc = plane.scores(s); bf = brute_scores(keys, np.array(A), np.array(owner, int), origin, states, order, t, c, s)
            err = np.abs(inc - bf).max(); worst = max(worst, err)
            ev = ch["qs"][r][1]
            for v in ev:
                plane.learn(int(v), s, aviews[r], t)
                A.append(aviews[r] if c["view"] == "action" else s); owner.append(int(v)); origin.append(t)
            plane.observe(s, t)
        print(c["name"], "max abs diff so far", worst, flush=True)
print("WORST", worst)
