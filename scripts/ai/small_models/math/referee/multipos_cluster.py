"""Chat-cluster bootstrap of the Objectives section's multi-positive loss deltas (reads multipos_per.npz read-only)."""
import json, pickle
import numpy as np
C = pickle.load(open("/tmp/claude-0/math/theory/chats.pkl", "rb"))
cid = np.repeat(np.arange(10), [len(c["qs"]) for c in C])
z = np.load("/tmp/claude-0/math/objectives/multipos_per.npz"); m = z["npos"] >= 2
rng = np.random.default_rng(1); out = {}
for a, b in (("mask_fwd", "lout_bi"), ("lout_fwd", "lout_bi"), ("mask_fwd", "lout_fwd")):
    d = np.mean([z[f"{a}_{s}"] - z[f"{b}_{s}"] for s in (0, 100, 200)], 0); bs = []
    for _ in range(4000):
        ch = rng.integers(0, 10, 10); idx = np.concatenate([np.where((cid == c) & m)[0] for c in ch]); bs.append(d[idx].mean())
    out[f"{a}-{b} (m>=2)"] = dict(mean=float(d[m].mean()), chat_cluster_CI=np.percentile(bs, [2.5, 97.5]).round(4).tolist())
print(json.dumps(out, indent=1)); json.dump(out, open("multipos_cluster.json", "w"), indent=1)
