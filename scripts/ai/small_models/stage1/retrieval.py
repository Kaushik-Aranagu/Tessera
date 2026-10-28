"""The read path used for the Haiku runs: rank-16 bridges (learning rate tuned on dev chats, from s11_rank.py) fused with
BM25 by reciprocal rank (k 60). This is the best single read from the earlier tests, and what the reader opens.

LoCoMo chat i is read with the bridge of the outer fold that held it out (fold i // 2), so no question is read by a bridge
trained on its own chat. LongMemEval-S is read with the rank-16 bridge trained on all ten LoCoMo chats.
A probe (the reader's next search) is read the same way: the probe through the state view for the dense list, and the
probe plus the question for BM25 (pre-registered in the front matter, test 1.3).
"""
import os
import numpy as np
import torch

import common as C

RANK = 16


def load_bridge(z, prefix, rank=RANK):
    b = C.Bridge(384, rank)
    b.load_state_dict({k: torch.as_tensor(z[f"{prefix}_{k}"]) for k in ("state.u", "state.v", "action.u", "action.v")})
    return b


class Reader:
    def __init__(self, with_lme=True):
        z = np.load(os.path.join(C.CACHE, "s11_models.npz"))
        self.chats = C.load_locomo()
        self.bridges = {f: load_bridge(z, f"f{f}_r16") for f in range(5)}
        self.keys = {}
        for i, c in enumerate(self.chats):
            K, S = self.bridges[i // 2].views(c["nodes"], c["asks"])
            self.keys[i] = (K, S)
        if with_lme:
            self.items, self.texts, self.vec = C.load_lme()
            self.lme_index = {it["qid"]: j for j, it in enumerate(self.items)}
            self.lme_bridge = load_bridge(z, "all_r16")
            self.lme_keys = [self.lme_bridge.key_np(self.vec[it["rows"]]) for it in self.items]
            self.lme_state = self.lme_bridge.state_np(np.array([it["q"] for it in self.items]))
        self._enc = None

    def encode(self, texts):
        if self._enc is None:
            self._enc = C.encoder()
        return self._enc.encode(list(texts), normalize_embeddings=True, batch_size=64).astype(np.float32)

    # ---- question ids: ("locomo", chat, r) or ("lme", index)

    def ids(self):
        out = [("locomo", i, r) for i, c in enumerate(self.chats) for r in range(len(c["qs"]))]
        return out + [("lme", j) for j in range(len(self.items))]

    def tag(self, q):
        return f"locomo:{q[1]}:{q[2]}" if q[0] == "locomo" else f"lme:{self.items[q[1]]['qid']}"

    def question(self, q):
        return self.chats[q[1]]["qs"][q[2]][0] if q[0] == "locomo" else self.items[q[1]]["question"]

    def answer(self, q):
        return self.chats[q[1]]["qs"][q[2]][3] if q[0] == "locomo" else self.items[q[1]]["answer"]

    def evidence(self, q):
        return self.chats[q[1]]["qs"][q[2]][1] if q[0] == "locomo" else self.items[q[1]]["ev"]

    def category(self, q):
        return C.CATS[self.chats[q[1]]["qs"][q[2]][2]] if q[0] == "locomo" else self.items[q[1]]["type"]

    def today(self, q):
        return "" if q[0] == "locomo" else self.items[q[1]]["qdate"]

    def snippet(self, q, node):
        if q[0] == "locomo":
            c = self.chats[q[1]]
            return dict(date=c["date"][node], text=c["text"][node])
        it = self.items[q[1]]
        return dict(date=it["dates"][node], text=self.texts[it["rows"][node]])

    def first(self, q):
        """Hop 0: the question's own fused list (dense bridge order and BM25 order)."""
        if q[0] == "locomo":
            K, S = self.keys[q[1]]
            return C.fuse(self.chats[q[1]]["lexorder"][q[2]], C.order_of(K @ S[q[2]]))
        return C.fuse(self.items[q[1]]["lexorder"], C.order_of(self.lme_keys[q[1]] @ self.lme_state[q[1]]))

    def dense_only(self, q):
        if q[0] == "locomo":
            K, S = self.keys[q[1]]
            return C.order_of(K @ S[q[2]])
        return C.order_of(self.lme_keys[q[1]] @ self.lme_state[q[1]])

    def probe(self, q, text, vec=None):
        """A later hop: the probe's dense list (state view of the probe) fused with BM25 on probe plus question."""
        e = self.encode([text])[0] if vec is None else vec
        lex_q = C.tokens(text + " " + self.question(q))
        if q[0] == "locomo":
            c = self.chats[q[1]]; K = self.keys[q[1]][0]; s = self.bridges[q[1] // 2].state_np(e)[0]
            return C.fuse(c["bm25"].rank(lex_q), C.order_of(K @ s))
        it = self.items[q[1]]; s = self.lme_bridge.state_np(e)[0]
        return C.fuse(it["bm25"].rank(lex_q), C.order_of(self.lme_keys[q[1]] @ s))
