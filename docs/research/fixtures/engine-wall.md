# One engine wall: every action that writes his text

For: Product's board, item AZ, for Core 0ai. Owner: Research lab. Oct 16, 2026, read on origin/master c7346eb (no
code under `App/`, `Features/` or `TesseraCore/` changed since f874295, which
[`../input-paths-walls.md`](../input-paths-walls.md) was read on). Every phrase here is made up (hunter2, tacocat,
4417, "sam", "the fake store"). Key cases never spell a key: the tests read `fakeKey`, which returns the package's own
test key (`ClaudeKeyTests.key`).

Product (2:06 pm, from the board; not yet in `decisions.md` on master): one wall in Core instead of a fix per path.
Every engine action that writes user text passes one shared check.

## 1. The check

One function, four answers, in this order:

| Order | Hit | Test on master today | Answer | Ruling |
|---|---|---|---|---|
| 1 | Claude key | `looksLikeClaudeKey` (`ClaudeKeyGuard.swift:13`, any case) | **Refuse.** Nothing stored, logged or kept as a note. Reason `refused: looksLikeKey`, as `CreateNote` throws today (`Notes.swift:108`) | 12:22 pm B1-11, 1:13 pm |
| 2 | Secret with a value | `SecretWords.hasValue` (`SecretWords.swift:40`) for a typed line; `isPrivateLine` (`:85`) for a pasted line | **Private note.** Title "Private note", the words only in its body | NE1/R4, 1:58 pm (1) |
| 3 | Money with an amount, said in the past ("paid rent 2100 fri") | Product's money test (2:22 pm): a currency sign; or an amount with a decimal or 3 or more digits; or a money verb next to a bare number with no unit noun ("bought 2 lemons" stays plain). `PrivateFacts.isMoneyShaped` (`PrivateFacts.swift:26`) is narrowed to it | **Private note**, dated when the action carries a day | 1:15 pm pick 3, 2:22 pm (3) |
| 3a | Money with an amount, still to do, with a day ("pay rent 2100 fri") | same test, plus a present-tense verb and a day | **Task with the amount dropped**, like a grocery price: task "Pay rent" on Friday, receipt "Pay rent, Friday." No amount in any title | 2:22 pm (1) |
| 3b | Money with an amount and no day ("bought a tv for 800", "paid 45.20 gas") | same check | **Private note**, dated now, never a task; no amount ever goes in a task title | 2:16 pm (from the coordinator; not yet in `decisions.md` on master) |
| 4 | Body fact | `PrivateFacts.isBodyShaped` (`PrivateFacts.swift:64`) | **Private note** | 1:15 pm, 12:02 pm, 1:36 pm |
| 4a | Medicine reminder: a medicine word (`PrivateFacts.medicines`, `:50-53`) in a task with a time ("take 2 advil" at 9 pm) | same check, plus the task's time | **Private task**: a task titled "Private task" at that time; the words only in a linked private note | 2:22 pm (2) |

A secret word with no value ("reset my PIN") passes as typed (12:30 pm; the hero shows it as "Private task", per an earlier ruling).

What "private note" means per action, so one answer fits all 28 rows:

- **Reroute** (the text is the point: a title, an item, a list name, who he waits on): the action does not run; one
  `CreateNote(body:on:isPrivate: true)` is written instead, in the same op record, pending if the action was pending.
- **Task without the amount** (rule 3a, task-making rows 1, 26, 27, 28 only): the task is made with the amount
  and any currency word cut from its title; nothing private is written. Telling past from future needs a short list
  of past money verbs in Core (paid, spent, bought, venmoed, zelled, tipped, refunded; `PrivateFacts.swift:30` already
  holds the first three). On a row that can't make a task (a routine name, a list item), "pay rent 2100 fri" is a
  private note dated now.
- **Private task** (rule 4a, the same four rows): the task is made titled "Private task" at its time, and its words
  go to a private note linked through `about`.
