import Foundation
// swiftlint:disable line_length

// Written by Research (docs/research/training-library-phase1.md) in our own words. The 40 extras use free-exercise-db
// (Unlicense) names, equipment and muscle fields only: no instructions, no images. Muscles are the fixed 18, taken
// per exercise from that table (shoulders split into Front, Side and Rear Delts; middle back and traps are Upper Back).

extension LibraryExtras {
    /// key|name|equipment|primary|secondary|mechanic|place|free-exercise-db id|cue
    static let exerciseTable = """
    E01|Bodyweight Squat|Body|Quads|Glutes, Hamstrings|compound|Home|Bodyweight_Squat|Feet shoulder width apart, sit back and down until your thighs are level, then stand tall.
    E02|Single-Leg Glute Bridge|Body|Glutes|Hamstrings|isolation|Home|Single_Leg_Glute_Bridge|Lie on your back, one foot planted and the other leg lifted, push through the heel until your hips are level with your knee.
    E03|Incline Push-Up|Body|Chest|Triceps, Front Delts|compound|Home|Incline_Push-Up|Hands on a bench or counter, body in one line, lower your chest to the edge and press away.
    E04|Decline Push-Up|Body|Chest, Front Delts|Triceps|compound|Home|Decline_Push-Up|Feet on a bench, hands on the floor, lower your chest between your hands and press back up.
    E05|Inverted Row|Body|Upper Back|Lats|compound|Home|Inverted_Row|Hang under a bar or sturdy table, body straight, pull your chest to the edge and lower with control.
    E06|Superman|Body|Lower Back|Glutes, Hamstrings|compound|Home|Superman|Face down, lift arms and legs together, pause for a breath, lower slowly.
    E07|Dead Bug|Body|Abs||compound|Home|Dead_Bug|On your back with knees and arms up, lower the opposite arm and leg while your lower back stays on the floor.
    E08|Side Plank|Body|Obliques|Abs|isolation|Home|Side_Bridge|On one forearm with your body in a line, hold your hips up for the whole set.
    E09|Mountain Climber|Body|Quads, Abs|Front Delts, Hamstrings|compound|Home|Mountain_Climbers|From a push-up position, drive one knee at a time toward your chest at a steady pace.
    E10|Bench Dip|Body|Triceps|Chest, Front Delts|compound|Home|Bench_Dips|Hands on a bench behind you, bend your elbows to lower your hips, then press up.
    E11|Bodyweight Lunge|Body|Quads, Glutes|Calves, Hamstrings|compound|Home|Bodyweight_Walking_Lunge|Step forward, drop your back knee toward the floor, push through the front foot into the next step.
    E12|Band Pull-Apart|Band|Rear Delts|Upper Back|isolation|Home|Band_Pull_Apart|Hold a band at chest height with straight arms and pull it apart until it touches your chest.
    E13|Crunch|Body|Abs||isolation|Home|Crunches|On your back with knees bent, curl your ribs toward your hips and lower slowly.
    E14|Reverse Crunch|Body|Abs||isolation|Home|Reverse_Crunch|On your back, curl your knees toward your chest and lift your hips a little off the floor.
    E15|Bent-Knee Hip Raise|Body|Abs||compound|Home|Bent-Knee_Hip_Raise|Lying down with knees bent in the air, lift your hips straight up using your abs, not momentum.
    E16|Glute Kickback|Body|Glutes|Hamstrings|compound|Home|Glute_Kickback|On hands and knees, press one heel toward the ceiling and squeeze at the top.
    E17|Band Good Morning|Band|Hamstrings|Glutes, Lower Back|compound|Home|Band_Good_Morning|Stand on a band looped over your shoulders, push your hips back with a flat back, then stand.
    E18|Band Reverse Fly|Band|Rear Delts|Upper Back|isolation|Home|Back_Flyes_-_With_Bands|Hold a band in front of you and pull your hands out wide, squeezing your shoulder blades.
    E19|Floor Back Extension|Body|Lower Back|Glutes, Hamstrings|compound|Home|Hyperextensions_With_No_Hyperextension_Bench|Face down with hands by your head, lift your chest and legs a little and lower slowly.
    E20|Russian Twist|Body|Obliques|Abs, Lower Back|compound|Home|Russian_Twist|Seated and leaning back, turn your torso side to side with your feet off the floor.
    E21|Sit-Up|Body|Abs||isolation|Home|Sit-Up|On your back with knees bent, curl all the way up to sitting and lower with control.
    E22|Band Calf Raise|Band|Calves||isolation|Home|Calf_Raises_-_With_Bands|Seated with a band over the balls of your feet, press your toes forward and return slowly.
    E23|Dumbbell Fly|Dumbbell|Chest||isolation|Gym|Dumbbell_Flyes|Lying on a bench with soft elbows, open your arms wide and bring the weights back together over your chest.
    E24|Incline Dumbbell Fly|Dumbbell|Chest|Front Delts|isolation|Gym|Incline_Dumbbell_Flyes|The same wide arc on an incline bench, which puts more work on the upper chest.
    E25|High-to-Low Cable Crossover|Cable|Chest|Front Delts|isolation|Gym|Cable_Crossover|Standing between high pulleys, sweep both hands down and together in front of your hips.
    E26|Arnold Press|Dumbbell|Front Delts, Side Delts|Triceps|compound|Gym|Arnold_Dumbbell_Press|Start with palms facing you at chest height, rotate them forward as you press overhead.
    E27|Dumbbell Front Raise|Dumbbell|Front Delts||isolation|Home|Front_Dumbbell_Raise|Lift a weight straight ahead to shoulder height with a soft elbow and lower slowly.
    E28|Bent-Over Rear Delt Raise|Dumbbell|Rear Delts|Upper Back|isolation|Gym|Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench|Chest on an incline bench, lift both weights out to the sides with your elbows slightly bent.
    E29|Dumbbell Upright Row|Dumbbell|Side Delts, Upper Back|Biceps|compound|Gym|Standing_Dumbbell_Upright_Row|Pull two dumbbells up the front of your body until your elbows reach shoulder height.
    E30|Dumbbell Pullover|Dumbbell|Lats, Chest|Triceps|compound|Gym|Bent-Arm_Dumbbell_Pullover|Lying across a bench, lower one dumbbell behind your head with bent arms and pull it back over your chest.
    E31|Concentration Curl|Dumbbell|Biceps|Forearms|isolation|Gym|Concentration_Curls|Seated with your elbow braced on your inner thigh, curl one dumbbell up without swinging.
    E32|Reverse Curl|Barbell|Forearms, Biceps||isolation|Gym|Reverse_Barbell_Curl|Hold the bar with palms down and curl it up, keeping your wrists straight.
    E33|Lying Dumbbell Triceps Extension|Dumbbell|Triceps||isolation|Gym|Lying_Dumbbell_Tricep_Extension|Lying on a bench, bend only at the elbows to lower the weights beside your head and press back.
    E34|Cable Wood Chop|Cable|Obliques|Abs, Front Delts|compound|Gym|Standing_Cable_Wood_Chop|Pull the handle diagonally across your body from high to low, turning from the hips.
    E35|Dumbbell Wrist Curl|Dumbbell|Forearms||isolation|Gym|Palms-Up_Dumbbell_Wrist_Curl_Over_A_Bench|Forearms on a bench, palms up, curl only your wrists to lift the weights and lower slowly.
    E36|Dumbbell Calf Raise|Dumbbell|Calves||isolation|Home|Standing_Dumbbell_Calf_Raise|Holding weights at your sides, rise onto your toes and lower below the step if you have one.
    E37|Kettlebell Thruster|Kettlebell|Front Delts, Quads|Triceps, Glutes|compound|Gym|Kettlebell_Thruster|Squat with the bell at your shoulders, then drive up and press it overhead in one motion.
    E38|Dumbbell Squat|Dumbbell|Quads|Glutes, Hamstrings, Calves, Lower Back|compound|Home|Dumbbell_Squat|Hold a dumbbell in each hand at your sides and squat to parallel.
    E39|One-Arm Dumbbell Shoulder Press|Dumbbell|Front Delts|Triceps, Side Delts|compound|Home|Dumbbell_One-Arm_Shoulder_Press|Press one dumbbell overhead from your shoulder while the other hand rests on your hip.
    E40|Leg Press Calf Raise|Machine|Calves||isolation|Gym|Calf_Press_On_The_Leg_Press_Machine|On the leg press, push the sled with just your toes and let your heels sink back.
    """

