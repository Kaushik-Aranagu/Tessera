# Review #662 (Builder A: stroke her, §6 beat, she wears the day, 07:00 quiet end, cut-wake-on-live)

Head 2efdd13a, merge-tree clean against master 98c9a93d. Static review.

## First pass: the band strip (coordinator's question). FIX FIRST.
SoulStrokeGesture adds `Color.clear` of 84 pt (bandAbove 43 + bandBelow 41) with `.contentShape(Rectangle())` and `.gesture(drag)` as a `.background` of the full-screen BottomChrome frame, padded 32 from the bottom. BottomChrome sits above the NavigationStack in RootView's ZStack.

1. **It swallows page taps and scroll starts.** The page's safeAreaInset reserves only 56 pt, so page rows live under about the bottom 60 pt of the strip (roughly y 724 to 784). The strip is the topmost hit-testable view there, so a tap or scroll that starts in it never reaches the page. The code comment, "nothing of the page lives in Tess's band", is not true at 724 to 784. Chrome content itself is unaffected, because the strip is a background and the chrome is drawn above it. Ask bar and tab taps keep working unless the ask bar overlaps a spot where the strip is on top.
2. **It is not gated.** `refusesStroke` (page not Home, working, listening, ask waiting, pinned) is applied only in the router. The strip still takes the touch on every page, so off Home the band is dead for scrolling and tapping even though no stroke can happen.
3. **Geometry is hard-coded.** The strip is fixed (bottom padding 32), while the hit test follows `dockCentre`. On a different safe-area inset the two disagree. 736 to 820 on a 779 dock does not equal the strip's placement (about 724 to 808 with a 34 pt inset).

Fix asked: attach the strip only when Home is up and `!refusesStroke`; either drop the strip and use `simultaneousGesture` on the page container, or make the strip `allowsHitTesting(false)` and put the drag on a layer that does not own touches. Position from `dockCentre`, not a constant. Add a UI test that taps and scrolls a row in y 724 to 784 on a non-Home page. Needs a sim check, since this is static reasoning.

## Rest of the diff: clean
- Router: strokeEntered/Left/Ended, refusesStroke, beat merge (two beats inside 940 ms become one, wear always counts), beatAfterListening, rollWearDay at 04:00 with a one-minute dry-away, taskUndone clamped at 0, liveOpened cancelling a wake in play, isQuietHour 23 to 07 for rest and for the wake guard. All trace correctly.
- SoulBeat math, SoulRipple, the Reduce Motion rules (colour stays, motion goes) and the haptic (one soft tick per stroke) match the sheet.
- Lows: (a) the same drag is attached twice (strip and simultaneousGesture) sharing `began`, so a touch in the strip fires both; benign today (entered is guarded, the second ended returns false) but fragile. (b) `began` is reset only in onEnded, which SwiftUI skips on a cancelled gesture; use @GestureState. (c) A pan that enters her and returns to the same side still gets the tick and ripple; the spec says tick on entry, so fine if intended.

**Verdict: FIX FIRST for the strip (items 1 to 3 above). Everything else PASS. Design PASS at 2efdd13a already logged. Re-check on the next head.**

## Delta 10282c95 (re-pinned; merge-tree clean, master merged in)
Closed: the strip is now a background behind her line and UNDO, shown only when model.path is empty, the command surface is closed and !refusesStroke, placed from dockCentre (the position maths checks: the band is centre-43 to centre+41). One drag, @GestureState, reset on cancel (lows a and b closed). The new UI test covers a pushed page.

**Still FIX FIRST: the strip now sits on Home, where it blocks the same things.**
1. Home's pages are one full-screen horizontal ScrollView (HomeSpatialView.swift, `ScrollView(.horizontal)` over `Page.allCases`). The strip is the topmost hit-testable view in y 724 to 808 and owns an exclusive `.gesture(drag)`, so a side swipe that starts in the band never reaches the ScrollView. That breaks the side-swipe principle (every screen has one) in the bottom 10 percent of the screen, and nothing tests it.
2. Home's page content reaches into the band too (dockClearance is 48, footLift 56, so content ends near y 790). Taps on a link line or word in 724 to 790 hit the strip first.
3. Losing the `simultaneousGesture` means a pan that starts on her line or UNDO no longer strokes her (the line takes the touch). Minor.

Fix asked: do not own touches. Put the drag as a `.simultaneousGesture` on the RootView container that holds the NavigationStack and BottomChrome (the tracker already rejects any start outside the band or inside her hit area), and delete the strip. A simultaneous gesture on an ancestor sees the touch without taking it from the page's ScrollView or buttons. Then a UI test: on Home, a horizontal swipe from y 760 changes the page, and a tap on the foot link at y about 760 opens it. Keep the existing pushed-page scroll test. Static reasoning; the Mac run confirms.

**Verdict on 10282c95: FIX FIRST (Home).**

## Delta 62ad9cc7: FIX FIRST still
Master merged in; the strip is unchanged. SoulStroke.swift still puts a Color.clear strip (contentShape Rectangle, .gesture(drag)) in the chrome's background whenever isHome. That strip owns touches across the full width at the band (y 736 to 820) on Home: the Home side swipe, page taps near y 760 (foot links) and the horizontal ScrollView pan all start inside it. Only the pushed-page case was fixed (isHome false off Home), and the one UI test added covers that case only.
Needed: drop the strip; attach the drag as .simultaneousGesture on the RootView container (it already reports without owning), keep isHome and refusesStroke guards; add a Home UI test: horizontal swipe from y 760 changes the page, and a tap on the foot link near y 760 opens it.
