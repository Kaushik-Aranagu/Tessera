# Deck, Level 1 and Level 2: what still differs from the board

Checked on Oct 28 against `ios/deck-levels` at b4d689dd. The contract is sheet 284 (`docs/design/levels-284.md`).
The board is https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp v112: open the Deck, turn the dial and tap a door, then tap a row. Most of it already matches: the frame, the rank weights, the title sizes, the first row's color, gold bests, the facts row and the sets body. The list below is what's left, roughly in the order he would notice it.

## Fix before it goes on his phone

1. **Two stray files are committed.** `Features/Home/DeckRoomContent.swift-E` and `Features/Landing/Kit/ItemBodies.swift-E` are backups left by `sed -i -E` on macOS (BSD sed takes `-E` as the backup suffix). Delete them, and use `sed -i '' -E` from now on
2. **Each door has its own caption.** At level 1 and 2 the caption is the door's keystone hint, not the landing's. It eases to the new door's words when the Door title turns (315): never a swap
   - Today: "The board keeps what you chalk on it"
   - This week: "Swipe fast left on the board to wipe it"
   - Library: "Hold a name on the board to see it"
   - Bests: "Bests are written in gold"
   - Plan: "Drag on the board to write"
3. **The foot changes with the level.** Today all three levels show the landing's Start, Log and Rest
   - Level 1: "Add" with "to {door}", then "Ask" with "Tess about {door}". The object follows the door as it turns (316). Only the object eases over, and the verb stays put
   - Level 2: the item's own verbs. For a lift: "Start" (hold) with "set 1, 185 lb", then "Swap" with "for dumbbells". For a row with no page of its own: "Open" with its name, then "Ask" with "Tess about {name}"
   - When the verbs change between items, the old action word leaves left (0.2 s) and the new one comes in from the right (0.32 s, starting 0.14 s later). When the verbs are the same, only the object eases over
4. **Tess stays at the foot on every level.** The screens set `.tess: nil` at levels 1 and 2. Sheet 284's frame keeps her bottom-right everywhere
5. **"BW" is jargon.** A bodyweight value reads "Body", the way the board's Dips row does

## This week

6. The week runs Monday first, the house rule, and not from today. It lists only the days with something on them, a workout done or one planned. Empty days are left out, and nothing ever says missed
7. Today's row is titled "Today", not its weekday name
8. Each row has a value:
   - done days: the workout's minutes ("50 min");
   - today: its start time ("6:30");
   - a planned day: "Plan".
   The sub line names the workout: "Push B, done" for a done day, "Push A" for today, "Pull B" for a planned day. It names the workout, not one lift ("Trained, Bench")
9. The Door title's line is "3 of 5 done": the workouts done, out of the ones the week plans. It is not "3 trained"

## Library

10. On the board, Library lists workouts, not lifts. Each row is a routine:
    - title: the routine's name ("Push A");
    - sub: its lifts ("Bench, press, row, dips");
    - value: its usual minutes ("45 min").
    A new one is in gold ("Hill sprints", with "New" as the first word of its sub), and a private one is "Private workout" with "Kept on the phone". The line is "28 workouts in 6 kinds". The lifts with their bests already live under Bests
    - If the routines and their kinds aren't in one place yet, say so and keep the lift list for now. This is the biggest change on the list

## Bests

11. The line counts the new bests since the plan's block began ("3 new since Oct 1"). It is not "N lifts"
12. A best from the last month says how long ago in words ("5 reps, three weeks ago"). Older ones keep the date ("3 reps, Oct 9")

## Plan

13. On the board, Plan is about the block, not the routines:
    - "This block": "Strength, 6 weeks", "5 of 6"
    - "Next week": "Deload, lighter", "Nov 2"
    - "New block": "Hypertrophy", "Nov 9"
    - "Goal": "Bench 225 by spring", "225 lb"
    The line is "Week 5 of 6, then a deload"
    - If Core has no block, deload or goal facts yet, keep the routines and tell Core what's missing. Don't make these rows up

## Item page (a lift)

14. The Item title's line says where the lift sits ("Push A, first lift"), not the next set. The next set is already in the room color in the body
15. The sets body:
    - one warm-up row, as on the board ("Warm-up", "95 lb, 10"), not two ramp rows. If the two-row ramp is a deliberate seam until Core prescribes warm-ups, keep it and say so in the sheet;
    - rows written "185 lb, 5", with a comma and never "×";
    - the note in words: "Last time: 180 lb, 4 sets of 5". Not "80 kg × 5, 5, 5, 4". When the reps differ, list them: "180 lb, 5, 5, 5 and 4"
16. A missing fact shows "—", as the board does, not "None" in the number's place

## Polish (small)

17. Row values stay ink, as on the board, whatever the row's state. Only the title takes the first row's mixed color or a state color (done green, best gold, and so on). Two big things on a row never share a color
18. A value's unit is half the value's size (0.41 of the title, not 0.5), with a 10 pt floor, in the value's own font and ink (Outfit Light). It is not Figtree in ink 2. That is the units rule
19. Rows settle in from 8 pt above with a 2 pt blur that clears (0.38 s, 45 ms apart). Today they come from 10 pt with no blur. The same goes for the facts and the body on the item page
20. A private row's title is ink like any other row. It is set apart only by its words ("Private workout", "Kept on the phone")
