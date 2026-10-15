# iOS Builder A (Mac, current iOS build thread)

*Owns: Workout, Exercise, Plans, Routine, Widgets, DesignSystem.*

**Now:** v1 slice 8, tap a logged set to edit it. Undo already works; per Research's gap audit (`../research/v1-gap-audit.md`) no UI calls `EditSet` yet. Done when tapping any logged stroke opens it on the dial and drum, changing it calls `EditSet` with undo, and it's covered in a recording. Design's sheet steers it if it lands first.

**Next:**
1. G1, "ready for 20" on a fresh start. Done when `TrainingPage.swift` uses the same first-time test as `Prefill.swift` (`isFirstTime`).
2. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). After the install and once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder A's screens (Workout, Exercise, Plans, Routine, Widgets) uses Design's replacement language and the audit's rows for those files are ticked, with a recording. Put the shared button style in DesignSystem first so Builder B and Core reuse it.
3. v1 slice 10, routine editor. Done when he can drop, reorder and change an exercise in his plan (not just today) per Design's routine editor sheet, using Core's `RemoveSlot` plus the existing `MoveSlot`, `EditSlot` and `SwapSlotExercise`.
4. v1 slice 17, voice in the gym. Done when holding the Bar during a workout takes speech ("same", "8", "80 for 7") into the existing grammar as a ghost row, with the mic usage string and Design's voice sheet. The Bar lives in Features/Command, so agree the hook with Builder B if B owns it by then. Until it ships, the mic glyph is hidden.

**Later:**
- Review the shared instruments in Core's cook mode (kitchen slice 12).
- M4 slice 10, widgets and snippets.
- Fixes from Kaushik's phone review on haptics, dial feel and the finish animation (unverifiable in the simulator).

*v1 slices 1 to 7, 9, 11 to 13, 15, 16, 18 and 19 are on master (gap audit, 19:02). 14 needs Core's Prefill fix.*
