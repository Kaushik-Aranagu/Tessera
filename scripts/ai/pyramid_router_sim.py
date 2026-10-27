#!/usr/bin/env python3
"""P3b prototype for the memory pyramid (docs/ai/harness/memory-pyramid.md): learned routing weights and confidence.

No model and no API call. Asks name their time the way people do ("Oct", "last month", "yesterday", "last Tuesday",
"the week of Oct 5"), so a reader can't find the node by matching words alone. A router scores each child of a node
for an ask with learned weights on (ask word, child feature) pairs: the child's title words, its recency rank among
its siblings and its level. After each answer the true path is known (hindsight), and one cross-entropy step trains
the scores along it, which is real backprop on a linear model. Confidence is the router's own probability: when every
step of a guessed path is sure enough, the reader opens that node directly instead of walking down to it.

Arms, the same asks:
  words     the router frozen at its start: only "the same word in the ask and the title" counts
  learned   the router trained online after every ask, walking level by level
  jump      learned, plus confidence: open the guessed node directly when every step's probability is over --sure

Usage: python3 scripts/ai/pyramid_router_sim.py [--nights 30] [--asks 20] [--rate 0.5] [--sure 0.9] [--seed 1]
"""
import argparse
import datetime as dt
import math
import random
import statistics
import zlib

from pyramid_sim import build, make_world

NOW = dt.date(2026, 10, 23)
WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def words(text):
    return [w for w in "".join(c.lower() if c.isalnum() else " " for c in text).split() if w]


def child_features(node, rank):
    return words(node.title) + [f"rank{min(rank, 6)}", f"level:{node.level}"]


class Router:
    def __init__(self, rate, learn=True):
        self.weights, self.rate, self.learn = {}, rate, learn

    @staticmethod
    def pairs(ask_words, feats):
        out = []
        for a in ask_words:
            for f in feats:
                out.append("same" if a == f else f"{a}|{f}")
        return out

    def score(self, ask_words, feats):
        # "same" starts at 1: the words-only router. Every other pair starts at 0 and is learned.
        return sum(self.weights.get(p, 1.0 if p == "same" else 0.0) for p in self.pairs(ask_words, feats))

    def probabilities(self, ask_words, options):
        scores = [self.score(ask_words, feats) for _, feats in options]
        top = max(scores)
        exps = [math.exp(s - top) for s in scores]
        total = sum(exps)
        return [e / total for e in exps]

    def train(self, ask_words, options, target):
        if not self.learn:
            return
        probs = self.probabilities(ask_words, options)
        for (path, feats), p in zip(options, probs):
            gradient = p - (1.0 if path == target else 0.0)
            for pair in self.pairs(ask_words, feats):
                start = 1.0 if pair == "same" else 0.0
                self.weights[pair] = self.weights.get(pair, start) - self.rate * gradient


def options(node, nodes):
    kids = sorted(node.children, reverse=True)
    return [(path, child_features(nodes[path], rank)) for rank, path in enumerate(kids)]


def true_path(target):
    parts = target.split("/")[1:]
    return ["/" + "/".join(parts[:i]) for i in range(2, len(parts) + 1)]


def walk(ask_words, target, nodes, router, sure, jump):
    """Returns (opens, first-try right at every step, found)."""
    path = true_path(target)
    opens, clean = 0, True
    if jump:
        guess, confident, node = [], True, nodes["/time"]
        while node.children and len(guess) < len(path):
            choices = options(node, nodes)
            probs = router.probabilities(ask_words, choices)
            best = max(range(len(probs)), key=probs.__getitem__)
            confident &= probs[best] >= sure
            guess.append(choices[best][0])
            node = nodes[choices[best][0]]
        if confident and guess:
            opens += 1
            if guess[-1] == target:
                return opens, True, True
            clean = False
    node = nodes["/time"]
    opens += 1
    for step in path:
        choices = options(node, nodes)
        probs = router.probabilities(ask_words, choices)
        ranked = sorted(range(len(choices)), key=lambda i: -probs[i])
        for tries, i in enumerate(ranked[:5]):
            opens += 1
            if choices[i][0] == step:
                clean &= tries == 0
                break
        else:
            return opens, False, False
        node = nodes[step]
    return opens, clean, True


