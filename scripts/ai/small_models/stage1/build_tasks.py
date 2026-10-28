#!/usr/bin/env python3
"""Write the reader's task files for the Mac run (haiku_run.py), one hop at a time.

  --hop 0   every LoCoMo question (1,536) and every LongMemEval-S question with user-turn evidence (428): the question
            and the top 10 of the fused read (retrieval.Reader.first). Also writes gold.jsonl.gz (id, answer), which only
            the grading call reads.
  --hop h   for each question whose read at hop h-1 said "not enough" and gave a next search: the probe is read
            (retrieval.Reader.probe), and the task shows the snippets cited so far plus the probe's top 10 minus anything
            already shown, numbered on from the last number used. Hop MAX_HOPS - 1 is marked as the last read.
At most 3 reads per question (hops 0, 1, 2), pre-registered for test 1.3.
Files go to stage1/runs/ (gzipped JSON lines). Snippets carry their node index for the analysis; the reader is never
shown node indices, only the snippet number, date and text.
Usage: python build_tasks.py --hop 0 | --hop 1 | --hop 2
"""
import argparse, gzip, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from retrieval import Reader  # noqa: E402

RUNS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "runs")
OPEN = 10
MAX_HOPS = 3


def read(path):
    if not os.path.exists(path) and os.path.exists(path + ".gz"):
        path += ".gz"
    op = gzip.open if path.endswith(".gz") else open
    with op(path, "rt") as f:
        return [json.loads(line) for line in f if line.strip()]


def write(path, rows):
    with gzip.open(path, "wt") as f:
        for row in rows:
            f.write(json.dumps(row) + "\n")


def answers(hop):
    """The reader's rows of one hop, by id (errors left out)."""
    path = os.path.join(RUNS, f"answers_hop{hop}.jsonl")
    return {r["id"]: r for r in read(path) if r.get("kind") == "read" and "error" not in r}


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--hop", type=int, required=True)
    a = p.parse_args()
    if not 0 <= a.hop < MAX_HOPS:
        sys.exit(f"--hop must be 0 to {MAX_HOPS - 1}")
    os.makedirs(RUNS, exist_ok=True)
    R = Reader()
    qs = R.ids(); by_tag = {R.tag(q): q for q in qs}
    if a.hop == 0:
        tasks, gold = [], []
        for q in qs:
            order = R.first(q)
            snippets = [dict(n=k + 1, node=int(v), **R.snippet(q, int(v))) for k, v in enumerate(order[:OPEN])]
            tasks.append(dict(id=R.tag(q), set=q[0], hop=0, question=R.question(q), today=R.today(q), history=[],
                              kept=[], snippets=snippets, last=False))
            gold.append(dict(id=R.tag(q), answer=R.answer(q)))
        write(os.path.join(RUNS, "tasks_hop0.jsonl.gz"), tasks)
        write(os.path.join(RUNS, "gold.jsonl.gz"), gold)
        print(f"hop 0: {len(tasks)} tasks ({sum(t['set'] == 'locomo' for t in tasks)} LoCoMo, "
              f"{sum(t['set'] == 'lme' for t in tasks)} LongMemEval-S)")
        return
    prev_tasks = {t["id"]: t for t in read(os.path.join(RUNS, f"tasks_hop{a.hop - 1}.jsonl.gz"))}
    prev = answers(a.hop - 1)
    todo = [(tid, r) for tid, r in prev.items() if tid in prev_tasks and not r["enough"] and r["next_search"].strip()]
    vecs = R.encode([r["next_search"] for _, r in todo]) if todo else []
    tasks = []
    for (tid, r), vec in zip(todo, vecs):
        t = prev_tasks[tid]; q = by_tag[tid]
        shown = {s["node"] for s in t["kept"] + t["snippets"]}
        number = {s["n"]: s for s in t["kept"] + t["snippets"]}
        kept = t["kept"] + [number[n] for n in r["cites"] if n in number and number[n] not in t["kept"]]
        top = R.probe(q, r["next_search"], vec)
        nxt = t.get("next_n", max(number, default=OPEN) + 1); new = []
        for v in top[:OPEN]:
            if int(v) not in shown:
                new.append(dict(n=nxt, node=int(v), **R.snippet(q, int(v)))); nxt += 1
        history = t["history"] + [dict(hop=t["hop"], search=t.get("probe") or t["question"], answer=r["answer"])]
        tasks.append(dict(id=tid, set=t["set"], hop=a.hop, question=t["question"], today=t["today"], history=history,
                          kept=kept, snippets=new, probe=r["next_search"], next_n=nxt, last=a.hop == MAX_HOPS - 1))
    write(os.path.join(RUNS, f"tasks_hop{a.hop}.jsonl.gz"), tasks)
    print(f"hop {a.hop}: {len(tasks)} tasks from {len(prev)} answers at hop {a.hop - 1}")


if __name__ == "__main__":
    main()
