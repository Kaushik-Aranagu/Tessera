# Spoken normaliser fixtures

For: Core engine (slice V1, `TessSpokenNormalizer`), Research lab. Date: 2026-10-15.

These are 80 transcript-to-text rows for the normaliser that sits between `SpeechTranscriber` and `TessGrammar.parse`. They add to the 30 phrases in `../speech-capture.md` section 4 and do not repeat them. Grammar facts come from a static read of `origin/master` at `0c0bfdb` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessModelCapture.swift`, `Units.swift`). Nothing was run. Every raw transcript is a plausible guess, not a recording.

## How to read the table

**Clock and fixtures.** Thu 15 Oct 2026, 18:00 Europe/London, the same as `../grammar-collisions.md`. Contexts:
- **W**: live workout, Bench Press in focus, last set 80 × 8.
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

**Operators.** Rows write × between weight and reps, because the normalised text is the clean sentence shown in the voice ghost, and × is the on-screen sign everywhere in the app (Design, speak.md `d288c11`, point 4). The grammar reads × as x (`TessGrammar.normalize`, `TessGrammar.swift:508` at `fdcaee4`), so every parse below is the same as with x. Typed or spoken x, `for`, `times`, `into` and `by` still parse: the normaliser turns spoken `by`, `times` and `into` between two numbers into × (rule 12), and the grammar reads `W x R` and `W for R` (`TessGrammar.swift:286`). A typed "80 by 8" is not a set on master ("by" parses only in the 2 × 10 ask, `TessGrammar+Live.swift:123`); see rows 81 to 83 and the item 100 section. The grammar already accepts `W for R` in both relative sets and named lifts (open question 2).

## Fixture rows

### Weights and reps

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 1 | W | Eighty-five for six. | 85 × 6 | G: set 85 × 6 | Hyphenated number words. The sentence period goes |
| 2 | W | 100 and 7.5 for 3. | 107.5 × 3 | G: set 107.5 × 3 | "and" joins a hundred-run even when the transcriber already wrote digits |
| 3 | I | Squat one oh 2.5 for 5. | Squat 102.5 × 5 | G: lift Back Squat 102.5 × 5 | "oh" is 0 only inside a digit run ("one oh two"). A lone "oh" is a word |
| 4 | W | 80 kilos times 8. | 80 kg x 8 | G: set 80 × 8 | "kilos" to kg, "times" to × |
| 5 | W | Same again. | same again | G: set 80 × 8 (same) | Already a grammar phrase. Only the period goes |
| 6 | W | Same weight, one more rep. | Same weight one more rep | **PASS** today. G\*: set 80 × 9 once a "same weight, one more rep" relative rule exists | **Trap.** "one more" must never become "1 more": the grammar matches the words `one more` |
| 7 | W | Drop to 70. | drop to 70 | G\*: drop set 70 × ? (take the last reps, or ask). Today M | The drop regex needs `for R`. "to" stays after drop, never × |
| 8 | W | 80 for 8 at 8. | 80 × 8 @8 | G\*: set 80 × 8, RPE 8 | No RPE in the grammar on master. `@8` with no space becomes an exercise word, and `@ 8` or `at 8` after a scheme is read as a weight (G:117). The normaliser writes `@N` glued, so it never looks like the weight form |
| 9 | W | 82.5 for 6 at RPE 9. | 82.5 × 6 @9 | G\*: set 82.5 × 6, RPE 9 | "at RPE N" and "RPE N" both give `@N` |
| 10 | W | 85 for 5 at nine and a half. | 85 × 5 @9.5 | G\*: set 85 × 5, RPE 9.5 | Half steps only. "at 9.25" stays as said |
| 11 | W | Same, at 9. | same @9 | G\*: set 80 × 8, RPE 9 | RPE after `same` |
| 12 | I | Bench 3 sets of 8 at 80. | Bench 3×8 at 80 | G: lift Bench Press 3 × 8 at 80 kg | `at 80` stays: over 10, so a weight, never RPE |
| 13 | I | Deadlift 2 plates for 5. | Deadlift 2 plates for 5 | **PASS**: M logExercise (the model works out the load from plates and bar) | "for" sits between a noun and a number, so it stays. Plate counts need bar maths, not the grammar. GC rule 6 (whole words) keeps "plates" from matching an exercise |
| 14 | W | 8 reps. | 8 | G: set 80 × 8 (reps only) | A trailing "reps" goes |
| 15 | W | Add two and a half. | add 2.5 | G\*: next set 82.5 × 8 (GC 41). Today M | "two and a half" is 2.5 |
| 16 | W | 80 for 8, 80 for 8, 80 for 6. | 80 × 8, 80 × 8, 80 × 6 | G: sets, 3 sets into Bench | **Trap.** Keep commas between complete sets. `parseCommaSets` needs them |
| 17 | I | Squat 100, 5. | Squat 100, 5 | G: lift Back Squat 100 × 5 | Keep a comma between two bare numbers too. The grammar reads it as weight, then reps |
| 18 | W | 80 for ate. | 80 × 8 | G: set 80 × 8 | "ate" is 8 only in a number slot (after for or x, or alone in W) |
| 19 | W | Eighty into eight. | 80 × 8 | G: set 80 × 8 | en-IN: "into" means times, only between two numbers |
| 20 | I | Three into ten bench at eighty. | 3×10 Bench at 80 | G: lift Bench Press 3 × 10 at 80 kg | en-IN "into" for sets x reps |
| 21 | I | Bench 80 kg, 8 reps only. | Bench 80 kg, 8 | G: lift Bench Press 80 × 8 | en-IN emphasis "only" after a number goes, and so does "reps". The comma stays (row 17) |

### Pounds

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 22 | W | 185 pounds for 5. | 185 lb x 5 | G: set 83.9 kg x 5, unit lb | `MassUnit(parsing:)` already takes "pounds", but the normaliser writes `lb` so the relative regex `(kg\|lb)` matches |
| 23 | I | Deadlift 225 lbs. for 3. | Deadlift 225 lb x 3 | G: lift Deadlift 225 lb x 3 | The dot in "lbs." is not a sentence end |
| 24 | I | I weigh 182 pounds. | I weigh 182 lb | M: body weight 182 lb (after M3 slice 1; no tool on master since e0f476a) | No operator and no second number, so no set |
| 25 | I | Eleven stone four. | Eleven stone four | **PASS**: M body weight 72.1 kg (after M3 slice 1; no tool on master since e0f476a) | Stone is not a `MassUnit`. "N stone M" is protected so "four" never becomes reps |
| 26 | I | Twelve pounds fifty at Tesco. | £12.50 at Tesco | G\*: spend 12.50 GBP, note "Tesco" (M5 Money draft). Today M | "N pounds MM" with no lift word and no operator is money. Trap pair with row 22 |

### Filler and noise

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 27 | W | Okay Tess, 80 for 8. | 80 × 8 | G: set 80 × 8 | A leading "okay Tess", "hey Tess" or "Tess," goes, with its comma |
| 28 | W | Uh, uh, 80, 80 for 8. | 80 × 8 | G: set 80 × 8 | A repeated number collapses. "80," on its own is not a complete set, so its comma goes |
| 29 | W | Yeah. Yeah. 80 for 7. | 80 × 7 | G: set 80 × 7 | A sentence made only of fillers ("yeah", "okay", "right") goes |
| 30 | W | Come on. Come on. 80 for 7. | Come on come on 80 × 7 | M: logExercise 80 × 7 | Real words are never dropped, even a spotter's. The "Heard" line shows them. Gym noise is not the normaliser's job |
| 31 | W | 80 for, for 8. | 80 × 8 | G: set 80 × 8 | Stutter. "for for" before a number collapses. At the end it means "for 4" (speech-capture row 10), so the homophone check runs before repeats collapse |
| 32 | W | 80 for 7 for | 80 × 7 | G: set 80 × 7, shown as doubtful | A dangling operator after a full set goes (a plate clang or cut-off). "for" becomes 4 only when one number has been said |
| 33 | W | Um. | (empty) | none: "Didn't hear anything." | Fillers only |
| 34 | W | Test, 80 for 8. | 80 × 8 | G: set 80 × 8 | "Tess" misheard as "Test". It goes only as the first word with a comma straight after it |
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
| 61 | I | Spent twelve fifty at Tesco. | Spent 12.50 at Tesco | G\*: spend 12.50, note "Tesco" (M5 Money draft). Today M | After a money cue ("spent", "paid", "cost", £), "twelve fifty" is 12.50, never 1250 or 12 × 50 |
| 62 | I | Spent 1250 at Tesco. | Spent 1250 at Tesco | **PASS**: M LogSpend (after Money 1; until then no tool), ask "12.50 or 1250?" | The transcriber already wrote "twelve fifty" as 1250. The normaliser cannot know (open question 6) |
| 63 | I | Lunch was a tenner. | Lunch was £10 | M: LogSpend 10 GBP, note "lunch" (after Money 1; until then no tool) | "a tenner" £10, "a fiver" £5. Messy phrases go to the model (M5 draft) |
| 64 | I | 20 quid for petrol. | 20 quid for petrol | G\*: spend 20 GBP, note "petrol" | "for" after a money amount is never ×. "quid" stays, since the draft `MoneyAmount.parse` reads it |
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
| 72 | W | Eighty, no wait, eighty-five for eight. | 85 × 8 | G: set 85 × 8 | The correction replaces the number before the cue |
| 73 | W | 80 for 8, sorry, 9. | 80 × 9 | G: set 80 × 9 | It replaces the last number, here the reps |
| 74 | I | Buy oat milk, no wait, almond milk. | Buy oat milk, no wait, almond milk | **PASS**: M addGroceries ["almond milk"] | A correction cue with no number or weekday after it is not resolved. The phrase skips the grammar, which would otherwise add three lines including "no wait" |

### Must not be rewritten

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 75 | I | Remind me to eat five a day. | Remind me to eat five a day | G: task "Eat five a day", no date | Protected phrase. "a day" is not a date |
| 76 | I | Meeting in Room 101 at three. | Meeting in Room 101 at 3 | G\*: task "Meeting in Room 101", Fri 16 Oct 15:00. Today G gives Fri 03:00 | "101" is never split or used as a weight. "at 3" is a time; a daytime bias belongs in `TessDates` |
| 77 | I | Book a table for two at seven. | Book a table for 2 at 7 | G\*: task "Book a table for 2", today 19:00 (GC 45). Today G gives Fri 07:00 | "for 2" has no number before it, so no x |
| 78 | I | Work nine to five on Saturday. | Work nine to five on Saturday | G: task "Work nine to five on", Sat 17 Oct 09:00 | **Trap.** "to" between numbers would give "9 × 5". Time ranges stay words |
| 79 | W | Two-three more sets. | Two-three more sets | **PASS**: M, nothing to log | en-IN "two or three". Never 2×3, 23, or a reps-only set of 2 |
| 80 | I | Remind me to water the plants 2-3 times a week. | Remind me to water the plants 2-3 times a week | G: task "Water the plants 2-3 times a week", no date | A range "N-M" stays. Recurrence is not parsed |

### "by" between numbers (item 100)

| # | Ctx | Raw transcript | Normalised | Expected grammar intent | Note |
|---|---|---|---|---|---|
| 81 | W | Eighty by eight. | 80 × 8 | G: set 80 × 8. Tess: "Set N logged. 80 × 8." | `by` between two numbers becomes × (rule 12). Without the rewrite master gives nil: the set regex reads x or for, not by (`TessGrammar.swift:286`) |
| 82 | I | Bench three by eight at eighty. | Bench 3×8 at 80 | G: lift Bench Press 3 × 8 at 80 kg. Tess on master: "Bench 3 x 8 at 80. Added to today." (plain x, `TessCaptureEngine.swift:211`; × once Core follows Design d288c11, point 4) | Sets by reps, as row 12 |
| 83 | I | Pay the gas bill by seven. | Pay the gas bill by 7 | G: task "Pay the gas bill", today 19:00 (`by` is a lead word the date reader drops, `TessGrammar.swift:544`; bare 7 is the next not yet passed) | **Trap.** `by` before a single number is a time word, never ×. Pair with row 43 |

Count: 83 rows. Routes: 46 G (grammar parses today), 20 G\* (a grammar change first, model until then), 7 M, 9 **PASS** (rows 6, 13, 25, 42, 45, 57, 62, 74, 79) and 1 none. Rows 81 to 83 were added for item 100 and traced at `fdcaee4`; the master checks below cover rows 1 to 80. Rows 36, 50, 56, 57 and 60 are caught by the grammar with a wrong result today; the normaliser cannot fix those, the grammar rules named in each row do.

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
10. **Homophones in fixed slots.** `for` at the end becomes 4 only when exactly one number came before it; after a full W × R a dangling `for` is dropped (rows 31, 32). `two` after `remind me`, `need`, `have` becomes `to` only before a verb, never before `days`, `weeks`, `hours`, `minutes`, `times` (row 60). A leading `by` becomes `buy` only when a number does not follow (rows 42, 43).
11. **Collapse repeats.** An immediate repeat of the same token (`to to`, `80, 80`, `for, for` before a number) collapses to one. This runs after step 10, so a trailing `for for` has already become `for 4` (rows 28, 31).
12. **Units and operators.** `kilos`, `kilo`, `kilograms`, `kgs`, `k` after a number become `kg`; `pounds`, `lbs`, `lbs.` become `lb` (rows 4, 22, 23). `for`, `by`, `times`, `into` between two numbers become `×` (the on-screen sign; the grammar reads it as x), except after `drop to`, in money, or after a protected place noun (rows 4, 19, 20, 64, 81, 82). `by` before a single number is a time word and stays (row 83). `to` between two numbers is never rewritten (row 78). `N sets of M` becomes `N×M`. A trailing `reps`/`rep` and an en-IN `only` after a number go (rows 12, 14, 21).
13. **RPE.** `at N`, `at RPE N` or `RPE N` with N from 5 to 10 in half steps, straight after a full W × R or `same`, becomes `@N` with no space. `at N` over 10 stays (it is a weight) (rows 8 to 12).
14. **Times and days.** `7:00 PM`, `7 p.m.`, `7 pm` become `7pm`; `half past three` 3:30; `quarter to seven` 6:45; `o'clock` goes; `tomorrow morning` becomes `tomorrow 9am` (afternoon 2pm, evening 6pm); `itself` after a day goes; `next <weekday>` becomes `<weekday>`; ordinals become `20th`; `in twenty minutes` becomes `in 20 min`. The normaliser never resolves a date and never reads the clock (rows 43, 48 to 55).
15. **Reorder reminders.** `remind me <date phrase> to X` becomes `remind me to X <date phrase>`, for date phrases step 14 knows. Unknown ones (`day after tomorrow`) stay put (rows 47, 48, 52, 55, 56, 58, 59).
16. **Commas.** Keep a comma that sits between two complete sets, between two bare numbers, or between list items. Drop a comma left next to a removed word, and a duplicate comma (rows 16, 17, 21, 28).
17. **Empty means nothing.** If nothing is left, return an empty string: no capture; the Speak layer says "Didn't hear anything." (row 33; `../speak-first-use.md` 10a to 10c).

