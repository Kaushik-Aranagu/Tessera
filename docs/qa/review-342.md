# QA review 342: Design 42 glass tab lens (Builder A)

*QA, Oct 16, about 1:15 AM Pacific. PR #342, `ios/tab-lens`, head `fc42d69`, from `a370b81`. Static review (no Swift
toolchain in the cloud). Trial merge onto master: clean, 2 files (`Features/Home/HomeSpatialView.swift` +198 / -16,
clip `39-tab-lens.mp4`, 11.3 s, 590×1282). Design judges the feel; this is safety and "the hold never fires a tap".*

## Verdict: FIX FIRST (two small fixes, both in `PaintedRail` / `releaseLens`)

It is data-safe. Nothing writes: the deck copies are `.allowsHitTesting(false)` and `.accessibilityHidden(true)`, and
their `onAppear` work is visual only. A tap still swaps pages, and a quick tap can't form the lens: the hold task is
cancelled in `onEnded` and re-checks `isCancelled`. Two paths break Design 42, though, and one of them can leave
Home stuck.

### F1. A cancelled touch leaves the lens up and Home frozen

`touch(cell:)` cleans up only in `onEnded` (`HomeSpatialView.swift:510-520`). When the system cancels a drag,
SwiftUI doesn't call `onEnded`. That happens when he pulls down Notification Center or Control Center from the
tab row, which sits at the top of the screen, or when a call or Siri takes over, or when the app goes to the
background mid-hold.

When that happens:
- `lens` stays non-nil, so the pager stays hidden (`:112`), scrolling stays disabled (`:110`), and the shrunken,
  non-interactive deck stays on screen.
- `pressedAt` stays set, so the next touch skips the reset of `travelled`. That touch is then taken as a slide and
  release.

It recovers only when he happens to touch the tab row again.

**Fix:** clean up on cancel as well as on end. Two ways would work:
- Add `@GestureState var pressing` (`.updating($pressing) { _, s, _ in s = true }`) and run the cancel or release
  in `.onChange(of: pressing)` when it goes false; GestureState resets on cancel.
- Or reset `lens`, `deckScale` and `pressedAt` on `scenePhase != .active` and `.onDisappear`.

### F2. A hold with no slide changes the page

Design 42 §6 says: "A hold with no slide is a cancel: the same return, no page change, no haptic."

`holdLens` puts the lens under the finger (`:239-248`). `releaseLens` always opens `Int(spot.rounded())` (`:259-261`).
So if he holds a word other than the current page and lets go without sliding, the page changes, just as a tap
would. `lensFrom` is set at `:240` and never read, which looks like the intended return target.

**Fix:** remember whether the lens moved off its first word (or travelled past a few points after the hold). On
release without a slide, settle back to `lensFrom`, with no page change.

## Checked and fine

- **Tap path.** Travel under 10 pt with no lens selects the word under the finger (`:513-517`). After the 260 ms hold
  the lens takes over and `onEnded` releases instead of selecting, so a hold never also taps. Movement of 10 pt or
  more before 260 ms does neither.
- **Ticks.** `.tesseraFeedback(.selection, trigger: lensTicks)` fires once on hold and once per word change while
  sliding (`:86, 241, 253`). There is no tick on release.
- **Reduce Motion.** There is no shrink (`:246`) and release snaps without the grow-back (`:269-271`). The lens and
  the ticks still play.
- **Accessibility.**
  - Each word is an element with the button trait, `.isSelected` and an action (`:480-488`), so VoiceOver still
    selects.
  - The deck is hidden from accessibility.
- **Liquid Glass** is on the lens only, the navigation layer.
- **Data safety.** No LaunchFlags or ProcessInfo reads, no store writes, no project.yml change. No secrets. The
  DEBUG `-queueScript` task in a deck copy is guarded by `QueueRow.scripted`, so it can't double-play.

## Lows

- **L1.** The deck builds second copies of all four pages for the whole hold, which costs extra on an older phone.
  Builder A already flagged a possible one-frame overlap at the edges during the grow-back. Both are device checks.
- **L2.** The lens width falls back to 60 pt before `widths` is measured (`:432`). The first hold after launch may
  size the pill wrong for one frame.
- **L3.** The deck ground's "#0A0A0C" literal (`:233`) is Design's value. A Theme token would keep it swappable per
  look.

## Install-day check (after the fixes)

- Hold TODAY, slide to REVIEW, and let go: Review opens.
- Hold TRAINING from Today without sliding, and let go: Today stays (F2).
- Hold the tab row and pull down Notification Center, then come back: Home is normal and taps work (F1).

## Addendum: re-check at `9281b0d` (Oct 16, about 1:25 AM Pacific): PASS

The delta is one commit to `Features/Home/HomeSpatialView.swift` (+47 / -4), plus the clip re-recorded (18.4 s).

- **F1 closed.**
  - A `@GestureState touching` is set by `.updating` on the row's DragGesture. When it drops while `pressedAt` is
    still set, the touch ended without `onEnded`, which is a system cancel. It then cancels the hold task, clears
    `pressedAt`, and calls `onCancel` if the lens is up.
  - Normal ends never reach it, because `onEnded` clears `pressedAt` first.
  - `scenePhase` leaving `.active` and Home's `onDisappear` also cancel.
  - `cancelLens` returns to `lensFrom` through the same release path, so the deck, scale and lens all reset.
- **F2 closed.** `lensSlid` is set only when the lens crosses a word (`slideLens`). Release opens the word under the
  lens only if it slid; otherwise it settles on `lensFrom`, with no page change.
- **Design's must-fix.** The deck's `spot` is rounded, so one page sits in one place, and each word crossed springs
  the lens.
- The clip shows a hold from TODAY, a slide through REVIEW and KITCHEN, and a release on TRAINING that opens
  Training; then a hold from Training that ends back on Training.
- Data safety is unchanged.

Device check, not a block: confirm a pull of Control Center from the tab row mid-hold brings Home back whole.
