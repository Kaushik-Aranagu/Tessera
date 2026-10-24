# 246 Notes landing: word wall + doors dial (APPROVED Oct 24, 1:54 AM PT)

Board: https://claude.ai/artifact/1mSPKcxhvQB4pFU2tmQZkx (v4). Owner: Builder B (Notes). Supersedes every earlier Notes landing
(226, 235 landing parts, 240, 242 rounds 1-5). Algorithm detail: landing-living-242.md rounds 4-6.

## Page (402 x 874 pt frame, 24 pt gutters)
- "Notes" at 54 pt top, Figtree 700 40 pt, room colour. One line under it (Figtree 16, ink 2), e.g. "Three new today, one from Tess."
- Word wall: x 24-378, y 180-400 (220 pt, a quarter of the screen, centred on the Home mosaic slot so the mosaic hands its place to the words).
- Doors dial: y 432-624 (32 pt under the wall). No section label.
- One line at 664: "You last wrote in <Title>, an hour ago." Figtree 15 ink 2, title ink 600. Private notes use shownLabel.
- "New note" action word bottom-left (28 pt from the edge, 44 pt target), Tess bottom-right. No lines, cards or fills.

## Word wall
- Words = the user's note titles, weighted (pinned, recent, due, opened often). Private notes never appear on the wall.
- CAPITALS, Figtree 900, letter-spacing -0.01 em, plus "sharpened": a same-colour outline behind each glyph, 3.5% of the size, mitred joins.
- Line box = cap height, 3 pt gaps between every brick. Rows solve their own height so they meet both edges exactly.
  - single word width = a/C*h (a = width per pt of size, C = cap height ratio);
  - stack of n small words, each sized to the brick width: (h-(n-1)*3)/(C*sum(1/a_i));
  - two-word name stacked on two lines, same colour and size: amax/C*(h-3)/2.
- The notch beside a stacked name's shorter line is filled by 1-3 small words stacked to its exact height, or two side by side at the name's size. Repeats are allowed, only of words not already on the wall. If nothing fits, the name goes on one line and the wall re-packs.
- HIS RULE: letters are never spaced unevenly and there are no gaps. Each word may stretch by 8% at most, glyphs and spacing together (uniform). A row that can't reach both edges is rejected, never squeezed. Pack at row-height scales 0.70-1.40 in 0.02 steps; keep the largest scale whose leftover is under 8 pt and spread the leftover into the row gaps.
- Colours: 12 per look, stepped by index*5 mod 12 so neighbours never match (light: B5452B 1E6E77 7A5A12 5A3F8E 2F6A8F 8A4570 3F6B2A 9A2541 0F766E 92400E 1F4E8C 1D1B19; black: F09A7E 84C3C9 E2C26A B4A3E6 8DBAD6 E3A3CB A9D48A F08E9C 5FD0C0 F0B07A 9DB8F0 F1EEE9). The wall is the one exception to 3-4 colours per page. Nothing under 13 pt.
- Tap a word: opens that note.

## Moments (his 1:46 AM timing)
- Every 5 s one word does one of: flip (rotateX 360, 0.8 s), jumble (letters scramble and settle left to right like the Home departure board, 0.8 s), dissolve (noise displacement out and back, 1.3 s).
- Every 40 s a new word swaps in and the wall re-packs (bricks glide to new places, spring 0.65 s).
- Every 2 min one whole-wall moment, in turn: diagonal flip wave; dissolve everything and rebuild with new words; pile and tidy.
- Pile: inside the band only. Words drop biggest first; each tries tilts 0, ±7, ±18, ±34, ±90 degrees at spots every 5 pt, falls until it touches the floor or another word (tilted-box separating-axis test, 3 pt margin), and keeps the lowest rest. If one can't fit, all shrink 3% and re-drop. Then they glide, turn and grow into the wall, 22 ms apart.
- Also plays on entry from Home (pile then tidy). Reduce Motion: no moments, swaps cross-fade.

## Doors dial
- The app dial: 3 places (focus plus one above and one below), 64 pt slots, loops, haptic tick per door, spring settle.
- Focus: name Figtree 700 21 pt x1.32 in its meaning colour, count Outfit 400 at about half size, ink 2. Neighbours: smaller, ink 2, depth blur up to 1 pt (none under Reduce Motion or Low Power).
- Doors in order: All notes (ink), Ideas (room), From Tess (Tess blue), Voice memos (room), Pinned (gold), Mentions (ink), Private (slate), Archive (ink 2).
- Right half beside the focus: "Newest <when>" (13 pt ink 2), then its 3 newest titles (16 pt, the first 700), rising 6 pt into place when the focus changes. Private titles use shownLabel.
- Drag vertically to turn. Tap the focus to open the door; tap a neighbour to turn to it.

## Next
- The pages behind each door (his 1:28 AM). Then Notes is done.
- Notes violet 5B3FB8 is still ΔE00 6 from Ember. This page uses room colour 8A4570 / E3A3CB (plum). Confirm that plum as the Notes room colour in the Notes round.
