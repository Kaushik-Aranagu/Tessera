# Grammar regression: group N (secret words), money rows, MU2 follow-up, lift aliases

For: the Research lead, to fold into `grammar-regression.md`. Research lab, 2026-10-16. Same seven cells and id style as the suite. Ids run on from K913 (N914 to K979, with gaps where rows were cut); renumber if another group took them first.

**Master traced:** `da49fc4` (Merge #459). Grammar files (`TessGrammar*.swift`, `SecretWords.swift`) are unchanged since `0eca9bb`, the recount's base; #451 (MU2 wall) added `PrivateFacts` and the router check only. Hand trace, nothing run. TG is `TessGrammar.swift`, Lift `TessGrammar+Lift.swift`, Kitchen `TessGrammar+Kitchen.swift`, SW `SecretWords.swift`, PF `PrivateFacts.swift`, CE `TessCaptureEngine.swift`, RT `TessModel.swift`.

**Context.** The suite's: none (nothing running), shop run, live workout (Bench Press in focus, last 80 x 8), spoken. Clock Thu 15 Oct 2026 18:10 PT; Fri 16, Sat 17, past Sat 10, Sun 11. Every secret value is a placeholder.

**Rulings used.** NE1/R4: a secret word with a value is a private note; with no value a task shape stays a task, anything else a private note (`secret-words.md`). R7: "remember …" with a secret gets "Private note, kept. It stays out of my memory." P1204 (Product 12:04 PM PT, as quoted in `suite-recount-oct-16.md`): "paid rent fri" and "bought milk sat" write dated notes (C2); the money guard fires only with an amount or a currency sign; a list or kitchen shape wins over a secret word with no digit; "pull-ups 8" logs Pull-Up. P1206 (Product 12:06 PM PT, from the coordinator; not in `decisions.md` on master): a medicine with a dose is a health fact, screened from Claude; "buy advil" with no dose stays a grocery item or task. MU2: money with an amount never reaches Claude; the ask "$X at Y?" with LOG / NOT NOW is not built (QA `review-451.md`), so today a walled miss gets "Didn't catch that." (RT:101). For status, as in the suite, only the grammar's parse (and Tess's line) counts; the wall verdict sits in the expected cell.

**New root causes.** SECW: a secret word with no value beats a list or kitchen shape (SW:11, TG:71, TG:487). LINE: the refusal line. MONV: the money guard fires on the verb alone (TG:116-121, Kitchen:84). ALIAS: "pull-ups" and "chin-ups" don't resolve (TG:415-421; TG:444-462 keeps the hyphen in one word).

