# Board against release 15 (Home, top bar, ask slot)

Design, Oct 18. I read the app code at c2193077 (release 15) against the sheets. I have not seen his phone, so this is from code, not from his screen. Each line says where it stands: BUILT, NOT BUILT, IN A PR (waiting on tests or review), or DRIFTED (built differently from the sheet).

## Why they differ
1. The board is the target, the phone is only what is merged. Approved work waits on test.sh, and the Mac was locked 10:44 AM to 4:14 PM Oct 18, so nothing merged then.
2. Several sheets are drawn ahead of any code. The big visible ones are the top bar and the colours.
3. Where sheets and code disagree, the list below names it.

## Top bar
- Sheet 73 A, one word up top, pull down or tap it for the area index: NOT BUILT. Release 15 still draws the four-word row Review, Today, Training, Kitchen with the glass lens from sheet 42 (Features/Home/HomeSpatialView.swift, `PaintedRail`; no area-index code exists). No open PR for it in the list I saw at 10:48 AM. This is the biggest visible gap.
- Screen-specific side swipes (sheet 75, Today's side page "The Day" and so on): not verified in code. I will check per screen.

## Home
- One plain line per thing, never cut text, "Thursday night" as the only day word where the painted stroke used to be: BUILT (Features/Home/HomeLineHero.swift:107). The day stroke lives one tap down in DayStrip.swift.
- Bolder titles with a colour per stage, key word first, done struck through (title accent): NOT BUILT. It opens as a PR after #895 merges.
- Area colours (sheet 86 C, `areaLean`): NOT BUILT. The only mention in code is a comment in Features/Kitchen/PantryColour.swift:4.
- Small faded images where not cluttered (his Oct 17 ask): NOT BUILT.
- Muscle figure: IN WIP (branch ios/muscle-figure, no PR yet). Food drawings are withdrawn on purpose, so nothing is missing there.
- Private rows at full ink with no dimming: IN A PR (#1031 kept links, #1032 recipe rows), PASS from Design, waiting on test.sh.

## Ask slot
- One-ask pattern (sheet 35, question beside the soul, always two ink words under it): PARTLY BUILT. The dated-lift ask has "Not now" (Features/Command/BottomChrome.swift:156-164). I have not checked that the set ask and the other asks use the same two-word form, so some may be DRIFTED.
- Offline phrases coming back as ghosts when the app opens: IN A PR (#1048), Design PASS conditional on a 3-phrase cap.

## Settings and paging
- Page turn setting (Slide, Turn, Soften, Rotate) and paged scrolling for long lists: NOT BUILT (no Rotate or page-turn setting in the code).

## Next
He names a screen and I check it line by line. I will also turn this list into a per-screen build order for Product if he wants.
