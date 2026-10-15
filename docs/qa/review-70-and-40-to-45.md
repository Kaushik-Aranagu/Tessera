# QA review: Core's hotfix #70, and the earlier merges #40 to #45

*Repo maintainer, 2026-10-15. This was a static read of master after #70 (8f1b274), with no Swift toolchain, so nothing was compiled or run. Core owns everything here except G1 and G2.*

## Hotfix #70: status of earlier findings

**Fixed (traced through the new code):** K1, K3, K4, K5, K7, K8, K9, K10, K11, K12, T1 to T6, and kitchen-acceptance Fixes 1 and 3 to 6. All 16 rows of the grammar-trace regression table now behave, except `80x8, 80x8, 80x6` (see H5).

**Still open:**
- **K2, partly fixed.** `bench 80x8, 82.5x6` (phrase row 12) and `80x8, 80x8, 80x6` are no longer groceries, but they aren't sets either. They return nothing. See H5.
- **K6, partly fixed.** `2 garlic cloves` makes an ingredient "Garlic cloves" (key "garlic clove"). It doesn't merge with `3 cloves garlic` (name "garlic"), and it lands in Other instead of Produce.
  - **Fix:** treat a trailing unit word ("cloves", "sprigs", "slices") as the unit, so both lines read as garlic.
- **G1 and G2 (iOS build), not fixed.** `Features/Home/TrainingPage.swift:115-119` still says "ready for 20" for the empty bar. Use the same first-time test that `Prefill.swift:51-52` now uses. `GroceriesView.swift:126-127` still clears the draft when the add fails.

## New bugs from #70

- **H1 (medium): comma lists and "get" now drop any item the app doesn't know.** `TessGrammar+Kitchen.swift:50-55` and `:44`, through `looksLikeGroceries` (`:62-69`)
  - **Failure:** on a fresh store, `milk, coffee, tea`, `eggs, bread, toothpaste` and `get coffee` all return nothing ("Didn't catch that"). Coffee, tea and toothpaste have no amount, aren't in the aisle guide and aren't saved ingredients, and the rule requires every item to pass. Before #70 they were groceries.
  - **Fix:** reject only on positive non-grocery signals (a set pattern, a leading task verb, a date). Or accept the list when at least one item looks like groceries and none looks like a set or a task.
- **H2 (low to medium): `buy sun cream` becomes a Sunday task "Buy cream".**
  - **Where:** `TessGrammar+Kitchen.swift:21-22` and `:39`, with the weekday table at `TessGrammar.swift:257-259`.
  - **Failure:** "sun" reads as Sunday, so the buy rule is skipped.
  - **Fix:** for buy/get, only count a short weekday ("sun", "sat", "wed", "mon") as a date when it's the last word or is followed by a time.
- **H3 (low to medium): whole-word recipe matching misses hyphens and singulars.** `TessGrammar+Kitchen.swift:117-120`
  - **Failure:** `cook stir-fry` doesn't find "Chicken and broccoli stir-fry", because the title is split on non-letters but the query only on spaces. It becomes a task "Cook stir-fry". `cook pancake` doesn't find "Protein pancakes".
  - **Fix:** split the query the same way as the title, and compare singular keys.
- **H4 (low): a dough or meat "rest" timer is read as seconds.** `TessGrammar+Kitchen.swift:79`
  - **Failure:** `dough rest timer 60` starts a 1-minute timer. `contains("rest")` also matches "forest" and "interest".
  - **Fix:** use seconds only when the label is exactly "rest" or "plank".
- **H5 (medium): comma-separated sets return nothing, and the test and comment overclaim.** `TessGrammar.swift:60`, `KitchenHotfixTests.swift:46`
  - **Failure:** `bench 80x8, 82.5x6` and `80x8, 80x8, 80x6` return nothing. The comment says the first "stays a lift". The test only checks that it isn't groceries.
  - **Fix:** split comma phrases into one set each in `parseLift`, carrying the exercise forward, and assert `.lift`.
- **Weak tests:**
  - `KitchenHotfixTests.swift:89` (Fix 6) never checks the time.
  - `GrammarTraceTests:205-212` only asserts "not kitchen", so a row that silently returns nothing still passes. Assert the intended parse.
- **Behaviour change, not a bug:** ingredients are now titled as typed, so a grocery item shows whichever name came first. A typed "eggs" followed by a recipe's "1 egg" shows "eggs 1". The Kitchen lead's Groceries fix 2 (pluralise on display) still applies.

## Earlier merges #40 to #45 (Notes, note capture, day load, Review)

- **N1 (high): opening a note and leaving it rewrites the note and moves it to the top.** `Features/Notes/NoteEditor.swift:99-131`, with `split`/`join` at `:145-158`
  - **What's wrong:** `join` trims the heading and the leading newlines of the rest, and `save()` runs on disappear and compares against the stored body.
  - **Failure:** for a note like `Garage gym\n\nRubber floor…`, or one whose first line ends in a space, open it and go back without typing. The blank line is dropped, `updatedAt` becomes now, the note jumps to the top as "Edited just now", and a junk op lands in the log.
  - **Fix:** remember the joined text at load and save only when it changes from that, or make `split` and `join` exact inverses.
- **N2 (medium): "Delete note" promises an Undo that doesn't exist.** `Features/Notes/NoteEditor.swift:83`, `:135-139`
  - **What's wrong:** the hint says "Undo brings it back", but nothing in the app undoes a user's `DeleteObject`. The only undo surfaces are Tess's last capture and the last set.
  - **Fix:** keep the delete's op and show an Undo toast in the notes index that calls `engine.undo`, or change the copy.
- **N3 (high): an @mention doesn't link when the name contains "&".** `TesseraCore/Sources/TesseraCore/Notes/Notes.swift:58-60`
  - **What's wrong:** each word is stripped of punctuation, so "&" becomes empty and the candidate gets a double space.
  - **Failure:** `@Mac & Cheese was great` never links the recipe "Mac & Cheese". Only `@[Mac & Cheese]` works.
  - **Fix:** strip punctuation from the joined candidate's edges, not from each word.
- **N4 (medium): resolving a mention can create an object outside the op log.** `Notes.swift:36-37`, called from `Transaction.linkMentions` (`:141-143`)
  - **What's wrong:** `resolve` calls `store.ensureClassObject` directly.
  - **Failure:** `note: @Workout felt long` on a store with no Workout class object inserts one without a logged create. Discarding the ghost or undoing the note leaves that object behind, and the log's `setLinks` points at an id it never created.
  - **Fix:** create the class object through the transaction, or only link to class objects that already exist.

**Checked and fine:** note capture runs before the kitchen rules ("note: buy milk" stays a note). The Review week's window, de-duplication and midnight and DST handling look right. `DayLoad.load` has no callers in the app yet, so its edge cases aren't visible.
