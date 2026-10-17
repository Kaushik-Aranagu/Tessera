# Review: #529 ios/plan-home, Plan my day on Home (Builder B, Design 53)

QA, Oct 16 2026, ~2:00 PM PT. Head **c19dfce**: one commit on master, merges cleanly. Static review.

## Verdict: PASS (two should-fix lows for Design and Builder B)

### The five checks
1. **Walls.** The only Claude call is `HomePlanModel.word` → `ClaudePlanWording.word(plan, pack:)` (HomePlan.swift:118-123).
   - The pack is `PlanPack(..., calendarKnown: false, includesEventTitles: false)`.
   - `PlanPack.packTitle` sends a secret, money or body title as "task" and every event as "busy" (PlanWording.swift:37-46, `SecretWords.mentions || PrivateFacts.isWalled`). `otherNames` goes through the same `isPrivate` filter (:164).
   - Notes are never in a DayPlan, so private notes and secret captures can't ride.
   - Nothing else in the diff builds a request.
2. **Off when asksClaude is false.** There are two gates:
   - `word()` returns before building the pack when `!model.asksClaude` (HomePlan.swift:117).
   - `ClaudePlanWording.word` checks `allowed()` before it reads the key (PlanWording.swift:450). AppModel wires `allowed` to `asksClaude` (AppModel.swift:62-75), and `asksClaude` already requires `settingsAreReal`.
   - With it off, the rules plan shows and nothing leaves the phone.
3. **Flags.** `-planNow` is read only through `LaunchFlags.has` inside `#if DEBUG` (NowPage.swift:151-158). `-resetDemo` clears the two offer flags the same way (HomePlan.swift:33-39).
   - The diff adds no raw `ProcessInfo` or `CommandLine` reads. The two `ProcessInfo` default parameters at AppClock.swift:18 and DemoData.swift:14 were already there and are the known ones.
   - The demo tasks are added only inside `DemoData.prepare`, which is behind `-demo`.
4. **UI test.** The new `testPlanOfferAndHoldKeepsIt` is in `HomeLinesUITests: SimulatorOnlyTestCase`.
5. **No Catalog or migration change.**
   - Keeping writes only existing `MoveTask` ops.
   - The offer state is two plain UserDefaults keys: the day number and a privacy-shown bool. Neither holds any of his content.

### Behaviour checked
- **Never over a workout.** `planNow` requires `model.session == nil && ledger.isEmpty`, which means nothing is running or paused. It also requires that the current timed item is not within 15 min, unless `-planNow` is set (NowPage.swift:33-35).
- **UNDO.** A swipe-keep is one op with UNDO; its `takeBack` also clears the row's kept mark. The hold runs one `MoveTask` per row. Its `takeBack` undoes every record, restores the kept set and the state, and re-opens the offer. BottomChrome runs `undo` then `takeBack` (BottomChrome.swift:737-741), and a note with a `takeBack` stays 10 s (HomeQueue.swift:36).
- **Skips write nothing.** Swipe-left skips write nothing and say nothing. Skipping the hero spends the offer for the day.
- **Motion.** All of it goes through `withTesseraAnimation` / `.tesseraAnimation`, and the breath pauses under Reduce Motion.

## What he sees (for Design)
- **Home TODAY, 08:00 to 21:00, when tasks need placing:**
  - context "this morning", "this afternoon", "this evening"
  - hero "Three tasks, Push A at 6 pm"
  - key START WITH <first>, a hold
  - "Plan" heading, with VIA CLAUDE once Claude's words land
  - up to 5 cobalt breathing rows, then "N MORE"
- **Lines:**
  - swipe keep: "Book physio, 9:30 am." with UNDO
  - hold: "Plan kept. Book physio is up." with UNDO
  - Claude's start line, when worded
- **One-time line under the rows:** "Sends your task and calendar titles, never notes, places or health."

## Should-fix lows
- **S1, the privacy line overstates and understates.**
  - It says "calendar titles", but this pack sends none: `includesEventTitles: false`, `calendarKnown: false`. Events go as "busy".
  - It doesn't say that money and body titles are kept back.
  - It also shows *after* the first send. Suggested: "Sends your task titles. Never notes, money, health or places." Design and Product decide whether it should come before the first send.
- **S2, two clocks bypass HouseTime (#507, merged).**
  - `HomePlanModel.spoken` (HomePlan.swift:196) and `PlanWords.heroForms` (:207-208) use `formatted(.dateTime.hour().minute())`. That follows the phone's 12/24-hour setting and locale, so a 24-hour phone says "Book physio, 09:30." and "Push A at 18".
  - The en_US output also carries a narrow no-break space before "am".
  - Use `HouseTime.clock` / `Format.clock`, as the rows already do (`PlanRow`, Format.clock).

## Lows
- **R1.** The offer re-reads only when `model.revision` changes, so at 21:00 the plan stays up until the next write. That's harmless.
- **R2.** `HomePlanModel` reads `Calendar.current` and `TesseraDay(calendar:)`, which is consistent with the rest of Home.

## Re-review at ffaa0b2 (rebased on master; merge-tree clean): **PASS**
- Wording off: `AppModel.planWordingReady = false` (AppModel.swift:64) is checked in `HomePlanModel.word` before any
  call (HomePlan.swift:115). With the flag off, ClaudePlanWording is never reached, so neither VIA CLAUDE nor the
  one-time line can show. PlanWordingOffTests sets asksClaude true and checks the plan shows, wordingCalls == 0 and
  viaClaude is false. The counter goes up after the guard, so the test pins the call site rather than the flag alone.
- S2 fixed: `spoken`, `heroForms` and the context all use `HouseTime.clock` (HomePlan.swift:206, :220, :226).
  `context` shows the first ghost row's time in plan order ("from 8:15 am"). Without a row it shows nothing.
- S1 superseded: the line now reads "Titles and counts only. Never notes, places, health or money." (HomePlan.swift:271,
  Design's copy pass). It covers money and is unreachable while the wording is off.
- Hero digits: "3 tasks" and "1 task" (HomePlan.swift:217).
- The UI test still subclasses SimulatorOnlyTestCase and covers skip, keep, hold and UNDO. `-planNow` is read only
  through LaunchFlags (NowPage.swift:155).
- Nothing new in data safety, the Catalog or migrations. No key literals.
- Low R3: `HomePlanModel.init` is no longer private (it was made internal for the test). Shared state still goes
  through `.shared`. Not blocking.
