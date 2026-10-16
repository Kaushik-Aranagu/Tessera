# Set logger rerun on master aec9ccd (board item 66)

Research lab. Date: 2026-10-16. Reruns the 40 group K rows (`fixtures/set-logger.md`, K775 to K814) and the other
live-workout rows of `fixtures/grammar-regression.md` against Core's live-workout guard (PR #205, merged as
`aec9ccd`). No Swift toolchain here: every result is a hand trace of `git show aec9ccd:<path>`. Nothing was run.

**Refs.** "L:n" is `TesseraCore/Sources/TesseraTess/TessGrammar+Live.swift` line n, "TG:n" is `TessGrammar.swift`
line n, both at `aec9ccd`.

**What changed.** With an entry in focus and no comma, `parse` now calls `parseLive` before the lift, past-log,
kitchen and task rules (TG:74-76). `parseLive` either claims the phrase (a set, or nil for the model) or returns nil
and lets the old rules read it (L:14). A comma list with an entry snaps every part, and one part out of range sends
the lot to the model (TG:77-83). Only rows with an entry in focus can change; in the app the entry is the workout
session's (`AppModel.swift:167`), and in the suite only the `live workout` contexts carry one.

**Kit as the test store builds it.** `prepareCatalog` installs the starter kit (`StarterContent.swift:59-61`,
`97-114`): Bench Press is plates on a 20 kg bar, 20 to 177.5 in 2.5 kg steps; dumbbells 2 to 50 in 2 kg steps.
Lat Pulldown (cable) has no loads set, so it is 5 kg steps from 0 to 300 (`LoadProfile.swift:102-104`); Pull-Up is
2.5 kg steps from 0 to 300 (`LoadProfile.swift:105-106`). A tie snaps to the lighter load (`Dial.swift:26`, `min`
keeps the first).

## Summary

| | pass | wrong write | miss |
|---|---|---|---|
| K before (`0a27447`) | 16 | 17 | 7 |
| K after (`aec9ccd`) | 38 | 0 | 2 |
| non-K live rows that change | +6 | -2 | -4 |

All four of Core's claims hold: `100 for 5 at 8` logs 100x5 RPE 8 (K798), a bare `81` writes nothing (K783),
`81 for 8` logs 80x8 and says "81 isn't loadable." (K790), and `call mom at 7` mid-workout is still the task
(A121). The two K rows still failing are the spoken rows (NRM): no normaliser on master.

If no other row moved, the suite totals go from 613 pass, 121 wrong write, 80 miss to 641, 102, 71 (814 rows).
Rows A to J were not re-traced against the grammar changes before `0a27447`, so treat that as the delta only.

## Group K

