# Home lines hero masks: every line that prints a title, and what it must read

*Research, Oct 17, 2026. For Core and the Home UI builder. Read by hand on origin/master 24ae561b (the lines the brief gave for 47365b0 had not moved: `HomeLines.swift` :505, :518, :558, :647 are the same text; :503 is the `fact(done:)` signature). Nothing was built or run. Every title below is described in words, and every expected string is computed from the templates in `HomeLines.swift`. Sources: `qa/review-881-and-research-docs-oct17.md` section 1, `docs/research/fixtures/private-title-masks.md` (PT45 to PT48, section 4A), `design/gaps-92.md` section 3.*

**The ruling this fixture tests (gaps-92 section 3).** "Private workout" reads in the hero's own place and weight. The context line is the time or the day word as usual. No lock glyph, no dimming, no asterisks. Same pattern for "Private recipe", "Private list", "Private note", "Private item". Receipts and Tess's line use the same string, thing first ("Private workout done").

Files named below (all `TesseraCore/Sources/TesseraCore/...` unless a full path is given): `HomeLines.swift` is `Home/HomeLines.swift`; `ObjectPrivacy.swift` is `Tess/ObjectPrivacy.swift`.

## 1. Inventory: every Home line that prints a title

A Home item is a `HomeFact` (`HomeLines.swift:8`, kinds `workout, cook, shop, list, task, rest`). The title enters in six places (the fact builders), and is printed in four slots: the row line (`text`), the hero, the context (list only), and the UI keys. The detail (SO FAR) never prints a title.

### 1a. Where the title enters (fact builders)

