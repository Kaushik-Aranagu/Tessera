#!/usr/bin/env python3
"""Kitchen week one: the counts behind docs/product/kitchen-v2-scope.md, read from a store copy.

Usage:  python3 scripts/kitchen-week-one.py <tessera.sqlite or backup.tessera> [--since YYYY-MM-DD] [--titles]
        python3 scripts/kitchen-week-one.py --self-test

Private filter (docs/product/kitchen-week-one-private-filter.md): only the classes the counts need are read (never
Note, Event, Training, body or money fields). No title is printed unless --titles is given, and then a private title
(secret-worded, or shaped like money or a body measure) prints as "Private recipe". A path under Application Support
is refused: copy the store first.

Reads only. Takes a `.tessera` backup (a plain SQLite copy, TesseraBackup.swift) or the simulator's
Application Support/Tessera/tessera.sqlite. Copy the file first; never point it at the live store.
Prints the bracketed numbers of the Oct 22 message plus the data rows of kitchen-week-one.md.
Standard library only. The capture-miss log (capture-misses.jsonl beside the store) is read when present.
"""

import hashlib
import io
import json
import os
import re
import shutil
import sqlite3
import tempfile
import urllib.parse
import contextlib
import sys
import uuid
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

READ_CLASSES = {"recipe", "cook", "kitchenTimer", "process", "listItem", "ingredient", "task"}  # PF1

# Mirrors TesseraCore SecretWords (Notes/SecretWords.swift); keep the two in step until Core exports the list (open 1).
SECRET_WORDS = {"password", "passwords", "passcode", "passcodes", "pin", "pins", "code", "codes", "combo",
                "combination", "passphrase", "pw", "pwd"}
PRIVATE_RECIPE = "Private recipe"
PRIVATE_ITEM = "Private item"
# Mirrors PrivateFacts.moneyWords (Tess/PrivateFacts.swift) plus TessMemoryScreen.moneyWords.
MONEY_WORDS = {"usd", "dollar", "dollars", "bucks", "buck", "gbp", "pound", "pounds", "quid", "tenner", "fiver", "eur",
               "euro", "euros", "inr", "rs", "rupee", "rupees", "cad", "aud", "chf", "jpy", "yen", "spend", "spent",
               "paid", "pay", "cost", "costs", "price", "refund", "refunded", "tip", "tipped", "venmo", "venmoed",
               "zelle", "zelled", "paypal", "owe", "owes", "balance", "checking", "savings", "salary", "paycheck",
               "copay", "rent", "invoice"}
BODY_UNIT = re.compile(r"\d\s*(kg|kgs|lb|lbs|cm|bpm|kcal|%)(\W|$)", re.I)


def _tokens(text):
    text = (text or "").lower().replace(":", " : ")
    return [t.strip(".,!?;'\"()") for t in text.split() if t.strip(".,!?;'\"()")]


def is_private_title(text):
    """PF4/PF5/PF7: secret-worded (SecretWords.mentions), or shaped like money or a body measure."""
    tokens = _tokens(text)
    for i, t in enumerate(tokens):
        if t in SECRET_WORDS or (t == "wifi" and i + 1 < len(tokens) and tokens[i + 1] in (":", "is")):
            return True
    lower = (text or "").lower()
    no_times = re.sub(r"\b\d{1,2}:\d{2}\s*(?:am|pm)?|\b\d{1,2}\s*(?:am|pm)\b", " ", lower)
    words = [w.strip(".,-") for w in re.split(r"[^\w.,-]+", no_times) if w.strip(".,-")]
    if any(w[0].isdigit() for w in words) and any(w in MONEY_WORDS for w in words):  # "Paid 40", "spent 12"
        return True
    if re.search(r"[$\u20b9\u20ac\u00a3\u00a5]", text or "") or BODY_UNIT.search(text or ""):
        return True
    return any(re.fullmatch(r"\d[\d,.]{2,}", t) for t in tokens)  # "Rent 1200": a 3+ digit amount


