#!/usr/bin/env python3
"""P4 prototype for the memory pyramid (docs/ai/harness/memory-pyramid.md): a topic axis that grows, splits and merges.

No model and no API call. Free-text leaves (things he told Tess, notes, conversation turns) arrive every night about
topics that start, run and fade; each topic has a few subtopics, and their words overlap. There are no dates to file
them by, so the tree has to grow its own shape:

- A new leaf goes down the tree to the node whose key (its most telling words, counted exactly from its leaves) it
  shares most words with.
- **Split.** A node holding more than --split children splits in two by 2-means over its children's words. Net2Net
  style: both halves start with the parent's key words, so nothing reads differently at the moment of the split.
  Under the root, the halves become its children; elsewhere they replace the node beside its siblings.
- **Merge.** Two siblings merge when the same asks keep using both, or their keys converge, and together they hold
  at most --merge children. With --merge well under --split (hysteresis) a merge can't set off the next split.
- **Collapse.** A node left with one child is removed and the child joins the grandparent.
- At most --cap structural changes a night, logged so that any one can be undone. A split whose halves merge back
  within 10 nights counts as a flip.

- **Settle.** Each night up to --settle leaves move to the holder they fit clearly better: one k-means reassignment
  step across the tree, so a subtopic that a split cut in two gathers again. --fit key compares shared key words
  (a gain of 2); --fit affinity sums, for each of the leaf's words, the share of the holder's other leaves that hold
  it (a gain of 1).

A reader answers each ask ("what did I say about <topic> <subtopic>") from the root down and reads the leaves of a node
that holds leaves; a leaf counts as found when it shares two words with the ask, the same rule flat uses. It counts
opens, characters read, and the share of the true leaves found (recall). How it picks children:
  --reader key     the children whose shown key shares a word with the ask, at most --beam
  --reader index   every child holding a leaf that matches, best first: an exact index, so the tree ranks but never
                   hides

Arms, the same leaves and asks:
  flat      every leaf read at once
  grow      split only
  merge     split and merge with hysteresis (--merge well under --split)
  churn     split and merge with no hysteresis (merge at --split) and no cap
  settle    merge, plus leaves settling each night

Usage: python3 scripts/ai/pyramid_topic_sim.py [--nights 60] [--leaves 12] [--asks 8] [--split 24] [--merge 12]
                                               [--cap 3] [--beam 2] [--key 6] [--reader key|index] [--settle 20]
                                               [--fit key|affinity] [--seed 1]
"""
import argparse
import collections
import random
import statistics

FILLER = ("said really maybe think going want thing still today again more just like need also much good last "
          "next week day time feel make get know right").split()


def make_topics(rng, count=14, subtopics=3):
    """Each topic has its own words and a few subtopics with theirs; some words are shared between topics."""
    syllables = "ba ce di fo gu ka le mi no pu ra se ti vo zu".split()
    used = set()

    def word():
        while True:
            w = "".join(rng.choice(syllables) for _ in range(3))
            if w not in used:
                used.add(w)
                return w

    shared = [word() for _ in range(6)]
    topics = []
    for index in range(count):
        topic_words = [word() for _ in range(5)] + [rng.choice(shared)]
        subs = [[word() for _ in range(4)] for _ in range(subtopics)]
        start = 1 if index < 6 else rng.randint(5, 40)
        topics.append({"id": index, "words": topic_words, "subs": subs, "start": start,
                       "end": start + rng.randint(15, 60)})
    return topics


def make_leaf(rng, topic, sub, leaf_id):
    words = rng.sample(topic["words"], 3) + rng.sample(topic["subs"][sub], 3) + rng.sample(FILLER, 3)
    rng.shuffle(words)
    return {"id": leaf_id, "topic": topic["id"], "sub": sub, "words": words, "text": " ".join(words)}


class Node:
    count = 0

    def __init__(self, parent=None, key=None):
        Node.count += 1
        self.id = Node.count
        self.parent = parent
        self.children = []   # nodes
        self.leaves = []     # leaves held directly
        self.key = list(key or [])
        self.born = 0

    def all_leaves(self):
        if self.leaves:
            return self.leaves
        return [leaf for child in self.children for leaf in child.all_leaves()]

    def size(self):
        return len(self.leaves) if self.leaves else len(self.children)


