# Shutdown and Day log copy (M4 slices 5 and 7)

For: Design studio (copy), Core engine, Product lead
Date: 2026-10-15
Checked against: `tess-voice.md` (2026-10-16). Context: `day-log.md`, `sticking-past-week-3.md`, `habits.md`, `../product/ship-list-m4.md`.

32 lines in 6 slots. Each slot shows at most one line, picked by the rule at the end of its table. When no row matches, Tess says nothing (voice rule 7).

## Shared building blocks

- **{counts}** is a list of what was done that day, built by the engine: nonzero counts only, at most 3, in fixed app order (Workouts, Kitchen, Tasks, Lists, Notes), joined with ", ". Forms: "1 workout", "2 workouts", "cooked once", "cooked 2 times", "4 tasks", "1 task", "2 notes". A zero is never printed; the item just drops out.
- **{headline}** is the Day log headline from the salience table in `day-log.md` ("Push day · carbonara"), without the count line.
- **Day boundary** is 04:00 local. A Shutdown opened between 00:00 and 04:00 belongs to the day before.
- **Gap** means no op of any kind for 3 or more days, the same trigger as the re-entry state on Now.
- **Busy** means 8 or more counted items, or headlines from 3 or more apps.
- **Quiet** means 1 or 2 counted items and no finished process.
- Numbers are digits. Units appear once. Times use 24 h ("08:00"), sleep uses "7h10" as in the Day log.

## Slot A: Day log, Tess line (slice 5)

One line under the date, above the assembled lines. Your own `DayNote` always sits above it in larger type. On past days the line is fixed once the day closes, so scrubbing back reads like a record, not a running commentary.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| A1 | Back in. {headline}. | Back in. Push day · 2 tasks. | First day with any op after a gap |
| A2 | {lift} PR, plus {n} more things. | Bench PR, plus 5 more things. | Any PR or first ever that day |
| A3 | Travel day. {n} things logged on the move. | Travel day. 3 things logged on the move. | A calendar event that day looks like travel (flight, train, hotel), or the phone sat in a different time zone |
| A4 | {workout} and {recipe}. Fed and trained. | Push day and carbonara. Fed and trained. | A finished workout and a finished cook on the same day |
| A5 | Full one. {n} things across {apps} apps. | Full one. 11 things across 4 apps. | Busy |
| A6 | {workout}, {sets} sets. {n} other things too. | Pull day, 16 sets. 3 other things too. | A finished workout, no cook |
| A7 | Cooked {recipe}. {n} more things logged. | Cooked carbonara. 2 more things logged. | A finished cook, no workout |
| A8 | Quiet day. {counts}. | Quiet day. 2 tasks. | Quiet |
| A9 | Rest day. Slept {sleep}. | Rest day. Slept 8h05. | No counted items, but a Health sleep fact exists |
| A10 | Fills itself as you go. | Fills itself as you go. | Today only, nothing logged yet, before Shutdown |

Silent cases: a past day with nothing logged shows only the date (empty runs collapse to "Oct 3 to 6", as `day-log.md` says), and a day with a `DayNote` and nothing else shows only the note. In A2, A6 and A7, the "{n} more/other things" clause drops when {n} is 0, so "Bench PR." stands alone.

**Selection rule A:** check A1 to A10 in order; the first match wins. Today's line is recomputed when an op lands; a past day's line is frozen at its Shutdown, or at 04:00 the next day if there was no Shutdown.

## Slot B: Shutdown opener (slice 7)

The first line of the 21:00 Now card. Counts only, past tense, never what didn't happen.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| B1 | Back in. Did {counts} today. | Back in. Did 2 tasks, 1 workout today. | First day back after a gap |
| B2 | Did {counts}. Plus a {lift} PR. | Did 1 workout, 3 tasks. Plus a bench PR. | A PR or first ever that day |
| B3 | {n} things done. Full day. | 12 things done. Full day. | Busy |
| B4 | Did {counts}. | Did 4 tasks, 1 workout, cooked once. | 2 or more counted items (the default) |
| B5 | {name}, done. That counts. | Pull day, done. That counts. | Exactly 1 counted item |
| B6 | {meetings} meetings, slept {sleep}. That was the day. | 3 meetings, slept 6h40. That was the day. | No counted items, but calendar or Health facts exist |
| B7 | A quiet one. Want a line for tomorrow? | A quiet one. Want a line for tomorrow? | Nothing at all: no items, no facts |

