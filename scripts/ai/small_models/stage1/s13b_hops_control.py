#!/usr/bin/env python3
"""Post hoc control for 1.3 (NOT pre-registered; added after an independent review of s13_hops.py).

Question: does the read-again recall gain come from Haiku's searches, or from fusing any second list into the
BM25-fused first read? Same questions, same number of extra lists, same k: each probe list is replaced by the
question's own dense bridge list (no search at all). Also reports an LLM-free arm that fuses every question's first
read with its dense list. Chat-clustered on LoCoMo, question-clustered on LongMemEval-S, as in s13_hops.py.
Usage: python s13b_hops_control.py
"""
import collections, json, os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common as C  # noqa: E402
import s13_hops as H  # noqa: E402
from retrieval import Reader  # noqa: E402

ARMS = ("single", "dense", "read_again", "control", "free")


def main():
    R = Reader(); by_tag = {R.tag(q): q for q in R.ids()}
    tasks = {h: {t["id"]: t for t in H.read(os.path.join(H.RUNS, f"tasks_hop{h}.jsonl.gz"))} for h in range(3)}
    reads0 = {r["id"] for r in H.read(os.path.join(H.RUNS, "answers_hop0.jsonl")) if r["kind"] == "read" and "error" not in r}
    probes = [(tid, h, t["probe"]) for h in (1, 2) for tid, t in tasks[h].items()]
    vecs = R.encode([p for _, _, p in probes])
    lists = collections.defaultdict(dict)
    for (tid, h, p), v in zip(probes, vecs):
        lists[tid][h] = R.probe(by_tag[tid], p, v)
    rec = collections.defaultdict(list); cl = collections.defaultdict(list); cat = collections.defaultdict(list)
    for tid in tasks[0]:
        if tid not in reads0:
            continue
        q = by_tag[tid]; ev = R.evidence(q); L0 = R.first(q); D = R.dense_only(q)
        hs = [h for h in (1, 2) if h in lists[tid]]
        arms = dict(single=L0, dense=D, read_again=C.fuse(L0, *[lists[tid][h] for h in hs]) if hs else L0,
                    control=C.fuse(L0, *[D for _ in hs]) if hs else L0, free=C.fuse(L0, D))
        for k in ARMS:
            rec[(q[0], k)].append(C.recall(arms[k], ev))
        cl[q[0]].append(q[1] if q[0] == "locomo" else len(cl[q[0]])); cat[q[0]].append(R.category(q))
    out = {"note": "post hoc control, not pre-registered"}
    for part in ("locomo", "lme"):
        c = np.array(cl[part]); t = np.array(cat[part]); v = {k: np.array(rec[(part, k)]) for k in ARMS}
        def block(m):
            row = {k: round(float(v[k][m].mean()), 4) for k in ARMS}; row["n"] = int(m.sum())
            for a, b in (("read_again", "control"), ("read_again", "dense"), ("read_again", "free")):
                d, ci = C.cluster_boot((v[a] - v[b])[m], c[m]); row[f"{a}_minus_{b}"] = [round(d, 4), [round(x, 4) for x in ci]]
            return row
        out[part] = {"all": block(np.ones(len(c), bool)), "by_type": {k: block(t == k) for k in sorted(set(t))}}
        print(part, json.dumps(out[part]["all"]))
    json.dump(out, open(os.path.join(HERE, "results", "s13b_hops_control.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