| ID | file:line | Builder | Kind and state | Source of the title | Private-titled object today |
|---|---|---|---|---|---|
| F1 | `HomeLines.swift:505` | `fact(done:)` (signature :503) | workout, done | `summary.title`, filled raw at `Training/WorkoutSummary.swift:92` (`store.displayTitle(of: workout)`) | **Raw.** `summary.doneLine(in:)` (`WorkoutSummary.swift:43`) masks, but the Home fact does not |
| F2 | `HomeLines.swift:518` (used at :525 workout, :541 shop) | `fact(process:)` | workout, running or paused (and the shop's title) | `store.displayTitle(of: subject)` | **Raw** for a workout. Shop is always the Groceries list, so no private case |
| F3 | `HomeLines.swift:533` via `cookTitle` :593 | `fact(process:)` cook branch, `fact(doneCook:)` :567, `fact(plannedCook:)` :612 | cook, running, paused, done, planned | `ObjectPrivacy.label(of: recipe ?? object)`, else the wall tests, else the title | **Masked** to "Private recipe" (`ObjectPrivacy.recipeLabel`) |
| F4 | `HomeLines.swift:547` | `fact(process:)` list branch | list, running or paused | `ListContents.shownName(of:in:)` (`Lists/ListRuns.swift:19`) | **Masked** to "Private list" (`privateListLabel`, :17) |
| F5 | `HomeLines.swift:558` | `fact(planned:)` | workout, planned (the routine) | `store.displayTitle(of: routine)` | **Raw** |
| F6 | `HomeLines.swift:619` | `fact(task:)` | task, planned | `store.displayTitle(of: task)` | **Raw** at the builder. A label exists (`ObjectPrivacy.label` returns "Private task" for a task) but this line does not call it. Whether an upstream step already swaps the task is not traced |
| F7 | `HomeLines.swift:647` | `fact(scheduled:)` | workout, planned (a scheduled session) | `store.displayTitle(of: workout)` | **Raw** |

No `HomeFact` kind exists for a note or a list item. A private note or item never reaches a Home line by its title (a list's items appear only as a count, "3 left"). The note and item rows in section 2 are therefore guards: they must stay absent.

### 1b. Where the title is printed (the templates)

All in `HomeLines.swift`. `P` is the fact's title. "text" is the row line; "hero" is the big line; "ctx" is the context above the hero.

| ID | Slot | file:line | Kind and state | Template |
|---|---|---|---|---|
| L1 | text | :230 | cook, done | `P done.` |
| L2 | text | :232 | cook, running or paused, no step | `P, cooking.` |
| L3 | text | :233 | cook, running or paused | `P, on step N.` |
| L4 | text | :235 | shop, nothing left | `P: all in the basket.` |
| L5 | text | :236 | shop | `P: N left.` |
| L6 | text | :238 | list, nothing left | `P: all done.` |
| L7 | text | :240 | list, paused | `P: paused, N left.` |
| L8 | text | :242 | list, running | `P: N left.` |
| L9 | text | :245 | task | `P` (his words; the page draws the time at the right) |
| L10 | text | :253 | workout, done, no sets | `P, no sets.` |
| L11 | text | :255 | workout, done, 0 records | `P done.` |
| L12 | text | :256 | workout, done, 1 record | `P done. <Exercise> best.` |
| L13 | text | :257 | workout, done, N records | `P done. N bests.` |
| L14 | text | :261 | workout, running, every set in | `P, all sets in.` |
| L15 | text | :264 | workout, paused, no exercise | `P paused.` |
| L16 | text | :268 | workout, planned, with a time | `P, <clock>.` |
| L17 | text | :270 | workout, planned, no time | `P <tomorrow or day word>.` |
| L18 | text | :277, :281, :285 (`cookWhen`) | cook, planned, then `, N to buy.` (`toBuy`, :424) | `P tomorrow` or `P, <clock>` or `P <tonight or today>` + `, <count>.` |
| H1 | hero | :293 | workout, done | `P done` (no sets: `P, no sets`) |
| H2 | hero | :296, :298 | workout, running | `P, <exercise> set N` or `P, all sets in` |
| H3 | hero | :300, :301 | workout, paused | `P, paused at <exercise>` or `P, paused` |
| H4 | hero | :304, :306 | workout, planned | `P, <clock>` or `P` |
| H5 | hero | :308 | task | `P` |
| H6 | hero | :309 | list, paused | `P, paused` |
| H7 | hero | :310, :311 | list, running | `P, N left` or `P, all done` or `P` |
| H8 | hero | :313 | cook, done | `P done` |
| H9 | hero | :314 | cook, running or paused | `P, step N` or `P` |
| H10 | hero | :315, :316 | shop | `P, N left` or `P, all in the basket` |
| H11 | hero | :312 (cook planned) | cook, planned | `cookWhen`, same three forms as L18 without the count |
| C1 | ctx | :342 | list, running | `P` itself, only when it passes `fitsContext` (a name that does not fit says nothing, never a cut one) |
| W1 | widget | :133, :138 (`widgetWords`) | any | `hero` then `context`; for a running list this is `P, N left, P` (see O4) |

The 15 title-printing lines the brief expected are L1 to L18 minus the shop and rest ones that cannot be private (L4, L5, H10) and the hero set H1 to H11; every one of them reads `fact.title`, so one masked `fact.title` fixes all of them. The fix point is the six builders in 1a, not the templates.

### 1c. Where the UI repeats the title (outside `HomeLines`)

| ID | file:line | What it prints | Source | Today for a private-titled thing |
|---|---|---|---|---|
| U1 | `Features/Home/HomeLineHero.swift:53` | accessibility hint `Opens <title>` | `line.fact.title` | Follows F1 to F7 |
| U2 | `Features/Home/NowPage.swift:52`, :54 | key `Resume <title>` and its label (the running session) | `session.workout.title` | **Raw** (`WorkoutSession.shownTitle`, `Features/Workout/WorkoutSession.swift:30`, is the masked twin and is not used here) |
| U3 | `Features/Home/NowPage.swift:60`, :62 | key `Resume <title>` and its label (a suspended process) | `fact.title` | Follows F2 to F4 |
| U4 | `Features/Home/NowPage.swift:74`, :75, and the hint on the next line | `Start <title>` (rest-day key), `Starts <title> anyway` | `next.title` | **Raw** (a routine's own title field) |
| U5 | `Features/Home/NowPage.swift:86`, :88 | key `Start <title>` and its label (the scheduled session) | `model.store.displayTitle(of: workout)` | **Raw** |
| U6 | `Features/Home/NowPage.swift:299`, :300 | key `Start <title>` and its label (the planned routine) | `routine.title` | **Raw** |
| U7 | `TesseraCore/.../Home/HomeDonePack.swift:57`, :67, :70 | the Claude pack: refuses a walled title, else sends `title` and `names` | `fact.title` | Refuses a raw private title today (see O1) |

## 2. Rows: exact strings

**Fixture.** Day clock 18:10 (evening, so the planned day word is "this evening", the cook's is "tonight"). Done workouts ended 7:40 pm, 6 of 6 exercises, 22 sets. Running or paused: exercise Bench or Incline (short names), set 2, paused 21 minutes ago. Planned time 7 pm. Lists: 3 left. Cooks: step 3 of 12, 2 to buy. Control title: "Push Day A" (T6). Private titles, in words (the trap inputs T1 to T5 of `private-title-masks.md` section 2):

- **M** a routine titled with a medicine name (T1).
- **B** a routine titled "Weigh in" with a weight and unit (T2).
- **R** a list titled "Rent" with a four-digit amount (T3).
- **C** a routine titled with a care word and no number (T4).
- **S** a routine, recipe or list titled with a secret word and digits (T5).

Each private row is run once per title of its class; the expected strings do not depend on which. "Same" in a control column means the control prints its own title in the same template.

### 2a. Workout and routine (labels from `ObjectPrivacy.routineLabel`)

| ID | State and fact | Private (M, B, C, S) text | hero | ctx | detail | Control "Push Day A" text | hero |
|---|---|---|---|---|---|---|---|
| HH1 | done, 0 records | `Private workout done.` | `Private workout done` | `7:40 pm` | `6 exercises, 22 sets.` | `Push Day A done.` | `Push Day A done` |
| HH2 | done, 1 record (Bench) | `Private workout done. Bench best.` | `Private workout done` | `7:40 pm` | `6 exercises, 22 sets, 1 new best.` | `Push Day A done. Bench best.` | `Push Day A done` |
| HH3 | done, 3 records | `Private workout done. 3 bests.` | `Private workout done` | `7:40 pm` | `6 exercises, 22 sets, 3 new bests.` | `Push Day A done. 3 bests.` | `Push Day A done` |
| HH4 | done, no sets | `Private workout, no sets.` | `Private workout, no sets` | `this evening` | none | `Push Day A, no sets.` | `Push Day A, no sets` |
| HH5 | running, Bench set 2 | `Bench, set 2.` | `Private workout, bench set 2` | `now` | `2 exercises, 5 sets.` (counts as the control) | `Bench, set 2.` | `Push Day A, bench set 2` |
| HH6 | running, every set in | `Private workout, all sets in.` | `Private workout, all sets in` | `now` | as HH5 | `Push Day A, all sets in.` | `Push Day A, all sets in` |
| HH7 | paused, Incline set 2 | `Incline paused at set 2.` | `Private workout, paused at incline` | `paused 21 min ago` (short `paused 21 min`) | as HH5 | `Incline paused at set 2.` | `Push Day A, paused at incline` |
| HH8 | paused, no exercise | `Private workout paused.` | `Private workout, paused` | `paused 21 min ago` | as HH5 | `Push Day A paused.` | `Push Day A, paused` |
| HH9 | planned today, no time | `Private workout this evening.` | `Private workout` | `this evening` | none | `Push Day A this evening.` | `Push Day A` |
| HH10 | planned today, 7 pm (scheduled, F7) | `Private workout, 7 pm.` | `Private workout, 7 pm` | `this evening` | none | `Push Day A, 7 pm.` | `Push Day A, 7 pm` |
| HH11 | planned tomorrow (routine, F5) | `Private workout tomorrow.` | `Private workout` | `tomorrow, first` | none | `Push Day A tomorrow.` | `Push Day A` |

Routes: HH1 to HH4 come from F1, HH5 to HH8 from F2, HH9 and HH11 from F5, HH10 from F7. The key under the hero (U2 to U6) reads `Resume Private workout` or `Start Private workout`; the control reads `Resume Push Day A` or `Start Push Day A`.

### 2b. Recipe (cook) and list

| ID | Class and fact | Private text | hero | ctx | detail | Control text | hero |
|---|---|---|---|---|---|---|---|
| HH12 | cook planned today, 2 to buy | `Private recipe tonight, 2 to buy.` | `Private recipe tonight` | `2 to buy` | none | `Tacos tonight, 2 to buy.` | `Tacos tonight` |
| HH13 | cook planned 7 pm, 2 to buy | `Private recipe, 7 pm, 2 to buy.` | `Private recipe, 7 pm` | `2 to buy` | none | `Tacos, 7 pm, 2 to buy.` | `Tacos, 7 pm` |
| HH14 | cook planned tomorrow, nothing to buy | `Private recipe tomorrow, nothing to buy.` | `Private recipe tomorrow` | `tomorrow` | none | `Tacos tomorrow, nothing to buy.` | `Tacos tomorrow` |
| HH15 | cook running, step 3 of 12 | `Private recipe, on step 3.` | `Private recipe, step 3` | `now` | `Step 3 of 12.` | `Tacos, on step 3.` | `Tacos, step 3` |
| HH16 | cook done 7:40 pm | `Private recipe done.` | `Private recipe done` | `7:40 pm` | none | `Tacos done.` | `Tacos done` |
| HH17 | list running, 3 left | `Private list: 3 left.` | `Private list, 3 left` | `Private list` | `3 left.` | `Packing: 3 left.` | `Packing, 3 left` |
| HH18 | list running, all done | `Private list: all done.` | `Private list, all done` | `Private list` | `All done.` | `Packing: all done.` | `Packing, all done` |
| HH19 | list paused, 3 left | `Private list: paused, 3 left.` | `Private list, paused` | `paused 21 min ago` | `3 left.` | `Packing: paused, 3 left.` | `Packing, paused` |

HH12 to HH16 are masked today (F3). HH17 to HH19 are masked today (F4). They are rows so a refactor to one shared function cannot regress them.

### 2c. Task, note, item (guards)

| ID | Fact | Expected | Notes |
|---|---|---|---|
| HH20 | task with a medicine-name title, timed 7 pm (F6) | text `Private task`; hero `Private task`; ctx `7 pm` | Raw today at :619 (O2). Control: a plain task prints its own words |
| HH21 | task with a rent-shaped title, no time | text `Private task`; hero `Private task`; ctx none | Same |
| HH22 | a private note exists | No Home line prints it; no `HomeFact` kind for it | If one ever does, it reads `Private note` |
| HH23 | a private item in a running list | The list line is the count only (`Private list: 3 left.` or the control's); `Private item` never appears and the raw item never appears | Items are not titles on Home |

## 3. Caps: does "Private workout" fit every slot?

Caps (`HomeLines.swift:184-185`, `rowWords = 6` at :183): context at most 6 words and 32 characters, no stop; detail one sentence, at most 14 words and 80 characters, with its stop; row line at most 6 words (test `rowLinesStayWithinSixWords`, `HomeLinesTests.swift:209`).

Labels: "Private workout" is 15 characters, 2 words; "Private recipe" 14, 2; "Private list" 12, 2; "Private task" 12, 2; "Private note" 12, 2; "Private item" 12, 2.

| ID | Slot and string | Words / chars | Cap | Fits |
|---|---|---|---|---|
| CAP1 | ctx `Private list` (C1 :342) | 2 / 12 | 6 / 32 | yes |
| CAP2 | ctx a reworded `Private workout, 7:40 pm` (Claude may use `names`, `HomeLine.names`) | 4 / 24 | 6 / 32 | yes |
| CAP3 | ctx reworded `Private workout this evening` | 4 / 28 | 6 / 32 | yes |
| CAP4 | ctx reworded `Private workout tomorrow, first` | 4 / 31 | 6 / 32 | yes (1 character to spare) |
| CAP5 | ctx reworded `Private workout, paused 21 min ago` | 6 / 34 | 6 / 32 | **no**: 34 characters. `Private workout, paused 2 h ago` is 6 / 31 and fits. The checker refuses it, so Claude's line falls back to the rules context, which is correct (a line that fails is refused, not cut) |
| CAP6 | detail reworded `Private workout, 6 exercises, 22 sets, 3 new bests.` | 9 / 51 | 14 / 80 | yes |
| CAP7 | detail reworded with days since: `Private workout, 6 exercises, 22 sets, 3 new bests, 4 days since.` | 12 / 65 | 14 / 80 | yes |
| CAP8 | row `Private workout done. Bench best.` (L12) | 5 / 33 | 6 words | yes |
| CAP9 | row `Private workout done. 3 bests.` (L13) | 5 / 30 | 6 words | yes |
| CAP10 | row `Private workout, all sets in.` (L14) | 5 / 29 | 6 words | yes |
| CAP11 | row `Private workout this evening.` (L17) | 4 / 29 | 6 words | yes |
| CAP12 | row `Private recipe tonight, nothing to buy.` (L18) | 6 / 39 | 6 words | yes, at the cap exactly |
| CAP13 | row `Private recipe, 7 pm, 2 to buy.` (HH13) | 7 / 31 | 6 words | **no**: 7 words. The control `Tacos, 7 pm, 2 to buy.` is 6. A two-word title costs one word of room. No runtime check enforces `rowWords`; only the test does, and it does not seed this case (O3) |
| CAP14 | row `Private recipe tomorrow, nothing to buy.` (HH14) | 6 / 40 | 6 words | yes, at the cap exactly |
| CAP15 | row `Private list: paused, 12 left.` (L7) | 5 / 30 | 6 words | yes |
| CAP16 | the 15 longest template outputs for a workout (HH1 to HH11, text and hero) | all at most 5 words | 6 words | yes; "Private workout" is no longer than a typical title (the control "Incline Push Day B" is 4 words, longer) |

Detail never prints the title (`detail(for:)`, :382), so "Private workout" fits there by absence; CAP6 and CAP7 cover the Claude reword.

## 4. VoiceOver label rows

VoiceOver reads the same words as the screen, with no extra mention that the title is private (a spoken "private" would read the lock the design rules out).

| ID | Control | Expected label or hint | Control reads |
|---|---|---|---|
| VO1 | Hero button (`HomeLineHero.swift:53`) | hint `Opens Private workout` | `Opens Push Day A` |
| VO2 | Resume key, running session (`NowPage.swift:54`) | `Resume Private workout` | `Resume Push Day A` |
| VO3 | Resume key, suspended process (`NowPage.swift:62`) | `Resume Private workout`, `Resume Private recipe`, `Resume Private list` | `Resume Push Day A` |
| VO4 | Start key, rest-day key (`NowPage.swift:75`) and its hint (next line) | `Start Private workout`; hint `Starts Private workout anyway` | `Start Push Day A` |
| VO5 | Start key, scheduled session (`NowPage.swift:88`) | `Start Private workout` | `Start Push Day A` |
| VO6 | Start key, planned routine (`NowPage.swift:300`) | `Start Private workout` | `Start Push Day A` |
| VO7 | Hero text (`HomeHeroText`) | the hero string of its row, e.g. `Private workout done` | the control's |
| VO8 | Context line | the ctx string of its row, e.g. `7:40 pm` | the control's |

The raw title must appear in no `accessibilityLabel`, `accessibilityHint` or `accessibilityValue` on the Home page (VO1 to VO8).

## 5. Negative rows

| ID | Row | Expected |
|---|---|---|
| NG1 | No lock glyph | The Home hero tree for HH1 to HH23 holds no `Image(systemName:)` whose name contains `lock`, and no lock character in any string |
| NG2 | No dimming | The hero and the context carry the same foreground style as the control's (`Theme.Colors.context` for the context, ink for the hero); no `.opacity` or `.foregroundStyle` branch on privacy |
| NG3 | No asterisks | No string for HH1 to HH23 contains `*`, a run of bullets, or a masking character (the words are the label, nothing added) |
| NG4 | No extra words | No string contains "private" other than as the leading word of the label (so `Private workout done`, never `Private: workout done` or `Private workout (private)`) |
| NG5 | Raw never leaks | For titles M, B, R, C, S, no string for the row (text, hero, ctx, detail, key, hint, label, widget line, Claude pack) contains any token of the raw title, case-folded and whitespace-collapsed (T7) |
| NG6 | Tess's line and Home never disagree | For each of HH1 to HH4: the hero's title token, the row line's title token, the done pack's `title`, and the Tess done line's title token are all the same string. `WorkoutSummary.doneLine(in:)` and `HomeLines.line(for:)` give `Private workout` for the same fact |
| NG7 | Control unchanged | For "Push Day A" every string in HH1 to HH11 equals its pre-change value byte for byte |
| NG8 | No second label | No Home string contains "Private routine" (ruled O1: one label, "Private workout") |
| NG9 | Masked at source | `HomeFact.title` itself is the label (no UI-side swap): `HomeFacts.fact(done:)`, `fact(process:)`, `fact(planned:)`, `fact(scheduled:)` and `fact(task:)` return a fact whose `title` is the label, so the widget, the Claude pack and the ledger resume key follow |
| NG10 | Raw kept where it belongs | The routine's own title field and the op payload keep the raw title (O3 of `private-title-masks.md`); only display masks |

## 6. Status, owner, tests, gaps, questions

### 6a. Status and owner

| IDs | Status | Owner |
|---|---|---|
| F1, F2, F5, F7, L-rows for a workout, HH1 to HH11 | **traced**: the builders read `displayTitle`/`summary.title` raw (read at the lines named) | Core: one `ObjectPrivacy.shownTitle(of:)` (section 4A of `private-title-masks.md`) at `WorkoutSummary.swift:92`, :518, :558, :647 |
| F3, F4, HH12 to HH19 | **traced**: masked today at :593 and :547 | Core (guard rows) |
| F6, HH20, HH21 | **traced** at the builder (raw); **inferred** end to end (the upstream task source is not read) | Core |
| U2, U4, U5, U6, VO2, VO4 to VO6 | **traced**: raw reads at the lines named | Home UI builder (Product to name A or B) |
| U1, U3, VO1, VO3 | **traced**: follow the fact | Home UI builder (test only) |
| HH22, HH23 | **traced**: no kind exists | Core (guard) |
| CAP1 to CAP16 | **computed** from the templates; lengths counted by script | Core |
| NG1 to NG3 | **inferred**: needs the view tree or a snapshot; not read | Home UI builder |
| O1 (Claude pack) | **inferred**: `isWalled("Private workout")` was not run | Core |

### 6b. Swift Testing names

Core (in `TesseraCore/Tests/TesseraCoreTests/HomeLinesTests.swift`, new `@Suite("Home lines private titles")`):

- `doneFactForPrivateRoutineReadsPrivateWorkout` (HH1 to HH4, NG6)
- `runningFactForPrivateWorkoutReadsPrivateWorkout` (HH5, HH6)
- `pausedFactForPrivateWorkoutReadsPrivateWorkout` (HH7, HH8)
- `plannedRoutineFactForPrivateTitleReadsPrivateWorkout` (HH9, HH11)
- `scheduledWorkoutFactForPrivateTitleReadsPrivateWorkout` (HH10)
- `plannedTaskFactForPrivateTitleReadsPrivateTask` (HH20, HH21)
- `privateRecipeAndListLinesStayMasked` (HH12 to HH19)
- `noteAndItemNeverReachAHomeLine` (HH22, HH23)
- `privateWorkoutFitsEveryHomeSlot` (CAP1 to CAP16, with CAP5 and CAP13 as the two known edges)
- `homeRowLinesStayWithinSixWordsForMaskedTitles` (extends the existing six-word test to HH12 to HH19)
- `controlTitleLinesAreUnchanged` (NG7)
- `noHomeLineLeaksARawPrivateTitle` (NG5, runs T1 to T5 and T7)
- `homeAndTessDoneLineAgreeOnTheTitle` (NG6)
- `homeFactTitleIsMaskedAtTheSource` (NG9)
- `noHomeStringHasLockDimOrAsterisk` (NG3, NG4, NG8)
- `widgetLineForPrivateWorkoutUsesTheLabel` (W1)

Home UI builder (in `TesseraTests/`):

- `homeKeysAndHintsReadPrivateWorkoutForPrivateTitle` (VO1 to VO6, U2 to U6)
- `homeHeroHasNoLockOrDimForPrivateTitle` (NG1, NG2)
- `noHomeAccessibilityStringHoldsARawPrivateTitle` (VO7, VO8, NG5)

### 6c. Gaps by owner

**Core**
- G1: `fact(done:)` copies `summary.title` raw (:505 from `WorkoutSummary.swift:92`). Mask once at :92 and F1 follows. Keep the raw title in a second property only if a caller needs it.
- G2: F2, F5, F7 (:518, :558, :647) each need the same mask. One `shownTitle(of:)`, not three copies. Note that :518 also feeds the cook, list and shop branches, which already mask their own; the new function must be class-aware and must not turn "Groceries" or a masked cook into something else.
- G3: F6 (:619) prints a task's raw title; `ObjectPrivacy.label` already has "Private task" for it.
- G4: `PlanWording.swift:39` (`privateLabels`) lists "Private recipe", "Private task", "Private note", "Private item", "Private memory" but not "Private workout" or "Private list". A masked title that reaches the plan pack as a title is not recognised as a label (the Home done pack does not read this set, the plan pack does).
- G5: no test seeds a private routine title through `HomeFacts`. `WorkoutSummaryTests.swift:75` tests `routineTitle` alone.

**Home UI builder**
- G6: U2, U4, U5, U6 read the title from the object (`session.workout.title`, `next.title`, `routine.title`, `displayTitle(of: workout)`), not from the fact. After Core masks the fact, these keys still print the raw title unless they take the fact's title or `shownTitle(of:)`. `WorkoutSession.shownTitle` (`WorkoutSession.swift:30`) exists for U2.
- G7: the second hint at the rest-day key ("Starts <title> anyway") is the same read as U4.

### 6d. Open questions

- **O1 (Product and Core).** After the mask, `HomeDonePack.build` (:57) sees the title "Private workout", which is not a care, money or medicine word, so it is likely not walled, and the pack would build and a Claude call would go out for a private routine, where it refuses today (the raw title trips the wall). Should the pack still refuse when the title is the label? Suggest yes: refuse when `fact.title == ObjectPrivacy.routineLabel`, so the private done line stays the rules line and Tess's line and Home cannot disagree (NG6). Not run.
- **O2 (Core).** Does anything upstream of `fact(task:)` (:619) already swap a private task for its label? Not traced. If yes, F6 is a non-issue and HH20 and HH21 are guards.
- **O3 (Product).** A two-word label costs a word in `Private recipe, 7 pm, 2 to buy.` (CAP13, 7 words). Allow 7 words for this one row, drop the count when the time is present, or shorten to `Private recipe, 7 pm.` with the count in the context (which already says "2 to buy")? Suggest the last; the context line carries the count, so the row loses nothing.
- **O4 (Product).** The widget sentence for a running list prints the name twice: hero `Private list, 3 left` plus ctx `Private list` gives `Private list, 3 left, Private list` (`widgetWords`, :133 to :138). The same happens for a plain list ("Packing, 3 left, Packing"), so it is not a privacy bug, but the masked version is the one most likely to be screenshotted. Drop the context when it repeats the name?
- **O5 (Product).** Should the masked label also stop counting as a "name" in `HomeLine.names` (Claude may reword with it)? Suggest keep it: it lets Claude say "Private workout, 7:40 pm" within the caps (CAP2), the same string Home prints.
- **O6 (Core).** A workout created from a routine carries the routine's title (`PlanActions.swift:124`, from `private-title-masks.md`). If he renames the routine later, an old workout keeps the old private title; the mask is by the title at read time, so a title that stops being private un-masks old Home facts. Acceptable?

## 7. What I could not trace

- Whether the upstream of `fact(task:)` swaps a private task (O2), and `PlanWording` consumers of `privateLabels` beyond :39 to :43.
- The view tree for NG1 and NG2: no snapshot or render was read; those rows are inferred from the code reading above (no lock or opacity branch on privacy in `HomeLineHero.swift`, but I read only the context, hero and key parts).
- Whether `isWalled("Private workout")` is false (O1): read the word lists in `HomeDonePack.swift:115-120` and `PrivateWords.swift:28-30`, which hold no "private" or "workout", but did not run it.
- The widget extension and Lock Screen consumers of `HomeLine.widgetLine` outside the lines read here (`git grep` found no use in `Widgets/`; the extension may take its words another way).
- No test was run; no test name above is confirmed to compile.
