# 213 One thing at a time, under the mosaic (Oct 23, 12:15 PM PT)

Board: https://claude.ai/artifact/VgyTXVBnXhMXW1ujG1qE1X. Kaushik picked option B at 12:04 PM ("something like B... swipe through... one thing at once... something big, something smaller, something even smaller... little graphics... no card"). REPLACES Next on Home (212 section 3 and 207's Next rows) and 209's mosaic pages (weather and week become kinds here). On by default.

## 1 The space
- Under the mosaic, a 196 pt space shows ONE thing. Three tiers, no frame, no card, no background:
  - big: Outfit 200 at 60 pt for numbers ("2:10", "4", "6 of 14", "64°", "8 pm"), or Outfit 200 at 44 pt for words ("Sunday", "Pack the charger"), in the thing's accent (ink for tasks); (sizes per the 12:18 PM section)
  - mid: Figtree 20, ink, with the app word as a 205 keyword (600, 1.1x, accent, 1 pt underline);
  - small: Figtree 15, ink 3.
- A small pixel sign on the right, centered vertically in the 196 pt space (top at 62 pt, center at 98 pt; right edge on the same margin as the text's left edge; 4:16 PM fix, it read off-center at the top; every tier's fixed slot ends 12 pt before the sign's left edge, and 224 short forms make each line fit), 72 pt (18 x 18 tiles of 4 pt, tile 3.2), in the accent blended toward the page in steps. Each sign moves a little:
  - Training: a barbell that lifts;
  - Groceries: a bag with things bobbing;
  - Birthday: confetti pixels falling;
  - Task: a pen line writing;
  - List: a suitcase filling to the done share;
  - Weather: a sun with turning rays;
  - Routine: a clock hand sweeping (no ring).
- Bottom right, "3 of 7" in Outfit 300, 14 pt, ink 3. No dots or bars.
- Order: Tess's on-device ranking, most important first, at most 7.

## 2 Kinds (copy patterns)
| Kind | big | mid | small |
| Training | 2:10 (time to start) | Push day, bench first | Bench best 205 lb, three weeks ago |
| Groceries | 4 | to get: tortillas, cilantro, limes, beans | For tacos tonight, on the way home |
| Birthday | Sunday | Mom turns 60 | Two days. A call in the morning, she likes those. |
| Task | Pack the charger | Before the trip, Sunday | Hold to strike it through |
| List | 6 of 14 | Packing, for Sunday | Next up: socks, the book, the adapter |
| Weather | 64° | Clear until 4, then rain | Sunset at 6:34 pm (sky word) + "A sample until Apple weather" |
| Routine | 8 pm | Stretch, five minutes | Third night this week |
Birthday accent: the existing routines/rose family, or Core's person accent if one exists; never cobalt. Weather uses the sky gradient (sheet 212 sunset rule). No money amounts, no health, body, calories or calendar titles off the phone. Private things read by their shown label.

## 3 Entrances (each kind its own)
- Each tier reveals in place with a clip (no offset, per the 12:14 correction), staggered 0 / 80 / 160 ms, 0.5 s.
- Training: the digits flip like the board (8 steps at 55 ms).
- Groceries: the items drop in one by one (110 ms apart, a small overshoot).
- Task: the title writes in left to right (stepped clip, 0.9 s).
- List: the count ticks up from 0.
- The pixel sign stays in place (12:14 correction: no rise).

## 4 The swipe
- A horizontal drag on the space OR on the mosaic turns the page. While dragging, the tiers follow at different speeds (big 0.9x, mid 0.72x, small 0.54x, sign 1x), which gives depth without a frame.
- Past 50 pt the page turns: the old one slides 40 pt and clips out in the swipe direction (0.32 s), and the new one enters with its own entrance. Under 50 pt it springs back.
- The mosaic follows: each page washes it 20% toward that thing's accent, sweeping across in about 0.6 s.
- One light haptic per page. Reduce Motion: plain swap, no parallax, no entrances.

## 5 Done
- Here horizontal swipes turn pages (his explicit ask for this surface), so finishing is press and hold on the big line: after 180 ms an ink strike (1.5 pt at 55% height) draws through over 0.6 s; letting go once it is full finishes it, shows the one Undo line, and the next thing arrives. Releasing early retracts the strike.
- One rigid haptic when the strike completes. This is the only exception to "swipe right = Done", and it applies only to this space.

## 6 The top lines stay departure style
- Line 1 is the date (212). Lines 2 and 3 roll every 6 s with the 200 letter flips (each character clicks through the alphabet, at most 9 steps, 52 ms, staggered per character). Never a slide or roll animation.

## 7 Looks
- Every board now has a look flip: Black (#000000 page and ground), Warm paper (current light), White (#FFFFFF page, #ECECEC ground), As the phone. Kaushik wants to compare absolute black on his phone; Core/A should check that the mosaic blend and Tess (screen compositing) read on pure black.

## Owners
- B: the space, the tiers, the swipe and the hold to finish; remove Next from Home.
- A: the pixel signs, the mosaic wash per page, the entrances.
- Core: the ranked thing list with kind, big/mid/small strings, privacy-safe; birthday source (Contacts later, local only).

## Reviewer guards
- No card, frame, background, dots or bars. Ink strike for done.
- No money, health or calendar text in strings. Private labels.
- Departure flips for the top lines, never slides.

## Reviewer conditions + coordinator ruling (12:10 PM)
- Swipe: on the one-thing surface a horizontal swipe pages and hold-to-strike is Done, with the one op-log Undo. Swipe right stays Done everywhere else.
- No frame, background or outline around any tier.
- The birthday accent must be more than ΔE 10 from Ember (2:26 PM rule; see tess-215-final.md); the rose B0466A / E07A9A qualifies.
- Private things use ObjectPrivacy.shownLabel in the big line, in the strike, and in the Undo line ("Private, done. Undo").
- Reduce Motion: plain swap between pages; the strike appears at once (static) on a completed hold, with no draw.
- Pure black is a ThemeConcept look (page and ground #000000), never a one-off override.
- VoiceOver: the thing on screen has an action named "Mark done" (same as the completed hold), plus adjustable actions for the next and previous thing.

## Addendum, Kaushik 12:12 PM: the mosaic lends its pixels; looks; Tess aware of her ground
- Lending: when a page arrives, its sign is built from tiles that fly out of the mosaic. One mosaic tile per sign tile, picked from fully shown tiles, staggered 7 ms, each flying 560 ms on an eased arc (lift 26 pt, swelling to 1.5x mid-flight, colour mixing from the mosaic tile to the sign colour). The sign draws for real only once all have landed.
- Each lent mosaic cell becomes a gap (88% toward the page) and fills back in over about 1.1 s after 450 ms, so the mosaic keeps its own pixels.
- On the next swipe the old sign's tiles fly home (500 ms, lift 18 pt) to free cells while the new sign's tiles fly out.
- Reduce Motion: no flights; the sign just shows.
- Looks: each look tunes its own accents, not just the ground. Black: page and ground #000000, ink F4F1EC, training FF6F52, kitchen F4B25E, routines EBA2B2, lists C6CF82, notes C6B7EE, money 97CBB2, sky FFB062 to F286A6. White: page FFFFFF, ground ECECEC, ink 121212, ink2 54514D, ink3 86827C, training C03C20, kitchen 9A6212, routines 9A4255, lists 536016, notes 5335B0, money 357059, sky BF6A22 to A33C62. Warm paper is today's light. All of them go through ThemeConcept.
- Tess reads her ground. TessSoul samples the luminance of what is under her frame (the page token plus whatever layer is beneath: the mosaic, text), at most every 0.5 s. Below 0.18 she uses screen with the dark paints, with core/mid alpha .8/.6, rising to .9/.68 toward pure black. Above that she uses multiply with the light paints, with a flat core/mid alpha of .80/.52 (normal blend, then a 30% multiply pass). So she is never pale on white or dull on black. The drawing itself is unchanged.

## Correction, Kaushik 12:14 PM (replaces section 4's parallax and slide, and the "fly home")
- Nothing moves when he swipes. No parallax, no follow, no slide. The swipe (horizontal, past 50 pt, on the space or the mosaic) only triggers the change.
- Everything transitions in place:
  - the old tiers fold away in place (clip from the top down, 0.26 s);
  - the new tiers reveal in the same spot (clip, no offset), staggered 200 / 280 / 360 ms, with their kind's entrance (digit flips, items dropping in, writing in);
  - the sign never moves: its tiles collapse where they stand, from the edges in (each shrinks to nothing with a 4 pt sink, 0.3 s);
  - 140 ms later the mosaic feeds in the new sign's tiles (the lending in the 12:12 addendum).

## Consistency and mosaic colours, Kaushik 12:18 PM
- One type system on every page (replaces section 1's two big faces):
  - big is always Outfit 200: 60 pt for short values ("2:10", "4", "6 of 14", "64°", "8 pm"), 44 pt for words ("Sunday", "Pack the charger", which may wrap to 2 lines);
  - mid is always Figtree 20 with exactly ONE keyword, the thing's own word ("Push day", "Groceries", "Mom", "trip", "Packing", "Clear", "Stretch"), 600 weight, 1.1x, with an accent underline (ink for tasks);
  - small is always Figtree 15, ink 3, never a keyword.
- Mosaic colours per look (the six base strips), through ThemeConcept:
  - Paper: today's.
  - White: cleaner and cooler: 222640, DEA88A, F2D8B2, E8B69E, 9E94CA, 646CAA.
  - Black: glowing but softened 22% toward 2E2C34: from 4E5896, D67C58, F0C68A, DE9676, 9C86D2, 6670C0.
  - System dark (151517): today's dark mix.
  - The Bayer edge always blends toward that look's page colour.

## Addendum, 12:24 PM PT Oct 23: Tess on light grounds (his "look at how bad Tess is looking")
On paper and white her three multiplied washes burned to a brown-black middle with grey edges. Fix in `SoulPalette` / `SoulRenderer` (TessSoul.swift), light looks only; dark looks keep screen exactly as built.
- Draw the six dabs into their own layer with **normal** blend (blue dabs first, then vermilion, then cadmium, satellites after their mains).
- Composite that layer onto the ground once normally, then once more with **multiply at 30%** opacity. That keeps the wet mixing he knows, without mud.
- Wash stops on light looks: core 0.80, mid 0.52 (replaces 0.8/0.6 and the pale 0.58/0.42).
- Plein paints a touch cleaner: vermilion D2502F, cobalt 3561C8, cadmium E0A21E (only inside Tess; Theme tokens unchanged). Superseded: Tess paints are in tess-215-final.md.
- Eyes on light: ink at 86%.
- Check on Plein, Porcelain, Celadon and the white look: no area of her darker than the eyes except the eyes themselves.
Board: https://claude.ai/artifact/VgyTXVBnXhMXW1ujG1qE1X (and Home board v22).
