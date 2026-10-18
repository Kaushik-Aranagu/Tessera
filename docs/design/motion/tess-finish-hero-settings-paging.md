# Motion for board 38 (Private workout finish hero) and 40 (Settings 4 pages with Page turn preview). Oct 17, PM; (lab) = default for Design to overrule

## 38 Finish hero, ordinary and Private workout (sheet 95)
Same timeline for both; only the words differ ("Push Day A" or "Private workout").
| t | What moves | What stays still |
|---|---|---|
| 0 | Finish screen arrives with the app's normal screen transition (150 ms crossfade in Reduce Motion) | Title, context line, back word |
| 0 to 260 (lab) | Hero word rises 10 pt into place out of a 4 pt blur (the value-word rise), the line under it fades in 220 ms, 60 ms later | Everything else |
| 400 (lab, after the hero has settled) | The strike draws left to right across the hero, 380 ms, house curve. `.success` haptic once at the strike's start | No second haptic: the bests line, Tess's line and the receipt never buzz |
| 780 | Strike lands; the hero stays full ink (Obsidian strike in inkSecondary) | Hero colour never dims |
| 4 s or any tap | Done hero drains to Home's resting line: crossfade 300 ms with the line's usual blur | |
"A new best on Bench press." (ordinary only) fades in 220 ms at t = 520 beneath the count line; no pulse, no haptic of its own. Tess's soul may take her usual reward beat at the strike (soul-signals, section 4); it has no haptic of its own.
Private workout: identical motion, identical timing, identical haptic, nothing extra. The line under it is the count and time only ("13 sets, 54 min."). No lock, no dimming, no masked blocks, no beat that hints (soul behaves identically: no glance, pause or beat for being private). Receipt and Tess's line: "Private workout, done."
Reduce Motion / Low Power: hero and line crossfade together 150 ms, the strike is a 150 ms fade-in of the finished strike (not a draw), the haptic stays.
Acceptance: one `.success` per finish; frame check of the strike start and end (SSIM bar from tess-motion-check.md); ordinary and Private clips are frame-identical apart from the words.

## 40 Settings: four pages of six or fewer, with the Page turn preview (sheet 93)
- Paging follows sheet 90 and the chosen Page turn word. Settings is the one screen where the setting that styles the turn is on the page being turned, so the page turn plays with the currently chosen word; a change takes effect for the next turn, never mid-turn.
- Pinned: the title and context line. Rail on the right, four segments; ink segment slides 200 ms.
- Page turn row: "Turn, on". Tap opens the four words in place (row grows over 320 ms, the other rows part), each word previews once on a mini page ("Groceries, 24 to get.", two lines), re-picking the same word does not replay (R4). Preview runs at the real option's timings (spec: tess-page-turn-motion.md), one mini page, 1 s hold at the end, then settles. Picker feedback is the only haptic; the preview has none.
- Whose swipe on Settings: a stepper row steps (sheet 90b), a name or empty space turns the page, a focused field never turns it. A row that opens (Tess asks Claude, receipts) keeps its horizontal swipe.
- Reduce Motion / Low Power: the mini page and the real turn are the 150 ms crossfade; the row's open/close is a 150 ms crossfade of height-free content (no growing).
- Error: a setting that did not save keeps the notice from tess-pantry-lean-notice-motion.md item 42 under its row; paging never hides it (the page holding the failed row stays; no auto-turn).
