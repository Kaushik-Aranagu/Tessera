# Living elements: every place can be reshaped, by his hand or by Tess

Kaushik, Oct 26: "everything about the UI is changeable or can be modified. Like it has life ... if I don't like
certain UI element, like how a list is being shown, like how a dial is being shown, it should be customizable. And
the way it should expose that ... should be co-built for AI to work ... a seamless connection between the two ... how
UI can be controlled by AI itself."

This extends the element contract (`elements.md`, PR #1434). Every place already says what it shows and what can be
done to it; now it also says **how it is drawn and how it could be**, and that look is an object he owns. Code:
`TesseraCore/Elements/ElementForms.swift` and `ElementLooks.swift` (the engine side), and
`TesseraTess/Harness/Elements/ElementLookTools.swift` (Tess's side). Tests: `ElementLooksTests.swift`.

## 1. The idea: shape, form, traits

A room already answers "what goes in each place". It now answers in two halves:

- **Shape.** This is what the content is, whatever draws it: `one` thing, a `few` ranked things, `many` rows,
  `words` with weight, `doors`, a `measure` over time, or `lines` of text. The room decides the shape from its
  facts.
- **Form.** This is how the shape is drawn: a rise, a stack, rows, a wall, a reel, an index, a ledger, a trace, or a
  room's own keystone material. The **studio** draws each form once. A room names its designed form, and he or Tess
  may swap it for any other form that can draw the same shape in that place.
- **Traits.** These are the qualities a form lets him tune, as words: density, facts, order, count, weight, shows,
  plus size and motion on every form.

The room's data never changes when a look changes. A reshape is a different drawing of the same content, so it can
never lose or hide a thing.

## 2. The forms (the studio's, nothing else)

| Form | Draws | Places | Own traits |
|---|---|---|---|
| rise | one, few | widget | facts |
| stack | few, many | widget, page | facts, count |
| rows | few, many | page, widget | density, facts, order |
| wall | words, many, few | keystone, page | density, weight |
| reel | doors | dial | none |
| index | doors | dial | density |
| ledger | many, measure | page, widget | density, order |
| trace | measure | widget, page, glyph | none |
| type | lines, one | needs, caption, door summary, title | count |
| mosaic, chalk, tickets, woods, sky, chart | the keystone materials | keystone, in their own room only | chalk: shows; tickets: count |

Every form also takes **size** (smaller, designed, bigger, always from the room's own type scale and never below the
floor) and **motion** (still, calm, designed). Motion never goes past what the studio drew, and Reduce Motion still
wins. "still" is the same switch as `LiveSwitch.dataOnly` (`docs/design/live-visibility.md`): the place draws from its
data with no clock.

**Walls, by construction:**
- Only forms in `ElementForms.all` exist, so a reshape can't make a card, pill, bar or ring.
- There is no colour trait. Colour stays the room's palette (3 or 4 per page, nothing near Ember), and money is never
  red or green.
- A keystone's material stays in its room: the Deck can't take the Galley's tickets.
- The keystone slot stays 354 by 182 pt.

New forms come from the Design studio and join this table.

## 3. A look is an object

`elementLook` is a system class, with one row per **scope**:

| Scope | Example | Row |
|---|---|---|
| A place in every room | "every dial as an index" | room empty, level empty |
| A place at one level, every room | (rare) | room empty, level set |
| A room's place | "the Deck's dial calmer" | room set, level empty |
| A room's place at one level | his hand on the landing only | room and level set |

The most specific row wins, in that order. A row with no form leaves the form as it was, and traits merge from the
general rows to the specific ones. A stored form that can't draw today's content (the shape changed) is passed over,
never forced (`ElementLooks.look`).

Writes go only through `setElementLook` and `restoreElementLook`, so his hand and Tess both get the op log, the ghost
row and the 10 s Undo. Restoring empties the row and deletes nothing, so a look is history he can browse like any
object ("Deck dial").

**The four places (for Core):**

| Class | SystemCatalog | Ops and ActionRegistry | Copies | ObjectPrivacy |
|---|---|---|---|---|
| `elementLook` | key and spec | `setElementLook` and `restoreElementLook` in `descriptors` and the decoders, not offered to the model (Tess has her own tools); Day log drops them; in-app only for Intents | Copied, like a setting: nothing private in a room, place and form name | None |

## 4. Tess

**What she sees.** `ElementMeaning.look` (`LookInfo`) says what the place is drawn as, every form it could be, and each
trait's word. When the ask is about looks (`LookWords.isAbout`), the frame adds one line per shown place:
`Look of dial: drawn as reel; could be index; motion designed, size designed.` Other asks don't carry these lines.

**Bound, no model.** A short nudge on the place he means runs at once (`ToolPicker.lookBound`):
- The forms: "the dial as an index", "every dial as an index", "one at a time".
- The traits: "denser", "airier", "bigger", "smaller", "calmer", "stop moving", "more detail", "just names", "show
  more".
- The studio's look back: "as it was", "as drawn", "the old look".

The place is the one he names ("the dial", "the board", "the list"), else the one he touched in the last 30 s, else
"this". "Every", "everywhere" or "all rooms" sets every room. It binds only when a place is named, the ask is 3 words
or fewer, or it says "make it" or "make the". So "log a bigger set" is not a look.

**Open asks.** "I don't like this dial", or "the Deck feels busy": no binding. The model gets `reshape` and
`restoreLook` first, plus the look lines. She tries one look as a pending change and says what she did and what Undo
brings back ("Try this: the doors as a column. Undo puts the reel back."). She proposes from the place's own list,
never a form it can't take.

**Never unasked.** She doesn't reshape anything he didn't talk about. A look he keeps past the Undo window may become a
`prefers` belief through `remember`, with the look row as evidence (for example "You like dense rows"). She may then
offer the same look in another room as a notice with a one-tap fix, never apply it.

**Purse.** Its look calls are `deviceOnly`, like every Purse call. A nudge there runs bound or on the phone's own model.

**Room agents.** An agent may suggest a look for its own room only (its scope).

## 5. Only what he can see

From the live-visibility spec (`docs/design/live-visibility.md`, compatibility section):

- `ElementMeaning.isShown` is fed from the same `liveScope` the shell sets, not from what is resident.
- "This" (`TessFrame.referent`) and a look's target only consider shown places.
- A call on a place he can't see writes the data and starts the Undo clock now. `TessFrame.reaction(of:on:)` is nil,
  so the shell skips the move and the place arrives changed. If it comes into view inside the window, it shows the
  end state with Tess's blue drying, not the whole move.

## 6. How a place takes a new look (Builders A and B, Design)

**The shell (Builder A):**
1. `PlaceHost` asks `ElementLooks.look(scope, shape:, designed:)` for its slot and draws `look.form` with
   `look.traits`.
2. Each form name maps to one view. The traits map to theme tokens: density to spacing steps, size to type steps,
   motion to `MotionPolicy` (still means no clock).
3. A new form is a "different kind" change by sheet 283's diff rules: the old form collapses to a point (a keystone
   dissolves with blur) and the new one forms from it. A trait change eases in place.
4. Reaction `.reshape` plays when the ghost row lands, if the place is shown.

**The rooms (Builders A and B):**
- Each `RoomContent` gives each place its shape and designed form.
- It fills `meaning.look` with `LookInfo.make(...)` and `meaning.isShown` from the live scope.
- The content payload stays as it is. A form reads whatever payload fits its shape.

**His hand (Design studio to draw it).** A proposal:
- Press and hold a place and it loosens.
- A horizontal swipe flips through its forms in place, drawn from his live data. The glass lens sits only under the
  finger, as on every horizontal swipe.
- The trait words sit under it in the room's own type: tap a word to step it.
- Letting go keeps the look with the 10 s Undo. Tess's line says what changed and how to get it back.
- No settings sheet, no cards.

## 7. Next

- The Design studio draws each form's alternates per place and the loosen gesture. The table in section 2 grows with
  them.
- Live rules: a trait whose value is a `Formula` over the item ("bigger when it's due within the hour"), so a place
  reacts to his data on its own. This is the "alive" half beyond reshaping.
- The test world: look asks ("make the list denser", "I don't like this dial") scored on whether the right place
  changed and nothing else did.
