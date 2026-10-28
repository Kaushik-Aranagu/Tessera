#!/usr/bin/env python3
"""Stage 1.9 (prediction P10): exact deletion with keys defined from per-node cite logs.

Why. Use-driven key learning moves node keys toward the questions that cited them. If a key is updated in place
(the move rule), a question the user later forgets keeps pulling on the keys it touched, and the result depends on the
order the questions arrived in (method Prop. 6.12 (iv), Section 6.9). Method Section 3.7 instead defines each key as a
canonical function of a per-node cite log, with the mean question state s_bar frozen per bridge version (method
Section 8, errors 10 and 11). P10 says: after forget plus closure, every byte of the memory state equals a fresh
rebuild from the retained records; a move-rule key with no log fails this; and the additive centred rule's clean gain
matches the centred move rule's within +-0.005.

PRE-REGISTERED PROTOCOL (written before any run of this script; not changed after seeing results)

Data and read: LoCoMo only, all 10 chats, 1,536 questions, through retrieval.Reader (tuned rank-16 bridges; chat i read
with the bridge of the outer fold that held it out, fold i // 2). K0 = n(A e_v) for every node (the base key plane),
S[r] = n(S e_q) for every question (the read query; it never changes). LongMemEval-S is not used: it has one question
per haystack, so the s12 learning protocol does not apply to it (as in s12_cites.py).

Learning protocol (the s12_cites.py protocol, clean cites): per held-out chat the same 3 shuffled orders as s12
(np.random.default_rng([chat, order, 2027]).permutation(nq)); at each question the current keys score S[r]; recall@10
dense and fused with BM25 (RRF k 60); then the question's cites (clean = all its marked evidence nodes) update the
keys. Per question the 3 orders are averaged. Arms (all see the same orders and the same reads of S[r]):
  base       no learning (s12_cites.run_order with no rule)
  move       plain move rule, eta 0.1, no log (s12_cites.run_order, "move eta0.1")
  centred    centred move rule, eta 0.1, c 1, no log (s12_cites.run_order, "centred"): d = n(S[r] - mu),
             k_v <- n(k_v + eta (d - k_v)); mu = the mean question state of the fold's 8 training chats under its
             bridge, frozen per bridge version (computed exactly as s12)
  additive   log-defined additive centred key (the P10 rule):
               k_v = K0_v                                        if the log of v is empty
               k_v = n( nu K0_v + sum_{t in log_v, ascending qid} n(n(S z_t) - s_bar) )   otherwise
             with nu = 1/eta' = (1 - eta)/eta = 9 at eta 0.1 (eta' = eta/(1 - eta), method P10), s_bar = mu.
             The log of node v stores, for each question t that cited v, its id and z_t = the frozen bge-small question
             vector (encoder space, not the S view; method 6.9 L1). The sum is formed in float64 in ascending question
             id order (canonical, order-independent), then normalised and stored as float32 keys. The per-question
             state n(S z_t) is a cache computed one row at a time (bridge.state_np on a 1 x 384 input: a fixed float
             path). The direction n(n(S z_t) - s_bar) is the same as the centred move rule's d, which is what makes the
             two rules agree to first order in eta (P10). Reads use the same S[r] as every other arm.
  literal    auxiliary, not in the bar: method 3.7's formula as printed, without the outer n on the centred term:
             n(nu K0_v + sum (n(S z_t) - s_bar)), nu 9.
The memory recomputes the keys of the dirty set (the nodes the question cited) from their logs after every question.
Self-checks before any number is used: the move and centred arms' reads must equal s12_cites.run_order exactly (my
copy of the update that also returns the final keys is asserted against it); the base keys from bridge.key_np(nodes)
must equal Reader's K0 byte for byte; the additive memory's keys before any cite must equal K0 byte for byte.

Deletion check (after each full clean-cite stream: 10 chats x 3 orders x 3 forget seeds = 90 cases per rule):
  forget set: a random 20% of the chat's questions, round(0.2 nq), np.random.default_rng([chat, seed, 2028]).choice
  without replacement, seeds 0, 1, 2 (the same forget sets for every rule and every order).
  Memory state, compared blob by blob as bytes (and as one sha256):
    version     bridge tag, eta, nu, key form, s_bar mode
    s_bar       float64 bytes
    base_keys   K0, float32 bytes
    records     retained question records in ascending id: id, z_t float32 bytes, cite list
    logs        per node in index order: entry count, then (question id, z_t float32 bytes) in ascending id
    state_cache per retained question: n(S z_t) float32 bytes
    acc         per node cached float64 accumulator u_v (nu K0_v when the log is empty)
    counts      per node cite counts, int32
    keys        float32 bytes
    Not compared: the commit counter (a bookkeeping number, not derived from records; the live memory has committed
    many versions, the rebuild once). No arm keeps a read cache.
  Forget + closure (data-flow closure, method 5.4 step 1): drop the forgotten questions' records, their entries in
  every node log, their cached states; recompute s_bar if it depends on them; recompute from the log every key in the
  dirty set (nodes the forgotten questions cited; every logged node when s_bar changed). With clean cites the cites
  are the marked evidence, chosen without reading any key, so the selection closure (5.4 step 2) is empty here.
  Fresh rebuild: a new memory built only from the retained records (base keys recomputed with bridge.key_np), ingested
  in a shuffled order np.random.default_rng([chat, order, seed, 2030]).permutation(retained), then one commit.
  Rules checked:
    L1  additive log-defined key, s_bar = the fold's frozen training mean (as in the learning protocol)
    L2  the same key with s_bar = the canonical mean (float64, ascending id) of the memory's own retained question
        states, recomputed at every commit (exercises D6: a frozen statistic recomputed in the closure). The live L2
        memory commits after every question of the stream.
    N1  plain move rule (eta 0.1) with no log: the state is the float32 key array after the stream; forgetting can only
        drop the records (no inverse exists). Its fresh rebuild replays the retained records through the same rule, in
        the most favourable order (the original arrival order restricted to retained questions; this needs an order
        log the no-log rule does not keep) and, reported too, in ascending id order.
    N2  centred move rule (eta 0.1, c 1) with no log, same as N1 (reported, not in the bar).
    X   negative control for the comparator's power (reported, not in the bar): L1's memory, but deletion subtracts the
        forgotten terms from the cached float64 accumulators instead of recomputing from the log (method 6.9: (sum+x)-x
        is not bitwise the sum without x).
  Also reported: order dependence (the final state of the full stream under orders 0, 1, 2 compared byte for byte,
  for L1, L2, N1, N2); residual influence of forgotten questions on the no-log keys (mean over forgotten question x
  and node v it cited of <k_v, d_x> in the kept state minus in the arrival-order rebuild, d_x the rule's direction);
  P10's O(eta^2) claim (after the order-0 stream, |additive - centred move| key difference for nodes with exactly 1
  cite versus 2 or more, and the share of cited nodes with 2 or more cites).

Statistics: per question the 3 orders are averaged; paired differences use the chat-clustered bootstrap
(common.cluster_boot, 4,000 draws, seed 0: the same resamples for every comparison). Nothing is tuned; eta 0.1, c 1 and
nu = 9 are fixed in advance from s12 and P10; no test chat chooses anything.

Pass bar (front matter table, test 1.9): "every byte of the memory state equals the rebuild from the retained records;
a move-rule key with no log fails; the additive centred rule's clean gain is within +-0.005 of the centred move rule";
fails if "any byte differs". Made exact here:
  B (bytes)    L1 and L2 states equal their fresh rebuilds in every blob in all 90 + 90 cases.
  N (no log)   N1's state differs from its retained-record rebuild (arrival-order replay) in at least 1 of the 90
               cases (predicted: all 90).
  G (gain)     D = mean over questions of (additive - centred) dense recall@10 under clean cites, with its 95%
               chat-clustered CI. G passes if |D| <= 0.005 and the CI lies inside [-0.005, +0.005]; G fails if
               |D| > 0.005; otherwise G is inconclusive (point inside, interval reaching past the bar).
Decision rule (mechanical, written into the verdict):
  PASS          B and N hold and G passes.
  FAIL          B fails, or N fails, or G fails.
  INCONCLUSIVE  B and N hold and G is inconclusive.
Reproduction note (not part of the bar): s12_cites.json on this setup reports baseline dense 0.6622 and clean gains
+0.0159 (move eta0.1) and +0.0197 (centred); this run recomputes them and says if they differ.

What this check does not cover: the selection closure with real (Haiku) cites, storage scrubbing (D4: SQLite
secure_delete, WAL, backups), gists and BM25 statistics (no node is deleted, only questions), the bridge weights
(trained on public chats only, policy A: zero influence), and LongMemEval-S.
Run history (added after run 1; the protocol above is unchanged): run 1 warned of a 0/0 in the L2 variant's first
commit (s_bar equals the single stored question, so its centred term had zero norm and became NaN until the next
commit). Fixed by defining a zero-norm term as zero, plus a finiteness assertion after every stream; rerun.
Usage: python s19_deletion.py
"""
import collections, hashlib, json, os, sys, time
import numpy as np
import torch
from threadpoolctl import threadpool_limits

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
from retrieval import Reader  # noqa: E402

