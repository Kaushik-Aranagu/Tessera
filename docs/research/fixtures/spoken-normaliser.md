# Spoken normaliser fixtures

For: Core engine (slice V1, `TessSpokenNormalizer`), Research lab. Date: 2026-10-15.

These are 80 transcript-to-text rows for the normaliser that sits between `SpeechTranscriber` and `TessGrammar.parse`. They add to the 30 phrases in `../speech-capture.md` section 4 and do not repeat them. Grammar facts come from a static read of `origin/master` at `0c0bfdb` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessModelCapture.swift`, `Units.swift`). Nothing was run. Every raw transcript is a plausible guess, not a recording.

## How to read the table

**Clock and fixtures.** Thu 15 Oct 2026, 18:00 Europe/London, the same as `../grammar-collisions.md`. Contexts:
- **W**: live workout, Bench Press in focus, last set 80 x 8.
- **I**: idle.
- **C**: cooking Weeknight dal.
- **S**: a shop run is going.

**Expected grammar intent** starts with a route:
- **G**: `TessGrammar` parses the normalised text on master today, as written.
- **G\***: the grammar parses it once a named grammar change lands (a `grammar-collisions.md` rule "GC n", the RPE rule, or the M5 Money draft). Until then it falls to the model.
- **M**: the model layer gets the normalised text.
- **PASS**: **pass to the model layer unchanged.** The normaliser changes nothing except edge punctuation, and the grammar must not claim the phrase.
- **none**: empty text, no capture.

**Case.** The normalised column keeps the transcriber's case. `TessGrammar.normalize` lowercases for matching anyway, while `parseTask` and `parseNote` build titles and bodies from the phrase as given, so lowercasing here would turn "Call Ravi" into "Call ravi". This differs from the 30 rows in `speech-capture.md`, which are all lowercase (open question 1).

**Operators.** Rows write `x` between weight and reps to match the 30 rows. The grammar already accepts `W for R` in both relative sets and named lifts (open question 2).

## Fixture rows

### Weights and reps

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 1 | W | Eighty-five for six. | 85 x 6 | G: set 85 x 6 | Hyphenated number words. The sentence period goes |
| 2 | W | 100 and 7.5 for 3. | 107.5 x 3 | G: set 107.5 x 3 | "and" joins a hundred-run even when the transcriber already wrote digits |
| 3 | I | Squat one oh 2.5 for 5. | Squat 102.5 x 5 | G: lift Back Squat 102.5 x 5 | "oh" is 0 only inside a digit run ("one oh two"). A lone "oh" is a word |
| 4 | W | 80 kilos times 8. | 80 kg x 8 | G: set 80 x 8 | "kilos" to kg, "times" to x |
| 5 | W | Same again. | same again | G: set 80 x 8 (same) | Already a grammar phrase. Only the period goes |
| 6 | W | Same weight, one more rep. | Same weight one more rep | **PASS** today. G\*: set 80 x 9 once a "same weight, one more rep" relative rule exists | **Trap.** "one more" must never become "1 more": the grammar matches the words `one more` |
| 7 | W | Drop to 70. | drop to 70 | G\*: drop set 70 x ? (take the last reps, or ask). Today M | The drop regex needs `for R`. "to" stays after drop, never x |
| 8 | W | 80 for 8 at 8. | 80 x 8 @8 | G\*: set 80 x 8, RPE 8 | No RPE in the grammar on master. `@8` with no space becomes an exercise word, and `@ 8` or `at 8` after a scheme is read as a weight (G:117). The normaliser writes `@N` glued, so it never looks like the weight form |
| 9 | W | 82.5 for 6 at RPE 9. | 82.5 x 6 @9 | G\*: set 82.5 x 6, RPE 9 | "at RPE N" and "RPE N" both give `@N` |
| 10 | W | 85 for 5 at nine and a half. | 85 x 5 @9.5 | G\*: set 85 x 5, RPE 9.5 | Half steps only. "at 9.25" stays as said |
| 11 | W | Same, at 9. | same @9 | G\*: set 80 x 8, RPE 9 | RPE after `same` |
| 12 | I | Bench 3 sets of 8 at 80. | Bench 3x8 at 80 | G: lift Bench Press 3 x 8 at 80 kg | `at 80` stays: over 10, so a weight, never RPE |
| 13 | I | Deadlift 2 plates for 5. | Deadlift 2 plates for 5 | **PASS**: M logExercise (the model works out the load from plates and bar) | "for" sits between a noun and a number, so it stays. Plate counts need bar maths, not the grammar. GC rule 6 (whole words) keeps "plates" from matching an exercise |
| 14 | W | 8 reps. | 8 | G: set 80 x 8 (reps only) | A trailing "reps" goes |
| 15 | W | Add two and a half. | add 2.5 | G\*: next set 82.5 x 8 (GC 41). Today M | "two and a half" is 2.5 |
| 16 | W | 80 for 8, 80 for 8, 80 for 6. | 80 x 8, 80 x 8, 80 x 6 | G: sets, 3 sets into Bench | **Trap.** Keep commas between complete sets. `parseCommaSets` needs them |
| 17 | I | Squat 100, 5. | Squat 100, 5 | G: lift Back Squat 100 x 5 | Keep a comma between two bare numbers too. The grammar reads it as weight, then reps |
| 18 | W | 80 for ate. | 80 x 8 | G: set 80 x 8 | "ate" is 8 only in a number slot (after for or x, or alone in W) |
| 19 | W | Eighty into eight. | 80 x 8 | G: set 80 x 8 | en-IN: "into" means times, only between two numbers |
| 20 | I | Three into ten bench at eighty. | 3x10 Bench at 80 | G: lift Bench Press 3 x 10 at 80 kg | en-IN "into" for sets x reps |
| 21 | I | Bench 80 kg, 8 reps only. | Bench 80 kg, 8 | G: lift Bench Press 80 x 8 | en-IN emphasis "only" after a number goes, and so does "reps". The comma stays (row 17) |

### Pounds

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 22 | W | 185 pounds for 5. | 185 lb x 5 | G: set 83.9 kg x 5, unit lb | `MassUnit(parsing:)` already takes "pounds", but the normaliser writes `lb` so the relative regex `(kg\|lb)` matches |
| 23 | I | Deadlift 225 lbs. for 3. | Deadlift 225 lb x 3 | G: lift Deadlift 225 lb x 3 | The dot in "lbs." is not a sentence end |
| 24 | I | I weigh 182 pounds. | I weigh 182 lb | M: logBodyWeight 182 lb | No operator and no second number, so no set |
| 25 | I | Eleven stone four. | Eleven stone four | **PASS**: M logBodyWeight 72.1 kg | Stone is not a `MassUnit`. "N stone M" is protected so "four" never becomes reps |
| 26 | I | Twelve pounds fifty at Tesco. | £12.50 at Tesco | G\*: spend 12.50 GBP, note "Tesco" (M5 Money draft). Today M | "N pounds MM" with no lift word and no operator is money. Trap pair with row 22 |

### Filler and noise

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 27 | W | Okay Tess, 80 for 8. | 80 x 8 | G: set 80 x 8 | A leading "okay Tess", "hey Tess" or "Tess," goes, with its comma |
| 28 | W | Uh, uh, 80, 80 for 8. | 80 x 8 | G: set 80 x 8 | A repeated number collapses. "80," on its own is not a complete set, so its comma goes |
| 29 | W | Yeah. Yeah. 80 for 7. | 80 x 7 | G: set 80 x 7 | A sentence made only of fillers ("yeah", "okay", "right") goes |
| 30 | W | Come on. Come on. 80 for 7. | Come on come on 80 x 7 | M: logExercise 80 x 7 | Real words are never dropped, even a spotter's. The "Heard" line shows them. Gym noise is not the normaliser's job |
| 31 | W | 80 for, for 8. | 80 x 8 | G: set 80 x 8 | Stutter. "for for" before a number collapses. At the end it means "for 4" (speech-capture row 10), so the homophone check runs before repeats collapse |
| 32 | W | 80 for 7 for | 80 x 7 | G: set 80 x 7, shown as doubtful | A dangling operator after a full set goes (a plate clang or cut-off). "for" becomes 4 only when one number has been said |
| 33 | W | Um. | (empty) | none: "Didn't hear anything." | Fillers only |
| 34 | W | Test, 80 for 8. | 80 x 8 | G: set 80 x 8 | "Tess" misheard as "Test". It goes only as the first word with a comma straight after it |
| 35 | I | Test the smoke alarm Saturday. | Test the smoke alarm Saturday | G: task "Test the smoke alarm", Sat 17 Oct 09:00 | Trap pair with row 34: no comma, so "Test" stays |
| 36 | I | Okay Tess, I'd like a reminder for Friday to book the MOT. | I'd like a reminder for Friday to book the MOT | M: createTask "Book the MOT", Fri 16 Oct | "like" stays (not next to a number). Today the date cue makes a wrong task "I'd like a reminder for to book the MOT" (GC rule 5 should send it to the model) |
| 37 | I | Please remind me to call Ravi tomorrow, thanks. | Remind me to call Ravi tomorrow | G: task "Call Ravi", Fri 16 Oct 09:00 | Politeness at the edges goes. Case kept for the name |

### Groceries

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 38 | I | Buy two lemons and some milk. | Buy 2 lemons and some milk | G: groceries ["2 lemons", "some milk"] | "some" stays. Cleaning lines is the Groceries code's job |
| 39 | I | Two lemons and some milk. | 2 lemons and some milk | M: addGroceries ["2 lemons", "milk"] | No "buy" and no comma. The normaliser never adds a verb or commas, because that would be guessing a domain |
| 40 | I | Get a dozen eggs. | Get 12 eggs | G: groceries ["12 eggs"] | "a dozen" is 12. The amount makes it gettable |
| 41 | I | Buy half a dozen eggs and a pint of milk. | Buy 6 eggs and a pint of milk | G: groceries ["6 eggs", "a pint of milk"] | "half a dozen" is 6. "a pint" stays words |
| 42 | I | By 4 lemons and a bag of rice. | By 4 lemons and a bag of rice | **PASS**: M addGroceries ["4 lemons", "a bag of rice"] | A leading "by" before a number stays (row 43 is why). The model fixes it, as in eval 50 |
| 43 | I | By 5 p.m., send the invoice. | By 5pm send the invoice | G: task "By send the invoice", Fri 16 Oct 17:00 | "p.m." joins the number. The title wording is a parseTask issue, not the normaliser's |
| 44 | I | Buy 1 kg atta and half kg dahi. | Buy 1 kg atta and 0.5 kg dahi | G: groceries ["1 kg atta", "0.5 kg dahi"] | en-IN "half kg" without "a" |
| 45 | S | Parmesan. | Parmesan | **PASS** today: M. G\*: groceries in a shop run (GC 42) | Nothing to change |
| 46 | C | Add two tins of chickpeas. | Add 2 tins of chickpeas | G\*: groceries (GC 40, `add X`). Today M | |

### Tasks and dates

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 47 | I | Remind me Friday to call the bank. | Remind me to call the bank Friday | G: task "Call the bank", Fri 16 Oct 09:00 | Reorder. Unchanged, parseTask strips "remind me" but not "to", which follows the date, so the title is "To call the bank" |
| 48 | I | Remind me next Tuesday to renew the passport. | Remind me to renew the passport Tuesday | G: task "Renew the passport", Tue 20 Oct 09:00 | "next" goes before a weekday, because `TessDates` has no "next" and it would land in the title. Whether he means 20 or 27 Oct is open question 4 |
| 49 | I | Call the dentist tomorrow morning. | Call the dentist tomorrow 9am | G: task "Call the dentist", Fri 16 Oct 09:00 | morning 9am, afternoon 2pm, evening 6pm (open question 9) |
| 50 | I | Remind me in 20 minutes to take the chicken out. | Remind me to take the chicken out in 20 min | G\*: task today 18:20, once `TessDates` reads "in N min". Today **wrong G**: dateless task "Take the chicken out in 20 min" | Relative time needs the clock (open question 5) |
| 51 | I | Pay the window cleaner Thursday. | Pay the window cleaner Thursday | G\*: task today, Thu 15 Oct (GC 44 and 46). Today G gives Thu 22 Oct 09:00 | "thursday" said on a Thursday means today. The normaliser leaves the weekday alone. The same-day rule belongs in `TessDates` |
| 52 | I | Remind me Thursday at 8 to put the bins out. | Remind me to put the bins out Thursday at 8 | G\*: task today 20:00 (GC rule 7, 12-hour clock). Today G gives Thu 22 Oct 08:00 | Reorder, then the date is the grammar's job |
| 53 | I | Dentist on the twentieth at half past three. | Dentist on the 20th at 3:30 | G\*: task "Dentist", Tue 20 Oct 15:30 (GC rule 7: ordinals, 12-hour). Today G gives Fri 03:30 | "twentieth" to 20th, "half past three" to 3:30 |
| 54 | I | Call mum at 7:00 PM. | Call mum at 7pm | G: task "Call mum", today 19:00 | Join "7:00 PM" to "7pm". Without the join, parseTime reads 07:00 and "PM" lands in the title |
| 55 | I | Remind me tomorrow itself to send the form. | Remind me to send the form tomorrow | G: task "Send the form", Fri 16 Oct 09:00 | en-IN "itself" after a day goes, then reorder |
| 56 | I | Remind me day after tomorrow to pay rent. | Remind me day after tomorrow to pay rent | G\*: task "Pay rent", Sat 17 Oct, once `TessDates` reads "day after tomorrow". Today **wrong G**: task "Day after to pay rent", Fri | The normaliser only reorders date phrases it knows. This one needs a date rule, not a text rule |
| 57 | I | Prepone the dentist to Wednesday. | Prepone the dentist to Wednesday | **PASS**: M rescheduleTask "Dentist", Wed 21 Oct | en-IN "prepone". "to" with no numbers stays. Today the date cue makes the task "Prepone the dentist to" (GC 13). GC rule 5 must hand it to the model |
| 58 | I | Remind me Friday, no, Saturday to clean the car. | Remind me to clean the car Saturday | G: task "Clean the car", Sat 17 Oct 09:00 | A correction also replaces a weekday with a weekday. "no" counts as a cue only before a word of the same type |
| 59 | I | Do one thing, remind me tomorrow to collect the courier. | Remind me to collect the courier tomorrow | G: task "Collect the courier", Fri 16 Oct 09:00 | en-IN opener "do one thing" goes |
| 60 | I | Remind me two days before the MOT. | Remind me 2 days before the MOT | M: createTask relative to the MOT, or ask. Today **wrong G**: dateless task "2 days before the MOT" | **Trap.** "two" becomes "to" after "remind me" only before a verb. Never before days, weeks, hours, minutes or times |

### Money

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 61 | I | Spent twelve fifty at Tesco. | Spent 12.50 at Tesco | G\*: spend 12.50, note "Tesco" (M5 Money draft). Today M | After a money cue ("spent", "paid", "cost", £), "twelve fifty" is 12.50, never 1250 or 12 x 50 |
| 62 | I | Spent 1250 at Tesco. | Spent 1250 at Tesco | **PASS**: M LogSpend (after Money 1; until then no tool), ask "12.50 or 1250?" | The transcriber already wrote "twelve fifty" as 1250. The normaliser cannot know (open question 6) |
| 63 | I | Lunch was a tenner. | Lunch was £10 | M: LogSpend 10 GBP, note "lunch" (after Money 1; until then no tool) | "a tenner" £10, "a fiver" £5. Messy phrases go to the model (M5 draft) |
| 64 | I | 20 quid for petrol. | 20 quid for petrol | G\*: spend 20 GBP, note "petrol" | "for" after a money amount is never x. "quid" stays, since the draft `MoneyAmount.parse` reads it |
| 65 | I | Spent fifteen hundred on petrol. | Spent 1500 on petrol | G\*: spend 1500, home currency | "fifteen hundred" is 1500 |
| 66 | I | Spent 1,00,000 on the bike. | Spent 100000 on the bike | G\*: spend 100000 | Indian digit grouping (one lakh) loses its commas. Said as "one lakh", the result is the same |
| 67 | I | Paid one lakh twenty thousand rupees deposit. | Paid 120000 rs deposit | M: LogSpend 120000 INR, note "deposit" (after Money 1; until then no tool) | "lakh" and "crore" are number words. "rupees" to rs. "paid" is not a draft grammar prefix |
| 68 | I | Spent four quid at seven eleven. | Spent 4 quid at seven eleven | G\*: spend 4 GBP, note "seven eleven" | **Trap.** The shop name is a protected phrase. "7 11" would read as weight and reps |

### Notes

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 69 | I | Note. The bar felt heavy today. | note: The bar felt heavy today. | G: note "The bar felt heavy today." | "Note." becomes "note:". Without that, `^note[:\s]` misses, and "today" makes it a task. The body is untouched, period included |
| 70 | I | Note to self, eighty felt easy. | note: eighty felt easy | G: note "eighty felt easy" | "note to self" is a note prefix. Number words in the body stay words |
| 71 | I | Make a note that the squat rack in bay two is broken. | note: the squat rack in bay two is broken | G: note "the squat rack in bay two is broken" | "make a note (that)" and "take a note" are note prefixes |

### Corrections

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 72 | W | Eighty, no wait, eighty-five for eight. | 85 x 8 | G: set 85 x 8 | The correction replaces the number before the cue |
| 73 | W | 80 for 8, sorry, 9. | 80 x 9 | G: set 80 x 9 | It replaces the last number, here the reps |
| 74 | I | Buy oat milk, no wait, almond milk. | Buy oat milk, no wait, almond milk | **PASS**: M addGroceries ["almond milk"] | A correction cue with no number or weekday after it is not resolved. The phrase skips the grammar, which would otherwise add three lines including "no wait" |

### Must not be rewritten

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 75 | I | Remind me to eat five a day. | Remind me to eat five a day | G: task "Eat five a day", no date | Protected phrase. "a day" is not a date |
| 76 | I | Meeting in Room 101 at three. | Meeting in Room 101 at 3 | G\*: task "Meeting in Room 101", Fri 16 Oct 15:00. Today G gives Fri 03:00 | "101" is never split or used as a weight. "at 3" is a time; a daytime bias belongs in `TessDates` |
| 77 | I | Book a table for two at seven. | Book a table for 2 at 7 | G\*: task "Book a table for 2", today 19:00 (GC 45). Today G gives Fri 07:00 | "for 2" has no number before it, so no x |
| 78 | I | Work nine to five on Saturday. | Work nine to five on Saturday | G: task "Work nine to five on", Sat 17 Oct 09:00 | **Trap.** "to" between numbers would give "9 x 5". Time ranges stay words |
| 79 | W | Two-three more sets. | Two-three more sets | **PASS**: M, nothing to log | en-IN "two or three". Never 2x3, 23, or a reps-only set of 2 |
| 80 | I | Remind me to water the plants 2-3 times a week. | Remind me to water the plants 2-3 times a week | G: task "Water the plants 2-3 times a week", no date | A range "N-M" stays. Recurrence is not parsed |

Count: 80 rows. Routes: 43 G (grammar parses today), 20 G\* (a grammar change first, model until then), 7 M, 9 **PASS** (rows 6, 13, 25, 42, 45, 57, 62, 74, 79) and 1 none. Rows 36, 50, 56, 57 and 60 are caught by the grammar with a wrong result today; the normaliser cannot fix those, the grammar rules named in each row do.

## Normaliser rules the rows imply

Apply in this order. Each step sees the output of the one before. The whole function stays pure and idempotent: running it on its own output changes nothing, and text that is already digits passes through (rows 2, 23).

1. **Trim and split sentences.** Drop `.` `?` `!` at sentence ends, but not inside numbers (`82.5`), unit abbreviations (`lbs.`) or times (`p.m.`). Keep every comma for now. Keep the transcriber's case (rows 37, 69).
2. **Wake words and politeness at the edges.** Drop a leading `okay Tess`, `ok Tess`, `hey Tess`, `Tess,`, and `Test,` only when a comma follows it (rows 27, 34, 35). Drop a leading `please`, `so`, `okay`, `right`, `do one thing`, and a trailing `please`, `thanks` (rows 37, 59). Drop any sentence made only of fillers (`yeah`, `okay`, `right`, `um`) (row 29). Drop the comma that went with a dropped word.
3. **Note prefix, then stop.** `note`, `note.`, `note:`, `note to self`, `make a note (that)`, `take a note (that)` at the start become `note: ` and the rest is returned exactly as heard, fillers and number words included (rows 69 to 71).
4. **Unresolved corrections go to the model.** If a cue (`no wait`, `sorry`, `I mean`, `actually`, or `no` before a same-type word) is followed by something that is not a number or a weekday, return the text unchanged with a "skip grammar" flag (row 74).
5. **Protect spans.** Mark spans that later steps must not touch: `five a day`, `nine to five`, `seven eleven`, number ranges `two-three` and `N-M`, `N stone M`, `same again`, `one more`, `same weight one more rep`, vague counts (`a couple of`, `a few`), a number after a place noun (`room`, `gate`, `platform`, `table`, `bay`) and a number word before a load noun (`plates`, `a side`) (rows 6, 13, 25, 68, 75 to 80).
6. **Fillers.** Drop `um`, `uh`, `erm`, `er`, `hmm` anywhere, and `like` only next to a number or at an edge, so "I'd like" stays (rows 28, 33, 36).
7. **Number words to digits.** Units, teens, tens, `hundred`, `thousand`, `lakh`, `crore`, `point`, `and a half`, `and half` (en-IN), hyphenated words, `oh` inside a digit run, `a dozen` 12, `half a dozen` 6, `half kg` 0.5 kg, `and` joining a run even across digits the transcriber wrote (`100 and 7.5`). Two-part weights `one twenty-five` give 100 to 300. Remove Indian grouping commas (`1,00,000`). `ate` is 8 only in a number slot (rows 1 to 3, 15, 18, 44, 65 to 67).
8. **Money.** After a money cue (`spent`, `paid`, `cost`, `£`, `₹`, `quid`, `rupees`): `N fifty` is N.50, `N pounds MM` is £N.MM, `a tenner` £10, `a fiver` £5, `rupees` becomes `rs`. A money amount is never an operand of step 12 (rows 26, 61, 63 to 68).
9. **Self-correction.** A cue followed by a number replaces the last number before the cue. A cue followed by a weekday replaces the last weekday. The cue and the replaced token go (rows 58, 72, 73).
10. **Homophones in fixed slots.** `for` at the end becomes 4 only when exactly one number came before it; after a full W x R a dangling `for` is dropped (rows 31, 32). `two` after `remind me`, `need`, `have` becomes `to` only before a verb, never before `days`, `weeks`, `hours`, `minutes`, `times` (row 60). A leading `by` becomes `buy` only when a number does not follow (rows 42, 43).
11. **Collapse repeats.** An immediate repeat of the same token (`to to`, `80, 80`, `for, for` before a number) collapses to one. This runs after step 10, so a trailing `for for` has already become `for 4` (rows 28, 31).
12. **Units and operators.** `kilos`, `kilo`, `kilograms`, `kgs`, `k` after a number become `kg`; `pounds`, `lbs`, `lbs.` become `lb` (rows 4, 22, 23). `for`, `by`, `times`, `into` between two numbers become `x`, except after `drop to`, in money, or after a protected place noun (rows 4, 19, 20, 64). `to` between two numbers is never rewritten (row 78). `N sets of M` becomes `NxM`. A trailing `reps`/`rep` and an en-IN `only` after a number go (rows 12, 14, 21).
13. **RPE.** `at N`, `at RPE N` or `RPE N` with N from 5 to 10 in half steps, straight after a full W x R or `same`, becomes `@N` with no space. `at N` over 10 stays (it is a weight) (rows 8 to 12).
14. **Times and days.** `7:00 PM`, `7 p.m.`, `7 pm` become `7pm`; `half past three` 3:30; `quarter to seven` 6:45; `o'clock` goes; `tomorrow morning` becomes `tomorrow 9am` (afternoon 2pm, evening 6pm); `itself` after a day goes; `next <weekday>` becomes `<weekday>`; ordinals become `20th`; `in twenty minutes` becomes `in 20 min`. The normaliser never resolves a date and never reads the clock (rows 43, 48 to 55).
15. **Reorder reminders.** `remind me <date phrase> to X` becomes `remind me to X <date phrase>`, for date phrases step 14 knows. Unknown ones (`day after tomorrow`) stay put (rows 47, 48, 52, 55, 56, 58, 59).
16. **Commas.** Keep a comma that sits between two complete sets, between two bare numbers, or between list items. Drop a comma left next to a removed word, and a duplicate comma (rows 16, 17, 21, 28).
17. **Empty means nothing.** If nothing is left, return an empty string: no capture, the Bar says "Didn't hear anything." (row 33).

