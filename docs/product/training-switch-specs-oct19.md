# Training switches, clock page and Day log page: row text for Builder A (Oct 19)

Product defaults, reversible. Every default is today's behavior.

## restTimer (On | Off, default On)
On: after a set commits, the rest countdown runs (Live Activity, rest-end local notification title "Timer", body "Rest is up"; no ActivityKit alert). Off: no countdown, no rest Live Activity, no rest-end notification; set logging, Done and the closing face are unchanged. Flipping it mid-workout takes effect at the next set; a running rest finishes.

## swapExercise (Two taps | One tap, default Two taps)
Two taps (today): pull down on the exercise name, see alternatives (same family, then same pattern, ranked by muscle overlap then gym equipment), tap one. One tap: a tap on a small "Swap" word under the name applies the top-ranked alternative at once with a 10 s UNDO (no 2 s ghost; ruled Oct 19); the full list is still one pull down away. Either way the swap is for this session only and loads convert.

## finishNudge (Off | On, default Off)
On: if a workout is still running 45 min after its last logged set (the same 45 min idle rule), send one quiet local notification, once per workout: "<title>, ready to finish?" (masked: "Private workout, ready to finish?"). Never between 11 PM and 7 AM, never a second time, no red, no count of what was missed. Tapping opens the closing face "<title>, ready to finish". The 6 h auto-finish is unchanged.

## Cook clock page (Builder A owns it end to end; Builder B owns the recipe page and the Cook hand-off)
Source sheets: design 69 (clock page), kitchen 12-cook-mode.md as amended, us-kitchen-pages.md for US units, decisions G228 and G229. Key points: the clock page IS the cook; dark ground like the workout, cream ink, screen stays awake; a running process (lit ProcessSeam, Now reads the recipe title); timer horizons stacked from the top edge; this step at 34/500 with scaled ingredients at 70%; swipe up or down is the only way to change step; finish keys are named actions only (G229); never suspended while a timer runs or within 45 min of the last step change; Reduce Motion crossfades the step; haptics through MotionPolicy only. Row text for VO5 to VO24 is in the Kitchen cook-mode acceptance; ask the coordinator for any row you need.

## Day log page (Core builds DayStory.lines; Builder A draws the page)
Source: design/day-log-page.md and day-log-v1.md. Key points: entry is the word "Day log" on Review's link line and the Home day label; the page opens on today at the bottom, lines rise bottom up; month at Title 44/500; each day is a date label, then rows with time (16/600 tabular, secondary) at x 22 and text (21/400) at x 86; no dots, no cards, no totals, no praise, no colour for good or bad days; empty days collapse to one row ("OCT 1 TO 4"), never a count; the faint row for an unfinished workout; "Also:" tail only past 6 lines; tap a line opens its object with back word DAYS; margin scrub on the left 80 pt with a Numeral 80 Light day under the thumb; 4 AM day boundary; Reduce Motion crossfades. Brand-new log: "Your days write themselves here."
