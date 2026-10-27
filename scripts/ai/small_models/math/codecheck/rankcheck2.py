"""Follow-up to rankcheck.py: is the rank sweep (rank 1 > rank 16 > full at Adam lr 1e-3, 320 steps) a rank effect
or a step-size effect? Rank-1 / rank-16 / full heads at several head learning rates, verbatim e5 loss, 5 folds.
"""
import sys, json, pickle
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
import e5_bridges as E  # noqa: E402

torch.set_num_threads(1)
D = pickle.load(open("/tmp/claude-0/sm/fix-alias-hub/chats.pkl", "rb"))["chats"]
dim = 384
eye = torch.eye(dim)


def train_lr(chats, rank, seed, head_lr, epochs=40):
    torch.manual_seed(seed)
    b = E.Bridge(dim, rank)
    head = [p for n, p in b.named_parameters() if n != "scale"]
    opt = torch.optim.AdamW([dict(params=head, lr=head_lr), dict(params=[b.scale], lr=1e-3)], lr=1e-3, weight_decay=0.0)
    data = [(torch.tensor(c["nodes"]), torch.tensor(c["asks"]), c["qs"]) for c in chats]
    for _ in range(epochs):
        for nodes, asks, qs in data:
            logits = b.scale.exp() * b.s(asks) @ b.a(nodes).T
            pos = torch.zeros_like(logits)
            for r, (_, ev, _) in enumerate(qs):
                pos[r, ev] = 1 / len(ev)
            forward = -(pos * logits.log_softmax(1)).sum(1).mean()
            cols = pos.sum(0) > 0
            backward = -(pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
            near = ((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum()
            loss = forward + backward + 0.01 * near
            opt.zero_grad(); loss.backward(); opt.step()
    return b


def evalb(b, idx):
    xs = []
    with torch.no_grad():
        for i in idx:
            c = D[i]
            K = b.a(torch.tensor(c["nodes"])).numpy(); S = b.s(torch.tensor(c["asks"])).numpy()
            for r, (_, ev, _) in enumerate(c["qs"]):
                xs.append(E.recall(list(np.argsort(-(K @ S[r]), kind="stable")), ev))
    return xs


arms = [(16, 1e-3), (1, 1e-3), (1, 3e-3), (16, 3e-4), (16, 1e-4), (0, 1e-4)]
per = {a: [] for a in arms}; mv = {a: [] for a in arms}
for fold in range(5):
    test = [2 * fold, 2 * fold + 1]
    tr = [D[i] for i in range(10) if i not in test]
    for a in arms:
        b = train_lr(tr, a[0], fold, a[1])
        per[a] += evalb(b, test)
        with torch.no_grad():
            mv[a].append(float((b.state.weight - eye).norm() + (b.action.weight - eye).norm()) / 2)
base = np.array(per[(16, 1e-3)]); rng = np.random.default_rng(0)
out = {}
for a in arms:
    d = np.array(per[a]) - base
    bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
    out[f"rank={a[0]} head_lr={a[1]}"] = {"recall10": round(float(np.mean(per[a])), 4), "minus_r16_lr1e-3": round(float(d.mean()), 4),
                                         "ci": [round(float(np.percentile(bs, 2.5)), 4), round(float(np.percentile(bs, 97.5)), 4)],
                                         "mean ||W-I||_F": round(float(np.mean(mv[a])), 3)}
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/codecheck/rankcheck2.json", "w"), indent=1)
