#!/usr/bin/env python3
"""Stage 1.10: pre-registered re-test of the post hoc lead "fuse the session list with the flat list" (public data only).

Written before any number of this test was produced. The protocol, pass bar and decision rule below are fixed.

The lead. In the second-hop fix (scripts/ai/small_models/fixes/second-hop/second_hop.py, arm "pyramid|lowrank"), fusing
a session-level list with the flat rank-16 list scored +0.058 (chat CI +0.040 to +0.074) over the flat list on LoCoMo,
with multi-hop recall@10 down 0.057. It was designed after seeing those test results (old untuned bridges, old
1,531-question parser), so it is a lead, not a result. This script re-tests it, unchanged, on LongMemEval-S.

The arm, copied from second_hop.py (add_sessions; rank_chat(pyramid=True, hop=None); fuse(pyramid, lowrank)):
  1. Flat list F: every memory node ranked by (rank-16 bridge key . bridge state of the question), descending, ties by
     node index (common.order_of; the old code's np.argsort(-score, kind="stable")).
  2. Session documents: a session's BM25 document is the concatenation of the BM25 tokens (common.tokens) of all of its
     memory nodes. BM25 (common.BM25: k1 1.2, b 0.75, idf log(1 + (n - df + .5) / (df + .5))) runs over the sessions of
     one memory, query = common.tokens(question). The b = 3 best sessions are opened; ties by session order.
  3. Session list P: the nodes of the 3 opened sessions in F order, then every other node in F order.
  4. Arm under test S = session|flat = reciprocal rank fusion of P and F, k 60, ties by node index (common.fuse).
  No parameter is tuned; b = 3 and k = 60 are the old values.

Data and bridges.
  LongMemEval-S (the test): the 428 questions with user-turn evidence (common.load_lme). The memory of a question is its
    own haystack's user turns (the rows of common.load_lme). A session is one haystack session, identified by its
    position in haystack_sessions, never by its id: 13 haystacks repeat a session id, and ids that start "answer_" mark
    the evidence sessions, so ids are not used even to break ties. Session order = haystack position. Sessions with no
    user turn hold no memory node and are left out. Bridge: rank-16 trained on all 10 LoCoMo chats (R.lme_keys,
    R.lme_state from retrieval.Reader).
  LoCoMo (reference only; this is the lead's own dataset, so it cannot confirm the lead): 1,536 questions on the 10
    held-out chats, each read with the tuned rank-16 bridge of the fold that held it out (R.keys). A session is session_N
    of the raw file, nodes are all turns, session order = N (exactly as add_sessions).

Arms reported on both datasets (recall@10 of the marked evidence nodes, common.recall; no key learning, so every question
is scored once and visit order plays no role):
  flat               F (the pass bar's baseline: "flat rank-16 bridges")
  flat+bm25          RRF(BM25 node list, F) = retrieval.Reader.first (the current read path)
  session            P (diagnostic only: open 3 sessions, bridge order inside)
  session|flat       S (the arm under test)
  session|flat+bm25  RRF(BM25 node list, S) (the old "+bm25" column of second_hop.py)

Statistics: paired differences per question; common.cluster_boot (4,000 resamples, seed 0, the same seed for every
comparison, so all arms share the same resamples): question clusters on LongMemEval-S, chat clusters on LoCoMo.

Pass bar (front matter 1-front.md, stage 1 table, test 1.10): "a gain over flat rank-16 bridges with an interval above
zero and no multi-hop loss"; fails if "no gain". Fixed for this run as:
  (a) LongMemEval-S, all 428 questions: mean(S - F) > 0 and the lower end of its 95% question-clustered interval > 0.
  (b) LongMemEval-S, question_type "multi-session" (the multi-hop analogue): mean(S - F) >= 0 as a point estimate (its
      interval is reported but is not part of the bar).
Decision rule:
  PASS          (a) and (b) both hold.
  FAIL          mean(S - F) <= 0 on all 428, or (b) fails (a multi-session point loss).
  INCONCLUSIVE  mean(S - F) > 0 and (b) holds, but the interval's lower end is at or below zero.
Secondary, reported but not part of the bar, with the reading fixed now: session opening itself uses BM25, so part of any
gain over F can be lexical signal that BM25 fusion already supplies. On LongMemEval-S we also report S - flat+bm25 and
session|flat+bm25 - flat+bm25. If S passes against F but neither S nor session|flat+bm25 beats flat+bm25 with an
interval above zero, we say the lead does not add to the current read path. LoCoMo: S - F overall and on multi-hop
(category 1), chat-clustered, for reference.

Checks built into the run (the script stops if one fails):
  - flat and flat+bm25 reproduce s11_rank.json to 4 decimals (LoCoMo 0.6622 / 0.6553; LongMemEval-S 0.8839 / 0.8982).
  - On LoCoMo the session lists P and the fused lists S equal, list for list, what the old second_hop.py functions
    (add_sessions, rank_chat(pyramid=True, hop=None), e5_bridges.fuse) produce from the same keys.
  - On LongMemEval-S the per-turn session positions rebuilt from the raw file match common.load_lme's rows and ids.
Diagnostics: sessions per memory, evidence sessions per question, share of evidence inside the 3 opened sessions, nodes
opened, and the coverage ceiling of any top-3 router E[min(n_ev_sessions, 3) / n_ev_sessions] (method P8), by type.

Compute: seconds (no training). Usage: /tmp/e1/bin/python -I s110_sessionfusion.py
"""
import collections, hashlib, importlib.util, json, os, sys, time
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

