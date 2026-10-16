# Fitness and workouts: what to steal, what to avoid

For: iOS build and Product lead
Date: 2026-10-15

Ranked by (how much it makes Kaushik log every session) x (low effort).

## Ideas

1. **One hold logs "same as planned".** Each set opens already filled with the target (progression suggestion, else last time). If he did it, one hold logs it; the dial and drum are only touched when reality differed. Why: "too many taps to log a set" is the top tracker complaint; lifters want 2 to 3 seconds per set. Fits: ghost target on the rep drum becomes the real default; Stamp moment unchanged. Effort S. [corahealth.app](https://www.corahealth.app/blog/best-workout-tracker-reddit)

2. **Log the set from the lock screen.** The rest Live Activity shows next set (exercise, weight x reps) with a "Done" button and rest +15s / skip, via App Intents. Phone face up on a bench stays locked. Why: Hevy ships exactly this and it is its most-cited convenience. Fits: same typed action ("syscall") as hold to log; the Activity is the seam, not a pill. Effort M (move rest Live Activity to P0 with it). [Hevy Live Activity](https://www.hevyapp.com/features/live-activity/)

3. **Progression rules as formulas on the routine slot.** A rule is a computed field like `dp(2.5kg, 8, 12)`: hit 12 on all sets, add 2.5 kg and drop to 8. Next session's dial opens on the result, with "why" one tap deep. Why: Liftosaur's scriptable progressions are the power-user favourite; built-in double progression covers most needs. Fits: reuses the e1RM expression language; rule is an object, linkable, inherited down the class tree (all BarbellLifts default to +2.5 kg). Effort S/M. [Liftoscript docs](https://www.liftosaur.com/doc/liftoscript)

4. **Plate-aware everything.** Gym and Equipment objects hold bar weight, smallest plate and dumbbell set; dial detents and suggestions land only on loadable values. Why: Fitbod users rage about being told to load 17.5 lb on a 45 lb bar. Fits: Equipment is already a class; plate math is already beside the dial. Effort S. [r/xxfitness on Fitbod](https://redlib.belloworld.it/r/xxfitness/comments/1fvy3gt/fitbod_app/lqalfse/?context=3)

5. **Never lose a session, and count sessions.** The live workout autosaves every set, survives a kill, and resumes with Ready-to-Resume. Today says "Session 6 of 14" (M1), never a streak; a half session still counts. Why: losing one workout is the fastest way to abandon a tracker; counts keep accountability without guilt. Fits: Workout is a process object; counts principle. Effort S. [corahealth.app](https://www.corahealth.app/blog/best-workout-tracker-reddit)

6. **Tess between sets, by voice.** Hold the Bar: "same", "80 for 7 at 8", "swap to dumbbell press", "how did I do last week". Tess confirms in one line with Undo. Why: a crop of voice-first gym loggers (RepTalk, EchoLift) exists because typing with chalky hands is miserable. Fits: Quick Capture plus Commands, on-device. Effort M. [tuffwraps on voice logging](https://www.tuffwraps.com/blogs/news/stop-typing-between-sets-how-voice-logging-changed-my-workouts)

7. **Swap within the class.** Bench taken? Pull down on the exercise to see siblings in its class (Incline, Dumbbell Press), pick one; the slot, set scheme and rule carry over. Why: busy gyms and bad substitutions are a common Fitbod/Hevy gripe. Fits: the class tree does the work; no search screen needed. Effort S/M. [r/xxfitness on Fitbod](https://redlib.belloworld.it/r/xxfitness/comments/1fvy3gt/fitbod_app/lqalfse/?context=3)

8. **Honest e1RM.** Use Epley only for 1 to 10 reps; when RPE is logged, adjust for reps in reserve (5 @ RPE 8 is really a 7RM effort). Flag 12+ rep sets as "not used for e1RM". Why: formulas assume failure and get noisy past 10 reps. Fits: one computed field change; PR hints get more trustworthy. Effort S. [fitnessvolt e1RM](https://fitnessvolt.com/rpe-training/compare/e1rm-formulas/)

9. **Weekly sets per muscle, fractional.** Count direct sets as 1 and indirect (triceps on bench) as 0.5, against a target range. Why: the largest volume meta-analysis (Pelland 2024, 67 studies) uses this method and finds diminishing but real returns. Fits: Exercise to Muscle links with a role; Week plan view. Effort M. [Pelland summary](https://biolayne.com/reps/issue-31/the-king-of-volume-metas/)

10. **Top-set check instead of questionnaires.** If the first working set's RPE is 2+ above plan, Tess offers one quiet option: "Drop to 77.5 for the rest?" No pump or soreness surveys. Why: RP Hypertrophy's feedback prompts are hard to judge and add friction. Fits: one next thing; calm by default. Effort M. [Dr. Muscle on RP](https://dr-muscle.com/rp-hypertrophy-app-beginners/)

## Pain points to avoid

- Popups between sets (rate us, feedback surveys, upsells).
- Suggesting weights the gym cannot load.
- Social feeds and streak badges; counts only.
- Requiring network (RP is web-only; gyms have bad signal). Everything offline first.
- Watch auto rep detection as a v1 crutch: Whoop's passive version "has not been publicly validated". Keep it P2. [the5krunner](https://the5krunner.com/2026/02/28/new-whoop-strength-trainer-update/)
- Programs you can only edit as long text on a phone (Liftosaur's own admission).

## Top 3 to act on now

1. Prefilled sets so one hold logs a planned set (idea 1).
2. Lock-screen "Done" and rest controls in the Live Activity (idea 2, promote to P0).
3. Double progression as a formula on the routine slot, feeding the dial (idea 3).
