# QA review 298: Plan my day through Claude (#298)

PR head 134f76a on base 97cac3e. 10 files (+931/-31). The new files are PlanWording.swift and PlanWordingTests.swift. It also folds in the review-290 fixes, the "@ 7" low from #289, and Research's money rows. No deletions. Static review; no toolchain here.

**Verdict: PASS on all six checks the coordinator asked for, with one should-fix (P1): on DST days, the pack sent to Claude has its clock times an hour off, so Tess's lines name the wrong hour.** Package only; nothing calls `ClaudePlanWording` from the app yet.

## The six checks
1. **The key stays in the Keychain and the header: yes.**
   - `keys.read()` (PlanWording.swift:367) feeds only `x-api-key` (:427).
   - The key is not in the pack, the cache, the ledger row or the log, which logs only V codes (:414).
   - The test body check also confirms no task UUID leaves the phone.
2. **The cap: yes.**
   - The reservation (:374) comes before any request. At the cap it returns "Claude paused until Dec 1. Here's your usual plan." with zero requests (tested).
   - One `defer` writes the ledger row on every path after the reservation (:384-390): works, timeout, offline, busy, bad key, other, late, `rejected V1` (no `proposePlan`) and `rejected V…` (validator).
   - Tested: rejected, timeout and late give 3 rows, the last one "late".
   - The same pack reuses its wording with no second call or row (tested).
3. **Nothing writes until a line is accepted: yes.** `word` and `DayPlan.applying` only return values.
   - The new `acceptingALineIsOneMoveTaskAndSkippingWritesNothing` test checks the accept path: skipping adds 0 ops; accepting is exactly one `MoveTask` by `.user`, with `startsAt` = the block start.
4. **The validator rejects moved fixed blocks and invented tasks: yes.**
   - **V3** (:180-186) compares every fixed block's start and end. Tested by moving Standup 5 minutes.
   - **V2** (:168-171) rejects any block set that differs from the pack: an added id, a dropped id, or a renamed one.
   - **V7** rejects ghost lines for anything but the run blocks. A ghost line naming a fixed block is tested.
   - Titles never come from Claude; the app shows its own.
   - **Gap T1 (low):** there's no test row for V2. Add one: an extra `{"id":"t4",…}` block, and a dropped `t3`.
5. **DST tests for Nov 1 and Mar 14: present and right for the plan.** `aDSTDayKeepsWallClockHours` covers both days in Los Angeles. The window is 07-21 on the clock, and cook waits for 18:00. All four hour sites now use `bySettingHour` (DayPlan.swift `at`, the 17:00 slot, the builder's C2 window). **But see P1 for the pack.**
6. **B1 on a real store with no Workout objects: yes.**
   - DayPlan+Store.swift:61-71: on a training day with nothing finished and no Workout object, today's routine from `week(containing:)` becomes a date-only workout.
   - Tested on the starter plan with an 18:00 dinner: the workout lands at 17:00-18:00.
   - Also closed:
     - L1: C3 now counts done timed tasks.
     - L2: a passed, unstarted workout moves to the first free hour from now, with `movedFrom` (tested).
     - L3: no free hour gives `notPlanned` (Push A, noFit) instead of vanishing (tested).
     - L4: the comment now says timed tasks win too.
     - The workout choice is sorted, so it no longer depends on store order.

## P1 (should-fix): the pack's clock times are an hour off on DST days
`PlanPack.minutes` (PlanWording.swift:32-38) counts elapsed minutes since the logical day's midnight (`date.timeIntervalSince(day)`). `applying` maps them back the same way (:306).
- On **Sun Nov 1**, 07:00 PST is 8 elapsed hours after midnight PDT. So the pack says `"window":["08:00","22:00"]` and every block starts an hour late.
- Claude then writes "8 am" for a 7 am block, and V11 passes it because it checks against the same shifted times.
- The block times on screen are right, because `applying` maps them back with the same offset. Only the words are wrong. On Mar 14 it's an hour early.

**Fix:**
- In `minutes`, use wall-clock components: `hour*60 + minute`, plus 1440 when the date falls on the next calendar day.
- In `applying`, rebuild with `calendar.date(bySettingHour:minute:second:of: day)`, adding a day for 24:00 and later.
- Add a pack test on Nov 1: `thePackIsTheFixtureLine` shape, with `"window":["07:00","21:00"]`.

## Lows
- **P2 (copy, for Product):** only a timeout and the cap get a line. A bad key, offline, busy and other failures return `.rules(line: nil)` (:393-401). Product's 8:38 PM call says a bad key says "That key didn't work. Paste it again?" (M2). The 19:22 call gives "Here's your usual plan." on failure. My recommendation:
  - bad key: the M2 line;
  - offline or busy: "Here's your usual plan.";
  - rejected or late: no line (the rules plan is fine and he never asked for Claude by name).
- **P3:** names that aren't in the pack aren't checked (fixture N5: "Mum's birthday", an offered-later task). V1-V12 don't cover it, so a line naming something invented passes. That's hard to check deterministically; the eval gate (18 of 20) is where it gets caught. Note it in the use-2 checklist.
- **P4:** the Sonnet 5.5 entry is `(2000, 10000, 100, 2500)` (ClaudeKey.swift:92). Input and output match $2/$10 per million. Cache read is 0.05× input, while Haiku's is 0.1× (10 of 100), so Sonnet's should be 200. It's unused today because this call reads no cache.
- **P5:** the fixture spec says effort low. The request sets no effort or thinking (:433-440). Fine for cost; noting the difference from the spec.
- **Grammar:**
  - "@ 7" now asks (F6).
  - "spent $1,250 on rent" and "spent $23.47 at trader joe's sat" give the miss line, never a task or groceries.
  - "chicken $1.29/lb, rice" stays groceries (the unit price is stripped before the money check).
  - KEEP4 and KEEP5 still log.
  - All tested; no issues.