| id | phrase | context | old | new | master at aec9ccd | note |
|---|---|---|---|---|---|---|
| K775 | `82.5` | live | pass | pass | nil: not whole (L:67-69) | |
| K776 | `80 for 8` | live | pass | pass | set 80x8 (TG:244, snap L:102-114) | |
| K777 | `80x8` | live | pass | pass | set 80x8 (TG:244) | |
| K778 | `same` | live | pass | pass | set 80x8 same (TG:231; snap skips `.same`, L:104) | |
| K779 | `one more` | live | pass | pass | set 80x8 same (TG:231) | |
| K780 | `8 reps` | live | pass | pass | set 80x8 reps only (L:67-69, TG:234) | 8 is below the bar, so not near 80 |
| K781 | `12` | db | pass | pass | set 24x12 (6 loads from 24, L:92-98) | |
| K782 | `24` | db | wrong write | pass | nil: within two loads (L:68-69) | REPS fixed |
| K783 | `81` | live | wrong write | pass | nil: above 50 (L:68) | REPS fixed |
| K784 | `55` | machine | wrong write | pass | nil: above 50 (L:68) | REPS fixed |
| K785 | `+5` | live | wrong write | pass | nil: signed change (L:37-39, on the raw phrase) | REPS fixed |
| K786 | `-5` | live | wrong write | pass | nil (L:37-39 reads the raw `-5`, before `normalize` drops the sign) | REPS fixed |
| K787 | `+2.5` | live | pass | pass | nil (L:37-39) | |
| K788 | `drop to 70 for 10` | live | pass | pass | set 70x10 drop (TG:237) | |
| K789 | `drop to 72 for 10` | live | wrong write | pass | set 72.5x10 drop, said 72 (L:110-113) | SNAP fixed |
| K790 | `81 for 8` | live | wrong write | pass | set 80x8, line ends "81 isn't loadable." | SNAP fixed |
| K791 | `81.25 x 8` | live | wrong write | pass | set 80x8 (tie, lighter wins) | SNAP fixed |
| K792 | `81.3 x 8` | live | wrong write | pass | set 82.5x8 | SNAP fixed |
| K793 | `200 x 3` | live | wrong write | pass | nil: above 177.5 (L:110) | SNAP fixed |
| K794 | `25 x 10` | db | wrong write | pass | set 24x10 (tie 24/26) | SNAP fixed |
| K795 | `57.5 x 10` | machine | wrong write | pass | set 55x10 (tie 55/60) | SNAP fixed |
| K796 | `80 x 8, 81 x 6` | live | wrong write | pass | sets 80x8, 80x6 (TG:77-83) | SNAP fixed |
| K797 | `180 lb for 5` | live | pass | pass | set 81.6 kg x 5, unit lb (snap skips lb, L:103) | |
| K798 | `100 for 5 at 8` | live | wrong write | pass | set 100x5 RPE 8 (L:56-65) | RPE fixed |
| K799 | `same at 9` | live | wrong write | pass | set 80x8 same RPE 9 | RPE fixed |
| K800 | `8 at 9` | live | wrong write | pass | set 80x8 reps only RPE 9 | RPE fixed |
| K801 | `fail at 6` | live | wrong write | pass | nil (L:41-43) | SETT fixed |
| K802 | `80 x 6 to failure` | live | miss | pass | set 80x6 failure (L:47-50) | KIND fixed |
| K803 | `warmup 60x5` | live | miss | pass | set 60x5 warmup (L:51-54) | KIND fixed |
| K804 | `skip` | live | pass | pass | nil (L:37) | now claimed, not fall-through |
| K805 | `bodyweight 12` | live | pass | pass | nil: Bench Press is not bodyweight (L:22) | |
| K806 | `bodyweight 12` | bw | miss | pass | set 0x12 (L:21-24) | LOADW fixed |
| K807 | `+10 for 6` | bw | miss | pass | set 10x6 (L:25-31, 10 is a 2.5 kg step) | LOADW fixed |
| K808 | `two plates` | live | pass | pass | nil (falls through, L:72; old rules as before) | |
| K809 | `bar for 10` | live | miss | pass | set 20x10 (L:32-35, `dial.bar`) | LOADW fixed |
| K810 | `eighty two and a half` | spoken | pass | pass | nil (falls through) | |
| K811 | `eighty two and a half for eight` | spoken | miss | miss | nil: no digits reach the grammar | NRM, needs the normaliser |
| K812 | `a hundred for five at eight` | spoken | miss | miss | nil: `at eight` has no digit, so L:56 does not match | NRM; once the normaliser gives `100 for 5 at 8`, L:56-65 reads it as K798 |
| K813 | `same` | no sets | pass | pass | nil (TG:231 needs a last set; falls through) | |
| K814 | `8` | no sets | pass | pass | nil: no last set (L:68) | |

## Core's SetLoggerTests against our K rows

The test (`TesseraCore/Tests/TesseraCoreTests/SetLoggerTests.swift` at `aec9ccd`) has 40 rows: 36 K rows plus B303,
B309, A180 and H625. Every expected value matches ours. **No row disagrees on the value.** Where they differ:

