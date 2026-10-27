import pickle, sys, numpy as np, torch
sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import train
chats = pickle.load(open("/tmp/claude-0/sm/fix-cite-noise/verify/chats_fresh.pkl", "rb"))
b = train([c for i, c in enumerate(chats) if i not in (0, 1)], 384, 40, 0, rank=16)
with torch.no_grad():
    for i in range(10):
        s = b.s(torch.tensor(chats[i]["asks"])).numpy()
        print(f"chat {i}: |mean ask state| {np.linalg.norm(s.mean(0)):.3f}  |mean raw ask| {np.linalg.norm(chats[i]['asks'].mean(0)):.3f}")
rng = np.random.default_rng(1)
S = rng.standard_normal((37, 384)); R = rng.standard_normal((37, 384)); s = rng.standard_normal(384); lam = 3.0
primal = s @ np.linalg.solve(S.T @ S + lam * np.eye(384), S.T @ R)
dual = (S @ s) @ np.linalg.solve(S @ S.T + lam * np.eye(37), R)
print("dual vs primal max abs diff", np.abs(primal - dual).max())
