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
| Tess | **Changed 2026-10-16:** "Tacos, 2 added." with UNDO for 10 s. No notification. Rows carry "for tacos" under them; no sage dab (`no-dots.md`) | Design 47 |

## Acceptance script

**Engine (`swift test`).** Times use the app clock.
1. "carbonara thursday" is captured on Monday. On Tuesday at 20:00 nothing is added. On Wednesday at 16:59 nothing is added. On Wednesday at 17:01, carbonara's non-staple lines are on Groceries with a share linking the recipe and the task.
2. Running the pass again (on every foreground) adds nothing.
3. "dal tonight" is captured at 18:00 and its ingredients are added at once.
4. Undoing the capture after the add removes the open items that carry only that share. An item that also carries another recipe's share loses only this share. Checked items stay.
5. A task moved from Thursday to Saturday before the add is added on Friday at 17:00.
6. If the recipe was deleted, the pass skips the task without crashing.

**On the simulator, in the recording.** Capture "dal tomorrow" in the ghost row. Open Groceries: the dal items are there with "for dal" under each, Tess says "Dal, 3 added." with UNDO (Design 47 replaced the 17:00 wait and the sage dab).

**UI bar.** There is nothing new on screen apart from the long-press wording, so it inherits Groceries' acceptance.

## Kitchen week rulings (Research's day-one walk, KW19, KW20, KW22, KW25, KW30)

*Kitchen lead, 2026-10-16, on `docs/research/fixtures/kitchen-week-day-one.md`. These depend on the walk's top gap 1: the share carries the plan task, not only the recipe, so the receipt, UNDO, delete and skip can all find the rows. Product can overrule any line.*

1. **Skipping a planned meal (KW20).** "skip dal", "skip wednesday's dal" and "skip tonight's dinner" are a skip word. A skip does what deleting the plan does to Groceries: open rows carrying only this plan's share go, checked rows stay, and a row that also carries another share loses only this one. The task is not deleted: it closes as skipped, so Review's "Cook 2 of 4" counts the miss. Receipt "Dal, skipped." with UNDO for 10 s (a change); UNDO puts the task and the rows back as they were. No match: "No dal planned."
2. **A meal planned on a day away (KW22).** Plan it as any day; Tess says nothing about the trip first, because the app does not know he is away until something tells it, and a dinner on the road is his call. The rows land as usual. Home shows the plan wherever he is, in the plan's own time zone rules (the 4 AM day boundary of the phone's zone).
3. **The Sunday reset (KW25).** There is none. Nothing clears on Sunday: open rows stay until bought or removed, the basket clears only on DONE, and a planned meal that went uncooked rolls forward like any task (never "overdue") until he cooks, moves or skips it. A week strip with its own reset is Kitchen v2; no reset op is built before it.
4. **Cooking a planned meal (KW30).** "cook chili" with a chili planned for today or earlier starts that plan's cook: the running cook links to the plan task, Home's line becomes the running cook ("Chili, step 2") in place of "Chili tonight, 2 to buy.", and the task closes when he holds DONE (`FinishCooking`), not at start, so an abandoned cook leaves the plan open. Cooking a planned meal on a different day than planned still closes that plan. "cook chili" with no plan starts a plain cook as today.
5. **Leftovers (KW19).** Out of v1 and v2 unless he asks (`kitchen-v2-scope.md`). "put 2 portions away" captures as a note on the cook's log line, adds no rows and touches nothing in Groceries; no portion count is kept anywhere.

## Private recipe on the plan (ruled Oct 17)

A planned private recipe is spoken and shown as "Private recipe, 7 pm." on the widget, in Siri and in notifications: lowercase time, no "at", never the name. With no time it reads "Private recipe, today." or "Private recipe, tonight." The bare word "Private" is retired for recipes. Its Groceries rows are masked as "Private item" like any walled thing. Rows: `kitchen-refill5-acceptance.md` K32.5 to K32.13 and `kitchen-widget-wash-acceptance.md` KW-W8.
