#!/usr/bin/env python3
"""Stage 1.3: real read-again. After each read Haiku either says it has enough or writes the next search; the probe is
read (dense state view of the probe, BM25 on probe plus question) and Haiku reads again, at most 3 reads in all.

Primary metric (pre-registered): recall@10 of the reciprocal-rank fusion (k 60) of every list the question read
(hop 0 list, then each probe's list), against the hop-0 list alone, same questions, paired.
Secondary: recall of the union of everything opened (more reads open more snippets, so this one is not at equal
budget; the opened count is reported next to it), and the grader's answer accuracy at the last read against hop 0.
Pass bar (front matter 1.3): LoCoMo multi-hop recall@10 above the single read (0.475 in the old runs) with a chat
interval above zero, and no overall loss. LongMemEval-S is reported by question type (question-clustered intervals).
Usage: python s13_hops.py
"""
import collections, gzip, json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
from retrieval import Reader  # noqa: E402

RUNS = os.path.join(HERE, "runs")


def read(path):
    if not os.path.exists(path) and os.path.exists(path + ".gz"):
        path += ".gz"
    if not os.path.exists(path):
        return []
    op = gzip.open if path.endswith(".gz") else open
    with op(path, "rt") as f:
        return [json.loads(line) for line in f if line.strip()]


def main():
    R = Reader(); by_tag = {R.tag(q): q for q in R.ids()}
    tasks = {h: {t["id"]: t for t in read(os.path.join(RUNS, f"tasks_hop{h}.jsonl.gz"))} for h in range(3)}
    rows = {h: read(os.path.join(RUNS, f"answers_hop{h}.jsonl")) for h in range(3)}
    reads = {h: {r["id"]: r for r in rows[h] if r["kind"] == "read" and "error" not in r} for h in range(3)}
    grades = {h: {r["id"]: r for r in rows[h] if r["kind"] == "grade" and "error" not in r} for h in range(3)}
    probes = [(tid, h, t["probe"]) for h in (1, 2) for tid, t in tasks[h].items()]
    vecs = R.encode([p for _, _, p in probes]) if probes else []
    lists = collections.defaultdict(dict)
    for (tid, h, p), v in zip(probes, vecs):
        lists[tid][h] = R.probe(by_tag[tid], p, v)
    res = collections.defaultdict(list); meta = collections.defaultdict(list)
    for tid in tasks[0]:
        if tid not in reads[0]:
            continue
        q = by_tag[tid]; ev = R.evidence(q); L0 = R.first(q)
        hops = [L0] + [lists[tid][h] for h in (1, 2) if h in lists[tid]]
        fused = C.fuse(*hops) if len(hops) > 1 else L0
        opened = set(L0[:10].tolist())
        for h in (1, 2):
            if tid in tasks[h]:
                opened |= {s["node"] for s in tasks[h][tid]["snippets"]}
        last = max([h for h in (0, 1, 2) if tid in grades[h]], default=None)
        part = q[0]
        res[(part, "single")].append(C.recall(L0, ev)); res[(part, "fused")].append(C.recall(fused, ev))
        res[(part, "union")].append(len(set(ev) & opened) / len(ev)); res[(part, "opened")].append(len(opened))
        res[(part, "hops")].append(len(hops))
        res[(part, "acc0")].append(grades[0][tid]["answer_correct"] if tid in grades[0] else np.nan)
        res[(part, "acc_last")].append(grades[last][tid]["answer_correct"] if last is not None else np.nan)
        meta[part].append((q[1] if part == "locomo" else len(meta[part]), R.category(q)))
    out = {}
    for part in ("locomo", "lme"):
        if not meta[part]:
            continue
        cl = np.array([m[0] for m in meta[part]]); cat = np.array([m[1] for m in meta[part]])
        s = np.array(res[(part, "single")]); f = np.array(res[(part, "fused")])
        row = dict(n=len(s), share_read_again=round(float(np.mean(np.array(res[(part, "hops")]) > 1)), 4),
                   mean_reads=round(float(np.mean(res[(part, "hops")])), 3),
                   single=round(float(s.mean()), 4), fused=round(float(f.mean()), 4))
        d, ci = C.cluster_boot(f - s, cl); row["fused_minus_single"] = [round(d, 4), [round(x, 4) for x in ci]]
        u = np.array(res[(part, "union")]); row["union_opened"] = round(float(u.mean()), 4)
        row["mean_opened"] = round(float(np.mean(res[(part, "opened")])), 2)
        a0 = np.array(res[(part, "acc0")], dtype=float); al = np.array(res[(part, "acc_last")], dtype=float)
        ok = ~np.isnan(a0) & ~np.isnan(al)
        if ok.any():
            row["accuracy_hop0"] = round(float(a0[ok].mean()), 4); row["accuracy_last"] = round(float(al[ok].mean()), 4)
        row["by_type"] = {}
        for c in sorted(set(cat)):
            m = cat == c
            d, ci = C.cluster_boot((f - s)[m], cl[m])
            row["by_type"][c] = dict(n=int(m.sum()), single=round(float(s[m].mean()), 4), fused=round(float(f[m].mean()), 4),
                                     diff=[round(d, 4), [round(x, 4) for x in ci]],
                                     read_again=round(float(np.mean(np.array(res[(part, "hops")])[m] > 1)), 3))
        out[part] = row
    if "locomo" in out:
        mh = out["locomo"]["by_type"].get("multi-hop")
        out["verdict"] = dict(
            multi_hop_fused=mh["fused"], multi_hop_above_0_475=mh["fused"] > 0.475,
            multi_hop_gain_ci_above_zero=mh["diff"][1][0] > 0,
            no_overall_loss=out["locomo"]["fused_minus_single"][0] >= 0)
        out["verdict"]["pass"] = all(out["verdict"][k] for k in ("multi_hop_above_0_475", "multi_hop_gain_ci_above_zero", "no_overall_loss"))
    os.makedirs(os.path.join(HERE, "results"), exist_ok=True)
    json.dump(out, open(os.path.join(HERE, "results", "s13_hops.json"), "w"), indent=1)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
