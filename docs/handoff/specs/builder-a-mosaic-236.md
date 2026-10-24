# Home 236: the mosaic as a widget stack (Design, Oct 23-24, from relays)

Boards: https://claude.ai/artifact/DygjFLo442RxyE1kmn4rJM (Home 236 v2, approved by Kaushik: "this is what I want, exactly like this on the phone"). Keep the same frame, edge and whole tiles. Every earlier mosaic feature (200, 201, 204, 209, 213 and the 214 keep-list) still plays on top.

Kaushik also wants: the mosaic blended into the page like earlier. Restore the 202 Rev 3 dithered edge and colour ramp if v2 lost them. Pixel art lives on the Home mosaic only. NO glass lens (cancelled). No dots, labels or counters on any swiper.

## Faces
- Gallery: the 214 scenes, a new one each turn, picked by Tess on the phone (Core's MosaicScenePicker).
- Weather (always present): a pixel scene with the temperature and next change in 218 pixel numerals. Until Core's source lands and he approves it, it shows the on-device sample.
- Place (more than 80 km from home): a pixel skyline by kind of place plus local time. The place name shows only while he holds the face. Location kind is never stored, logged or backed up.
- Context faces (shown first while live): Workout (lift mark and rest timer), Cooking (step and its timer), Shopping (at a store or when he opens To get: count and next 3 items; stays Off until location is approved), Today (the next thing).

## Turning
- Auto-turn every 5-10 s on the line clock (random within), never in the same second as a line flip. A live face gets 2 of every 3 turns; each turn uses a 200 changeover.
- Swipe follows the finger 1:1 and commits past 35% or on a flick with a light impact. A touch pauses auto-turn for 30 s. The next face peeks once. Vertical swipes also page.
- Reduce Motion: plain swap every 10 s. Low Power: swipe only. Quiet hours: gallery and weather only, every 20 s.
- Tap: a face opens its room.
- The swipe lives on the MosaicSlot itself (GestureKit/stackCommits), NEVER on the Home page (#1391 removed a page-level drag that bled into the one-thing list). Reuse pageDirection for the wipe direction. Face swipes and lean stay inside the mosaic frame +8.

## Sign (the one-thing sign)
- 20x20 mosaic tiles (80 pt), centred on the big and mid tiers. Edge tiles keep 33% of their source colour. Builds from the bottom row up: 6 ms stagger, 420 ms arc. Every 4-7 s one tile trades with the mosaic. New drawings.

## Settings
- Settings > Home > Mosaic: one switch per face plus "Turn by itself".

## Tests
- Add UI tap tests (G13) for the face taps alongside the swipe (a plain tap must reach the face; see the apps-list tap bug).

## Privacy and walls
Never show money amounts, health, body or calories on Home or in widgets; private items use ObjectPrivacy.shownLabel; calendar text stays on the phone only; only Tess takes touches on her layer.
