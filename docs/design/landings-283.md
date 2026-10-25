# 283 Landings: one layout for every room (v4, Oct 25 4:25 PM PT; design approved 2:48 PM)
Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp (v4). Owners: Builder A (Bridge, flip, Deck, Lookout), Builder B (Log, Galley, Watch, Purse). Builds on landing-contract v2 and hub 282. v2 replaces the v1 middle and doors.

## His rules (Oct 25, PDT)
- 12:22 PM: every landing opens like Bridge, then the doors. Sections persist across screens, and each owns its touch zone. Opening a room from Bridge flips the mosaic into that room's keystone, each room its own way. The top area holds navigation, the title and summary lines.
- 12:26 PM: the blurred small-type dial is for the doors on the left only (the 246 dial). The right side shows the room's own content.
- 2:44 PM: the switcher is one text-only element that swipes both ways (axes may mean the same or different things), elegant and dramatic. It is optional per room but reserves its own space near the top; the room's needs sit to its right. The middle band shows what's going on, with animation themed to the room.
- 2:48 PM: design approved; build it. Make the Lookout transition cooler. The lower sections (widget and dial) stay exactly as on Bridge in every room.
- 2:50 PM and 2:55 PM: name the sections on a reference page. Keep the widget simple and subtly on theme with the keystone (Watch: birds or flowers; Deck: chalk).

