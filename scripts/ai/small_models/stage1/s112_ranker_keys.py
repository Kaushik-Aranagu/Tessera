#!/usr/bin/env python3
"""Stage 1.12: does learning keys from use add anything ON TOP of the ranker? (public data only; pre-registered)

Written before any number of this test was produced. The protocol, the primary metric and the decision rule below are
fixed; this docstring's sha256[:16] is printed in the log and stored in the JSON.

Why. Stage 1 found that learning keys from Haiku's cites gains under 1 point of recall@10 on LoCoMo (s111: the s12 rule
picked per fold on dev chats, +0.005 over the fused rank-16 read after fusion, chat interval [-0.0005, +0.0111]), while
an LLM-free LightGBM ranker over the fused read's top 50 gains +0.094 (0.7492 vs 0.6553). If learning from use is worth
keeping, it has to add to that ranker. This test gives the ranker the learned keys as features and asks whether recall
rises.

Data and read (unchanged from s111_baselines.py). LoCoMo: 1,536 questions on 10 chats (common.load_locomo, sha-pinned),
outer folds common.FOLDS (chat pairs (0,1) ... (8,9)); chat i is read with the tuned rank-16 bridge of fold i // 2
(retrieval.Reader keys, trained on the 8 other chats). LongMemEval-S: the 428 questions with user-turn evidence
(common.load_lme), read with the rank-16 bridge trained on all 10 LoCoMo chats. Cites: Haiku's hop-0 cites
(runs/answers_hop0.jsonl, rows of kind "read"; snippet numbers n mapped to nodes through runs/tasks_hop0.jsonl.gz); the
opened set of a question is its 10 hop-0 snippet nodes (the fused rank-16 top 10). No LLM is called; nothing is re-read.

Arm A (reference): the s111 ranker exactly. LightGBM over the top 50 candidates of each question's fused rank-16 read
(RRF k 60 of the BM25 list and the bridge list), its 25 features (s111_baselines.qfeats), labels 1 for a marked evidence
node else 0, scored by recall@10 of the reordered top 50. For outer fold f it is fit on the 8 training chats, whose
bridge features come from inner rank-16 bridges that held each chat's pair out (common.train on the other 6 training
chats, fold f's tuned lr from s11_rank.json, seed 1000 + 10 f + pair[0]); the test pair uses the outer bridge.
Hyperparameters per fold on dev chats (the test pair of fold (f + 1) mod 5, read with the inner bridge that held that pair
out): objective {lambdarank, binary} x num_leaves {7, 31} x trees {50, 100, 200, 400} (learning rate 0.05, min 20 rows
per leaf, no subsampling, deterministic, one thread, random_state 0), fit on the 6 training chats outside the dev pair,
best mean dev recall@10, ties first in grid order. LongMemEval-S: the config with the best pooled dev recall over the 5
folds, fit on all 10 LoCoMo chats (features from the bridge that held each chat out). Check (the run stops otherwise):
per-fold picks equal s111's picks.ranker, LoCoMo mean 0.7492, LongMemEval-S 0.9187 with config lambdarank/31/50.

Learning streams (the s12 protocol). For a chat read with bridge b (keys K0 = b's key view of the nodes, states S = b's
state view of the questions), a rule from s12_cites.RULES and an order o in {0, 1, 2}
(np.random.default_rng([chat, o, 2027]).permutation, the s12/s111 orders), the keys start at K0 and the chat's questions
are visited in that order; after question r the keys learn from r's Haiku cites exactly as s12_cites.run_order (pull the
cited keys toward the state; centred rules toward s - c mu, with mu the mean ask state of b's own training chats under b,
frozen; push the opened-but-not-cited keys for contrastive and combo). Cites are static (what Haiku cited from the hop-0
opened top 10). Causal: the features of question r use the keys as they stand BEFORE r's own update, so in order o only
the questions visited before r have moved any key. Every stream starts from K0 (nothing carries across chats or orders).

Arm B (under test): arm A's ranker with 4 learned-key features appended (29 features, columns 26 to 29). With L_r the
learned keys before r's update and s_r the bridge state of question r, per candidate v of the SAME 50 candidates (the
base fused top 50, so B can only reorder what A reorders and the comparison isolates the features):
  26 learned cosine      l_v = L_r[v] . s_r  (a key that has not moved gives exactly the base bridge cosine)
  27 learned rank        rank of v among the 50 by l_v, descending, 0 = best, ties by fused position
  28 learned gap         l_v - max over the 50 of l
  29 learned minus base  l_v - K0[v] . s_r   (exactly 0 for a key that has not moved)
Rule (PRIMARY): per outer fold f, the s12 rule picked on fold f's dev chats by s111 (picks.ours.fused for haiku cites:
fold 0 combo, 1 move η0.1, 2 centred, 3 combo, 4 contrastive). The run recomputes these picks from its own dev streams
(best mean dev fused recall@10, each question averaged over the 3 orders, ties first in s12's RULES order) and stops if
they differ from s111's. Within fold f the same rule drives the streams of its training chats, its dev chats and its
test pair.
Secondary arm "combo" (not decisive): the same with combo (centred pull η 0.1, c 1, plus centred push η 0.02) in every
fold.

Training rows of arm B (no leak through bridges or streams). For outer fold f, training chat j's 29 features come from
its inner bridge b (the one that held j's pair out, as in A) and from the learning stream run on chat j with b's keys,
b's states, b's frozen mean, j's own Haiku cites and opened sets, under fold f's rule. Labels are the gold evidence, as in
A. Streams use cites, never labels, so no chat's features come from a bridge or a learning stream that saw its labels.
Test chats: the outer bridge, the outer fold's frozen mean (mean ask state of its 8 training chats), their own cites.
Dev chats: their inner bridge and that bridge's frozen mean, as in A and in s111's dev runs.

Orders. The stream depends on the order, so arm B is run once per order o: the model of order o is fit on the order-o
features of its training chats and scored on the order-o features of the chats it is evaluated on (dev or test). Each
question's arm B recall@10 is the mean over the 3 orders. Arm B's hyperparameters: the same grid and procedure as A, with
a config's dev score per fold = mean over the dev questions of their order-averaged recall@10 (ties first in grid
order). Arm A does not depend on the order (one fit per config, as in s111).

LongMemEval-S (428 questions). One question per history, so nothing is asked twice and the keys cannot learn: learned =
base (features 26 to 29 are the bridge cosine, its rank among the 50, its gap to the best, and 0). Arm B there: the config
with the best pooled dev score over the 5 folds, fit on all 10 LoCoMo chats (the bridge that held each chat out, and chat
i's outer stream under fold i // 2's rule), one model per order, each question's recall averaged over the 3 models;
compared with arm A (s111's LongMemEval-S ranker). Same for combo.

PRIMARY METRIC: LoCoMo recall@10 of B minus A, per question (1,536), paired by question, chat-clustered.

Statistics. LoCoMo: common.cluster_boot (whole chats resampled, 4,000 draws, seed 0, the same draws for every comparison)
for the 95% percentile interval. Next to every interval: the exact one-sided chat sign-flip p (statistic = the
question-weighted mean difference sum_j e_j D_j / N, D_j = chat j's summed difference, N = 1,536; all 2^10 sign vectors
e; p = share of sign vectors whose statistic is >= the observed one, the observed included, so p >= 1/1024) and a
jackknife-t 95% interval (leave one chat out; theta_-j = question-weighted mean without chat j; SE = sqrt((G - 1)/G *
sum_j (theta_-j - mean theta)^2), G = 10; estimate +- t(0.975, 9 df) SE). LongMemEval-S: cluster_boot with each question
its own cluster, and a leave-one-question-out jackknife-t interval (no sign-flip there: the verdict uses only its point
estimate).

DECISION RULE (fixed now; computed from unrounded values):
  PASS          LoCoMo B - A point estimate > 0 AND its chat-clustered 95% percentile interval lies above zero (lower
                end > 0) AND the exact one-sided sign-flip p < 0.05, AND LongMemEval-S B - A >= -0.005 (point estimate).
  FAIL          LoCoMo B - A point estimate <= 0, OR the LoCoMo interval lies above zero but LongMemEval-S B - A < -0.005.
  INCONCLUSIVE  otherwise.
Reported, not decisive: multi-hop (LoCoMo category 1) B - A with the same statistics; the secondary combo arm (combo - A on
LoCoMo, multi-hop and LongMemEval-S); B - base, A - base and combo - B; per-chat differences and chats up; B's test recall
per order; dev picks and dev tables of both arms; the share of candidate rows whose learned key has moved (feature 29 not
0); the LightGBM gain share of features 26 to 29 in the picked test models.

Checks (the run stops if one fails): arm A reproduces s111 (above); the opened sets equal the fused top 10; the inner
bridges reproduce s11's dev recall (s111's check); every stream's dense and fused recall@10 equal s12_cites.run_order's
for the same keys, rule, cites and order; the dev picks equal s111's picks.ours.fused; on the test chats the picked rules'
fused mean equals s111's "ours" 0.6603 and combo's equals s111's 0.6618.

Known limits, stated in advance. (1) The opened sets and cites of a training chat were logged from its outer read, whose
bridge (fold j // 2) was trained on 8 chats that can include fold f's test pair. Haiku cannot be re-run, so this channel
(which nodes were opened and so could be cited) stays, as it did for s111's dev runs; it carries no gold label of any
chat. (2) Dev selection follows s111 exactly, including that the fit chats' features come from inner bridges whose
training set includes the dev pair; this applies to both arms alike. (3) Ten chats: the sign-flip p cannot go below
1/1024, and the learned features exist only for keys a chat's earlier questions moved.

Code-path test before the one real run: --smoke runs the whole pipeline with every learned arm's stream at η = 0 (keys
never move, so learned = base and arms B and combo carry no learning), checks that feature 29 is 0 everywhere, prints no
value of arm B or combo, and writes only to the scratch directory. It measures nothing about learning. The real run is
done once; if a bug forces a rerun, the report says what and why, and the decision rule above stays unchanged.

Outputs: results/s112_ranker_keys.json (and the tee'd results/s112_ranker_keys.log). Compute: about 15 CPU minutes with 3
processes. Usage:
  /tmp/e1/bin/python -I s112_ranker_keys.py [--procs 3] [--cache <pkl>] [--reuse] [--smoke --out <scratch json>]
"""
import os