    /// id|title|group|place|level|minutes|about|exercise:sets:from:to;...  (a hold is seconds)
    static let workoutTable = """
    W01|Push Day|push|gym|intermediate|55|Chest first, then shoulders and triceps. A classic heavy push session.|Bench Press:4:6:8;Overhead Press:3:8:8;Incline Dumbbell Press:3:10:10;Dumbbell Lateral Raise:3:12:15;Rope Pushdown:3:12:12;Cable Fly:2:15:15
    W02|Machine Push|push|gym|beginner|45|All machines and cables, so you can train hard without a spotter.|Machine Chest Press:3:10:10;Machine Shoulder Press:3:10:10;Pec Deck:3:12:12;Cable Lateral Raise:3:15:15;Overhead Cable Extension:3:12:12;Dip:2:8:10
    W03|Push at Home|push|home|beginner|35|Push-ups and a pair of dumbbells. Chest, shoulders and triceps in about half an hour.|Push-Up:4:8:15;One-Arm Dumbbell Shoulder Press:3:10:10;Decline Push-Up:3:8:12;Dumbbell Lateral Raise:3:15:15;Bench Dip:3:12:12;Dumbbell Front Raise:2:12:12
    W04|Pull Day|pull|gym|intermediate|55|Heavy rows and pulldowns, then rear shoulders and biceps.|Barbell Row:4:6:8;Lat Pulldown:3:10:10;Seated Cable Row:3:10:12;Face Pull:3:15:15;Barbell Curl:3:10:10;Hammer Curl:2:12:12
    W05|Pull-Up Focus|pull|gym|intermediate|40|Starts with pull-ups while you are fresh, then back volume and curls.|Pull-Up:4:5:8;Chest-Supported Row:3:10:10;Straight-Arm Pulldown:3:12:12;Reverse Pec Deck:3:15:15;Incline Dumbbell Curl:3:12:12
    W06|Pull at Home|pull|home|beginner|35|Dumbbells, a band and a sturdy table or bar for rows.|One-Arm Dumbbell Row:4:10:10;Inverted Row:3:8:12;Band Pull-Apart:3:20:20;Dumbbell Curl:3:12:12;Superman:3:12:12;Hammer Curl:2:12:12
    W07|Leg Day|legs|gym|intermediate|60|A heavy squat and hinge, then machines for the rest of the legs.|Back Squat:4:6:6;Romanian Deadlift:3:8:8;Leg Press:3:12:12;Lying Leg Curl:3:12:12;Standing Calf Raise:4:12:12;Hip Abduction:2:15:15
    W08|Machine Legs|legs|gym|beginner|50|Machines and walking lunges with no heavy bar on your back.|Hack Squat:3:10:10;Walking Lunge:3:10:10;Seated Leg Curl:3:12:12;Leg Extension:3:12:12;Hip Thrust:3:10:10;Seated Calf Raise:3:15:15
    W09|Legs at Home|legs|home|beginner|35|One dumbbell or two, plus floor work for glutes and calves.|Goblet Squat:4:12:12;Dumbbell Romanian Deadlift:3:10:10;Reverse Lunge:3:10:10;Single-Leg Glute Bridge:3:12:12;Dumbbell Calf Raise:3:15:15
    W10|Full Body A|fullBody|gym|intermediate|50|Squat, press and row in one session. Pair it with B on alternate days.|Back Squat:3:8:8;Bench Press:3:8:8;Barbell Row:3:8:8;Overhead Press:2:10:10;Plank:3:45:45
    W11|Full Body B|fullBody|gym|intermediate|55|Deadlift, incline press and pulldown, with lunges and core to finish.|Deadlift:3:5:5;Incline Dumbbell Press:3:10:10;Lat Pulldown:3:10:10;Walking Lunge:2:10:10;Dumbbell Lateral Raise:2:15:15;Cable Crunch:3:12:12
    W12|Full Body at Home|fullBody|home|beginner|40|Dumbbells only. Legs, push, pull and core.|Goblet Squat:3:12:12;Push-Up:3:10:10;One-Arm Dumbbell Row:3:10:10;Dumbbell Romanian Deadlift:3:10:10;One-Arm Dumbbell Shoulder Press:2:10:10;Dead Bug:3:10:10
    W13|Short Strength|short|gym|beginner|25|Four big moves in about 25 minutes when the day is tight.|Goblet Squat:3:10:10;Dumbbell Bench Press:3:10:10;Lat Pulldown:3:10:10;Plank:2:45:45
    W14|Short at Home|short|home|beginner|20|No equipment and about 20 minutes. Good for a hotel room.|Bodyweight Squat:3:15:15;Push-Up:3:10:10;Superman:3:12:12;Bodyweight Lunge:2:10:10;Plank:2:40:40;Dead Bug:2:10:10
    """
}
// swiftlint:enable line_length
