# Sheet 286: living looks, and coming back into view (Oct 26)

Kaushik, 12:33 PM PDT: "there is an option for any UI element to be alive, or like can be reactive and can be
modified... if I don't like... how a list is being shown, like how a dial is being shown, it should be
customizable... co-built for AI." And: "UI part should only work when the user is actually seeing that part of the
screen... otherwise we should only update the data layer."

> Updated by sheet 287 (`transitions-287.md`): the looks now use #1449's names (forms and traits). The Column look
> is now the **index** form, and the gesture is holding the Nav word, not swiping inside a pane in Layout mode.

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp. The third row of buttons has the Deck's door looks, Tess
changing a look, and "leave, change, come back" on the Galley. This sheet builds on the shell contract
(`shell-contract-283.md`), the element contract (`docs/ai/harness/elements.md`, #1434), Tess's hand (sheet 285)
and `docs/design/live-visibility.md` (branch claude/project-thread-xhv9sw).

## 1. A look is how a place shows its meaning

- **What a look may change:** only how the place draws. It must keep the place's frame, its items, its focus and
  its calls. So Tess's frame (`ElementMeaning`) is the same in every look, and the tool picker never needs to know
  the look.
- **Where looks are kept:** per room, per place. A look can be set for one room or for every room.
- **Who sets them:** looks are settings, not his data. Changing one writes nothing to his notes, workouts or money,
  and a change by Tess is a shell call (`setLook`), never a tool.
- **What a look may not change:** the look rules hold in every look. That means no cards, pills, bars, rings,
  middle dots, filled dots or decorative underlines; 3 to 4 colours; the biggest words never share a colour; money
  is always "about".
- **Keystones are the exception:** each room's keystone is its identity, so it has no alternative looks. It only
  has a **Quiet** setting, with the same picture, fewer moving parts and no idle motion.

## 2. The looks, place by place

| Place | Looks (the first is the default) | Notes |
|---|---|---|
| Switcher | **Words across** (today), **Roll word** in the sentence | Roll word is the board's three-place roll, kept inside the 26 pt sentence. |
| Needs | **Two lines** (today), **One line**, **Count** ("3 things", Outfit) | Count only where the room has a count. |
| Widget | **One thing** (today), **One and next** (the next item as a 15 pt line under the small line), **Quiet** (Big line only) | The Glyph stays in every look except Quiet, which hides it. |
| Glyph | **Drawn** (today), **None** | None frees the widget's right column for the Big line. |
| Doors (dial) | **Reel** (today), **Column**, **Sentence** | Built on the board. See section 3. |
| Door summary | **Lines** (today), **One sentence**, **Numbers** | Numbers shows only the door's Outfit numbers with 13 pt labels. |
| Page (level 1 rows) | **Ranked** (today, weights 1.7 to 0.84), **Even**, **Two columns** (names only, the room colour on the first), **By time** (a 52 pt time column, then the rows) | By time is offered only where rows have times (Watch, Galley, Lookout, Deck). |
| Body (level 2) | One per kind (sheet 284). Each kind adds **Plain** (text lines, no drawing). | |
| Action word | **Word and line** (today), **Word only** | |
| Tess | **Soul** (today), **Still** (no idle motion) | |

## 3. How a look changes

- **The frame never moves.** Only what is inside it changes.
- **Shared things travel.** Anything both looks show, such as each door's name or a row's title, moves from where
  it was to where it goes. Position and size change together over 520 ms on a slight spring
  (cubic-bezier .2,.9,.25,1.04).
- **Everything else** fades out in 160 ms or fades in over 260 ms, starting at 260 ms. Nothing is cut.
- **By Tess:** sheet 285 applies. The wash comes first, then the swap. The Undo line reads "Tess showed the doors as
  an index  Undo" for 10 s. A look is not a material, so it carries no blue.
- **Keeping it everywhere:** the Undo line offers "Everywhere" as a second word only when Tess set the look in one
  room and the same look exists elsewhere.
- **Moving between rooms:** the place plays its look's own entrance. Only Reel spins. Column and Sentence words
  rise in order, 40 ms apart, from 420 ms in, while the old doors fade out with a little blur. The board now does
  this.
- **Reduce Motion:** a 150 ms crossfade, and nothing travels.
- **Where he changes a look himself:** in Layout mode. Tap a pane to select it, then swipe across inside the pane
  to try each look live in its own frame. Tap again to keep it, or tap the Nav word to leave it as it was. Layout
  mode already maps every place, so this adds no new screen. He can also ask Tess ("show the doors as a list").

## 4. Coming back into view

From live-visibility.md: while a place is not seen, only its data updates. The rule for what he sees when it comes
back:

> **Show now. Then play only what changed while he was away, once, after the room has settled (650 ms), within
> 600 ms. Never replay the missed motion.** With more than six changes, or after more than an hour away, just show
> now with the keystone's 0.94 settle.

| Keystone | Coming back |
|---|---|
| Bridge mosaic | It shows now. Only the tiles whose face changed flip, 40 ms apart, in reading order. |
| Log wall | New words set in, using the wall's arrival. Words that were removed are simply gone. |
| Lookout sky | It shows the sky for this minute, with no catch-up. Rain and wind start at their current strength. The hour that is now in the strip takes the room colour with no motion. |
| Deck board | New chalk writes in at twice the speed. Lines wiped while he was away are already gone. |
| Galley rail | New tickets hang with half the swing. Changed tickets reprint (the print-down clip in 7 steps). Built on the board. |
| Watch woods | It shows the grove as it is now. Each tree that grew plays one growth step only, never a time-lapse. |
| Purse index chart | Only the new piece of the line draws, from the last point he saw. |
| Widget, needs, summary, rows | They show now. If the shown item changed, the widget makes its own move once. Other lines change with no motion. |

Tess's changes while he is away (live-visibility.md, section "Compatibility"):
- If the Undo window is still open when he comes back, the change arrives already made but still in her blue, and
  the Undo line shows the time it has left. The flight and the wash never play.
- If the window has closed, the change has already dried into the room's ink.

## 5. Interface changes for builders and Core

- **SlotContent.look:**
  - Add `SlotContent.look: LookID`, read from `RoomLooks[room][place]`, which falls back to `Looks.everywhere[place]`
    and then to the default.
  - Each `PlaceHost` renders the same `ElementMeaning` through the look's view.
  - `LookCatalog.looks(for: Place) -> [LookDef]` (id, name, phrases), so Layout mode and Tess list the same looks.
- **Shell calls in `ElementCatalog`, on every place:**
  - `setLook(place, look, scope: room | everywhere)` and `showLooks(place)` (opens Layout mode on that pane).
  - Their phrases: "show the doors as a column", "make the list even", "quieter sky".
  - They need no model when bound: "as a column" names one look.
- **The swap move:**
  - `MotionPolicy.lookSwap` (520 ms spring, 160 out, 260 in at 260).
  - Shared things match by item id, using `matchedGeometryEffect` on `item.id` inside the place's namespace.
- **Coming back:**
  - `LiveRegion` keeps a `seenKey` per keystone: a small summary of what was drawn, such as ticket ids and texts,
    tile faces, or the chalk lines.
  - When `isLive` turns true, the keystone gets `onReturn(diff:)` instead of replaying, and plays at most six
    differences.
  - This sits on top of live-visibility.md's "next frame from current data". It does not change the gate.
- **Quiet:**
  - `LiveSwitch` gains `.quiet`: the region still draws on change, but it has no idle loop.
  - A keystone's Quiet setting and the "stop animating the sky" call both set it, so there is one switch.
- **Tess's frame:**
  - `ElementMeaning.isShown` (from live-visibility.md) also gates the referent.
  - A look change never changes `ElementMeaning`, so the existing tests stay valid. Add one test: the same screen in
    two looks gives the same frame.

## Open for the next round

- ~~Draw Column and Sentence for the Log's eight doors~~ Done in sheet 292 (`transitions-287.md`, "Many doors").
- ~~Draw the Page looks (Even, Two columns, By time) on one room.~~ Done in sheet 293 (`transitions-287.md`, "Page forms").
- ~~Draw the Layout mode swipe-through.~~ Done in sheet 308, below.

## Sheet 308: the swipe-through (Oct 26)

In shape mode (hold the Nav word, tap the doors), a swipe across the doors used to do nothing until the finger lifted,
then the look changed. Now the swipe shows where it is going before it gets there.

- **The doors follow the finger, held back.** They move a third of the finger's travel, easing out so they never go
  past 28 pt, and thin to 65% as they go. They stay inside their own pane of glass, so nothing is cut.
- **The foot says which look is coming.** The foot already lists Reel, Index and Sentence. As the finger moves, the
  next look's word warms from grey to the room's colour while the current one cools. It reaches full colour exactly
  at 40 pt, the point where letting go takes it, so the colour is the threshold and no marker is needed.
- **Letting go past 40 pt** takes the look: the doors settle back over 160 ms as the look's own change plays.
- **Letting go short of it** springs the doors home over 320 ms with a small overshoot, and the words cool back.
- The glass lens still rides under the finger. Nothing new is drawn on the glass.
- Reduce Motion: the doors do not move and the words do not warm; a swipe past 40 pt changes the look with the
  150 ms crossfade.
- Measured on the board (`t52.js`): Deck in paper and black, a 30 pt swipe that springs home, a 90 pt swipe that
  takes Index, and a swipe back to Reel. `t39.js` still finds no cut words.

For the builders: a `DragGesture` on the pane drives `@State var drag: CGFloat`. Doors: `.offset(x: pull(drag))`
with `pull` = `drag / 3`, soft-capped at 28 pt, and `.opacity(1 - 0.35 * u)`, where `u = clamp((|drag| - 8) / 32)`.
Foot words: tint the next look with `Theme.room.mix(with: .secondary, by: u)` and the current one with `1 - u`.
On end, either `withTesseraAnimation(.snap)` the look change, or `withTesseraAnimation(.springHome)` back to zero.

