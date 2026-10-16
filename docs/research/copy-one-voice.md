# Tonight's copy, one voice (board item 126)

For: Design, Builder A, Builder B. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Every new on-screen line in Design 41, 44, 46, 47, 49, 50, 53, 54, 56 and 57 (branch `claude/project-thread-b3tu3f`, up to 413b91b), plus the 7d16c88 addenda, checked against the voice and the house rules. Sheet text is read from the commits that added it; older lines a sheet only repeats are not re-checked.

Checked against:
- `docs/research/tess-voice.md` (principles 1 to 8, M33 to M58) and `TessVoice` in `TesseraCore/Sources/TesseraTess/TessCapturing.swift` (`violations`: 12 words or more fails, no "!", no emoji, banned words).
- `docs/ai/home-lines.md`: context line 6 words, 32 characters, no stop; SO FAR 14 words, 80 characters, with a stop; §2 no-repeat (a context line never carries a word the page already shows); no sleep or health on Home's context.
- House rules: US English and US dates ("Oct 16", "Nov 1"); times as "6:12 pm", "9 am", "Saturday 3 pm"; digits for counts; no "!"; no "…"; undo lines name the thing first, then what happened, UNDO under the line it undoes and reverting what that line names; back words "‹ SETTINGS"; "best", never "record"; no grading words; memory in the second person; one ask is a line plus two ink words; no yes/no question in a live workout; cobalt is Tess's voice only; no " · " in a row except before a pack size; nothing on screen is called "Home".

Sheet map: 41 is `home-first-review.md` (091ddcd), 44 `training-mode.md` (7fcbee6, 413b91b), 46 `review-week.md` (da55bb6 and its 87c7169 addendum), 47 `groceries-tess.md` (05d14dd, 7d16c88), 49 `tess-knows.md` (512ec3e, d73cba4, 7d16c88), 50 the `settings-place.md` addendum (839d521), 53 `plan-home.md` (487634f), 54 the `widget-states.md` and `lockscreen.md` addenda (94e50b6), 56 `live-workout.md` (87c7169, written), 57 `notes-grammar.md` (efdf7de).

## 41 Home, one line per thing

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Push A, paused at bench" / "Push A done" / "Push A" | hero | ok | |
| "paused 21 min ago", short form "paused 21 min" | context | ok | |
| "this evening", "today" | context | ok | |
| "Thursday night" | day label | ok | |
| `START PUSH A`, `RESUME PUSH A` | key | ok | |
| ‹ TODAY | back word | ok | |
| "1 exercise, 2 sets, 1 new best." | SO FAR | ok | 7 words, a stop, "best" |
| STILL TO GO | label | ok | |
| "Read Designing Data-Intensive Applications" | Next row | ok | Only if that is his title as typed; the dot goes, nothing is added |
| "16 Oct" in the sheet's prose | prose | fix | US date: "Oct 16" (the same in 44, 46, 47, 49, 50) |

## 44 Training in workout mode (and the 413b91b addendum)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "today, 5 exercises, about 55 min" | context | ok | Exactly 6 words and 32 characters, at the cap. It may only wrap, never grow |
| "rest day, Push A tomorrow" | context, rest day | fix | Must match Home and her line (decision 2:53 AM PT). Planned rest day: "Push A tomorrow". Marked rest day: "Legs A waits for tomorrow" |
| "Bench press is ready for 82.5 today." | Tess | ok | |
| "Push A running. Bench press first." | Tess | ok | |
| `PAUSE`, `PULL A TOMORROW`, `REST DAY TOMORROW` | key and label | ok | |
| `PUSH PULL LEGS, ROLLS ON`, `ROUTINES` | plan line | ok | |
| "Push Pull Legs, rolls on" / "fixed days" | Routines context | ok | |
| "5 exercises, about 55 min" | routine row | ok | |
| "Mon, Thu · 5 exercises, about 55 min" | routine row | fix | " · " is for pack sizes only (41 §3, 7d16c88): "Mon and Thu, 5 exercises, about 55 min" |
| "Make a routine" | write line | ok | |
| "Push C made." / "Push C dropped." / "Push B dropped." | Tess + UNDO | ok | |
| `ROLLS ON`, `FIXED DAYS`, `DROP`, `DAYS` | words | ok | |
| "Push Pull Legs on fixed days." | Tess + UNDO | ok | |
| "rolls on", "Mon, Thu", "Pick a day" | DAYS line | ok | |
| "Push A on Mondays." / "Push A on Mondays and Thursdays." | Tess + UNDO | ok | |
| "Thursday was Pull A's. Push A has it now." | Tess + UNDO | fix | Undo names the thing written first: "Push A on Thursdays, taken from Pull A." |
| "Rest day" | Now hero | ok | |
| "Push A, no fixed days." | Tess + UNDO | ok | |
| `PUSH PULL LEGS, NO DAYS YET` / `PUSH PULL LEGS, FIXED DAYS` | plan line | ok | |

