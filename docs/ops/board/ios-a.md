# iOS Builder A (Mac, current iOS build thread)

*Owns: Workout, Exercise, Plans, Routine, Widgets, DesignSystem.*

**Done:** ship-2 (#91): v1 slices 8 to 12, G1, a haptic, P2, B3, the launch note, and the mic hidden.

**Now (until the 20:05 cut):** PaintKey ink rewrite, then D4 (rest survives an app kill), then the edit-set steer. After the final build, run gym-flow D, E and H plus `regression.md` on the phone.

**Next:**
1. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). Start once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder A's screens (Workout, Exercise, Plans, Routine, Widgets) uses Design's replacement language and the audit's rows for those files are ticked, with a recording. Put the shared button style in DesignSystem first so Builder B and Core can reuse it.
2. Fixes from Kaushik's phone review on Workout, Exercise and Plans (haptics, dial feel, finish animation). These go ahead of 3 and 4 when they come in.
3. Swap the DeleteObject stopgap for Core's `RemoveSlot`, rest days in the week view, and grouping in the exercise library, as each Core API lands.
4. M4 slice 10, widgets and snippets, pulled forward. Snippets first, then the App Group test build, per Design's `widgets-and-snippets.md`.

**Later:**
- Review the shared instruments in Core's cook mode (kitchen slice 12).
- Fixes from Kaushik's phone review on haptics, dial feel and the finish animation (unverifiable in the simulator).

*All v1 slices except 17 (voice) are on master after #91. Voice moved to Builder B's Ask Tess capture surface (Kaushik, 19:18). 14 still needs Core's Prefill fix.*