What it never does: guess a domain (no added `buy`, commas or `remind`, row 39), split run-ons, resolve a date, or touch a note body.

## Open questions

1. **Case.** These rows keep the transcriber's case so task titles and notes keep names ("Call Ravi"). The 30 rows in `speech-capture.md` lowercase everything. Pick one before V1 tests are written.
2. **Do we rewrite `for` at all?** The grammar already accepts `W for R`. Rewriting adds risk ("table for 2", "Room 101 for 2 nights") for little gain, and since #248 it changes the parse: the 2 × 10 ask reads only x or by (`TessGrammar+Live.swift:123`), so "two for ten" written as `2 × 10` would ask where `2 for 10` does not. Default suggestion: keep `for` in the text the grammar gets, rewrite only `times`, `by`, `into`, and show × for any of them in the clean sentence on screen (Design d288c11, point 4). The live-workout rules below already keep `for`.
3. **RPE grammar.** Rows 8 to 11 need a grammar change: `@N` after W × R, N from 5 to 10. It collides with GC 26 (`bench 80 × 8 at 7`, ambiguous lift or time). Does `at 8` in an idle lift mean RPE, a time, or ask? Live workout only is the safe default.
4. **Weekday meaning.** "Thursday" on a Thursday is today (row 51), which conflicts with `TessDates` today (GC 44). And does "next Tuesday" on a Thursday mean 20 or 27 Oct? UK usage is split. Default suggestion: 20 Oct, with the 27th as a one-tap alternative.
5. **Should the normaliser read the clock?** "in 20 minutes" and "day after tomorrow" (rows 50, 56) need `now`. Suggestion: no. Add them to `TessDates`, which already has the clock, and keep the normaliser pure.
6. **Money shape.** The transcriber may write "twelve fifty" as 1250 (row 62). Should a 4-digit spend at a food shop always show "12.50 or 1250?" Also which home currency (GBP or INR) for amounts with no symbol, and do `quid` and `rupees` become symbols or stay words for the M5 parser?
7. **Return type.** Row 74 needs a "skip grammar" flag, and the ghost row needs the raw heard line. Suggest `struct Spoken { text: String; skipGrammar: Bool; heard: String }` instead of a bare `String`.
8. **Note bodies.** Rule 3 keeps a note body exactly as heard, so "note, uh, call the physio" keeps "uh". Is that right, or should fillers go there too?
9. **Part-of-day times.** Are morning 9am, afternoon 2pm, evening 6pm his times? `tonight` is already 20:00 in the grammar.
10. **en-IN on device.** `SpeechTranscriber` support for en-IN is unverified (`speech-capture.md`). If he uses en-GB with an Indian accent, do "lakh", "into" and "two-three" survive transcription, and does the en-IN locale write `1,00,000`?
11. **Protected phrase list.** A fixed list ("five a day", "seven eleven") will always miss something. Should a capitalised word from the transcriber also protect the numbers next to it, and who owns the list?
12. **"Test" for "Tess".** Rows 34 and 35 rely on the transcriber putting a comma after the wake word. Measure on device in V3 before relying on it.
13. **Model tools.** Many M rows expect `addGroceries`, `LogSpend` or `rescheduleTask`. `TessToolCatalog.allowed` on master is only `logExercise`, `createTask`, `createRoutine`, `createPlan`, `createNote`, `createList`, `startShop` (`logBodyWeight` was removed in e0f476a; body weight comes with M3 slice 1, see `../m3-1-2-brief.md`). `addGroceries` and `rescheduleTask` are among T2's 10 tools; `LogSpend` joins the registry with Money slice 1, so LogSpend rows expect no tool until then.
14. **Default unit.** Rows with no unit default to kg. If he lifts in pounds on some days, should the normaliser or the grammar use the entry's last unit?

