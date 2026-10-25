# 283 Landings: one layout for every room (v2, Oct 25 3:10 PM PT; design approved 2:48 PM)
Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp (v2). Owners: Builder A (Bridge, flip, Deck, Lookout), Builder B (Log, Galley, Watch, Purse). Builds on landing-contract v2 and hub 282. v2 replaces the v1 middle and doors.

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
