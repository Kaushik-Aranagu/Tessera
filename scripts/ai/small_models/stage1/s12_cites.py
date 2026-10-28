#!/usr/bin/env python3
"""Stage 1.2 (predictions P1 and P3, idea 5): learning from the reader's real cites.

Input: runs/tasks_hop0.jsonl.gz and runs/answers_hop0.jsonl (Haiku's reads and grades from haiku_run.py).
Cite quality, for LoCoMo and LongMemEval-S: answer accuracy (grader), cites per question, and the wrong-cite rate
p_w two ways: graded (a cite the grader did not mark as supporting the gold answer) and marked (a cite that is not
one of the benchmark's marked evidence turns).

Learning rules, LoCoMo only (LongMemEval-S has one question per haystack, so nothing is asked twice). Protocol as the
cite-noise fix: rank-16 keys of the fold that held the chat out, 3 shuffled orders per chat (the same orders for every
arm), after each question the plane learns from that question's cites, recall@10 on the next questions. Cites are
static: they are what Haiku cited from the hop-0 opened top 10 (the fused read), not re-read after the keys move.
Cite conditions:
  haiku     what Haiku cited (the real signal)
  graded    Haiku's cites that the grader marked as supporting the gold answer (needs the gold answer: a ceiling)
  visible   the marked evidence inside the opened top 10 (the old "visible" oracle on this read)
  clean     all marked evidence (the old oracle; reproduces about +0.020 for move)
  self      the current dense top 1
Rules (settings fixed in advance from the cite-noise fix's most common dev picks; nothing tuned on these cites):
  move η 0.1, move η 0.05, contrastive (pull η 0.05, push opened-not-cited η 0.03), centred (η 0.1, c 1) and combo
  (centred pull η 0.1 plus centred push η 0.02). Centred rules subtract the mean ask state of the fold's training
  chats under its bridge, frozen per bridge version (method fix #10), instead of a running mean.
Statistics: per question, the 3 orders are averaged; differences against no learning use the chat-clustered bootstrap.
Pass bars (front matter 1.2): P1 move gains at most +0.005 on real cites (falsified by a gain above +0.005 with a chat
interval above zero). P3 learning helps iff p_w is below break-even (0.24 to 0.27 for move at η 0.1; 0.38 to 0.42 at
η 0.05; 0.55 centred). Idea 5 is upgraded only if some rule gains with a chat interval above zero on haiku cites and
keeps a gain after BM25 fusion (fused interval above zero).
Usage: python s12_cites.py [--answers runs/answers_hop0.jsonl]
"""
import argparse, collections, gzip, json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

RULES = {
    "move η0.1": dict(eta=0.1),
    "move η0.05": dict(eta=0.05),
    "contrastive": dict(eta=0.05, eta_neg=0.03),
    "centred": dict(eta=0.1, c=1.0),
    "combo": dict(eta=0.1, c=1.0, eta_neg=0.02),
}
CONDS = ("haiku", "graded", "visible", "clean", "self")
ORDERS = 3
BREAK_EVEN = {"move η0.1": (0.24, 0.27), "move η0.05": (0.38, 0.42), "centred": (0.55, 0.55)}


def read(path):
    if not os.path.exists(path) and os.path.exists(path + ".gz"):
        path += ".gz"
    op = gzip.open if path.endswith(".gz") else open
    with op(path, "rt") as f:
        return [json.loads(line) for line in f if line.strip()]


def unit1(x):
    return x / np.linalg.norm(x)