- **K796** is not in the row list but has its own test (`aCommaListSnapsEveryPart`, lines 123-131), same expectation.
- **K810, K811, K812** (spoken) are not covered. Fine for now: they need the normaliser. K812 should be added with the
  normaliser, since S704 is what decides it then.
- **What the test does not check** (lines 102-115): the phrase kind (`same` or reps only, K778 to K781, K800), the
  unit (K797 checks `81.6x5` only, not `unit lb`, as S703 keeps pounds), and whether nil means "claimed for the
  model" or "fell through". The snap line is checked once (`tessSaysWhenItSnapped`, `81 for 8`); S703 wants it on
  every snap. None of these is wrong on master; they are gaps that would let a later change slip.
- **H625** runs without the `total awaited` store our row names. Same answer here (the guard runs before any Money
  rule), but the row's point is "never a total", so the store should be in the test.

## Other live-workout rows (groups A to H)

Every other `live workout` row was traced through L:14-77. Six change, all toward pass:

| id | phrase | old | new | master at aec9ccd | why |
|---|---|---|---|---|---|
| A180 | `100` | wrong write (RC12) | pass | nil: above 50 (L:68) | S701 |
| B303 | `80 x 8 @8` | miss (RPE) | pass | set 80x8 RPE 8 (L:56-65) | S704 reads `@N` too |
| B304 | `82.5 x 6 @9` | miss (RPE) | pass | set 82.5x6 RPE 9 | S704 |
| B305 | `85 x 5 @9.5` | miss (RPE) | pass | set 85x5 RPE 9.5 (half step allowed, L:59) | S704 |
| B306 | `same @9` | miss (RPE) | pass | set 80x8 same RPE 9 | S704 |
| D473 | `3x10` | wrong write (RC12) | pass | nil: 3 kg is under the 20 kg bar, so snap gives nil (L:110) | by the range check, not by reading "no weight said" |

Root cause counts move with them: RPE (B303 to B306) goes to 0; RC12 goes from 8 to 6.

Checked and unchanged (each falls through at L:72 or is claimed with the same answer): A038, A042, A079 (`7` is
80x7), A080 (`at 7`: L:56 needs text before `at`), A081 to A083, A120, **A121 (`call mom at 7`: `call mom` is no set
core, L:57 and L:81-84, so it falls through to the task, still pass)**, A153, A159, A168 (now claimed nil by L:72
because `80x8 then` looks like a set; still miss), A169 (still wrong write, RC6), A170 and A171 (still wrong write),
A172, A174, A175, A177 to A179, A275, A276 (still miss), B296 to B302, B309 to B311, B313, B316, B321 to B323,
B359, B360, B366, C400, C428, D475, D476, E513 (now claimed nil by the warmup word, L:51 and L:72; same nil), E514,
F546, G559, G560 (`142`: nil, above 50), G586, H616, H624, H625. Rows in cook, shop run or none contexts carry no
entry, so `parseLive` never runs for them (D cook rows with numbers, A122, A123 and the other `at N` rows included).

## Gaps for Core (no suite row today; worth adding)

1. **`same at 3`, `8 at 3`, `same at 11`.** L:61 sends a non-RPE `at N` to the model only when the left side looks
   like a full set; for `same` or bare reps it returns nil and the old rules read it, so `8 at 3` becomes task "8"
   Fri 16 15:00 and `same at 11` task "Same". S704 says a set phrase is never a task in a live workout. Fix: return
   the model when `isSetCore` holds, not only `looksLikeSet`.
2. **`3x10` with dumbbells in focus.** D473 passes only because 3 is under the bar. In the db context `3x10` snaps to
   2x10 (tie 2/4) and `4x10` logs 4x10: a sets-by-reps phrase logged as a weight. Suggest a K row (db, `3x10`, nil).
3. **`24 reps` with dumbbells at 24.** The "reps" word is said, but L:67 still applies the near-weight test, so it
   goes to the model. A miss, not a wrong write; Product may want `N reps` exempt from S701.
