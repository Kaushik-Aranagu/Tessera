# Workout Guide asset plan: moving exercise pictures for our 72 seeds

Date: 2026-10-20. Status: PLAN for Product, Core and Builder A. Docs only; no files were added to the repo.
Decision: Kaushik chose Workout Guide (option B) on 2026-10-20 and said color depth and size may be adjusted.
His words also lift the share-alike skip for these exercise pictures. This file records that scope, so the old
"skip share-alike" rule in the library notes still holds for everything else.

## What it is
Workout Guide (github.com/bryllim/workout-guide, package packages/workout-guide) ships 302 exercises,
each as three 512x512 SVG frames (assets/<slug>/frame-1.svg to frame-3.svg) plus a manifest with name,
equipment, primary and secondary muscles and per-frame credit. Played in order the frames give a rough motion
cycle. Frames are white lines on a transparent ground (monochrome already), so they sit on any dark or ink
backing without the pale-blue ground problem of the other candidate.

## Mapping: all 72 seeds covered
57 seeds match a Workout Guide exercise of the same name; 15 use a sibling with the same motion
(Kaushik: the motion and the muscles are what matter). By name alone, 60 are identical and 12 differ in spelling
or wording only; three sibling rows carry the identical name. An earlier count of 62 exact came from a looser name match;
the table below is the strict one. Every slug was checked against the manifest. Sibling rows are marked so Builder A
can label them correctly; none needs new art.

