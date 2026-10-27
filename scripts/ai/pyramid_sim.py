#!/usr/bin/env python3
"""P3 prototype for the memory pyramid (docs/ai/harness/memory-pyramid.md): the backward pass, simulated.

No model and no API call: a seeded made-up year of training and cooking, a pyramid over it (day, week, month, year,
root) with exact totals and residuals as in MemoryPyramid.swift, and a reader whose answers are checked exactly.
Each night the reader answers a stream of asks; what it had to dig for is promoted up the tree, and what nobody uses
sinks back down. It reports, per night, how many nodes a reader opened and how many tokens it read per ask, for:

  flat       every leaf under the asked node, read at once
  static     the pyramid as P1 builds it: totals and residuals, digging when a node lacks the fact
  per-node   the backward pass, promoting a fact onto the one node it was dug for after k digs there
  shared     the backward pass with weights shared per level: k digs for a kind of fact at a level promote it onto
             every node of that level (a level's shared parameter, each node's line computed exactly)

Usage: python3 scripts/ai/pyramid_sim.py [--nights 60] [--asks 8] [--k 3] [--budget 3] [--forget 30] [--seed 1]
       [--shift 30] [--json PATH]
--shift N: from night N he stops asking about recipes, to show a promoted line sinking once nobody uses it.
"""
import argparse
import collections
import datetime as dt
import json
import random
import statistics

ROUTINES = ["Push A", "Pull A", "Legs", "Push B", "Pull B"]
RECIPES = ["Chili", "Dal", "Pasta", "Stir fry", "Tacos", "Curry", "Soup", "Omelette"]
EXERCISES = {"Push A": "Bench", "Pull A": "Row", "Legs": "Squat", "Push B": "Press", "Pull B": "Deadlift"}
NOTES = ["Call the bank", "Pack the charger", "Buy oats", "Plan the week", "Fix the shelf", "Book a haircut"]


def make_world(rng, end=dt.date(2026, 10, 23), days=365):
    """Leaves: (date, kind, text, stats). A month favors one routine and one recipe, so 'most' differs by month."""
    leaves = []
    start = end - dt.timedelta(days=days - 1)
    favorite_routine, favorite_recipe = {}, {}
    for offset in range(days):
        day = start + dt.timedelta(days=offset)
        month = (day.year, day.month)
        favorite_routine.setdefault(month, rng.choice(ROUTINES))
        favorite_recipe.setdefault(month, rng.choice(RECIPES))
        if rng.random() < 0.58:
            routine = favorite_routine[month] if rng.random() < 0.45 else rng.choice(ROUTINES)
            sets = rng.randint(8, 18)
            if rng.random() < 0.05:
                leaves.append((day, "workout", "Private workout", {}))
            else:
                weight = rng.choice([60, 70, 80, 90, 100])
                text = f"{routine}: {EXERCISES[routine]} {weight} kg x5, {sets} sets"
                leaves.append((day, "workout", text, {"workouts": 1, "sets": sets}))
        if rng.random() < 0.42:
            recipe = favorite_recipe[month] if rng.random() < 0.5 else rng.choice(RECIPES)
            leaves.append((day, "cook", f"Cooked {recipe}", {"cooks": 1}))
        if rng.random() < 0.3:
            leaves.append((day, "note", rng.choice(NOTES), {"notes": 1}))
    return leaves


LABELS = {"workouts": "workouts", "sets": "sets", "cooks": "meals cooked", "notes": "notes"}


class Node:
    def __init__(self, path, level, title):
        self.path, self.level, self.title = path, level, title
        self.children, self.leaves, self.stats, self.residuals = [], [], collections.Counter(), {}

    def leaf_text(self):
        return [text for _, _, text, _ in self.leaves]


