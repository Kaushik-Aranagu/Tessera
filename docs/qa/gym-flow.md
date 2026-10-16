# v1 gym flow check

A written end-to-end check for a Mac lead to run on the simulator, and on Kaushik's phone when it matters, before a workout PR merges. It follows v1 slices 1 to 8 in the ship list. Write down anything that fails, with the step number. Rows marked with a bug number are known to fail on master today (see `tessera/qa/review-46-to-58.md` in the project folder).

## Setup

1. Run `scripts/test.sh`. Both the package and the app must be green.
2. Delete the app from the simulator so the next launch is a fresh install. Then launch a DEBUG build with no arguments.

## A. Seed (slice 1)

1. Expect six routines in the plan: Push A, Pull A, Legs A, Push B, Pull B, Legs B.
2. Open Push A. Expect Bench Press 4 × 5–8, Overhead Press 3 × 6–10, Incline DB Press 3 × 8–12, DB Lateral Raise 3 × 12–15, Rope Pushdown 3 × 10–15.
3. Check the kit: a 20 kg bar, plates 25 / 20 / 15 / 10 / 5 / 2.5 / 1.25, and dumbbells in 2 kg steps.

## B. First session and prefilled logging (slice 2)

1. Start today's routine from Home. Expect the live cover to open on the first exercise.
2. With no history, set 1 opens at the starting weight (the empty 20 kg bar for Bench), labelled "First time. Start light".
3. Close the live cover without logging. Expect Home not to say "Bench Press is ready for 20 today" (G1).
4. Reopen the workout and hold once to log set 1. Expect one hold, one logged set, and the rest timer starting.
5. Set 2 opens at set 1's weight with the target reps.
6. Plan targets with no history read "From the plan", not "First time" (K11).

## C. The dial and the drum (slice 3)

1. Turn the weight dial on Bench. Expect it to snap only to loadable values (20, 22.5, 25 … with 1.25 kg plates) and to show plates per side as text.
2. Move to a dumbbell exercise. Expect 2 kg steps.
3. Roll the rep drum. Expect whole numbers and a smooth roll.
4. Log a set at a dialled value and check the logged weight matches exactly.

## D. Kill mid-set and resume

1. Log 2 sets of the second exercise, then turn the dial to a new weight without logging.
2. Kill the app from the app switcher and relaunch.
3. Expect the workout still running on the same exercise, with 2 sets logged, the next set prefilled, and What's running showing the workout.
4. Expect the rest timer's end time preserved. If it ended while the app was dead, expect it shown as done, not restarted.

## E. Lock Screen (rest Live Activity)

1. Log a set and lock the phone. Expect the rest Live Activity with a draining countdown.
2. Tap +15s. Expect the end time to move by 15 seconds.
3. Tap Skip. Expect rest to end.
4. Tap Done (Log Planned Set). Expect the next set logged at its prefilled weight × reps without opening the app, and the activity to restart rest.
5. Unlock and open the app. Expect the set from step 4 in the session, and undo to remove it.

## F. Edit and undo (slice 8)

1. Tap a logged set, change its weight, and save. Expect the new value everywhere: the session, the exercise page and the summary.
2. Undo. Expect the old value back.
3. Undo again. Expect the last logged set removed.

## G. Finish and history (slices 4 to 7)

1. Hold to finish. Expect the session compressed into today on Home with Tess's one-line summary.
2. Expect Now's countdown, while a rest is running, to be a draining bar, not just a number.
3. Open Bench Press. Expect the best set, best e1RM and last 5 sessions, and the page to read well with this single session.
4. Start Push A again next time (or change the date). Expect set 1 to open at last time's set 1 (source "last time"). Expect a "beats 5RM" style hint when the prefill would set a record, and one celebration when it does.

## H. Wrap-up

1. Export JSON and check the workout, sets and exercises are present.
2. Repeat B4, E1 and G1 with Reduce Motion on. Expect no slides or sweeps, but the same results.
3. Launch with `-resetDemo`, then relaunch normally. Expect dumbbells in 2 kg steps and his plate list, not the defaults (K12).
