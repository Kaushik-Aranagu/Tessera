# MET mapping draft: exercise seeds -> Compendium of Physical Activities (DRAFT)

Date: 2026-10-19. Status: DRAFT for Product and Core. Docs only; nothing was added to the repo.

## Read first: estimate input, never a measurement
This mapping feeds a calorie estimate: kcal = MET x body-mass-kg x hours. The app must show the result as
"about N kcal" and never as a measured value. A MET is a population average for an activity class; real
energy use varies with the person, load, tempo and rest. Rest time inside a lifting session is part of the
Compendium figure for resistance training, so use session time, not only set time.

## Terms (as relayed from Core; not read by this author)
Free commercial use if MET values are NOT changed; activities with different MET levels are NOT combined or
averaged; the Compendium is cited. So this file gives ONE code and ONE unchanged MET per exercise. No averages,
no scaling, no invented numbers. Suggested citation line (Core to confirm wording on pacompendium.com):
"Compendium of Physical Activities, 2024 Adult Compendium (pacompendium.com)".

## What was and was not possible
pacompendium.com is not reachable from this sandbox. The official table was therefore NOT seen. Every code and
value below comes from GitHub-hosted third-party copies, fetched read-only from raw.githubusercontent.com into a
scratch folder outside the repo. Rule applied: VERIFIED only if seen in a source quoting the official table
itself. None qualifies, so every row is VERIFY ON MAC. Confidence is still good: for all 9 codes used, the MET
agrees across the independent copies listed below (3 copies per code), and S1 tracks 1993/2000/2011/2024 side
by side so the 2024 column is identifiable (a few codes changed between editions, see "Edition warning").

Sources seen:
- S1: https://github.com/tonningp/met_calc , file data/adult_compendium_tracking_2024.csv (columns code_2024,
  met_2024, activity_description; also 1993, 2000, 2011 columns). Primary secondary source.
- S2: https://github.com/weathon/tnt_tracker , file data/met-compendium.json (header says "2024 Adult Compendium
  of Physical Activities", url pacompendium.com/adult-compendium/).
- S3: https://github.com/dmitkov28/notebooks , file notebooks/met/met.csv (undated copy; it contains 2024-era
  codes such as 02056 and 17018).
- Also read for cross-check (not used as a row source): https://github.com/Xsatc77/amide tools/compendium_data.json,
  https://github.com/stefan1condeescu/MacroSense database/seeds/seed_activities_compendium_official.sql,
  https://github.com/dpfens/PyExPhys pyexphys/mets.py (2011-style 02050 text).
Not usable: brazoramonk-arch/compendium-of-physical-activities (README only, links to a calculator site).

## Edition warning (important for Core)
Between 2011 and 2024 several MET values changed (examples seen in S1: 02020 8.0 -> 7.5, 02040 8.0 -> 7.5,
02070 6.0 -> 7.3, 02068 12.3 -> 11.0). The 9 codes used here are identical in the 2011 and 2024 columns of S1
(the six older codes: 02022, 02024, 02030, 02050, 02052, 02054); Core must confirm on the official 2024 table, and the in-app citation
must name the edition used. Codes 02056, 02058 and 17018 do not exist in 2011 (new in 2024).

