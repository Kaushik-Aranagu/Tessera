# Plan my day: prompt pack for model-layer T6

For: Core engine (T6, M4 slice 6b). Owner: Research lab.
Date: 2026-10-15
Inputs: `tess-model-layer.md` (sections 2, 5, 6, 11, 12), `plan-my-day-scenarios.md` (20 fixtures, rules R1 to R8), `tess-voice.md` (incl. Model layer lines), `shutdown-daylog-copy.md`, `../product/ship-list-m4.md` (slices 6, 6b).

**What exists on origin/master (`5956550`).** No `DayPlan`, `PlanMyDay` or `proposePlan` code on any branch yet; slice 6 is unbuilt. `TessVoice` (with `bannedWords` and `violations(in:)`) lives in `TesseraCore/Sources/TesseraTess/TessCapturing.swift`. Foundation Models is used only in `TessModelCapture.swift` (`LanguageModelSession`, `RegistryTool` over `DynamicGenerationSchema`). No `@Generable` type exists yet. Names below that don't exist yet are proposals: `DayPlan` (slice 6 output), `TessUse.planWording`, `PlanPack`, `ProposePlan`, `PlanProposalValidator`.

**Shape of the call.** One structured response, no tool loop: `session.respond(to: pack.json, generating: ProposePlan.self)` with `tools: []`. Section 11 already routes whole-response output this way; the package sends it as Claude structured outputs. "proposePlan" is the schema's name. Raw-client fallback: same JSON schema as structured output, or as a strict tool with `tool_choice: auto` (Sonnet 5.5 rejects forced tool choice); a text-only reply simply fails V1.

**Word limit, a conflict.** The board says "12 words or fewer". `TessVoice.violations` rejects at `words.count >= 12`, so 11 is the real limit. The prompt says 11; the validator reuses `violations` unchanged.

## 1. Instructions text (stable, paste-ready)

