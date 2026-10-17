# Siri new intents fixture: "What's next in Tessera" and "Add oat milk to groceries in Tessera"

For Core (`TesseraIntents`), Builder A (shortcut phrases) and QA (walls rows). Research lab, docs only. Task CB, discovery gap 7 (`ops/discovery-gaps.md`, item 7). Date: 2026-10-17.

**Master read:** `origin/master`, hand-traced through `git show` (no Swift toolchain here, nothing was run). Every value is made up (hunter2, tacocat, 4417, 2100). Key rows are a build marker only (`"build": "KEY"`); the test builds the fake key in Swift (`ClaudeKeyTests.key`) and no key text is written in this file.

**Style:** same as `walls-ui-phrases.json` (siri rows S01 to S05, `WallsSiriTests`) and `siri-body-weight.md`. "Current" is what master does today; "Expected" is the target.

## 0. What exists and what does not

| thing | on master | file:line |
|---|---|---|
| Siri intents | LogSet, LogNextSet, UndoLastSet, StartRoutine, FinishWorkout, CreateTask, TellTess. No read-Home intent, no grocery intent | `TesseraCore/Sources/TesseraIntents/Intents.swift:9-203` |
| Phrases | six registered, none about today or groceries | `App/AppIntentsPackageLink.swift:15-26` |
| Home's one line | `HomeLines.line(for:now:calendar:)` returns `HomeLine` (`text`, `hero`, `context`); quiet is "All quiet."; a rest day is `"\(RestDay.line)."` | `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:202`, `:157`, `:220` |
| Private-title rule | `PrivateFacts.isPrivateTitle` (secret word, money or body fact). Used for Siri read-backs at `Intents.swift:174` (task: "Task added." or "Task added for fri.") and `:199` (Tell Tess: "Saved."), and for the on-screen mask at `ObjectPrivacy.swift:35` (label "Private task", `:10`) | `PrivateFacts.swift:12` |
| Private-note line | `"\(SecretWords.title), kept."` | `Intents.swift:169` |
| Grocery write | `AddGroceries(lines:)`; receipt "Oat milk, on Groceries" (`Groceries.swift:434-445`); the grammar's own line is "Oat milk, on the list." or "Chickpeas, already on Groceries." (`TessCaptureEngine.swift:324-345`) | `Groceries.swift:403` |
| Engine wall | not built. `AddGroceries` row 9 of `engine-wall.md` is "F F F F" (not walled) | `fixtures/engine-wall.md` section 2, row 9 |

Rule for every row: **nothing leaves the phone.** Neither intent calls Claude, the on-device model or the network. A Siri read never says a number that came from a money or body fact. Every row marked [needs new intent] fails to compile or find its intent on master, so QA marks it pending until Core lands `WhatsNextIntent` and `AddGroceryIntent` (names are proposals).

## 1. Rules (decided by the existing walls, restated so each row can be checked)

1. **One table.** The read intent returns `HomeLines.line(for:)` text for the same fact Home shows. No second set of Siri words. A test builds the fact, asks both, and compares strings.
2. **Private or walled title is never read.** If the top item's title passes `PrivateFacts.isPrivateTitle` (`PrivateFacts.swift:12`), Siri says the masked form Home already uses: "Private task" in the title slot (`ObjectPrivacy.swift:10`, `:35`), so "Private task, 9 pm." For a locked phone Product may prefer the count form ("1 thing today."); flagged in section 4.
3. **No Claude call.** Pure rules, as `HomeLines` is (`HomeLines.swift:179-181`).
4. **No number from a money or body fact.** A task whose title holds 2100 or 82.4 is masked before the line is built, not after.
5. **Snippet in the baseline language** (widgets-and-snippets.md): the snippet shows the same line, in the phone's baseline language, not a translated paraphrase.
6. **A grocery write goes through the engine** (`AddGroceries`), by `.intent`. The engine-wall table decides: key refused; secret with a value becomes a private note; money or body fact becomes a private note; plain stays a grocery.
7. **A walled phrase never becomes a grocery title** and is never read back. The receipt for a private note is "Private note, kept." (`Intents.swift:169`).
8. **Receipt names the thing first**, e.g. "Oat milk, on Groceries." per tess-voice. Master says "Oat milk, on the list." (grammar) and "Oat milk, on Groceries" (action receipt). **Product to confirm the exact wording** (section 4).

