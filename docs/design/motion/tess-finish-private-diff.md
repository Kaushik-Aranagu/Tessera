# Private workout finish vs ordinary finish: the frame-by-frame diff list (board 48)

Source: design sheet 95 and tess-finish-hero-settings-paging.md (board 38). Goal: nothing in motion, timing, haptic, sound or layout tells a Private workout finish from an ordinary one. Only the visible words differ, and those words are fixed.

## Allowed differences (the whole list)
| Where | Ordinary | Private |
|---|---|---|
| Hero text | "Push Day A" | "Private workout" |
| Line under the hero | "13 sets, 54 min." then, if any, "A new best on Bench press." | "13 sets, 54 min." only |
| Receipt and Tess's line | "Push Day A, done." | "Private workout, done." |
The bests line may be absent on an ordinary finish too (no best that day), so its absence alone tells nothing; its fade-in (t = 520 ms, 220 ms) simply does not happen.

## Must be identical, frame for frame (QA diff: record both with the same fake clock, compare per-frame SSIM of everything outside the hero word and the line text; bar 0.99)
1. Screen transition in (normal 380 ms house spring or Reduce Motion 150 ms crossfade).
2. Hero rise (10 pt, 4 pt blur clearing, to t = 260 ms) and the count line fade (220 ms, 60 ms later).
3. The strike: starts 400 ms, 380 ms, same easing, same x-height, same colour (Obsidian inkSecondary); its length follows the hero's text width, so the lengths differ only because the words do.
4. Haptic: one `.success` at the strike's start, same time, same strength. No second haptic anywhere (no best haptic, no soft lock tick). This follows sheet 95 ("one haptic per moment, so nothing else buzzes") and the project rule of one haptic per moment.
5. Hero ink: full ink in both; no dimming, no lock glyph, no masked blocks, no blur held on any text.
6. Tess's soul: same reward beat at the strike (soul-signals section 4), no glance, pause, or beat for being private; same eye state, mouth, roam and pigment.
7. Drain after 4 s or any tap: same 300 ms crossfade to Home's resting line, same blur.
8. Layout: the line under the hero starts at the same y; the hero wraps by its own text width only (confirm "Private workout" wraps no differently at the largest Dynamic Type than "Push Day A" would; if it does, wrapping is allowed, motion is not).
9. VoiceOver order and timing: hero, line, then Tess's line; "Private workout" is read as that string, not as a longer description.
10. Reduce Motion / Low Power: both use the 150 ms crossfade and the finished strike fade-in (150 ms); haptic stays.

## Must not exist on the Private finish
A lock, a dimmed hero, a masked or blurred block, a reveal affordance, a different haptic, a pause before the strike, a skipped soul beat, a shorter or longer drain, or a different receipt shape.

## Checks for QA (three)
1. Record ordinary and Private on the demo day with `-demoTime`; diff all frames outside the text boxes: expect per-frame SSIM of at least 0.99 outside the hero word, the line text and the strike length (the same bar as the ten items above).
2. Count haptics: exactly one `.success` on each.
3. Read both receipts aloud with VoiceOver: same sentence shape, thing first.
