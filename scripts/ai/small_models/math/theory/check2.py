"""(i) Lemma 1 second-order term on random LoCoMo vectors; (ii) mean session size per d' bin."""
import sys
import numpy as np
sys.path.insert(0, "/tmp/claude-0/math/theory")
from common import bridges, chats
from pool import sessions
C, B = chats(), bridges()
K, S = B["f0_k0"], B["f0_s0"]
rng = np.random.default_rng(0)
for eta in (0.02, 0.1, 0.3):
    e1, e2 = [], []
    for _ in range(20000):
        k, s, q = K[rng.integers(len(K))], S[rng.integers(len(S))], S[rng.integers(len(S))]
        a, c, rho = k @ q, k @ s, s @ q
        kp = (1 - eta) * k + eta * s; kp /= np.linalg.norm(kp)
        ex = kp @ q - a
        fo = eta * (rho - a * c)
        so = fo + eta ** 2 * (1 - c) * (rho - 2 * a + 1.5 * a * (1 - c))
        e1.append(abs(ex - fo)); e2.append(abs(ex - so))
    print(f"eta {eta}: mean |exact - first order| {np.mean(e1):.2e}, |exact - second order| {np.mean(e2):.2e}")
ms = {(0, 17): [], (17, 22): [], (22, 27): [], (27, 100): []}
for i, c in enumerate(C):
    sess, of = sessions(c)
    for q in c["qs"]:
        evs = {of[e] for e in q[1]}
        if len(evs) == 1:
            m = len(sess[evs.pop()])
            for (lo, hi), v in ms.items():
                if lo <= m < hi:
                    v.append(m)
print({f"{lo}-{hi - 1}": round(float(np.mean(v)), 1) for (lo, hi), v in ms.items()})
