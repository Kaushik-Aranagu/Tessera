# Grammar collision audit: sets, tasks, kitchen, lists, books

For: Core engine (Tess grammar), Product lead
Date: 2026-10-15. Research lab.

Static read of `origin/master` at `fcad46c`. Nothing was run, so every "today" result below is inferred from the code. "G:" is `TesseraCore/Sources/TesseraTess/TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift`, "E:" is `TessCaptureEngine.swift`. List phrase fixtures are in `fixtures/lists-fixtures.md` (another researcher). This file covers only where list phrases collide with other domains.

## How the grammar dispatches today

`TessCaptureEngine.capture` (E:20-33) runs `TessGrammar.parse`. If that returns nil, the on-device model gets the phrase (E:29-30). The model can only call registry tools, and `logSet` is not among them (E:83-88). If the model is unavailable, the line is "Didn't catch that". The first non-nil rule wins:

1. **Note** (G:47, G:70). `^note[:\s]` keeps the rest as typed. It beats dates and everything else.
2. **Pasted recipe** (G:50, K:10-15). Multi-line text with an `ingredients` or `you will need` heading line.
3. **Relative set** (G:54, G:77-100). Runs only when `context.entry` is set (live workout). It matches `same`, `again`, `repeat`, `one more`, any bare number from 1 to 100 (G:82), `drop to W for R`, and `W x R` / `W for R`.
4. **Named lift** (G:57, G:114-132):
   - An `NxM` scheme is read as sets x reps when there is another number, otherwise as weight x reps (G:142-153).
   - The other tokens fill weight and then reps. Words are kept except a skip list (G:164).
   - `resolveExercise` (G:187-210) tries an exact name, then the alias table, then library aliases, then a substring fallback: every word, with a trailing "s" dropped, must be **contained** in an exercise name, and the shortest name wins (G:206-209).
5. **Kitchen** (G:61, K:17-58). Placed after lifts on purpose (G:60). `docs/qa/grammar-trace.md` still describes the old kitchen-first order, so that doc is stale. The sub-order is:
   - `list:` or `new list` (K:24)
   - an exact `shop` word (K:28)
   - bail out on `todo`/`task`/`remind` (K:33)
   - timer, when there is no date (K:36, K:72-88)
   - `buy`/`get`/`groceries:` when there is no date. `get` must look like groceries (K:39-48).
   - a bare comma list where every item looks like groceries (K:50-56, K:62-69). `looksLikeGroceries` only needs an amount, an aisle word (including the last word, `Aisles.swift`) or a known ingredient.
   - `parseCook` (K:91-106). `cook`/`make` is explicit; otherwise a date cue is needed. `recipe(named:)` tries an exact title and then the first recipe that holds every word as a whole word (K:109-122).
6. **Task** (G:64, G:215-234). An explicit `todo`/`task`/`remind [me] [to]`, or **any** date cue. A date cue is any token in `TessDates` (G:256-305):
   - a weekday abbreviation such as `sun` or `sat`
   - `today`, `tonight`, `tomorrow`
   - `at N`
   - `3pm`, `15:00`, `noon`

   A date with no time is set to 09:00, even when that is in the past (G:298). A weekday that is today and already past moves to next week (G:301-303).

What follows from this structure:

- **Context.** `TessContext` (TessCapturing.swift:12-26) carries only `now`, `calendar`, `entry` and `commitImmediately`. A running cook, shop, list run or book is not visible to the grammar. A cook is only read after parsing, to attach a timer (E:100-101).
- **Other domains.** There is no question, completion, reschedule, list-add or reading grammar on master. Phrases in those domains either fall through to the model or are caught by the date-cue task rule, which is the biggest source of collisions.

## Collision table

Columns: phrase; source (TE = `tess-eval-phrases.md` row, QE = `questions-eval.md` row, KP = `kitchen-phrases.md`, LA = `lists-acceptance.md`, RD = `ship-list-reading-draft.md`, "derived" = a variant of the cited row); what the code picks today (inferred), or "future" when the collision appears once the planned lists or reading grammar lands as drafted; the correct domain; and the cause.

