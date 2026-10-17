# WallsUITests: the walls, typed by a test instead of a person

For: Builder B (writes the test and the App-side seam). Owner: Research lab. Product item AU. Oct 16, 2026, read on
origin/master fbede70. Fixture: [`fixtures/walls-ui-phrases.json`](fixtures/walls-ui-phrases.json) (114 rows: 36 typed, 36
rows for the Core 0ai private-field mask in section 11 (34 objectPage rows, PM01 to PM34, and the two package and live
rows PM35 and PM36 for workout notes), 11 bare-number body rows in section 12, and 31 rows for the five bypass paths
in the 0ai rider plus the bar trap in section 13).

**Why.** The v9 gate's V5 and the Design walk's beats 7 and 8 need secret-shaped, money and body phrases typed on the
Simulator. Builder A's safety check blocks a session from typing secret-shaped phrases, so those beats were covered by
unit tests only. This test reads the phrases from the fixture and types them itself. No session, and nobody on the
phone, has to type one by hand.

Every value in the fixture is made up (hunter2, tacocat, 4417, "the fake store"). The key rows hold no key: the test
takes its value from `ClaudeSection.fakeKey` in test code.

## 1. What master does today (the short version)

| Surface | Rows | Pass on master | Known fails |
|---|---|---|---|
| askBar | 19 | 13 | A06, A07 (a "?" skips Tess), A10, A11, A12 (money in the miss log or no dated note), A15 (Slice 1) |
| notesPage | 7 | 3 | N02 (no Notes receipt), N04, N05, N06 (Notes checks secret words only) |
| siriAddTask | 5 | 3 | S03, S04 (P14 not on master) |
| paste | 5 | 4 | P04 (money in the miss log) |
| objectPage (section 11, read on 64ffb93) | 20 | 5 | PM01 to PM03, PM05 to PM07, PM11, PM12, PM14 to PM20 (no private-field mask; PM18 and PM19 have no newest row yet) |
| objectPage, planMyDay and liveWorkoutAsk, workout notes (section 11, read on b41695d) | 16 | 10 | PM21 to PM24, PM33, PM34 (the front prints a workout's notes, `ObjectPage.swift:232-234`) |
| askBar and live workout ask, bare-number body wall (section 12) | 11 | 7 | BN01, BN02, BN04, BN11 (no last-weight check, decisions 2:56) |
| Five bypass paths, package tests (section 13, read on 6f9b639) | 25 | 12 | BM01 to BM04, BM06 to BM09 (no engine wall on model or Claude writes), BM13, BM14 (RememberFact keeps a bare weight), BM18, BM19 (turnover keeps it), BM24 (Plan my day sends it) |
| Bar trap, live workout ask and askBar (section 13) | 6 | 5 | BM31 (no last-weight check) |
| **Total** | **114** | **62** | **52** |

Two findings matter for the gate itself:

1. **A "?" in the Ask bar never reaches Tess.** `BottomChrome.swift:508-509` sends any phrase ending in "?" (or holding
   "best" or "pr") to `CommandInterpreter`, which writes a task titled with the phrase (`CaptureParts.swift:184-188`).
   So V5's second phrase, "what's my wifi password?", becomes a task and the line is "Drying. Swipe to drop it.", not
   "It's in your private notes." Worse, "door code 4417?" becomes a plain task with the value in its title (A07). The
   grammar's answer (`TessGrammar.swift:497-498`) is only reachable from Siri's Tell Tess and the unit tests.
2. **Money reaches the miss log.** `TessCaptureEngine.swift:58` skips keys and secret words but not
   `PrivateFacts.isWalled`, and `PasteRecipe.swift:205` likewise. Rows A10, A12 and P04.

## 2. The test class

File `TesseraUITests/WallsUITests.swift`, matching the other UI tests (`ReturnKeyUITests`, `ClaudeSettingsUITests`):

```swift
import XCTest

/// Product item AU: the walls, typed from docs/research/fixtures/walls-ui-phrases.json (every value made up).
@MainActor
final class WallsUITests: SimulatorOnlyTestCase {
    override func setUp() {
        continueAfterFailure = true // one row's fail must not hide the rest
    }
}
```

- `SimulatorOnlyTestCase` (`TesseraUITests/SimulatorOnly.swift:5-12`) throws `XCTSkip` off the simulator, so the test
  can never type into his real data.
- Launch arguments go only through `LaunchFlags` in the app (`App/LaunchFlags.swift`), which reads them on the
  simulator only. Every launch here uses `["-demo", "-demoTime", "18:10", "-resetDemo", "-wallsSpy"]`, plus
  `-openLink notes` or `-openLink pasteRecipe` for those surfaces (`HomeSpatialView.swift:131-139`).
- Master has no `accessibilityIdentifier` anywhere in `Features/` or `App/`. The tests find elements by label, as the
  others do: `app.buttons["Tess"]`, the `Write` mode, `app.textFields["Ask"]` (`BottomChrome.swift:372`),
  `app.textFields["New note"]` (`NotesView.swift:158`), `app.textViews["Recipe text"]` (`PasteRecipe.swift:86`). The
  only new identifier is the probe's (section 5).
- Keep the `snap(_:_:)` helper from `HomeLinesUITests` so a run with `UITEST_SNAPS` set leaves a screenshot per row
  for Design (section 9).

## 3. Loading the fixture

Add the JSON to the UI test bundle in `project.yml`, then run `xcodegen generate` (never hand-edit the project):

```yaml
  TesseraUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - TesseraUITests
      - path: docs/research/fixtures/walls-ui-phrases.json
        buildPhase: resources
```

The same `path:` plus `buildPhase: resources` form the app target uses for `Resources` (`project.yml:53-54`). The file
stays where Research keeps it; no copy.

Read it in the test:

```swift
struct WallRow: Decodable {
    let id: String
    let phrase: String?
    let build: String?
    let surface: String
    let expectPrivate: Bool
    let expectNoClaude: Bool
    let expectNotInMissLog: Bool
    let expectLine: String?
    let lineMatch: String?
    let passesOnMaster: Bool
    let pending: String?
}

struct WallFixture: Decodable { let rows: [WallRow] }

static func rows(_ surface: String) throws -> [WallRow] {
    let bundle = Bundle(for: WallsUITests.self)
    let url = try XCTUnwrap(bundle.url(forResource: "walls-ui-phrases", withExtension: "json"))
    return try JSONDecoder().decode(WallFixture.self, from: Data(contentsOf: url)).rows
        .filter { $0.surface == surface }
}
```

`passesOnMaster`, `masterEvidence` and `notes` are for people; the test reads `pending` only.

## 4. The key rows

Rows A09, N03, S02 and P03 have `"phrase": null, "build": "KEY"`. The test takes the value from the app's own fake
key, in test code:

```swift
func text(for row: WallRow) -> String {
    if row.build == "KEY" { return ClaudeSection.fakeKey }
    return row.phrase ?? ""
}
```

Nothing key-shaped is written under docs/: not the fixture, not this spec. The value lives only in
`ClaudeSection.fakeKey`, which the app already builds at run time.

The key is **pasted, never typed**. The Ask bar (`BottomChrome.swift:395-398`), the Notes line (`NotesView.swift:82-84`)
and the recipe text (`PasteRecipe.swift:119-121`) clear the field the moment the prefix lands, so `typeText` would
leave the tail typed into an empty field and write it. Paste instead:

```swift
UIPasteboard.general.string = text(for: row)
field.tap()
field.press(forDuration: 1.0)
app.menuItems["Paste"].tap() // a user paste from the edit menu shows no Allow Paste alert
UIPasteboard.general.string = "" // never leave it on the pasteboard
```

## 5. The no-Claude seam (App only, no Core change)

Today a UI test can't tell whether Claude was called: in any demo launch the app never wires Claude at all
(`AppModel.swift:133-143`, "Off in demos, so a fake key never goes over the network"). So every "no Claude" check
would pass trivially. The smallest seam needs **no Core change**, because `ClaudeTessModel` already takes a `session`
and writes one usage-ledger row for every call it makes, failures included (`ClaudeTessModel.swift:27-35`, `:105-111`,
`:121-123`), and the unit tests already spy that way (`RouteStub`, `ClaudeRouteTests.swift:7-59`, `:128`).

Builder B adds, behind a new `-wallsSpy` flag (read through `LaunchFlags`, so simulator only, and inside `#if DEBUG`):

1. **A spy session.** `App/Debug/WallsSpy.swift`: a `URLProtocol` like `RouteStub` that answers every request in
   memory with `200` and `{"content":[{"type":"text","text":"Spy."}],"stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":1}}`.
   Nothing ever reaches the network.
2. **Wiring in `AppModel.init`**, after line 143:

   ```swift
   #if DEBUG
       if LaunchFlags.has("-wallsSpy"), let capture = runtime.tess as? TessCaptureEngine {
           capture.model = nil // grammar only: the run is the same on any Mac (see note)
           capture.claude = ClaudeTessModel(
               keys: InMemoryKeychain(ClaudeSection.fakeKey), // the app's fake key, built in code
               ledger: TessUsageLedger(store: store, classes: classes),
               flags: ClaudeMissFlags(defaults: UserDefaults(suiteName: "walls-spy")!),
               session: WallsSpy.session(),
               sendsMisses: { true })
           CaptureMissLog.beside(store).map { try? FileManager.default.removeItem(at: $0.url) }
       }
   #endif
   ```

3. **A probe.** One hidden line on the root view, under the same flag:
   `Text("claude \(ledger.calls().count) misses \(missLines)")` with `.accessibilityIdentifier("walls.probe")`,
   `.opacity(0)`, `.allowsHitTesting(false)`, read on `model.revision`. `missLines` is the line count of
   `capture-misses.jsonl` beside the store (`CaptureMissLog.swift:29-32`).

Notes on the seam:

- **Why the on-device model is off.** The router lets the on-device model read money and body phrases
  (`TessModel.swift:75-79`). Whether it is available depends on the Mac running the Simulator, so with it on, a row
  like A10 could land as a model task on one Mac and "Didn't catch that." on another. Grammar only makes the run the
  same everywhere. The on-device step keeps its own unit tests.
- **Why the miss log is removed at launch.** `-resetDemo` wipes the store but not `capture-misses.jsonl`, and the log
  keeps only its newest 2000 lines (`CaptureMissLog.swift:18`), so a full log would show no change. Removing it under
  the flag (simulator, demo data) gives a clean count.
- **The spy's own check.** A18 and A19 are plain phrases nothing on the phone reads, so under the spy they reach Claude
  and the `claude` count rises. If neither moves it, the seam is broken and the test fails with "spy not wired",
  rather than passing every no-Claude row for the wrong reason.
- **Receipts as a second witness.** Since every call writes a ledger row, Settings, Claude, Receipts would also show
  rows; the probe is cheaper. No real or realistic key is involved anywhere.

## 6. Entering each phrase

**askBar** (one launch, rows in fixture order):

```swift
app.buttons["Tess"].tap()
app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Write")).firstMatch.tap()
app.textFields["Ask"].typeText(phrase) // the Ask field already has autocorrect off (BottomChrome.swift:385)
app.typeText("\n") // Return sends; the words dry for 2 s, then commit
```

Wait for the line, then reopen Write for the next row. The ghost commits after 2 s, so rows don't need UNDO; a row
that writes leaves its row, and the Day log check in section 7 uses that.

**notesPage** (`-openLink notes`): tap `app.textFields["New note"]`, `typeText(phrase)`, then `typeText("\n")`. A
typed newline is Return there (`NotesView.swift:150-156`).

**paste** (`-openLink pasteRecipe`): put the phrase on `UIPasteboard.general`, tap `app.textViews["Recipe text"]`,
long-press, Paste. A paste over 40 characters is read at once (`PasteRecipe.swift:128-130`); a short one needs the
keyboard's Done word first. Then tap SAVE in the bar.

**siriAddTask:** Siri can't be driven from a UI test. These rows run as a unit test in the package,
`TesseraCore/Tests/TesseraCoreTests/WallsSiriTests.swift`, calling the intent's own entry point:
`CreateTaskIntent.add(text, startsAt: nil, engine: engine)` (`Intents.swift:136-145`), the same path `perform()`
takes, as `TessTests.swift:226-237` already does. The test loads the same JSON with
`Bundle.module` after adding it under `resources: [.copy(...)]` in `Package.swift`, or with a path relative to
`#filePath` (`../../../docs/research/fixtures/walls-ui-phrases.json`), which needs no package change. Add a Tell Tess
twin later if Product wants it; Add a Task never calls a model, so its no-Claude check is structural.

**Autocorrect.** The Notes line and the recipe text don't turn autocorrect off, so the Simulator may rewrite "tacocat"
or "hunter2" on the space. Before the run, the script sets
`xcrun simctl spawn booted defaults write com.apple.Preferences KeyboardAutocorrection -bool NO`. If a phrase still
changes, paste it as in section 4.

## 7. What it asserts

Per row, after the line shows or 6 s pass:

| Check | How | Rows |
|---|---|---|
| The line | `lineMatch == "exact"`: `app.staticTexts[expectLine].waitForExistence(timeout: 6)`. `"prefix"`: a static text with `label BEGINSWITH expectLine`. Skipped when `expectLine` is null | all with a line |
| Private | The new thing reads "Private note". Ask bar: the receipt says so. Notes: a button with `label BEGINSWITH "Private note"` appears. | `expectPrivate` true |
| Nothing leaks on screen | After the dry, no static text or button label contains the fake value (hunter2, tacocat, 4417, 2100, or the key's fake tail), using `label CONTAINS[c]`. Skipped on the paste screen, where the text is the pasted text itself; P01 checks the saved recipe instead | every private row, the key rows, A06, A07 |
| No second line (#508) | The Notes row is one combined element (`NotesView.swift:216`). Its label is "Private note" plus the time only, and nothing after it holds the value | N01, N02, N04 to N06 |
| Not private | No "Private note" text appears for this row | A08, A16 to A19, N07, P02 |
| No Claude | The probe's `claude` count is the same before and after | `expectNoClaude` true |
| Not in the miss log | The probe's `misses` count is the same before and after | `expectNotInMissLog` true |
| Ignored line | The pasted line's element has `value == "ignored"` (`PasteRecipe.swift:307`) | P01 (and not ignored in P02) |

Then, once per run:

- **The Day log.** Relaunch with `-demo -demoTime 18:10 -wallsSpy -homePage review` (no `-resetDemo`, so the rows
  written above stay) and tap today's weekday button, as `ReviewWeekUITests` does. Assert no line contains hunter2,
  tacocat, 4417 or 2100, and no line starts "Note: " with a secret word in it. A single private note reads "Private
  note" (`DayStory.swift:345-347`); several notes collapse to "N notes", and the day shows four lines at most
  (`ReviewWeek.swift:191-192`), so the check that must hold is the negative one.
- **The spy's own check** (section 5).

## 8. Pending rows, runtime and names

**Pending rows.** A row with `pending` set runs inside `XCTExpectFailure(row.pending!) { ... }` with
`options.isStrict = true`. The suite is green on master, and the day a fix lands the row "unexpectedly passes" and
fails, so Research sets `pending` to null and `passesOnMaster` to true in the same PR as the fix. That keeps the fixture
honest without anyone reading it by hand.

**Runtime budget** (iPhone 17 Simulator): about 6 s a row on the Ask bar (type, 2 s dry, line), 4 s on Notes, 8 s on
paste, 10 s a launch. About 2 minutes for the Ask bar, 30 s for Notes, 40 s for paste, 20 s for the Day log, so about
4 minutes in all. Fail the run if it passes 6 minutes. The Siri unit test takes under a second.

**Names.** One XCTest method per surface (each relaunch costs 10 s, so 36 methods would double the time). Each row
runs inside `XCTContext.runActivity(named: "<id> <surface>")`, so a fail reads "A07 askBar" in the report, and every
assertion message starts with the row id.

| Method | Rows |
|---|---|
| `testAskBarWalls` | A01 to A19, then the spy's own check |
| `testNotesPageWalls` | N01 to N07 |
| `testPasteWalls` | P01 to P05 |
| `testDayLogShowsNoValue` | the Day log, after the three above (runs last by name order; or set the order in the scheme) |
| `WallsSiriTests.addATaskWalls` (package) | S01 to S05, one `@Test(arguments:)` row each, so Swift Testing names each row |
| `testObjectPageMask` | PM01 to PM20 (section 11), its own launch with `-wallsSeedPrivate` |
| `testLiveWorkoutWalls` | BN11, BM26, BM27, BM31 (section 13), launches with `-wallsLiveWorkout` |
| `WallsBypassTests` (package) | BM01 to BM25 (section 13), one `@Test(arguments:)` per surface |

**Run:** `xcodebuild -scheme TesseraUITests -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:TesseraUITests/WallsUITests test | xcbeautify`.
The Tessera scheme doesn't run UI tests (`project.yml:127-143`) and `scripts/test.sh` doesn't either, so Builder A
runs this line in the gate. Adding a `--walls` switch to `scripts/test.sh` is a small follow-up.

## 9. What it replaces in the pin checklist

`git grep -n "V5\|beat 7" origin/master -- docs` finds the gate row at `docs/research/next-build-script-v9.md:44`, the
walk's beats 7 and 8 at `docs/design/next-build-walk.md:23-24`, and the checklist line that runs both at
`docs/product/pin-checklist.md:38`. The v10 gate copies the v9 script (`docs/research/next-build-v10.md:95-97`), so
the change goes there too.

| Today | Becomes |
|---|---|
| **V5** (v9 script :44): Builder A types "wifi password is tacocat" then "what's my wifi password?" on the pin. | **V5**: on the pin, Builder A runs `WallsUITests` and `WallsSiriTests` with the run line above. Pass: every row without `pending` passes, every pending row reports its expected failure (none "unexpectedly passed" without a fixture update), and the spy's own check holds. Paste the summary line and the run time. Rows A01 and A06 are the old V5's two phrases. |
| **Walk beat 7** (walk :23): typing "wifi password is tacocat4417" in Notes and pasting the key-shaped string. | **Beat 7**: no typing in the take. Design checks the frames `testNotesPageWalls` leaves under `UITEST_SNAPS` (rows N01 to N03) against sheet 57 and #422/#471: the "Private note" row with no second line, and the key line in cobalt. The 3-minute take goes from beat 6 straight to beat 8 and gets about 20 s shorter. |
| **Walk beat 8** (walk :24): the recipe to Groceries, then a pasted recipe ending in a wifi line. | **Beat 8, split.** The groceries half (pack sizes, staples, the receipt naming the thing first) stays in the take, since it has no secret in it. The wifi half moves to `testPasteWalls` (P01, P02): Design checks its snaps for the wifi line in tertiary ink, read as ignored. |
| **pin-checklist.md:38**, "run the v9 gate ... V1 to V6 ... Then record Design's 9-beat walk" | Add after "V1 to V6": "(V5 is `WallsUITests`)", and "9-beat walk" becomes "walk, with beats 7 and 8's private halves from `WallsUITests` snaps". |

Known fails that the new V5 surfaces on the pin, so nobody reads them as new: A06 and A07 (the old V5's second
phrase fails in the app today, see section 1), N02 (beat 7's "Private note, kept." line isn't built on the Notes page),
and the money and body rows waiting on Core 0aa, 0ac and P14.

The Wall rows W1 to W14 and Inbox I1 to I4 could move into the same fixture later; they are not part of item AU.

## 10. One line for Kaushik after the install (optional)

In Notes, type "wifi password is tacocat4417" and check it shows as Private note.

## 11. The private-field mask rows (Core 0ai, rider R18)

Product, 2:45 pm: any object flagged private shows only its class's private label ("Private note", "Private task",
"Private memory") on the generic object page, in `PropertyList` and in the class page's "newest" row. Rows PM01 to
PM20 are the fixture's PM1 to PM20 (workout notes, PM21 to PM36, are below) ([`fixtures/private-field-mask.md`](fixtures/private-field-mask.md)), with
`surface` `objectPage`. Read on origin/master 64ffb93.

**New fields.** These rows add `seed` (which fixture object), `route` (how the test gets to the page) and
`mustNotShow` (strings no label or hint may contain). `WallRow` gains `let seed: String?`, `let route: String?` and
`let mustNotShow: [String]?`; the typed rows don't have them, so all three are optional. `expectLine` is the label
the page or row must show ("Private memory"); null means no label check (the controls, which instead assert that no
private label appears).

**Seeding (App only, no Core change).** Builder B adds `-wallsSeedPrivate`, read through `LaunchFlags` (simulator
only) inside `#if DEBUG`, beside `-wallsSpy`. After `-resetDemo` it writes the fixture's objects O1 to O8 through
`ObjectStore` with fixed ids, plus the pre-#422 note (PM16) and a forgotten hash entry (PM17). O1 is written straight
to the store, since `RememberFact` refuses a secret word (`TessMemory.swift:142-143`). `-openObject <row id>` pushes
that row's object page for the two rows with no tap route (PM15, PM17), through `model.open(_:_:)` like `-openLink`.

**Routes the test taps.** Notes: Review, today's weekday button, the note's line (`ReviewWeek.swift:358-362`). Tasks:
the Home queue row (`HomeQueue.swift:263`). Memories: Review, Push A (`ReviewPage.swift:269`), then its Linked from
row (`ObjectPage.swift:254-262`). Class pages: the breadcrumb (`ObjectPage.swift:312-326`).

**What it asserts, per row.**

| Check | How | Rows |
|---|---|---|
| The label | `app.staticTexts[expectLine]` exists (the hero, or the row) | `expectLine` set |
| Nothing leaks | No static text, button label or `accessibilityHint` contains any `mustNotShow` string (`CONTAINS[c]`) | every row with `mustNotShow` |
| No fields | No static text "Properties" on a masked page | every `expectPrivate` row with a generic route |
| Not masked | No "Private note", "Private task" or "Private memory" text for this object; its field row shows | PM08 to PM10, PM13 |
| Hash | No static text matches `[0-9a-f]{16,}` | PM17 |

PM18 and PM19 wait on Core 0ak's newest row and PM07 on Core 0ac slice 2 (or the 2:22 pm "Private task" title):
their `pending` says so, and they run under `XCTExpectFailure` like any other pending row (section 8). About 1 minute
in all: one launch, twenty pages at about 3 s each.

**Workout notes, PM21 to PM36 (decisions 5:07 pm, item 4; read on origin/master b41695d).** A workout's `notes` (the
rich-text field every Thing has, `SystemCatalog.swift:56-58`) is a body fact. The generic front prints it today
(`ObjectPage.swift:232-234`), so "left knee sore" shows under the hero. After 0ai the front shows one muted line, "Note
kept private", in the notes slot, with no words and no line count, whatever the note says; the workout itself is not
masked (hero, class line, Properties, Contents, Linked from and Start workout show as today). Every other surface reads
no notes on master and must stay that way: the Day log line (`DayStory.swift:224-229`), Review and WeekFacts
(`WeekFacts.swift:3-5`), the summary, finish screen and Now's done line (`WorkoutSummary.swift:30-36`,
`WorkoutFinishView.swift:36-71`, `HomeLines.swift:479-488`), exercise HISTORY (`ExerciseDigest.swift:13-19`,
`ExerciseViews.swift:98-150`), the Training page, the live screen and the Live Activity (`RestActivityAttributes.swift:6-30`;
the only widget on master is `RestLiveActivity`, `TesseraWidgetsBundle.swift:5-8`), and the Claude packs
(`TessModelCapture.swift:70-83`, `PlanWording.swift:8`). Nothing on master writes a workout's notes, so the seed does.