- **Run without it** (the text is an extra: a timer label, a cook's note, a next step, a recipe title override): the
  action runs with that field cleared (a timer is "Timer"), and the text becomes a private note in the same record.
- **Own private form**: `CreateNote` and `EditNote` make the note itself private; `RememberFact` keeps a body fact as a
  private memory line (1:13 pm, "Health note, kept on this phone.") and refuses secrets and money (R7, 3:24 am MU2).
- **Structured**: a field read by a parser (`progression`) is refused by its own validation; the wall checks the key
  only.

Where it sits: **`ActionEngine.perform`, before `action.apply` (`ActionEngine.swift:47-50`).** That one spot sees the
UI, the grammar, the on-device model and Claude (both through `TessTools.run`, `TessTools.swift:32-33`), Siri and
`perform(named:)` (`:78-87`). Each action names its text fields once (a `wallText` list on the action), so the wall
never guesses. Two backstops: `Transaction.create`, `setTitle` and `set(.text/.richText)` (`Transaction.swift:34-83`)
refuse a key whatever called them, and the writers outside the engine (rows 24 and 25 below: memory turnover and the inbox) call the same check
by hand.

## 2. Every action that writes user text

"S M B K" is master today for secret, money-with-a-day, body and key. Money with no day (2:16 pm) reads the same as M
on every row: same check, no date, and the phrases below ("bought a tv for 800", "paid 45.20 gas") fail wherever M fails. **P**: the cell already holds; **F**: it doesn't.
"Called by" is who reaches it on master (none means only `ActionRegistry` decode, which nothing calls).

| # | Action | file:line | Text it writes | Wall | Called by | S M B K | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | `CreateTask` | `TrainingActions.swift:403` | title `:434`; summary "Added “title”" `:445` | perform, reroute; dated by `startsAt` or `due` | Ask bar `CaptureParts` via `AppModel.swift:188`; grammar `TessCaptureEngine.swift:294`; model and Claude `TessTools.swift:118`; Siri `Intents.swift:144` | F F F F | not walled |
| 2 | `RenameObject` | `TrainingActions.swift:492` | title `:507`, on any object, a private note included | perform, reroute; refuse any title change on an `isPrivate` object | none | F F F F | not walled |
| 3 | `CreateRoutine` | `PlanActions.swift:5` | title `:21`; shows in Plans, the Live Activity and the Siri picker (`Entities.swift:58-104`) | perform, reroute | Routines "Name it" `RoutinesPage.swift:142`; demo | F F F F | not walled |
| 4 | `CreatePlan` | `PlanActions.swift:147` | title `:176` (not even trimmed) | perform, reroute | demo only `DemoData.swift:137` | F F F F | not walled |
| 5 | `AddSlot` | `PlanActions.swift:30` | `progression` `:88` | structured: `ProgressionRule` refuses at `:70-72`; wall checks key | routine editor, exercise page | P P P P | walled |
| 6 | `EditSlot` | `RoutineEditing.swift:42` | `progression` `:101` | structured: refused at `:85-87` | routine editor | P P P P | walled |
| 7 | `CreateNote` | `Notes.swift:80` | title `:113`, body `:114`; dated by `on` `:121` | perform, own form: `isPrivate` when walled | Notes page `NotesView.swift:121`; grammar `TessCaptureEngine.swift:298-302`; tools `TessTools.swift:190`; Siri `Intents.swift:141` | P F F P | partial |
| 8 | `EditNote` | `Notes.swift:137` | body `:169`/`:177`, title `:172`/`:181` | perform, own form: the note turns private | note editor `NoteEditor.swift:164` | P F F P | partial |
| 9 | `AddGroceries` | `Groceries.swift:403` | ingredient name `:419`, item `:421`; summary `:431`; receipt `:442` | perform, per line: walled lines become private notes, the rest are added | Groceries line `GroceriesView.swift:203`; grammar `TessCaptureEngine.swift:324`; tools `TessTools.swift:155` | F F F F | not walled |
| 10 | `CreateRecipe` | `Recipes.swift:122` | title override `:172`, `sourceText` `:174`, lines `:195-198`, steps `:228` | perform: title override runs without it; body text keeps the pasted-line cut (`:162-164`) and is never money-walled (11:52 am) | Paste `PasteRecipe.swift:201`; grammar `:376`; tools `:207` | F F F F | not walled (secret lines in the text: P, P06) |
| 11 | `EditRecipe` | `Recipes.swift:252` | title `:278` | perform, reroute | none | F F F F | not walled |
| 12 | `StartKitchenTimer` | `Cooking.swift:155` | title from label `:182`; summary `:197` | perform, run without it ("Timer") | grammar `TessCaptureEngine.swift:350` | F F F F | not walled |
| 13 | `FinishCooking` | `Cooking.swift:222` | cook `note` `:243` | perform, run without it | grammar `:370` (passes no note today) | F F F F | not walled |
| 14 | `CreateList` | `Lists.swift:73` | title `:89`; receipt "Films, made" `:97` | perform, reroute | grammar `TessCaptureEngine.swift:354`; tools `TessTools.swift:178` | F F F F | not walled |
| 15 | `AddListItem` | `Lists.swift:102` | title `:132`, `quantity` `:135`, `section` `:138`; receipt `:151` | perform, reroute | tools `TessTools.swift:314` (no Lists view yet) | F F F F | not walled |
| 16 | `MoveListItem` | `Lists.swift:196` | `section` `:216`, and on Groceries the ingredient's `aisle` `:221` | perform, reroute (item stays put) | none | F F F F | not walled |
| 17 | `RenameListSection` | `Lists.swift:244` | `section` on every item `:266`; summary, receipt `:271-275` | perform, reroute | none | F F F F | not walled |
| 18 | `StartProcess` | `ProcessActions.swift:6` | `nextStep` via `saveContext` `:265`, `ownerApp` `:46` | perform, run without it | inside `StartWorkout` `TrainingActions.swift:222` (fixed strings) | F F F F | not walled |
| 19 | `SaveContext` | `ProcessActions.swift:59` | `nextStep` `:81` to `:265` | perform, run without it | none | F F F F | not walled |
| 20 | `SuspendProcess` | `ProcessActions.swift:90` | `nextStep` `:117` to `:265` | perform, run without it | Groceries `GroceriesView.swift:268` (no step) | F F F F | not walled |
| 21 | `StartTask` | `TaskProcesses.swift:7` | `nextStep` `:23` (defaults to the task's title) | perform, run without it | none | F F F F | not walled |
| 22 | `WaitOnTask` | `TaskProcesses.swift:33` | `waitingOn` `:59`; summary "Waiting on …" `:65` | perform, reroute | none | F F F F | not walled |
| 23 | `RememberFact` | `TessMemory.swift:171` | memory title `:252`; summary "Kept. …" `:269` | perform, own form; its screen (`:226`, `TessMemory.swift:135-160`) becomes the shared check plus memory's place rule | decode only (the grammar's "remember" goes to a private note, R7) | P F F P | partial |
| 24 | Memory turnover (not an action) | `TessMemory+Turnover.swift:35`, line built `:59-104`, written by `TessMemoryStore.write` `TessMemory.swift:644-680` (`store.create` `:665`, in-place title `:661`) | yesterday's Day log line | call the check in `write` before `:665` | every launch, once a day | P F F P | partial |
| 25 | Inbox (not an action) | `TessInbox.swift:25-32` | waiting phrase title `:32` | already checks all four `:29-30` | Claude offline retry | P P P P | walled |
| 26 | On-device model and Claude tools | router `TessModel.swift:75-79` lets the model read money and body; `TessModelCapture.swift:151-156` runs `TessTools.run` (`TessTools.swift:48-75`) | whatever rows 1, 7, 9, 10, 14, 15 write | inherits perform; `TessTools.run`'s rollback must keep the note | Ask bar, Tell Tess | F F F F at the engine (the router keeps secrets and keys off this route, `TessModel.swift:69`, `:74`) | not walled |
| 27 | Siri Add a Task | `Intents.swift:136-145` | through rows 1 and 7 | inherits perform; drop its own `hasValue` branch `:140-142` once the wall holds | Siri, Shortcuts | P F F P | partial |
| 28 | Siri Tell Tess | `Intents.swift:161-164` via the router | through the grammar and rows 1, 7, 9 | inherits perform; misses need the grammar (section 4, item 2) | Siri, Shortcuts | P F F P | partial |

**Count: 28 rows (23 engine actions, 2 writers outside the engine, 3 caller paths). 3 walled, 6 partial, 19 not
walled. Cells, with the money-with-no-day column: 27 of 140 hold on master.**

Left out, with the reason: `LogSet` `kind`, `source`, `unit` (enums); `WriteSettings` (look names and the folder's
display name, never typed; `TesseraSettings.swift:14-19` guards the name); `StartCooking` (`Cooking.swift:105`) and
`StartProcess`'s process title (`ProcessActions.swift:44`) copy a stored title, walled when it was made. No action
writes a workout or routine note on master: `Thing.notes` (`SystemCatalog.swift:57`) is written only by the exercise
library seed (`ExerciseLibraryInstaller.swift:88`); a future "set notes" action joins row 7's form. Plan my day
(`PlanWording.swift`), the link reader (`RecipeLinkReader.swift`) and the miss log (`CaptureMissLog.swift`) write no
objects; the miss log is 0ah's line at `TessCaptureEngine.swift:58`.

## 3. Phrases and the outcome after the wall

Now is Thu Oct 15, 2026, 6:00 pm Pacific, so "fri" and "tomorrow" are Fri Oct 16. Every key cell: refused, nothing
kept, no private note. "PN" is a private note titled "Private note" holding the words; "PN Fri" is dated Fri.

| # | Secret | Money with a day | Body | After the wall |
|---|---|---|---|---|
| 1 | "door code 4417" | title "Paid rent 2100", `startsAt` Fri | "knee hurts" | PN, PN Fri, PN; no task |
| 2 | "door code 4417" on task "Call mom" | "paid rent 2100 fri" | "took 2 advil" | PN each; the task keeps "Call mom" |
| 3 | "door code 4417" | "venmo sam 250 fri" | "knee hurts" | PN each; no routine, nothing in the Siri picker |
| 4 | "gate code 4417" | "paid rent 2100 fri" | "slept 5 hours" | PN each; no plan |
| 5, 6 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | refused by `ProgressionRule`; no PN (structured) |
| 7 | "wifi password is hunter2" | "paid rent 2100", `on` Fri | "knee hurts" | the note is private; money one dated Fri |
| 8 | "wifi password is tacocat" into "buy oat milk" | "paid rent 2100 fri" | "knee hurts" | the edited note turns private, title "Private note" |
| 9 | `["wifi password is hunter2"]` | `["rent 2100 fri"]` | `["took 2 advil"]` | PN each; no ingredient, no grocery row, no receipt naming it. `["eggs", "door code 4417"]`: eggs added, one PN |
| 10 | title "pw tacocat24" | title "paid rent 2100 fri" | title "knee hurts" | recipe saved as "Red lentil soup" (the parsed title), PN |
| 11 | "pw tacocat24" | "paid rent 2100 fri" | "slept 5 hours" | PN; title stays "Red lentil soup" |
| 12 | "safe code 4417" | "venmo sam 250 fri" | "took 2 advil" | 10 min timer titled "Timer", PN |
| 13 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | the cook finishes, its note is empty, PN |
| 14 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | PN; no list |
| 15 | "wifi password is hunter2" | "rent 2100 fri" | "took 2 advil" | PN; no item on Packing |
| 16, 17 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | PN; section and aisle unchanged |
| 18 to 21 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | the process runs, `nextStep` empty, PN |
| 22 | "door code 4417" | "venmo sam 250 fri" | "knee hurts" | PN; the task is not waiting |
| 23 | "door code 4417" | "coffee 6.25 sat" | "took 2 advil" | secret and money refused, nothing kept; body kept as a private memory line. Today "coffee 6.25 sat" and "took 2 advil" are kept as plain lines |
| 24 | "Thu: done door code 4417." | "Thu: done coffee 6.25 sat." | "Thu: done took 2 advil." | no memory line. Today the last two are kept |
| 25 | "door code 4417" | "paid rent 2100 fri" | "knee hurts" | not queued (holds today) |
| 26 | `createTask` title "door code 4417" | title "Paid rent 2100", `startsAt` Fri | "knee hurts" | PN, PN Fri, PN; the tool returns "Done" with the note, not an error |
| 27 | "door code 4417?" | "Paid rent 2100", When Fri | "knee hurts" | "Private note, kept." each, PN Fri for money; key: the key line |
| 28 | "door code 4417" | "paid rent 2100 fri" | "knee hurts tomorrow" | line starts "Private note"; PN Fri for money and body. Today money is "Didn't catch that." plus a miss-log line, body is a task "Knee hurts" |

**Future money and medicine, task-making rows 1, 26, 27, 28** (2:22 pm): "Pay rent 2100" with a Friday time (Tell
Tess: "pay rent 2100 fri") makes task "Pay rent" on Friday, receipt "Pay rent, Friday.", no private note and no
"2100" anywhere, Siri's line included. "take 2 advil" at 9 pm (Tell Tess: "take 2 advil at 9pm") makes a task titled
"Private task" at 9 pm, with "advil" in no title, line or receipt. On master every caller writes a task "Pay rent
2100" (Tell Tess: a miss, `TessGrammar.swift:117-120`, because it starts with "pay") and a task "Take 2 advil".

**Money with no day, every row** (2:16 pm): rows with a typed field take "bought a tv for 800"; rows 1, 7, 9, 26, 27
and 28 take "paid 45.20 gas" (row 9 as `["paid 45.20 gas"]`, row 1 as a title with no `startsAt`). After the wall: a
private note dated now, no task, no amount in any task title, no grocery row, list item or routine. Rows 5 and 6 are
refused by `ProgressionRule` as before; row 23 refuses it ("bought" is missing from memory's money words today,
`TessMemory.swift:109-110`, so "bought a tv for 800" is kept as a plain line on master); row 24 takes "Thu: done bought a tv for 800." and keeps it today (no "bought" in memory's money words); row 25
keeps nothing.
On master row 28 is "Didn't catch that." plus a miss-log line, as for money with a day; Siri Add a Task (row 27)
saves a task "paid 45.20 gas".

Controls (must still write as typed): "buy milk", "reset my PIN", "Book physio", "pay rent" on Fri, "Push day",
`["eggs", "2 lemons"]`, "Packing", "charger", "pasta", "Arjun's reply", "bought 2 lemons" on Sat as a **plain** note
(1:15 pm, and 2:22 pm's money test). On master `isMoneyShaped` walls it ("bought" with any number,
`PrivateFacts.swift:30`), so Core narrows it to the 2:22 pm test before the wall leans on it.

## 4. Where one wall can't do it alone

1. **Days.** The weekday words live above Core (`TessGrammar.swift:568`, `TessDates.pastDay` in TesseraTess), so the
   wall can date a note only from an action's own date field (rows 1, 7, 26, 27). "paid rent 2100 fri" typed into
   Groceries, a list or a routine name becomes a private note dated now, with "fri" left in its body. Either accept
   that or move the day reader into Core.
2. **Misses never reach the engine.** "paid rent 2100 fri" is dropped by the grammar's money guard
   (`TessGrammar.swift:117-120`, `TessGrammar+Kitchen.swift:81-86`): the Ask bar and Tell Tess say "Didn't catch that."
   and the miss log keeps it (`TessCaptureEngine.swift:58`). To be "a private dated note everywhere", the grammar must
   emit `.note(on:)` for a past-tense money phrase (beside `parsePastLog`, `:322-331`); the wall then makes it private. Likewise "pay rent 2100 fri" is a miss today; the grammar must
   hand `CreateTask` a title and a Friday time so rule 3a can drop the amount.
3. **Writers outside the engine** (rows 24, 25 and the miss log) use `store.create` or a file, so `perform` never sees
   them. They call the shared check by hand. Row 24's in-place rewrite (`TessMemory.swift:661`) needs it too.
4. **Callers that assume the action ran.** A reroute changes what comes back, so three spots must read the outcome
   instead of their own input: `TessCaptureEngine.swift:296` says "\(title), in Later." from its parse;
   `Intents.swift:144` reads `CreateTask`'s summary; `TessTools.run` (`TessTools.swift:63-74`) undoes every record since
   its mark on any error, so a wall that answers by throwing after writing the note would have the note undone. One
   shape that works: `perform` throws `EngineWall.Kept(record)` and those three treat it as success with "Private note,
   kept." (`AppModel.capture`, `AppModel.swift:184-195`, shows the ghost from the returned record and needs the same).
5. **Rulings that pulled the other way: resolved.** (a) Future money with a day: **resolved 2:22 pm**, a task with
   the amount dropped ("Pay rent", Friday); past tense stays a private dated note (1:15 pm). (b) Medicine reminder:
   **resolved 2:22 pm**, a private task titled "Private task" (replaces 12:30 pm's "Medicine"). (c) "bought 2 lemons
   sat": **resolved 2:22 pm**, the money test in rule 3 is the rule; Core narrows `isMoneyShaped`
   (`PrivateFacts.swift:30` walls "bought" with any number today). (d) Recipe text keeps prices (11:52 am), so row 10
   walls the title only. (e) `RememberFact` keeps body facts as private memory (1:13 pm), not as notes.
6. **Private notes can be renamed.** `RenameObject` (`TrainingActions.swift:506-508`) retitles any object, so "Private
   note" can become "gate 4417". The wall refuses a title change on any `isPrivate` object, whatever the new text.
7. **Two key checks.** Memory's screen matches the key prefix case-sensitively (`TessMemory.swift:139`), so an
   upper-case key passes it; one shared check (`looksLikeClaudeKey`) closes that.
8. **Correction to AX.** The sweep's "Done: Rent 2100 becomes a memory line" doesn't happen: memory's money words hold
   "rent" (`TessMemory.swift:109-110`), so `write` returns nil at `:648`. The real memory leaks are shapes the memory
   screen lacks: "coffee 6.25" and "took 2 advil" (row 24).
9. **Rows written before the wall stay as they are** (as N15). The wall guards writes, not old rows.

## 5. Tests Core can paste

One file, `TesseraCore/Tests/TesseraCoreTests/EngineWallTests.swift`. One parameterized `@Test` per row (29 with row
23's two), plus three single tests and two task-caller tests for 2:22 pm: 34 tests, 152 cases (each row's argument list carries the money-with-no-day probe,
`.spend`, from Product's 2:16 pm addition). They compile on master. The row's master status is in each
doc comment; every case not marked "holds" fails until the wall lands. Key cases take `fakeKey`, never a literal.

```swift
import Foundation
@testable import TesseraCore
@testable import TesseraIntents
@testable import TesseraTess
import Testing

/// What a probe is: one wall each, plus the key.
enum WallKind: String, Sendable {
    case secret, moneyWithDay, moneyNoDay, body, key
}

/// One phrase for one wall. `needle` is the part that must never land outside a private note. Key probes carry no
/// text: the test reads `EngineWallTests.fakeKey`.
struct WallProbe: Sendable, CustomTestStringConvertible {
    let kind: WallKind
    let phrase: String
    let needle: String

    var testDescription: String {
        kind == .key ? "key: fakeKey" : "\(kind.rawValue): \(phrase)"
    }

    var isDated: Bool {
        kind == .moneyWithDay
    }

    static func secret(_ phrase: String, _ needle: String) -> WallProbe {
        WallProbe(kind: .secret, phrase: phrase, needle: needle)
    }

    static func money(_ phrase: String, _ needle: String) -> WallProbe {
        WallProbe(kind: .moneyWithDay, phrase: phrase, needle: needle)
    }

    /// Money with an amount and no day (Product 2:16 pm): a private note, never a task.
    static func spend(_ phrase: String, _ needle: String) -> WallProbe {
        WallProbe(kind: .moneyNoDay, phrase: phrase, needle: needle)
    }

    static func body(_ phrase: String) -> WallProbe {
        WallProbe(kind: .body, phrase: phrase, needle: phrase)
    }

    static let key = WallProbe(kind: .key, phrase: "", needle: "")

    /// The common set for a one-line field.
    static let standard: [WallProbe] = [
        .secret("door code 4417", "4417"), .money("paid rent 2100 fri", "rent 2100"),
        .spend("bought a tv for 800", "tv for 800"), .body("knee hurts"), .key,
    ]
}

/// The four paths that make a task (rows 1, 26, 27, 28).
enum TaskCaller: String, Sendable, CaseIterable {
    case createTask, modelTools, siriAddTask, tellTess
}

/// docs/research/fixtures/engine-wall.md (Product 2:06 pm Oct 16): every engine action that writes his text passes
/// one check. A key is refused; a secret with a value, money with an amount and a body fact become a private note and
/// land nowhere else. Made-up phrases only.
@MainActor
struct EngineWallTests {
    static let la = TimeZone(identifier: "America/Los_Angeles")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = la
        return calendar
    }

    /// Thu Oct 15, 2026, 6:00 pm; "fri" and "tomorrow" are Fri Oct 16.
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 18))!
    static let friday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 12))!
    static let ninePM = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 21))!
    static let saturday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 12))!
    static let lentils = "Red lentil soup\nIngredients\n1 cup red lentils\n2 cups water\nMethod\nSimmer for 20 min."

    /// The package's own test key, so nothing key-shaped is spelled in this file.
    static var fakeKey: String {
        ClaudeKeyTests.key
    }

    let store = ObjectStore.open(inMemory: true)
    let classes: [SystemCatalog.Key: ClassDef]
    let engine: ActionEngine

    init() throws {
        classes = try store.prepareCatalog()
        engine = ActionEngine(store: store, classes: classes)
        engine.zone = { Self.la }
    }

    // MARK: Reading the outcome

    func text(_ probe: WallProbe) -> String {
        probe.kind == .key ? Self.fakeKey : probe.phrase
    }

    /// Titles, text values and op log lines outside anything private that hold `needle`.
    func leaks(_ needle: String) -> [String] {
        let objects = store.context.all(ObjectRecord.self)
            .filter { !$0.isDeleted && store.value("isPrivate", of: $0) != .bool(true) }
        let texts = objects.flatMap { [$0.title] + $0.values.values.compactMap(\.stringValue) }
        let log = engine.history(limit: 500).flatMap { [$0.summary, $0.receipt ?? ""] }
        return (texts + log).filter { $0.localizedCaseInsensitiveContains(needle) }
    }

    func privateNotes() -> [ObjectRecord] {
        store.objects(of: classes[.note]!).filter { !$0.isDeleted && store.value("isPrivate", of: $0) == .bool(true) }
    }

    func privateNote(holding needle: String) -> ObjectRecord? {
        privateNotes().first {
            store.value("body", of: $0)?.stringValue?.localizedCaseInsensitiveContains(needle) == true
        }
    }

    /// The wall's contract. Key: nothing kept and no private note (and, for an engine action, it throws). Otherwise: a
    /// private note titled "Private note" holds the words, dated `day` when given, and nothing else holds them.
    func expectWalled(_ probe: WallProbe, day: Date? = nil, keyThrows: Bool = true,
                      sourceLocation: SourceLocation = #_sourceLocation, _ run: (String) throws -> Void)
    {
        let notesBefore = privateNotes().count
        var threw = false
        do {
            try run(text(probe))
        } catch {
            // The wall may answer with a "kept" signal; the outcome is read below either way.
            threw = true
        }
        if probe.kind == .key {
            #expect(!keyThrows || threw, "\(probe)", sourceLocation: sourceLocation)
            #expect(privateNotes().count == notesBefore, sourceLocation: sourceLocation)
            #expect(leaks(String(Self.fakeKey.suffix(12))).isEmpty, sourceLocation: sourceLocation)
            return
        }
        let note = privateNote(holding: probe.needle)
        #expect(note?.title == SecretWords.title, "\(probe)", sourceLocation: sourceLocation)
        if probe.kind == .moneyNoDay {
            // 2:16 pm: never a task, and no amount in any task title.
            let titles = store.objects(of: classes[.task]!).filter { !$0.isDeleted }.map(\.title)
            #expect(!titles.contains { $0.contains(where: \.isNumber) }, "\(probe): \(titles)",
                    sourceLocation: sourceLocation)
        }
        if let day, let note {
            #expect(Self.calendar.isDate(note.createdAt, inSameDayAs: day), "\(probe)", sourceLocation: sourceLocation)
        }
        #expect(leaks(probe.needle).isEmpty, "\(probe): \(leaks(probe.needle))", sourceLocation: sourceLocation)
    }

    // MARK: Fixtures

    func task(_ title: String = "Call mom") throws -> ObjectRecord {
        try engine.perform(CreateTask(title: title), by: .user).output
    }

    func routine() throws -> ObjectRecord {
        try engine.perform(CreateRoutine(title: "Push day"), by: .user).output
    }

    func slot() throws -> ObjectRecord {
        try engine.perform(AddSlot(routine: routine().id, exercise: classes[.benchPress]!.id), by: .user).output
    }

    func recipe() throws -> ObjectRecord {
        try engine.perform(CreateRecipe(text: Self.lentils), by: .user).output
    }

    func cook() throws -> ObjectRecord {
        try engine.perform(StartCooking(recipe: recipe().id, time: Self.now), by: .user).output
    }

    func list() throws -> ObjectRecord {
        try engine.perform(CreateList(name: "Packing"), by: .user).output
    }

    func item() throws -> ObjectRecord {
        try engine.perform(AddListItem(list: list().id, text: "charger", section: "Bags"), by: .user).output
    }

    func process() throws -> ObjectRecord {
        try engine.perform(StartTask(task: task().id), by: .user).output
    }

    // MARK: 1 to 4: titles (master: none hold)

    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("Paid rent 2100", "rent 2100"),
                      .body("knee hurts"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_createTask_walledTitleBecomesPrivateNote(_ probe: WallProbe) {
        expectWalled(probe, day: probe.isDated ? Self.friday : nil) {
            try engine.perform(CreateTask(title: $0, startsAt: probe.isDated ? Self.friday : nil), by: .user)
        }
    }

    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("paid rent 2100 fri", "rent 2100"),
                      .body("took 2 advil"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_renameObject_walledTitleBecomesPrivateNote(_ probe: WallProbe) throws {
        let task = try task()
        expectWalled(probe) { try engine.perform(RenameObject(object: task.id, title: $0), by: .user) }
        #expect(task.title == "Call mom")
    }

    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("venmo sam 250 fri", "venmo sam 250"),
                      .body("knee hurts"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_createRoutine_walledTitleBecomesPrivateNote(_ probe: WallProbe) {
        expectWalled(probe) { try engine.perform(CreateRoutine(title: $0), by: .user) }
    }

    @Test(arguments: [WallProbe.secret("gate code 4417", "4417"), .money("paid rent 2100 fri", "rent 2100"),
                      .body("slept 5 hours"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_createPlan_walledTitleBecomesPrivateNote(_ probe: WallProbe) throws {
        let routine = try routine()
        expectWalled(probe) { try engine.perform(CreatePlan(title: $0, routines: [routine.id]), by: .user) }
    }

    // MARK: 5, 6: structured (master: all hold)

    @Test(arguments: WallProbe.standard)
    func engineWall_addSlot_progressionRefusedWithNoNote(_ probe: WallProbe) throws {
        let routine = try routine()
        let before = privateNotes().count
        #expect(throws: (any Error).self) {
            try engine.perform(AddSlot(routine: routine.id, exercise: classes[.benchPress]!.id,
                                       progression: text(probe)), by: .user)
        }
        #expect(privateNotes().count == before)
        #expect(leaks(probe.kind == .key ? String(Self.fakeKey.suffix(12)) : probe.needle).isEmpty)
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_editSlot_progressionRefusedWithNoNote(_ probe: WallProbe) throws {
        let slot = try slot()
        let before = privateNotes().count
        #expect(throws: (any Error).self) {
            try engine.perform(EditSlot(slot: slot.id, progression: text(probe)), by: .user)
        }
        #expect(privateNotes().count == before)
        #expect(leaks(probe.kind == .key ? String(Self.fakeKey.suffix(12)) : probe.needle).isEmpty)
    }

    // MARK: 7, 8: notes (master: secret and key hold)

    @Test(arguments: [WallProbe.secret("wifi password is hunter2", "hunter2"), .money("paid rent 2100", "rent 2100"),
                      .body("knee hurts"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_createNote_walledNoteIsPrivate(_ probe: WallProbe) {
        expectWalled(probe, day: probe.isDated ? Self.friday : nil) {
            try engine.perform(CreateNote(body: $0, on: probe.isDated ? Self.friday : nil), by: .user)
        }
    }

    @Test(arguments: [WallProbe.secret("wifi password is tacocat", "tacocat"),
                      .money("paid rent 2100 fri", "rent 2100"), .body("knee hurts"),
                      .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_editNote_walledEditMakesTheNotePrivate(_ probe: WallProbe) throws {
        let note = try engine.perform(CreateNote(body: "buy oat milk"), by: .user).output
        expectWalled(probe) { try engine.perform(EditNote(note: note.id, body: $0, title: $0), by: .user) }
    }

    // MARK: 9, 10, 11: kitchen (master: none hold)

    @Test(arguments: [WallProbe.secret("wifi password is hunter2", "hunter2"), .money("rent 2100 fri", "rent 2100"),
                      .body("took 2 advil"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_addGroceries_walledLineBecomesPrivateNote(_ probe: WallProbe) {
        expectWalled(probe) { try engine.perform(AddGroceries(lines: [$0]), by: .user) }
    }

    @Test(arguments: [WallProbe.secret("pw tacocat24", "tacocat24"), .money("paid rent 2100 fri", "rent 2100"),
                      .body("knee hurts"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_createRecipe_walledTitleIsDroppedAndKeptPrivate(_ probe: WallProbe) {
        expectWalled(probe) { try engine.perform(CreateRecipe(text: Self.lentils, title: $0), by: .user) }
        if probe.kind != .key {
            #expect(store.objects(of: classes[.recipe]!).contains { $0.title == "Red lentil soup" })
        }
    }

    @Test(arguments: [WallProbe.secret("pw tacocat24", "tacocat24"), .money("paid rent 2100 fri", "rent 2100"),
                      .body("slept 5 hours"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_editRecipe_walledTitleBecomesPrivateNote(_ probe: WallProbe) throws {
        let recipe = try recipe()
        expectWalled(probe) { try engine.perform(EditRecipe(recipe: recipe.id, title: $0), by: .user) }
        #expect(recipe.title == "Red lentil soup")
    }

    // MARK: 12, 13: cooking (master: none hold)

    @Test(arguments: [WallProbe.secret("safe code 4417", "4417"), .money("venmo sam 250 fri", "venmo sam 250"),
                      .body("took 2 advil"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_startKitchenTimer_walledLabelBecomesTimer(_ probe: WallProbe) {
        expectWalled(probe) {
            try engine.perform(StartKitchenTimer(label: $0, minutes: 10, time: Self.now), by: .user)
        }
        if probe.kind != .key {
            #expect(store.objects(of: classes[.kitchenTimer]!).map(\.title) == ["Timer"])
        }
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_finishCooking_walledNoteIsKeptPrivate(_ probe: WallProbe) throws {
        let cook = try cook()
        expectWalled(probe) { try engine.perform(FinishCooking(cook: cook.id, note: $0, time: Self.now), by: .user) }
        #expect(store.value("note", of: cook) == nil)
    }

    // MARK: 14 to 17: lists (master: none hold)

    @Test(arguments: WallProbe.standard)
    func engineWall_createList_walledNameBecomesPrivateNote(_ probe: WallProbe) {
        expectWalled(probe) { try engine.perform(CreateList(name: $0), by: .user) }
    }

    @Test(arguments: [WallProbe.secret("wifi password is hunter2", "hunter2"), .money("rent 2100 fri", "rent 2100"),
                      .body("took 2 advil"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_addListItem_walledItemBecomesPrivateNote(_ probe: WallProbe) throws {
        let list = try list()
        expectWalled(probe) { try engine.perform(AddListItem(list: list.id, text: $0), by: .user) }
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_moveListItem_walledSectionBecomesPrivateNote(_ probe: WallProbe) throws {
        let item = try item()
        expectWalled(probe) { try engine.perform(MoveListItem(item: item.id, section: $0), by: .user) }
        #expect(store.value("section", of: item)?.stringValue == "Bags")
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_renameListSection_walledNameBecomesPrivateNote(_ probe: WallProbe) throws {
        let item = try item()
        let list = try #require(item.parent)
        expectWalled(probe) {
            try engine.perform(RenameListSection(list: list.id, from: "Bags", to: $0), by: .user)
        }
        #expect(store.value("section", of: item)?.stringValue == "Bags")
    }

    // MARK: 18 to 22: processes (master: none hold)

    @Test(arguments: WallProbe.standard)
    func engineWall_startProcess_walledNextStepIsKeptPrivate(_ probe: WallProbe) throws {
        let task = try task()
        expectWalled(probe) { try engine.perform(StartProcess(subject: task.id, nextStep: $0), by: .user) }
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_saveContext_walledNextStepIsKeptPrivate(_ probe: WallProbe) throws {
        let process = try process()
        expectWalled(probe) { try engine.perform(SaveContext(process: process.id, nextStep: $0), by: .user) }
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_suspendProcess_walledNextStepIsKeptPrivate(_ probe: WallProbe) throws {
        let process = try process()
        expectWalled(probe) { try engine.perform(SuspendProcess(process: process.id, nextStep: $0), by: .user) }
    }

    @Test(arguments: WallProbe.standard)
    func engineWall_startTask_walledNextStepIsKeptPrivate(_ probe: WallProbe) throws {
        let task = try task()
        expectWalled(probe) { try engine.perform(StartTask(task: task.id, nextStep: $0), by: .user) }
    }

    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("venmo sam 250 fri", "venmo sam 250"),
                      .body("knee hurts"), .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_waitOnTask_walledWhoBecomesPrivateNote(_ probe: WallProbe) throws {
        let task = try task()
        expectWalled(probe) {
            try engine.perform(WaitOnTask(task: task.id, waitingOn: $0, checkAt: Self.friday), by: .user)
        }
    }

    // MARK: 23, 24, 25: memory and the inbox

    /// Master: secret and key hold; "coffee 6.25 sat" and "bought a tv for 800" are kept today.
    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("coffee 6.25 sat", "6.25"),
                      .spend("bought a tv for 800", "tv for 800"), .key])
    func engineWall_rememberFact_secretAndMoneyRefused(_ probe: WallProbe) {
        #expect(throws: (any Error).self, "\(probe)") {
            try engine.perform(RememberFact(text: text(probe)), by: .tess)
        }
        #expect(leaks(probe.kind == .key ? String(Self.fakeKey.suffix(12)) : probe.needle).isEmpty)
    }

    /// Master: "knee hurts" holds; "took 2 advil" is kept as a plain line today.
    @Test(arguments: [WallProbe.body("knee hurts"), .body("took 2 advil")])
    func engineWall_rememberFact_bodyFactIsAPrivateLine(_ probe: WallProbe) throws {
        try engine.perform(RememberFact(text: probe.phrase), by: .tess)
        #expect(leaks(probe.needle).isEmpty, "\(probe): \(leaks(probe.needle))")
    }

    /// Master: secret and key hold; the money and body lines are kept today.
    @Test(arguments: [WallProbe.secret("Thu: done door code 4417.", "4417"),
                      .money("Thu: done coffee 6.25 sat.", "6.25"), .body("Thu: done took 2 advil."),
                      .spend("Thu: done bought a tv for 800.", "tv for 800"), .key])
    func engineWall_memoryTurnover_walledDayLineNeverKept(_ probe: WallProbe) {
        let memory = TessMemoryStore(engine: engine, calendar: Self.calendar, forgetLogURL: nil)
        let line = probe.kind == .key ? "Thu: done \(Self.fakeKey)." : probe.phrase
        #expect(memory.write(kind: .recent, area: .days, text: line, evidence: [], day: Self.now) == nil, "\(probe)")
    }

    /// Master: all hold.
    @Test(arguments: WallProbe.standard)
    func engineWall_inbox_walledPhraseNeverQueued(_ probe: WallProbe) {
        #expect(TessInbox(store: store, classes: classes).add(text(probe), at: Self.now) == nil, "\(probe)")
    }

    // MARK: 26, 27, 28: callers

    /// The on-device model and Claude both write through TessTools.run. Master: none hold.
    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("Paid rent 2100", "rent 2100"),
                      .body("knee hurts"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_modelTools_walledTitleBecomesPrivateNote(_ probe: WallProbe) {
        expectWalled(probe, day: probe.isDated ? Self.friday : nil) { title in
            var arguments: [String: Any] = ["title": title]
            if probe.isDated {
                arguments["startsAt"] = "2026-10-16T12:00:00"
            }
            _ = try TessTools.run("createTask", arguments: JSONSerialization.data(withJSONObject: arguments),
                                  engine: engine, pending: false, now: Self.now, calendar: Self.calendar)
        }
    }

    /// Master: secret and key hold.
    @Test(arguments: [WallProbe.secret("door code 4417?", "4417"), .money("Paid rent 2100", "rent 2100"),
                      .body("knee hurts"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_siriAddTask_walledTitleBecomesPrivateNote(_ probe: WallProbe) {
        var line = ""
        expectWalled(probe, day: probe.isDated ? Self.friday : nil, keyThrows: false) {
            line = try CreateTaskIntent.add($0, startsAt: probe.isDated ? Self.friday : nil, engine: engine)
        }
        #expect(line == (probe.kind == .key ? TessRouter.keyLine : "\(SecretWords.title), kept."), "\(probe)")
    }

    /// Master: secret and key hold; money is a miss today, body a task "Knee hurts".
    @Test(arguments: [WallProbe.secret("door code 4417", "4417"), .money("paid rent 2100 fri", "rent 2100"),
                      .body("knee hurts tomorrow"), .spend("paid 45.20 gas", "45.20"), .key])
    func engineWall_tellTess_walledPhraseBecomesPrivateNote(_ probe: WallProbe) async {
        let tess = TessCaptureEngine(engine: engine)
        let context = TessContext(now: Self.now, calendar: Self.calendar, commitImmediately: true)
        let capture = await tess.capture(text(probe), context: context)
        let needle = probe.kind == .key ? String(Self.fakeKey.suffix(12)) : probe.needle
        #expect(leaks(needle).isEmpty, "\(probe): \(leaks(needle))")
        if probe.kind == .key {
            #expect(capture.line == TessRouter.keyLine)
        } else {
            #expect(capture.line.hasPrefix(SecretWords.title), "\(probe): \(capture.line)")
            let note = privateNote(holding: probe.kind == .body ? "knee hurts" : needle)
            #expect(note != nil, "\(probe)")
            if probe.kind == .moneyWithDay || probe.kind == .body, let note {
                #expect(Self.calendar.isDate(note.createdAt, inSameDayAs: Self.friday), "\(probe)")
            }
        }
    }

    // MARK: 2:22 pm: future money stays a task, a medicine reminder is a private task

    /// Makes a task through one caller; returns what he is told.
    func addTask(_ caller: TaskCaller, title: String, at date: Date, iso: String,
                 phrase: String) async throws -> String
    {
        switch caller {
        case .createTask:
            return try engine.perform(CreateTask(title: title, startsAt: date), by: .user).record.receipt ?? ""
        case .modelTools:
            let arguments: [String: Any] = ["title": title, "startsAt": iso]
            let records = try TessTools.run("createTask", arguments: JSONSerialization.data(withJSONObject: arguments),
                                            engine: engine, pending: false, now: Self.now, calendar: Self.calendar)
            return records.last?.receipt ?? ""
        case .siriAddTask:
            return try CreateTaskIntent.add(title, startsAt: date, engine: engine)
        case .tellTess:
            let context = TessContext(now: Self.now, calendar: Self.calendar, commitImmediately: true)
            return await TessCaptureEngine(engine: engine).capture(phrase, context: context).line
        }
    }

    func liveTasks() -> [ObjectRecord] {
        store.objects(of: classes[.task]!).filter { !$0.isDeleted }
    }

    func startDay(of task: ObjectRecord) -> Date? {
        if case let .date(date)? = store.value("startsAt", of: task) {
            return date
        }
        return nil
    }

    /// Master: none hold (a task "Pay rent 2100"; Tell Tess misses).
    @Test(arguments: TaskCaller.allCases)
    func engineWall_futureMoney_staysTaskWithoutAmount(_ caller: TaskCaller) async throws {
        let line = try await addTask(caller, title: "Pay rent 2100", at: Self.friday, iso: "2026-10-16T12:00:00",
                                     phrase: "pay rent 2100 fri")
        let tasks = liveTasks()
        #expect(tasks.map(\.title) == ["Pay rent"], "\(caller)")
        if let task = tasks.first, let day = startDay(of: task) {
            #expect(Self.calendar.isDate(day, inSameDayAs: Self.friday), "\(caller)")
        }
        #expect(engine.history(limit: 5).contains { $0.receipt == "Pay rent, Friday." }, "\(caller)")
        #expect(privateNotes().isEmpty, "\(caller)")
        #expect(!line.contains("2100"), "\(caller): \(line)")
        #expect(leaks("2100").isEmpty, "\(caller): \(leaks("2100"))")
    }

    /// Master: none hold (a task "Take 2 advil").
    @Test(arguments: TaskCaller.allCases)
    func engineWall_medicineReminder_isAPrivateTask(_ caller: TaskCaller) async throws {
        let line = try await addTask(caller, title: "take 2 advil", at: Self.ninePM, iso: "2026-10-15T21:00:00",
                                     phrase: "take 2 advil at 9pm")
        let tasks = liveTasks()
        #expect(tasks.map(\.title) == ["Private task"], "\(caller)")
        if let task = tasks.first, let time = startDay(of: task) {
            #expect(time == Self.ninePM, "\(caller)")
        }
        #expect(privateNote(holding: "advil") != nil, "\(caller)")
        #expect(!line.localizedCaseInsensitiveContains("advil"), "\(caller): \(line)")
        #expect(leaks("advil").isEmpty, "\(caller): \(leaks("advil"))")
    }

    // MARK: Single tests

    /// Section 4 item 6. Master: fails (the note is retitled).
    @Test func engineWall_renameObject_privateNoteKeepsItsTitle() throws {
        let note = try engine.perform(CreateNote(body: "door code 4417"), by: .user).output
        _ = try? engine.perform(RenameObject(object: note.id, title: "gate 4417"), by: .user)
        #expect(note.title == SecretWords.title)
        #expect(leaks("4417").isEmpty)
    }

    /// Row 9, mixed line. Master: fails (both are added).
    @Test func engineWall_addGroceries_cleanLinesStayWalledLineGoesPrivate() throws {
        _ = try? engine.perform(AddGroceries(lines: ["eggs", "door code 4417"]), by: .user)
        let items = Groceries(store: store, classes: classes).list.map(\.orderedChildren) ?? []
        #expect(items.map(\.title) == ["eggs"])
        #expect(privateNote(holding: "4417")?.title == SecretWords.title)
        #expect(leaks("4417").isEmpty)
    }

    /// The wall must not over-wall. Master: all hold today; the last one fails under a wall built on
    /// PrivateFacts.isWalled until isMoneyShaped takes 2:22 pm's money test ("bought" with a count is not money).
    @Test func engineWall_controls_plainTextStillWrites() throws {
        for title in ["buy milk", "reset my PIN", "Book physio"] {
            #expect(try engine.perform(CreateTask(title: title), by: .user).output.title == title)
        }
        #expect(try engine.perform(CreateTask(title: "pay rent", startsAt: Self.friday), by: .user).output.title
            == "pay rent")
        #expect(try engine.perform(CreateRoutine(title: "Push day"), by: .user).output.title == "Push day")
        #expect(try engine.perform(AddGroceries(lines: ["eggs", "2 lemons"]), by: .user).output.count == 2)
        let list = try engine.perform(CreateList(name: "Packing"), by: .user).output
        #expect(try engine.perform(AddListItem(list: list.id, text: "charger"), by: .user).output.title == "charger")
        let timer = try engine.perform(StartKitchenTimer(label: "pasta", minutes: 10, time: Self.now), by: .user)
        #expect(timer.output.title == "pasta")
        let task = try engine.perform(CreateTask(title: "Call mom"), by: .user).output
        try engine.perform(WaitOnTask(task: task.id, waitingOn: "Arjun's reply", checkAt: Self.friday), by: .user)
        #expect(privateNotes().isEmpty)
        let lemons = try engine.perform(CreateNote(body: "bought 2 lemons", on: Self.saturday), by: .user).output
        #expect(store.value("isPrivate", of: lemons) != .bool(true))
    }
}
```

Notes for Core on the code:

- `Groceries(store:classes:).list` in the mixed test stands for "the groceries list object"; use whatever reader
  `GroceriesTests` uses if the name differs (`Groceries.listID` is the fixed id, `Groceries.swift:218`).
- `TessMemoryStore.write` and `TessInbox.add` are internal, so the file needs `@testable` on TesseraCore and
  TesseraTess, as above.
- `expectWalled` reads outcomes, not the error type, so the tests hold for either answer shape in section 4 item 4.