def build(leaves):
    nodes = {}

    def node(path, level, title):
        if path not in nodes:
            nodes[path] = Node(path, level, title)
        return nodes[path]

    root = node("/time", "root", "Everything")
    for leaf in sorted(leaves, key=lambda leaf: leaf[0]):
        day, _, _, stats = leaf
        year = node(f"/time/{day.year}", "year", str(day.year))
        month = node(f"/time/{day.year}/{day.month:02}", "month", day.strftime("%B %Y"))
        iso = day.isocalendar()
        week = node(f"/time/{iso[0]}/w{iso[1]:02}", "week", f"Week {iso[1]}, {iso[0]}")
        d = node(f"{month.path}/{day.day:02}", "day", day.strftime("%a, %b %-d, %Y"))
        d.date = day
        d.leaves.append(leaf)
        for parent, child in ((root, year), (year, month), (month, d), (week, d)):
            if child.path not in parent.children:
                parent.children.append(child.path)
        for n in (root, year, month, week, d):
            n.stats.update(stats)
            if n is not d:
                n.leaves.append(leaf)
    for n in nodes.values():
        kids = [nodes[c] for c in n.children]
        if len(kids) < 3:
            continue
        for key in LABELS:
            values = [k.stats[key] for k in kids]
            mean = statistics.mean(values)
            spread = statistics.pstdev(values)
            if mean <= 0 or spread <= 0:
                continue
            for word, best in (("most", max(values)), ("fewest", min(values))):
                if values.count(best) != 1:
                    continue
                kid = kids[values.index(best)]
                line = f"{word} {LABELS[key]} ({best})"
                n.residuals.setdefault(kid.path, []).append((abs(best - mean) / spread, line))
    return nodes


# Facts the engine can compute exactly for any node, by kind. A promoted line is one of these, never a model's guess.
def fact(kind, node, nodes):
    workouts = [t for _, k, t, _ in node.leaves if k == "workout" and t != "Private workout"]
    cooks = [t[len("Cooked "):] for _, k, t, _ in node.leaves if k == "cook"]
    if kind == "top_routine":
        counts = collections.Counter(t.split(":")[0] for t in workouts)
        return leader(counts, "most done routine")
    if kind == "top_recipe":
        return leader(collections.Counter(cooks), "most cooked")
    if kind.startswith("last:"):
        routine = kind[5:]
        days = [d for d, k, t, _ in node.leaves if k == "workout" and t.startswith(routine + ":")]
        return f"last {routine}: {max(days):%b %-d}" if days else None
    return None


def leader(counts, label):
    if not counts:
        return None
    best = max(counts.values())
    top = [name for name, count in counts.items() if count == best]
    return f"{label}: {top[0]} ({best})" if len(top) == 1 else None


def zoom(node, nodes, promoted):
    lines = [f"{node.title} ({node.path})"]
    lines.append("Totals: " + ", ".join(f"{LABELS[k]} {node.stats[k]}" for k in LABELS if node.stats[k]))
    lines += [line for line in promoted]
    if node.level == "day":
        lines += [f"{node.path}/leaf: {t}" for t in node.leaf_text()]
    else:
        ranked = sorted(node.residuals.items(), key=lambda item: -max(score for score, _ in item[1]))
        for path, residuals in ranked[:8]:
            lines.append(f"{path}: " + "; ".join(text for _, text in sorted(residuals, reverse=True)[:2]))
        rest = len(node.children) - min(8, len(ranked))
        if rest > 0:
            lines.append(f"{rest} more under it")
    return "\n".join(lines)[:1200]


class Reader:
    """Answers one ask by opening nodes. Counts every open and every character read."""

    def __init__(self, nodes, promoted_for):
        self.nodes, self.promoted_for = nodes, promoted_for
        self.opens = self.chars = 0

    def read(self, path):
        node = self.nodes[path]
        text = zoom(node, self.nodes, self.promoted_for(node))
        self.opens += 1
        self.chars += len(text)
        return text


