# Test-gap audit, last 15 merges to origin/master (ab7d3bf, detached)

Read-only static audit. Scope: merges #553 to #583 (`git log --merges -15`). Code-bearing merges: 553ad19 (#580), 4757aef (#576), 648d9d0 (#553), e068e14 (merge of master into dst-night), da006da (merge of master), ab7d3bf (#583). The rest are docs, fixtures or Python only.

Ranked by risk.

1. gap: privacy mask in the object page has no UI or view test. Features/Objects/ObjectPage.swift:225-270 (privateLabel gates title, classLine, notes, PropertyList, Contents, Linked from). Only ObjectPrivacy unit tests exist (TesseraCore/Tests/TesseraCoreTests/ObjectPrivacyTests.swift). A leak here would not be caught.
2. gap: paste miss-log privacy branch untested. Features/Recipes/PasteRecipe.swift:206 (`!PrivateFacts.isWalled(text)`, da006da). No test references CaptureMissLog for money or body-fact text.
3. gap: new voice line on Home queue. Features/Home/HomeQueue.swift:478-480 ("\(entry.title), \(when)." and "next week"). No test asserts it. HomeQueueUITests.swift has no "Moved", "tomorrow" or "next week" check. Also verify that an untimed "Not now" really moves to next week (the `to:` target is passed, so the string may not match the move).
4. gap: CommandInterpreter private and failure branches. Features/Command/CaptureParts.swift:192 ("It's in your private notes." / "That stays on this phone." are covered at TesseraTests/AppModelTests.swift:115-116), but :195 and :202 ("Couldn't save that.") and :198 ("\(SecretWords.title), kept.") have no assertion. The apostrophe changed from U+2019 to ASCII in :195 and :202 with no test.
5. gap: Tess copy for a key-shaped literal in CaptureParts:187 is covered (AppModelTests.swift:120). No gap, listed for completeness.
6. gap (low): TessDates.ahead, branch saidDay && !saidTime with the hour at 22:xx (TessDates+FallBack.swift:7). The 23:10 case is covered (TimeWordsTests.swift:40, 83), the 22:xx case is not. Product intent (22:40 "today" becomes 7 am tomorrow) is unconfirmed.
7. gap (low): ReviewFootLineUITests.swift:9-14 hard-codes 736 of 874 and sleep(2). It covers the footLift constant (HomeSpatialView.swift:51, 199) but is timing-fragile.
8. gap (copy, "…" rule): TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift:22 "Reading \(host)…" is user-facing progress copy with a literal ellipsis.
9. gap (copy, "…" rule): TesseraCore/Sources/TesseraIntents/TesseraRuntime.swift:59 and :73 contain literal "…" in user-facing hint strings ("Tell Tess (\"note: …\")", "list: …").
10. gap (low): Theme.swift:282 default argument `ProcessInfo.processInfo.arguments` is a raw read outside the allowed set (App/LaunchFlags.swift, AppClock.swift:18, DemoData.swift:14). It goes through LaunchFlags.value(after:in:) so the simulator guard still applies. Route it through LaunchFlags to satisfy the rule.
11. false-positive-likely: "…" as a truncation glyph, not copy: Features/Objects/ObjectPage.swift:323, Features/Notes/NoteEditor.swift:208, TesseraCore/Sources/TesseraCore/Notes/Notes.swift:132.
12. false-positive-likely: Features/Tess/TessSoul.swift:95 reads ProcessInfo.isLowPowerModeEnabled, which is not an argv or environment read. tools/storage-spike/* is outside the app target.
13. false-positive-likely: "record" for personal best. No user-facing string uses "record" for a PB. ExerciseViews.swift:151 says "your best". Features/Home/ReviewWeek.swift:133 matches the word in the user's own text, not in copy. HomeLinesTests.swift:32 asserts "best".
14. false-positive-likely: UI test base class. All 10 UI test classes subclass SimulatorOnlyTestCase (TesseraUITests/SimulatorOnly.swift:5). No violation.
15. covered: DST and fall-back (FallBackNightTests.swift:27-47, TessMemoryTests.swift:152, DayStoryTests.swift:242, ReviewTripWeekTests.swift:196). Quiet-hours "Not now" (TimeWordsTests.swift:57-80, DayBoundaryTests.swift:54, TaskTests.swift:60-68). MoveTask summary "Stretch, moved to Later" (TaskTests.swift:68). TessCaptureEngine.when public (DayBoundaryTests.swift:78).
16. secret hygiene: key-shaped literals in tests, recorded by location only. TesseraTests/ClaudeKeySafetyTests.swift:7-8 (a key-shaped literal at file:line) and TesseraCore/Tests/TesseraCoreTests/ClaudeKeyTests.swift:179-180 (a key-shaped literal at file:line). Fixtures, not live keys. Consider a non-prefixed placeholder.

Totals: 4 gaps at privacy or copy risk (1-4), 4 low or copy gaps (6-10), 5 false-positive-likely, 1 secret-hygiene note.
