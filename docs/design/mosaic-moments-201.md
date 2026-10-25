# 201 Mosaic moments: weather, announcements, Tess, app events (on top of 200)
Kaushik 10:50 PM PT Oct 22 (cmsg_01VTPva3JGXrfvetgUvAWE7M3RufkRB4emxp3c1CPUhrR1): "cool ways. Like weather, announcements and tess and other stuff... transformations and transitions should be cool and smooth and awesome".
Board (Moments section): https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp . Switch homeMosaicMoments, default Off (needs homeMosaicMoods).

A moment interrupts the mood: it takes the window (its own size), runs, then hands back to the mood with a dissolve (or a fall after an announcement). The sentence turns over on the departure board both ways. A new moment replaces a running one, and a mood change cancels it.

## Builder A (MosaicView, MosaicMoment)
- snow 50x32, enter fall, 9 s: a pale blue-grey field, 2 flakes per column drifting ±0.8 col, a drift building 1 row per 1.5 s up to 5.
- fog 56x24, dissolve, 8 s: the mood under mist mixed in 4 steps (0.25 quantised) of 0.55 + 0.35 sin(j·0.13 + t/1.8 s + i·0.35); tiles shrink by up to 15%.
- wind 62x22, wipe, 7 s: tiles sway dx = sin(t/260 ms + i·0.5 − j·0.25) x 1.8 x gust; 7-tile light streaks run across about a third of the rows.
- storm 56x34, fall, 8 s: dark rain; every 3 s a pixel bolt (a random walk of ±1.2 per row from a column at 25-75%) shows for 260 ms, with a 90 ms field flash at 0.55.
- heat 50x26, wave, 7 s: rows sampled ±0.8 by sin(t/240 ms + j·0.7), a warm 18% tint, dy ±0.9.
- announce 62x22, wipe, runs until the text has crossed: the mood steps back 55% toward the ground. The text is rasterised from Figtree 600 at 12.5 pt into 14 tile rows (alpha > 0.47) and crawls right to left at 15 tiles/s. The app word is in its accent, the rest in ink. Then the tiles fall back into the mood.
- tess 40x24, gather, 6.5 s: the mood steps back 50%; Tess's two eyes form in tiles (2 x 5 each, at 40% and 60% of the width) in Tess cobalt (Theme.tess 2E6DA4 / 9DBFE6), look ±1 col, and blink (1 row for 150 ms every 2.9 s). Eyes only: no orb or skin.
- timer 32x32 (it squares up), wave, 4.2 s: three square (Chebyshev) pulses 480 ms apart in Kitchen, with the centre 3x3 held in Kitchen.
- finished (keeps the mood's size), 3.2 s: one accent tile flies from the top-right (under the sentence) to the now column at 62% height over 700 ms, then a square sparkle grows outward 1 ring per 90 ms to 3.
- Reduce Motion: the moment shows as a still frame with a 150 ms crossfade; no crawl (the sentence carries the words), no sway, no flash.

## Builder B
- The sentence lines per moment come from Core, and the departure-board flip runs on enter and on return. One soft haptic per moment on enter, except announce, which gets a tick, and timer, which gets rigid.

## Core (MosaicMomentSource, on the phone only)
- Sources:
  - weather: WeatherKit later; Off until the paid entitlement; coarse location; never paired with his data.
  - announcements: the next timed thing at 15 min, from NowRanker.
  - tess: an on-device suggestion is ready.
  - timer: a kitchen timer finished.
  - finished: an op-log finish.
- Rules: at most one moment per 10 min except timer and finished. None during quiet hours unless a timer finishes.
- Nothing goes to Claude, backups, logs or widgets. Walled titles are masked in announcements ("Private workout"). No money amounts. Health, body and calories are never shown.

## Hand-backs (11:35 PM)
- New changeover melt: each column starts at hash x 420 ms + 18 ms per row; over 520 ms the old tile drops dy = q^2 x (rows − i + 4) x step x 0.5 while shrinking to 30%, and the mood's tile grows in under it (scale q).
- Return paths: snow, storm and announce melt (the letters drip down into the mood); fog dissolves; heat waves back; Tess gathers back; timer and finished dissolve.

## More moments (Oct 23 7:05 AM)
- best, 44x30, wave in / melt out, 4.6 s: the mood steps back 40%; 7 Training steps (5x2 tiles, rising 3 rows every 5 columns) appear one per 120 ms, then a plus-shaped pixel star (centre warm white) blinks at 180 ms on/off at the top. Words: "A new best." (never "record"). Private workouts stay masked.
- reminder, keeps the mood's size, dissolve, 3 s: the window knocks 3 times (dx up to 2 pt, 110 ms each at 300/560/820 ms), and a 2-column band just inside the right edge lights in the app accent on each knock, then holds at 70%.
- delivery (at the door), 50x26, wave, 4.4 s: a 9x7 parcel (accent outline plus a centre tape column, fill 55% to the ground) slides in from the right over 900 ms ease-out, bumps 1 row, and shows two dust tiles. Kitchen for groceries.
- Core sources: best from TrainingLedger PRs; reminder from Routines/Tasks due now; delivery only from his own in-app 'arrived' mark (no outside service).
