# Review: PR #306, S1/S2 fixes on #303 (head 5615a83)

QA thread, Oct 15 PT. Static review. Files: `TesseraCore/Sources/TesseraTess/PlanWording.swift`, `Tests/TesseraCoreTests/PlanWordingTests.swift`. Base f274252, which is current master with #303 and #304 merged.

**Verdict: PASS. S1 and S2 from review-303 are closed.** The lows below can ride a later PR.

## S1, V13 never rejects a valid plan: CLOSED

- S1a: "rest" is now the phrase " rest day " (PlanWording.swift:297), so "the rest of the afternoon is yours." passes.
- S1b: only multi-word names count (:151). "Lunch" is dropped, and a name that overlaps a plan or all-day title is dropped too ("Reply to landlord today", "Bank holiday").
- S1c: the training words are now only workout, gym and training (:293). "session" passes.
- Tests: `ordinaryWordsPassV13` covers four valid lines with "Lunch" and "Reply to landlord today" in otherNames. `anAllDayTitleInThePlanIsNotSomethingElse` covers an all-day title. The bad rows from #303 still catch "Sort the garage" and "Mum's birthday".
- L1: the overlap test at :151 compares strings as substrings, not words. A one- or two-letter title ("AC") or an empty title drops almost every name, and the title "Run" drops "brunch with sam". That only makes V13 catch less; it never rejects a valid plan. Compare as words (padded with spaces) in a later PR.

## S2, a failed pack never makes a new paid call: CLOSED

- S2a: the cache key no longer changes with the clock. `cacheKey` (:116-129) drops "now", "window" and the run blocks' start and end, and keeps the fixed blocks' times, allDay, cap, light, rest and cal. A failed, rejected, cut-off or late result is remembered for the whole TesseraDay, whatever the pack (`failed`, :417, :439-441, :463-466). Reopening at 08:07 after a 08:00 rejection makes no call. A good wording is reused through `repacked` (:516 on), which moves each run to its new start, re-checks it with the validator and applies it. The test `aMinuteLaterTheWordingIsReusedAndAFailureIsRememberedToday` checks one request across 08:00 and 08:07, with the first ghost now at 08:10.
- S2b: "late" now goes through `done()` (:492) and is remembered (tested with `stale: { true }`).
- S2c: a bad key is never remembered (:464), so a newly pasted key is tried (tested: two 401 calls means two requests). Offline and cancelled aren't remembered either, and neither of those is a paid answer.

## Lows (not blocking)

- L2: "busy" (429/5xx) is remembered for the whole day. That costs nothing, but one 529 at 7 am means no Claude wording until tomorrow. Add "busy" to the not-remembered list at :464.
- L3: "late" is remembered for the day. Late means he touched the plan, so the touched plan won't get Claude wording again today. That's what Product asked for; just noting it.
- L4: a good wording whose lines name a clock time ("Bike light first, 7 am.") fails V11 after `repacked` moves the run, so the next open makes a new paid call. That costs at most one call per 5-minute shift, only while he keeps reopening, and each new answer is cached. Acceptable at about $0.005 a call. A later fix could fall back to the remembered lines without the times.
- L5: a cancel that surfaces as a non-URLError inside `send` maps to `Failure.other` (:587-588) and is caught by the Failure catch before `catch is CancellationError` (:482). So it gets remembered for the day as "other". URLSession normally throws `URLError.cancelled`, which maps to offline and isn't remembered, so this is rare. Fix: check `Task.isCancelled` first in the Failure catch.