def shown_title(text, stand_in):
    return stand_in if is_private_title(text) else (text or "")


PACIFIC = ZoneInfo("America/Los_Angeles")

REFERENCE = datetime(2001, 1, 1, tzinfo=timezone.utc)  # Swift's Date epoch (JSONEncoder default)


def swift_date(seconds):
    return REFERENCE + timedelta(seconds=seconds) if seconds is not None else None


def unix_date(seconds):
    return datetime.fromtimestamp(seconds, timezone.utc) if seconds is not None else None


def stable_id(name):
    """SystemCatalog.stableID: a UUIDv5-shaped id from SHA-256 of "tessera:<name>"."""
    b = bytearray(hashlib.sha256(f"tessera:{name}".encode()).digest()[:16])
    b[6] = (b[6] & 0x0F) | 0x50
    b[8] = (b[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(b))).upper()


GROCERIES_ID = stable_id("kitchen.groceries")


def value_pairs(raw):
    """FieldValues as stored: a JSON object keyed by field id, or the older flat [id, value, id, value] array."""
    data = json.loads(raw)
    if isinstance(data, dict):
        return list(data.items())
    if isinstance(data, list):
        return list(zip(data[::2], data[1::2]))
    raise ValueError("values is neither an object nor an array")


def scalar(value):
    """A FieldValue as Swift's synthesized Codable writes it: {"text": {"_0": "..."}}; tolerate flat forms."""
    if isinstance(value, dict) and len(value) == 1:
        kind, inner = next(iter(value.items()))
        payload = inner.get("_0") if isinstance(inner, dict) else inner
        return kind, payload
    return None, value


def main():
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("--") and not re.fullmatch(r"\d{4}-\d\d-\d\d", a)]
    if not args:
        print(__doc__)
        sys.exit(2)
    path = args[0]
    if "application support" in os.path.realpath(path).lower():  # PF12
        sys.exit("Refusing a store under Application Support: copy the file somewhere else and point the script at the copy.")
    with_titles = "--titles" in sys.argv
    since = None
    if "--since" in sys.argv:
        # Midnight Pacific on that date (his day), not UTC.
        since = datetime.fromisoformat(sys.argv[sys.argv.index("--since") + 1]).replace(tzinfo=PACIFIC)

    db = sqlite3.connect(f"file:{urllib.parse.quote(os.path.abspath(path))}?mode=ro", uri=True)
    db.row_factory = sqlite3.Row

    # systemKey is stored as "system.recipe"; the script speaks in bare keys.
    classes = {r["id"]: (r["systemKey"] or "").removeprefix("system.") or None
               for r in db.execute("SELECT id, systemKey FROM classDef")}
    if "recipe" not in classes.values():
        sys.exit(f"{path}: no Recipe class in classDef; not a Tessera store, or one from before the kitchen shipped")
    fields = {r["id"]: (r["ownerID"], r["key"]) for r in db.execute("SELECT id, ownerID, key FROM fieldDef")}

    objects = {}
    by_class = defaultdict(list)
    unreadable = 0
    read_ids = [cid for cid, key in classes.items() if key in READ_CLASSES]
    marks = ",".join("?" * len(read_ids))
    for r in db.execute(f"SELECT * FROM object WHERE isClassObject = 0 AND classID IN ({marks})", read_ids):  # PF1
        values = {}
        raw = r["values"]
        if raw:
            try:
                for fid, v in value_pairs(raw):
                    key = fields.get(str(fid).upper(), (None, str(fid)))[1]
                    values[key] = scalar(v)
            except (ValueError, TypeError, AttributeError):
                unreadable += 1
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
    if unreadable:
        out.append(f"WARNING: {unreadable} objects had values this script could not read; counts below may be low")

    # Recipes saved, and how.
    recipes = [o for o in live("recipe") if in_window(o["created"])]
    create_ops = {i: op for op in ops if op["action"] == "createRecipe" for i in op["ids"]}
    how = Counter()
    for rec in recipes:
        op = create_ops.get(rec["id"])
        route = (op or {}).get("route") or ""
        source = (value(rec, "sourceText") or "")
        if route == "claude" or (op and op["actor"] == "tess"):
            how["ghost row"] += 1
        elif source.strip():
            how["pasted or from a link"] += 1
        else:
            how["other"] += 1
    out.append(f"Recipes saved: {len(recipes)} ({', '.join(f'{v} {k}' for k, v in how.items()) or 'none'})")
    # A link recipe is saved through the paste screen as text and the store keeps no URL (Recipes.swift), so
    # paste and link can't be told apart here; the capture-miss log below counts links that failed to read.
    edits = sum(1 for op in ops if op["action"] == "editRecipe")
    out.append(f"Recipe edits after saving (editRecipe ops): {edits}")
    opened_not_cooked = [r for r in live("recipe") if value(r, "lastOpenedAt", "date")
                         and not any(r["id"] in links[(c["id"], "recipe")] for c in live("cook"))]
    line = f"Recipes opened but never cooked: {len(opened_not_cooked)}"
    if with_titles and opened_not_cooked:  # PF2/PF3: titles only on request, private ones replaced
        line += ": " + ", ".join(shown_title(r["title"], PRIVATE_RECIPE) for r in opened_not_cooked[:8])
    out.append(line)

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
    # The built-in list has a stable id (Groceries.listID), whatever he renames it to.
    items = [o for o in live("listItem") if (o["parent"] or "").upper() == GROCERIES_ID and in_window(o["created"])]
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
            if ing and value(ing, "isStaple") is True and not is_private_title(it["title"]) \
                    and it["title"] != PRIVATE_ITEM:  # PF7: a private line gets no staple credit
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

    return "\n".join(out).replace("$", "")  # PF10: no amount ever prints


