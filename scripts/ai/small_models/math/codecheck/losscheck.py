"""Code-vs-math audit of e5_bridges.train() on tiny random chats.

Captures the exact scalar the unmodified train() passes to loss.backward() (by wrapping torch.Tensor.backward),
with a stand-in optimizer that (1) randomises every parameter once so that U != 0, the full head != I and the
log-scale != log 20, and (2) never steps. It then recomputes the loss from the written formula in float64 numpy
and compares. Also checks LowRank.forward(x) == x @ LowRank.weight.T, and the closed-form gradients of the
backward term (O6) and of the forward term against autograd.
Read-only use of /tmp/claude-0/sm/e5_bridges.py.
"""
import sys, json
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
import e5_bridges as E  # noqa: E402

torch.set_num_threads(1)
rng = np.random.default_rng(7)
d, r = 12, 3


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def make_chat(N, Q):
    nodes = unit(rng.normal(size=(N, d))).astype(np.float32)
    asks = unit(rng.normal(size=(Q, d))).astype(np.float32)
    qs = []
    for i in range(Q):
        m = int(rng.integers(1, 4))
        ev = sorted(set(rng.choice(min(N, 6), size=m, replace=True).tolist()))  # overlap: evidence among first 6 nodes
        qs.append((f"q{i}", ev, int(rng.integers(1, 5))))
    return dict(nodes=nodes, asks=asks, qs=qs)


chats = [make_chat(9, 5), make_chat(11, 6), make_chat(7, 4)]

# ---------- capture the exact loss train() computes
captured, params_seen = [], []


class FakeOpt:
    def __init__(self, params, **kw):
        self.params = list(params)
        g = torch.Generator().manual_seed(123)
        with torch.no_grad():
            for p in self.params:
                if p.dim() == 0:
                    p.copy_(torch.tensor(np.log(13.7), dtype=p.dtype))
                else:
                    p.add_(0.3 * torch.randn(p.shape, generator=g))
        params_seen.append([p.detach().clone().numpy() for p in self.params])
        self.grads = []

    def zero_grad(self):
        for p in self.params:
            p.grad = None

    def step(self):
        self.grads.append([None if p.grad is None else p.grad.clone().numpy() for p in self.params])


orig_backward = torch.Tensor.backward


def rec_backward(self, *a, **k):
    captured.append(float(self.detach()))
    return orig_backward(self, *a, **k)


E.torch.optim.AdamW = FakeOpt
torch.Tensor.backward = rec_backward


def formula(P, rank, ch, variant="written"):
    """The loss as written in the drafts (float64)."""
    # torch registers the module's own parameter (scale) before the children's: order is scale, state.*, action.*
    if rank:
        lt, Us, Vs, Ua, Va = P            # u: d x r, v: r x d, weight = I + u v
        S = np.eye(d) + Us.astype(np.float64) @ Vs; A = np.eye(d) + Ua.astype(np.float64) @ Va
    else:
        lt, S, A = P[0], P[1].astype(np.float64), P[2].astype(np.float64)
    lam = np.exp(float(lt))
    a = ch["asks"].astype(np.float64); e = ch["nodes"].astype(np.float64)
    s = unit(a @ S.T); k = unit(e @ A.T)            # n(S a_i), n(A e_j)
    L = lam * s @ k.T
    Q, N = L.shape
    pi = np.zeros((Q, N))
    for i, (_, ev, _) in enumerate(ch["qs"]):
        pi[i, ev] = 1.0 / len(ev)
    lsm_row = L - np.log(np.exp(L).sum(1, keepdims=True))
    lsm_col = L - np.log(np.exp(L).sum(0, keepdims=True))
    fwd = -(pi * lsm_row).sum() / Q
    J = pi.sum(0) > 0
    if variant == "written":
        tgt = pi[:, J] / pi[:, J].sum(0, keepdims=True)
        bwd = -(tgt * lsm_col[:, J]).sum() / J.sum()
    elif variant == "unnormalised-col-target":   # a plausible bug: forget the column normalisation
        bwd = -(pi[:, J] * lsm_col[:, J]).sum() / J.sum()
    elif variant == "binary-col-target-over-count":  # uniform 1/|{q: v in P_q}| instead of pi(q|v)
        B = (pi[:, J] > 0).astype(float); tgt = B / B.sum(0, keepdims=True)
        bwd = -(tgt * lsm_col[:, J]).sum() / J.sum()
    elif variant == "mean-over-all-columns":
        tgt = np.zeros_like(pi); tgt[:, J] = pi[:, J] / pi[:, J].sum(0, keepdims=True)
        bwd = -(tgt * lsm_col).sum() / N
    pen = ((S - np.eye(d)) ** 2).sum() + ((A - np.eye(d)) ** 2).sum()
    return fwd + bwd + 0.01 * pen, dict(fwd=fwd, bwd=bwd, pen=pen, lam=lam, s=s, k=k, L=L, pi=pi, J=J)