About 450 tokens (1,900 characters), a little over the 400 target; every line earns its place. No dates, names or variables, so the bytes never change between calls. The pack goes in the prompt, not appended to the instructions (the sketch in `tess-model-layer.md` section 1 appends it; for this use, don't).

```
You are Tess, the voice of Tessera, a personal planning app for one person.

The app's rules have already built today's plan. It is correct. You word it, and you may lightly reorder tasks. Reply only with proposePlan.

Plan rules
- Return every input block once, with its exact id. Never add, drop, merge or split a block. Titles are shown by the app; you never change them.
- Blocks marked "fixed" (events, the workout, timed tasks) keep their exact start and end.
- Other blocks have a "run": tasks back to back in one gap. You may change their order inside their run only, then pack them back to back from the run's first start, each keeping its "min". Never move a task to another run. Keeping the input order is always fine.
- ghostLines: one line per run block, same ids, never more than 3.
- startWith: the earliest block that is not an event, with one line. Null if there is none.
- lineText: "" for run blocks. For fixed blocks usually "", or a short line tying it to a task.
- note: one line about the whole day, or null. Usually null.

Voice
- Every line 11 words or fewer. Plain, warm, a little dry. Point first.
- Say what the title doesn't: length, timing, or what it sits next to. Invent nothing.
- Offer, never instruct. No "should", "need to" or "don't forget".
- No greetings, praise, apologies, emoji or exclamation marks.
- Nothing that grades the day or the person: never missed, failed, behind, overdue, late, again, only, streak.
- Numbers: times as HH:mm from the input or your block times, durations as the given minutes. No counts of anything.
- Never mention sleep, energy, tiredness, health, or why the plan is short. When "light" is true, keep the wording gentle, leave the workout's lineText empty, and if the workout is startWith, its line is just its title and time.
- Never advise on training. Mention people, places and things only as they appear in titles.
```

## 2. Input format (the context pack, per call)

Built by `TessContextPack` for `TessUse.planWording` from the slice 6 `DayPlan`, after the rules have run. Compact JSON, keys in a fixed order (`JSONEncoder` with `.sortedKeys`), one line on the wire.

**In:** `weekday` (Mon to Sun, no date), `now`, `window` (`[from, to]`), `light` (bool), `cap` (2 or 3), `allDay` (titles), `blocks`. Per block: `id` (short handle), `kind` (`event`, `workout`, `timedTask`, `task`), `title`, `start`, `end`, `min`, and either `"fixed": true` or `"run": n`. Optional: `due` (only when the block ends by it), `movedFrom` (workout moved by R3/A7).

**Out, always:** sleep and energy values, the card line (it holds "slept 7h25"), `lighterTopSet` (the engine draws that offer itself), notes, set history, `rolls`, `rolledFrom`, carried-over flags, `updatedAt`, `priority`, declined events, `notPlanned` and `offerLater` tasks, `training.missed`, object UUIDs.

**Handles, not UUIDs.** Ids are `t1..t3` (run tasks), `e1..eN` (events), `k1..` (timed tasks), `w1` (workout). `PlanPack` keeps `handles: [String: UUID]`; the engine maps back after validation. Shorter, no copy errors on 36-character ids, and object ids never leave the phone. "Same object ids" is checked on handles, which are 1:1 with objects.

**Pack rules the engine applies.** Drop `due` when the rules placed a task after it (d10 Prepare slides), so Tess can't point at it. A run is a maximal sequence of task blocks with no gap between them (`end == next.start`) and no fixed block in between. No call at all when the plan has no task blocks (d14): nothing to word.

Example (d01, about 230 tokens):

```json
{"allDay":[],"blocks":[
{"id":"t1","kind":"task","title":"Reply to landlord","start":"08:00","end":"08:15","min":15,"run":1},
{"id":"t2","kind":"task","title":"Expense report","start":"08:15","end":"09:00","min":45,"run":1,"due":"17:00"},
{"id":"t3","kind":"task","title":"Book physio","start":"09:00","end":"09:20","min":20,"run":1},
{"id":"e1","kind":"event","title":"Standup","start":"09:30","end":"09:45","min":15,"fixed":true},
{"id":"e2","kind":"event","title":"Design review","start":"11:00","end":"12:00","min":60,"fixed":true},
{"id":"e3","kind":"event","title":"1:1 Priya","start":"15:00","end":"15:30","min":30,"fixed":true},
{"id":"w1","kind":"workout","title":"Push A","start":"18:00","end":"19:00","min":60,"fixed":true}],
"cap":3,"light":false,"now":"08:00","weekday":"Mon","window":["08:00","21:00"]}
```

## 3. `proposePlan` schema

**Ordering, per ship-list 6b ("rewords and reorders the rules plan").** Allowed: permute tasks inside one run, repacked back to back from the run's first start. Not allowed: moving a task to another gap, changing any length, touching fixed blocks. This keeps every proposal rules-valid by construction (due times, cook after 18:00 and window all hold, since the run's span is unchanged) and makes "lightly reorders" checkable. Moving tasks across gaps is parked until evals show the run rule is too tight.

Strict JSON schema (raw route and evals; strict mode allows no `maxItems` or patterns, so V-rules enforce them):

```json
{
  "name": "proposePlan",
  "description": "Tess's wording and light reorder of today's rules plan.",
  "strict": true,
  "input_schema": {
    "type": "object",
    "additionalProperties": false,
    "required": ["blocks", "startWith", "ghostLines", "note"],
    "properties": {
      "blocks": {
        "type": "array",
        "description": "Every input block once, same id, in time order.",
        "items": {
          "type": "object",
          "additionalProperties": false,
          "required": ["id", "start", "end", "lineText"],
          "properties": {
            "id":       {"type": "string", "description": "An input id, copied exactly."},
            "start":    {"type": "string", "description": "HH:mm, 24-hour."},
            "end":      {"type": ["string", "null"], "description": "HH:mm, or null for start plus min."},
            "lineText": {"type": "string", "description": "11 words or fewer. \"\" for run blocks."}
          }
        }
      },
      "startWith": {
        "anyOf": [
          {"type": "object", "additionalProperties": false, "required": ["id", "line"],
           "properties": {"id": {"type": "string"}, "line": {"type": "string"}}},
          {"type": "null"}
        ]
      },
      "ghostLines": {
        "type": "array",
        "description": "One accept-or-skip line per run block. At most 3.",
        "items": {"type": "object", "additionalProperties": false, "required": ["id", "line"],
                  "properties": {"id": {"type": "string"}, "line": {"type": "string"}}}
      },
      "note": {"type": ["string", "null"], "description": "One line about the day, usually null."}
    }
  }
}
```