## Mapping rules (explained once)
Pick by the seed's own equipment, pattern, log type and rep range. Each exercise gets exactly one rule.
- R1 (default, 02054, 3.5): any machine, cable, dumbbell, ez-bar or light-barbell resistance
  exercise, compound or isolation, with rep range inside about 8-15+ (the description's "8-15 reps"). This
  covers 52 of 72 seeds.
- R2 (02050, 6.0): barbell COMPOUND press or row whose rep range starts at 6 or lower (heavy, low-rep work;
  description: power lifting or body building, vigorous effort). Bench, incline bench, close-grip bench,
  overhead press, barbell row.
- R3 (02052, 5.0): barbell squat or hinge (squat, deadlift family) whose rep range starts at 6 or lower
  (description: squats, deadlift, slow or explosive effort). Back/front squat, deadlift, sumo, Romanian.
  Squats and deadlifts with an 8-12 range (hack, smith, goblet, dumbbell RDL, good morning) stay on R1.
- R4 (02022, 3.8): bodyweight pull/push seeds that the description names (push-ups, pull-ups): push-up,
  pull-up, chin-up; dip is not named but is the same effort class, so it uses the same code (judgement call,
  flagged below).
- R5 (own code): plank -> 02024 (plank is named, light effort); back extension -> 02030 (back exercises are
  named); ab wheel rollout and hanging leg raise -> 02056 (bodyweight resistance, general; crunch-type work).
- R6: kettlebell swing -> 02058 (code exists for exactly this).
- R7: farmer's carry -> 17018 (carrying a load, 15-155 lb, level ground, slow pace). Closest code found; it
  is a walking-with-load code, so Core should confirm there is nothing better (see questions below).
- Assisted pull-up uses R1: the machine assists the lifter, so it is not a bodyweight calisthenics set.
- Not applied: no seed is a cardio, rowing-machine, running, cycling, jump-rope or stretching exercise (all 72
  seeds are strength, core and carry). Codes for those are listed in the appendix for later seeds.

## Mapping table (72 rows)
Columns: exercise | equipment | pattern | code | code description (quoted from S1 unless noted) | MET | rule |
source | status.

| Exercise | Equipment | Pattern | Code | Code description | MET | Rule | Source | Status |
|---|---|---|---|---|---|---|---|---|
| Bench Press | barbell | horizontalPush | 02050 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | 6.0 | R2 | S1, S2, S3(2011) | VERIFY ON MAC |
| Incline Bench Press | barbell | horizontalPush | 02050 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | 6.0 | R2 | S1, S2, S3(2011) | VERIFY ON MAC |
| Close-Grip Bench Press | barbell | horizontalPush | 02050 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | 6.0 | R2 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Bench Press | dumbbell | horizontalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Incline Dumbbell Press | dumbbell | horizontalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Machine Chest Press | machine | horizontalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Push-Up | bodyweight | horizontalPush | 02022 | "Calisthenics (e.g., pushups, sit ups, pull-ups, lunges), moderate effort" | 3.8 | R4 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dip | bodyweight | horizontalPush | 02022 | "Calisthenics (e.g., pushups, sit ups, pull-ups, lunges), moderate effort" | 3.8 | R4 | S1, S2, S3(2011) | VERIFY ON MAC |
| Cable Fly | cable | horizontalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Pec Deck | machine | horizontalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Overhead Press | barbell | verticalPush | 02050 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | 6.0 | R2 | S1, S2, S3(2011) | VERIFY ON MAC |
| Seated Dumbbell Shoulder Press | dumbbell | verticalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Machine Shoulder Press | machine | verticalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Lateral Raise | dumbbell | verticalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Cable Lateral Raise | cable | verticalPush | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Barbell Row | barbell | horizontalPull | 02050 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | 6.0 | R2 | S1, S2, S3(2011) | VERIFY ON MAC |
| One-Arm Dumbbell Row | dumbbell | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Seated Cable Row | cable | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Chest-Supported Row | machine | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| T-Bar Row | barbell | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Face Pull | cable | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Reverse Pec Deck | machine | horizontalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Pull-Up | bodyweight | verticalPull | 02022 | "Calisthenics (e.g., pushups, sit ups, pull-ups, lunges), moderate effort" | 3.8 | R4 | S1, S2, S3(2011) | VERIFY ON MAC |
| Chin-Up | bodyweight | verticalPull | 02022 | "Calisthenics (e.g., pushups, sit ups, pull-ups, lunges), moderate effort" | 3.8 | R4 | S1, S2, S3(2011) | VERIFY ON MAC |
| Assisted Pull-Up | machine | verticalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Lat Pulldown | cable | verticalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Close-Grip Pulldown | cable | verticalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Straight-Arm Pulldown | cable | verticalPull | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Back Squat | barbell | squat | 02052 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | 5.0 | R3 | S1, S2, S3(2011) | VERIFY ON MAC |
| Front Squat | barbell | squat | 02052 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | 5.0 | R3 | S1, S2, S3(2011) | VERIFY ON MAC |
| Goblet Squat | dumbbell | squat | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hack Squat | machine | squat | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Leg Press | machine | squat | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Smith Machine Squat | smith | squat | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Bulgarian Split Squat | dumbbell | lunge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Walking Lunge | dumbbell | lunge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Reverse Lunge | dumbbell | lunge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Step-Up | dumbbell | lunge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Deadlift | barbell | hinge | 02052 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | 5.0 | R3 | S1, S2, S3(2011) | VERIFY ON MAC |
| Sumo Deadlift | barbell | hinge | 02052 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | 5.0 | R3 | S1, S2, S3(2011) | VERIFY ON MAC |
| Romanian Deadlift | barbell | hinge | 02052 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | 5.0 | R3 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Romanian Deadlift | dumbbell | hinge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Good Morning | barbell | hinge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Kettlebell Swing | kettlebell | hinge | 02058 | "Kettle bell swings" | 9.8 | R6 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hip Thrust | barbell | hinge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Back Extension | bodyweight | hinge | 02030 | "Calisthenics, light or moderate effort, general (e.g., back exercises), going up & down from floor (Taylor Code 150)" | 3.5 | R5 | S1, S2, S3(2011) | VERIFY ON MAC |
| Cable Pull-Through | cable | hinge | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Leg Extension | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Lying Leg Curl | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Seated Leg Curl | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hip Adduction | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hip Abduction | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Standing Calf Raise | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Seated Calf Raise | machine | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Barbell Curl | barbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Curl | dumbbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hammer Curl | dumbbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Incline Dumbbell Curl | dumbbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Preacher Curl | ezBar | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Cable Curl | cable | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Rope Pushdown | cable | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Overhead Cable Extension | cable | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Skull Crusher | ezBar | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Overhead Extension | dumbbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Barbell Shrug | barbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Dumbbell Shrug | dumbbell | isolation | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Plank | bodyweight | core | 02024 | "Calisthenics (e.g., curl ups, abdominal crunches, plank), light effort" | 2.8 | R5 | S1, S2, S3(2011) | VERIFY ON MAC |
| Ab Wheel Rollout | bodyweight | core | 02056 | "Body weight resistance exercises (e.g., squat, lunge, push-up, crunch), general" | 3.0 | R5 | S1, S2, S3(2011) | VERIFY ON MAC |
| Hanging Leg Raise | bodyweight | core | 02056 | "Body weight resistance exercises (e.g., squat, lunge, push-up, crunch), general" | 3.0 | R5 | S1, S2, S3(2011) | VERIFY ON MAC |
| Cable Crunch | cable | core | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Pallof Press | cable | core | 02054 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | 3.5 | R1 | S1, S2, S3(2011) | VERIFY ON MAC |
| Farmer's Carry | dumbbell | carry | 17018 | "Carrying 15 - 155 lb (6.8 - 70.4 kg) load (e.g. suitcase, boxes, furniture), level ground or downstairs, slow pace" | 4.5 | R7 | S1, S2, S3(2011) | VERIFY ON MAC |

## Codes used (9 distinct)

| Code | MET | Description | Seen in | Rows |
|---|---|---|---|---|
| 02022 | 3.8 | "Calisthenics (e.g., pushups, sit ups, pull-ups, lunges), moderate effort" | S1, S2, S3(2011) | 4 |
| 02024 | 2.8 | "Calisthenics (e.g., curl ups, abdominal crunches, plank), light effort" | S1, S2, S3(2011) | 1 |
| 02030 | 3.5 | "Calisthenics, light or moderate effort, general (e.g., back exercises), going up & down from floor (Taylor Code 150)" | S1, S2, S3(2011) | 1 |
| 02050 | 6.0 | "Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous effort (Taylor Code 210) [text from S3; S1 row is run together with 02049]" | S1, S2, S3(2011) | 5 |
| 02052 | 5.0 | "Resistance (weight) training, squats, deadlift, slow or explosive effort" | S1, S2, S3(2011) | 5 |
| 02054 | 3.5 | "Resistance (weight) training, multiple exercises, 8-15 reps at varied resistance" | S1, S2, S3(2011) | 52 |
| 02056 | 3.0 | "Body weight resistance exercises (e.g., squat, lunge, push-up, crunch), general" | S1, S2, S3(2011) | 2 |
| 02058 | 9.8 | "Kettle bell swings" | S1, S2, S3(2011) | 1 |
| 17018 | 4.5 | "Carrying 15 - 155 lb (6.8 - 70.4 kg) load (e.g. suitcase, boxes, furniture), level ground or downstairs, slow pace" | S1, S2, S3(2011) | 1 |

Note on 02050: in S1 the description cell is run together with 02049 ("Elliptical trainer, vigorous effort
Resistance (weight lifting - free weight, nautilus or universal-type), power lifting or body building, vigorous
effort") and shows only "(Taylor Code 210)" for 02050; S2 stores just " 210)". The text quoted above is from S3.
The MET 6.0 agrees in S1, S2, S3, PyExPhys and the Xsatc77 copy. Core: read the exact current wording.

## Judgement calls to confirm (Product / Core)
1. Dip -> 02022 (not named in the description). Alternative 02056 (3.0). Pick one; do not average.
2. Hanging leg raise and ab wheel rollout -> 02056 (3.0) rather than 02024 (2.8, light effort); both are
   harder than plank-level work. Alternative 02022 (3.8).
3. Farmer's carry -> 17018 (4.5). Other loaded-carry codes seen: 17016 (4.0, 5-14 lb, moderate pace) and 17019
   (6.5, 50-150 lb, moderate pace); loads in the app are heavier than 17016 but pace is slow, so 17018 fits best.
4. Barbell compounds that start at 6 reps (bench, row, OHP, squat, deadlift) are labelled vigorous/heavy by
   the rep-range rule. A user doing 6-10 reps at moderate load may argue for 02054 (3.5). The rule uses the
   seed's range, not what the user actually logs. A later option is to choose the code from the logged reps
   (still one unchanged code per set type, never an average).
5. 02054 says "multiple exercises". A session of many sets across several exercises matches it best; a single
   exercise alone is an approximation. Show "about", always.

## Counts
- Rows: 72. VERIFIED from official table: 0. VERIFY ON MAC: 72. NOT FOUND: 0.
- Distinct codes used: 9 (02022, 02024, 02030, 02050, 02052, 02054, 02056, 02058, 17018).

## What Core must read from pacompendium.com
1. The official 2024 Adult Compendium entries for the 9 codes above: confirm code, exact description text, and
   MET (S1/S2/S3 agree on the values listed; the official page was not seen). Priority: 02054, 02050, 02052.
2. The exact 02050 description (see note above) and whether "Taylor Code 210" is part of the official text.
3. The edition and publication date to cite, and the required citation wording and any link/attribution rule.
4. Whether a better code than 17018 exists for a heavy loaded carry (farmer's carry); and whether the table has
   a dip-specific or hanging-leg-raise-specific entry (none seen in S1).
5. The licence/terms text itself (relayed only second-hand so far): no-change rule, no-averaging rule.

## Appendix: other codes seen (not used; for future cardio/stretch seeds), S1 2024 column, VERIFY ON MAC
| Code | MET | Description |
|---|---|---|
| 02070 | 7.3 | Rowing, stationary ergometer, general, vigorous effort |
| 02071 | 5.0 | Rowing, stationary ergometer, general, <100 watts, moderate effort |
| 02068 | 11.0 | Rope skipping exercise, general |
| 02101 | 2.3 | Stretching, mild |
| 02020 | 7.5 | Calisthenics (e.g., pushups, sit ups, pull-ups, jumping jacks, burpees, battling ropes), vigorous effort |
| 02060 | 5.5 | Health club exercise, general (Taylor Code 160) |
Running (12xxx) and cycling (01xxx) codes exist in S1; read them from the official table when such seeds are added.
