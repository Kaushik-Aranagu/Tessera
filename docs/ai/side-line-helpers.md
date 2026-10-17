# Side-line helpers (spec for Core)

Audience: Core engineers. Inputs: `research/fixtures/side-lines.md` (sections 2, 3, Q5) and `docs/ai/side-jobs.md` section 1. Code paths are under `TesseraCore/Sources/TesseraCore/`. Docs only; no fixture rows are written here.

## 0. Findings against the working tree

The fixture (read against master a438262) says the task move count and buy cadence have no helper. The tree I read already has both: `Tasks/TaskStory.swift` (`moves`, `rolls`, hand actors `.user/.tess/.intent`) and `Kitchen/BuyCadence.swift` (`days`, `everyDays`, `minimumBuys = 3`, reads `checkListItem` ops). Both are on current master (checked Oct 16 at the 4:30 PM PT master head). So sections 1 and 2 below are "confirm and wrap", not build. The other four helpers are absent from the tree: nothing public counts a routine's runs, cook durations, a month sum, or planned cooks (`cooksByDay` in `DayLog/WeekFacts.swift:202` gives recipe titles per day, not durations or plans).

Shared rules for every helper:

- **House day.** Group and compare by `TesseraDay` (`Engine/TesseraDay.swift`): 04:00 to 04:00, weeks start Monday, `month(containing:)` has 04:00 edges. 00:30 on the 1st is still last month. Never use `startOfDay` for a key. Times shown in a line come from `HouseTime.clock` (`Format/HouseTime.swift:7`), 12-hour lowercase. The helpers return `Date` values and numbers; they never format.
- **Too little history returns nil, never 0 and never a default,** so the band stays empty (rule E5). A zero count is also nil where the fixture says E6.
- **Privacy.** No helper reads a private note, a money amount or a body measure. Concretely: no note body or title fields, no `note` field on a Cook (`Catalog/SystemCatalog.swift:320`), no `notes` on an Exercise, no body-weight or money class objects, no field with `isPrivate`-style walls. A helper skips any object whose title fails `PrivateFacts.isPrivateTitle` (`Tess/PrivateFacts.swift:12`) when its result would name that object. Helpers return counts, dates and durations only. The finished line still goes through `SecretWords.mentions` and `PrivateFacts.isWalled` (E3), but that is the caller's check, not a helper's job.
- **Actors.** Op-log helpers count `.user`, `.tess`, `.intent` only; `.system` never counts (same set as `TaskStory.handActors`, which is `static`, internal).
- **Isolation.** Follow the neighbors: `@MainActor` structs that take `ObjectStore` or `ActionEngine`. Swift 6 strict concurrency; no `nonisolated(unsafe)` caches.
- **Undone records.** Count only `record.state == .committed`.

## 1. Task move count (confirm, thin wrapper)

- **Signature (new, wrapper):** `extension TaskStory { public var sideLine: Moves? }` with `public struct Moves: Equatable, Sendable { public let hand: Int; public let firstPlanned: Date? }`. Or call `TaskStory(of:engine:).moves` directly; a wrapper is optional.
- **Reads:** `engine.history(of: task.id, limit: .max)`; `OpRecord.action == "moveTask"`, `.actor`, `.state`, `.createdAt`; the task's `createdAt`. `keepPlannedTask` is "planned", `rollForwardTasks` (`.system`) is "rolled"; neither is a move (fixture Q3 says rolls are not moves, awaiting Product).
- **House day:** a task made today (`TesseraDay.isSameDay(madeAt, now)`) returns nil (E4). "First planned {day}" uses the day of the first `moved` or `planned` target, as a `Date` key.
- **Too little:** nil when `moves == 0` and there is no first-planned day, or the task was made today. Never returns 0.
- **Feeds:** kind Task (3), "ITS STORY"; glance GL-2, GL-E1, GL-E4. Rows SL-T1, SL-T2, SL-T3, SL-T4.
- **Privacy:** does not read the title. SL-T4 ("Reset bank pin") must produce the same line as SL-T1 because the line never names the task.
- **Tests:** `taskMovesCountHandActorsOnly`, `taskMovesIgnoreNightlyRollsAndKeeps`, `taskMadeTodayHasNoStory`, `taskMovesRespectFourAmDay`.

## 2. Buy cadence (confirm; no new field needed)

