# Training library, phase 1: workouts and extra exercises

Date: 2026-10-22. Status: DRAFT for Product, Core and Builder A. Docs only. Research wrote this in our own words.
Scope: product/training-app-scope-oct22.md, phase 1 (Library). Kaushik said "Go phase 1" at 8:17 AM PT Oct 22.

## What is here
- 14 workouts: Push (3), Pull (3), Legs (3), Full body (3), Short (2). Nine are Gym and five are Home.
- 40 extra exercises beyond the 72 built-in ones (id E01 to E40), each with muscles, equipment and a one-line cue.
- Every workout line uses an exercise from the 72 or from the extras below, so nothing needs art, a new equipment kind or a new muscle.

## Rules this follows
- Muscles are the fixed 18 (Chest, Front Delts, Side Delts, Rear Delts, Triceps, Biceps, Forearms, Lats, Upper Back, Lower Back, Abs, Obliques, Glutes, Quads, Hamstrings, Adductors, Abductors, Calves). Primary counts 1, secondary 0.5, as the ledger does.
- Equipment is the fixed 9: Barbell, Dumbbell, EZ bar, Cable, Machine, Smith, Kettlebell, Body, Band.
- Sources: the 72 built-in rows are the fixture table (fixtures/exercise-muscles.md). The extras come from free-exercise-db (Unlicense) data only: the entry name, equipment, force and muscle fields. Names, cues and workout text here are our own words; nothing is copied from its instructions or photos, and no image is used.
- free-exercise-db lists "shoulders" as one muscle and calls the middle back "middle back" and "traps". The extras split shoulders into Front, Side and Rear Delts and fold middle back and traps into Upper Back, by the exercise. This split is Research's reading; Core confirms it before it seeds.
- The Home column is the gym-free picture: Body, Band, Dumbbell or Kettlebell only. Inverted Row needs a sturdy table or bar and Bench Dip needs a bench or chair.
- Minutes are our estimates for working sets plus rest, warm-up not included.
- Words: "best", never "record". Plain gym words, US English, no muscle figure by names.

## The 14 workouts

| id | Workout | Group | Place | Level | About | Equipment | Main muscles | Also works |
|---|---|---|---|---|---|---|---|---|
| W01 | Push Day | Push | Gym | Intermediate | about 55 min | Barbell, Dumbbell, Cable | Chest, Front Delts, Side Delts, Triceps | none |
| W02 | Machine Push | Push | Gym | Beginner | about 45 min | Machine, Cable, Body | Chest, Triceps, Front Delts, Side Delts | none |
| W03 | Push at Home | Push | Home | Beginner | about 35 min | Body, Dumbbell | Front Delts, Chest, Side Delts, Triceps | Abs |
| W04 | Pull Day | Pull | Gym | Intermediate | about 55 min | Barbell, Cable, Dumbbell | Lats, Upper Back, Biceps, Rear Delts, Forearms | Lower Back |
| W05 | Pull-Up Focus | Pull | Gym | Intermediate | about 40 min | Body, Machine, Cable, Dumbbell | Lats, Upper Back, Rear Delts, Biceps | none |
| W06 | Pull at Home | Pull | Home | Beginner | about 35 min | Dumbbell, Body, Band | Upper Back, Biceps, Lats, Rear Delts, Lower Back | Glutes, Hamstrings |
| W07 | Leg Day | Legs | Gym | Intermediate | about 60 min | Barbell, Machine | Glutes, Quads, Hamstrings, Calves, Abductors | Adductors, Lower Back |
| W08 | Machine Legs | Legs | Gym | Beginner | about 50 min | Machine, Dumbbell, Barbell | Quads, Glutes, Hamstrings, Calves | Adductors |
| W09 | Legs at Home | Legs | Home | Beginner | about 35 min | Dumbbell, Body | Glutes, Quads, Hamstrings, Calves | Lower Back |
| W10 | Full Body A | Full body | Gym | Intermediate | about 50 min | Barbell, Body | Quads, Glutes, Chest, Upper Back, Lats | Lower Back, Triceps, Adductors, Biceps |
| W11 | Full Body B | Full body | Gym | Intermediate | about 55 min | Barbell, Dumbbell, Cable | Glutes, Hamstrings, Lower Back, Chest, Front Delts | Upper Back, Forearms, Triceps, Biceps |
| W12 | Full Body at Home | Full body | Home | Beginner | about 40 min | Dumbbell, Body | Quads, Chest, Lats, Upper Back, Hamstrings | Triceps, Biceps, Rear Delts, Lower Back |
| W13 | Short Strength | Short | Gym | Beginner | about 25 min | Dumbbell, Cable, Body | Quads, Chest, Lats, Abs | Glutes, Triceps, Front Delts, Biceps |
| W14 | Short at Home | Short | Home | Beginner | about 20 min | Body | Quads, Abs, Chest, Lower Back, Glutes | Hamstrings, Triceps, Front Delts, Calves |