ETA = 0.1
NU = (1.0 - ETA) / ETA  # 1 / eta', eta' = eta / (1 - eta)
FORGET = 0.2
SEEDS = 3
ORDERS = S12.ORDERS
BAR = 0.005
CENTRED = S12.RULES["centred"]
MOVE = S12.RULES["move η0.1"]
assert CENTRED == dict(eta=ETA, c=1.0) and MOVE == dict(eta=ETA)


# ---------------------------------------------------------------- the log-defined memory

class LogMemory:
    """One chat's node plane under one bridge version, with keys defined from per-node cite logs (method 3.7)."""

    def __init__(self, k0, bridge, tag, sbar_mode, sbar_fixed=None, form="normed", nu=NU):
        self.k0 = np.array(k0, dtype=np.float32, copy=True)
        self.bridge, self.tag, self.sbar_mode, self.form, self.nu = bridge, tag, sbar_mode, form, float(nu)
        self.sbar_fixed = None if sbar_fixed is None else np.array(sbar_fixed, dtype=np.float64, copy=True)
        n = len(self.k0)
        self.asks = {}                          # qid -> (z float32, cites tuple): the retained records
        self.logs = [dict() for _ in range(n)]  # node -> {qid: z}: cite log of encoder-space states
        self.s_cache = {}                       # qid -> n(S z) float32 (cache, one row at a time)
        self.acc = self.nu * self.k0.astype(np.float64)
        self.keys = self.k0.copy()
        self.counts = np.zeros(n, dtype=np.int32)
        self.commits = 0
        self._set_sbar()

    def clone(self):
        m = object.__new__(LogMemory); m.__dict__.update(self.__dict__)
        m.k0 = self.k0.copy(); m.asks = {q: (z.copy(), c) for q, (z, c) in self.asks.items()}
        m.logs = [{q: z.copy() for q, z in L.items()} for L in self.logs]
        m.s_cache = {q: s.copy() for q, s in self.s_cache.items()}
        m.acc = self.acc.copy(); m.keys = self.keys.copy(); m.counts = self.counts.copy(); m.sbar = self.sbar.copy()
        m.sbar_fixed = None if self.sbar_fixed is None else self.sbar_fixed.copy()
        return m

    def _state_of(self, z):
        return self.bridge.state_np(z[None])[0].astype(np.float32)

    def _set_sbar(self):
        if self.sbar_mode == "fold":
            self.sbar = self.sbar_fixed.copy()
        else:
            tot = np.zeros(self.k0.shape[1], dtype=np.float64)
            for q in sorted(self.s_cache):
                tot = tot + self.s_cache[q].astype(np.float64)
            self.sbar = tot / max(len(self.s_cache), 1)

    def term(self, q):
        # Bug fix after run 1 (see the log): in the L2 variant the first commit has s_bar equal to the only stored
        # question, so the centred term was 0/0 = NaN until the next commit. A zero-norm term is now defined as zero.
        x = self.s_cache[q].astype(np.float64) - self.sbar
        if self.form != "normed":
            return x
        nrm = np.linalg.norm(x)
        return x / nrm if nrm > 0 else np.zeros_like(x)

    def _rebuild_node(self, v):
        log = self.logs[v]
        u = self.nu * self.k0[v].astype(np.float64)
        for q in sorted(log):
            u = u + self.term(q)
        self.acc[v] = u
        self.keys[v] = (u / np.linalg.norm(u)).astype(np.float32) if log else self.k0[v]
        self.counts[v] = len(log)

    def add(self, q, z, cites):
        """Store one question record and its log entries; returns the dirty nodes (commit separately)."""
        z = np.array(z, dtype=np.float32, copy=True); cites = tuple(int(v) for v in cites)
        self.asks[q] = (z, cites)
        self.s_cache[q] = self._state_of(z)
        for v in cites:
            self.logs[v][q] = z
        return set(cites)

    def commit(self, dirty):
        self._set_sbar(); self.commits += 1
        dirty = set(dirty)
        if self.sbar_mode == "own":  # s_bar is a function of every retained record: every logged key is dirty
            dirty |= {v for v, L in enumerate(self.logs) if L}
        for v in sorted(dirty):
            self._rebuild_node(v)

    def forget(self, qs):
        """Data-flow closure: records, log entries, cached states, s_bar, and every key that depended on them."""
        dirty = set()
        for q in qs:
            _, cites = self.asks.pop(q)
            del self.s_cache[q]
            for v in cites:
                del self.logs[v][q]
            dirty |= set(cites)
        self.commit(dirty)
        return dirty

    def forget_subtract(self, qs):
        """Negative control: subtract the forgotten terms from the cached accumulators (no recompute from the log)."""
        assert self.sbar_mode == "fold"
        for q in qs:
            t = self.term(q)
            _, cites = self.asks.pop(q)
            for v in cites:
                del self.logs[v][q]
                self.acc[v] = self.acc[v] - t
                self.keys[v] = (self.acc[v] / np.linalg.norm(self.acc[v])).astype(np.float32)
                self.counts[v] = len(self.logs[v])
            del self.s_cache[q]

    def state(self):
        b = collections.OrderedDict()
        b["version"] = f"{self.tag}|eta={ETA!r}|nu={self.nu!r}|form={self.form}|sbar={self.sbar_mode}".encode()
        b["s_bar"] = np.ascontiguousarray(self.sbar, dtype=np.float64).tobytes()
        b["base_keys"] = self.k0.tobytes()
        b["records"] = b"".join(np.int64(q).tobytes() + self.asks[q][0].tobytes() + np.int32(len(self.asks[q][1])).tobytes()
                                + np.array(self.asks[q][1], dtype=np.int32).tobytes() for q in sorted(self.asks))
        b["logs"] = b"".join(np.int32(len(L)).tobytes() + b"".join(np.int64(q).tobytes() + L[q].tobytes() for q in sorted(L))
                             for L in self.logs)
        b["state_cache"] = b"".join(np.int64(q).tobytes() + self.s_cache[q].tobytes() for q in sorted(self.s_cache))
        b["acc"] = self.acc.tobytes()
        b["counts"] = self.counts.tobytes()
        b["keys"] = self.keys.tobytes()
        return b


