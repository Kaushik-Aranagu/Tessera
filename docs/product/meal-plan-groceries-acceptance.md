# Meal plan feeds groceries: defaults and acceptance script

*Kitchen lead, 2026-10-15. This is Core's idle-time slice (board item 7, Research `next-areas.md` part 2, #2): "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task. Below are the product calls, so Core can build it without asking, followed by what I'll check. Product can overrule any line.*

## Defaults

| Question | Default | Why |
|---|---|---|
| When | **Changed 2026-10-16 (Design 47, `groceries-ai-acceptance.md`):** the moment the cook task is captured or its recipe set, for any date. The tidy pass only catches a recipe linked to a task later | He sees the rows land and can undo them; the Home count reminds him on the day |
| How much | The recipe's own serves, through `AddRecipeToGroceries(recipe:, serves: nil)`, with staples skipped as usual | It is the same path as the recipe page's swipe, so merging and shares already work |
| Only once | The task records `groceriesAddedAt` and is never added again, even if he clears the basket or removes the recipe by hand | If he takes it off, that was his choice |
| Linked | The share carries the task: the recipe dab's long-press reads "Carbonara, Thursday", not just "Carbonara" | He can see why an item appeared |
| Task moved to another day | If the recipe hasn't been added yet, the new date counts. If it has, it stays on the list | Moving dinner doesn't change what's in the fridge |
| Task deleted or undone | If the recipe was added, `RemoveRecipeFromGroceries` removes the open items that carry only this share, and checked items stay. If it wasn't added, nothing happens | Undo puts things back the way they were |
| Task done or cooked early | Nothing changes. Open items stay; he may still need them | |
| Already on the list from the recipe page | The share merges as it does today; there are no duplicate lines | |
| Tess | **Changed 2026-10-16:** "Added 2 for tacos." with UNDO for 10 s. No notification. Rows carry "for tacos" under them; no sage dab (`no-dots.md`) | Design 47 |

## Acceptance script

**Engine (`swift test`).** Times use the app clock.
1. "carbonara thursday" is captured on Monday. On Tuesday at 20:00 nothing is added. On Wednesday at 16:59 nothing is added. On Wednesday at 17:01, carbonara's non-staple lines are on Groceries with a share linking the recipe and the task.
2. Running the pass again (on every foreground) adds nothing.
3. "dal tonight" is captured at 18:00 and its ingredients are added at once.
4. Undoing the capture after the add removes the open items that carry only that share. An item that also carries another recipe's share loses only this share. Checked items stay.
5. A task moved from Thursday to Saturday before the add is added on Friday at 17:00.
6. If the recipe was deleted, the pass skips the task without crashing.

**On the simulator, in the recording.** Capture "dal tomorrow" in the ghost row. Open Groceries: the dal items are there with "for dal" under each, Tess says "Added 3 for dal." with UNDO (Design 47 replaced the 17:00 wait and the sage dab).

**UI bar.** There is nothing new on screen apart from the long-press wording, so it inherits Groceries' acceptance.
