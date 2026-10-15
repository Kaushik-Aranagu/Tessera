# iOS Builder A (Mac, current iOS build thread)

*Owns: Workout, Exercise, Plans, Routine, Widgets, DesignSystem.*

**Done:** #108 (PaintKey ink rewrite: every key is a stroke word, dead keys removed; D4, rest survives an app kill). ship-2 (#91): v1 slices 8 to 12, G1, a haptic, P2, B3, the launch note, and the mic hidden.

**Now (until the 2:05 PM Pacific cut):** the edit-set steer. After the final build, run gym-flow D, E and H plus `regression.md` on the phone.

**Next:**
1. #109, tap a logged set to edit it. Done when it's merged and the Today-style finger test passes on the phone.
2. Swap WorkoutTessBar for the Tess soul in the workout, so Tess looks the same everywhere. Done when the workout uses the soul-in-the-corner capture, with no separate bar.
3. Design's audit rows for ExerciseStrip, SwapPanel and WeekPage (`docs/design/audit-build-1.md`). Done when each row is fixed and recorded.
4. QA's fix: rest persists after a swap. Done when swapping an exercise mid-rest keeps the rest counting after a kill, with a test.
5. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). Start once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder A's screens (Workout, Exercise, Plans, Routine, Widgets) uses Design's replacement language and the audit's rows for those files are ticked, with a recording. Put the shared button style in DesignSystem first so Builder B and Core can reuse it. Builder A's rows from `../research/screen-fast-paths.md` are part of it: drop "Keep holding"; show the workout instruction lines only the first few times (the keys are now at `WorkoutModeView.swift:544-575`, so no-buttons.md's line numbers are stale); remove the rounded fills on the week range bar and on lifted or picked rows; and make one path back into a running workout, the lit top seam plus the Live Activity, in place of six. The Exercise page's main action is history and progress, not logging (Product, 19:47).
6. Fixes from Kaushik's phone review on Workout, Exercise and Plans (haptics, dial feel, finish animation). These go ahead of 3 and 4 when they come in.
7. Swap the DeleteObject stopgap for Core's `RemoveSlot`, rest days in the week view, and grouping in the exercise library, as each Core API lands.
8. M4 slice 10, widgets and snippets, pulled forward. Snippets first, then the App Group test build, per Design's `widgets-and-snippets.md`.

**Later:**
- Review the shared instruments in Core's cook mode (kitchen slice 12).
- Fixes from Kaushik's phone review on haptics, dial feel and the finish animation (unverifiable in the simulator).

*All v1 slices except 17 (voice) are on master after #91. Voice moved to Builder B's Ask Tess capture surface (Kaushik, 19:18). 14 still needs Core's Prefill fix.*
