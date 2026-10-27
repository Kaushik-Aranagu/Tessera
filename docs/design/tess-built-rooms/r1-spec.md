# R1: the Chart room, blank, built by talking (build spec)

For: Core (engine, tool, validator) and Builder A (player, look, motion). From: Design.
Approved: Kaushik picked "Both now" on the Design thread card, Oct 27 2026, 1:26 PM PDT.
Read first: the Tess-built rooms page (`index.html` here, sections "The shape" and "From one sentence to the screen") and board sheet 357 (`sheets.md`, board map entry "Chart room (experimental)").

The goal of R1: one new room, the Chart room, opens as the bare shell frame. Kaushik says or types what he wants. Tess turns it into a patch, and the room fills place by place as a ghost that sets after the 2-second drying line. Every change can be undone. No install is needed for anything inside the kit below.

Not in R1: shaders (R4), scripts and logic packs (R3; R1 has one built-in reaction, "highlight the top row", below), the Mac part builder (R5), rewriting a preset room (R6), ghost variants (R2).

## 1. The room is objects (Core)

Two new system classes in `SystemCatalog` (no new storage; everything goes through `ObjectStore` and the op log):

| Class | Key | Fields |
|---|---|---|
| Room | `room` | `name` (text), `color` (choice of theme color roles), `look` (text: JSON of LookCatalog trait values, for example `{"density":"airy","motion":"calm"}`), `reach` (text: JSON array of grants, below) |
| Room part | `roomPart` | `kind` (choice: the kit in section 3), `place` (choice: shell `Place` raw values), `props` (text: JSON, per kind), `bind` (text: an `ObjectPath` query, optional) |

- A part is a child of its room (`parent`), and its order within a place is its sort index.
- So a patch is only existing ops: `.create` (add a part), `.setValue` (change kind, place, props, bind, or the room's look and reach), `.softDelete` (remove), `.setSortIndex` (move). Undo, "undo what Tess did" and history are free, because every op already has an inverse and an actor.
- A Tess patch is one op group written as `pending` (the ghost). It commits when the drying line ends (2 s) or on a tap. Dismissing it marks it `undone`. This is the same pending flow Tess's ghost rows use today.
- Bindings are `ObjectPath` queries resolved at render time. The document never holds a copy of his data, so the room stays live.

## 2. The tool: `patchRoom` (Core)

A strict tool in `TessTools`, so the model's output is shape-checked before anything runs:

```json
{"room": "Chart room",
 "say": "Plants, set",
 "ops": [
   {"op": "add", "id": "title", "kind": "title", "place": "title", "props": {"text": "Plants"}},
   {"op": "add", "id": "line", "kind": "line", "place": "switcher", "props": {"text": "{count} plants, the {top} is thirsty"}, "bind": "Plant"},
   {"op": "set", "id": "list", "props": {"sort": "-daysSince(lastWatered)"}},
   {"op": "look", "trait": "motion", "value": "calm"},
   {"op": "grant", "reach": "write Plant.lastWatered"},
   {"op": "remove", "id": "old"},
   {"op": "move", "id": "list", "place": "widget", "index": 0}]}
```

- `say` is the receipt line, with no full stop at the end.
- `id` is the part's stable id in the room (its object title), so later sentences can name it.
- Plan in prose, then patch: the job's instructions let the model think in plain words before the tool call. Strict formats hurt reasoning, so only the call itself is constrained.
- Context the job sends: the sentence, the room's current parts (kind, place, props, bind; no object values), the kit description generated from code (section 3), the class catalog (names, fields, kinds), what he last touched within 30 s, and the LookCatalog traits. Everything may go to Claude except the key (his Oct 27 11:59 AM rule).
- Demo mode stays no-Claude: there, the four board sentences map to canned patches so the room still demonstrates.
- Model rung: Core's call under the harness's ladder. It is a small structured task, so it starts at the smallest rung that passes the eval below.

## 3. The kit for R1 (Builder A draws, Core validates)

Twelve parts. Each maps to a shell `Place` and draws through `ThemeConcept`, `MotionPolicy` and the existing type scale, so a room built by talking looks like the rest of the app.

| Kind | Places | Props | Draws as |
|---|---|---|---|
| `title` | title | text, color role | the 40 pt room title |
| `line` | switcher, caption | text with `{count}`, `{top}` and field tokens | the 26 pt light sentence, or the one-line caption |
| `lines` | needs, caption | up to 2 texts | the existing `lines` payload |
| `number` | keystone, widget | value from bind, unit, label | Outfit numeral; unit at half size, min 10 pt |
| `row` | keystone, widget | from bind: big, small, sort, max 4 | a ranked row of numerals over names (sheet 357 keystone) |
| `list` | widget, page | from bind: big field, small field, sort, max rows | the existing list payload, ranked weights |
| `stack` | keystone, widget | child part ids, axis, gap step (density trait) | layout only |
| `grid` | keystone, widget | child part ids, columns 2 to 4 | layout only |
| `glyph` | glyph | SF Symbol name from a vetted list, color role | the existing glyph place |
| `doors` | dial, doorSummary | door names, each with a bind | the existing dial and door summary |
| `actionWord` | actionWord | verb, object text, does (a single field write) | the existing action word and hold |
| `top` | (a modifier on `row` or `list`) | field to rank by | highlights the top item in wine and breathes it slowly (Reduce Motion: still) |

`top` is R1's single built-in reaction. General reactions (facts and wishes) wait for R3.

## 4. The validator: `RoomPatchValidator` (Core, pure engine code, runs inside `apply`)

Each rejection returns one plain reason line. The first rejection goes back to the model for one retry; a second is shown to him.

- Kinds and places: the kind is in the kit and allowed in that place; at most one part owns a single-occupant place (title, glyph, actionWord); at most 24 parts per room.
- Props: keys known for the kind; text at most 80 characters per line; a trailing full stop is stripped from any shown line; sentence case kept; key-shaped text refused (the same check as `TessRouter`).
- Look: color roles only (never hex); type sizes only from the scale; trait values only from `LookCatalog`; no new color within ΔE 10 of Ember; 3 to 4 colors per room (count the roles in use).
- Room color (added with sheet 365): the room's own color sits ΔE76 20 or more from every other room's color in both themes, because rooms sit side by side in Bridge's apps dial. Teal fails (6.8 from the Purse's 2A7878), so "Make it teal" gets the refusal with an offer: "Teal is the Purse's. Olive, like the leaves?" Olive (5E6B1F / B5BE7A, the Lists color the Log freed) and slate pass.
- Binds: the class exists; fields exist and have the right kind; private objects show as "Private" (the existing `ObjectPrivacy` check).
- Reach: the room starts with read access to classes it binds. Any write (`actionWord.does` or `grant`) adds a grant. A patch that widens reach is applied pending and needs his Allow (section 5). It never commits on the drying line alone. Money classes (`pool`, `inflow`, `poolMove`, `spend`, `rateNote`) can never be written by a room; such a grant is refused with "Rooms can't change money". Health and body classes may be read and shown on his phone, but they never reach widgets, backups or logs (the existing walls).
- Undo grants: undoing the patch removes its grant in the same op group.

