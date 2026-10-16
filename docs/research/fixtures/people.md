# People fixtures

For: Core engine (M5 People slices 1 to 5, `TessGrammar+People.swift`), Research lab. Date: 2026-10-15.

These are 40 capture phrases for the M5 People ship list (`../../product/ship-list-m5-people.md`, approved 2026-10-15 19:22). They add to the 15 eval rows in that ship list and repeat only a few of them where a collision needs a pair. Grammar facts come from a static read of `origin/master` at `e56c15e` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessTools.swift`). Nothing was run. Every spoken transcript is a plausible guess, not a recording. Reading (`reading.md`, `ship-list-m5-reading.md`), Money (`ship-list-m5-money.md`) and Upkeep (`upkeep.md`, `ship-list-m5-upkeep.md`) are only specced, not on master.

## How to read the tables

**Slice ids.** P1 Person class and actions, P2 Mentions in tasks and people on first use, P3 Last talked and last mentioned, P4 Birthdays as dated tasks, P5 People phrases and tools, P6 Person page, P7 People page, P8 @ in the editors. "P5 table" means the phrase is in the slice 5 capture table as written. "P5 rule" means one of the rules under that table. "P5 eval N" is row N of the ship list's eval table. "Decision N" is the ship list's decision N. **Gap** means no slice covers it; the expected column is then a proposal, and the row is an open question. Other domains: "Reading S4", "Money M4" and "Upkeep U4" are slice 4 of those ship lists.

**Line refs.** "G:" is `TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift`, "T:" is `TessTools.swift`, all at `e56c15e`. The line numbers match the ones in `reading.md`. `grammar-collisions.md` ("GC") was written against `fcad46c`, so its line numbers are stale.

**Facts about master that most rows depend on.**
- The dispatch order is note (G:55), pasted recipe (G:58), question guard (G:62), process rule (G:66), relative set (G:70), comma sets (G:73), named lift (G:76), kitchen (G:80), reschedule (G:83), task (G:90). Nil goes to the model.
- There is no people, contact or completion grammar. A contact phrase with no date (`called mom`, `met sam`) reaches the model. The model's `completeTask` tool finds an open task by exact title, then by every word as a substring (T:263-275). `createTask` links `about` only to an exact object title (T:288-295).
- `TessDates` (G:393-484) knows weekdays, `today`, `tonight`, `tomorrow`, `tmrw`, `at N` and clock times. It has no `yesterday`, no month names, no day numbers and no ordinals. A weekday said on that same weekday, with no time, means today at the next whole hour (G:437-443), so at 18:00 on a Thursday `thu` gives today 19:00. A bare `at 7` is read on a 24-hour clock; 07:00 has passed, so it means tomorrow 07:00 (G:417, G:429-434, GC row 45).
- `buy X` is groceries whenever there is no date (K:39). `get X` is groceries when X looks gettable, which any phrase of 3 words or fewer does unless it starts with a word like "up" or "the" (K:149-156).
- At the shop, a bare phrase of 4 words or fewer with no number and no date goes on the list (G:120-128).
- Notes link `@Name` only (`NoteList.mentions`); a bare name in a note links nothing.

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London, the same as `../grammar-collisions.md`.

**Fixtures.** The P5 eval fixtures: people Mom (aliases Mum, Amma), Sam (Sam Patel, last talked Tue 13 Oct), Ben and Rosemary, the ingredient Rosemary, and no Priya. Added here: Ravi (no birthday, no aliases). Open tasks: "Call mom", "Finish the report". The book Dune (reading, suspended). Lists: Groceries, Packing, Books. No list called Gifts or Ravi.

**Contexts.**
- **I**: idle. Nothing running.
- **I2**: idle, and the open task "Call mom" is already done.
- **W**: live workout, Bench Press in focus, last set 80 x 8.
- **S**: a shop run of the Groceries list is going.

**Spoken column.** Raw transcript, then the text after `TessSpokenNormalizer` as specified in `spoken-normaliser.md`. The normaliser keeps the transcriber's case, so names stay capitalised. "Typed only" means nobody says it. "Same" means the normaliser changes nothing but edge punctuation.

## Proposed placement of the people rule

P5 puts people after notes, pasted recipes and relative sets, before comma sets, lifts, kitchen and tasks, and after reading, money and upkeep. U4 puts upkeep after comma sets, lifts and kitchen. Both cannot hold (open question 1). The rows below assume this order:

1. note (G:55), pasted recipe (G:58)
2. question guard (G:62), with `did` narrowed (Upkeep U4) and `when's` added (row 29)
3. process rule (G:66), relative set (G:70)
4. reading (Reading S4), money (Money M4)
5. **people (new)**
6. comma sets (G:73), named lift (G:76), kitchen (G:80)
7. upkeep (Upkeep U4)
8. reschedule (G:83), task (G:90)