What it never does: guess a domain (no added `buy`, commas or `remind`, row 39), split run-ons, resolve a date, or touch a note body.

## Open questions

1. **Case.** These rows keep the transcriber's case so task titles and notes keep names ("Call Ravi"). The 30 rows in `speech-capture.md` lowercase everything. Pick one before V1 tests are written.
2. **Do we rewrite `for` at all?** The grammar already accepts `W for R`. Rewriting adds risk ("table for 2", "Room 101 for 2 nights") for little gain. The table writes `x` only to match the 30 rows. Default suggestion: keep `for`, rewrite only `times`, `by`, `into`.
3. **RPE grammar.** Rows 8 to 11 need a grammar change: `@N` after W x R, N from 5 to 10. It collides with GC 26 (`bench 80 x 8 at 7`, ambiguous lift or time). Does `at 8` in an idle lift mean RPE, a time, or ask? Live workout only is the safe default.
4. **Weekday meaning.** "Thursday" on a Thursday is today (row 51), which conflicts with `TessDates` today (GC 44). And does "next Tuesday" on a Thursday mean 20 or 27 Oct? UK usage is split. Default suggestion: 20 Oct, with the 27th as a one-tap alternative.
5. **Should the normaliser read the clock?** "in 20 minutes" and "day after tomorrow" (rows 50, 56) need `now`. Suggestion: no. Add them to `TessDates`, which already has the clock, and keep the normaliser pure.
6. **Money shape.** The transcriber may write "twelve fifty" as 1250 (row 62). Should a 4-digit spend at a food shop always show "12.50 or 1250?" Also which home currency (GBP or INR) for amounts with no symbol, and do `quid` and `rupees` become symbols or stay words for the M5 parser?
7. **Return type.** Row 74 needs a "skip grammar" flag, and the ghost row needs the raw heard line. Suggest `struct Spoken { text: String; skipGrammar: Bool; heard: String }` instead of a bare `String`.
8. **Note bodies.** Rule 3 keeps a note body exactly as heard, so "note, uh, call the physio" keeps "uh". Is that right, or should fillers go there too?
9. **Part-of-day times.** Are morning 9am, afternoon 2pm, evening 6pm his times? `tonight` is already 20:00 in the grammar.
10. **en-IN on device.** `SpeechTranscriber` support for en-IN is unverified (`speech-capture.md`). If he uses en-GB with an Indian accent, do "lakh", "into" and "two-three" survive transcription, and does the en-IN locale write `1,00,000`?
11. **Protected phrase list.** A fixed list ("five a day", "seven eleven") will always miss something. Should a capitalised word from the transcriber also protect the numbers next to it, and who owns the list?
12. **"Test" for "Tess".** Rows 34 and 35 rely on the transcriber putting a comma after the wake word. Measure on device in V3 before relying on it.
13. **Model tools.** Many M rows expect `addGroceries`, `LogSpend` or `rescheduleTask`. `TessToolCatalog.allowed` on master is only `logExercise`, `createTask`, `createRoutine`, `createPlan`, `createNote`, `createList`, `startShop`, `logBodyWeight`. `addGroceries` and `rescheduleTask` are among T2's 10 tools; `LogSpend` joins the registry with Money slice 1, so LogSpend rows expect no tool until then.
14. **Default unit.** Rows with no unit default to kg. If he lifts in pounds on some days, should the normaliser or the grammar use the entry's last unit?
