#!/usr/bin/env python3
"""Referee checks, part 2: key-update fixed points, deletion arithmetic, tree bound, conformal bound, spectra."""
import json, math
import numpy as np

rng = np.random.default_rng(777)
R = {}


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def rec(name, ok, **info):
    R[name] = dict(ok=bool(ok), **info)
    print(f"[{'ok' if ok else 'FAIL'}] {name} {info}")


# ---------------------------------------------------------------- S1 Prop 4.2: sphere argmin of sum, and the 1/(1+|u|) step
d = 40; k0 = unit(rng.normal(size=d)); Ss = unit(rng.normal(size=(30, d)) + 1.5 * unit(rng.normal(size=d))); mu = 2.5
target = unit(Ss.sum(0) + mu * k0)
# brute-force Riemannian descent on the sum objective
k = unit(rng.normal(size=d))
for it in range(20000):
    g = (k - Ss).sum(0) + mu * (k - k0)
    k = unit(k - 1e-3 * (g - (g @ k) * k))
rec("S1a Prop 4.2: argmin_sphere sum 1/2|k-s_t|^2 + mu/2|k-k0|^2 = unit(sum s_t + mu k0)", k @ target > 1 - 1e-10, cos=float(k @ target))
u = mu * k0; kk = unit(u)
for s in Ss:
    eta = 1 / (1 + np.linalg.norm(u))
    kk = unit(kk + eta * (s - kk)); u = u + s
rec("S1b move rule with eta_t = 1/(1+|u_t|) reproduces unit(running sum) exactly", np.allclose(kk, unit(u)), cos=float(kk @ unit(u)))
# objectives' check C5 uses the MEAN version: unit(mean s + mu k0) != unit(sum s + mu k0)
rec("S1c note: unit(mean s + mu k0) differs from unit(sum s + mu k0) for the same mu",
    True, cos_between=float(unit(Ss.mean(0) + mu * k0) @ target))

# ---------------------------------------------------------------- S2 commutative key vs centered move, 1/2/3 cites (Analysis P8b)
dev = {1: [], 2: [], 3: []}
for t in range(2000):
    d = 64; k0 = unit(rng.normal(size=d)); T = unit(rng.normal(size=(3, d)) + 0.5 * k0); eta = 0.1; lam = eta / (1 - eta)
    k = k0.copy()
    for n in (1, 2, 3):
        k = unit(k + eta * (T[n - 1] - k))
        comm = unit(k0 + lam * T[:n].sum(0))
        dev[n].append(1 - k @ comm)
rec("S2 additive key unit(k0 + lam sum t) vs move steps: equal for 1 cite, differ (2nd order) already at 2 cites",
    max(dev[1]) < 1e-12 and np.mean(dev[2]) > 1e-8, mean_1_minus_cos={n: float(np.mean(v)) for n, v in dev.items()})

# ---------------------------------------------------------------- S3 floating-point decrement is not bit-exact
bad = 0; N = 20000
for t in range(N):
    base = rng.normal(size=384).astype(np.float32)
    others = rng.normal(size=(5, 384)).astype(np.float32)
    x = rng.normal(size=384).astype(np.float32)
    with_x = base + others.sum(0, dtype=np.float32) + x
    dec = with_x - x
    never = base + others.sum(0, dtype=np.float32)
    bad += not np.array_equal(dec, never)
rec("S3 float32 'u - s_t' is not bitwise equal to the never-added sum (exactness needs canonical recomputation)", bad > 0,
    share_not_bit_equal=bad / N)

# ---------------------------------------------------------------- S4 Prop 2.4 coverage bound, full statement (3 levels)
viol = 0; worst = 0; trials = 3000
for t in range(trials):
    n2, f1, f0 = 6, 5, 8                       # level-2 nodes, children per level-2, leaves per level-1
    V2 = np.arange(n2); V1 = np.arange(n2 * f1); V0 = np.arange(n2 * f1 * f0)
    par1 = V1 // f1; par0 = V0 // f0
    alpha = 5.0
    s2 = rng.normal(0, 1, n2); s1 = rng.normal(0, 1, len(V1)); s0 = rng.normal(0, 1, len(V0))
    P = rng.choice(len(V0), int(rng.integers(1, 4)), replace=False)
    boost = rng.uniform(0, 3, len(P)); s0[P] += boost; s1[par0[P]] += boost * rng.uniform(0, 1); s2[par1[par0[P]]] += boost * rng.uniform(0, 1)
    b2, b1, b0 = 2, 4, 6
    anc = {0: P, 1: par0[P], 2: par1[par0[P]]}
    sc = {0: s0, 1: s1, 2: s2}; b = {0: b0, 1: b1, 2: b2}
    m = {l: len(set(anc[l].tolist())) for l in anc}
    if any(m[l] > b[l] for l in m):
        continue
    # beam search
    beam2 = set(np.argsort(-s2, kind="stable")[:b2].tolist())
    c1 = [v for v in V1 if par1[v] in beam2]; beam1 = set(sorted(c1, key=lambda v: -s1[v])[:b1])
    c0 = [v for v in V0 if par0[v] in beam1]; got = set(sorted(c0, key=lambda v: -s0[v])[:b0])
    miss = 1 - len(got & set(P.tolist())) / len(P)
    L = 0
    for l in (0, 1, 2):
        pos_set = set(anc[l].tolist()); neg = np.array([u for u in range(len(sc[l])) if u not in pos_set])
        lam = 1 / math.log(2 + b[l] - m[l])
        L += lam * np.mean([np.logaddexp(0, np.logaddexp.reduce(alpha * (sc[l][neg] - sc[l][a]))) for a in anc[l]])
    viol += miss > L + 1e-12; worst = max(worst, miss / L if L > 0 else 0)
