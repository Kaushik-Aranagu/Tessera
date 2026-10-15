# Built-in exercise catalog: source, class tree, v1 seed

For: Core engine (catalog), iOS build, Product lead
Date: 2026-10-16

## 1. Sources and licenses

| Source | License (verified) | Private app | Future public app |
|---|---|---|---|
| yuhonas/free-exercise-db (800+ exercises, images) | Unlicense (public domain). Restructured from wrkout/exercises.json, also Unlicense. Where the text and images came from is not documented. | Yes | Risky for images and instruction text; fine as a taxonomy reference |
| wger | Code AGPL-3.0. Exercise data "Creative Commons (see individual entries)"; initial data CC-BY-SA 3.0. Each exercise carries license + author fields. | Yes | Yes, with per-entry attribution, and our derived catalog must stay CC-BY-SA. Using the data alone does not pull in the AGPL. |
| ExerciseDB (11,000+ via paid API; $300 Gumroad pack of 1,300 GIFs) | Code AGPL-3.0; data under separate Terms of Use (could not be read: JS-only page). The pack lists no license. | Only if paid | No, unless we get written terms |
| Liftosaur | Whole repo AGPL-3.0, no separate data license | Yes (read only) | No for a closed app; use as a reference only |
| Hevy (400+ exercises), ExRx | Proprietary | Link only | No |

wger's maintainer calls the open lists "problematic because their license are unclear" (issue 2196), mainly the images.

**Recommendation:** we write the v1 seed ourselves (about 70 exercises, listed below). Names and muscle mappings are common gym knowledge, and the cues and descriptions will be in our own words. Use free-exercise-db's vocabularies (force, mechanic, equipment, 17 muscles) as a cross-check. Ship no third-party images; exercise glyphs come from the design system. Every class package carries `source` and `license` fields, so an optional "wger import" package can be added later with attribution kept per object.

## 2. Taxonomies

- **Muscles (18):** chest, front delts, side delts, rear delts, triceps, biceps, forearms, lats, upper back (traps and rhomboids), lower back, abs, obliques, glutes, quads, hamstrings, adductors, abductors, calves. Muscle is a class with a `group` (Shoulders holds the 3 delts) so we can roll counts up. (free-exercise-db lumps delts into "shoulders"; volume needs them split.)
- **Fractional sets:** primary = 1.0, secondary = 0.5. Pelland, Schoenfeld et al. 2024 compared total, direct and fractional counting, and fractional fit hypertrophy and strength best. Store the role on the Exercise to Muscle link, with an optional `contribution` override (for example 0.25 for lower back on rows).
- **Movement patterns:** squat (knee dominant), lunge (single leg), hinge, horizontal push, vertical push, horizontal pull, vertical pull, carry, plus core (anti-extension, anti-rotation, flexion). Isolation moves are grouped by joint action.
- **Equipment:** barbell, dumbbell, EZ bar, cable, machine, smith machine, kettlebell, bodyweight, band.

## 3. Class tree (pattern is the spine, equipment is a trait)

Bench taken? Kaushik wants a DB or machine press, not a barbell row. So **movement pattern is the inheritance spine**, and **equipment is a trait**. The trait brings plate math, the load increment, bar weight and e1RM rules.

```
Exercise
  StrengthExercise
    HorizontalPush > BenchPress (family), Fly
    VerticalPush > OverheadPress (family), LateralRaise
    HorizontalPull > Row (family), RearDeltFly
    VerticalPull > PullUp (family), Pulldown (family)
    Squat, Lunge, Hinge > Deadlift (family), HipExtension
    Isolation > Curl, TricepsExtension, KneeExtension, KneeFlexion, HipAbAdduction, CalfRaise, Shrug
    Core > AntiExtension, AntiRotation, TrunkFlexion
    Carry
  CardioExercise, MobilityExercise (later)
Traits: Barbell, Dumbbell, EZBar, Cable, Machine, Smith, Kettlebell, Bodyweight, Assisted, Unilateral
```

**Exercise fields:** name, aliases, `muscles` (links with role and contribution), `equipment` (link to Equipment), `mechanic` (compound or isolation), `laterality`, `logType` (weight x reps, bodyweight + added, assisted, reps only, duration, distance + load), `loadIncrement` (defaults from the trait), `e1rmEligible`, `variantOf` (link), and the variant attributes `angle`, `grip` and `stance`, plus cues and `source`/`license`.
**Class-level defaults** are inherited: a progression rule (Barbell gives +2.5 kg, Dumbbell gives +2 kg per hand), a rest timer (compound 150 s, isolation 90 s) and a weekly target range per muscle (10 to 20 sets).

## 4. Variants: object plus link, not a subclass

- A **variant is its own Exercise object** when its load numbers are not comparable with the base exercise: different equipment, angle or grip (Incline DB Press, Close-Grip Bench). It gets its own history and PRs, and links `variantOf` to the base. Hevy and Strong do the same thing ("Bench Press (Dumbbell)").
- **Paused, tempo, belt and straps are set tags**, not new exercises, so the PR stays on Bench Press, with a filter for tags.
- **A subclass (family) only appears when 3 or more variants share a swap pool and a progression rule** (BenchPress, Row, Deadlift). That keeps the tree shallow and stops classes multiplying.
- **Swap order:** same family, then same pattern class, ranked by how much the primary muscles overlap and then by equipment the gym has. The slot, set scheme and rule carry over, and the load is converted where a mapping exists (for example DB ~ 0.8 x BB / 2 per hand, marked as an estimate).