| # | Phrase | Source | Today (inferred) | Correct | Why |
|---|---|---|---|---|---|
| 1 | `p 42 of 80` | RD (short book) | lift: **Dip** 42 kg x 80 | book page 42 of 80 | "of" is skipped and "p" is a substring of "dip", which is the shortest name (G:164, G:206-209) |
| 2 | `p 142` (workout live) | RD | model, which may guess a set | book page | No reading rule exists. The draft puts reading after relative sets, which is safe here, but it must also run before named lifts (row 1) |
| 3 | `42` (workout live, book resumed) | RD + TE 6 | set, 80 x 42 | set (the workout is in front) | Correct today. It must stay a set when reading lands, and a bare number goes to the book only when no workout is live |
| 4 | `finished` (workout live, book reading) | RD + TE 37 | model | finish workout | Draft rule: "finished" means a book whenever one is reading. The running process should win over a suspended book |
| 5 | `start the chilli` | TE 127 | model | start cook | Draft: `start X` queues and starts a book named X |
| 6 | `start push day` | TE 33 | model | start workout | Same draft rule. It would become a book called "Push day" |
| 7 | `start writing the report` | TE 104 | model | task (start) | Same. It would become the book "Writing the report" |
| 8 | `read chapter four` | derived TE 105 | model | task | Draft: `read X` queues a book. Without a day cue this becomes the book "Chapter four" |
| 9 | `finished Dune: slow start, great end` | RD | model | finish book with review | A future `<list>:` add rule would read "finished dune" as a list name. The comma rule is safe only because "great end" has no aisle |
| 10 | `add project hail mary to books` | TE 165 vs RD | model | one owner: Books list or book queue | The two drafts give books two sources of truth (RD open question 3) |
| 11 | `done for today` | TE 38 | task "Done for", today 09:00 | finish workout | "today" is a date cue, so it becomes a task (G:232) |
| 12 | `done call mum` | TE 84 | model | complete task "Call mum" | "done" has no grammar. It could also mean the end of a workout, cook step, list item or book |
| 13 | `move dentist to friday` | TE 86 | task "Move dentist to", Fri | reschedule "Dentist" | A date cue creates a new task with the verb in its title |
| 14 | `not today passport` | TE 88 | task "Not passport", today 09:00 | reschedule "Renew passport" to Later | Same |
| 15 | `i feel like rubbish today skip leg day` | TE 200 | task "I feel like rubbish skip leg day" | reschedule Leg Day | Same |
| 16 | `what did i weigh monday` | QE 44 | task "What did i weigh", Mon | question, no write | There is no question guard before the task rule |
| 17 | `anything due tmrw` | QE 36 | task "Anything due", tomorrow | question | Same |
| 18 | `everything from tuesday` | QE 53 | task "Everything from", Tue | question | Same |
| 19 | `what did i get done today` | QE 33 | task "What did i get done", today | question | Same |
| 20 | `what did tess log today` | QE 59 | task "What did tess log", today | question | Same. "did" and "log" are dropped only inside lifts |
| 21 | `buy present for mums birthday on the twentieth` | TE 109 | groceries, 1 line | task, 20 Oct | `TessDates` misses ordinals, so the date check fails and `buy` wins (K:39) |
| 22 | `buy sun cream` | derived TE 111 | task "Buy cream", Sunday | groceries "sun cream" | "sun" reads as a weekday (G:258), which blocks `buy` (K:39) |
| 23 | `buy eggs and remind me to defrost the chicken tonight` | TE 153 | one task, the whole line, 20:00 | groceries + task | No splitting. "tonight" makes the whole line a task |
| 24 | `log bench eighty for eight and remind me to call mum tomorrow` | TE 192 | one task "Log bench eighty for eight and…" | set + task | No splitting, and spoken numbers are not normalized |
| 25 | `bench 80x8 today` | derived TE 1 | task "Bench 80x8", today 09:00 | set Bench 80 x 8 | "today" is kept as an exercise word, so the lift is not resolved and the date makes it a task |
| 26 | `bench 80 x 8 at 7` | derived TE 1 | task "Bench 80 x 8", 07:00 | set, or ask | `at 7` is taken as the weight in the scheme regex (G:117), so sets = 80, which fails, and `at 7` is then a time |
| 27 | `2 x 6 rolls` | derived KP 4 | lift: **Ab Wheel Rollout** 2 kg x 6 | groceries | "rolls" becomes "roll", a substring of "rollout" (G:206) |
| 28 | `bbq: sausages, buns, ketchup` (list BBQ exists) | derived TE 162 | groceries, with "bbq: sausages" as text | add to BBQ list | The aisle check uses the last word, so "bbq: sausages" reads as meat (Aisles.swift) |
| 29 | `2 t-shirts, 3 socks` (Packing run going) | derived TE 185 | groceries, 2 lines | add to Packing | An amount alone counts as groceries (K:67) |
| 30 | `3 emails, 2 calls` | derived TE 79 | groceries, 2 lines | tasks, or the model | Same |
| 31 | `dal for dinner monday` | TE 131 | task "Dal for dinner", Mon, not linked | cook task linking Weeknight dal | `recipe(named:)` needs every word, including "for dinner" (K:118-121) |
| 32 | `carbonara next wednesday` | TE 132 | task "Carbonara next", Wed | cook task linking carbonara | "next" is not a date word, so it blocks the recipe match |
| 33 | `rice thu` | derived TE 130 | cook task for the first recipe with "rice" | ask: Salmon rice bowl or Egg fried rice | The first whole-word match wins silently (K:118) |
| 34 | `rest timer 90` (workout live) | derived TE 41 | kitchen timer "Rest" 1.5 min (linked to the cook if one runs) | workout rest 90 s | No rest grammar, so `parseTimer` takes it (K:72) |
| 35 | `timer 90` (workout live) | derived TE 41 | kitchen timer, **90 min** | rest 90 s | Without "rest" or "plank", a bare number of 30 or more counts as minutes (K:79) |
| 36 | `push day thu` | derived TE 33 | task "Push day", Thu | schedule Push Day | Any date cue makes a task. Routine names are not checked |
| 37 | `make a list called camping` | TE 172 | model (tried as a cook first) | new list "Camping" | `make` is treated as a cook verb (K:93). No list verb form |
| 38 | `list: books` (Books exists) | derived KP 33 | a second list called "Books" | open the existing Books list | `CreateList` does not dedupe (Lists.swift:84-90) |
| 39 | `Camping\nYou will need:\n- tent\n- stove` | LA 3 | recipe | new list "Camping" | The pasted-recipe check runs second and treats a "you will need" heading as a recipe (K:13) |
| 40 | `add milk to packing` | TE 182, KP 42 | model | add to Packing | Future: `add X` defaults to groceries (TE 183), so the named list must win |
| 41 | `add 2.5` (workout live) | TE 20 | model | next set +2.5 kg | Future: `add X` to groceries would add "2.5" |
| 42 | `parmesan` (shop running) | TE 156 | model | groceries | Bare nouns: the grammar cannot see that a shop is running |
| 43 | `idea: tess should read my log back` | TE 96 | model | note | Future: `<name>:` adds to a list named "Idea" |
| 44 | `call mum thu` (Thu 18:00) | TE 61 | task, **next** Thu 22 Oct 09:00 | eval says Thu 15 Oct | G:301-303 conflicts with the eval. Decide on one rule, then fix one side |
| 45 | `call mum at 7` (18:00) | TE 100 | task tomorrow 07:00 | today 19:00 | A bare `at N` is read on a 24-hour clock (G:315-332) |
| 46 | `buy milk today` (after 09:00) | derived KP 50 | task "Buy milk", today 09:00 (already past) | groceries, or a task with no time | A date with no time is set to 09:00 even when that is in the past (G:298) |