## 46 Review, the week on one page (and the 87c7169 addendum)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "the week so far" | context | fix | §2 no-repeat: the hero ("A quiet week so far") and the band ("3 SO FAR") already say it. Use the dates, as the Day log does: "Oct 12 to 18" |
| "Three sessions" / "All six sessions in" / "A quiet week so far" | hero | ok | Kept from `review-sentence.md`; see cross-sheet 10 on digits |
| M T W T F S S | day letters | ok | |
| TRAINING, 3 OF 6; mid-week "3 SO FAR" | band | ok | |
| TASKS DONE, 14 | band | ok | |
| "·" at 38% for a day with no tasks or spend | band mark | fix | No dots (Kaushik, 8:07 PM PT). Leave the column empty |
| COOK · 2 OF 4, READ · 3 OF 5 | habit band | fix | Same form as the other bands and no dot: "COOK, 2 OF 4" |
| WEIGHT, 78.2 KG / MONEY, $161 / COOKED, 2 | band | ok | |
| "cooked 3 times" | COOKED line | ok | |
| "Tue  Bench 85 × 8, a best." | week's lines | ok | |
| "a best, a first, a record count" | Core's pick rule | fix | "best", never "record": "a best, a first, the week's top count" |
| "Tuesday" / "Bench best, 5 done" | tapped day | ok | |
| "Tuesday was the bench best." | Tess | ok | |
| "Training, 3 of 6 sessions. Monday trained, ..." | VoiceOver | fix | Read what the band shows: mid-week "Training, 3 so far. Monday trained, ..." |
| "Read Tuesday" | VoiceOver action | ok | |

## 47 Groceries with Tess (and the 7d16c88 recipe line)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| ‹ KITCHEN / "Groceries" | top | ok | |
| "9 to get, for tacos and two more" | count line | fix | Digits: "9 to get, for tacos and 2 more" |
| USUALLY, "Oat milk  Bananas  Coffee" | foot | ok | |
| "for tacos", "for tacos · 15 oz" | row line | ok | The dot is a pack size |
| "Scallions, for the tacos?" + KEEP / NOT NOW | one ask | fix | Say it as the row line will: "Scallions, for tacos?" |
| "for tacos?" | row, wet | ok | |
| "Scallions, for the tacos." + UNDO | Tess | fix | "Scallions, for tacos." |
| "Added 2 for tacos." + UNDO | Tess | fix | Verb first breaks the undo rule (M33): "2 for tacos, added." It is Product's settled line (12:54 AM PT), so Product says yes first |
| "Oat milk, in Dairy and eggs." + UNDO | Tess | ok | |
| "2 to buy" over "Tacos tonight", `GROCERIES` | Home | ok | |
| "tonight" over "Tacos tonight", `COOK` | Home, all in | fix | §2 no-repeat: the hero says "tonight". Give the time: "at 7 pm" (or "all in" with no time) |
| "for chili · 28 oz", "for curry · 14.5 oz", "for tacos and chili · 15 oz" | row line | ok | |
| "for tacos and chili", "for frittata" | row line | ok | |
| "for curry and two more", "for chili and two more" | row line | fix | Digits: "for curry and 2 more", "for chili and 2 more" |