| Our exercise | Workout Guide slug | Match | Their name | Primary muscle (their label) |
|---|---|---|---|---|
| Bench Press | bench-press | exact | Bench Press | Chest |
| Incline Bench Press | incline-bench-press | exact | Incline Bench Press | Chest |
| Close-Grip Bench Press | close-grip-bench-press | exact | Close-Grip Bench Press | Triceps |
| Dumbbell Bench Press | dumbbell-bench-press | exact | Dumbbell Bench Press | Chest |
| Incline Dumbbell Press | incline-dumbbell-press | exact | Incline Dumbbell Press | Chest |
| Machine Chest Press | machine-chest-press | exact | Machine Chest Press | Chest |
| Push-Up | push-up | exact | Push-up | Chest |
| Dip | dip | exact | Dip | Triceps |
| Cable Fly | cable-fly | exact | Cable Fly | Chest |
| Pec Deck | pec-deck | exact | Pec Deck | Chest |
| Overhead Press | overhead-press | exact | Overhead Press | Shoulders |
| Seated Dumbbell Shoulder Press | seated-dumbbell-press | sibling | Dumbbell Seated Shoulder Press | Shoulders |
| Machine Shoulder Press | machine-shoulder-press | exact | Machine Shoulder Press | Shoulders |
| Dumbbell Lateral Raise | lateral-raise | sibling | Lateral Raise | Shoulders |
| Cable Lateral Raise | cable-lateral-raise | exact | Cable Lateral Raise | Shoulders |
| Barbell Row | barbell-row | exact | Barbell Row | Back |
| One-Arm Dumbbell Row | one-arm-dumbbell-row | exact | One-Arm Dumbbell Row | Back |
| Seated Cable Row | seated-row | sibling | Seated Cable Row | Back |
| Chest-Supported Row | chest-supported-row | exact | Chest Supported Row | Back |
| T-Bar Row | t-bar-row | exact | T-Bar Row | Back |
| Face Pull | face-pull | exact | Face Pull | Upper Back |
| Reverse Pec Deck | reverse-pec-deck | exact | Reverse Pec Deck | Rear Delts |
| Pull-Up | pull-up | exact | Pull-up | Lats |
| Chin-Up | chin-up | exact | Chin-up | Biceps |
| Assisted Pull-Up | assisted-pull-up | exact | Assisted Pull-up | Lats |
| Lat Pulldown | lat-pulldown | exact | Lat Pulldown | Lats |
| Close-Grip Pulldown | close-grip-lat-pulldown | sibling | Close-Grip Lat Pulldown | Lats |
| Straight-Arm Pulldown | straight-arm-pulldown | exact | Straight-Arm Pulldown | Lats |
| Back Squat | squat | sibling | Squat | Quads |
| Front Squat | front-squat | exact | Front Squat | Quads |
| Goblet Squat | goblet-squat | exact | Goblet Squat | Quads |
| Hack Squat | hack-squat | exact | Hack Squat | Quads |
| Leg Press | leg-press | exact | Leg Press | Quads |
| Smith Machine Squat | smith-machine-squat | exact | Smith Machine Squat | Quads |
| Bulgarian Split Squat | bulgarian-split-squat | exact | Bulgarian Split Squat | Quads |
| Walking Lunge | walking-lunge | exact | Walking Lunge | Quads |
| Reverse Lunge | reverse-lunge | exact | Reverse Lunge | Quads |
| Step-Up | step-up | exact | Step-Up | Quads |
| Deadlift | deadlift | exact | Deadlift | Posterior Chain |
| Sumo Deadlift | sumo-deadlift | exact | Sumo Deadlift | Posterior Chain |
| Romanian Deadlift | romanian-deadlift | exact | Romanian Deadlift | Hamstrings |
| Dumbbell Romanian Deadlift | dumbbell-romanian-deadlift | exact | Dumbbell Romanian Deadlift | Hamstrings |
| Good Morning | good-morning | exact | Good Morning | Hamstrings |
| Kettlebell Swing | kettlebell-swing | exact | Kettlebell Swing | Glutes |
| Hip Thrust | hip-thrust | exact | Hip Thrust | Glutes |
| Back Extension | back-extension | exact | Back Extension | Lower Back |
| Cable Pull-Through | cable-pull-through | exact | Cable Pull-Through | Glutes |
| Leg Extension | leg-extension | exact | Leg Extension | Quads |
| Lying Leg Curl | lying-leg-curl | exact | Lying Leg Curl | Hamstrings |
| Seated Leg Curl | seated-leg-curl | exact | Seated Leg Curl | Hamstrings |
| Hip Adduction | hip-adduction-machine | sibling | Hip Adduction Machine | Adductors |
| Hip Abduction | hip-abduction-machine | sibling | Hip Abduction Machine | Glutes |
| Standing Calf Raise | standing-calf-raise | exact | Standing Calf Raise | Calves |
| Seated Calf Raise | seated-calf-raise | exact | Seated Calf Raise | Calves |
| Barbell Curl | bicep-curl | sibling | Bicep Curl | Biceps |
| Dumbbell Curl | bicep-curl | sibling | Bicep Curl | Biceps |
| Hammer Curl | hammer-curl | exact | Hammer Curl | Biceps |
| Incline Dumbbell Curl | incline-dumbbell-curl | exact | Incline Dumbbell Curl | Biceps |
| Preacher Curl | preacher-curl | exact | Preacher Curl | Biceps |
| Cable Curl | cable-curl | exact | Cable Curl | Biceps |
| Rope Pushdown | rope-tricep-pushdown | sibling | Rope Tricep Pushdown | Triceps |
| Overhead Cable Extension | overhead-tricep-extension | sibling | Overhead Tricep Extension | Triceps |
| Skull Crusher | skull-crusher | exact | Skull Crusher | Triceps |
| Dumbbell Overhead Extension | dumbbell-overhead-tricep-extension | sibling | Dumbbell Overhead Tricep Extension | Triceps |
| Barbell Shrug | shrug | sibling | Barbell Shrug | Upper Back |
| Dumbbell Shrug | dumbbell-shrug | exact | Dumbbell Shrug | Upper Back |
| Plank | plank | exact | Plank | Core |
| Ab Wheel Rollout | ab-wheel | sibling | Ab Wheel Rollout | Core |
| Hanging Leg Raise | hanging-leg-raise | exact | Hanging Leg Raise | Core |
| Cable Crunch | cable-crunch | exact | Cable Crunch | Core |
| Pallof Press | pallof-press | exact | Pallof Press | Core |
| Farmer's Carry | farmer-carry | sibling | Farmer Carry | Forearms |