46 collisions in total: 36 are wrong today and 10 are future (rows 2 to 10 and 40, 41 and 43 depend on grammar that is not built yet; row 3 is correct today and only needs a guard).

## Proposed precedence rules

The rules are applied in order. The first rule that binds wins. The ghost row shows the rest as alternatives (rule 9).

1. **Explicit prefixes first, and only when their argument resolves.** Prefixes are `note:`/`note`, `todo`/`task`/`remind`, `list:`/`new list`, `groceries:`/`buy`, `timer`, `cook`/`make <recipe>`, `read`/`reading`/`finished <book>`, and `<list name>:`. `<list name>:` binds only to an existing list's exact name (rows 9, 28, 43), and `list: <existing>` opens that list (row 38). A prefix with an unresolved argument falls through without failing.
2. **A question guard comes before every capture rule.** A lead word of `what`, `whats`, `when`, `how`, `did`, `am i`, `anything`, `everything` or `show` routes to the questions path and never writes (rows 16 to 20).
3. **Split before routing.** Split on ` and remind me to `, ` and also ` and `, then `. Each part runs through these rules, and the result is one ghost batch (rows 23, 24).
4. **The process in front decides bare input.** Add `process` (the running `ProcessTable` subject) to `TessContext`. The process in front is the one running in Now; suspended processes do not count.
   - Workout: numbers, `same`, `done`/`finished`, `add 2.5`, `timer N` and `rest N` belong to the workout.
   - Cooking: `timer N`, `next` and `done` belong to the cook.
   - Shop or list run: bare nouns and `done X` go to that list.
   - Book resumed with no workout: `p N` and bare `N` go to the book. A book always goes through `p` (rows 3, 4, 34, 35, 41, 42).
