# Living looks: the AI side of sheets 286 and 287

Kaushik, Oct 26: "there is an option for any UI element to be alive ... if I don't like ... how a list is being
shown, like how a dial is being shown, it should be customizable ... co-built for AI ... a seamless connection between
the two."

Design owns the forms and their motion. Sheet 286 is `docs/design/living-looks-286.md` and sheet 287 is
`docs/design/transitions-287.md`, both on PR #1435; where they differ, 287 wins. This page covers the engine's side
and Tess's side of those sheets.

- **Code:**
  - `TesseraCore/Elements/ElementForms.swift` and `LookCatalog.swift`
  - `TesseraSettings.placeLooks`
  - in `TesseraTess/Harness/Elements/`: `ElementLookTools.swift`, `ElementChange.swift`, `ElementStage.swift`, and
    the shell calls in `ElementCatalog` and `TessRun`
- **Tests:** `ElementLooksTests.swift`.
- **Related:** Tess's hidden test path is `rehearsal.md`; the template and suite for her calls is section 7.

## 1. What a look is

- **A form plus traits.** A place's content has a shape: one, few, many, words, doors, measure or lines. A form is how
  that shape is drawn, and traits tune the form. Only forms the studio drew exist (`ElementForms`), so a look can
  never make a card, a pill, a bar or a ring. There is no colour trait.
- **How a place draws its meaning, nothing more.** A look keeps the place's frame, its items, its focus and its
  calls. So `ElementMeaning` and `TessFrame` are the same in every look, and the tool picker never needs to know the
  look. A test checks this: the same screen in two looks gives the same frame.
- **A setting, not his data.** Looks are kept in `TesseraSettings.placeLooks` as a `RoomLooks`, which travels with a
  restore like his other preferences. Changing one writes nothing to his notes, workouts or money.
- **Each field inherits.** `RoomLooks.look(room:place:)` fills the form and each trait separately:
  1. the room's own entry;
  2. otherwise, every room's entry;
  3. otherwise, the studio's.

  A room names only what differs. A kept form or value that no longer exists, or that the room can't show, falls
  through.
- **Keystones keep their material.** A keystone is its room's identity, so it has one form per room and can't be
  changed for every room. It is tuned by `motion` (designed, calm or still; still is `LiveSwitch.quiet`). The board
  and the rail add their own traits.

## 2. Forms per place (sheet 287, section 6)

Each place lists its forms with the designed one first, then its traits. `LookCatalog.forms(for:room:)` and
`traits(for:form:)` give these lists; shape mode, Layout mode and Tess all read the same table.

| Place | Forms | Traits |
|---|---|---|
| switcher | type, roll | none |
| needs | type | count (1, 2), facts (numbers only) |
| widget | rise, stack, rows, ledger (Purse), trace (Lookout, Purse) | facts (just names), size |
| glyph | drawing, trace | shows (on, off) |
| dial | reel, index, sentence | density (an index of more than 5 doors takes two columns) |
| doorSummary | type, sentence | facts (numbers only) |
| page | rows, columns, wall, ledger, stack | weight (ranked, even), order (rank, time), density |
| keystone | its room's material: mosaic, wordWall, chalk, tickets, woods, sky or chart | motion; chalk: shows; tickets: count |
| actionWord | type | shows (word only, word and line) |

