# The `homeLines` job (ship list AI-4, with AI-10's memory)

One page for Core's PR and Builder B's swap-in. It sits on `claude-client.md` (AI-2), `line-check-vectors.md`
(AI-3), `home-lines.md` (slots), `memory-store.md` (shape A) and `architecture.md` sections 5 and 6. "New" marks
anything that doesn't exist yet. Where the docs and the code differ, the list at the end says so.

**For the done job only sections 2a to 2c apply.** Sections 2 to 4, and tests 2 to 5 and 9 in section 8, are the old all-Home job and are kept as history.

## 1. The job

```swift
/// new. Static bytes: the same instructions and tool every call, so the prefix caches and snapshots hold.
static let homeLines = TessJob(
    name: "homeLines",
    model: HomeLinesModel.chosen,   // AI-5 decides; "claude-sonnet-5-5" until it does. Must be a key of prices
    maxTokens: 512, effort: "low", timeout: 6,
    instructions: TessVoice.house + HomeLinesJob.rules,   // home-lines.md section 2, as instructions
    output: HomeLinesJob.proposeLines, writeTools: [],
    memory: [],                     // AI-4 ships with none; AI-10 sets [.told, .noticed, .recent]
    priority: .lines,
    toolChoice: HomeLinesModel.chosen.hasPrefix("claude-haiku") ? .forced : .auto)
```

`proposeLines` (strict): `{"lines": [{"item": "h1", "context": "...", "detail": "..."}]}`. `item` is the pack's
handle (`h1`, `h2`, in Home order), never a UUID. `context` and `detail` are optional strings; leaving one out
keeps that slot's rules words. Sonnet runs with auto: no tool call is `.noLine`, every rules line stays. Haiku runs
forced, as the AI-5 run does (`eval-rubric.md` section 1). Max tokens is a suggestion: 150 out is the estimate
(`spend-projection.md`), and 512 leaves room for a full Home without inviting prose.

## 2. The pack (`HomeLinesPack.build`, new)

`<facts>` holds, per item that is not `fixed` (a live workout, a done workout with no sets): the handle, kind,
title, state, the hero, the day label, the rules context and detail, `numbers`, `names`, and times as clock words
("7:40 pm", "this evening"). Counts come from `HomeFact`: sets done, exercises done of planned, step of steps, items
left, to buy, days since last, bests. Nothing else: no weights, reps, volume, notes, places, health, money,
people. A fixed item is not packed at all; a line for an unknown or fixed handle fails C1 or C14.

**Ticking values never enter the pack.** A paused item's "paused 21 min ago" (`HomeLines.ago`) changes every minute,
so its context slot is rules only and is left out of the pack; only its detail goes. The same holds for "just now"
and "2 h ago". Its `numbers` drop those digits too.

**AI-10 memory block (shape A).** Before `<facts>`, one `<memory>` block from the shared builder in
`memory-store.md` section 4: told lines that match an item (Training and Kitchen areas, by title or exercise
word), up to 10 noticed lines (Training and Kitchen), the last 7 recent lines. Never About you, never People,
never a private line. Each item also carries `fits: [ruleId]`: the noticed rules today agrees with (the slot, the
weekday), so "usual" is allowed only when `fits` is not empty (Research 124 H-M1 to H-M3).

## 2a. After AI-5: the narrowed job (Oct 16, PR #488)

AI-5 found Claude adds a true fact only on done workouts; everywhere else it padded ("After work, your usual slot",
once on a Saturday). So the job narrows before anything ships:

- **Packed items:** only a done workout with a best (`records` not empty; the field is an old code name, to be renamed `bests`) or 4 or more days since the same routine, counted in house days (`daysSinceLastRun`, 4 am turnover).
  Every other item keeps its rules lines and is never packed. A Home with no such item makes no call at all.
- **Instructions:** `scripts/ai/home_lines_eval.py` `DONE_RULES` is the text to copy. It opens with Research's rule:
  "Return the rules line unchanged unless you add one true fact it lacks", and bans "usual", "as usual" and a
  restated time of day.
- **The `fits` rule is memory-only and off for the done job** (there is no memory block): AI-5's Saturday slip, a "usual" with no matching weekday, is covered by the phone's house-day check and the banned words in section 2c item 4.
- Kaushik read the rerun and chose Sonnet on Home for this job (section 2b).

## 2b. Kaushik's decision (Oct 16, 2026, 2:41 PM PT): Sonnet on Home

He chose "Sonnet on Home" over the recommended "App lines + gap" after reading the rerun (`home-lines-eval-results.md`, "Rerun verdict"). What ships:

