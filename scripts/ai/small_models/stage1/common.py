"""Shared pieces for the stage 1 re-runs of the two-plane memory tests (public data only: LoCoMo and LongMemEval-S).

Fixes from method section 8 that live here:
  #6  LoCoMo evidence is parsed with D:?(\\d+):(\\d+) and leading zeros stripped, so 1,536 questions are kept (was 1,531)
  #2  the logit scale alpha is fixed at 20 (it was a parameter pinned by the step budget)
  #17 the read loss is forward-only L_mask (per-positive InfoNCE, other positives out of the denominator)
  #1  the learning rate is a per-call argument so each rank can be tuned on dev chats (see s11_rank.py)
  #5  chat-clustered paired bootstrap for LoCoMo; question-clustered for LongMemEval-S (one haystack per question)
Embeddings come from the frozen BAAI/bge-small-en-v1.5 and are cached under STAGE1_CACHE (default /tmp/claude-0/stage1).
"""
import collections, hashlib, json, math, os, re
import numpy as np
import torch

SHA_LOCOMO = "79fa87e90f04081343b8c8debecb80a9a6842b76a7aa537dc9fdf651ea698ff4"
SHA_LME = "d6f21ea9"  # first 8 hex of the sha256 of longmemeval_s_cleaned.json (lme_s.json here), checked in full below
CACHE = os.environ.get("STAGE1_CACHE", "/tmp/claude-0/stage1")
MODEL = "BAAI/bge-small-en-v1.5"
ALPHA = 20.0
CATS = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}
STOP = set("a about am an and are at be been did do does far for how i in is it many me much my of on or so that the to was we were what when you".split())
EVID = re.compile(r"D:?(\d+):(\d+)")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def tokens(t):
    return [w for w in re.split(r"[^a-z0-9]+", t.lower()) if len(w) >= 2 and any(c.isalpha() for c in w) and w not in STOP]


class BM25:
    """Okapi BM25 (k1 1.2, b 0.75, idf log(1 + (n - df + .5) / (df + .5))) over a fixed list of token lists; e5's scorer."""

    def __init__(self, docs):
        self.n = len(docs); self.avg = sum(map(len, docs)) / max(self.n, 1)
        self.tf = [collections.Counter(d) for d in docs]; self.len = np.array([len(d) for d in docs], dtype=np.float64)
        self.df = collections.Counter(w for d in docs for w in set(d))
        self.post = collections.defaultdict(list)
        for i, c in enumerate(self.tf):
            for w, f in c.items():
                self.post[w].append((i, f))

    def scores(self, query):
        out = np.zeros(self.n)
        norm = 1.2 * (0.25 + 0.75 * self.len / self.avg)
        for w in set(query):
            if w not in self.df:
                continue
            idf = math.log(1 + (self.n - self.df[w] + 0.5) / (self.df[w] + 0.5))
            for i, f in self.post[w]:
                out[i] += idf * f * 2.2 / (f + norm[i])
        return out

    def rank(self, query):
        s = self.scores(query)
        return np.lexsort((np.arange(self.n), -s))


def order_of(scores):
    """Descending order, ties by index (np.argsort stable on the negated scores, as in e5)."""
    return np.argsort(-np.asarray(scores), kind="stable")


def fuse(*orders, k=60):
    """Reciprocal rank fusion, ties by node index (same result as e5_bridges.fuse on integer ids)."""
    n = len(orders[0]); f = np.zeros(n)
    for o in orders:
        pos = np.empty(n, dtype=np.int64); pos[np.asarray(o)] = np.arange(n)
        f += 1.0 / (k + pos + 1)
    return np.lexsort((np.arange(n), -f))


def recall(order, ev, k=10):
    ev = set(ev)
    return len(set(np.asarray(order[:k]).tolist()) & ev) / len(ev)


def unit(x):
    return x / np.linalg.norm(x, axis=-1, keepdims=True)


def encoder():
    from sentence_transformers import SentenceTransformer
    return SentenceTransformer(MODEL)


# ---------------------------------------------------------------- LoCoMo

