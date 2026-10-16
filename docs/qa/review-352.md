# QA review 352: Design 46 Review as the week on one page (Builder B)

*QA, Oct 16, about 1:40 AM Pacific. PR #352, `ios/review-week`, head `fe49343`, from `94b69cc`. Static review.
Trial merge onto master: clean, 5 files (+472 / -97). Design reviews the recording; this is behaviour and safety.*

## Verdict: FIX FIRST (one line: the week's lines can end in "…")

### F1. Lines truncate with "…"

Each row in `WeekLines` is `.lineLimit(1)` (`Features/Home/ReviewWeek.swift:329`). Day log lines aren't capped the
way Home lines are. Something like "Bought 6 things, for tacos and Sunday's chili." after a "Tue" lead, or a
workout line with a PR at large Dynamic Type, ends in "…". Kaushik's rule is never "…" (REVIEW 1). **Fix:** let the
row wrap: `.fixedSize(horizontal: false, vertical: true)` with no line limit, or a two-line hanging indent under the
lead. The hero already does it right with `ViewThatFits`.

## Checked and fine

- **Tap a day, tap again.** `read(_:)` toggles `reading`, and a tap anywhere else brings the week back
  (`ReviewPage.swift:318-331`). A dab opens its session only once its day is being read, so the first tap never
  opens a workout. Letters, band cells and dabs all go through `read`.
- **The bands.**
  - TRAINING shows "3 of 6", or a bare count with no plan (`ReviewWeek.swift:96-98`), with the existing
    `DayMarkView` rest dabs.
  - TASKS DONE counts by `doneAt`, the day each was done (`:51-57`). Days ahead and days before first use are blank.
  - COOKED shows only when something was cooked, with cadmium dabs.
  - `objects(of:)` excludes soft-deleted objects, so undoing a cook or a task takes its mark away.
- **The hero.** It picks the longest form that fits one line ("Push A, Bench best, 3 done" → "Push A, 3 done" →
  "Push A"), with no "…". Other heroes are "Rest day", "A quiet day" and "Still ahead".
- **The Day log** reads a window per past day (`DayStory.lines(engine:on:)`), never the whole log, so #318 S1 holds.
- **Accessibility.**
  - Each band is one spoken element ("Training, 3 sessions of 6. Monday trained, …").
  - The letters carry the button trait, a name and a hint, and the UI test taps them as `app.buttons["Thursday"]`.
- **Data safety.**
  - `ReviewWeekUITests` is a `SimulatorOnlyTestCase` (`:5`). Its `-homePage` flag is read through `LaunchFlags`
    (`HomeSpatialView.swift:55`). The `ProcessInfo` environment read is in the test target only (snapshot folder),
    never in the app.
  - `DemoData` now stamps `doneAt` on demo tasks, which only runs under `-demo` on the Simulator.
  - No store writes, no migration, no project.yml change. No secrets.
- **The full Review screen**, "The week" link word (`HomeSpatialView.swift:212`), is untouched, so install-day steps
  2, 16 and 18 still hold.

## Lows

- **L1. `ReviewWeekData.compute` runs on every body pass**, and every write bumps `model.revision`. That's 7 Day log
  windows, every task and every cook each time, including while Review is off screen (and in #342's lens deck).
  Fine today, but worth caching per revision once WeekFacts (#348) replaces the per-day counts.
- **L2. The "best lines" rank is a stand-in.** It scores the words "best", "record", " pr" and "first"
  (`ReviewWeek.swift:121-133`). Swap it for `WeekFacts.bestLines` when #348 lands; the comment says so.
- **L3. A stale comment.** `read(_:)` says "a day still ahead returns to the week", but a day ahead is read
  ("Still ahead"). One or the other should change.
- **L4.** If even the shortest hero form doesn't fit, `ViewThatFits` falls back to the last form, which is
  `fixedSize` and would clip rather than wrap. That's unlikely with routine titles.