## The sections (402 x 874 pt; same names everywhere)
1. Status bar: 0-44.
2. Masthead: 44-182. Title (Figtree 700 40 at top 54, room color). Nav word (the previous screen's name, 15 pt 500 ink2, right edge at top 56, 44 pt target; goes back). Switcher (x 24-224, top 106, 76 tall; optional). Needs (x 228-378, top 124, two 15/24 lines, the first 600 ink). Bridge: Settings word and departure lines.
3. Keystone: 24-378 x 196-378, live on every page of the room. Bridge: the mosaic, 180-400.
4. Caption: top 388, 15 pt ink2, one line on how to touch the keystone. Bridge: none.
5. Widget: 24-378 x 400-612, Bridge's one-thing box exactly. Header (13 pt 600, .12em caps, at 429), Big line (64 tall: a word at 38 pt 700, or a number in Outfit 56 with its unit at half size), Middle line (20 pt 500), Small line (15 pt 500 ink2), Glyph (80 x 80, right edge, top 444). Bridge: the one thing.
6. Doors: Dial x 24-184, top 640, three 40 pt places (focus 26 pt 700 in its color with an Outfit count; neighbours 20 pt, 1.6 pt blur). Door summary x 186-378, top 652: a 13 pt ink2 label and up to three 16/24 lines, the first 700. It rises 6 pt by clip on change. Bridge: the apps dial and one fact line at 688.
7. Foot: Action word bottom left (Figtree 600 20), Tess bottom right.
- Text fits its slot: cut on a whole word, drop trailing small words and commas. No ellipsis, no shrinking.

## Touch
- Switcher: across and up or down past 40 pt commit; tap goes to the next across. Axis lock at 8 pt. Needs change with it.
- Widget: across and up or down for the next item (past 50 / 44 pt), hold the Big line 180 ms then 600 ms to strike it (Done, Undo 10 s; Lookout and Purse have no strike), tap opens it.
- Dial: up and down; tap the focus to open. Keystone: its own gestures; strips own drags that start on them.

## The switcher (text only)
- One word, Figtree 300 38/56, variable weight. Across: the old letters stream out leaning with the swipe (skew 24°, 2.5 pt blur, 14 ms apart, 300 ms); the new ones stream in from the swipe side at weight 800, overshoot at 700 and settle at 300 (720 ms, 22 ms apart). Up and down: each letter rolls over like a drum (rotateX 85° in, 24 ms apart, 620 ms). While dragging, the word follows the finger, letter-spacing opens to +.055em and weight rises to 600; the next word shows at the far edge. A weight wave (300 to 520) passes through it every 9 s.
- Lists: Log across Newest, Due, Pinned, From Tess; up/down Today, This week, Earlier. Lookout across Now, Tonight, Tomorrow, This week. Deck across Today, This week, This month; up/down Push A, Pull A, Legs. Galley across Tonight, Tomorrow, This week. Watch across Evening, Night, Morning. Purse across October, This year, Since May.

## The widget, on theme
- Log: Big line in the word wall's type (Figtree 900 caps 36); words type in at 16 ms a letter. Glyph: three wall words re-set one after another.
- Lookout: words blow in from the right on the wind. Glyph: a cloud drifting, with rain falling.
- Deck: Big line in Caveat 600 48 (numbers stay Outfit); lines are written on in chalk steps. Glyph: the board's ticks, this week's sessions, stroke by stroke.
- Galley: Big line in Caveat 600 48; words rise like steam. Glyph: one ticket on the rail, swinging as it is hung.
- Watch: words grow from the baseline. Glyph: a little bird hops onto a branch and a flower under it opens.
- Purse: numbers count up. Glyph: the index line draws to its dot. No red or green for amounts.
- Each glyph moves once on arrival and every 7 s after. Reduce Motion: no motion, everything shown.
- Cards (sample data): Log Trip packing, Run plan, Lamp repair, Book club. Lookout rain from 7 pm, tonight 54°, Thursday 68°. Deck tonight 6:30 pm, this week 3 of 6, yesterday's walk. Galley Tacos, Rice, 3 things on the way, 7 dishes. Watch Walk, Journal (thirsty, wine), 3 of 7. Purse still yours 2,125, next drop 45, today 86.

## Opening
- Sections in order (masthead, keystone, caption, widget, dial, summary, action), 80 ms apart: each rises 10 pt out of a 3 pt blur from 95% size over 0.5 s (0.2, 0.8, 0.2, 1), revealed by a clip. Reduce Motion: 150 ms cross-fade. Entered from Bridge, the keystone comes by the flip and the rest starts 160 ms later.

## The flip (Bridge to a room)
- The mosaic is snapshotted and cut into 16 x 8 tiles over the slot. Each tile turns away by cos(pi/2 * p) over 340 ms, darkening to 28%, with 0-420 ms delays by the room's order plus 0-40 ms jitter. Orders: Log row by row (x), Deck a left-to-right sweep (y), Galley column by column (y), Watch from the ground up (y), Purse left to right (x).
- Lookout (new): the mosaic blows apart like cloud. From the middle out, each tile drifts outward and with the wind (up to 110 pt right, 22 pt up), grows to 1.35x, turns up to 10°, blurs to 6 pt and fades over 700 ms (ease-out cubic). A soft warm glint (32% at its peak) sweeps across the slot from 120 to 1100 ms.
- Back to Bridge: page-colored tiles open on the mosaic in the room's order. Haptic: one soft tick on the first tile. Reduce Motion: 150 ms cross-fade.

## Changes for builders (against v1 of this sheet)
1. The up-next switcher at 422 and the summary sentence are gone; the middle is now the Widget at 400, Bridge's one-thing box.
2. The doors dial moves from 540 to 640 and becomes Bridge's dial (40 pt places, width 160); the Door summary moves to x 186, top 652.
3. The masthead gains the Switcher and Needs at 106.
4. Lookout's flip is the cloud drift above.
5. Names: use the seven section names above in code and talk.

## v3 (his 3:57 and 4:04 PM notes)
- Fonts: Caveat is gone. Deck writes in Barlow Condensed 600: the board's chalk at 1.04x its old size, and the widget Big line at 50 pt in caps. Galley's tickets are printed in IBM Plex Sans Condensed: titles 700 13 pt caps .08em, sub 500 10.5 caps, lines 400 12.5. The widget Big line is 700 40 caps .04em.
- Foot, the action word: a verb (Figtree 600 24/32, room color) over its object (500 13/18 ink2), at x 24, bottom 22, 220 x 64. Never "Start Push A". Tap does it. Swiping across past 56 pt moves to the room's next action: the letters stream in leaning from the swipe side, 480 ms, 22 ms apart, and the object rises in. A start (Deck) needs a 500 ms hold that fills the verb with color from left to right; a tap shows "Hold to start." Actions: Log Write, Speak, List. Lookout Alert, Hours, Walk. Deck Start, Log, Rest. Galley Cook, Get, Wash. Watch Plant, Water, Pause. Purse Log, Look, Plan.
- Glyph library (80 x 80, item color), picked by rules on the item's header, big and middle lines (first match wins; Tess picks later):
  - Log: spark (Tess), bulb (repair), book (club), checklist (packing, list).
  - Lookout: rain, moon (low, night), sun (driest, clear).
  - Deck: steps (walk, run), ticks (week, of 6), barbell (push, pull, legs).
  - Galley: plates (dishes), bowl with steam (rice, leftovers), ticket (tacos, cook), basket (things, get).
  - Watch: watering can (journal, thirsty), grove (tended, of 7), bird and flower (walk, next, stretch).
  - Purse: calendar (drop, rent), coins (today, spent), index line (still yours, pace).
  - The cover: when nothing fits, the item's own words (up to three, Figtree 900 caps, sized to 80 pt wide, set like the wall).
- The glyph never cuts: the old one collapses into a point (260 ms, rotating 70°), a 6 pt dot pulses, and the new one forms from it (440 ms from 330 ms, overshoot 1.08). Each drawing moves once on arrival and every 7 s.
- The keystone hands the item over when it arrives:
  - Log: the matching wall word lifts 14 pt and flies to the Big line (760 ms). The wall word dims while it is away, and the other lines drop in from the top.
  - Galley: the matching ticket tears off with a torn edge, swings and falls into the glyph (900 ms).
  - Deck: 70 grains of chalk dust fall from the board and turn blue as they land.
  - Lookout: 26 drops fall from the glass.
  - Watch: the bird flies down from the woods, and petals drift for the other items.
  - Purse: a dot slides off the index on an arc.
  - Reduce Motion: none of these.
- To do later: polish the keystones; a library of short videos.

## v4: the whole screen mapped, moving place by place, Layout mode (his 4:11 and 4:14 PM notes)
- Every point belongs to a named place; an empty place is kept and marked, never filled by its neighbour. Phone points, x, y, w by h:
  - Status bar 0, 0, 402 by 44 (system).
  - Masthead 0, 44, 402 by 138: Title 24, 50, 260 by 48; Nav word 300, 50, 94 by 46; Switcher 24, 106, 200 by 76; Needs 228, 118, 150 by 58. On Bridge it holds the Settings word (24, 74, 110 by 44) and the Departure board (140, 74, 238 by 104).
  - Breath 24, 182, 354 by 14 (always empty).
  - Keystone 24, 196, 354 by 182.
  - Caption 24, 378, 354 by 34 (empty on Bridge).
  - Widget 24, 412, 354 by 200 (Bridge's one-thing box; content from 429). Glyph 298, 444, 80 by 80.
  - Breath 24, 612, 354 by 28.
  - Doors 24, 640, 354 by 120: Dial 24, 640, 160 by 120; Door summary 186, 640, 192 by 120.
  - Breath 24, 760, 354 by 16.
  - Foot 0, 776, 402 by 76: Action word 24, 786, 220 by 62 (empty on Bridge, which shows the undo line); Tess 306, 776, 96 by 96.
  - Home bar 0, 852, 402 by 22 (system).
  - Edges: Back edge x 0 to 24 (swipe back); right edge x 378 to 402, empty.
- Moving between Bridge and a room (and room to room through Bridge) goes place by place. The old screen's places are lifted into the new one, play their exit there and are dropped:
  - Masthead flaps like the board: old rows rotateX 0 to 88° in 200 ms, 50 ms apart; new rows -88° to 6° to 0 in 340 ms from 180 ms, 60 ms apart.
  - Keystone: the flip (tiles), and back, the reveal.
  - Caption rolls up into the keystone (160 ms) and unrolls from it (320 ms at 520 ms).
  - Widget: the old item up 48 pt and out (260 ms); the new one up from 64 pt below (420 ms at 200 ms).
  - Dial, the reel: a 120 pt window masked at both ends shows a column of the old three places, nine mixed names from both lists, then the new three. It runs 980 ms, fast at first with 3 pt blur, then slows to rest on the new doors, and the real dial fades in under it (140 ms).
  - Door summary slides off right 80 pt (260 ms), and the new one slides in from 90 pt right with a 3 pt overshoot (420 ms at 640 ms, as the reel slows).
  - Action word: out left with a skew (220 ms); the new letters stream in from the left (460 ms at 420 ms, 24 ms apart). Tess stays, and only her colour changes.
  - Reduce Motion: a 150 ms cross-fade.
- When one side is empty, the other side plays its half alone. When content won't carry over (a picture becoming words), it collapses to a point and forms again, as the Glyph does.
- Show sections (board): the map drawn over any live screen, with its empty places hatched.
- Layout mode (Settings > Layout mode, read-only): every screen as soft bubbles, one per place, in the room's colour (11% fill, 18 pt radius, a 1 pt inner line). Empty places are dashed, and the Title bubble carries the room's name. Swipe across (arrow keys on the board) to walk Bridge, Log, Lookout, Deck, Galley, Watch and Purse; each bubble moves the way its place does. Tap a bubble to read its frame, what it holds on this screen, its touch and its move, inside the Keystone bubble. Tap the Nav word bubble twice, or swipe from the left edge, to leave. Editing comes later.

## v5: the shell stays, only content changes (his 4:21 and 4:22 PM notes)
- No screen ever slides in. The places stay where they are; going anywhere hands each place new content and the
  place changes it in its own way. Back is the same moves run the other way, with every place restored.
- A keystone that is the same on both sides (the Galley rail, the Deck board, the Log wall) is not touched.
- Content in no named place (door lists) leaves softly where it stands; new content settles in from the top down.
- Layout to layout: Switcher + Needs merge into the Door title; Widget, Glyph, Dial and Door summary merge into
  the Page. Back splits them apart. Layout mode shows it: tap the Dial bubble twice, Nav word twice to return.
- The full contract between the UI and the content: `shell-contract-283.md`.

## v6: back in place, and a door summary per room (his 4:47 and 4:48 PM notes)
- Back never moves the page. An edge pull leaves the screen where it is: content blurs up to 2.4 pt and fades
  to 60% with the pull (full at 120 pt) and the nav word scales up to 1.18. Past 80 pt the places change in place
  (v5 rules); short of it, everything settles back in 0.28 s. No interactive pop, no screen translation.
- Door summary (186,640 192x120) keeps its place; its lines change per room when the dial turns:
  - Log: new lines type on (one step per letter, up to 0.42 s, 0.12 s apart); old lines backspace (0.15 s).
  - Lookout: new lines condense out of fog (blur 8 to 0, letter spacing .22 em to normal, 0.62 s); old lines
    evaporate upward with blur.
  - Deck (Barlow Condensed): lines are chalked on left to right (0.3 s, 0.15 s apart); old ones are wiped off
    with a small puff of chalk dust falling toward the foot.
  - Galley (IBM Plex Sans Condensed): the new summary prints down in 7 steps (0.52 s); the old one tears off
    upward on a zigzag edge.
  - Watch: new lines grow up from their baseline with a small sway (0.56 s); old lines fall like leaves.
  - Purse: words do not move (plain fade); only the numbers roll like a meter, digit by digit. Never red/green.
- Reduce Motion: a plain swap. All under 1 s.
