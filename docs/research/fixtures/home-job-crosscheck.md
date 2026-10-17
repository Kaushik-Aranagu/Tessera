# Home done job: BG fixtures against the fixed job doc

Research worker BY, Oct 17, 2026. Written only: nothing was run and no call was made.

Compared: `ai/home-lines-job.md` as fixed (it now carries sections 2a, 2b and 2c) against
`docs/research/fixtures/home-done-job.md` (BG, HD1 to HD24, plus its ten rulings). "Job doc" below means the fixed
file. Where section 2c says it wins over sections 1 to 5, I read 2c first.

Result: 22 match, 2 drift (HD9, HD13), plus 8 document-level drifts listed after the table.

## 1. Moment by moment

| Moment | BG says | Job doc says | Match or drift | Fix owner |
|---|---|---|---|---|
| HD1 best | Calls Claude (best). Rules "8:05 pm" first; Claude's context "8:05 pm, a bench best" lands wet; identical detail never redraws | 2a/2b: done workout with a best is the only packed item; section 6 rules line first, differing words wet, identical never redraw; 2c.7 numeric C6 licenses "05" | match | none |
| HD2 two bests | Context of 7 words and 39 chars refused (C2, C3), kept as rules; detail swaps alone | Section 5: per slot check, a fail keeps that slot's rules words, other slots still swap; section 6: a line that wouldn't fit never arrived (C2, C3). The 6 word/32 char and 14 word/80 char numbers are not written in the doc, only by reference | match (caps by reference) | AI architecture (optional one-liner, D6) |
| HD3 gap of exactly 4 | Calls Claude; 4 is inclusive | 2a "4 or more days since the same routine" | match | none |
| HD4 gap of 9, clock dropped | Calls; "first in 9 days" passes; "nine" fails C8 | Calls by gap. C7 and C8 live in line-check-vectors (L7, L29), not in this doc | match (by reference) | none |
| HD5 gap of 3 | No call | 2a: any other item keeps rules lines and is never packed; no packable item means no call | match | none |
| HD6 other routine's gap | No call; only the finished routine's own gap counts | 2a "since the same routine" | match | none |
| HD7 no best, no gap | No call | 2a | match | none |
| HD8 first run, nil gap | No call; nil is not 4 or more | 2a "4 or more days since the same routine"; nil not mentioned but not 4 or more | match | none |
| HD9 gap across 4 am | Gap counted in his days; 3 on the wall calendar, 4 in his day, so it calls | 2a and 2c.8 name `sinceLastDays` but never say it counts house days. A gate on wall-clock days would not call | drift (minor, underspecified) | AI architecture, D4 |
| HD10 finish at 12:30 am | Calls (best); label "Thursday night"; one call across the 4 am turnover | 2c.1 cache by workout id, nothing asks again at 4 am; 2c.4 house day with 4 am turnover | match | none |
| HD11 made-up weekday | "first since Saturday" and the true "first since Friday" both refused as C15; "first in 6 days" passes | 2c.4 refuses any weekday name that doesn't match the finish's house day (Friday and Saturday are not Thursday) | match | none |
| HD12 "yesterday" across 4 am | Both slots refused as C15; BG also lists "last night" and "tomorrow" | 2c.4 lists weekday names, "yesterday", "today", "tonight", "this morning"; "early Friday" and "yesterday" are refused. "last night" and "tomorrow" are not in the list | match for this fixture (list gap in D2) | AI architecture, D2 |
| HD13 "after work" on a Saturday | Refused; "usual", "usually", "after work", "before work" all fail with or without memory | 2c.4 bans "usual" and "as usual" outright and names only weekday and relative-day words. "after work" and "before work" are not named. Section 2a still routes the "usual" guard through `fits`, which is empty when `memory: []` | drift | AI architecture, D1 |
| HD14 money fact same day | Calls (best); rent task never packed; body holds no "rent", "$", "1,850" | Section 2 "no ... money, people ..." and a fixed or non-qualifying item is not packed; 2a packs only the done workout; section 5 money and SecretWords walls | match | none |
| HD15 body fact same day | Calls (gap 6); no weight, kg or weigh-in time packed | Section 2 "no weights ... health ..." | match | none |
| HD16 secret in a note | Calls; no note field, SecretWords wall as backstop | Section 2 "no ... notes ..."; section 5 SecretWords wall | match | none |
| HD17 timeout at 6 s | Rules line stays silently; late reply dropped; no retry; never asked again; row says "timeout" and counts to the month | 2b and 2c.3: 6 s, no retries, a timeout keeps the rules line and that finish is never asked again; section 5: no Failure line on Home | match | none |
| HD18 cached second open | No second call on part-of-day turn, reopen or widget reload; cached words draw at rest | 2c.1 one call per finish, keyed by workout id, nothing asks again; section 6 cached words at rest, no drying. The ruling that a set added after finish only redraws the rules line is not written in the doc | match (ruling not in doc, see D3) | AI architecture, D3 |
| HD19 switch off | No call; cache ignored and cleared; turning on later does not ask | Section 5 switch off ignores and clears the cache; 2c.1 nothing asks on the switch turning on | match | none |
| HD20 cap reached (and 20b at $40.10) | No call at $50; also no call past the 80% step-aside | Section 5 `.refused(.cap)`; 2c.6 step-aside at $40 holds | match | none |
| HD21 Claude adds nothing | `.noLine` or identical words: no redraw; call counted and cached | Section 1 Sonnet auto, no tool call is `.noLine`; section 6 identical words never redraw | match | none |
| HD22 done with 0 sets | Fixed, no call | Section 2 "a done workout with no sets" is fixed and not packed; fails C1 or C14 if named | match | none |
| HD23 done cook | No call, rules only | 2a and 2b: every other Home moment stays on rules | match | none |
| HD24 demo with a best | No call; cache never read or written | Section 5 demo rules lines, cache never read or written | match | none |