### N. Secret words (#422) (33 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| N914 | `wifi password is tacocat` | none | privateNote "Wifi password is tacocat", "Private note, kept." | secret-words#S1 | NE1 | pass |
| N915 | `wifi: tacocat24` | none | privateNote "Wifi: tacocat24" | secret-words#S2 | NE1 | pass |
| N916 | `door code 4417` | none | privateNote "Door code 4417" | secret-words#S3, recount | NE1 | pass |
| N917 | `my pin is 4417` | none | privateNote "My pin is 4417" | secret-words#S5, recount | NE1 | pass |
| N918 | `my passcode is one two three four` | none, spoken | privateNote (value after "is"; SW:48-49) | secret-words#S6 | NE1 | pass |
| N919 | `the wifi is tacocat` | none | privateNote ("wifi" before "is", SW:27-28) | secret-words#R2 | NE1 | pass |
| N920 | `netflix password hunter2` | none | privateNote "Netflix password hunter2" | secret-words#S9 | NE1 | pass |
| N923 | `note: gym locker combo 4417` | none | privateNote "Gym locker combo 4417", never a plain note (TG:71 runs before `parseNote`, TG:74) | recount, secret-words#S7 | NE1 | pass |
| N924 | `remember the wifi password is hunter2` | none | privateNote, remembered; "Private note, kept. It stays out of my memory." · now: the note, but "Private note, kept. I don't keep passwords." (da49fc4: CE:300) | recount, secret-words#S8 | R7 | wrong write (LINE) |
| N925 | `remember my pin is 4417` | none | as N924 · now: the old line (CE:300) | secret-words#R7 | R7 | wrong write (LINE) |
| N926 | `remember to change the wifi password fri` | none | task "Remember to change the wifi password" Fri 16, no time (no value, task shape) · now: privateNote "To change the wifi password fri" (TG:477-479 sets remembered, so TG:484 skips `parseTask`) | new | R4 | wrong write (SECW) |
| N927 | `Tess, wifi password is tacocat` | none | privateNote "Wifi password is tacocat" (wake word off, TG:66) | new | NE1, WAKE | pass |
| N928 | `what's the wifi password?` | none | ask "It's in your private notes.", no write (TG:481-482) | secret-words#S11, recount | NE1 | pass |
| N930 | `password reset email friday` | none | task "Password reset email" Fri 16, no time, alerts F [N1] · now: Fri 16 09:00 | secret-words#S12, recount | R4 | pass |
| N931 | `code review friday 3pm` | none | task "Code review" Fri 16 15:00, alerts T | secret-words#S18, recount | R4 | pass |
| N932 | `todo: reset my PIN` | none | task "Reset my PIN" Later | secret-words#S14, recount | R4 | pass |
| N933 | `change the wifi password tomorrow` | none | task "Change the wifi password" Fri 16, no time [N1] · now: Fri 16 09:00 | secret-words#S13 | R4 | pass |
| N934 | `email sam the wifi password sat` | none | task "Email sam the wifi password" Sat 17, no time [N1] · now: Sat 17 09:00 | new | R4 | pass |
| N935 | `call mom about the wifi password` | none | privateNote (no value, no task shape; nothing goes to a model) | secret-words#S15 | R4 | pass |
| N936 | `zip code 94110` | none | privateNote (harmless false positive) | secret-words#S16 | NE1 | pass |
| N937 | `bobby pins` | none | privateNote "Bobby pins" (no list or kitchen shape; harmless) | new | R4, P1204 | pass |
| N938 | `garage 4417` | none | nil (no secret word; not caught, S20) | secret-words#S20 | NE1 | pass |
| N939 | `buy pins` | none | groceries [pins] · now: privateNote "Buy pins" (SW:11, TG:487) | recount | P1204 | wrong write (SECW) |
| N940 | `get a combination lock` | none | the kitchen reading, never a private note: groceries [a combination lock] (Kitchen:49-65) · now: privateNote "Get a combination lock" (TG:487) | recount | P1204 | wrong write (SECW) |
| N941 | `buy a rolling pin` | none | groceries [a rolling pin] · now: privateNote "Buy a rolling pin" (TG:487) | new | P1204 | wrong write (SECW) |
| N942 | `milk, eggs, pins` | none | groceries [milk, eggs, pins] · now: privateNote "Milk, eggs, pins" (TG:487) | recount | P1204 | wrong write (SECW) |
| N943 | `milk, eggs, bobby pins` | none | groceries [milk, eggs, bobby pins] · now: privateNote (TG:487) | new | P1204 | wrong write (SECW) |
| N944 | `bobby pins` | shop run | groceries [bobby pins] · now: privateNote "Bobby pins" (TG:71 runs before the shop rule, TG:86) | new | P1204 | wrong write (SECW) |
| N945 | `milk, eggs, gate code 2580` | none | privateNote (a digit value wins over the list) | new | P1204 | pass |
| N946 | `door code 4417` | shop run | privateNote, never a grocery line | recount | NE1 | pass |
| N947 | `pin 4417` | live workout | privateNote "Pin 4417", never a set | recount | NE1 | pass |
| N948 | `pinch of salt` | shop run | groceries [pinch of salt] (whole words: no "pin") | recount, secret-words#S19 | NE1 | pass |
| N949 | `buy spinach and feta` | none | groceries [spinach, feta] | recount | NE1 | pass |

