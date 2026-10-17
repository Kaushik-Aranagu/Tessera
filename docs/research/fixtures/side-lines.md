# Tess's side line, and every glance (Research BD2)

*Research, Oct 16. Design ask 1 from sheet 75 ("Tess on the side", item 1) and the glance table ("Every glance: one big fact and two small"). Read against origin/master a438262. It follows AI architecture's shape: rules first, computed on the phone, with Claude rewording off by default (as AI-5). It uses the Kitchen lead's side lines from `product/kitchen-sides-acceptance.md` (on `claude/project-thread-nq38le`) verbatim. Every value is made up.*

## 1. The rules

1. **One line per side**, in her band, the same at both stops (the glance and the full side). The phone counts it from the store. No Claude call is made to produce it. Rewording is off by default; when "Tess asks Claude" is on, a reworded line must pass the same checks, and the rules line shows first.
2. **The cap is Home's detail slot**: `HomeLines.fitsDetail` (`TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:193-200`, caps at :184): 14 words, 80 characters, one sentence ending in a stop, no "?" or "!", and no ". " inside. The context cap (6 words, 32 characters, no stop, :183 and :186-191) is not for the line. It is used here only for the glance's small facts, which are labels, not sentences.
3. **The line never repeats the page's own title.** The title already sits on the spine above it, so a line can lead with its count ("7 for 2 cooks"). This also keeps a private title off the line by construction. When the line names *another* thing, that thing leads ("Push A today, Pull A next on Tuesday."), as thing-first asks.
4. **Words.** "best", never "record" or "PR" (the Set field is named "Record" at `Catalog/SystemCatalog.swift:162`; that word never reaches a line). Times come from `HouseTime.clock` (`Format/HouseTime.swift:7`): 12-hour, lowercase, "8:30 pm", "7 am". Weights are in kg. Days are words ("Thursday", "Sep 20"). No praise, no filler, no exclamation marks.
5. **Private things.** A line never holds a private note's title or words, a money amount, a body measurement or intake, a health word, or a secret word. The check runs on the finished line: `SecretWords.mentions` (`Notes/SecretWords.swift:34`) and `PrivateFacts.isWalled` (`Tess/PrivateFacts.swift:17`) must both be false. Private notes are counted ("5 private"), never named. The Claude cost on The week and Receipts is the app's own spend, already on the front, and Design rules it is not his money. Even so, the *line* there carries counts only.

## 2. When the line stays empty

An empty band is correct, never a fault. These cases are ordered: the first that matches wins.

| Case | Rule | Example |
|---|---|---|
| E1 Body or money side | Body weight's and money's sides never have a line, whatever the data | SL-BW1, SL-MN1 |
| E2 Private object | A private note, a private memory, or any object whose title fails `PrivateFacts.isPrivateTitle` (`Tess/PrivateFacts.swift:12`) when the line would need its content | SL-N5 |
| E3 Walled line | The built line fails rule 5's check: dropped, not reworded | SL-E4 trap |
| E4 First day | The object was made today, so there is no history to count | SL-T3, SL-I3 |
| E5 Too little history | Under the kind's minimum (named in each row: 2 cooks, 3 buys, 3 sessions) | SL-C4, SL-E2 |
| E6 Zero | The only fact is a zero ("0 to buy", "mentioned in 0 places") | SL-C2, SL-N6 |
| E7 Live | The live workout has no side line; its live corner (`Features/Workout/LiveTessCorner.swift`) is her voice there | SL-X1 |
| E8 Says only the front | The line would repeat what the front already shows in the same words | SL-G2 |

## 3. Phrase table per kind, and the data each needs

"Exists" means the phone can count it on a438262 with no new Core code. "Partial" means the data is stored but no helper counts it. "No" means a new field or class is needed.