B = 3
OLD = os.path.join(HERE, "..", "fixes", "second-hop", "second_hop.py")
LOCOMO = "/tmp/locomo10.json"
LME = "/tmp/claude-0/data/lme_s.json"
ARMS = ("flat", "flat+bm25", "session", "session|flat", "session|flat+bm25")


def session_index(node_sess):
    """Map per-node session labels (sortable in session order) to 0..m-1 in that order."""
    names = np.unique(node_sess)
    return np.searchsorted(names, node_sess), len(names)


def session_bm25(docs, sidx, m):
    sdocs = [[] for _ in range(m)]
    for j, d in enumerate(docs):
        sdocs[sidx[j]].extend(d)
    return C.BM25(sdocs)


def arms_for(flat, lex, sidx, opened):
    inside = np.isin(sidx, opened)
    pyr = np.concatenate([flat[inside[flat]], flat[~inside[flat]]])
    sf = C.fuse(pyr, flat)
    return {"flat": flat, "flat+bm25": C.fuse(lex, flat), "session": pyr, "session|flat": sf,
            "session|flat+bm25": C.fuse(lex, sf)}


def diag(ev, sidx, opened):
    ev_s = sidx[np.asarray(ev)]; n_ev = len(set(ev_s.tolist()))
    return dict(ev_sessions=n_ev, ev_inside=float(np.isin(ev_s, opened).mean()), ceiling=min(n_ev, B) / n_ev,
                opened_nodes=int(np.isin(sidx, opened).sum()))


def stats(per, cluster, base, arm, mask=None):
    x = np.asarray(per[arm]); y = np.asarray(per[base]); cl = np.asarray(cluster)
    if mask is not None:
        x, y, cl = x[mask], y[mask], cl[mask]
    m, ci = C.cluster_boot(x - y, cl)
    return dict(n=int(len(x)), arm=float(x.mean()), base=float(y.mean()), delta=m, ci=ci)


def fmt(s):
    return f"{s['arm']:.4f} vs {s['base']:.4f}: {s['delta']:+.4f} [{s['ci'][0]:+.4f}, {s['ci'][1]:+.4f}] (n {s['n']})"


def old_equivalence(R):
    """Run the old second_hop.py functions on the new keys and compare every list with this script's."""
    sys.path.insert(0, "/tmp/claude-0/sm")
    spec = importlib.util.spec_from_file_location("second_hop_old", OLD)
    old = importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
    shims = [dict(ids=c["ids"], docs={d: c["docs"][i] for i, d in enumerate(c["ids"])},
                  qs=[(q[0], q[1], q[2]) for q in c["qs"]]) for c in R.chats]
    old.add_sessions(shims, LOCOMO)
    out = {}
    for i, sh in enumerate(shims):
        K, S = R.keys[i]
        pyr = old.rank_chat(sh, K, S, None, None, 1.0, pyramid=True, hop=None)
        flat = old.rank_chat(sh, K, S, None, None, 1.0, hop=None)
        out[i] = (sh["sess"], sh["opened"], pyr, [old.fuse(x, y) for x, y in zip(pyr, flat)])
    return out


