# Step-aside, cap and Home done-job tests (C3, for 0al)

Sources: docs/ai/home-lines-job.md 2b/2c, spend-projection.md, claude-client.md, ask-subject-pack.md.
Cap = 50_000_000_000 n$; 80% = $40. Fakes: stub transport, injected clock, injected HouseTime. No key value in any fixture.

## A. Step-aside order and cap
1. `linesJobRunsAt39_99` given month $39.99 / when .lines asks / then request sent.
2. `linesStepsAsideAtExactly40` given month $40.00 / when .lines asks / then .refused step-aside, no request, no row.
3. `weekStoryStepsAsideAt40` given $40.00 / when week story asks / then rules words, no request.
4. `livingColourStepsAsideAt40` given $40.00 / when living colour asks / then today's colours, no request.
5. `captureRunsAt40` given $40.00 / when capture asks / then request sent, row written.
6. `planRecipeAskSubjectLinkItemsRunAt40` given $40.00 / when each of the four asks / then each is sent. (Ruled Product 8:21: askSubject and linkItems run to $50; ask-subject-pack.md already says so.)
7. `stepAsideIsBeforeReserve` given $40.00 / when .lines asks / then pendingNano unchanged and reserve not called.
8. `stepAsideWritesNoRow` given step-aside / then ledger row count unchanged.
9. `capturePassesAt49_99IfEstimateFits` given $49.99 and a $0.0006 estimate / then refused .cap (reserve counts this call).
10. `reserveRefusesWhenTotalPlusPendingPlusEstimatePassesCap` given $49.9993 / when estimate is $0.0015 / then .refused(.cap).
11. `callAtExactlyFiftyIsRefused` given total + pending + estimate = $50.00 exactly / then decide and pin: allowed or refused (doc says "would pass").
12. `everyJobRefusedAtCap` given $50 / when any job asks / then .refused(.cap), "Claude paused until <date>.", no request, no row.
13. `keyCheckFallbackStopsAtCap` given $50 / then the fallback "Hi" check sends nothing.
14. `callCrossingCapMidFlightKeepsRowAndCost` given reserve passed at $49.99 and the reply costs more than estimated / then row cost is the real cost, a second call is refused.
15. `parallelCallsCannotBothReserveLastDollar` given two jobs reserve at once near $50 / then the second is refused, pending released by settle.
16. `settleRunsOnThrowAndTimeout` given a throw or timeout / then reservation released (defer), row written with outcome.
17. `unknownModelStringIsRefusedNotFree` given a model not in prices / then refused, never a $0 row.

## B. Reset on the 1st (house time, 4 am boundary)
18. `monthResetsAtFourAmOnTheFirst` given clock 03:59 on Nov 1 vs 04:00 / then 03:59 still counts as October, 04:00 starts a clean month, pending $0 total.
19. `step-asideLiftsAfterReset` given $41 in October / when Nov 1 04:00 passes / then .lines runs again.
20. `reserveAndCapMessageUseHouseDate` given $50 on Oct 31 / then paused-until date reads Nov 1.
21. `timezoneChangeDoesNotMoveMonth` given phone moves from PT to Tokyo mid-month / then the month key is unchanged (house time, not device calendar).
22. `clockSetBackwardDoesNotRefundSpend` given clock moved back a day within the month / then total unchanged; set across the 1st backward, no double reset.
23. `dstShiftKeepsFourAmBoundary` given a DST change night / then the day boundary is still 04:00 house time.

## C. Home done job: 40 a day, debounce, one call per finish
24. `doneJobSkipsCallWithNoBestAndUnder4Days` given done workout, no best, 3 days since / then no call, rules line.
25. `doneJobCallsOncePerFinish` given a finish with a best / then one call; a set added later makes no second call (cache keyed by workout id only).
26. `fortyFirstCallOfDaySendsNothing` given 40 homeLines rows today (failures and .noLine included) / then the 41st sends no request, no row.
27. `fortiethCallStillRuns` given 39 rows today / then the 40th is sent.
28. `dayCapResetsAtFourAm` given 40 rows before 04:00 / when 04:00 passes / then calls resume; 03:59 still capped.
29. `debounceCoalescesThreeChangesInTenMinutes` given three pack changes inside 10 min / then one trailing call with the newest pack.
30. `finishSkipsDebounceButCountsToCap` given a workout finishes inside the window / then it calls at once and the row counts toward 40.
31. `pausedTickNeverRecalls` given "paused 21 min ago" to "22 min" / then pack bytes identical, no call.
32. `capReachedMidFlightKeepsReply` given the 40th call in flight / then its reply is kept; no 41st.
33. `lateReplyDroppedRowSaysLate` given reply after 6 s deadline / then dropped, row outcome "late" with cost, never asked again.

## D. Misses and askSubject
34. `missesLedgerHoldsCeilingBeforeSend` given a miss / then reserve holds 3 rounds x 507,000 n$ ($0.0015).
35. `sixHundredMissesAtCeilingStayUnderCap` given 600 misses at ceiling ($0.91) / then totals match, no refusal until the cap.
36. `askSubjectTwentiethAskRuns` given 19 askSubject rows today / then the 20th sends.
37. `askSubjectTwentyFirstAskAnswersOnPhone` given 20 rows today / then no request, no row, phone answers alone.
38. `askSubjectDayCapRollsAtFourAm` given 20 rows / when 04:00 passes / then the next ask is sent.
39. `askSubjectCapCountsOnlyItsOwnJob` given 40 homeLines rows / then askSubject is unaffected, and the reverse.
