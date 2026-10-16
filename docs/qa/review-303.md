# Review: PR #303, the #298 follow-ups (head e835a61)

QA thread, Oct 15 PT. Static review (no Swift toolchain here). Files: `TesseraCore/Sources/TesseraTess/PlanWording.swift`, `ClaudeKey.swift`, `TessGrammar+Kitchen.swift`, `Tests/TesseraCoreTests/PlanWordingTests.swift`.

**Verdict: FIX FIRST.** P1 passes. V13 can reject valid plans (S1). The "remembered failed pack" almost never hits, because the cache key changes every minute (S2). Both fixes are small and stay inside PlanWording.swift.

## 1. P1 on the DST days: PASS

- `minutes()` (PlanWording.swift:42-46) now reads the wall clock (hour × 60 + minute), and adds 24 h only when the date falls on a later calendar day than the plan day. On Nov 1, 07:00 packs as "07:00", not "06:00".
- `applying()` rebuilds a time from the day plus `hour / 24` days, then `bySettingHour(hour % 24, …)`. That is a clean round trip; it never adds hours to a date.
- `aDSTDayPacksWallClockTimes` runs on 2026-11-01 (fall back) and 2027-03-14 (spring forward) in America/Los_Angeles. It checks the window, the block start, that the validator accepts a 07:00 reply, and that the applied ghost lands at hour 7. Both dates are the real US change days.
- Low (L1): the change itself happens at 01:00-03:00, before the 07:00 floor, so an hour that doesn't exist or happens twice can never be packed. Nothing to fix.

## 2. V13 never rejects a valid plan: FAIL (S1)

V13 is at PlanWording.swift:270-280. Every line is checked: lineText, ghost lines, startWith and note (:247-248). Three paths reject plans that are fine.

- **S1a. The bare "rest" token.** `!pack.hasWorkout && tokens.contains("rest")` rejects any line with the word "rest" on a day with no workout block. "Garage, then the rest of the afternoon is yours." and "Do the rest after lunch." both come back rejected, and he gets the usual plan for no reason. This will be common because most days have no workout.
  - Fix: match the phrase "rest day" (and "rest days") instead of the token. Keep the exception for the note that is exactly "Rest day." on a rest day.
- **S1b. Single-word names in otherNames.** `otherNames` keeps any phrase of 3 or more characters that isn't a block title (:131). A Later task or routine called "Lunch", "Run", "Read" or "Call" matches the same everyday word in a valid line. "before lunch" is rejected whenever he has a Later task named "Lunch" that isn't in today's plan.
  - Fix: only keep names of two or more words, or one word of 6 or more letters that isn't a common word. Simpler still: drop one-word names and accept that V13 misses those.
- **S1c. "session" and "lift" on a day with no workout.** "A short focus session on the deck." and "Give it one quick session." are valid lines for a task block, but they are rejected unless the word appears in a title. Of the training words, only "gym", "workout" and "training" name training without doubt.
  - Fix: trim the list to `["workout", "gym", "training"]`, plus "train" only when it isn't next to a station or ticket word. Dropping "train" is fine too.
- **Tests (T2).** The new rows only prove that bad lines are caught (the V13 rows at PlanWordingTests.swift:175-177, and `aRestDaySaysOnlyRestDay`). Add pass rows on a day with no workout and a Later task "Lunch", checking that these come back with no violations:
  - "the rest of the afternoon is yours."
  - "before lunch."
  - "a short focus session."

## 3. A remembered failed pack never makes a new paid call: FAIL (S2)

The cache is at PlanWording.swift:395 and :410-412, and `done()` is at :433-438.

- **S2a. The key changes every minute.** The cache compares `pack.json`, and the pack JSON holds `"now": clock(minutes(now))` (:104). After 07:00 the window start also moves with now, rounded up to 5 minutes (DayPlan.swift:214-217). So reopening Plan my day a minute later is a different pack, and it makes a new paid call. A rejected or cut-off reply repeats, and he pays for it, every time he opens the screen. The test `aRejectedPackIsRememberedAndTheSwitchIsOne` passes only because both calls happen in the same minute with a fixed `now`.
  - Fix: key the cache on the pack without "now" and "window", i.e. the blocks, allDay, cap, light, rest and cal. Also remember failures for the day: after a rejected, max_tokens or refusal outcome for the same blocks, don't call again today. A cheaper option is no second paid call after a rejection on the same TesseraDay, whatever changes.
  - Test: call word() at 08:00 and again at 08:07 with the same tasks, and expect one request.
- **S2b. "late" isn't remembered.** The stale path (:457-460) returns without `done()`. The call was paid, and reopening the same pack pays again. Fix: `return done(.rules(line: nil))`. That's safe because a different, touched plan already has a different pack.
- **S2c. A cached bad key outlives a new key.** `badKey` is cached against the pack, and the key is read before the cache check, but the cache doesn't know which key failed. Once S2a is fixed (a stable key), he pastes a fresh key and still gets "That key didn't work…" from the cache until the plan changes. Fix: don't cache `badKey` (it costs nothing), or clear the cache when the key is saved.
- **Low (L2).** The cache is one entry, in memory, and gone on relaunch. That's acceptable once S2a is fixed, because a relaunch is rare. Not blocking.
- OK: "offline" isn't cached, which is right because no paid call happened. "busy" (529) and "timeout" are cached, also right: a timeout may have been billed.

## 4. Other items: PASS

- P4: the Sonnet 5.5 cache read is 200, in the price table in ClaudeKey.swift.
- P5: `"output_config": ["effort": "low"]` is on the wire (:514), and the test checks the body. The field name matches the current API's effort setting.
- Hard deadline: `withDeadline` (:481) races the send against a sleep in a task group and cancels the loser, so the 20 s holds even when bytes trickle in.
- stop_reason: "max_tokens" or "refusal" gives the rules plan, writes a ledger row with that outcome, and is cached (test `aCutOffReplyShowsTheRulesPlan`).
- Outcome lines match Product's wording. The bad key line is M2 plus "Here's your usual plan." on one line, which is how Product wrote it.
- `allowed` is checked before the key read, with no request (tested). `includesEventTitles: false` sends events as "busy" and drops allDay and event words from titleWords (tested).
- T1: the V2 rows cover an added block and a dropped block.
- isMoney is now `(?i)`, so "$1.29/LB" isn't a spend.
- Secret check: no key material in the diff.

## Must fix before merge
1. S1a, S1b and S1c, plus the T2 pass rows.
2. S2a (a cache key without now and window, plus a per-day failure memory) with the 08:00/08:07 test; S2b; S2c.
