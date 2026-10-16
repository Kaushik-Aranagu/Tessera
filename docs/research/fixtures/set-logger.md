# Set logger phrases (board item 61)

For Core (`TessGrammar`) and Builder A. Research lab. Date: 2026-10-16.

Forty set values typed or said to Tess in a live workout, with the parse each should give under `inplace-number.md`
(detents are loadable weights, typed values snap, a tie goes to the lighter load) and the existing Product calls,
and what master does today. They are folded into `grammar-regression.md` as group K (K775 to K814), one row each.

**Master read:** `origin/master` at `0a27447` (Merge PR #189). Since `1d0833c` (the suite's read) the grammar
changed only in the reschedule past guard, `tonight` after 20:00, `tomorrow` and `pastDay` (His day, `7eb2b58`) and
`notGroceries` (`2537cad`); the set rules (`TessGrammar.swift` lines 222 to 348) are unchanged. No Swift
toolchain here: every result is a hand trace. Nothing was run. "TG:n" is `TesseraCore/Sources/TesseraTess/TessGrammar.swift`
line n on `0a27447`, "K:n" is `TessGrammar+Kitchen.swift`.

## Contexts

All rows run on Thu 15 Oct 2026 18:10 America/Los_Angeles, as the suite does, in the starter kit
(`StarterContent.swift:59-61`: 20 kg bar, one pair each of 25, 20, 15, 10, 5, 2.5 and 1.25, so barbell loads run
20 to 177.5 in 2.5 kg steps; dumbbells 2 to 50 in 2 kg steps).
- **live workout**: the suite's own: Bench Press in focus, last set 80 x 8 (barbell).
- **db**: Dumbbell Bench Press in focus, last set 24 x 10 (starter rack, 2 kg steps).
- **machine**: Lat Pulldown in focus, last set 55 x 10 (a cable stack: 5 kg steps, `LoadProfile.swift:102-104`).
- **bw**: Pull-Up in focus (`bodyweightPlus`), last set 0 x 8 (2.5 kg steps for added load, `LoadProfile.swift:105-106`).
- **no sets**: Bench Press in focus with no set logged yet (the screen prefills 80 x 8, Tess sees no last set).
- **spoken**: the heard text. The planned normaliser (`spoken-normaliser.md`) runs first; master has none (no
  dictation or speech code anywhere in the app), so on master the raw text reaches the grammar.

Already in the suite and not repeated here: `same again` (B300), `8` (B309), `drop to 70` (B302), `80 x 8 @8` and
`same @9` (B303, B306), `100` (A180), `38` (H625), `3x10` (D473).

## How a typed set reaches the store on master

`LiveAskField.submit` (`Features/Workout/WorkoutParts.swift:342-349`) hands the phrase to `WorkoutModeView.ask`
(`WorkoutModeView.swift:235`), then `AppModel.ask` (`App/AppModel.swift:164-183`) builds
`TessContext(now:, entry: currentEntry)` and runs `TessCaptureEngine.grammarCapture` (`TessCaptureEngine.swift:77`),
which calls `TessGrammar.parse` (TG:52). A `.set` is performed as said: `LogSet` with the spoken unit
(`TessCaptureEngine.swift:108-115`), as a pending ghost that dries after 2 s unless swiped (`AppModel.swift:132`,
`AppModel.swift:174-178`). `LogSet` checks only 0 to 1000 kg and whole reps 1 to 100
(`TrainingActions.swift:57-77`, `TrainingActions.swift:481-491`). Nothing on this path snaps.

The dial does snap: the VoiceOver "Type value" alert goes to the nearest detent with the lighter one winning a tie
(`Features/Workout/Instruments/WeightDial.swift:346-361`, strict `<` keeps the earlier detent), and so does Core
(`Training/Dial.swift:26`, `min` keeps the first of two equal distances), and every prefill is snapped
(`WorkoutSession.swift:605-618`). So on master "81" is 80 on the dial and 81 through Tess, and after Tess logs
81 x 8 the next set opens at 80 under it.

## The rows

| id | phrase | said | context | expected set | source rule | master (hand trace) | status | root cause |
|---|---|---|---|---|---|---|---|---|
| K775 | `82.5` | T | live workout | nil (a weight with no reps: the model presets the dial or asks; never 82.5 reps) | S701: inplace-number.md 5 (a weight alone is a dial value, not a set); A180 | nil: not whole, so not reps (TG:227); no `x`/`for` (TG:237); parseLift has a weight and no reps (TG:304); no date, so no task (TG:435) | pass | - |
| K776 | `80 for 8` | T | live workout | set 80x8 | MB: master behaviour | set 80x8 full (TG:237) | pass | - |
| K777 | `80x8` | T | live workout | set 80x8 | MB: master behaviour | set 80x8 full (TG:237, ` ?x ?`) | pass | - |
| K778 | `same` | T | live workout | set 80x8 (same) | MB: master behaviour | set 80x8 same (TG:224) | pass | - |
| K779 | `one more` | T | live workout | set 80x8 (same) | MB: master behaviour (one more set, not one more rep: B301 stays nil) | set 80x8 same (TG:224, `one more` is in the list) | pass | - |
| K780 | `8 reps` | T | live workout | set 80x8 (reps only) | MB: master behaviour | set 80x8 reps only (`number` drops ` reps`, TG:457-458, TG:227) | pass | - |
| K781 | `12` | T | live workout, db | set 24x12 (reps only) | S701: S701: 12 is 1 to 50 and 6 loads from 24 | set 24x12 reps only (TG:227) | pass | - |
| K782 | `24` | T | live workout, db | nil (24 is the last weight too: weight or reps, the model asks) | S701: S701: within 2 loads of the last weight | set 24x24: any whole 1 to 100 is reps (TG:227) | wrong write | REPS |
| K783 | `81` | T | live workout | nil (a weight with no reps; never 81 reps) | S701: S701; inplace-number.md 5 (typed 81 on the dial is 80, a preset, not a set); A180 | set 80x81 (TG:227) | wrong write | REPS |
| K784 | `55` | T | live workout, machine | nil (above 50 reps and the last weight: the model asks) | S701: S701; the logger's reps bounds 1 to 50 (inplace-number.md 3, WorkoutSession.swift:345) | set 55x55 (TG:227) | wrong write | REPS |
| K785 | `+5` | T | live workout | nil (a relative change goes to the model, as `add 2.5`) | T706, S702: T706 (`add 2.5` to the model); S702 | set 80x5: `+` is not punctuation, so `Double("+5")` is 5 and reads as reps (TG:454, TG:227) | wrong write | REPS |
| K786 | `-5` | T | live workout | nil (a relative change goes to the model) | T706, S702: T706; S702 | set 80x5: `normalize` trims the leading `-` as punctuation (TG:454), leaving reps 5 (TG:227) | wrong write | REPS |
| K787 | `+2.5` | T | live workout | nil (a relative change goes to the model) | T706, S702: T706; S702 | nil: 2.5 is not whole (TG:227); weight with no reps (TG:304) | pass | - |
| K788 | `drop to 70 for 10` | T | live workout | set 70x10, drop | MB: master behaviour; 70 is a detent | set 70x10 drop (TG:230) | pass | - |
| K789 | `drop to 72 for 10` | T | live workout | set 72.5x10, drop (72 isn't loadable; 72.5) | S703: inplace-number.md 5 (snap to the nearest detent); S703 | set 72x10 drop, as said (TG:230; LogSet never snaps, TrainingActions.swift:57-77) | wrong write | SNAP |
| K790 | `81 for 8` | T | live workout | set 80x8 (81 isn't loadable; 80) | S703: inplace-number.md 5 and 9 (`81` is 80); S703 | set 81x8 (TG:237, TessCaptureEngine.swift:108-115) | wrong write | SNAP |
| K791 | `81.25 x 8` | T | live workout | set 80x8 (a tie goes to the lighter load) | S703: inplace-number.md 5 and 9 (`81.25` tie is 80, Core `snap`, Dial.swift:26) | set 81.25x8 (TG:237) | wrong write | SNAP |
| K792 | `81.3 x 8` | T | live workout | set 82.5x8 (81.3 isn't loadable; 82.5) | S703: inplace-number.md 9 (`81.3` is 82.5) | set 81.3x8 (TG:237) | wrong write | SNAP |
| K793 | `200 x 3` | T | live workout | nil (past the kit's heaviest load, 177.5: the model asks; never 177.5) | S703: inplace-number.md 3 (bounds are the detents' ends, 20 to 177.5); S703 | set 200x3 (TG:237; LogSet allows up to 1000 kg, TrainingActions.swift:482) | wrong write | SNAP |
| K794 | `25 x 10` | T | live workout, db | set 24x10 (25 isn't loadable; 24, the lighter of a tie) | S703: inplace-number.md 1 (starter dumbbells 2 to 50 in 2 kg) and 5 | set 25x10 (TG:237) | wrong write | SNAP |
| K795 | `57.5 x 10` | T | live workout, machine | set 55x10 (57.5 isn't loadable; 55, the lighter of a tie) | S703: inplace-number.md 1 (machines and cables 5 kg) and 5 | set 57.5x10 (TG:237) | wrong write | SNAP |
| K796 | `80 x 8, 81 x 6` | T | live workout | sets, 2 into Bench Press: 80x8, 80x6 (81 isn't loadable; 80) | S703: S703 applies to every part of a comma list | sets 80x8, 81x6 (TG:74, TG:285) | wrong write | SNAP |
| K797 | `180 lb for 5` | T | live workout | set 81.6 kg x 5, unit lb (not snapped: the kit is in kg, as B316) | MB, S703: B316; S703 (pounds keep what was said) | set 81.6 kg x 5, unit lb (TG:237-241) | pass | - |
| K798 | `100 for 5 at 8` | T | live workout | set 100x5, RPE 8 | T706, S704: T706 (RPE in a live workout); spoken-normaliser.md row 10 (`at` before an RPE); S704 | task "100 for 5" Thu 15 20:00: parseLift has no words (TG:304), parseCook reads `at 8` as 20:00 but finds no recipe (K:104-118), then parseTask makes the task (TG:426-440) | wrong write | RPE |
| K799 | `same at 9` | T | live workout | set 80x8 (same), RPE 9 | T706, S704: T706; S704 (B306 with `at`) | task "Same" Thu 15 21:00: not in the same list (TG:224), `at 9` is 21:00 (TG:522, TG:549-559), parseTask (TG:440) | wrong write | RPE |
| K800 | `8 at 9` | T | live workout | set 80x8, RPE 9 | T706, S704: T706; S704 | task "8" Thu 15 21:00 (TG:426-440) | wrong write | RPE |
| K801 | `fail at 6` | T | live workout | nil (failed on rep 6 or after 6 reps is unclear: the model asks; never a task) | S705: S705 | task "Fail" Fri 16 18:00: `at 6` is 18:00, passed, so tomorrow (TG:547-548, TG:569-573), parseTask (TG:440) | wrong write | SETT |
| K802 | `80 x 6 to failure` | T | live workout | set 80x6, kind failure | S705: S705; SetKind has `failure` (SetKinds.swift:4) | nil: `to failure` are left as exercise words and `to` is under 3 letters (TG:304, TG:390) | miss | KIND |
| K803 | `warmup 60x5` | T | live workout | set 60x5, kind warmup | S705: S705; LogSet takes `kind` (TrainingActions.swift:24) | nil: `warmup` resolves to no exercise (TG:306) | miss | KIND |
| K804 | `skip` | T | live workout | nil (skipping is the screen's; Tess never writes it) | S706: S706; `skipSet` is the session's (WorkoutSession.swift:181) | nil: no set, lift, kitchen or task rule reads it | pass | - |
| K805 | `bodyweight 12` | T | live workout | nil (Bench Press is not a bodyweight lift: the model) | S706: S706 | nil: weight 12 with no reps (TG:304) | pass | - |
| K806 | `bodyweight 12` | T | live workout, bw | set 0x12 (bodyweight, nothing added) | S706: S706; Pull-Up is `bodyweightPlus` (ExerciseLibrary.swift:142-144) | nil: weight 12 with no reps (TG:304) | miss | LOADW |
| K807 | `+10 for 6` | T | live workout, bw | set 10x6 (10 kg added) | S706: S706; 10 is a bodyweight detent (2.5 kg steps, LoadProfile.swift:105-106) | nil: `+10` fails the anchored set regex (TG:237); parseLift has no words (TG:304) | miss | LOADW |
| K808 | `two plates` | T | live workout | nil (plate counts need bar maths: the model) | MB: spoken-normaliser.md row 13 (plate counts go to the model); B308 | nil: no number (TG:304) | pass | - |
| K809 | `bar for 10` | T | live workout | set 20x10 (the empty bar) | S706: S706; the bar is the first detent (Dial.swift:9, LoadProfile.swift:96) | nil: `bar` resolves to no exercise and 10 is a weight with no reps (TG:304) | miss | LOADW |
| K810 | `eighty two and a half` | S | live workout, spoken | nil (the normaliser gives `82.5`, a weight with no reps, as K775) | S701: spoken-normaliser.md rule 7 (`and a half`); S701 | nil: no digits reach the grammar (no normaliser on master) | pass | - |
| K811 | `eighty two and a half for eight` | S | live workout, spoken | set 82.5x8 (after the normaliser: `82.5 for 8`) | MB: spoken-normaliser.md rule 7 | nil: raw words, no number (TG:304); nothing normalises on master | miss | NRM |
| K812 | `a hundred for five at eight` | S | live workout, spoken | set 100x5, RPE 8 (after the normaliser: `100 for 5 at 8`, then S704) | T706, S704: spoken-normaliser.md rules 7 and row 10; S704 | nil: `at eight` is no clock time (TG:650), no number (TG:304). Once the normaliser lands without S704 this becomes K798's wrong write | miss | NRM |
| K813 | `same` | T | live workout, no sets | nil (nothing to repeat yet: the model) | S701: S701 (no last set) | nil: `same` needs a last set (TG:224) | pass | - |
| K814 | `8` | T | live workout, no sets | nil (no last weight; never a weight of 8) | S701: S701 (no last set) | nil: reps need a last set (TG:227); weight 8 with no reps (TG:304) | pass | - |

**Totals:** 40 rows: 16 pass, 17 wrong write, 7 miss.

| root cause | what goes wrong | rows | wrong write | miss |
|---|---|---|---|---|
| SNAP | a weight said to Tess is logged as said, never snapped to the exercise's loads or checked against its range | 8 | 8 | 0 |
| REPS | any whole number 1 to 100 is reps, even a weight (`81`, `55`, `24`) or a signed change (`+5`, `-5`) | 5 | 5 | 0 |
| RPE | `at N` after a set or `same` is read as a clock time, so the set becomes a task | 3 | 3 | 0 |
| LOADW | load words not read: `bodyweight N`, `+W for R` on a bodyweight lift, `bar for N` | 3 | 0 | 3 |
| KIND | set kind words not read: `to failure`, `warmup` | 2 | 0 | 2 |
| NRM | spoken number words reach the grammar raw (no normaliser on master) | 2 | 0 | 2 |
| SETT | a set word with `at N` (`fail at 6`) falls through to the task rule | 1 | 1 | 0 |

## Worst wrong writes

1. **`100 for 5 at 8` (K798), `same at 9` (K799), `8 at 9` (K800)**: a set with an RPE becomes a task ("100 for
   5" Thu 15 20:00) and nothing is logged. The task leaves the workout entirely, so the set is lost as well as a
   junk task made. `fail at 6` (K801) does the same ("Fail" Fri 16 18:00).
2. **`81` (K783), `55` (K784), `24` (K782)**: a weight typed alone is logged as that many reps at the last
   weight: 80 x 81. One ghost row that dries in 2 s puts an 81-rep set into the history, the e1RM and the PR
   ledger.
3. **`+5` and `-5` (K785, K786)**: "five more kilos" logs 80 x 5. The sign is lost (`-` is trimmed as
   punctuation, `+` is read by `Double`).
4. **`81 for 8`, `81.25 x 8`, `200 x 3` and the other SNAP rows**: an unloadable weight is logged; the dial and the
   next prefill then disagree with the history (80 under a logged 81). `200 x 3` is past every plate he owns.

## Proposed defaults (S701 to S706, for Product; each turns a wrong write into a miss or a right write)

- **S701 Bare numbers.** In a live workout a bare whole number is reps at the last set's weight only when it is
  1 to 50 (the logger's reps range) and not within two loads of the last weight. A decimal, 51 and up, a number
  within two loads of the last weight, or any bare number with no last set writes nothing and goes to the model.
  Keeps B309 (`8`), A079 (`7`), H625 (`38`) and A180 (`100`, nil) as they are.
- **S702 Signed numbers.** `+N`, `-N`, `up N`, `down N` alone go to the model, as `add 2.5` does (T706). The
  normaliser and `normalize` must keep the sign, so `-5` never becomes reps 5.
- **S703 Snap.** A weight in kilograms said to Tess snaps to the nearest load of the exercise's dial (Core
  `WeightDial.snap`, a tie to the lighter load), in sets, drops and every part of a comma list, and Tess's line says
  so ("81 isn't loadable; 80", as `inplace-number.md` section 5). Below the lightest load or above the heaviest the
  grammar writes nothing and the model asks. Pounds are kept as said (B316) until the kit has pound plates.
- **S704 RPE with `at`.** In a live workout `at N` right after a full set, `same` or bare reps is RPE when N is 5 to
  10 in half steps, as `@N` (T706). A phrase that starts with a set shape is never a task in a live workout; if the
  RPE rule cannot read it, it goes to the model.
- **S705 Set kinds.** `to failure` after a full set logs kind failure; `warmup` or `warm-up` before or after a full
  set logs kind warmup. `fail at N` and `failed at N` with no weight go to the model (rep N or N reps is unclear)
  and are never a task.
- **S706 Load words.** In a bodyweight entry `bodyweight N` and `bw N` are N reps with nothing added, and `+W for R`
  or `+W x R` is W kg added (S702 covers a bare `+W`). In a barbell entry `bar for N` and `bar x N` are the empty
  bar. In an entry of another kind these go to the model. `skip` writes nothing: skipping is the screen's.