### Workout contents

**W01 Push Day** (Gym, intermediate, about 55 min): Chest first, then shoulders and triceps. A classic heavy push session.
- Bench Press: 4 x 6-8
- Overhead Press: 3 x 8
- Incline Dumbbell Press: 3 x 10
- Dumbbell Lateral Raise: 3 x 12-15
- Rope Pushdown: 3 x 12
- Cable Fly: 2 x 15

**W02 Machine Push** (Gym, beginner, about 45 min): All machines and cables, so you can train hard without a spotter.
- Machine Chest Press: 3 x 10
- Machine Shoulder Press: 3 x 10
- Pec Deck: 3 x 12
- Cable Lateral Raise: 3 x 15
- Overhead Cable Extension: 3 x 12
- Dip: 2 x 8-10

**W03 Push at Home** (Home, beginner, about 35 min): Push-ups and a pair of dumbbells. Chest, shoulders and triceps in about half an hour.
- Push-Up: 4 x 8-15
- One-Arm Dumbbell Shoulder Press: 3 x 10 (extra E39)
- Decline Push-Up: 3 x 8-12 (extra E04)
- Dumbbell Lateral Raise: 3 x 15
- Bench Dip: 3 x 12 (extra E10)
- Dumbbell Front Raise: 2 x 12 (extra E27)

**W04 Pull Day** (Gym, intermediate, about 55 min): Heavy rows and pulldowns, then rear shoulders and biceps.
- Barbell Row: 4 x 6-8
- Lat Pulldown: 3 x 10
- Seated Cable Row: 3 x 10-12
- Face Pull: 3 x 15
- Barbell Curl: 3 x 10
- Hammer Curl: 2 x 12

**W05 Pull-Up Focus** (Gym, intermediate, about 40 min): Starts with pull-ups while you are fresh, then back volume and curls.
- Pull-Up: 4 x 5-8
- Chest-Supported Row: 3 x 10
- Straight-Arm Pulldown: 3 x 12
- Reverse Pec Deck: 3 x 15
- Incline Dumbbell Curl: 3 x 12

**W06 Pull at Home** (Home, beginner, about 35 min): Dumbbells, a band and a sturdy table or bar for rows.
- One-Arm Dumbbell Row: 4 x 10
- Inverted Row: 3 x 8-12 (extra E05)
- Band Pull-Apart: 3 x 20 (extra E12)
- Dumbbell Curl: 3 x 12
- Superman: 3 x 12 (extra E06)
- Hammer Curl: 2 x 12

**W07 Leg Day** (Gym, intermediate, about 60 min): A heavy squat and hinge, then machines for the rest of the legs.
- Back Squat: 4 x 6
- Romanian Deadlift: 3 x 8
- Leg Press: 3 x 12
- Lying Leg Curl: 3 x 12
- Standing Calf Raise: 4 x 12
- Hip Abduction: 2 x 15

**W08 Machine Legs** (Gym, beginner, about 50 min): Machines and walking lunges with no heavy bar on your back.
- Hack Squat: 3 x 10
- Walking Lunge: 3 x 10
- Seated Leg Curl: 3 x 12
- Leg Extension: 3 x 12
- Hip Thrust: 3 x 10
- Seated Calf Raise: 3 x 15

**W09 Legs at Home** (Home, beginner, about 35 min): One dumbbell or two, plus floor work for glutes and calves.
- Goblet Squat: 4 x 12
- Dumbbell Romanian Deadlift: 3 x 10
- Reverse Lunge: 3 x 10
- Single-Leg Glute Bridge: 3 x 12 (extra E02)
- Dumbbell Calf Raise: 3 x 15 (extra E36)