def self_test():
    """Builds a fixture store from made-up rows and checks the filter against it (PF2 to PF10, PF12)."""
    now = (datetime.now(timezone.utc) - REFERENCE).total_seconds()
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "fixture.sqlite")
        db = sqlite3.connect(path)
        db.executescript("""
            CREATE TABLE classDef(id TEXT, systemKey TEXT);
            CREATE TABLE fieldDef(id TEXT, ownerID TEXT, key TEXT);
            CREATE TABLE object(id TEXT, classID TEXT, parentID TEXT, title TEXT, createdAt REAL, deletedAt REAL,
                                "values" TEXT, isClassObject INTEGER);
            CREATE TABLE link(fieldID TEXT, fromID TEXT, toObjectID TEXT);
            CREATE TABLE op(action TEXT, actor TEXT, createdAt REAL, objectIDs TEXT);
        """)
        for cid, key in [("C1", "system.recipe"), ("C2", "system.listItem"), ("C3", "system.note")]:
            db.execute("INSERT INTO classDef VALUES(?,?)", (cid, key))
        db.execute("INSERT INTO fieldDef VALUES('F1','C1','lastOpenedAt')")
        opened = json.dumps({"F1": {"date": {"_0": now}}})
        titles = ["Tacos", "Private recipe", "Door code 4417 soup", "Rent 1200", "Weight 80 kg", "Pay $40 pasta"]
        for n, t in enumerate(titles):
            db.execute("INSERT INTO object VALUES(?,?,?,?,?,NULL,?,0)", (f"R{n}", "C1", None, t, now, opened))
        db.execute("INSERT INTO object VALUES('RD','C1',NULL,'Deleted secret pin 9',?,?,?,0)", (now, now, opened))
        for n, t in enumerate(["Milk", "Private item", "wifi password hunter2"]):
            db.execute("INSERT INTO object VALUES(?,?,?,?,?,NULL,NULL,0)", (f"L{n}", "C2", GROCERIES_ID, t, now))
        db.execute("INSERT INTO object VALUES('N1','C3',NULL,'Note about my salary',?,NULL,NULL,0)", (now,))
        db.commit()
        db.close()
        before = hashlib.sha256(open(path, "rb").read()).hexdigest()

        def run(*extra):
            sys.argv = ["kitchen-week-one.py", path, *extra]
            return main()

        plain, with_titles = run(), run("--titles")
        after = hashlib.sha256(open(path, "rb").read()).hexdigest()
        failures = []

        def check(ok, what):
            print(("ok   " if ok else "FAIL ") + what)
            if not ok:
                failures.append(what)

        check("Recipes saved: 6" in plain and "Recipes opened but never cooked: 6" in plain, "counts include every live recipe, not the deleted one")
        check("Tacos" not in plain, "no title without --titles (PF2)")
        for secret in ["Door code", "4417", "Rent", "1200", "Weight", "80 kg", "Pay", "40", "pin 9", "hunter2", "Milk", "salary"]:
            check(secret not in plain and secret not in with_titles, f"{secret!r} never printed (PF4/5/6/7/10/13)")
        check("Tacos" in with_titles and with_titles.count(PRIVATE_RECIPE) == 5, "--titles shows Tacos and 5 stand-ins (PF3)")
        check("Grocery items: 3 (0 from recipes, 3 typed, 0 typed staples)" in plain, "grocery items counted, none named (PF6)")
        check("$" not in plain + with_titles, "no $ in output (PF10)")
        check(before == after, "store file unchanged (PF12)")
        swift = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "TesseraCore", "Sources", "TesseraCore",
                             "Notes", "SecretWords.swift")
        decl = re.search(r"public\s+static\s+let\s+words\s*:\s*Set<String>\s*=\s*\[(.*?)\]", open(swift).read(), re.S)
        core = set(re.findall(r'"([^"]+)"', decl.group(1))) if decl else set()
        check(bool(core), f"found {len(core)} words in Core's SecretWords.words")
        check(core == SECRET_WORDS, f"word list matches Core (missing {sorted(core - SECRET_WORDS)}, extra {sorted(SECRET_WORDS - core)})")
        link = os.path.join(tmp, "Application Support", "Tessera")
        os.makedirs(link)
        shutil.copy(path, os.path.join(link, "tessera.sqlite"))
        elsewhere = os.path.join(tmp, "innocent.sqlite")
        os.symlink(os.path.join(link, "tessera.sqlite"), elsewhere)
        try:
            sys.argv = ["x", elsewhere]
            main()
            check(False, "symlink into Application Support refused")
        except SystemExit as e:
            check("Application Support" in str(e), "symlink into Application Support refused (realpath)")
        for t in ["Paid 40", "spent 12", "Lunch \u20b9250", "Dinner 6.25"]:
            check(is_private_title(t), f"{t!r} is money-shaped")
        check(not is_private_title("Tacos 3pm") and not is_private_title("Pizza"), "plain titles stay plain")
        try:
            sys.argv = ["x", "/Users/someone/Library/Application Support/Tessera/tessera.sqlite"]
            main()
            check(False, "live path refused")
        except SystemExit as e:
            check("Application Support" in str(e), "live Application Support path refused (PF12)")
        code = open(__file__).read().split("def self_test")[0]
        tables = {t.lower() for t in re.findall(r"\b(?:FROM|JOIN)\s+(\w+)", code)}
        check(tables <= {"classdef", "fielddef", "object", "link", "op"}, f"queries touch only known tables: {sorted(tables)}")
        check(re.search(r"FROM object WHERE[^\n]*classID IN", code) is not None, "object query is limited by classID IN")
        check(not re.search(r"""["'](?:note|event|training|bodyWeight)["']""", code), "no note/event/training class named in code")
        print("\n--- sample output with --titles ---\n" + with_titles)
        sys.exit(1 if failures else 0)


if __name__ == "__main__":
    result = main()
    if result:
        print(result)