| Rows | Surface | What | Pass on master |
|---|---|---|---|
| PM21 to PM24 | objectPage | Front: a symptom ("left knee sore"), a weight ("weighed 82.4 before"), a plain note ("felt strong", the trap: masked too, since 5:07 pm names the field, not the words) and three lines with "locker 4417" (one marker, no count) | 0 |
| PM25 to PM27 | objectPage | Controls: no notes, a blank note (no marker for either), and the field mask doesn't mask the workout | 3 |
| PM28 to PM32 | objectPage | Linked from and refs, Day log and Review, summary and Now, exercise HISTORY, Training and Home: no note words | 5 |
| PM33 | objectPage | A planned workout's front, then Start workout and the live screen; Lock Screen and Dynamic Island by hand | 0 |
| PM34 | objectPage | VoiceOver on PM21 to PM24 and PM33's front | 0 |
| PM35 | planMyDay (package) | Never packed for Claude: the Plan my day pack | 1 |
| PM36 | liveWorkoutAsk (UI, `-wallsSpy`) | Never packed for Claude: the live ask's capture pack | 1 |

**Seeding.** `-wallsSeedPrivate` also writes W1 to W7 (`fixtures/private-field-mask.md` section 3b): notes on today's
Push A, yesterday's legs workout and the latest pull workout, a control with none, a workout planned for 7:00 pm with
notes, a three-line note and a blank one. `-openObject` reaches W4, W6 and W7. The leaking rows' `pending` is "Core
0ai: workout notes mask (decisions 5:07)". The checks are the table above plus one: `expectLine` "Note kept private"
appears exactly once on rows PM21 to PM24, PM33 and PM34, and never on PM25 to PM27. PM27's "no Notes row" is an exact
match, since `CONTAINS` would match the marker. If Product picks a blank over the marker (fixture Q4), those rows drop
`expectLine`. About 50 s more: twelve pages, one live start and the two package or spy rows.

