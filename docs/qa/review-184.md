# Review #184 (merged ab45919) — Review week: PASS with two should-fix (not in tonight's install)

Static review plus the last frame of docs/recordings/review-week.mp4 (Thursday: S M T W trained, T rest stroke,
F S faint rings; "Four / sessions / this week").

## #179 lows: both closed
- P1: `settled` now also flips on any scroll phase other than idle.
- P2: `@ScaledMetric(relativeTo: .body) timeRoom = 64`.

## The four claims
- **Headline:** it counts sessions ("All six sessions in", "A quiet week so far", first-week variants). It never
  says "good" or "of seven". ViewThatFits breaks after the number phrase. At 56 pt the tail still wraps (the frame
  shows three lines: "Four / sessions / this week"), but nothing ends on a single orphaned word. OK. The
  VoiceOver label carries the plain count.
- **Rest as a dry ink stroke:** RestMark/RestStroke at 50% ink, drawn in over 280 ms, with Reduce Motion respected.
  OK.
- **Ring only for open days, nothing before first use:** `.none` (empty, letter tertiary, hidden from VoiceOver).
  firstUse is the earliest of the plan's createdAt and the first workout's startedAt. OK.
- Tess line: now a fact ("Front Delts: 3 sets this week, toward a usual 10."), shown only after 3 sessions. OK.

## Past-rest inference (`WeekReview.marks`): should-fix
The rule: an empty past day is rest when `done + ahead >= perWeek`, where ahead = Core's planned training days left.
Core's `week()` plans exactly `min(due, days left)` days, so this reads as "can he still make the count?".
- **R1 false misses (the main one):** once he falls behind, every empty past day becomes an open ring, including
  the one the plan meant as rest. Example, 6 a week (PPL x2): trained Mon, nothing Tue or Wed, Thursday morning.
  Due is 5 and only 4 days are left, so meets is false and both Tue and Wed show rings, though one of them was the
  week's rest day.
  Fix: give the week `7 - perWeek` rest slots. Subtract the rest days Core already marks ahead, then mark that many
  empty past days as rest (latest first), and only the remainder as open.
- **R2 false rest (small):** `done` here counts sessions, while Core's `due` counts days. Two sessions in one day
  inflate `done + ahead`, so a day he actually missed can show as rest. Fix: count trained days
  (`week.count { $0.sessions > 0 }`), as Core does.

## Should-fix (Design call)
- R3: future planned days (F and S in the recording) draw the same faint 25% ring as a missed past day, so "not
  yet" and "missed" look identical. A ring should mean only a past open day. Fix: `.open` only for `day < today`.
  Future planned days get nothing, or a planned mark from Design.

## Lows
- R4: `-homePage` is DEBUG-only and parses `"\($0)"` case names, which is fine for recordings.
- R5: the week follows Calendar.current's firstWeekday (Sunday in the recording, en_US), while HomeRestDayTests
  uses Monday. That's consistent with the Plan page, but worth confirming that's what Design wants.