## 49 What Tess knows (with d73cba4 and the 7d16c88 forget-by-voice lines)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Tess remembers 12 things." / "Nothing yet." | Settings door | ok | |
| "12 things about you." + WHAT I KNOW | Tess | ok | |
| ‹ SETTINGS, ‹ TODAY, ‹ WHAT I KNOW | back words | ok | |
| "What I know / about you" | title | ok | |
| "12 things. 4 you told me, 8 I noticed." / "Nothing kept yet." | count line | ok | |
| Training, Kitchen, People, About you, The last 14 days | group words | ok | |
| "You train after work on weekdays." / "You work 9 to 5." | lines | ok | Second person |
| "you said so on Oct 9, used today", "from 14 workouts, used today", "from 6 weeks", "you said so just now", "from what you said on Oct 16", "stays on this phone" | source lines | ok | |
| "Wed  Pull A done, 2 tasks, cooked chili." | day line | ok | |
| FORGET, FORGET EVERYTHING | words | ok | |
| "Left shoulder, forgotten." + UNDO | Tess | ok | |
| "Kept. You rest on Sundays." + UNDO | Tess | fix | Thing first, and the same name the voice table uses: "Rest on Sundays, kept." |
| "Everything forgotten, 12 things." + UNDO | Tess | fix | Thing first: "12 things, forgotten." |
| 'Say "remember that…" and I'll keep it here.' | empty page | fix | No "…": 'Say "remember that" and I'll keep it here.' |
| "I let one go to make room: Tacos means the sheet-pan tacos." | Tess | fix | 12 words fails `TessVoice.violations`; thing first, second person: "Tacos means your sheet-pan tacos, let go to make room." |
| "Kept, on this phone only." | Tess | ok | |
| "I don't keep sums of money." / "I don't keep places." | Tess | ok | |
| "I keep 40 things. Forget one and say it again." | Tess | fix | An order, not an offer: "I keep 40 things. Forget one to make room." |
| 'Nothing yet. Say "remember that…" and I'll keep it.' | Tess at zero | fix | No "…": 'Nothing yet. Say "remember that" and I'll keep it.' |
| "Say that in Tessera and I'll keep it." | Siri | ok | |
| "You said so on October 9, used today. Actions: Forget." / "Change after work" | VoiceOver | ok | |
| "Rest on Sundays, forgotten." / "Rest on Sundays, taken back." | Tess | ok | |
| "Tacos means the sheet-pan tacos, forgotten." | Tess | fix | The sheet's own rule: the name is the value words, never the whole line: "Tacos, forgotten." |
| "Two things match. Swipe the one to forget." + WHAT I KNOW | Tess | fix | Digits: "2 things match. Swipe the one to forget." |
| "I don't have that." / "That takes a hold, on the page." | Tess | ok | |
| "Train 6 to 8, forgotten." | Tess | fix | Times read "6 to 8 pm". Noticed lines have no value words (49), so the name rule needs its fallback named for them: "Train 6 to 8 pm, forgotten." |
| 'Say what to keep, like "remember that I rest on Sundays".' | Tess | fix | US punctuation puts the stop inside the quote: '...like "remember that I rest on Sundays."' |
| "Training keeps your bests." | Tess | ok | |

## 50 Settings, the "Tess asks Claude" answer (839d521)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Tess asks Claude when she's unsure, for Plan my day, and to word Home." | answer, AI-4 | fix | Nothing on screen is called Home, and 14 words fails `violations`: "Tess asks Claude when unsure, for Plan my day and Today." (11) |
| "...and to word Home and your week." | answer, AI-11 | fix | Same two rules, 17 words: "Tess asks Claude when unsure, for plans, Today and your week." (11) |
| "Tess stays on this phone." | answer, no | ok | Third person in a Tess-coloured line; see cross-sheet 9 |
| "This month $0.00 of $10." / "of $50." | spend line | ok | |
| "Claude paused until 1 Nov." | spend line | fix | US date (decision 7:34 PM PT, M10): "Claude paused until Nov 1." |
| "Titles and counts only. Never notes, places, health or money." | privacy line | ok | One wording for every privacy line, see cross-sheet 2 |

