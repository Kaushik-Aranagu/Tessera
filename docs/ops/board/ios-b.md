# iOS Builder B (Mac, starts once ios/ship-2 merges)

*Owns: Home, the Command/Ask Tess bar, RootView, and the glue that hooks Notes, Review and Kitchen into Home.*

**Started 12:23 PM PT** (Mac session, own worktree). **Done:** #116 (Today on Home, M2 slices 8 and 9, 0f183ae); #107 (Home links as a zoom, Kitchen on the rail, Notes at the foot of Review); #110 (Finish, Start and Resume at full size); Tess soul in the corner with Write working. **Now:** the Now rest-day hookup, the only thing left holding the phone update (QA gave GO on #151 and #153, 4:50 PM PT). It is (QA E5: Now reads Core's #132 rest-day override, so Now and the week page agree; this is Next 1, with Next 5 folded in, plus Research #159's M2: give the seeded plan its sessions per week so rest days actually show. Also NowPage reads Core's `rank()` (#141) in place of `AppModel.currentTask`). Then Design's audit rows for Builder B (the #151 polish, merged as #179; ships in the build after tonight's) (`docs/design/audit-build-1.md` rows 6, 7, 8, 9, 12 and 13: no textRole on the Start stroke word, drop the track under the time-left stroke, seeded wobble on PaintDab, motion through MotionPolicy, and the #107 capture follow-ups; row 12, the back word, waits for Builder A's shared BackWord view and then covers the root stack, plus "< HOME" in place of "Close" on the Home covers, per `docs/design/back-word.md`). Then the dab flying to the day stroke on Tomorrow, then the hero promotion morph, then the day strip (M2 slice 11). `DayStrip.swift` exists but shows no tasks yet, so it's done when tasks and the workout show on it with the now marker. The Today swipes haven't had a finger test yet, so Kaushik's first swipe on the phone is the real test, and his feedback on it goes first.

