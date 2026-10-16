# QA review: PR #366, AI-1 Home lines (Builder B)

Head `52a729bae7ba0190aefc9de3290c85a4ec422e1c` (ios/home-lines). Static review plus a contact sheet of
docs/recordings/home-lines.mp4 (13 s). Trial merge onto master: clean. 9 files, +253/-220: NowPage, new
HomeLineHero.swift, HomeQueue, PaintKey (DesignSystem/Paint.swift), DemoData, HomeDataTests, two UI tests, the clip.
Checked against docs/ai/home-lines.md (caps, §4), Design 41 §3 and Research 116 where the PR claims them.

## Verdict: FIX FIRST (two one-line "…" paths, and the clip shows one state)

### F1. A Next row can still end in "…"
`QueueRow` swaps `.lineLimit(1)` for `.lineLimit(2)` + `fixedSize(horizontal: false, vertical: true)`
(HomeQueue.swift:352). A title that needs three lines at Body 21 (about 60 characters, or fewer at a large Dynamic
Type size) is cut at two with "…". Design 41: rows wrap or fit. **Fix:** drop the `lineLimit(2)`; the row already
grows (`minHeight`, measured `heights` for the Later word).

### F2. The context line's last fallback truncates
`LineHero`'s `ViewThatFits` tries the context and the short context at `fixedSize`, then falls back to
`Text(contextShort ?? context).lineLimit(1)` with no `fixedSize` (HomeLineHero.swift:23-26), which truncates with
"…". The caps (32 characters) fit at the default size, so this bites at large Dynamic Type. **Fix:** make the last
child wrap (`fixedSize(horizontal: false, vertical: true)` with no line limit), as the hero's own last form does.

### R1. The clip is one still state
All 13 seconds are the same rest-day evening (contact sheet at 1 fps: "Friday evening", "today", "Rest day",
START PUSH A, Next). It doesn't show the new paused-workout hero with RESUME and the progress ink line (the one new
DesignSystem element), a task hero with Finish, a planned routine, a done workout, or a context redraw. Recordings,
not stills: a re-cut covering at least the paused workout (some sets logged) and a task hero. Design reviews the clip
too, so this can be their call.

## Checked and fine
- **Data safety.** No new LaunchFlags or ProcessInfo reads in app code (the UI tests' snapshot env read is test
  side); both new UI tests subclass `SimulatorOnlyTestCase`; demo change is the title string only; no engine or
  catalog change.
- **One line per thing.** Every hero reads `HomeLines.line(for:now:)`: the time words above (Voice 21, context
  colour), the hero, one key. The planned routine's counts and the done workout's count line are gone from Home
  (41.1, 41.6). The day word (`DayLabel`) replaces the stroke as the only day word (41.4). The demo title loses its
  " · " (41 §3).
- **Paused workout.** A running or paused session is the hero with "Resume Push A" in live ink; the key's ink line is
  progress, sets logged over sets planned, nil (a plain line) before any set. `PaintKey.progress` draws a 22% track
  and a masked fill animated through `tesseraAnimation`; a hold still shows the usual trace. The default is nil, so
  every other PaintKey is unchanged.
- **Hero fit.** `HomeHeroText` picks Hero 56 one line, Title 44 one line, then Title 44 wrapped; the wrapped form
  can't truncate.
- **Haptics.** No new feedback; Finish keeps its single impact (NowPage.swift:86).
- **Tess's slot.** Nothing new is laid out in the 736-820 band; the clip's "Hold me to talk." stays put.

## Lows
- **L1. The hero's fit is estimated** from character count × 0.56 em, so a line of wide glyphs ("Mom's birthday
  Wednesday", capitals) could pick Hero 56 one line and truncate. Device check at the largest Dynamic Type size; a
  hidden measuring `Text` would make it exact.
- **L2. The rest-day override.** Context reads "today" instead of Core's weekday because the day word above names
  the day. That's fine under the caps; the lens should own it so Widgets and Lock Screen (Design 54) read the same.
- **L3. Rest day with a workout in Next.** At 18:10 the demo reads "Rest day" with START PUSH A, and Next lists
  "Push Day A 19:00". The demo's scheduled workout and the rest day disagree; Product/Design should say which Home
  believes.