The level 2 body (its kind's drawing, or plain type) joins this table once the body has a place in the contract.
Sheet 287's bullets also list sentence on needs and columns on the dial. The table shows neither, so here needs
takes a line count and the dial's index takes columns through density. Design can add them as rows.

**Changing a look:** `RoomLooks.applying(_:place:scope:)` takes a `LookChange`, which is `.form`, `.trait` or
`.designed`.
- It refuses:
  - a form or value the place doesn't have;
  - one the room can't show;
  - a form tied to some rooms, when the scope is every room;
  - a form's own trait, when the scope is every room.
- A value the scope would inherit anyway is cleared, not stored.
- "As drawn" in one room holds against what every room says. "As drawn" for every room clears the place everywhere.
- `offersEverywhere` tells the shell when the Undo line may offer "Everywhere".

## 3. By hand: shape mode (sheet 287, section 4)

1. He holds the Nav word for 450 ms. Shape mode opens over the live screen: a raised-glass outline goes around every
   place, the Nav word becomes Done, and the foot becomes the shape line.
2. He taps a place. Its forms show as words, with its trait words under them.
3. He swipes inside the place, or taps a form word, to change the form. He taps a trait word to step it.
4. Done keeps the change and starts a 10 s Undo.

Settings > Layout mode opens the same mode on Bridge. Both write through `RoomLooks.applying` and
`SettingsStore.update`. This is the builders' half.

## 4. Tess

- **Shell calls, never tools.** She has two:
  - `setLook(place, form | trait + value, scope: room | everywhere)`; a form of `designed` means as drawn.
  - `showLooks(place)`, which opens shape mode with that place picked.

  Both are in `ElementCatalog.shellCalls` and offered on every living place (`LookCatalog.isLiving`). `TessRun` hands
  them to the host as a `ShellIntent`, and `ShellIntent.change` gives the change kind. There's no ghost row. The
  host:
  1. checks the change with `RoomLooks.applying`;
  2. writes settings;
  3. plays sheet 285's wash, then the travel, then the Undo line ("Doors as an index. Undo").

  A look carries no blue.
- **Bound, no model.** A short ask that names one change on a place runs at once. The longest phrase wins.
  - "show the doors as an index"
  - "every dial as a list", which changes every room
  - "the summary as one sentence"
  - "calmer sky", the keystone's motion one step calmer
  - "as drawn"
  - "what looks can the doors have", which runs `showLooks`

  A trait word steps from his kept value, so "denser" on an airy index gives the designed density. A step past the
  end goes to the model.

  **Which place it binds to.** First the place he names. Otherwise the one he touched in the last 30 s, then
  "this". It must be a place he can see.

  **When it binds.** Only when one of these is true:
  - the ask is about looks;
  - it names the place;
  - it is nothing but the change and filler.

  So a bare "denser" binds, but "add bigger plates" and "quiet hours at 10" never do. A bound change is his own
  choice, like his hand, so it isn't staged.
- **Open asks.** "I don't like this dial" gets `setLook` and `showLooks` first. The look lines
  (`TessFrame.lookLines`) say each shown place's form and traits now, and what else it could take. They are read from
  settings, never from the frame. A form or value she picks is checked in two steps:
  1. against the place's own list (`LookWords.isKnown`);
  2. on the quiet stage (`TessRun.stage`, section 5).

  If it fails, she hears which checks failed, keeps his look, and tries the next form or tells him why.
- **Never unasked.** A look he keeps may become a `prefers` belief. She may offer it in another room as a notice with
  a one-tap fix, but never applies it.

## 5. The pipeline and the stage (sheet 287, sections 1, 3 and 5)

- **`Change { place, kind, itemIDs, before, after }` and `Control { hand, tess, system, stage }`.** These go to
  `PlaceHost` with `isShown`.
  - `ChangeKind` is sheet 287's catalog of kinds.
  - `Reaction.change` maps a call's reaction to its kind.
  - The shell's `TransitionCatalog.move(kind:control:place:room:)` picks the move. There is one move per kind, and
    the control changes only tempo and mark.
- **The reshape is the travel move.** `ReshapeMove` matches items by id: what both forms show travels over 520 ms,
  and the rest fades. It collapses to a point only when the two forms share no item.
- **The quiet stage.** The shell's `ShellStage.render(screen:looks:)` draws with no window and no clock. It returns a
  `StageReport`: per place, the flags fits, floor, contrast, rules, touch and calm.
  - The picture stays in memory on the phone.
  - Only the flags reach a model, and they never carry an item's name.
  - The host hands `TessRun.stage` a closure that renders the screen he is on with one `LookChange`.

## 6. Only what he can see

From `live-visibility.md`:
- `ElementMeaning.isShown` comes from the shell's `liveScope`.
- "This" and a look's target only consider shown places.
- `TessFrame.reaction(of:on:)` is nil for a place he can't see. The setting or the data lands and the Undo clock
  runs, but the move is skipped. If the place comes into view inside the window, it shows the end state.

## 7. Her calls as a template (sheet 288, section 6)

`ElementCall` is the base: a tool that acts on nothing, on any rung, for any kind of thing, with a reaction. A call
names only what differs from that.

`CallConformance.failures(_:room:place:)` is the suite. Every call on every place in every room must pass it:
- **real:** a Tess tool, `open`, a proposed tool, or the shell;
- **reach:** the call and its tool agree on money;
- **inputs:** each input is an argument the tool or shell call takes;
- **bound:** when he needn't say anything, the frame fills every input;
- **wall:** a device-only call never reaches a Claude rung, bound or open.

`ElementCatalog.everyCall` is the registry. `CallConformance.unregistered` must be empty, so no Tess tool escapes the
suite. The first run caught two calls whose inputs disagreed with their tools:
- `setServeTime` took `time`, but the tool takes `serveAt`;
- `query` took `question`, but the tool takes `from`.

## 8. Builders

- **Rendering:** `SlotContent.look` is a `PlaceLook`, from `SettingsStore.read().looks.look(room:place:)`. Each
  `PlaceHost` renders the same `ElementMeaning` through the form's view and its traits.
- **Shape mode:** the Nav word hold, and Settings > Layout mode, both write through `RoomLooks.applying` and
  `SettingsStore.update`.
- **Moves:** `TransitionCatalog` as sheet 287's table, `MotionPolicy` for the travel (shared things matched by item
  id), and `LiveSwitch.quiet` for still.
- **The stage:** `ShellStage.render(screen:looks:) -> StageReport`, with `TessRun.stage` wired to it.
- **System changes:** the shell holds `.system` changes while a touch is down on the place (2 s at most), and
  coalesces changes on one place within 1 s.
- **The host:** handles the `setLook` and `showLooks` intents.
- **Sheet 288:** `TesseraElement`, `ElementSpec`, `ElementConformance.run(spec:)` and `ElementRegistry.all`.
