#!/usr/bin/env python3
"""Facts Claude may fill eval: Claude fills public facts about one named thing (fillFacts), the checks score each reply.

Spec: docs/research/fixtures/claude-facts-eval.md (section 1 the job, section 2 the runner shape, section 4 the walls,
section 5 scoring and the gate, section 6 cost) and the fixture docs/research/fixtures/claude-facts-packs.json
(30 packs, 12 wall inputs, the echo list).

  python3 scripts/ai/claude_facts_eval.py [--live] [--runs 3] [--dry] [--out docs/...]

Dry by default: without --live the runner behaves exactly as --dry. Dry builds every request, scores a stub reply
equal to each pack's truth, sends nothing and never reads the key. --fixture PATH is allowed only with --dry.

One call per pack: the system prompt, one strict tool fillFacts (tool_choice auto: Sonnet 5.5 returns a 400 on a
forced tool, docs/ai/claude-client.md section 2) and a user turn holding only the public name and the kind. Nothing
else rides: no handle, no id, no notes, no history.

Before any call, dry or not, the self-test checks: exactly 30 packs (14 food, 10 exercise, 6 unknowable); every
truth muscle is a MuscleSeed name; every wall input is refused or stripped by the packer stand-in as the fixture
says; every pack name passes the packer unchanged; no echo string and no wall input in any request; every request
body is at most 1,560 bytes; the scorer passes each truth stub and catches a set of bad replies; the dry estimate
(every call of a full run at its worst case) is under $0.25. One mismatch and it exits nonzero before sending.

Key: TESSERA_CLAUDE_KEY, else ANTHROPIC_API_KEY, from the environment only, looked up only on a live run, never
printed, logged or written (not its length, not a prefix). api.anthropic.com only, redirects refused, no request
body saved, no retries (any error stops the run and writes what it has), and it stops itself before a call whose
worst case would pass $1. Each invocation adds one section to docs/ai/claude-facts-eval-results.md (newest first).
"""
import argparse
import hashlib
import json
import math
import os
import re
import statistics
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
FIXTURE = ROOT / "docs/research/fixtures/claude-facts-packs.json"
SWIFT_SOURCES = ROOT / "TesseraCore/Sources"
RESULTS = ROOT / "docs/ai/claude-facts-eval-results.md"
API_URL = "https://api.anthropic.com/v1/messages"
API_HOST = "api.anthropic.com"
STOP_NANO = 1_000_000_000  # $1 per invocation
MAX_RUNS = 3
TIMEOUT_S = 20.0
MAX_TOKENS = 80  # a fillFacts call is about 25 to 50 tokens (spec section 6)
WORST_INPUT_TOKENS = 900  # system about 150, schema about 120, pack about 20, plus TOOL_OVERHEAD_TOKENS, with room
BODY_CAP = 1560  # bytes, so bytes // 4 + 10 + 500 never passes 900
DRY_BAR_NANO = 250_000_000  # the dry estimate must be under $0.25 (spec section 6)
CHECKER_VERSION = "claude_facts_eval.py FactsCheck 1"
SPENT = [0]  # real nano-dollars, from usage
TIMEOUTS = [0]
MODEL = "claude-sonnet-5-5"
# Nano-dollars per token: input, output, cache read, cache write (TessUsageLedger.prices; ClaudeKey.swift:95).
PRICES = {"claude-haiku-5-5": (100, 500, 10, 125), "claude-sonnet-5-5": (2000, 10000, 200, 2500)}
EXPECT_FOOD, EXPECT_EXERCISE, EXPECT_UNKNOWABLE, EXPECT_WALLS = 14, 10, 6, 12
PACK_IDS = [f"F{i:02d}" for i in range(1, 15)] + [f"X{i:02d}" for i in range(1, 11)] \
    + [f"U{i:02d}" for i in range(1, 7)]
WALL_IDS = [f"W{i:02d}" for i in range(1, 13)]
TOLERANCE = {"kcal": {"relative": 0.15}, "macroG": {"relative": 0.2, "absoluteFloor": 1.5}}  # spec section 3
# Built, not written out, so this file never holds the literal key prefix (ClaudeKeyGuard.looksLikeClaudeKey).
KEY_PREFIX = "sk" + "-" + "ant" + "-"
KEY_SHAPED = re.compile(re.escape(KEY_PREFIX) + r"\S*", re.I)
MACROS = ["kcal", "proteinG", "fatG", "carbsG"]
TOOL_NAME = "fillFacts"
TOOL_DESCRIPTION = "Public facts, or decline."
INSTRUCTIONS = (
    "Fill public facts about one named thing; the user turn gives its kind and name. Call "
    "fillFacts once, no text. Food: per100g is typical kcal, protein, fat and carbs (g) per 100 g from public tables "
    "like USDA; primaryMuscles null. Exercise: primaryMuscles is only the main muscles worked; per100g null. If it "
    "is not a known public food or a standard named movement (a house recipe, made-up product, mix or vague name), "
    "decline true and both null.")

# ---------------------------------------------------------------------------------------------------------------
# The 18 MuscleSeed names. Read at run time from the Swift source (MuscleSeed.name in
# TesseraCore/Sources/TesseraCore/Catalog/ExerciseSeed.swift on master) when the source is there; else from the
# fixture's muscleNames (a copy of the runner outside the repo). The source used is printed and recorded.


def swift_muscle_names(root):
    """(names in declared order, path) from `enum MuscleSeed`'s `name` switch, or (None, None) when no Swift file
    declares MuscleSeed. A file that declares it but does not parse cleanly raises, so it never falls back silently."""
    src = root / "TesseraCore/Sources"
    if not src.is_dir():
        return None, None
    for path in sorted(src.rglob("*.swift")):
        text = path.read_text(errors="replace")
        m = re.search(r"\benum MuscleSeed\b[^{]*\{", text)
        if not m:
            continue
        name_at = text.find("var name: String", m.end())
        if name_at < 0:
            raise ValueError(f"{path.name}: MuscleSeed has no `var name: String`")
        declared = []
        for line in text[m.end():name_at].splitlines():
            line = line.strip()
            if line.startswith("case ") and ":" not in line:
                declared += [c.strip() for c in line[5:].split(",") if c.strip()]
        nxt = re.compile(r"\n\s*(?:public\s+)?(?:var|func|static|init)\b").search(text, name_at + 1)
        segment = text[name_at:nxt.start() if nxt else len(text)]
        pairs = dict(re.findall(r'case \.(\w+):\s*"([^"]+)"', segment))
        if len(declared) != 18 or set(pairs) != set(declared):
            raise ValueError(f"{path.name}: MuscleSeed parse looks wrong ({len(declared)} cases, {len(pairs)} names)")
        return [pairs[c] for c in declared], path
    return None, None


