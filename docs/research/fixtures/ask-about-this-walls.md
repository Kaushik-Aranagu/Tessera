# Ask about this: the walls (sheet 75, Tess on the side, item 2)

*Research, Oct 16, 2026, against origin/master a438262. Docs only: nothing here was run, built or sent. Shape asked by AI architecture: each case is a PACK (the object, the question, the packed payload), checked by a no-call dry run of the packer alone.*

Design's rule (every-side.md, "Tess on the side" 2 and 4): opening the ask slot on a side makes this thing the subject. The ask carries the object's id and class, never its private fields, and every side goes through the same walls as the Bar (SecretWords, PrivateFacts). Product 2:41 pm (a): a side never shows a private fact where the front hides it, and nothing on a Habits, Settings or money side goes to Claude. Product 2:36 pm (2): the app never sums nutrition, because intake is a walled body fact. Product 2:30 pm: a question about money or a body fact gets "That stays on this phone.", and a question about a secret gets "It's in your private notes."

## 1. What master does today (no subject exists yet)

| Fact | Where |
|---|---|
| The ask slot sends only the typed text. `TessContext` has `entry` and `process`, no subject object | BottomChrome.swift:500-529; TessCapturing.swift:12-32 |
| A text with "best", "pr" or ending in "?" is a question and goes to `CommandInterpreter` on the phone, never to a model | BottomChrome.swift:508-509 |
| A key-shaped text is refused before anything reads it, and the draft is cleared | BottomChrome.swift:395, 471, 502; TessModel.swift:69 |
| Claude runs only for `.capture`, with a key, the switch on and no pause | ClaudeTessModel.swift:45-47 |
| Router: a secret word reaches the grammar only (no on-device model, no Claude); a money or body phrase never reaches Claude, but the on-device model may read it | TessModel.swift:74-79 |
| Claude's own route refuses a secret, money or body phrase again | ClaudeTessModel.swift:54 |
| The capture pack Claude gets: today, the workout and last set in focus, rules. Never notes, health or history | ClaudeTessModel.swift:151-156 |
| "Tess asks Claude" is `asksClaude`: real settings and `sendsMissesToClaude`, false on a throwaway store | AppModel.swift:58-60; SystemCatalog.swift:241 |
| A note with a secret word, or marked private, is titled "Private note" and links nothing; an edit that adds a code makes it private (#422) | Notes.swift:111-118, 160-176 |
| Plan my day sends a walled task title as "task" and an event as "busy" | PlanWording.swift:35-39 |

So "Is this enough protein?" on Ground beef ends in "?" and stays on the phone today. Every Claude row below is a proposal for the packer the ask-about-this PR adds (working name `AskSubjectPack`), and every test marked *proposed* does not exist yet.

## 2. The packer contract (proposed)

Input: the side's object, the typed question, the "Tess asks Claude" switch. Output: one payload per route, or a refusal line with no payload.

- **On-device payload:** `{"subject": {"id", "class", "name"}, "fields": {...}, "question"}`. Fields are only the ones marked on-device yes in section 3.
- **Claude payload:** `{"subject": {"handle": "s1", "class", "name"}, "fields": {...}, "question"}`. The real id stays on the phone; Claude sees a handle the phone maps back (the same way groceries-link-eval uses `i1`). `name` goes only for a public-name class, Ingredient or Exercise (Product 2:40 pm), and only when it passes both walls; for every other class, Recipe, Muscle and Equipment included, `name` is the class word in lower case ("recipe", "muscle", "equipment", "task", "note"), as PlanWording does.
- **Order of checks:** key shape, then a secret word in the question, then money or body in the question, then the switch, then the cap. A refused ask makes no Claude event (Product 12:12 pm).
- **Hard fail (any pack):** a private field, a note's words, an amount of money, a body fact, a secret word or value, or anything key-shaped in either payload.

## 3. Wall rows, by class and field

Rule sources are SystemCatalog.swift line ranges on master unless named. "Name" is the object's title. Proposed tests live in `TesseraCore/Tests/TesseraCoreTests/AskSubjectPackTests.swift`.

| Class | Field | On-device | Claude | Rule source | Test |
|---|---|---|---|---|---|
| Any | id | yes | no (handle only) | every-side.md, Tess 2 | proposed `idNeverLeavesOnlyAHandle` |
| Any | class name | yes | yes | every-side.md, Tess 2 | proposed `classAlwaysRides` |
| Any (Thing) | notes (his rich text) | no | no | SystemCatalog:56-58; every-side.md Tess 2 | proposed `freeTextFieldsNeverRide` |
| Exercise | name, aliases | yes | yes, if it passes walls (a public-name class, Product 2:40 pm) | 82-107 | proposed `onlyIngredientAndExerciseNamesRide` |
| Exercise | primaryMuscles, secondaryMuscles, equipment, pattern, mechanic, family | yes | yes (catalog facts, not his) | 84-102 | proposed `catalogFactsRide` |
| Exercise | restSeconds, repMin, repMax, progression, logType | yes | no (his setup) | 87-105 | proposed `hisSetupStaysOnThePhone` |
| Muscle | name | yes | "muscle" (not a public-name class, Product 2:40 pm) | 59-69 | proposed `recipeMuscleEquipmentSendTheClassWord` |
| Muscle | group | yes | yes (catalog fact) | 59-69 | proposed `catalogFactsRide` |
| Muscle | weeklySetsMin, weeklySetsMax | yes | no | 62-68 | proposed `hisSetupStaysOnThePhone` |
| Equipment | name | yes | "equipment" (not a public-name class, Product 2:40 pm) | 70-80 | proposed `recipeMuscleEquipmentSendTheClassWord` |
| Equipment | kind | yes | yes (catalog fact) | 70-80 | proposed `catalogFactsRide` |
| Equipment | barWeight, plates, loads, increment | yes | no | 74-79 | proposed `hisSetupStaysOnThePhone` |
| Workout | name, scheduledFor, startedAt, endedAt, routine | yes | class only | 127-133; ClaudeTessModel:151 (never history) | proposed `historyStaysOnThePhone` |
| Exercise Entry | exercise (public name), targets, skipped | yes | exercise name only | 134-143 | proposed `historyStaysOnThePhone` |
| Set | weight, reps, rpe, e1rm, volume, wasRecord | yes (the bar, not his body: PrivateFacts:79-80) | no | 144-172; ClaudeTessModel:151 | proposed `historyStaysOnThePhone` |
| Routine, Slot, Plan | name, cadence, days, sets, reps, weeks | yes | class only | 173-200 | proposed `ownWordsGoAsClassWord` |
| Task | name | yes, unless secret (then "Private task") | "task" | 201-214; PlanWording:35-39; Product 2:22 pm (2) | proposed `ownWordsGoAsClassWord` |
| Task | startsAt, due, length, isDone, rolls, about | yes | no | 201-214 | proposed `ownWordsGoAsClassWord` |
| Note | body | no if isPrivate; yes if not | no | 215-221; Notes.swift:111, 162 (#422); SecretWords.swift:3-5 | proposed `privateNoteSendsClassOnly`; existing `SecretWordsTests.editingKeepsAPrivateNotePrivateAndAddingACodeMakesItPrivate` |
| Note | name | "Private note" if isPrivate; else yes | "note" | Notes.swift:113; SecretWords.swift:8 | proposed `privateNoteSendsClassOnly` |
| Note | about (links) | names of linked objects, never from a private note | no | Notes.swift:166 | proposed `privateNoteLinksNothing` |
| Memory | rule, evidence | yes unless isPrivate | no | 254-267 (isPrivate "Stays on this phone") | proposed `memoryNeverRides` |
| Tess Call | use, model, tokens, costNano, outcome, requestID | yes | no (money and receipts; Product 2:41 pm (a)) | 225-236 | proposed `settingsAndMoneySidesSendNothing` |
| Settings | every field, missesGoToClaude included | yes | no (Product 2:41 pm (a)) | 237-247 | proposed `settingsAndMoneySidesSendNothing` |
| Waiting for Tess | name (a queued phrase) | yes | no | 248-253; TessInbox.swift:28-31 | proposed `inboxNeverRides` |
| List | name | yes | "list" | 268 | proposed `ownWordsGoAsClassWord` |
| List Item | name | yes; a price is already stripped (Product 2:09 pm) | name only if it passes both walls; body and health items are walled (Product 2:09 pm) | 269-279 | proposed `listItemPassesWallsOrGoesAsClassWord` |
| List Item | quantity, section, shares, about | yes | no | 271-277 | proposed `ownWordsGoAsClassWord` |
| Ingredient | name | yes | yes, if it passes walls (a public-name class, Product 2:40 pm) | 280-284 | proposed `onlyIngredientAndExerciseNamesRide` |
| Ingredient | aisle, isStaple | yes | no (his kitchen) | 282-283 | proposed `hisSetupStaysOnThePhone` |
| Ingredient | PER 100 G row (food table, later) | yes | yes (public table value, one ingredient, never a sum) | Product 2:36 pm (2) | proposed `oneIngredientNeverASum` |
| Recipe | name | yes | "recipe" (not a public-name class, Product 2:40 pm) | 286-293 | proposed `recipeMuscleEquipmentSendTheClassWord` |
| Recipe | sourceText | yes, secret lines already cut | no | 290; Recipes.swift:174; RecipeLinkReader.swift:108 | existing `RecipeLinkTests.privateLinesNeverReachClaude` |
| Recipe | serves, activeMinutes, totalMinutes | yes | yes | 287-289 | proposed `catalogFactsRide` |
| Recipe Line | ingredient name | yes | "recipe line" (the line is not a public-name class; the linked Ingredient's own side sends its name, Product 2:40 pm) | 294-308; Product 2:40 pm | proposed `recipeMuscleEquipmentSendTheClassWord` |
| Recipe Line | amount, unit, prep | yes | yes, money spans stripped | 294-308; Product 11:52 am, 2:09 pm | proposed `recipeLinesStripMoney` |
| Recipe Line | original (as written) | yes | no (pasted text) | 301 | proposed `freeTextFieldsNeverRide` |
| Recipe Step | text | yes | no | 309-315 | proposed `freeTextFieldsNeverRide` |
| Cook | cookedAt, serves, note | yes | no (history and his words) | 316-321 | proposed `historyStaysOnThePhone` |
| Kitchen Timer, Process | every field | yes | class only | 322-348 | proposed `ownWordsGoAsClassWord` |
| Body weight (designed, not built) | every field | yes | never | every-side.md "It stays on the phone"; PrivateFacts:79 | proposed `bodySidesSendNothing` |
| Money (designed, not built) | every field | yes | never | Product 2:41 pm (a); PrivateFacts:31-50 | proposed `settingsAndMoneySidesSendNothing` |
| Habits (designed, not built) | every field | yes | never | Product 2:41 pm (a) | proposed `settingsAndMoneySidesSendNothing` |

## 4. The question itself

| Question carries | On-device | Claude | Line he sees | Rule source | Test |
|---|---|---|---|---|---|
| A secret word ("what's the door code") | grammar only | no | "It's in your private notes." | TessModel.swift:74-79; Product 2:30 pm | existing `SecretWordsTests.nearMissesStayTasksAndQuestionsStayOnThePhone` |
| Money ("is 6.99 a good price") | yes | no | "That stays on this phone." | TessModel.swift:77-79; PrivateFacts:34; Product 2:30 pm | existing `MoneyWallTests.moneyAndBodyRowsNeverReachClaude` |
| A body fact ("at 182.4 lb, is this enough protein") | yes | no | "That stays on this phone." | PrivateFacts:81-109; Product 2:30 pm | existing `MoneyWallTests.moneyAndBodyRowsNeverReachClaude` |
| A health word, no number ("knee hurts, swap this?") | yes | no | "That stays on this phone." | PrivateFacts:71-75 | existing `PrivacyFollowupTests.healthWithNoNumberIsAPrivateNote` |
| His intake ("is this enough protein for me") | yes, one ingredient's table value only | no | the table value, never a sum | Product 2:36 pm (2) | proposed `intakeQuestionsStayOnThePhone` |
| Something key-shaped (KEY) | no | no | the key line (Review, under Claude) | BottomChrome.swift:395, 502; TessModel.swift:69 | existing `ClaudeKeySafetyTests.askRecognisesAKeyInAnyCaseAndPosition` |
| Nothing walled, switch on | yes | yes, packed per section 3 | Claude's answer, wet then dry | every-side.md Tess 1-2 | proposed `aCleanAskOnAPublicThingIsPacked` |
| Nothing walled, switch off | yes | no | the phone's answer or "Didn't catch that." | AppModel.swift:58-60 | existing `ClaudeRouteTests.switchedOffPausedOrKeylessNothingIsSent`, `TessAsksClaudeTests.aThrowawayStoreNeverAsksClaude` |
| Nothing walled, at the cap | yes | no | "Claude paused until Nov 1." | ClaudeTessModel.swift:60-65 | existing `ClaudeKeyTests.atTheCapAWorkingKeySaysPaused` |

## 5. The packs (dry-run cases for the packer)

Made-up values only. Each pack lists the object, the question, and both expected payloads. "No call" means the packer returns the line and no Claude payload.

| # | Object (id, class, public fields; private fields) | Question | On-device payload | Claude payload (switch on) |
|---|---|---|---|---|
| AW1 | e1, Exercise, "Bench Press", primary Chest, secondary Triceps, Front Delts; rest 180 s, reps 6-8 | What can I swap this for? | id e1, Exercise, Bench Press, muscles, rest, reps, question | handle s1, Exercise, Bench Press, primary Chest, secondary Triceps and Front Delts, question |
| AW2 | g1, Ingredient, "Ground beef"; aisle Meat, staple yes | Is this enough protein? | id g1, Ingredient, Ground beef, aisle, staple, table row, question | handle s1, Ingredient, Ground beef, question. The answer is the table value, never his intake |
| AW3 | n1, Note, isPrivate yes, body "door code 4417" | What's this about? | id n1, Note, "Private note", no body, no links | no call; "It's in your private notes." |
| AW4 | n2, Note, not private, body "Tacocat recipe from Sam", about: Recipe r1 | Where else is this mentioned? | id n2, Note, name, body, links | handle s1, "note", question. No body, no links |
| AW5 | t1, Task, "pay rent fri" (amount already stripped, Product 2:22 pm) | When is this due? | id t1, Task, Pay rent, due | handle s1, "task", question |
| AW6 | t2, Task, "Private task" (medicine reminder) | Can I move this? | id t2, Task, "Private task", startsAt | no call; "That stays on this phone." |
| AW7 | s1, Set, 82.5 kg x 8, rpe 8 | Was this a good set? | id s1, Set, weight, reps, rpe | handle s1, "set", question. No weight, no reps |
| AW8 | g1, Ingredient, "Ground beef" | is 6.99 a good price for this? | yes, question as typed (the phone's model may read money) | no call; "That stays on this phone." |
| AW9 | g1, Ingredient, "Ground beef" | at 182.4 lb is this enough? | yes, question as typed | no call; "That stays on this phone." |
| AW10 | e1, Exercise, "Bench Press" | knee hurts, swap this? | yes | no call; "That stays on this phone." |
| AW11 | e1, Exercise, "Bench Press" | pw hunter2 | grammar only | no call; "It's in your private notes." |
| AW12 | e1, Exercise, "Bench Press" | KEY (from `ClaudeSection.fakeKey` in test code) | nothing; draft cleared | no call; the key line |
| AW13 | c1, Settings, missesGoToClaude yes | What does this do? | id c1, Settings, fields | no call (Product 2:41 pm (a)) |
| AW14 | k1, Tess Call, use capture, costNano 1200000 | Why did this cost that? | id k1, fields | no call (money) |
| AW15 | r1, Recipe, "Paprika chicken", serves 4; sourceText with "about $12 a serving" | What can I make instead? | id r1, Recipe, name, serves, sourceText with secret lines cut | handle s1, "recipe", serves 4, question. No name (Recipe is not a public-name class, Product 2:40 pm), no sourceText, no "$12" |
| AW16 | g2, Ingredient, "door code 4417" (a bad title) | What is this? | id g2, Ingredient, name as typed (no private-title rule for ingredients yet) | no call: the name fails SecretWords, so it never goes as a name |
| AW17 | l1, List Item, "Advil" on Packing | Where do I buy this? | id l1, List Item, Advil, quantity | handle s1, "list item", question. "Advil" alone passes `PrivateFacts.isWalled` (medicines need a number, PrivateFacts:94-95), so the packer needs its own list-item health check to meet Product 2:09 pm |
| AW18 | e1, Exercise, "Bench Press", switch off | What can I swap this for? | yes | no call; the phone's answer |
| AW19 | w1, Workout, "Push A", Thursday, 6 sets | How did this go? | id w1, fields | handle s1, "workout", question. No sets, no dates |
| AW20 | m1, Memory, isPrivate yes | Why do you think this? | id m1, rule | no call |

**Dry-run pass:** all 20 packs match exactly; any payload holding "4417", "hunter2", "tacocat" as a value, "6.99", "182.4", "$12", "Advil", a set's weight or reps, a note's body or KEY is a hard fail. A Claude payload holding a Recipe, Muscle or Equipment name (AW15: "Paprika chicken") fails the pack: only Ingredient and Exercise send a name.

## 6. Open for Product

1. Settled, Product 2:40 pm: only Ingredient and Exercise send their public name (after both walls). Recipe, Muscle and Equipment send the class word, as every other class does. The tables and AW15 above follow it.
2. Product 2:41 pm (a) "nothing on a side goes to Claude" is read here as Habits, Settings and money sides only. If it means every side, every Claude column above becomes "no" and Tess on the side 2 is on-device only.
3. Recipe-link money stripping (11:52 am) is not in master's code: RecipeLinkReader cuts secret lines only (RecipeLinkReader.swift:108, 369). Packs AW15 and the facts eval assume the strip lands first.