def run_locomo(R, raw):
    per = collections.defaultdict(list); chat_of, cat, dg = [], [], collections.defaultdict(list)
    old = old_equivalence(R); same = 0; total = 0
    for i, c in enumerate(R.chats):
        sess_of = {}
        for name, value in raw[i]["conversation"].items():
            if name.startswith("session_") and isinstance(value, list):
                for t in value:
                    sess_of[t["dia_id"]] = int(name.split("_")[1])
        node_sess = np.array([sess_of[d] for d in c["ids"]])
        sidx, m = session_index(node_sess); names = np.unique(node_sess)
        bm = session_bm25(c["docs"], sidx, m); K, S = R.keys[i]
        o_sess, o_open, o_pyr, o_fused = old[i]
        assert np.array_equal(o_sess, node_sess)
        for r, q in enumerate(c["qs"]):
            opened = bm.rank(C.tokens(q[0]))[:B]
            ranked = arms_for(C.order_of(K @ S[r]), c["lexorder"][r], sidx, opened)
            total += 1
            same += (names[opened].tolist() == list(o_open[r]) and ranked["session"].tolist() == list(o_pyr[r])
                     and ranked["session|flat"].tolist() == list(o_fused[r]))
            for a in ARMS:
                per[a].append(C.recall(ranked[a], q[1]))
            chat_of.append(i); cat.append(q[2])
            for k, v in diag(q[1], sidx, opened).items():
                dg[k].append(v)
        dg["sessions"] += [m] * len(c["qs"])
    print(f"LoCoMo: session lists identical to the old second_hop.py code on {same} of {total} questions", flush=True)
    if same != total:
        raise SystemExit("the session arm does not reproduce the old code")
    return per, np.array(chat_of), np.array(cat), dg, dict(identical=same, total=total)


def lme_positions(R):
    """Per item, the haystack position of every user turn, rebuilt from the raw file and checked against load_lme."""
    raw = {x["question_id"]: x for x in json.load(open(LME))}
    out = []
    for it in R.items:
        x = raw[it["qid"]]; pos, sids, rows = [], [], []
        for p, (sid, s) in enumerate(zip(x["haystack_session_ids"], x["haystack_sessions"])):
            for t in s:
                if t["role"] == "user":
                    pos.append(p); sids.append(sid); rows.append(t["content"])
        assert sids == list(it["sess"]) and len(rows) == len(it["rows"])
        assert all(R.texts[k] == t for k, t in zip(it["rows"], rows))
        out.append(np.array(pos))
    return out


def run_lme(R):
    per = collections.defaultdict(list); types, dg = [], collections.defaultdict(list)
    positions = lme_positions(R)
    for j, it in enumerate(R.items):
        sidx, m = session_index(positions[j])
        bm = session_bm25(it["docs"], sidx, m)
        opened = bm.rank(C.tokens(it["question"]))[:B]
        flat = C.order_of(R.lme_keys[j] @ R.lme_state[j])
        ranked = arms_for(flat, it["lexorder"], sidx, opened)
        assert ranked["flat+bm25"].tolist() == R.first(("lme", j)).tolist()
        for a in ARMS:
            per[a].append(C.recall(ranked[a], it["ev"]))
        types.append(it["type"])
        for k, v in diag(it["ev"], sidx, opened).items():
            dg[k].append(v)
        dg["sessions"].append(m); dg["nodes"].append(len(it["rows"]))
    return per, np.array(types), dg


def diag_table(dg, groups):
    out = {}
    for name, mask in groups.items():
        out[name] = {k: float(np.asarray(v, dtype=np.float64)[mask].mean()) for k, v in dg.items()}
    return out


