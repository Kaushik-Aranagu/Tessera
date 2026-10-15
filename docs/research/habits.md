# Habits that count, not judge

For: Product lead, Core engine, Design studio
Date: 2026-10-15

## What the apps and studies say

- **Weekly targets beat daily chains.** Streaks and Habitify allow "x times per week"; Loop allows "x times in y days". Apple Fitness rings fill themselves from sensors, and since watchOS 11 you can pause rings and set goals per weekday. Weekly targets give slack, and slack keeps people going: Sharif and Shu (2017) found that built-in "emergency reserve" days raised persistence.
- **Missing one day does not matter.** Lally (2010): habits took a median of 66 days to become automatic, and one missed day did not change the curve. Loop's habit strength score works the same way: a miss lowers the score a little, it never sets it back to zero.
- **Broken streaks make people quit.** Silverman and Barasch (2022): once a streak breaks, people do the activity less. This is the "what-the-hell effect" (Polivy and Herman): one slip, then "the day is ruined anyway". Way of Life's red X and Not Boring Habits' streak counter are built on this risk. Atoms ("never miss twice") still talks in streaks.
- **Monday is a gift.** Dai, Milkman and Riis (2014), the fresh-start effect: people start goals more often at the start of a week. A clean Monday is a feature, as long as it does not show a debt.
- **Close to done pulls you forward.** Goal gradient (Kivetz et al. 2006): effort speeds up near the goal. "3 of 4" works better than "75%".
- **Gentle apps last.** Finch (a pet you care for, no penalty) and Tiimo (visual day, no guilt) are the ADHD favourites. People say they quit apps because of red, nagging reminders and catch-up screens.
- **Auto-fill removes the double entry.** Habitify and Streaks read Apple Health (steps, workouts). The check-in happens without a second tap, so the habit is just a view of what you already did.

## The habit, as data

| Field | Value | Default |
|---|---|---|
| `name` | text | none |
| `target` | 1 to 7, times per week | 3 |
| `period` | calendar week, Monday 00:00 local | fixed in slice 2 |
| `rule` | optional: "counts when a `<Class>` finishes" | none |
| `pausedWeeks` | list of week starts | empty |
| `attachedTo` | optional link to any object | none |

- A **check-in** is an object linked to the habit (date, plus `source`: manual, or a link to the object that filled it).
- **One check-in per day counts.** Two workouts on Tuesday count as 1 toward "train 3 times".
- **Rule check-ins are worked out, not saved.** The count is: manual check-ins, plus finished objects of the rule's class that week. Undoing a workout removes its check-in for free, and the op log stays clean.

## How a week looks

- Seven small marks, Monday to Sunday. Done days are filled. Past days with nothing look the same as future days: empty, never crossed out.
- The headline is **"2 of 3 this week"**. When the target is met: "Done for the week", and extra days show as "+1".
- One tap deeper: "Last 8 weeks: target met in 6", and "4 of the last 7 days" for daily habits. Never a streak number.
- No red anywhere. No percentage under the headline.

## The week boundary

- Monday 00:00: the count goes back to 0 quietly. No summary of last week, no "missed" message, no notification.
- Nothing carries over. A short week is never a debt for the next one.
- A paused week is left out of the history ("6 of 7 weeks", not "6 of 8"). It shows as a soft blank, never as a failure.
- Coming back after a gap: show this week only (re-entry rule 1 in `sticking-past-week-3.md`).

## Showing where a check-in came from

- Each auto check-in shows the source's icon and a tappable handle: "Push day A, Tue". A manual one shows "logged".
- One line after the source finishes: "Counts for Train 3×/week (2 of 3)". This is the reward, and it comes from the data.
- To remove an auto check-in you edit the source (v1). A "doesn't count" switch can come later.

## Never

- Streak counters, or anything that resets to 0 because of a miss.
- Red, crosses, "missed", "failed", "you broke".
- Catch-up or backfill prompts ("log the days you missed?").
- More than one reminder a day. Habits send none in v1; Now can show the one that is closest to its target.
- Raising the target on your behalf, or comparing weeks in a way that sounds like a grade.

## Smallest first version

**Slice 2 (engine):** `Habit` class with the fields above. Manual check-in action (undoable). `count(week)`, `isMet(week)`, `lastWeeks(n)` excluding paused weeks, and `lastDays(7)`. Capture "habit read" or "✓ read" adds today's check-in. Tests: Monday boundary in local time, one per day, pause, undo.

**Idle slice (logs fill habits):** a `rule` that names one class (`Workout` or `Cook`) and fires on "finished". The count query adds those objects. The workout and cook summaries get the one "Counts for..." line. Apple Health as a source comes later (needs HealthKit work).

Not in v1: custom periods (x per month), reminders, per-weekday targets, the strength score.

## Yes/no for Kaushik (defaults taken, nothing is blocked)

1. Count at most one check-in per day toward a weekly target? Default: yes.
2. No habit notifications at all in v1? Default: yes.