In B6, either fact drops out when it is missing ("Slept 7h10. That was the day.").

**Selection rule B:** a late-night opener (F1) replaces B whenever the late-night condition holds. Otherwise check B1 to B7 in order; the first match wins.

## Slot C: Shutdown carry-over (slice 7)

Shown above the preselected items that roll to tomorrow. Moving is the default and is said as a plain fact, never as a debt.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| C1 | {n} going to Later. Still there, just quieter. | 2 going to Later. Still there, just quieter. | Some open items are 7 or more days untouched (auto-age rule) |
| C2 | {n} rolling over. Plan my day picks up to 3. | 7 rolling over. Plan my day picks up to 3. | 6 or more items roll |
| C3 | {task} moves to tomorrow. Tap to keep it. | Call the bank moves to tomorrow. Tap to keep it. | Exactly 1 item rolls |
| C4 | {n} moving to tomorrow. Tap any to keep. | 3 moving to tomorrow. Tap any to keep. | 2 to 5 items roll |

Silent case: nothing rolls, so the section is hidden. If {task} is longer than 4 words, C3 uses the C4 form with n = 1 ("1 moving to tomorrow. Tap to keep it.") so the line stays under 12 words.

**Selection rule C:** C1 shows as its own small line under the list when it applies (it describes a different group). For the main line, check C2 to C4 in order, first match wins. After 00:00 the late-night form F2 replaces C2 to C4.

## Slot D: tomorrow line (slice 7)

The optional line for tomorrow. It is a ghost-row placeholder, never a question that waits for an answer.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| D1 | Tomorrow starts with {event} at {time}. | Tomorrow starts with Standup at 09:30. | Tomorrow has a timed calendar event before 12:00 |
| D2 | One line for tomorrow, if you want. | One line for tomorrow, if you want. | Otherwise |

**Selection rule D:** D1 if it matches, else D2. B7 already offers the line, so on a B7 day D2's placeholder shows empty (no second offer).

## Slot E: Shutdown close (slice 7)

Shown for about 2 seconds after "Shutdown complete", as the card folds into the Day log.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| E1 | Closed. Tomorrow picks up from here. | Closed. Tomorrow picks up from here. | First day back after a gap |
| E2 | Closed. {lift} PR filed under {weekday}. | Closed. Bench PR filed under Tuesday. | A PR that day |
| E3 | Closed. Your line is waiting at 08:00. | Closed. Your line is waiting at 08:00. | You wrote a tomorrow line |
| E4 | Closed. {n} things in {weekday}'s log. | Closed. 6 things in Tuesday's log. | 1 or more counted items |
| E5 | Day closed. Nothing waiting tonight. | Day closed. Nothing waiting tonight. | No counted items |

**Selection rule E:** a late-night close (F3) replaces E whenever the late-night condition holds. Otherwise check E1 to E5 in order; the first match wins.

## Slot F: late-night Shutdown

Late night means Shutdown is opened at or after 23:00, or between 00:00 and 04:00. It writes to the day before when past midnight, and names that day so there is no doubt where things went.

| # | Template | Filled example | Picked when |
|---|---|---|---|
| F1 | Filed under {weekday}. Did {counts}. | Filed under Tuesday. Did 3 tasks, cooked once. | Late night, 1 or more counted items (replaces B) |
| F2 | {n} moving to {nextWeekday}. Tap any to keep. | 2 moving to Wednesday. Tap any to keep. | Past 00:00 and 1 or more items roll (replaces C2 to C4) |
| F3 | Closed. Sleep is also training. | Closed. Sleep is also training. | Late night and a workout finished that day (replaces E) |
| F4 | Saved to {weekday}. Pick up tomorrow. | Saved to Tuesday. Pick up tomorrow. | Late night, any other case (replaces E) |