class Tree:
    def __init__(self, args, merge_at, cap, merging, settle=0):
        self.args, self.merge_at, self.cap, self.merging, self.settle = args, merge_at, cap, merging, settle
        self.moves = 0
        self.root = Node()
        self.df = collections.Counter()   # in how many leaves each word appears
        self.leaf_count = 0
        self.log = []                     # (night, op, ids)
        self.co_use = collections.Counter()
        self.split_from = {}              # half id -> (night, sibling id)
        self.flips = 0

    # Keys are exact: the words of a node's leaves that set it apart, counted, never a guess.
    def rekey(self, node):
        leaves = node.all_leaves()
        if not leaves:
            node.key = []
            return
        counts = collections.Counter(w for leaf in leaves for w in set(leaf["words"]) if w not in FILLER)
        n = len(leaves)
        score = {w: c / n * (1 + (self.leaf_count / (1 + self.df[w])) ** 0.5 / 10) for w, c in counts.items()}
        node.key = [w for w, _ in sorted(score.items(), key=lambda kv: (-kv[1], kv[0]))[:self.args.key]]

    def rekey_up(self, node):
        while node:
            self.rekey(node)
            node = node.parent

    def holders(self, node=None):
        node = node or self.root
        if not node.children:
            return [node]
        return [h for child in node.children for h in self.holders(child)]

    def nodes(self, node=None):
        node = node or self.root
        return [node] + [n for child in node.children for n in self.nodes(child)]

    def insert(self, leaf):
        self.leaf_count += 1
        self.df.update(set(leaf["words"]))
        node = self.root
        while node.children:
            node = max(node.children, key=lambda c: (len(set(c.key) & set(leaf["words"])), -c.id))
        node.leaves.append(leaf)
        self.rekey_up(node)

    def two_means(self, items, words_of):
        """Split items in two by word overlap: seed with the two least alike, then five rounds of reassignment."""
        sets = [set(words_of(item)) - set(FILLER) for item in items]

        def sim(a, b):
            return len(a & b) / (len(a | b) or 1)

        first = 0
        second = min(range(len(items)), key=lambda i: (sim(sets[0], sets[i]), i))
        centers = [collections.Counter(sets[first]), collections.Counter(sets[second])]
        groups = [[], []]
        for _ in range(5):
            groups = [[], []]
            for index, words in enumerate(sets):
                score = [sum(center[w] for w in words) / (sum(center.values()) or 1) for center in centers]
                groups[0 if score[0] >= score[1] else 1].append(index)
            if not groups[0] or not groups[1]:
                half = len(items) // 2
                groups = [list(range(half)), list(range(half, len(items)))]
            centers = [collections.Counter(w for i in g for w in sets[i]) for g in groups]
        return [[items[i] for i in g] for g in groups]

    def split(self, node, night):
        if node.leaves:
            halves = self.two_means(node.leaves, lambda leaf: leaf["words"])
        else:
            halves = self.two_means(node.children, lambda child: child.key)
        made = []
        for half in halves:
            new = Node(key=node.key)   # Net2Net: both halves start as the parent reads
            new.born = night
            if node.leaves:
                new.leaves = half
            else:
                new.children = half
                for child in half:
                    child.parent = new
            made.append(new)
        if node is self.root:
            node.leaves, node.children = [], made
            for new in made:
                new.parent = node
        else:
            parent = node.parent
            parent.children.remove(node)
            for new in made:
                new.parent = parent
                parent.children.append(new)
        for new in made:
            self.rekey(new)
        self.rekey_up(made[0].parent)
        self.split_from[made[0].id] = (night, made[1].id)
        self.split_from[made[1].id] = (night, made[0].id)
        self.log.append((night, "split", node.id, made[0].id, made[1].id))

    def merge(self, a, b, night):
        parent = a.parent
        if a.leaves or b.leaves:
            a.leaves = a.all_leaves() + b.all_leaves()
            a.children = []
        else:
            a.children += b.children
            for child in b.children:
                child.parent = a
        parent.children.remove(b)
        if self.split_from.get(a.id, (None, None))[1] == b.id and night - self.split_from[a.id][0] <= 10:
            self.flips += 1
        self.rekey_up(a)
        self.log.append((night, "merge", a.id, b.id))

    def collapse(self, node, night):
        child = node.children[0]
        parent = node.parent
        parent.children[parent.children.index(node)] = child
        child.parent = parent
        self.log.append((night, "collapse", node.id, child.id))

    def night(self, night):
        changes = 0
        cap = self.cap if self.cap > 0 else 10 ** 9
        # Splits first, biggest first.
        for node in sorted(self.nodes(), key=lambda n: -n.size()):
            if changes >= cap:
                break
            if node.size() > self.args.split:
                self.split(node, night)
                changes += 1
        if self.merging:
            for node in self.nodes():
                if changes >= cap:
                    break
                kids = [c for c in node.children if (c.leaves or not c.children)]
                best = None
                for i, a in enumerate(kids):
                    for b in kids[i + 1:]:
                        together = len(a.all_leaves()) + len(b.all_leaves())
                        alike = len(set(a.key) & set(b.key)) / (len(set(a.key) | set(b.key)) or 1)
                        used = self.co_use[frozenset((a.id, b.id))]
                        if together <= self.merge_at and (alike >= 0.5 or used >= 3):
                            score = (used, alike)
                            if best is None or score > best[0]:
                                best = (score, a, b)
                if best and best[1].parent is node and best[2].parent is node:
                    self.merge(best[1], best[2], night)
                    changes += 1
            for node in self.nodes():
                if changes >= cap:
                    break
                if node is not self.root and len(node.children) == 1 and not node.leaves:
                    self.collapse(node, night)
                    changes += 1
        if self.settle:
            self.settle_leaves()
        if night % 10 == 0:
            self.co_use.clear()
        return changes

    def settle_leaves(self):
        """Move up to `settle` leaves, each to the holder whose key it shares clearly more words with than its own:
        one reassignment step of k-means across the whole tree, so a subtopic split across holders gathers again.
        A move changes no fact, only where a leaf sits, and is logged like any other change."""
        holders = [h for h in self.holders() if h.leaves]
        candidates = []
        if self.args.fit == "affinity":
            counts = {h.id: collections.Counter(w for leaf in h.leaves for w in set(leaf["words"])) for h in holders}

            def fit(words, h, leaf):
                # How much of each word the holder's other leaves hold, on average: a word every one of them has
                # counts 1.
                own = leaf in h.leaves
                n = len(h.leaves) - own
                return sum((counts[h.id][w] - own) / n for w in words) if n > 0 else 0.0
        for holder in holders:
            for leaf in holder.leaves:
                words = set(leaf["words"]) - set(FILLER)
                if self.args.fit == "affinity":
                    here = fit(words, holder, leaf)
                    best = max(holders, key=lambda h: (fit(words, h, leaf), -h.id))
                    gain = fit(words, best, leaf) - here
                    enough = gain >= 1
                else:
                    here = len(words & set(holder.key))
                    best = max(holders, key=lambda h: (len(words & set(h.key)), -h.id))
                    gain = len(words & set(best.key)) - here
                    enough = gain >= 2
                if best is not holder and enough:
                    candidates.append((-gain, leaf["id"], leaf, holder, best))
        for _, _, leaf, source, target in sorted(candidates, key=lambda c: c[:2])[:self.settle]:
            if leaf in source.leaves and len(source.leaves) > 1:
                source.leaves.remove(leaf)
                target.leaves.append(leaf)
                self.moves += 1
        for holder in holders:
            self.rekey_up(holder)

    def answer(self, ask_words):
        """Root down: open children sharing an ask word, best first, at most `beam` per node; read held leaves."""
        opens, chars, found, used = 0, 0, [], []
        frontier = [self.root]
        while frontier:
            node = frontier.pop(0)
            opens += 1
            if node.children:
                chars += sum(len(" ".join(c.key)) + 8 for c in node.children)
                if self.args.reader == "index":
                    # An exact index: a child is opened when one of its leaves shares two words with the ask, so the
                    # tree can rank but never hide (the walk opens every such child, best first).
                    def hits(child):
                        return sum(len(set(leaf["words"]) & ask_words) >= 2 for leaf in child.all_leaves())
                    ranked = sorted(((hits(c), c) for c in node.children), key=lambda pair: (-pair[0], pair[1].id))
                    frontier += [c for count, c in ranked if count > 0]
                else:
                    ranked = sorted(node.children, key=lambda c: (-len(set(c.key) & ask_words), c.id))
                    frontier += [c for c in ranked if set(c.key) & ask_words][:self.args.beam]
            else:
                chars += sum(len(leaf["text"]) + 4 for leaf in node.leaves)
                hits = [leaf for leaf in node.leaves if len(set(leaf["words"]) & ask_words) >= 2]
                if hits:
                    used.append(node.id)
                found += hits
        for i, a in enumerate(used):
            for b in used[i + 1:]:
                self.co_use[frozenset((a, b))] += 1
        return opens, chars, found