for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(_v, "1")

import argparse, hashlib, json, pickle, sys, time  # noqa: E402
import multiprocessing as mp  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402
from scipy import stats as sps  # noqa: E402

torch.set_num_threads(1)
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s12_cites as S12  # noqa: E402
import s111_baselines as S111  # noqa: E402
from retrieval import Reader  # noqa: E402

S111_JSON = os.path.join(HERE, "results", "s111_baselines.json")
PICKS_S111 = ["combo", "move η0.1", "centred", "combo", "contrastive"]  # s111 picks.ours.fused (haiku cites), per fold
GRID = [(o, lv, k) for o in S111.RK_OBJ for lv in S111.RK_LEAVES for k in S111.RK_TREES]
FITS = [(o, lv) for o in S111.RK_OBJ for lv in S111.RK_LEAVES]
NORD = S12.ORDERS
ARMS = ("B", "combo")
RULES = list(S12.RULES)
EXTRA_NAMES = ["learned cos", "learned rank in 50", "learned gap to best", "learned minus base"]
FEATURE_NAMES = S111.FEATURE_NAMES + EXTRA_NAMES

# globals filled in the parent before the worker pools fork
R = CH = LR16 = OPENED = CITES = ORDERS = KEYS = FEAT = FEAT_LME = FEAT_LME_X = EXTRA = None