rec("S4 Prop 2.4: 1 - R_tree <= L_hier on random 3-level trees", viol == 0, violations=int(viol), max_ratio=worst)

# ---------------------------------------------------------------- S5 Prop 8 conformal fire rate bound
for nref, K in ((150, 10), (40, 5)):
    fires = 0; T = 40000
    for t in range(T):
        # anisotropic exchangeable ask cloud
        mu = np.array([0.8] + [0.0] * 15)
        X = unit(mu + rng.normal(0, 0.3, size=(nref + 2, 16)))
        a, q, ref = X[0], X[1], X[2:]
        rK = np.sort(ref @ a)[-K]
        fires += (a @ q) > rK
    rec(f"S5 Prop 8: Pr[<a,q> > r_K(a)] <= K/(n_ref+1) (n_ref={nref}, K={K})", fires / T <= K / (nref + 1) + 3 * math.sqrt(K / (nref + 1) / T),
        rate=fires / T, bound=K / (nref + 1))

# ---------------------------------------------------------------- S6 Prop 13: quarter-circle ratio and the Weyl-type bound
E = rng.normal(size=(384, 384)) / math.sqrt(384)
rec("S6a ||E||_F / ||E||_op ~ sqrt(d)/2 for an iid 384x384 matrix", True, ratio=float(np.linalg.norm(E) / np.linalg.norm(E, 2)), sqrt_d_over_2=math.sqrt(384) / 2)
viol = 0
for t in range(300):
    d, r = 60, int(rng.integers(1, 8))
    U = np.linalg.qr(rng.normal(size=(d, d)))[0]; Vv = np.linalg.qr(rng.normal(size=(d, d)))[0]
    sig = np.sort(rng.exponential(1, d))[::-1] * rng.uniform(0.1, 3)
    G = U @ np.diag(sig) @ Vv.T; En = rng.normal(0, rng.uniform(0.01, 1), size=(d, d))
    Gh = G + En
    def trunc(M, r):
        u, s, vt = np.linalg.svd(M); return (u[:, :r] * s[:r]) @ vt[:r]
    lhs = np.linalg.norm(trunc(Gh, r) - G)
    rhs = np.linalg.norm(G - trunc(G, r)) + 2 * math.sqrt(2 * r) * (sig[r] + np.linalg.norm(En, 2))
    viol += lhs > rhs + 1e-9
rec("S6b Prop 13 bound ||G^_r - G||_F <= ||G - G_r||_F + 2 sqrt(2r)(sigma_{r+1} + ||E||_op)", viol == 0, violations=int(viol))

# ---------------------------------------------------------------- S7 Prop 4 ODE closed form and t*
lam, W0 = 0.1 * 0.229 / 0.048, 0.034
ts = np.linspace(0, 0.95 / (lam * W0), 2000); n = np.zeros_like(ts)
for i in range(1, len(ts)):
    dt = ts[i] - ts[i - 1]; n[i] = n[i - 1] + dt * W0 * math.exp(lam * n[i - 1])
closed = -np.log(1 - lam * W0 * ts) / lam
rec("S7 Prop 4: n(t) = -ln(1 - lam W0 t)/lam solves dn/dt = W0 e^{lam n}; t* = beta/(eta h W0)",
    abs(n[-1] - closed[-1]) / closed[-1] < 0.02, tstar_top5=0.048 / (0.1 * 0.229 * 0.034), tstar_leader=0.048 / (0.1 * 0.229 * 0.047),
    tstar_eta002_top5=0.0476 / (0.0046 * 0.034), tstar_eta002_leader=0.0476 / (0.0046 * 0.047))