def digest(blobs):
    h = hashlib.sha256()
    for k, v in blobs.items():
        h.update(k.encode()); h.update(np.int64(len(v)).tobytes()); h.update(v)
    return h.hexdigest()


def diff_blobs(a, b):
    return [k for k in a if a[k] != b.get(k)] + [k for k in b if k not in a]


def fresh_log(k0, br, tag, mode, mu, form, Z, ev, ingest):
    m = LogMemory(k0, br, tag, mode, mu if mode == "fold" else None, form)
    for r in ingest:
        m.add(int(r), Z[r], ev[r])
    m.commit(range(len(k0)))
    return m


# ---------------------------------------------------------------- streams

def move_stream(K0, S, lexorder, qs, cites, order, eta, c, mu):
    """s12_cites.run_order without the push, also returning the final keys (asserted equal to s12's reads)."""
    keys = K0.copy(); dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    for r in order:
        s = S[r]; top = C.order_of(keys @ s)
        dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        d = S12.unit1(s - c * mu) if c else s
        for v in cites[r]:
            keys[v] = S12.unit1(keys[v] + eta * (d - keys[v]))
    return dense, fused, keys


def move_keys(K0, S, cites, seq, eta, c, mu):
    """Replay a list of question records through the no-log move rule (the rebuild of N1/N2)."""
    keys = K0.copy()
    for r in seq:
        d = S12.unit1(S[r] - c * mu) if c else S[r]
        for v in cites[r]:
            keys[v] = S12.unit1(keys[v] + eta * (d - keys[v]))
    return keys