## 53 Plan my day on the new Home

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Friday morning" | day label | ok | |
| "this morning, slept 6h40" | context | fix | Home's context never names sleep or health (home-lines §2), and the sheet itself moves sleep to the pulled view. "morning" repeats the day label (§2). Give the time: "from 8 am" |
| "this morning" | context, no Health | fix | Same repeat: "from 8 am" |
| "Four hours free" / "Two hours free" | hero | fix | Digits: "4 hours free", "2 hours free" (Design's call, see cross-sheet 10) |
| "Three tasks, Push A at 6" | hero | fix | Digits: "3 tasks, Push A at 6". The bare hour stays: it is the settled hero form ("Tacos at 7", Design kitchen rule) |
| `START WITH REPLY TO LANDLORD`, `START WITH PUSH A` | key | ok | |
| Plan, VIA CLAUDE, "2 MORE", "1 MORE" | words | ok | |
| "Landlord reply first, then physio." | Tess | ok | |
| "Sends your task and calendar titles, never notes, places or health." | first-time slot | fix | Three wordings of one promise (cross-sheet 2). Use one: "Titles and counts only. Never notes, places, health or money." |
| "slept 6h40", "20 min, while the morning is quiet." | pulled view | ok | |
| "Reply to landlord, 8 am." + UNDO | Tess | ok | |
| "this morning, 8 am" | context after keep | fix | "morning" repeats the day label: "at 8 am" |
| `START PUSH A`, `RESUME PUSH A`, "Push A done" | key, Next row | ok | |
| "Plan kept. Reply to landlord is up." + UNDO | Tess | ok | |
| "Rest day" | hero | ok | |

## 54 Widgets and the Lock Screen (widget-states and lockscreen addenda)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Push A, all sets in." / "ready to finish" / "82.5 × 8" | 60 s face | ok | |
| "Push A today." / "Push A this evening." | medium, rectangular | ok | |
| `6:00 PM` / "6:00 pm" | meta, rectangular | fix | Times as "6 pm": `6 PM` in label case, "6 pm" in a sentence |
| "7:40 PM", "7:30 AM", "7:40 pm", "7:30 am", "IN 10 MIN", "In 10 min" | meta | ok | |
| "Push A, bench set 4." / "1:32" / "Resting 1:32" | running, resting | ok | |
| Word "Resume" while running | medium | fix | It isn't paused. Use the routine's name, "Push A", as the planned state does |
| "Call landlord at six." | timed task | fix | Times as "6 pm": "Call landlord at 6 pm." (inline: no stop) |
| "Rest day." | rest day | fix | Home's rest day context is the weekday, so the meta carries it: `SUNDAY`. On a marked day it must match Home: "Rest today, Legs A waits for tomorrow." |
| "All quiet." / "Push A done, a bench best." / "Push A done." / "Tacos tonight, 2 to buy." | lines | ok | |
| "Pull A tomorrow, first." | day closed | fix | "first" reads as nothing. Match Training's `PULL A TOMORROW`: "Pull A tomorrow." with meta `7:30 AM` |
| Push A, Set 4, 1:32, 10 min, Rest, Quiet, Done, 7:30 | circular | ok | |
| Words "Pull A", "Groceries" | medium | ok | |
| "Push A done." with UNDO SET 22 | Log a set snippet | fix | UNDO must revert the record its line names (principle 8). The line names the workout, the key takes back a set. Line "Set 22 logged." with UNDO; "Push A done." stays a line with no UNDO |

## 56 The workout, live (`live-workout.md`, written)

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| "Push A, set 1 of 4" / "Rest, then set 2" / "Rest, then Overhead press" / "Push A, last set" | context | ok | Under 32 characters |
| "last time 82.5 × 8" / "set 1, 82.5 × 8" / "4 sets, 82.5 × 8 best" | detail | ok | |
| "kg", "rest", "25 + 5 + 1.25 EACH SIDE" | set block | ok | |
| `LOG 82.5 × 8`, `SKIP REST`, `LOG 30 × 12 AND FINISH`, `PAUSE` | key | ok | No yes/no question anywhere on the page |
| "Hold me to tell me a set." | Tess, first three | ok | |
| "Set 2 logged. 80 × 7." + UNDO | Tess | ok | |
| "eighty for seven" | his heard words | ok | |
| "DRAG RIGHT +15 · FLING LEFT TO GO" | rest hint | fix | No " · " outside a pack size, and "TO GO" is vague. Two lines: "DRAG RIGHT +15" / "FLING LEFT TO SKIP" |

## 57 Notes on the new grammar

| Line | Where | Verdict | Rule and proposed words |
|---|---|---|---|
| ‹ REVIEW, "Notes", ‹ NOTES | top | ok | |
| "3 notes, the latest yesterday" / "4 notes, the latest just now" / "A place for loose thoughts" | context | ok | Under 6 words and 32 characters |
| "Write something. @ links a thing." | writing line | ok | |
| "now", "yesterday", "Tue" | row time | ok | |
| "12 Oct" | row time | fix | US date: "Oct 12" |
| "edited Tuesday, about Bench press" | note context | fix | 33 characters, over 32, and LINKS below already shows Bench press (§2): "edited Tuesday" |
| "edited just now" / "written Oct 12" | note context | ok | |
| LINKS, DONE, DELETE NOTE | words | ok | |
| "Bar felt heavy on set 3, deleted." + UNDO 10 s | Tess | ok | Better than M35's "Note deleted.", see cross-sheet 4 |
| "Nothing written yet." / 'Say "note: bar felt heavy" and I'll keep it here.' | empty page | ok | |

## Where two sheets say the same thing differently

| # | The thing | The wordings | Proposed one way |
|---|---|---|---|
| 1 | A rest day | 44 "rest day, Push A tomorrow"; 54 "Rest day."; 7d16c88 Home "Rest today" / "Legs A waits for tomorrow" but her line "Rest today. Legs A is next."; 7d16c88 "waits for next Wednesday" vs decisions "waits for Thursday" | Her line and Home: "Rest today. Legs A waits for tomorrow." Fixed days: "Legs A waits for Wednesday" (no "next"). "Push A is Thursday's." becomes "Push A is on Thursday." |
| 2 | What leaves the phone | 50 "Titles and counts only. Never notes, places, health or money."; 53 "Sends your task and calendar titles, never notes, places or health."; decisions 10:29 PM PT "Sends your task and event titles, never notes or places." | 50's line everywhere; Product retires the 10:29 PM wording |
| 3 | Clock times | 54 "6:00 PM", "6:00 pm", "at six"; decisions 3:05 AM PT "Push A at 7 PM"; home-lines "7:40 pm" | "6 pm", "7:40 pm" in sentences; `6 PM` only in label case. Heroes keep the bare hour ("Tacos at 7", "Push A at 6") |
| 4 | Deleting a note | 57 "Bar felt heavy on set 3, deleted."; tess-voice M35 "Note deleted." | 57's form; Research updates M35 to "{first line}, deleted." |
| 5 | Memory receipts | 49 "Kept. You rest on Sundays."; "Everything forgotten, 12 things."; 7d16c88 "Rest on Sundays, forgotten." | "{value words}, kept." / "{name}, forgotten." / "12 things, forgotten." |
| 6 | A row's recipe | 47 ask "for the tacos?" and "for the tacos."; row line "for tacos" | "for tacos" everywhere |
| 7 | "and N more" | 47 "and two more"; 53 "2 MORE" | Digits: "and 2 more" |
| 8 | The spend line | 50 "This month $0.00 of $10."; tess-voice M8 "Tess: $1.20 of $10 this month." | 50's line; Research updates M8 and M9 |
| 9 | Who speaks in Settings | 50 "Tess asks Claude...", "Tess stays on this phone." set in her voice; tess-voice: Tess speaks as "I" | Either set these in ink as app labels (like M13), or first person: "I stay on this phone." Design picks one |
| 10 | Counts as words | 46 hero "Three sessions"; 53 "Four hours free"; tess-voice "Numbers as digits" | Digits, or Design writes the hero exception into tess-voice |
| 11 | Tomorrow's workout | 44 `PULL A TOMORROW`; 54 "Pull A tomorrow, first." | "Pull A tomorrow." |
| 12 | Undo words | M34 "{name} taken back."; settled exceptions "Legs A, back on today.", "Claude key is back.", "Set 3 is back." | Research lists all three exceptions in tess-voice so Builders don't "fix" them |
| 13 | Dates | 50 "1 Nov"; 57 "12 Oct"; prose "16 Oct" in 41, 44, 46, 47, 49, 50 | "Nov 1", "Oct 12", "Oct 16" |
| 14 | The code's voice | `TessVoice.instructions` still says "Lead with what you did, in past tense" and `bannedWords` lacks "undone"; tess-voice principle 1 and the eval list changed Oct 15 | Core syncs `TessCapturing.swift:78` to the doc (not a sheet fix) |

Out of scope: British spellings in sheet prose and token or file names ("colour", "generalises", `living-colours.md`) are not on screen and stay as they are.