# ---------------------------------------------------------------- S8 Prop 7 invariances of the bidirectional loss
def bi_loss(L, pos):
    fw = -(pos * (L - np.logaddexp.reduce(L, axis=1, keepdims=True))).sum(1).mean()
    cols = pos.sum(0) > 0; pc = pos[:, cols] / pos[:, cols].sum(0)
    bw = -(pc * (L[:, cols] - np.logaddexp.reduce(L[:, cols], axis=0, keepdims=True))).sum(0).mean()
    return fw, bw
Q, N = 10, 30; L = rng.normal(size=(Q, N)); pos = np.zeros((Q, N))
for i in range(Q):
    ev = rng.choice(N, 2, replace=False); pos[i, ev] = 0.5
row = rng.normal(size=(Q, 1)); col = rng.normal(size=(1, N))
f0, b0 = bi_loss(L, pos); f1, b1 = bi_loss(L + row, pos); f2, b2 = bi_loss(L + col, pos); f3, b3 = bi_loss(L + 0.7, pos)
rec("S8 Prop 7: forward blind to row offsets, backward blind to column offsets, sum blind only to the global constant",
    abs(f1 - f0) < 1e-12 and abs(b2 - b0) < 1e-12 and abs(b1 - b0) > 1e-3 and abs(f2 - f0) > 1e-3 and abs(f3 + b3 - f0 - b0) < 1e-12)

# ---------------------------------------------------------------- S9 Analysis Prop 2: Delta theta_K can be negative
# d is in the top K-1 for q (so theta_K unaffected by a rise) but the move toward s LOWERS d's score on q
d_ = 8; K = 3
q = unit(np.array([1.0, 0, 0, 0, 0, 0, 0, 0])); s = unit(np.array([0.2, 1, 0, 0, 0, 0, 0, 0]))
others = np.array([0.9, 0.8, 0.5, 0.45, 0.4]); kd = unit(np.array([0.85, -0.5, 0, 0, 0, 0, 0, 0]))
sc_before = np.concatenate([others, [kd @ q]]); theta_before = np.sort(sc_before)[-K]
kd2 = unit(kd + 0.3 * (s - kd)); sc_after = np.concatenate([others, [kd2 @ q]]); theta_after = np.sort(sc_after)[-K]
rec("S9 Analysis Prop 2: a wrong pull can LOWER theta_K (Delta theta_K < 0) when rho - a_d c_d < 0", theta_after < theta_before,
    rho_minus_ac=float(s @ q - (kd @ q) * (kd @ s)), dtheta=float(theta_after - theta_before))

# ---------------------------------------------------------------- S10 Prop 12 Cauchy-Schwarz bound by simulation
m = 20; pi_ = rng.dirichlet(np.ones(m) * 0.3); Delta, sd = 0.3, 0.1
def dprime(alpha):
    return (alpha @ pi_) * Delta / (sd * np.linalg.norm(alpha))
best = dprime(pi_); mean_ = dprime(np.ones(m) / m)
rand_max = max(dprime(rng.dirichlet(np.ones(m))) for _ in range(20000))
rec("S10 Prop 12: query-independent pool d' <= ||pi||_2 Delta/s, attained at alpha ~ pi; mean gives m^-1/2",
    rand_max <= best + 1e-12 and abs(best - np.linalg.norm(pi_) * Delta / sd) < 1e-12 and abs(mean_ - Delta / sd / math.sqrt(m)) < 1e-12)

# ---------------------------------------------------------------- S11 identities (Lemma 5, Lemma 9) and Prop 10 consistency
X = unit(rng.normal(size=(50, 30)) + 1.2 * unit(rng.normal(size=30))); n = len(X); mu = X.mean(0)
G = X @ X.T; off = (G.sum() - n) / (n * (n - 1))
rec("S11a Lemma 5/9: mean pairwise cosine = (n|mu|^2 - 1)/(n-1); |mean|^2 = 1/n + (1-1/n) rho", abs(off - (n * mu @ mu - 1) / (n - 1)) < 1e-12 and abs(mu @ mu - (1 / n + (1 - 1 / n) * off)) < 1e-12)
pred_frozen = 0.665 / (1 / 21.6 + (1 - 1 / 21.6) * 0.687); pred_bridge = 0.267 / (1 / 21.6 + (1 - 1 / 21.6) * 0.319)
rec("S11b Prop 10 consistency: parent-parent cos ~ |mu|^2 / E|xbar|^2 predicted from measured inputs", abs(pred_frozen - 0.946) < 0.01 and abs(pred_bridge - 0.756) < 0.01,
    pred_frozen=pred_frozen, meas_frozen=0.946, pred_bridge=pred_bridge, meas_bridge=0.756)
# Lemma 5 against the reported geometry
rec("S11c Lemma 5 vs reported means: |mu|^2 vs ask-ask; <mu,mu_k> vs ask-node", True,
    frozen=(0.742 ** 2, 0.742 * 0.814 * 0.877), bridge=(0.560 ** 2, 0.560 * 0.517 * 0.339),
    gap_frozen=math.sqrt(0.742 ** 2 + 0.814 ** 2 - 2 * 0.742 * 0.814 * 0.877), gap_bridge=math.sqrt(0.560 ** 2 + 0.517 ** 2 - 2 * 0.560 * 0.517 * 0.339))