**W10 Full Body A** (Gym, intermediate, about 50 min): Squat, press and row in one session. Pair it with B on alternate days.
- Back Squat: 3 x 8
- Bench Press: 3 x 8
- Barbell Row: 3 x 8
- Overhead Press: 2 x 10
- Plank: 3 x 45 s

**W11 Full Body B** (Gym, intermediate, about 55 min): Deadlift, incline press and pulldown, with lunges and core to finish.
- Deadlift: 3 x 5
- Incline Dumbbell Press: 3 x 10
- Lat Pulldown: 3 x 10
- Walking Lunge: 2 x 10
- Dumbbell Lateral Raise: 2 x 15
- Cable Crunch: 3 x 12

**W12 Full Body at Home** (Home, beginner, about 40 min): Dumbbells only. Legs, push, pull and core.
- Goblet Squat: 3 x 12
- Push-Up: 3 x 10
- One-Arm Dumbbell Row: 3 x 10
- Dumbbell Romanian Deadlift: 3 x 10
- One-Arm Dumbbell Shoulder Press: 2 x 10 (extra E39)
- Dead Bug: 3 x 10 (extra E07)

**W13 Short Strength** (Gym, beginner, about 25 min): Four big moves in about 25 minutes when the day is tight.
- Goblet Squat: 3 x 10
- Dumbbell Bench Press: 3 x 10
- Lat Pulldown: 3 x 10
- Plank: 2 x 45 s

**W14 Short at Home** (Home, beginner, about 20 min): No equipment and about 20 minutes. Good for a hotel room.
- Bodyweight Squat: 3 x 15 (extra E01)
- Push-Up: 3 x 10
- Superman: 3 x 12 (extra E06)
- Bodyweight Lunge: 2 x 10 (extra E11)
- Plank: 2 x 40 s
- Dead Bug: 2 x 10 (extra E07)

Sets are working sets. Warm-ups are not listed and count nothing. "45 s" is a hold, logged by time.

## 40 extra exercises

