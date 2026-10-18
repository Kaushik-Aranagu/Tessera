# VoiceOver words for the one UNDO slot (Product item AS)

For: Builder B (BottomChrome, `UndoSlot`, Home, Groceries, Recipes, Notes, Backup, Settings), Builder A (the live
corner, finish, Routines), Core (`UndoWindow`), QA, Product. Research lab, Oct 16, 2026 (Pacific).
Read on `origin/master` at `559d67e` (Merge #521). Nothing was built or run.

Sources: `fixtures/undo-collision.md` (the slot, UC1 to UC18), `undo-windows-audit.md` (X1 to X19),
`fixtures/voiceover-recipe-clock-lists.md` (VO rules, VO20, VO23), `receipts-thing-first.md` (RC rows),
`accessibility.md` (A9, A11, A14, B3, B11), `fixtures/settings-day-one.md` (S45 to S61),
`fixtures/notes-day-one.md` (N35), `product/meal-plan-groceries-acceptance.md` (KW20), and these rulings in
`product/decisions.md`: 1:35 pm (one UNDO slot), 12:39 pm (VoiceOver 10 s), 12:45 pm (windows pause, 4 am roll; its
Claude key early-commit rule is superseded, the Claude key has no UNDO, 10:47 PM Oct 17), 12:35 pm (receipts name the thing, "Rice, on Groceries."), 1:13 pm (Claude key line),
1:15 pm (Notes receipts, VoiceOver announces them), 6:37 pm Oct 15 ("is back" for undoing a removal), F2 ("Push A,
back on.").

Master today posts no announcement anywhere and reads no VoiceOver state (audit headline; UC11). Every string below
is new on master unless a row says otherwise.

## The rules

1. **Thing first, everywhere VoiceOver speaks.** The announcement, the key's label and the taken-back answer all
   start with the claim's `thing`, the same string the line starts with. The label is `"Undo \(thing)"`: "Undo Milk",
   never "Undo" alone (UC11 proposed "Undo, Milk"; the brief's "Undo Milk" replaces it, and the spoken pause is the
   same).
2. **One source.** `line`, `announcement`, `label`, `hint`, `takenBack` are all computed from the claim, so the
   words and the UNDO cannot disagree (the 1:35 pm rule). Nothing outside the slot posts an UNDO announcement.
3. **Never read a secret.** No announcement, label, hint or value carries the private note's text, a walled title,
   the Claude key, any part of it, or its last four digits. A private note's thing is always the literal
   "Private note"; a walled health memory's is "Health note" (12:35 pm); a walled task's is "Private task"
   (1:06 pm). Test with "gate code is 4417", "wifi password is hunter2", "locker tacocat": none of `4417`, `hunter2`,
   `tacocat` may appear in any spoken string.
4. **Spoken, not shown, for symbols and units.** The shown line keeps "×" and "kg"; the announcement and label say
   the words. "82.5 × 8" is spoken "82.5 kilograms for 8" (the unit on master is kg, `App/AppClock.swift:35-36`, and
   Settings UNITS reads "Kilograms", S74; if a pound unit lands, "pounds"). Pass digits, not number words, so
   VoiceOver reads "82.5" as "eighty-two point five" in the phone's own voice. Never "e1RM" (spelled out as letters),
   never "×" (read as "multiplied by"), never "/" (read as "slash"). Times stay "6:30 pm", which VoiceOver reads well.
5. **"best", never "record" or "PR".** A best is spoken "a bench best".
6. **Windows under VoiceOver.** Every claim is 10 s when VoiceOver is on (12:39 pm, 1:35 pm), read once when the
   claim opens (`UndoWindow(kind:voiceOver:opensAt:)`). Turning VoiceOver on or off mid-window does not change the
   open window. Focus on the key does not pause it: the 12:39 pm ruling took a flat 10 s over VO20's "pauses while
   focused" (see Conflicts, C3).
7. **Pause in the background.** Leaving the app or locking the phone pauses the window (12:45 pm). Nothing is said on
   leaving. On return nothing is re-announced: the line is still on screen, and the key's value gives the time left.
   The one exception is the Claude key: it commits when the app goes to the background (12:45 pm), so on return its
   UNDO is gone and nothing is said.
8. **How to post.** One helper in the slot posts `AccessibilityNotification.Announcement(text)` with
   `accessibilitySpeechAnnouncementPriority = .high` on an `AttributedString`, so a newer claim interrupts an older
   line still being spoken, and a taken-back answer interrupts the line. Never move VoiceOver focus to the UNDO key
   when a claim opens; he decides whether to go there.
9. **The value.** The key's `accessibilityValue` is the whole seconds left, rounded up, at the moment focus lands:
   "10 seconds left" ... "2 seconds left", "1 second left". No `.updatesFrequently` (it would talk every second).
10. **Hints.** One short sentence saying what the tap changes, thing named, ending in a period. Hints are off for
    many users, so nothing needed lives only in the hint.
11. **The answer word.** "Thing, taken back." (1:35 pm, 12:35 pm). Undoing a removal says "Thing is back." (6:37 pm
    Oct 15 exception: delete note, routine dropped, backup folder; the Claude key is no longer one, it has no UNDO). Undoing a finish says "Push A, back on."
    (F2). See C1.

## Window close: say nothing

When a claim's window ends with no tap, the slot posts **no announcement**. Why:
- Nothing changed in his data. The write already happened and was already announced when the claim opened.
- He did not act, so there is nothing to confirm. A "too late" line would only tell him what he chose not to do.
- A spoken close would double every receipt: each line would be followed 10 s later by a second line, often on top
  of what he is reading or dictating next.
- The value already told him the time when he went to the key.

The one thing the slot does: if VoiceOver focus was on the UNDO key when it leaves, post
`AccessibilityNotification.LayoutChanged` with the line's element (now its resting text, or the soul when the line
is empty) so focus does not jump to the top of the screen. VoiceOver then reads that element's own label; the slot
adds no words.

## A newer claim replaces an older one

- Only the new claim's announcement is posted, at high priority, so it cuts off the older line if that is still
  being spoken. The older thing is never named again: no "Milk's undo is gone", no "Call mom, kept." The 1:35 pm rule
  says the older thing keeps its write; saying so would add a line for a non-event.
- The UNDO key takes a new identity per claim (`.id(claim.id)`), so a VoiceOver focus that sat on "Undo Call mom" is
  dropped rather than silently retargeted to Milk. A double tap aimed at the old label can never take back the new
  thing. The new key reads "Undo Milk" when he swipes to it.
- A line with nothing to take back (K7 "Tacos, nothing to add.", or the overnight line with no op, UC18) is
  still the newest line, so it closes the older claim's UNDO too, and it is announced the same way.

## The strings per kind

Shown = the line on screen. Ann = the announcement when the claim opens. Label, Hint, Value = the UNDO key.
Back = the announcement after UNDO. Close = the announcement when the window ends (always none, see above).
Window = without VoiceOver; every row is 10 s with VoiceOver on.

### K1. Capture, a new thing (Builder B, BottomChrome)

| Field | Words |
|---|---|
| Thing | `Milk` |
| Shown | "Milk, on Groceries." (12:35 pm list receipts name the list; master says "Milk, on the list.", RC19) |
| Ann | "Milk, on Groceries." |
| Label | "Undo Milk" |
| Hint | "Takes Milk off Groceries." |
| Value | "10 seconds left" (VO); "4 seconds left" otherwise |
| Back | "Milk, taken back." |
| Close | none |
| Window | 4 s, from when the line shows (an UNDO while the ghost dries discards it) |

A task capture: Shown and Ann "Dentist, Thursday 3 pm.", Label "Undo Dentist", Hint "Removes Dentist.", Back
"Dentist, taken back." Several things in one phrase: Shown and Ann "3 things, on Groceries.", Label
"Undo 3 things", Hint "Takes 3 things off Groceries.", Back "3 things, taken back."

### K2. Capture, a private note (Builder B)

| Field | Words |
|---|---|
| Thing | `Private note` (literal, never from the text) |
| Shown | "Private note, kept." (master, `TessCaptureEngine.swift:300`) |
| Ann | "Private note, kept." |
| Label | "Undo Private note" |
| Hint | "Removes the private note." |
| Value | "10 seconds left" (VO); "4 seconds left" otherwise |
| Back | "Private note, taken back." |
| Close | none |
| Window | 4 s |

The drying ghost in the Write field is his own text; while a phrase is classed private, the ghost's
`accessibilityLabel` is "Private note" too, so VoiceOver never reads "gate code is 4417" back from the ghost (UC15
left this out of scope; flagged here as Q4).

### K3. Home, done (Builder B; Home queue, Now page)

| Field | Words |
|---|---|
| Thing | `Call mom` |
| Shown | "Call mom, done." |
| Ann | "Call mom, done." |
| Label | "Undo Call mom" |
| Hint | "Marks Call mom not done." |
| Value | "10 seconds left" |
| Back | "Call mom, taken back." |
| Close | none |
| Window | 10 s |

Now's "Done. Next one is up." goes (RC1); the next task is its own row, not part of the announcement.

### K4. Home, move to tomorrow (Builder B)

| Field | Words |
|---|---|
| Thing | `Call mom` |
| Shown | "Call mom, tomorrow." ("Call mom, next week." for next week) |
| Ann | "Call mom, tomorrow." |
| Label | "Undo Call mom" |
| Hint | "Moves Call mom back to today." |
| Value | "10 seconds left" |
| Back | "Call mom, taken back." |
| Close | none |
| Window | 10 s |

### K5. Carry N tasks, the 4 am roll (Builder B; Core's roll line)

| Field | Words |
|---|---|
| Thing | `2 tasks` (one task: its title, "Call mom") |
| Shown | "2 tasks, carried into today." (SH11); one task "Call mom, carried into today." |
| Ann | same as Shown |
| Label | "Undo 2 tasks" / "Undo Call mom" |
| Hint | "Moves 2 tasks back to yesterday." / "Moves Call mom back to yesterday." |
| Value | "10 seconds left" |
| Back | "2 tasks, taken back." / "Call mom, taken back." |
| Close | none |
| Window | 10 s, opening when the line shows on return, not at 4 am |

With the workout wrap-up joined (X14), the one slot means one claim that takes back both (12:45 pm "takes back
both or shows two UNDOs"; one slot leaves only "both"): Shown and Ann "2 tasks, carried into today. Push A, no sets,
not saved.", Label "Undo 2 tasks and Push A", Hint "Moves 2 tasks back and reopens Push A.", Back "2 tasks and Push A,
taken back."

### K6. Recipe, send to Groceries (Builder B, RecipePage)

| Field | Words |
|---|---|
| Thing | `Tacos` |
| Shown | "Tacos, 10 added." |
| Ann | "Tacos, 10 added." |
| Label | "Undo Tacos" |
| Hint | "Takes 10 things off Groceries." |
| Value | "10 seconds left" |
| Back | "Tacos, taken back." |
| Close | none |
| Window | 10 s (12:45 pm) |

### K7. Recipe, nothing new (Builder B; no claim with a way back)

| Field | Words |
|---|---|
| Thing | `Tacos` |
| Shown | "Tacos, nothing to add." (L2) |
| Ann | "Tacos, nothing to add." |
| Label, Hint, Value | none: no UNDO key, it wrote nothing |
| Back | none |
| Close | none |
| Window | none; the line rests like any line, 4 s (10 s with VoiceOver) |

It is still the newest line, so it closes any older claim's UNDO.

### K8. Backup, stop using the folder (Builder B, BackupView)

| Field | Words |
|---|---|
| Thing | shown `iCloud Drive/Tessera`; spoken `iCloud Drive Tessera folder` |
| Shown | "iCloud Drive/Tessera dropped. Copies stay on this iPhone." (S59) |
| Ann | "iCloud Drive Tessera folder dropped. Copies stay on this iPhone." |
| Label | "Undo iCloud Drive Tessera folder" |
| Hint | "Keeps saving copies to the folder." |
| Value | "10 seconds left" |
| Back | "iCloud Drive Tessera folder is back." (shown: "iCloud Drive/Tessera is back.", S61) |
| Close | none |
| Window | 10 s; outside the op log, the claim carries a take-back closure |

The folder name is his to pick; build the spoken thing as "\(location) \(folderName) folder", never with "/".

### K9. Delete a note (Builder B, NoteEditor)

| Field | Words |
|---|---|
| Thing | the note's first line, `Bar felt heavy on set 3`; a private note: `Private note` |
| Shown | "Bar felt heavy on set 3, deleted." / "Private note, deleted." |
| Ann | same as Shown |
| Label | "Undo Bar felt heavy on set 3" / "Undo Private note" |
| Hint | "Brings the note back." |
| Value | "10 seconds left" |
| Back | "Bar felt heavy on set 3 is back." / "Private note is back." |
| Close | none |
| Window | 10 s (destructive) |

A first line longer than 8 words is cut to its first 8 words in Shown, Ann, Label and Back alike (Q2).

### K10. Claude key removed (Builder B, Settings: Claude) - NO UNDO

Product ruled (10:47 PM Oct 17) that removing the Claude key has no UNDO, because nothing keeps a copy of the key, and
shows a plain receipt with no key content. K10 therefore takes no slot claim: no Label, Hint, Value or Back, no window,
and nothing to commit when the app goes to the background. Remove is a two-step tap key ("Remove the Claude key?" with
"Remove" and "Keep it", 11:07 PM Oct 17, #978 item 4) and keeps VoiceOver double tap.

| Field | Words |
|---|---|
| Thing | `Claude key` |
| Shown | "Claude key removed. Everything stays on this phone." |
| Ann | "Claude key removed. Everything stays on this phone." |
| UNDO | none (no slot claim) |

No string here carries the key, its prefix or its last four; key state is yes/no only (10:44 PM Oct 17, item 4).
Replacing a key (S45) is also a plain receipt, "Claude key replaced.", with no UNDO and no digits. The old
`undoRemove()` path (`ClaudeSection.swift:~393-398`) is what Core/Builder B must remove.

### K11. Live workout, LOG a set (Builder A, the live corner)

| Field | Words |
|---|---|
| Thing | `Set 3` |
| Shown | "Set 3 logged. 82.5 × 8." |
| Ann | "Set 3 logged. 82.5 kilograms for 8." |
| Label | "Undo set 3" |
| Hint | "Removes set 3 of bench press." |
| Value | "10 seconds left" (VO); "4 seconds left" otherwise |
| Back | "Set 3, taken back." |
| Close | none |
| Window | 4 s; master has none (UC13) |

Variants: a best, Shown "Set 3 logged. 85 × 5, best." and Ann "Set 3 logged. 85 kilograms for 5, a bench best."
Added load, Ann "Set 2 logged. Plus 10 kilograms for 8." Bodyweight, Ann "Set 2 logged. 8 reps." Sets 2 to 4 at once,
Ann "Sets 2 to 4 logged.", Label "Undo sets 2 to 4", Back "Sets 2 to 4, taken back." Siri's "Undo Last Set" stays
outside the slot and keeps its own "Set 3 taken back." (X15); a Siri take-back closes this claim with no announcement
from the slot.

### K12. Finish the workout (Builder A, finish view)

| Field | Words |
|---|---|
| Thing | `Push A` |
| Shown | "Push A done." (with a best: "Push A done, a bench best.") |
| Ann | same as Shown |
| Label | "Undo Push A" |
| Hint | hold to finish: "Reopens Push A."; LOG AND FINISH: "Reopens Push A and takes back set 4." |
| Value | "10 seconds left" |
| Back | "Push A, back on." (F2) |
| Close | none |
| Window | 10 s, both finishes (12:45 pm) |

Zero sets: Shown and Ann "Push A, no sets, not saved.", same key and Back.

### K13. Routine dropped (Builder A, Routines page)

| Field | Words |
|---|---|
| Thing | `Push B` |
| Shown | "Push B dropped." (V-T6, `RoutinesPage.swift` clean row) |
| Ann | "Push B dropped." |
| Label | "Undo Push B" |
| Hint | "Puts Push B back in the plan." |
| Value | "10 seconds left" |
| Back | "Push B is back." |
| Close | none |
| Window | 10 s (master has none, X6) |

### K14. Habit marked (Builder B, BottomChrome; Shutdown's DONE)

| Field | Words |
|---|---|
| Thing | `Read` |
| Shown | typed: "Read, 3 of 5 this week."; Shutdown DONE: "Read, done."; at the target: "Read done for the week." |
| Ann | same as Shown |
| Label | "Undo Read" |
| Hint | "Unmarks Read for today." (before 4 am the habit day is yesterday: "Unmarks Read for Monday.") |
| Value | "10 seconds left" (VO); typed "4 seconds left"; Shutdown "10 seconds left" |
| Back | "Read, taken back." |
| Close | none |
| Window | typed 4 s (his capture, HW6); Shutdown DONE 10 s (shutdown-flow 5) |

### K15. Skip a meal (Builder B, Groceries and Home)

| Field | Words |
|---|---|
| Thing | `Dal` |
| Shown | "Dal, skipped." (KW20) |
| Ann | "Dal, skipped." |
| Label | "Undo Dal" |
| Hint | "Puts Dal and its groceries back." |
| Value | "10 seconds left" |
| Back | "Dal, taken back." |
| Close | none |
| Window | 10 s |

### K16. Partial undo (both builders; any kind)

`ActionEngine.undo` returns `.partial(skipped:)` when an op changed since (audit, undo-lines). The slot reads it.

| Field | Words |
|---|---|
| Back | "Tacos, partly taken back." then, when the skipped part can be named, one more sentence: "2 stayed on Groceries." |
| Ann on open, Label, Hint, Value | those of the claim's own kind |
| Close | none; the claim is closed by the tap either way |

Other kinds: "Call mom, partly taken back.", "Push A, partly taken back." No count sentence when the skipped ops have
no plain name.

## Conflicts with existing rulings

- **C1. "taken back" or "is back".** 1:35 pm says "The receipt is 'Thing, taken back.'"; the 6:37 pm Oct 15 ruling
  keeps "is back" for undoing a removal; the habit delete ("Read is
  back.") use it. This file keeps "is back" for K8, K9, K13 and F2's "Push A, back on." for K12, reading 1:35 pm
  as the general rule. Product to confirm.
- **C2. "Undo Milk" or "Undo, Milk".** UC11 proposed the comma; this file uses the brief's "Undo Milk".
- **C3. Pause while focused.** `voiceover-recipe-clock-lists.md` (rules line, VO20, VO40) wanted windows to pause
  while VoiceOver focus is on Undo. 12:39 pm took the flat 10 s instead, and the `UndoWindow` sketch pauses only in the
  background. This file follows 12:39 pm; VO20's "pauses while focused" and VO40's wait should be struck.
- **C4. "for 8" or "for 8 reps".** `accessibility.md` A9 says "\(weight) kilograms for \(reps) reps"; the brief says
  "82.5 kilograms for 8". This file uses the brief for the announcement. A9 is the log key's label, where "reps" may
  stay.
- **C5. The capture line.** Master and UC1 say "Milk, on the list."; 12:35 pm decided "Rice, on Groceries." This file
  uses the decided form.
- **C6. 4 am.** 12:45 pm allowed "two UNDOs" at 4 am; one slot leaves only "takes back both" (K5).

## Strings invented here (Product to confirm)

1. Every hint (K1 to K15).
2. K5's one-task form "Call mom, carried into today." and the joined roll and wrap-up claim (label, hint, back).
3. K8's spoken thing "iCloud Drive Tessera folder" (no slash) and its hint.
4. K9's private form "Private note, deleted." and "Private note is back."; the 8-word cut.
5. K10's "Claude key replaced." and "Claude key removed." plain receipts (no slot claim).
6. K11's spoken variants: "a bench best", "Plus 10 kilograms for 8", "8 reps", and "Undo set 3" in lower case.
7. K12's hint naming the set for LOG AND FINISH.
8. K14's "Unmarks Read for Monday." before 4 am.
9. K16's second sentence ("2 stayed on Groceries.").
10. The value format "N seconds left" and "1 second left".

## Questions for Product

- Q1. C1 above: keep "is back" for removals under the one slot?
- Q2. A long note's first line as the thing: cut at 8 words, or name it "Note" when it is long?
- Q3. Should the Magic Tap (two-finger double tap) take back the current claim while one is open? It would give
  VoiceOver a way to UNDO without hunting for the key. The live workout may want Magic Tap for LOG instead.
- Q4. The drying ghost of a private phrase: label "Private note" while it dries (K2), or out of scope as his own text?

## Swift Testing table (sketch, not code to paste)

Builders add one pure value, `UndoSpeech`, computed from a claim, so these run without VoiceOver or a clock.
Builder B's file covers K1 to K9, K14, K15, K16; Builder A's covers K11 to K13 and K16 in the live corner.

```swift
import Testing
@testable import Tessera

struct UndoSpeechRow: Sendable, CustomTestStringConvertible {
    let id: String
    let claim: UndoSlot.Claim          // built by a test factory per kind
    let shown: String
    let announcement: String
    let label: String?                 // nil: no UNDO key
    let hint: String?
    let takenBack: String?
    var testDescription: String { id }
}

// Builder B (BottomChrome and the pages that draw their key only while their claim is current)
let bottomChromeRows: [UndoSpeechRow] = [
    .init(id: "K1",  claim: .capture("buy milk"),
          shown: "Milk, on Groceries.", announcement: "Milk, on Groceries.",
          label: "Undo Milk", hint: "Takes Milk off Groceries.", takenBack: "Milk, taken back."),
    .init(id: "K2",  claim: .capture("gate code is 4417"),
          shown: "Private note, kept.", announcement: "Private note, kept.",
          label: "Undo Private note", hint: "Removes the private note.", takenBack: "Private note, taken back."),
    .init(id: "K3",  claim: .homeDone("Call mom"),
          shown: "Call mom, done.", announcement: "Call mom, done.",
          label: "Undo Call mom", hint: "Marks Call mom not done.", takenBack: "Call mom, taken back."),
    .init(id: "K4",  claim: .homeMove("Call mom", to: .tomorrow),
          shown: "Call mom, tomorrow.", announcement: "Call mom, tomorrow.",
          label: "Undo Call mom", hint: "Moves Call mom back to today.", takenBack: "Call mom, taken back."),
    .init(id: "K5",  claim: .carry(count: 2),
          shown: "2 tasks, carried into today.", announcement: "2 tasks, carried into today.",
          label: "Undo 2 tasks", hint: "Moves 2 tasks back to yesterday.", takenBack: "2 tasks, taken back."),
    .init(id: "K6",  claim: .recipeSend("Tacos", added: 10),
          shown: "Tacos, 10 added.", announcement: "Tacos, 10 added.",
          label: "Undo Tacos", hint: "Takes 10 things off Groceries.", takenBack: "Tacos, taken back."),
    .init(id: "K7",  claim: .recipeSend("Tacos", added: 0),
          shown: "Tacos, nothing to add.", announcement: "Tacos, nothing to add.",
          label: nil, hint: nil, takenBack: nil),
    .init(id: "K8",  claim: .backupFolderDropped(location: "iCloud Drive", folder: "Tessera"),
          shown: "iCloud Drive/Tessera dropped. Copies stay on this iPhone.",
          announcement: "iCloud Drive Tessera folder dropped. Copies stay on this iPhone.",
          label: "Undo iCloud Drive Tessera folder", hint: "Keeps saving copies to the folder.",
          takenBack: "iCloud Drive Tessera folder is back."),
    .init(id: "K9",  claim: .noteDeleted(firstLine: "Bar felt heavy on set 3", isPrivate: false),
          shown: "Bar felt heavy on set 3, deleted.", announcement: "Bar felt heavy on set 3, deleted.",
          label: "Undo Bar felt heavy on set 3", hint: "Brings the note back.",
          takenBack: "Bar felt heavy on set 3 is back."),
    .init(id: "K9p", claim: .noteDeleted(firstLine: "wifi password is hunter2", isPrivate: true),
          shown: "Private note, deleted.", announcement: "Private note, deleted.",
          label: "Undo Private note", hint: "Brings the note back.", takenBack: "Private note is back."),
    .init(id: "K14", claim: .habitMarked("Read", count: 3, target: 5),
          shown: "Read, 3 of 5 this week.", announcement: "Read, 3 of 5 this week.",
          label: "Undo Read", hint: "Unmarks Read for today.", takenBack: "Read, taken back."),
    .init(id: "K15", claim: .mealSkipped("Dal"),
          shown: "Dal, skipped.", announcement: "Dal, skipped.",
          label: "Undo Dal", hint: "Puts Dal and its groceries back.", takenBack: "Dal, taken back."),
]

// Builder A (the live corner, finish, Routines)
let liveCornerRows: [UndoSpeechRow] = [
    .init(id: "K11", claim: .setLogged(set: 3, lift: "bench press", kg: 82.5, reps: 8, best: false),
          shown: "Set 3 logged. 82.5 × 8.", announcement: "Set 3 logged. 82.5 kilograms for 8.",
          label: "Undo set 3", hint: "Removes set 3 of bench press.", takenBack: "Set 3, taken back."),
    .init(id: "K11b", claim: .setLogged(set: 3, lift: "bench press", kg: 85, reps: 5, best: true),
          shown: "Set 3 logged. 85 × 5, best.", announcement: "Set 3 logged. 85 kilograms for 5, a bench best.",
          label: "Undo set 3", hint: "Removes set 3 of bench press.", takenBack: "Set 3, taken back."),
    .init(id: "K12", claim: .finished("Push A", withLastSet: nil),
          shown: "Push A done.", announcement: "Push A done.",
          label: "Undo Push A", hint: "Reopens Push A.", takenBack: "Push A, back on."),
    .init(id: "K12f", claim: .finished("Push A", withLastSet: 4),
          shown: "Push A done.", announcement: "Push A done.",
          label: "Undo Push A", hint: "Reopens Push A and takes back set 4.", takenBack: "Push A, back on."),
    .init(id: "K13", claim: .routineDropped("Push B"),
          shown: "Push B dropped.", announcement: "Push B dropped.",
          label: "Undo Push B", hint: "Puts Push B back in the plan.", takenBack: "Push B is back."),
]

@Suite @MainActor struct UndoSpeechTests {
    @Test(arguments: bottomChromeRows + liveCornerRows)
    func wordsPerKind(_ row: UndoSpeechRow) {
        let s = UndoSpeech(row.claim)
        #expect(s.shown == row.shown)
        #expect(s.announcement == row.announcement)
        #expect(s.label == row.label)
        #expect(s.hint == row.hint)
        #expect(s.takenBack == row.takenBack)
    }

    @Test(arguments: bottomChromeRows + liveCornerRows)
    func labelStartsWithUndoAndTheThing(_ row: UndoSpeechRow) {
        guard let label = row.label else { return }
        #expect(label.hasPrefix("Undo "))
        #expect(label != "Undo")
    }

    @Test(arguments: bottomChromeRows + liveCornerRows)
    func nothingSpokenCarriesASecretOrASymbol(_ row: UndoSpeechRow) {
        let s = UndoSpeech(row.claim)
        let spoken = [s.announcement, s.label, s.hint, s.takenBack].compactMap { $0 }
        for text in spoken {
            for secret in ["4417", "hunter2", "tacocat"] { #expect(!text.contains(secret)) }
            for glyph in ["×", "/", "e1RM", "record", "PR"] { #expect(!text.contains(glyph)) }
        }
    }

    @Test func valueIsWholeSecondsLeft()          // "10 seconds left", "1 second left", rounded up
    @Test func windowCloseAnnouncesNothing()      // close posts no announcement
    @Test func newerClaimAnnouncesOnlyItself()    // UC1, UC3: one post, the new line
    @Test func newerClaimGivesTheKeyANewIdentity()
    @Test func voiceOverMakesEveryKindTenSeconds()
    @Test func claudeKeyRemoveHasNoUndo()  // K10: plain receipt, no slot claim, nothing to commit on background
    @Test func partialUndoSaysPartly()            // K16: "Tacos, partly taken back. 2 stayed on Groceries."
}
```

The `#expect` on "PR" is case-sensitive on purpose, so "Copies" and "press" do not trip it.