Swift sketch (package route, in `TesseraTess`):

```swift
import FoundationModels

@Generable(description: "Tess's wording and light reorder of today's rules plan")
struct ProposePlan {
    @Guide(description: "Every input block once, same id, in time order")
    var blocks: [ProposedBlock]
    @Guide(description: "The earliest block that is not an event; nil when there is none")
    var startWith: PlanLine?
    @Guide(description: "One accept-or-skip line per run block", .maximumCount(3))
    var ghostLines: [PlanLine]
    @Guide(description: "One line about the whole day; usually nil")
    var note: String?
}

@Generable struct ProposedBlock {
    @Guide(description: "An input id, copied exactly") var id: String
    @Guide(description: "HH:mm, 24-hour", .pattern(/([01]\d|2[0-3]):[0-5]\d/)) var start: String
    @Guide(description: "HH:mm, or nil for start plus min") var end: String?
    @Guide(description: "11 words or fewer; empty for run blocks") var lineText: String
}

@Generable struct PlanLine {
    @Guide(description: "An input id") var id: String
    @Guide(description: "One line, 11 words or fewer") var line: String
}

// ClaudeTessModel, use .planWording (Sonnet 5.5, 20 s timeout, maxTokens 1,024)
let session = LanguageModelSession(model: claude, tools: [], instructions: PlanWording.instructions)
let reply = try await session.respond(to: pack.json, generating: ProposePlan.self,
                                      options: GenerationOptions(maximumResponseTokens: 1_024))
let problems = PlanProposalValidator.violations(reply.content, against: pack)
let plan = problems.isEmpty ? rulesPlan.applying(reply.content, handles: pack.handles) : rulesPlan
```

UNVERIFIED: whether the package turns `.maximumCount` and `.pattern` into JSON Schema keywords or drops them. The validator is the gate either way.

## 4. Validation rules (`PlanProposalValidator`)

All run before anything shows. Any violation: show the rules plan as is, silently. Log `Logger(subsystem: "com.kaushikaranagu.tessera", category: "tess.plan").debug("plan rejected: \(codes)")` and write the `TessCall` with outcome `rejected` and the codes. Never log the pack or Claude's text (privacy). The rules plan renders first; a valid proposal swaps the wording in.

| # | Rule | Check |
|---|---|---|
| V1 | Shape | Decodes as `ProposePlan`. No duplicate ids anywhere |
| V2 | Same objects | Set of `blocks.id` equals the pack's id set. Nothing added, dropped or unknown |
| V3 | Fixed blocks don't move | Every `fixed` block has the input `start` and `end` exactly. Covers events, the workout and timed tasks |
| V4 | Light reorder only | Each run's blocks stay in that run, back to back from the run's input start, each with its input `min` (`end` null means start + min). Order inside the run is free |
| V5 | Window | Every run block lies inside `window`. Fixed blocks are exempt (d12: Design crit began 11:00, before the 11:10 window) |
| V6 | No overlap | No two blocks overlap; touching is fine |
| V7 | Ghost lines | `ghostLines` ids equal the run-block ids; count at most 3 and at most `cap`; each line non-empty |
| V8 | Start with | `startWith.id` is the earliest non-event block in the proposal (task, timed task or workout), per R8; null only when there is none. Line non-empty |
| V9 | Lines | For every `lineText`, ghost line, start line and note: `TessVoice.violations(in:)` is empty (11 words max, one line, no "!", no emoji, the 8 base banned words). `lineText` is "" for run blocks |
| V10 | Plan banned words | Also none of: missed, failed, behind, overdue, late, again, only, finally, skipped, slipped, lazy, backlog, "catch up", "need to", "don't forget", "remember to", lighter, "go easy", "take it easy", "push through". Token match, so "Later" is not "late" |
| V11 | No new numbers | Times (`9:30`, `09:30`, `8am`) must equal a time in the pack or in the proposal's own blocks. Durations (`15 min`, `2 hours`, `1.5 h`) must equal some block's `min` (hour forms convert). Any other number, digit or word from "two" up, must appear as a token in a pack title ("PR 412", "Interview 4"). So counts like "3 tasks" fail |
| V12 | No health words | None of: sleep, slept, sleepy, tired, exhausted, fatigue, energy, rested, recovery, recover, heart, HRV, steps, sore, sick, unwell, drained, burnout. A word that appears in a pack title is exempt ("Book physio", "Call GP", "Dentist") |

