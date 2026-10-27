#!/usr/bin/env python3
"""Offline retrieval check for the memory pyramid (docs/ai/harness/memory-pyramid.md) on a public long-memory set.

No model and no API call. LoCoMo (snap-research/locomo, CC BY-NC 4.0) holds ten long two-person chats, 19 to 32
sessions each, with questions whose evidence turns are marked. Each turn is a leaf. The question is whether reading
down a hierarchy keeps the evidence a flat search finds, and how much less it has to score. BM25 stands in for the
reader at every level, so the numbers are a floor for lexical routing, not a model's score.

Arms, the same turns and questions (adversarial category 5 left out, as its answers are "not mentioned"):
  flat      every turn scored at once, top k
  session   the --sessions best sessions (a session scored as all its turns), then their turns, top k
  topic     the 2 x --sessions best holders of a topic tree grown over the turns (the Swift TopicTree's rules,
            mirrored below), then their turns, top k
  both      the union of the session and topic candidates, top k

It prints recall@k (the share of a question's evidence turns in the top k, averaged), recall@10 by LoCoMo category,
how much evidence the candidates could reach at all, and items scored per question.

Usage: python3 scripts/ai/pyramid_locomo_check.py [--data locomo10.json] [--sessions 3] [--split 24] [--nights 10]
The data file is not kept in the repo. With no --data it is downloaded to a temporary folder from
https://raw.githubusercontent.com/snap-research/locomo/main/data/locomo10.json (about 2.8 MB).
"""
import argparse
import collections
import json
import math
import os
import re
import tempfile
import urllib.request

DATA_URL = "https://raw.githubusercontent.com/snap-research/locomo/main/data/locomo10.json"
# PyramidAsk.stopWords.
STOP = set(
    "a about am an and are at be been did do does far for how i in is it many me much my of on or so that the to was "
    "we were what when you".split()
)
ROOT = "/topics"
CATEGORIES = {1: "multi-hop", 2: "when", 3: "inference", 4: "single-hop"}


def tokens(text):
    """TopicWords' words, in order and repeated: lowercased, no stop words, two characters and a letter at least."""
    return [
        w
        for w in re.split(r"[^a-z0-9]+", text.lower())
        if len(w) >= 2 and any(c.isalpha() for c in w) and w not in STOP
    ]


def words(text):
    return set(tokens(text))


# MARK: The topic tree, as TopicTree.swift does it