### H. Money additions (16 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| H950 | `spent $23.47 at trader joe's` | none | ask "$23.47 at Trader Joe's?" LOG / NOT NOW [MU2] · now: nil; walled, never Claude (RT:77-79) | recount, money-body-wall#MB1 | MU2 | pass |
| H951 | `spent $1,250 on rent` | none | spend 1250 [MU2] · now: nil (TG:117) | recount | MU2 | pass |
| H952 | `$212.37 at costco` | none | ask "$212.37 at Costco?" [MU2] · now: nil (TG:118) | money-body-wall#MB1 | MU2 | pass |
| H954 | `costco 212.37` | none | spend 212.37 [MU2] · now: nil; walled by two decimals (PF:36) | money-body-wall#MB2 | MU2 | pass |
| H955 | `rent 2100` | none | [MU2] · now: nil; walled (PF:33) | money-body-wall#MB4 | MU2 | pass |
| H956 | `venmo sam 25 for pizza` | none | [MU2] · now: nil; walled | money-body-wall#MB5 | MU2 | pass |
| H958 | `paid the plumber 180` | none | spend 180 [MU2] · now: nil (TG:117) | new | MU2, P1204 | pass |
| H959 | `coffee 6.25 today` | none | spend 6.25 [MU2] · now: nil; walled, never a task · master: task "Coffee 6.25" Thu 15 19:00 (TG:141; the guard at TG:116-121 needs a lead verb or a sign) | money-body-wall#MB11 | MU2 | wrong write (MONV) |
| H960 | `chicken $1.29/lb, rice` | none | groceries [chicken $1.29/lb, rice] (a unit price is no spend, Kitchen:82) | recount | B430 | pass |
| H961 | `pay the gas bill sat` | none | task "Pay the gas bill" Sat 17, no time, alerts F [N1] · now: nil (TG:116-121, Kitchen:84) | new | P1204, W4 | miss (MONV) |
| H962 | `pay sam back fri` | none | task "Pay sam back" Fri 16, no time [N1] · now: nil (TG:116-121) | new | P1204, W4 | miss (MONV) |
| H963 | `paid the gas bill sat` | none | note "Paid the gas bill" Sat 10 12:00 · now: nil (TG:116-121 runs before `parsePastLog`, TG:127) | new | P1204, C2 | miss (MONV) |
| H964 | `bought bread sun` | none | note "Bought bread" Sun 11 12:00 · now: nil (TG:116-121) | new | P1204, C2 | miss (MONV) |
| H965 | `call the bank about rent fri` | none | task "Call the bank about rent" Fri 16, no time [N1] · now: Fri 16 09:00; not walled (no amount) | new | W4 | pass |
| H966 | `budget meeting 3pm` | none | task "Budget meeting" Fri 16 15:00, alerts T (C5) | money-body-wall#MB38 | W4, C5 | pass |
| H967 | `Tess dinner fri` | none | task "Tess dinner" Fri 16, no time [N1] (TG:66 keeps "Tess") · now: Fri 16 09:00 | recount | WAKE | pass |

### H. MU2 follow-up, Product item G (8 rows)

L1 and L3 are QA's lows in `docs/qa/review-451.md` (not in `money-body-wall.md` or `core.md`). Both are router-wall gaps, not grammar gaps: the grammar passes each row, and the wall result is in the cell.

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| H968 | `paid 20 for 2 tickets` | none | spend 20 [MU2] · now: nil (TG:117); walled · wall today: **reaches Claude**, `isTraining` reads "20 for 2" as a set (PF:98) | review-451#L3 | MU2 | pass |
| H969 | `slept badly` | none | nil (no day, no past log) · wall: Product open (L1); today reaches Claude, sleep needs a number (PF:66) | review-451#L1 | MU2 | pass |
| H970 | `knee hurts` | none | nil · wall: Product open (L1); today reaches Claude (no symptom word or number) | review-451#L1 | MU2 | pass |
| H971 | `took 2 advil` | none | nil (no day); walled, medicine with a number | money-body-wall#MB21 | P1206 | pass |
| H972 | `refill lexapro 10mg` | none | nil; walled, a dose (PF:63) | coordinator, money-body-wall#MB27 | P1206 | pass |
| H973 | `refill lexapro 10mg fri` | none | task "Refill lexapro 10mg" Fri 16, no time, on the phone only; packs carry "task" [MW5] · now: Fri 16 09:00; walled (PF:63) | coordinator | P1206 | pass |
| H974 | `buy advil` | none | groceries [advil]; not walled (no dose) | coordinator | P1206, B430 | pass |
| H975 | `buy advil fri` | none | task "Buy advil" Fri 16, no time [N1] · now: Fri 16 09:00; not walled | coordinator | P1206 | pass |