def answer(ask, nodes, promoted_for):
    """Returns (opens, chars, dug, correct). `dug` is the (node, kind) the answer had to be dug below."""
    reader = Reader(nodes, promoted_for)
    kind, target, expected = ask
    text = reader.read(target)
    node = nodes[target]
    if kind in ("day_routine", "day_sets", "month_workouts", "week_workouts"):
        return reader.opens, reader.chars, None, expected in text
    if kind == "month_most_sets":
        if any(line.startswith(expected + ":") and "most sets" in line for line in text.splitlines()):
            return reader.opens, reader.chars, None, True
        # Not among the lines shown: open every day and compare.
        for child in node.children:
            reader.read(child)
        return reader.opens, reader.chars, (target, kind), True
    if kind in ("top_routine", "top_recipe") or kind.startswith("last:"):
        if expected in text:
            return reader.opens, reader.chars, None, True
        if kind.startswith("last:"):
            # Newest first: months, then days, until the routine shows up.
            for year in sorted(node.children, reverse=True):
                reader.read(year)
                for month in sorted(nodes[year].children, reverse=True):
                    reader.read(month)
                    for day in sorted(nodes[month].children, reverse=True):
                        if any(t.startswith(kind[5:] + ":") for t in nodes[day].leaf_text()):
                            reader.read(day)
                            return reader.opens, reader.chars, (target, kind), True
            return reader.opens, reader.chars, (target, kind), False
        # Count across the days that hold one.
        word = "workout" if kind == "top_routine" else "cook"
        for child in node.children:
            if any(k == word for _, k, _, _ in nodes[child].leaves):
                reader.read(child)
        return reader.opens, reader.chars, (target, kind), True
    raise ValueError(kind)


def flat(ask, nodes):
    _, target, expected = ask
    text = "\n".join(f"{d}: {t}" for d, _, t, _ in nodes[target].leaves)
    return 1, len(text)


def make_ask(rng, nodes, night, shift):
    days = [n for n in nodes.values() if n.level == "day"]
    months = sorted((n for n in nodes.values() if n.level == "month"), key=lambda n: n.path)
    weeks = [n for n in nodes.values() if n.level == "week"]
    kinds = ["day_routine", "day_sets", "month_workouts", "week_workouts", "month_most_sets", "top_routine",
             "top_recipe", "last"]
    weights = [3, 2, 2, 1, 2, 3, 0 if night >= shift else 3, 2]
    kind = rng.choices(kinds, weights)[0]
    # Recent things are asked about more.
    month = months[min(len(months) - 1, int(len(months) * (1 - rng.random() ** 2)))]
    if kind in ("day_routine", "day_sets"):
        day = rng.choice([nodes[c] for c in month.children])
        workouts = [t for _, k, t, _ in day.leaves if k == "workout" and t != "Private workout"]
        if not workouts:
            return None
        expected = workouts[0].split(":")[0] if kind == "day_routine" else f"sets {day.stats['sets']}"
        return kind, day.path, expected
    if kind == "month_workouts":
        return kind, month.path, f"workouts {month.stats['workouts']}"
    if kind == "week_workouts":
        week = rng.choice(weeks)
        return kind, week.path, f"workouts {week.stats['workouts']}"
    if kind == "month_most_sets":
        kids = [nodes[c] for c in month.children]
        best = max(k.stats["sets"] for k in kids)
        top = [k for k in kids if k.stats["sets"] == best]
        return (kind, month.path, top[0].path) if len(top) == 1 else None
    if kind in ("top_routine", "top_recipe"):
        line = fact(kind, month, nodes)
        return (kind, month.path, line) if line else None
    routine = rng.choice(ROUTINES)
    line = fact("last:" + routine, nodes["/time"], nodes)
    return ("last:" + routine, "/time", line) if line else None


