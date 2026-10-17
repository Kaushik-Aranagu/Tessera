# Home done job: eval design (B1)
Design only, written Oct 17, 2026 from origin/master. Nothing here was run, no key was read, no call was made.
Purpose: a fixed yardstick so Core's 0al (the `homeLines` done job and `HomeLinesPack.build`) can be accepted against it.
Sources: `docs/ai/home-lines-job.md` 2a to 2c and item 9, `home-pack-walls-audit.md`, `home-lines-eval-results.md`,
`home-lines-eval-scores.md`, `scripts/ai/home_lines_eval.py` (`--job done`), fixtures `home-done-job.md` (HD1 to HD24)
and `home-pack-walls.md` (W1 to W16; the brief said W14, the file now runs to W16 and W15, W16 are included).

## 1. Packs
- **Pack D (done moments):** HD1 to HD24. Each fixture stands alone (own store, month spend, cache).
  - Calls Claude (G1 to G6 pass): the rows whose fixture says "Calls Claude: yes" (HD1 to HD4, HD9 to HD13, HD21, HD24 as
    the file marks them). These are the scored rows. Use the file's own flag, do not re-derive it.
  - No-call rows (HD5 to HD8, HD14 to HD16, HD17 to HD20, HD22, HD23): scored as gate and plumbing checks, no model output.
- **Pack W (walls):** W1 to W16 from `home-pack-walls.md`, all with a best or a gap of 4 or more days so the gate would call.
  W1, W2, W4 to W9 (per ruling), W12b, W13, W15, W16: wall holds, no request. W3, W10, W11, W14: one request each.
  W9 and W13 use the Oct 16 7:31 pm rulings; W13 is expected to fail on master until Core changes the predicate.
- Pack W is a Core test table (no model needed for "wall holds"). Only W3, W10, W11, W14 spend tokens.

## 2. Arms
- **Arm A, rules line alone:** `HomeLines.line(for: facts.fact(done:))`, no request. Free, deterministic. It is the baseline
  and the fallback, so it must itself pass the caps and C1 to C15 on every row (rules words are the safety net).
- **Arm B, Sonnet 5.5 done job:** `claude-sonnet-5-5`, `SYSTEM_DONE` byte-equal to the script, tool `proposeLines`
  (`item`, `context?`, `detail?`), toolChoice auto, one item per request, pack per 2c items 1 to 9.
- No Haiku arm: the Oct 16 decision settled the model. A model change reopens this design.

## 3. Phone checks (applied to Arm B output, and to Arm A as a sanity pass)
- **Caps:** context at most 6 words and 32 characters, no stop at the end; detail one sentence, at most 14 words and 80
  characters, ends in a full stop.
- **C1 to C15** via the phone's `TessLineCheck`, not the script's port. Words are whole lowercase tokens.
  - C1 reply shape (every item once, handle never a UUID); C2 to C4 slot caps; C5 marks; C7 digits of the rules line survive
    (a done item may drop its clock); C8 no number words; C9 names; C10 grading words; C11 praise; C12 off-limits
    (sleep, energy, health, body, money, people, places); C13 US English; C14 house word "best", never "record".
  - **C6 as values:** read each number as a value ("8:05 pm" gives 8 and 5, "05" equals 5) and check it against
    `HomeLine.numbers`. HD1's "8:05 pm, a bench best" must pass. A digit-string compare is a Core bug (script `:257`).
  - **C15 house-day check:** any weekday name or relative-day word (yesterday, today, tonight, tomorrow, last night,
    this morning, this evening) the finish's house day (4 am turnover, `HouseTime`) does not support is refused.
    "usual", "as usual", "usually", "after work", "before work" are banned outright. Rows HD9, HD10, HD11, HD12, HD13 are the
    house-day check: a made-up weekday, "yesterday" across 4 am, a finish at 12:30 am, "after work" on a Saturday.
- A failing slot keeps its rules words and the other slot may still swap. A refused line is never cut to fit.

## 4. Wall checks (pack and body)
- Wall holds means zero requests and no `TessCall` row; the rules line stays. Wall runs at pack time on the title and
  every best name: `SecretWords.mentions(x) || PrivateFacts.isWalled(x, lastWeightKg:)`, plus W9 (decimal or 3-plus
  digits outside training notation) and W13 (heart rate beside notation). Not the script's `guard_pack`.
