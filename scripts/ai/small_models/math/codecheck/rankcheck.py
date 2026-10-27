"""Is 'full-rank vs rank-16' (0.610 vs 0.657) a rank effect or an Adam step-size effect?

Under Adam every parameter moves ~lr per step, so a full head (d^2 free entries, all with gradient from step 1)
moves W much further per step than I + U V with U = 0, V ~ 0.01 at init. Measure ||W - I||_F after the unmodified
train(), and held-out recall@10 of full-rank heads trained with smaller head learning rates (verbatim loss copy).
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


out = {}
# ||W - I||_F after the unmodified train(), fold 0
for rank in (1, 16, 0):
    b = E.train([c for i, c in enumerate(D) if i not in {0, 1}], dim, 40, 0, rank=rank)
    with torch.no_grad():
        out[f"fold0 rank={rank} ||S-I||_F, ||A-I||_F"] = [float((b.state.weight - eye).norm()), float((b.action.weight - eye).norm())]
arms = [(16, 1e-3), (0, 1e-3), (0, 3e-4), (0, 1e-4), (0, 3e-5)]
per = {a: [] for a in arms}; tr_rec = {a: [] for a in arms}
for fold in range(5):
    test = [2 * fold, 2 * fold + 1]
    train_idx = [i for i in range(10) if i not in test]
    for a in arms:
        b = train_lr([D[i] for i in train_idx], a[0], fold, a[1])
        per[a] += evalb(b, test)
        if fold == 0:
            tr_rec[a] = float(np.mean(evalb(b, train_idx)))
            with torch.no_grad():
                out[f"fold0 rank={a[0]} lr={a[1]} ||A-I||_F"] = float((b.action.weight - eye).norm())
base = np.array(per[(16, 1e-3)]); rng = np.random.default_rng(0)
for a in arms:
    d = np.array(per[a]) - base
    bs = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
    out[f"heldout rank={a[0]} head_lr={a[1]}"] = dict(recall10=float(np.mean(per[a])), minus_r16=float(d.mean()),
                                                     ci=[float(np.percentile(bs, 2.5)), float(np.percentile(bs, 97.5))],
                                                     fold0_train_recall=tr_rec[a])
print(json.dumps(out, indent=1))
json.dump(out, open("/tmp/claude-0/math/codecheck/rankcheck.json", "w"), indent=1)