## 5. v1 seed (69). Format: name (equipment): primary / secondary

**HorizontalPush > BenchPress:** Bench Press (BB): chest / triceps, front delts. Incline Bench Press (BB): chest, front delts / triceps. Close-Grip Bench (BB): triceps, chest / front delts. DB Bench Press: chest / triceps, front delts. Incline DB Press: chest, front delts / triceps. Machine Chest Press: chest / triceps, front delts.
**HorizontalPush:** Push-Up (BW): chest / triceps, front delts, abs. Dip (BW): chest, triceps / front delts.
**Fly:** Cable Fly: chest / front delts. Pec Deck (M): chest.
**VerticalPush > OverheadPress:** Overhead Press (BB): front delts / triceps, side delts. Seated DB Shoulder Press: front delts / triceps, side delts. Machine Shoulder Press: front delts / triceps.
**LateralRaise:** DB Lateral Raise: side delts. Cable Lateral Raise: side delts.
**HorizontalPull > Row:** Barbell Row: upper back, lats / biceps, rear delts, lower back. One-Arm DB Row: lats, upper back / biceps, rear delts. Seated Cable Row: upper back, lats / biceps, rear delts. Chest-Supported Row (M): upper back / lats, rear delts, biceps. T-Bar Row: upper back, lats / biceps, lower back.
**RearDeltFly:** Face Pull (C): rear delts / upper back. Reverse Pec Deck (M): rear delts / upper back.
**VerticalPull > PullUp:** Pull-Up (BW): lats / biceps, upper back. Chin-Up (BW): lats, biceps / upper back. Assisted Pull-Up (M): lats / biceps.
**Pulldown:** Lat Pulldown (C): lats / biceps, upper back. Close-Grip Pulldown (C): lats / biceps. Straight-Arm Pulldown (C): lats.
**Squat:** Back Squat (BB): quads, glutes / adductors, lower back. Front Squat (BB): quads / glutes, upper back. Goblet Squat (DB): quads / glutes. Hack Squat (M): quads / glutes. Leg Press (M): quads, glutes / adductors. Smith Squat: quads / glutes.
**Lunge:** Bulgarian Split Squat (DB): quads, glutes / adductors. Walking Lunge (DB): quads, glutes / adductors. Reverse Lunge (DB): glutes, quads. Step-Up (DB): quads, glutes.
**Hinge > Deadlift:** Deadlift (BB): glutes, hamstrings, lower back / quads, upper back, forearms. Sumo Deadlift (BB): glutes, quads, adductors / hamstrings, lower back. Romanian Deadlift (BB): hamstrings, glutes / lower back. DB Romanian Deadlift: hamstrings, glutes / lower back.
**Hinge:** Good Morning (BB): hamstrings, lower back / glutes. KB Swing: glutes, hamstrings / lower back.
**HipExtension:** Hip Thrust (BB): glutes / hamstrings. Back Extension (BW): lower back, glutes / hamstrings. Cable Pull-Through: glutes / hamstrings.
**KneeExtension / KneeFlexion:** Leg Extension (M): quads. Lying Leg Curl (M): hamstrings. Seated Leg Curl (M): hamstrings.
**HipAbAdduction:** Hip Adduction (M): adductors. Hip Abduction (M): abductors, glutes.
**CalfRaise:** Standing Calf Raise (M): calves. Seated Calf Raise (M): calves.
**Curl:** Barbell Curl: biceps / forearms. DB Curl: biceps / forearms. Hammer Curl (DB): biceps, forearms. Incline DB Curl: biceps. Preacher Curl (EZ): biceps. Cable Curl: biceps / forearms.
**TricepsExtension:** Rope Pushdown (C): triceps. Overhead Cable Extension: triceps. Skull Crusher (EZ): triceps. DB Overhead Extension: triceps.
**Shrug:** Barbell Shrug: upper back / forearms. DB Shrug: upper back / forearms.
**Core:** Plank (BW, duration): abs / obliques. Ab Wheel Rollout: abs / lats. Hanging Leg Raise: abs / forearms. Cable Crunch: abs. Pallof Press (C): obliques / abs.
**Carry:** Farmer's Carry (DB): forearms, upper back / abs, obliques.

## 6. Open items for engineering

- The demo tree's `BarbellLift` class becomes the `Barbell` trait, and `BenchPress` moves under `HorizontalPush`. Seeds use stable UUIDv7s, so this is cheap now and costly once sets exist.
- The DB to BB load conversion on swap is a heuristic. Show it as a suggestion, never as a logged value.

Sources: GitHub repos yuhonas/free-exercise-db, wrkout/exercises.json, wger-project/wger (README, issue 2196), exercisedb/exercisedb-api, astashov/liftosaur, exercemus/exercises; wger.readthedocs.io; exercisedb.gumroad.com; help.hevyapp.com; train.fitness on Pelland 2024; scienceforsport.com.
