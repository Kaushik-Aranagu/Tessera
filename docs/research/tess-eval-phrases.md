# Tess capture eval set (200 phrases)

For: Core engine (Tess engine), Product lead
Date: 2026-10-15

Companion to `tess-routing.md`. Extends `kitchen-phrases.md` (no kitchen phrase is repeated here). Phrases are written the way voice dictation transcribes them: lowercase, fillers, numbers as words, run-ons.

**Assumed state.** Exercises: Bench press, Incline DB press, Squat, Deadlift, Overhead press (OHP), Barbell row, Pull-ups, Lat pulldown, Curls, Leg press. Workouts: Push Day, Pull Day, Leg Day. Mid-workout rows assume a live workout on Bench press, last set 80 x 8, unless the phrase names another exercise. Recipes: Spaghetti carbonara, Chilli con carne, Weeknight dal. Lists: Groceries, Packing, Films, Books, Hardware. Today is Thursday 15 Oct; units kg.

**Actions.** `logSet`, `repeatSet`, `editLastSet`, `deleteLastSet`, `startWorkout`, `finishWorkout`, `swapExercise`, `startRest`, `addTask`, `addNote`, `completeTask`, `rescheduleTask`, `addGrocery`, `startCook`, `startTimer`, `startShop`, `newList`, `addToList`, `runList`, `resetList`, `pickFromList`, `none` (shows "Didn't catch that" or "Can't do that yet", writes nothing). A cell with `+` means several actions in one ghost batch.

**Route.** `grammar`: the grammar must pass this (regression row). `model`: the grammar may fail; the on-device model must pass it. A row passes only if the action and every key field match.

## Workouts (60)

