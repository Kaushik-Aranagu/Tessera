# Phrases for the new features (board item 122)

For: Core (the grammar in `TesseraTess`, AI-8), Builder B (AI-9), the AI thread, Design (49 and 44). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). The words he'd say for four new things: remember, what do you know, forget, and routine changes. The sources:
- Design 49 `tess-knows.md` with its addendum d73cba4;
- Design 44 part two `training-mode.md` (#359) and `routine-editor.md`;
- ship list AI-8 and AI-9;
- `decisions.md` (the rest weekday, "Drop clears days", "skip" in a workout).

The "master today" column is a hand trace of `TessGrammar.parse` on master f2f10f9 (rule order: note, pasted recipe, question, process, in focus, lifts, kitchen, reschedule, task). The memory actions come from #356 (`core/tess-memory` e098e7e). Nothing was run.

**Summary:**
- No grammar exists yet for any of the four. Most phrases fall through to the model, which is fine with Claude on and a miss line with it off.
- Six phrases become **wrong tasks** today, because a weekday or "today" is in them. Examples: "remember that I rest on Sunday" makes a task called "Remember that I rest", and "rest day sunday" makes a task called "Rest day".
- One phrase can **move the wrong task**: "push A to Thursday" matches the reschedule shape with the name "a", so a single open task with the word "a" in its title ("Call a plumber") moves to Thursday.
- Claude can't do any of it either. `TessTools` has no remember, forget or plan tool, and the plan editing actions (days, mode, drop, order) aren't in `ActionRegistry`.

## 1. Remember

His own "remember that …" keeps after the 2 s dry, with UNDO (AI-8, Design 49). The screen rows from `fixtures/tess-memory.md` S1 to S20 decide kept, private or refused. This table covers only how the phrase is read.

| # | He says | Expect | Master today |
|---|---|---|---|
| V-R1 | remember that I rest on Sundays | Kept: "Kept. You rest on Sundays." with UNDO | Model ("Sundays" isn't a weekday word, so no date) |
| V-R2 | remember that I rest on Sunday | The same as V-R1. A weekday in a memory phrase is part of the fact, never a due date | **Task "Remember that I rest", Sunday 9 am** ("on" dropped as a lead word) |
| V-R3 | remember I train after work on weekdays | Kept (with or without "that") | Model |
| V-R4 | Tess, remember mom's birthday is Oct 9 | Kept. The wake word goes; "9" is licensed by his words | Model (the wake word is stripped) |
| V-R5 | Remember that tacos means the sheet-pan tacos. | Kept, Kitchen. A spoken stop and a capital make no difference | Model |
| V-R6 | remember to call mom Friday | **A task**, "Call mom", Friday. "remember to" + a verb is a reminder, not memory | Task "Remember to call mom", Friday. The title keeps "Remember to" |
| V-R7 | don't forget the dentist Thursday | A task, "Dentist", Thursday | Task "Don't forget the dentist", Thursday |
| V-R8 | remember to stretch | A task with no day goes to Later: "Stretch" | Model (no date, no "todo") |
| V-R9 | remember this | No write. Tess: "Say what to keep, like "remember that I rest on Sundays"." A statement, not a question | Model |
| V-R10 | remember my squat best is 140 | Not kept. Tess: "Training keeps your bests." Lifts and bests are the ledger's facts, not memory | Model |
| V-R11 | remember I weigh 82.4 kg | Refused as a measured value (`tess-memory.md` S9) | Model |
| V-R12 | remember that in a live workout: "remember the left rack is broken" | Kept, Training. A memory phrase isn't a set, so the live workout doesn't own it. No ask | Model (no set shape) |
| V-R13 | I rest on Sundays (no "remember") | Never his own keep. With Claude on, Claude's `remember` may offer it as a ghost row, KEEP / NOT NOW | Model |
| V-R14 | Siri: "remember that I like tacos" | "Say that in Tessera and I'll keep it." Nothing written (AI-8) | No intent yet |

## 2. What do you know

Her answer is "12 things about you." with **WHAT I KNOW** under her line, which opens the page with ‹ TODAY (Design 49). It must work with Claude off, so it's a grammar phrase read **before** the question rule.

| # | He says | Expect | Master today |
|---|---|---|---|
| V-K1 | what do you know | "12 things about you." + WHAT I KNOW | Question rule, so the model's read-only answer. With Claude off, nothing knows the count |
| V-K2 | what do you remember | The same | The same |
| V-K3 | what do you know about me | The same | The same |
| V-K4 | show me what you know | The same | The same ("show me" is a question lead) |
| V-K5 | Tess what do you know (no comma) | The same. The memory phrase allows a leading "Tess" | Model. The wake word stays because no comma follows it, so the question rule misses it too |
| V-K6 | what do you know about my training | The same answer, and the page opens at the Training group | Model |
| V-K7 | what do you know, with nothing kept | "Nothing yet. Say "remember that…" and I'll keep it." and no WHAT I KNOW (S8) | Model |
| V-K8 | what do you know, with only day lines (week one) | "Nothing kept yet." + WHAT I KNOW, since the page has The last 14 days (addendum S2). **Not drawn**; this is the default proposed | Model |
| V-K9 | do you know my rest day | Not this phrase. It's a question about one fact, so the model answers it with the pack | Model ✓ |
| V-K10 | what do you know about mom | Not this phrase in v1: the model answers it from the pack. People lines are packable unless private | Model ✓ |

## 3. Forget

Design 49 draws forgetting only as a swipe and a hold. These are the defaults proposed for saying it. A line he names is forgotten with the same 10 s UNDO and the same Tess line as the swipe. Forget everything is never done by voice.

| # | He says | Expect | Master today |
|---|---|---|---|
| V-F1 | forget that I rest on Sundays | One line has every word he said, so it's forgotten. "Rest on Sundays, forgotten." with UNDO. Redaction after 10 s, as for the swipe | Model. Claude has no forget tool |
| V-F2 | forget the shoulder thing | One line matches "shoulder" (a private one). "Left shoulder, forgotten." with UNDO. Private lines match the same way. The matching is on the phone, so nothing is sent | Model |
| V-F3 | forget what I said about tacos | Words like "what I said about", "the … thing" and "that" don't count toward the match | Model |
| V-F4 | forget about mom | Two lines match ("mom's birthday", "call mom back"). No write. Tess: "Two things match. Swipe the one to forget." + WHAT I KNOW | Model |
| V-F5 | forget my gym | No line matches. "I don't have that." + WHAT I KNOW | Model |
| V-F6 | forget that I usually train 6 to 8 | A noticed line. Forgotten, and its rule id is suppressed (`tess-memory.md` M3) | Model |
| V-F7 | forget everything | No write. Tess: "Hold FORGET EVERYTHING on WHAT I KNOW." + WHAT I KNOW. It wipes every line, so it keeps the hold | Model |
| V-F8 | never mind / forget it, within 10 s of "Kept." | The same as UNDO: the line goes and Tess says "Rest on Sundays, taken back." | Model |
| V-F9 | forget it, with nothing kept in the last 10 s | Not a memory phrase. It goes to the model | Model ✓ |
| V-F10 | forget the dentist tomorrow | Not memory and never a task called "Forget …": it goes to the model, which may ask about the task | **Task "Forget the dentist", tomorrow** |

## 4. Routine changes

The words are Design 44's own lines, so a spoken change lands exactly like the tap. Every change has UNDO. The routine names below are his PPL x2 (Push A, Pull A, Legs A, Push B, Pull B, Legs B).

| # | He says | Expect (action, Tess) | Master today |
|---|---|---|---|
| V-T1 | Push A on Mondays and Thursdays | SetRoutineWeekdays {Mon, Thu}. "Push A on Mondays and Thursdays." Switches the plan to fixed days if it rolls on, and says so: "Push Pull Legs on fixed days." | Model ("Mondays" is plural) |
| V-T2 | push a on monday and thursday | The same as V-T1 | **Task "Push a and", Thursday 9 am** |
| V-T3 | push A to Thursday | Push A's day is Thursday. If Pull A had it: "Thursday was Pull A's. Push A has it now." | **Reschedule shape**: the name is "a", so a single open task with the word "a" ("Call a plumber") moves to Thursday. With 0 or 2+ such tasks, the model |
| V-T4 | move Legs A to Saturday | SetRoutineWeekdays {Sat} on Legs A, as V-T3 | Model, unless one open task has both "legs" and "a" |
| V-T5 | fixed days / rolls on | SetScheduleMode. "Push Pull Legs on fixed days." / "Push Pull Legs rolls on." | Model |
| V-T6 | drop Push B | DropRoutineFromPlan, and its days clear. "Push B dropped." with UNDO. History stays | Model |
| V-T7 | new routine Push C | CreateRoutine. "Push C made." The Routines page opens on it with "Add an exercise" ready | Model |
| V-T8 | put Pull B before Legs A | MoveRoutineInPlan. "Pull B goes before Legs A." | Model (no "to", so no reschedule shape) |
| V-T9 | add face pulls to Pull A | AddSlot with the last-used sets, or the library default. "Face pulls, in Pull A." | Model |
| V-T10 | take dips out of Push B | RemoveSlot. "Dips dropped." with UNDO | Model |
| V-T11 | swap bench for dumbbell press in Push A | SwapSlotExercise. "Dumbbell press, in for bench press." | Model |
| V-T12 | rest day Sunday | restWeekday = 1. "Sunday is your rest day." This is his answer to the Oct 22 list's question 12, so Product logs it | **Task "Rest day", Sunday** |
| V-T13 | make Sunday my rest day | The same as V-T12 | **Task "Make my rest day", Sunday** |
| V-T14 | skip legs today | No write. A rolling plan already rolls a missed day on: "Legs A waits for tomorrow." On fixed days: "Legs A waits for next Wednesday." | **Task "Skip legs", today at the next hour** |
| V-T15 | rest day today | No write, as V-T14: "Rest today. Legs A is next." | **Task "Rest day", today** |
| V-T16 | skip, in a live workout | "Skip is on the workout screen." (decided, 8:58 PM PT Oct 15) | ✓ |
| V-T17 | Push A tomorrow | No write: the plan, not a date, decides the day. "Pull A is tomorrow. Push A is after it." | **Task "Push A", tomorrow** |

## 5. Gaps

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| V1 | **No memory phrase rule.** With a weekday in it, "remember that …" becomes a task (V-R2); without one, it needs Claude | `TessGrammar.parse` | A rule before the question rule: `^(tess,? )?(please )?remember (that )?(.+)` → RememberFact. "remember to" / "don't forget (to)" + the rest → a task with those words dropped (V-R6, V-R7) | Core (AI-8) |
| V2 | **"what do you know" is a question,** so with Claude off nothing answers | `isQuestion` comes first | Match V-K1 to V-K8 before the question rule and answer from the memory count, on the phone | Core (AI-8), Builder B (the key) |
| V3 | **Forget by voice isn't drawn** | Design 49 | V-F1 to V-F10: every word must match one line; 2+ or 0 open the page; never forget everything by voice | Design (copy), Core |
| V4 | **Claude can't do any of it.** `TessTools` has no remember, forget or plan tool. SetRoutineWeekdays, MoveRoutineInPlan, DropRoutineFromPlan, SetScheduleMode and AddRoutineToPlan aren't in `ActionRegistry`, so App Intents can't reach them either | `TessTools.swift`, `ActionRegistry.swift` | Register the plan actions. Add `remember` (pending, a ghost row) to Claude's tools. Forget stays on the phone and is never a Claude tool | Core, the AI thread |
| V5 | **"push A to Thursday" can move a task.** The reschedule shape's name is "a" | `rescheduleShape`, `parseReschedule` | A name that is a routine's name, or "a"/"b" after push, pull or legs, is never a task reschedule. Single-letter words never count toward a task match | Core |
| V6 | **Routine words become tasks** with a day in them (V-T2, V-T12, V-T13, V-T14, V-T15, V-T17) | `parseTask` | Like a lift (A184), a phrase that names a routine, "rest day" or "skip" + a routine never becomes a task: the routine rule or the model reads it | Core |
| V7 | **Plural weekdays.** "Mondays" isn't in `weekdays`, which is right for memory but needed for V-T1 | `TessDates.weekdays` | Read plurals only inside the routine rule, never as a date | Core |
| V8 | **Rest day by voice before Oct 22.** V-T12 answers the list's question 12 | `oct-22-list.md` | If he says it first, Product logs it and drops question 12 | Product |
| V9 | **Bests as memory** (V-R10) | Design 49, arch 4 | Not kept: "Training keeps your bests." | Design (copy), the AI thread |
| V10 | **"skip" and "rest today" lines** aren't drawn (V-T14, V-T15, V-T17) | Design 44 | The words above. They are statements, with no UNDO since nothing is written | Design (copy) |

## 6. For the grammar regression fixture

V-R2, V-R6, V-R7, V-F10, V-T2, V-T3, V-T12 to V-T15 and V-T17 are the rows that misfire today. Once V1, V5 and V6 land, they belong in `fixtures/grammar-regression.md` as guard rows: each one must never write a task with the title shown in the "master today" column.