# ---------------------------------------------------------------- S12 arithmetic in the drafts
a = {}
a["view params 2dr"] = 2 * 384 * 16
a["two full heads 2d^2"] = 2 * 384 ** 2
a["per ask full / lowrank"] = (2 * 384 ** 2 / 1225, 4 * 384 * 16 / 1225)
a["LoRA r16 Qwen3-8B attn"] = 36 * 16 * (2 * 8192 + 2 * 5120)
a["Pi params dp=1024"] = 4096 * 1024 + 1024 * 384
a["P params dp=1024 ms=1"] = 384 * 1024 + 1024 * 4096
a["KV bytes/token fp16"] = 36 * 2 * 8 * 128 * 2
a["KV(100 tok)/768B"] = 100 * 36 * 2 * 8 * 128 * 2 / 768
a["log2(588)"] = math.log2(588)
a["full heads / label bits"] = 294912 / (math.log2(588) * 1225)
a["move unrelated drift 0.1(0.308-0.379*0.100)"] = 0.1 * (0.308 - 0.379 * 0.100)
a["g/(h eta) eta=.1, .02"] = (0.253 / (0.266 * 0.1), 0.253 / (0.266 * 0.02))
a["same with n_v/2 as in eq (4)"] = (2 * 0.253 / (0.266 * 0.1), 2 * 0.253 / (0.266 * 0.02))
a["cap bound W<=W0 e^{zeta|mu|/beta}"] = 0.034 * math.exp(0.3 * 0.560 / 0.048)
# self-feedback predictions 0.653 (alpha - beta p_self) with p_self = 0.748 for all eta vs per-eta realised p_self
lines = {0.02: (0.0057, 0.0140, 0.652), 0.05: (0.0147, 0.0351, 0.683), 0.1: (0.0199, 0.0727, 0.748), 0.2: (-0.0024, 0.1349, 0.821)}
a["self pred with p=0.748 fixed"] = {e: 0.653 * (al - be * 0.748) for e, (al, be, _) in lines.items()}
a["self pred with realised p_self"] = {e: 0.653 * (al - be * p) for e, (al, be, p) in lines.items()}
# p* from components
comp = {0.02: (0.0106, 0.0031, 0.0046, 0.0054), 0.05: (0.0266, 0.0111, 0.0123, 0.0123), 0.1: (0.0500, 0.0175, 0.0296, 0.0462), 0.2: (0.0859, 0.0381, 0.0876, 0.1095), "c0.1": (0.0317, 0.0072, 0.0082, 0.0126)}
a["p* eq (3)"] = {str(e): (B - Hc) / (B + D + Hw - Hc) for e, (B, D, Hc, Hw) in comp.items()}
a["B/(B+D)"] = {str(e): B / (B + D) for e, (B, D, Hc, Hw) in comp.items()}
# endpoint-interpolation misses (in-sample criterion of prediction P2: 0.005)
meas = {0.02: (0.0060, 0.0011, -0.0024, -0.0085), 0.05: (0.0143, 0.0048, -0.0067, -0.0233), 0.1: (0.0204, -0.0029, -0.0232, -0.0636), 0.2: (-0.0016, -0.0443, -0.0826, -0.1476)}
a["endpoint misses at p=.3,.6"] = {e: (abs(0.7 * v[0] + 0.3 * v[3] - v[1]), abs(0.4 * v[0] + 0.6 * v[3] - v[2])) for e, v in meas.items()}
a["coverage ceiling check: multi-hop share>3 * avg loss"] = None
a["visible: B_vis - H"] = 0.0165 - 0.0189
a["gated unrelated part = 0.556 H_c?"] = (0.556 * 0.0296, 0.0063 / 0.556)
a["centered: H_c drop, B drop"] = (1 - 0.0082 / 0.0296, 1 - 0.0317 / 0.0500)
a["rank-1 gain share recovered by centering"] = (0.609 - 0.575) / (0.667 - 0.575)
a["dilution: 1/4 of mean->LSE gap by ridge, distilled-8 share"] = ((0.556 - 0.500) / (0.724 - 0.500), (0.653 - 0.500) / (0.724 - 0.500))
a["tau log n for n=15..33.5 at tau=.05"] = (0.05 * math.log(15), 0.05 * math.log(33.5))
for k_, v in a.items():
    print(f"   {k_}: {v}")
R["S12 arithmetic"] = {k_: (str(v)) for k_, v in a.items()}

json.dump(R, open("/tmp/claude-0/math/referee/checks2.json", "w"), indent=1, default=str)
