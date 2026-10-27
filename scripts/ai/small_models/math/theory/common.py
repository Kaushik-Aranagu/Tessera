import pickle
import numpy as np

HERE = "/tmp/claude-0/math/theory"
CHATS = None
BR = None


def chats():
    global CHATS
    if CHATS is None:
        CHATS = pickle.load(open(f"{HERE}/chats.pkl", "rb"))
    return CHATS


def bridges():
    global BR
    if BR is None:
        BR = dict(np.load(f"{HERE}/bridges_r16.npz"))
    return BR


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def recall(top, ev, k=10):
    return len(set(top[:k]) & set(ev)) / len(ev)


def topk(scores, k):
    idx = np.argpartition(-scores, k)[:k]
    return idx[np.argsort(-scores[idx], kind="stable")]


def folds():
    """(fold, test chat index) pairs exactly as e6: fold f tests chats 2f, 2f+1 with that fold's bridge."""
    for fold in range(5):
        for i in (2 * fold, 2 * fold + 1):
            yield fold, i


def orders(fold, i, n, count=3):
    """Same visit permutations as e6_fixes.py (rng seeded 100*fold + 10*i + o, first draw = permutation)."""
    return [np.random.default_rng(100 * fold + 10 * i + o).permutation(n) for o in range(count)]
