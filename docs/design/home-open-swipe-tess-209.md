# 209 The mosaic wakes on open, swipes to widget pages, Tess as built (Oct 23, 11:50 AM PT; coordinator rulings 11:25 AM)

Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp (version 18). Kaushik's 11:16 AM ask:
- the mosaic reacts, differently, whenever the app opens, fresh or from the background
- swiping across the mosaic left or right changes it to other screens: weather and other widget-like things, while it keeps its own personality
- keep the older apps layout (205 vertical list), drop the 208 dial, make room for Tess, and make Tess the earlier soft, real version

Everything here ships ON by default. 208's dial and simplified Tess are rejected; never rebuild them.

## 1 Apps list: 205 as built, no label
- Keep the 205 list (#1329) exactly: 3 rows of 40 pt, wraps round, the pick at 1.3x in its accent with the fact line.
- Remove the "Apps" caption. Nothing replaces it.
- Above the list, an 80 pt empty band ("Tess room") for section 2. The list moves down by that band; Next stays where it is.
- 206 glances keep firing 240 ms after the list settles on an app.

## 2 Tess on her own layer
- One top overlay over the whole Home (above the mosaic, list and sheets), hit-testing off except on Tess herself.
- She sits at the top of the Tess room, 22 pt from the leading edge, with her one line beside her (Figtree, primary, sentence case, wraps to 2 lines, never "...").
- Draw her with TessSoul exactly as it exists (Features/Tess/TessSoul.swift): six dabs (3 mains 76x70, 3 satellites 46x42, spread .65), radial wash through the shape paths, blur about 4x scale, multiply on light and screen on dark, the 9 s lift and 6.4 s breath, eyes 8.4 pt apart with the 160 ms blink. No new drawing, no flat circle, no outline.
- Size: 96 pt canvas, visible body about 64 pt wide. Never faded.
- Tap: she pools together (1.8 s), the line moves to her next thought, the mosaic plays the "tess" moment. One soft haptic.
- Reduce Motion: still dabs, no lift, no blink; the line swaps plainly.

## 3 The mosaic reacts on every open
Pick one by how long the app was away (scenePhase active; the time since last background):
| Away | Reaction | Length |
| under 2 min | ripple from the middle | 0.9 s |
| 2 min to 3 hr | the tiles flip from the last scene they showed to now, row by row | 1.4 s |
| first open after 4 AM local | night falls away into the day, top to bottom | 2.2 s |
| 2 days or more | dusty pixels gather into today; the "back" mood | 2.4 s |
| cold launch | gather from night after 500 ms | 1.8 s |
- One reaction per open; never stack. A moment already playing wins.
- Reduce Motion: no reaction, the current scene just shows.
- No haptic on open.

## 4 Swipe across the mosaic: pages
- A horizontal swipe that starts on or within 30 pt of the mosaic, with |dx| over 40 pt, moves to the next page (left swipe) or previous (right). Wraps round. Vertical scrolling is untouched.
- Pages, in order:
  1. The mood (the mosaic's own life, the default)
  2. Weather: a pixel sun with turning rays and the temperature in Outfit pixels. Sample only until Apple WeatherKit is entitled (paid account): the sample lives in memory only (never stored, logged or backed up) and the caption labels it "Weather, sample until Apple weather". Coarse location only, never paired with his data, never sent anywhere.
  3. Next: the time to the next thing ("2:10") in that app's accent, text only; its pixels leave (fade toward the ground) as the minute counts down. No line under it. Caption "Push day in 2 hr 10 min".
  4. Week: the 7 day letters (M T W T F S S) as pixel text in ink weight, done days and today at full ink, others at 42% toward the ground, and a 3-tile mark in Training colour under each done day. No squares. Caption "This week, 3 of 5 training days".
- Change: a 0.5 s wipe in the swipe direction. The caption under the mosaic changes with it (secondary, one line).
- The rim blend (202 Rev 3) mirrors each page's ground only, never its motif.
- Pages are quiet: the sentence never changes for them. Moments (206, 207, Tess) still play over any page and hand back to it.
- The page resets to the mood on the next open from the background over 2 min.
- Never on a page: money amounts, health, body, calories or calendar titles; walled things stay masked.
- One light haptic per page change. Reduce Motion: plain swap, no wipe.

## 5 Owners
- B: section 1 (list label off, Tess room) and section 4's swipe on Home.
- A: MosaicView page scenes (weather, next, week), the wipe, the open reactions in section 3, and the Tess overlay.
- Core: the away-time cue for section 3 and a page-facts source (next item time, week done count) through MosaicFacts. Weather waits on the entitlement.

## Reviewer guards
- No dial code ships. No "Apps" caption.
- Tess uses TessSoul unchanged; any other drawing fails.
- Pages show no money, health, body or calendar data; weather is sample until WeatherKit.
- Reduce Motion paths are plain swaps.