# ---------------------------------------------------------------------------------------------------------------
# The packer stand-in (spec section 4). Mirrors the app's walls: looksLikeClaudeKey (ClaudeKeyGuard.swift),
# SecretWords.title and SecretWords.mentions (SecretWords.swift), PrivateFacts.isBodyShaped and isMoneyShaped
# (PrivateFacts.swift), plus the intake wall (Product 2:36 pm (2); no Swift function yet, so this is the stand-in).
# Money is stripped, not refused (the recipe-link rule, docs/ai/claude-client.md section 3 step 2); a phrase that is
# still money-shaped after the strip, or empty, is refused.

SECRET_WORDS = {"password", "passwords", "passcode", "passcodes", "pin", "pins", "code", "codes", "combo",
                "combination", "passphrase", "pw", "pwd"}  # SecretWords.words
MEMORY_MONEY = {"$", "\u00a3", "\u20ac", "dollar", "dollars", "bucks", "paid", "spent", "cost", "price", "rent",
                "salary", "venmo", "paypal", "invoice", "refund"}  # TessMemoryScreen.moneyWords
MONEY_WORDS = MEMORY_MONEY | {
    "usd", "dollar", "dollars", "bucks", "buck", "gbp", "pound", "pounds", "quid", "tenner", "fiver", "eur", "euro",
    "euros", "inr", "rs", "rupee", "rupees", "cad", "aud", "chf", "jpy", "yen", "spend", "paid", "pay",
    "cost", "costs", "refund", "refunded", "tip", "tipped", "venmo", "venmoed", "zelle", "zelled", "paypal", "owe",
    "owes", "balance", "checking", "savings", "salary", "paycheck", "copay", "rent"}  # PrivateFacts.moneyWords
CURRENCY = "$\u00a3\u20ac\u20b9\u00a5"
SICK_SLANG = [r"\bsick\s+of\b",
              r"\b(?:set|lift|pr|workout|session|pump|song|view|beat|car|shot|play|trick)\s+(?:was|is|looks|looked)?"
              r"\s*sick\b",
              r"\bsick\s+(?:set|lift|pr|workout|session|pump|song|view|beat|car|shot|play|trick)\b"]
WEIGH_WORDS = {"weigh", "weighs", "weighed", "weighing", "weigh-in", "bw", "scale"}
BODY_UNITS = {"lb", "lbs", "kg", "kgs", "pounds", "kilos"}
DAY_WORDS = {"this", "morning", "today", "tonight", "evening", "night", "am", "pm", "at", "yesterday", "now", "in",
             "me", "i", "my", "was", "is", "weight"}
VITALS = {"bp", "hr", "hrv", "spo2", "pulse", "resting", "temp", "temperature", "glucose", "bpm", "systolic",
          "diastolic"}
MEDICINES = {"advil", "tylenol", "ibuprofen", "acetaminophen", "aspirin", "aleve", "lexapro", "zoloft", "sertraline",
             "prozac", "adderall", "xanax", "melatonin", "benadryl", "claritin", "zyrtec", "pill", "pills", "tablet",
             "tablets", "capsule", "capsules", "dose", "meds", "medication"}
SYMPTOMS = {"migraine", "nausea", "nauseous", "fever", "rash", "headache", "vomiting", "vomited", "dizzy", "diarrhea",
            "cramps", "insomnia", "symptoms", "hurts", "hurt", "hurting", "aches", "ache", "aching", "sore", "injured",
            "sprained", "slept", "cramping", "sick", "unwell"}
KITCHEN_UNITS = {"g", "gram", "grams", "oz", "ml", "cup", "cups", "tbsp", "tsp"}
# Intake stand-in (fixture W11 check: intake words with "me", "my" or "today").
INTAKE_WORDS = {"protein", "kcal", "calorie", "calories", "carb", "carbs", "fat", "fats", "macro", "macros", "fiber",
                "sugar", "intake", "ate", "eat", "eaten", "eating"}
PERSONAL_WORDS = {"me", "my", "today"}
PER_UNIT = r"(?:\s*/\s*[a-z]+|\s+(?:a|an|per|each)\s+[a-z]+)?"
QUALIFIER = r"(?:\b(?:about|around|roughly|approx(?:imately)?|under|over|only|just)\s+)?"
MONEY_SPANS = [
    re.compile(QUALIFIER + r"(?:\b\d+\s+for\s+)?[" + re.escape(CURRENCY) + r"]\s?\d[\d,]*(?:\.\d+)?" + PER_UNIT, re.I),
    re.compile(QUALIFIER + r"(?:\b\d+\s+for\s+)?\b\d[\d,]*\.\d{2}\b" + PER_UNIT, re.I),
    re.compile(QUALIFIER + r"\b\d[\d,]*(?:\.\d+)?\s*(?:" + "|".join(sorted(
        {"dollars", "dollar", "bucks", "buck", "usd", "eur", "euros", "euro", "gbp", "quid", "rupees", "rupee", "inr",
         "yen"}, key=len, reverse=True)) + r")\b" + PER_UNIT, re.I),
]


def looks_like_claude_key(text):
    return KEY_PREFIX in text.lower()


def secret_tokens(text):
    """SecretWords.tokens: lowercased, ":" its own word, split on whitespace, edge punctuation off."""
    return [t.strip(".,!?;'\"()") for t in text.lower().replace(":", " : ").split() if t.strip(".,!?;'\"()")]


def secret_mentions(text):
    """SecretWords.mentions: a secret word, or "wifi" before ":" or "is"."""
    toks = secret_tokens(text)
    return any(t in SECRET_WORDS or (t == "wifi" and i + 1 < len(toks) and toks[i + 1] in (":", "is"))
               for i, t in enumerate(toks))


def pf_words(lower):
    """PrivateFacts.words: letters and digits, with ".", "," and "-" kept inside numbers."""
    return [w.strip(".,-") for w in re.split(r"[^\w.,\-]|_", lower) if w.strip(".,-")]


def without_times(lower):
    return re.sub(r"\b\d{1,2}:\d{2}\s*(?:am|pm)?|\b\d{1,2}\s*(?:am|pm)\b", " ", lower)