## Master check

Checked against `origin/master` at `254ed5168eda99adaab6aa5b07d27a1f8923e5bd` (`254ed51`, merge of PR #139, 2026-10-15). Static hand trace, nothing was run. Clock Thu 15 Oct 2026 18:00. W has the workout as the running process and the Bench Press entry in focus (last set 80 × 8); I has no process; C has a cook running; S has the groceries list as the running process.

**Files.** `G:` is `TesseraCore/Sources/TesseraTess/TessGrammar.swift` (parse order, question guard, process ownership, reschedule, notes, relative sets, comma sets, lifts, tasks, normalize, `TessDates`). `K:` is `TessGrammar+Kitchen.swift` (lists, shop, timers, buy/get, comma groceries, cook). The Tess lines come from `TessCaptureEngine.swift`. There is no `grammar-misfires.md` in `fixtures/`, so the root causes below point at the `grammar-collisions.md` rules (GC n) that the rows already name.

**How PASS is judged.** G rows pass when master gives the intent as written. G\* rows pass only when master already gives the target intent; a G\* row that still falls to the model is a FAIL marked "G\* gap" (safe, nothing wrong is written). M and **PASS** rows pass when the grammar returns nil. A FAIL marked "wrong write" means the grammar claims the phrase and makes the wrong object.

**Owners.** Builder B owns the normaliser in the app's Speak path. Core owns the grammar.

**Changes since `0c0bfdb` that the table above does not know yet.** Shop runs now own bare nouns (G:120-128), so row 45 is G today. A weekday said on that same day now means today, at the next whole hour when no time is given (G:439-443), so row 51 gives today 19:00, not Thu 22 Oct. The scheme regex the rows call G:117 is now G:238.

| # | Result | Current parse on master (deciding rule) | Proposed fix (owner) |
|---|---|---|---|
| 1 | PASS | set 85 × 6 kg, full (relative full regex, G:178) | |
| 2 | PASS | set 107.5 × 3 kg (G:178) | |
| 3 | PASS | lift Back Squat, 1 × 5 at 102.5 kg (scheme G:238, alias "squat" G:302, G:252) | |
| 4 | PASS | set 80 × 8 kg (G:178, " kg" before " x ") | |
| 5 | PASS | set 80 × 8, phrase same (G:165) | |
| 6 | PASS | nil, goes to the model (no rule matches; parseTask needs a date or prefix, G:369) | |
| 7 | FAIL (G\* gap) | nil, goes to the model. Drop regex needs `for R` (G:171) | Core: make `(for or x) R` optional in the drop regex and take the last set's reps |
| 8 | FAIL (G\* gap) | nil, goes to the model. `@8` is read as an exercise word, which fails to resolve (G:285, G:331) | Core: RPE rule, `@N` (5 to 10, half steps) after a full W × R or `same`, live workout only |
| 9 | FAIL (G\* gap) | nil, goes to the model (same as row 8) | Core: RPE rule (row 8) |
| 10 | FAIL (G\* gap) | nil, goes to the model (same as row 8) | Core: RPE rule (row 8) |
| 11 | FAIL (G\* gap) | nil, goes to the model. `same @9` is not in the same list (G:165) | Core: RPE rule (row 8), also after `same` |
| 12 | PASS | lift Bench Press, 3 × 8 at 80 kg (scheme with `at`, G:238, G:266) | |
| 13 | PASS | nil, goes to the model. "deadlift plates" resolves to no exercise (whole words, G:328-346) | |
| 14 | PASS | set 80 × 8, reps only (G:168) | |
| 15 | FAIL (G\* gap) | nil, goes to the model. `add` is skipped as a lift word and there are no reps (G:285, G:245) | Core: GC 41, `add N` in a live workout is the next set at last weight + N |
| 16 | PASS | sets, 3 sets into Bench: 80 × 8, 80 × 8, 80 × 6 (comma sets, each via the relative set, G:226) | |
| 17 | PASS | lift Back Squat, 1 × 5 at 100 kg (two-part comma rule, G:206) | |
| 18 | PASS | set 80 × 8 (G:178) | |
| 19 | PASS | set 80 × 8 (G:178) | |
| 20 | PASS | lift Bench Press, 3 × 10 at 80 kg (scheme with weight elsewhere, G:267) | |
| 21 | PASS | lift Bench Press, 1 × 8 at 80 kg (two-part comma rule, G:206) | |
| 22 | PASS | set 185 lb x 5, stored 83.9 kg, unit lb (G:178) | |
| 23 | PASS | lift Deadlift, 1 × 3 at 225 lb (token read, G:276-288; exact name G:316) | |
| 24 | PASS | nil, goes to the model (one number, no reps, G:245) | |
| 25 | PASS | nil, goes to the model (no rule matches) | |
| 26 | FAIL (G\* gap) | nil, goes to the model. There is no money rule on master | Core: Money grammar (M5 draft `spend`) |
| 27 | PASS | set 80 × 8 (G:178) | |
| 28 | PASS | set 80 × 8 (G:178) | |
| 29 | PASS | set 80 × 7 (G:178) | |
| 30 | PASS | nil, goes to the model. Lift words "come on come on" fail the 3-letter floor (G:331) | |
| 31 | PASS | set 80 × 8 (G:178) | |
| 32 | PASS | set 80 × 7 (G:178). Note: master has no "doubtful" mark on a set | Builder B: carry a doubt flag on the normaliser output (open question 7); not a grammar change |
| 33 | PASS | nil, empty text (G:54). The command bar also drops empty input (`Features/Command/BottomChrome.swift:384`) | Builder B: the "Didn't hear anything." line belongs to the Speak path; it is not on master |
| 34 | PASS | set 80 × 8 (G:178) | |
| 35 | PASS | task "Test the smoke alarm", Sat 17 Oct 09:00 (parseTask, G:367; weekday G:414) | |
| 36 | FAIL (wrong write) | task "I'd like a reminder for to book the MOT", Fri 16 Oct 09:00 (date cue, G:367-370) | Builder B: treat `I'd like a reminder (for <date>) to X`, `set a reminder`, `can you remind me` as `remind me`, then rule 15 gives "Remind me to book the MOT Friday" (a correct G task). Core backstop: a title with `for to` or ending in `to` goes to the model (GC 5) |
| 37 | PASS | task "Call Ravi", Fri 16 Oct 09:00 (explicit `remind me to`, G:356-366) | |
| 38 | PASS | groceries ["2 lemons", "some milk"] (buy prefix, K:40; split on "and", K:171) | |
| 39 | PASS | nil, goes to the model (no prefix, no comma, no date) | |
| 40 | PASS | groceries ["12 eggs"] (get prefix, gettable, K:45, K:149) | |
| 41 | PASS | groceries ["6 eggs", "a pint of milk"] (K:40) | |
| 42 | PASS | nil, goes to the model (one number, no date) | |
| 43 | PASS | task "By send the invoice", Fri 16 Oct 17:00 (5pm passed, so tomorrow, G:429-434) | |
| 44 | PASS | groceries ["1 kg atta", "0.5 kg dahi"] (K:40; parseLift fails as reps 0.5 is under 1, G:245) | |
| 45 | PASS | groceries ["parmesan"] (shop run owns bare nouns, G:120-128). G\* target reached; GC 42 landed | |
| 46 | FAIL (G\* gap) | nil, goes to the model. `add` is not a grocery prefix (K:40) | Core: GC 40, `add X` outside a workout is groceries unless X names a list |
| 47 | PASS | task "Call the bank", Fri 16 Oct 09:00 (G:356, G:414) | |
| 48 | PASS | task "Renew the passport", Tue 20 Oct 09:00 (nextDate, G:458) | |
| 49 | PASS | task "Call the dentist", Fri 16 Oct 09:00 (tomorrow + 9am, G:412, G:420) | |
| 50 | FAIL (wrong write) | task "Take the chicken out in 20 min", no date (explicit task, G:369) | Core: `TessDates` reads `in N min` / `in N hours` from the clock (today 18:20) |
| 51 | PASS | task "Pay the window cleaner", today Thu 15 Oct 19:00 (same-day weekday, next whole hour, G:439-443). G\* target reached | |
| 52 | FAIL (wrong write) | task "Put the bins out", Thu 22 Oct 08:00 (`at 8` on a 24-hour clock, passed, so +7 days, G:417, G:445) | Core: GC 7, Product's bare-hour rule (decisions.md 4:26 PM PT: 1 to 6 mean pm, 7 to 11 the next one not yet passed today, 12 noon, a passed time lands tomorrow), so today 20:00 |
| 53 | FAIL (wrong write) | task "Dentist on the 20th", Fri 16 Oct 03:30 (`20th` is not a date; `at 3:30` passed today, so tomorrow, G:417, G:429-434) | Core: GC 7, ordinals (`20th`, `on the 20th`) in `TessDates` plus the bare-hour rule (3 means pm), giving Tue 20 Oct 15:30 |
| 54 | PASS | task "Call mum", today 19:00 (G:417, G:470) | |
| 55 | PASS | task "Send the form", Fri 16 Oct 09:00 | |
| 56 | FAIL (wrong write) | task "Day after to pay rent", Fri 16 Oct 09:00 (only `tomorrow` is a date word, G:412) | Core: `TessDates` reads `day after tomorrow` as +2 days, and parseTask drops a `to` left at the start after the date |
| 57 | FAIL (wrong write) | task "Prepone the dentist to", Wed 21 Oct 09:00. `prepone` is not in the reschedule verbs (G:133), so G:87 does not stop it | Core: add `prepone` and `bring forward` to `rescheduleShape` (G:133). Then it is a reschedule if one open task matches, or the model if not (GC 5, GC 13) |
| 58 | PASS | task "Clean the car", Sat 17 Oct 09:00 | |
| 59 | PASS | task "Collect the courier", Fri 16 Oct 09:00 | |
| 60 | FAIL (wrong write) | task "2 days before the MOT", no date (explicit task, G:369) | Core: parseTask sends `N days/weeks before/after X` to the model instead of making a title of it |
| 61 | FAIL (G\* gap) | nil, goes to the model (no money rule) | Core: Money grammar (row 26) |
| 62 | PASS | nil, goes to the model (`1250` is not a time, G:470) | |
| 63 | PASS | nil, goes to the model | |
| 64 | FAIL (G\* gap) | nil, goes to the model. One number, no reps (G:245); no money rule | Core: Money grammar (row 26) |
| 65 | FAIL (G\* gap) | nil, goes to the model (no money rule) | Core: Money grammar (row 26) |
| 66 | FAIL (G\* gap) | nil, goes to the model (no money rule) | Core: Money grammar (row 26) |
| 67 | PASS | nil, goes to the model (one number, G:245) | |
| 68 | FAIL (G\* gap) | nil, goes to the model (no money rule) | Core: Money grammar (row 26), keeping "seven eleven" as the note |
| 69 | PASS | note "The bar felt heavy today." (parseNote, G:156) | |
| 70 | PASS | note "eighty felt easy" (G:156) | |
| 71 | PASS | note "the squat rack in bay two is broken" (G:156) | |
| 72 | PASS | set 85 × 8 (G:178) | |
| 73 | PASS | set 80 × 9 (G:178) | |
| 74 | FAIL (wrong write) | groceries ["oat milk", "no wait", "almond milk"] (buy prefix and comma split, K:40, K:171) | Builder B: return the skip-grammar flag and, when it is set, run a `TessRouter` with only `OnDeviceTessModel` (both are public). Core backstop: the grocery splitter refuses a list with a correction cue item (`no wait`, `sorry`, `I mean`) |
| 75 | PASS | task "Eat five a day", no date (G:356-370) | |
| 76 | FAIL (wrong write) | task "Meeting in Room 101", Fri 16 Oct 03:00 (`at 3` on a 24-hour clock, passed, so tomorrow, G:417, G:429-434) | Core: GC 7, Product's bare-hour rule (decisions.md 4:26 PM PT: 1 to 6 mean pm, 7 to 11 the next one not yet passed today, 12 noon, a passed time lands tomorrow): 3 means 15:00, already passed today, so Fri 15:00 as the row expects |
| 77 | FAIL (wrong write) | task "Book a table for 2", Fri 16 Oct 07:00 (G:417, G:429-434) | Core: GC 7 / GC 45 bare-hour rule (7 is the next one not yet passed), giving today 19:00 |
| 78 | PASS | task "Work nine to five on", Sat 17 Oct 09:00 (G:414) | |
| 79 | PASS | nil, goes to the model (no digits) | |
| 80 | PASS | task "Water the plants 2-3 times a week", no date (G:356-370) | |

### Counts

- **57 PASS, 23 FAIL** out of 80.
- Of the 23 FAILs, 13 are G\* gaps that fall safely to the model (rows 7 to 11, 15, 26, 46, 61, 64 to 66, 68) and 10 are wrong writes where the grammar makes the wrong object (rows 36, 50, 52, 53, 56, 57, 60, 74, 76, 77).
- By owner: 21 Core, 2 Builder B (rows 36 and 74, each with a Core backstop). Rows 32 and 33 pass the grammar but need Builder B for the doubt mark and the "Didn't hear anything." line.
- The normalised text is never the cause of a FAIL here: every row's normalised text is what the grammar needs, except rows 36 and 74, where the normaliser could do more.

### Top fixes, by rows fixed

1. **Money grammar, M5 draft `spend` rule (Core): 6 rows** (26, 61, 64, 65, 66, 68).
2. **RPE `@N` after a full set or `same`, live workout only (Core): 4 rows** (8, 9, 10, 11).
3. **GC 7 in `TessDates`: Product's bare-hour rule (decisions.md 4:26 PM PT: 1 to 6 mean pm, 7 to 11 the next one not yet passed today, 12 noon, a passed time lands tomorrow) for a bare `at N`, plus ordinals (Core): 4 rows** (52, 53, 76, 77), all wrong writes today.
4. **Relative dates in `TessDates`: `in N min`, `day after tomorrow` (Core): 2 rows** (50, 56), both wrong writes today.
5. **`add` by process: `add N` in a workout is the next set (GC 41), `add X` elsewhere is groceries (GC 40) (Core): 2 rows** (15, 46).

Then one row each: drop with no reps (row 7, Core), reminder openers in the normaliser (row 36, Builder B), `prepone` as a reschedule verb (row 57, Core), relative offsets to the model (row 60, Core), and the skip-grammar route (row 74, Builder B).

## Post-hotfix check (master db049cb)

Re-traced by hand against `origin/master` at `db049cbedeb6db3563599b9023ed8e2eb592d7b4`, which includes #153 (`82c51d9`, grammar hotfix) and #151 (Home swipe, no grammar change). Same clock and contexts as the Master check above; the input is each row's normalised text. Nothing was run. The 23 FAIL rows were traced again in full, and every PASS row was spot-checked against what the hotfix changed: the question guard (raw `?`; `is`, `are`, `who`, `where`, `which`; `do/can/should i`), the shop-run branch, `parsePastLog`, `TessDates.find` (bare hours, a passed time rolls to tomorrow, lead words `on`/`by`/`this`/`for` dropped), and `notGroceries` on `buy`/`get`. Expected results follow `product/decisions.md`, the 4:26 PM bare-hour calls and the 4:41 PM time-form calls.

### New counts

- **60 PASS, 20 FAIL** out of 80 (was 57 and 23).
- Of the 20 FAILs, **7 are wrong writes** (was 10): rows 36, 50, 53, 56, 57, 60, 74. **13 are G\* gaps** that go to the model (unchanged): rows 7 to 11, 15, 26, 46, 61, 64 to 66, 68.

### Rows that changed status

| # | Was | Now | Current parse on master |
|---|---|---|---|
| 52 | FAIL (wrong write) | PASS | task "Put the bins out", today 20:00. `Thursday` is today, so the bare 8 takes the next one that hasn't passed |
| 76 | FAIL (wrong write) | PASS | task "Meeting in Room 101", Fri 16 Oct 15:00. `at 3` is 15:00, already passed, so tomorrow |
| 77 | FAIL (wrong write) | PASS | task "Book a table for 2", today 19:00 |

Changed result, same status:

- **Row 53** (`Dentist on the 20th at 3:30`): still a wrong write, now task "Dentist on the 20th", Fri 16 Oct 15:30 (was 03:30). The hour is right; `20th` is still not a date.
- **Row 36**: still a wrong write, now titled "I'd like a reminder to book the MOT" (the `for` before `Friday` is dropped), Fri 09:00.
- **Row 43** (PASS): the title is now "Send the invoice", Fri 17:00, not "By send the invoice", because `by` before `5pm` is dropped. Better than the row's written intent.
- **Row 78** (PASS): the title is now "Work nine to five", Sat 09:00 (the `on` before `Saturday` is dropped).

### Regressions

None. The 57 rows that passed still pass. Checked in particular: rows 38, 40, 41 and 44 stay groceries under `notGroceries` (`a pint of milk` finds the dairy aisle on its last word; `some milk`, `1 kg atta` and `0.5 kg dahi` skip the gift shape); row 45 stays groceries in the shop run; row 35 stays Sat 09:00 (`alarm` is an am cue, but the row has no clock time); row 67 (`Paid 120000 rs deposit`) has a past verb but no day, so `parsePastLog` leaves it to the model as before; rows 61 and 65 start with `Spent`, which is not in `pastVerbs`, so they still go to the model.

### Top 5 remaining root causes, by row count

1. **Money grammar, M5 `spend` rule (Core): 6 rows** (26, 61, 64, 65, 66, 68), all G\* gaps.
2. **RPE `@N` after a full set or `same`, live workout only (Core): 4 rows** (8 to 11), all G\* gaps.
3. **Relative dates in `TessDates`, `in N min` and `day after tomorrow` (Core): 2 rows** (50, 56), both wrong writes.
4. **`add` by process, GC 40 and GC 41 (Core): 2 rows** (15, 46), both G\* gaps.
5. **Ordinal dates, `on the 20th` (Core): 1 row** (53), a wrong write. The bare-hour half of the old fix 3 is done.

Then one row each: drop with no reps (row 7), reminder openers (row 36, Builder B, with a Core backstop), `prepone` as a reschedule verb (row 57), relative offsets to the model (row 60), and the skip-grammar route for a spoken correction (row 74, Builder B). Of the 7 wrong writes left, 5 are Core's (50, 53, 56, 57, 60) and 2 are Builder B's (36, 74).

## Live-workout number words (board item 78)

For: Core (the normaliser in `TesseraCore`) and Builder B (Speak). Research lab. Date: 2026-10-16.

K811 and K812 are the two group K rows that still miss on master (`set-logger-rerun.md`): no number-word normaliser
exists, so spoken numbers reach the grammar as words. This section gives the normaliser's expected output for
them and for 24 more live-workout number phrases (N01 to N24), and the parse the grammar should then give under
S701 to S706 and the "N reps" exemption.

**Master read.** `origin/master` at `e75f40f` (merge of PR #210, set guard follow-up: dictation periods, commas,
non-RPE `at`, N reps). "L:n" is `TessGrammar+Live.swift` line n, "TG:n" is `TessGrammar.swift` line n, both at
`e75f40f`. No Swift toolchain: each expected parse is a hand trace of the normalised text through master, and
master already gives every one of them once the normaliser hands it that text. Nothing was run. Raw transcripts
are guesses at what `SpeechTranscriber` writes, not recordings.

**"N reps" exemption.** PR #210 reads a number followed by `reps` as reps whatever the last weight (L:71-76), and
`product/decisions.md` (7:43 PM PT) records it as a coordinator default. **Product has not confirmed it yet.** N07
and N10 depend on it.

**Contexts.** Thu 15 Oct 2026 18:10 America/Los_Angeles, starter kit, as group K.
- **W**: live workout, Bench Press (barbell, kg) in focus, last set 80 × 8. Loads 20 to 177.5 in 2.5 kg steps.
- **D**: live workout, Dumbbell Bench Press (dumbbells, kg) in focus, last set 24 × 10. Loads 2 to 50 in 2 kg steps.
- **I**: idle, nothing in focus.

**Parse** is one of: set (weight x reps, with kind or RPE), reps only (at the last weight), same, sets (a list),
nil (nothing written, the model reads it or asks), or task.

| id | raw transcript | ctx | normalised | expected parse |
|---|---|---|---|---|
| K811 | eighty two and a half for eight | W | `82.5 for 8` | set 82.5 × 8 (TG:258 full set; 82.5 is a load) |
| K812 | a hundred for five at eight | W | `100 for 5 at 8` | set 100 × 5, RPE 8 (L:50-58), as K798 |
| N01 | a hundred and five | W | `105` | nil: a weight with no reps, over 50 (S701, L:72) |
| N02 | a hundred and five for three | W | `105 for 3` | set 105 × 3 |
| N03 | a hundred, five | W | `100, 5` | nil: the comma path reads `100` as a weight and `5` as reps, so one set from two parts goes to the model (TG:81-85) |
| N04 | eighty two point four | I | `82.4` | nil: no entry, no reps, no date. The model reads it as body weight (decisions.md D12) |
| N05 | eighty two  point four for six | W | `82.4 for 6` | set 82.5 × 6 (S703, L:115-125); Tess says "Set N logged. 82.5 × 6, nearest load to 82.4." (`TessCaptureEngine.swift:224-232` at `fdcaee4`; the old "82.4 isn't loadable." went in #248) |
| N06 | one oh five for five | W | `105 for 5` | set 105 × 5 |
| N07 | twenty four reps | D | `24 reps` | reps only, 24 × 24 (N reps exemption, L:71-73) |
| N08 | twenty four | D | `24` | nil: within two loads of the last weight, as K782 (S701) |
| N09 | eight at three | W | `8 at 3` | nil: `at 3` is no RPE (5 to 10), so the model; never a task (L:54-55) |
| N10 | eight reps at nine | W | `8 reps at 9` | reps only, 80 × 8, RPE 9 |
| N11 | same at nine and a half | W | `same at 9.5` | same, 80 × 8, RPE 9.5 |
| N12 | eighty for 8 | W | `80 for 8` | set 80 × 8 (mixed words and digits) |
| N13 | 100 for five at 8 | W | `100 for 5 at 8` | set 100 × 5, RPE 8 |
| N14 | a couple more | W | `a couple more` | nil: no number reaches the grammar; never 2 reps or 2 sets |
| N15 | ten ten ten | W | `10 10 10` | nil: no set shape and no words (TG:325), so the model |
| N16 | ten, ten, ten | W | `10, 10, 10` | sets, 3 into Bench Press: 80 × 10 each (comma path, TG:81-85) |
| N17 | one more set | W | `one more set` | nil: not in the same list (TG:245), so the model; `one` stays a word |
| N18 | a hundred for for | W | `100 for 4` | set 100 × 4 (a trailing `for` after one number is 4) |
| N19 | eighty four eight | W | `84 8` | nil: two numbers, no operator. Never 80 × 8 by guess |
| N20 | a eighty for a eight | W | `80 for 8` | set 80 × 8 (`a` before a plain number word is a filler) |
| N21 | and eighty for eight reps | W | `80 for 8` | set 80 × 8 (leading `and` goes; `reps` after a full set goes) |
| N22 | drop to seventy two for ten | W | `drop to 72 for 10` | set 72.5 × 10, drop (as K789); Tess says "Drop set logged. 72.5 × 10, nearest load to 72." |
| N23 | call mum at seven | W | `call mum at 7` | task "Call mum", today 19:00 (not a set core, L:94-96, so the task rule, as A121) |
| N24 | plus five | W | `+5` | nil: a signed change goes to the model (S702, L:40) |
| N25 | eighty two and a half by six | W | `82.5 × 6` | set 82.5 × 6. `by` between two numbers becomes × (rule 12); the set regex has no `by` (`TessGrammar.swift:286`), so the normaliser has to rewrite it. Tess says "Set N logged. 82.5 × 6." |
| N26 | two by ten | W | `2 × 10` | the 2 × 10 ask: "2 × 10: 2 sets, or 2 kg?" (`TessGrammar+Live.swift:123`, `TessSetCountAsk.swift:30`); 2 is under half of 80. Typed "2 by 10" asks the same. "two for ten" stays `2 for 10` and does not ask (open question 2) |

Count: 28 rows (K811, K812, N01 to N26). Parses: 14 set or reps-only writes, 1 same, 1 sets, 10 nil, 1 task, 1 ask.
On master today (no normaliser) the raw words give nil for every row but one: N13 (`100 for five at 8`) is not a
set shape to L:101, so it falls through and the task rule reads `at 8` as 20:00, making task "100 for five". A
wrong write until the normaliser lands.

**Two traps if the normaliser gets them wrong.** Collapsing `ten ten ten` to `10`
(old rule 11) logs one 80 × 10 reps-only set, a wrong write (N15). Keeping `reps` after a full set (`80 for 8 reps`) is safe but a
miss: the anchored set regex (TG:258) fails and L:79 sends it to the model (N21).

### Number-word rules, in order

These sit inside rule 7 of the list above and change rules 11 to 13 for live-workout numbers. Each step sees the
output of the one before; the function stays pure and idempotent, and digits pass through untouched (N12, N13).

1. **Lowercase, collapse spaces, drop the end period.** Two or more spaces become one (N05). Keep commas.
2. **Leading fillers.** A leading `and`, `so`, `okay` goes (N21). `a` goes when the next word is a plain number
   word (`a eight`, N20), but stays before `hundred`, `thousand`, `dozen`, `couple`, `few`, `half` and `bit`.
3. **Protect.** `one more`, `one more set`, `a couple`, `a few`, `same again` and number words before a load noun
   (`two plates`) are never turned into digits (N14, N17, K808).
4. **Read number runs.** A run is a series of number words with no comma in it. `a hundred` and `one hundred` are
   100; `and` joins only after `hundred` or `thousand` (`a hundred and five` 105, N01); a tens word plus a unit word
   is one number (`eighty two` 82, `twenty four` 24); `point` gives a decimal (`82.4`, N05); `and a half` adds 0.5
   (K811); `oh` is 0 only inside a run (`one oh five` 105, N06); `one twenty five` is 125 (100 to 300 only). Digits
   already in the run join it (`82 and a half` 82.5).
5. **A comma ends a run.** `a hundred, five` is `100, 5`, never 105 (N03).
6. **Repeats.** A number said twice right before an operator is a stutter and collapses (`eighty eighty for
   eight`). Three or more equal numbers in a row are kept, each as said (N15, N16). Never add commas.
7. **`for`, `by` and `four`.** `for` between two numbers stays `for` (the grammar reads it; the clean sentence on screen shows ×). `by` between two numbers becomes × (N25, N26), since the set regex does not read `by`. A `for` at the end after
   exactly one number is 4 (N18). `four` inside a run stays a number, so `eighty four eight` is `84 8` (N19).
8. **`reps`.** Keep `reps` after a bare number (N07, N10); make `rep` after a number `reps`, since the grammar
   strips only ` reps` (TG:478-480). Drop `reps` after a full `W for R` (N21).
9. **`at N`.** Keep `at N` as heard (`at 8`, `at 9.5`); since PR #205 the grammar reads both `at N` and `@N`
   (L:50). Never turn a bare `at N` into a clock time in the normaliser (N09, N23).
10. **Signs.** `plus N` and `minus N` at the start become `+N` and `-N` (N24, K807); `up N` and `down N` stay.
11. **Units.** `pounds`, `lbs`, `lb` after a number become `lb`; `kilos`, `kg`, `k` become `kg`. No unit means kg.

What it never does here: snap a weight (that is S703, in the grammar), decide reps against weight (S701), or guess
an operator between two bare numbers (N19).

### Ambiguous cases and defaults

| case | default | why |
|---|---|---|
| `a hundred and five`: 105, or 100 and 5 reps | 105 | British "a hundred and five" is one number. A comma (N03) or `for` splits it |
| `a hundred, five`: 100 × 5, or a pause | `100, 5`, the model asks | Dictation commas are unreliable; one set from two parts is not guessed |
| `eighty four eight`: 84 then 8, or 80 for 8 | `84 8`, the model | Rewriting `four` to `for` mid-run would break every real 84 |
| `ten ten ten`: three sets of 10, or a stutter | keep all three; no comma, so the model | Collapsing it logs one wrong set; adding commas is guessing |
| `twenty four reps` with dumbbells at 24 | reps, 24 × 24 | The "N reps" exemption, **not yet confirmed by Product** |
| `eight at three`: RPE 3, rep 3, or 3 pm | nil, the model | S704 allows RPE 5 to 10 only; a set phrase is never a task |
| `a couple` (more, reps, sets) | words kept, the model | "a couple" is 2 or 3 in speech |
| `one more set` vs `one more` | `one more` is the same set; `one more set` goes to the model | B301 and K779; "one more set" is often a plan, not a log |

### Decisions for Product

1. **Confirm the "N reps" exemption** (N07, N10). It is on master since PR #210 as a coordinator default only.
2. **`ten ten ten`** (N15): model (default), or three reps-only sets at the last weight like `ten, ten, ten` (N16).
3. **`a hundred, five`** (N03): model (default), or 100 × 5 when the second number is 1 to 50.

## × on screen (item 100, Design d288c11)

Design settled the sign app-wide: × in everything shown or said on screen (Tess lines, set lines, the doubtful line, the Day log); typing or saying x or "by" still parses; VoiceOver reads × as "by". What changed here:

- Every weight-and-reps pair in the tables now uses ×, in the normalised text and in the expected intents. The grammar reads × as x (`TessGrammar.swift:508`), so no parse and no PASS or FAIL above changes.
- Rule 12 writes × for spoken `by`, `times` and `into` between two numbers; `by` before one number stays a time word (row 83).
- New rows 81 to 83 and N25, N26 cover "by". Typed "80 by 8" still needs Core: master reads `by` only in the 2 × 10 ask (`TessGrammar+Live.swift:123`), not in the set or scheme regexes (`TessGrammar.swift:286`, 358).
- Expected Tess lines follow master `fdcaee4` (#248): "Set N logged. 80 × 8.", "Drop set logged. 72.5 × 10, nearest load to 72." (N05, N22, N25, 81). The lift line keeps a plain x for more than one set on master (`TessCaptureEngine.swift:211`, row 82) until Core changes it.
- Rule 17 now names the Speak layer, not the old Bar.

## Re-trace on master after #262 (12f1c43)

Item 113, Research lab, 2026-10-16. Base `origin/master` at `8d5e427` (Merge PR #270); its `TesseraTess` code is `12f1c43` (Merge PR #262, Core commit `926ce1b`, "Spoken numbers to digits"), and nothing after #262 touches the grammar, the normaliser or a Speak path (#266, #258 and #264 to #271 are UI, settings, backups and launch flags). No Swift toolchain here: `TessSpoken.numbers` was ported line for line to a scratch script, checked against all 34 rows of Core's `SpokenNumbersTests` (output and idempotence, all equal), and run on every raw transcript below; each grammar result is a hand trace. Clock Thu 15 Oct 2026 18:10 America/Los_Angeles (as `grammar-regression.md`; no row changes between 18:00 and 18:10). Contexts as above; D as in the live section.

**What #262 built.** `TessSpoken.numbers` (`TesseraCore/Sources/TesseraTess/TessSpoken.swift`) is the "Live-workout number words" rules 1 to 11 above, nothing more: lowercase, `-` to a space, spaces collapsed, an end `.` or `!` dropped; a leading `and`, `so`, `okay`, `ok` dropped and `a` before a plain number word; `one more` and a number word before `plates` or `side` protected; number runs (`a hundred and five`, `eighty two`, `one oh five`, `one twenty five`, `point`, `and a half`), a comma ending a run; `plus N` and `minus N` at the start; a trailing `for` after one number is 4; `times` and `into` to `x`; kilos and pounds to `kg` and `lb`; `rep` to `reps`, and `reps` after a full set dropped; a stutter before an operator dropped. `for`, `by` and `at N` stay (the grammar reads them). Wake words, politeness, fillers, note prefixes, corrections, money, times, reordering and the other protected spans of rules 1 to 17 are not built.

**Where it runs.** Only in `parseInFocus` (`TessGrammar.swift:115-124`): with an exercise in focus and a number word (`zero` to `ninety`, `hundred`) or `plus`/`minus` in the phrase, the live rules read `TessSpoken.numbers(phrase)` first; if they claim it, that wins; if not, the raw phrase goes on through every rule as before. There is no Speak layer on master (Speak is still a word, `Features/Command/BottomChrome.swift`), so nothing else normalises: I, C and S rows, and W rows with no number word, reach the grammar as the raw transcript (typed, or keyboard dictation into the Write line).

**How it is judged.** "Normaliser" compares `TessSpoken.numbers(raw)` with the Normalised column; case, × against x, and the live rules' kept `for`, `by`, `at N` and `reps` count as the same. "Master" is what master does with what reaches the grammar. PASS when master gives the row's expected intent: a G\* row passes on its target, or on nil where `grammar-regression.md` gates the target (Money); an M or **PASS** row passes on nil. "FAIL (period)": the right task and date, but the title keeps the dictation period. "hook" marks a W row the normaliser reached. TG is `TessGrammar.swift`, LV `TessGrammar+Live.swift`, Kitchen `TessGrammar+Kitchen.swift`, all at `12f1c43`.

### Main rows (1 to 83) on `12f1c43`

| # | Ctx | `TessSpoken.numbers(raw)` | Normaliser | Master (what reaches the grammar) | Result |
|---|---|---|---|---|---|
| 1 | W | `85 for 6` | same (keeps `for`) | hook: set 85 × 6, "Set 2 logged. 85 × 6." | PASS |
| 2 | W | `100 and 7.5 for 3` | differs: `and` joins digits only after a `hundred` word | raw (no number word): the `and` split finds no set, then nil | FAIL (miss) |
| 3 | I | `squat 1 oh 2.5 for 5` | differs: `one oh 2.5` not read | nil: `parseLift` words `squat one oh` fail the 3-letter floor (TG:501) | FAIL (miss) |
| 4 | W | `80 kg x 8` | same | raw (no number word): `kilos` read (LV:19), `times` not, so nil | FAIL (miss) |
| 5 | W | `same again` | same | set 80 × 8 (same), "Set 2 logged, same again." | PASS |
| 6 | W | `same weight, one more rep` | differs: comma kept | nil: neither the hook text nor the raw phrase is a live set, and the comma parts are no grocery list | PASS |
| 7 | W | `drop to 70` | same | nil (drop with no reps goes to the model, T706) | PASS |
| 8 | W | `80 for 8 at 8` | same (keeps `at 8`, rule 9) | set 80 × 8, RPE 8 (raw, LV:37-46) | PASS |
| 9 | W | `82.5 for 6 at rpe 9` | differs: `at rpe 9` not read | nil: `at rpe 9` is no RPE shape and `looksLikeSet` sends it to the model (LV:81) | FAIL (miss) |
| 10 | W | `85 for 5 at 9.5` | same (keeps `at`) | hook: set 85 × 5, RPE 9.5 | PASS |
| 11 | W | `same, at 9` | differs: comma kept | set 80 × 8 (same), RPE 9: the joined parts `same at 9` (TG:155) | PASS |
| 12 | I | `bench 3 sets of 8 at 80` | differs: `sets of` not rewritten (idle, not run) | **wrong write**: lift Bench Press 1 × 8 at 3 kg (`parseLift` takes 3 as the weight and drops `80`, TG:446-458) | FAIL (wrong write) |
| 13 | I | `deadlift 2 plates for 5` | same | nil (`deadlift plates` is no exercise) | PASS |
| 14 | W | `8 reps` | same (keeps `reps`, rule 8) | set 80 × 8, reps only | PASS |
| 15 | W | `add 2.5` | same | nil (`add 2.5` goes to the model, T706) | PASS |
| 16 | W | `80 for 8, 80 for 8, 80 for 6` | same (keeps `for`) | sets, 3 into Bench: 80 × 8, 80 × 8, 80 × 6 | PASS |
| 17 | I | `squat 100, 5` | same | lift Back Squat 1 × 5 at 100 (TG:365-371) | PASS |
| 18 | W | `80 for ate` | differs: `ate` not read | nil (`ate` is no exercise) | FAIL (miss) |
| 19 | W | `80 x 8` | same | hook: set 80 × 8 | PASS |
| 20 | I | `3 x 10 bench at 80` | same (idle, not run) | nil: idle, no digits reach `parseLift` | FAIL (miss) |
| 21 | I | `bench 80 kg, 8 reps only` | differs: `reps only` kept | **wrong write**: groceries [Bench 80 kg, 8 reps only.]: the comma list counts `8 reps only.` as an amount (Kitchen:59-65); the lift is lost | FAIL (wrong write) |
| 22 | W | `185 lb for 5` | same | raw (no number word): `pounds` is no unit the live set regex reads, `parseLift` has no exercise word: nil | FAIL (miss) |
| 23 | I | `deadlift 225 lb for 3` | same | lift Deadlift 1 × 3 at 225 lb | PASS |
| 24 | I | `i weigh 182 lb` | same | nil | PASS |
| 25 | I | `11 stone 4` | differs: `11 stone 4` (rule 5 protects `N stone M`) | nil (idle, not run) | PASS |
| 26 | I | `12 lb 50 at tesco` | differs: `12 lb 50` (money not read) | nil [Money] (gated, now nil) | PASS |
| 27 | W | `tess, 80 for 8` | differs: `tess,` kept (only `okay` goes) | **wrong write**: groceries [Okay Tess, 80 for 8.] mid-workout: the comma parts fail the live guard and the kitchen comma list reads `80 for 8.` as amount 80; the set is lost | FAIL (wrong write) |
| 28 | W | `uh, uh, 80, 80 for 8` | differs: fillers and the repeat kept | nil (`uh uh` is no exercise; `80` has no letter, so no grocery list) | FAIL (miss) |
| 29 | W | `yeah. yeah. 80 for 7` | differs: `yeah.` kept | nil | FAIL (miss) |
| 30 | W | `come on. come on. 80 for 7` | differs: inner periods kept | nil | PASS |
| 31 | W | `80 for, for 8` | differs: the stutter kept | **wrong write**: groceries [80 for, for 8.] mid-workout (as row 27); the set is lost | FAIL (wrong write) |
| 32 | W | `80 for 7 for` | differs: dangling `for` kept (two numbers before it) | nil: `looksLikeSet` sends it to the model (LV:81); no doubtful set | FAIL (miss) |
| 33 | W | `um` | differs: `um` kept | nil (the model reads `Um.`; nothing written; "Didn't hear anything." is Speak's) | PASS |
| 34 | W | `test, 80 for 8` | differs: `test,` kept | **wrong write**: groceries [Test, 80 for 8.] mid-workout (as row 27); the set is lost | FAIL (wrong write) |
| 35 | I | `test the smoke alarm saturday` | same | task "Test the smoke alarm" Sat 17 09:00 (now parse, B324) | PASS |
| 36 | I | `tess, i'd like a reminder for friday to book the mot` | differs: wake words kept | **wrong write**: task "Okay Tess, I'd like a reminder to book the MOT." Fri 16 09:00 | FAIL (wrong write) |
| 37 | I | `please remind me to call ravi tomorrow, thanks` | differs: politeness kept | **wrong write**: task "Please remind me to call Ravi thanks." Fri 16 09:00 (not explicit: `please` comes first) | FAIL (wrong write) |
| 38 | I | `buy 2 lemons and some milk` | same | groceries [two lemons, some milk.] (the right two items; the words stay words) | PASS |
| 39 | I | `2 lemons and some milk` | same | nil | PASS |
| 40 | I | `get a dozen eggs` | differs: `a dozen` kept | groceries [a dozen eggs.] (the right item) | PASS |
| 41 | I | `buy half a dozen eggs and a pint of milk` | differs: `half a dozen` kept | nil: `half a dozen eggs` reads as the gift shape (`notGroceries`, Kitchen:164) in a two-item list | FAIL (miss) |
| 42 | I | `by 4 lemons and a bag of rice` | same | nil | PASS |
| 43 | I | `by 5 p.m., send the invoice` | differs: `5 p.m.,` not joined | nil: `p.m.` is no time and `send the invoice` is an errand line | FAIL (miss) |
| 44 | I | `buy 1 kg atta and half kg dahi` | differs: `half kg` kept | groceries [1 kg atta, half kg dahi.] (the right items) | PASS |
| 45 | S | `parmesan` | same | groceries [parmesan] (shop run) | PASS |
| 46 | C | `add 2 tins of chickpeas` | same | nil (`add X` is not read yet: ADD, as B334) | FAIL (miss) |
| 47 | I | `remind me friday to call the bank` | differs: no reorder | task "Call the bank." Fri 16 09:00 (title keeps the dictation period) | FAIL (period) |
| 48 | I | `remind me next tuesday to renew the passport` | differs: `next` kept | **wrong write**: task "Next to renew the passport." Tue 20 09:00 | FAIL (wrong write) |
| 49 | I | `call the dentist tomorrow morning` | differs: `morning` not 9am | **wrong write**: task "Call the dentist morning." Fri 16 09:00 | FAIL (wrong write) |
| 50 | I | `remind me in 20 minutes to take the chicken out` | differs: no reorder, no `min` | **wrong write**: task "In 20 minutes to take the chicken out." Later (RELT) | FAIL (wrong write) |
| 51 | I | `pay the window cleaner thursday` | same | task "Pay the window cleaner" Thu 15 19:00 (now parse, B339) | PASS |
| 52 | I | `remind me thursday at 8 to put the bins out` | differs: no reorder | task "Put the bins out." Thu 15 20:00 (period) | FAIL (period) |
| 53 | I | `dentist on the twentieth at half past 3` | differs: ordinal and `half past` not read | nil: no date the grammar reads | FAIL (miss) |
| 54 | I | `call mum at 7:00 pm` | differs: `7:00 pm` not joined | **wrong write**: task "Call mum PM." Thu 15 19:00 | FAIL (wrong write) |
| 55 | I | `remind me tomorrow itself to send the form` | differs: `itself` kept | **wrong write**: task "Itself to send the form." Fri 16 09:00 | FAIL (wrong write) |
| 56 | I | `remind me day after tomorrow to pay rent` | same | **wrong write**: task "Day after to pay rent." Fri 16 09:00 (RELT, as B343) | FAIL (wrong write) |
| 57 | I | `prepone the dentist to wednesday` | same | **wrong write**: task "Prepone the dentist to" Wed 21 09:00 (RC13, as B344) | FAIL (wrong write) |
| 58 | I | `remind me friday, no, saturday to clean the car` | differs: the correction is kept | **wrong write**: task "No, to clean the car." Sat 17 09:00 | FAIL (wrong write) |
| 59 | I | `do 1 thing, remind me tomorrow to collect the courier` | differs: `do 1 thing` (opener kept, `one` rewritten) | **wrong write**: task "Do one thing, remind me to collect the courier." Fri 16 09:00 | FAIL (wrong write) |
| 60 | I | `remind me 2 days before the mot` | same | **wrong write**: task "Two days before the MOT." Later (RELT, as B347) | FAIL (wrong write) |
| 61 | I | `spent 12 50 at tesco` | differs: `12 50` (money not read) | nil [Money] (gated, now nil) | PASS |
| 62 | I | `spent 1250 at tesco` | same | nil [Money] | PASS |
| 63 | I | `lunch was a tenner` | differs: `a tenner` kept | nil | PASS |
| 64 | I | `20 quid for petrol` | same | nil [Money] | PASS |
| 65 | I | `spent 15 hundred on petrol` | differs: `15 hundred` | nil [Money] | PASS |
| 66 | I | `spent 1, 00, 000 on the bike` | differs: grouping commas kept | nil [Money] (`00` has no letter, so no grocery list) | PASS |
| 67 | I | `paid 1 lakh 20 thousand rupees deposit` | differs: `lakh`, `thousand` not read | nil (`Paid` with no day is no past log) | PASS |
| 68 | I | `spent 4 quid at 7 11` | differs: `7 11` (rule 5 protects `seven eleven`) | nil [Money] (idle, not run) | PASS |
| 69 | I | `note. the bar felt heavy today` | differs: `note.` not made `note:` | **wrong write**: task "Note. The bar felt heavy" Thu 15 19:00 (`today` with no time), never a note | FAIL (wrong write) |
| 70 | I | `note to self, 80 felt easy` | differs: body rewritten to `80` (rule 3 forbids it) | **wrong write**: note "to self, eighty felt easy." (RC16, as A234) | FAIL (wrong write) |
| 71 | I | `make a note that the squat rack in bay 2 is broken` | differs: `bay 2` (note prefix not read) | nil: `make` is read as a cook verb, no recipe, no task | FAIL (miss) |
| 72 | W | `80, no wait, 85 for 8` | differs: the correction is kept | nil: the hook's `80, no wait, 85 for 8` is not read (`no wait` is no set), and the raw phrase reaches no rule | FAIL (miss) |
| 73 | W | `80 for 8, sorry, 9` | differs: the correction is kept | nil: the joined parts start with a set shape, so the model (LV:81) | FAIL (miss) |
| 74 | I | `buy oat milk, no wait, almond milk` | same | **wrong write**: groceries [oat milk, no wait, almond milk.] (as B361) | FAIL (wrong write) |
| 75 | I | `remind me to eat 5 a day` | differs: `5 a day` (rule 5 protects it) | task "Eat five a day." Later (period) | FAIL (period) |
| 76 | I | `meeting in room 101 at 3` | same | nil: `at three` is no time to the grammar | FAIL (miss) |
| 77 | I | `book a table for 2 at 7` | same | nil: `at seven` is no time to the grammar | FAIL (miss) |
| 78 | I | `work 9 to 5 on saturday` | differs: `9 to 5` (rule 5 protects it) | task "Work nine to five" Sat 17 09:00 (now parse, B365) | PASS |
| 79 | W | `2 3 more sets` | differs: `2 3` (rule 5 protects the range) | nil (the hook result `2 3 more sets` is no live phrase; raw nil) | PASS |
| 80 | I | `remind me to water the plants 2 3 x a week` | differs: `2 3 x a week` (range and `times` rewritten) | task "Water the plants 2-3 times a week." Later (period) | FAIL (period) |
| 81 | W | `80 by 8` | differs: keeps `by` (the grammar reads it since #254) | hook: set 80 × 8, "Set 2 logged. 80 × 8." | PASS |
| 82 | I | `bench 3 by 8 at 80` | differs: keeps `by` (idle, not run) | nil: idle, no digits reach `parseLift` | FAIL (miss) |
| 83 | I | `pay the gas bill by 7` | same | nil: `by seven` is no time to the grammar | FAIL (miss) |

### Live-workout number words (K811, K812, N01 to N26) on `12f1c43`

| id | Ctx | `TessSpoken.numbers(raw)` | Normaliser | Master | Result |
|---|---|---|---|---|---|
| K811 | W | `82.5 for 8` | same | set 82.5 × 8, "Set 2 logged. 82.5 × 8." | PASS |
| K812 | W | `100 for 5 at 8` | same | set 100 × 5, RPE 8, "Set 2 logged. 100 × 5, RPE 8." | PASS |
| N01 | W | `105` | same | nil: asks "105 for how many reps?" before the model | PASS |
| N02 | W | `105 for 3` | same | set 105 × 3 | PASS |
| N03 | W | `100, 5` | same | nil: `100` asks, so the list goes to the model; never groceries (K885) | PASS |
| N04 | I | `82.4` | same (idle, not run) | nil (idle: the raw words reach no rule) | PASS |
| N05 | W | `82.4 for 6` | same | set 82.5 × 6, "Set 2 logged. 82.5 × 6, nearest load to 82.4." | PASS |
| N06 | W | `105 for 5` | same | set 105 × 5 | PASS |
| N07 | D | `24 reps` | same | set 24 × 24 (reps only, the word `reps` said) | PASS |
| N08 | D | `24` | same | nil: asks "24: 24 kg, or 24 reps?" before the model | PASS |
| N09 | W | `8 at 3` | same | nil: `at 3` is no RPE (LV:41-43); never a task | PASS |
| N10 | W | `8 reps at 9` | same | set 80 × 8, RPE 9 | PASS |
| N11 | W | `same at 9.5` | same | set 80 × 8 (same), RPE 9.5, "Set 2 logged, same again, RPE 9.5." | PASS |
| N12 | W | `80 for 8` | same | set 80 × 8 | PASS |
| N13 | W | `100 for 5 at 8` | same | set 100 × 5, RPE 8 (was a task "100 for five" 20:00 on raw words) | PASS |
| N14 | W | `a couple more` | same | nil (no number word, so the hook is skipped) | PASS |
| N15 | W | `10 10 10` | same | nil (`10 10 10` is no set shape, K884) | PASS |
| N16 | W | `10, 10, 10` | same | sets, 3 × 80 × 10, "Sets 2 to 4 logged. 80 × 10." | PASS |
| N17 | W | `one more set` | same | nil (`one more set` is protected; the model) | PASS |
| N18 | W | `100 for 4` | same | set 100 × 4 | PASS |
| N19 | W | `84 8` | same | nil (`84 8` has no operator) | PASS |
| N20 | W | `80 for 8` | same | set 80 × 8 | PASS |
| N21 | W | `80 for 8` | same | set 80 × 8 | PASS |
| N22 | W | `drop to 72 for 10` | same | drop set 72.5 × 10, "Drop set logged. 72.5 × 10, nearest load to 72." | PASS |
| N23 | W | `call mum at 7` | same | nil: only the live rules read `call mum at 7`; the task rule reads the raw `at seven`, which is no time | FAIL (miss) |
| N24 | W | `+5` | same | nil: says "Say the set, like 85 × 8." before the model | PASS |
| N25 | W | `82.5 by 6` | differs: keeps `by` (`82.5 by 6`) | set 82.5 × 6 (the set regex reads ` by `, TG:336) | PASS |
| N26 | W | `2 by 10` | differs: keeps `by` (`2 by 10`) | asks "2 × 10: 2 sets, or 2 kg?" (LV:153) | PASS |

### Counts on `12f1c43`

- **Main rows: 38 PASS, 45 FAIL** out of 83. Of the 45: **20 wrong writes** (rows 12, 21, 27, 31, 34, 36, 37, 48, 49, 50, 54, 55, 56, 57, 58, 59, 60, 69, 70, 74), **4 period only** (47, 52, 75, 80) and **21 misses** that write nothing (2, 3, 4, 9, 18, 20, 22, 28, 29, 32, 41, 43, 46, 53, 71, 72, 73, 76, 77, 82, 83). The normaliser's output matches the Normalised column on 32 of 83.
- **Live rows: 27 PASS, 1 FAIL** out of 28 (N23, a miss). The normaliser matches on 26 of 28; N25 and N26 keep `by`, which the grammar reads (`TessGrammar.swift:336`, `TessGrammar+Live.swift:153`), so the parse is the same. Before #262 every row but N13 gave nil on master and N13 was a wrong write; K811, K812, N02, N05, N06, N07, N10 to N13, N16, N18, N20 to N22, N25 and N26 now write or ask as the table says.
- These counts are not comparable with the post-hotfix 60 PASS, 20 FAIL: that check traced the Normalised column, as if the full normaliser ran. On the Normalised column, `grammar-regression.md` group B (B296 to B367, rows 1 to 80) keeps the current status: 64 pass, 7 wrong write, 1 miss, unchanged by #262.

### Findings on `12f1c43`

1. **Sets lost or invented (flag to Core).** Rows 27, 31 and 34 (W: `Okay Tess, 80 for 8.`, `80 for, for 8.`, `Test, 80 for 8.`) and row 21 (I: `Bench 80 kg, 8 reps only.`) write groceries and lose the set: a comma phrase that the live guard and `parseCommaSets` do not read falls to the kitchen comma list, whose set check knows `x` and `×` but not `for` (`looksLikeGroceries`, `TessGrammar+Kitchen.swift:75`, and `isShoppingList`, line 143), so `80 for 8.` is a grocery line with amount 80. K885's fix covers only phrases with a number word. Fix: treat `N for M` as a set there, and keep the kitchen comma list out of a live workout. Row 12 (I: `Bench 3 sets of 8 at 80.`) invents Bench Press 3 kg × 8: idle, `parseLift` takes the first number as the weight and drops `80` (`TessGrammar.swift:446-458`); `N sets of M` is read only in focus (`TessGrammar+Live.swift:145`). Typed text does the same in every case.
2. **The hook needs a number word.** Rows 4 and 22 (`80 kilos times 8.`, `185 pounds for 5.`) miss in a live workout although `TessSpoken` reads `times` and `pounds`; `82 and a half for 6` (`speech-capture.md` row 6) misses the same way. Widening the trigger to those words, or to any W phrase, would clear them.
3. **Only the live rules read the normalised text.** N23 (`call mum at seven`, W) goes to the model where `call mum at 7` is a task at 19:00: the task rule reads the raw `at seven`.
4. **A `where` that guards one word only** (`TessSpoken.swift:227-231`). In `case "times", "into" where ...` a Swift `where` binds to the last pattern only, so `times`, `kilos`, `kilo`, `kilograms`, `kgs`, `pounds`, `lbs` and `lbs.` are rewritten with no number beside them; only `into`, `k` and `pound` are guarded. No row fails on it today (in focus only the live rules read the result), but run on every transcript it turns row 80 into `2 3 x a week`. Fix: one case per word, or the guard inside the body.
5. **Protected spans.** `TessSpoken` alone breaks what rule 5 protects and touches a note body (rule 3): rows 25, 59, 68, 70, 75, 78, 79 and 80. Harmless in focus; the Speak path (Builder B) must run the full normaliser around it, not `TessSpoken` alone, on idle text.
6. **What waits on the Speak normaliser, not on Core.** The idle number-word misses (3, 20, 53, 76, 77, 82, 83, and `speak-first-use.md` 2b `bench eighty for eight`, nil on master), the four title periods, and the wake word, politeness, opener and note-prefix wrong writes (36, 37, 48, 49, 54, 55, 58, 59, 69, 70). Core's own rows stay as before: RELT and RC13 (50, 56, 57, 60) and the corrections backstop (74).

The Speak-in-the-workout rows of `speak-first-use.md` (7a, 6c to 6d, 11c, 2e) are now `grammar-regression.md` K896 to K900; all pass on `12f1c43` (2e's doubtful line waits on Speak).
