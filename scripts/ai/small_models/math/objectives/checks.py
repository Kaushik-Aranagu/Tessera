#!/usr/bin/env python3
"""Numerical checks of the derivations in the Objectives and Training section (synthetic data only)."""
import numpy as np
import torch

torch.set_default_dtype(torch.float64)
rng = np.random.default_rng(0)
ok = lambda name, cond: print(f"  [{'ok' if cond else 'FAIL'}] {name}")


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


print("C1 gradients of the three multi-positive losses wrt logits")
for trial in range(5):
    n, m = 40, int(rng.integers(2, 6))
    l = torch.tensor(rng.normal(0, 3, n), requires_grad=True)
    P = torch.zeros(n, dtype=torch.bool); P[:m] = True
    p = l.softmax(0)
    # L_out
    Lout = -(l.log_softmax(0)[P]).mean(); g, = torch.autograd.grad(Lout, l)
    y = P.double() / m
    ok(f"L_out grad = p - y (trial {trial})", torch.allclose(g, p - y))
    # L_in
    Lin = -torch.logsumexp(l.log_softmax(0)[P], 0); g, = torch.autograd.grad(Lin, l)
    qpost = torch.where(P, p / p[P].sum(), torch.zeros_like(p))
    ok(f"L_in grad = p - posterior over positives (trial {trial})", torch.allclose(g, p - qpost))
    # masked
    ZN = torch.logsumexp(l[~P], 0)
    Lm = (torch.logaddexp(l[P], ZN) - l[P]).mean(); g, = torch.autograd.grad(Lm, l)
    sig = torch.sigmoid(l - ZN)  # e^l_p / (e^l_p + Z_N)
    gp = -(1 - sig[P]) / m
    gn = (torch.exp(l[~P])[None, :] / (torch.exp(l[P])[:, None] + torch.exp(ZN))).sum(0) / m
    ok(f"masked grad positives = -(1-sigma_p)/|P|, negatives = mean_p e^l_n/(e^l_p+Z_N) (trial {trial})",
       torch.allclose(g[P], gp) and torch.allclose(g[~P], gn))
    # decomposition L_out >= L_mask termwise, L_out >= log|P|
    ok(f"L_out >= L_mask and L_out >= log|P| (trial {trial})", Lout.item() >= Lm.item() - 1e-12 and Lout.item() >= np.log(m) - 1e-12)

print("C2 masked loss bounds the recall@k miss rate: 1 - recall@k <= L_mask / log(2 + k - |P|)")
viol = 0; tight = []
for trial in range(20000):
    n = 200; m = int(rng.integers(1, 6)); k = int(rng.integers(m, 20))
    l = rng.normal(0, rng.uniform(0.5, 5), n); l[:m] += rng.normal(rng.uniform(-1, 4), 1, m)
    order = np.argsort(-l, kind="stable"); topk = set(order[:k])
    miss = 1 - len(topk & set(range(m))) / m
    ZN = np.logaddexp.reduce(l[m:])
    Lm = np.mean(np.logaddexp(l[:m], ZN) - l[:m])
    bound = Lm / np.log(2 + k - m)
    viol += miss > bound + 1e-12; tight.append(miss / bound if bound > 0 else 0)
ok(f"no violations in 20000 random instances (violations {viol}, max ratio miss/bound {max(tight):.3f})", viol == 0)

print("C3 tree union bound: leaf missed => some ancestor out of its level beam (global ranks)")
viol = 0
for trial in range(3000):
    nS, per_s, b, k = 25, 20, 3, 10
    leaf_sess = np.repeat(np.arange(nS), per_s)
    ls = rng.normal(0, 1, nS); ll = rng.normal(0, 1, nS * per_s)
    ev = rng.choice(nS * per_s, int(rng.integers(1, 4)), replace=False)
    ls[leaf_sess[ev]] += rng.uniform(0, 3); ll[ev] += rng.uniform(0, 3)
    beam = set(np.argsort(-ls)[:b])
    cand = [v for v in range(nS * per_s) if leaf_sess[v] in beam]
    got = set(sorted(cand, key=lambda v: -ll[v])[:k])
    glob_s = set(np.argsort(-ls)[:b]); glob_l = set(np.argsort(-ll)[:k])
    for v in ev:
        if v not in got and (leaf_sess[v] in glob_s and v in glob_l):
            viol += 1
ok(f"no leaf missed while all its ancestors are in their global top-b (violations {viol})", viol == 0)