5. **An exact object name beats a verb heuristic.** After a status verb (`start`, `finished`, `done`, `move`, `skip`, `add … to`), resolve the remainder against existing objects of every class: routines, recipes, lists, books and open tasks. A single exact match decides the domain. If nothing matches, a verb never creates a new object titled with the verb. The phrase goes to the model instead (rows 5 to 8, 11 to 15, 36).
6. **Lifts match whole words only.**
   - `resolveExercise` must match whole words, with no substring match and no tokens shorter than 3 characters (rows 1, 27).
   - Strip `today`/`tonight`/`now` before the lift is tried. A lift with a future day becomes a planned item, not a set (rows 25, 26).
   - `at N` after a full `W x R` is a time, not a weight.
7. **Date cues need to stand alone.**
   - Keep a stop list of compounds where a weekday word is part of a noun: `sun cream`, `sun dried`, `sat nav`.
   - Add ordinals (`1st`, `twentieth`).
   - Use one same-day weekday rule, shared by the eval and the code.
   - A bare `at N` takes the next occurrence on a 12-hour clock.
   - A date with no time never lands in the past (rows 21, 22, 44 to 46).
8. **Groceries are for food, by default and only when nothing else applies.** A comma list or bare noun is groceries only when every item resolves to an ingredient or an aisle word. An amount alone is not enough. Recipes match on their title minus filler words (`for dinner`, `next`) (rows 28 to 32).
9. **Ambiguous input shows alternatives and is not auto-committed.**
   - Two parses can be ambiguous: both bind at the same rule, or a match is not unique (several recipes, a book vs a list, or a set vs a planned task).
   - The ghost row shows the top parse and up to 2 one-tap alternatives, and it waits for a tap instead of the 2 s commit (rows 10, 26, 33).
10. **The model is a last resort and runs inside the context.** The model's prompt gets the running process and its object names. A model result that contradicts rule 4, such as a set while reading with no workout live, fails validation.

## Test rows

Swift Testing, as one parameterized table. A context is idle unless stated otherwise. The clock is Thu 15 Oct 2026, 18:00 Europe/London, matching the eval state. Fixtures are the eval-set objects (routines, the recipes "Spaghetti carbonara", "Chilli con carne", "Weeknight dal", "Salmon rice bowl" and "Egg fried rice", the lists Groceries, Packing, Films, Books and BBQ, and the book "Dune"). `kind` follows `GrammarTraceTests.kind` and adds the new cases. Rows marked `// guard` pass today and must keep passing.