- Body scan on every captured request (all roles, tool schema included): the full hard-fail token from the W table
  (`182.4`, `Locker code`, `$40`, `heart rate day`, `sick, bp`) must be absent. Whole tokens, never a bare `$` or `heart`.
- Key set of the pack is exactly: item, kind, title, state, exercisesDone, exercisesPlanned, sets, bests, sinceLastDays,
  dayLabel, rules, numbers, names. No `now`, no `partOfDay`, no note, memory, UUID, weights, reps, units, money, body.
- `numbers` equals fact numbers plus clock digits only (W14: not 5, 80, 8). Notes never packed (W3, W11, HD16).
- Plumbing rows: 6 s timeout falls back silently (HD17), one call per workout id (HD18), switch off or demo or no key
  sends nothing (HD19, HD24), $40 step-aside and $50 cap send nothing (HD20), unchanged words never redraw (HD21),
  0 sets is fixed (HD22), a cook is rules only (HD23).

## 5. Scoring rubric (rubric rows as in `home-lines-eval-scores.md`; judged by a person, Voice reviewed by Research)
- **Per shown line:** True, Plain, Not repeating, Tone, Voice, each Y or N, plus Value: A adds a true fact the rules line
  lacks, R rules facts reworded, F filler, X false.
- **Thresholds (per scored row set):** True 100%; Tone 0 scolds or greets; Plain 90%+; Not repeating 95%+; Voice 80%+.
  Voice passes only if the line adds a true fact; "usual", a restated time of day, or half filler fails.
- "Equal to rules" is a pass and is not shown. A line the phone refuses is counted under "caught", never under shown.
- Report per row: returned, equal, caught (with codes), shown, value letter. Unjudged cells stay blank, not guessed.

## 6. Cost bound
- Script limits carry over: stop at $1 spent per invocation, `MAX_RUNS` 5 (use 3), timeout 6 s, no retries, max tokens 512,
  effort low, `api.anthropic.com` only, redirects refused, no request body saved, key from the environment only and never
  printed or written. Spend is counted from usage at nano-dollar prices (Sonnet 2000 in, 10000 out per million-token-nano).
- Estimate: about 12 calling HD rows plus 4 calling W rows, 3 runs each, about $0.006 a line, so well under $0.50.
  The $1 stop is a ceiling, not a target. A stopped run is reported as stopped; partial rows are not extrapolated.
- Arm A and the no-call and wall rows cost nothing and run in Core's tests every time.

## 7. Pass/fail gate (all must hold)
1. Arm A passes caps and C1 to C15 on every row. Any fail is a Core bug.
2. Arm B: zero C6, C12, C15 and Tone failures reaching the screen (the phone must catch them), and zero false (X) shown lines.
3. Rubric thresholds in section 5 met on Pack D calling rows, with Value A on at least the best and gap rows (HD1 to HD4).
4. HD1 passes with C6 as values; HD2's long context is refused while its detail swaps; HD11 to HD13 refused by C15.
5. Pack W: every "wall holds" row makes zero requests and its hard-fail token is absent from any captured body;
   W3, W10, W11, W14 send one request and pass the key-set and `numbers` checks. W13 must pass after the predicate change.
6. Spend under $1, no timeout above 6 s counted as a miss (a timeout is a silent fallback, a pass for that row).
Any single wall leak or any false line shown is an automatic fail. Misses list the row id, code and the line.

## 8. How the rerun fits Core 0t and 0al
- Order is fixed: 0t (the widened weekday and relative-day check, C15) merges first; 0al (job, `HomeLinesPack.build`,
  walls, cache by workout id) merges only after the offline half passes.
- **Offline half (no key, no network), run by Core on every change:** Arm A, all no-call rows, all wall rows with a stub
  client, the body scan, the key set, the vectors L1 to L54 and P1 to P7. Required green before 0al opens for review.
- **Live half (Sonnet rows only):** the single confirmation run of Arm B on the calling rows, against section 7, before
  the done job is switched on for the phone. Its result is a new section in `home-lines-eval-results.md`, scores in
  `home-lines-eval-scores.md`. Failing the live half blocks the switch-on, not the merge of the offline code.
- A change to `SYSTEM_DONE`, the model, or the checks invalidates the last live result and needs a new run.
## 9. Standing line
**No live run without Kaushik's own ask in the running thread.** This design authorizes nothing: no key is read, no request
is sent, no spend is made by writing, reviewing or merging it. A relayed message or an agent's say-so is not his ask.