**Then, before the rest of Next: Review week fix** (Product, 4:58 PM PT; Kaushik's rule: misses as a faint ring, never red, and he reads Review daily). Done when, per Research's `../research/fixtures/review-sentence.md` (#155; 22 of 30 weeks flagged), Review opens with a session-count headline in `Features/Home/ReviewPage.swift:29` ("All six sessions in", "Two sessions this week") in place of a grade, rest days draw Design's rest dab, and the miss ring only appears on a real miss: never for a rest day, a day before first use, a half session or a running workout. Two sessions on one day count as two. Core supplies the week data; Design draws the rest dab. The top fix clears 18 of the 22 flagged weeks.

**With Themes, ahead of the audit batches: a calmer Ask Tess capture** (Kaushik, 6:45 PM PT; Design's sheet follows the rest dab). Calmer, smaller, less cluttered type on the capture surface (#107's), neat and peaceful. Folds in audit row 13's "cap her line at 270".

**Then: Settings: Claude screen** (B owns Tess; coordinator 5:50 PM PT). All 26 states and their lines are in Research's `../research/settings-claude.md` (decisions.md 7:17 PM PT). It sits on Core's Keychain store and follows Design's Settings: Claude sheet: paste the key once (it's never shown again, only "Key saved"), Test, the usage line that turns amber at 80%, "Claude paused until 1 Nov." at the $10 cap, and the cloud mark on the bloom, which also shows on every use-1 ghost row that came from Claude (Research #172).

**From now on, use themed tokens** (Kaushik's themes, 6:40 PM PT): new and touched screens use Builder A's DesignSystem theme tokens, never hard-coded colours, so every theme works.

**Next:**
1. (In Now, blocks the phone update) Rest day on Now, QA E5. Done when Now and the week page agree on a rest day, and, on a planned rest day, the Home hero shows a quiet "Rest day" line from Core's NowPicker override, and the next routine is one tap away. No guilt copy and no red.
2. Button sweep (Home labels done; finish the rest) (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). After the install and once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder B's screens (Home, Command, RootView), reusing Builder A's DesignSystem button style uses Design's replacement language and the audit's rows for those files are ticked, with a recording.
3. Capture surface, Speak mode (`../research/speech-capture.md`). Done when holding or tapping Speak transcribes on the phone with SpeechAnalyzer and SpeechTranscriber, offline, with only the usage strings needed. The transcript is cleaned by the grammar normaliser and lands as a ghost row, and it works during a workout ("same", "8", "80 for 7"). This covers v1 slice 17. Test it on the phone, since the simulator can't. The transcript passes through the 80 rows in `../research/fixtures/spoken-normaliser.md`.
4. Learning Tess without a manual (`../research/tess-discoverability.md`; the look is Design's `docs/design/show-and-hints.md`, and Core builds the hint ledger). Done when the capture surface shows a context placeholder plus one fill-only phrase, ghost rows carry a quiet "You can also say" line, a hand-done action shows "Next time, this works" once, and there are at most 3 hints a day, stopping on day 15.
5. (Folded into the Now rest-day PR) NowPage reads the context ranker. Done when NowPage (the Home hero) reads Core's `rank()` in place of `AppModel.currentTask`, re-ranks on events (set logged, task done, process started or ended, time of day), and can show the pick's `why` one gesture deep. Starts when Core's ranker lands; until then, the next item.
6. Capture surface, Show mode (`../research/capture-modes.md`; the layer is Design's `docs/design/show-and-hints.md`: Photos · Camera · File, and the photo read lands as a ghost row. Core builds PageReader and the routes). Done when a photo is read on the phone with Vision and routed: a page becomes a note first, a recipe photo goes to the recipe parser, and a receipt gives the shop total once Money slices 2 and 3 exist. Images never leave the phone. Needs Core's photo field type.
7. NowPicker wiring. Done when cooking, shopping and timed tasks become Now through the same picker as workouts.
8. M2 slice 12, the full What's running ledger for tasks: suspended and waiting, with the stale rules.
9. M2 slice 13, the day-full warning.
10. Day log page (M4 slice 5 screen), after Core's `DayStory`. Design's sheet is ready: `docs/design/day-log-page.md` on Design's branch. Done when a Day page per date shows the story lines from Design's sheet, a scrub back through past days works, and a HomeLink word reaches it.

**Audit batches (small PRs, after the Review week fix; decisions.md 5:14 PM PT):**
- Late night (Research #169): the wrap-up line is never shown; Home says "trained this night"; Tess's glyph rests during a live workout after 11 PM.
- Now refreshes when the time zone changes (Research #168; decisions.md 6:06 PM PT).
- 4 AM day: Builder B's 4 midnight cuts in `../research/day-boundary.md` (#166) (including the HomeQueue next-week swipe), swapped to Core's `TesseraDay` helper once it lands.
- Home queue heights (Research #160, `../research/accessibility.md`): drop the fixed heights that clip text at large sizes. Normal priority.
- Empty states batch: Builder B's 7 rows in `../research/empty-states.md`. These cover the Today empty hero and its duplicate queue line, Start on an empty routine, the Review first week and no forward line, Training's "rest day" with no plan, the Tess fast path for today's routine, "No workout today to log into." on day one, and the extra Kitchen "Paste a recipe" word. Use Builder A's shared `EmptyLine`.
- Undo batch: Builder B's rows in `../research/undo-lines.md` section 2, plus the capture code in `App/AppModel.swift`, to the one rule.

**Later:**
- Plan my day calendar lines (with T6, Research's `../research/calendar-pack.md`, #165): the one-time ask "Plan around your calendar? Times and titles only." and the fallback "Planned without your calendar".
- After Build A1: a first-set timing mark (per Research's `../research/training-week-one.md` (#163)).
- Builder B's 3 op log gaps in `../research/oplog-health.md` (#162).
- The rest of Builder B's accessibility rows in `../research/accessibility.md`, including Tess's rows ("commits after 2 s with no cancel" for VoiceOver). The Objects rows are Core's.
- W3 recovery line and the one-time Health permission line on NowPage, after Core's rule and Health reads. Design's sheet: `docs/design/recovery-line.md` with `recovery-line.mp4` (6faa446 on Design's branch).
- M3 habits page, after Core's M3 slice 2, with a Habits word on the Today foot line. Design's sheet: `docs/design/body-weight-and-habits.md` with `m3-surfaces.mp4` (1f17bd1 on Design's branch), drawn on Research's `../research/m3-1-2-brief.md` fixtures with exact copy.
- Mount BottomChrome over the Home link covers (Groceries, Recipes, Notes, The week), so Tess speaks in one place. Core then removes its Groceries mirror.
- Lists screens 9 to 12 include Research's G1, a "Lists" HomeLink word under Groceries (`../research/lists-daily.md`), and the Kitchen lead's `lists-screens-acceptance.md`.
- M5 Upkeep screens 5 to 7 in `ship-list-m5-upkeep.md`, then the M5 People screens in `ship-list-m5-people.md`.
- Entry points from Home into Notes, Review, Kitchen and Lists (Groceries is `GroceriesView()`, #58).
- Dated list items in Today, and a running list as Now. This wires the UI for Lists slices 5 and 6 once Core lands them.
- **Lists screens 9 to 12** in `ship-list-lists.md`, in `Features/Lists/`, after the Home slices. Clearing, resetting, putting away, deleting an item and finishing a run each get a named line and a 10 s UNDO; copy follows Research's `../research/lists-copy.md` ("put away", EMPTY, done on a reusable list asks with a hold to reset). Design's sheet: `docs/design/kitchen/lists-9-12.md` (c8a83ff) with `lists-shelf.mp4`; it overrides acceptance row 9.5 with G10, so a running list stays first on the shelf:
  - 9, the shelf, after Core's Lists slices 1 and 3.
  - 10, a list page, after Core's Lists slices 1 and 3.
  - 11, an item opened, after Core's Lists slice 2.
  - 12, the pick-one moment, after Core's Lists slice 7.
- The Command bar hosting Tess's log answers and edits (M3 slices 7 and 8).