## 2. Part A: "What's next in Tessera" (read Home's line)

State is the app's data at the time Siri is asked. Now is Thu Oct 15, 2026, 6:00 pm Pacific unless a row says otherwise.

| id | state | expected line (same as `HomeLines.line` for the same fact) | what leaves the phone | Swift Testing name (`WallsSiriTests`) | owner | file:line |
|---|---|---|---|---|---|---|
| R01 | Ordinary: top item is a timed task "Call mom" at 7 pm | "Call mom at 7 pm." (`HomeLines.swift:260`); snippet the same | nothing | `whatsNextOrdinaryTaskReadsHomeLine` | Core | [needs new intent] |
| R02 | Ordinary: top item is a planned routine "Pull A" with no time | "Pull A today." (`:262`) | nothing | `whatsNextPlannedRoutineReadsHomeLine` | Core | [needs new intent] |
| R03 | Ordinary: top item is a task for tomorrow | "<title> tomorrow." (`:262`) | nothing | `whatsNextTomorrowTaskReadsHomeLine` | Core | [needs new intent] |
| R04 | Top task is a secret word: "wifi password is hunter2" at 8 pm | "Private task, 8 pm." Never "wifi", never "hunter2". Title masked by the private-title rule (`PrivateFacts.swift:12`, `ObjectPrivacy.swift:35`) | nothing | `whatsNextSecretWordTaskReadsPrivateTask` | Core | [needs new intent] |
| R05 | Top task is a money task made before the wall: title "pay rent 2100 fri" | "Private task, Friday." No "2100", no "rent". After the wall (engine-wall.md rule 3a) the title is "Pay rent" and the line is "Pay rent Friday." with no amount anywhere | nothing | `whatsNextMoneyTaskNeverSpeaksTheAmount` | Core | [needs new intent] |
| R06 | Top task is a body-fact task: title "weighed 82.4 this morning" | "Private task, today." No "82.4" | nothing | `whatsNextBodyFactTaskNeverSpeaksTheNumber` | Core | [needs new intent] |
| R07 | Top task is a body-shaped bare phrase "knee hurts" at 9 pm | "Private task, 9 pm." | nothing | `whatsNextKneeTaskReadsPrivateTask` | Core | [needs new intent] |
| R08 | Top task is a medicine task, title "take 2 advil" at 9 pm (engine-wall rule 4a: stored as "Private task") | "Private task, 9 pm." Never "advil" | nothing | `whatsNextMedicineTaskReadsPrivateTask` | Core | [needs new intent] |
| R09 | Top task is a private note's linked task (title "Private task") | "Private task, <day or time>." same as R04, never the note body | nothing | `whatsNextPrivateTaskTitleReadsPrivateTask` | Core | [needs new intent] |
| R10 | Live workout running: "Pull A", set 3 of bench | "Bench press, set 3." (`:253-254`). The weight and reps are not in the line | nothing | `whatsNextLiveWorkoutReadsHomeLine` | Core | [needs new intent] |
| R11 | Live workout paused | "Bench press paused at set 3." (`:257`) | nothing | `whatsNextPausedWorkoutReadsHomeLine` | Core | [needs new intent] |
| R12 | Workout just finished with a best | "Pull A done. 1 best." (`:248`), "bests" for more. Never "record" | nothing | `whatsNextFinishedWorkoutSaysBestNotRecord` | Core | [needs new intent] |
| R13 | Rest day, no session planned | "Rest day." (`RestDay.line` plus stop, `:220`); snippet the same | nothing | `whatsNextRestDayReadsRestDayLine` | Core | [needs new intent] |
| R14 | Nothing planned, nothing open | "All quiet." (`HomeLines.quiet`, `:157`) | nothing | `whatsNextNothingPlannedReadsAllQuiet` | Core | [needs new intent] |
| R15 | Live cook, step 3 of "Lentil soup" | "Lentil soup, on step 3." (`:231`) | nothing | `whatsNextLiveCookReadsHomeLine` | Core | [needs new intent] |
| R16 | Shop in progress, 4 items left | "Groceries: 4 left." (`:234`) | nothing | `whatsNextShopInProgressReadsHomeLine` | Core | [needs new intent] |
| R17 | Locked phone, top task private (same as R04) | Same masked line. Siri asks Face ID first (`authenticationPolicy`, as `Intents.swift:134-135`); on a refusal it says nothing about the day | nothing | `whatsNextLockedPhoneNeverReadsPrivateWords` | Core | [needs new intent] |
| R18 | Claude key is saved and online; Claude is down; no key | The same line in all three. The probe's `claude` count is the same before and after | nothing (no Claude call) | `whatsNextNeverCallsClaude` | Core | [needs new intent] |
| R19 | Phone language is not English | The snippet shows the baseline-language line; the intent does not translate or send the line | nothing | `whatsNextSnippetUsesBaselineLanguage` | Core, Design | [needs new intent] |
| R20 | Parity: every fact kind in R01 to R16 | `intentText == HomeLines.line(for: fact).text` for each; a widget line and the Siri line never differ (gap 6 and 7 share the test) | nothing | `whatsNextAlwaysMatchesHomeLinesTable` | Core | [needs new intent] |
| R21 | Phrases: "What's next in Tessera", "What's up next in Tessera", "What's on in Tessera" | Registered as shortcut phrases with the app name in each; none says "Tess" for the app | nothing | `whatsNextShortcutPhrasesAllNameTessera` | Builder A | [needs new intent] |

