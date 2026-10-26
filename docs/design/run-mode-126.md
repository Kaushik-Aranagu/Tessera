# Item 126: Run mode, one focus mode for any routine
Kaushik, Oct 22: workout mode should be generic: a recipe is a routine, and so are a
morning routine and a night routine. Stills: mockups/run-mode-126.png (workout set,
recipe step, morning routine).

## The model
A routine is an ordered list of steps. Each step has one kind:
- counted (weight x reps, or reps): the live set as it is today
- timed (a countdown: rest, simmer, stretch, plank)
- check (just done or skip: water, pills, plan the day)
- parallel (runs beside the next step: "at the same time", recipe timers)
Run mode shows one step at a time. Same skeleton for every routine; each kind fills it.

## The skeleton (top to bottom)
1. Top line: "< Back", routine name, "step N of M" (set N of M in workouts).
2. Progress strip: one segment per step, done = ink, now = hot, ahead = 18% ink.
3. Step title (40 pt Figtree), then one hint line (last time, how, what for).
4. The big thing: Outfit 200 at 108 pt: the weight, or the countdown, or nothing for a
   check step (then the title moves down into this space).
5. What the step needs: plates, ingredients with amounts, or for a check routine what is
   done so far with times.
6. One ink action (Log / Start timer / Done) and one quiet word (Pause / Skip).
7. Next step, faint, one line, so the next thing is never a surprise.
Back always works (sheet 120 rule: never stuck); the routine keeps running, a Live
Activity carries the step and its timer, and coming back lands on the same step.

## Tuned per scenario
- Workout: set marks (sheet #1195 chasing pulse) sit under the title; rest is a timed step
  inserted after each logged set; long press = exercise page.
- Recipe: parallel steps show "at the same time"; amounts scale with serves; screen kept on.
- Morning / night routine: mostly check steps; the order can be dragged; it starts from a
  time or from Today ("Morning, 6 steps, START"); a skipped step is a day mark, not a
  failure.
- Any routine he makes himself uses the same kinds; a new kind is a sheet first.
Haptics: one per step done; the countdown ends with one firm tap. Reduce Motion: steps
crossfade. VoiceOver reads title, the big thing, then the action.

## Control plane and runners (Kaushik, Oct 22, 08:11: replaces "same skeleton for every routine")
The generic part is only the control plane. Each routine type runs in its own way.
- CONTROL PLANE (shared, engine + one host view, no look of its own): the step list and its
  order, the current step, step state (ahead, now, done, skipped), timers including several
  at once, pause and resume, Back without stopping, coming back to the same step, the Live
  Activity, one haptic per step done, Reduce Motion and VoiceOver hooks, and the log of what
  was done and when.
- RUNNERS (one per routine type, each its own UI on top of the control plane):
  - Default runner: the skeleton drawn in run-mode-126.png. Any routine with no runner of
    its own (morning, night, anything he makes) uses it.
  - Workout runner: the live set as built (weights, plates, set marks, rest), tuned for one
    hand and a glance.
  - Recipe runner: cook mode, tuned for messy hands: several timers side by side, scaled
    amounts, "at the same time" steps, screen kept on, hands-free next.
  - A new routine type starts on the default runner and gets its own runner only when its
    use shows what it needs; each runner gets its own sheet.
