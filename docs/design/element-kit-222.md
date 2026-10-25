# Item 222: The element kit (Oct 23, 4:05 PM PT)

Kaushik, 3:48 PM: "think about the various element designs, like scrolling through a page, or scrolling through a list of selections... the radial things, or the dials, or scroll wheel things". At 3:54 PM: "your job would be to come up and think through different creative elements and how we can integrate them into different apps and different scenarios".
Board: https://claude.ai/artifact/MmVpRetTCAxZ2iMxy1vB7r (each element is live).

Every element is ink and type only (no cards, pills, bars or filled dots), has no alpha fades, gives one selection tick per step, uses MotionPolicy springs, steps plainly under Reduce Motion, and is an adjustable element or a list under VoiceOver.

| Element | What it is | Values | Where |
|---|---|---|---|
| Drum | words on a cylinder past a reading line | 24° per item, radius 84 pt, 34 pt of drag per item; on the line: ink, Outfit 300, 28 pt; neighbours ink 2, then ink 3; the reading line is 1 pt in the room's own accent (Routines on the board) in the accent; it springs to the nearest item with flick carry (velocity x 6) | start time, servings, rest between sets, repeat rule, reset rule, due day |
| Thumb arc | a quarter circle anchored at the bottom-right corner, radius 180 pt | the unset part is a 1 pt edge hairline; the set part is 2 pt in the accent; the handle is a 28 pt ink stroke across the arc; 0 to 60 in steps of 5; the value is Outfit 200 at 64 pt, top left | cook timers, focus minutes, live set weight one-handed |
| Lens | a list read through a lens at one third of the height | 34 pt rows; under the lens 1.38x, ink, 600; neighbours are pushed 10 pt apart; further rows ink 2, then ink 3; it snaps to a row with velocity carry | Recipes, Library, notes in a thing, Runs, Browse |
| Page turn | long lists as pages of six (his Oct 17 ask) | swipe 40 pt or more; the old page goes, the new rows slide 22 pt under a clip, 280 ms, 30 ms apart; the last line reads "8 more, swipe up" | Pantry places, long lists, Log, Spending |
| Fold | one more dimension by pinch | the same tiles regroup from days (12 x 7 grid) to weeks (a stack per week) to months; 520 ms, staggered by weekday and week, with a 14 pt arc lift; the knob word Days, Weeks or Months taps through | Training log, habits, Routines tide day to week, Money shapes |
| Word strip | a sideways run of words | the middle word is 21 pt, 600, ink; neighbours 16 pt ink 2; beyond them ink 3; 104 pt apart; it snaps with flick carry; no blur and no underline bar | Plan days, Kind knobs, Recipes' week, month in Money |
| Thread | Daily's signature, pulled like a cord | one 1.2 pt edge line at x 28; the current step has a 3 pt accent stitch, 26 pt long; the step is Figtree 500 at 32 pt; the next steps are 17 pt ink 3; pull down past 60 pt to advance, and the step strikes and rises out under a clip | running routine, cook steps, live sets |
| Pressed number | numbers as instruments (131 §2b) | holding the top half climbs and the bottom half falls, starting at 380 ms, then speeding from 320 ms by 0.82x per step down to 60 ms; a flick steps once; "was 185" shows for 2 s | set weight and reps, Pantry amounts, list quantity, a bill's due day |

Money uses only the drum, fold, strip and pressed number on its own pages. It never shows an amount outside them, and nothing here leaves the phone.
Kitchen dark is C49A5E on the board (sheet 221).

## Reviewer fixes (4:00 PM, folded in)
- **Lens:** a list reader only: Recipes, Library, notes, Runs and Browse. Never on Home's apps list. It stays at 1.38x with no fisheye, rim or highlight arc.
- **Thumb arc:** anchored at the bottom-left corner, clear of Tess. The value moves to the top right. It shows only while a value is being set: it comes out from the corner under a circular clip in 0.26 s on press and goes back 0.6 s after release, so it never reads as a progress ring.
- **Fold:** tiles are presence marks only, with no intensity, colour scale or numbers. Any reading goes in the sentence. Money shows no amounts.
- **Pressed number:** each change goes on the op-log Undo (10 s), alongside "was 185". VoiceOver gets an adjustable element with fixed steps. With Reduce Motion each press is one step, with no acceleration.