def run_order(K0, S, lexorder, qs, cites, opened, order, cfg, mu):
    """One pass over a chat. cites: per question a list of nodes (None = self). Returns dense and fused recall per question."""
    keys = K0.copy(); n = len(K0); dense = np.zeros(len(qs)); fused = np.zeros(len(qs))
    eta, c, neg = cfg.get("eta", 0.0), cfg.get("c", 0.0), cfg.get("eta_neg", 0.0)
    for r in order:
        s = S[r]; top = C.order_of(keys @ s)
        dense[r] = C.recall(top, qs[r][1]); fused[r] = C.recall(C.fuse(lexorder[r], top), qs[r][1])
        if not eta:
            continue
        cited = [int(top[0])] if cites[r] is None else cites[r]
        d = unit1(s - c * mu) if c else s
        for v in cited:
            keys[v] = unit1(keys[v] + eta * (d - keys[v]))
        if neg:
            for u in opened[r]:
                if u not in cited:
                    keys[u] = unit1(keys[u] - neg * d)
    return dense, fused


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--tasks", default=os.path.join(HERE, "runs", "tasks_hop0.jsonl.gz"))
    p.add_argument("--answers", default=os.path.join(HERE, "runs", "answers_hop0.jsonl"))
    p.add_argument("--out", default=os.path.join(HERE, "results", "s12_cites.json"))
    a = p.parse_args()
    R = Reader()
    tasks = {t["id"]: t for t in read(a.tasks)}
    reads, grades = {}, {}
    for row in read(a.answers):
        if "error" in row:
            continue
        (reads if row["kind"] == "read" else grades)[row["id"]] = row
    out = {"source": os.path.basename(a.answers), "quality": {}}

    # ---- cite quality
    for part in ("locomo", "lme"):
        ids = [t for t in tasks if tasks[t]["set"] == part]
        got = [t for t in ids if t in reads]
        n_cites = n_bad_graded = n_bad_marked = n_graded_cites = 0; correct = graded_q = 0; zero = 0
        vis_ev = vis_cited = 0; by_cat = collections.defaultdict(lambda: [0, 0, 0])
        for t in got:
            task, rd = tasks[t], reads[t]
            node = {s["n"]: s["node"] for s in task["snippets"]}
            cited = [node[n] for n in rd["cites"] if n in node]
            ev = set(_evidence(R, t))
            opened = set(node.values())
            n_cites += len(cited); zero += not cited
            n_bad_marked += sum(v not in ev for v in cited)
            vis = ev & opened; vis_ev += len(vis); vis_cited += len(vis & set(cited))
            g = grades.get(t)
            if g is not None:
                graded_q += 1; correct += g["answer_correct"]
                sup = {node[n] for n in g["supports"] if n in node}
                n_graded_cites += len(cited); n_bad_graded += sum(v not in sup for v in cited)
                cat = _category(R, t); by_cat[cat][0] += 1; by_cat[cat][1] += g["answer_correct"]
        out["quality"][part] = dict(
            tasks=len(ids), read=len(got), graded=graded_q,
            answer_accuracy=round(correct / max(graded_q, 1), 4),
            cites_per_question=round(n_cites / max(len(got), 1), 3), no_cites=round(zero / max(len(got), 1), 4),
            p_wrong_graded=round(n_bad_graded / max(n_graded_cites, 1), 4),
            p_wrong_marked=round(n_bad_marked / max(n_cites, 1), 4),
            visible_evidence_cited=round(vis_cited / max(vis_ev, 1), 4),
            accuracy_by_type={k: round(v[1] / v[0], 3) for k, v in sorted(by_cat.items())})

    # ---- learning rules on LoCoMo
    rows = collections.defaultdict(list)  # (rule, cond, mode) -> per question values (chat order)
    base = {"dense": [], "fused": []}; chat_of = []; cat_of = []
    for i, ch in enumerate(R.chats):
        K0, S = R.keys[i]; f = i // 2
        tr = [j for j in range(10) if j not in C.FOLDS[f]]
        mu = np.concatenate([R.bridges[f].views(R.chats[j]["nodes"], R.chats[j]["asks"])[1] for j in tr]).mean(0)
        nq = len(ch["qs"]); opened, cites = [], {c: [] for c in CONDS}
        for r in range(nq):
            tid = f"locomo:{i}:{r}"; task = tasks.get(tid); rd = reads.get(tid); g = grades.get(tid)
            node = {s["n"]: s["node"] for s in task["snippets"]} if task else {}
            op = list(node.values()); opened.append(op)
            hc = [node[n] for n in rd["cites"] if n in node] if rd else []
            sup = {node[n] for n in g["supports"] if n in node} if g else set()
            ev = ch["qs"][r][1]
            cites["haiku"].append(hc); cites["graded"].append([v for v in hc if v in sup])
            cites["visible"].append([v for v in ev if v in set(op)]); cites["clean"].append(list(ev))
            cites["self"].append(None)
        orders = [np.random.default_rng([i, o, 2027]).permutation(nq) for o in range(ORDERS)]
        d0 = np.zeros(nq); f0 = np.zeros(nq)
        for order in orders:
            d, fu = run_order(K0, S, ch["lexorder"], ch["qs"], cites["clean"], opened, order, {}, mu)
            d0 += d / ORDERS; f0 += fu / ORDERS
        base["dense"] += d0.tolist(); base["fused"] += f0.tolist()
        chat_of += [i] * nq; cat_of += [q[2] for q in ch["qs"]]
        for rule, cfg in RULES.items():
            for cond in CONDS:
                dd = np.zeros(nq); ff = np.zeros(nq)
                for order in orders:
                    d, fu = run_order(K0, S, ch["lexorder"], ch["qs"], cites[cond], opened, order, cfg, mu)
                    dd += d / ORDERS; ff += fu / ORDERS
                rows[(rule, cond, "dense")] += dd.tolist(); rows[(rule, cond, "fused")] += ff.tolist()
    chat_of = np.array(chat_of); cat_of = np.array(cat_of)
    b_d = np.array(base["dense"]); b_f = np.array(base["fused"])
    out["baseline"] = dict(dense=round(float(b_d.mean()), 4), fused=round(float(b_f.mean()), 4),
                           dense_multi_hop=round(float(b_d[cat_of == 1].mean()), 4))
    out["rules"] = {}
    for rule in RULES:
        for cond in CONDS:
            v_d = np.array(rows[(rule, cond, "dense")]); v_f = np.array(rows[(rule, cond, "fused")])
            dd, cd = C.cluster_boot(v_d - b_d, chat_of); df, cf = C.cluster_boot(v_f - b_f, chat_of)
            per_chat = [round(float((v_d - b_d)[chat_of == j].mean()), 4) for j in range(10)]
            out["rules"][f"{rule} | {cond}"] = dict(dense=round(float(v_d.mean()), 4), gain=round(dd, 4),
                                                    ci=[round(x, 4) for x in cd], fused_gain=round(df, 4),
                                                    fused_ci=[round(x, 4) for x in cf],
                                                    multi_hop_gain=round(float((v_d - b_d)[cat_of == 1].mean()), 4),
                                                    chats_up=sum(x > 0 for x in per_chat), per_chat=per_chat)
    # ---- verdicts, mechanical
    pw = out["quality"]["locomo"]["p_wrong_graded"]
    mv = out["rules"]["move η0.1 | haiku"]
    v = dict(P1_move_gain_at_most_0_005=not (mv["gain"] > 0.005 and mv["ci"][0] > 0))
    for rule, (lo, hi) in BREAK_EVEN.items():
        r = out["rules"][f"{rule} | haiku"]
        predicted = "helps" if pw < lo - 0.05 else ("hurts" if pw > hi + 0.05 else "near break-even")
        seen = "helps" if r["ci"][0] > 0 else ("hurts" if r["ci"][1] < 0 else "no clear effect")
        v[f"P3 {rule}"] = dict(p_wrong=pw, break_even=[lo, hi], predicted=predicted, measured=seen)
    ups = [k for k, r in out["rules"].items() if k.endswith("| haiku") and r["ci"][0] > 0 and r["fused_ci"][0] > 0]
    v["idea5_upgrade"] = dict(rules_passing=ups, upgraded=bool(ups))
    out["verdict"] = v
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump(out, open(a.out, "w"), indent=1)
    print(json.dumps(out["quality"], indent=1))
    print(f"baseline dense {out['baseline']['dense']:.3f}  fused {out['baseline']['fused']:.3f}")
    for k, r in out["rules"].items():
        print(f"  {k:<26} gain {r['gain']:+.4f} [{r['ci'][0]:+.4f},{r['ci'][1]:+.4f}]  fused {r['fused_gain']:+.4f} "
              f"[{r['fused_ci'][0]:+.4f},{r['fused_ci'][1]:+.4f}]  mh {r['multi_hop_gain']:+.4f}  chats up {r['chats_up']}/10")
    print(json.dumps(out["verdict"], indent=1))


def _parse(t):
    part, *rest = t.split(":", 1)
    return part, rest[0]


def _evidence(R, t):
    part, rest = _parse(t)
    if part == "locomo":
        i, r = map(int, rest.split(":")); return R.chats[i]["qs"][r][1]
    return R.items[R.lme_index[rest]]["ev"]


def _category(R, t):
    part, rest = _parse(t)
    if part == "locomo":
        i, r = map(int, rest.split(":")); return C.CATS[R.chats[i]["qs"][r][2]]
    return R.items[R.lme_index[rest]]["type"]


if __name__ == "__main__":
    main()
