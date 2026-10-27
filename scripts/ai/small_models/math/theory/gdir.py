"""Directions of the two dominant singular pairs of the initial gradient (all 1531 asks): alignment with the mean ask
direction mu_s and the mean node direction mu_k (frozen space)."""
import sys
import numpy as np
sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import chats
from rank import per_ask_grads
C = chats()
GA = np.zeros((384, 384)); GS = np.zeros((384, 384)); n = 0
S_all = np.concatenate([c["asks"] for c in C]); X_all = np.concatenate([c["nodes"] for c in C])
for c in C:
    a, s = per_ask_grads(c)
    GA += a.astype(np.float64).sum(0); GS += s.astype(np.float64).sum(0); n += len(a)
GA /= n; GS /= n
mus = S_all.mean(0); mus /= np.linalg.norm(mus)
muk = X_all.mean(0); muk /= np.linalg.norm(muk)
for name, G in (("action", GA), ("state", GS)):
    U, sv, Vt = np.linalg.svd(G)
    for i in range(2):
        print(f"{name} sv{i + 1} {sv[i]:.3f}: |cos(u, mu_s)| {abs(U[:, i] @ mus):.3f} |cos(u, mu_k)| {abs(U[:, i] @ muk):.3f} "
              f"|cos(v, mu_s)| {abs(Vt[i] @ mus):.3f} |cos(v, mu_k)| {abs(Vt[i] @ muk):.3f}")
print(f"cos(mu_s, mu_k) frozen {mus @ muk:.3f}")