def is_amount(word):
    return word[:1].isdigit() and not re.fullmatch(r"\d{1,2}(?:am|pm)", word)


def has_amount(phrase):
    return any(is_amount(w) for w in pf_words(without_times(phrase.lower())))


def is_training(lower):
    return bool(re.search(r"\d\s*(?:x|\u00d7|for|by)\s*\d", lower) or re.search(r"\d\s*reps?\b", lower))


def is_money_shaped(phrase):
    """PrivateFacts.isMoneyShaped."""
    lower = phrase.strip().lower()
    if not lower:
        return False
    spent = bool(re.search(r"\b(?:paid|spent|spend)\b", lower) or re.search(r"\bbought\b.*\bfor\s+\d", lower)) \
        and has_amount(lower)
    if not spent and is_training(lower):
        return False
    if spent or any(c in CURRENCY for c in lower):
        return True
    ws = pf_words(without_times(lower))
    if any(is_amount(w) for w in ws) and any(w in MONEY_WORDS for w in ws):
        return True
    return any(re.fullmatch(r"\d{1,3}(?:,\d{3})*\.\d{2}|\d+\.\d{2}|\d+,\d{2}", w) for w in ws)


def is_body_shaped(phrase):
    """PrivateFacts.isBodyShaped."""
    lower = phrase.strip().lower()
    if not lower or is_training(lower):
        return False
    ws = pf_words(lower)
    has_number = any(w[:1].isdigit() for w in ws)
    sick_of = any(re.search(p, lower) for p in SICK_SLANG)
    if any(w in SYMPTOMS and not (w == "sick" and sick_of) for w in ws) or re.search(r"\d\s*(?:mg|mcg)\b", lower) \
            or re.search(r"\bbody\s?fat\b|\bbf\s*\d", lower):
        return True
    if not has_number:
        return False
    if any(w in MEDICINES for w in ws) or "slept" in ws or any(w in VITALS for w in ws) \
            or "blood pressure" in lower or "heart rate" in lower:
        return True
    if any(w in WEIGH_WORDS for w in ws):
        return not any(w in KITCHEN_UNITS for w in ws) and not any(re.fullmatch(r"\d+g", w) for w in ws)
    rest = [w for w in ws if not w[:1].isdigit() and w not in BODY_UNITS]
    unit_or_decimal = any(w in BODY_UNITS for w in ws) or any("." in w for w in ws) \
        or any(re.fullmatch(r"\d+(?:\.\d+)?(?:lbs?|kgs?)", w) for w in ws)
    return unit_or_decimal and all(w in DAY_WORDS for w in rest)


def is_intake(phrase):
    ws = set(re.findall(r"[^\W_]+", phrase.lower()))
    return bool(ws & INTAKE_WORDS) and bool(ws & PERSONAL_WORDS)


def strip_money(phrase):
    out = phrase
    for span in MONEY_SPANS:
        out = span.sub(" ", out)
    return re.sub(r"\s+", " ", out).strip(" ,;:-/")


def packer(phrase):
    """The name the pack would carry, or None when the packer refuses it."""
    if looks_like_claude_key(phrase) or phrase.strip() == "Private note" or secret_mentions(phrase) \
            or is_body_shaped(phrase) or is_intake(phrase):
        return None
    if is_money_shaped(phrase):
        phrase = strip_money(phrase)
        if not phrase or is_money_shaped(phrase) or has_currency_left(phrase):
            return None
    return phrase


def has_currency_left(phrase):
    return any(c in CURRENCY for c in phrase)


# ---------------------------------------------------------------------------------------------------------------
# Fixture and walls.

def load_fixture(path):
    try:
        fx = json.loads(Path(path).read_text())
    except (OSError, ValueError) as e:
        sys.exit(f"fixture {path}: cannot read ({type(e).__name__}); nothing sent")
    return fx


def fake_key():
    """W12: ClaudeSection.fakeKey's shape, built at run time and held only in memory, never written."""
    return KEY_PREFIX + "fake" + "0" * 24


def wall_input(wall):
    return fake_key() if wall.get("input") == "KEY" else wall.get("input", "")


def echo_exempt(pack, echo):
    """Echo strings inside a pack's own public name. That name is what the request must carry, so such a string is
    not a wall leak for that pack; every exemption is printed and recorded (a fixture mismatch for Research)."""
    return [e for e in echo if e.lower() in pack["name"].lower()]


def echo_hits(text, pack, echo):
    low = text.lower()
    skip = set(echo_exempt(pack, echo))
    return [e for e in echo if e not in skip and e.lower() in low]


# ---------------------------------------------------------------------------------------------------------------
# Requests.

def tool_schema(names):
    """fillFacts, strict, no extra properties: decline, per100g (four numbers) or null, primaryMuscles or null."""
    return {"type": "object", "additionalProperties": False, "required": ["decline", "per100g", "primaryMuscles"],
            "properties": {
                "decline": {"type": "boolean"},
                "per100g": {"anyOf": [{"type": "object", "additionalProperties": False, "required": MACROS,
                                       "properties": {k: {"type": "number"} for k in MACROS}},
                                      {"type": "null"}]},
                "primaryMuscles": {"anyOf": [{"type": "array", "items": {"type": "string", "enum": names}},
                                             {"type": "null"}]}}}


