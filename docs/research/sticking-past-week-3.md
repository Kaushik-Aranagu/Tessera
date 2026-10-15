# Sticking past week 3

For: Product lead (cross-team), Design studio
Date: 2026-10-15

## Why tools get dropped (short version)

- **Novelty decays in 2 to 3 weeks; habits take longer.** Lally (2010): automaticity took 18 to 254 days, median 66. Missing one day did not hurt the curve. So week 3 is when the novelty is gone and the habit is not built yet. [Lally summary](https://www.spring.org.uk/2023/01/form-a-habit.php)
- **Habits ride on context, not willpower.** Wood: about 43% of daily actions are habitual and are triggered by place, time and the previous action. A tool sticks when it attaches to something that already happens.
- **ADHD is a problem of doing, not knowing** (Barkley). Help has to sit at the "point of performance". Ramsay: shame and avoidance build on each other. An app full of overdue items becomes something you avoid.
- **Lapsing is normal.** Epstein et al. "lived informatics" (2015): people stop, forget, and come back. Many resume, if coming back is easy. Their follow-up work says to design for life after use stops, too. [Epstein 2015](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf), [Beyond abandonment](https://library.selfresearch.org/research/beyond-abandonment-to-next-steps-understanding-and-designing-for-life-after-personal-informatics-tool-use/)
- **Market data agrees.** Day 30 retention for most app categories is in single digits. [Benchmarks](https://unstar.app/blog/app-retention-benchmarks-2026)
- **What people say when they quit** (r/ADHD, r/productivity, about Notion, Todoist, Habitica, Tiimo and Structured): "I spent more time setting it up than using it", "the red overdue count made me close it", "I broke my streak and never opened it again", "too many notifications, I muted it, then forgot it". Things lasts longer for many because it is calm and stays out of the way.

## Design rules, ranked

1. **Coming back is a fresh start, never a bill.** After a gap, show today, not the backlog.
   Smallest change: the re-entry screen below. Touches: Home (Now), Tasks.
2. **Nothing ever goes overdue in red.** Old items fade into a quiet "Later" pile on their own after 7 days untouched. They are still there, just not shouting.
   Smallest change: an auto-age rule on Task due dates, plus a muted "Later (12)" row. Touches: Tasks, Lists.
3. **Attach to moments that already happen.** One existing cue per area: gym arrival or open, making dinner, bedtime. Do not invent new rituals.
   Smallest change: Now picks its one next thing by time of day (workout slot, cooking slot, Shutdown at 21:00), which M4 already plans. Touches: Home (Now), Kitchen, Shutdown.
4. **Counts, and resilient ones.** "12 workouts in the last 30 days", never "streak: 0". A missed day never resets anything.
   Smallest change: replace any run-length figure with a rolling count; check the habits design before it ships. Touches: Workouts, habits (planned).
5. **The useful version takes under 10 seconds.** Logging must work with zero setup and good defaults; structure is optional and later.
   Smallest change: every new app ships with one ghost-row capture ("bench 80x5", "eggs") before any setup screen. Touches: Lists, habits, body weight.
6. **Pay back on day one.** Every entry shows something back right away (a PR, "3rd time this month", a fuller Day log). The reward comes from the data, not from confetti.
   Smallest change: one plain feedback line after a log. Touches: Workouts, Day log.
7. **Quiet by default, one interrupt a day at most.** Notification fatigue leads to muting, and muting leads to forgetting. Prefer the Live Activity or widget, which you see without being nagged.
   Smallest change: a global cap of 1 non-timer notification a day; the rest wait in Now. Touches: interrupt masking (M4 slice 4).
8. **Fresh but familiar.** Novelty fades, so add small, rotating surprises inside known places, such as an "on this day" line from the Day log or a new theme. Never move the core controls.
   Smallest change: one rotating "from your history" line on Now. Touches: Home, Day log.
9. **Easy to shrink.** On a bad week the app should get smaller, not louder. Let any app be paused ("hide Kitchen for now") with no loss of data.
   Smallest change: a "pause" action on each app tile; paused apps leave Now. Touches: Home.
10. **Show the long view only when asked.** Trends are motivating when you look on purpose, and judging when they are pushed at you.
    Smallest change: trends live one tap deep, never on the open screen. Touches: Workouts, Day log.

## Re-entry after a gap (5 days away)

When the app opens and there has been no activity for 3 days or more:

- **One line of welcome, with no count of missed days.** "Good to see you. Here is today."
- **One next thing**, picked by time of day, and small on purpose: "Do a short Push day (30 min)?" or "Pick one task for today".
- **What is still running**, frozen where it was left: "Half-read recipe, carbonara" with Resume. Anything older than 7 days is quietly sent to Later.
- **A soft summary, under a fold**, that only counts things that did happen: "Since last time: 1 workout, 2 notes".
- **Plan reset offer:** if a training plan slipped, "Restart this week from day 1?" with one tap. No "you missed 3 sessions".
- **No catch-up list.** The backlog is reachable from Tasks but never shown first.

Effort: small. It is a Now state, and it reuses the process list and Ready-to-Resume.

## Top 3 to do now

1. The re-entry state on Now (rule 1). It is the strongest single fix for lapsing.
2. Auto-age to Later, with no red anywhere (rule 2).
3. Rolling counts instead of streaks, decided before habits ship (rule 4).
