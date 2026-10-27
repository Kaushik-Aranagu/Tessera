#!/usr/bin/env python3
"""Referee checks, part 1: losses, gradients, bounds (synthetic data, float64). Writes only under this folder."""
import json, math
import numpy as np
import torch

torch.set_default_dtype(torch.float64)
rng = np.random.default_rng(12345)
R = {}


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def rec(name, ok, **info):
    R[name] = dict(ok=bool(ok), **{k: (float(v) if isinstance(v, (np.floating, float)) else v) for k, v in info.items()})
    print(f"[{'ok' if ok else 'FAIL'}] {name} {info}")


# ---------------------------------------------------------------- R1 L_out = uniform soft-target CE = mean log-lik
mx = 0
for t in range(200):
    n = 50; m = int(rng.integers(1, 6)); l = rng.normal(0, 3, n); P = rng.choice(n, m, replace=False)
    lsm = l - np.logaddexp.reduce(l)
    y = np.zeros(n); y[P] = 1 / m
    ce = -(y * lsm).sum(); avg = -lsm[P].mean()
    mx = max(mx, abs(ce - avg))
rec("R1 L_out == H(y,p) == -(1/m) sum_p log p_p", mx < 1e-12, maxdiff=mx)

# ---------------------------------------------------------------- R2 e5 train() terms == formulas (forward/backward)
mxf = mxb = 0
for t in range(50):
    Q, N, d = 12, 40, 8
    S = torch.tensor(unit(rng.normal(size=(Q, d)))); K = torch.tensor(unit(rng.normal(size=(N, d)))); alpha = 20.0
    qs = [sorted(set(rng.choice(N, int(rng.integers(1, 4)), replace=False).tolist())) for _ in range(Q)]
    logits = alpha * S @ K.T
    pos = torch.zeros_like(logits)
    for r, ev in enumerate(qs):
        pos[r, ev] = 1 / len(ev)
    fwd = -(pos * logits.log_softmax(1)).sum(1).mean()
    cols = pos.sum(0) > 0
    bwd = -(pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
    # formulas
    f2 = np.mean([-np.mean([logits[r].log_softmax(0)[v].item() for v in ev]) for r, ev in enumerate(qs)])
    Vp = sorted({v for ev in qs for v in ev}); b2 = 0
    for v in Vp:
        w = np.array([(1 / len(ev)) if v in ev else 0 for ev in qs]); w = w / w.sum()
        b2 += -(w * logits[:, v].log_softmax(0).numpy()).sum()
    b2 /= len(Vp)
    mxf = max(mxf, abs(fwd.item() - f2)); mxb = max(mxb, abs(bwd.item() - b2))
rec("R2 e5 forward == (1/Q) sum_q L_out(q); backward == mean over cited v of CE with pi(q|v)", mxf < 1e-10 and mxb < 1e-10,
    fwd_diff=mxf, bwd_diff=mxb)

# ---------------------------------------------------------------- R3 logit gradients of L_out, L_in, L_mask
okall = True
for t in range(20):
    n, m = 30, int(rng.integers(2, 6))
    l = torch.tensor(rng.normal(0, 3, n), requires_grad=True); P = torch.zeros(n, dtype=torch.bool); P[rng.choice(n, m, replace=False)] = True
    p = l.softmax(0).detach()
    Lout = -(l.log_softmax(0)[P]).mean(); g1, = torch.autograd.grad(Lout, l)
    okall &= torch.allclose(g1, p - P.double() / m)
    Lin = -torch.logsumexp(l.log_softmax(0)[P], 0); g2, = torch.autograd.grad(Lin, l)
    pi = p[P].sum(); okall &= torch.allclose(g2, p - torch.where(P, p / pi, torch.zeros_like(p)))
    okall &= torch.allclose(g2[P], -p[P] * (1 - pi) / pi)
    ZN = torch.logsumexp(l[~P], 0)
    Lm = (torch.logaddexp(l[P], ZN) - l[P]).mean(); g3, = torch.autograd.grad(Lm, l)
    lp = l.detach()[P]; ln = l.detach()[~P]; zn = torch.exp(ZN.detach())
    sig = torch.exp(lp) / (torch.exp(lp) + zn)
    okall &= torch.allclose(g3[P], -(1 - sig) / m)
    okall &= torch.allclose(g3[~P], (torch.exp(ln)[None, :] / (torch.exp(lp)[:, None] + zn)).sum(0) / m)
    okall &= bool((g3[~P] >= p[~P] - 1e-15).all())   # push under L_mask >= push under L_out
rec("R3 gradients of L_out/L_in/L_mask (and L_mask push >= L_out push)", okall)

# ---------------------------------------------------------------- R4 Prop 1.1 bound and Prop 1.2 decomposition
viol = 0; ratio = 0; dec = 0; lim = 0
for t in range(20000):
    n = 120; m = int(rng.integers(1, 6)); k = int(rng.integers(m, 25))
    l = rng.normal(0, rng.uniform(0.3, 4), n)
    if rng.random() < 0.3:  # ties
        l = np.round(l, 0)
    P = np.arange(m); l[P] += rng.normal(rng.uniform(-2, 4), 1, m)
    order = np.argsort(-l, kind="stable")
    # adversarial tie-breaking: put negatives first among ties
    order = sorted(range(n), key=lambda i: (-l[i], 0 if i >= m else 1))
    miss = 1 - len(set(order[:k]) & set(P)) / m
    ZN = np.logaddexp.reduce(l[m:]); ZP = np.logaddexp.reduce(l[:m]); Z = np.logaddexp(ZN, ZP)
    Lm = np.mean(np.logaddexp(l[:m], ZN) - l[:m]); Lo = np.mean(Z - l[:m])
    bnd = Lm / np.log(2 + k - m)
    viol += (miss > bnd + 1e-12) or (Lm > Lo + 1e-12)
    ratio = max(ratio, miss / bnd if bnd > 0 else 0)
    E = np.mean(Z - np.logaddexp(l[:m], ZN)); dec = max(dec, abs(Lo - Lm - E))
rec("R4a Prop 1.1: 1-R@k <= L_mask/log(2+k-m) <= L_out/log(2+k-m) (ties broken against positives)", viol == 0,
    violations=int(viol), max_ratio=ratio)
rec("R4b Prop 1.2: L_out = L_mask + E_q exactly", dec < 1e-10, maxdiff=dec)
# limit Z_N/Z_P -> 0: E -> H(unif, softmax_P) >= log m
m = 4; lp = rng.normal(0, 1, m); Es = []
for shift in (0, 5, 10, 20, 40):
    l = np.concatenate([lp + shift, rng.normal(0, 1, 50)])
    ZN = np.logaddexp.reduce(l[m:]); Z = np.logaddexp.reduce(l)
    Es.append(np.mean(Z - np.logaddexp(l[:m], ZN)))
Hlim = -np.mean(lp - np.logaddexp.reduce(lp))
rec("R4c Prop 1.2 limit E_q -> H(unif(P), softmax_P) >= log m", abs(Es[-1] - Hlim) < 1e-8 and Hlim >= np.log(m), E_seq=[round(e, 5) for e in Es], H=Hlim)

# alpha boundedness under L_out: m_q = 1 separable ask -> L_out strictly decreasing in alpha (no finite optimum)
cpos, cneg = 0.6, rng.uniform(-0.2, 0.5, 100)
Ls = [-(a * cpos - np.logaddexp.reduce(np.concatenate([[a * cpos], a * cneg]))) for a in (10, 20, 50, 100, 1000)]
rec("R4d L_out with m_q=1 and a separable positive is decreasing in alpha (equalizer gives no bound)",
    all(np.diff(Ls) < 0), L=[round(x, 6) for x in Ls])

# ---------------------------------------------------------------- R5 e5 backward-term gradient wrt a key
okg = True
for t in range(20):
    Q, d, alpha = 15, 10, 20.0
    S = torch.tensor(unit(rng.normal(size=(Q, d))))
    kv = torch.tensor(unit(rng.normal(size=d)), requires_grad=True)
    w = np.zeros(Q); idx = rng.choice(Q, 3, replace=False); w[idx] = rng.uniform(0.2, 1, 3); w = torch.tensor(w / w.sum())
    lg = alpha * S @ kv
    L = -(w * lg.log_softmax(0)).sum(); g, = torch.autograd.grad(L, kv)
    sm = lg.softmax(0).detach(); sbar = sm @ S
    pred = -alpha * (w[:, None] * (S - sbar[None, :])).sum(0)
    okg &= torch.allclose(g, pred)
    # gradient wrt the ask states is non-zero (the term also shapes S, not only the keys)
    S2 = S.clone().requires_grad_(True); L2 = -(w * (alpha * S2 @ kv.detach()).log_softmax(0)).sum(); gs, = torch.autograd.grad(L2, S2)
    okg &= gs.abs().max().item() > 1e-6
rec("R5 grad_k of e5 backward CE = -alpha sum_q pi(q|v)(s_q - sbar_v); and grad wrt s_q != 0", okg)

# ---------------------------------------------------------------- R6 L_key gradients (Section 4.3 of Objectives)
okk = True
for t in range(20):
    d, nB, nC, nU, alpha, mu = 12, 25, 2, 4, 20.0, 0.3
    s = torch.tensor(unit(rng.normal(size=d)))
    Bk = torch.tensor(unit(rng.normal(size=(nB, d)))); Bk[0] = s   # bank contains the current ask
    K0 = torch.tensor(unit(rng.normal(size=(nC + nU, d))))
    Kc = (K0 + 0.1 * torch.tensor(rng.normal(size=K0.shape))).requires_grad_(True)
    C, U = list(range(nC)), list(range(nC, nC + nU))
    lsk = alpha * Kc @ s
    ZU = torch.logsumexp(lsk[U], 0)
    t1 = sum(torch.logaddexp(torch.tensor(0.0), ZU - lsk[v]) for v in C) / nC
    t2 = sum(-(alpha * s @ Kc[v] - torch.logsumexp(alpha * Bk @ Kc[v], 0)) for v in C) / nC
    t3 = mu / 2 * ((Kc - K0) ** 2).sum()
    g, = torch.autograd.grad(t1 + t2 + t3, Kc)
    k = Kc.detach(); ls = (alpha * k @ s)
    for v in C:
        sig = torch.exp(ls[v]) / (torch.exp(ls[v]) + torch.exp(ls[U]).sum())
        sb = (alpha * Bk @ k[v]).softmax(0) @ Bk
        pred = -alpha / nC * ((1 - sig) * s + (s - sb)) + mu * (k[v] - K0[v])
        okk &= torch.allclose(g[v], pred)
    for u in U:
        om = sum(torch.exp(ls[u]) / (torch.exp(ls[v]) + torch.exp(ls[U]).sum()) for v in C) / nC
        okk &= torch.allclose(g[u], alpha * om * s + mu * (k[u] - K0[u]))
rec("R6 L_key gradients (pull, push omega_u, centering, anchor) match autograd", okk)

# ---------------------------------------------------------------- R7 Prop 4.1 / Lemma 1(ii): move = projected gradient step
mx1 = mx2 = mx3 = 0
for t in range(200):
    d = 384; k = unit(rng.normal(size=d)); s = unit(rng.normal(size=d) + rng.uniform(-1, 1) * k); eta = rng.uniform(0.01, 0.95)
    move = unit(k + eta * (s - k))
    kt = torch.tensor(k, requires_grad=True); L = 0.5 * ((kt - torch.tensor(s)) ** 2).sum(); g, = torch.autograd.grad(L, kt)
    # finite-difference check of the gradient
    e = 1e-6; fd = np.array([(0.5 * np.sum((k + e * np.eye(d)[i] - s) ** 2) - 0.5 * np.sum((k - e * np.eye(d)[i] - s) ** 2)) / (2 * e) for i in range(0, d, 37)])
    mx3 = max(mx3, np.abs(fd - g.numpy()[::37]).max())
    mx1 = max(mx1, np.abs(move - unit(k - eta * g.numpy())).max())
    mx2 = max(mx2, np.abs(move - unit(k + eta / (1 - eta) * s)).max())
rec("R7 Prop 4.1: unit(k+eta(s-k)) == unit(k - eta grad 1/2|k-s|^2) == unit(k + eta/(1-eta) s); FD gradient", max(mx1, mx2) < 1e-12 and mx3 < 1e-6,
    d1=mx1, d2=mx2, fd=mx3)
# small-eta Riemannian form k' = k + eta (I - k k^T) s + O(eta^2)
errs = []
for eta in (1e-2, 1e-3, 1e-4):
    k = unit(rng.normal(size=50)); s = unit(rng.normal(size=50))
    errs.append(np.linalg.norm(unit(k + eta * (s - k)) - (k + eta * (s - (k @ s) * k))))
rec("R7b Lemma 1(ii): error of Riemannian first-order form is O(eta^2)", errs[1] / errs[0] < 0.02 and errs[2] / errs[1] < 0.02, errs=errs)

# ---------------------------------------------------------------- R8 Lemma 1 second-order expansion (Analysis)
e1 = {}; e2 = {}
for eta in (0.02, 0.1, 0.3):
    a1 = a2 = 0
    for t in range(20000):
        d = 64; k, s, q = unit(rng.normal(size=(3, d)) + 0.6 * unit(rng.normal(size=d)))
        a, c, rho = k @ q, k @ s, s @ q
        ex = unit((1 - eta) * k + eta * s) @ q - a
        f1 = eta * (rho - a * c); f2 = f1 + eta ** 2 * (1 - c) * (rho - 2 * a + 1.5 * a * (1 - c))
        a1 += abs(ex - f1); a2 += abs(ex - f2)
    e1[eta] = a1 / 20000; e2[eta] = a2 / 20000
# third-order scaling check: error of the 2nd-order form shrinks like eta^3
rec("R8 Lemma 1: second-order term correct (residual ~ eta^3)", e2[0.02] / e2[0.1] < (0.2 ** 3) * 1.6, first=e1, second=e2)
# norm identity
k, s = unit(rng.normal(size=(2, 30))); c = k @ s; eta = 0.37
rec("R8b ||(1-eta)k + eta s||^2 = 1 - 2eta(1-c) + 2eta^2(1-c)", abs(np.sum(((1 - eta) * k + eta * s) ** 2) - (1 - 2 * eta * (1 - c) + 2 * eta ** 2 * (1 - c))) < 1e-12)

# ---------------------------------------------------------------- R9 Prop A.5 unroll, angle formula
okA5 = True; okang = True
for t in range(200):
    d, J, eta = 20, 8, rng.uniform(0.05, 0.9)
    k0 = unit(rng.normal(size=d)); Ss = unit(rng.normal(size=(J, d)))
    k = k0.copy(); us = [k0.copy()]
    u = k0.copy()
    for j in range(J):
        knew = unit(k + eta * (Ss[j] - k))
        u = (1 - eta) * u + eta * np.linalg.norm(u) * Ss[j]; us.append(u.copy())
        okA5 &= np.allclose(unit(u), knew)
        th = np.arccos(np.clip(k @ Ss[j], -1, 1)); th2 = np.arccos(np.clip(knew @ Ss[j], -1, 1))
        pred = math.atan2((1 - eta) * math.sin(th), (1 - eta) * math.cos(th) + eta)
        okang &= abs(pred - th2) < 1e-9 and th2 < th + 1e-12
        k = knew
    unrolled = (1 - eta) ** J * k0 + eta * sum((1 - eta) ** (J - j) * np.linalg.norm(us[j - 1]) * Ss[j - 1] for j in range(1, J + 1))
    okA5 &= np.allclose(unrolled, u)
rec("R9 Prop A.5: unrolled form matches iteration; tan-angle formula (atan2 branch) and theta' < theta", okA5 and okang)

# ---------------------------------------------------------------- R10 Prop A.2 anchored cap bound
gam = 0.3; mins = []; maxdist = 0
for t in range(2000):
    d = 384; k0 = unit(rng.normal(size=d)); k = k0.copy()
    tgt = unit(rng.normal(size=d))
    for j in range(int(rng.integers(5, 60))):
        s = unit(tgt + rng.uniform(0, 1.5) * unit(rng.normal(size=d)))
        kk = unit(k + rng.uniform(0.05, 0.9) * (s - k))
        dvec = kk - k0; nn = np.linalg.norm(dvec)
        if nn > gam:
            kk = unit(k0 + dvec * gam / nn)
        k = kk
        mins.append(k @ k0); maxdist = max(maxdist, np.linalg.norm(k - k0))
bnd = math.sqrt(1 - gam ** 2)
rec("R10 Prop A.2: <k,k0> >= sqrt(1-gamma^2) after cap; but |k-k0| can exceed gamma after renormalisation",
    min(mins) >= bnd - 1e-12, min_cos=min(mins), bound=bnd, max_dist=maxdist, gamma=gam,
    dist_limit=math.sqrt(2 - 2 * bnd))

# ---------------------------------------------------------------- R11 Prop A.1 rank(S^T A - I) <= 2r
rk = []
for t in range(5):
    d, r = 384, 16
    US, BS, UA, BA = (rng.normal(size=(d, r)) for _ in range(4))
    S = np.eye(d) + US @ BS.T; A = np.eye(d) + UA @ BA.T
    Dl = S.T @ A - np.eye(d); Dl2 = BS @ US.T + UA @ BA.T + BS @ US.T @ UA @ BA.T
    sv = np.linalg.svd(Dl, compute_uv=False)
    rk.append(int((sv > 1e-9 * sv[0]).sum()))
    assert np.allclose(Dl, Dl2)
rec("R11 Prop A.1: Delta formula exact and rank = 2r generically", all(x == 32 for x in rk), ranks=rk)

# ---------------------------------------------------------------- R12 Prop A.3 numeric: union of two hemispheres
d = 384; c1, c2, b = unit(rng.normal(size=(3, d))); Sx = unit(rng.normal(size=(200000, d)))
frac = np.mean(((Sx @ (c1 - b)) > 0) | ((Sx @ (c2 - b)) > 0))
phi = math.acos(unit(c1 - b) @ unit(c2 - b))
rec("R12 Prop A.3: OR-region share = 1/2 + phi/(2 pi) (about 2/3 for random vectors in high d)", abs(frac - (0.5 + phi / (2 * math.pi))) < 0.005,
    measured=frac, exact=0.5 + phi / (2 * math.pi))

# ---------------------------------------------------------------- R13 xi_m
from math import erf, sqrt, pi, exp, log
def xi(m):
    xs = np.linspace(-12, 12, 400001); ph = np.exp(-xs ** 2 / 2) / sqrt(2 * pi)
    Phi = 0.5 * (1 + np.vectorize(erf)(xs / sqrt(2)))
    return float(np.trapezoid(xs * m * ph * Phi ** (m - 1), xs))
xs_ = {m: xi(m) for m in (2, 4, 16, 64)}
rec("R13 xi_m = E max of m std normals (0.564, 1.029, 1.766, 2.344) and <= sqrt(2 ln m)",
    all(abs(xs_[m] - v) < 6e-4 for m, v in zip((2, 4, 16, 64), (0.564, 1.029, 1.766, 2.344))) and all(xs_[m] <= sqrt(2 * log(m)) for m in xs_),
    xi={m: round(v, 4) for m, v in xs_.items()})

# ---------------------------------------------------------------- R14 Prop 2.3 LSE sandwich + composition; mean-LSE breaks composition
x = rng.normal(0, 0.1, 50); groups = np.split(rng.permutation(50), [7, 20, 38]); tau = 0.05
lse = lambda v: tau * np.logaddexp.reduce(np.asarray(v) / tau)
mlse = lambda v: tau * (np.logaddexp.reduce(np.asarray(v) / tau) - np.log(len(v)))
comp = lse([lse(x[g]) for g in groups]); direct = lse(x)
mcomp = mlse([mlse(x[g]) for g in groups]); mdirect = mlse(x)
rec("R14 sum-LSE composes across levels; sandwich max <= LSE <= max + tau log n", abs(comp - direct) < 1e-12 and x.max() <= direct <= x.max() + tau * np.log(50) + 1e-12)
rec("R14b mean-LSE (Analysis section's definition) does NOT compose with unequal subtree sizes", abs(mcomp - mdirect) > 1e-4,
    mean_lse_composed=mcomp, mean_lse_direct=mdirect, offset_tau_log_33_over_15=0.05 * np.log(33.5 / 15))

json.dump(R, open("/tmp/claude-0/math/referee/checks1.json", "w"), indent=1, default=str)