## 3. Part B: "Add oat milk to groceries in Tessera" (add a grocery)

"Wall decides" follows the engine-wall table (`fixtures/engine-wall.md`, section 1 order: key, secret with a value, money, body). Current is what master does with the same phrase through `AddGroceries` called by the new intent (there is no wall on `AddGroceries` today, row 9 of the table).

| id | phrase said to Siri | expected result | receipt said back | what leaves the phone | Swift Testing name (`WallsSiriTests`) | owner | file:line |
|---|---|---|---|---|---|---|---|
| G01 | "Add oat milk to groceries in Tessera" | Grocery "oat milk" added through `AddGroceries`; the "to groceries" and "in Tessera" tails are cut | "Oat milk, on Groceries." (flag, section 4) | nothing | `addGroceryOatMilkWritesAGrocery` | Core | [needs new intent] |
| G02 | "Add eggs to my grocery list in Tessera" | Grocery "eggs" | "Eggs, on Groceries." | nothing | `addGroceryEggsWritesAGrocery` | Core | [needs new intent] |
| G03 | "Add 2 lemons to groceries in Tessera" | Grocery "lemons", quantity 2. Not money: "bought 2 lemons" stays plain (`engine-wall.md` rule 3) | "Lemons, on Groceries." | nothing | `addGroceryQuantityStaysAGrocery` | Core | [needs new intent] |
| G04 | "Add a dozen eggs and oat milk to groceries in Tessera" | Two groceries, one record, one undo | "Eggs and oat milk, on Groceries." (two names, `Groceries.swift:437-441`) | nothing | `addGroceryTwoItemsNamesBoth` | Core | [needs new intent] |
| G05 | "Add oat milk, eggs, rice, tea to groceries in Tessera" | Four groceries | "Oat milk, eggs and 2 more, on Groceries." | nothing | `addGroceryFourItemsNamesTwoAndCounts` | Core | [needs new intent] |
| G06 | Item already on the list: "oat milk" is open | No second row; the existing one is returned | "Oat milk, already on Groceries." (grammar says "already on Groceries.", `TessCaptureEngine.swift:340-342`) | nothing | `addGroceryDuplicateAddsNoSecondRow` | Core | [needs new intent] |
| G07 | Item matches a checked-off one from the last shop | Unchecked again, no second row | "Oat milk, on Groceries." | nothing | `addGroceryCheckedItemComesBackNotDuplicated` | Core | [needs new intent] |
| G08 | "Add wifi password hunter2 to groceries in Tessera" (secret word with a value) | Wall decides: private note (title "Private note", words only in its body). No grocery row, no ingredient. Rule 2 of the table | "Private note, kept." Never "wifi" or "hunter2" | nothing | `addGroceryWifiPasswordBecomesPrivateNote` | Core | [needs new intent] |
| G09 | "Add door code 4417 to groceries in Tessera" | Private note; no grocery | "Private note, kept." | nothing | `addGroceryDoorCodeBecomesPrivateNote` | Core | [needs new intent] |
| G10 | "Add wifi password to groceries in Tessera" (secret word, no value) | Ruled (Product 5:58 pm): a bare secret word becomes a private note, no grocery row | "Private note, kept." | nothing | `addGroceryBareSecretWordBecomesPrivateNote` | Core | [needs new intent] |
| G11 | "Add oat milk 4.50 to groceries in Tessera" (money-shaped) | Same as the Bar's grocery price rule: price dropped, grocery "oat milk" added, no amount in any title (`engine-wall.md` 3a, "like a grocery price"). | "Oat milk, on Groceries." Never "4.50" | nothing | `addGroceryPriceIsDroppedFromTheTitle` | Core | [needs new intent] |
| G12 | "Add paid 45.20 gas to groceries in Tessera" (past-tense money, amount, no day) | Private note dated now (rule 3b); no grocery | "Private note, kept." | nothing | `addGroceryPastTenseMoneyBecomesPrivateNote` | Core | [needs new intent] |
| G13 | "Add rent 2100 to groceries in Tessera" | Private note; no grocery "rent" | "Private note, kept." Never "2100" | nothing | `addGroceryRentAmountBecomesPrivateNote` | Core | [needs new intent] |
| G14 | "Add weighed 82.4 to groceries in Tessera" (body-shaped, `PrivateFacts.swift:81-109`) | Private note; no grocery | "Private note, kept." Never "82.4" | nothing | `addGroceryBodyWeightBecomesPrivateNote` | Core | [needs new intent] |
| G15 | "Add knee hurts to groceries in Tessera" | Private note; no grocery | "Private note, kept." | nothing | `addGroceryBodyFactBecomesPrivateNote` | Core | [needs new intent] |
| G16 | "Add took 2 advil to groceries in Tessera" | Private note (body fact); no grocery "advil" | "Private note, kept." | nothing | `addGroceryMedicineBecomesPrivateNote` | Core | [needs new intent] |
| G17 | Key-shaped paste: `"build": "KEY"` (the test builds the fake key in Swift from `ClaudeKeyTests.key`, and says "Add <key> to groceries in Tessera") | Refused. Nothing stored, logged, or kept as a note (`looksLikeClaudeKey`, `ClaudeKeyGuard.swift:13`) | "That looks like a Claude key. It goes in Review, under Claude." (`TessRouter.keyLine`, as S02) | nothing | `addGroceryKeyShapedPasteIsRefused` | Core | [needs new intent] |
| G18 | Mixed: "Add eggs and wifi password hunter2 to groceries in Tessera" | Eggs added; the secret line becomes one private note (engine-wall.md row 9: "eggs added, one PN") | "Eggs, on Groceries." then nothing about the secret; the secret line is never named | nothing | `addGroceryMixedAddsEggsAndOneNote` | Core | [needs new intent] |
| G19 | No item said: "Add to groceries in Tessera" | Siri asks "What should I add?" and writes nothing (like "What's the task?", `Intents.swift:127`) | "What should I add?" | nothing | `addGroceryNoItemAsksForOne` | Core | [needs new intent] |
| G20 | The "in Tessera" tail alone: "oat milk in Tessera" in the item slot | The tail is cut like "to groceries"; the title is "oat milk", never "oat milk in Tessera" | "Oat milk, on Groceries." | nothing | `addGroceryCutsTheInTesseraTail` | Core | [needs new intent] |
| G21 | A grocery title is never private: after G01 to G18 | No grocery row, ingredient, list item or Shop line holds hunter2, tacocat, 4417, 2100, 4.50 as a title (scan the store) | nothing | nothing | `addGroceryNoWalledPhraseEverBecomesATitle` | QA | [needs new intent] |
| G22 | A walled phrase is not read back: after G08 to G16 | The spoken dialog for each is "Private note, kept." only; it contains none of the phrase's words | nothing | nothing | `addGroceryWalledPhraseIsNeverReadBack` | QA | [needs new intent] |
| G23 | No Claude, no model, no miss log | The probe's `claude` count and `misses` count are unchanged after G01 to G18 | nothing | nothing | `addGroceryNeverCallsClaudeOrMissLog` | QA | [needs new intent] |
| G24 | Locked phone | Face ID first (`authenticationPolicy = .requiresAuthentication`, as `Intents.swift:134-135`); a refusal writes nothing | none | nothing | `addGroceryLockedPhoneRequiresAuthentication` | Core | [needs new intent] |
| G25 | Parity with the Bar: the same item typed in the Ask bar | Same op record shape (one `AddGroceries`, `by: .intent` vs `.tess`) and the same wall answer for every phrase in G01 to G18 | nothing | nothing | `addGroceryMatchesTheBarForEveryPhrase` | Core | [needs new intent] |
| G26 | Phrases: "Add oat milk to groceries in Tessera", "Add eggs to my list in Tessera", "Put milk on my shopping list in Tessera" | Registered as shortcut phrases, each with the app name; parameter is a free-text item | nothing | nothing | `addGroceryShortcutPhrasesAllNameTessera` | Builder A | [needs new intent] |
| G27 | Snippet after G01 | Shows the receipt line and an Undo; the snippet reads in the baseline language | nothing | nothing | `addGrocerySnippetShowsReceiptAndUndo` | Core, Design | [needs new intent] |
| G28 | Undo after G01 | One undo removes the grocery; the line says "Oat milk, off your list." (flag, section 4) | nothing | nothing | `addGroceryUndoRemovesTheGrocery` | Core | [needs new intent] |