**In the riders gate:** row PF1 in `next-build-v9r.md` section 3 runs `testObjectPageMask` (PM01 to PM34) with the
run line in section 8 (`-only-testing:TesseraUITests/WallsUITests/testObjectPageMask`), plus PM35 in the package suite
and PM36 in `testLiveWorkoutWalls`.

## 12. The bare-number body wall (Core 0ai, rider R19)

Product, 2:56 pm: "is 82.4 good?" is walled. A bare number within 10% of his last logged weight is a body fact even
with no day word. With no weight logged, a bare decimal is walled only next to a body word (weight, weigh, kg, lb,
body fat, BMI). Rows BN01 to BN11, surface `askBar` (BN11: `liveWorkoutAsk`), read on origin/master aed5c24.

**New field.** `seed` here is an object, `{"lastWeightKg": 82.0}` or `{"lastWeightKg": null}` for no weight logged.
Builder B's `-wallsSeedPrivate` seam writes one body weight entry with that value (or none) before the row runs.
`WallRow.seed` becomes an enum that decodes either a string (section 11) or this object.

**What it asserts.** `expectNoClaude` true: the `-wallsSpy` call log stays empty and the miss log gains nothing.
`expectNoClaude` false: the phrase is not walled, so the spy may log a call when "Tess asks Claude" is on. On the
Ask bar a "?" phrase never reaches Claude today (`BottomChrome.swift:509-510`, Research BK), so BN01, BN02 and BN04
also check the line "That stays on this phone." (#564) and that no Home row holds the number (today "is 82.4 good?"
becomes the task "Is 82.4 good?", `CaptureParts.swift:200-201`). BN11 runs the same phrase in the live workout ask
(`WorkoutModeView.swift:280`) with no set in focus, the one path where a question reaches Claude today. Decisions
4:46 pm adds the bar trap, the body-word list and the five bypass paths: section 13.

