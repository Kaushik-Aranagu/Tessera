#!/usr/bin/env python3
"""Plan my day eval: Claude words today's rules plan (proposePlan), the phone's checks score each reply.

Specs: docs/research/fixtures/plan-my-day-claude.md (section 2 the call, section 3 every check, section 6 the scoring
outline and token rules), docs/research/fixtures/plan-my-day-pack.md (P packs, G items), Research's rerun plan
(26 packs, 24 called, 3 runs, 72 Sonnet calls, $1 stop, pass bar, hard fails) and the fixture
docs/research/fixtures/plan-my-day-eval.json (packs, expected replies, mustNot lists, 18 bad replies).

  python3 scripts/ai/plan_my_day_eval.py [--models sonnet] [--runs 3] [--dry] [--out docs/...]

The instructions and the proposePlan schema are read at runtime from master's
TesseraCore/Sources/TesseraTess/PlanWording.swift (`instructions`, `schemaText`), never from a copy. The request
mirrors ClaudePlanWording.send (PlanWording.swift:580-599). The scorer mirrors
PlanProposalValidator.violations (PlanWording.swift:213-320) line by line, then adds the Tessera checks from
plan-my-day-claude.md section 3 (M-fmt, M-light, M-day, N1 to N6) and the rerun plan's hard fails (HF-screened,
HF-private, HF-event).

Before any call, dry or not, the self-test checks: the Swift literals parse and the schema is JSON; exactly 26 packs,
24 called, 18 bad replies; every pack goes with events as "busy" and allDay [] (HF-event pre-check); no screened word
anywhere in a pack; every expected reply scores clean; every bad reply is caught with at least its listed codes.
One mismatch and it exits before sending.

Key: TESSERA_CLAUDE_KEY, else ANTHROPIC_API_KEY, from the environment only, looked up only without --dry, never
printed or written. api.anthropic.com only, redirects refused, no request body saved, no retries (any error stops
the run and writes what it has), and it stops itself before a call whose worst case would pass $1.
--dry builds every request and scores a stub reply equal to each pack's expected reply; it sends nothing and reads
no key. Each invocation adds one section to docs/ai/plan-my-day-eval-results.md (newest first); people fill the
person columns and the verdict goes to docs/ai/plan-my-day-eval-scores.md.
"""
import argparse
import hashlib
import json
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
FIXTURE = ROOT / "docs/research/fixtures/plan-my-day-eval.json"
SOURCE_DOC = ROOT / "docs/research/fixtures/plan-my-day-claude.md"
SWIFT = ROOT / "TesseraCore/Sources/TesseraTess/PlanWording.swift"
RESULTS = ROOT / "docs/ai/plan-my-day-eval-results.md"
API_URL = "https://api.anthropic.com/v1/messages"
API_HOST = "api.anthropic.com"
STOP_NANO = 1_000_000_000  # $1 per invocation
MAX_RUNS = 3
TIMEOUT_S = 20.0  # ClaudePlanWording.timeout (PlanWording.swift:425)
MAX_TOKENS = 1024  # ClaudePlanWording.maxTokens (PlanWording.swift:420)
WORST_INPUT_TOKENS = 1270  # rerun plan: every call at 1,270 in and 1,024 out is the worst case
CHECKER_VERSION = "plan_my_day_eval.py PlanCheck 1"
SPENT = [0]  # real nano-dollars, from usage
TIMEOUTS = [0]
MODELS = {"sonnet": "claude-sonnet-5-5", "haiku": "claude-haiku-5-5"}
# Nano-dollars per token: input, output, cache read, cache write (TessUsageLedger.prices; ClaudeKey.swift:95).
PRICES = {"claude-haiku-5-5": (100, 500, 10, 125), "claude-sonnet-5-5": (2000, 10000, 200, 2500)}
EXPECT_PACKS, EXPECT_CALLED, EXPECT_BAD = 26, 24, 18
PACK_IDS = [f"d{i:02d}" for i in range(1, 24)] + ["P02", "P14", "P24"]
GATE_PACKS = [f"d{i:02d}" for i in range(1, 24)]
EXTRA_PACKS = ["P02", "P14", "P24"]
# Built, not written out, so this file never holds the literal key prefix (ClaudeKeyGuard.looksLikeClaudeKey).
KEY_PREFIX = "sk" + "-" + "ant" + "-"
KNOWN_CODES = {f"V{i}" for i in range(1, 13)} | {"M-fmt", "M-light", "M-ghost", "M-day"} \
    | {f"N{i}" for i in range(1, 8)} | {"HF-screened", "HF-private", "HF-event"}
HARD = {"M-fmt", "HF-screened", "HF-private", "HF-event"}  # rerun plan "Hard fails"
MUST_NOT = {f"N{i}" for i in range(1, 8)}
TOOL_DESCRIPTION = "Tess's wording and light reorder of today's rules plan."  # PlanWording.swift:593

# ---------------------------------------------------------------------------------------------------------------
# Master's prompt: the two Swift literals, parsed, never copied.


def swift_literal(source, name):
    """The value of a Swift multiline literal `static let <name> = ...` (plain or raw `#`), as Swift builds it: the
    closing delimiter's indentation is stripped from every line, a trailing backslash joins a line to the next
    (non-raw only), escapes are read in a non-raw string, and there is no newline after the last line."""
    m = re.search(r"static let " + re.escape(name) + r' = (#?)"""\n', source)
    if not m:
        raise ValueError(f"PlanWording.swift: no `static let {name}` multiline literal")
    raw = m.group(1) == "#"
    close = re.compile(r'^([ \t]*)"""' + ("#" if raw else "") + r"\s*$", re.M)
    end = close.search(source, m.end())
    if not end:
        raise ValueError(f"PlanWording.swift: `{name}` has no closing delimiter")
    indent = end.group(1)
    body = source[m.end():end.start()]
    lines = body.split("\n")[:-1]  # the text ends with the newline before the closing delimiter
    out = []
    for line in lines:
        if line.strip() == "":
            out.append("")
            continue
        if not line.startswith(indent):
            raise ValueError(f"PlanWording.swift: `{name}` line under-indented: {line[:40]!r}")
        out.append(line[len(indent):])
    if raw:
        return "\n".join(out)
    text = ""
    for i, line in enumerate(out):
        if line.endswith("\\") and not line.endswith("\\\\") and i + 1 < len(out):
            text += line[:-1]
        else:
            text += line + ("\n" if i + 1 < len(out) else "")
    if "\\(" in text:
        raise ValueError(f"PlanWording.swift: `{name}` holds an interpolation")
    escapes = {'\\"': '"', "\\\\": "\\", "\\n": "\n", "\\t": "\t", "\\'": "'", "\\0": "\0"}
    return re.sub(r'\\["\\nt\'0]', lambda e: escapes[e.group(0)], text)


