#!/usr/bin/env python3
"""E5: learned bridges between the reasoning plane and the memory plane, on LoCoMo (public, no Tessera data).

Two-plane model, smallest version. The memory plane is the chat's turns (leaves). A frozen small encoder gives every
leaf and every ask a vector. Bridges are CLM-style heads: a state head on the ask and an action head on the node, both
linear, initialised to identity, trained with InfoNCE over all of a chat's nodes (bidirectional contrastive, like CLM).
Arms, recall@10 on held-out chats (5 folds, 2 chats each, train on the other 8, never on the test chat):
  frozen     cosine of the frozen encoder (the E1 'dense' arm)
  bridged    the trained bridge heads, zero-shot on unseen chats
  +hybrid    each fused with BM25 by reciprocal rank (k=60)
  +use       memory-plane learning at test time: questions are taken in order; after each one, the nodes it cited
             (its evidence, standing in for a verified cite) move their key a step toward the ask's state vector.
             Only earlier questions' feedback is ever used for a later one.
Usage: python3 e5_bridges.py --data locomo10.json [--model BAAI/bge-small-en-v1.5] [--epochs 40] [--eta 0.3]
"""
import argparse, collections, hashlib, json, math, re, sys
import numpy as np
import torch

STOP = set("a about am an and are at be been did do does far for how i in is it many me much my of on or so that the to was we were what when you".split())
CATS = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
SHA = "79fa87e90f04081343b8c8debecb80a9a6842b76a7aa537dc9fdf651ea698ff4"


def tokens(t):
    return [w for w in re.split(r"[^a-z0-9]+", t.lower()) if len(w) >= 2 and any(c.isalpha() for c in w) and w not in STOP]


def bm25_rank(docs, ids, query):
    n = len(ids); avg = sum(len(docs[i]) for i in ids) / n
    df = collections.Counter(w for i in ids for w in set(docs[i])); tf = {i: collections.Counter(docs[i]) for i in ids}
    def score(d):
        out = 0.0
        for w in set(query):
            if w in tf[d]:
                idf = math.log(1 + (n - df[w] + 0.5) / (df[w] + 0.5))
                out += idf * tf[d][w] * 2.2 / (tf[d][w] + 1.2 * (0.25 + 0.75 * len(docs[d]) / avg))
        return out
    return sorted(ids, key=lambda d: (-score(d), d))


def fuse(*orders, k=60):
    s = collections.defaultdict(float)
    for o in orders:
        for p, d in enumerate(o):
            s[d] += 1 / (k + p + 1)
    return sorted(s, key=lambda d: (-s[d], d))


def load(path, model):
    from sentence_transformers import SentenceTransformer
    enc = SentenceTransformer(model)
    chats = []
    for sample in json.load(open(path)):
        turns = {}
        for name, value in sample["conversation"].items():
            if name.startswith("session_") and isinstance(value, list):
                for t in value:
                    c = t.get("blip_caption")
                    turns[t["dia_id"]] = f"{t['speaker']}: {t['text']}" + (f" {c}" if c else "")
        ids = list(turns)
        qs = []
        for q in sample["qa"]:
            if q["category"] == 5 or not q.get("evidence"):
                continue
            ev = [ids.index(e.strip()) for e in q["evidence"] if e.strip() in turns]
            if ev:
                qs.append((q["question"], sorted(set(ev)), q["category"]))
        nodes = enc.encode([turns[i] for i in ids], normalize_embeddings=True, batch_size=64)
        asks = enc.encode([q[0] for q in qs], normalize_embeddings=True, batch_size=64)
        chats.append(dict(ids=ids, docs={i: tokens(turns[i]) for i in ids}, text=turns, nodes=nodes, asks=asks, qs=qs))
    return chats


class LowRank(torch.nn.Module):
    """Identity plus a rank-r change: far fewer weights than a full head, for small training sets."""
    def __init__(self, dim, rank):
        super().__init__()
        self.u = torch.nn.Parameter(torch.zeros(dim, rank)); self.v = torch.nn.Parameter(torch.randn(rank, dim) * 0.01)

    @property
    def weight(self):
        return torch.eye(self.u.shape[0]) + self.u @ self.v

    def forward(self, x):
        return x + (x @ self.v.T) @ self.u.T


class Bridge(torch.nn.Module):
    def __init__(self, dim, rank=0):
        super().__init__()
        if rank:
            self.state, self.action = LowRank(dim, rank), LowRank(dim, rank)
        else:
            self.state = torch.nn.Linear(dim, dim, bias=False); self.action = torch.nn.Linear(dim, dim, bias=False)
            for m in (self.state, self.action):
                torch.nn.init.eye_(m.weight)
        self.scale = torch.nn.Parameter(torch.tensor(math.log(20.0)))

    def s(self, x):
        return torch.nn.functional.normalize(self.state(x), dim=-1)

    def a(self, x):
        return torch.nn.functional.normalize(self.action(x), dim=-1)


