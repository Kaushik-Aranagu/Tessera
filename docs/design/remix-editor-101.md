# 101. The Remix editor, the code view and your own app tiles on Home

**Ask (Product, huddle batch 9, Oct 19):** "Remix editor and code view for classes; your own app tiles on Home." M3 deferred it for Design (`ship-list-m3.md` line 22; `object-model.md` section 2 "users build classes visually, but there is also a code view"). No Settings switch: these are new screens, reached from a class page. Spec only; nothing ships until Core's schema ops (A1 in `ship-list-build.md`) and Builder B take it. Not yet okayed by Kaushik. Extends `ghost-class.md` (the page IS the editor), `no-buttons.md` (ink-word actions), 75 (every screen has a side), 90 (six rows a page), 99 (one `read` size, three sizes a screen).

## The idea in one line
A class is edited on its own page, in place, as ghost ink. There is no form. The same class can also be read and written as a few lines of code, and the two always show one truth. A class you have made can sit on Home as a tile that is only a line, never a card.

## A. Entering Remix
- On any class page the hero name is a held word: **Remix** is its method (object-model section 1, Methods). Hold the hero, or say "change Plants" to Tess. System classes (Exercise, Note) open Remix as a copy-on-edit: the first change makes your own subclass and says so in one line, "Your Plants, from Plant." The system class is never altered.
- The page does not navigate. The class page turns wet cobalt top-down (the ghost style, 380 ms; 150 ms crossfade under Reduce Motion), because nothing you change is real until you say Keep.

## B. The editor is the page (visual)
Same layout as the class page, five blocks, at most 3 sizes (56 name, 21 rows, 16 labels):
1. **Breadcrumb**, `THING / PLANT`. Tap the parent word to choose another parent from the class names in a sheet-less list in place; inherited fields show faint with a 16 word "from Thing".
2. **Hero name.** Tap to rename in the writing line. Plural stays derived.
3. **WHAT A PLANT HAS**: one row per field, 21, 40 pt apart: name in 600, a dot, the kind word. Tap the kind word to cycle (text, number, date, choice, link and the rest of FieldKind); choice shows its options as a second line only on the row you touched. Swipe left drops a field (retired, never deleted: history keeps its values, the line says "Kept in old entries"). A drag handle does not exist: hold a row and move it, with one light haptic at pickup and one at drop.
4. **HOW IT SHOWS**: the starter view, one row: layout as an ink word (list, board, calendar, gallery), group by, sort by. Tap steps the word.
5. **WHAT IT DOES**: methods and rules, read only in v1 ("Water plants every 7 days" from Chore). Shown so nothing is hidden; edited by speaking to Tess.
- **Add a field** is a last faint row, "A new thing it has", that takes a typed or spoken name and defaults the kind from the name ("rating" reuses the catalog shape, add-a-field rule).
- **Keep** and **Not now** are two ink words at the bottom, no pill. Keep applies one op group (class, fields, view) in the op log; Tess says "Plants updated." with Undo that removes the whole group. Not now discards the wet page. Leaving the page by a swipe back asks nothing and keeps nothing.
- **Preview of the change.** A line above Keep counts what the change touches in plain words: "12 plants keep their values. 1 field is hidden." Never reads any object's words.

## C. The code view
- **Entry:** the side swipe of the Remix page (sheet 75): the page's side is **AS CODE**. Swipe left reveals it; the page and the code turn together, one truth.
- **Reads like the sketch in the object model:** one block in Inter Tight at 16 with tabular figures, one line per field, indentation by two spaces. Ruled by Product (Oct 19, final): no monospaced face; alignment comes from tabular figures and fixed two-space steps.
```
class Plant: Thing {
  species: Text
  location: Choice(kitchen, bedroom, balcony)
  got: Date
}
view Plants: list, group by location
```
- Editing: the block is directly editable; every keystroke re-parses. A line that does not parse gets a 16 `inkSecondary` note under it in plain words ("location needs options in brackets"), the page side keeps the last good version, and Keep is disabled by saying why, not by greying silently. Pasting from outside is allowed; nothing is sent anywhere.
- No syntax colour except the area colour at 72% on the class name and Tess cobalt on a line Tess changed. Dynamic Type applies; at AX1 and up long lines wrap with a hanging indent, never scroll sideways.
- Undo in the code view is the op log, not text undo: the same Undo word.
- VoiceOver reads the code view as the visual page does ("Field species, text"), and offers "Read as code" on the page rotor.

## D. Your own app tiles on Home
- **What a tile is:** a class you made (or remixed) can be put on Home with the hold method **Put on Home** on its page. It is **one line**, not a card or a box: the class name at 21 in `ink`, its one live value in `inkSecondary` ("Plants, 2 need water"), and a hairline under. It sits among the Home lines in the order of the Home queue rules, below the day's own lines.
- **The value** is one of: a count (objects), the next due object, or the last entry. The class page offers the three as a stepper row, "Home shows".
- **Tap** opens the class page; a vertical swipe on the tile turns the page like any Home row (sheet 90). Long-press reorders among tiles.
- **A tile never shouts:** no badge, no colour beyond the area colour on the name at 72%, no haptic until a real change (one soft haptic if its value changes while Home is open).
- **Limit:** four tiles; a fifth asks which to take off, in one line.
- **Privacy:** a class named with a Private word wall shows "Private class" at 100% ink and a value of only a count (matches inventory OL04, "Private class"). Its objects' titles never appear on Home.
- **Empty state:** nothing is on Home until he puts a class there; the class page offers it once, in Tess's line, never twice.

## States
| State | Look |
|---|---|
| Empty class (no fields yet) | Hero, breadcrumb, one faint row "Say what it has" and the mic hint; Keep is not shown |
| Long (14+ fields) | Fields group by parent ("from Thing" first, collapsed to a count), own fields open; six rows a page under sheet 90 |
| Working (Tess edits by voice) | The changed row paints in cobalt left to right, 420 ms, the rest holds still |
| Error (cannot keep) | One plain line in `ink` under Keep: the cause and the fix ("2 fields share a name"); one soft `.warning` only for a failed write |
| Private / masked | A class or field whose name is a Private word reads "Private class" or "Private field" at 100% ink; kind words still show |
| Reduce Motion / Low Power | 150 ms crossfade, no breath, no paint-in |
| AX1+ | Name above, kind below on its own line; side AS CODE becomes a row at the bottom of the page |
| Obsidian | Area colour at 72%, ghost cobalt as Tess's colour |

## Side (sheet 75)
The class page's side is **AS CODE** (above). The tile's side is **LATELY**: the last five entries as one 21 line each, row name first, no counts of words.

## Never
Pills, cards or boxes around a tile; a form; a field-type picker in a sheet; deleting a field that has values; editing a system class in place; sending the code or any object's words to Claude (Remix is on the phone; only Tess edits by voice go through the usual Tess route and walls from 80); an auto-Keep; italics; a faded Tess; a fourth size.

## For Builder B and Core
- Core: schema ops in the op log (A1) are the dependency; a Remix session is one pending op group, Keep commits it, Not now discards it. A parse error never partially applies.
- Builder B: the editor is the class page in an edit state, not a new screen file; the code view is a second renderer of the same `ClassDef`. Tile is a Home line type with the one-line layout above. Default: no tile exists on a phone until he adds one, so nothing on Home changes at ship.
- Rulings from Product (Oct 19, final): code view stays Inter Tight with tabular figures; Put on Home capped at four tiles; "On Home as one line" defaults to off.
