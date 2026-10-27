# The week story job (AI-11), the switch copy (AI-6) and an AI-14 check

For Core and Builder B. Follows `architecture.md` 3, 5, 6, 7, `claude-client.md`, `memory-store.md`,
`line-check-vectors.md` and the code on this tree. "New" marks what doesn't exist yet.

## Part 1. AI-11 "The week, told"

### 1.1 The shape

```swift
// new. Static, like every TessJob (claude-client.md section 1).
TessJob(name: "weekStory", model: "claude-sonnet-5-5", maxTokens: 400, effort: "low", timeout: 20,
        instructions: TessVoice house voice + the week rules below, output: proposeWeek, writeTools: [],
        memory: [.told, .noticed, .recent], priority: .lines, toolChoice: .auto)
```

`WeekFactsBuilder.facts(weekContaining:plan:now:)` exists (`DayLog/WeekFacts.swift`). New: a `WeekPack` builder
that gives handles (`w1`, `w2`, ...) and returns `TessPack`. Memory is the shape A block (AI-0), the same bytes
Home lines send, private lines never. About 2,000 tokens in and 300 out: $0.007 a call (section 5.6).

### 1.2 The facts pack: titles, counts and states only

Sent in `<facts>`, all from `WeekFacts`: weekday words and today (`days[].weekday`, `isToday`); per day the
trained and planned titles, due-and-not-done as a state, tasks done, cooked titles, before first use; days trained
of planned; `routinesDone`, `recipesCooked`; bests by exercise short name only ("Bench", not the kind's digits);
`tasksDone`, `cookedDays`; `next` as a title and a weekday word.

Never sent: `bestLines` (their `DayLine` text carries the top set, "Bench 85 × 8", from `DayStory.topSet`), any
`DayLine` text or time, weights, reps, minutes, body weight, money, notes, health, places, task titles. Each
handle carries its licensed numbers, as `HomeFact` does. The pack still passes `ClaudeClient`'s money and
SecretWords walls (claude-client.md section 3).

### 1.3 Cadence and cache

- **When.** The week just ended, worded Monday after 04:00 (at the first time Review shows after the turnover) (Product, decisions.md 11:45 AM PT Oct 16),
  and again only when that week's facts change. Never on a timer or in a live workout. At most once per 10 minutes, 3 a day.
- **Cache key.** A hash of the pack text plus the job's static bytes, not `WeekFacts ==` (that compares
  `bestLines`, whose wording can change without the facts changing). Same hash, same lines, no call.
- **Where.** The Home lines' cache file (new with AI-4, not backed up); a cold launch shows a matching story.

### 1.4 Tool and tool choice

One strict tool, `proposeWeek`: `{"lines": [{"text": string, "handles": [enum of the pack's handles]}]}`,
`minItems` and `maxItems` 3. Sonnet 5.5 refuses a forced tool, so `tool_choice` is auto; a reply with no tool
call is `.noLine` (claude-client.md section 2). No write tools: the story is words only (section 5.3).

### 1.5 Validation

- **Three lines,** each with at least one handle from the pack, each `TessLineCheck` slot `.detail`: 14 words,
  80 characters, one sentence ending in ".", no "!", emoji or newline (line-check-vectors.md, L39 to L54).
- **Truth.** Every digit group licensed by that line's handles or the week counts; no number words; no clock
  digits (AI-0); names only from the pack, with sentence starts, weekdays and months exempt.
- **Voice.** `TessVoice`, plan banned words, plus still, streak, should, finally, missed, behind; "best", never
  "record". A due-and-not-done day is never worded as missed.
- **On any fail,** all three rules lines stay (one story, no mixing); nothing visible; the ledger row says why.
- **Rules lines (new, always there).** Three plain count lines from the same lens: "4 of 5 sessions." / "Bests
  on Bench and Squat." (or "3 tasks done, 2 cooks.") / "Legs is first up Monday." (or nothing next: "Plan ends
  this week.").
- **80%, offline, switch off, demo.** At 80% of the month ($40) the week story steps aside before reserve, with Home lines and living colour; capture, plan, recipe and questions keep running to $50.
  Offline, busy, bad key, capped, switch off, no key, demo flags: rules lines at once, no queue.

### 1.6 Touched ids, links and Review

`touched` lists the objects behind each handle in line order (workouts, routines, cooks, the next routine) and
never enters the request body. Builder B links each line's handles to them. New: the lens adds an id per handle
(from `TrainingLedger.week` and `cooksByDay`), since `WeekFacts` carries titles only.

**Builder B, Review top.** Rules lines show at once; a passing set dries in over them through `MotionPolicy`,
wrapping, never truncated, in `ReviewWeekData.bestLines`'s row shape (`WeekLines.Row`).

### 1.7 Tests Core should write

1. Pack snapshot on the demo week: no `×`, "kg", minutes, `DayLine` text or task title. A logged body weight,
   a note and a spend leave it byte-identical.
2. Same facts on a second open: no request reaches the stub. A new workout: one request.
3. A line over 14 words, an unlicensed digit, an invented name, two lines, no tool call, or "Training moved later
   this week, mostly after 7 pm." (clock digits): all three rules lines stay; the row says why.