## 4. Product to confirm

1. **Receipt wording (ruled, Product 5:58 pm).** "Oat milk, on Groceries." per the 2:09 ruling; master's grammar line "on the list." (`TessCaptureEngine.swift:345`) changes to match. One wording for the Bar and Siri, so parity row G25 can compare strings.
2. **Private title read aloud (ruled, Product 5:58 pm).** "Private task, 8 pm." (comma, no "at" before a time, per the 5:11 rule). R04 to R09 assert it.
3. **G10 (ruled, Product 5:58 pm).** A bare secret word becomes a private note.
4. **G11 (ruled, Product 5:58 pm).** A price on a grocery is dropped (2:09), not kept as a private note, because it is not a money line.
5. **Intent names** `WhatsNextIntent` and `AddGroceryIntent` are proposals.

## 5. Test shape

Suite `WallsSiriTests` in `TesseraCore/Tests/TesseraCoreTests/`, next to `SiriParityTests.swift`, calling the intents' own entry points (`WhatsNextIntent.read(engine:now:)`, `AddGroceryIntent.add(_:engine:)`, same pattern as `CreateTaskIntent.add`, `Intents.swift:154`). Rows are Swift Testing `@Test(arguments:)`, one row each, so a fail names the row. Rows R01 to R21 and G01 to G28 are 49 rows. Every row marked [needs new intent] stays pending until Core lands the two intents, then flips on the same PR.

```swift
@Test("what's next never reads a private title", arguments: PrivateTopTasks.all)
func whatsNextPrivateTitleNeverRead(row: PrivateTopTask) async throws { /* R04 to R09 */ }

@Test("a walled grocery phrase becomes a private note", arguments: WalledGroceryPhrases.all)
func addGroceryWalledPhraseBecomesPrivateNote(row: WalledGroceryPhrase) async throws { /* G08 to G16, G18 */ }
```