| id | Exercise | Equipment | Primary | Secondary | Type | Place | free-exercise-db entry |
|---|---|---|---|---|---|---|---|
| E01 | Bodyweight Squat | Body | Quads | Glutes, Hamstrings | compound | Home | Bodyweight Squat |
| E02 | Single-Leg Glute Bridge | Body | Glutes | Hamstrings | isolation | Home | Single Leg Glute Bridge |
| E03 | Incline Push-Up | Body | Chest | Triceps, Front Delts | compound | Home | Incline Push-Up |
| E04 | Decline Push-Up | Body | Chest, Front Delts | Triceps | compound | Home | Decline Push-Up |
| E05 | Inverted Row | Body | Upper Back | Lats | compound | Home | Inverted Row |
| E06 | Superman | Body | Lower Back | Glutes, Hamstrings | compound | Home | Superman |
| E07 | Dead Bug | Body | Abs | none | compound | Home | Dead Bug |
| E08 | Side Plank | Body | Obliques | Abs | isolation | Home | Side Bridge |
| E09 | Mountain Climber | Body | Quads, Abs | Front Delts, Hamstrings | compound | Home | Mountain Climbers |
| E10 | Bench Dip | Body | Triceps | Chest, Front Delts | compound | Home | Bench Dips |
| E11 | Bodyweight Lunge | Body | Quads, Glutes | Calves, Hamstrings | compound | Home | Bodyweight Walking Lunge |
| E12 | Band Pull-Apart | Band | Rear Delts | Upper Back | isolation | Home | Band Pull Apart |
| E13 | Crunch | Body | Abs | none | isolation | Home | Crunches |
| E14 | Reverse Crunch | Body | Abs | none | isolation | Home | Reverse Crunch |
| E15 | Bent-Knee Hip Raise | Body | Abs | none | compound | Home | Bent-Knee Hip Raise |
| E16 | Glute Kickback | Body | Glutes | Hamstrings | compound | Home | Glute Kickback |
| E17 | Band Good Morning | Band | Hamstrings | Glutes, Lower Back | compound | Home | Band Good Morning |
| E18 | Band Reverse Fly | Band | Rear Delts | Upper Back | isolation | Home | Back Flyes - With Bands |
| E19 | Floor Back Extension | Body | Lower Back | Glutes, Hamstrings | compound | Home | Hyperextensions With No Hyperextension Bench |
| E20 | Russian Twist | Body | Obliques | Abs, Lower Back | compound | Home | Russian Twist |
| E21 | Sit-Up | Body | Abs | none | isolation | Home | Sit-Up |
| E22 | Band Calf Raise | Band | Calves | none | isolation | Home | Calf Raises - With Bands |
| E23 | Dumbbell Fly | Dumbbell | Chest | none | isolation | Gym | Dumbbell Flyes |
| E24 | Incline Dumbbell Fly | Dumbbell | Chest | Front Delts | isolation | Gym | Incline Dumbbell Flyes |
| E25 | Cable Crossover | Cable | Chest | Front Delts | isolation | Gym | Cable Crossover |
| E26 | Arnold Press | Dumbbell | Front Delts, Side Delts | Triceps | compound | Gym | Arnold Dumbbell Press |
| E27 | Dumbbell Front Raise | Dumbbell | Front Delts | none | isolation | Home | Front Dumbbell Raise |
| E28 | Bent-Over Rear Delt Raise | Dumbbell | Rear Delts | Upper Back | isolation | Gym | Bent Over Dumbbell Rear Delt Raise With Head On Bench |
| E29 | Dumbbell Upright Row | Dumbbell | Side Delts, Upper Back | Biceps | compound | Gym | Standing Dumbbell Upright Row |
| E30 | Dumbbell Pullover | Dumbbell | Lats, Chest | Triceps | compound | Gym | Bent-Arm Dumbbell Pullover |
| E31 | Concentration Curl | Dumbbell | Biceps | Forearms | isolation | Gym | Concentration Curls |
| E32 | Reverse Curl | Barbell | Forearms, Biceps | none | isolation | Gym | Reverse Barbell Curl |
| E33 | Lying Dumbbell Triceps Extension | Dumbbell | Triceps | none | isolation | Gym | Lying Dumbbell Tricep Extension |
| E34 | Cable Wood Chop | Cable | Obliques | Abs, Front Delts | compound | Gym | Standing Cable Wood Chop |
| E35 | Dumbbell Wrist Curl | Dumbbell | Forearms | none | isolation | Gym | Palms-Up Dumbbell Wrist Curl Over A Bench |
| E36 | Dumbbell Calf Raise | Dumbbell | Calves | none | isolation | Home | Standing Dumbbell Calf Raise |
| E37 | Kettlebell Thruster | Kettlebell | Front Delts, Quads | Triceps, Glutes | compound | Gym | Kettlebell Thruster |
| E38 | Dumbbell Squat | Dumbbell | Quads | Glutes, Hamstrings, Calves, Lower Back | compound | Home | Dumbbell Squat |
| E39 | One-Arm Dumbbell Shoulder Press | Dumbbell | Front Delts | Triceps, Side Delts | compound | Home | Dumbbell One-Arm Shoulder Press |
| E40 | Leg Press Calf Raise | Machine | Calves | none | isolation | Gym | Calf Press On The Leg Press Machine |