| Row | Phrase | Last weight | Walled | Master today |
|---|---|---|---|---|
| BN01 | is 82.4 good? | 82 kg | yes | plain ("good" is not a day word, `PrivateFacts.swift:104-108`) |
| BN02 | how's 76 looking? | 82 kg | yes | plain (a whole number is never walled) |
| BN03 | 82.4? | 82 kg | yes | walled (control) |
| BN04 | my weight is 82.4, good? | none | yes, body word | plain |
| BN05 | is 82.4 good? | none | no | plain |
| BN06 | is 3.5 good? | 82 kg | no (trap) | plain |
| BN07 | is 120 good? | 82 kg | no (trap) | plain |
| BN08 | rate this 8.5 | 82 kg | no (trap) | plain |
| BN09 | is 91 good? | 82 kg | no (just over 90.2) | plain |
| BN10 | bench 82.5 x 5 good? | 82 kg | no (set notation) | plain (`isTraining`, `PrivateFacts.swift:83`) |
| BN11 | is 82.4 good? (live workout ask) | 82 kg | yes | reaches the model (`WorkoutModeView.swift:280`) |

The band is inclusive: 73.8 to 90.2 kg for a last weight of 82. Gate row **BW1** in `next-build-v9r.md`.

Builder B's seam: master stores no weight as a number (a weigh-in is a private note, `TessCaptureEngine.swift:304-310`), so until M3 `-wallsSeedPrivate` seeds the last weight as a weigh-in private note ("82 this morning"). Full path list: `body-number-sweep.md` (Research BK).