- **Signature (existing):** `BuyCadence(of: ingredient, engine:, calendar:)`, `.everyDays: Int?`, `.line: String?`.
- **Decision:** read the op log, do not add a buy date to the ingredient. Reason verified in the tree: checked rows are deleted at the shop's end, so only `checkListItem` ops (with `setValue(... .bool(true))`) and the item's incoming `about` link survive (`BuyCadence.init`). A stored date would be a second source of truth and would need a migration. If the op log is ever compacted (unverified whether any compaction exists), revisit and add the field then.
- **Reads:** `ingredient.incomingLinks` (grocery items whose `about` points at it), `OpRecord.action == "checkListItem"`, `.state`, `.actor`, `.objectIDs`, `.ops` (`.setValue ... .bool(true)`), `.createdAt`.
- **House day:** one buy per `TesseraDay.day(of:)`, so a 02:00 check counts for the day before. The mean gap is `span / (buys - 1)`, rounded, minimum 1.
- **Too little:** nil under 3 buy days (`minimumBuys`), which is E5; the line then falls back to "In {n} of your recipes." (via `RecipeBook.recipes(using:)`, `Kitchen/Recipes.swift:88`) or empty (SL-I3, SL-I5).
- **Gap to close:** `.line` is a built sentence inside Core; side lines should build their own text. Expose `everyDays` and keep `.line` for compatibility. A first-day ingredient (E4) must return nil: add `guard` on `ingredient.createdAt` in the caller.
- **Feeds:** kind Ingredient (18), "PER 100 G"; rows SL-I1, SL-I2, SL-I3, SL-I5. Not SL-I4 (nutrition never enters).
- **Privacy:** reads grocery ops only; no quantity, price or note. A price on a row (money) is never read.
- **Tests:** `ingredientCadenceNeedsThreeBuys`, `cadenceCountsOneBuyPerHouseDay`, `cadenceIgnoresSystemChecks`, `cadenceSurvivesDeletedGroceryRows`.

## 3. Public routine last-run

- **Signature (new):** 
```swift
@MainActor public struct RoutineRuns {
    public init(of routine: ObjectRecord, store: ObjectStore, classes: ClassResolver, calendar: Calendar = .current)
    public func lastFinished(before now: Date) -> Date?
    public func daysSinceLast(before now: Date) -> Int?
    public func finishedCount(inMonthOf now: Date) -> Int?
}
```
  It promotes the internal `HomeFacts.daysSinceLastRun(of:before:)` (`Home/HomeLines.swift:593`) and reuses its logic. `HomeFacts` then calls the new type. The class-resolver type name is **unverified**; use whatever `HomeFacts` holds as `engine.classes`.
- **Reads:** Workout objects where the `routine` link points at the routine; `endedAt` (`Catalog/SystemCatalog.swift:131-132`); `isDeleted`. Not `scheduledFor`, not sets, not weights.
- **House day:** "days since" is the difference between `TesseraDay.day(of:)` of `endedAt` and of `now`, as in the existing code. A workout ended at 01:00 Friday belongs to Thursday. The month count uses `TesseraDay.month(containing:)`.
- **Too little:** `lastFinished` nil when never run (SL-R2, SL-R4); `finishedCount` nil when 0 (E6).
- **Feeds:** Routines (5) "LAST TIMES" and Routine (6); rows SL-R1, SL-R2, SL-R3, SL-R4; also SL-WK2 ("last done 6 days ago"); glance GL-4, GL-5. "Next" in SL-R1 comes from `PlanSchedule` (`Training/PlanSchedule.swift:23`), not this helper.
- **Privacy:** reads dates only, never set weights, never `WorkoutSummary` notes.
- **Tests:** `routineLastRunIsNilWhenNeverFinished`, `routineLastRunUsesHouseDay`, `routineMonthCountIgnoresOtherRoutinesAndDeleted`, `homeLinesStillUsesSameDaysSinceLast`.

## 4. Cook durations

- **Signature (new):**
```swift
extension CookLog {
    public func durations(of recipe: ObjectRecord) -> [TimeInterval]
    public func medianMinutes(of recipe: ObjectRecord) -> Int?
}
```
- **Reads:** `cooks(of:)` (`Kitchen/Cooking.swift:30`), each cook's `createdAt` (set by `StartCooking`, line 89) and `cookedAt` (set by `FinishCooking`, line 238). The Cook class has **no** `startedAt` field (`Catalog/SystemCatalog.swift:316-321`), although `HomeLines.fact(doneCook:)` reads one and so gets nil; do not copy that. The Process object for the cook has `startedAt` and `endedAt` (`Processes/ProcessModel.swift`), a possible alternative; unverified whether it survives after the cook is done.
- **Known risk:** a cook set aside and resumed reuses the same Cook (`StartCooking` picks the open one back up), so `createdAt` to `cookedAt` includes the pause. Spec: drop any cook longer than 6 hours, and name the cutoff a constant (`CookLog.longestPlausible`). Product to confirm 6 hours (unverified rule; mine).
- **House day:** none for the duration itself. A cook finished across 04:00 is still one duration. Group by day only if a caller needs it, via `TesseraDay`.
- **Too little:** `medianMinutes` nil under 2 finished cooks (E5, SL-C4). Two cooks give the mean of the two (SL-C5: 44 and 54 gives 49). Odd counts take the middle; even counts the mean of the middle two, rounded to the nearest minute.
- **Feeds:** Recipe original (17) "COOKS"; rows SL-C3, SL-C4, SL-C5; glance GL-12.
- **Privacy:** never reads `note` on a Cook or the recipe's steps.
- **Tests:** `cookMedianIsNilUnderTwoCooks`, `cookMedianOfTwoIsTheirMean`, `cookDurationDropsImplausiblyLongPaused`, `cookDurationIgnoresUnfinishedAndDeleted`.