def train_ids(f):
    return S111.train_ids(f)


def dev_pair(f):
    return S111.dev_pair(f)


def rule_of(arm, f):
    return PICKS_S111[f] if arm == "B" else "combo"


def bridge_job(spec):
    """Inner rank-16 bridge of fold f that holds pair out (as s111's 'bridge' job)."""
    torch.set_num_threads(1)
    f, pair = spec
    fit = [j for j in train_ids(f) if j not in pair]
    b = C.train([CH[j] for j in fit], 16, LR16[f], seed=1000 + 10 * f + pair[0])
    return spec, {k: v.numpy() for k, v in b.state_dict().items()}


# ---------------------------------------------------------------- learning streams

def stream(K0, S, ch, cites, opened, order, cfg, mu, cands, base_cos):
    """s12_cites.run_order, plus per question the learned cosine of its 50 candidates with the keys BEFORE its own update.
    A key that has not moved gives exactly the base cosine (base_cos, column 0 of the base feature rows)."""
    keys = K0.copy(); moved = np.zeros(len(K0), dtype=bool); nq = len(ch["qs"])
    dense = np.zeros(nq); fused = np.zeros(nq); lcs = [None] * nq
    eta, c, neg = cfg.get("eta", 0.0), cfg.get("c", 0.0), cfg.get("eta_neg", 0.0)
    for r in order:
        s = S[r]; top = C.order_of(keys @ s)
        dense[r] = C.recall(top, ch["qs"][r][1]); fused[r] = C.recall(C.fuse(ch["lexorder"][r], top), ch["qs"][r][1])
        cand = cands[r]; lc = base_cos[r].copy(); mv = moved[cand]
        if mv.any():
            lc[mv] = keys[cand[mv]] @ s
        lcs[r] = lc
        if not eta:
            continue
        cited = cites[r]
        d = S12.unit1(s - c * mu) if c else s
        for v in cited:
            keys[v] = S12.unit1(keys[v] + eta * (d - keys[v])); moved[v] = True
        if neg:
            for u in opened[r]:
                if u not in cited:
                    keys[u] = S12.unit1(keys[u] - neg * d); moved[u] = True
    return lcs, dense, fused


def stream_job(spec):
    """All 3 orders of one (keys tag, chat, rule) stream, each checked against s12_cites.run_order."""
    tag, j, rule = spec
    K0, S, mu = KEYS[(tag, j)]; ch = CH[j]; rows = FEAT[(tag, j)]
    cands = [x[1] for x in rows]; base_cos = [x[0][:, 0].copy() for x in rows]
    cfg = {} if rule == "null" else S12.RULES[rule]
    res = []; same = True
    for order in ORDERS[j]:
        lcs, d, fu = stream(K0, S, ch, CITES[j], OPENED[j], order, cfg, mu, cands, base_cos)
        d0, f0 = S12.run_order(K0, S, ch["lexorder"], ch["qs"], CITES[j], OPENED[j], order, cfg, mu)
        same = same and bool(np.array_equal(d, d0) and np.array_equal(fu, f0))
        res.append((lcs, d, fu))
    return spec, (res, same)


def extra(lc, X):
    """Features 26-29: learned cosine, its rank among the 50 (0 best, ties by fused position), gap to the best, and
    learned minus base bridge cosine (X column 0)."""
    m = len(lc); rk = np.empty(m, dtype=np.float32)
    rk[np.lexsort((np.arange(m), -lc))] = np.arange(m)
    return np.column_stack([lc, rk, lc - lc.max(), lc - X[:, 0]]).astype(np.float32)


# ---------------------------------------------------------------- ranker

def rows_for(arm, tag, j, o):
    base = FEAT[(tag, j)]
    if arm == "A":
        return base
    return [(np.hstack([x[0], e]), x[1], x[2], x[3], x[4]) for x, e in zip(base, EXTRA[(arm, tag, j, o)])]


