# Grammar misses: blind read

For: Kaushik. Research lab, board item 88, 2026-10-16. Source: `fixtures/grammar-miss-claude.md` (the use 1 gate, 186 rows, 147 sent to Claude) and, for the phone side, the hand traces behind `fixtures/grammar-regression.md`.

This takes a few minutes. Do it once your Claude key is in, so your ticks count as the gate's human read.

## What you are looking at

30 phrases you might type into Tess. Under each one are two results, A and B. One is what the phone does today on its own (master, no Claude). The other is the row the gate expects Claude to write. Which is which changes from row to row, so don't look for a pattern.

- The context line says the day, the clock and what is open (a task, a workout). Today is Thu Oct 15, 2026 unless the line says otherwise.
- "Later" means a task with no date. "No write" means nothing is saved.
- Alerts are left off both sides, since the app can't set them yet.
- Two rows (money) never go to Claude at all; their second side is what the phone should do once fixed. Read them the same way.

## How to score

1. For each row, tick one box: A, B, both (either would be fine to you) or neither (you would undo both).
2. If either side writes something you would take back straight away, write "take back" next to that row.
3. Only then open the answer key at the end and count, for the 28 rows that go to Claude:
   - **Claude side right:** your tick names the Claude side, or "both".
   - **Take backs on the Claude side.**
4. Count the 2 money rows on their own.

