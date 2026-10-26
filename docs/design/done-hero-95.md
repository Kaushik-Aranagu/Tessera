# 95. The Done hero and "Private workout" on the finish screen

Spec only. The finish screen is one moment: the day's workout is done.
- **Hero**: the workout's name at Hero size, "Push Day A". It strikes through once (the house done), 380 ms, one `.success` haptic.
- **Under it**, one plain line: "13 sets, 54 min." Then, if any: "A new best on Bench press." (never "record").
- **A private workout**: the hero reads "Private workout" with the same strike, same haptic. The line under it is the count and time only ("13 sets, 54 min."); no exercise names, no bests, no weights. No lock, no dimming, no masked blocks.
- Receipts and Tess's line use the same string, thing first: "Private workout, done."
- The Done hero drains to Home's resting line after 4 s or on any tap; one haptic per moment, so nothing else buzzes.
- Obsidian: the strike uses `inkSecondary`; the hero stays `ink`.