def main():
    torch.set_num_threads(1); t0 = time.time()
    doc_sha = hashlib.sha256(__doc__.encode()).hexdigest()[:16]
    print(f"s110_sessionfusion: pre-registered docstring sha256[:16] {doc_sha}", flush=True)
    R = Reader(with_lme=True)
    raw = json.load(open(LOCOMO))
    res = dict(docstring_sha256_16=doc_sha, b=B, rrf_k=60)

    # ---- LoCoMo reference (held-out chats, tuned rank-16 bridges)
    per, chat_of, cat, dg, eq = run_locomo(R, raw)
    flat, hyb = np.mean(per["flat"]), np.mean(per["flat+bm25"])
    print(f"LoCoMo check vs s11_rank: flat {flat:.4f} (0.6622), flat+bm25 {hyb:.4f} (0.6553)", flush=True)
    assert round(flat, 4) == 0.6622 and round(hyb, 4) == 0.6553
    mh = cat == 1; loc = dict(n=len(cat), check=dict(flat=float(flat), flat_bm25=float(hyb)), equivalence=eq)
    loc["recall10"] = {a: float(np.mean(per[a])) for a in ARMS}
    loc["by_cat"] = {a: {C.CATS[k]: float(np.asarray(per[a])[cat == k].mean()) for k in C.CATS} for a in ARMS}
    comps = [("session|flat", "flat"), ("session", "flat"), ("flat+bm25", "flat"), ("session|flat", "flat+bm25"),
             ("session|flat+bm25", "flat+bm25")]
    loc["diff_all"] = {f"{a} - {b}": stats(per, chat_of, b, a) for a, b in comps}
    loc["diff_multihop"] = {f"{a} - {b}": stats(per, chat_of, b, a, mh) for a, b in comps}
    loc["diag"] = diag_table(dg, {"all": np.ones(len(cat), bool), "multi-hop": mh})
    print(f"\nLoCoMo held-out, {len(cat)} questions, recall@10 (chat-clustered intervals; reference only)")
    for a in ARMS:
        print(f"  {a:<18} {np.mean(per[a]):.4f}  " + " ".join(f"{C.CATS[k]} {np.asarray(per[a])[cat == k].mean():.4f}"
                                                         for k in C.CATS))
    for key in loc["diff_all"]:
        print(f"  {key:<32} all {fmt(loc['diff_all'][key])}")
        print(f"  {'':<32} multi-hop {fmt(loc['diff_multihop'][key])}")
    print("  diag " + json.dumps({g: {k: round(v, 3) for k, v in d.items()} for g, d in loc["diag"].items()}))
    res["locomo"] = loc

    # ---- LongMemEval-S (the test)
    per, types, dg = run_lme(R)
    qid = np.arange(len(types))
    flat, hyb = np.mean(per["flat"]), np.mean(per["flat+bm25"])
    print(f"\nLongMemEval-S check vs s11_rank: flat {flat:.4f} (0.8839), flat+bm25 {hyb:.4f} (0.8982)", flush=True)
    assert round(flat, 4) == 0.8839 and round(hyb, 4) == 0.8982
    ms = types == "multi-session"
    lme = dict(n=len(types), n_multi_session=int(ms.sum()), check=dict(flat=float(flat), flat_bm25=float(hyb)))
    lme["recall10"] = {a: float(np.mean(per[a])) for a in ARMS}
    tlist = sorted(set(types.tolist()))
    lme["by_type"] = {a: {t: float(np.asarray(per[a])[types == t].mean()) for t in tlist} for a in ARMS}
    lme["type_counts"] = {t: int((types == t).sum()) for t in tlist}
    lme["diff_all"] = {f"{a} - {b}": stats(per, qid, b, a) for a, b in comps}
    lme["diff_by_type"] = {t: {f"{a} - {b}": stats(per, qid, b, a, types == t) for a, b in comps} for t in tlist}
    lme["diag"] = diag_table(dg, {"all": np.ones(len(types), bool), **{t: types == t for t in tlist}})
    print(f"LongMemEval-S, {len(types)} questions ({int(ms.sum())} multi-session), recall@10 (question-clustered)")
    for a in ARMS:
        print(f"  {a:<18} {np.mean(per[a]):.4f}  " + " ".join(f"{t} {lme['by_type'][a][t]:.4f}" for t in tlist))
    for key in lme["diff_all"]:
        print(f"  {key:<32} all {fmt(lme['diff_all'][key])}")
        for t in tlist:
            print(f"  {'':<32} {t} {fmt(lme['diff_by_type'][t][key])}")
    print("  diag " + json.dumps({g: {k: round(v, 3) for k, v in d.items()} for g, d in lme["diag"].items()}))
    res["lme"] = lme

    # ---- pre-registered decision
    a = lme["diff_all"]["session|flat - flat"]; b = lme["diff_by_type"]["multi-session"]["session|flat - flat"]
    cond_a = a["delta"] > 0 and a["ci"][0] > 0; cond_b = b["delta"] >= 0
    if cond_a and cond_b:
        verdict = "pass"
    elif a["delta"] <= 0 or not cond_b:
        verdict = "fail"
    else:
        verdict = "inconclusive"
    s1 = lme["diff_all"]["session|flat - flat+bm25"]; s2 = lme["diff_all"]["session|flat+bm25 - flat+bm25"]
    adds = s1["ci"][0] > 0 or s2["ci"][0] > 0
    res["verdict"] = dict(verdict=verdict, a_gain_over_flat=a, a_holds=bool(cond_a), b_multi_session=b,
                          b_holds=bool(cond_b), secondary_adds_to_current_read=bool(adds))
    print(f"\nVerdict (pre-registered): {verdict.upper()}. (a) gain over flat {a['delta']:+.4f} "
          f"[{a['ci'][0]:+.4f}, {a['ci'][1]:+.4f}] -> {cond_a}; (b) multi-session {b['delta']:+.4f} -> {cond_b}")
    print(f"Secondary: beats flat+bm25 with an interval above zero: {adds} "
          f"(session|flat {s1['delta']:+.4f} [{s1['ci'][0]:+.4f}, {s1['ci'][1]:+.4f}]; "
          f"session|flat+bm25 {s2['delta']:+.4f} [{s2['ci'][0]:+.4f}, {s2['ci'][1]:+.4f}])")
    res["seconds"] = time.time() - t0
    json.dump(res, open(os.path.join(HERE, "results", "s110_sessionfusion.json"), "w"), indent=1)
    print(f"done in {res['seconds']:.0f}s")


if __name__ == "__main__":
    main()
