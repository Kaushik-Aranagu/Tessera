#!/usr/bin/env python3
"""Reviewer check, DEV ONLY (training chats of each outer fold; test chats never touched): the chosen hop settings sit
at the grid edge (60 epochs). Does training the hop head longer (200 epochs) change the dev picture?"""
import os, pickle, sys
import numpy as np
import torch

sys.path.insert(0, "/tmp/claude-0/sm")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from e5_bridges import train  # noqa: E402
import second_hop as sh  # noqa: E402

torch.set_num_threads(1)
chats = pickle.load(open("/tmp/claude-0/sm/fix-second-hop/chats.pkl", "rb")); sh.add_sessions(chats, "/tmp/locomo10.json")
dim = chats[0]["nodes"].shape[1]
for fold in range(5):
    test = [2 * fold, 2 * fold + 1]; tr = [i for i in range(10) if i not in test]
    pairs = [tr[j:j + 2] for j in range(0, 8, 2)]; base = []; sc = {}
    for j, dev in enumerate(pairs):
        inner = [i for i in tr if i not in dev]
        b = train([chats[i] for i in inner], dim, 40, 1000 + 10 * fold + j, rank=16)
        projs = {i: sh.project(b, chats[i]) for i in inner + dev}
        for i in dev:
            base += [sh.recall(o, ev) for o, (_, ev, _) in zip(sh.rank_chat(chats[i], *projs[i], b, None, 1.0, hop=None), chats[i]["qs"])]
        for rank in (4, 16):
            for pr in ("gold", "gold+top1"):
                head = sh.train_hop([chats[i] for i in inner], [projs[i] for i in inner], dim, rank, 200, pr, 1000 + 10 * fold + j)
                for w in (0.5, 1.0):
                    for i in dev:
                        sc.setdefault((rank, pr, w), []).extend(
                            sh.recall(o, ev) for o, (_, ev, _) in zip(sh.rank_chat(chats[i], *projs[i], b, head, w), chats[i]["qs"]))
    best = max(sc, key=lambda k: np.mean(sc[k]))
    print(f"fold {fold} dev lowrank {np.mean(base):.3f}; epochs=200 best {best} {np.mean(sc[best]):.3f}; all: "
          + ", ".join(f"{k[0]}/{k[1]}/w{k[2]} {np.mean(v):.3f}" for k, v in sorted(sc.items())), flush=True)