Not checkable, accepted: a line that invents content within the rules ("bring the mocks"). The instruction "Invent nothing" and the weekly 20-line read cover it.

Timeouts, 429/529 and the cap also fall back to the rules plan. `tess-voice.md` M18/M22 give plan lines ("Claude timed out. Here's the rules plan."). Since the rules plan is already on screen, I recommend no line for plan (voice rule 7: nothing changed for him). Product to confirm.

## 5. Worked examples

### Example 1: normal day (d01)

Input pack: as in section 2.

Ideal output (Tess moves the two short tasks ahead of the report; all three still finish before Standup):

```json
{"blocks":[
 {"id":"t1","start":"08:00","end":"08:15","lineText":""},
 {"id":"t3","start":"08:15","end":"08:35","lineText":""},
 {"id":"t2","start":"08:35","end":"09:20","lineText":""},
 {"id":"e1","start":"09:30","end":"09:45","lineText":""},
 {"id":"e2","start":"11:00","end":"12:00","lineText":""},
 {"id":"e3","start":"15:00","end":"15:30","lineText":""},
 {"id":"w1","start":"18:00","end":"19:00","lineText":""}],
 "startWith":{"id":"t1","line":"Landlord reply first, then physio, then the report."},
 "ghostLines":[
  {"id":"t1","line":"15 min, a quick one to open with."},
  {"id":"t3","line":"20 min, while the morning is quiet."},
  {"id":"t2","line":"45 min, done before Standup. Due 17:00."}],
 "note":null}
```

Validation: pass. V2 7 of 7 ids. V3 e1 to e3 and w1 unchanged. V4 run 1 is t1, t3, t2 packed from 08:00 with 15, 20, 45 min, ends 09:20. V5, V6 hold. V7 3 lines, cap 3. V8 t1 is the earliest non-event. V9 longest line 8 words. V11 "15 min", "20 min", "45 min" match `min`; "17:00" is t2's `due`; "one" is not a counted number word. V12 "physio" is not on the list, and would be exempt anyway (title).

Rejected variant: start line "Two quick ones, then the report." fails V11 ("two" is a count, not in any title).

### Example 2: overbooked day (d10)

Input pack (Write board memo was offered to Later by R7, so it is not sent; Prepare slides was placed after its 12:00 due, so `due` is dropped):

```json
{"allDay":[],"blocks":[
{"id":"t1","kind":"task","title":"Fix expense claim","start":"08:00","end":"08:30","min":30,"run":1},
{"id":"e1","kind":"event","title":"Prep call","start":"08:30","end":"09:00","min":30,"fixed":true},
{"id":"e2","kind":"event","title":"Board prep","start":"09:00","end":"10:30","min":90,"fixed":true},
{"id":"e3","kind":"event","title":"Roadmap workshop","start":"10:30","end":"12:00","min":90,"fixed":true},
{"id":"t2","kind":"task","title":"Call plumber","start":"12:00","end":"12:15","min":15,"run":2},
{"id":"e4","kind":"event","title":"Lunch 1:1 Dev","start":"12:30","end":"13:00","min":30,"fixed":true},
{"id":"e5","kind":"event","title":"Customer workshop","start":"13:00","end":"15:30","min":150,"fixed":true},
{"id":"e6","kind":"event","title":"Sync with Lee","start":"15:30","end":"16:00","min":30,"fixed":true},
{"id":"e7","kind":"event","title":"Exec review","start":"16:00","end":"17:30","min":90,"fixed":true},
{"id":"e8","kind":"event","title":"Wrap-up","start":"17:30","end":"18:00","min":30,"fixed":true},
{"id":"w1","kind":"workout","title":"Pull A","start":"18:00","end":"19:00","min":60,"fixed":true},
{"id":"t3","kind":"task","title":"Prepare slides","start":"19:00","end":"20:00","min":60,"run":3}],
"cap":3,"light":false,"now":"08:00","weekday":"Wed","window":["08:00","21:00"]}
```