class TopicTree:
    def __init__(self, of, split_at=24, merge_at=12, settle=20, cap=3, key_words=12):
        self.of = of  # leaf id -> word set
        self.df = collections.Counter(w for ws in of.values() for w in ws)
        self.split_at, self.merge_at, self.settle_n, self.cap, self.key_words = (
            split_at, merge_at, settle, cap, key_words)
        self.nodes = {ROOT: dict(id=ROOT, parent=None, children=[], leaves=[])}
        self.co_use = {}
        self.made = 0

    @staticmethod
    def size(node):
        return len(node["leaves"]) if node["leaves"] else len(node["children"])

    def leaves(self, node_id):
        node = self.nodes.get(node_id)
        if not node:
            return []
        return node["leaves"] + [leaf for child in node["children"] for leaf in self.leaves(child)]

    def holder(self, leaf):
        return next((n["id"] for n in self.nodes.values() if leaf in n["leaves"]), None)

    def key(self, node_id):
        leaves = self.leaves(node_id)
        if not leaves:
            return []
        counts = collections.Counter(w for leaf in leaves for w in self.of.get(leaf, ()))
        total = max(1, len(self.of))
        scored = [(w, c / len(leaves) * math.log(1 + total / self.df.get(w, 1))) for w, c in counts.items()]
        scored.sort(key=lambda x: (-x[1], x[0]))
        return [w for w, _ in scored[: self.key_words]]

    def insert(self, leaf):
        if self.holder(leaf):
            return
        own = self.of.get(leaf, set())
        node_id = ROOT
        while self.nodes[node_id]["children"]:
            shared = {c: len(own & set(self.key(c))) for c in self.nodes[node_id]["children"]}
            best = max(shared.values())
            node_id = min(c for c in shared if shared[c] == best)
        self.nodes[node_id]["leaves"].append(leaf)

    def new_id(self):
        self.made += 1
        return f"{ROOT}/t{self.made}"

    @staticmethod
    def two_means(sets):
        if len(sets) < 2:
            return [list(range(len(sets)))]

        def alike(a, b):
            return len(a & b) / max(1, len(a | b))

        far = min(range(1, len(sets)), key=lambda j: (alike(sets[0], sets[j]), j))
        centers = [{w: 1 for w in sets[0]}, {w: 1 for w in sets[far]}]
        groups = [[], []]
        for _ in range(5):
            groups = [[], []]
            for index, item in enumerate(sets):
                score = [sum(c.get(w, 0) for w in item) / max(1, sum(c.values())) for c in centers]
                groups[0 if score[0] >= score[1] else 1].append(index)
            if not groups[0] or not groups[1]:
                half = len(sets) // 2
                groups = [list(range(half)), list(range(half, len(sets)))]
            centers = [collections.Counter(w for index in g for w in sets[index]) for g in groups]
        return groups

    def split(self, node_id):
        node = self.nodes[node_id]
        holds = bool(node["leaves"])
        items = node["leaves"] if holds else node["children"]
        sets = [self.of.get(x, set()) if holds else set(self.key(x)) for x in items]
        halves = []
        for group in self.two_means(sets):
            half = self.new_id()
            new = dict(id=half, parent=None, children=[], leaves=[])
            if holds:
                new["leaves"] = [items[i] for i in group]
            else:
                new["children"] = [items[i] for i in group]
                for child in new["children"]:
                    self.nodes[child]["parent"] = half
            self.nodes[half] = new
            halves.append(half)
        if node_id == ROOT:
            node["leaves"], node["children"] = [], halves
            for half in halves:
                self.nodes[half]["parent"] = ROOT
        else:
            parent = node["parent"]
            del self.nodes[node_id]
            self.nodes[parent]["children"] = [c for c in self.nodes[parent]["children"] if c != node_id] + halves
            for half in halves:
                self.nodes[half]["parent"] = parent

    def mergeable(self):
        best = None
        limit = min(self.merge_at, self.split_at // 2)
        for node in sorted(self.nodes.values(), key=lambda n: n["id"]):
            holders = sorted(c for c in node["children"] if not self.nodes[c]["children"])
            for i, a in enumerate(holders):
                for b in holders[i + 1:]:
                    if len(self.leaves(a)) + len(self.leaves(b)) > limit:
                        continue
                    ka, kb = set(self.key(a)), set(self.key(b))
                    alike = len(ka & kb) / max(1, len(ka | kb))
                    used = self.co_use.get(f"{a}|{b}", 0)
                    if not (used >= 3 or alike >= 0.5):
                        continue
                    if best is None or (used, alike) > best[0]:
                        best = ((used, alike), (a, b))
        return best[1] if best else None

    def merge(self, kept, removed):
        self.nodes[kept]["leaves"] += self.nodes[removed]["leaves"]
        parent = self.nodes[removed]["parent"]
        self.nodes[parent]["children"] = [c for c in self.nodes[parent]["children"] if c != removed]
        del self.nodes[removed]

    def collapse(self, node_id):
        node = self.nodes[node_id]
        child, parent = node["children"][0], node["parent"]
        self.nodes[parent]["children"] = [child if c == node_id else c for c in self.nodes[parent]["children"]]
        self.nodes[child]["parent"] = parent
        del self.nodes[node_id]

    def settle(self):
        holders = sorted((n for n in self.nodes.values() if not n["children"] and n["leaves"]), key=lambda n: n["id"])
        counts = {
            h["id"]: collections.Counter(w for leaf in h["leaves"] for w in self.of.get(leaf, ())) for h in holders
        }

        def fit(own, leaf, holder):
            inside = leaf in holder["leaves"]
            others = len(holder["leaves"]) - (1 if inside else 0)
            if others <= 0:
                return 0
            return sum((counts[holder["id"]].get(w, 0) - (1 if inside else 0)) / others for w in own)

        moves = []
        for source in holders:
            for leaf in source["leaves"]:
                own = self.of.get(leaf, set())
                fits = [(h["id"], fit(own, leaf, h)) for h in holders]
                top = max(f for _, f in fits)
                best = min(h for h, f in fits if f == top)
                here = dict(fits)[source["id"]]
                if best != source["id"] and top - here >= 1:
                    moves.append((top - here, leaf, source["id"], best))
        moves.sort(key=lambda m: (-m[0], m[1]))
        for _, leaf, source, to in moves[: self.settle_n]:
            if len(self.nodes[source]["leaves"]) <= 1:
                continue
            self.nodes[source]["leaves"].remove(leaf)
            self.nodes[to]["leaves"].append(leaf)

    def night(self):
        changes = 0
        for node in sorted(list(self.nodes.values()), key=lambda n: (-self.size(n), n["id"])):
            if self.size(node) <= self.split_at:
                continue
            if changes >= self.cap:
                break
            current = self.nodes.get(node["id"])
            if not current or self.size(current) <= self.split_at:
                continue
            self.split(node["id"])
            changes += 1
        while changes < self.cap and (pair := self.mergeable()):
            self.merge(*pair)
            changes += 1
        while changes < self.cap:
            lone = sorted(
                n["id"] for n in self.nodes.values() if n["id"] != ROOT and not n["leaves"] and len(n["children"]) == 1
            )
            if not lone:
                break
            self.collapse(lone[0])
            changes += 1
        self.settle()


# MARK: Scoring


class BM25:
    def __init__(self, docs):
        self.docs = docs
        self.n = len(docs)
        self.average = sum(len(d) for d in docs.values()) / max(1, self.n)
        self.df = collections.Counter(w for d in docs.values() for w in set(d))
        self.tf = {i: collections.Counter(d) for i, d in docs.items()}

    def score(self, query, doc, k1=1.2, b=0.75):
        tf, length, out = self.tf[doc], len(self.docs[doc]), 0.0
        for w in set(query):
            if w in tf:
                idf = math.log(1 + (self.n - self.df[w] + 0.5) / (self.df[w] + 0.5))
                out += idf * tf[w] * (k1 + 1) / (tf[w] + k1 * (1 - b + b * length / self.average))
        return out

    def rank(self, query, ids=None):
        ids = self.docs.keys() if ids is None else ids
        return sorted(ids, key=lambda d: (-self.score(query, d), d))


def conversations(path):
    with open(path) as handle:
        data = json.load(handle)
    for sample in data:
        chat = sample["conversation"]
        turns, session = {}, {}
        for name, value in chat.items():
            if name.startswith("session_") and isinstance(value, list):
                for turn in value:
                    caption = turn.get("blip_caption")
                    turns[turn["dia_id"]] = f"{turn['speaker']}: {turn['text']}" + (f" {caption}" if caption else "")
                    session[turn["dia_id"]] = name
        questions = [q for q in sample["qa"] if q["category"] != 5 and q.get("evidence")]
        yield turns, session, questions


def run(args):
    ks = (5, 10, 20)
    total = collections.defaultdict(float)
    asked = 0
    holders_made = []
    for turns, session, questions in conversations(args.data):
        docs = {d: tokens(t) for d, t in turns.items()}
        flat = BM25(docs)
        by_session = collections.defaultdict(list)
        for d in turns:
            by_session[session[d]].append(d)
        sessions = BM25({s: [w for d in ds for w in docs[d]] for s, ds in by_session.items()})
        tree = TopicTree({d: words(t) for d, t in turns.items()}, split_at=args.split, merge_at=args.split // 2)
        for d in turns:
            tree.insert(d)
        for _ in range(args.nights):
            tree.night()
        holders = [n for n in tree.nodes.values() if not n["children"] and n["leaves"]]
        holders_made.append(len(holders))
        topics = BM25({h["id"]: [w for d in h["leaves"] for w in docs[d]] for h in holders})
        for question in questions:
            evidence = {e.strip() for e in question["evidence"]} & set(turns)
            if not evidence:
                continue
            asked += 1
            query = tokens(question["question"])
            session_pool = [d for s in sessions.rank(query)[: args.sessions] for d in by_session[s]]
            topic_pool = [d for h in topics.rank(query)[: 2 * args.sessions] for d in tree.nodes[h]["leaves"]]
            both_pool = sorted(set(session_pool) | set(topic_pool))
            ranked = {
                "flat": flat.rank(query),
                "session": flat.rank(query, session_pool),
                "topic": flat.rank(query, topic_pool),
                "both": flat.rank(query, both_pool),
            }
            total["scored flat"] += flat.n
            total["scored session"] += sessions.n + len(session_pool)
            total["scored topic"] += topics.n + len(topic_pool)
            total["scored both"] += sessions.n + topics.n + len(both_pool)
            total["reach session"] += len(evidence & set(session_pool)) / len(evidence)
            total["reach topic"] += len(evidence & set(topic_pool)) / len(evidence)
            total["reach both"] += len(evidence & set(both_pool)) / len(evidence)
            category = question["category"]
            total[f"n{category}"] += 1
            for arm, order in ranked.items():
                for k in ks:
                    total[f"{arm}@{k}"] += len(evidence & set(order[:k])) / len(evidence)
                total[f"{arm}@10 c{category}"] += len(evidence & set(order[:10])) / len(evidence)
    arms = ("flat", "session", "topic", "both")
    print(f"{asked} questions over {len(holders_made)} chats; topic holders per chat about "
          f"{sum(holders_made) / max(1, len(holders_made)):.0f}; --sessions {args.sessions}")
    for k in ks:
        print(f"recall@{k:<2}  " + "  ".join(f"{arm} {total[f'{arm}@{k}'] / asked:.3f}" for arm in arms))
    for category, name in CATEGORIES.items():
        count = total[f"n{category}"]
        print(f"  @10 {name} ({count:.0f})  "
              + "  ".join(f"{arm} {total[f'{arm}@10 c{category}'] / count:.3f}" for arm in arms))
    print("evidence reachable  " + "  ".join(f"{arm} {total[f'reach {arm}'] / asked:.3f}" for arm in arms[1:]))
    print("items scored a question  " + "  ".join(f"{arm} {total[f'scored {arm}'] / asked:.0f}" for arm in arms))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", help="locomo10.json; downloaded when left out")
    parser.add_argument("--sessions", type=int, default=3)
    parser.add_argument("--split", type=int, default=24)
    parser.add_argument("--nights", type=int, default=10)
    args = parser.parse_args()
    if not args.data:
        args.data = os.path.join(tempfile.mkdtemp(prefix="locomo-"), "locomo10.json")
        urllib.request.urlretrieve(DATA_URL, args.data)
    run(args)


if __name__ == "__main__":
    main()
