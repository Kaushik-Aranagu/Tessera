# QA handoff (Oct 24, 2026, 1:00 AM PT)

QA is the adversarial reviewer. It reviews statically from GitHub (repo-scoped API: pulls, compare, contents at a
ref, tarballs) and sends one verdict per request to the coordinator. Verdicts: **PASS**, **PASS WITH NOTES**,
**FIX FIRST**, **STOP**. Block only for privacy walls, data safety or a revert; everything else is a note. A head is
"pinned" when QA has reviewed that exact sha; any new head needs a re-pin (say whether it is "tests only", "merge
only" or "logic changed").

Older verdict files live in `/mnt/project-files/tessera/qa/review-<N>.md` (not readable from Mac sessions).

## Open PRs this session reviewed

| PR | Head pinned | Verdict | Open notes | Merge order |
|---|---|---|---|---|
| #1358 | e09adb4c | PASS (earlier) | | rides build 78 with #1377 |
| #1377 | 7828b9d7 | PASS | | after #1358 |
| #1367 | 11b2834e | PASS WITH NOTES | completeFileProtection, why lines need the wall | harness stack |
| #1368 / #1369 / #1370 | e59a3920 / 110b2796 / 59c5604b | PWN / PASS / PASS | | on their bases |
| #1374 | 2dfbe195 | PASS WITH NOTES | | on #1366 |
| #1375 | 9ac77a57 | PASS WITH NOTES | | harness: #1364, #1365, #1367, #1368, #1375 |
| #1378 | 01439d49 | PASS WITH NOTES | | after #1375 |
| #1379 | 01f8b50a | PASS WITH NOTES | notes folded into #1380 | after #1375 |
| #1380 | e0524baf | PASS WITH NOTES | | after #1379 |
| #1381 | 9b6b9d43 | PASS WITH NOTES | Off copy (facet fixed in #1384) | on #1374 |
| #1382 | 6e191a1c | PASS | | after #1380 |
| #1383 | 701584e0 | PASS WITH NOTES | | to master |
| #1384 | 077d10f1 | PASS WITH NOTES | hand-set "out" hides rebought items; Got it on typed row; refusal matched by string | after #1381, #1383 |
| #1385 | afd58d82 | PASS | | after #1382 |
| **#1386** | 60ff4545 | **FIX FIRST** | Get it adds literal "private item" and lowercases names; 50 pt focus slot shorter than ~78 pt row | after #1384, waits for B's fix |
| #1387 | 898e1cf6 | PASS | cooked vs dry calories before calories go on | to master |
| #1363 / #1366 | a37a716c / 409666be | HELD | waiting for A's simulator recordings | |
| #1390 | 3247958c | PASS WITH NOTES | commit UI test needs #1392 (apps list) to pass | to master |
| #1391 | 546aca8c | PASS WITH NOTES | dead `pageDirection`; 236 stack swipe goes on MosaicSlot | to master **before #1393** |
| #1392 | 488280ed | PASS (installed) | add `onDisappear { onHold(false) }` | to master |
| #1393 | 03a5332d | PASS (re-pin) | base is #1391's branch: retarget to master after #1391 merges, then re-pin | after #1391 |
| #1394 | d22bfac0 | PASS | | #1385 then #1378 then #1394 |
| #1395 | 7aed147f | PASS | | after #1394 |
| #1398 | e601cc3f | PASS | | after #1395 |
| #1399 | 7cea3319 | PASS | | after #1398 |
| #1400 | d688c8e4 | PASS | Sample data seeding on the phone needs Core's test stamp first | after #1394 |
| #1396 | bb6cb183 | PASS | race on empty info between mkdir and write (tiny) | to master |
| #1401 | a6f28164 | PASS | | to master |
| #1402 | 0a78f359 | PASS | | after core/weather and #1401 |
| #1389 | merged 1de73767 | PASS WITH NOTES (after the fact) | follow-ups landed in #1390 | merged |

Older stacked PRs (#1312 to #1357, #1361, #1364, #1365, #1397) were carried from earlier rounds; check
`qa/review-<N>.md` before merging. Six old PRs (#1284 #1274 #1277 #1278 #1276 #1280) stay as they are.

## Waiting for review

- B's fix for #1386 (Recipes room).
- A's simulator evidence: integrated plan items 1 to 9, open findings 1 to 15, and the #1363 / #1366 recordings.
- Any re-pin after a retarget or rebase (#1393 after #1391 merges).

## Standing checks (every PR)

- **G11 to G13** (integrated build plan): a tap on the apps list middle row opens its door; a tap on a side row
  centres it; a tap reaches its button under every hold or drag gesture, proven by a UI test. Any PR that adds or
  changes a gesture needs a UI tap test and at least one positive test (a swipe that commits shows UNDO), not only
  "nothing happened" tests.
- **Gesture policy**: `GestureTuning` / `GestureKit` only. Rows, pagers and pulls are simultaneous; an element that
  takes vertical swipes inside a scroll view (Home's one thing, the Weather hour strip) uses a high-priority drag and
  must have no tap targets under it, or a test proving taps still land.
- **Color count** (sheet color-roles-241): 3 to 4 colors per page, never 1, never 5 or more. State colors are the
  same in every room: go green = done, wine = late or warning, gold = best or new, slate = planned or labels; Money
  uses sage instead of green. New tokens: teal 1E6E77/84C3C9, clay 9C4B2C/E2A07F, gold 7E6A1E/D9C27A.
- **Big type**: two adjacent big type elements (title, hero name, stat numbers, focus word) never share a color.
  The action word may share the title's accent. Nothing within ΔE 10 of Ember (Notes violet 5B3FB8 is ΔE00 6: Design
  is fixing it).
- **Look**: no cards, pills, fades, blur (the Training routine wheel's depth blur is his exception), bars or chart
  furniture; no "..." or middle dots; sentence case; "best", never "record"; Reduce Motion cuts. Fixed text slots fit
  their words: use shorter words, never a smaller body font. Only big fixed titles step down, 1 pt at a time, to
  about 0.75x.
- **Walls**: walled titles read "Private ..." everywhere outside their room. Health, body, calendar and calories
  never reach backups, logs or widgets. Money actions are never offered to Claude (superseded Oct 27, 12:28 PM: Claude may propose money changes, each pending with 10 s Undo; room agents have no money tools). No money amount on Home. Sample
  data never touches his real store. The Claude key is never printed, logged, copied or asked for. Lab mode (his
  pick) lets Claude calls carry health, body, calendar, calories and money; strict keeps them out (no Body or Money
  agent, lab-only belief classes and day kinds dropped). Opus is a second-try rung only. One $100 monthly cap
  covers the phone and the Mac runner (runner stops at min($50, $100 minus the phone's month)). Forgetting purges
  every copy: the belief chain, the memory line, the op log (redact) and `memory-eval.json`.
- **Known flaky test**: `MosaicMomentSourceTests` reads the wall clock and fails between about 11:45 PM and
  12:10 AM PT. It belongs to Builder A (fix with an injected clock). Don't count it against other PRs in that window.
- **No CI**: `scripts/test.sh` must end "All green" before a PR opens. Cloud-written PRs are not compiled; Core runs
  `swift test` (and the app build) before merge.