**The bar** (from the fixture's human read): at least 80% of Claude's ghost rows and ask lines sound like Tess, and none you would take back. The full gate asks for 118 of 147 rows. For these 28, that is **at least 23 rows where you ticked the Claude side or "both", and 0 take backs on the Claude side**. A miss here is a row to look at, not a fail on its own: this is a sample, and the hardest rows are over-picked on purpose.

## The rows

### 1. `call mom half 11`

Thu Oct 15, 11:30 pm. Nothing running.

- **A:** Task: Call mom, tomorrow 11:30 am.
- **B:** No write.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 2. `call mom tmrw morning`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Call mom morning, tomorrow 9:00 am.
- **B:** Task: Call mom, tomorrow 9:00 am.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 3. `can you move the dentist to friday`

Thu Oct 15, 6:10 pm. Open task: Dentist, Sat Oct 17 10:00 am.

- **A:** Dentist moved to tomorrow (Fri Oct 16), 10:00 am.
- **B:** No write.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 4. `spent 30 dinner sat`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Spent 30 dinner, Saturday 9:00 am (Oct 17).
- **B:** Note: Spent 30 dinner, dated last Saturday (Oct 10).

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 5. `remind me in 2 hours to call mom`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Call mom, today 8:10 pm.
- **B:** Task: In 2 hours to call mom, Later.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 6. `call mom 7 pm`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Call mom, today 7:00 pm.
- **B:** No write.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 7. `lunch with Olive, Basil`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Lunch with Olive, Basil, Later.
- **B:** Groceries: "lunch with Olive", "Basil".

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 8. `5x5`

Thu Oct 15, 6:10 pm. In a workout: Pull-Up (bodyweight) in focus, last set bodyweight x 8.

- **A:** No write. Asks: "5 × 5: 5 sets, or +5 kg?"
- **B:** Pull-Up set: +5 kg x 5.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 9. `8 and call mom at 7`

Thu Oct 15, 6:10 pm. In a workout: Bench Press in focus, last set 80 x 8 kg.

- **A:** Bench Press set: 80 x 8 kg. Task: Call mom, today 7:00 pm.
- **B:** Task: 8 and call mom, today 7:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 10. `move dentist to next fri`

Thu Oct 15, 6:10 pm. Open task: Dentist, Sat Oct 17 10:00 am.

- **A:** Dentist moved to Fri Oct 23, 10:00 am.
- **B:** Dentist moved to tomorrow (Fri Oct 16), 10:00 am.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 11. `out of milk`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** No write.
- **B:** Groceries: "milk".

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 12. `80x8 then call mom`

Thu Oct 15, 6:10 pm. In a workout: Bench Press in focus, last set 80 x 8 kg.

- **A:** No write.
- **B:** Bench Press set: 80 x 8 kg. Task: Call mom, Later.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 13. `bench 80x8 at 7`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Bench 80x8, today 7:00 pm.
- **B:** No write. Asks: "Log bench 80 x 8 now, or plan it for 7 pm?"

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 14. `drinks with Candy, Honey`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Groceries: "drinks with Candy", "Honey".
- **B:** Task: Drinks with Candy, Honey, Later.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 15. `spent 12.40 lunch thu`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Note: Spent 12.40 lunch, dated today.
- **B:** Task: Spent 12.40 lunch, today 7:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 16. `call mom half 5`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** No write.
- **B:** Task: Call mom, tomorrow 5:30 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 17. `Candy, Honey and Basil are coming`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Groceries: "Candy", "Honey", "Basil are coming".
- **B:** No write. Asks: "When are they coming?"

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 18. `buy lego for priya`

Thu Oct 15, 6:10 pm. No Priya in your people.

- **A:** Groceries: "lego for priya".
- **B:** Task: Buy lego for priya, Later.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 19. `basil, olive and rose`

Thu Oct 15, 6:10 pm. Your people include Rose, Ravi and Rosemary.

- **A:** Groceries: "basil", "olive", "rose".
- **B:** No write. Asks: "Groceries, or Basil, Olive and Rose?"

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 20. `2x10`

Thu Oct 15, 6:10 pm. In a workout: Dumbbell Bench Press in focus, last set 24 x 10 kg.

- **A:** Dumbbell Bench Press set: 2 kg x 10.
- **B:** No write. Asks: "2 × 10: 2 sets, or 2 kg?"

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 21. `bench 80x8 today`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Bench Press logged in today's workout: 80 x 8 kg.
- **B:** Task: Bench 80x8, today 7:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 22. `Remind me at 6 PM to call Mom.`

Fri Oct 16, 5:40 pm. Nothing running.

- **A:** Task: PM to call Mom., today 6:00 pm.
- **B:** Task: Call Mom, today 6:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 23. `call mom half 7`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** No write.
- **B:** Task: Call mom, today 7:30 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 24. `bench 80 for 8, 81`

Thu Oct 15, 6:10 pm. In a workout: Bench Press in focus, last set 80 x 8 kg.

- **A:** Bench Press set: 80 x 8 kg. Asks: "81 for how many reps?"
- **B:** Bench Press set: 80 x 8 kg. Nothing about the 81.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 25. `coffee with Pepper, then gym`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Groceries: "coffee with Pepper", "then gym".
- **B:** Task: Coffee with Pepper, Later.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 26. `remind me to call mom at 6, actually 7`

Fri Oct 16, 5:40 pm. Nothing running.

- **A:** Task: Call mom actually 7, today 6:00 pm.
- **B:** Task: Call mom, today 7:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 27. `lunch with ravi`

Thu Oct 15, 6:10 pm. Ravi is one of your people.

- **A:** Task: Lunch with ravi, Later, linked to Ravi.
- **B:** No write.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 28. `push dentist to next week`

Thu Oct 15, 6:10 pm. Open task: Dentist, Sat Oct 17 10:00 am.

- **A:** Dentist moved to Sat Oct 24, 10:00 am.
- **B:** No write.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 29. `buy present for moms birthday on the twentieth`

Thu Oct 15, 6:10 pm. Mom is one of your people.

- **A:** Task: Buy present for moms birthday on the twentieth, Later.
- **B:** Task: Buy present for moms birthday, Tue Oct 20, no time.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

### 30. `bench 3x5 at 80 then call mom at 7`

Thu Oct 15, 6:10 pm. Nothing running.

- **A:** Task: Bench 3x5 at 80 then call mom, today 7:00 pm.
- **B:** Bench Press logged: 3 sets of 5 at 80 kg. Task: Call mom, today 7:00 pm.

Which is right?  [ ] A   [ ] B   [ ] both   [ ] neither

## Answer key, do not read first

Seed: Python `random.Random(88)`. The 30 rows were shuffled with `shuffle`, then for each row in the new order one `random() < 0.5` put the phone on side A.

| # | fixture id | picked as | A is | B is |
|---|---|---|---|---|
| 1 | C436 | hard | Claude (expected) | phone |
| 2 | C418 | common | phone | Claude (expected) |
| 3 | C395 | common | Claude (expected) | phone |
| 4 | H609 | money | phone | expected (on-phone target, no Claude call) |
| 5 | C424 | common | Claude (expected) | phone |
| 6 | A091 | common | Claude (expected) | phone |
| 7 | A137 | people | Claude (expected) | phone |
| 8 | K880 | hard | Claude (expected) | phone |
| 9 | A169 | hard | Claude (expected) | phone |
| 10 | C389 | hard | Claude (expected) | phone |
| 11 | A271 | common | phone | Claude (expected) |
| 12 | A168 | common | phone | Claude (expected) |
| 13 | A184 | hard | phone | Claude (expected) |
| 14 | A138 | people | phone | Claude (expected) |
| 15 | H610 | money | expected (on-phone target, no Claude call) | phone |
| 16 | C415 | hard | phone | Claude (expected) |
| 17 | A139 | people | phone | Claude (expected) |
| 18 | F544 | people | phone | Claude (expected) |
| 19 | E499 | people | phone | Claude (expected) |
| 20 | K876 | hard | phone | Claude (expected) |
| 21 | A183 | common | Claude (expected) | phone |
| 22 | J749 | common | phone | Claude (expected) |
| 23 | A092 | common | phone | Claude (expected) |
| 24 | K874 | hard | Claude (expected) | phone |
| 25 | A136 | people | phone | Claude (expected) |
| 26 | J773 | hard | phone | Claude (expected) |
| 27 | F531 | people | Claude (expected) | phone |
| 28 | C388 | hard | Claude (expected) | phone |
| 29 | F540 | people | phone | Claude (expected) |
| 30 | A167 | hard | phone | Claude (expected) |

**How the 30 were picked.** Every people phrase (8: rows naming a person in a plan, a group or a gift; the many "call mom" rows count as time phrases, and E497 `buy sage green paint` names no one). Every money phrase (2: H609, H610, both local in the fixture). Then the hardest (11: the fixture's named weak spots, keeping a moved task's time, two-intent splits, the set-count asks, bare half-hours across midnight, a self-correction) and the commonest (9: the call, remind, move, groceries and set shapes you say most). Nothing was left out of the people or money groups.

**Where the phone side comes from.** The gate fixture has no master column, so the phone side is the hand trace in the suite's source fixtures (`grammar-misfires.md` post-hotfix check, `reschedule-time-rows.md`, `reminders.md`, `set-logger.md`, `people.md`, `money.md`), checked against `TessGrammar` on master `8fc5bd3`, whose grammar files are unchanged since the fixture's `1c6193a`. Nothing was run. F540 uses master's code over `people.md`: `present` is a non-grocery word after `buy`, so it is a Later task, not groceries. J756 (`remind me tomorrow at 9 to call mom` at 12:30 am) was left out: master's "his tomorrow" now gives Sat 9:00 am, the expected row, so both sides would match.