| # | Phrase | Expected action | Key fields | Route |
|---|---|---|---|---|
| 1 | bench 80x8 | logSet | Bench press, 80 kg, 8 | grammar |
| 2 | log bench 80 for 8 | logSet | Bench press, 80, 8 | grammar |
| 3 | 80 for 7 | logSet | current exercise, 80, 7 | grammar |
| 4 | same again | repeatSet | 80, 8 | grammar |
| 5 | same | repeatSet | 80, 8 | grammar |
| 6 | 8 | logSet | current, last weight 80, 8 | grammar |
| 7 | eight | logSet | current, 80, 8 | grammar |
| 8 | eighty for seven | logSet | current, 80, 7 | grammar |
| 9 | eighty two and a half for six | logSet | current, 82.5, 6 | grammar |
| 10 | 82.5 x 6 | logSet | current, 82.5, 6 | grammar |
| 11 | squat 100 5 5 5 | logSet x3 | Squat, 100, 5 each | grammar |
| 12 | squat three by five at a hundred | logSet x3 | Squat, 100, 5 each | grammar |
| 13 | bench 3x10 at 60 | logSet x3 | Bench press, 60, 10 each | grammar |
| 14 | deadlift 140 for 3 | logSet | Deadlift, 140, 3 | grammar |
| 15 | pull ups 10 | logSet | Pull-ups, bodyweight, 10 | grammar |
| 16 | pullups bodyweight plus 10 for 6 | logSet | Pull-ups, +10 kg, 6 | grammar |
| 17 | drop to 70 for 10 | logSet | current, 70, 10 | grammar |
| 18 | same weight 6 reps | logSet | current, 80, 6 | grammar |
| 19 | same but 6 | logSet | current, 80, 6 | grammar |
| 20 | add 2.5 | logSet | current, 82.5, 8 | model |
| 21 | go up two and a half same reps | logSet | current, 82.5, 8 | model |
| 22 | um so that was eighty for like seven i think | logSet | current, 80, 7 | model |
| 23 | okay uh bench eighty kilos eight reps | logSet | Bench press, 80, 8 | grammar |
| 24 | did eight at eighty | logSet | current, 80, 8 | model |
| 25 | got six that time | logSet | current, 80, 6 | model |
| 26 | failed on the seventh so six | logSet | current, 80, 6 | model |
| 27 | that last one was actually seven | editLastSet | reps 7 | model |
| 28 | change last set to 85 | editLastSet | weight 85 | grammar |
| 29 | no wait 82.5 not 80 | editLastSet | weight 82.5 | model |
| 30 | scratch that | deleteLastSet | last set | grammar |
| 31 | undo | deleteLastSet | last set (via undo) | grammar |
| 32 | delete the last set | deleteLastSet | last set | grammar |
| 33 | start push day | startWorkout | Push Day | grammar |
| 34 | lets do legs | startWorkout | Leg Day | model |
| 35 | start pull | startWorkout | Pull Day | grammar |
| 36 | gonna train push today | startWorkout | Push Day | model |
| 37 | finish workout | finishWorkout | current | grammar |
| 38 | done for today | finishWorkout | current | model |
| 39 | im done thats it | finishWorkout | current | model |
| 40 | rest 2 minutes | startRest | 120 s | grammar |
| 41 | rest ninety | startRest | 90 s | grammar |
| 42 | two and a half minute rest | startRest | 150 s | model |
| 43 | swap incline for dips | swapExercise | Incline DB press to Dips | grammar |
| 44 | do dips instead of incline today | swapExercise | Incline DB press to Dips | model |
| 45 | ohp 50 for 8 | logSet | Overhead press, 50, 8 | grammar |
| 46 | overhead press fifty by eight | logSet | Overhead press, 50, 8 | grammar |
| 47 | rows 70 10 | logSet | Barbell row, 70, 10 | grammar |
| 48 | db incline 30s for 10 | logSet | Incline DB press, 30 per hand, 10 | grammar |
| 49 | the thirties for ten | logSet | current DB exercise, 30, 10 | model |
| 50 | curls twelve fives at fourteen | logSet | Curls, 14, 12 | model |
| 51 | leg press 200 for 12 and then 220 for 10 | logSet x2 | Leg press, 200x12, 220x10 | grammar |
| 52 | bench eighty eight eight seven | logSet x3 | Bench press, 80, 8/8/7 | model |
| 53 | squat a hundred for five felt heavy | logSet + addNote | Squat 100x5; note "felt heavy" linked to set | model |
| 54 | 80 for 8 rpe 9 | logSet | current, 80, 8, RPE 9 | grammar |
| 55 | eighty for eight at r p e nine | logSet | current, 80, 8, RPE 9 | model |
| 56 | log warmup 40 for 10 | logSet | current, 40, 10, warmup | grammar |
| 57 | bench 176 pounds for 8 | logSet | Bench press, 80 kg (from 176 lb), 8 | model |
| 58 | lat pulldown sixty five 12 | logSet | Lat pulldown, 65, 12 | model |
| 59 | another one | repeatSet | 80, 8 | model |
| 60 | same as last week | logSet | current, last session's top set | model |

## Tasks and notes (50)