Ideal output (no reorder possible: three runs of one):

```json
{"blocks":[
 {"id":"t1","start":"08:00","end":"08:30","lineText":""},
 {"id":"e1","start":"08:30","end":"09:00","lineText":""},
 {"id":"e2","start":"09:00","end":"10:30","lineText":""},
 {"id":"e3","start":"10:30","end":"12:00","lineText":""},
 {"id":"t2","start":"12:00","end":"12:15","lineText":""},
 {"id":"e4","start":"12:30","end":"13:00","lineText":""},
 {"id":"e5","start":"13:00","end":"15:30","lineText":""},
 {"id":"e6","start":"15:30","end":"16:00","lineText":""},
 {"id":"e7","start":"16:00","end":"17:30","lineText":""},
 {"id":"e8","start":"17:30","end":"18:00","lineText":""},
 {"id":"w1","start":"18:00","end":"19:00","lineText":""},
 {"id":"t3","start":"19:00","end":"20:00","lineText":""}],
 "startWith":{"id":"t1","line":"Expense claim first, before Prep call."},
 "ghostLines":[
  {"id":"t1","line":"30 min, before the first call."},
  {"id":"t2","line":"15 min between workshops."},
  {"id":"t3","line":"After Pull A. 60 min, then the evening is yours."}],
 "note":"Meetings until 18:00. Each task fits a gap."}
```

Validation: pass. V2 12 of 12. V3 all 8 events and w1 unchanged. V4 three runs of one, unchanged. V7 3 lines. V8 t1. V9 longest 10 words (t3). V11 "18:00" is e8's end; "30 min", "15 min", "60 min" match. V10 the note has no count and no grading.

Rejected variants: note "8 meetings today, so 3 short tasks." fails V11 ("8" and "3" are counts; "Lunch 1:1 Dev" only licenses "1"). Moving t3 to "12:15" to beat its due fails V4 and V6.

### Example 3: light-energy day (d04, energy 2)

Input pack (energy is never sent; only `light` and `cap`; the lighter top set on Push B is drawn by the engine):

```json
{"allDay":[],"blocks":[
{"id":"t1","kind":"task","title":"Draft Q4 goals","start":"08:00","end":"09:00","min":60,"run":1,"due":"17:00"},
{"id":"t2","kind":"task","title":"Pay council tax","start":"09:00","end":"09:10","min":10,"run":1},
{"id":"e1","kind":"event","title":"Standup","start":"09:30","end":"09:45","min":15,"fixed":true},
{"id":"e2","kind":"event","title":"Client call","start":"10:00","end":"11:00","min":60,"fixed":true},
{"id":"e3","kind":"event","title":"Team lunch","start":"12:30","end":"13:30","min":60,"fixed":true},
{"id":"w1","kind":"workout","title":"Push B","start":"18:00","end":"19:00","min":60,"fixed":true}],
"cap":2,"light":true,"now":"08:00","weekday":"Thu","window":["08:00","21:00"]}
```

Ideal output (small task first as an easy start):

```json
{"blocks":[
 {"id":"t2","start":"08:00","end":"08:10","lineText":""},
 {"id":"t1","start":"08:10","end":"09:10","lineText":""},
 {"id":"e1","start":"09:30","end":"09:45","lineText":""},
 {"id":"e2","start":"10:00","end":"11:00","lineText":""},
 {"id":"e3","start":"12:30","end":"13:30","lineText":""},
 {"id":"w1","start":"18:00","end":"19:00","lineText":""}],
 "startWith":{"id":"t2","line":"Council tax first, then the goals draft."},
 "ghostLines":[
  {"id":"t2","line":"10 min. Small, and done early."},
  {"id":"t1","line":"60 min, finished before Standup. Due 17:00."}],
 "note":null}
```