- **Job done only.** A finished workout with a best, or one at least 4 days after the same routine. Sonnet 5.5, prompt `SYSTEM_DONE` from `scripts/ai/home_lines_eval.py`. Every other Home moment stays on rules.
- **Behind "Tess asks Claude"** and the monthly cap. The rules line shows first; Claude's differing words land wet and dry (section 6). A 6 s timeout, no retries, one call per finish, cached on the workout.
- **The phone checks every line** (caps: context at most 6 words and 32 characters, detail at most 14 words and 80 characters; C1 to C14 and the C15 house-day check of section 2c item 4); a line that fails keeps the rules line.
- **Gate:** Core's weekday check (0t, widened to all weekday and relative-day words in section 2c item 4) merges first. Money and body facts are never packed (section 2); the walls are in section 5.

## 2c. The done job: what Core copies (settles Research BG, Oct 16 2:42 PM PT)

Research's done-job fixtures (`docs/research/fixtures/home-done-job.md`, HD1 to HD24) found ten places where this page and the eval script disagree. For the done job, this section wins over sections 1 to 5 and over the script. The script is an eval harness. Core copies only its `SYSTEM_DONE` text, never its plumbing.

1. **Cache by workout id only.** One call per finish, ever. The entry is keyed by the workout's id and holds the words that passed. There is no day key and no facts hash, and nothing asks again at 4 am, on the switch turning on or on FORGET (AI-4 ships with no memory). A set added after the finish changes the rules line only; there is no second call (Product 2:42 pm). Sections 3 and 4 are for the old all-Home job and do not apply.
2. **No `now` and no `partOfDay` in a done pack.** The pack holds the routine title, the finish clock word, the `dayLabel` (for example "Thursday night", no wall-clock now), the bests, `sinceLastDays` and the rules line. A "now" invites a wrong "yesterday", and part of day would change a hash that no longer exists.
3. **6 s timeout, no retries.** The eval script's 30 s socket timeout and its retries exist only so an eval run survives a slow network. Core must not copy them. A timeout keeps the rules line, and that finish is never asked again.
4. **C15 is a house-day check, on the phone.** Refuse any weekday name or relative-day word ("yesterday", "today", "tonight", "tomorrow", "last night", "this morning", "this evening") that the finish's house day doesn't support (4 am turnover, `HouseTime`). This replaces the eval's memory-based `weekday_slip`, which never fires with `memory: []`. "usual", "as usual", "usually", "after work" and "before work" stay banned outright, with or without memory. HD11 to HD13 test it.
5. **Shape and tokens:** as section 1, with `{"lines": [{"item": "h1", "context"?, "detail"?}]}`, both slots optional, and max tokens 512. The script's `id` with both fields required, and its 1,500 tokens, are eval-only.
6. **Step-aside at $40 holds.** `.lines` steps aside at 80% of the $50 month like every lines job, so done lines are the first thing to go quiet before the cap. That is intended.
7. **C6 compares numbers, not digit strings.** Read each number in the line as a value ("8:05 pm" gives 8 and 5, "05" equals 5) and check it against `HomeLine.numbers`. A literal port of the script's string compare would refuse "8:05 pm, a bench best".
8. **Field name:** `HomeFact.sinceLastDays`. `lastSameRoutineDaysAgo` in the script and `first-features.md` is the same fact under an older name.

## 3. Cache and key

- **File** (new): `Application Support/Tessera/home-lines-cache.json`, excluded from backup, complete file
  protection, never in a `.tessera` backup. In memory too, so a redraw never reads disk.
- **Key:** the phone's day (`yyyy-MM-dd`, the day the label names, turning over at 04:00 with `turnover`) plus a
  SHA-256 facts hash over the exact `<facts>` and `<memory>` bytes, the job's instructions and the model string.
- **Entry:** per item handle hash, the words that passed, the verdict, and `memoryIDs` (the lines it read). A new
  day drops every entry. Words are run through `TessLineCheck` again on load, so a tightened check wins.
- **FORGET** drops every entry whose `memoryIDs` holds the forgotten line (H-M4, H-M5), before the next draw.

## 4. When a call is made

The coordinator (new, app side, `HomeLinesCoordinator`) asks only when the facts hash is new for today and no
cache entry covers it. That happens on: a state change (planned to running to paused to done), a count changing
on a non-fixed item, an item added or removed, a part-of-day word turning ("today" to "this evening"), the 04:00
turnover (new day, new memory block), a FORGET, and the switch turned on.

It must NOT ask on: a minute tick ("21 min ago" to "22 min ago"), a scroll, a redraw, foregrounding with the same
hash, a theme, Dynamic Type or Reduce Motion change, a widget timeline reload, sets logged in a live workout (the
item is fixed, and no call runs at all while a workout runs), a network coming back (no queue for lines), or demo.

- **Debounce: 10 minutes.** A change inside the window schedules one trailing call with the newest pack. Moments
  (a workout finishes, a process pauses, a cook is done) skip the window but still count.
- **40 a day.** Count today's `TessCall` rows whose `job` is "homeLines" (the AI-2 field), failures and `.noLine`
  included. At 40, rules lines until the next day; nothing visible changes.
