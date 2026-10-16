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
