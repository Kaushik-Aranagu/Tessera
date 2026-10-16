# Review 334: HomeLines lens (AI-1)
PR #334 (core/home-lines) at 39a6495, cut from 450a0c0; re-confirmed at 2d3cbaa, which is that head plus a master merge (no change to the PR's 4 files). Trial merge onto master d55d29c clean. TesseraCore only: `Home/HomeLines.swift` (+457), `Groceries.toBuy(for:)` (+9), DayStory's short names moved to `ExerciseWords` (no change in output), `HomeLinesTests.swift` (+275). No app files, no catalog or schema change. Static review against docs/ai/home-lines.md on master, Oct 16 PT.

**Verdict: PASS.** One small fix to fold in (L1); nothing blocks.

## Against home-lines.md: PASS
- **Slots kept separate.** `HomeLine` has `hero` (rules only, no stop), `context` plus `contextShort` (rules; Claude may reword), `detail` (SO FAR, one sentence with its stop), and the row `text`. Every row of the section 2 table comes out as written:
  - planned: "Push A" with "today", "this evening" or "tonight"
  - running: "Push A, bench set 3" with "now"
  - paused: "Push A, paused at bench" with "paused 21 min ago", short "paused 21 min"
  - done: "Push A done" with "done at 7:40 pm"
  - done with no sets: "Push A, no sets" with "this afternoon"
  - rest: "Rest day" with the weekday
  - cooking: "Chili, step 3" with "paused 8 min ago"
  - shopping: "Groceries, 4 left" with "at the store"
  - planned cook: "Tacos tonight" with "2 to buy", row "Tacos tonight, 2 to buy." (tested at 21:30)
- **Numbers carry every digit.** `numbers` is the facts' numbers (step, steps, toBuy, sinceLastDays; for a started workout also exercises done and planned, sets, and the record count when there's more than one), plus every digit run in the rules context and detail. So "done at 8:05 pm" licenses 8 and 5, and "1 new best" licenses 1. The tests pin the exact arrays.
- **Allowed names:** `names` = title + exercise in focus + record names. Short names only ("Bench"). No weights, reps or volume ever sit in a fact (`factsFromTheStore` checks that "80" never appears).
- **`fixed`:** true for a running workout and for a done workout with no sets, so Claude never sees a live workout or comments on an empty one. A paused workout isn't fixed, which matches section 3: "not in a live workout".
- **`sinceLastDays`:** whole 04:00 days (TesseraDay) since the same routine last ended before now. Nil when it never has.
- **Planned cook unbought count:** `Groceries.toBuy(for:)` counts open, undeleted rows whose shares name the recipe. 0 reads "nothing to buy".
- **Caps:** `fitsContext` (6 words, 32 characters, no stop) and `fitsDetail` (one sentence, 14 words, 80 characters, its stop, no ? or !). These refuse rather than cut. Tests assert every rules line passes them, and that row lines stay within 6 words with no "kg", "×" or "…".

## L1 (fold in, one line): the rest-day weekday ignores the 04:00 day
`HomeLines.context`, the `(.rest, _)` case, takes the weekday from `now` on the midnight calendar. At 01:00 Friday his day is still Thursday, but the line says "Friday". Fix: `calendar.component(.weekday, from: TesseraDay(calendar: calendar).day(of: now))`. A test at 01:00 would pin it. `dayWord` and `partWord` are fine: DayPart already treats 00:00 to 04:00 as `.late` ("tonight").

## Lows
- L2: a title with digits in it ("5x5 Day") is in `names` but its digits aren't in `numbers`. If a Claude line repeats the title, the AI-4 checker could refuse it. Either add the title's digits or let the checker match names before digits.
- L3: `DayStoryClock.sentenceTime` duplicates `DayStory.sentenceTime`. Point one at the other.
- L4: `daysSinceLastRun` scans every workout for each planned or done fact, on the main actor. That's fine at today's history. If Home calls it every redraw at five-year scale, cache it per launch or day.

## App gate note
The 00:00 to 04:00 `ExerciseAndPlansTests` failure Core saw is master's old test, fixed by #330 (TesseraDay). #334 doesn't carry that fix because it was cut from 450a0c0. A merge onto master picks it up; the trial merge is clean. Not a finding.

## Data safety
Pure rules: no key, no network, no writes, no LaunchFlags or ProcessInfo reads, no UI tests.