def load_locomo(path="/tmp/locomo10.json"):
    """Ten chats. Each: ids (dia_id per node), text, date (session date per node), docs (BM25 tokens), nodes and asks
    (unit bge-small vectors), qs = [(question, sorted evidence node indices, category, answer)]. 1,536 questions."""
    if sha256(path) != SHA_LOCOMO:
        raise SystemExit("not the pinned LoCoMo file")
    os.makedirs(CACHE, exist_ok=True)
    raw = json.load(open(path))
    chats = []
    for sample in raw:
        conv = sample["conversation"]; turns, date = {}, {}
        for name, value in conv.items():
            if name.startswith("session_") and isinstance(value, list):
                when = conv.get(f"{name}_date_time", "")
                for t in value:
                    c = t.get("blip_caption")
                    turns[t["dia_id"]] = f"{t['speaker']}: {t['text']}" + (f" {c}" if c else "")
                    date[t["dia_id"]] = when
        ids = list(turns); where = {d: i for i, d in enumerate(ids)}
        qs = []
        for q in sample["qa"]:
            if q["category"] == 5:
                continue
            ev = {where[f"D{int(a)}:{int(b)}"] for e in q.get("evidence") or [] for a, b in EVID.findall(e)
                  if f"D{int(a)}:{int(b)}" in where}
            if ev:
                qs.append((q["question"], sorted(ev), q["category"], str(q.get("answer", ""))))
        chats.append(dict(sample_id=sample.get("sample_id", str(len(chats))), ids=ids, text=[turns[i] for i in ids],
                          date=[date[i] for i in ids], docs=[tokens(turns[i]) for i in ids], qs=qs))
    cache = os.path.join(CACHE, "locomo_emb.npz")
    if os.path.exists(cache):
        z = np.load(cache)
    else:
        enc = encoder(); z = {}
        for i, c in enumerate(chats):
            z[f"n{i}"] = enc.encode(c["text"], normalize_embeddings=True, batch_size=64)
            z[f"a{i}"] = enc.encode([q[0] for q in c["qs"]], normalize_embeddings=True, batch_size=64)
        np.savez(cache, **z)
    for i, c in enumerate(chats):
        c["nodes"] = z[f"n{i}"].astype(np.float32); c["asks"] = z[f"a{i}"].astype(np.float32)
        assert len(c["asks"]) == len(c["qs"]) and len(c["nodes"]) == len(c["ids"])
        c["bm25"] = BM25(c["docs"])
        c["lexorder"] = [c["bm25"].rank(tokens(q[0])) for q in c["qs"]]
    assert sum(len(c["qs"]) for c in chats) == 1536
    return chats


# ---------------------------------------------------------------- LongMemEval-S

def load_lme(path="/tmp/claude-0/data/lme_s.json", emb="/tmp/claude-0/data/lme_emb.npz"):
    """LongMemEval-S, the 428 questions whose evidence includes a user turn. The memory of each question is its own
    haystack's user turns (as E7). Each item: qid, type, question, answer, qdate, rows (index into texts), sess, dates,
    ev (evidence row positions), q (unit question vector). Returns (items, texts, vec)."""
    if not sha256(path).startswith(SHA_LME):
        raise SystemExit("not the checked LongMemEval-S file")
    data = json.load(open(path))
    texts = sorted({t["content"] for x in data for s in x["haystack_sessions"] for t in s if t["role"] == "user"})
    index = {t: i for i, t in enumerate(texts)}
    vec = np.load(emb)["v"].astype(np.float32)
    assert vec.shape[0] == len(texts)
    items = []
    for x in data:
        rows, sess, dates, ev = [], [], [], []
        for sid, sdate, s in zip(x["haystack_session_ids"], x["haystack_dates"], x["haystack_sessions"]):
            for t in s:
                if t["role"] != "user":
                    continue
                if t.get("has_answer"):
                    ev.append(len(rows))
                rows.append(index[t["content"]]); sess.append(sid); dates.append(sdate)
        if ev:
            items.append(dict(qid=x["question_id"], type=x["question_type"], question=x["question"],
                              answer=str(x["answer"]), qdate=x.get("question_date", ""), rows=np.array(rows),
                              sess=sess, dates=dates, ev=sorted(ev)))
    os.makedirs(CACHE, exist_ok=True)
    cache = os.path.join(CACHE, "lme_q.npz")
    if os.path.exists(cache):
        qv = np.load(cache)["q"]
    else:
        qv = encoder().encode([it["question"] for it in items], normalize_embeddings=True, batch_size=64)
        np.savez(cache, q=qv)
    for it, q in zip(items, qv):
        it["q"] = q.astype(np.float32)
        it["docs"] = [tokens(texts[r]) for r in it["rows"]]
        it["bm25"] = BM25(it["docs"])
        it["lexorder"] = it["bm25"].rank(tokens(it["question"]))
    assert len(items) == 428
    return items, texts, vec


# ---------------------------------------------------------------- bridges

class LowRank(torch.nn.Module):
    """H = I + U V^T, U zero at start, V small."""

    def __init__(self, dim, rank):
        super().__init__()
        self.u = torch.nn.Parameter(torch.zeros(dim, rank)); self.v = torch.nn.Parameter(torch.randn(rank, dim) * 0.01)

    @property
    def weight(self):
        return torch.eye(self.u.shape[0]) + self.u @ self.v

    def forward(self, x):
        return x + (x @ self.v.T) @ self.u.T


