# iOS Builder B (Mac, starts once ios/ship-2 merges)

*Owns: Home, the Command/Ask Tess bar, RootView, and the glue that hooks Notes, Review and Kitchen into Home.*

**Now:** M2 slice 8, Today on Home (`ship-list-m2.md`). Done when it shows Now, then up to 3 Next and Later in a bounded surface, with swipe right for done and left for not now. It meets the UI bar.

**Next:**
1. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). After the install and once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder B's screens (Home, Command, RootView), reusing Builder A's DesignSystem button style uses Design's replacement language and the audit's rows for those files are ticked, with a recording.
2. M2 slice 9, the task finish moment (Ink strike and haptic). Not rough.
3. NowPicker wiring. Done when cooking, shopping and timed tasks become Now through the same picker as workouts.
4. M2 slice 11, the day strip showing tasks and the workout, with the now marker.
5. M2 slice 12, the full What's running ledger for tasks: suspended and waiting, with the stale rules.
6. M2 slice 13, the day-full warning.

**Later:**
- Entry points from Home into Notes, Review, Kitchen and Lists (Groceries is `GroceriesView()`, #58).
- Dated list items in Today, and a running list as Now. This wires the UI for Lists slices 5 and 6 once Core lands them.
- **Lists screens 9 to 12** in `ship-list-lists.md`, in `Features/Lists/`, after the Home slices:
  - 9, the shelf, after Core's Lists slices 1 and 3.
  - 10, a list page, after Core's Lists slices 1 and 3.
  - 11, an item opened, after Core's Lists slice 2.
  - 12, the pick-one moment, after Core's Lists slice 7.
- The Command bar hosting Tess's log answers and edits (M3 slices 7 and 8).
