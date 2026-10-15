# Speak mode: first phone test

For: Builder B, Kaushik. Date: 2026-10-15. Takes about five minutes.

**Status on origin/master (`0950ba7`).** Speak is a word only: tapping it says "Speak comes next." There is no `SpeechAnalyzer`, `SpeechTranscriber`, spoken normaliser or mic usage key yet. Run this once slices V1 (normaliser) and V2 (hold to talk) from `speech-capture.md` are on the build. Expected lines are the Tess lines master's capture engine writes today.

## Setup

1. Once on Wi-Fi, open Speak so the speech model downloads. Then turn on airplane mode and run with `-demoTime 18:10`.
2. Speak lives on Tess's soul (bottom right): tap it, then Speak, or hold the soul in a workout. Hold, talk, let go. Let each ghost dry (2 s) before the next row.

## Part 1: mid-workout (quiet room)

Start a throwaway workout, add Bench Press and log one set of 80 x 8 with the dial. N is the next set number.

| # | Say | Tess shows | Pass if |
|---|---|---|---|
| 1 | eighty for seven | Set N. 80 x 7. | 80 x 7 on Bench |
| 2 | same | Same again, logged. | Another 80 x 7 |
| 3 | eight | Set N. 80 x 8. | Reps only, weight stays 80 |
| 4 | eighty two and a half for six | Set N. 82.5 x 6. | 82.5, not 82 or 2.5 |
| 5 | eighty k for eight | Set N. 80 x 8. | "k" read as kg |
| 6 | drop to seventy for ten | Drop set. 70 x 10. | A drop set, not 70 x 2 |
| 7 | seventy two point five for ten | Set N. 72.5 x 10. | 72.5 x 10 |
| 8 | bench eighty for six | Set N. 80 x 6. | Lands in the Bench entry |
| 9 | note bar felt heavy | Noted. | A note, no set |
| 10 | squat a hundred for five | Back Squat 5 reps at 100. Added to today. | Back Squat, not Bench |

End the workout before Part 2.

## Part 2: tasks and kitchen (quiet room)

| # | Say | Tess shows | Pass if |
|---|---|---|---|
| 11 | remind me to call the plumber tomorrow | Call the plumber, tomorrow 9 am. | Title has no "two" or "to" |
| 12 | buy milk and bread | 2 things on the list. | Groceries, not "By milk" |
| 13 | buy a dozen eggs | 12 eggs, on the list. | 12, not "a dozen" |
| 14 | dentist saturday at three pm | Dentist, Saturday 3 pm. | 3 pm, not 3 am |
| 15 | call mum tomorrow at seven pm | Call mum, tomorrow 7 pm. | 7 pm, "PM" not in the title |
| 16 | set a timer for ten minutes | Timer, 10 min. | A timer, not a task |
| 17 | timer pasta ten | Pasta, 10 min. | A 10 min timer |
| 18 | new list camping | New list: Camping. | A list, not a task |
| 19 | cook lasagne tomorrow | Cook lasagne, tomorrow 9 am. | A dated cook task |
| 20 | move dentist to sunday | Dentist, Sunday 9 am. | Row 14's task moves (fails if he has another dentist task) |

## Part 3: noisy or mumbled (music on, loud)

Say the fillers and corrections as written. Row 26 lands as "tomorrow" if run on a Thursday.

| # | Say | Tess shows | Pass if |
|---|---|---|---|
| 21 | um squats um a hundred for five | Back Squat 5 reps at 100. Added to today. | Fillers gone |
| 22 | uh like bench eighty for eight | Bench 8 reps at 80. Added to today. | "like" gone |
| 23 | okay Tess, deadlift one twenty for five | Deadlift 5 reps at 120. Added to today. | 120, not 1:20 or 1 |
| 24 | squat a hundred for five, no wait, four | Back Squat 4 reps at 100. Added to today. | 4 reps, one set |
| 25 | bench eighty for eight, sorry, nine | Bench 9 reps at 80. Added to today. | 9 reps, one set |
| 26 | remind me friday, no, saturday to clean the car | Clean the car, Saturday 9 am. | Saturday, title clean |
| 27 | please remind me to call Ravi tomorrow, thanks | Call Ravi, tomorrow 9 am. | No "please" or "thanks" |
| 28 | um buy, uh, oat milk | Oat milk, on the list. | One item, no "um" |
| 29 | ab wheel rollout three sets of ten (model route) | Ab Wheel Rollout 3 x 10, or "Didn't catch that" | No wrong set saved |
| 30 | um, uh (nothing else) | Didn't hear anything. | Nothing saved |

## Scoring

Pass at 26 of 30, with no wrong write committed. A wrong ghost you swiped away fails its row but is not a wrong write.

## Report back

One line per row that failed or looked odd. Rows not listed count as passes.

```
Row #:
Heard line:
Tess showed:
Saved? (yes, swiped, nothing):
```

Also send: phone locale, AirPods or speaker, and the slowest wait from release to ghost.
