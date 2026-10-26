# 200 Departure mosaic: board sentence, mosaic moods, Tess picks (on top of 199)
Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp . Kaushik picked it Oct 22 10:09 PM PT (cmsg_01VTPva3JGXrfvetgUvAWE7MGgCc9jkPdR1nkn8F5NgSBV, cmsg_01VTPva3JGXrfvetgUvAWE7MMuP2f15MioNcD3695GHRFB).
Review switch homeMosaicMoods, default Off (needs homeMosaic).

## Builder B: departure-board sentence + smaller layout
- The sentence is 21/400 Figtree, app words 500 in their accent, numbers Outfit 300, gap 3 pt, top inset 64 pt. Gutter 24. The mosaic block is 200x112 pt, right-aligned to the gutter, 14 pt under the sentence (his 10:34 PM: smaller pixels, narrower).
- When the lines change, each changed character steps forward through " a-zA-Z0-9:,.'" to its new one, at most 9 steps (skip evenly), 52 ms per step. Each step is a scaleY 0.08 -> 1 over 70 ms from the middle hinge. Start delay = (line x 5 + index) x 14 ms. Unchanged characters stay put. One soft haptic when the last character lands, and only while Home is on screen.
- With Reduce Motion: a 150 ms crossfade of the whole line, no flips.
- VoiceOver reads the final sentence once.

## Builder A: MosaicView, finer pixels, moods, changeovers
- Grid: step 4 pt, tile 3.2, corner 0.7, so 50 x 28 tiles. Lean radius 36 pt, up to 5 pt. Ripple radius 120.
- Edges blend by dithering, never by blur or fade. Tiles less than 4 from an edge are kept with a probability of (e+1)/5 (hash-fixed). A kept edge tile mixes toward the page ground by (1-k) x 0.8 and scales by 0.6 + 0.4k, where k = 0.55 + e x 0.1.
- Moods (enum MosaicMood):
  - morning: a lilac -> peach sky, horizon at 66%, a gold pixel sun r 4.6 rising over the session, sparkle on the water.
  - day: the 199 field.
  - golden: amber -> rose -> plum, a sun r 5.2 at 78%/62%, a slow horizontal light streak.
  - running: the day field plus a current toward the now column every 2.2 s. Done sets are Training-accent tiles; remaining sets are ink rings.
  - rest: still water, horizon at 55%, the reflection shimmering ±1.5 columns.
  - back: dusty, scattered tiles gather over about 2.4 s.
  - done: an evening field with one small pixel firework per finished app, in its accent, staggered 700 ms and repeating every 5.2 s, fading after 2.2 s.
  - rain: a grey-blue field with drops down the columns (WeatherKit later; Off until the entitlement exists).
  - night: deep indigo, a faint aurora band, about 4% twinkling stars, a crescent moon r 4.8 (cut r 4.5, offset -1.4/+2.3), a shooting star every 7 s, and what was done today glowing low in the now column.
- Changeovers (MosaicTransition), each mood with a default:
  - wave: delay = distance x 20 ms, 520 ms ease-out cubic, bump sin(p·π) x 0.45.
  - fall: each column offset by hash x 380 ms plus 26 ms per row from the bottom; the new tile drops in over 360 ms with ease-in.
  - wipe: a stair diagonal in 3-tile steps over 1 s, its front dithered.
  - dissolve: a hard per-tile swap at hash x 900 ms.
  - gather: hash x 700 ms, then 500 ms.
  - Defaults: morning fall, day wave, golden wipe, running wave, rest dissolve, back gather, done wave, rain fall, night dissolve.
  - With Reduce Motion: a 150 ms crossfade, with no lean and no ripple.

## Core: Tess picks the mood (MosaicMoodPicker, on the phone only)
- Inputs: MosaicFacts (now, sun times, a running process, a planned rest day, days since last open, finishedToday vs. what was due), and the weather later.
- Order:
  1. running
  2. done (all of today finished, until 10 PM)
  3. back (first open after 3+ days, once)
  4. rest (a planned rest day)
  5. night (after 10 PM)
  6. golden (sunset within 30 min)
  7. morning (within 60 min after sunrise)
  8. rain (later)
  9. day
- Hold each mood at least 10 min, except running and done.
- The sentence lines come from the same pick, with words already on the phone.
- Nothing goes to Claude. No mood cue, health, calendar, body, calorie or walled title ever leaves the phone, and the mood doesn't use asksClaude at all. Weather would use Apple WeatherKit with coarse location only, never paired with his data.

## QA answers (Oct 22 10:40 PM PT)
- Tile colour changes inside the mosaic (aurora, streak, rain trails) are not "fades". The firework accent steps down in 4 hard steps of 550 ms (1, 0.66, 0.33, 0).
- No centering: anchor the tiles top-right to the gutter; the 0.8 pt remainder sits on the left and bottom, under the dithered edge.

## Living size (his 10:49 PM, cmsg_01VTPva3JGXrfvetgUvAWE7MWWHFAZavmEdt7BnVrFDEHv): supersedes the fixed block size
- The frame reserves 248x160 pt (max 62 x 40 tiles at a 4 pt step), anchored top-right. The visible window is cols x rows per mood: morning 50x28, day 48x24, golden 60x30, running 40x28, rest 62x20, back 36x22, done 56x36, rain 50x30, night 62x38.
- The window size eases toward its target at 0.06 per frame (about 1 s) and snaps to whole tiles, so it grows pixel by pixel. It breathes ±1.4 columns (period 4.3 s x 2π) and ±1.2 rows (5.9 s x 2π).
- The dithered edge is computed on the live window, with the hash keyed on the absolute column so the edge stays stable while it grows. Mood scenes lay out against the live window.
- Reduce Motion: snap to the target size, no breathing.

## Sentence segments (answer to Builder B, 11:14 PM)
- Mood and moment lines come back from Core as segments (text / app word + HomeApp / number), the same type as the day sentence. App words are 500 in their accent and tappable (1 pt underline while pressed); numbers are Outfit 300; Tess's words are never cobalt; masked items are plain ink and not tappable; flips keep each segment's style.
