"""Is the logit scale alpha = exp(scale) 'learned' by e5's train(), or pinned by the optimiser budget?

(1) Trajectory of alpha and of d loss / d scale under the unmodified train() (real AdamW, wrapped only to record).
(2) alpha* = argmin over alpha of the training loss with the trained heads held fixed (what the loss wants).
(3) Held-out recall@10 (5 folds, rank 16, e6 protocol without key learning) when the scale gets its own lr
    (copy of train()'s loss lines; only the optimiser param groups differ), and with alpha frozen at 20.
Read-only use of /tmp/claude-0/sm/e5_bridges.py.
"""
import sys, json, math, pickle, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
import e5_bridges as E  # noqa: E402

torch.set_num_threads(1)
D = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
dim = 384
traj = []
RealAdamW = torch.optim.AdamW


class RecAdamW(RealAdamW):
    def step(self, *a, **k):
        sc = [p for g in self.param_groups for p in g["params"] if p.dim() == 0][0]
        g = float(sc.grad)
        out = super().step(*a, **k)
        traj.append((float(sc.detach().exp()), g))
        return out


def loss_terms(b, nodes, asks, qs, alpha=None):
    """Verbatim copy of train()'s loss lines, with an optional alpha override."""
    sc = b.scale.exp() if alpha is None else alpha
    logits = sc * b.s(asks) @ b.a(nodes).T
    pos = torch.zeros_like(logits)
    for r, (_, ev, _) in enumerate(qs):
        pos[r, ev] = 1 / len(ev)
    forward = -(pos * logits.log_softmax(1)).sum(1).mean()
    cols = pos.sum(0) > 0
    backward = -(pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
    return forward, backward


def train_variant(chats, rank, seed, scale_lr=None, fix_alpha=False, epochs=40):
    torch.manual_seed(seed)
    b = E.Bridge(dim, rank)
    head = [p for n, p in b.named_parameters() if n != "scale"]
    groups = [dict(params=head, lr=1e-3)]
    if not fix_alpha:
        groups.append(dict(params=[b.scale], lr=1e-3 if scale_lr is None else scale_lr))
    opt = RealAdamW(groups, lr=1e-3, weight_decay=0.0)
    eye = torch.eye(dim)
    data = [(torch.tensor(c["nodes"]), torch.tensor(c["asks"]), c["qs"]) for c in chats]
    for _ in range(epochs):
        for nodes, asks, qs in data:
            f, bw = loss_terms(b, nodes, asks, qs)
            near = ((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum()
            loss = f + bw + 0.01 * near
            opt.zero_grad(); loss.backward(); opt.step()
    return b


def heldout(b, test):
    xs = []
    with torch.no_grad():
        for i in sorted(test):
            c = D[i]
            K = b.a(torch.tensor(c["nodes"])).numpy(); S = b.s(torch.tensor(c["asks"])).numpy()
            for r, (_, ev, _) in enumerate(c["qs"]):
                top = list(np.argsort(-(K @ S[r]), kind="stable"))
                xs.append(E.recall(top, ev))
    return xs


out = {}
t0 = time.time()
# (1) trajectory, unmodified train(), fold 0
E.torch.optim.AdamW = RecAdamW
for rank in (16, 0):
    traj.clear()
    tr = [c for i, c in enumerate(D) if i not in {0, 1}]
    b = E.train(tr, dim, 40, 0, rank=rank)
    al = [a for a, _ in traj]; gs = np.array([g for _, g in traj])
    out[f"traj rank={rank}"] = dict(steps=len(al), alpha_first=al[0], alpha_at=[al[i] for i in (9, 79, 159, 239, 319)],
                                     max_abs_dlogalpha_per_step=float(np.max(np.abs(np.diff(np.log([20.0] + al))))),
                                     frac_steps_grad_negative=float((gs < 0).mean()),
                                     grad_scale_last40_mean=float(gs[-40:].mean()))
    # (2) alpha* for the trained heads on the training chats (loss as a function of alpha only)
    grid = np.exp(np.linspace(np.log(5), np.log(400), 120))
    with torch.no_grad():
        data = [(torch.tensor(c["nodes"]), torch.tensor(c["asks"]), c["qs"]) for c in tr]
        tot = []
        for a_ in grid:
            v = 0.0
            for nodes, asks, qs in data:
                f, bw = loss_terms(b, nodes, asks, qs, alpha=float(a_))
                v += float(f + bw)
            tot.append(v / len(data))
    out[f"alpha* rank={rank}"] = dict(alpha_star=float(grid[int(np.argmin(tot))]), loss_at_star=float(min(tot)),
                                      loss_at_trained=float(np.interp(al[-1], grid, tot)), trained_alpha=al[-1])
E.torch.optim.AdamW = RealAdamW
out["time_part1_s"] = time.time() - t0

# (3) held-out recall of variants, 5 folds, rank 16
arms = {"code (scale lr 1e-3)": dict(), "alpha fixed 20": dict(fix_alpha=True), "scale lr 3e-2": dict(scale_lr=3e-2)}
per = {k: [] for k in arms}; fin = {k: [] for k in arms}
for fold in range(5):
    test = {2 * fold, 2 * fold + 1}
    tr = [c for i, c in enumerate(D) if i not in test]
    for name, kw in arms.items():
        b = train_variant(tr, 16, fold, **kw)
        per[name] += heldout(b, test); fin[name].append(float(b.scale.exp()))
base = np.array(per["code (scale lr 1e-3)"]); rng = np.random.default_rng(0)
for name in arms:
    d = np.array(per[name]) - base
    bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
    out[f"heldout {name}"] = dict(recall10=float(np.mean(per[name])), diff=float(d.mean()),
                                  ci=[float(np.percentile(bs, 2.5)), float(np.percentile(bs, 97.5))], final_alpha=fin[name])
out["time_total_s"] = time.time() - t0
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/codecheck/scalecheck.json", "w"), indent=1)
