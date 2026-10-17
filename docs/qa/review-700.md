# Review #700 (head 1bea347e): FIX FIRST (small), static
NowPage only. Planned cook: cookRecipe(of:) takes the first live `about` link whose class is a Recipe subclass, hero reads fact(plannedCook:recipe:), hero opens the recipe, key is GROCERIES (openLink(.groceries)); done cook: cooksFinished(on:).first shows fact(doneCook:) after the done-workout branch.
## Finding
fact(plannedCook:) (HomeLines.swift:552) reads the time from the task's `due` only. A captured cook ("cook tacos thu 7 pm", TessCaptureEngine:376) creates the task with `startsAt` and `about: [recipe]`, never `due`; Tasks.swift:81 itself reads startsAt first, then due. So the hero loses the time ("Tacos tonight, 12 to buy." instead of "Tacos at 7 pm, 12 to buy.") and, if a task ever has a date-only due, would say "at 12 am". The existing HomeLines test builds the task with no time, so it doesn't catch this.
Fix: `startsAt: store.value("startsAt", of: task)?.dateValue ?? store.value("due", of: task)?.dateValue` (or pass the ScheduleItem start as fact(task:startsAt:) does), plus a test with a timed cook task.
## Checks
- Caps: planned context is "N to buy" (kitchenContext), done context a clock; both well inside 6 words/32 chars. Recipe title only appears in the hero/text, which have no cap (same as workout titles).
- 4 AM: cooksFinished uses TesseraDay.isSameDay, so a cook stays until 04:00; the NowPage passes its own `now`.
- Privacy: no recipe-level private flag exists; the recipe title already shows on the planned task ("Cook tacos") and cook rows, so #700 adds no new text. It need not wait for G21, but G21 should run the recipe title through SecretWords.isPrivateLine, because done cooks are a new Home surface. Ingredient/step private lines are already cut.
- Low: with a recipe task the hero has no Finish hold, so a cook task cannot be finished from Home (intended? Product to confirm).
