"""Label-free anisotropy correction vs learned bridges: is most of what the rank-1/16 heads learn the common-mode
(mean) correction? recall@10 on all 10 chats (no training at all for the centering arms)."""
import sys
import numpy as np
import torch
sys.path.insert(0, "/tmp/claude-0/sm"); sys.path.insert(0, "/tmp/claude-0/math/theory")
from e5_bridges import train
from common import chats, recall, unit
torch.set_num_threads(1)
C = chats()
def ev(fn):
    r = []
    for i, c in enumerate(C):
        K, S = fn(i, c)
        for j, (_, e, _) in enumerate(c["qs"]):
            r.append(recall(list(np.argsort(-(K @ S[j]), kind="stable")), e))
    return np.mean(r)
print(f"frozen                                {ev(lambda i, c: (c['nodes'], c['asks'])):.3f}")
print(f"center, this chat's own means         {ev(lambda i, c: (unit(c['nodes'] - c['nodes'].mean(0)), unit(c['asks'] - c['asks'].mean(0)))):.3f}")
def other(i):
    t = {i, i ^ 1}
    return (np.concatenate([C[j]['nodes'] for j in range(10) if j not in t]).mean(0), np.concatenate([C[j]['asks'] for j in range(10) if j not in t]).mean(0))
print(f"center, training chats' means         {ev(lambda i, c: (unit(c['nodes'] - other(i)[0]), unit(c['asks'] - other(i)[1]))):.3f}")
def abtt(X, D):
    Xc = X - X.mean(0); U, s, Vt = np.linalg.svd(Xc, full_matrices=False)
    return unit(Xc - Xc @ Vt[:D].T @ Vt[:D])
for D in (1, 3):
    print(f"all-but-the-top D={D}, own chat        {ev(lambda i, c: (abtt(c['nodes'], D), abtt(c['asks'], D))):.3f}")
# what a rank-1 head learns: train on chats 2..9, inspect u, v of each head
b = train([C[j] for j in range(2, 10)], 384, 40, 0, rank=1)
mus = unit(np.concatenate([c['asks'] for c in C]).mean(0)); muk = unit(np.concatenate([c['nodes'] for c in C]).mean(0))
for nm, h in (("state", b.state), ("action", b.action)):
    u = h.u.detach().numpy()[:, 0]; v = h.v.detach().numpy()[0]
    print(f"rank-1 {nm} head W = I + u v^T: |u| {np.linalg.norm(u):.2f} |v| {np.linalg.norm(v):.2f} cos(v, mu_s) {unit(v) @ mus:+.2f} cos(v, mu_k) {unit(v) @ muk:+.2f} "
          f"cos(u, mu_s) {unit(u) @ mus:+.2f} cos(u, mu_k) {unit(u) @ muk:+.2f}  u.v {u @ v:+.2f}")
with torch.no_grad():
    K = b.a(torch.tensor(C[0]['nodes'])).numpy(); S = b.s(torch.tensor(C[0]['asks'])).numpy()
print(f"after the rank-1 heads (chat 0): |mean ask| {np.linalg.norm(S.mean(0)):.3f} |mean key| {np.linalg.norm(K.mean(0)):.3f} cos(means) {unit(S.mean(0)) @ unit(K.mean(0)):.3f}")
