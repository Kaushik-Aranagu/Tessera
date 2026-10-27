import numpy as np, json
rng = np.random.default_rng(5)
def unit(x): return x / np.linalg.norm(x, axis=-1, keepdims=True)
K, eta = 10, 0.1; found = 0; tried = 0; neg_share = []
for t in range(20000):
    d = 16; base = unit(rng.normal(size=d))
    keys = unit(base * 0.3 + rng.normal(size=(60, d)) * 0.3)
    s = unit(base + rng.normal(size=d) * 0.5); q = unit(s + rng.normal(size=d) * 0.6)
    e = 0  # evidence node, excluded from theta_K
    top_s = [v for v in np.argsort(-(keys @ s)) if v != e][:K]
    dd = int(rng.choice(top_s))
    others = np.array([v for v in range(60) if v != e])
    th0 = np.sort(keys[others] @ q)[-K]
    k2 = keys.copy(); k2[dd] = unit(keys[dd] + eta * (s - keys[dd]))
    th1 = np.sort(k2[others] @ q)[-K]
    tried += 1
    if th1 < th0 - 1e-12: found += 1
print(json.dumps(dict(share_dtheta_negative=found / tried, tried=tried)))