SWIFT_TEXT = SWIFT.read_text()
INSTRUCTIONS = swift_literal(SWIFT_TEXT, "instructions")
SCHEMA_TEXT = swift_literal(SWIFT_TEXT, "schemaText")
SCHEMA = json.loads(SCHEMA_TEXT)  # PlanWording.swift:588: the app sends the parsed object, so do we

# ---------------------------------------------------------------------------------------------------------------
# Word lists. Swift's are mirrored with their line numbers; the plan doc's additions are marked.

TESS_VOICE_BANNED = ["should", "must", "missed", "streak", "great", "awesome", "sorry", "oops"]  # TessCapturing:99
PLAN_BANNED = ["missed", "failed", "behind", "overdue", "late", "again", "only", "finally", "skipped",  # PW:203
               "slipped", "lazy", "backlog", "lighter"]
PLAN_BANNED_PHRASES = ["catch up", "need to", "don't forget", "remember to", "go easy", "take it easy",  # PW:205
                       "push through"]
HEALTH_WORDS = ["sleep", "slept", "sleepy", "tired", "exhausted", "fatigue", "energy", "rested",  # PW:207
                "recovery", "recover", "heart", "hrv", "steps", "sore", "sick", "unwell", "drained", "burnout"]
NUMBER_WORDS = ["two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",  # PW:210
                "twelve", "twenty", "thirty", "forty", "fifty", "sixty", "hundred"]
TRAINING = ["workout", "gym", "training"]  # PW:310
# plan-my-day-claude.md section 3: N2 adds yesterday and still; N3 adds night and the "why" phrases; N5 the cal words.
N2_WORDS = set(TESS_VOICE_BANNED) | set(PLAN_BANNED) | {"yesterday", "still"}
N3_WORDS = set(HEALTH_WORDS) | {"night", "gentle"}
N3_PHRASES = ["kept it", "light day", "short day", "small day"]
CAL_WORDS = ["clear", "free", "open", "empty", "nothing"]
REST_WORDS = ["rest", "workout", "gym", "training"]
RUNNING_WORDS = ["start", "begin", "restart", "kick off", "get going", "warm up"]
# Screened: SecretWords.words (SecretWords.swift) plus the distinctive words of every screened title in
# plan-my-day-pack.md ("Reset my PIN", "Pay Sam back $40", "Refill lexapro 10mg", "IT: reset VPN password",
# "Text sitter the door code", and P24's "Take lexapro"). Common words of those titles (my, the, pay, back, text,
# take, it) are left out: "any word of a screened title" read literally would flag "the" in "Water the plants".
SECRET_WORDS = {"password", "passwords", "passcode", "passcodes", "pin", "pins", "code", "codes", "combo",
                "combination", "passphrase", "pw", "pwd"}
SCREENED_WORDS = SECRET_WORDS | {"reset", "sam", "refill", "lexapro", "10mg", "vpn", "sitter", "door"}
SCREENED_MARKS = ["$40", "door code", KEY_PREFIX]
SCREENED_TITLES = ["Reset my PIN", "Pay Sam back $40", "Refill lexapro 10mg", "IT: reset VPN password",
                   "Text sitter the door code", "Take lexapro"]
# HF-private: a line on a "task"-titled block may say only its length, its time and its order. Any other word must
# come from another block's title sent as typed. Anything else is a guess at what the private block is.
GUESS_OK = {"a", "an", "the", "and", "then", "first", "next", "to", "for", "by", "before", "after", "at", "on", "in",
            "of", "with", "from", "until", "between", "about", "while", "right", "straight", "done", "finished",
            "quick", "short", "small", "one", "it", "its", "this", "that", "is", "out", "way", "up", "off", "early",
            "well", "long", "start", "min", "mins", "minutes", "hour", "hours", "h", "am", "pm", "morning",
            "afternoon", "evening", "noon", "task", "so", "just", "there", "here", "into", "your", "you"}


def words(text):
    """Swift `split { !$0.isLetter && !$0.isNumber }` (PW:172): "Anu's" is "anu", "s"."""
    return re.findall(r"[^\W_]+", text.lower())


def tokens(text):
    """Swift `split { !$0.isLetter && !$0.isNumber && $0 != "'" }` (PW:297): "don't" stays one token."""
    return [t for t in re.split(r"[^\w']|_", text.lower()) if t]


def letter_words(text):
    """TessVoice.violations: `split(whereSeparator: { !$0.isLetter })` (TessCapturing:118)."""
    return re.findall(r"[^\W\d_]+", text.lower())


def padded(ws):
    return " " + " ".join(ws) + " "


def has_phrase(line, phrase):
    """Token-run match (plan-my-day-claude.md section 6), on letters and digits."""
    return padded(words(phrase)) in padded(words(line))


def is_emoji(ch):
    o = ord(ch)
    return o >= 0x1F000 or 0x2600 <= o <= 0x27BF or 0x2B00 <= o <= 0x2BFF


# ---------------------------------------------------------------------------------------------------------------
# The pack, as PlanPack holds it (PlanWording.swift:9-178), rebuilt from the wire JSON.

def clock_min(text):
    m = re.fullmatch(r"(\d{2}):(\d{2})", text or "")
    return int(m.group(1)) * 60 + int(m.group(2)) if m else None