People before kitchen lets `dinner with Rosemary fri` reach people before `parseCook` (K:96). People after money keeps `spent 12.40 lunch with sam` a spend (row 39). The two people rows that need the kitchen to change first (rows 32, 33) are about `buy` and `get`, which people does not claim on its own.

## Phrase rows

### Talked: past contact phrases

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 1 | I | `called mom` | "Called Mom." Same | SetTaskDone on the open task "Call mom". That done task links Mom and holds a contact word, so Mom reads "talked today". No extra note | "Done: Call mom. Talked today." | **Past contact verb vs completeTask.** No grammar on master; the model may call `completeTask` "call mom" (T:121) or `createNote`. Resolves: an open task about the same person with the same contact verb (call, ring, text, see, meet, visit) beats a new talk note (GC rule 5, the Upkeep "open task beats a new chore" rule). One check, one write | P5 rule, P3 (done task counts as talked), GC rule 5 |
| 2 | I2 | `called mom` | "Called Mom." Same | LogTalk(people: [Mom], text: "Called @Mom", at: now). A note about [Mom] | "Called Mom. Noted." | Model today. No open task, so the talk note | P5 table (`met Sam`), P3 |
| 3 | I | `rang mom` | "Rang Mom." Same | Same as row 1: SetTaskDone "Call mom" | "Done: Call mom. Talked today." | Model today. `completeTask` "rang mom" fails: "rang" is not in "Call mom" (T:270). **Gap:** P3's contact list treats call and ring as one family for "talked", but no slice says a task "Call mom" is done by "rang mom". Proposal: contact verbs match as one family when completing a task | Gap (P3 list, P5 rule) |
| 4 | I | `texted ravi` | "Texted Ravi." Same | LogTalk([Ravi], "Texted @Ravi") | "Texted Ravi. Noted." | Model today. No collision | P5 rule, P3 list |
| 5 | I | `met sam yesterday` | "Met Sam yesterday." Same | LogTalk([Sam], "Met @Sam", at: Wed 14 Oct). Sam reads "talked yesterday" | "Met Sam, Wed 14 Oct. Noted." | `yesterday` is not a `TessDates` word, so model today. The same word is needed by Upkeep and Money (`upkeep.md` open question 8) | P5 eval 5 |
| 6 | I | `saw mom sat` | "Saw Mom on Saturday." to `Saw Mom on Saturday` | LogTalk([Mom], "Saw @Mom", at: Sat 10 Oct) | "Saw Mom, Sat 10 Oct. Noted." | **Past contact vs task.** Master: task "Saw mom", Sat 17 Oct 09:00, not linked (G:414, G:90). Resolves: people runs before the task rule, and a day cue after a past contact verb is the most recent past day. Spoken: "on" stays in the text and must be dropped before a day cue | P5 table (`saw mom yesterday`), P5 rule |
| 7 | I | `called mom thu` | "Called Mom Thursday." Same | SetTaskDone "Call mom" (row 1), done today. With no open task, LogTalk at Thu 15 Oct | "Done: Call mom. Talked today." | Master: task "Called mom", today 19:00. **"thu" on a Thursday.** For a past verb, the most recent past Thursday must include today, or it lands on Thu 8 Oct | P5 rule, `decisions.md` |
| 8 | I | `met priya` | "Met Priya." (risk: "Met Pria") | Ambiguous: "New person Priya, met today" or "Note: met Priya". Waits for a tap | "New person: Priya?" | Model today. A misheard name ("Pria") offers a new person with the wrong spelling. A tap is required, so nothing is written by accident | P5 table, P5 eval 4, GC rule 9 |
| 9 | I | `met the deadline` | "Met the deadline." Same | No person. Goes to the model | (the model's line) | Model today. P5 rule: an article after the verb means not a name | P5 rule, P5 eval 6 |
| 10 | I | `saw dune` | "Saw Dune." Same | No person, no book write. Goes to the model | (the model's line) | **People vs Reading.** "Dune" is the exact title of a book, so the name test fails (P5 rule: "not the exact title of another object"). Reading S4 has no `saw` phrase, so it passes too. Guard row: neither domain writes | P5 rule, Reading S4 |
| 11 | I | `talked to sam and mom` | "Talked to Sam and Mom." Same | One LogTalk([Sam, Mom], "Talked to @Sam and @Mom"). Both read "talked today" | "Talked to Sam and Mom. Noted." | Model today. **GC rule 3** would split on ` and ` into "talked to sam" and "mom". Resolves: no split inside a contact phrase (P5 slice text) | P5 eval 13, GC rule 3 |
| 12 | I | `facetimed amma` | "FaceTimed Amma." to `FaceTimed Amma` (risk: "face timed") | LogTalk([Mom], "FaceTimed @Amma"). The note keeps the alias as typed and links Mom | "FaceTimed Mom. Noted." | Model today. **Gap inside P2:** `linkMentions` resolves `@Amma` through `NoteList.resolve`, which matches titles, not aliases. Proposal: `linkMentions` asks `person(named:)` before titles, so aliases link. "face timed" as two words misses the contact list; add it | P1 (aliases), P2, P3 list |

### Plans: contact tasks

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 13 | I | `call mom` | "Call Mom." Same | No new task. Proposal: return the open task "Call mom" and link Mom to it if it is not linked | "Call Mom is already on your list." | Model today, which calls `createTask` and makes a second "Call mom". **Gap:** P5 makes a task with no check for an open one. Proposal: a contact task that matches an open task by title is returned, like `AddChore` and `AddPerson` return existing objects | P5 table, P5 eval 1 (with no open task) |
| 14 | I | `call ravi` | "Call Ravi." Same | Task "Call Ravi", Later, about [Ravi] | "Call Ravi, in Later." | Model today. No date, so the task rule misses. Resolves: people claims a contact task with a resolved person even with no date | P5 table |
| 15 | I | `call priya` | "Call Priya." Same | No person. Goes on unchanged: the task rule misses (no date), so the model | (the model's line) | Model today, the same as expected. A bare unknown name after a future contact verb never creates a person | P5 rule |
| 16 | I | `call priya thu` | "Call Priya Thursday." Same | Task "Call priya", today 19:00, not linked, no person | "Call priya, today 7 pm." | Master gives the same. Guard row. The title keeps the typed case ("priya"); typed "Call Priya thu" keeps the capital (G:370) | P5 rule, `decisions.md` |
| 17 | I | `coffee with ravi thu` | "Coffee with Ravi Thursday." Same | Task "Coffee with Ravi", today 19:00, about [Ravi] | "Coffee with Ravi, today 7 pm." | Master: the same task but not linked. `parseCook` (K:96) tries a recipe named "coffee with ravi" first and finds none. **"thu" on a Thursday** means today; the time 19:00 comes from G:441, not from him (open question 6) | P5 table (`dinner with Sam fri`), P2 |
| 18 | I | `coffee with ravi at 7` | "Coffee with Ravi at seven." to `Coffee with Ravi at 7` | Task "Coffee with Ravi", today 19:00, about [Ravi] | "Coffee with Ravi, today 7 pm." | **Bare `at N`.** Master: task tomorrow (Fri 16 Oct) 07:00. Resolves: GC rule 7, the next occurrence on a 12-hour clock. P5 says contact tasks are dated "as the task grammar does", so the fix belongs in `TessDates` | P5 table (`see sam at 7`), GC rule 7 |
| 19 | I | `lunch with ravi` | "Lunch with Ravi." Same | Proposal: ambiguous. Top: task "Lunch with Ravi", Later, about [Ravi]. Alternative: LogTalk "Lunch with @Ravi" today. Waits for a tap | "Lunch with Ravi: plan or done?" | Model today. **Gap:** with no date and no verb, a social noun (coffee, lunch, dinner, drinks) could be a plan or a log. P5 has it only with a date | Gap (P5 table) |
| 20 | I | `drinks with ben 7pm` | "Drinks with Ben at 7 p.m." to `Drinks with Ben at 7pm` | Task "Drinks with Ben", today 19:00, about [Ben]. Never Bench Press | "Drinks with Ben, today 7 pm." | Master: the same task, not linked. The lift rule finds no numbers ("7pm" is not a number), and whole-word matching (G:327-331) keeps "ben" from Bench | P5 eval 7, P5 rule |
| 21 | I | `dinner with rosemary fri` | "Dinner with Rosemary Friday." Same | Task "Dinner with Rosemary", Fri 16 Oct 09:00, about Person Rosemary. Not groceries, not a cook | "Dinner with Rosemary, Fri." | Master: the same task, not linked. People runs before kitchen, so the ingredient never wins after a contact phrase | P5 eval 8, Decision 8 |

### Birthdays

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 22 | I | `ravi's birthday 12 may` | Typed only (row 23 is the spoken form) | SetBirthday(Ravi, month 5, day 12), and task "Ravi's birthday" Wed 12 May 2027, about [Ravi] | "Ravi's birthday, 12 May. On your list for Wed 12 May." | Model today: the lift reads 12 as a weight with no reps and fails, and `TessDates` has no months. **"may" as a month vs a verb:** a month word counts only next to a day number (P5 eval 10, "moving in may") | P5 table, P4 |
| 23 | I | `Ravi's birthday the 12th of May` | "Ravi's birthday is on the twelfth of May." to `Ravi's birthday is on the 12th of May` | Same as row 22 | Same as row 22 | Model today. The normaliser writes ordinals as `12th` (rule 14) but keeps "is on the" and "of". Resolves: the birthday shape skips `is`, `on`, `the`, `of` and reads `12th` | P5 table, normaliser rule 14 |
| 24 | I | `priya's birthday 3 june` | "Priya's birthday third of June." to `Priya's birthday 3rd of June` | AddPerson("Priya"), SetBirthday(Priya, 6, 3), task "Priya's birthday" Thu 3 Jun 2027. One undo removes all three | "Priya's birthday, 3 Jun. On your list for Thu 3 Jun." | Model today. A birthday phrase is one of the three ways to create a person (Decision 4). A misheard name creates a misspelt person; see open question 8 | P5 table, P5 rule, P1, P4 |
| 25 | I | `sam birthday 12/3` | Typed only | SetBirthday(Sam, 3, 12), task Fri 12 Mar 2027 | "Sam's birthday, 12 Mar. On your list for Fri 12 Mar." | Model today ("12/3" is not a number or a time). Day first, as the P5 table writes it. `3/12` would be 3 Dec | P5 table |
| 26 | I | `mom's birthday 15 oct` | "Mom's birthday is the fifteenth of October." to `Mom's birthday is the 15th of October` | SetBirthday(Mom, 10, 15), task "Mom's birthday" today, untimed. It shows on Now today | "Mom's birthday, 15 Oct. That's today." | Model today. Setting today's date gives today's task (P4 test) | P4, P5 table |
| 27 | I | `mom's birthday sat` | "Mom's birthday Saturday." Same | Task "Mom's birthday", Sat 17 Oct 09:00, about [Mom]. Birthday unchanged | "Mom's birthday, Sat." | Master: the same task, not linked. No day and month, so not a birthday change. The possessive links Mom, as P5 eval 11 does for "moms birthday" | P5 rule ("a birthday needs a day and a month") |
| 28 | I | `buy present for moms birthday on the twentieth` | "Buy a present for Mom's birthday on the twentieth." to `Buy a present for Mom's birthday on the 20th` | Task "Buy present for moms birthday", Tue 20 Oct 09:00, about [Mom]. Birthday unchanged | "Buy present for Mom's birthday, Tue 20 Oct." | **Groceries vs task.** Master: groceries, one line (K:39), because `TessDates` misses the ordinal, so no date stops `buy`. Resolves: ordinals in `TessDates` (GC rule 7). The spoken form gives `20th`, which needs the same rule | P5 eval 11, GC row 21, GC rule 7 |
| 29 | I | `when's ravi's birthday` | "When's Ravi's birthday?" to `When's Ravi's birthday` | Question, no write. Answered from Ravi's birthday on the phone | "No birthday saved for Ravi." (after row 22: "12 May, a Wednesday.") | **Question guard gap.** `when's` is not a lead word (G:97), and the normaliser drops the spoken `?` (rule 1). Master sends it to the model as a capture, not a question. Resolves: add `when's`, `whens` and `who` to the lead words | P5 rule (questions), GC rule 2 |

### Gifts, groceries and bare names

| # | Ctx | Typed | Spoken (raw to normalised) | Expected intent and fields | Feedback line | Collision with master and how it resolves | Slice |
|---|---|---|---|---|---|---|---|
| 30 | I | `gift idea for priya: lego` | Typed only (the normaliser has no rule for a spoken "colon") | Proposal: a note "gift idea for @Priya: lego", with Priya offered as "New person: Priya?" (row 8). Waits for a tap | "Gift idea for Priya: lego. New person?" | Model today. **`<list name>:` (GC rule 1)** binds only to an exact list name, so "gift idea for priya" is not a list and no list called that is made. **Gap:** gift ideas are Later in the ship list | Gap (P5 Later: gift ideas) |
| 31 | I | `gift sam: chalk bag` | Typed only | Proposal: model now. When gift lists land, an item "chalk bag" on Sam's gift list | (the model's line) | Model today. Guard: never groceries "chalk bag", never a list "Gift sam". The shape is the Later one from the ship list | P5 Later |
| 32 | I | `buy lego for priya` | "Buy Lego for Priya." Same | Groceries ["lego for priya"], as the P5 rule says ("kitchen keeps its words without a contact phrase"). No person | "Lego for priya, on Groceries." | Master gives the same. **Groceries vs a gift.** The result is right by the approved rule but reads oddly. See open question 9 | P5 rule, Decision 8 |
| 33 | I | `get mom a card` | "Get Mom a card." Same | Proposal: task "Get Mom a card", Later, about [Mom] | "Get Mom a card, in Later." | **Groceries vs a person.** Master: groceries ["mom a card"]. `get` passes `isGettable` because the item is 3 words (K:155). Resolves: `get` with a resolved person as the next word is not groceries; people makes a task about them | Gap (P5 rule covers `buy rosemary` only) |
| 34 | I | `buy rosemary` | "Buy rosemary." Same | Groceries ["rosemary"]. No person link | "Rosemary, on Groceries." | Master gives the same. Guard row: the ingredient keeps its kitchen meaning without a contact phrase | P5 eval 9, Decision 8 |
| 35 | S | `ravi` | "Ravi." Same | Proposal: no write. "Didn't catch that. Ravi is a person." | "Ravi? That's a person, not a grocery." | **Bare name vs shop run.** Master: groceries ["ravi"] (G:120-128): any short phrase with no number goes on the list. Resolves: the process rule skips a phrase that is exactly a person's name and not an ingredient. `rosemary` at the shop stays groceries | Gap (GC rule 4, P5 rule) |
| 36 | W | `sam` | "Sam." (risk: "Same.") | No write. Not a set, not a lift | "Didn't catch that." | **Bare name vs exercise and sets.** Master: no relative set (not a number or `same`), no lift (no numbers), so the model. `ben 3x10` idle also misses: "ben" is not a whole word of any exercise (G:327-331). **Spoken trap:** "Sam" heard as "Same" logs 80 x 8, and the reverse loses a set. A person's name is never read as a set word | P5 rule (lifts), GC rule 6 |
| 37 | I | `note called mom, she's fine` | "Note, called Mom, she's fine." to `note: called Mom, she's fine` | Note "called mom, she's fine", no link, so Mom's talk line is unchanged | "Noted." | Master gives the same: note runs first (G:55). **Gap:** P5 says a contact phrase in a note counts as talked, but only `@Mom` links (P2), so the bare name does nothing. Proposal: keep it; the note editor's @ (P8) is the way to link | P5 rule (note wins), P2 |
| 38 | I | `ravi: call back about the flat` | "Ravi, call back about the flat." to `Ravi, call back about the flat` | Proposal: model. Never a list "Ravi", never a person write | (the model's line) | Model today. **`<list name>:` (GC rule 1)** would add to a list called Ravi if one existed; none does. P5 rule: people phrases never use a colon. The spoken form has a comma instead. The kitchen comma list (K:51-57) does not take it, because "call" is an errand verb (K:135, K:143) | P5 rule, GC rule 1 |
| 39 | I | `spent 12.40 lunch with sam` | "Spent twelve forty lunch with Sam." to `Spent 12.40 lunch with Sam` | LogSpend 12.40, note "lunch with sam", category "lunch". No talk logged. Linking the spend to Sam is Later | "Logged 12.40, lunch with sam." | Model today. **People vs Money.** "lunch with sam" is a contact phrase. Money runs first and takes `spent`; people never sees the phrase | Money M4 table, P5 Later |
| 40 | I | `read sam's draft` | "Read Sam's draft." Same | Proposal: model, which may make the task "Read Sam's draft" about [Sam]. No book | (the model's line) | Model today. **People vs Reading.** The Reading S4 table queues a new book "Sam's draft" from `read X`. `read` is not a contact word, so people does not claim it. Resolves: `reading.md` open question 1 (`read X` creates a book only when it looks like a title), and a possessive that names a person is not a title | Reading S4 table, P5 rule |

Count: 40 rows. Slice cover: 32 rows cite a P5 table phrase, rule, eval row or decision (some also P1 to P4, Reading S4 or Money M4); 8 are gaps (rows 3, 12, 13, 19, 30, 33, 35, and the note link in row 37). On master: 10 rows already give the expected result (4 writes: rows 16, 32, 34, 37; 6 model hand-offs: rows 9, 10, 15, 31, 38, 40). 4 rows make the right task without the person link (17, 20, 21, 27). 6 rows write the wrong thing (6, 7, 18, 28, 33, 35). The other 20 go to the model where the grammar should act. Ambiguous rows that wait for a tap: 8, 19, 30.

## Collisions with master's grammar and the specced domains

| Existing rule | Phrase that meets it | Today on master | Proposed rule |
|---|---|---|---|
| completeTask, a model tool (T:121, T:263-275) | `called mom`, `rang mom`, `called mom thu` | Model; it may mark "Call mom" done, or fail on "rang" | An open task about the person with a verb from the same contact family is completed; that done task is the talk. Otherwise a talk note. Never both (rows 1 to 3, 7) |
| createTask, a model tool | `call mom` with "Call mom" open | Model makes a second task | Return the open task (row 13) |
| Task rule with a weekday (G:90, G:414) | `saw mom sat`, `called mom thu` | Tasks "Saw mom" next Saturday and "Called mom" today 19:00 | People runs before tasks. A day cue after a past contact verb is the most recent past day, today included (rows 6, 7) |
| Task rule, unlinked | `coffee with ravi thu`, `drinks with ben 7pm`, `dinner with rosemary fri`, `mom's birthday sat` | Tasks with no `about` | Same tasks, linked to the person (rows 17, 20, 21, 27) |
| `TessDates` bare `at N` (G:417, G:429-434) | `coffee with ravi at 7` | Tomorrow 07:00 | Next occurrence on a 12-hour clock (GC rule 7) (row 18) |
| `TessDates`, no months, no ordinals, no `yesterday` | `ravi's birthday 12 may`, `buy present for moms birthday on the twentieth`, `met sam yesterday` | Model, or groceries for the `buy` phrase | One date parser for day and month, ordinals and `yesterday`, shared with Upkeep and Money. A month word counts only next to a day number (rows 5, 22 to 28) |
| Question guard (G:97) | `when's ravi's birthday` | Model, as a capture | Add `when's`, `whens`, `who` (row 29) |
| Kitchen `buy` (K:39) | `buy lego for priya`, `buy rosemary` | Groceries | Keep, as the approved P5 rule says (rows 32, 34). See open question 9 |
| Kitchen `get` (K:39-48, K:149-156) | `get mom a card` | Groceries ["mom a card"] | `get <person> ...` is a task about the person (row 33) |
| Kitchen `parseCook` (K:96) | `dinner with rosemary fri`, `coffee with ravi thu` | Task, after no recipe matched | People before kitchen, so a contact phrase is never tried as a recipe (rows 17, 21) |
| Process rule, shop run (G:120-128) | `ravi` at the shop | Groceries ["ravi"] | A bare exact person name that is not an ingredient is not a grocery (row 35) |
| Relative set and lift (G:70, G:76) | `sam` in a workout, spoken "Sam" vs "Same" | Model | A person's name is never a set word; measure the "Sam"/"Same" mishearing on device (row 36) |
| Note (G:55) | `note called mom, she's fine` | Note, no link | Keep; only `@Mom` links (row 37) |
| GC rule 1 (`<list name>:`, future) | `gift idea for priya: lego`, `ravi: call back about the flat` | Model | Binds only to an exact list name; people phrases never use a colon (rows 30, 38) |
| GC rule 3 (split on ` and `) | `talked to sam and mom` | Model | No split inside a contact phrase (row 11) |
| Reading S4 (`read X`) | `read sam's draft` | Model | `read X` does not create a book from a phrase that names a person (row 40) |
| Reading, exact titles | `saw dune` | Model | An exact title of another object is never a new person (row 10) |
| Money M4 (`spent`) | `spent 12.40 lunch with sam` | Model | Money runs first; no talk logged (row 39) |

## Open questions

1. **Order of the new rules.** P5 puts people after upkeep and before comma sets, lifts and kitchen. U4 puts upkeep after kitchen. Both cannot hold. Suggestion: reading, money, people, then comma sets, lifts and kitchen, then upkeep, then tasks. Drop "after upkeep" from P5; the two share no verbs.
2. **Completing a contact task.** Should `called mom` complete the open "Call mom" and log nothing else (row 1)? Should `rang mom` and `phoned mom` complete it too (row 3)?
3. **Duplicate contact tasks.** Should `call mom` return the open "Call mom" instead of making a second one (row 13)?
4. **Aliases in mentions.** Should `@Amma` link Mom through her aliases (row 12)? Today `NoteList.resolve` matches titles only.
5. **Plan or log.** With no date and no verb, is `lunch with ravi` a plan for Later or a talk today (row 19)? Suggestion: ask with two taps.
6. **Untimed contact tasks today.** `coffee with ravi thu` said on a Thursday at 18:00 gets 19:00, a time he never said (row 17). Should a weekday that is today give an untimed task today instead?
7. **Shared date parser.** Birthdays need day and month in any order, `12/3`, ordinals, `the 12th of May` and an optional year (rows 22 to 26). Upkeep needs months and `yesterday`. Build one parser in `TessDates` with a past mode?
8. **Misheard names.** A spoken birthday phrase can create a misspelt person ("Pria") with no tap (row 24). Should a birthday phrase for an unknown name also wait for a tap, as `met Priya` does (row 8)?
9. **Gifts in `buy`.** `buy lego for priya` is groceries by the approved rule (row 32). Should `for <person>` after `buy` make a task about them instead, or wait for gift lists?
10. **Bare names at the shop.** Should the shop-run rule skip a phrase that is exactly a person's name (row 35)?
11. **Bare names in notes.** Should a contact phrase plus a bare existing name in a note link the person (row 37), or is `@` the only way?
12. **New question lead words.** Add `when's`, `whens` and `who` (row 29)? `who` could clash with nothing on master today.
13. **"Sam" and "Same".** In a live workout, a spoken "Sam" may come back as "Same" and log a set (row 36). Measure on device; if it happens, should a set from "same" need the exact word with no capital?
14. **Gift idea shape.** When gift ideas land, is the shape `gift idea for priya: lego`, `gift sam: chalk bag`, or both (rows 30, 31)?