def rk_job(spec):
    """One LightGBM fit (400 trees, scored at 50/100/200/400) as s111's rk_dev / rk_test / rk_lme, for arm A or a learned
    arm at order o."""
    arm, kind, f, o, obj, leaves = spec
    inner = ("inner", f)
    if kind == "dev":
        fit = [x for j in train_ids(f) if j not in dev_pair(f) for x in rows_for(arm, inner, j, o)]
        ev = [x for j in dev_pair(f) for x in rows_for(arm, inner, j, o)]
    elif kind == "test":
        fit = [x for j in train_ids(f) for x in rows_for(arm, inner, j, o)]
        ev = [x for j in C.FOLDS[f] for x in rows_for(arm, "outer", j, o)]
    else:
        fit = [x for j in range(10) for x in rows_for(arm, "outer", j, o)]
        ev = FEAT_LME if arm == "A" else FEAT_LME_X
    model = S111.rk_fit(fit, obj, leaves)
    scores = {k: S111.rk_score(model, ev, obj, k) for k in S111.RK_TREES}
    imp = ({k: model.booster_.feature_importance("gain", iteration=k) for k in S111.RK_TREES}
           if kind == "test" else None)
    return spec, (scores, imp)


# ---------------------------------------------------------------- statistics

def jackknife_t(diff, cl, level=0.95):
    """Leave-one-cluster-out jackknife of the question-weighted mean; estimate +- t(G - 1) SE."""
    diff = np.asarray(diff, dtype=np.float64)
    ids, inv_ = np.unique(np.asarray(cl), return_inverse=True)
    S = np.bincount(inv_, weights=diff); n = np.bincount(inv_).astype(np.float64); G = len(ids)
    est = S.sum() / n.sum(); th = (S.sum() - S) / (n.sum() - n)
    se = float(np.sqrt((G - 1) / G * ((th - th.mean()) ** 2).sum()))
    t = float(sps.t.ppf(0.5 + level / 2, G - 1))
    return [float(est - t * se), float(est + t * se)], se


def signflip_p(diff, cl):
    """Exact one-sided sign-flip p over clusters: share of the 2^G sign vectors with sum_j e_j D_j / N >= observed."""
    diff = np.asarray(diff, dtype=np.float64)
    ids, inv_ = np.unique(np.asarray(cl), return_inverse=True)
    D = np.bincount(inv_, weights=diff); G = len(ids)
    E = 1.0 - 2.0 * ((np.arange(2 ** G)[:, None] >> np.arange(G)[None, :]) & 1)
    T = E @ D / len(diff); obs = D.sum() / len(diff)
    return float((T >= obs - 1e-12).mean())


def compare(diff, cl, exact=True):
    m, ci = C.cluster_boot(diff, cl)
    jk, se = jackknife_t(diff, cl)
    d = dict(n=int(len(diff)), mean=m, ci=ci, jackknife_t_ci=jk, jackknife_se=se)
    if exact:
        d["signflip_p_one_sided"] = signflip_p(diff, cl)
    return d


def fmt(d):
    s = (f"{d['mean']:+.4f}  pct [{d['ci'][0]:+.4f}, {d['ci'][1]:+.4f}]  jk-t [{d['jackknife_t_ci'][0]:+.4f}, "
         f"{d['jackknife_t_ci'][1]:+.4f}]")
    if "signflip_p_one_sided" in d:
        s += f"  sign-flip p {d['signflip_p_one_sided']:.4f}"
    return s + f"  (n {d['n']})"


def rnd(x, k=6):
    if isinstance(x, dict):
        return {a: rnd(b, k) for a, b in x.items()}
    if isinstance(x, (list, tuple)):
        return [rnd(b, k) for b in x]
    if isinstance(x, (float, np.floating)):
        return round(float(x), k)
    return x


# ---------------------------------------------------------------- main