def train(chats, dim, epochs, seed, rank=0):
    torch.manual_seed(seed)
    b = Bridge(dim, rank); opt = torch.optim.AdamW(b.parameters(), lr=1e-3, weight_decay=0.0)
    eye = torch.eye(dim)
    data = [(torch.tensor(c["nodes"]), torch.tensor(c["asks"]), c["qs"]) for c in chats]
    for _ in range(epochs):
        for nodes, asks, qs in data:
            logits = b.scale.exp() * b.s(asks) @ b.a(nodes).T          # asks x nodes
            pos = torch.zeros_like(logits)
            for r, (_, ev, _) in enumerate(qs):
                pos[r, ev] = 1 / len(ev)
            forward = -(pos * logits.log_softmax(1)).sum(1).mean()       # ask -> node
            cols = pos.sum(0) > 0                                        # node -> ask, CLM's bidirectional term
            backward = -(pos[:, cols] / pos[:, cols].sum(0) * logits[:, cols].log_softmax(0)).sum(0).mean()
            near = ((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum()
            loss = forward + backward + 0.01 * near
            opt.zero_grad(); loss.backward(); opt.step()
    return b


def recall(order, ev, k=10):
    return len(set(order[:k]) & set(ev)) / len(ev)


def run(args):
    if hashlib.sha256(open(args.data, "rb").read()).hexdigest() != SHA:
        sys.exit("not the pinned LoCoMo file")
    chats = load(args.data, args.model)
    dim = chats[0]["nodes"].shape[1]
    arms = ("frozen", "bridged", "frozen+hybrid", "bridged+hybrid", "bridged+use", "bridged+use+hybrid")
    tot = collections.defaultdict(float); n = 0; per = collections.defaultdict(list)
    for fold in range(5):
        test = {2 * fold, 2 * fold + 1}
        b = train([c for i, c in enumerate(chats) if i not in test], dim, args.epochs, fold)
        with torch.no_grad():
            for i in sorted(test):
                c = chats[i]
                keys = b.a(torch.tensor(c["nodes"])).numpy().copy()
                states = b.s(torch.tensor(c["asks"])).numpy()
                for r, (q, ev, cat) in enumerate(c["qs"]):
                    ids = list(range(len(c["ids"])))
                    lex = [c["ids"].index(d) for d in bm25_rank(c["docs"], c["ids"], tokens(q))]
                    frozen = list(np.argsort(-(c["nodes"] @ c["asks"][r]), kind="stable"))
                    bridged = list(np.argsort(-(b.a(torch.tensor(c["nodes"])).numpy() @ states[r]), kind="stable"))
                    used = list(np.argsort(-(keys @ states[r]), kind="stable"))
                    ranked = {"frozen": frozen, "bridged": bridged, "frozen+hybrid": fuse(lex, frozen),
                              "bridged+hybrid": fuse(lex, bridged), "bridged+use": used, "bridged+use+hybrid": fuse(lex, used)}
                    n += 1; tot[f"n{cat}"] += 1
                    for arm, o in ranked.items():
                        x = recall(o, ev); tot[arm] += x; tot[f"{arm} c{cat}"] += x; per[arm].append(x)
                    for e in ev:  # backward pass on the memory plane: cited nodes move toward the ask
                        keys[e] = keys[e] + args.eta * (states[r] - keys[e])
                        keys[e] /= np.linalg.norm(keys[e])
    print(f"{n} questions, held-out chats, model {args.model}, recall@10")
    for arm in arms:
        print(f"  {arm:<20} {tot[arm] / n:.3f}   " + "  ".join(f"{CATS[k]} {tot[f'{arm} c{k}'] / tot[f'n{k}']:.3f}" for k in CATS))
    rng = np.random.default_rng(0)
    for a, b0 in (("bridged", "frozen"), ("bridged+hybrid", "frozen+hybrid"), ("bridged+use", "bridged")):
        d = np.array(per[a]) - np.array(per[b0])
        boots = [d[rng.integers(0, len(d), len(d))].mean() for _ in range(2000)]
        print(f"  {a} minus {b0}: {d.mean():+.3f}  95% CI [{np.percentile(boots, 2.5):+.3f}, {np.percentile(boots, 97.5):+.3f}]")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--data", required=True); p.add_argument("--model", default="BAAI/bge-small-en-v1.5")
    p.add_argument("--epochs", type=int, default=40); p.add_argument("--eta", type=float, default=0.3)
    run(p.parse_args())