| # | Phrase | Expected action | Key fields | Route |
|---|---|---|---|---|
| 61 | call mom thu | addTask | "Call mom", Thu 15 Oct | grammar |
| 62 | dentist thu 3pm | addTask | "Dentist", Thu 15:00 | grammar |
| 63 | note: bar felt heavy | addNote | "bar felt heavy" | grammar |
| 64 | email landlord tomorrow | addTask | "Email landlord", Fri 16 Oct | grammar |
| 65 | pay rent on the 1st | addTask | "Pay rent", 1 Nov | grammar |
| 66 | renew passport | addTask | "Renew passport", Later | grammar |
| 67 | todo fix bike tyre | addTask | "Fix bike tyre", Later | grammar |
| 68 | remind me to call mom tomorrow | addTask | "Call mom", tomorrow | grammar |
| 69 | remind me to call mom tomorrow at six | addTask | "Call mom", Fri 18:00 | grammar |
| 70 | call the bank monday morning | addTask | "Call the bank", Mon 19 Oct, morning | grammar |
| 71 | book physio next week | addTask | "Book physio", week of 19 Oct | grammar |
| 72 | submit taxes by friday | addTask | "Submit taxes", due Fri 16 Oct | grammar |
| 73 | in 2 hours check laundry | addTask | "Check laundry", today +2 h | grammar |
| 74 | um i need to uh email sarah about the thing on monday | addTask | "Email Sarah about the thing", Mon | model |
| 75 | dont let me forget to water the plants | addTask | "Water the plants", Later | model |
| 76 | i should probably book a haircut sometime next week | addTask | "Book a haircut", week of 19 Oct | model |
| 77 | after work pick up the parcel | addTask | "Pick up the parcel", today evening | model |
| 78 | end of the month cancel the gym trial | addTask | "Cancel the gym trial", 31 Oct | model |
| 79 | call mom and also text dad | addTask x2 | "Call mom"; "Text dad" | model |
| 80 | dentist thursday at three thirty pm | addTask | "Dentist", Thu 15:30 | grammar |
| 81 | dentist on the twenty second at ten | addTask | "Dentist", 22 Oct 10:00 | grammar |
| 82 | meeting with raj next tuesday 2 | addTask | "Meeting with Raj", Tue 20 Oct 14:00 | model |
| 83 | every monday take out bins | addTask | "Take out bins", repeats Mon | model |
| 84 | done call mom | completeTask | "Call mom" | grammar |
| 85 | finished the taxes | completeTask | "Submit taxes" | model |
| 86 | move dentist to friday | rescheduleTask | "Dentist", Fri | grammar |
| 87 | push the landlord email to next week | rescheduleTask | "Email landlord", week of 19 Oct | model |
| 88 | not today passport | rescheduleTask | "Renew passport", Later | model |
| 89 | note: idea for a widget that shows rest time | addNote | full text | grammar |
| 90 | note shoulder clicked on overhead press | addNote | text; link Overhead press | grammar |
| 91 | note: dal needed more chilli | addNote | text; link Weeknight dal | model |
| 92 | jot down that the gym closes at ten on sundays | addNote | "Gym closes at 10 on Sundays" | model |
| 93 | quick note uh wifi password is on the router | addNote | "Wifi password is on the router" | model |
| 94 | note to self knee felt fine today | addNote | "Knee felt fine today" | model |
| 95 | note about push day: shorten rests | addNote | "Shorten rests"; link Push Day | model |
| 96 | idea: tess should read my log back | addNote | "Tess should read my log back" | grammar |
| 97 | call mom thu, dentist fri 3pm | addTask x2 | "Call mom" Thu; "Dentist" Fri 15:00 | grammar |
| 98 | tomorrow call the plumber | addTask | "Call the plumber", Fri | grammar |
| 99 | 3pm today review the lease | addTask | "Review the lease", today 15:00 | grammar |
| 100 | call mom at 7 | addTask | "Call mom", today 19:00 | grammar |
| 101 | call mom tonight | addTask | "Call mom", today evening | grammar |
| 102 | wait for the refund check monday | addTask | "Refund", waiting, check Mon | model |
| 103 | waiting on amazon refund | addTask | "Amazon refund", waiting | model |
| 104 | start writing the report | addTask + start | "Writing the report", running | model |
| 105 | need to read chapter four before thursday | addTask | "Read chapter four", due Thu 22 Oct | model |
| 106 | send invoice friday 9 am and a reminder note to attach receipts | addTask + addNote | task Fri 09:00; note linked | model |
| 107 | call mom thurs | addTask | "Call mom", Thu | grammar |
| 108 | dentist 3 30 | addTask | "Dentist", today 15:30 | model |
| 109 | buy present for moms birthday on the twentieth | addTask | "Buy present for mom's birthday", 20 Oct | model |
| 110 | email boss re holiday dates asap | addTask | "Email boss re holiday dates", today | model |

## Kitchen (50)

