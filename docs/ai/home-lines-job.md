# The `homeLines` job (ship list AI-4, with AI-10's memory)

One page for Core's PR and Builder B's swap-in. It sits on `claude-client.md` (AI-2), `line-check-vectors.md`
(AI-3), `home-lines.md` (slots), `memory-store.md` (shape A) and `architecture.md` sections 5 and 6. "New" marks
anything that doesn't exist yet. Where the docs and the code differ, the list at the end says so.

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
left, to buy, days since last, record names. Nothing else: no weights, reps, volume, notes, places, health, money,
people. A fixed item is not packed at all; a line for an unknown or fixed handle fails C1 or C14.

**Ticking values never enter the pack.** A paused item's "paused 21 min ago" (`HomeLines.ago`) changes every minute,
so its context slot is rules only and is left out of the pack; only its detail goes. The same holds for "just now"
and "2 h ago". Its `numbers` drop those digits too.

**AI-10 memory block (shape A).** Before `<facts>`, one `<memory>` block from the shared builder in
`memory-store.md` section 4: told lines that match an item (Training and Kitchen areas, by title or exercise
word), up to 10 noticed lines (Training and Kitchen), the last 7 recent lines. Never About you, never People,
never a private line. Each item also carries `fits: [ruleId]`: the noticed rules today agrees with (the slot, the
weekday), so "usual" is allowed only when `fits` is not empty (Research 124 H-M1 to H-M3).

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

- **Home doesn't use the lens.** `HomeLines` is referenced only inside `TesseraCore`; `Features/Home/NowPage.swift`
  builds its own `contextLine` and its own `ago`. Builder B moves Home onto `HomeLines` first, or there is no slot.
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