| Kind (sheet 75 #) | Side | Rules line (pattern) | Data it needs (file:line) | Exists |
|---|---|---|---|---|
| Today (1, 2) | THE DAY | "{n} to go, the next is {title} at {time}." / "All {n} done, nothing left today." | `TaskList.todayCounts`, `Tasks/Tasks.swift:75`; next item `NowRanker`/`NowPicker` (`Tasks/`); `HouseTime.clock` | Exists |
| Task (3) | ITS STORY | "Moved {n words}, and today's the day." / "First planned {day}, moved {n} since." | hand moves: `MoveTask` ops in the op log (`Tasks/Tasks.swift:93`; `OpRecord.createdAt` and `objectIDs`, `Model/Models.swift:524`, :538); nightly rolls `rolls` and `rolledFrom` (`Catalog/SystemCatalog.swift:209-210`, `Tasks/Tasks.swift:18`) | Partial: no helper counts a task's moves |
| Training tab (4) | THE WEEK | "{done} of {planned} sessions, {routine} next on {day}." | `WeekFacts.trainedDays`, `plannedDays`, `next` (`DayLog/WeekFacts.swift:42-51`) | Exists |
| Routines (5) | LAST TIMES | "{last} today, {next} next on {day}." | `daysSinceLastRun` (`Home/HomeLines.swift:593`, internal); Workout `routine` and `endedAt` (`Catalog/SystemCatalog.swift:131-132`); plan order `PlanSchedule` (`Training/PlanSchedule.swift:23`) | Partial: the helper is internal to HomeLines |
| Routine (6) | LAST TIMES | "Last done {day}, {n} times this month." | as above, per routine | Partial |
| Plan (7) | THE PLAN | "{n} days a week, on fixed days." / "..., rolling on." | `sessionsPerWeek`, `scheduleMode` (`Catalog/SystemCatalog.swift:196-198`) | Exists |
| Exercise (8) | YOUR SETUP | "Best {kg} kg for {reps}, in {month}." | `TrainingLedger.records` and `bestSet` (`Training/TrainingLedger.swift:112-116`); `sessions` :96 | Exists |
| Workout, finish (9, 12) | THE SETS | "{n} sets in {min} min, one new best." / "{routine}, last done {n} days ago." | `WorkoutSummary.sets`, `startedAt`, `endedAt`, `records` (`Training/WorkoutSummary.swift:15-22`) | Exists |
| Kitchen tab (13) | THE WEEK'S COOKS | "{n} cooks this week, {m} to buy." (Kitchen) | planned cooks by day: not on master (Kitchen week 67); `Groceries.toBuy(for:)` (`Kitchen/Groceries.swift:59`) | No: planned cooks |
| Groceries, shop (14, 15) | FOR WHAT | "{n} for {k} cooks, {j} just because." (Kitchen) | shares: `Groceries.recipes(for:)` (`Kitchen/Groceries.swift:73`), `share(of:)` :79; `shares` field (`Catalog/SystemCatalog.swift:277`) | Exists |
| Recipe (16) | INGREDIENTS | "{n} to buy." (Kitchen; "{n} to buy, {m} at home." once Pantry knows) | the dry run of `AddRecipeToGroceries` (`Kitchen/Groceries.swift:271`) | Exists |
| Recipe original (17) | COOKS | "Cooked {n} times, about {median} min." (Kitchen; empty under 2) | `CookLog.cooks(of:)` (`Kitchen/Cooking.swift:30`); start = the cook's `createdAt` at `StartCooking` (:89), end = `cookedAt` at `FinishCooking` (:238, field at `Catalog/SystemCatalog.swift:319`) | Partial: no duration helper |
| Ingredient (18) | PER 100 G | "You buy it about every {n} days." when USUALLY knows, else "In {n} of your recipes." (Kitchen) | cadence: checked rows are deleted at the shop's end (`Kitchen/Shopping.swift:61`, `Lists/Lists.swift:293-296`), so buys live only in `checkListItem` ops plus the item's `about` link to the ingredient (`Kitchen/Groceries.swift:86-89`). USUALLY is not on master. Recipes: `RecipeBook.recipes(using:)` (`Kitchen/Recipes.swift:88`) | Cadence: No. Recipes: Exists |
| Paste (19) | WHAT I READ | "{n} lines kept, {m} ignored." | `CreateRecipe.lines(of:)` (`Kitchen/Recipes.swift:146`) | Exists |
| Review tab (20) | THE MONTH | "{n} sessions and {m} tasks done in {month}." | `WeekFacts` per week (`DayLog/WeekFacts.swift:78`), summed over the month's weeks | Partial: no month helper |
| The week (21) | WHAT LEAVES THE PHONE | "{n} calls to Claude this month, most for {job}." | `TessUsageLedger.calls()` (`TesseraTess/ClaudeKey.swift:106`); `use` (`Catalog/SystemCatalog.swift:226`); jobs `TessUse` (`TesseraTess/TessModel.swift:5`) | Exists |
| Notes (22) | BY THING | "{thing} comes up most, in {n} notes." / "{n} notes, all private." | `NoteList.notes(about:)` (`Notes/Notes.swift:22`); private notes have no links (`Notes/Notes.swift:111-119`) | Exists |
| Note (23) | WHERE IT'S MENTIONED | "Mentioned in {n} places." | `ObjectStore.backlinks(to:)` (`Engine/ObjectStore.swift:287`) | Exists |
| Receipts (24) | BY JOB | "{job}, {n} of this month's {total} calls." | as for 21 | Exists |
| Backups (25) | WHAT'S IN ONE | "The last one ran at {time}, {n} kept." | `TesseraBackup.Info.createdAt` (`Export/TesseraBackup.swift:14-15`); kept count from the folder (`writeRolling` keep 7, :120). Object counts per copy are not in `Info`. | Partial: no counts in a copy |
| Class page (26) | ITS OBJECTS | "{n} of them, the newest from {day}." | `ObjectStore.objects(of:)`; `createdAt` | Exists |
| Any other object (27) | default | "Linked from {n} things." | `ObjectStore.backlinks(to:)` (`Engine/ObjectStore.swift:287`) | Exists |
| List (27, generic) | default | "{done} of {n} done." | `ListContents.items(of:)` (`Lists/Lists.swift:33`) | Exists |
| Live workout (10) | running order | none (E7) | | |
| Habit (not built) | HOW IT COUNTS | "{n} of 7 days this week." (this week only, no history) | no Habit class (`Catalog/SystemCatalog.swift:12-25`) | No |
| Body weight (not built) | HOW IT'S MEASURED | none (E1) | | No |
| Money (not built) | WHERE IT CAME FROM | none (E1) | | No |
| Book (not built) | YOUR NOTES | "{n} notes, the last on {day}." | no Book class | No |
| Person (not built) | LAST TIMES | "Last seen {n} weeks ago." | no Person class | No |
| Chore (not built) | LAST TIMES | "About every {n} weeks, last on {date}." | no Chore class | No |
| Day log (not built) | THE DAY | "{routine} and {n} tasks done." | `DayStory` (`DayLog/DayStory.swift`), no view | Partial |
| Shutdown (not built) | TOMORROW | "{title} at {time}, then {n} tasks." | tomorrow's plan, `DayPlan` (`Tasks/DayPlan.swift`) | Partial |
| Trip (not in the inventory) | none drawn | "Leaving {day}, {n} of {m} packed." | no Trip class; a trip is a List today | No |

## 4. Fixtures: the side line

Columns: the class, the facts the phone counted, the expected rules line or "empty", its words and characters, and the filler trap that must NOT appear in the line. Every non-empty line was checked with a copy of `fitsDetail`: 0 lines over the cap.

| ID | Class (#) | Facts counted | Expected | Words / chars | Trap (must not appear) |
|---|---|---|---|---|---|
| SL-D1 | Today (1) | 6 done, 4 to go; next Stretch at 20:30 | "4 to go, the next is Stretch at 8:30 pm." | 10 / 40 | "You've got this" |
| SL-D2 | Today (1) | first day: no tasks, no workouts, store made today | empty | 0 | "Fresh start" |
| SL-D3 | Today (1) | 7 of 7 done | "All 7 done, nothing left today." | 6 / 31 | "Great job" |
| SL-D4 | Today (1) | 2 to go; the next task is titled "Reset bank pin" (secret word "pin") | "2 to go." | 3 / 8 | "bank pin" (never named) |
| SL-T1 | Task (3) "Call the plumber" | made Tuesday; 2 hand moves; set for today | "Moved twice, and today's the day." | 6 / 33 | "Finally" |
| SL-T1x | Task (3) | Design's example, as drawn | "Moved twice. Today's the day." fails `fitsDetail` (". " inside) | 5 / 29, refused | (replaced by SL-T1) |
| SL-T2 | Task (3) | first planned Monday; rolled 2 nights by itself; 1 hand move | "First planned Monday, moved once since." | 6 / 39 | "overdue", "missed" |
| SL-T3 | Task (3) | made today, no moves | empty | 0 | "Just added" |
| SL-T4 | Task (3) "Reset bank pin" | 2 hand moves; today | "Moved twice, and today's the day." | 6 / 33 | "pin" |
| SL-W1 | Training (4) | 3 of 6 sessions; next Legs A on Saturday | "3 of 6 sessions, Legs A next on Saturday." | 9 / 41 | "on fire" |
| SL-W2 | Training (4) | no plan, no sessions, first week | empty | 0 | "Let's go" |
| SL-R1 | Routines (5) | Push A done today; Pull A due Tuesday | "Push A today, Pull A next on Tuesday." | 8 / 37 | "neglected" |
| SL-R2 | Routines (5) | plan with no finished workouts | empty | 0 | "Time to start" |
| SL-R3 | Routine (6) Push A | last finished Thursday; 4 this month | "Last done Thursday, 4 times this month." | 7 / 39 | "Crushing it" |
| SL-R4 | Routine (6) | never run | empty | 0 | "Give it a go" |
| SL-P1 | Plan (7) | 4 sessions a week; fixed days | "4 days a week, on fixed days." | 7 / 29 | "on track" |
| SL-P2 | Plan (7) | no sessionsPerWeek, no routines | empty | 0 | "Build your plan" |
| SL-E1 | Exercise (8) Bench Press | 14 sessions; best 100 kg × 5 on Mar 3 | "Best 100 kg for 5, in March." | 7 / 28 | "PR", "record" |
| SL-E2 | Exercise (8) | 2 sessions (min 3) | empty | 0 | "Keep going" |
| SL-E3 | Exercise (8) Pull-up, `bodyweightPlus` | best +10 kg × 6 in August | "Best 6 reps with 10 kg added, in August." | 9 / 40 | any body weight ("82 kg") |
| SL-E4 | Exercise (8) Back Squat | best 140 kg × 3 in May; notes "left knee sore" | "Best 140 kg for 3, in May." | 7 / 26 | "knee" (notes never feed the line) |
| SL-WK1 | Workout finish (12) Push A | 20 sets, 5 exercises, 52 min, 1 best | "20 sets in 52 min, one new best." | 8 / 32 | "PR", "Beast mode" |
| SL-WK2 | Workout (9), planned | Push A last finished 6 days ago | "Push A, last done 6 days ago." | 7 / 29 | "usual" |
| SL-WK3 | Workout (9), finished | 0 sets logged, all skipped | empty | 0 | "Rest is good too" |
| SL-K1 | Kitchen (13) | 3 cooks planned; 8 to buy | "3 cooks this week, 8 to buy." | 7 / 28 | "Yum" |
| SL-K2 | Kitchen (13) | no cooks planned | empty | 0 | "What's for dinner" |
| SL-G1 | Groceries (14) | 10 rows: 7 for Tacos and Chili, 3 with no share | "7 for 2 cooks, 3 just because." | 7 / 30 | "Happy shopping" |
| SL-G2 | Groceries (14) | empty list | empty | 0 | "All stocked up" |
| SL-G3 | Groceries (14) | 5 rows, no shares | "5 just because, none for a cook." | 7 / 32 | "usual" |
| SL-C1 | Recipe (16) | 12 things, 7 not on the list | "7 to buy." | 3 / 9 | "delicious" |
| SL-C2 | Recipe (16) | 0 to buy | empty | 0 | "You're all set" |
| SL-C3 | Recipe original (17) | 4 finished cooks: 38, 44, 46, 51 min (median 45) | "Cooked 4 times, about 45 min." | 6 / 29 | "favorite" |
| SL-C4 | Recipe original (17) | 1 cook | empty | 0 | "First of many" |
| SL-C5 | Recipe original (17) | 2 cooks: 44 and 54 min | "Cooked 2 times, about 49 min." | 6 / 29 | "getting faster" |
| SL-I1 | Ingredient (18) Rice | USUALLY: bought Sep 12, 21, 30, Oct 9 | "You buy it about every 9 days." | 7 / 30 | "You always forget" |
| SL-I2 | Ingredient (18) Paprika | no cadence; in 3 recipes | "In 3 of your recipes." | 5 / 21 | "staple" |
| SL-I3 | Ingredient (18) | made today; no recipes, no buys | empty | 0 | "New!" |
| SL-I4 | Ingredient (18) Ground beef | table row 215 kcal per 100 g; in 2 recipes | "In 2 of your recipes." | 5 / 21 | "kcal", "protein" |
| SL-I5 | Ingredient (18) Rice | 2 buys only (min 3), no recipes | empty | 0 | "every so often" |
| SL-PA1 | Paste (19) | 14 kept, 3 ignored | "14 lines kept, 3 ignored." | 5 / 25 | "Looks tasty" |
| SL-PA2 | Paste (19) | 14 kept, 3 ignored, one ignored line is "wifi is cedar4471" | "14 lines kept, 3 ignored." | 5 / 25 | "wifi", "cedar4471" |
| SL-PA3 | Paste (19) | every line kept | empty | 0 | "Perfect" |
| SL-M1 | Review (20) | October: 11 sessions, 41 tasks | "11 sessions and 41 tasks done in October." | 8 / 41 | "Proud of you" |
| SL-M2 | Review (20) | first week of use | empty | 0 | "Great start" |
| SL-S1 | The week (21) | 38 calls; most for Home lines; $3.20 | "38 calls to Claude this month, most for Home lines." | 10 / 51 | "$", "worth it" |
| SL-S2 | The week (21) | "Tess asks Claude" off; 0 calls | "Nothing has gone to Claude this month." | 7 / 38 | "Stay private" |
| SL-N1 | Notes (22) | 23 notes, 5 private; Landlord in 4 | "Landlord comes up most, in 4 notes." | 7 / 35 | any private title |
| SL-N2 | Notes (22) | 3 notes, all private | "3 notes, all private." | 4 / 21 | "Private note" as a name, any body word |
| SL-N3 | Notes (22) | 1 note | empty | 0 | "Start writing" |
| SL-N4 | Note (23) Garage ideas | mentioned in 3 notes | "Mentioned in 3 places." | 4 / 22 | "Great note" |
| SL-N5 | Note (23), private | mentioned nowhere (it can't be) | empty | 0 | any word of its body |
| SL-N6 | Note (23) | mentioned in 0 places | empty | 0 | "Link it" |
| SL-RC1 | Receipts (24) | 38 calls; Home lines 21 | "Home lines, 21 of this month's 38 calls." | 8 / 40 | "$" |
| SL-RC2 | Receipts (24) | 0 calls | empty | 0 | "Nothing yet" |
| SL-B1 | Backups (25) | last copy 04:00; 7 kept | "The last one ran at 4 am, 7 kept." | 9 / 33 | "Safe and sound" |
| SL-B2 | Backups (25) | no copy yet | empty | 0 | "Back up now" |
| SL-CL1 | Class (26) Barbell Lift | 38 objects; newest Tuesday | "38 of them, the newest from Tuesday." | 7 / 36 | "Private note" |
| SL-CL2 | Class (26) | 0 objects | empty | 0 | "Add one" |
| SL-O1 | Any object (27) Squat rack | 3 backlinks | "Linked from 3 things." | 4 / 21 | "useful" |
| SL-O2 | Any object (27) a Muscle | 0 backlinks | empty | 0 | "Lonely" |
| SL-L1 | List (27) Packing | 14 items, 6 done | "6 of 14 done." | 4 / 13 | "Almost there" |
| SL-L2 | List (27) | 0 items | empty | 0 | "Add something" |
| SL-X1 | Live workout (10) | anything | empty | 0 | any line in the side band |
| SL-H1 | Habit (not built) Water | 5 of 7 days this week | "5 of 7 days this week." | 6 / 22 | "streak" |
| SL-H2 | Habit (not built) Weigh in | 4 of 7 days | "4 of 7 days this week." | 6 / 22 | "82.4", "kg" (Q4, ruled 2:44) |
| SL-BW1 | Body weight (not built) | 12 weigh-ins | empty | 0 | any weight, "kg" |
| SL-MN1 | Money (not built) | 9 spends | empty | 0 | "$" |
| SL-BK1 | Book (not built) Dune | 4 notes; last Sunday | "4 notes, the last on Sunday." | 6 / 28 | "Great read" |
| SL-PE1 | Person (not built) Sam | last seen 3 weeks ago | "Last seen 3 weeks ago." | 5 / 22 | "Reach out" |
| SL-CH1 | Chore (not built) Descale the kettle | every 5 weeks; last Sep 20 | "About every 5 weeks, last on Sep 20." | 8 / 36 | "overdue" |
| SL-DL1 | Day log (not built) Thursday | Push A; 3 tasks done | "Push A and 3 tasks done." | 6 / 24 | "productive" |
| SL-SD1 | Shutdown (not built) | tomorrow Push A at 07:00; 3 tasks | "Push A at 7 am, then 3 tasks." | 8 / 29 | "Big day" |
| SL-TR1 | Trip (not in the inventory) | leaving Friday; packing 9 of 14 | "Leaving Friday, 9 of 14 packed." | 6 / 31 | "Bon voyage" |

## 5. Fixtures: every glance

Each glance holds one big fact (Hero 56, its unit at 21) and at most two small facts (Body 19). Expected text is from Design's table. Small facts are checked against the context cap (6 words, 32 characters, no stop); the three that are sentences are checked against the detail cap. Big facts are a number with its unit, or one name. 0 over the cap.

| ID | Screen (#) | Big fact | Small 1 | Small 2 | Data (see section 3) |
|---|---|---|---|---|---|
| GL-1 | Today: THE DAY (1) | "4" *to go* | "6 done" (2 / 6) | "Stretch at 8:30 pm" (4 / 18) | todayCounts; next item |
| GL-2 | A task: ITS STORY (3) | "2" *moves* | "made Tuesday" (2 / 12) | "in Plan my day" (4 / 14) | move ops (partial) |
| GL-3 | Training: THE WEEK (4) | "3" *of 6 sessions* | "Legs A, Saturday" (3 / 16) | "Push A, today" (3 / 13) | WeekFacts |
| GL-4 | Routines: LAST TIMES (5) | "Push A" | "today" (1 / 5) | "Pull A, Tuesday" (3 / 15) | last run (partial) |
| GL-5 | A routine: LAST TIMES (6) | "Thursday" | "5 of 5, 1,072 kg moved." (6 / 23) | "4 times this month" (4 / 18) | WorkoutSummary.volume |
| GL-6 | Plans: THE PLAN (7) | "4" *days a week* | "Push Pull Legs" (3 / 14) | "on fixed days" (3 / 13) | plan fields |
| GL-7 | An exercise: YOUR SETUP (8) | "Third hole" | "Olympic bar, 20 kg" (4 / 18) | "written Oct 9" (3 / 13) | `notes`, screened (PL1); `barWeight` (`Catalog/SystemCatalog.swift:74`) (superseded by depth-76.md, sheet 76: the exercise's SETUP is a page of its one side) |
| GL-8 | A workout or finish: THE SETS (9, 12) | "20" *sets* | "Bench 82.5 × 7" (4 / 14) | "5 exercises" (2 / 11) | WorkoutSummary |
| GL-9 | Kitchen: THE WEEK'S COOKS (13) | "3" *cooks* | "Tacos, Friday" (2 / 13) | "8 to buy" (3 / 8) | planned cooks (no) |
| GL-10 | Groceries: FOR WHAT (14) | "7" *for 2 cooks* | "Tacos and chili" (3 / 15) | "3 just because" (3 / 14) | shares |
| GL-11 | A recipe: INGREDIENTS (16) | "12" *things* | "4 on Groceries" (3 / 14) | the key "ADD 8 TO GROCERIES" (4 / 18) | recipe lines; dry run |
| GL-12 | Recipe original: COOKS (17) | "4" *times* | "Sunday, 45 min" (3 / 14) | "about 45 min" (3 / 12) | CookLog (duration partial) |
| GL-13 | An ingredient: PER 100 G (18) | "215" *kcal* | "18.6 g protein" (3 / 14) | "15 g fat" (3 / 8) | food table (no; Kitchen bundles USDA) |
| GL-14 | Paste: WHAT I READ (19) | "14" *lines kept* | "3 ignored" (2 / 9) | "nytimes.com" (1 / 11) | CreateRecipe.lines |
| GL-15 | Review: THE MONTH (20) | "11" *sessions* | "4 weeks" (2 / 7) | "41 tasks done" (3 / 13) | WeekFacts summed (partial) (superseded by depth-76.md, sheet 76: Review gets THE DAYS) |
| GL-16 | The week: WHAT LEAVES THE PHONE (21) | "$3.20" *this month* | "38 calls" (2 / 8) | "Titles and counts only." (4 / 23) | ledger |
| GL-17 | Notes: BY THING (22) | "23" *notes* | "Landlord, 4" (2 / 11) | "5 private" (2 / 9) | NoteList |
| GL-18 | A note: WHERE IT'S MENTIONED (23) | "3" *places* | "Garage ideas" (2 / 12) | "Tile quotes" (2 / 11) | backlinks |
| GL-19 | Claude receipts: BY JOB (24) | "Home lines" | "$1.10" (1 / 5) | "21 calls" (2 / 8) | ledger |
| GL-20 | Backups: WHAT'S IN ONE (25) | "4 am" *last one* | "7 kept" (2 / 6) | "Never your Claude key." (4 / 22) | Backup Info |
| GL-21 | A class page: ITS OBJECTS (26) | "38" *objects* | the newest: "Squat rack" (2 / 10) | the most used: "Olympic bar" (2 / 11) | objects(of:) |
| GL-22 | Any other object (27), Equipment "Rack" | its most-used field (edited most in the last 30 days): "20" *kg bar* | next field: "plates to 25 kg" (4 / 15) | "linked from 3" (3 / 13) | fields; backlinks |

### Glance edge cases

| ID | Case | Facts | Expected |
|---|---|---|---|
| GL-E1 | Small fact with no data | Task: 2 moves, made Tuesday, not in Plan my day and linked to nothing | Big "2" *moves*; small 1 "made Tuesday" (2 / 12); small 2 is left out (no blank row, no dash, no "none") |
| GL-E2 | Both small facts empty | Plan: 4 days a week; no routines named; no scheduleMode | Big "4" *days a week* alone |
| GL-E3 | No big fact at all | Note mentioned in 0 places | No glance: the swipe opens straight to the full side (Design: "A glance with no big fact opens straight to the full side"), and Tess's band is empty (SL-N6) |
| GL-E4 | Zero is not a big fact | Task with 0 moves, made last week | No glance; straight to the full side, which shows its story |
| GL-E5 | Private notes counted, never named | Notes: 23 notes, 2 private | Small 2 is "2 private notes" (3 / 15) when no other count shares the row, or "5 private" (2 / 9) after "23 notes". Never a title, never "Private note" as a row. |
| GL-E6 | A note mentioned in four or more places | Mentioned in 5: Garage ideas, Tile quotes and 3 others | Big "5" *places*; small 1 "Garage ideas" (2 / 12); small 2 "Tile quotes and 3 more" (5 / 22) (the copy rule's "and N more" from four; see Q6) |
| GL-E7 | The top thing is private | Notes: the most-linked thing is only in private notes | Private notes link nothing (`Notes/Notes.swift:111-119`), so it can't be the top thing; the next plain one leads |
| GL-E8 | A setup line is walled | Exercise notes: "Third hole", "left knee sore" | Big "Third hole"; a counted line "1 line kept private" (4 / 19) replaces small 2 only on the full side, never in the glance |
| GL-E9 | Class page with private objects | Note class: 12 notes, newest is private | Big "12" *objects*; the newest named is the newest plain note; "5 private" counts the rest (PL3) |
| GL-E10 | A side too small for two stops | Any object with one backlink and no hidden fields | No glance; straight to the full side |

## 6. Swift Testing names

Core (pure, `TesseraCoreTests`), one `@Test` per name, `@Suite("Side lines")`:

- `sideLineFitsHomeDetailCap` (every non-empty fixture passes `HomeLines.fitsDetail`)
- `designTwoSentenceLineIsRefused` (SL-T1x)
- `sideLineNeverRepeatsOwnTitle`
- `sideLineNeverHoldsSecretWordOrWalledFact` (SL-D4, SL-T4, SL-PA2)
- `privateNoteSideLineIsEmpty` (SL-N5)
- `privateNotesAreCountedNeverNamed` (SL-N1, SL-N2, GL-E5)
- `bodyWeightAndMoneySidesHaveNoLine` (SL-BW1, SL-MN1); `bodyHabitShowsCountOnly` (SL-H2)
- `firstDaySideLineIsEmpty` (SL-D2, SL-T3, SL-I3)
- `taskStoryCountsHandMovesNotNightlyRolls` (SL-T1, SL-T2)
- `exerciseLineSaysBestNeverRecord` (SL-E1)
- `bodyweightPlusLineShowsAddedLoadOnly` (SL-E3)
- `exerciseNotesNeverFeedTheLine` (SL-E4)
- `ingredientCadenceNeedsThreeBuys` (SL-I1, SL-I5)
- `ingredientLineNeverCarriesNutrition` (SL-I4)
- `cooksLineIsEmptyUnderTwoCooks` (SL-C4, SL-C5)
- `groceriesForWhatCountsShares` (SL-G1, SL-G3)
- `zeroIsNeverALine` (SL-C2, SL-N6, SL-CL2, SL-O2, SL-L2)
- `claudeLinesCarryCountsNotDollars` (SL-S1, SL-RC1)
- `sideLineTimesAreTwelveHourLowercase` (SL-D1, SL-B1, SL-SD1)
- `sideLineHasNoFillerTrap` (each row's trap)
- `glanceSmallFactsFitContextCap`
- `glanceLeavesOutEmptySmallFact` (GL-E1, GL-E2)
- `glanceWithoutBigFactOpensFullSide` (GL-E3, GL-E4, GL-E10)
- `glanceNeverNamesAPrivateObject` (GL-E5, GL-E7, GL-E9)
- `glanceListsUseAndNMoreFromFour` (GL-E6)
- `walledSetupLineStaysOffTheGlance` (GL-E8)

App (`TesseraTests`, the SideHost):

- `liveWorkoutHasNoSideLine` (SL-X1)
- `sideLineIsTheSameAtBothStops`
- `rewordingIsOffByDefault`

## 7. Open questions

- **Q1. Design's task example.** "Moved twice. Today's the day." is two sentences, and `fitsDetail` refuses it (`HomeLines.swift:199`). This file uses "Moved twice, and today's the day." Design to confirm.
- **Q2. Thing-first on a side.** The Kitchen lines ("7 for 2 cooks, 3 just because.") lead with a count, and the title sits on the spine above. This file keeps that, and leads with a thing only when the line names another one. Product to confirm, or every line gains the title (which then needs the private-title rule E2 in every row).
- **Q3. Do nightly rolls count as moves?** `rolls` is "never shown as misses" (`Tasks/Tasks.swift:17`). This file counts only his own moves and gives rolls as "First planned Monday". Product to rule.
- **Q4. A habit named for the body.** "Weigh in, 4 of 7 days" gives no weight, but it is a body habit. Ruled 2:44 PM (4): a body-named habit shows its count only, never a value, so SL-H2 reads "4 of 7 days this week."
- **Q5. Data to build.** The task move count, a public routine last-run helper, cook durations, a month sum, buy cadence (USUALLY), planned cooks and the food table are each one Core helper or more. Cadence needs care: bought rows are deleted at the shop's end, so it must read the op log, or keep a buy date on the ingredient.
- **Q6. "And N more" in a two-slot glance.** Design's row 18 says small 2 is "the second named, or 'and N more' from four". This file joins them ("Tile quotes and 3 more") so the second name is not lost. Design to confirm.
- **Q7. GL-22's "most-used field".** Ruled 2:44 PM (7): the most-used field is the field edited most in the last 30 days, counted from his own edits in the op log.
