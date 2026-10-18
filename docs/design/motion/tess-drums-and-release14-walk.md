# Board 49 (Money dial and Reading drums) and 50 (Release 14 motion checks for the walk). Oct 17, PM; (lab) = default for Design to overrule

## 49 Drum motion: Money dial (design/money-dial.md) and Reading page drum (design/reading.md)
Both are the weight dial's siblings: tabular numerals on 100 pt (whole units, pages) or 60 pt (cents) rows, masked to 25% at the edges, current row full ink. One motion model for every drum, parameters per drum:
| Drum | Row | Coast | Tick | Release writes |
|---|---|---|---|---|
| Money whole units | 100 pt | ease-out cubic about 620 ms | `.selection` per number | nothing until Log |
| Money cents | 60 pt | drag with momentum, same cubic | `.selection` per step | nothing until Log |
| Reading page | 100 pt | ease-out cubic about 900 ms | `.selection` per page | `SetBookPage` on release; Tess "Dune, p 168." |
Gaps the sheets leave (lab defaults):
- **Tick rate cap.** A flick across 40 numbers would buzz 40 times. Cap at one `.selection` per 40 ms (25 per second); ticks beyond the cap are skipped, never queued, and the tick on the landing number always plays. This keeps "one haptic per moment" honest for a coast.
- **Settle.** The coast ends with a 90 ms snap to the row (house spring, no overshoot), no extra tick.
- **Live follow.** "Log £38.20" and the context line number change in place with no animation (no roll, no count-up); a currency change rolls 380 ms (sheet).
- **Landing haptics:** Money: `.impact(medium, 0.8)` once on Log, none on SKIP. Reading: none on the drum release (the ticks were the haptics); `FinishBook` hold: `.impact(medium, 0.8)` once at the bloom.
- **Reading glint:** one 760 ms soft-light sweep on arrival; Reduce Motion replaces it with a `.selection` (the sheet). Keep: that is the only motion-to-haptic swap, and it counts as the arrival moment's one haptic.
- **Reduce Motion / Low Power:** drums step with no coast and no snap; the z-zoom is a 150 ms crossfade; the fold-up after Log is a 150 ms fade; ticks per step still capped at 25/s.
- **Soul:** quiet; no beat on the drum, one reward beat on Log and on Finished, none for a Skip.
- **Private:** a money amount is a Private money value where the wall applies; the drum motion is identical.
Acceptance: a 40-number flick plays at most ~25 ticks/s and always ticks on landing; one `.impact` per Log; Reduce Motion drum has no coast.

## 50 Release 14: motion things to feel after install (what he should see and feel)
Release 14 is mostly walls, masks, parsing and copy (qa/release-14-gate-table.md: #564, #868, #871, #884, #885, #886, #890, #895, #912, #913, #917 candidate), so little of it moves. Walk list, in order, each one line:
1. **#662 Home stroke (owed from before):** on Home, a stroke of the day: touch her and the tap gives one soft tick; the swipe never starts a drag. If the tick is missing or doubled, FIX FIRST.
2. **#786 and #806 Lists swipes vs side swipe:** on a list, swipe a row sideways: the row's own action runs and the side does not open; swipe from the screen edge: the side opens with one `.selection` on landing. Never both.
3. **#871 starter lists / CopyList receipt:** copy a list: Tess's line "<name> copied." with UNDO appears; the copy does NOT open by itself; tapping the receipt opens it; UNDO removes it.
4. **#917 Pantry (no ochre):** the Pantry state words read in ink; tapping a state word cycles it with one `.selection` and a 160 ms word crossfade; nothing is coloured ochre.
5. **#884 / #895 / #912 / #890 (walls, masks):** no motion change expected. A Private title or item must look and move exactly like any other (no pause, no glance by the soul); if you see her do anything different for a private thing, FIX FIRST.
6. **#886 parser, #885, #913:** no motion change; just confirm nothing flickers when a recipe or link lands.
7. **Soul sanity (any screen):** at rest she blinks and breathes; eyes setting off by default means nothing to see unless it is turned on.
8. **Reduce Motion and Low Power:** with Low Power on, screens crossfade in 150 ms and sides do not slide (decision Oct 17, PM).
9. **Haptic sanity:** one finished item gives one `.success`; a failed save, if one can be provoked, gives one soft `.warning` (once the Haptic case lands).
Any FIX FIRST becomes a roll-forward fix (release-14-checklist.md). Items 1 to 3 are the ones owed; 4 to 9 are a quick look.
