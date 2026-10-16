# Undo collision fixtures (Product item AM, for F1)

Traced by hand on `origin/master` at `6f73f5f` (Merge #511). No build or Simulator run; line numbers are master's.
For: Builder B (owns F1), Core (owns the shared `UndoWindow`, F2), Builder A (live workout), QA, Product.
Reads with: `docs/research/next-build-v10.md` F1 and F2, `docs/research/undo-windows-audit.md` (X13 race).

## The rulings these cases check

- **R1. An UNDO takes back only the thing its line names** (`docs/product/decisions.md:518`, "One rule for undo").
- **R2. One UNDO on screen, owned by the most recent line.** A newer line closes the older line's window; the older
  thing is no longer one tap away (proposed here, see the end; it follows R1, because only one line shows by the soul).
- **R3. Windows** (`decisions.md:358` AQ15 and `:161-176`): a new capture 4 s; a change or removal 10 s; recipe to
  Groceries 10 s; a capture's 4 s counts from when its line shows; with VoiceOver on, every window is 10 s; windows
  pause while the app is in the background or the phone is locked; Siri's undo has no window.
- **R4. The answer to an UNDO names the thing**: "Milk, taken back.", "Call Mum, taken back.",
  "Private note, taken back." (`decisions.md:171`). A private note's line and its answer never show the value.

## How the collision happens on master (root cause)

There are two undo owners behind one UNDO word by the soul, and the line and the key read them in opposite order.

1. **The line prefers the capture.** `BottomChrome.line` is `reply ?? voice.note?.text ?? model.launchNote`
   (`Features/Command/BottomChrome.swift:147-149`). `reply` is the capture's line, set by `say(_:)` for 4 s
   (`BottomChrome.swift:713-724`, called from `commit` at `:527`).
2. **The key prefers Home.** `canUndo` returns `voice.note.undo != nil` whenever a Home note exists
   (`BottomChrome.swift:728-733`), and `undo()` reverts `voice.note.undo` first, falling back to
   `model.undoLastCapture()` only when there is no Home note (`BottomChrome.swift:736-745`).
3. **Home's note outlives the capture's line.** `TessVoice.say` keeps a note with an op for 10 s
   (`Features/Home/HomeQueue.swift:29-39`, the 10 at `:34`); the done is said at `HomeQueue.swift:459`, the move at
   `:480`, Now's done at `Features/Home/NowPage.swift:242`, the basket clear at `GroceriesView.swift:260`.
4. **The capture's own undo state is separate and offset.** `AppModel.lastCapture` is set only when the ghost dries,
   2 s after the line (`App/AppModel.swift:252-257`, `:265-288`), and lives 4 s from then (`AppModel.swift:281-287`).
   So the capture's line shows from +2 s to +6 s after Return, and its UNDO from +4 s to +8 s
   (Return dries 2 s first, `BottomChrome.swift:481-484`).

So for any capture made while a Home note with an op is alive, the screen reads the capture's line and UNDO reverts
the Home task. The comment at `BottomChrome.swift:726-727` ("UNDO only ever sits under the line whose record it
reverts") is the intent; the code does not hold it, because `line` and `canUndo` are computed separately from two
sources with no shared owner. A second, smaller form of the same bug sits inside the capture path: a second capture's
line shows while `lastCapture` still points at the first (UC1). A third sits in live mode: the set's UNDO has no
window and reappears under any new line, including a capture's (UC13).

**Every undo owner on master** (each keeps its own state and timer; none knows about the others):

| Owner | State | Window | Where |
|---|---|---|---|
| Ask Tess capture | `AppModel.lastCapture`, `lastCaptures` | 4 s from the ghost drying | `AppModel.swift:174-176`, `:281-287`, `:304-315` |
| Home, Now, basket, overnight wrap-up | `TessVoice.note.undo` | 10 s with an op, 4 s without | `HomeQueue.swift:13-44`; `BottomChrome.swift:135-141` |
| BottomChrome's UNDO key and spoken "undo" | reads both of the above | n/a | `BottomChrome.swift:205-208`, `:631-638`, `:728-745` |
| Groceries' own note line | `TessVoice.note.undo` | as above | `GroceriesView.swift:625-649` |
| Recipe to Groceries | `RecipePage.sent` | 4 s | `Features/Recipes/RecipePage.swift:184-199`, `:202-229` |
| Backup "Stop using it" | `BackupView.forgotten` | 10 s | `Features/Backup/BackupView.swift:113-116`, `:285-304` |
| Live set and edit | `WorkoutSession.undoable`, `lastEdit` | none; the key leaves with the line (4 s) | `WorkoutSession.swift:447-450`; `WorkoutSession+Edit.swift:85-104`; `LiveTessCorner.swift:39-46`, `:68-75` |
| LOG AND FINISH | `canTakeBackFinish(at:)` | 10 s | `WorkoutModeView.swift:106-126` |
| Routines, routine editor, recipe paste, Claude key, Siri | their own | see the audit X6, X7, X10, X19, X15 | `undo-windows-audit.md` |

## Timing used below

All times are seconds from the first action, with Reduce Motion off.

- Typed capture: Return at t, ghost dries in the Write line until t+2 (`BottomChrome.swift:482`), line shows t+2 to
  t+6 (`:720`), ghost row dries into a real row at t+4 (`AppModel.swift:181`, `:253`), capture UNDO t+4 to t+8
  (`AppModel.swift:282`).
- Spoken capture: the voice ghost dries 3 s (`BottomChrome.swift:651`), then the same as typed from the commit.
- Home swipe done: the op lands 1.32 s after release (`HomeQueue.swift:444` 0.42 s, `:454` 0.9 s, `:455`), then
  "Call Mum, done." with a 10 s UNDO.
- Home move: the op lands 0.2 s after release (`HomeQueue.swift:474`), then "Moved to tomorrow." with 10 s.
- Lines on master for the phrases used: "buy milk" says "Milk, on the list." and "buy eggs" says "Eggs, on the list."
  (`TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:337`); "gate code is 4417" says "Private note, kept."
  (`TessCaptureEngine.swift:300`).

Status words: **pass** (master meets the ruling), **wrong** (master shows or does something the ruling forbids),
**miss** (the ruling wants something master never shows), **not built**.

## Cases

### UC1. Two quick captures

- **Actions.** t=0 types "buy milk", Return. t=3 types "buy eggs", Return. t=6 taps UNDO.
- **Ruled.** t=2 "Milk, on the list." with UNDO for milk, window 2 to 6. t=5 "Eggs, on the list." replaces it and
  owns the only UNDO, window 5 to 9; milk's window closes at 5. The t=6 tap takes back eggs only and says
  "Eggs, taken back." Milk stays on the list.
- **Master.** Milk commits at t=4 and `lastCapture` = milk until t=8 (`AppModel.swift:276`, `:282`). Eggs' line shows
  at t=5 (`BottomChrome.swift:527`) but eggs stays pending until t=7, so `lastCapture` is still milk. The t=6 tap runs
  `undoLastCapture()` (`BottomChrome.swift:743`, `AppModel.swift:304-315`): milk is taken back under the line
  "Eggs, on the list.", and eggs stays. No answer line, no haptic (the `else` branch never bumps `undos`).
  Variant: Return at t=1 instead commits milk early inside `ask` (`AppModel.swift:214`), same result.
- **Status: wrong.**

### UC2. Capture, then a Home done

- **Actions.** t=0 types "buy milk", Return. t=2.68 releases a swipe-done on "Call Mum" in Home's queue (op lands
  t=4). t=5 taps UNDO.
- **Ruled.** t=2 milk's line and UNDO. t=4 "Call Mum, done." becomes the line and owns the UNDO (10 s, to t=14);
  milk's window closes. The t=5 tap takes back Call Mum and says "Call Mum, taken back."
- **Master.** t=4 `voice.note` = "Call Mum, done." with its op (`HomeQueue.swift:459`), but the line still reads
  "Milk, on the list." until t=6 because `reply` wins (`BottomChrome.swift:148`). The t=5 tap reverts Call Mum
  (`BottomChrome.swift:737-741`) under milk's line. Milk can never be taken back: its `lastCapture` (t=4 to t=8) is
  hidden behind the Home note and expires unseen.
- **Status: wrong** (the right thing is taken back under the wrong line).

### UC3. Home done, then a capture (the F1 headline)

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=3 types "buy milk", Return. t=6 taps
  UNDO.
- **Ruled.** t=1.32 "Call Mum, done." with UNDO. t=5 "Milk, on the list." takes the line and the UNDO (window 5 to 9);
  Call Mum's window closes at 5. The t=6 tap takes back milk and says "Milk, taken back." Call Mum stays done.
- **Master.** The line reads "Milk, on the list." from t=5 (`BottomChrome.swift:148`), while `canUndo` is true from
  the Home note (`:729-731`, alive to t=11.32 per `HomeQueue.swift:34`). The t=6 tap reverts Call Mum to not done
  (`:737-741`); milk stays. At t=7 milk commits and a second UNDO appears under the same line, now for milk.
- **Status: wrong.**

### UC4. Capture, then a move

- **Actions.** t=0 types "buy milk", Return. t=3 releases a swipe-left on "Call Mum" (op lands t=3.2). t=4 taps UNDO.
- **Ruled.** t=3.2 "Call Mum, tomorrow." (thing first) owns the line and the UNDO for 10 s. The t=4 tap moves Call Mum
  back and says "Call Mum, taken back."
- **Master.** The move says "Moved to tomorrow." (`HomeQueue.swift:480`, thing last), hidden behind milk's line until
  t=6. The t=4 tap moves Call Mum back under "Milk, on the list."
- **Status: wrong.**

### UC5. Recipe sent to Groceries, then a capture

- **Actions.** On the Tacos recipe page: t=0 swipes the column left (sends 10 items). t=1 opens Tess, types
  "buy milk", Return. t=4 taps the recipe page's UNDO. Second run: same, but t=5 taps the soul's UNDO.
- **Ruled.** t=0 "Tacos, 10 added." with UNDO, 10 s (`decisions.md:165`). t=3 "Milk, on the list." is the newer
  line; the recipe's UNDO goes and milk's is the only one (window 3 to 7). A t=4 tap on the old spot does nothing; a
  t=5 tap on milk's UNDO says "Milk, taken back."
- **Master.** The recipe page keeps its own line "10 to buy, in Groceries" and UNDO for 4 s
  (`RecipePage.swift:186-198`, `:212-229`) while BottomChrome draws milk's line over the same page
  (`App/RootView.swift:37`). From t=3 to t=4 two lines and two UNDO keys are on screen. Each takes back its own thing
  (the t=4 tap takes back the tacos send, the t=5 tap takes back milk), so nothing wrong is undone, but there are two
  keys, the window is 4 s not 10, the line is thing last, and the success haptic plays on the undo
  (`RecipePage.swift:142`, audit X9).
- **Status: wrong** (two UNDOs, window and line off rule; no cross-undo).

### UC6. A backup's 10 s window, with a capture inside it

- **Actions.** Review, Backups: t=0 taps "Stop using it". t=3 opens Tess, types "buy milk", Return. t=8 taps the
  backup page's UNDO. Second run: no capture, t=9 taps UNDO; third run: t=11 taps where UNDO was.
- **Ruled.** t=0 "iCloud folder, dropped." (F12 wording to come from Design) with UNDO 10 s. With the capture,
  t=5 milk's line owns the only UNDO; the backup's UNDO goes. Without it, t=9 brings the folder back and says
  "iCloud folder, taken back."; t=11 does nothing.
- **Master.** The backup UNDO lives 10 s on the page (`BackupView.swift:113-116`, `:290-294`) and acts on the
  bookmark, outside the op log. With the capture, from t=5 to t=10 milk's line and UNDO sit by the soul while the
  backup's UNDO sits on the page: two keys, each on its own thing. Without the capture, t=9 brings the folder back
  ("The folder is back.", `:303`) and t=11 finds no UNDO: pass on the window, but no VoiceOver stretch, no pause, and
  the line "Copies stay on this iPhone only now." does not name the thing (`:288`, F12).
- **Status: wrong** with the capture; **pass** on the 10 s window alone.

### UC7. Capture UNDO after its window

- **Actions.** t=0 types "buy milk", Return. t=7 taps where UNDO was.
- **Ruled.** Window 2 to 6 (counts from the line). At t=7 there is no UNDO; milk stays.
- **Master.** The line goes at t=6 (`BottomChrome.swift:720`) but `lastCapture` lives to t=8
  (`AppModel.swift:282`), and the resting row shows when `canUndo` alone is true (`BottomChrome.swift:153`). So from
  t=6 to t=8 an UNDO shows with no line, and the t=7 tap takes milk back. From t=2 to t=4 the line shows with no UNDO.
- **Status: wrong** (window is t+4 to t+8, not from the line; UNDO shown without its line).

### UC8. Home UNDO after its window

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=12 taps where UNDO was.
- **Ruled.** Window 1.32 to 11.32. Nothing at t=12; Call Mum stays done.
- **Master.** The note clears at t=11.32 (`HomeQueue.swift:34-37`); `canUndo` is false (`BottomChrome.swift:732`,
  no capture). Nothing happens.
- **Status: pass.**

### UC9. Home done, then the app goes to the background

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=3 swipes home (app to the background).
  t=30 opens the app. t=31 taps UNDO.
- **Ruled.** The window pauses at t=3 with 8.32 s left (`decisions.md:162`), so on return "Call Mum, done." and its
  UNDO stay until t=38.32. The t=31 tap says "Call Mum, taken back."
- **Master.** `TessVoice.say` sleeps with `Task.sleep` (`HomeQueue.swift:34`), which keeps counting while the app is
  away; on return the note is gone, so there is no UNDO at t=31. Foreground also runs `tidyProcesses`
  (`App/TesseraApp.swift:85-86`), and any overnight line it raises replaces the Home note outright
  (`BottomChrome.swift:135-141`).
- **Status: wrong.**

### UC10. A capture drying while the app goes to the background

- **Actions.** t=0 types "buy milk", Return. t=1 swipes home (the ghost is still drying). t=30 opens the app. t=31
  taps UNDO.
- **Ruled.** Drying and the window both pause. On return the ghost finishes drying, the line shows, and the 4 s
  window counts from it, so the t=31 tap (or one up to 4 s after the line) takes back milk: "Milk, taken back."
- **Master.** The 2 s dry, the 2 s ghost and the 4 s window are all `Task.sleep` timers (`BottomChrome.swift:482`,
  `AppModel.swift:253`, `:282`); none pauses. Whether the capture commits in the background or on return, and
  whether its line is seen at all, depends on when iOS suspends the app. Likely: line and UNDO already gone by t=30,
  milk saved with no way back on screen. Needs a Simulator run to confirm.
- **Status: wrong** (unconfirmed detail; no pause either way).

### UC11. VoiceOver on, one capture

- **Actions.** VoiceOver on. t=0 types "buy milk", Return. t=9 swipes to UNDO and double-taps.
- **Ruled.** Every window is 10 s with VoiceOver on (`decisions.md:170`, `:189`): the line and its UNDO show t=2 to
  t=12. The line is announced when it shows. The key reads "Undo, Milk" (proposed label). The t=9 double-tap says
  "Milk, taken back."
- **Master.** No code reads VoiceOver state and nothing posts an announcement (no `isVoiceOverRunning`,
  `accessibilityVoiceOverEnabled` or `AccessibilityNotification` anywhere on master). The line is gone at t=6, the
  UNDO at t=8, so t=9 finds nothing. BottomChrome's key has no label or hint (`BottomChrome.swift:205-208`), so it
  reads only "Undo".
- **Status: wrong** (window); **miss** (announcement, named key).

### UC12. VoiceOver on, Home done then a capture

- **Actions.** VoiceOver on. t=0 double-taps done on "Call Mum" on the Now page (op lands at once,
  `NowPage.swift:237`). t=4 dictates or types "buy milk", Return. t=8 double-taps UNDO.
- **Ruled.** t=6 milk's line owns the UNDO, 10 s (to t=16). The t=8 double-tap says "Milk, taken back." Call Mum
  stays done.
- **Master.** Now says "Done. Next one is up." with a 10 s note (`NowPage.swift:242`, thing last). From t=6 the line
  reads milk while UNDO reverts Call Mum, as in UC3. The VoiceOver user hears only "Undo" and has no way to tell
  which thing it will take back.
- **Status: wrong.**

### UC13. Live workout: LOG, then a capture

- **Actions.** In live mode on Push A. t=0 taps LOG (bench, set 3, 80 × 8). t=2 taps the soul, types "buy milk",
  Return at t=4. t=5 taps UNDO.
- **Ruled.** t=0 "Set 3 logged. 80 × 8." with UNDO 4 s (to t=4). t=4 "Milk, on the list." owns the only UNDO, 4 s from
  the line. The t=5 tap takes back milk ("Milk, taken back."); set 3 stays.
- **Master.** The live ask goes straight to `model.ask` (`WorkoutModeView.swift:275-288`) and shows its reply in
  `LiveTessCorner` (`:257`). That corner's key is `session.canUndoLast` (`:259`), which is the set and has no window
  (`WorkoutSession.swift:447-450`; it only hides when the line fades, `LiveTessCorner.swift:68`). So the UNDO under
  "Milk, on the list." takes back set 3 (`WorkoutSession+Edit.swift:93-104`); milk stays. Any later line (a capture,
  "Bench is done.") brings the same set UNDO back, minutes later.
- **Status: wrong.**

### UC14. Live workout: the capture's own UNDO

- **Actions.** In live mode, with no set logged yet. t=0 types "buy milk" in the live ask, Return. t=2 looks for UNDO.
- **Ruled.** "Milk, on the list." with UNDO, 4 s from the line.
- **Master.** `lastCapture` is set (`AppModel.swift:276`) but nothing in live mode reads it; the corner shows UNDO
  only for a set or an edit (`WorkoutModeView.swift:259`). The capture has no way back until he leaves live mode, by
  which time its 4 s are over.
- **Status: miss.**

### UC15. A private note captured right after a Home done

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=3 types "gate code is 4417", Return.
  t=6 taps UNDO.
- **Ruled.** t=5 "Private note, kept." owns the line and the UNDO, 4 s. The t=6 tap takes back the note and says
  "Private note, taken back." Neither line nor answer ever shows 4417, and VoiceOver reads only those words.
- **Master.** The line is "Private note, kept." (`TessCaptureEngine.swift:300`), no value: pass for the line. But the
  UNDO under it reverts Call Mum (`BottomChrome.swift:737-741`), so the note he meant to take back stays. Only a second
  tap after the note dries at t=7 takes it back, with no answer line. While drying, the Write line shows the typed
  text as the ghost (`BottomChrome.swift:477`); that is his own field, not Tess's line, and is out of scope here.
- **Status: wrong** (UNDO); **pass** (line hides the value); **miss** ("Private note, taken back.").

### UC16. Spoken "undo" after a Home done and a capture

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=3 types "buy milk", Return. t=6 holds the
  soul and says "undo".
- **Ruled.** As UC3: milk is taken back, "Milk, taken back."
- **Master.** `SpokenPhrase.isUndo` routes to the same `undo()` (`BottomChrome.swift:631-638`), so Call Mum is
  reverted.
- **Status: wrong.**

### UC17. Two Home actions in a row

- **Actions.** t=0 releases a swipe-done on "Call Mum" (op lands t=1.32). t=2 releases a swipe-left on "Pay rent"
  (op lands t=2.2). t=3 taps UNDO.
- **Ruled.** t=2.2 "Pay rent, tomorrow." owns the UNDO; Call Mum's window closes. The t=3 tap moves Pay rent back:
  "Pay rent, taken back."
- **Master.** The second `say` replaces the note (`HomeQueue.swift:29-31`), so the t=3 tap moves Pay rent back:
  right thing, but the line is "Moved to tomorrow." and the tap says nothing.
- **Status: pass** on ownership; the line and the answer fail under F2 and the audit (X3).

### UC18. An overnight line arriving over a capture

- **Actions.** At 3:59 am: t=0 types "buy milk", Return. t=3 locks the phone; t=20 (after 4 am) unlocks. The foreground
  tidy raises the roll line.
- **Ruled.** Milk's window paused at lock; on return the newest line (the roll) owns the UNDO, or, if it has nothing
  to take back, shows no UNDO. Milk's window closes either way (newest line owns).
- **Master.** `voice.say(notes, undo: model.processUndo)` (`BottomChrome.swift:138`) sets a note with no op, so
  `canUndo` is false (`:729-731`) even if `lastCapture` were alive. Here it is consistent with R2 by accident.
  Needs a Simulator run for the 4 am timing.
- **Status: pass** by accident (unconfirmed).

## Tally

18 cases: 3 pass (UC8, UC17 on ownership, UC18 unconfirmed), 13 wrong, 1 miss (UC14), 1 split (UC6: wrong with a
capture, pass alone). Plus misses inside cases: no VoiceOver announcement or named key (UC11), no "X, taken back."
after any in-app UNDO (all). Not built: Lists' remove (NE11) and the Live Activity undo have no UNDO to collide yet.

## Proposed single-owner rule

**One UNDO slot for the whole app. The line and the UNDO are one value, so they cannot disagree.**

1. Every surface that shows a line with a way back (capture, Home, Now, Groceries, recipe send, backup, live set,
   finish, Routines, notes delete) opens a claim in one shared slot. Opening a claim closes the one before it: the
   older thing keeps its write, but its UNDO goes. There is never more than one UNDO on screen.
2. A claim carries its thing ("Milk", "Call Mum", "Private note"), its line, its kind, and what it takes back (all
   ops of one phrase together). The line text and the UNDO key both read the current claim; nothing else draws an
   UNDO. A page that draws its own key (recipe, backup, live corner) shows it only while its claim is current.
3. The window opens when the line shows (for a capture, while the ghost is still drying: an UNDO before it dries
   discards it). Length: 4 s for a new thing, 10 s for a change or removal, 10 s for all with VoiceOver on. It pauses
   in the background and while locked, and resumes on return.
4. UNDO takes back exactly the claim's ops and answers "Thing, taken back." For a private note the thing is always
   "Private note". A partial reversal says so ("Call Mum, partly taken back.") rather than looking whole.
5. Siri's "Undo Last Set" stays outside the slot (no window, `decisions.md:167`), but a Siri take-back closes an open
   in-app claim on the same set.

## Shape of the shared UndoWindow (Core 0s)

Core owns the pure timing value in `TesseraCore` (no UI, no SwiftUI, an injectable clock so tests run without
sleeping); the app owns one `@MainActor @Observable` slot that every builder calls. Sketch, not code to paste:

```swift
// TesseraCore/Engine/UndoWindow.swift (Core)
public enum UndoKind: Sendable { case new, change }   // destructive counts as change

public struct UndoWindow: Sendable, Equatable {
    public static func seconds(for kind: UndoKind, voiceOver: Bool) -> Double  // 4 or 10; 10 when voiceOver
    public init(kind: UndoKind, voiceOver: Bool, opensAt: Date)
    public mutating func pause(at: Date)
    public mutating func resume(at: Date)
    public func remaining(at: Date) -> Double        // never below 0; frozen while paused
    public func isOpen(at: Date) -> Bool
}

// App/UndoSlot.swift (Builder B, used by A and B)
@MainActor @Observable final class UndoSlot {
    struct Claim: Identifiable { let id: UUID; let thing: String; let line: String
                                 let kind: UndoKind; let ops: [OpRecord]   // or a takeBack closure for non-op-log
                                 var window: UndoWindow }
    private(set) var current: Claim?
    func open(thing: String, line: String, kind: UndoKind, ops: [OpRecord]) -> Claim.ID   // replaces current
    func isCurrent(_ id: Claim.ID) -> Bool
    func undo() -> String?            // takes back current only if open; returns "Thing, taken back."
    func scenePhaseChanged(_ phase: ScenePhase)   // pause on .background/.inactive lock, resume on .active
    var voiceOver: Bool               // fed from accessibilityVoiceOverEnabled; read when a claim opens
}
```

`TessVoice.note`, `AppModel.lastCapture`, `RecipePage.sent`, `BackupView.forgotten` and the live corner's
`canUndoLast` become claims in this slot; `BottomChrome.line` and `canUndo` both read `slot.current`.

### Tests Core can copy (Swift Testing, `TesseraCore/Tests`)

```swift
@Suite struct UndoWindowTests {
    @Test func newThingGetsFourSeconds()
    @Test func changeGetsTenSeconds()
    @Test func voiceOverMakesEveryWindowTenSeconds()
    @Test func windowCountsFromWhenItOpens()
    @Test func pausedWindowDoesNotCountDown()
    @Test func resumeContinuesWithTheTimeLeft()
    @Test func closedAfterItsLengthAndNeverNegative()
    @Test func pauseTwiceThenResumeOnceKeepsTheSameRemaining()
}
```

### Tests the Builders can copy (Swift Testing, `TesseraTests`)

```swift
@Suite @MainActor struct UndoSlotTests {
    @Test func newerClaimClosesTheOlderOne()                   // UC1, UC17
    @Test func lineAndUndoReadTheSameClaim()                   // root cause
    @Test func captureAfterHomeDoneUndoesTheCapture()          // UC3, UC16
    @Test func homeDoneAfterCaptureUndoesHomeDoneAndShowsItsLine() // UC2, UC4
    @Test func secondCaptureUndoesOnlyTheSecond()              // UC1
    @Test func captureWindowCountsFromItsLine()                // UC7
    @Test func undoDuringTheGhostDiscardsIt()                  // UC7 ruled start
    @Test func noUndoWithoutALine()                            // UC7
    @Test func expiredClaimUndoesNothing()                     // UC8
    @Test func backgroundPausesTheWindow()                     // UC9, UC10
    @Test func voiceOverStretchesCaptureToTenSeconds()         // UC11, UC12
    @Test func undoAnswersThingTakenBack()                     // R4
    @Test func privateNoteAnswerNeverShowsTheValue()           // UC15, uses "gate code is 4417"
    @Test func recipeSendClaimIsTenSecondsAndYieldsToACapture() // UC5
    @Test func backupClaimYieldsToACapture()                   // UC6
    @Test func liveCaptureOwnsTheCornerUndoNotTheLastSet()     // UC13, UC14
    @Test func liveSetUndoClosesWhenItsWindowEnds()            // UC13 tail
    @Test func overnightLineWithNoOpClosesTheOpenClaim()       // UC18
}
```

Each fixture runs as its UC id on the PR that closes F1 (Builder B) and F2 (Core, then A and B), and UC10, UC18 also
on the Simulator with `-demoTime`, since their background timing cannot be settled by reading code.