print("C4 move rule = projected gradient step on 1/2||k-s||^2 and on -<k,s> with eta' = eta/(1-eta)")
for trial in range(5):
    d = 384; k = unit(rng.normal(size=d)); s = unit(rng.normal(size=d)); eta = rng.uniform(0.01, 0.9)
    move = unit(k + eta * (s - k))
    kt = torch.tensor(k, requires_grad=True); L = 0.5 * ((kt - torch.tensor(s)) ** 2).sum(); g, = torch.autograd.grad(L, kt)
    pgd = unit(k - eta * g.numpy())
    lin = unit(k + eta / (1 - eta) * s)
    # Euclidean projection onto the sphere: x/|x| is the closest unit vector
    x = k - eta * g.numpy(); cands = unit(rng.normal(size=(2000, d)) * 0.05 + x)
    closest = np.min(np.linalg.norm(cands - x, axis=1)) >= np.linalg.norm(unit(x) - x) - 1e-12
    ok(f"identical steps, projection is nearest point (trial {trial})", np.allclose(move, pgd) and np.allclose(move, lin) and closest)

print("C5 stationary point of the anchored loss E[1/2||k-s||^2] + mu/2||k-k0||^2 on the sphere is unit(E s + mu k0)")
d = 32; k0 = unit(rng.normal(size=d)); mean_dir = unit(rng.normal(size=d))
S = unit(mean_dir + 0.6 * rng.normal(size=(4000, d)) / np.sqrt(d)); mu = 0.7
k = k0.copy()
for t, s in enumerate(np.tile(S, (5, 1))):
    eta = 1.0 / (t + 50)
    k = unit(k - eta * ((k - s) + mu * (k - k0)))
target = unit(S.mean(0) + mu * k0)
ok(f"SGD with 1/t steps converges to unit(mean s + mu k0): cos = {k @ target:.5f}", k @ target > 0.9995)

print("C6 centered pull is the alpha -> 0 limit of the node->ask InfoNCE gradient")
d, nQ = 64, 300
Q = unit(rng.normal(size=(nQ, d)) + 2.0 * unit(rng.normal(size=d)))   # anisotropic ask cloud (common direction)
kv = unit(rng.normal(size=d)); s = Q[0]
for alpha in (0.01, 0.1, 1.0, 20.0):
    kt = torch.tensor(kv, requires_grad=True)
    logits = alpha * torch.tensor(Q) @ kt
    L = -(logits[0] - torch.logsumexp(logits, 0)); g, = torch.autograd.grad(L, kt)
    step = -g.numpy() / alpha
    centered = s - Q.mean(0)
    print(f"    alpha {alpha:>5}: cos(step, s - mean ask) = {unit(step) @ unit(centered):.4f}")
kt = torch.tensor(kv, requires_grad=True); logits = 0.01 * torch.tensor(Q) @ kt
L = -(logits[0] - torch.logsumexp(logits, 0)); g, = torch.autograd.grad(L, kt)
ok("alpha=0.01 step direction matches s - mean(asks)", unit(-g.numpy()) @ unit(s - Q.mean(0)) > 0.999)

print("C7 a single parent vector cannot equal max over children for all asks (convex, not linear)")
d = 16; C = unit(rng.normal(size=(5, d)))
Qs = unit(rng.normal(size=(5000, d)))
target = (Qs @ C.T).max(1)
w, *_ = np.linalg.lstsq(Qs, target, rcond=None)
resid = target - Qs @ w
ok(f"best linear fit leaves residual std {resid.std():.3f} (target std {target.std():.3f})", resid.std() > 0.05)
M = np.vstack([C, C[:2]])
ok("m-prototype max with prototypes = children is exact", np.allclose((Qs @ M.T).max(1), target))

print("C8 mean pooling dilution: margin from one evidence child shrinks as 1/(n |mean|)")
for n in (5, 20, 40):
    d = 384; base = unit(rng.normal(size=d))
    ch = unit(base + 1.0 * rng.normal(size=(n, d)) / np.sqrt(d))
    q = unit(base + 1.0 * rng.normal(size=d) / np.sqrt(d))
    star = unit(q + 0.3 * rng.normal(size=d) / np.sqrt(d))
    with_ev = ch.copy(); with_ev[0] = star
    m0, m1 = unit(ch.mean(0)) @ q, unit(with_ev.mean(0)) @ q
    pred = (star @ q - ch[0] @ q) / (n * np.linalg.norm(with_ev.mean(0)))
    print(f"    n={n:>2}: mean-pool margin {m1 - m0:+.4f}, predicted (c*-c_0)/(n|mean|) {pred:+.4f}, max-pool margin {(with_ev @ q).max() - (ch @ q).max():+.4f}")