| # | Phrase | Expected action | Key fields | Route |
|---|---|---|---|---|
| 111 | buy bananas | addGrocery | ["bananas"] | grammar |
| 112 | buy a dozen eggs | addGrocery | ["12 eggs"] | grammar |
| 113 | get two litres of milk | addGrocery | ["2 l milk"] | grammar |
| 114 | we need olive oil | addGrocery | ["olive oil"] | grammar |
| 115 | im out of eggs | addGrocery | ["eggs"] | model |
| 116 | were running low on coffee | addGrocery | ["coffee"] | model |
| 117 | um buy some uh tomatoes and like basil | addGrocery | ["tomatoes", "basil"] | model |
| 118 | buy chicken thighs rice and soy sauce | addGrocery | 3 lines | model |
| 119 | onions garlic ginger | addGrocery | 3 lines | grammar |
| 120 | half a kilo of mince | addGrocery | ["500 g mince"] | grammar |
| 121 | buy three tins of chopped tomatoes | addGrocery | ["3 tins chopped tomatoes"] | grammar |
| 122 | add the carbonara ingredients to groceries | addGrocery | non-staple ingredients of Spaghetti carbonara | grammar |
| 123 | groceries for chilli | addGrocery | non-staple ingredients of Chilli con carne | model |
| 124 | i want to make dal this week what do i need | addGrocery | ingredients of Weeknight dal | model |
| 125 | cook dal | startCook | Weeknight dal | grammar |
| 126 | lets make carbonara | startCook | Spaghetti carbonara | grammar |
| 127 | start the chilli | startCook | Chilli con carne | grammar |
| 128 | im cooking that pasta thing | startCook | Spaghetti carbonara | model |
| 129 | ok time to cook | none | ask which recipe | model |
| 130 | cook chilli saturday | addTask | "Cook chilli con carne", Sat 17 Oct, links recipe | grammar |
| 131 | dal for dinner monday | addTask | "Cook weeknight dal", Mon 19 Oct | grammar |
| 132 | carbonara next wednesday | addTask | "Cook spaghetti carbonara", Wed 21 Oct | grammar |
| 133 | lets do chilli on the weekend | addTask | "Cook chilli con carne", Sat | model |
| 134 | plan carbonara and dal for tuesday and thursday | addTask x2 | carbonara Tue; dal Thu 22 Oct | model |
| 135 | timer 3 min | startTimer | "Timer", 3 min | grammar |
| 136 | three minute timer | startTimer | "Timer", 3 min | grammar |
| 137 | timer onions eight minutes | startTimer | "Onions", 8 min | grammar |
| 138 | set a timer for the rice for twelve minutes | startTimer | "Rice", 12 min | grammar |
| 139 | timer one and a half hours | startTimer | "Timer", 90 min | grammar |
| 140 | timer 45 seconds | startTimer | "Timer", 45 s | grammar |
| 141 | half hour timer for the bread | startTimer | "Bread", 30 min | model |
| 142 | uh can you time the pasta like ten minutes | startTimer | "Pasta", 10 min | model |
| 143 | two timers pasta ten sauce fifteen | startTimer x2 | Pasta 10; Sauce 15 | model |
| 144 | timer 10 and 20 | startTimer x2 | 10 min; 20 min | model |
| 145 | how long is left on the pasta | none | read-out only, no write | model |
| 146 | cancel the pasta timer | none | stop timer "Pasta" (not in action list; expect "Can't do that yet") | model |
| 147 | going shopping | startShop | Groceries | grammar |
| 148 | im at tesco | startShop | Groceries | model |
| 149 | heading to the shop now | startShop | Groceries | model |
| 150 | buy oat milk tomorrow | addTask | "Buy oat milk", Fri | grammar |
| 151 | note carbonara needed more pepper | addNote | text; link Spaghetti carbonara | grammar |
| 152 | the chilli was too spicy use one chilli next time | addNote | text; link Chilli con carne | model |
| 153 | buy eggs and remind me to defrost the chicken tonight | addGrocery + addTask | ["eggs"]; "Defrost the chicken", today evening | model |
| 154 | buy kitchen roll, bin bags, washing up liquid | addGrocery | 3 lines | grammar |
| 155 | buy 6 eggs 1 l milk 200 g butter | addGrocery | 3 lines with amounts | model |
| 156 | parmesan | addGrocery | ["parmesan"] | model |
| 157 | groceries: pecorino, guanciale | addGrocery | 2 lines | grammar |
| 158 | buy feta for the salad | addGrocery | ["feta"] | grammar |
| 159 | get stuff for carbonara and also bananas | addGrocery | carbonara ingredients + "bananas" | model |
| 160 | make dal for four | startCook | Weeknight dal, serves 4 | model |