### Cues (our words)
- E01 Bodyweight Squat: Feet shoulder width apart, sit back and down until your thighs are level, then stand tall.
- E02 Single-Leg Glute Bridge: Lie on your back, one foot planted and the other leg lifted, push through the heel until your hips are level with your knee.
- E03 Incline Push-Up: Hands on a bench or counter, body in one line, lower your chest to the edge and press away.
- E04 Decline Push-Up: Feet on a bench, hands on the floor, lower your chest between your hands and press back up.
- E05 Inverted Row: Hang under a bar or sturdy table, body straight, pull your chest to the edge and lower with control.
- E06 Superman: Face down, lift arms and legs together, pause for a breath, lower slowly.
- E07 Dead Bug: On your back with knees and arms up, lower the opposite arm and leg while your lower back stays on the floor.
- E08 Side Plank: On one forearm with your body in a line, hold your hips up for the whole set.
- E09 Mountain Climber: From a push-up position, drive one knee at a time toward your chest at a steady pace.
- E10 Bench Dip: Hands on a bench behind you, bend your elbows to lower your hips, then press up.
- E11 Bodyweight Lunge: Step forward, drop your back knee toward the floor, push through the front foot into the next step.
- E12 Band Pull-Apart: Hold a band at chest height with straight arms and pull it apart until it touches your chest.
- E13 Crunch: On your back with knees bent, curl your ribs toward your hips and lower slowly.
- E14 Reverse Crunch: On your back, curl your knees toward your chest and lift your hips a little off the floor.
- E15 Bent-Knee Hip Raise: Lying down with knees bent in the air, lift your hips straight up using your abs, not momentum.
- E16 Glute Kickback: On hands and knees, press one heel toward the ceiling and squeeze at the top.
- E17 Band Good Morning: Stand on a band looped over your shoulders, push your hips back with a flat back, then stand.
- E18 Band Reverse Fly: Hold a band in front of you and pull your hands out wide, squeezing your shoulder blades.
- E19 Floor Back Extension: Face down with hands by your head, lift your chest and legs a little and lower slowly.
- E20 Russian Twist: Seated and leaning back, turn your torso side to side with your feet off the floor.
- E21 Sit-Up: On your back with knees bent, curl all the way up to sitting and lower with control.
- E22 Band Calf Raise: Seated with a band over the balls of your feet, press your toes forward and return slowly.
- E23 Dumbbell Fly: Lying on a bench with soft elbows, open your arms wide and bring the weights back together over your chest.
- E24 Incline Dumbbell Fly: The same wide arc on an incline bench, which puts more work on the upper chest.
- E25 Cable Crossover: Standing between high pulleys, sweep both hands down and together in front of your hips.
- E26 Arnold Press: Start with palms facing you at chest height, rotate them forward as you press overhead.
- E27 Dumbbell Front Raise: Lift a weight straight ahead to shoulder height with a soft elbow and lower slowly.
- E28 Bent-Over Rear Delt Raise: Chest on an incline bench, lift both weights out to the sides with your elbows slightly bent.
- E29 Dumbbell Upright Row: Pull two dumbbells up the front of your body until your elbows reach shoulder height.
- E30 Dumbbell Pullover: Lying across a bench, lower one dumbbell behind your head with bent arms and pull it back over your chest.
- E31 Concentration Curl: Seated with your elbow braced on your inner thigh, curl one dumbbell up without swinging.
- E32 Reverse Curl: Hold the bar with palms down and curl it up, keeping your wrists straight.
- E33 Lying Dumbbell Triceps Extension: Lying on a bench, bend only at the elbows to lower the weights beside your head and press back.
- E34 Cable Wood Chop: Pull the handle diagonally across your body from high to low, turning from the hips.
- E35 Dumbbell Wrist Curl: Forearms on a bench, palms up, curl only your wrists to lift the weights and lower slowly.
- E36 Dumbbell Calf Raise: Holding weights at your sides, rise onto your toes and lower below the step if you have one.
- E37 Kettlebell Thruster: Squat with the bell at your shoulders, then drive up and press it overhead in one motion.
- E38 Dumbbell Squat: Hold a dumbbell in each hand at your sides and squat to parallel.
- E39 One-Arm Dumbbell Shoulder Press: Press one dumbbell overhead from your shoulder while the other hand rests on your hip.
- E40 Leg Press Calf Raise: On the leg press, push the sled with just your toes and let your heels sink back.

## Open points for Product and Core
1. Seed ids for E01 to E40 and W01 to W14 are for Core to mint (stable UUIDs, as the built-ins). The ids above are labels in this note only.
2. Level words (Beginner, Intermediate) come from the lift list, not from free-exercise-db levels. Product can drop the Level column if it adds noise.
3. Programs (multi-week) are phase 2 and are not written here.
4. The Place column says where an exercise is usually done. Dumbbell moves that fit both a home and a gym are marked Home, so the Home filter shows them. Core and Product decide whether a row can carry both.
5. The extras have no Gym visual picture. Builder A decides how an exercise page looks without one. Face Pull in the built-ins is also without a picture. Pictures stay on the exercise page only and never go to Claude.
