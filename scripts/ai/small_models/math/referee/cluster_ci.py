"""Chat- and ask-clustered bootstrap for the clean-cite move gain (eta 0.1), versus the visit-level bootstrap used in e6."""
import json, pickle
import numpy as np
C = pickle.load(open("/tmp/claude-0/math/theory/chats.pkl", "rb")); B = np.load("/tmp/claude-0/math/theory/bridges_r16.npz")
def unit(x): return x / np.linalg.norm(x, axis=-1, keepdims=True)
rows = []
for fold in range(5):
    for i in (2 * fold, 2 * fold + 1):
        K0 = B[f"f{fold}_k{i}"].astype(np.float64); S = B[f"f{fold}_s{i}"].astype(np.float64); qs = C[i]["qs"]
        for o in range(3):
            order = np.random.default_rng(100 * fold + 10 * i + o).permutation(len(qs)); keys = K0.copy()
            for r in order:
                ev = qs[r][1]
                t = np.argsort(-(keys @ S[r]), kind="stable")[:10]; t0 = np.argsort(-(K0 @ S[r]), kind="stable")[:10]
                rows.append((i, r, len(set(t) & set(ev)) / len(ev) - len(set(t0) & set(ev)) / len(ev)))
                for v in ev: keys[v] = unit(keys[v] + 0.1 * (S[r] - keys[v]))
rows = np.array(rows); d = rows[:, 2]; rng = np.random.default_rng(0)
vis = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
askid = rows[:, 0] * 1000 + rows[:, 1]; ua = np.unique(askid); per_ask = np.array([d[askid == a].mean() for a in ua])
ask = [per_ask[rng.integers(0, len(ua), len(ua))].mean() for _ in range(2000)]
chats_ = np.unique(rows[:, 0]); per_chat = {c: d[rows[:, 0] == c] for c in chats_}
cl = []
for _ in range(2000):
    pick = rng.choice(chats_, len(chats_)); cl.append(np.concatenate([per_chat[c] for c in pick]).mean())
out = dict(mean=float(d.mean()), visit_CI=np.percentile(vis, [2.5, 97.5]).tolist(), ask_cluster_CI=np.percentile(ask, [2.5, 97.5]).tolist(),
           chat_cluster_CI=np.percentile(cl, [2.5, 97.5]).tolist(), chats_positive=int(sum(per_chat[c].mean() > 0 for c in chats_)))
print(json.dumps(out)); json.dump(out, open("cluster_ci.json", "w"))
