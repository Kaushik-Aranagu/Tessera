# iOS Builder B (Mac, starts once ios/ship-2 merges)

*Owns: Home, the Command/Ask Tess bar, RootView, and the glue that hooks Notes, Review and Kitchen into Home.*

**Started 12:23 PM PT** (Mac session, own worktree). **Done:** #107 (Home links as a zoom, Kitchen on the rail, Notes at the foot of Review), #110 (Finish, Start and Resume at full size, "21 min ago"), Tess soul in the corner with Write working. **Now:** M2 Home: Today, the day strip and NowPicker wiring (Next items below), then Speak.

**Next:**
1. Button sweep (Home labels done; finish the rest) (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). After the install and once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder B's screens (Home, Command, RootView), reusing Builder A's DesignSystem button style uses Design's replacement language and the audit's rows for those files are ticked, with a recording.
2. Ask Tess capture surface, Write mode (Kaushik, 19:18; `../product/spatial-interaction.md` section 0, built to Design's revised `no-buttons.md`). Done when Ask Tess is a small glyph, not a bar, that animates open into a capture surface; typing works in it with the ghost row as today; and it's ready for the Speak and Show modes below. Show it in a recording.
3. Capture surface, Speak mode (`../research/speech-capture.md`). Done when holding or tapping Speak transcribes on the phone with SpeechAnalyzer and SpeechTranscriber, offline, with only the usage strings needed. The transcript is cleaned by the grammar normaliser and lands as a ghost row, and it works during a workout ("same", "8", "80 for 7"). This covers v1 slice 17. Test it on the phone, since the simulator can't. The transcript passes through the 80 rows in `../research/fixtures/spoken-normaliser.md`.
4. Learning Tess without a manual (`../research/tess-discoverability.md`). Done when the capture surface shows a context placeholder plus one fill-only phrase, ghost rows carry a quiet "You can also say" line, a hand-done action shows "Next time, this works" once, and there are at most 3 hints a day, stopping on day 15.
5. NowPage reads the context ranker. Done when NowPage (the Home hero) reads Core's `rank()` in place of `AppModel.currentTask`, re-ranks on events (set logged, task done, process started or ended, time of day), and can show the pick's `why` one gesture deep. Starts when Core's ranker lands; until then, the next item.
6. Capture surface, Show mode (`../research/capture-modes.md`). Done when a photo is read on the phone with Vision and routed: a page becomes a note first, a recipe photo goes to the recipe parser, and a receipt gives the shop total once Money slices 2 and 3 exist. Images never leave the phone. Needs Core's photo field type.
7. M2 slice 9, the task finish moment (Ink strike and haptic). Not rough.
8. NowPicker wiring. Done when cooking, shopping and timed tasks become Now through the same picker as workouts.
9. M2 slice 11, the day strip showing tasks and the workout, with the now marker.
10. M2 slice 12, the full What's running ledger for tasks: suspended and waiting, with the stale rules.
11. M2 slice 13, the day-full warning.

**Later:**
- M5 Money screens 6, 7, 5 in `ship-list-m5-money.md` (after Core's slices 1 to 3), then M5 Upkeep screens 5 to 7 in `ship-list-m5-upkeep.md`, then the M5 People screens in `ship-list-m5-people.md`.
- Entry points from Home into Notes, Review, Kitchen and Lists (Groceries is `GroceriesView()`, #58).
- Dated list items in Today, and a running list as Now. This wires the UI for Lists slices 5 and 6 once Core lands them.
- **Lists screens 9 to 12** in `ship-list-lists.md`, in `Features/Lists/`, after the Home slices:
  - 9, the shelf, after Core's Lists slices 1 and 3.
  - 10, a list page, after Core's Lists slices 1 and 3.
  - 11, an item opened, after Core's Lists slice 2.
  - 12, the pick-one moment, after Core's Lists slice 7.
- The Command bar hosting Tess's log answers and edits (M3 slices 7 and 8).