def simulate(args):
    rng = random.Random(args.seed)
    topics = make_topics(rng)
    arms = {
        "grow": Tree(args, merge_at=0, cap=args.cap, merging=False),
        "merge": Tree(args, merge_at=args.merge, cap=args.cap, merging=True),
        "churn": Tree(args, merge_at=args.split, cap=0, merging=True),
        "settle": Tree(args, merge_at=args.merge, cap=args.cap, merging=True, settle=args.settle),
    }
    leaves, history = [], []
    for night in range(1, args.nights + 1):
        active = [t for t in topics if t["start"] <= night <= t["end"]]
        for _ in range(args.leaves):
            topic = rng.choice(active)
            leaf = make_leaf(rng, topic, rng.randrange(len(topic["subs"])), len(leaves))
            leaves.append(leaf)
            for tree in arms.values():
                tree.insert(leaf)
        seen = sorted({(leaf["topic"], leaf["sub"]) for leaf in leaves})
        asks = []
        for _ in range(args.asks):
            topic_id, sub = rng.choice(seen)
            topic = topics[topic_id]
            words = set(rng.sample(topic["words"][:5], 2) + rng.sample(topic["subs"][sub], 2))
            target = {leaf["id"] for leaf in leaves if leaf["topic"] == topic_id and leaf["sub"] == sub}
            asks.append((words, target))
        row = {"night": night}
        flat_chars = sum(len(leaf["text"]) + 4 for leaf in leaves)
        # Flat reads every leaf and keeps the ones that share two words with the ask, the same rule the tree's reader
        # uses on the leaves it reads, so recall compares finding, not matching.
        flat_recall = [len({leaf["id"] for leaf in leaves if len(set(leaf["words"]) & words) >= 2} & target)
                       / len(target) for words, target in asks]
        row["flat"] = {"opens": 1, "chars": flat_chars, "recall": statistics.mean(flat_recall), "changes": 0,
                       "nodes": 1}
        for name, tree in arms.items():
            opens, chars, recall = [], [], []
            for words, target in asks:
                o, c, found = tree.answer(words)
                opens.append(o)
                chars.append(c)
                recall.append(len({leaf["id"] for leaf in found} & target) / len(target))
            changes = tree.night(night)
            row[name] = {"opens": statistics.mean(opens), "chars": statistics.mean(chars),
                         "recall": statistics.mean(recall), "changes": changes, "nodes": len(tree.nodes())}
        history.append(row)
    return history, arms


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--nights", type=int, default=60)
    parser.add_argument("--leaves", type=int, default=12)
    parser.add_argument("--asks", type=int, default=8)
    parser.add_argument("--split", type=int, default=24)
    parser.add_argument("--merge", type=int, default=12)
    parser.add_argument("--cap", type=int, default=3)
    parser.add_argument("--beam", type=int, default=2)
    parser.add_argument("--key", type=int, default=6)
    parser.add_argument("--settle", type=int, default=20)
    parser.add_argument("--fit", choices=["key", "affinity"], default="key")
    parser.add_argument("--reader", choices=["key", "index"], default="key")
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args()
    history, arms = simulate(args)
    windows = [(1, 5), (6, 15), (16, 30), (31, 45), (46, args.nights)]
    names = ["flat", "grow", "merge", "churn", "settle"]
    print("opens, tokens (chars / 4), recall per ask; structural changes per night; nodes at the end of the window")
    print(f"{'nights':<8}" + "".join(f"{name:>30}" for name in names))
    for first, last in windows:
        rows = [r for r in history if first <= r["night"] <= last]
        if not rows:
            continue
        cells = []
        for name in names:
            cell = (f"{statistics.mean(r[name]['opens'] for r in rows):.1f}, "
                    f"{statistics.mean(r[name]['chars'] for r in rows) / 4:.0f}, "
                    f"{statistics.mean(r[name]['recall'] for r in rows):.2f}, "
                    f"{statistics.mean(r[name]['changes'] for r in rows):.1f}, {rows[-1][name]['nodes']}")
            cells.append(f"{cell:>30}")
        print(f"{first}-{last:<6}" + "".join(cells))
    for name, tree in arms.items():
        ops = collections.Counter(entry[1] for entry in tree.log)
        print(f"{name}: {dict(ops)}, flips {tree.flips}, leaf moves {tree.moves}")


if __name__ == "__main__":
    main()