def log_stream(mem, S, lexorder, qs, Z, ev, order, read=True):
    dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    for r in order:
        if read:
            top = C.order_of(mem.keys @ S[r])
            dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        mem.commit(mem.add(int(r), Z[r], ev[r]))
    return dense, fused


# ---------------------------------------------------------------- main

def main():
    t0 = time.time()
    torch.set_num_threads(1)
    out_json = os.path.join(HERE, "results", "s19_deletion.json")
    R = Reader(with_lme=False)
    arms = ("base", "move", "centred", "additive", "literal")
    vals = {a: {"dense": [], "fused": []} for a in arms}
    chat_of, cat_of = [], []
    dele = {k: collections.defaultdict(int) for k in ("L1", "L2", "X", "N1", "N2")}
    dele_diff_blobs = {k: collections.Counter() for k in ("L1", "L2", "X")}
    nolog = {k: dict(differ_arrival=0, differ_sorted=0, nodes_differ=[], max_abs=[], residual=[]) for k in ("N1", "N2")}
    x_keys_differ = 0
    order_dep = {k: [] for k in ("L1", "L2", "N1", "N2")}
    p10 = dict(one_cite=[], multi_cite=[], n_cited=0, n_multi=0)
    dirty_sizes = {"L1": [], "L2": []}
    s_gap = 0.0
    checks = dict(move_reads_equal_s12=True, base_keys_equal_reader=True, additive_initial_keys_equal_K0=True)

    with threadpool_limits(1):
        for i, ch in enumerate(R.chats):
            f = i // 2; br = R.bridges[f]; tag = f"f{f}_r16"
            K0, S = R.keys[i]
            k0 = br.key_np(ch["nodes"]).astype(np.float32)
            checks["base_keys_equal_reader"] &= k0.tobytes() == K0.tobytes()
            tr = [j for j in range(10) if j not in C.FOLDS[f]]
            mu = np.concatenate([br.views(R.chats[j]["nodes"], R.chats[j]["asks"])[1] for j in tr]).mean(0)
            nq = len(ch["qs"]); Z = ch["asks"]; ev = [list(q[1]) for q in ch["qs"]]; opened = [[] for _ in range(nq)]
            orders = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(ORDERS)]
            forgets = [sorted(np.random.default_rng([i, s, 2028]).choice(nq, size=int(round(FORGET * nq)), replace=False).tolist())
                       for s in range(SEEDS)]
            acc = {a: (np.zeros(nq), np.zeros(nq)) for a in arms}
            finals = {k: [] for k in order_dep}
            for o, order in enumerate(orders):
                d, fu = S12.run_order(K0, S, ch["lexorder"], ch["qs"], ev, opened, order, {}, mu)
                acc["base"][0][:] += d / ORDERS; acc["base"][1][:] += fu / ORDERS
                runs = {}
                for name, cfg in (("move", MOVE), ("centred", CENTRED)):
                    d, fu = S12.run_order(K0, S, ch["lexorder"], ch["qs"], ev, opened, order, cfg, mu)
                    d2, fu2, keys = move_stream(K0, S, ch["lexorder"], ch["qs"], ev, order, cfg["eta"], cfg.get("c", 0.0), mu)
                    checks["move_reads_equal_s12"] &= bool(np.array_equal(d, d2) and np.array_equal(fu, fu2))
                    acc[name][0][:] += d / ORDERS; acc[name][1][:] += fu / ORDERS; runs[name] = keys
                mem = LogMemory(k0, br, tag, "fold", mu, "normed")
                checks["additive_initial_keys_equal_K0"] &= mem.keys.tobytes() == K0.tobytes()
                d, fu = log_stream(mem, S, ch["lexorder"], ch["qs"], Z, ev, order)
                acc["additive"][0][:] += d / ORDERS; acc["additive"][1][:] += fu / ORDERS
                lit = LogMemory(k0, br, tag, "fold", mu, "raw")
                d, fu = log_stream(lit, S, ch["lexorder"], ch["qs"], Z, ev, order)
                acc["literal"][0][:] += d / ORDERS; acc["literal"][1][:] += fu / ORDERS
                own = LogMemory(k0, br, tag, "own", None, "normed")
                log_stream(own, S, ch["lexorder"], ch["qs"], Z, ev, order, read=False)
                assert all(np.isfinite(m_.keys).all() and np.isfinite(m_.acc).all() for m_ in (mem, lit, own))
                s_gap = max(s_gap, max(float(np.abs(mem.s_cache[r] - S[r]).max()) for r in range(nq)))
                finals["L1"].append(digest(mem.state())); finals["L2"].append(digest(own.state()))
                finals["N1"].append(runs["move"].tobytes()); finals["N2"].append(runs["centred"].tobytes())
                if o == 0:  # P10: O(eta^2) difference between the additive and the centred move keys
                    dk = np.linalg.norm(mem.keys.astype(np.float64) - runs["centred"].astype(np.float64), axis=1)
                    p10["one_cite"] += dk[mem.counts == 1].tolist(); p10["multi_cite"] += dk[mem.counts >= 2].tolist()
                    p10["n_cited"] += int((mem.counts >= 1).sum()); p10["n_multi"] += int((mem.counts >= 2).sum())
                # ---- deletion: 3 forget seeds from this end-of-stream state
                for s, fg in enumerate(forgets):
                    fset = set(fg); keep = [r for r in range(nq) if r not in fset]
                    ingest = np.random.default_rng([i, o, s, 2030]).permutation(keep)
                    for name, live, mode in (("L1", mem, "fold"), ("L2", own, "own")):
                        m = live.clone(); dirty_sizes[name].append(len(m.forget(fg)))
                        fr = fresh_log(br.key_np(ch["nodes"]).astype(np.float32), br, tag, mode, mu, "normed", Z, ev, ingest)
                        bad = diff_blobs(m.state(), fr.state())
                        dele[name]["cases"] += 1; dele[name]["equal"] += not bad
                        dele[name]["sha_equal"] += digest(m.state()) == digest(fr.state())
                        dele_diff_blobs[name].update(bad)
                        if name == "L1":
                            fresh_l1 = fr
                    m = mem.clone(); m.forget_subtract(fg)
                    bad = diff_blobs(m.state(), fresh_l1.state())
                    dele["X"]["cases"] += 1; dele["X"]["equal"] += not bad; dele_diff_blobs["X"].update(bad)
                    x_keys_differ += "keys" in bad
                    for name, cfg in (("N1", MOVE), ("N2", CENTRED)):
                        c = cfg.get("c", 0.0); kept = runs["move" if name == "N1" else "centred"]
                        reb_a = move_keys(K0, S, ev, [r for r in order if r not in fset], ETA, c, mu)
                        reb_s = move_keys(K0, S, ev, keep, ETA, c, mu)
                        nolog[name]["differ_arrival"] += kept.tobytes() != reb_a.tobytes()
                        nolog[name]["differ_sorted"] += kept.tobytes() != reb_s.tobytes()
                        dn = (kept != reb_a).any(1)
                        nolog[name]["nodes_differ"].append(int(dn.sum()))
                        nolog[name]["max_abs"].append(float(np.abs(kept - reb_a).max()))
                        for x in fg:
                            dx = S12.unit1(S[x] - c * mu) if c else S[x]
                            for v in ev[x]:
                                nolog[name]["residual"].append(float(kept[v] @ dx - reb_a[v] @ dx))
                        dele[name]["cases"] += 1; dele[name]["equal"] += kept.tobytes() == reb_a.tobytes()
            for k in order_dep:
                order_dep[k].append(len(set(finals[k])) == 1)
            for a in arms:
                vals[a]["dense"] += acc[a][0].tolist(); vals[a]["fused"] += acc[a][1].tolist()
            chat_of += [i] * nq; cat_of += [q[2] for q in ch["qs"]]
            print(f"chat {i}: {nq} questions, {time.time() - t0:.0f}s", flush=True)

    assert all(checks.values()), checks
    chat_of = np.array(chat_of); cat_of = np.array(cat_of)
    V = {a: {m: np.array(v) for m, v in d.items()} for a, d in vals.items()}
    out = dict(test="1.9", prediction="P10", eta=ETA, nu=NU, forget_fraction=FORGET, seeds=SEEDS, orders=ORDERS,
               self_checks=checks, max_abs_state_cache_vs_reader_S=s_gap)
    out["baseline"] = dict(dense=round(float(V["base"]["dense"].mean()), 4), fused=round(float(V["base"]["fused"].mean()), 4),
                           dense_multi_hop=round(float(V["base"]["dense"][cat_of == 1].mean()), 4))
    gains = {}
    for a in arms[1:]:
        g = {}
        for m in ("dense", "fused"):
            dd = V[a][m] - V["base"][m]; mean, ci = C.cluster_boot(dd, chat_of)
            g[m] = dict(value=round(float(V[a][m].mean()), 4), gain=round(mean, 4), ci=[round(x, 4) for x in ci])
        g["multi_hop_gain"] = round(float((V[a]["dense"] - V["base"]["dense"])[cat_of == 1].mean()), 4)
        gains[a] = g
    out["gains_clean"] = gains
    out["reproduces_s12"] = dict(baseline_dense=out["baseline"]["dense"] == 0.6622,
                                 move_gain=gains["move"]["dense"]["gain"] == 0.0159,
                                 centred_gain=gains["centred"]["dense"]["gain"] == 0.0197)
    diff = {}
    for m in ("dense", "fused"):
        mean, ci = C.cluster_boot(V["additive"][m] - V["centred"][m], chat_of)
        per_chat = [float((V["additive"][m] - V["centred"][m])[chat_of == j].mean()) for j in range(10)]
        diff[m] = dict(D=mean, ci=ci, per_chat=[round(x, 5) for x in per_chat])
    mean, ci = C.cluster_boot(V["literal"]["dense"] - V["centred"]["dense"], chat_of)
    diff["literal_minus_centred_dense"] = dict(D=mean, ci=ci)
    out["additive_minus_centred"] = diff
    one = np.array(p10["one_cite"]); multi = np.array(p10["multi_cite"])
    out["p10_first_order"] = dict(cited_nodes=p10["n_cited"], with_2plus_cites=p10["n_multi"],
                                  share_2plus=round(p10["n_multi"] / max(p10["n_cited"], 1), 4),
                                  one_cite_max_key_diff=float(one.max()) if len(one) else None,
                                  multi_cite_key_diff_mean=float(multi.mean()), multi_cite_key_diff_median=float(np.median(multi)),
                                  multi_cite_key_diff_max=float(multi.max()),
                                  multi_cite_share_above_1e_4=float((multi > 1e-4).mean()))
    out["deletion"] = {}
    for k in ("L1", "L2", "X"):
        out["deletion"][k] = dict(cases=dele[k]["cases"], byte_equal=dele[k]["equal"],
                                  sha_equal=dele[k].get("sha_equal"), differing_blobs=dict(dele_diff_blobs[k]))
    out["deletion"]["X"]["keys_differ_cases"] = x_keys_differ
    out["deletion"]["dirty_set_size_mean"] = {k: float(np.mean(v)) for k, v in dirty_sizes.items()}
    for k in ("N1", "N2"):
        nl = nolog[k]; res = np.array(nl["residual"])
        out["deletion"][k] = dict(cases=dele[k]["cases"], byte_equal_arrival_rebuild=dele[k]["equal"],
                                  differ_arrival_rebuild=nl["differ_arrival"], differ_sorted_rebuild=nl["differ_sorted"],
                                  nodes_differ_mean=float(np.mean(nl["nodes_differ"])),
                                  max_abs_key_diff_mean=float(np.mean(nl["max_abs"])),
                                  residual_influence_mean=float(res.mean()), residual_influence_share_positive=float((res > 0).mean()),
                                  residual_pairs=int(len(res)))
    out["order_independent_chats"] = {k: int(sum(v)) for k, v in order_dep.items()}

    # ---- verdict, mechanical
    B = (out["deletion"]["L1"]["byte_equal"] == out["deletion"]["L1"]["cases"] == 90
         and out["deletion"]["L2"]["byte_equal"] == out["deletion"]["L2"]["cases"] == 90)
    N = out["deletion"]["N1"]["differ_arrival_rebuild"] >= 1
    D, (lo, hi) = diff["dense"]["D"], diff["dense"]["ci"]
    G = "pass" if abs(D) <= BAR and -BAR <= lo and hi <= BAR else ("fail" if abs(D) > BAR else "inconclusive")
    overall = "fail" if (not B or not N or G == "fail") else ("pass" if G == "pass" else "inconclusive")
    out["verdict"] = dict(B_bytes_equal_all=B, N_nolog_move_fails=N, G_gain=G, D=round(D, 5), D_ci=[round(lo, 5), round(hi, 5)],
                          bar=BAR, overall=overall)
    out["seconds"] = round(time.time() - t0, 1)
    os.makedirs(os.path.dirname(out_json), exist_ok=True)
    json.dump(out, open(out_json, "w"), indent=1)

    print(f"\nself-checks {checks}; max |state cache - Reader S| {s_gap:.2e}")
    b = out["baseline"]; print(f"baseline dense {b['dense']:.4f} fused {b['fused']:.4f} multi-hop {b['dense_multi_hop']:.4f}")
    for a, g in gains.items():
        print(f"  {a:<9} dense {g['dense']['value']:.4f} gain {g['dense']['gain']:+.4f} [{g['dense']['ci'][0]:+.4f},{g['dense']['ci'][1]:+.4f}]"
              f"  fused gain {g['fused']['gain']:+.4f} [{g['fused']['ci'][0]:+.4f},{g['fused']['ci'][1]:+.4f}]  mh {g['multi_hop_gain']:+.4f}")
    print(f"reproduces s12: {out['reproduces_s12']}")
    print(f"additive - centred: dense {diff['dense']['D']:+.5f} [{diff['dense']['ci'][0]:+.5f},{diff['dense']['ci'][1]:+.5f}]"
          f"  fused {diff['fused']['D']:+.5f} [{diff['fused']['ci'][0]:+.5f},{diff['fused']['ci'][1]:+.5f}]")
    print(f"literal - centred: dense {diff['literal_minus_centred_dense']['D']:+.5f} {[round(x, 5) for x in diff['literal_minus_centred_dense']['ci']]}")
    print("P10 first order:", json.dumps(out["p10_first_order"]))
    print("deletion:", json.dumps(out["deletion"], indent=1))
    print("order-independent chats (of 10):", out["order_independent_chats"])
    print("verdict:", json.dumps(out["verdict"]))
    print(f"{out['seconds']}s")


if __name__ == "__main__":
    main()