Validation: pass. V4 run 1 is t2, t1 from 08:00, ends 09:10, before Standup. V7 2 lines, cap 2. V9 w1 `lineText` "" as the light rule asks. V11 "10 min", "60 min", "17:00" all in the pack. V12 no health word; "Q4" is not a bare number.

Rejected variants: note "Kept it light since energy is low." fails V12 ("energy"). w1 `lineText` "Go easy on the top set." fails V10 ("go easy").

## 6. Hand check across the 20 scenarios

Checked by reading each fixture's expected plan through the pack rules, then judging what Sonnet 5.5 at `effort: low` would most likely return under the instructions above, against V1 to V12 as written (all-or-nothing). "Pass" means the likely output passes; "At risk" means a plausible output fails; "Likely fail" means the most tempting output fails.

| Id | Pack in short | What Sonnet likely does | Verdict | Risk |
|---|---|---|---|---|
| d01 | Run of 3, 3 meetings, gym | Short tasks first (Example 1) | Pass | Repacking arithmetic across 3 tasks; a count in the start line ("Two quick ones") |
| d02 | Run of 2, then garage 120 min alone | Keeps order; "Garage, 2 hours" | Pass | "2 hours" passes only because V11 converts hours to `min` |
| d03 | Light, cap 2, Arjun email + PR 412 | Gentle lines, maybe email first | Pass | Saying "easy morning" or why there are 2; "412" is licensed by the title |
| d04 | Light, cap 2 (Example 3) | Tax first | Pass | A workout line about going lighter (V10) |
| d05 | Run of 3; gym `movedFrom` 18:00 to 18:30 | w1 line "After Vendor call, at 18:30." | Pass | Temptation to move the gym or the Vendor call back (V3) |
| d06 | Sat; Call mum, garage, carbonara in 3 runs; Parkrun + Legs B | Neutral lines, cook "at dinner" | Pass | Training advice on Legs B after Parkrun (V10 if "go easy"); moving Call mum to 09:00 (V4, V6) |
| d07 | Sun rest day, run of 3, brunch | Short, relaxed lines | Pass | "Rest day" is fine; risk is a count ("3 small ones") |
| d08 | No sleep data (not sent), 2 runs | Plain lines | Pass | None notable; nothing about sleep is in the pack |
| d09 | Push A (the rolled-on workout), landlord reply | Plain lines | Pass | Would say "again" if `training.missed` or `rolls` were sent; they aren't |
| d10 | 8 meetings, 3 runs of 1 (Example 2) | Writes a note about the packed day | At risk | Note counting meetings or tasks (V11); wanting slides before noon (V4, V6); Board memo can't leak, it isn't sent |
| d11 | All-day Mum's birthday; flowers due 12:00; Call mum fixed 19:30 | "For Mum's birthday" on flowers | Pass | Moving Call mum earlier (V3) |
| d12 | Now 11:07, window 11:10; Design crit 11:00 to 11:30 in progress; run of 3 | "Starting after Design crit." | At risk | "late start" or "behind" (V10); a validator without the fixed-block window exemption rejects every proposal here (V5) |
| d13 | Run of 3 of 30 min; Pull B at 17:00 | Plain lines | Pass | Wanting the gym in the morning on a Saturday (V3) |
| d14 | Empty day | Not sent | Pass | No call: no task blocks to word, $0 |
| d15 | Call GP + receipts; Dentist fixed 15:00 | Plain lines | Pass | Health-adjacent wording beyond titles ("check-up", "appointments"); titles are exempt from V12 |
| d16 | Run of 3 (30, 10, 5); priority not sent | Maybe NDA first | Pass | Repacking 3 uneven lengths |
| d17 | 5 events, 2 runs; offsite plan (noFit) not sent | Note about an interview day | At risk | Note "5 interviews" fails V11 ("4" alone is licensed by "Interview 4") |
| d18 | Light, cap 2; Legs A 08:00 is startWith | Start line about going lighter | Likely fail | "Legs A at 08:00. Lighter top set if you want." fails V10 ("lighter") and leaks why |
| d19 | Library book + Lisbon run; Cook chilli 90 min after gym | "After Push B, 90 min" | Pass | "1.5 hours" passes via the hour conversion; "an hour and a half" passes |
| d20 | Sat 09:00; finished workout (no block); 2 runs | Plain lines | Pass | None notable; the finished workout isn't sent |