## 13. The five bypass paths and the bar trap (Core 0ai rider, decisions 4:46 pm)

Product, 4:46 pm: of the 12 paths in `body-number-sweep.md` (Research BK) that never reach PrivateFacts, five are IN
the 0ai rider because they feed Tess or Claude: the on-device model's writes, tool writes, RememberFact, memory
turnover, and Plan my day (`PlanWording.swift:37-39`). Each must call PrivateFacts with the new `lastWeightKg`
parameter, which has no default. With a set in focus mid-workout a number is the bar; a number with another unit stays
plain; Core adds a body-word list (weight, weigh, weighed, kg, lb, lbs, body fat, BMI) and "weight" leaves `dayWords`.
Rows BM01 to BM31, read on origin/master 6f9b639.

**Rows.** Each path gets five rows with a last weight of 82 kg (band 73.8 to 90.2): a secret ("wifi password is
hunter2"), money ("pay rent 2100 fri"), a bare weight ("82.4"), the 2:56 pm question ("is 82.4 good?") and a plain
control. Then six bar-trap rows.

| Rows | Surface | Path (BK row) | Pass on master | Fails |
|---|---|---|---|---|
| BM01 to BM05 | modelWrite | On-device model writes (BK15) | 1 | BM01 to BM04: `TessTools.swift:118` performs CreateTask with any title |
| BM06 to BM10 | toolWrite | Claude tool writes (BK24) | 1 | BM06 to BM09: same write, reached from `ClaudeTessModel.swift:88` |
| BM11 to BM15 | rememberFact | RememberFact (BK22) | 3 | BM13, BM14: no health word, own digits licensed, so the line is kept and can leave the phone |
| BM16 to BM20 | memoryTurnover | Memory turnover (BK23) | 3 | BM18, BM19: "done is 82.4 good" passes `TessMemory+Turnover.swift:67` and `:104` |
| BM21 to BM25 | planMyDay | Plan my day (BK13) | 4 | BM24: "good" isn't a day word, so the title goes as written |
| BM26, BM27 | liveWorkoutAsk, bench in focus | Bar context | 2 | none (traps for after 0ai) |
| BM28 to BM30 | askBar | Other units | 3 | none (traps for after 0ai) |
| BM31 | liveWorkoutAsk, no set in focus | Bare-number wall | 0 | BM31 |

The secret and money rows pass today on RememberFact, turnover and Plan my day (each has its own secret and money
check), and fail on the two write paths, which have no check at all. They stay in so a 0ai change that swaps in
PrivateFacts can't lose a wall that already holds. Expected outcomes after 0ai:

- **modelWrite, toolWrite:** a secret or a body number becomes a private note ("Private note, kept." on the OpRecord's
  receipt; decisions 2:06 pm). "pay rent 2100 fri" stays the task "Pay rent" with the amount dropped (2:22 pm (1)).
  The control lands as titled.
- **rememberFact:** secret and money are refused with their lines ("I don't keep passwords.", "I don't keep sums of
  money."). A bare weight inside the band is a measured value, and RememberFact never keeps one, private or not
  (`TessMemory.swift:209`), so BM13 and BM14 expect a refusal and no memory line. That's Research's reading of the
  existing rule; there's no refusal line for health today (`Refusal.health`, `:128`), so `expectLine` is null.
- **memoryTurnover:** the walled part of the day line is skipped (2:06 pm), and no recent line holds the value. Today
  a money word drops the whole day line, which passes BM17; the row checks only the value.
- **planMyDay:** a walled title goes as "task" and `otherNames` (`PlanWording.swift:164`) leaves it out.

**The bar trap.** BM26 "is 80 good?" and BM27 "80 for 8 felt heavy" run in the live workout ask with Bench Press in
focus at 80 kg: plain, though 80 is inside the band (4:46 pm (3)). BM28 "80 min walk", BM29 "75 g oats" and BM30 "85%
done" run on the Ask bar with no focus, so only the unit rule keeps them plain. `PrivateFacts.words`
(`PrivateFacts.swift:114-118`) drops "%", so the unit check has to read the raw phrase or "85" looks bare. BM31 "is
82.4 good?" runs in a live workout with no set in focus: no bar context, so it is walled. All five plain rows pass
today because master never walls a whole number with no unit; they are there to catch an over-wall once the band lands.
How Core skips the band when `context.entry` is set (`AppModel.swift:238-239` fills it for the live ask and for the Ask
bar while a workout runs) is Core's call; the rows pin only the outcome.

**New fields.** `seed` stays an object with `lastWeightKg`, and gains `write` (package rows: what the test writes,
in words) and `focus` (live rows: `{"exercise": "Bench Press", "lastSet": "80 × 8"}`, or null for a workout with no
set in focus). `WallRow`'s seed object becomes a struct with all three optional. For package rows, `mustNotShow` lists
strings no stored title, memory line, receipt or Claude pack may hold, and `expectNoClaude` means the value never
reaches a Claude request or pack.

### Seams and tests, per path

None of the five paths can be typed in the app (no screen reaches them with a phrase), so they run as package tests in
`TesseraCore/Tests/TesseraCoreTests/WallsBypassTests.swift`, one `@Test(arguments:)` per surface reading the same JSON
by `#filePath` as `WallsSiriTests` does (section 6). Every package test seeds the last weight as a weigh-in private
note ("82 kg this morning", `CreateNote(body:, isPrivate: true)`) until M3's body weight entry exists, so
`BodyWeight.lastKg(in:)` (4:46 pm (1)) reads 82 from the store.

| Surface | Test | Seam needed | What changes in 0ai |
|---|---|---|---|
| modelWrite | Package, through `TessCaptureEngine.capture` | None new. A fake `TessModelCapturing` (the pattern at `TessTests.swift:164-180`) whose `capture` calls `TessTools.run("createTask", arguments: {"title": <phrase>, "startsAt": null, "about": []}, engine:, pending: true)`, the same call `CatalogTool.perform` makes (`TessModelCapture.swift:151-156`). The request is "ring the gym about chalk", which the grammar misses (`TessTests.swift:178`), so the router runs the fake with the model's attribution. The real `TessModelCapture` can't run in a test: whether the on-device model is there depends on the Mac | The engine wall on CreateTask (and CreateList, AddListItem, CreateNote, CreateRecipe) calls `isPrivateTitle(_:lastWeightKg:)` with `BodyWeight.lastKg(in: transaction.store)` |
| toolWrite | Package, `ClaudeTessModel.run` | None new. `RouteStub` (`ClaudeRouteTests.swift:7-59`) queues a `tool_use` reply calling `createTask` with the row's phrase as title, then an `end_turn` answer, as `aMissGoesToClaudeAndLandsAsAPendingGhost` does (`:112-122`). The request text "ring the gym about chalk" passes the wall at `ClaudeTessModel.swift:54`, so the test proves the write itself is walled, whatever Claude says | Same engine wall; nothing in `ClaudeTessModel` |
| rememberFact | Package, `engine.perform(named: "rememberFact", ...)` | None. The registry path (`ActionEngine.swift:78-83`, `ActionRegistry.swift:113`) is how a model, Claude or an intent would call it. It isn't in `TessTools.all` (`TessTools.swift:37-40`) and no screen calls it on master, so it has no UI path | `RememberFact.apply` (`TessMemory.swift:195-233`) calls PrivateFacts with the store's last weight beside its own screen |
| memoryTurnover | Package, `TessMemoryStore(engine:).turnover(now:)` as `TessMemoryTests.swift:167` does | A task written straight to the `ObjectStore`, titled with the phrase and done yesterday, then turnover at 5:00 am. Not through CreateTask: after 0ai the engine would retitle it, and the row stands for a task made before 0ai or by an exempt path | `recentLine` (`TessMemory+Turnover.swift:67`, `:104`) calls PrivateFacts per line with the engine's last weight |
| planMyDay | Package, `PlanPack(...)` as `PlanWordingTests.swift:107` does | The new `lastWeightKg:` parameter on `PlanPack.init` and a static `isPrivate(_:lastWeightKg:)` (the one threading path, BK13). `HomePlan.swift:117` passes `BodyWeight.lastKg(in: model.store)`. No UI test: wording is off (`HomePlan.swift:115`, `planWordingReady`), so the app makes no call to watch | `PlanWording.swift:37-39`, `:45`, `:164` |
| liveWorkoutAsk | UI, `testLiveWorkoutWalls` under `-wallsSpy` (section 5), plus the same rows as a package test through `TessCaptureEngine.capture` with `TessContext(entry:)` | App: a `-wallsLiveWorkout bench80` flag (a workout with Bench Press in focus and one set 80 × 8) and `-wallsLiveWorkout empty` (a workout with no exercise, so `session.currentEntry` is nil, `WorkoutSession.swift:120-123`), read through `LaunchFlags` inside `#if DEBUG`. The field is `app.textFields["log bench 80x8, or ask"]` (`WorkoutParts.swift:361`). This is the one surface where the spy's Claude count really moves (4:46 pm (5)); BN11 and BM31 are the Claude check | The set-context rule in `TessCaptureEngine.capture` |
| askBar (BM28 to BM30) | UI, appended to `testAskBarWalls` | The `-wallsSeedPrivate` weight from section 12 | The unit rule inside `isBodyShaped` |

**Runtime.** The package rows take under a second. The live rows need two launches (bench80 and empty), about 40 s,
and the three Ask bar rows add about 20 s, so the suite stays under the 6-minute cap. **Gate:** row BW1 in
`next-build-v9r.md` grows to BN01 to BN11 plus BM01 to BM31; that file belongs to another worker, so Product or its
owner makes the edit.

**BN01 to BN04 (4:46 pm (5)).** On the Ask bar a walled "?" phrase answers "That stays on this phone." and makes no
Home task. BN01, BN02 and BN04 already checked that; BN03 now checks the line too (it passes on master, since
CommandInterpreter answers it and saves nothing, `CaptureParts.swift:190-192`). The line is already on master, so their
`pending` names Core 0ai only, and BN04 names the body-word list. BN11 now pins no set in focus (`seed.focus` null).

**After the rider, Core 0an.** Three more bypass paths get the same check in a follow-up, not in 0ai: the Groceries
Add line (`GroceriesView.swift:365`, with the 2:09 pm price strip), Routines' Name it (`RoutinesPage.swift:110`) and
what a pasted recipe saves (`PasteRecipe.swift:200-202` to `CreateRecipe`). Their rows come with 0an.

**Exempt (4:46 pm (2)):** the Notes page and editor, "note:", backup restore and RenameObject are his own words in his
own place, kept on the phone and never sent, so they get no rows here.