## Lists (25)

| # | Phrase | Expected action | Key fields | Route |
|---|---|---|---|---|
| 161 | add passport to packing | addToList | Packing ["passport"] | grammar |
| 162 | packing: toothbrush, adapter, sunscreen | addToList | Packing, 3 items | grammar |
| 163 | films: dune part two | addToList | Films ["Dune Part Two"] | grammar |
| 164 | add the bear to films | addToList | Films ["The Bear"] | grammar |
| 165 | add project hail mary to books | addToList | Books ["Project Hail Mary"] | grammar |
| 166 | put screws on the hardware list | addToList | Hardware ["screws"] | grammar |
| 167 | um can you add like a charger to the packing list | addToList | Packing ["charger"] | model |
| 168 | i want to watch oppenheimer at some point | addToList | Films ["Oppenheimer"] | model |
| 169 | someone recommended the overstory add that to books | addToList | Books ["The Overstory"] | model |
| 170 | dont forget swim shorts for the trip | addToList | Packing ["swim shorts"] | model |
| 171 | new list gift ideas | newList | "Gift ideas" | grammar |
| 172 | make a list called camping | newList | "Camping" | grammar |
| 173 | start a list for christmas presents mom dad sis | newList + addToList | "Christmas presents", 3 items | model |
| 174 | run packing | runList | Packing | grammar |
| 175 | lets pack | runList | Packing | model |
| 176 | start the packing list | runList | Packing | grammar |
| 177 | reset the packing list | resetList | Packing | grammar |
| 178 | pick a film | pickFromList | Films | grammar |
| 179 | pick something from books | pickFromList | Books | grammar |
| 180 | what film should we watch tonight | pickFromList | Films | model |
| 181 | films: arrival, her, past lives | addToList | Films, 3 items | grammar |
| 182 | add milk to packing | addToList | Packing ["milk"] (named list wins over groceries) | grammar |
| 183 | add sunscreen | addGrocery | ["sunscreen"] (no list named, groceries default) | grammar |
| 184 | add to camping tent and stove | addToList | Camping (if it exists), 2 items; else none | model |
| 185 | packing charger socks and um my passport | addToList | Packing, 3 items | model |

## Messy, ambiguous and negative (15)

| # | Phrase | Expected action | Key fields | Route |
|---|---|---|---|---|
| 186 | um | none | no write, nothing shown | grammar |
| 187 | uh hang on | none | no write | grammar |
| 188 | book a flight to lisbon | none | "Can't do that yet. Want a task instead?" | model |
| 189 | whats the weather | none | "Can't do that yet." | model |
| 190 | bench | none | ask for weight and reps; no write | grammar |
| 191 | eighty | none | ambiguous (weight or reps); guess "80 x 8?" as a question | model |
| 192 | log bench eighty for eight and remind me to call mom tomorrow | logSet + addTask | Bench 80x8; "Call mom" Fri | model |
| 193 | buy milk no wait we have milk buy bread | addGrocery | ["bread"] only | model |
| 194 | call mom no actually thursday | addTask | "Call mom", Thu | model |
| 195 | mom | none | ambiguous; guess "Call mom?" as a question | model |
| 196 | ok so like the thing for the stuff | none | "Didn't catch that." | model |
| 197 | delete everything | none | no bulk delete; "Can't do that yet." | model |
| 198 | squat a hundred for five buy eggs | logSet + addGrocery | Squat 100x5; ["eggs"] | model |
| 199 | dates | addGrocery | ["dates"] (food, not a calendar word) | model |
| 200 | i feel like rubbish today skip leg day | rescheduleTask | Leg Day to tomorrow; line "Leg Day moved to tomorrow. Or drop it?"; no persuasion | model |

## Counts

Workouts 60, tasks and notes 50, kitchen 50, lists 25, messy 15. Route split: about 108 grammar, 92 model.