def user_turn(kind, name):
    """The exact user turn: the kind and the public name only, sorted keys, no spaces."""
    return json.dumps({"kind": kind, "name": name}, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def build_body(pack, schema):
    """System prompt, one strict tool, tool_choice auto, the pack as the user turn, effort low."""
    name = packer(pack["name"])
    return {"model": MODEL, "max_tokens": MAX_TOKENS, "system": INSTRUCTIONS,
            "tools": [{"name": TOOL_NAME, "description": TOOL_DESCRIPTION, "strict": True, "input_schema": schema}],
            "tool_choice": {"type": "auto"},
            "messages": [{"role": "user", "content": user_turn(pack["kind"], name if name is not None else "")}],
            "output_config": {"effort": "low"}}


def body_bytes(body):
    """The larger of the bytes sent (ASCII-escaped) and the estimate's UTF-8 bytes."""
    return max(len(json.dumps(body).encode()), len(json.dumps(body, ensure_ascii=False).encode()))


def request_problems(body, pack, fixture):
    """Before any send: size, echo strings, wall inputs and anything key-shaped. Hard fails, never sent."""
    bad = []
    text = json.dumps(body, ensure_ascii=False)
    low = text.lower()
    if body_bytes(body) > BODY_CAP:
        bad.append(f"{pack['id']}: request body {body_bytes(body)} bytes, cap {BODY_CAP}")
    hits = echo_hits(text, pack, fixture["echo"])
    if hits:
        bad.append(f"{pack['id']}: echo string(s) in the request {hits} (hard fail)")
    for w in fixture["walls"]:
        if wall_input(w).lower() in low:
            bad.append(f"{pack['id']}: wall {w['id']} input in the request (hard fail)")
    if looks_like_claude_key(text):
        bad.append(f"{pack['id']}: something key-shaped in the request (hard fail)")
    if packer(pack["name"]) != pack["name"]:
        bad.append(f"{pack['id']}: the packer changes or refuses the public name")
    if body["messages"][0]["content"] != user_turn(pack["kind"], pack["name"]):
        bad.append(f"{pack['id']}: the user turn is not exactly kind and name")
    return bad


# The API adds a tool-use system prompt that the request bytes don't show (a few hundred tokens); counted in the
# worst case so the $1 stop never runs a fraction of a cent over (coordinator audit of #502).
TOOL_OVERHEAD_TOKENS = 500


def worst_nano(body):
    """The $1 stop's per-call worst case: at least 900 tokens in (more if this request is bigger, at 4 bytes a token
    plus 10, as TessUsageLedger.estimate, plus the API's own tool-use system prompt) and max_tokens out."""
    est = len(json.dumps(body, ensure_ascii=False).encode()) // 4 + 10 + TOOL_OVERHEAD_TOKENS
    i, o, _, _ = PRICES[MODEL]
    return max(WORST_INPUT_TOKENS, est) * i + MAX_TOKENS * o


class NoRedirect(urllib.request.HTTPRedirectHandler):
    """Refuse every redirect, so the key header never follows a 3xx to another address."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(req.full_url, code, "redirect refused", headers, fp)


OPENER = urllib.request.build_opener(NoRedirect)


def scrub(text, key=None):
    """Anything key-shaped out of a line before it is printed or written."""
    text = str(text or "")
    if key:
        text = text.replace(key, "[key]")
    return KEY_SHAPED.sub("[key]", text)


def post(key, body):
    """One Messages call, no retries. Any error stops the run with the status and the API's error type and message
    only (scrubbed)."""
    if urllib.parse.urlsplit(API_URL).hostname != API_HOST:
        sys.exit("refusing a host other than api.anthropic.com")
    req = urllib.request.Request(API_URL, data=json.dumps(body).encode(), method="POST",
                                 headers={"x-api-key": key, "anthropic-version": "2023-06-01",
                                          "content-type": "application/json"})
    started = time.time()
    try:
        with OPENER.open(req, timeout=TIMEOUT_S) as r:
            return json.load(r), time.time() - started
    except urllib.error.HTTPError as e:
        try:
            err = json.load(e).get("error", {})
        except Exception:
            err = {}
        sys.exit(scrub(f"API error {e.code}: {err.get('type', '')} {err.get('message', '')}".strip(), key))
    except (TimeoutError, urllib.error.URLError, ConnectionError) as e:
        reason = getattr(e, "reason", e)
        if isinstance(e, TimeoutError) or isinstance(reason, TimeoutError):
            TIMEOUTS[0] += 1
            sys.exit(f"timeout after {TIMEOUT_S:.0f} s")
        sys.exit(f"network error: {type(reason).__name__}")
    except ValueError:
        sys.exit("API reply is not JSON")


def truth_input(pack):
    """The fillFacts input equal to the pack's truth (required muscles for an exercise)."""
    truth = pack.get("truth") or {}
    if pack["expect"] == "decline":
        return {"decline": True, "per100g": None, "primaryMuscles": None}
    if pack["kind"] == "food":
        return {"decline": False, "per100g": dict(truth["per100g"]), "primaryMuscles": None}
    return {"decline": False, "per100g": None, "primaryMuscles": list(truth["primaryMuscles"]["required"])}


def stub_reply(body, inp):
    """--dry: a reply in the API's shape whose fillFacts input is the given input."""
    return {"content": [{"type": "tool_use", "name": TOOL_NAME, "input": inp}], "stop_reason": "tool_use",
            "usage": {"input_tokens": len(json.dumps(body).encode()) // 4 + 10 + TOOL_OVERHEAD_TOKENS,
                      "output_tokens": len(json.dumps(inp).encode()) // 4 + 20}}, 0.0


def cost_nano(usage):
    i, o, cr, cw = PRICES[MODEL]
    return (usage.get("input_tokens", 0) * i + usage.get("output_tokens", 0) * o
            + usage.get("cache_read_input_tokens", 0) * cr + usage.get("cache_creation_input_tokens", 0) * cw)


# ---------------------------------------------------------------------------------------------------------------
# Scoring (spec section 5).

def category(pack):
    if pack["expect"] == "decline":
        return "refuse"
    return "range" if pack["kind"] == "food" else "exact"


def is_number(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def in_tolerance(field, got, want, tol):
    if field == "kcal":
        return abs(got - want) <= tol["kcal"]["relative"] * abs(want)
    return abs(got - want) <= max(tol["macroG"]["relative"] * abs(want), tol["macroG"]["absoluteFloor"])


def summary(inp):
    if not isinstance(inp, dict):
        return "no fillFacts input"
    per, mus = inp.get("per100g"), inp.get("primaryMuscles")
    parts = [f"decline {inp.get('decline')}"]
    if isinstance(per, dict):
        parts.append("per100g " + ", ".join(f"{k} {per.get(k)}" for k in MACROS))
    elif per is not None:
        parts.append("per100g (not an object)")
    if isinstance(mus, list):
        parts.append("muscles " + ", ".join(str(m) for m in mus))
    elif mus is not None:
        parts.append("muscles (not a list)")
    return "; ".join(parts)


def score(data, pack, fixture, names):
    """Returns {pass, extra [why], hard [why], why [why], cut, noTool, reply}."""
    content = data.get("content") or []
    texts = [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
    tools = [b for b in content if isinstance(b, dict) and b.get("type") == "tool_use"]
    extra, hard, why = [], [], []
    if any((t or "").strip() for t in texts):
        extra.append("text block")
    if len(tools) > 1:
        extra.append("second tool call")
    if any(b.get("name") != TOOL_NAME for b in tools):
        extra.append("a tool other than fillFacts")
    cut = data.get("stop_reason") == "max_tokens"
    if cut:
        why.append("cut off at max_tokens")
    hits = echo_hits(json.dumps(content, ensure_ascii=False), pack, fixture["echo"])
    if hits:
        hard.append(f"echo in the reply {hits}")
    inp = next((b.get("input") for b in tools if b.get("name") == TOOL_NAME), None)
    out = {"extra": extra, "hard": hard, "why": why, "cut": cut, "noTool": inp is None, "reply": summary(inp)}
    if inp is None:
        why.append(f"no fillFacts call (stop {data.get('stop_reason')})")
        out["pass"] = False
        return out
    if not isinstance(inp, dict):
        why.append("fillFacts input is not an object")
        out["pass"] = False
        return out
    unknown = sorted(set(inp) - {"decline", "per100g", "primaryMuscles"})
    if unknown:
        extra.append(f"extra field(s) {unknown}")
    missing = sorted({"decline", "per100g", "primaryMuscles"} - set(inp))
    if missing:
        why.append(f"missing {missing}")
    decline, per, mus = inp.get("decline"), inp.get("per100g"), inp.get("primaryMuscles")
    if not isinstance(decline, bool):
        why.append("decline is not a bool")
    if pack["kind"] == "food" and mus is not None:
        extra.append("primaryMuscles on a food")
    if pack["kind"] == "exercise" and per is not None:
        extra.append("per100g on an exercise")
    if per is not None:
        if not isinstance(per, dict):
            why.append("per100g is not an object")
            per = None
        else:
            if set(per) - set(MACROS):
                extra.append(f"extra per100g field(s) {sorted(set(per) - set(MACROS))}")
            if any(not is_number(per.get(k)) for k in MACROS):
                why.append("per100g is missing a number")
                per = None
    if mus is not None:
        if not isinstance(mus, list) or any(not isinstance(m, str) for m in mus):
            why.append("primaryMuscles is not a list of names")
            mus = None
        elif any(m not in names for m in mus):
            why.append(f"not MuscleSeed names {sorted(set(mus) - set(names))}")
    cat = category(pack)
    if cat == "refuse":
        if decline is not True:
            why.append("did not decline")
        if per is not None or mus is not None:
            why.append("filled a field on an unknowable")
    elif decline is not False:
        why.append("declined a knowable row (a miss)")
    elif cat == "range":
        if per is None:
            why.append("no per100g")
        else:
            truth = pack["truth"]["per100g"]
            off = [k for k in MACROS if not in_tolerance(k, per[k], truth[k], fixture["tolerance"])]
            if off:
                why.append("outside tolerance: " + ", ".join(f"{k} {per[k]} (truth {truth[k]})" for k in off))
        if mus is not None:
            why.append("primaryMuscles not null")
    else:
        t = pack["truth"]["primaryMuscles"]
        if mus is None:
            why.append("no primaryMuscles")
        else:
            lacking = [m for m in t["required"] if m not in mus]
            outside = sorted(set(mus) - set(t["allowed"]))
            if lacking:
                why.append(f"lacks required {lacking}")
            if outside:
                why.append(f"outside allowed {outside}")
        if per is not None:
            why.append("per100g not null")
    out["pass"] = not why and not extra and not hard
    return out


# ---------------------------------------------------------------------------------------------------------------
# The self-test.

def bad_vectors(pack, names):
    """Replies the scorer must fail for this pack, with the bucket each must land in (why, extra or hard)."""
    t = truth_input(pack)
    tool = lambda inp: {"content": [{"type": "tool_use", "name": TOOL_NAME, "input": inp}], "stop_reason": "tool_use"}
    vecs = [("text block beside the call",
             {"content": [{"type": "text", "text": "Here you go."}] + tool(t)["content"], "stop_reason": "tool_use"},
             "extra"),
            ("second tool call", {"content": tool(t)["content"] * 2, "stop_reason": "tool_use"}, "extra"),
            ("no tool call", {"content": [], "stop_reason": "end_turn"}, "why"),
            ("cut off", dict(tool(t), stop_reason="max_tokens"), "why"),
            ("echo in the reply", {"content": [{"type": "text", "text": "hunter2"}] + tool(t)["content"],
                                   "stop_reason": "tool_use"}, "hard")]
    cat = category(pack)
    if cat == "range":
        per = dict(t["per100g"], kcal=t["per100g"]["kcal"] * 1.2 + 5)
        vecs += [("kcal 20% off", tool(dict(t, per100g=per)), "why"),
                 ("declined a knowable", tool({"decline": True, "per100g": None, "primaryMuscles": None}), "why"),
                 ("muscles on a food", tool(dict(t, primaryMuscles=["Chest"])), "extra")]
    elif cat == "exact":
        outside = next(n for n in names if n not in pack["truth"]["primaryMuscles"]["allowed"])
        vecs += [("a muscle outside allowed", tool(dict(t, primaryMuscles=t["primaryMuscles"] + [outside])), "why"),
                 ("per100g on an exercise",
                  tool(dict(t, per100g={"kcal": 1, "proteinG": 1, "fatG": 1, "carbsG": 1})), "extra")]
    else:
        vecs += [("filled an unknowable",
                  tool({"decline": False, "per100g": {"kcal": 200, "proteinG": 10, "fatG": 10, "carbsG": 10},
                        "primaryMuscles": None}), "why"),
                 ("extra field", tool(dict(t, source="guess")), "extra")]
    return vecs


def self_test(fixture_path):
    """Exits nonzero, before any call, on any mismatch."""
    bad = []
    fx = load_fixture(fixture_path)
    for k in ("packs", "walls", "echo", "muscleNames", "tolerance"):
        if k not in fx:
            bad.append(f"fixture has no {k}")
    if bad:
        print("self-test FAILED, nothing sent:", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        sys.exit(1)
    try:
        names, swift_path = swift_muscle_names(ROOT)
    except (OSError, ValueError) as e:
        names, swift_path = None, None
        bad.append(f"MuscleSeed found in the Swift source but not parsed: {e}")
    if names is not None:
        source = f"Swift ({swift_path.relative_to(ROOT)})"
        if names != fx["muscleNames"]:
            bad.append(f"fixture muscleNames differ from MuscleSeed: {sorted(set(names) ^ set(fx['muscleNames']))}")
    else:
        names = list(fx["muscleNames"])
        source = "fixture muscleNames (no MuscleSeed in the Swift source here)"
    if len(names) != 18 or len(set(names)) != 18:
        bad.append(f"want 18 distinct MuscleSeed names, got {len(set(names))}")
    if fx["tolerance"] != TOLERANCE:
        bad.append(f"fixture tolerance {fx['tolerance']} differs from the spec {TOLERANCE}")
    packs = fx["packs"]
    ids = [p.get("id") for p in packs]
    food = [p for p in packs if p.get("kind") == "food" and p.get("expect") == "fill"]
    exercise = [p for p in packs if p.get("kind") == "exercise" and p.get("expect") == "fill"]
    unknowable = [p for p in packs if p.get("expect") == "decline"]
    if (len(packs), len(food), len(exercise), len(unknowable)) != (30, EXPECT_FOOD, EXPECT_EXERCISE,
                                                                    EXPECT_UNKNOWABLE):
        bad.append(f"fixture holds {len(packs)} packs ({len(food)} food, {len(exercise)} exercise, "
                   f"{len(unknowable)} unknowable), want 30 (14, 10, 6)")
    if ids != PACK_IDS:
        missing, extra = sorted(set(PACK_IDS) - set(ids)), sorted(set(ids) - set(PACK_IDS))
        bad.append(f"fixture pack ids: missing {missing or 'none'}, unexpected {extra or 'none'}"
                   + ("" if missing or extra else ", out of order or repeated"))
    for p in packs:
        if p.get("kind") not in ("food", "exercise") or p.get("expect") not in ("fill", "decline"):
            bad.append(f"{p.get('id')}: kind {p.get('kind')!r}, expect {p.get('expect')!r}")
            continue
        cat = category(p)
        t = p.get("truth")
        if cat == "refuse" and t is not None:
            bad.append(f"{p['id']}: an unknowable with a truth")
        if cat == "range" and not (isinstance(t, dict) and isinstance(t.get("per100g"), dict)
                                   and all(is_number(t["per100g"].get(k)) for k in MACROS)):
            bad.append(f"{p['id']}: truth per100g is not four numbers")
        if cat == "exact":
            pm = (t or {}).get("primaryMuscles") or {}
            req, allowed = pm.get("required") or [], pm.get("allowed") or []
            if not req or not set(req) <= set(allowed):
                bad.append(f"{p['id']}: required muscles must be a non-empty subset of allowed")
            off = sorted(set(req + allowed) - set(names))
            if off:
                bad.append(f"{p['id']}: truth muscles not MuscleSeed names {off}")
    # Walls through the packer stand-in.
    walls = fx["walls"]
    if [w.get("id") for w in walls] != WALL_IDS:
        bad.append(f"fixture walls: want {EXPECT_WALLS} (W01 to W12), got {[w.get('id') for w in walls]}")
    walls_ok = 0
    for w in walls:
        inp, want = wall_input(w), w.get("packer", "")
        got = packer(inp)
        strip_to = re.fullmatch(r"strip to '([^']*)'", want)
        if want == "refuse":
            ok = got is None
        elif strip_to:
            ok = got == strip_to.group(1)
        elif want == "strip the money span":
            ok = got is not None and not is_money_shaped(got) and not has_currency_left(got) \
                and not any(e.lower() in got.lower() for e in fx["echo"]) and got != inp
        else:
            ok = False
            bad.append(f"{w['id']}: unknown packer rule {want!r}")
        if not ok and (want in ("refuse", "strip the money span") or strip_to):
            shown = "refused" if got is None else ("(key-shaped)" if looks_like_claude_key(got) else repr(got))
            bad.append(f"{w['id']}: packer must {want}, got {shown}")
        walls_ok += ok
    # Requests.
    schema = tool_schema(names)
    exempt = []
    sizes, worst_total = [], 0
    for p in packs:
        if p.get("kind") not in ("food", "exercise"):
            continue
        body = build_body(p, schema)
        sizes.append(body_bytes(body))
        worst_total += worst_nano(body) * MAX_RUNS
        bad += request_problems(body, p, fx)
        exempt += [(p["id"], e) for e in echo_exempt(p, fx["echo"])]
    if any(looks_like_claude_key(x) for x in [INSTRUCTIONS, TOOL_DESCRIPTION, json.dumps(schema)]):
        bad.append("the prompt or schema holds something key-shaped")
    # Scorer: each truth stub passes; each bad reply is caught in its bucket.
    truth_ok = caught = n_vec = 0
    for p in packs:
        if p.get("kind") not in ("food", "exercise") or p.get("id") not in PACK_IDS:
            continue
        try:
            r = score({"content": [{"type": "tool_use", "name": TOOL_NAME, "input": truth_input(p)}],
                       "stop_reason": "tool_use"}, p, fx, names)
            if r["pass"]:
                truth_ok += 1
            else:
                bad.append(f"{p['id']}: the truth stub fails: {r['why'] + r['extra'] + r['hard']}")
            for label, data, bucket in bad_vectors(p, names):
                n_vec += 1
                r = score(data, p, fx, names)
                if r["pass"] or not r[bucket]:
                    bad.append(f"{p['id']} bad reply \"{label}\": want a {bucket} fail, got pass={r['pass']} "
                               f"{r['why'] + r['extra'] + r['hard']}")
                else:
                    caught += 1
        except (KeyError, TypeError, StopIteration) as e:
            bad.append(f"{p.get('id')}: cannot score ({type(e).__name__})")
    if worst_total >= DRY_BAR_NANO:
        bad.append(f"dry estimate ${worst_total / 1e9:.4f} is not under $0.25")
    print(f"self-test: MuscleSeed names from {source}; {len(packs)} packs ({len(food)} food, {len(exercise)} "
          f"exercise, {len(unknowable)} unknowable); walls held {walls_ok}/{len(walls)}; request bodies "
          f"{min(sizes or [0])} to {max(sizes or [0])} bytes (cap {BODY_CAP}); truth stubs pass {truth_ok}/"
          f"{len(packs)}; bad replies caught {caught}/{n_vec}", flush=True)
    for pid, e in exempt:
        print(f"self-test note: echo {e!r} is in {pid}'s own public name, so it is not counted as a leak for "
              f"{pid} (fixture mismatch: echo list vs pack name)", flush=True)
    print(f"dry estimate: {len(packs) * MAX_RUNS} calls ({len(packs)} packs x {MAX_RUNS} runs) at the worst case "
          f"${worst_total / 1e9:.4f} (bar under $0.25)", flush=True)
    if bad:
        print("self-test FAILED, nothing sent:", file=sys.stderr)
        for b in bad:
            print("  " + scrub(b), file=sys.stderr)
        sys.exit(1)
    return {"packs": len(packs), "walls": walls_ok, "truth": truth_ok, "caught": caught, "vectors": n_vec,
            "fixture": fx, "names": names, "source": source, "schema": schema, "worst": worst_total,
            "exempt": exempt, "maxBody": max(sizes or [0])}


# ---------------------------------------------------------------------------------------------------------------
# The run.

def run(args, key, report, selftest):
    """Fills `report` in place, so a run cut short by an exit still has what it spent and got back."""
    fx, names, schema = selftest["fixture"], selftest["names"], selftest["schema"]
    s = {"calls": 0, "cost": [], "latency": [], "rows": {c: [0, 0] for c in ("range", "exact", "refuse")},
         "extraOk": 0, "hard": [], "cut": 0, "noTool": 0, "passed": Counter(), "done": Counter(), "fails": [],
         "worstMax": 0}
    report[MODEL] = s
    for run_no in range(1, args.runs + 1):
        for p in fx["packs"]:
            body = build_body(p, schema)
            problems = request_problems(body, p, fx)
            if problems:
                s["hard"].append((run_no, p["id"], "request: " + "; ".join(problems)))
                sys.exit(f"hard fail before sending {p['id']}: " + scrub("; ".join(problems)))
            worst = worst_nano(body)
            s["worstMax"] = max(s["worstMax"], worst)
            if SPENT[0] + worst > STOP_NANO:
                sys.exit(f"stopped at the $1 ceiling: spent ${SPENT[0] / 1e9:.4f}, next call's worst case "
                         f"${worst / 1e9:.4f}")
            data, secs = stub_reply(body, truth_input(p)) if args.dry else post(key, body)
            nano = cost_nano(data.get("usage", {}))
            SPENT[0] += nano
            s["calls"] += 1
            s["cost"].append(nano)
            s["latency"].append(secs)
            s["done"][p["id"]] += 1
            r = score(data, p, fx, names)
            cat = category(p)
            s["rows"][cat][1] += 1
            if r["pass"]:
                s["rows"][cat][0] += 1
                s["passed"][p["id"]] += 1
            if not r["extra"]:
                s["extraOk"] += 1
            s["cut"] += r["cut"]
            s["noTool"] += r["noTool"]
            if r["hard"]:
                s["hard"].append((run_no, p["id"], "; ".join(r["hard"])))
            if not r["pass"]:
                s["fails"].append((run_no, p["id"], "; ".join(r["why"] + r["extra"] + r["hard"]),
                                   scrub(r["reply"], key)))
    return report


# ---------------------------------------------------------------------------------------------------------------
# The record.

def commit_id():
    """HEAD from .git without running git."""
    try:
        head = (ROOT / ".git/HEAD").read_text().strip()
        if not head.startswith("ref: "):
            return head[:7]
        ref = head[5:]
        path = ROOT / ".git" / ref
        if path.exists():
            return path.read_text().strip()[:7]
        for line in (ROOT / ".git/packed-refs").read_text().splitlines():
            if line.endswith(" " + ref):
                return line.split()[0][:7]
    except OSError:
        pass
    return "unknown"


def now_pt():
    try:
        from zoneinfo import ZoneInfo
        return datetime.now(ZoneInfo("America/Los_Angeles")).strftime("%b %d, %Y %I:%M %p PT")
    except Exception:
        return datetime.now(timezone.utc).strftime("%b %d, %Y %H:%M UTC")


def sha(data):
    return hashlib.sha256(data if isinstance(data, bytes) else data.encode()).hexdigest()[:12]


def cell(text):
    return scrub(text).replace("|", "\\|").replace("\n", " ")


def pctl(values, q):
    v = sorted(values) or [0]
    return v[min(len(v) - 1, int(len(v) * q))]


def need(n):
    """90% of n row-runs, rounded up: 38 of 42, 27 of 30."""
    return math.ceil(0.9 * n - 1e-9)


def gate_rows(s, runs):
    rng, ex, ref = s["rows"]["range"], s["rows"]["exact"], s["rows"]["refuse"]
    full_r, full_x, full_u = EXPECT_FOOD * runs, EXPECT_EXERCISE * runs, EXPECT_UNKNOWABLE * runs
    total = full_r + full_x + full_u
    spend = sum(s["cost"])
    yes = lambda ok: "pass" if ok else "FAIL"
    return [
        ("Range rows passed", f"{need(full_r)} of {full_r} (90%) or better", f"{rng[0]} of {rng[1]}",
         yes(rng[0] >= need(full_r))),
        ("Exact rows passed", f"{need(full_x)} of {full_x} (90%) or better", f"{ex[0]} of {ex[1]}",
         yes(ex[0] >= need(full_x))),
        ("Refuse rows passed", f"{full_u} of {full_u}", f"{ref[0]} of {ref[1]}", yes(ref[0] == full_u)),
        ("No extra fields", f"{total} of {total}", f"{s['extraOk']} of {s['calls']}", yes(s["extraOk"] == total)),
        ("Hard fails", "0", str(len(s["hard"])), yes(not s["hard"])),
        ("Cut off (max_tokens)", "0", str(s["cut"]), yes(s["cut"] == 0)),
        ("Cost per full run", "under $0.25", f"${spend / 1e9:.4f}", yes(spend < DRY_BAR_NANO and runs == MAX_RUNS)),
    ]


def write_report(report, args, selftest, fixture_path, stopped=None):
    s = report.get(MODEL)
    total = sum(s["cost"]) / 1e9 if s else 0
    calls = s["calls"] if s else 0
    fx = selftest["fixture"]
    exempt = ", ".join(f"{e!r} in {pid}" for pid, e in selftest["exempt"]) or "none"
    lines = [f"## {now_pt()}: {MODEL}, {args.runs} run(s)"
             + (" (DRY: stub replies equal to each pack's truth, nothing sent)" if args.dry else "")
             + (f" **stopped: {scrub(stopped)}** (partial)" if stopped else ""), "",
             "| Field | Value |", "|---|---|",
             f"| Model | {MODEL} |",
             "| Tool choice | auto (Sonnet 5.5 returns a 400 on a forced tool) |",
             f"| Effort | low; max_tokens {MAX_TOKENS}; timeout {TIMEOUT_S:.0f} s; no retries |",
             f"| Runs | {args.runs} |",
             f"| Prompt hash | {sha(INSTRUCTIONS)} ({len(INSTRUCTIONS)} chars) |",
             f"| Schema hash | {sha(json.dumps(selftest['schema'], sort_keys=True))} (fillFacts, strict) |",
             f"| Fixture hash | {Path(fixture_path).name} {sha(Path(fixture_path).read_bytes())} |",
             f"| MuscleSeed names | {selftest['source']} |",
             f"| Checker | {CHECKER_VERSION} |",
             f"| Self-test | {selftest['packs']} packs, walls held {selftest['walls']} of {EXPECT_WALLS}, truth stubs "
             f"pass {selftest['truth']}, bad replies caught {selftest['caught']} of {selftest['vectors']}, largest "
             f"body {selftest['maxBody']} bytes |",
             f"| Echo exempt (in the pack's own name) | {cell(exempt)} |",
             f"| Commit | {commit_id()} |", f"| Calls | {calls} |", f"| Spend | ${total:.4f} |",
             f"| Worst case, full run | ${selftest['worst'] / 1e9:.4f} |", ""]
    if s:
        lines += ["### Gate", "", "| Gate | Bar | Result | |", "|---|---|---|---|"]
        lines += [f"| {g} | {b} | {r} | {ok} |" for g, b, r, ok in gate_rows(s, args.runs)]
        p95l = pctl(s["latency"], 0.95)
        med = statistics.median(s["cost"]) / 1e9 if s["cost"] else 0
        lines += [f"| No fillFacts call | report only | {s['noTool']} | |",
                  f"| Cost per call, median / max | worst ${s['worstMax'] / 1e9:.4f} | ${med:.5f} / "
                  f"${max(s['cost'] or [0]) / 1e9:.5f} | |",
                  f"| Latency p95 | report only | {p95l:.1f} s | |",
                  f"| Timeouts at {TIMEOUT_S:.0f} s | 0 | {TIMEOUTS[0]} | |", ""]
        lines += ["### Per pack", "", "| Pack | Kind | Scored as | Passed |", "|---|---|---|---|"]
        lines += [f"| {p['id']} | {p['kind']} | {category(p)} | {s['passed'][p['id']]} of {s['done'][p['id']]} |"
                  for p in fx["packs"] if s["done"][p["id"]]]
        lines += [""]
        if s["hard"]:
            lines += ["### Hard fails", "", "| Run | Pack | Why |", "|---|---|---|"]
            lines += [f"| {r} | {pid} | {cell(w)} |" for r, pid, w in s["hard"]] + [""]
        lines += ["### Failed row-runs", ""]
        if s["fails"]:
            lines += ["| Run | Pack | Why | Reply |", "|---|---|---|---|"]
            lines += [f"| {r} | {pid} | {cell(w)} | {cell(rep)} |" for r, pid, w, rep in s["fails"]]
        else:
            lines += ["None."]
        lines += [""]
    path = Path(args.out) if args.out else RESULTS
    title = "# Facts Claude may fill eval: results"
    intro = [title, "", "Written by `scripts/ai/claude_facts_eval.py`, one section per invocation, newest first. "
             "Pass bar: `docs/research/fixtures/claude-facts-eval.md` section 5. No request body, key or key prefix "
             "is ever written here.", ""]
    old = path.read_text() if path.exists() else ""
    if old.startswith(title):
        head, sep, rest = old.partition("\n## ")
        text = head.rstrip("\n") + "\n\n" + "\n".join(lines) + ("\n## " + rest if sep else "")
    else:
        text = "\n".join(intro + lines) + ("\n" + old if old else "")
    if looks_like_claude_key(text):
        sys.exit("refusing to write: the results hold something key-shaped")
    path.parent.mkdir(parents=True, exist_ok=True)  # under docs/ only (checked in main)
    path.write_text(text.rstrip("\n") + "\n")
    print(f"wrote {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--live", action="store_true", help="send the calls (needs the key); without it the run is dry")
    ap.add_argument("--dry", action="store_true", help="build every request, score a stub reply, send nothing "
                                                       "(the default)")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--out", help="results path under docs/ (default docs/ai/claude-facts-eval-results.md)")
    ap.add_argument("--fixture", help=argparse.SUPPRESS)  # another fixture, with --dry only
    args = ap.parse_args()
    if args.live and args.dry:
        sys.exit("--live and --dry together: pick one")
    if not 1 <= args.runs <= MAX_RUNS:
        sys.exit(f"--runs must be 1 to {MAX_RUNS}")
    if args.out and not Path(args.out).resolve().is_relative_to(DOCS.resolve()):
        sys.exit("--out must be under docs/")
    if args.fixture and not args.dry:
        sys.exit("--fixture is for a --dry run only")
    explicit_dry = args.dry
    args.dry = not args.live
    fixture_path = Path(args.fixture) if args.fixture else FIXTURE
    selftest = self_test(fixture_path)  # exits before any call on a mismatch
    if args.dry and not explicit_dry:
        print("no --live: dry run (nothing sent, no key read)")
    key = None
    if not args.dry:
        # Cloud sessions withhold ANTHROPIC_API_KEY, so the Tess environment carries TESSERA_CLAUDE_KEY.
        key = os.environ.get("TESSERA_CLAUDE_KEY") or os.environ.get("ANTHROPIC_API_KEY")
        if not key:
            sys.exit("TESSERA_CLAUDE_KEY is not set. Put it in the environment, never in a file or a chat.")
    report = {}
    try:
        run(args, key, report, selftest)
    except SystemExit as stop:
        # The $1 stop, a hard fail, an API error, a timeout or a network error: keep what was spent and returned.
        if any(s["calls"] or s["hard"] for s in report.values()) or TIMEOUTS[0]:
            write_report(report, args, selftest, fixture_path, stopped=str(stop.code))
        raise
    s = report[MODEL]
    print(f"{'[dry] ' if args.dry else ''}{MODEL}: calls={s['calls']} range={s['rows']['range'][0]}/"
          f"{s['rows']['range'][1]} exact={s['rows']['exact'][0]}/{s['rows']['exact'][1]} refuse="
          f"{s['rows']['refuse'][0]}/{s['rows']['refuse'][1]} extraOk={s['extraOk']}/{s['calls']} "
          f"hard={len(s['hard'])} cut={s['cut']} spend=${sum(s['cost']) / 1e9:.4f}")
    for g, b, r, ok in gate_rows(s, args.runs):
        print(f"  gate {g}: {r} (bar {b}) {ok}")
    write_report(report, args, selftest, fixture_path)


if __name__ == "__main__":
    main()
