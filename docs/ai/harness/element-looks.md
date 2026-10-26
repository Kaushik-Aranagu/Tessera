# Living looks: the AI side of sheet 286

Kaushik, Oct 26: "there is an option for any UI element to be alive ... if I don't like ... how a list is being
shown, like how a dial is being shown, it should be customizable ... co-built for AI ... a seamless connection between
the two."

Design owns the looks and their motion: `docs/design/living-looks-286.md` (PR #1435). This page covers the engine
and Tess's side of that sheet, section 5. Code: `TesseraCore/Elements/LookCatalog.swift`, `TesseraSettings.placeLooks`,
`TesseraTess/Harness/Elements/ElementLookTools.swift`, and the shell calls in `ElementCatalog` and `TessRun`. Tests:
`ElementLooksTests.swift`. Tess's hidden test path is `rehearsal.md`.

## 1. What a look is

- **How a place draws its meaning, nothing more.** A look keeps the place's frame, its items, its focus and its
  calls, so `ElementMeaning` and `TessFrame` are the same in every look and the tool picker never needs to know the
  look. A test holds this: the same screen in two looks gives the same frame.
- **A setting, not his data.** Looks are kept in `TesseraSettings.placeLooks` (a `RoomLooks`, which travels with a
  restore like his other preferences). Changing one writes nothing to his notes, workouts or money.
- **Keystones have only Quiet.** A room's keystone is its identity: as drawn, or Quiet (the same picture with no
  idle motion, `LiveSwitch.quiet`).

## 2. The catalog (`LookCatalog`)

`LookCatalog.looks(for: place, room:)` gives `[LookDef]` (id, name, phrases, rooms), with the default first. Layout
mode and Tess read the same list.

| Place | Looks (default first) |
|---|---|
| switcher | wordsAcross, rollWord |
| needs | twoLines, oneLine, count |
| widget | oneThing, oneAndNext, quiet |
| glyph | drawn, none |
| dial | reel, column, sentence |
| doorSummary | lines, oneSentence, numbers |
| page | ranked, even, twoColumns, byTime (Watch, Galley, Lookout, Deck only) |
| actionWord | wordAndLine, wordOnly |
| tess | soul, still |
| keystone | drawn, quiet |

The level 2 body's per-kind looks plus Plain (sheet 284) join this once the body has a place in the contract.

**Resolving a look:** `RoomLooks.look(room:place:)` returns the room's look, then every room's, then the default. A
kept look that no longer exists, or that the room can't show, falls through. `setting(_:place:scope:)` refuses a look
the place doesn't have or the room can't show, and refuses every room for a look tied to some rooms. Setting the
default for every room clears that entry. `offersEverywhere` tells the shell when the Undo line may offer
"Everywhere".

## 3. Tess

- **Shell calls, never tools.** `setLook(place, look, scope: room | everywhere)` and `showLooks(place)`, which opens
  Layout mode on that pane. Both are in `ElementCatalog.shellCalls` and offered on every place with more than one
  look. `TessRun` hands them to the host as a `ShellIntent`. There's no ghost row: the host checks
  `RoomLooks.setting`, writes settings, and plays sheet 285's wash, then the swap, then the Undo line ("Tess showed
  the doors as a column. Undo"). A look carries no blue.
- **Bound, no model.** A short ask that names one look on a place runs at once:
  - "show the doors as a column" or "every dial as a list" (every room);
  - "the summary as one sentence" (the longest phrase wins);
  - "quieter sky" (the keystone's Quiet);
  - "as drawn" (the default back);
  - "what looks can the doors have" (`showLooks`).

  The place is the one he names; otherwise the one he touched in the last 30 s, then "this". It must be a shown
  place. It binds only when the ask is about looks or names a place, so "quiet hours at 10" never quiets the
  widget.
- **Open asks.** "I don't like this dial" gets `setLook` and `showLooks` first. The look lines (`TessFrame.lookLines`,
  read from settings, never from the frame) say what each shown place is now and what it could be. She tries
  candidates off screen first (`rehearsal.md`) and shows him one that passed.
- **Never unasked.** A look he keeps may become a `prefers` belief. She may offer it in another room as a notice
  with a one-tap fix, never apply it.

## 4. Only what he can see

From `live-visibility.md`:
- `ElementMeaning.isShown` comes from the shell's `liveScope`.
- "This" and a look's target only consider shown places.
- `TessFrame.reaction(of:on:)` is nil for a place he can't see. The setting or the data lands and the Undo clock
  runs, but the move is skipped. If the place comes into view inside the window, it shows the end state.

## 5. Builders (sheet 286, section 5)

- `SlotContent.look: LookID`, from `SettingsStore.read().looks.look(room:place:)`. Each `PlaceHost` renders the same
  `ElementMeaning` through the look's view.
- Layout mode lists `LookCatalog.looks(for:room:)`, and a keep writes `RoomLooks.setting` through
  `SettingsStore.update`.
- `MotionPolicy.lookSwap`; shared things match by item id.
- `LiveSwitch.quiet` for a keystone's Quiet.
- The host handles the `setLook` and `showLooks` intents.