def main():
    global R, CH, LR16, OPENED, CITES, ORDERS, KEYS, FEAT, FEAT_LME, FEAT_LME_X, EXTRA
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--tasks", default=os.path.join(HERE, "runs", "tasks_hop0.jsonl.gz"))
    p.add_argument("--answers", default=os.path.join(HERE, "runs", "answers_hop0.jsonl"))
    p.add_argument("--procs", type=int, default=3)
    p.add_argument("--out", default=os.path.join(HERE, "results", "s112_ranker_keys.json"))
    p.add_argument("--cache", default="", help="pickle of the finished ranker runs")
    p.add_argument("--reuse", action="store_true", help="with --cache: skip straight to the summary")
    p.add_argument("--smoke", action="store_true", help="code-path test: η = 0 in every learned arm, no arm value shown")
    a = p.parse_args()
    if a.smoke and os.path.abspath(a.out).startswith(os.path.join(HERE, "results")):
        raise SystemExit("--smoke writes only to the scratch directory: pass --out")
    t0 = time.time()
    doc_sha = hashlib.sha256(__doc__.encode()).hexdigest()[:16]
    print(f"s112_ranker_keys: pre-registered docstring sha256[:16] {doc_sha}"
          + ("  [SMOKE: η = 0 in every learned arm; no arm value is shown]" if a.smoke else ""), flush=True)
    s111 = json.load(open(S111_JSON))
    assert s111["locomo"]["by_source"]["haiku"]["picks"]["ours"]["fused"] == PICKS_S111
    if a.reuse and a.cache and os.path.exists(a.cache):
        z = pickle.load(open(a.cache, "rb"))
        print("reusing finished runs from", a.cache, flush=True)
        return summarise(a, t0, z["RES"], z["out"], z["info"], s111)
    out = dict(test="1.12 learned keys on top of the ranker", docstring_sha256_16=doc_sha, smoke=a.smoke,
               protocol=__doc__.strip(), checks={})

    R = Reader(); CH = R.chats; S111.CH = CH
    LR16 = json.load(open(os.path.join(HERE, "results", "s11_rank.json")))["picks"]["r16"]
    tasks = {t["id"]: t for t in S12.read(a.tasks)}
    rows = S12.read(a.answers)
    if len(rows) < S111.MIN_ANSWER_ROWS:
        raise SystemExit(f"{a.answers}: {len(rows)} rows, fewer than {S111.MIN_ANSWER_ROWS}")
    reads = {r["id"]: r for r in rows if "error" not in r and r.get("kind") == "read"}
    OPENED, CITES, ORDERS = {}, {}, {}
    mism = 0; ncites = 0
    for i, ch in enumerate(CH):
        nq = len(ch["qs"]); OPENED[i] = []; CITES[i] = []
        for r in range(nq):
            tid = f"locomo:{i}:{r}"; node = {sn["n"]: sn["node"] for sn in tasks[tid]["snippets"]}
            op = list(node.values()); OPENED[i].append(op)
            mism += op != R.first(("locomo", i, r))[:10].tolist()
            rd = reads.get(tid); hc = [node[n] for n in rd["cites"] if n in node] if rd else []
            CITES[i].append(hc); ncites += len(hc)
        ORDERS[i] = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(NORD)]
        sess = [int(C.EVID.match(x).group(1)) if C.EVID.match(x) else -1 for x in ch["ids"]]
        ch["_static"] = S111.chat_static(ch["ids"], ch["docs"], sess)
    out["checks"]["answer_rows"] = len(rows)
    out["checks"]["opened_not_equal_fused_top10"] = mism
    out["checks"]["haiku_cites_per_question"] = round(ncites / 1536, 3)
    print(f"answer rows {len(rows)} | opened sets that differ from the fused top 10: {mism} | Haiku cites per question "
          f"{ncites / 1536:.3f}", flush=True)
    assert mism == 0

    # inner bridges (fold f, held-out pair), as in s111
    ctx = mp.get_context("fork")
    specs = [(f, pr) for f in range(5) for pr in C.inner_pairs(train_ids(f))]
    INNER = {}
    with ctx.Pool(a.procs) as pool:
        for spec, sd in pool.imap_unordered(bridge_job, specs):
            b = C.Bridge(384, 16); b.load_state_dict({k: torch.as_tensor(v) for k, v in sd.items()}); INNER[spec] = b
    s11 = json.load(open(os.path.join(HERE, "results", "s11_rank.json")))["by_lr"]["r16"]
    rep = {}
    for f in range(5):
        xs = [x for pr in C.inner_pairs(train_ids(f)) for j in pr for x in C.chat_recalls(INNER[(f, pr)], CH[j])]
        rep[f] = dict(here=round(float(np.mean(xs)), 4), s11=s11[f"fold{f}_dev"][str(LR16[f])])
    out["checks"]["inner_bridge_dev_dense_vs_s11"] = rep
    print(f"inner bridges trained ({time.time() - t0:.0f}s); dev recall vs s11: {rep}", flush=True)
    assert all(v["here"] == v["s11"] for v in rep.values())

    # keys, states and frozen centring means: outer (test chats) and inner (every training chat of every fold)
    KEYS = {}
    for i in range(10):
        f = i // 2
        mu = np.concatenate([R.bridges[f].views(CH[j]["nodes"], CH[j]["asks"])[1] for j in train_ids(f)]).mean(0)
        KEYS[("outer", i)] = (R.keys[i][0], R.keys[i][1], mu)
    for f in range(5):
        for pr in C.inner_pairs(train_ids(f)):
            b = INNER[(f, pr)]; fit = [j for j in train_ids(f) if j not in pr]
            mu = np.concatenate([b.views(CH[j]["nodes"], CH[j]["asks"])[1] for j in fit]).mean(0)
            for j in pr:
                K, S = b.views(CH[j]["nodes"], CH[j]["asks"]); KEYS[(("inner", f), j)] = (K, S, mu)

    # base ranker features (s111's 25)
    FEAT = {}
    for i in range(10):
        FEAT[("outer", i)] = S111.chat_feats(i, *R.keys[i])
        assert all(np.array_equal(x[4], R.first(("locomo", i, r))) for r, x in enumerate(FEAT[("outer", i)]))
    for f in range(5):
        for j in train_ids(f):
            K, S, _ = KEYS[(("inner", f), j)]; FEAT[(("inner", f), j)] = S111.chat_feats(j, K, S)
    FEAT_LME = []
    for t, it in enumerate(R.items):
        st = S111.chat_static(it["rows"], it["docs"], it["sess"]); qt = C.tokens(it["question"])
        cb = R.lme_keys[t] @ R.lme_state[t]; cf = R.vec[it["rows"]] @ it["q"]; bm = it["bm25"].scores(qt)
        X, cand, fused = S111.qfeats(cb, cf, bm, it["lexorder"], st, qt)
        assert np.array_equal(fused, R.first(("lme", t)))
        FEAT_LME.append((X, cand, np.isin(cand, it["ev"]).astype(np.float32), it["ev"], fused))
    # LongMemEval-S: keys cannot learn, learned = base
    FEAT_LME_X = [(np.hstack([x[0], extra(x[0][:, 0].copy(), x[0])]), x[1], x[2], x[3], x[4]) for x in FEAT_LME]
    assert all(not x[0][:, 28].any() for x in FEAT_LME_X)
    print(f"features built ({time.time() - t0:.0f}s)", flush=True)

    # learning streams
    tags_arm = [("outer", i) for i in range(10)] + [(("inner", f), j) for f in range(5) for j in train_ids(f)]
    need = set()
    for f in range(5):
        for j in dev_pair(f):
            need |= {(("inner", f), j, rn) for rn in RULES}
    for tag, j in tags_arm:
        f = j // 2 if tag == "outer" else tag[1]
        need |= {(tag, j, rule_of(arm, f)) for arm in ARMS}
        if a.smoke:
            need.add((tag, j, "null"))
    STREAMS = {}
    with ctx.Pool(a.procs) as pool:
        for spec, res in pool.imap_unordered(stream_job, sorted(need, key=str), chunksize=4):
            STREAMS[spec] = res
    same = all(v[1] for v in STREAMS.values())
    out["checks"]["streams_equal_s12_run_order"] = dict(streams=len(STREAMS), all_equal=same)
    print(f"{len(STREAMS)} streams x {NORD} orders run ({time.time() - t0:.0f}s); dense and fused recall equal "
          f"s12_cites.run_order: {same}", flush=True)
    assert same

    def order_mean(key, col):  # per-question mean over the orders (col 1 dense, 2 fused), accumulated as s12/s111 do
        acc = np.zeros(len(STREAMS[key][0][0][col]))
        for o in range(NORD):
            acc += STREAMS[key][0][o][col] / NORD
        return acc

    rule_dev = {(f, rn): float(np.concatenate([order_mean((("inner", f), j, rn), 2) for j in dev_pair(f)]).mean())
                for f in range(5) for rn in RULES}
    picks = [max(RULES, key=lambda rn: (rule_dev[(f, rn)], -RULES.index(rn))) for f in range(5)]
    s111_dev = s111["locomo"]["by_source"]["haiku"]["dev"]["rules"]
    dev_match = all(round(rule_dev[(f, rn)], 4) == s111_dev[f"fold{f}"][rn][1] for f in range(5) for rn in RULES)
    picked_fused = float(np.concatenate([order_mean(("outer", i, PICKS_S111[i // 2]), 2) for i in range(10)]).mean())
    combo_fused = float(np.concatenate([order_mean(("outer", i, "combo"), 2) for i in range(10)]).mean())
    out["checks"]["dev_rule_picks"] = dict(here=picks, s111=PICKS_S111, dev_fused_means_equal_s111=dev_match)
    out["checks"]["test_fused_learned_read"] = dict(picked=round(picked_fused, 4), picked_s111=0.6603,
                                                    combo=round(combo_fused, 4), combo_s111=0.6618)
    print(f"dev picks {picks} (s111 {PICKS_S111}; dev means equal s111: {dev_match}); learned read fused on test: "
          f"picked {picked_fused:.4f} (0.6603), combo {combo_fused:.4f} (0.6618)", flush=True)
    assert picks == PICKS_S111 and dev_match
    assert round(picked_fused, 4) == 0.6603 and round(combo_fused, 4) == 0.6618

    # learned-key features 26-29 per arm, tag, chat and order
    EXTRA = {}; moved = {}
    for arm in ARMS:
        rows_moved = []; q_moved = []
        for tag, j in tags_arm:
            f = j // 2 if tag == "outer" else tag[1]
            res = STREAMS[(tag, j, "null" if a.smoke else rule_of(arm, f))][0]
            for o in range(NORD):
                ex = [extra(lc, x[0]) for lc, x in zip(res[o][0], FEAT[(tag, j)])]
                EXTRA[(arm, tag, j, o)] = ex
                if tag == "outer":
                    rows_moved += [float((e[:, 3] != 0).mean()) for e in ex]
                    q_moved += [float((e[:, 3] != 0).any()) for e in ex]
        moved[arm] = dict(test_candidate_rows_moved=float(np.mean(rows_moved)),
                          test_questions_with_a_moved_candidate=float(np.mean(q_moved)))
    if a.smoke:
        assert all(not e[:, 3].any() for v in EXTRA.values() for e in v), "η = 0 must leave feature 29 at 0"
        print("smoke: feature 29 is 0 everywhere", flush=True)
    out["learned_feature_coverage"] = moved
    print(f"learned features built ({time.time() - t0:.0f}s)", flush=True)

    # ranker fits
    specs = [("A", kind, f, 0, o, lv) for kind in ("dev", "test") for f in range(5) for o, lv in FITS]
    specs += [("A", "lme", -1, 0, o, lv) for o, lv in FITS]
    for arm in ARMS:
        specs += [(arm, kind, f, od, o, lv) for kind in ("dev", "test") for f in range(5) for od in range(NORD)
                  for o, lv in FITS]
        specs += [(arm, "lme", -1, od, o, lv) for od in range(NORD) for o, lv in FITS]
    RES = {}
    with ctx.Pool(a.procs) as pool:
        for n, (spec, res) in enumerate(pool.imap_unordered(rk_job, specs, chunksize=1)):
            RES[spec] = res
            if (n + 1) % 25 == 0:
                print(f"  {n + 1}/{len(specs)} ranker fits ({time.time() - t0:.0f}s)", flush=True)
    print(f"ranker fits done ({time.time() - t0:.0f}s)", flush=True)
    info = dict(chat_of=np.concatenate([[i] * len(CH[i]["qs"]) for i in range(10)]),
                cat_of=np.concatenate([[q[2] for q in CH[i]["qs"]] for i in range(10)]),
                base_fused=np.concatenate([[C.recall(x[4], x[3]) for x in FEAT[("outer", i)]] for i in range(10)]),
                lme_base=np.array([C.recall(x[4], x[3]) for x in FEAT_LME]),
                lme_type=np.array([it["type"] for it in R.items]))
    if a.cache:
        pickle.dump(dict(RES=RES, out=out, info=info), open(a.cache, "wb"))
    return summarise(a, t0, RES, out, info, s111)


def summarise(a, t0, RES, out, info, s111):
    chat_of, cat_of = info["chat_of"], info["cat_of"]; mh = cat_of == 1
    base, lme_base = info["base_fused"], info["lme_base"]; qcl = np.arange(len(lme_base))

    def dev_vec(arm, f, g):
        o_, lv, k = g
        if arm == "A":
            return RES[("A", "dev", f, 0, o_, lv)][0][k]
        return np.mean([RES[(arm, "dev", f, od, o_, lv)][0][k] for od in range(NORD)], 0)

    def pick(arm):
        dev = {(f, g): float(dev_vec(arm, f, g).mean()) for f in range(5) for g in GRID}
        per = {f: max(GRID, key=lambda g: (dev[(f, g)], -GRID.index(g))) for f in range(5)}
        pooled = {g: float(np.concatenate([dev_vec(arm, f, g) for f in range(5)]).mean()) for g in GRID}
        return per, max(GRID, key=lambda g: (pooled[g], -GRID.index(g))), dev, pooled

    def test_vec(arm, per, od=None):
        parts = []
        for f in range(5):  # fold f scores chats 2f, 2f + 1 in that order, so folds in order give chats 0..9
            o_, lv, k = per[f]
            if arm == "A":
                parts.append(RES[("A", "test", f, 0, o_, lv)][0][k])
            elif od is None:
                parts.append(np.mean([RES[(arm, "test", f, x, o_, lv)][0][k] for x in range(NORD)], 0))
            else:
                parts.append(RES[(arm, "test", f, od, o_, lv)][0][k])
        return np.concatenate(parts)

    def lme_vec(arm, g):
        o_, lv, k = g
        if arm == "A":
            return RES[("A", "lme", -1, 0, o_, lv)][0][k]
        return np.mean([RES[(arm, "lme", -1, od, o_, lv)][0][k] for od in range(NORD)], 0)

    P, V, LV = {}, {}, {}
    out["picks"] = {}; out["dev"] = {}
    for arm in ("A",) + ARMS:
        per, lp, dev, pooled = pick(arm)
        P[arm] = per; V[arm] = test_vec(arm, per); LV[arm] = lme_vec(arm, lp)
        out["picks"][arm] = dict(per_fold={f: list(map(str, per[f])) for f in range(5)}, lme=list(map(str, lp)))
        out["dev"][arm] = {f"fold{f}": {"/".join(map(str, g)): round(dev[(f, g)], 4) for g in GRID} for f in range(5)}
        out["dev"][arm]["pooled"] = {"/".join(map(str, g)): round(pooled[g], 4) for g in GRID}
    # arm A must be s111's ranker
    s111_pk = {f: (v[0], int(v[1]), int(v[2])) for f, v in ((int(f), v) for f, v in s111["picks"]["ranker"].items())}
    s111_lme = tuple(s111["picks"]["ranker_lme"]); s111_lme = (s111_lme[0], int(s111_lme[1]), int(s111_lme[2]))
    repro = dict(picks_equal=all(P["A"][f] == s111_pk[f] for f in range(5)), locomo=round(float(V["A"].mean()), 4),
                 locomo_s111=s111["locomo"]["ranker"]["fused"], lme_pick_equal=bool(pick("A")[1] == s111_lme),
                 lme=round(float(LV["A"].mean()), 4), lme_s111=s111["lme"]["ranker"])
    out["checks"]["arm_A_reproduces_s111"] = repro
    print(f"arm A vs s111: {repro}", flush=True)
    assert repro["picks_equal"] and repro["lme_pick_equal"]
    assert repro["locomo"] == 0.7492 == repro["locomo_s111"] and repro["lme"] == 0.9187 == repro["lme_s111"]

    loc = dict(n_questions=int(len(chat_of)), n_multi_hop=int(mh.sum()),
               means={k: float(v.mean()) for k, v in (("base", base), ("A", V["A"]), ("B", V["B"]),
                                                     ("combo", V["combo"]))},
               multi_hop_means={k: float(v[mh].mean()) for k, v in (("base", base), ("A", V["A"]), ("B", V["B"]),
                                                                   ("combo", V["combo"]))},
               by_order={arm: [float(test_vec(arm, P[arm], od).mean()) for od in range(NORD)] for arm in ARMS})
    cmp_ = {}
    for name, x, y in (("B - A", V["B"], V["A"]), ("combo - A", V["combo"], V["A"])):
        cmp_[name] = dict(all=compare(x - y, chat_of), multi_hop=compare((x - y)[mh], chat_of[mh]),
                          per_chat=[float((x - y)[chat_of == j].mean()) for j in range(10)])
        cmp_[name]["chats_up"] = int(sum(v > 0 for v in cmp_[name]["per_chat"]))
        cmp_[name]["chats_down"] = int(sum(v < 0 for v in cmp_[name]["per_chat"]))
    for name, x, y in (("A - base", V["A"], base), ("B - base", V["B"], base), ("combo - base", V["combo"], base),
                       ("combo - B", V["combo"], V["B"])):
        cmp_[name] = dict(all=compare(x - y, chat_of), multi_hop=compare((x - y)[mh], chat_of[mh]))
    loc["comparisons"] = cmp_
    lme = dict(n_questions=int(len(lme_base)), means={k: float(v.mean()) for k, v in
                                                       (("fused read", lme_base), ("A", LV["A"]), ("B", LV["B"]),
                                                        ("combo", LV["combo"]))},
               comparisons={name: compare(x - y, qcl, exact=False) for name, x, y in
                            (("B - A", LV["B"], LV["A"]), ("combo - A", LV["combo"], LV["A"]),
                             ("A - fused read", LV["A"], lme_base))},
               note="one question per history: learned = base; models trained on LoCoMo")
    # gain share of the learned features in the picked test models (mean over folds and orders of per-model shares)
    gain = {}
    for arm in ARMS:
        sh = []
        for f in range(5):
            o_, lv, k = P[arm][f]
            for od in range(NORD):
                imp = np.asarray(RES[(arm, "test", f, od, o_, lv)][1][k], dtype=np.float64); sh.append(imp / imp.sum())
        sh = np.mean(sh, 0)
        gain[arm] = dict(learned={EXTRA_NAMES[c]: float(sh[25 + c]) for c in range(4)},
                         learned_total=float(sh[25:].sum()),
                         top5={FEATURE_NAMES[c]: float(sh[c]) for c in np.argsort(-sh)[:5]})
    out["gain_share"] = gain

    # pre-registered decision
    pr = cmp_["B - A"]["all"]; lm = lme["comparisons"]["B - A"]["mean"]
    passed = pr["mean"] > 0 and pr["ci"][0] > 0 and pr["signflip_p_one_sided"] < 0.05 and lm >= -0.005
    failed = pr["mean"] <= 0 or (pr["ci"][0] > 0 and lm < -0.005)
    verdict = "pass" if passed else ("fail" if failed else "inconclusive")
    out["verdict"] = dict(result=verdict, locomo_B_minus_A=pr, lme_B_minus_A=lm,
                          conditions=dict(point_above_zero=pr["mean"] > 0, interval_above_zero=pr["ci"][0] > 0,
                                          signflip_p_below_0_05=pr["signflip_p_one_sided"] < 0.05,
                                          lme_at_least_minus_0_005=lm >= -0.005))
    out["locomo"] = loc; out["lme"] = lme
    out["seconds"] = round(time.time() - t0)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.smoke:  # keep no arm value: only the checks and the shape of the summary
        json.dump(dict(smoke=True, docstring_sha256_16=out["docstring_sha256_16"], checks=out["checks"],
                       summary_keys=sorted(out), locomo_keys=sorted(loc), comparison_keys=sorted(cmp_),
                       seconds=out["seconds"]), open(a.out, "w"), indent=1, ensure_ascii=False)
        print(f"smoke: summary built ({', '.join(sorted(out))}); verdict computed, not shown; "
              f"wrote {a.out}; seconds {out['seconds']}")
        return
    json.dump(rnd(out), open(a.out, "w"), indent=1, ensure_ascii=False)

    # ---------------------------------------------------------------- print
    print("\npicks (obj/leaves/trees) per fold, and for LongMemEval-S:")
    for arm in ("A",) + ARMS:
        print(f"  {arm:<6} {[ '/'.join(out['picks'][arm]['per_fold'][f]) for f in range(5)]}  lme "
              f"{'/'.join(out['picks'][arm]['lme'])}")
    print(f"\nLoCoMo recall@10 ({loc['n_questions']} questions, {loc['n_multi_hop']} multi-hop):")
    for k in loc["means"]:
        print(f"  {k:<6} {loc['means'][k]:.4f}   multi-hop {loc['multi_hop_means'][k]:.4f}")
    for arm in ARMS:
        print(f"  {arm} by order: {[round(x, 4) for x in loc['by_order'][arm]]}")
    for name, c in cmp_.items():
        print(f"  {name:<13} all       {fmt(c['all'])}")
        print(f"  {'':<13} multi-hop {fmt(c['multi_hop'])}")
        if "per_chat" in c:
            print(f"  {'':<13} per chat {[round(x, 4) for x in c['per_chat']]}  up {c['chats_up']} down {c['chats_down']}")
    print(f"\nLongMemEval-S recall@10 ({lme['n_questions']} questions): "
          + "  ".join(f"{k} {v:.4f}" for k, v in lme["means"].items()))
    for name, c in lme["comparisons"].items():
        print(f"  {name:<15} {fmt(c)}")
    print("\nlearned-feature coverage on the test chats:", json.dumps(rnd(out["learned_feature_coverage"], 4)))
    print("gain share in the picked test models:", json.dumps(rnd(gain, 4), ensure_ascii=False))
    print(f"\nVERDICT (pre-registered): {verdict.upper()}  LoCoMo B - A {fmt(pr)};  LongMemEval-S B - A {lm:+.4f}")
    print(json.dumps(rnd(out["verdict"]["conditions"]), ensure_ascii=False))
    print(f"seconds {out['seconds']}")


if __name__ == "__main__":
    main()
