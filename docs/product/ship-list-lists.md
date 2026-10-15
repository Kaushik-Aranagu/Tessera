# Lists ship list (engine-first)

*Kitchen lead (Lists after Kitchen), 2026-10-15 18:40. Same rules as `ship-list-kitchen.md`: small end-to-end slices, velocity over perfection. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/<Area>/` folder that meets the UI bar. Supersedes kitchen slice 15 ("Lists app v0").*

**The idea in one line.** A list is the simplest app you can build out of blocks: items you can check, each one able to open into a paragraph, a date or a link, and the whole list able to run on Now. It is the kitchen `List` block (`TesseraCore/Sources/TesseraCore/Lists/`), so groceries, packing, books to read and M3's List template are all one class.

**Progressive disclosure rule.** A list opens as names and nothing else. Sections, notes on items, dates, "reusable", "run it" and "pick one" are options you turn on per list (or that appear once you've used them), never chrome that every list carries.

## Slices

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **List housekeeping** | Undoable: rename a list, archive it (and bring it back), delete one item, edit an item's text or quantity, uncheck everything. `ListContents` gives a progress count ("3 of 7") and lists by last touched. Reuses `RenameObject` and `DeleteObject` where they fit | Engine |
| 2 | **Items open into a paragraph** | An item can carry a `note` (plain text with @links, read by the same code as Notes), an optional date, and links. An item with a note or date shows a marker; the item itself is a linkable object, so it has backlinks | Engine |
| 3 | **Lists from text** | Paste lines and get a list: each line an item, "Heading:" or "# Heading" lines become sections, leading bullets, numbers and "[ ]" / "[x]" are read (checked ones come in done). Also `AddListItems(list, lines)` for many at once | Engine |
| 4 | **Reusable lists** | A list flagged reusable (packing, gym bag, leaving the house) never loses items: "clear done" becomes "reset", which unchecks everything. The flag is an option on the list, off by default | Engine |
| 5 | **Run a list on Now** | Generalise `StartShop` to `StartListRun(list)`: any list can be the running process ("Packing, 6 left"), suspend into the ledger, and finish (clear done, or reset if reusable). Groceries' shop becomes this with aisle order | Engine |
| 6 | **Dated items reach Today** | An item with a date appears in Today's list through `TaskList` (as a linked item, not a copy); finishing it there checks it on its list and the other way round | Engine |
| 7 | **Pick one** | `ListContents.pick(from:)` chooses one open item, weighted away from what was picked recently (stores `pickedAt`). For "what to watch", "what to cook", "which chore first" | Engine |
| 8 | **List phrases** | Ghost row: "packing: charger, socks" or "add charger to packing" adds to a named list; "pack" / "run packing" starts a run; "pick from films" picks one; "reset packing". Kitchen phrases keep priority for groceries | Engine |
| 9 | **Lists shelf** | The Lists app front page, see design steer | Feature screen `Features/Lists/` |
| 10 | **A list page** | One list, see design steer | Feature screen `Features/Lists/` |
| 11 | **An item, opened** | z into an item: its paragraph, date and links | Feature screen `Features/Lists/` |
| 12 | **Pick one moment** | The living moment for slice 7 | Feature screen `Features/Lists/` |

Build order: 1 → 3 → 2 → 4 → 5 → 7 → 6 → 8; screens 9 and 10 after 1 and 3, 11 after 2, 12 after 7.

## Design steers

Shared: light ground, the house paper and washes; lists lean lilac and sky (the planning colour). Vermilion only for a running list, cobalt only for Tess. Same instrument as Groceries: tap strikes and sinks, no checkboxes, no row separators.

**9. Lists shelf.** Not a grid of cards: list names as a typographic column, mixed sizes by how recently you touched them (the one you're living in is largest). Under each name, in Label tier, its state as a word: "3 OF 7", "RUNNING", "REUSABLE". Archived lists don't appear; a single word at the bottom ("Archived") zooms into them. New list is the ghost row ("list: films"), or paste a block of lines anywhere on the page and it becomes a list (slice 3), with Tess saying "Twelve things, two sections."

**10. A list page.** The hero is the list name. One context line: "3 of 7" or "Packing, running". Items at Body 21 hang from the left; sections, when used, are Title-tier margin words like Groceries' aisles. Checked items sink into a fold that reads "4 done" (or, on a reusable list, the fold is the "reset" key: hold to uncheck all, paint drains back out). The list's options open by tapping the context line, which unfolds in place into words, not toggles or a sheet: **Sections**, **Reusable**, **Run it**, **Pick one**, **Archive** (Design's build sheet `docs/design/kitchen/lists-9-12.md` has the values). Once you've used one it stays visible as a single word under the context line, so a list grows its own features as you use it. Lists are x siblings of each other (swipe between them, the hero parallaxes); the page is one screen tall, with the items in a bounded vertical window that fades at the bottom.

**11. An item, opened.** Zoom from the item: the item text becomes the hero, and below it the paragraph at Body size, editable in place, @links in cobalt. The date, if any, is a line in words ("Thursday"), tapped to open a day lane of day words in place. Backlinks sit at the bottom as names. No form fields; an empty item shows only a faint "Add a note" line.

**12. Pick one moment.** Hold the hero with "Pick one" on: the other names dim to 20% and one name lifts out of the column and grows to hero size in the centre, with the paint-dab bloom behind it (the soul's bloom, small) and a soft haptic. Tap it to open it; swipe it away for another pick. Reduce Motion: a cross-fade to the picked name.

## Depends on

- **M3 slice 10 (List template):** creates a slice 1 `List`; nothing in Lists waits for it.
- **M3 slice 3 (add a field):** later, lets a list grow its own column (a rating on Films). Not needed for this list.
- **M3 slice 4 (saved queries):** later, for smart lists ("every open item dated this week"). Deferred.
- From master: the kitchen List block, Notes' @link parsing, Process and the ledger, TaskList, the ghost row.

## Deferred

Smart lists from saved queries, nesting lists in lists, shared lists, reminders and notifications on dates, custom columns, sorting rules, and imports from Apple Reminders.

## Defaults taken

Lists are flat with one level of sections. Checked items stay until "clear done" (or "reset" on a reusable list). An item's paragraph is plain text with @links, like Notes. A dated item joins Today but stays on its list. "Pick one" avoids anything picked in the last 7 days when it can. Groceries stays its own list with aisles; Lists never shows it on the shelf twice (it appears once, as "Groceries", opening the Groceries screen).