def simulate(args):
    rng = random.Random(args.seed)
    nodes = build(make_world(rng))
    level_of = {path: n.level for path, n in nodes.items()}
    arms = ["flat", "static", "per-node", "shared"]
    # Promotion state per arm: which fact kinds a node (per-node) or a level (shared) shows, with last-use night.
    node_lines = collections.defaultdict(dict)     # per-node: path -> {kind: last night used}
    level_lines = collections.defaultdict(dict)    # shared: level -> {kind: last night used}
    node_digs = collections.Counter()
    level_digs = collections.Counter()

    def lines(kinds, node):
        out = []
        for kind in kinds:
            line = fact(kind, node, nodes)
            if line:
                out.append(line)
        return out

    def family(kind):
        return "last" if kind.startswith("last:") else kind

    def level_kinds(node):
        shown = level_lines[node.level]
        # A shared "last" line fans out to every routine at that level.
        kinds = [k for k in shown if k != "last"] + (["last:" + r for r in ROUTINES] if "last" in shown else [])
        return lines(kinds, node)

    history = []
    for night in range(1, args.nights + 1):
        asks = []
        while len(asks) < args.asks:
            ask = make_ask(rng, nodes, night, args.shift)
            if ask:
                asks.append(ask)
        row = {"night": night}
        for arm in arms:
            opens, chars, correct = [], [], 0
            for ask in asks:
                if arm == "flat":
                    o, c = flat(ask, nodes)
                    opens.append(o)
                    chars.append(c)
                    correct += 1
                    continue
                if arm == "static":
                    promoted = lambda node: []
                elif arm == "per-node":
                    promoted = lambda node: lines(node_lines[node.path], node)
                else:
                    promoted = level_kinds
                o, c, dug, ok = answer(ask, nodes, promoted)
                opens.append(o)
                chars.append(c)
                correct += ok
                kind, target, _ = ask
                # Every use of a promoted line refreshes it.
                if arm == "per-node" and kind in node_lines[target]:
                    node_lines[target][kind] = night
                if arm == "shared" and family(kind) in level_lines[level_of[target]]:
                    level_lines[level_of[target]][family(kind)] = night
                if dug and arm == "per-node":
                    node_digs[dug] += 1
                    if node_digs[dug] >= args.k:
                        node_lines[target][kind] = night
                if dug and arm == "shared":
                    key = (level_of[target], family(kind))
                    level_digs[key] += 1
                    if level_digs[key] >= args.k:
                        level_lines[key[0]][key[1]] = night
            row[arm] = {"opens": statistics.mean(opens), "tokens": statistics.mean(chars) / 4,
                        "accuracy": correct / len(asks)}
        # Night pass: demote lines unused for `forget` nights, then keep at most `budget` per level, freshest first.
        for shown in list(level_lines.values()) + list(node_lines.values()):
            for kind, last in list(shown.items()):
                if night - last >= args.forget:
                    del shown[kind]
            while len(shown) > args.budget:
                del shown[min(shown, key=shown.get)]
        row["shared_lines"] = {level: sorted(shown) for level, shown in level_lines.items() if shown}
        history.append(row)
    return history


def window(history, arm, field, first, last):
    rows = [r[arm][field] for r in history if first <= r["night"] <= last]
    return statistics.mean(rows) if rows else float("nan")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nights", type=int, default=60)
    parser.add_argument("--asks", type=int, default=8)
    parser.add_argument("--k", type=int, default=3)
    parser.add_argument("--budget", type=int, default=3)
    parser.add_argument("--forget", type=int, default=30)
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--shift", type=int, default=30)
    parser.add_argument("--json")
    args = parser.parse_args()
    history = simulate(args)
    print(f"{'nights':<10}" + "".join(f"{arm:>22}" for arm in ["flat", "static", "per-node", "shared"]))
    for first, last in ((1, 1), (2, 5), (6, 10), (11, 29), (30, 45), (46, 60)):
        if first > args.nights:
            break
        cells = []
        for arm in ["flat", "static", "per-node", "shared"]:
            opens = window(history, arm, "opens", first, last)
            tokens = window(history, arm, "tokens", first, last)
            cells.append(f"{opens:5.1f} op {tokens:6.0f} tk")
        print(f"{first:>3}-{last:<6}" + "".join(f"{c:>22}" for c in cells))
    print("accuracy (all nights):", {arm: round(window(history, arm, 'accuracy', 1, args.nights), 3)
                                     for arm in ["flat", "static", "per-node", "shared"]})
    for night in (5, 29, args.nights):
        if night <= args.nights:
            print(f"shared lines after night {night}:", history[night - 1]["shared_lines"])
    if args.json:
        with open(args.json, "w") as out:
            json.dump(history, out, indent=1, default=str)


if __name__ == "__main__":
    main()
