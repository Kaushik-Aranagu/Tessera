"""Prep for the analysis section: encode LoCoMo once (e5_bridges.load), train the e6 rank-16 bridges per fold
(seed = fold, 40 epochs, same as e6_fixes.py), and cache everything the theory checks need.
Read-only use of /tmp/claude-0/sm; writes only under /tmp/claude-0/math/theory/."""
import os, pickle, sys, time
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
from e5_bridges import load, train  # noqa: E402

HERE = "/tmp/claude-0/math/theory"
torch.set_num_threads(1)


def main():
    t0 = time.time()
    cache = os.path.join(HERE, "chats.pkl")
    if os.path.exists(cache):
        chats = pickle.load(open(cache, "rb"))
    else:
        chats = load("/tmp/locomo10.json", "BAAI/bge-small-en-v1.5")
        pickle.dump(chats, open(cache, "wb"))
    print(f"loaded {len(chats)} chats in {time.time() - t0:.0f}s", flush=True)
    dim = chats[0]["nodes"].shape[1]
    out = {}
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        tr = [c for i, c in enumerate(chats) if i not in test]
        t1 = time.time()
        b = train(tr, dim, 40, fold, rank=16)
        with torch.no_grad():
            for i in range(10):
                out[f"f{fold}_k{i}"] = b.a(torch.tensor(chats[i]["nodes"])).numpy()
                out[f"f{fold}_s{i}"] = b.s(torch.tensor(chats[i]["asks"])).numpy()
            out[f"f{fold}_Ws"] = b.state.weight.numpy().copy()
            out[f"f{fold}_Wa"] = b.action.weight.numpy().copy()
        print(f"fold {fold} trained in {time.time() - t1:.0f}s", flush=True)
    np.savez(os.path.join(HERE, "bridges_r16.npz"), **out)
    print(f"done {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