def train_path(ask_words, target, nodes, router):
    node = nodes["/time"]
    for step in true_path(target):
        router.train(ask_words, options(node, nodes), step)
        node = nodes[step]


def make_ask(rng, nodes):
    days = sorted(p for p, n in nodes.items() if n.level == "day")
    months = sorted(p for p, n in nodes.items() if n.level == "month")
    kind = rng.choice(["day", "day", "month"])
    if kind == "month":
        path = months[min(len(months) - 1, int(len(months) * (1 - rng.random() ** 2)))]
        year, month = map(int, path.split("/")[2:4])
        first = dt.date(year, month, 1)
        ago = (NOW.year - year) * 12 + NOW.month - month
        names = [first.strftime("%B"), first.strftime("%b"), first.strftime("%B %Y")]
        if ago == 0:
            names.append("this month")
        if ago == 1:
            names.append("last month")
        if 2 <= ago <= 6:
            names.append(f"{ago} months ago")
        stem = rng.choice(["How many workouts in {}?", "What did I train most in {}?", "How was {}?"])
        return stem.format(rng.choice(names)), path
    path = days[min(len(days) - 1, int(len(days) * (1 - rng.random() ** 3)))]
    day = dt.date(*map(int, path.split("/")[2:5]))
    names = [day.strftime("%b %-d"), day.strftime("%A, %b %-d"), day.strftime("%-d %b"), day.strftime("%B %-d")]
    back = (NOW - day).days
    if back == 1:
        names.append("yesterday")
    if back == 0:
        names.append("today")
    if 2 <= back <= 7:
        names.append(f"last {WEEKDAYS[day.weekday()]}")
    stem = rng.choice(["What did I do on {}?", "How many sets {}?", "Did I cook on {}?"])
    return stem.format(rng.choice(names)), path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nights", type=int, default=30)
    parser.add_argument("--asks", type=int, default=20)
    parser.add_argument("--rate", type=float, default=0.5)
    parser.add_argument("--sure", type=float, default=0.9)
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args()
    rng = random.Random(args.seed)
    nodes = build(make_world(random.Random(args.seed)))
    arms = {"words": Router(args.rate, learn=False), "learned": Router(args.rate), "jump": Router(args.rate)}
    print(f"{'nights':<9}" + "".join(f"{name:>28}" for name in arms))
    rows = []
    for night in range(1, args.nights + 1):
        asks = [make_ask(rng, nodes) for _ in range(args.asks)]
        row = {}
        for name, router in arms.items():
            opens, clean, found = [], 0, 0
            for text, target in asks:
                ask_words = words(text)
                o, c, f = walk(ask_words, target, nodes, router, args.sure, jump=name == "jump")
                opens.append(o)
                clean += c
                found += f
                # Hindsight: the answer names the node it came from, so the true path is known after every ask.
                train_path(ask_words, target, nodes, router)
            row[name] = (statistics.mean(opens), clean / len(asks), found / len(asks))
        rows.append(row)
    for first, last in ((1, 1), (2, 5), (6, 10), (11, 20), (21, args.nights)):
        if first > args.nights:
            break
        cells = []
        for name in arms:
            window = [r[name] for r in rows[first - 1:last]]
            opens = statistics.mean(w[0] for w in window)
            clean = statistics.mean(w[1] for w in window)
            found = statistics.mean(w[2] for w in window)
            cells.append(f"{opens:4.1f} op {clean:4.0%} right {found:4.0%} found")
        print(f"{first:>3}-{last:<5}" + "".join(f"{c:>28}" for c in cells))
    print("weights learned:", len(arms["learned"].weights),
          "| strongest:", sorted(arms["learned"].weights.items(), key=lambda kv: -kv[1])[:6])


if __name__ == "__main__":
    main()
