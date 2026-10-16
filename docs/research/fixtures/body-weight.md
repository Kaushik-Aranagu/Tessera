# Body weight phrases (board item 71)

For Core (`TessGrammar`) and Builder A (body weight, M3 slice 1). Research lab. Date: 2026-10-16.

Twenty-five weigh-in phrases typed or said to Tess, with the route each should take under the 7:24 PM PT set-logger
call (S701 to S706) and the 7:34 PM PT M3 call (D12 settled: S701 stands, so a bare number near the last set weight
mid-workout goes to the model and weights snap), and what master does today. Routes: **ghost** (a Body weight ghost
row that waits for a tap, no 2 s commit, `m3-lines.md` T1), **commit** (a ghost that dries after 2 s, T6), **set**
(the workout's), or **nil** (the model). They are folded into `grammar-regression.md` as group M (M849 to M873).

**Master read:** `origin/master` at `bf28a92` (Merge PR #208). The grammar is `aec9ccd`'s: PR #205 added the
live-workout guard (`TessGrammar+Live.swift`, S701 to S706), which runs first for a phrase with no comma while an
entry is in focus; nothing in `TesseraTess` changed after it.
Master has no body weight code: no `BodyWeight` class, no `LogBodyWeight` action, and no model tool for it
(`logBodyWeight` was removed in `e0f476a`, `m3-1-2-brief.md` section 1). So every weigh-in target is gated on the
Body weight slice (M3 slice 1), and the status judges what master must do until then. No Swift toolchain here:
every result is a hand trace. Nothing was run. "TG:n" is `TesseraCore/Sources/TesseraTess/TessGrammar.swift` line n
on `bf28a92`, "K:n" is `TessGrammar+Kitchen.swift`, "LV:n" is `TessGrammar+Live.swift`.

## Contexts

All rows run on Thu 15 Oct 2026 18:10 America/Los_Angeles, as the suite does.
- **weigh-ins**: the 30 weigh-ins of `m3-1-2-brief.md` section 2 (Sep 3 to Wed 14 Oct, last entry 78.1 kg on Wed
  14, trend 78.2), unit kg. With the trend at 78.2, 82.4 is 4.2 kg above it, so the ghost carries T2's note.
- **lb**: `AppClock.unit` is lb: lines say lb, values convert to one decimal, the bare range is 66 to 550 (D11).
- **live workout**, **bw**: the suite's (Bench Press in focus, last set 80 x 8; Pull-Up in focus, last set 0 x 8).
- **total awaited**, **book in front**: the suite's (a shop ended 1 h ago with no total; Dune is the running process).
- **spoken**: the heard text; the normaliser runs first once it lands (master has none).

## The rows

| id | phrase | context | route and expected parse | decision: reason | master (hand trace) | status | root cause | gate |
|---|---|---|---|---|---|---|---|---|
| M849 | `82.4` | none, weigh-ins | ghost: LogBodyWeight 82.4 kg, waits for a tap, "4.2 KG ABOVE TREND" | B734: m3-lines T1, T2 | nil: a weight with no reps (TG:309-311); no day (TG:442) | pass | - | Body weight |
| M850 | `weighed 82.4` | none, weigh-ins | commit: LogBodyWeight 82.4 kg Thu 15, "Body weight logged. 82.4 kg, 4.2 above trend." | B734: T6, T4 | nil: `weighed` is a word with no reps (TG:311); a past verb with no day (TG:211) | pass | - | Body weight |
| M851 | `82.4 kg this morning` | none, weigh-ins | commit: LogBodyWeight 82.4 kg Thu 15 | B734: T6; BP2 | nil: no reps (TG:311); `this morning` is no day or time to `TessDates.find` (TG:511-542) | pass | - | Body weight |
| M852 | `weight 181 lb` | none, weigh-ins | commit: LogBodyWeight 82.1 kg, entered lb, "Body weight logged. 82.1 kg, 3.9 above trend." | B734; BP3 | nil: 181 lb read (TG:343-349), no reps (TG:311) | pass | - | Body weight |
| M853 | `82,4` | none, weigh-ins | nil (a comma decimal goes to the model; never a list) | BP1 | nil: comma sets need a lift or an entry (TG:268-298); no letters, so no grocery list (K:144); no day | pass | - | - |
| M854 | `eighty two point four` | none, weigh-ins, spoken | ghost: LogBodyWeight 82.4 kg (after the normaliser: `82.4`, as M849) | B734; BP6 (spoken-normaliser rule 7, `point`) | nil: no digits reach the grammar | pass | - | Body weight |
| M855 | `82.4 yesterday` | none, weigh-ins | ghost: LogBodyWeight 82.4 kg Wed 14, replacing 78.1 once kept, "Oct 14 body weight now 82.4 kg." (10 s undo) | BP2; m3-lines T11 | nil: `find` does not read `yesterday` (TG:511-542); no reps (TG:311) | pass | - | Body weight |
| M856 | `weighed 82.4 yesterday` | none, weigh-ins | commit: LogBodyWeight 82.4 kg Wed 14, replacing 78.1, "Oct 14 body weight now 82.4 kg." · now: note "Weighed 82.4" Wed 14 12:00 | BP2, C2 | note "Weighed 82.4" Wed 14 12:00 (TG:208-216) | pass | - | Body weight |
| M857 | `bw 82.4` | none, weigh-ins | commit: LogBodyWeight 82.4 kg | B734: T6 | nil: no reps (TG:311) | pass | - | Body weight |
| M858 | `82.4` | live workout, weigh-ins | nil (near the last weight, 80: the model; never a weigh-in mid-workout without `bw`) | B734, S701 | nil: not whole, so the live guard sends it to the model (LV:67-69) | pass | - | - |
| M859 | `78` | live workout, weigh-ins | nil (within two loads of 80 and above 50: the model; he may mean his weight) | B734, S701 | nil: above 50, so the live guard sends it to the model (LV:67-69) | pass | - | - |
| M860 | `82,4` | live workout, weigh-ins | nil (a comma decimal: the model; never two sets) | BP1, S701 | sets 80x82, 80x4: a comma skips the live guard (TG:74); no lift in `82 4`, so each part is bare reps (TG:272-298, TG:292, TG:234), and the comma snap leaves reps-only parts alone (TG:77-83, LV:103-104) | wrong write | REPS | - |
| M861 | `82.4 kg` | live workout, weigh-ins | nil (a weight with no reps, as K775; never a weigh-in mid-workout without `bw`) | B734 (D12), S701 | nil: no set shape, so the live guard lets it fall through (LV:71-72); no reps (TG:311) | pass | - | - |
| M862 | `bw 82.4` | live workout, weigh-ins | commit: LogBodyWeight 82.4 kg, the workout untouched (T13) · now: nil | B734: T13 | nil: `bw` needs a whole number (LV:21), no set shape (LV:71-72), no reps (TG:311) | pass | - | Body weight |
| M863 | `62.3` | live workout, weigh-ins | nil (a decimal far from 80 is still the model; never a set, never a weigh-in) | B734, S701 | nil: not whole, the model (LV:67-69) | pass | - | - |
| M864 | `65` | live workout, weigh-ins | nil (above 50 reps: the model) | S701 | nil: above 50, the model (LV:67-69) | pass | - | - |
| M865 | `bw 82.4` | live workout, bw, weigh-ins | commit: LogBodyWeight 82.4 kg (not whole reps 1 to 50, so a weigh-in) | BP4, B734 | nil: `bw` needs a whole number (LV:21), no set shape (LV:71-72), no reps (TG:311) | pass | - | Body weight |
| M866 | `bw 12` | live workout, bw, weigh-ins | set 0x12 (bodyweight, nothing added; never a weigh-in of 12) | BP4, S706 | set 0x12: `bw N` on a bodyweight lift (LV:21-23) | pass | - | - |
| M867 | `25` | none, weigh-ins | nil (below 30: not a body weight; the model) | B734: T16 | nil (TG:311, TG:442) | pass | - | - |
| M868 | `30` | none, weigh-ins | ghost: LogBodyWeight 30 kg, waits for a tap, "48.2 KG BELOW TREND" (30 to 250 is inclusive) | B734: T1, T2 | nil (TG:311) | pass | - | Body weight |
| M869 | `181.7` | none, weigh-ins, lb | ghost: LogBodyWeight 181.7 lb (82.4 kg), "Body weight 181.7 lb?", "9.3 LB ABOVE TREND" | B734 (m3-lines unit note), D11 | nil (TG:311) | pass | - | Body weight |
| M870 | `60` | none, weigh-ins, lb | nil (below 66 lb: not a body weight; the model) | B734, D11 | nil (TG:311) | pass | - | - |
| M871 | `82.4 kg` | none, weigh-ins, lb | commit: LogBodyWeight 82.4 kg, entered kg; the line in lb: "Body weight logged. 181.7 lb, 9.3 above trend." | BP3 | nil: no reps (TG:311) | pass | - | Body weight |
| M872 | `82.4` | none, weigh-ins, total awaited | LogShopTotal 82.40 (a waiting total wins over the body weight ghost) · now: nil | BP5, M410 | nil (TG:311) | pass | - | Money |
| M873 | `82` | none, weigh-ins, book in front | SetBookPage(Dune, 82) (the book in front wins; never a weigh-in) · now: nil | BP5, T706 | nil: the book in front claims nothing on master (TG:118-155); no reps (TG:311) | pass | - | Reading |

**Totals:** 25 rows: 24 pass, 1 wrong write, 0 miss. On `21f335a`, before the live guard, `78`, `65` and `82,4`
were wrong writes and `bw 12` a miss; the guard fixed all but `82,4`. 13 are gated on Body weight, 1 on Money, 1 on Reading, 10 not
gated.

| root cause | what goes wrong | rows | wrong write | miss |
|---|---|---|---|---|
| REPS | `82,4` mid-workout becomes two reps-only sets: the comma path skips the S701 guard | 1 | 1 | 0 |

## Worst wrong writes

1. **`82,4` mid-workout (M860)**: two sets, 80 x 82 and 80 x 4, from a weight typed with a decimal comma. Both dry in
   2 s and land in the history, the e1RM and the PR ledger. The live guard does not see it: a phrase with a comma
   skips `parseLive` (TG:74), the comma-set loop reads each part with `parseRelativeSet` (TG:292), and the comma snap
   only touches full sets and drops (LV:103-104). Fix: run the S701 bare-number test on each comma part too.

Nothing writes a body weight today. Every weigh-in falls to the model, which has no tool for it, so at worst nothing
is written (`I weigh 182 lb`, B318, is the same case; its target becomes a commit once Body weight lands).

## Proposed defaults (BP1 to BP6, for Product; none writes where master does not)

- **BP1 Comma decimals.** `82,4` goes to the model on his locale (decimal point), idle or mid-workout; it is never a
  list and never two sets. Core runs the S701 guard on each part of a comma list too.
- **BP2 Day words.** `today` and `this morning` are today. `yesterday` or a weekday back to six days ago dates the
  weigh-in and replaces that day's entry (T11's line, 10 s undo). A bare number with a day stays a ghost; with a
  prefix or a unit it commits.
- **BP3 Units.** A unit said wins over the setting. The value is stored in kg with the unit he said; the line uses
  the setting's unit.
- **BP4 `bw N` in a bodyweight entry.** A whole number 1 to 50 is reps (S706); anything else in 30 to 250 kg is a
  weigh-in. Everywhere else `bw N` is a weigh-in (T13).
- **BP5 Bare-number order.** A waiting shop total (M410) and the page of the book in front (T706) come before the
  body weight ghost. The ghost is the last bare-number reading: no process in front, no total waiting, 30 to 250 kg
  (66 to 550 lb), just before `parseTask`.
- **BP6 Spoken numbers.** `eighty two point four` reaches the rule as `82.4` through the normaliser
  (`spoken-normaliser.md` rule 7); master has no normaliser, so it stays nil until then.

Placement for Core (`m3-1-2-brief.md` section 4): the prefixes (`weighed`, `weigh`, `i weigh`, `weight`, `bw`) and a
number with a unit run after `parseForProcess` and before `parseRelativeSet`, except mid-workout, where only `bw`
binds. Keep the guards: `80` mid-workout is reps, `bench 82.4 x 5` is a lift, `what did i weigh monday` is a question.