4. Switch off, demo, no key, offline and the 80% mark send nothing; `touched` ids never reach the body.
5. Rules lines for no plan, a first week, no bests, and a plan that has ended.

### Where code and docs differ

- **Line caps.** `first-features.md` says three lines "at the Home line caps (6 words, 32 characters)" and, two
  paragraphs later, "14 words each". This note takes the detail slot (14 words, 80 characters).
- **Its own example fails.** first-features' "mostly after 7 pm" breaks AI-0's no clock digits rule.
- **Habits.** Architecture section 3 and first-features send habits as "n of m"; `WeekFacts` has no habits field.
- **Rules lines.** DECIDED (Product, decisions.md 11:45 AM PT Oct 16): three plain count lines, as the ship list says. Design 46 (`review-week.md`) and
  the code show the day log's three best lines, which carry weights ("Bench 85 × 8, a best."): never packed; Design and Builder B move to the count lines.
- **Where it lands.** The ship list says "Review top"; Design 46 puts THE WEEK'S LINES under the bands.
- **The week.** Review's week runs Monday to Sunday (`ReviewWeekData.days`), so "Sunday after 04:00" tells a week
  with a day still to go. DECIDED (Product, decisions.md 11:45 AM PT Oct 16): tell the week just ended, Monday 04:00; the ship list's "Sunday" is stale.
- **Memory kinds.** Section 6 says "all", section 3 told and noticed; this note follows shape A's one block.
- **No ids, no handles** in `WeekFacts` yet; `TessUse` has no week case (rows need AI-2's `job` field).

## Part 2. AI-6 Settings copy for "Tess asks Claude"

What Design's copy must say (`settings-place.md` addendum 1:05 AM PT, then Design 62 `copy-pass.md`, Product
f80c08c):
- **Third person always.** "Tess asks Claude: yes." / "no." stays as #320 built it; never "I ask Claude".
- **The yes answer names only jobs the build does,** in the order he meets them: misses ("when unsure"), Plan my
  day, then Today (Home lines, AI-4), then your week (AI-11). Final words per copy-pass: after AI-4 "Tess asks
  Claude when unsure, for Plan my day and Today."; after AI-11 "Tess asks Claude when unsure, for plans, Today
  and your week." Recipe links, groceries (AI-12) and soul colour (AI-14) are not named. The no answer stays
  "Tess stays on this phone."
- **The cap line** reads `TessUsageLedger.capDollars`, never a typed number: "This month **$x.xx** of $50."
  today, and the paused line "Paused until **Nov 1**."
- **The 80% line.** The meter turns amber at 80% and "PAUSES AT $" + `capDollars` shows. Architecture 5.5 says
  this same line also tells him word jobs (Today, your week) step aside (settled by Product's 8:16 ruling); Design says nothing else changes.
- **The privacy line,** from AI-4 on, under the spend line, with the switch on or off: "Titles and counts only.
  Never notes, places, health or money."
  (Send side superseded by Kaushik's Oct 27 12:10 PM ruling, docs/product/decisions.md; the backup, log, widget and screen walls stay.)

### Where code and docs differ

- `ClaudeSection.toggleMisses` writes the pre-AI-4 line, "Tess asks Claude when she's unsure, and for Plan my
  day.", and shows it only after a flip; Design 62 drops "she's" and the ship list row still quotes Design 50.
- Code says "Paused until Nov 1."; settings-place says "Claude paused until 1 Nov." and, later, "...Nov 1.".
- The 80% state shows "PAUSES AT $50" only; no line says word jobs stepped aside.
- No privacy line is built. The comment on `missesGoToClaude` (line 58) still says "misses and Plan my day".
- `ClaudeKey.swift` still opens the ledger with "The $10 month" though the cap is $50 (Swift, not changed here).

## Part 3. AI-14 check: ship-list row against architecture section 9

| Point | Ship list AI-14 | Section 9 | Verdict |
|---|---|---|---|
| Palettes, ±0.2 nudges, candidates only; once a day after 07:00; under $0.01 | yes | yes (Haiku 5.5) | match |
| Cadence: 3 a day, 2 h apart, quiet hours | yes | not stated; "never on a timer, in a workout, mid-moment" | gap in section 9 |
| Out of range nudge, extra field | "anything else is rejected" | clamps nudges; `proposeSoul` has `reason` | DECIDED: clamp (Product, decisions.md 11:45 AM PT Oct 16); ship-list row to follow |
| Fallback | "keeps today's colours" | the palette she's on, or Today | wording; "today's" reads as the Today palette |
| FORGET | "pins her back" | pins to Today and pauses the job | DECIDED: Design 48's FORGET, one palette off 30 days (Product, decisions.md 11:45 AM PT Oct 16) |
| Store | `LivingPalette` store | `LivingPalette` kept by `SoulPaletteStore` on `ThemeStore` | naming |
| Gate | none | Design's 20 day-shapes eval, his "feels like weather" on a recording | row lacks the gate |
| 80% step-aside | not stated | yes | row lacks it |
| Settings | not stated | the line "grows one more clause" | Design 48 says nothing new in Settings |

### Where code and docs differ

None of `LivingPalette`, `soulPalette`, `proposeSoul` or `look(_:living:)` exists in code yet. Section 9 and
the row both lack Research's learned numbers (median first write, usual slot, three-day flip) that Design 48 took.