class Bridge(torch.nn.Module):
    """State view S (on asks or probes) and key view A (on nodes); rank 0 means full 384 x 384 heads."""

    def __init__(self, dim, rank):
        super().__init__()
        if rank:
            self.state, self.action = LowRank(dim, rank), LowRank(dim, rank)
        else:
            self.state = torch.nn.Linear(dim, dim, bias=False); self.action = torch.nn.Linear(dim, dim, bias=False)
            for m in (self.state, self.action):
                torch.nn.init.eye_(m.weight)

    def s(self, x):
        return torch.nn.functional.normalize(self.state(x), dim=-1)

    def a(self, x):
        return torch.nn.functional.normalize(self.action(x), dim=-1)

    def views(self, nodes, asks):
        with torch.no_grad():
            return self.a(torch.as_tensor(nodes)).numpy(), self.s(torch.as_tensor(asks)).numpy()

    def state_np(self, x):
        with torch.no_grad():
            return self.s(torch.as_tensor(np.atleast_2d(x))).numpy()

    def key_np(self, x):
        with torch.no_grad():
            return self.a(torch.as_tensor(np.atleast_2d(x))).numpy()

    def drift(self):
        eye = torch.eye(self.state.weight.shape[0])
        with torch.no_grad():
            return float(((self.state.weight - eye).norm() + (self.action.weight - eye).norm()) / 2)


def mask_loss(logits, P):
    """Forward-only L_mask: mean over asks of (1/n+) sum_p log(e^l_p + Z_neg) - l_p."""
    lse_neg = torch.logsumexp(logits.masked_fill(P, -1e9), 1, keepdim=True)
    per = (torch.logaddexp(logits, lse_neg.expand_as(logits)) - logits).masked_fill(~P, 0.0)
    return (per.sum(1) / P.float().sum(1)).mean()


def train(chats, rank, lr, seed, epochs=40, near=0.01, dim=384):
    """One AdamW step per chat per epoch (40 epochs), alpha fixed at 20, plus 0.01 ||W - I||_F^2 per head as before."""
    torch.manual_seed(seed)
    b = Bridge(dim, rank); opt = torch.optim.AdamW(b.parameters(), lr=lr, weight_decay=0.0)
    eye = torch.eye(dim)
    data = []
    for c in chats:
        P = torch.zeros(len(c["qs"]), len(c["ids"]), dtype=torch.bool)
        for r, q in enumerate(c["qs"]):
            P[r, q[1]] = True
        data.append((torch.as_tensor(c["nodes"]), torch.as_tensor(c["asks"]), P))
    for _ in range(epochs):
        for nodes, asks, P in data:
            loss = mask_loss(ALPHA * b.s(asks) @ b.a(nodes).T, P)
            if near:
                loss = loss + near * (((b.state.weight - eye) ** 2).sum() + ((b.action.weight - eye) ** 2).sum())
            opt.zero_grad(); loss.backward(); opt.step()
    return b


def chat_recalls(b, chat, hybrid=False):
    """Per-question recall@10 of a bridge (or the frozen space when b is None) on one chat."""
    K, S = (chat["nodes"], chat["asks"]) if b is None else b.views(chat["nodes"], chat["asks"])
    out = []
    for r, q in enumerate(chat["qs"]):
        o = order_of(K @ S[r])
        out.append(recall(fuse(chat["lexorder"][r], o) if hybrid else o, q[1]))
    return out


# ---------------------------------------------------------------- folds and statistics

FOLDS = [(2 * f, 2 * f + 1) for f in range(5)]


def inner_pairs(train_ids):
    """Four dev pairs carved from the eight training chats of an outer fold, in index order."""
    t = sorted(train_ids)
    return [(t[2 * j], t[2 * j + 1]) for j in range(len(t) // 2)]


def cluster_boot(diff, cluster, n=4000, seed=0):
    """Paired difference: mean and 95% percentile CI resampling whole clusters (chats, or questions)."""
    diff = np.asarray(diff, dtype=np.float64); cluster = np.asarray(cluster)
    ids = np.unique(cluster); sums = np.array([diff[cluster == c].sum() for c in ids])
    cnt = np.array([(cluster == c).sum() for c in ids]); rng = np.random.default_rng(seed)
    pick = rng.integers(0, len(ids), (n, len(ids)))
    boots = sums[pick].sum(1) / cnt[pick].sum(1)
    return float(diff.mean()), [float(np.percentile(boots, 2.5)), float(np.percentile(boots, 97.5))]