## 5. The ghost, the drying line and Allow (Builder A, look from sheet 357)

- Blank room: every place is drawn as a dashed outline at its exact shell frame, inset 2 pt, with its name in 11 pt ink 2 at the top left. Layout mode's place map is the source of the frames.
- While Tess works, what he said shows in the widget place in Newsreader italic 20 pt, ink 2, in quotes.
- A pending patch renders its parts at 38% ink, and the labels of the places it fills hide. A 1 pt line in the room color runs along the foot of each filled place over 2 s (linear), then the group commits, the parts go to full ink, the outline lets go, and the receipt shows `say` with Undo (10 s).
- A widening patch shows its wine line ("This room can now mark plants watered") with Allow, and it waits. Undo on the receipt reverts the patch and the grant together.
- Reduce Motion: the drying line is drawn whole, nothing breathes, and the 2 s wait still applies.
- Haptics: one light tick when a ghost sets, nothing on each part.
- Rules that still apply: no cards, pills, bars, rings, dots or decorative underlines; no overlap; no word cut by a box; no full stop at the end of a shown line.

## 6. Where it lives (Builder A)

- A new room, "Chart room", in the apps list and dial after Purse, in slate. Feature flag `chartRoom`, group Everywhere, ships On (the defaults-on rule).
- Once he names it, the dial row carries the room's `name` and `color`, and the fact line on the right is the room's own top fact, read live from its `line` part ("Orchid, 6 days"). The dial keeps showing the old name until he turns to that row; there, once, the old name lifts off and the new one rises in (sheet 365). Reduce Motion: the new name, no move.
- It needs "Tess asks Claude" for free sentences; with that Off, or in Demo, it uses the canned patches.
- One Chart room in R1. "Make another room" comes later.
- The player is a `RoomContent` (`DocumentRoom`) that answers `screen(for:state:)` from the room's parts, so the shell, its moves and back all work unchanged. Parts that fit an existing `SlotPayload` use it. Free compositions in the keystone and widget use one new `SlotKind.parts` with a recursive `PartNode` enum in a `@ViewBuilder` (no `AnyView`), and `ForEach` keyed by part id, so edits animate instead of remounting.

## 7. Tests and proof

- Core: a validator table test (one case per rule above); op-group round trips (patch, undo, redo) leave the store identical; pending commits after 2 s and discards on dismiss; money grants are refused; widening waits for Allow; key-shaped text is refused; an eval of 20 sentences (the board's four, plus 16 more covering colors, order, density, doors and an action word) where every result passes the validator and matches the expected patch shape.
- Builder A: blank and after four sentences, in light and dark and at the largest Dynamic Type; no overlap and no cut words (the existing layout checks); a recording of a ghost setting, of Allow, and of an undo.
- `scripts/test.sh` green before each PR. Small changes may ship without the full run (his Oct 26 rule), but R1 is not small.

## 8. Order, so neither side waits

1. Core: classes, ops and the validator, with tests, on a fixture room. The fixture JSON doubles as Builder A's test data.
2. Builder A, in parallel: the player against the fixture (blank frame, all twelve parts, ghost, drying line, Allow), behind `chartRoom`.
3. Core: `patchRoom` in `TessTools`, the job, the demo canned patches and the eval.
4. Join: wire the job to the room and run the four board sentences end to end on the simulator, then the install list says what is in it and what isn't built yet (his Oct 26 rule).