Notes on siblings: Barbell Curl and Dumbbell Curl both use bicep-curl (same elbow-flexion motion); Back Squat uses
squat; Barbell Shrug uses shrug; the pulldown, row, press and extension siblings differ only in grip or handle.
Two of our seeds share one slug (bicep-curl); files are stored once per slug, keyed by slug, so the bundle holds
71 distinct exercises (213 files, 71 x 3).

## Credit and license notice (for the credits screen)
Product ruling (decisions.md, 2026-10-19 5:30 PM): one plain About page at the foot of Settings, one line per
source (Compendium, Everkinetic art with both names and CC BY-SA 4.0, reference library). No credits on exercise
pages. The Exercise pictures line reads:

- "Exercise pictures: Workout Guide by Bryl Lim (bryllim.com), CC BY-SA 4.0. Artwork by Everkinetic / Greg Priday,
  CC BY-SA 4.0. Changes: recolored and resized."
- Links: https://github.com/bryllim/workout-guide ; https://github.com/everkinetic/data ;
  https://creativecommons.org/licenses/by-sa/4.0/
- The manifest's own change note reads: "Rasterized on a transparent 512 x 512 canvas, recolored for monochrome
  display, and vector-traced." Our change line must add whatever Design and Builder A do on top (see next section).
- Core must read the repo's LICENSE and README on the Mac and paste the exact wording used; this author saw the
  manifest's per-frame attribution, not the repo license file text.

Note: only some Workout Guide frames come from Everkinetic art (QA counted 76 of 302 exercises with an Everkinetic
sourced frame 1; frames 2 and 3 are Bryl Lim's). The About line credits both because the manifest names both; do
not describe every picture as Everkinetic art.

## Adaptations Kaushik allowed
- Color depth toward our ink look: swap the white fill for the theme ink color at render time (one SVG fill token)
  rather than editing files. Rendering as a template image with a tint keeps the files untouched.
- Size: 512x512 SVG scales without loss; no resize needed for the long-press sheet. If the bundle must shrink,
  minify the SVG paths (svgo-style, lossless) before bundling.
- Smoothing: the cycle is three hard frames. Options in order of cost: (1) ease between frames with a short
  cross-fade at about 150 ms (free, runs in SwiftUI, respects Reduce Motion by showing frame 2 still); (2) path
  morphing needs matching point counts and is not safe on these traced files; (3) in-betweens drawn by hand are a
  separate art job. Recommend (1).
- Every adapted file stays under CC BY-SA 4.0 with the credit above. Do not relicense or strip the credit.

## Scope and limits
- GATE: no second-person build ships without the CC BY-SA 4.0 license kept on the pictures and both credits in
  place on the About page (Product ruling).
- Art is stored on the phone as bundled files; no runtime fetch, and the pictures never go to Claude.
- Share-alike applies when the app or its pictures are shared with someone. Kaushik's build is signed for his own
  phone only, so nothing is shared today. If a second person ever receives a build, the pictures (and any adapted
  versions) must stay CC BY-SA 4.0, the credit must show, and Product should re-check the app code question first.
- Bundle as a read-only resource folder next to the library; never in backups, export or the op log; no network.
- Size estimate for our 72 seeds: 5.3 MB of raw SVG for the 213 files (QA measured; my earlier 6.5 MB was an estimate).
- The 72 seeds are strength, core and carry only. Workout Guide also has stretches and cardio (isStretch flag,
  Cardio equipment) for later seeds.

## Other free sources like this (searched only through what was already seen)
Nothing new was searched in this pass. Known and ruled out: RepDB (still photos, pale blue ground), wger (all 383
images CC BY-SA, no motion), free-exercise-db (stills, provenance unclear). The hunt for more moving sets is the
next task, per Kaushik's 00:29 note, and will go into exercise-clips-hunt-draft.md.

## Handoff
Builder A owns the long-press sheet and the import PR. Core measures bundle size and confirms the license text.
Design sets the ink treatment. Research (this thread) can turn slug mapping into a JSON file if Builder A wants it.
