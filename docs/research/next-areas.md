# Next app areas and cross-app links

*Research lab, 2026-10-15 18:15. For: Product lead (planning, M4 and beyond). This brief was checked against master (Kitchen slices 1-9 merged) and the ship lists for v1, M2 (tasks, notes), M3 (body weight, habits, class tools) and Kitchen (recipes, groceries, lists). Nothing below repeats them. Velocity rule: every item has a rough first version.*

## Part 1. Next app areas, ranked

Ranked by how often Kaushik would touch it × how much it reuses / how big the first version is.

| # | Area | Why it fits | Reuses | One creative, uncluttered idea | Smallest first version |
|---|---|---|---|---|---|
| 1 | **Day log (journal that writes itself)** | The op log already records the day; an OS has a system log | Op log, Note, Review side | The day assembles itself from what happened ("Push day, 6 sets PR'd bench · carbonara · 4 tasks"), and you add one line to it. Scrubbing back through days is the Time Machine from round 1 | A Day page per date: auto lines from the op log plus one optional note line; capture "today: …" |
| 2 | **Money (spend log)** | Logging one number at a time, like a set | Log entry, capture grammar, Process (shopping) | Finishing a shop asks one thing: the receipt total, entered on the weight dial's sibling instrument. No budgets screen, just "this month: 312 on groceries, 14 shops" | `Spend` class (amount, category, date, links); "spent 12.40 lunch" in the ghost row; a month count line |
| 3 | **Sleep and energy** | Training and focus both depend on it; HealthKit has the data already | Log entry, HealthKit, Now | A morning check-in on the rep drum: energy 1 to 5, one hold. Tess pairs it with sleep from Health, and on low-energy days the routine offers a lighter top set | HealthKit sleep read + one 1-to-5 energy log a day, both shown on the Day log |
| 4 | **Reading and watching queue** | A book in progress is a process with a resume point (the page) | List, Process, What's running | The book you're reading sits in What's running like a workout. "p 142" in the ghost row moves its resume point, and finishing it writes a one-line review | `Book` class on a List, with start reading / page / finish actions |
| 5 | **People** | Personal OS staple; birthdays and "last talked" are just fields and links | Object page, links, Task, List (gift ideas) | Each person page shows "last talked 3 weeks ago" from @mentions in notes and tasks, so nothing is entered twice | `Person` class: name, birthday, notes via @links; birthday makes a dated task |
| 6 | **Home upkeep (chores, plants, bills)** | Recurring care is a habit with a due date | Habits (M3), Task recurrence, Now | Items show how long since they were last done ("watered 6 days ago"), not overdue red; the stalest drifts toward Now | A `Chore` = habit with an interval; "watered plants" in the ghost row resets it |

Skip for now: travel (rare use), finance accounts and budgets (heavy, needs bank data), language learning (better served by dedicated apps).

## Part 2. Cross-app links, each shippable alone

| # | Link | What Kaushik sees | Built from | Effort |
|---|---|---|---|---|
| 1 | **Logs fill habits by themselves** | "Train 3×/week" and "Cook at home 4×" count themselves when a workout or cook finishes | Habit gets an optional rule: "counts when a `Workout` or `Cook` finishes" | S |
| 2 | **Meal plan feeds groceries** | "Carbonara thursday" puts its ingredients on Groceries the evening before, linked to that task | Dated cook task + `AddRecipeToGroceries` | S |
| 3 | **Body weight is the load** | Pull-ups and dips count body weight plus added weight, so their e1RM and volume are real | Exercise trait `bodyweightLoad` reading the latest body weight entry | S |
| 4 | **Shop when it fits** | When Groceries has 8 or more items and nothing is running in the evening, Now offers "Shop, 9 to buy" once | Now picker rule over the Groceries count | S |
| 5 | **Training-day food** | On training days the Kitchen shelf floats recipes tagged "high protein" up a size | Shelf ranking reads today's routine | S |
| 6 | **Day load counts everything** | The day-full warning includes the workout and the planned cook's minutes, not just tasks | Day load sums durations of routine and recipe | S |

## Recommendation

Draft M4 or M5 around the **Day log** first. It costs the least, it makes the OS idea visible, and areas 2 to 6 all write into it. Cross-app links 1 to 3 are each a one-afternoon slice and could fill idle build time now.
