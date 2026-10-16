#!/usr/bin/env python3
"""Kitchen week one: the counts behind docs/product/kitchen-v2-scope.md, read from a store copy.

Usage:  python3 scripts/kitchen-week-one.py <tessera.sqlite or backup.tessera> [--since YYYY-MM-DD]

Reads only. Takes a `.tessera` backup (a plain SQLite copy, TesseraBackup.swift) or the simulator's
Application Support/Tessera/tessera.sqlite. Copy the file first; never point it at the live store.
Prints the bracketed numbers of the Oct 22 message plus the data rows of kitchen-week-one.md.
Standard library only. The capture-miss log (capture-misses.jsonl beside the store) is read when present.
"""

import json
import os
import sqlite3
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

REFERENCE = datetime(2001, 1, 1, tzinfo=timezone.utc)  # Swift's Date epoch (JSONEncoder default)


def swift_date(seconds):
    return REFERENCE + timedelta(seconds=seconds) if seconds is not None else None


def unix_date(seconds):
    return datetime.fromtimestamp(seconds, timezone.utc) if seconds is not None else None


def scalar(value):
    """A FieldValue as Swift's synthesized Codable writes it: {"text": {"_0": "..."}}; tolerate flat forms."""
    if isinstance(value, dict) and len(value) == 1:
        kind, inner = next(iter(value.items()))
        payload = inner.get("_0") if isinstance(inner, dict) else inner
        return kind, payload
    return None, value


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        sys.exit(2)
    path = args[0]
    since = None
    if "--since" in sys.argv:
        since = datetime.fromisoformat(sys.argv[sys.argv.index("--since") + 1]).replace(tzinfo=timezone.utc)

    db = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    db.row_factory = sqlite3.Row

    classes = {r["id"]: r["systemKey"] for r in db.execute("SELECT id, systemKey FROM classDef")}
    class_id = {v: k for k, v in classes.items() if v}
    fields = {r["id"]: (r["ownerID"], r["key"]) for r in db.execute("SELECT id, ownerID, key FROM fieldDef")}

    objects = {}
    by_class = defaultdict(list)
    for r in db.execute("SELECT * FROM object WHERE isClassObject = 0"):
        values = {}
        raw = r["values"]
        if raw:
            try:
                for fid, v in json.loads(raw).items():
                    key = fields.get(fid.upper(), fields.get(fid, (None, fid)))[1]
                    values[key] = scalar(v)
            except (ValueError, AttributeError):
                values["_unreadable"] = (None, True)
        o = {
            "id": r["id"], "cls": classes.get(r["classID"]), "parent": r["parentID"], "title": r["title"],
            "created": unix_date(r["createdAt"]), "deleted": unix_date(r["deletedAt"]), "v": values,
        }
        objects[o["id"]] = o
        by_class[o["cls"]].append(o)

    links = defaultdict(list)  # (fromID, field key) -> [toObjectID]
    for r in db.execute("SELECT fieldID, fromID, toObjectID FROM link WHERE toObjectID IS NOT NULL"):
        key = fields.get(r["fieldID"], (None, None))[1]
        links[(r["fromID"], key)].append(r["toObjectID"])

    def value(o, key, kind=None):
        k, v = o["v"].get(key, (None, None))
        if kind == "date":
            return swift_date(v) if isinstance(v, (int, float)) else None
        return v

    def in_window(d):
        return d is not None and (since is None or d >= since)

    def live(cls):
        return [o for o in by_class.get(cls, []) if o["deleted"] is None]

    # Ops: action, actor, route, created.
    cols = {r[1] for r in db.execute("PRAGMA table_info(op)")}
    route_col = "route" if "route" in cols else "NULL"
    ops = [dict(r) for r in db.execute(f"SELECT action, actor, {route_col} AS route, createdAt, objectIDs FROM op")]
    for op in ops:
        op["created"] = unix_date(op["createdAt"])
        try:
            op["ids"] = json.loads(op["objectIDs"] or "[]")
        except ValueError:
            op["ids"] = []
    ops = [op for op in ops if in_window(op["created"])]

    out = []

    # Recipes saved, and how.
    recipes = [o for o in live("recipe") if in_window(o["created"])]
    create_ops = {i: op for op in ops if op["action"] == "createRecipe" for i in op["ids"]}
    how = Counter()
    for rec in recipes:
        op = create_ops.get(rec["id"])
        route = (op or {}).get("route") or ""
        source = (value(rec, "sourceText") or "")
        if value(rec, "sourceURL"):
            how["link"] += 1
        elif route == "claude" or (op and op["actor"] == "tess"):
            how["ghost row"] += 1
        elif source.strip():
            how["pasted"] += 1
        else:
            how["other"] += 1
    out.append(f"Recipes saved: {len(recipes)} ({', '.join(f'{v} {k}' for k, v in how.items()) or 'none'})")
    edits = sum(1 for op in ops if op["action"] == "editRecipe")
    out.append(f"Recipe edits after saving (editRecipe ops): {edits}")
    opened_not_cooked = [r for r in live("recipe") if value(r, "lastOpenedAt", "date")
                         and not any(r["id"] in links[(c["id"], "recipe")] for c in live("cook"))]
    out.append(f"Recipes opened but never cooked: {len(opened_not_cooked)}"
               + (": " + ", ".join(r["title"] for r in opened_not_cooked[:8]) if opened_not_cooked else ""))

    # Cooks.
    cooks = [o for o in live("cook") if in_window(o["created"])]
    finished = [c for c in cooks if value(c, "cookedAt", "date")]
    processes = live("process")
    kitchen_procs = [p for p in processes if value(p, "ownerApp") == "Kitchen"]
    cook_ids = {c["id"] for c in cooks}
    cook_procs = [p for p in kitchen_procs if set(links[(p["id"], "subject")]) & cook_ids]
    ends = Counter(value(p, "endReason") or value(p, "state") or "?" for p in cook_procs)
    out.append(f"Cooks: {len(cooks)} started, {len(finished)} finished; cook processes by end: "
               + (", ".join(f"{k} {v}" for k, v in ends.items()) or "none"))

    # Timers.
    timers = [o for o in live("kitchenTimer") if in_window(o["created"])]
    stop_ops = {i: op for op in ops if op["action"] == "stopKitchenTimer" for i in op["ids"]}
    early = 0
    for t in timers:
        ends_at = value(t, "endsAt", "date")
        op = stop_ops.get(t["id"])
        if op and ends_at and op["created"] < ends_at - timedelta(seconds=30):
            early += 1
    per_cook = Counter(links[(t["id"], "cook")][0] for t in timers if links[(t["id"], "cook")])
    out.append(f"Timers: {len(timers)} ({early} stopped early); per cook: "
               + (", ".join(str(n) for n in per_cook.values()) or "none"))

    # Groceries items by source.
    groceries = next((l for l in live("list") if l["title"].lower() == "groceries"), None)
    items = [o for o in live("listItem") if groceries and o["parent"] == groceries["id"] and in_window(o["created"])]
    source = Counter()
    typed_staples = 0
    ingredient_by_id = {i["id"]: i for i in live("ingredient")}
    for it in items:
        try:
            shares = json.loads(value(it, "shares") or "[]")
        except ValueError:
            shares = []
        recipe_shares = [s for s in shares if s.get("recipe")]
        if recipe_shares:
            source["recipe"] += 1
        else:
            source["typed"] += 1
            ing = next((ingredient_by_id[i] for i in links[(it["id"], "about")] if i in ingredient_by_id), None)
            if ing and value(ing, "isStaple") is True:
                typed_staples += 1
    out.append(f"Grocery items: {len(items)} ({source['recipe']} from recipes, {source['typed']} typed, "
               f"{typed_staples} typed staples)")
    add_ops = Counter(op["actor"] + ("/" + op["route"] if op["route"] else "") for op in ops if op["action"] == "addGroceries")
    out.append("addGroceries by actor: " + (", ".join(f"{k} {v}" for k, v in add_ops.items()) or "none"))

    # Struck then unstruck, removed straight after adding.
    toggles = [op for op in ops if op["action"] == "checkListItem"]
    out.append(f"Item check/uncheck ops: {len(toggles)} (read pairs by hand if more than 0)")

    # Shops.
    shops = [op for op in ops if op["action"] == "startShop"]
    finished_shops = [op for op in ops if op["action"] == "finishShop"]
    out.append(f"Shops: {len(shops)} started with the title hold, {len(finished_shops)} finished")

    # Planned cooks.
    recipe_ids = {r["id"] for r in live("recipe")}
    planned = [t for t in live("task") if set(links[(t["id"], "about")]) & recipe_ids and in_window(t["created"])]
    cooked_recipes = {rid for c in live("cook") for rid in links[(c["id"], "recipe")]}
    planned_cooked = [t for t in planned if set(links[(t["id"], "about")]) & cooked_recipes]
    out.append(f"Planned cooks (tasks linking a recipe): {len(planned)}, of which cooked: {len(planned_cooked)}")

    # Capture misses.
    miss_path = os.path.join(os.path.dirname(os.path.abspath(path)), "capture-misses.jsonl")
    if os.path.exists(miss_path):
        misses = [json.loads(l) for l in open(miss_path) if l.strip()]
        by_source = Counter(m.get("source", "?") for m in misses)
        links_pasted = sum(1 for m in misses if m.get("text", "").startswith("http"))
        out.append(f"Capture misses: {len(misses)} ({', '.join(f'{k} {v}' for k, v in by_source.items())}; "
                   f"{links_pasted} were links)")
    else:
        out.append("Capture misses: no capture-misses.jsonl beside the store (it never rides in a backup)")

    print("\n".join(out))


if __name__ == "__main__":
    main()