- **L4.** The "…" UI test can't catch truncation: a cut Text's accessibility label is still the full string. Its
  height check on the long title is the useful part.
- **L5 (pre-existing, not this PR).** The ghost row's title (NowPage.swift:324) and the paused ledger row's step line
  (NowPage.swift:401, `.truncationMode(.middle)`) are still `lineLimit(1)`.

## Addendum: re-check at `a31e7ea`

Verdict: **PASS**. Trial merge onto master 9f91f26 is clean.

- F1 fixed: `QueueRow`'s title has `.fixedSize(horizontal: false, vertical: true)` and no line limit (HomeQueue.swift). Rows use a minimum height and measured heights, so "Read Designing Data-Intensive Applications" wraps to two lines in the clip. `HomeLinesUITests` covers it.
- F2 fixed: the last child of `LineHero`'s context `ViewThatFits` wraps instead of truncating (HomeLineHero.swift).
- Design F2 is in: a rest day with a next session shows "Start …" in ink. With no next session, the planned session becomes the hero with START in ink (NowPage.swift).
- The "today" override is gone. The hero's id is filtered out of Next and Later.
- The old Done, Rest, Routine and Running heroes are now one `LineHero`. The running or paused session shows "Resume Push Day A" with a progress key.
- R1 closed: the 53 s clip `docs/recordings/home-lines.mp4` walks Start, Home while running ("Push Day A, bench set 3 / Resume Push Day A"), two logged sets, a skipped rest with UNDO, Finish, and Back to today. It ends on the next task ("Groceries for the week"). There is no "…" in any frame. Heroes use digits and a lower-case "pm" ("Push Day A at 7 pm").
- Data safety: all three UI tests subclass `SimulatorOnlyTestCase`. `ProcessInfo` appears only in test code, for the snapshot folder. There is no migration. The DemoData title change only drops a "·".

### S1 (should fix, next Builder B push). The walk test's minimise step is stale
`HomeWalkUITests.swift:28-29` taps (0.89, 0.102), "the chevron at the top right". Since #381 that chevron is gone, and PAUSE ("Pause the workout", WorkoutModeView.swift:689-696) at the bottom of the screen is the way back to Home. The top right now shows the "1 / 5 ⌄" counter, which opens the running order. The `Resume Push` check at :32-34 can still pass on Home's buttons that stay in the tree under the cover, so the test may go green without ever going back to Home. Fix: tap `app.buttons["Pause the workout"]`, then assert Home's RESUME is hittable.

### Lows
- L1: the walk ends on the next task hero, not a true rest day, as Builder B said. The rest-day path (`facts.rest(next:now:)` nil → planned session with START) has no recording. That is fine for this PR, but a still or clip belongs in the next Home PR.
- L2 (not this PR): the finish card reads "Friday, 18:10 to 18:10" with "1 MIN" under the `-demoTime` clock. That is #381's N2, still open.

## Addendum: re-check at `46dfd4d` (rebased on 5af8f2c)

Verdict: **PASS** for the code and the S1 fix. Trial merge onto master is clean.

- S1 fixed (HomeWalkUITests.swift):
  - PAUSE is found by its label `"Pause the workout"` (case-insensitive), asserted to exist, and tapped.
  - RESUME is asserted on Home before it is tapped.
  - Finish comes from the running order's FINISH HERE.
  - There are no coordinate taps on the old chevron; the only coordinate left is a fallback for LOG.
- The new commit's app change is cosmetic: Home's keys get `.textRole(.labelStrong)` (NowPage.swift), and the accessibility labels are unchanged.
- **The clip is older than this head.** At 0:12, `home-lines.mp4` (54 s) shows Tess saying "Same as last time, 82.5 × 7." before set 1. This head carries #397 (732d72f is an ancestor), where `.lastTime` returns nil (WorkoutSession+Prefill.swift:13), so the build at 46dfd4d can't say that line. The walk itself matches the test: Start, two sets with a rest, PAUSE, Home showing "Push Day A, bench set 3 / RESUME PUSH DAY A", the running order, FINISH HERE, done, Back to today. It's Design's call whether to accept it or have it re-recorded on 46dfd4d.
- Low: the last assertion (`… .waitForExistence(timeout: 5) || true`) can never fail. Drop it, or make it a real check of the done line.