```swift
enum Ctx: Sendable { case idle, workout, cooking, shopping, packingRun, reading, workoutAndReading }
struct CollisionRow: Sendable { let phrase: String; let ctx: Ctx; let expect: String }

static let collisionRows: [CollisionRow] = [
    .init("p 42 of 80", .reading, "book.page Dune 42 of 80"),
    .init("p 142", .workoutAndReading, "book.page Dune 142"),
    .init("42", .workoutAndReading, "set 80x42"), // guard
    .init("finished", .workoutAndReading, "workout.finish"),
    .init("finished", .reading, "book.finish Dune"),
    .init("start the chilli", .idle, "cook.start Chilli con carne"),
    .init("start push day", .idle, "workout.start Push Day"),
    .init("start writing the report", .idle, "task Writing the report"),
    .init("start Dune", .idle, "book.start Dune"),
    .init("read chapter four", .idle, "ambiguous book|task"),
    .init("finished Dune: slow start, great end", .idle, "book.finish Dune review"),
    .init("add project hail mary to books", .idle, "list.add Books"),
    .init("done for today", .workout, "workout.finish"),
    .init("done call mum", .idle, "task.complete Call mum"),
    .init("move dentist to friday", .idle, "task.reschedule Dentist Fri"),
    .init("not today passport", .idle, "task.reschedule Renew passport later"),
    .init("i feel like rubbish today skip leg day", .idle, "nothing"),
    .init("what did i weigh monday", .idle, "question"),
    .init("anything due tmrw", .idle, "question"),
    .init("everything from tuesday", .idle, "question"),
    .init("what did i get done today", .idle, "question"),
    .init("what did tess log today", .idle, "question"),
    .init("buy present for mums birthday on the twentieth", .idle, "task Buy present for mums birthday 20 Oct"),
    .init("buy sun cream", .idle, "groceries [sun cream]"),
    .init("buy eggs and remind me to defrost the chicken tonight", .idle, "groceries [eggs] + task Defrost the chicken 20:00"),
    .init("bench 80x8 today", .idle, "lift Bench Press 80x8"),
    .init("bench 80 x 8 at 7", .idle, "ambiguous lift|task"),
    .init("2 x 6 rolls", .idle, "groceries [2 x 6 rolls]"),
    .init("bbq: sausages, buns, ketchup", .idle, "list.add BBQ 3"),
    .init("2 t-shirts, 3 socks", .packingRun, "list.add Packing 2"),
    .init("3 emails, 2 calls", .idle, "nothing"),
    .init("dal for dinner monday", .idle, "cook.task Weeknight dal Mon"),
    .init("carbonara next wednesday", .idle, "cook.task Spaghetti carbonara Wed 21 Oct"),
    .init("rice thu", .idle, "ambiguous Salmon rice bowl|Egg fried rice"),
    .init("rest timer 90", .workout, "rest 90s"),
    .init("rest timer 90", .cooking, "rest 90s"),
    .init("timer 90", .workout, "rest 90s"),
    .init("timer 10", .cooking, "timer 10 min cook"), // guard
    .init("push day thu", .idle, "workout.schedule Push Day Thu"),
    .init("make a list called camping", .idle, "list.new Camping"),
    .init("list: books", .idle, "list.open Books"),
    .init("Camping\nYou will need:\n- tent\n- stove", .idle, "list.new Camping"),
    .init("add milk to packing", .idle, "list.add Packing [milk]"),
    .init("add 2.5", .workout, "set 82.5x8"),
    .init("add sunscreen", .idle, "groceries [sunscreen]"),
    .init("parmesan", .shopping, "groceries [parmesan]"),
    .init("idea: tess should read my log back", .idle, "note"),
    .init("call mum thu", .idle, "task Call mum Thu 15 Oct"),
    .init("call mum at 7", .idle, "task Call mum 19:00 today"),
    .init("buy milk today", .idle, "ambiguous groceries|task"),
    .init("note mums birthday sat", .idle, "note"), // guard
    .init("todo buy bulbs", .idle, "task Buy bulbs later"), // guard
    .init("list the car on ebay sat", .idle, "task List the car on ebay Sat"), // guard
    .init("bench 80, 8", .idle, "lift Bench Press 80x8"), // guard
    .init("dates", .idle, "nothing"), // guard
]

@Test(arguments: collisionRows) func collisions(_ row: CollisionRow) {
    #expect(kind(grammar.parse(row.phrase, context: context(row.ctx))) == row.expect, "\(row.phrase)")
}
```

Notes for Core:

- `Ctx` needs `TessContext.process`, which is rule 4.
- The new `kind` strings need parse cases for these domains:
  - question
  - completeTask
  - rescheduleTask
  - startWorkout and scheduleWorkout
  - finishWorkout
  - rest
  - list.add and list.open
  - the reading cases
  - `.ambiguous([Parse])`
- Rows tagged "nothing" mean that grammar-only Tess makes no write.
