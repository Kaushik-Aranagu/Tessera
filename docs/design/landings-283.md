# 283 Landings: one layout for every room (draft, Oct 25 2:55 PM PT; awaiting his review)
Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp (v1, the linked prototype with v3 landings). Owners: Builder A (Bridge, flip, Deck, Lookout), Builder B (Log, Galley, Watch, Purse). Builds on landing-contract v2 and hub 282; changes against them are listed at the end.

## His rules (Oct 25, PDT)
- 12:22 PM: every landing opens like Bridge, then the doors. Sections persist across screens, and each owns its touch and swipe zone. Opening a room from Bridge flips the mosaic into that room's keystone, and each room may flip its own way. The lower doors block arrives its own way. The top area becomes navigation plus a title and summary lines.
- 12:26 PM: the blurred small-type treatment is only for the doors dial on the left, done like the 246 dial (focus sharp, neighbours smaller and blurred). The right side shows the room's own summaries or lists, and Bridge keeps one line there. Landings may add a switcher, one element that swipes up and down through other things. Bridge needs none.

## Page (402 x 874, 24 pt gutters), same on every room landing
- Title: Figtree 700 40 pt at top 54, room color. Nav word: the previous screen's name ("Bridge"), 15 pt 500 ink2, right edge, 44 pt target; it goes back (as does the left edge 0-24).
- Summary: top 106, two lines, Figtree 300 24/32 pt, key phrases 600 in role colors. Fixed slot, 354 x 64.
- Keystone: 24-378 x 196-378 (Watch bleeds to 0-402). Locked per room: Log word wall (246, h 182), Lookout skypiece (254 v9), Deck blackboard (258; the slate is now 206-368 with a 26 pt chalk edge), Galley pass (259), Watch woodland (268 v4), Purse indices (278 v3).
- Caption: top 388, 15 pt ink2, one line.
- Up next (the switcher): 24-378 x 422-518. It shows one thing at 20 pt (name 600), with the previous and next ones 30 pt above and below, at 72% size, 1.4 pt blur and half opacity. Swipe up or down past 24 pt to scroll. Swipe right past 90 pt for Done, left for Not now; the item follows the finger up to 110 pt, and Undo lasts 10 s. Tap opens it. Axis lock at 8 pt.
- Doors: the 246 dial, x 24-204, top 540, 3 places of 48 pt. The focus is 28 pt 700 in its color, with its count in Outfit; neighbours are 21 pt scaled 0.66, ink2, 1.8 pt blur, 60% opacity.
- Right summary: x 212-378, top 556, 120 pt tall. A 13 pt ink2 label, then up to four 16/24 pt lines (the first 700, numbers in Outfit). It rises 6 pt by clip when the focus changes.
- Action word bottom left (Figtree 600 20), Tess bottom right.
- Text fits its slot: the phone cuts a line on a whole word and drops trailing small words and commas. No ellipsis and no shrinking.

## Bridge
- It keeps 236 (board, mosaic, one thing). Its apps list becomes the same dial (x 24-184, top 640, 40 pt places, focus 26 pt 700 in the room color, neighbours 20 pt, 1.6 pt blur). Right of the focus is one 15 pt 500 ink2 line at top 688 (x 186-378): "Push A at 6:30 pm", "Tacos tonight", "Walk around 6", "Three new today", "Rent due Friday", "Rain from 7 pm".

## Opening (every landing, and Bridge on return)
- Sections in order (top, keystone, caption, up next, doors, summary, action), 80 ms apart. Each rises 10 pt out of a 3 pt blur from 95% size, over 0.5 s with ease-out (0.2, 0.8, 0.2, 1). It is revealed by a clip from the top edge, never an opacity fade. Reduce Motion: 150 ms cross-fade.
- When a room is entered from Bridge, the keystone comes in by the flip and the other sections start 160 ms later.

## The flip (Bridge to a room)
- The mosaic as shown is snapshotted and cut into 16 x 8 tiles over the slot (22.1 x 22.75 pt). Each tile turns away by cos(pi/2 * p) on its axis over 340 ms, darkening to 28% as it turns, and the new keystone is live under it. Delays run 0-420 ms by the room's order, plus 0-40 ms of jitter, so the whole flip is under 0.8 s.
- Orders: Log row by row like type (axis x). Lookout from the middle out (x). Deck a sweep left to right, the towel (y). Galley column by column, top down, like tickets (y). Watch from the ground up (y). Purse left to right like a line drawing (x).
- Back to Bridge: Bridge opens with its sections, and page-colored tiles open on the mosaic in the room's order (300 ms each, sin ease).
- The old screen is gone from the first frame; only the mosaic tiles carry over. Haptic: one soft tick when the first tile turns.
- Reduce Motion: no tiles; 150 ms cross-fade.

## Room content (sample data)
- Log: "Three new today, one from Tess. Trip packing has 8 left." Up next: trip packing, run plan, lamp repair, book club. Doors are the 247 doors with counts; the right side shows the 3 newest titles ("Locked, 3 private notes" for Private).
- Lookout: "Cloudy now, rain from 7 PM until about midnight." Up next: the care items. Doors: Hours, Tonight, This week, Air, Sky. Text color comes from the sky under the glass.
- Deck: "Push A at 6:30, bench first. Three of six done this week." Doors: Today (the lifts), This week, Library, Bests, Plan.
- Galley: "Tacos tonight, 25 min. Rice goes out today." Doors: Tonight, Pantry, Recipes, Groceries, Leftovers.
- Watch: "Three tended, four to go, Journal is thirsty." Doors: Today, Body, Mind, Home, Weekly. The summary lines use state colors (done green, care wine, automated slate).
- Purse: "2,125 still yours. Closing at 179 after rent." Doors: This month, Kinds, Saving, Investing, Debts, Mine. No red or green for amounts.

## Changes for builders (against landing-contract v2)
1. The two update rows at 424 become the one up-next switcher at 422-518.
2. Every room's doors are the dial, not door words. That includes Watch and Purse.
3. Bridge's apps list becomes the depth-blur dial, with one line on the right.
4. The nav word sits at the right of the title row.
5. The Deck slate shrinks to 206-368 so it stays in the slot.
6. The right summary is new, per room, as above.

## Open
- The switcher as "up next" (recommended) or as a time lens (today / this week / this month) that changes the summaries. Waiting on his call.