## 2. Drifts in the job doc

Each has the exact section and a one-line fix for AI architecture.

- **D1. Section 2c item 4 (HD13), with section 2a bullet 3.** 2c.4 names weekday words and four relative-day words
  and bans only "usual" and "as usual". BG also bans "usually", "after work" and "before work". 2a bullet 3 still makes
  the `fits` rule "required", but with `memory: []` there is no `fits`, and 2c.4 says "usual" is banned outright, so
  2a bullet 3 contradicts it. Fix: in 2c.4 add "usually", "after work" and "before work" to the banned words, and
  strike 2a bullet 3 or mark it "memory-only, off for the done job".
- **D2. Section 2c item 4 (HD12).** The relative-day list omits "last night" and "tomorrow". Fix: write the list as
  "any weekday name or relative-day word (yesterday, today, tonight, tomorrow, last night, this morning, this evening)
  that the finish's house day does not support".
- **D3. Section 2c item 1 (HD18).** The Product 2:42 pm amendment (a set added after finishing only redraws the rules
  line, with no second call) is in BG's rulings but not in the doc. Fix: append "A set added after finish changes
  the rules line only; no second call."
- **D4. Section 2a bullet 1 and 2c item 8 (HD9).** "4 or more days since the same routine" never says the count is in
  house days. Fix: write "counted in house days (`daysSinceLastRun`, 4 am turnover)".
- **D5. Sections 2, 3, 4 and 8 are only partly marked stale.** 2c.1 voids sections 3 and 4, but section 2 (packs every
  non-fixed item, includes a memory block and a `fits` list), section 4's "a cook is done" trigger and section 8
  tests 1 to 5 and 9 (paused-item hash, debounce, 40 a day, memory block) still read as live. That breaks the standing
  rule "Claude wording on for finished workouts only" for a reader who starts at section 2. Fix: add one banner line
  under the title, "For the done job only 2a to 2c apply; sections 2 to 4 and tests 2 to 5 and 9 in section 8 are
  the old all-Home job".
- **D6. Section 6 and 2b (caps).** The doc cites C2 and C3 but never states the caps (context at most 6 words and 32
  characters; detail at most 14 words and 80 characters). Fix: write the two caps in 2b once.
- **D7. Section 2c item 2 against BG's pack.** BG packs `dayLabel` ("Thursday night"); 2c.2 lists the pack contents
  without it, and section 2 lists "the day label". Fix: say in 2c.2 whether `dayLabel` rides in the done pack (BG
  says it does, with no wall-clock `now`).
- **D8. Wording.** Section 2 ("record names"), 2a ("`records` not empty") and the last list ("Bench record.") use the
  old word. The last item correctly says the house word is "best", but the first two do not. Also 2b says "C1 to
  C15 including C15 weekday_slip", which 2c.4 replaces. Fix: write "bests" in section 2, name the field as an old
  code name ("`records`, to be renamed `bests`"), and say "C15 house-day check" in 2b. Also fix the pointer in 2b
  "Money and body facts are never packed (section 5)": the pack exclusion is in section 2; section 5 holds the walls.

## 3. Standing rules

| Rule | Job doc | Result |
|---|---|---|
| Rules line first, Claude's words after | Section 6 and 2b: rules line draws first, differing words land wet and dry; cached words draw at rest | holds |
| Claude wording on for finished workouts only | 2a and 2b hold it; sections 2, 4, 8 still describe the old all-Home job (D5) | holds in 2a to 2c, stale text remains |
| Switches on only after the Core 0t weekday check | 2b Gate: "Core's weekday check on 'usual' (0t) merges first". 2c.4 widens the check to all weekday words, so the gate should name that too | holds, wording could widen (D1) |
| Money and body facts never go to Claude | Section 2 list, section 5 walls, 2b; HD14 to HD16 all hold | holds |
| "best", never "record" | Section 2 and 2a still say "record" and `records` (D8) | drift in wording only |