The other item G phrases are already suite rows: `pay rent fri` (H613), `paid rent fri` (A011), `bought milk sat` (A013). All are miss today (TG:116-121) and flip with the pin PR.

### K. Lift aliases (4 rows)

| id | phrase | context | expected parse | source rows | decision | status |
|---|---|---|---|---|---|---|
| K976 | `pull-ups 3x8` | none | lift Pull-Up 3 sets x 8 at bodyweight (as A181) · now: nil (TG:415-421, 444-462) | recount | P1204 | miss (ALIAS) |
| K977 | `chin-ups 3x8` | none | lift Chin-Up 3 sets x 8 at bodyweight · now: nil (TG:415-421) | recount | P1204 | miss (ALIAS) |
| K978 | `pull-ups 3 sets of 8` | none | lift Pull-Up 3 sets x 8 at bodyweight · now: nil (TG:415-421) | new | P1204 | miss (ALIAS) |
| K979 | `pull-ups 8` | none | lift Pull-Up 1 set x 8 at bodyweight · now: nil (alias, and then Lift:39-43 reads one number as reps only with Pull-Up in focus) | recount | P1204 | miss (ALIAS) |

## Totals

| group | rows | pass | wrong write | miss |
|---|---|---|---|---|
| N. Secret words | 33 | 24 | 9 | 0 |
| H. Money additions | 16 | 11 | 1 | 4 |
| H. MU2 item G | 8 | 8 | 0 | 0 |
| K. Lift aliases | 4 | 0 | 0 | 4 |
| **all new** | **61** | **43** | **10** | **8** |

**Flips with Core's small pin PR** (money guard with an amount or a sign, the secret-word list shape, the "pull-ups" alias):
- New rows, 12: N939 to N943, H961 to H964, K976 to K978. N944 also flips if the fix counts the shop run as a list shape.
- Existing rows, 7: A011, A013, B339, E504, H613, I730 (miss to pass); H615 (no amount, so `parseTask` gives its task again); K907 (the alias brings in Lift:39-43).
- Do not flip: N924 and N925 (the line rides AI-3, `core.md:90`), N926, H959 and K979.

## Unsure
- **The 12:04 and 12:06 rulings are not on master.** The recount file is untracked in the shared tree, and `decisions.md` on master has neither. The 12:04 ruling comes from the recount and the brief, and the 12:06 ruling from the coordinator.
- **The 12:04 ruling conflicts with existing rows.** If the guard fires on any amount, H612 (`pay rent 650 fri`), A012, H609 and H610 stay nil. That contradicts H612's task and the recount's dated notes for H609 and H610. I added no amount-plus-day rows; Product to say which wins.
- **N940:** the recount expected a Later task; the kitchen rules give groceries (`notGroceries` has no hardware words). **N926** as a task is my reading of R4.

**Ruled (Product, decisions.md 12:13 PM PT):** a day wins over an amount: "pay rent 650 fri" is a task and a past-tense one a dated note (H612, A012, H609, H610); no amount ever goes to Claude. A money verb beats the set shape ("paid 20 for 2 tickets" stays on the phone). L1: body and health facts with no number stay on the phone (12:02). "remember ... fri", "coffee 6.25 today", the pull-ups/chin-ups aliases and the money-verb vs set fix are Core item 0c. "get a combination lock" as a grocery row stands.