out = {}
for rank in (r, 0):
    captured.clear(); params_seen.clear()
    E.train(chats, d, 1, seed=0, rank=rank)
    P = params_seen[0]
    rows = []
    for ci, ch in enumerate(chats):
        code = captured[ci]
        mine, parts = formula(P, rank, ch)
        alts = {v: formula(P, rank, ch, v)[0] for v in ("unnormalised-col-target", "binary-col-target-over-count", "mean-over-all-columns")}
        rows.append(dict(chat=ci, code=code, formula=mine, absdiff=abs(code - mine),
                         fwd=parts["fwd"], bwd=parts["bwd"], pen=parts["pen"], lam=parts["lam"],
                         alt_absdiff={k: abs(code - v) for k, v in alts.items()},
                         shared_cited_cols=int(((parts["pi"] > 0).sum(0) > 1).sum())))
    out[f"rank={rank}"] = rows

# ---------- LowRank.weight is the matrix applied by forward
torch.manual_seed(1)
lr = E.LowRank(d, r)
with torch.no_grad():
    lr.u.normal_(); lr.v.normal_()
    x = torch.randn(5, d)
    out["lowrank_forward_vs_weight_maxabs"] = float((lr(x) - x @ lr.weight.T).abs().max())
    out["lowrank_penalty_equals_||uv||F^2"] = float(((lr.weight - torch.eye(d)) ** 2).sum() - ((lr.u @ lr.v) ** 2).sum())
    full = torch.nn.Linear(d, d, bias=False)
    out["linear_forward_vs_weight_maxabs"] = float((full(x) - x @ full.weight.T).abs().max())
# at init: U = 0 so W = I exactly and only u gets a gradient
torch.manual_seed(0)
b0 = E.Bridge(d, r)
out["init_W_minus_I_max"] = float((b0.state.weight - torch.eye(d)).abs().max())
out["init_scale"] = float(b0.scale.exp())

# ---------- gradient checks on one chat (autograd vs closed forms), rank-r parameters from the capture
P = [torch.tensor(p, dtype=torch.float64, requires_grad=False) for p in params_seen[0]] if False else None
ch = chats[1]
lam = 17.0
a = torch.tensor(ch["asks"], dtype=torch.float64); e = torch.tensor(ch["nodes"], dtype=torch.float64)
S = torch.eye(d, dtype=torch.float64) + 0.2 * torch.randn(d, d, dtype=torch.float64, generator=torch.Generator().manual_seed(3))
s = torch.nn.functional.normalize(a @ S.T, dim=-1)
k = torch.nn.functional.normalize(e @ S.T, dim=-1).detach().requires_grad_(True)
Ltt = lam * s @ k.T
pi = torch.zeros_like(Ltt)
for i, (_, ev, _) in enumerate(ch["qs"]):
    pi[i, ev] = 1.0 / len(ev)
J = pi.sum(0) > 0
bwd = -(pi[:, J] / pi[:, J].sum(0) * Ltt[:, J].log_softmax(0)).sum(0).mean()
g_auto, = torch.autograd.grad(bwd, k)
with torch.no_grad():
    sm = Ltt.softmax(0)                      # softmax over asks, per column
    sbar = sm.T @ s                          # N x d: softmax-weighted mean ask for each node
    tgt = torch.zeros_like(pi); tgt[:, J] = pi[:, J] / pi[:, J].sum(0)
    g_formula = -lam * (tgt.T @ s - sbar) / J.sum()
    g_formula[~J] = 0.0
out["O6_backward_key_grad_maxabs_err"] = float((g_auto - g_formula).abs().max())
out["O6_backward_key_grad_scale"] = float(g_auto.abs().max())
# forward-term logit gradient: p - y, divided by Q
Ld = Ltt.detach().clone().requires_grad_(True)
fwd = -(pi * Ld.log_softmax(1)).sum(1).mean()
gL, = torch.autograd.grad(fwd, Ld)
out["forward_logit_grad_err"] = float((gL - (Ld.detach().softmax(1) - pi) / pi.shape[0]).abs().max())

torch.Tensor.backward = orig_backward
print(json.dumps(out, indent=1, default=float))
json.dump(out, open("/tmp/claude-0/math/codecheck/losscheck.json", "w"), indent=1, default=float)