def wire(pack):
    """The exact user turn: sorted keys, no spaces, slashes unescaped (PW:144-146)."""
    return json.dumps(pack, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


class Pack:
    def __init__(self, raw):
        self.raw = raw
        self.json = wire(raw)
        self.blocks = {}
        runs = {}
        for b in raw["blocks"]:
            fixed = "run" not in b  # PW:93-98: a block with no run is fixed
            self.blocks[b["id"]] = {"start": clock_min(b["start"]), "end": clock_min(b["end"]), "min": b["min"],
                                    "fixed": fixed, "kind": b["kind"], "title": b["title"],
                                    "running": bool(b.get("running"))}
            if not fixed:
                runs.setdefault(b["run"], []).append(b["id"])
        self.runs = [runs[k] for k in sorted(runs)]
        self.cap = raw["cap"]
        self.window = (clock_min(raw["window"][0]), clock_min(raw["window"][1]))
        self.now = clock_min(raw["now"])
        self.dues = [clock_min(b["due"]) for b in raw["blocks"] if "due" in b]
        sent = [b["title"] for b in raw["blocks"] if b["title"] not in ("busy", "task")] + list(raw["allDay"])
        self.title_words = {w for t in sent for w in words(t)}  # PW:174-177
        self.title_phrases = [padded(words(t)) for t in sent]
        self.other_names = set()  # PW:164: not on the wire; the fixture's mustNot carries these instead
        self.has_workout = any(b["kind"] == "workout" for b in raw["blocks"])  # PW:169
        self.is_rest_day = raw.get("rest") is True  # PW:170
        self.calendar_known = raw.get("cal") is not False
        self.light = raw["light"] is True
        self.private = {i for i, b in self.blocks.items() if b["title"] == "task" and b["kind"] != "event"}


# ---------------------------------------------------------------------------------------------------------------
# Q5: a time in a line is re-rendered through the one formatter before scoring ("5 PM", "5:00 pm", "5pm" are
# "5 pm"). A 24-hour HH:mm is never re-rendered: it stays and fails M-fmt and V11.

AMPM_ANY = re.compile(r"\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b", re.I)


def rerender(line):
    def fix(m):
        hour, minute = int(m.group(1)), m.group(2)
        if not 1 <= hour <= 12:
            return m.group(0)
        mm = "" if minute in (None, "00") else ":" + minute
        return f"{hour}{mm} {m.group(3).lower()}"
    return AMPM_ANY.sub(fix, line) if line is not None else None


def ampm(minutes):
    """Minutes of day as his time format (settings-claude.md 6:37 PM PT): "7:30 am", "5 pm", "12 pm"."""
    h, m = divmod(minutes % (24 * 60), 60)
    suffix = "am" if h < 12 else "pm"
    h12 = h % 12 or 12
    return f"{h12} {suffix}" if m == 0 else f"{h12}:{m:02d} {suffix}"


# ---------------------------------------------------------------------------------------------------------------
# The reply: ProposePlan's Decodable shape (PW:182-199). A decode failure is V1 (plan-my-day-claude.md section 6).

def decode(reply):
    if not isinstance(reply, dict):
        return "reply is not an object"
    blocks, ghosts = reply.get("blocks"), reply.get("ghostLines")
    if not isinstance(blocks, list) or not isinstance(ghosts, list):
        return "blocks or ghostLines missing"
    for b in blocks:
        if not (isinstance(b, dict) and isinstance(b.get("id"), str) and isinstance(b.get("start"), str)
                and isinstance(b.get("lineText"), str) and (b.get("end") is None or isinstance(b.get("end"), str))):
            return "a block does not decode"
    for g in ghosts:
        if not (isinstance(g, dict) and isinstance(g.get("id"), str) and isinstance(g.get("line"), str)):
            return "a ghost line does not decode"
    sw = reply.get("startWith")
    if sw is not None and not (isinstance(sw, dict) and isinstance(sw.get("id"), str)
                               and isinstance(sw.get("line"), str)):
        return "startWith does not decode"
    if reply.get("note") is not None and not isinstance(reply.get("note"), str):
        return "note does not decode"
    return None


def reply_lines(reply):
    """Every line with where it sits, in Swift's order (PW:284-285): lineTexts, ghost lines, startWith, note."""
    out = [("lineText", b["id"], b["lineText"]) for b in reply["blocks"] if b["lineText"] != ""]
    out += [("ghost", g["id"], g["line"]) for g in reply["ghostLines"]]
    if reply.get("startWith") is not None:
        out.append(("startWith", reply["startWith"]["id"], reply["startWith"]["line"]))
    if reply.get("note") is not None:
        out.append(("note", "", reply["note"]))
    return out


# ---------------------------------------------------------------------------------------------------------------
# PlanProposalValidator.violations (PW:213-320), mirrored. V13 (PW:307-317) is reported as N5: the plan doc's
# unsent-facts code, and the fixture's code list has no V13.

def numbers_are_licensed(line, times, lengths, titles):
    """PW:324-351. Returns None when licensed, else why: "time", "hhmm", "length" or "count"."""
    rest = line
    for m in re.finditer(r"(\d{1,2})(?::(\d{2}))?\s?(am|pm)\b", line):  # PW:328
        hour = int(m.group(1))
        if not 1 <= hour <= 12:
            return "time"
        value = (hour % 12 + (12 if m.group(3) == "pm" else 0)) * 60 + int(m.group(2) or 0)
        if value not in times and value + 24 * 60 not in times:
            return "time"
        rest = rest.replace(m.group(0), " ")
    if re.search(r"\d{1,2}:\d{2}", rest):  # PW:335
        return "hhmm"
    for m in re.finditer(r"(\d+(?:\.\d+)?)\s?(min|mins|minutes|hour|hours|h)\b", rest):  # PW:338
        value = float(m.group(1))
        as_minutes = int(value * 60) if m.group(2).startswith("h") else int(value)
        if as_minutes not in lengths:
            return "length"
        rest = rest.replace(m.group(0), " ")
    for token in re.findall(r"[^\W_]+", rest):  # PW:344
        if (any(c.isdigit() for c in token) or token in NUMBER_WORDS) and token not in titles:
            return "count"
    return None


def tess_voice_violations(line):
    """TessVoice.violations(in:) (TessCapturing:102-122)."""
    problems = []
    if len(line.split()) >= 12:
        problems.append("12+ words")
    if "\n" in line:
        problems.append("newline")
    if "!" in line:
        problems.append("!")
    if any(is_emoji(c) for c in line):
        problems.append("emoji")
    problems += [w for w in TESS_VOICE_BANNED if w in letter_words(line)]
    return problems


def validator(reply, pack):
    """Returns (codes, per-line codes {(slot, id, line): [codes]}, placed)."""
    codes, per_line = [], {}
    ids = [b["id"] for b in reply["blocks"]]
    ghost_ids = [g["id"] for g in reply["ghostLines"]]
    if len(set(ids)) != len(ids) or len(set(ghost_ids)) != len(ghost_ids):  # PW:222
        codes.append("V1")
    if set(ids) != set(pack.blocks):  # PW:225
        codes.append("V2")
        return codes, per_line, {}
    placed = {}
    for b in reply["blocks"]:  # PW:230-236
        start = clock_min(b["start"])
        if start is None or b["id"] not in pack.blocks:
            codes.append("V1")
            return codes, per_line, {}
        end = clock_min(b.get("end"))
        placed[b["id"]] = (start, end if end is not None else start + pack.blocks[b["id"]]["min"])
    for i, inp in pack.blocks.items():  # PW:238 V3
        if inp["fixed"] and placed[i] != (inp["start"], inp["end"]):
            codes.append("V3")
            break
    for run in pack.runs:  # PW:245 V4
        cursor = min(pack.blocks[i]["start"] for i in run)
        for i, at in sorted(((i, placed[i]) for i in run if i in placed), key=lambda x: x[1][0]):
            if at[0] != cursor or at[1] - at[0] != pack.blocks[i]["min"]:
                codes.append("V4")
                break
            cursor = at[1]
        if any(i not in placed or placed[i][0] < pack.window[0] or placed[i][1] > pack.window[1]
               for i in run):  # PW:258 V5
            codes.append("V5")
    ordered = sorted(placed.values(), key=lambda p: p[0])  # PW:266 V6
    if any(a[1] > b[0] for a, b in zip(ordered, ordered[1:])):
        codes.append("V6")
    run_ids = {i for run in pack.runs for i in run}  # PW:271 V7
    if set(ghost_ids) != run_ids or len(ghost_ids) > min(3, pack.cap) \
            or any(g["line"].strip(" \t") == "" for g in reply["ghostLines"]):
        codes.append("V7")
    non_events = [(p[0], i) for i, p in placed.items() if pack.blocks[i]["kind"] != "event"]  # PW:278 V8
    earliest = min(non_events)[1] if non_events else None
    sw = reply.get("startWith")
    if (sw["id"] if sw else None) != earliest or (sw is not None and sw["line"] == ""):
        codes.append("V8")
    if any(b["id"] in run_ids and b["lineText"] != "" for b in reply["blocks"]):  # PW:286 V9
        codes.append("V9")
    times = {t for b in pack.blocks.values() for t in (b["start"], b["end"])} \
        | {t for p in placed.values() for t in p} | set(pack.dues) | {pack.window[0], pack.window[1], pack.now}
    lengths = {b["min"] for b in pack.blocks.values()}
    for slot, bid, line in reply_lines(reply):
        lc = []
        if tess_voice_violations(line):  # PW:293
            lc.append("V9")
        lower = line.lower()
        toks = tokens(line)
        if any(t in PLAN_BANNED for t in toks) or any(p in lower for p in PLAN_BANNED_PHRASES):  # PW:298
            lc.append("V10")
        if numbers_are_licensed(lower, times, lengths, pack.title_words):  # PW:301
            lc.append("V11")
        if any(t in HEALTH_WORDS and t not in pack.title_words for t in toks):  # PW:304
            lc.append("V12")
        pad = padded(toks)  # PW:309-317 (V13, reported as N5)
        if any(f" {n} " in pad for n in pack.other_names) \
                or (not pack.has_workout and any(t in TRAINING and t not in pack.title_words for t in toks)) \
                or (not pack.has_workout and " rest day " in pad and not (pack.is_rest_day and line == "Rest day.")):
            lc.append("N5")
        per_line[(slot, bid, line)] = lc
        codes += lc
    return sorted(set(codes)), per_line, placed


# ---------------------------------------------------------------------------------------------------------------
# The Tessera checks (plan-my-day-claude.md section 3) and the rerun plan's hard fails.

def exempt(phrase, pack):
    """A word or phrase in a title sent as typed is exempt (section 6; fixture "about")."""
    p = padded(words(phrase))
    return p.strip() == "" or any(p in t for t in pack.title_phrases)


def guesses(line, pack):
    """HF-private: a word on a private block's line that is not length, time, order, or another block's title."""
    return [w for w in words(line) if not w.isdigit() and w not in GUESS_OK and w not in pack.title_words]


def screened(line):
    lw = set(words(line))
    return sorted((lw & SCREENED_WORDS) | {m for m in SCREENED_MARKS if m.lower() in line.lower()})


def line_checks(slot, bid, line, pack, entry, event_titles):
    codes = []
    lower = line.lower()
    toks = tokens(line)
    # M-fmt: once valid am/pm times are taken out, any HH:mm left (or an am/pm hour past 12) is a hard fail.
    rest = re.sub(r"\b(1[0-2]|[1-9])(?::[0-5]\d)? (am|pm)\b", " ", lower)
    if re.search(r"\d{1,2}:\d{2}", rest) or re.search(r"\b\d{1,2}(?::\d{2})?\s?(am|pm)\b", rest):
        codes.append("M-fmt")
    # N1: no line names a time in 11 pm to 7 am.
    for m in re.finditer(r"\b(\d{1,2})(?::(\d{2}))? (am|pm)\b", lower):
        h = int(m.group(1))
        if 1 <= h <= 12:
            v = (h % 12 + (12 if m.group(3) == "pm" else 0)) * 60 + int(m.group(2) or 0)
            if v < 7 * 60 or v >= 23 * 60:
                codes.append("N1")
    # N2: guilt words, token match, title words exempt; no "!", emoji or em-dash.
    if any(t in N2_WORDS and t not in pack.title_words for t in toks) \
            or any(has_phrase(line, p) and not exempt(p, pack) for p in PLAN_BANNED_PHRASES) \
            or "!" in line or "\u2014" in line or any(is_emoji(c) for c in line):
        codes.append("N2")
    # N3: health and why.
    if any(t in N3_WORDS and t not in pack.title_words for t in toks) \
            or any(has_phrase(line, p) and not exempt(p, pack) for p in N3_PHRASES):
        codes.append("N3")
    # N5: unsent facts. The rest-day note "Rest day." is the one line allowed to say rest (d21).
    rest_note = pack.is_rest_day and slot == "note" and line == "Rest day."
    if not rest_note:
        n5 = [w for w in entry.get("mustNot") or [] if has_phrase(line, w) and not exempt(w, pack)]
        if not pack.calendar_known:
            n5 += [w for w in CAL_WORDS if has_phrase(line, w) and not exempt(w, pack)]
        if not pack.has_workout:
            n5 += [w for w in REST_WORDS if has_phrase(line, w) and not exempt(w, pack)]
        if any(b["running"] for b in pack.blocks.values()):
            n5 += [w for w in RUNNING_WORDS if has_phrase(line, w) and not exempt(w, pack)]
        if n5:
            codes.append("N5")
    # HF-event: a line naming an event title the pack sent as "busy" (titles from plan-my-day-claude.md section 4).
    if any(has_phrase(line, t) and not exempt(t, pack) for t in event_titles.get(entry["id"], [])):
        codes += ["HF-event", "N5"]
    # HF-screened: a screened word or title anywhere in a line.
    if screened(line):
        codes.append("HF-screened")
        if pack.private:
            codes.append("HF-private")  # with a private block in the pack, a screened word is a guess at it
    # HF-private: a line on a "task"-titled block that says more than its length, time and order.
    if bid in pack.private and slot in ("ghost", "startWith", "lineText") and guesses(line, pack):
        codes.append("HF-private")
    return codes


def reply_checks(reply, pack, placed, codes):
    out = []
    if "V3" in codes:
        out.append("N4")  # N4 is V3 (section 3)
    if "V11" in codes:
        out.append("N6")  # N6 counts: V11 (section 3)
    run_ids = {i for run in pack.runs for i in run}
    # N1: no run block starts or ends in 11 pm to 7 am.
    if any(i in placed and (placed[i][0] < 7 * 60 or placed[i][1] > 23 * 60) for i in run_ids):
        out.append("N1")
    # M-light: ghost lines at most 2, workout lineText "", a workout startWith line is exactly "{title} at {time}.".
    if pack.light:
        sw = reply.get("startWith")
        if len(reply["ghostLines"]) > 2 \
                or any(pack.blocks.get(b["id"], {}).get("kind") == "workout" and b["lineText"] != ""
                       for b in reply["blocks"]) \
                or (sw and pack.blocks.get(sw["id"], {}).get("kind") == "workout"
                    and sw["line"] != f"{pack.blocks[sw['id']]['title']} at {ampm(pack.blocks[sw['id']]['start'])}."):
            out.append("M-light")
    # M-day: a real weekday, the window inside 7 am to 9 pm, every run block inside the window.
    if pack.raw.get("weekday") not in ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun") \
            or pack.window[0] < 7 * 60 or pack.window[1] > 21 * 60 \
            or any(i not in placed or placed[i][0] < pack.window[0] or placed[i][1] > pack.window[1] for i in run_ids):
        out.append("M-day")
    # N5: on a rest day the note is null or exactly "Rest day."; a running workout is startWith.
    if pack.is_rest_day and reply.get("note") not in (None, "Rest day."):
        out.append("N5")
    running = [i for i, b in pack.blocks.items() if b["running"]]
    if running and (reply.get("startWith") or {}).get("id") != running[0]:
        out.append("N5")
    # M-ghost and N7 (writes) are not mechanized: a proposePlan reply carries no ops; the app test owns them.
    return out


def score(reply, entry, pack, event_titles):
    """Returns (codes, caught [(slot, id, line, codes)], shown [(slot, id, line)], dropped count)."""
    why = decode(reply)
    if why:
        return ["V1"], [("(reply)", "", why, ["V1"])], [], 0
    reply = dict(reply, blocks=[dict(b, lineText=rerender(b["lineText"])) for b in reply["blocks"]],
                 ghostLines=[dict(g, line=rerender(g["line"])) for g in reply["ghostLines"]],
                 startWith=(dict(reply["startWith"], line=rerender(reply["startWith"]["line"]))
                            if reply.get("startWith") else None),
                 note=rerender(reply.get("note")))
    codes, per_line, placed = validator(reply, pack)
    if "V2" in codes or not placed:
        return codes, [("(reply)", "", "ids or times do not match the pack", codes)], [], 0
    caught = []
    all_codes = set(codes)
    for slot, bid, line in reply_lines(reply):
        lc = sorted(set(per_line.get((slot, bid, line), []) + line_checks(slot, bid, line, pack, entry,
                                                                           event_titles)))
        all_codes |= set(lc)
        if lc:
            caught.append((slot, bid, line, lc))
    extra = reply_checks(reply, pack, placed, codes)
    all_codes |= set(extra)
    reply_level = sorted((set(codes) - {c for *_, lc in caught for c in lc}) | set(extra))
    if reply_level:
        caught.insert(0, ("(reply)", "", "", reply_level))
    shown, dropped = [], 0
    if not all_codes:
        for slot, bid, line in reply_lines(reply):
            # G11 (Design 12:18 pm): the app drops a ghost line beside a "task" block, so it is never shown.
            if slot == "ghost" and bid in pack.private:
                dropped += 1
                continue
            shown.append((slot, bid, line))
    return sorted(all_codes), caught, shown, dropped


# ---------------------------------------------------------------------------------------------------------------
# Fixture, pack pre-checks and the self-test.

def source_event_titles():
    """The event and all-day titles each d pack had before Oct 16 sent them as "busy" (section 4 of
    plan-my-day-claude.md), for HF-event. Read at runtime so the source stays the doc."""
    out, current = {}, None
    for raw in SOURCE_DOC.read_text().splitlines():
        m = re.match(r"^\*\*(d\d\d)\*\*", raw)
        if m:
            current = m.group(1)
            continue
        if current and raw.startswith("`{") and raw.rstrip().endswith("}`"):
            pack = json.loads(raw.strip().strip("`"))
            out[current] = [b["title"] for b in pack["blocks"] if b["kind"] == "event" and b["title"] != "busy"] \
                + list(pack.get("allDay", []))
            current = None
    return out


def pack_problems(entry):
    """HF-event and HF-screened before any call: events go as "busy", allDay is [], nothing screened."""
    pid, raw = entry["id"], entry["pack"]
    bad = []
    if raw.get("allDay") != []:
        bad.append(f"{pid}: allDay is {raw.get('allDay')!r}, want [] (HF-event)")
    for b in raw.get("blocks", []):
        if b.get("kind") == "event" and b.get("title") != "busy":
            bad.append(f"{pid}: event {b.get('id')} title {b.get('title')!r}, want \"busy\" (HF-event)")
    text = wire(raw)
    hits = screened(text)
    hits += [t for t in SCREENED_TITLES if t.lower() in text.lower()]
    if hits:
        bad.append(f"{pid}: screened words in the pack {sorted(set(hits))} (HF-screened)")
    if not any("run" in b for b in raw.get("blocks", [])):
        bad.append(f"{pid}: no run block, so PlanPack is nil and call must be false")
    for b in raw.get("blocks", []):
        if clock_min(b.get("start")) is None or clock_min(b.get("end")) is None:
            bad.append(f"{pid}: block {b.get('id')} times are not HH:mm")
    return bad


def load_fixture(path):
    try:
        fx = json.loads(Path(path).read_text())
    except (OSError, ValueError) as e:
        sys.exit(f"fixture {path}: cannot read ({type(e).__name__}); nothing sent")
    return fx


def worst_nano(model, body):
    """The $1 stop's per-call worst case: at least 1,270 tokens in (more if this request is bigger, at 4 bytes a
    token plus 10, as TessUsageLedger.estimate) and max_tokens out."""
    est = len(json.dumps(body, ensure_ascii=False).encode()) // 4 + 10
    i, o, _, _ = PRICES[model]
    return max(WORST_INPUT_TOKENS, est) * i + MAX_TOKENS * o


def self_test(fixture_path, event_titles):
    """Exits nonzero, before any call, on any mismatch."""
    bad = []
    if len(INSTRUCTIONS) < 500 or "proposePlan" not in INSTRUCTIONS or not INSTRUCTIONS.startswith("You are Tess"):
        bad.append(f"instructions parse looks wrong ({len(INSTRUCTIONS)} chars)")
    if "\\\n" in INSTRUCTIONS or "\n    " in INSTRUCTIONS:
        bad.append("instructions kept a line continuation or Swift indentation")
    if not (isinstance(SCHEMA, dict) and set(SCHEMA.get("required", [])) == {"blocks", "startWith", "ghostLines",
                                                                              "note"}):
        bad.append("schemaText does not parse to the proposePlan schema")
    vectors = [("5 PM", "5 pm"), ("5:00 pm", "5 pm"), ("5pm", "5 pm"), ("Due 7:30AM.", "Due 7:30 am."),
               ("Due 17:00.", "Due 17:00."), ("12:00 pm", "12 pm")]
    for raw, want in vectors:
        if rerender(raw) != want:
            bad.append(f"re-render {raw!r}: got {rerender(raw)!r}, want {want!r}")
    if sorted(event_titles) != [d for d in GATE_PACKS if d != "d14"]:
        bad.append(f"plan-my-day-claude.md section 4: parsed {len(event_titles)} d packs, want 22 (all but d14)")
    fx = load_fixture(fixture_path)
    packs = fx.get("packs") or []
    ids = [p.get("id") for p in packs]
    called = [p for p in packs if p.get("call")]
    n_bad = sum(len(p.get("bad") or []) for p in packs)
    if len(packs) != EXPECT_PACKS:
        bad.append(f"fixture holds {len(packs)} packs, want {EXPECT_PACKS}")
    if len(called) != EXPECT_CALLED:
        bad.append(f"fixture calls {len(called)} packs, want {EXPECT_CALLED}")
    if n_bad != EXPECT_BAD:
        bad.append(f"fixture holds {n_bad} bad replies, want {EXPECT_BAD}")
    if len(set(ids)) != len(ids):
        bad.append(f"fixture pack ids repeat: {[i for i, n in Counter(ids).items() if n > 1]}")
    if sorted(ids) != sorted(PACK_IDS):
        missing, extra = sorted(set(PACK_IDS) - set(ids)), sorted(set(ids) - set(PACK_IDS))
        bad.append(f"fixture pack ids: missing {missing or 'none'}, unexpected {extra or 'none'}")
    for p in packs:
        if p.get("id") in ("d14", "d22") and (p.get("call") or p.get("pack") is not None
                                              or p.get("expect") is not None):
            bad.append(f"{p['id']}: want call false, pack null, expect null (no call in the app)")
    expect_ok = caught_ok = 0
    for p in called:
        problems = pack_problems(p)
        if problems:
            bad += problems
            continue
        pack = Pack(p["pack"])
        body = build_body(pack, MODELS["sonnet"])
        if body["messages"][0]["content"] != pack.json:
            bad.append(f"{p['id']}: the request does not carry the wire pack")
        codes, caught, _, _ = score(p.get("expect"), p, pack, event_titles)
        if codes:
            bad.append(f"{p['id']} expect: want clean, got {codes} {[(s, i, l, c) for s, i, l, c in caught]}")
        else:
            expect_ok += 1
        for v in p.get("bad") or []:
            unknown = set(v.get("codes", [])) - KNOWN_CODES
            if unknown:
                bad.append(f"{p['id']} bad \"{v.get('why')}\": unknown codes {sorted(unknown)}")
            got, _, _, _ = score(v.get("reply"), p, pack, event_titles)
            missing = set(v.get("codes", [])) - set(got)
            if missing or not got:
                bad.append(f"{p['id']} bad \"{v.get('why')}\": want {v.get('codes')}, got {got}, missing "
                           f"{sorted(missing)}")
            else:
                caught_ok += 1
    print(f"self-test: prompt {len(INSTRUCTIONS)} chars and schema parsed from PlanWording.swift; "
          f"{len(packs)} packs ({len(called)} called); expected replies clean {expect_ok}/{len(called)}; "
          f"bad replies caught {caught_ok}/{n_bad}; event titles from {len(event_titles)} source packs"
          + ("; a pack that fails its pre-check is not scored" if bad else ""), flush=True)
    if bad:
        print("self-test FAILED, nothing sent:", file=sys.stderr)
        for b in bad:
            print("  " + b, file=sys.stderr)
        sys.exit(1)
    return {"packs": len(packs), "called": len(called), "expect": expect_ok, "bad": caught_ok, "fixture": fx}


# ---------------------------------------------------------------------------------------------------------------
# Requests.

def build_body(pack, model):
    """ClaudePlanWording.send's body (PW:589-598): system is the instructions string, one strict tool, tool_choice
    auto, the wire pack as the user turn, effort low. tool_choice stays auto for every model, as the app sends it:
    Sonnet 5.5 returns a 400 on a forced tool, so the app never forces one."""
    return {"model": model, "max_tokens": MAX_TOKENS, "system": INSTRUCTIONS,
            "tools": [{"name": "proposePlan", "description": TOOL_DESCRIPTION, "strict": True,
                       "input_schema": SCHEMA}],
            "tool_choice": {"type": "auto"}, "messages": [{"role": "user", "content": pack.json}],
            "output_config": {"effort": "low"}}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    """Refuse every redirect, so the key header never follows a 3xx to another address."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(req.full_url, code, "redirect refused", headers, fp)


OPENER = urllib.request.build_opener(NoRedirect)


def post(key, body):
    """One Messages call, no retries (rerun plan). Any error stops the run with the status and the API's error type
    and message only."""
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
        sys.exit(f"API error {e.code}: {err.get('type', '')} {err.get('message', '')}".strip())
    except (TimeoutError, urllib.error.URLError, ConnectionError) as e:
        reason = getattr(e, "reason", e)
        if isinstance(e, TimeoutError) or isinstance(reason, TimeoutError):
            TIMEOUTS[0] += 1
            sys.exit(f"timeout after {TIMEOUT_S:.0f} s")
        sys.exit(f"network error: {type(reason).__name__}")


def stub_reply(body, entry):
    """--dry: a reply in the API's shape whose proposePlan input is the pack's expected reply."""
    return {"content": [{"type": "tool_use", "name": "proposePlan", "input": entry["expect"]}],
            "stop_reason": "tool_use",
            "usage": {"input_tokens": len(json.dumps(body).encode()) // 4,
                      "output_tokens": len(json.dumps(entry["expect"]).encode()) // 4 + 100}}, 0.0


def cost_nano(model, usage):
    i, o, cr, cw = PRICES[model]
    return (usage.get("input_tokens", 0) * i + usage.get("output_tokens", 0) * o
            + usage.get("cache_read_input_tokens", 0) * cr + usage.get("cache_creation_input_tokens", 0) * cw)


def tool_input(data):
    """PW:628-632: the first tool_use block named proposePlan."""
    for block in data.get("content", []):
        if block.get("type") == "tool_use" and block.get("name") == "proposePlan":
            return block.get("input")
    return None


def run(args, key, report, fixture, event_titles):
    """Fills `report` in place, so a run cut short by an exit still has what it spent and got back."""
    entries = fixture["packs"]
    for mk in args.models:
        model = MODELS[mk]
        s = {"calls": 0, "cost": [], "latency": [], "noTool": 0, "clean": Counter(), "runsDone": Counter(),
             "hard": [], "mustNot": [], "caught": [], "shown": [], "codes": Counter(), "skipped": [],
             "dropped": 0, "worstMax": 0}
        report[model] = s
        for run_no in range(1, args.runs + 1):
            for e in entries:
                if not e["call"]:
                    if run_no == 1:
                        s["skipped"].append(e["id"])
                    continue
                pack = Pack(e["pack"])
                body = build_body(pack, model)
                worst = worst_nano(model, body)
                s["worstMax"] = max(s["worstMax"], worst)
                if SPENT[0] + worst > STOP_NANO:
                    sys.exit(f"stopped at the $1 ceiling: spent ${SPENT[0] / 1e9:.4f}, next call's worst case "
                             f"${worst / 1e9:.4f}")
                data, secs = stub_reply(body, e) if args.dry else post(key, body)
                nano = cost_nano(model, data.get("usage", {}))
                SPENT[0] += nano
                s["calls"] += 1
                s["cost"].append(nano)
                s["latency"].append(secs)
                s["runsDone"][e["id"]] += 1
                got = tool_input(data)
                if got is None:
                    s["noTool"] += 1
                    stop = data.get("stop_reason")
                    codes, caught, shown, dropped = ["V1"], [("(reply)", "", f"no proposePlan (stop {stop})",
                                                              ["V1"])], [], 0
                else:
                    codes, caught, shown, dropped = score(got, e, pack, event_titles)
                s["codes"].update(codes)
                s["dropped"] += dropped
                if not codes:
                    s["clean"][e["id"]] += 1
                if not codes and not any(row[1] == e["id"] for row in s["shown"]):
                    # The person columns score one run per pack: the first clean one.
                    s["shown"] += [(run_no, e["id"], slot, bid, expected_line(e, slot, bid), line)
                                   for slot, bid, line in shown]
                if set(codes) & HARD:
                    s["hard"].append((run_no, e["id"], sorted(set(codes) & HARD)))
                if set(codes) & MUST_NOT:
                    s["mustNot"].append((run_no, e["id"], sorted(set(codes) & MUST_NOT)))
                s["caught"] += [(run_no, e["id"], slot, bid, line, c) for slot, bid, line, c in caught]
    return report


def expected_line(entry, slot, bid):
    exp = entry.get("expect") or {}
    if slot == "ghost":
        return next((g["line"] for g in exp.get("ghostLines", []) if g["id"] == bid), "")
    if slot == "startWith":
        return (exp.get("startWith") or {}).get("line", "")
    if slot == "lineText":
        return next((b["lineText"] for b in exp.get("blocks", []) if b["id"] == bid), "")
    return exp.get("note") or ""


# ---------------------------------------------------------------------------------------------------------------
# The record.

def commit_id():
    """HEAD from .git without running git (no subprocess)."""
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
    return (text or "").replace("|", "\\|").replace("\n", " ")


def pctl(values, q):
    v = sorted(values) or [0]
    return v[min(len(v) - 1, int(len(v) * q))]


def write_report(report, args, selftest, fixture_path, stopped=None):
    total = sum(sum(s["cost"]) for s in report.values()) / 1e9
    calls = sum(s["calls"] for s in report.values())
    packs_hash = sha("\n".join(wire(p["pack"]) for p in selftest["fixture"]["packs"] if p["pack"] is not None))
    lines = [f"## {now_pt()}: {', '.join(report)}, {args.runs} run(s)"
             + (" (DRY: stub replies equal to each expected reply, nothing sent)" if args.dry else "")
             + (f" **stopped: {stopped}** (partial)" if stopped else ""), "",
             "| Field | Value |", "|---|---|",
             f"| Models | {', '.join(report)} |",
             "| Tool choice | auto (as ClaudePlanWording.send; Sonnet 5.5 refuses a forced tool) |",
             f"| Effort | low; max_tokens {MAX_TOKENS}; timeout {TIMEOUT_S:.0f} s; no retries |",
             f"| Runs | {args.runs} |",
             f"| Prompt hash | {sha(INSTRUCTIONS)} (PlanWording.swift `instructions`, {len(INSTRUCTIONS)} chars) |",
             f"| Schema hash | {sha(json.dumps(SCHEMA, sort_keys=True))} (PlanWording.swift `schemaText`) |",
             f"| Fixture hash | {Path(fixture_path).name} {sha(Path(fixture_path).read_bytes())}; wire packs "
             f"{packs_hash} |",
             f"| Checker | {CHECKER_VERSION} |",
             f"| Self-test | {selftest['packs']} packs, {selftest['called']} called, {selftest['expect']} expected "
             f"replies clean, {selftest['bad']} bad replies caught |",
             f"| Commit | {commit_id()} |", f"| Calls | {calls} |", f"| Spend | ${total:.4f} |", ""]
    for model, s in report.items():
        full = args.runs == 3
        called_d = [p for p in GATE_PACKS if s["runsDone"][p]]
        clean_d = [p for p in called_d if s["clean"][p] == args.runs]
        extra_ok = [p for p in EXTRA_PACKS if s["clean"][p] == args.runs
                    and not any(pid == p for _, pid, _ in s["hard"])]
        med = statistics.median(s["cost"]) / 1e9 if s["cost"] else 0
        p95c = pctl(s["cost"], 0.95) / 1e9
        top = max(s["cost"] or [0]) / 1e9
        p95l = pctl(s["latency"], 0.95)
        gate_note = "" if full else f" (only {args.runs} run(s): the gate needs 3)"
        lines += [f"### {model}", "",
                  f"Calls {s['calls']}; packs that make no call (scored on the app's builder): "
                  f"{', '.join(s['skipped']) or 'none'}. Ghost lines dropped beside a \"task\" block (G11): "
                  f"{s['dropped']}. Largest per-call worst case held: ${s['worstMax'] / 1e9:.4f}.", "",
                  "| Row | Bar | Result |", "|---|---|---|",
                  f"| Self-test | 100% before any call | {selftest['expect']}/{selftest['called']} expected clean, "
                  f"{selftest['bad']}/{EXPECT_BAD} bad caught |",
                  f"| Gate: d packs clean in {args.runs} of {args.runs}{gate_note} | 21 of 23 (d14, d22 make no "
                  f"call) | {len(clean_d)} of {len(called_d)} called; with d14 and d22 by the builder, "
                  f"{len(clean_d) + 2} of 23 |",
                  f"| P02, P14, P24 clean in {args.runs} of {args.runs}, 0 hard fails | 3 of 3, not counted | "
                  f"{len(extra_ok)} of 3 ({', '.join(extra_ok) or 'none'}) |",
                  f"| Hard fails (M-fmt 24-hour, HF-screened, HF-private, HF-event) | 0 | {len(s['hard'])} |",
                  f"| Must-nots (N1 to N7) | 0 in all calls | {len(s['mustNot'])} |",
                  f"| No proposePlan in the reply | report only | {s['noTool']} |",
                  f"| Cost per call, median | under $0.006 | ${med:.5f} |",
                  f"| Cost per call, p95 | under $0.008 | ${p95c:.5f} |",
                  f"| Cost per call, max | none over $0.0125 | ${top:.5f} |",
                  f"| Latency p95 | under 10 s | {p95l:.1f} s |",
                  f"| Timeouts at {TIMEOUT_S:.0f} s | 0 | {TIMEOUTS[0]} |",
                  "| True | 100% | (person) |", "| Plain | 90% or more | (person) |",
                  "| Not repeating | 95% or more | (person) |",
                  "| Tone: praises, judges or tells him what to do | 0 lines | (person) |",
                  "| Voice (Research ruling Oct 16) | 80% or more | (Research) |",
                  "| His read: a line he would take back | 0 | (Kaushik) |", ""]
        lines += ["#### Per pack (clean runs)", "", "| Pack | Clean | Codes seen |", "|---|---|---|"]
        seen = {}
        for r, pid, slot, bid, line, c in s["caught"]:
            seen.setdefault(pid, set()).update(c)
        for p in PACK_IDS:
            if s["runsDone"][p]:
                lines.append(f"| {p} | {s['clean'][p]} of {s['runsDone'][p]} | "
                             f"{', '.join(sorted(seen.get(p, []))) or 'none'} |")
        lines += ["", "#### Catches by code", ""]
        lines += [f"- {code}: {n} run(s)" for code, n in sorted(s["codes"].items())] or ["- none"]
        lines += [""]
        if s["caught"]:
            lines += ["#### Caught lines", "", "| Run | Pack | Slot | Block | Claude | Codes |",
                      "|---|---|---|---|---|---|"]
            lines += [f"| {r} | {pid} | {slot} | {bid} | {cell(line)} | {', '.join(c)} |"
                      for r, pid, slot, bid, line, c in s["caught"]] + [""]
        lines += ["#### Shown lines (the first clean run of each pack; a person scores each)", "",
                  "| Run | Pack | Slot | Block | Expected | Claude | True | Plain | Not repeating | Tone | Voice | "
                  "Why (fails) |", "|---|---|---|---|---|---|---|---|---|---|---|---|"]
        lines += [f"| {r} | {pid} | {slot} | {bid} | {cell(exp)} | {cell(line)} |  |  |  |  |  |  |"
                  for r, pid, slot, bid, exp, line in s["shown"]] or ["| | | | | | none | | | | | | |"]
        lines += [""]
    lines += ["### The 10 for Kaushik", "", "| # | Pack | Claude's line | Would you take it back? |",
              "|---|---|---|---|"]
    lines += [f"| {n} |  |  |  |" for n in range(1, 11)] + ["", "Scorer: (name)", ""]
    path = Path(args.out) if args.out else RESULTS
    title = "# Plan my day eval: results"
    intro = [title, "", "Written by `scripts/ai/plan_my_day_eval.py`, one section per invocation, newest first. "
             "Pass bar: `plan-rerun-plan.md` and `plan-my-day-claude.md` section 5. Person scores and the verdict "
             "go to `plan-my-day-eval-scores.md`.", ""]
    old = path.read_text() if path.exists() else ""
    if old.startswith(title):
        head, sep, rest = old.partition("\n## ")
        text = head.rstrip("\n") + "\n\n" + "\n".join(lines) + ("\n## " + rest if sep else "")
    else:
        text = "\n".join(intro + lines) + ("\n" + old if old else "")
    path.write_text(text.rstrip("\n") + "\n")
    print(f"wrote {path.relative_to(ROOT) if path.is_relative_to(ROOT) else path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", default="sonnet", help="sonnet (default), or sonnet,haiku for a comparison")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--dry", action="store_true", help="build every request, score a stub reply, send nothing")
    ap.add_argument("--out", help="results path under docs/ (default docs/ai/plan-my-day-eval-results.md)")
    ap.add_argument("--fixture", help=argparse.SUPPRESS)  # self-test of another fixture, with --dry only
    args = ap.parse_args()
    if not 1 <= args.runs <= MAX_RUNS:
        sys.exit(f"--runs must be 1 to {MAX_RUNS}")
    if args.out and not Path(args.out).resolve().is_relative_to(DOCS.resolve()):
        sys.exit("--out must be under docs/")
    args.models = [m.strip() for m in args.models.split(",") if m.strip()]
    if not args.models or any(m not in MODELS for m in args.models):
        sys.exit(f"--models must be from {', '.join(MODELS)}")
    if args.fixture and not args.dry:
        sys.exit("--fixture is for a --dry self-test only")
    event_titles = source_event_titles()
    fixture_path = Path(args.fixture) if args.fixture else FIXTURE
    selftest = self_test(fixture_path, event_titles)  # exits before any call on a mismatch
    if args.fixture:
        print("--fixture: self-test only; nothing built for sending, nothing written")
        return
    key = None
    if not args.dry:
        # Cloud sessions withhold ANTHROPIC_API_KEY, so the Tess environment carries TESSERA_CLAUDE_KEY.
        key = os.environ.get("TESSERA_CLAUDE_KEY") or os.environ.get("ANTHROPIC_API_KEY")
        if not key:
            sys.exit("TESSERA_CLAUDE_KEY is not set. Put it in the environment, never in a file or a chat.")
    report = {}
    try:
        run(args, key, report, selftest["fixture"], event_titles)
    except SystemExit as stop:
        # The $1 stop, an API error, a timeout or a network error: keep what was spent and returned, then exit.
        if any(s["calls"] for s in report.values()) or TIMEOUTS[0]:
            write_report(report, args, selftest, fixture_path, stopped=str(stop.code))
        raise
    for model, s in report.items():
        print(f"{'[dry] ' if args.dry else ''}{model}: calls={s['calls']} clean="
              f"{sum(s['clean'].values())} hard={len(s['hard'])} mustNot={len(s['mustNot'])} "
              f"no call: {', '.join(s['skipped']) or 'none'} spend=${sum(s['cost']) / 1e9:.4f}")
    write_report(report, args, selftest, fixture_path)


if __name__ == "__main__":
    main()
