# QA review: #627 Core 0ai part 2, the engine wall

Head 5ea9a64. Static, full privacy depth. Merge-tree clean on master. 30 files, +856/-89. This extends my pre-review (qa/prereview-engine-wall.md); everything there is closed.

## Closed since the pre-review
- W1: `BodyWeight.kilograms` now needs a weigh word, or a weight unit with only day words beside it, strips clock times first, and ignores "bp 120/80", "ibuprofen 200 mg" and "squat 140 kg". W2: `lastKg` is cached per `TesseraContext.revision` (bumped on markDirty and delete, test `hisWeightIsReadOncePerChange`). W3: named numbers ("room 82", "bus 76 at 8", "ticket #84") are not his weight. W4: Tess and Siri say "Private note, kept." or the private-task line from the STORED title. W5: the EngineWall comment now matches CreateNote's rule. W6: tests for each outcome's receipt and for list lines matching what was kept.
- AI architecture's six points, seen in code: PlanPack takes `lastWeightKg` with no default (HomePlan passes it), ClaudeTessModel second wall, TessInbox add and drain, TessRouter `walled` check, TessCaptureEngine miss log, memory turnover third guard, RememberFact bare-weight refusal. Old-arity calls: none left (grep).
- SecretWords.isSecretListLine: a list line is secret with a value, or with a secret word that is not a thing to buy (pin, code, combo, combination stay groceries; password, passcode, pw, passphrase do not). "buy pins" and "combination lock" stay items. The Claude wall still uses `SecretWords.mentions` (any mention), so "buy pins" is stored but never leaves the phone.
- AddListItem: price comes off ("milk $4" is milk); only-money, secret or weight lines become a private note; a medicine or body fact stays on his list in his words and reads "Private item" in summary and receipt. DayStory counts grocery items and never prints their titles, so the log does not name them.
- Tests: WallsBypassTests runs the BN and BM rows from fixtures/walls-ui-phrases.json by surface (askBar, liveWorkoutAsk, modelWrite, toolWrite, rememberFact, memoryTurnover, planMyDay), with a guard test (`theFixtureIsRead`, at least 42 rows) so an unreadable fixture fails instead of passing empty. No key-shaped text in the new tests.

## Findings (none blocking)
- L1 (copy, confirm): a task with a medicine or body fact and no time becomes a private NOTE, not a task ("pick up lexapro" with no day). Product 8:13 PM says a medicine name is a health fact everywhere and a medicine reminder needs a time to be a private task, so this follows the ruling; confirm that "buy advil" typed as a task (no time) landing in Notes as "Private note" is wanted, since the list path keeps it as an item.
- L2 (over-wall, safe): AddListItem runs `isBareWeight` on the stripped line, so "80 stickers" or "buy 82 candles" is a private note when his last weight is about 82 (unit words outside the otherUnits list). Same for tasks. Add a count-noun exemption (a number followed by a plain word that is not a weight/day word) or a note in the receipt; low because it fails closed.
- L3 (edge): `BodyWeight.kilograms` with a weigh word takes the first in-range number, so "weighed squat at 140 kg" reads 140 as a weigh-in. Rare; the squat guard only applies without a weigh word.
- L4 (gate): the PR text says the app tests are queued. Releases need test.sh on the merged SHA plus walls-ui BM rows on the phone build; this is not a UI-visible change except the "Private item" and "Private note, kept." lines.

Verdict: PASS at 5ea9a64. Hold the release gate on app tests (L4).