**Result: 16 of 20 pass as written** (d14 by not calling). 3 at risk (d10, d12, d17), 1 likely fail (d18). With the tweaks below, all 20 are expected to pass; T6's live eval should run each scenario 3 times because wording varies.

**Most likely to fail, and the fix.**

| Scenario | Why | Prompt tweak | Validation tweak |
|---|---|---|---|
| d18 | Light day plus a workout as startWith pulls Tess toward the lighter top set | Already in the prompt: on a light day the workout's start line is just title and time | On light days the engine replaces a failing workout start line with "{title} at {start}." instead of rejecting |
| d10 | Packed days tempt a summary note with counts | "No counts of anything" (in); add "On a full day, a note is optional; never count" if evals show it | Drop a failing `note` and keep the rest (the one exception to all-or-nothing). Turns most d10 and d17 failures into passes |
| d17 | Same: note counts interviews | As d10 | As d10 |
| d12 | Late open invites "late" and "behind"; in-progress event starts before the window | Banned words already listed in the prompt | Fixed blocks exempt from V5 (built in); keep "late" in V10 |
| Cross-cutting: runs of 3 (d01, d05, d07, d13, d16) | Repacking arithmetic can drift 5 minutes | None | If V4 fails only on times while the order is a valid permutation of the run, the engine repacks the run itself (Claude's order, engine's times) |
| Cross-cutting: hour forms (d02, d06, d19, d20) | "2 hours" for 120 min | Prompt asks for minutes | V11 hour conversion (built in) |

## 7. Cost per call (Sonnet 5.5: $2 input, $10 output, $0.10 cache read per million)

| Part | Tokens (estimate) |
|---|---|
| Instructions | ~450 |
| Schema as sent by the package (structured output) | ~300 (UNVERIFIED how the package serialises it) |
| Pack | ~230 (d01) to ~380 (d10) |
| Input total | ~1,000 to 1,150 |
| Output: JSON | ~250 (d01) to ~400 (d10) |
| Output: thinking at `effort: low` | 0 to ~200 |

| Case | Input | Output | Cost |
|---|---|---|---|
| Typical day (d01) | 1,000 | 400 | $0.0020 + $0.0040 = ~$0.006 |
| Busy day (d10) | 1,150 | 600 | $0.0023 + $0.0060 = ~$0.008 |
| Cap pre-check worst case (`maxTokens` 1,024) | 1,150 | 1,024 | ~$0.0125 |
| One month, 30 mornings | | | ~$0.20 |
| One eval pass over 20 scenarios x 3 runs | | | ~$0.40 |

Caching: the stable prefix (instructions plus schema, ~750 tokens) is probably under Sonnet's minimum cacheable length, so expect no cache reads (UNVERIFIED for 5.5; T3 measures). If it did cache, it would save about $0.0013 a call. This sits inside the $0.25 a month the model-layer brief estimated and far under the $10 cap.

## Assumptions and open items

- ASSUMED: run-only reordering is enough for "reorders" in 6b. If Product wants cross-gap moves, V4 becomes "inside window, no overlap, ends by `due`, cook at or after 18:00" and the prompt's run paragraph changes; expect lower pass rates.
- ASSUMED: one `startWith` line and up to 3 ghost lines are new copy only; accept and skip still set `startsAt` through the op log exactly as slice 6 does.
- ASSUMED: no line for plan fallbacks (timeout, busy, cap), conflicting with M18/M22's plan variants. Product to pick.
- UNVERIFIED: `@Guide` `.maximumCount` and `.pattern` mapping in the Claude package; package schema token count; cacheable minimum for Sonnet 5.5.