Late night with no counted items falls back to B6 or B7 for the opener.

## Selection rule (engine summary)

1. Work out the inputs once per render: the attributed date (04:00 boundary), counted items, finished processes, PRs, rolled items, Health and calendar facts, gap flag, late-night flag. All are derived from the op log and the mounts; no model call.
2. For each slot, if the late-night flag is set and the slot has an F row, use the matching F row.
3. Otherwise walk the slot's rows top to bottom and take the first whose condition holds.
4. If none holds, render nothing for that slot.
5. Same inputs always give the same line. There are no random variants and no rotation, so a line can be tested and a past Day log never changes wording on rescrub.
6. Fill placeholders, then drop any clause whose number is 0. If the filled line reaches 12 words, use the slot's short form (named in the slot notes) or drop the trailing clause.

## Self-check against tess-voice.md

Run over all 32 filled examples above (word count by spaces, banned-word list from the eval checklist, "!" and emoji regex).

| Voice rule | Result | Notes |
|---|---|---|
| 1. Done, then the number | Pass | Openers and closes lead with the done thing in past tense (B2 to B5, E2, E4, F1). Headlines name the thing, then one count. |
| 2. Counts, not streaks | Pass | Only counts and "{n} things". No run lengths, no "in a row", no reset. |
| 3. One line, under 12 words | Pass | Longest filled example is 10 words (C2, C3); C3 has a short form for long task names. Templates with lists cap {counts} at 3 items. No greeting, no sign-off, no praise word. |
| 4. The user decides | Pass | Carry-over is "Tap any to keep", the tomorrow line is "if you want", B7 asks "Want...?". No "should" or "don't forget". |
| 5. Dry, rarely | Pass | 3 dry lines of 32 (A4 "Fed and trained", E2 "filed under", F3 "Sleep is also training"), all on done states, about 1 in 10. |
| 6. Honest about limits | Pass | Travel day (A3) only fires on a calendar title or time-zone change, never on a guess. Missing Health data drops the clause instead of inventing a number. |
| 7. Silence is fine | Pass | Empty past days, note-only days, nothing rolling, and no-match slots all render nothing. |
| No misses, no guilt | Pass | No line mentions what didn't happen. "Rolling", "moving" and "Later" replace "unfinished", "left over" and "overdue". Gaps are never counted. |
| No red | Pass | Copy carries no colour cue; carry-over and Later use the normal text style. |
| Banned words (should, must, missed, streak, great, awesome, sorry, oops) | Pass | None present. Also absent: "again", "only", "failed", "behind", "late". |
| Digits, units once, no "!", no emoji | Pass, 1 exception | "cooked once" stays as wording, because the ship list uses it for slice 7. From 2 it is "cooked 2 times". |

### Lines fixed during the check

| Draft | Failed | Fixed to |
|---|---|---|
| Good to see you. Here is today. (from `sticking-past-week-3.md`) | Rule 3, a greeting | Back in. Did {counts} today. (B1) |
| Nothing logged today. | Points at an absence on a past day | Silence on past days; A10 for today only |
| 3 tasks left over. Moving them to tomorrow. | Guilt ("left over") | {n} moving to tomorrow. Tap any to keep. (C4) |
| Only 2 tasks today, and that's fine. | "Only" grades the day | Quiet day. {counts}. (A8) |
| Great work. Day closed. Rest well. | Praise word, sign-off | Closed. {n} things in {weekday}'s log. (E4) |
| You've had a big day of training and cooking. | 10 words but no count, and narrates | {workout} and {recipe}. Fed and trained. (A4) |
| Up late. Filed under Tuesday. | Comments on the user's hour | Filed under {weekday}. Did {counts}. (F1) |