- **Stale reply.** `stale` is "the facts hash changed since send"; a stale reply is dropped and its row says "late".

## 5. Validation, step-aside and walls

Each returned slot runs `TessLineCheck.check(slot:numbers:names:rulesLine:isDone:dayLabel:hero:)`, per item and
per slot. A fail keeps that slot's rules words and nothing visible happens; other slots still swap. The row's outcome
lists the codes ("rejected C6, C10"). AI-10 adds one rule: "usual" (or "your slot") with empty `fits` fails.
`ClaudeClient` already gives the rest: switch off, demo and no key send nothing; the money and SecretWords walls;
`.lines` steps aside at 80% of the month ($40 of $50); the cap returns `.refused(.cap)`.

**What shows.** Offline, busy, timeout, capped, stepped aside: cached words for unchanged items, rules elsewhere.
Switch off: rules lines only, cache ignored (and cleared). Demo (`-demo`, `-resetDemo`, `-theme`): rules lines, the
cache is never read or written. Any `Failure` line is never shown on Home; it is for Settings only.

## 6. On screen (Builder B, Design 41)

The rules line draws first, every time. When Claude's words differ, the slot redraws wet in `tess` and dries to its
resting colour on `Theme.Motion.dry`: `context` for the context line, `inkSecondary` for SO FAR. Identical words
never redraw. The hero, Next rows and day label never redraw for Claude. Cached words on a cold launch draw at rest,
with no drying (they are not news). No mark at rest. Reduce Motion: a crossfade. The step-down forms (Design 41 rule
2) apply to Claude's words exactly as to rules words; a line that wouldn't fit never arrived (C2, C3).

## 7. `touched`

`TessPack.touched` = the packed items' `HomeFact.id`s in Home order, then the memory block's ids. Never in the body
(handles are). The builder calls `markUsed` for the memory ids, so the page says "used today". The app gets them
through `onAsk` as `SoulEvent.askClaude(touched:)`.

## 8. Tests Core should write

1. Pack snapshot per fixture (H1 to H12, E1 to E20): titles, states, counts, times only; decode it and find no
   weight, rep, health, note, money, place or person word, and no digit outside `numbers`.
2. A paused item's pack is byte-identical at 21 and 22 minutes: no call, same hash.
3. Same day and hash: one call, then cache hits; a new day: a call; restore of a backup: no cache file comes back.
4. Debounce: three changes in 10 minutes give one trailing call; a workout finishing calls at once.
5. The 41st call of a day sends nothing (stub sees no request, no row).
6. A failing context keeps the rules context while a passing detail swaps; the row says "rejected" and the codes.
7. Sonnet with no tool call: `.noLine`, every rules line, no redraw. Haiku body carries the forced tool choice.
8. 80% month: no request, rules lines; switch off, demo, no key: no request, no cache read.
9. AI-10: the memory block holds no private, About you or People line; "your usual slot" fails without `fits` and
   passes with it (H5); FORGET drops the cached lines that read it (H-M4, H-M5); H2, E7, E15, E17, E18 pass.
10. `touched` UUIDs never appear in the captured body.

## Where code and docs differ

- **Home uses the lens now.** `Features/Home/NowPage.swift` builds the done line from `HomeLines.line`, so the slot exists (Research BG, Oct 16).
- **Model.** Architecture section 6 and 5.6 say Haiku; the ship list (Oct 16 reorder) says Sonnet. DECIDED (Product, decisions.md 11:45 AM PT Oct 16): Sonnet until AI-5 decides.
- **Drying.** `home-lines.md` says the house 2 s and a crossfade under Reduce Motion; `Theme.Motion.dry` is a 1.1 s
  spring after 0.4 s and returns nil under Reduce Motion (the colour settles).
- **Cold launch.** Architecture 5.5 shows yesterday's Claude lines for unchanged facts; this note keys by day, so a
  new day starts on rules lines. DECIDED (Product, decisions.md 11:45 AM PT Oct 16): rules lines on cold launch (the day label and part-of-day words change anyway).
- **Which memory.** The ship list says Training and Kitchen; `memory-store.md` says every group but About you.
  DECIDED (Product, decisions.md 11:45 AM PT Oct 16): Training and Kitchen, as the ship list says. Code: `Reads.area` takes one area, told lines aren't matched, no text block,
  no `touched`, no `markUsed` caller, no `fits` anywhere.
- **Not in code:** the job, `proposeLines`, the pack builder, the cache file, the debounce, the 40-a-day count,
  `TessCall.job`, the 80% step-aside and `TessLineCheck`. `HomeLine` has `weekday` but no day label for the check.
- **Ticking digits.** `HomeLine.numbers` takes the digits of "paused 21 min ago", so they change each minute;
  the pack and hash must drop them. `HomeLine.text`'s doc comment says "Bench record."; the house word is "best".