## 5. Month sum

- **Signature (new):**
```swift
extension WeekFactsBuilder {
    public func month(containing date: Date, plan: ObjectRecord?, now: Date = .now) -> MonthFacts?
}
public struct MonthFacts: Equatable, Sendable {
    public let sessions: Int
    public let tasksDone: Int
    public let weeks: Int
}
```
- **Reads:** `WeekFacts.trainedDays` (`DayLog/WeekFacts.swift`; note: days with a finished workout, not sessions, so two sessions in a day count once; the fixture says "sessions", so decide and document: unverified), and `tasksDoneByDay()` (:215). Sum by day key inside `TesseraDay.month(containing:)`, not by summing whole weeks (a week straddles two months; the fixture's "summed over the month's weeks" would double count at the edges).
- **House day:** month edges at 04:00; keys from `OpZones.dayKey` as the existing builders do (trip zones, R12).
- **Too little:** nil when the month has under 2 full weeks of use (`firstUse()` at :189; GL-15 wants "4 weeks", SL-M2 wants empty in the first week; the 2-week cutoff is unverified, Product to rule). Also nil when both sums are 0 (E6).
- **Feeds:** Review tab (20) "THE MONTH"; rows SL-M1, SL-M2; glance GL-15 (superseded by depth-76 per the fixture; keep the helper for the side line).
- **Privacy:** counts only. Never reads task titles, workout notes, body weight or money.
- **Tests:** `monthSumUsesHouseMonthEdges`, `monthSumIsNilInFirstWeek`, `monthSumDoesNotDoubleCountStraddlingWeek`.

## 6. Planned cooks

- **Signature (new):**
```swift
@MainActor public struct PlannedCooks {
    public init(store: ObjectStore, classes: ClassResolver, calendar: Calendar = .current)
    public func inWeek(containing date: Date) -> [(recipe: ObjectRecord, day: Date)]
    public func toBuyCount(inWeek date: Date) -> Int?
}
```
- **What a planned cook is on master:** a Task whose `about` link is a Recipe, with its `due` date (`HomeFacts.fact(plannedCook:recipe:)`, `Home/HomeLines.swift:552`; test at `Tests/TesseraCoreTests/HomeLinesTests.swift:311`). Which field links the recipe is **unverified**; read how that test builds `dinner`. The fixture says Kitchen week 67 owns the real model, so this helper may be replaced; keep the signature stable and the body small.
- **Reads:** Task `due`, the recipe link, `isDone`, `isDeleted`; `Groceries.toBuy(for:)` (`Kitchen/Groceries.swift:59`) for the count, summed over distinct rows (a row two cooks share counts once; unverified how `toBuy` returns, check before summing).
- **House day:** `day` is `TesseraDay.day(of: due)`; the week is `TesseraDay.week(containing:)`. A cook due 01:00 Saturday belongs to Friday.
- **Too little:** `inWeek` empty gives no line (SL-K2); `toBuyCount` nil when no cooks. A done cook task is not "planned".
- **Feeds:** Kitchen tab (13) "THE WEEK'S COOKS"; rows SL-K1, SL-K2; glance GL-9.
- **Privacy:** reads task `due` and the recipe link only. Skip a task whose title fails `PrivateFacts.isPrivateTitle`. Never reads the task's note.
- **Tests:** `plannedCooksUseHouseDayAndWeek`, `plannedCooksSkipDoneAndDeleted`, `plannedCooksToBuyCountsSharedRowOnce`, `noPlannedCooksGivesNilBuyCount`.

## 7. Open points

2. Rolls are not moves (fixture Q3); Product to rule.
3. 6-hour cook cutoff and 2-week month minimum are my proposals, not facts.
4. "Sessions" in the month sum: days trained or workouts finished.
5. Food table (fixture Q5) is out of scope here.
