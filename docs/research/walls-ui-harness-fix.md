# WallsUITests harness fix: read `seed` and `mustNotShow`, clear the screen between rows

*Research, Sat Oct 17, 2026. For Builder B (#564), QA. Read by hand on #564's head aaa64dc and master 38cb7ab. Nothing was built or run. Every value is made up.*

## Why

BN01, BN02 and BN04 fail on master by code (the bare-number wall is Core 0ai, not in master), yet #564's `testAskBarWalls` reports "expected failure but none recorded" for them. The suite cannot see the failure:

1. **It never reads `seed`.** `WallRow` has no `seed`, so every row runs with the demo data and no last weight.
2. **It never reads `mustNotShow`.** The leak search runs only for `expectPrivate`, KEY rows and A06, A07, A20, A21 (`assertNoValue` also uses the fixed `fakeValues`, never the row's list). BN rows are none of these, so "82.4" on a Home task is never looked for.
3. **A stale line passes.** `assertLine` looks for the line text anywhere on screen. "That stays on this phone." from A20 or A21 can still be on screen when BN01 runs, so the line check passes for the wrong row.
4. **Nothing checks Home.** Decisions 4:46 pm (5) say a walled "?" phrase makes no Home task. The test never looks at Home.

## Changes (test code and the decode only; no app change beyond the seam walls-ui-test-spec.md section 12 already asks for)

1. **Decode.** `WallRow` gains `mustNotShow: [String]?` and `seed`, which decodes either a string (objectPage rows) or an object `{lastWeightKg: Double?, focus, write}` (section 12 and section 14). Unknown keys stay ignored. `harnessNote` is not used here.
2. **Seed groups.** Group the askBar rows by `seed.lastWeightKg` (82.0, null, or no seed). Launch once per group with `-wallsSeedPrivate` and that weight (the seam from section 12: one weigh-in private note, or none), in this order so the order of rows inside a group stays the fixture's. Either one test method per group or a relaunch when the value changes.
3. **Clear between rows.** Before each row's text is typed: close the Ask, then `waitForNonExistence` (8 s) of every distinct `expectLine` text in the fixture, not only this row's. If a line is still there, record a failure named "stale line, row cannot be trusted" and skip the row's checks (a pending row still records its expected failure, so it does not go green by accident). Do not relaunch for this.
4. **mustNotShow on every askBar row.** After the line check, close the Ask so Home is showing, then search the whole accessibility tree (`descendants(matching: .any)`, label contains, case-insensitive) for each string in the row's `mustNotShow`, plus `fakeValues` for private rows as now. This is the "no Home row holds the number" check: a task titled "Is 82.4 good?" on Home must be found.
5. **A control row, so the search is known to see.** After the fixture rows, type `buy milk 82.4` (not walled on master: it is an ordinary task) and require the search from step 4 to FIND "82.4" on Home. If it does not, fail with "leak search is blind", the same idea as the existing "spy not wired" check.
6. **Pending stays strict.** BN01, BN02 and BN04 keep `pending` (Core 0ai part 2). With steps 2 to 4 they fail for the right reasons on master: the line reads "Drying. Swipe to drop it." (not the expected line) and a Home task holds "82.4" or "76". Strict expected failure then records, and #564 is green.

## What to expect on the first run

Any row that was green only because of the stale line or the missing leak search will now go red. Builder B sends the list of newly red rows (ids only) to Research; Research marks them `passesOnMaster: false` with their pending owner, or tells Core if one is a real gap. Do not clear a pending flag to make a row green.

## Acceptance

- BN01, BN02 and BN04 each record their expected failure, and the failure message names the line or the Home leak, not "none recorded".
- The control row `buy milk 82.4` finds "82.4" on Home.
- A deliberately stale line (run A20, then BN01 with the closing step removed) fails the "stale line" check.
