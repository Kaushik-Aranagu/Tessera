# Lists acceptance checks

*Kitchen lead, 2026-10-15; screen checks follow Design's build sheet `docs/design/kitchen/lists-9-12.md` (c8a83ff as amended) and Design 65 `list-remove.md`; rows refreshed 2026-10-16. UNDO lengths: 4 s for a new capture, 10 s for a remove or a change (Product). One block per slice in `ship-list-lists.md`. A Lists PR passes when every check in its block holds; the Kitchen lead runs them against the merged code and recording and posts pass or a fix list. "Undo" means one `undo` restores the exact previous state, including order and `checkedAt`.*

## 1. List housekeeping (engine)
- Rename a list; undo restores the old name. Groceries can be renamed but keeps its fixed id.
- Put a list away (the engine's `archive`; the word on every screen is "put away", never "Archive"): it leaves `lists()` and appears in `archived()`; bring it back; undo works both ways, 10 s. Groceries cannot be put away (error, no op).
- Remove one item (`removeListItem`, the op behind the swipe and the phrase): undo within 10 s puts it back in the same position with its `checkedAt` as it was; a removed row never counts as checked.
- Edit an item's text and quantity; an empty text is refused.
- "Uncheck all" clears `isDone` and `checkedAt` on every item, one op, one undo.
- `progress(of:)` gives done and total ("3 of 7") and excludes nothing hidden.
- `lists()` can sort by last touched (any item change touches the list).

## 2. Items open into a paragraph (engine)
- Setting a note on an item with "@Bench Press" and "@[Push Day A]" creates links; Bench Press's backlinks show the item.
- Editing the note re-reads links (removed @ removes the link).
- Date set and cleared; undo restores.
- `Item` exposes `hasNote` and `date` so a row can show a marker without loading the note.

## 3. Lists from text (engine)
- This paste gives list "Trip" with sections "Clothes" and "Tech", 5 items, "passport" done:
  ```
  Trip
  Clothes:
  - socks
  - 2 t-shirts
  # Tech
  [ ] charger
  [x] passport
  1. adapter
  ```
- Quantities read as in groceries ("2 t-shirts" → quantity "2", text "t-shirts").
- `AddListItems(list, lines)` adds many in one op; undo removes all of them.
- A blank or whitespace-only paste is refused.
- The paste shows a change preview (items, sections, checked) before anything is written; dismissing it writes nothing.

## 4. Reusable lists (engine)
- The flag is off by default; turning it on is undoable.
- On a reusable list "clear done" unchecks instead of deleting; item count is unchanged.
- `CopyList(list, name:)` makes a new list with the same sections and items, all open, in one op; the original is untouched. Nothing in the API or copy says "template".
- Groceries can't be made reusable (it has recurring items later in Kitchen v2 instead).

## 5. Run a list on Now (engine)
- `StartListRun(packing)` makes Packing the running process; Now's line reads "Packing, 6 left" and drops as items are checked.
- Starting another process suspends it into the ledger with "Packing, 4 left".
- Finishing clears done items and ends the process; on a reusable list finishing does not reset, the reset is its own op behind the hold (or the ask on "done").
- `StartShop` and `FinishShop` still pass their existing tests, now on top of the run.

## 6. Dated items reach Today (engine)
- An open item dated today appears in `TaskList.today`, titled as the item, linked to it (no copied Task object).
- Checking it from Today checks it on its list, and the other way round, in one op.
- It rolls forward like a task (never "overdue"); clearing its date takes it off Today.

## 7. Pick one (engine)
- `pick(from:)` returns only open items and nil for an empty list.
- Given a fixed seed and three items, one of which was picked in the last 7 days, that one is never chosen while others exist.
- Accepting a pick (opening it) stamps `pickedAt`; a skip doesn't. Picking never checks the item. Undoable; it shows in "What Tess did" only if Tess did it.

## 8. List phrases (engine)
- The Lists rows (41-48) in `kitchen-phrases.md` pass.
- Rows 1-40 still pass (kitchen phrases keep priority for groceries).
- An unknown list name ("add charger to holiday") makes no list silently; Tess says "No list called holiday."

## 8b. The wall on list items (Core 0ai; Product 2:06 PM Oct 16)
- Adding an item by the ghost row, a phrase ("add charger to packing") or a paste runs PrivateFacts plus secret words before the title is written. A secret or a money-shaped line never becomes an item: it becomes a private note, receipt "Private note, kept.", and the list is unchanged.
- A price on an item is stripped and the item stays ("gift for mum $30" on Errands gives "gift for mum"), the same rule as Groceries section 6, so a list item never carries money.
- A paste runs the check per line; the ghost list's count and "Twelve things, two sections." count only the lines that landed, and the receipt adds "1 private note, kept." when any dropped out.
- Body and health lines ("ibuprofen 400 mg") on a list are items as typed (a packing list needs its meds); they are walled only from Claude, never from the list.

## 9. Lists shelf (screen)
- No cards or grid: list names in one typographic column, sizes by last touched, Label-tier state word under each ("3 OF 7", "RUNNING · 9 LEFT", "REUSABLE", "PICK ONE", "EMPTY"; "14 TO BUY" under Groceries).
- Groceries appears once and opens the Groceries screen.
- Put-away lists are behind one word at the bottom, "Put away".
- Pasting a block of lines on the page makes a ghost list with the state word "12 THINGS · 2 SECTIONS" and Tess's line in cobalt with UNDO for 4 s.
- Nothing under 16pt; Dynamic Type at AX sizes goes to one column with no clipping; recording committed.

## 10. A list page (screen)
- Hero is the list name; one context line; items at 21pt; tap strikes and sinks into "N done".
- Options open by tapping the context line, which unfolds in place into the option words (no sheet); tapping outside folds them back. A used option stays as a labels line under the hero ("REUSABLE · PICK ONE").
- Holding the hero does nothing unless Pick one is on (then it picks, see 12).
- Swiping between lists pages horizontally with the hero parallax; the page stays one screen tall with a bounded item window.
- A running list shows the lit vermilion seam at the top.
- The fold is pinned at the bottom: tap to open and restore, hold 0.7 s to clear done. On a reusable list it reads "N done. Hold to reset." (no dot between) and the strikes un-paint right to left while held.

## 11. An item, opened (screen)
- Zoom transition from the item row; the back word returns.
- Note editable in place; @links in cobalt and tappable.
- Date in words; tapping it opens a day lane of day words in place (x scroll with snap), not a picker. No date shows "Add a day" at 40%. Backlinks as names under "LINKED FROM".
- Swiping right on the hero strikes the item and zooms back to the list.
- An empty item shows only a faint "Add a note" line; no form fields.

## 12. Pick one moment (screen)
- Only with Pick one on: hold the hero 0.6 s (paint fills its underline). Others dim to 14% with a 2 pt blur; one name lifts with matched geometry and grows to hero at the centre in about 520 ms, with the small bloom and a medium haptic.
- Tap opens the item; swipe left sends it back into its row and picks again.
- Reduce Motion: a cross-fade only. Recording committed.
