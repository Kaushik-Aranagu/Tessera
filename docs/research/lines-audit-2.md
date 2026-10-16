# Lines audit 2: Tess, UNDO and empty-state lines since #158

For: Core, Builder A, Builder B, Design. Board item 89. 2026-10-16. Research lab.
Code read: `git diff 11f4648 origin/master -- '*.swift'` (148 commits, 97 Swift files; tests left out), traced by hand,
no simulator run. Checked against `tess-voice.md` (principles 1 to 8, M1 to M58, X1 to X21) and the undo rule: name
the thing, then what happened; Undo says the same name plus "taken back"; destructive writes keep UNDO for 10 s.
Baseline: `docs/research/undo-lines.md` and `docs/research/empty-states.md` (#158). Line numbers are origin/master.

Owners: Core = TesseraCore engine and grammar (including TesseraTess and TesseraIntents). Builder A = training,
workout, looks, widgets and the Live Activity. Builder B = Home (Now, Review), BottomChrome, Ask Tess, Settings: Claude,
Day log. Backups have no named owner; filed under Builder B as the Settings side of the app (Product to confirm).

## Summary

| Owner | ok | fix | Rows |
|---|---|---|---|
| Core | 15 | 13 | 28 |
| Builder A | 9 | 3 | 12 |
| Builder B | 13 | 8 | 21 |
| **All** | **37** | **24** | **61** |

Top 5 fixes:
1. **The empty wrap-up deletes a workout with no UNDO** (`ProcessTable.swift:128`). "Closed Push A, nothing was logged" should be M37 "Push A, no sets, not saved." with a 10 s UNDO. Generic Undo now skips system writes (`ActionEngine.swift:161`, QA D1), so the delete's record has to be passed with the line. Core, then Builder B.
2. **The UNDO beside the overnight notes can take back a different record** (`BottomChrome.swift:94`). The notes go to `voice.say` with no record, but `canUndo` still shows UNDO when `lastCapture` is set. Tapping it beside "Carried 2 tasks into today." would undo an unrelated capture. Builder B.
3. **Set receipts still have no verb and use "x"** (`TessCaptureEngine.swift:121` to `127`): "Set 3. 80 x 8 @8." should be "Set 3 logged. 80 × 8, RPE 8." (X1, X2). Core.
4. **Set asks have no lines of their own** (`TessGrammar+Live.swift`, S701 to S706). Without the on-device model, "3x10", "81" and "fail at 6" all get "Didn't catch that. Try “bench 80 x 8”." They should get the asks, for example "3 × 10: 3 sets, or 3 kg?". Core.
5. **Overnight lines put the verb first and miss full stops** (`RollForward.swift:33` to `35`, `ProcessTable.swift:112, 134`). "Carried one task into today." should be "Pay rent carried into today."; "Saved Push A, 3 of 5 exercises" should be "Push A saved. 3 of 5 exercises." Core.

API key check: no line shows or echoes a full key. M1 "Key saved. Ends in ...a1B2." shows the last 4 characters, as M1 intends. A key typed into Ask is refused before any route runs (`TessModel.swift:63`) and is kept out of the capture-miss log (`TessCaptureEngine.swift:33`, `CaptureMissLog.swift:39`). Backup failure reasons and launch logs carry error descriptions only. One aside that is not a line: `ClaudeKey.swift:257` sends the key as `Authorization: Bearer`. Anthropic API keys normally go in the `x-api-key` header, so Core should check this against `claude-key-test.md` before Settings: Claude ships.

## 1. Set lines and set asks

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:121 | "Same again @8, logged." | fix | "Set 4 logged, same again." (RPE as ", RPE 8."); names the set (X2) | Core |
| TessCaptureEngine.swift:122 | "Drop set. 70 x 10 @8." | fix | "Drop set logged. 70 × 10, RPE 8." | Core |
| TessCaptureEngine.swift:123 | "Set 3. 80 x 8 @8." | fix | "Set 3 logged. 80 × 8, RPE 8." (X1, X2; "@8" is typed shorthand, not her voice) | Core |
| TessCaptureEngine.swift:127 | appended " 81 isn't loadable." | fix | "Set 3 logged. 80 × 8, nearest load to 81." Says what was logged, not what can't be | Core |
| TessGrammar+Live.swift:20 (every `return model`: 26, 34, 38, 43, 47, 57, 74, 84, 86), reply from TessModel.swift:74 | No ask. Without the on-device model, every guarded phrase gets "Didn't catch that. Try “bench 80 x 8”." | fix | One line per case, from the grammar: "3 × 10: 3 sets, or 3 kg?", "81: 81 kg, or 81 reps?", "Fail at 6: rep 6, or 6 reps?", "+5 kg: on the next set?", "skip": "Skip set 4?". No write until he answers | Core |
| TesseraCore/Sources/TesseraIntents/Intents.swift:76 | "Set 3 taken back." (Siri, Lock Screen Undo) | ok | Matches M34 and X10 | Core |
| Intents.swift:63 | "Takes back the most recently logged set, and only that set." | ok | Shortcuts description, plain | Core |
| TessCaptureEngine.swift:87 | appended " On Now then." | ok | M41 | Core |
| TessCaptureEngine.swift:217 | "Dentist, Saturday 3 pm." after midnight (weekday named, never "tomorrow") | ok | M39; the time format is still the open X6 call | Core |
| TesseraCore/Sources/TesseraTess/TessModel.swift:64 | "That looks like a Claude key. Paste it in Settings." | ok | M24 (still the one instruction-shaped line, already noted) | Core |

## 2. Set aside and the empty wrap-up

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| Widgets/RestLiveActivity.swift:215 | "Push A" / "set aside" (stale ready face) | ok | late-night #12 | Builder A |
| RestLiveActivity.swift:76 | "Aside" (Dynamic Island, compact trailing) | ok | The tick and the expanded face carry the name | Builder A |
| TesseraCore/Sources/TesseraCore/Processes/ProcessTable.swift:128 | "Closed Push A, nothing was logged" (deletes the workout, no UNDO, no full stop) | fix | "Push A, no sets, not saved." (M37). Return the `DeleteObject` record with the note so the line gets a 10 s UNDO, then "Push A taken back." Generic Undo skips system writes since `ActionEngine.swift:161`, so the record must be passed | Core |
| ProcessTable.swift:134 | "Saved Push A, 3 of 5 exercises" (text unchanged, newly shown by BottomChrome) | fix | "Push A saved. 3 of 5 exercises." Name first, full stop | Core |
| ProcessTable.swift:112 | "Put two things away. They're in Later." (newly shown) | fix | "Two things moved to Later." | Core |

## 3. Carried (rolled-over) tasks

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| TesseraCore/Sources/TesseraCore/Tasks/RollForward.swift:33 | "Carried one task into today." / "Carried 3 tasks into today." | fix | "Pay rent carried into today." (name the one task) / "3 tasks carried into today." | Core |
| RollForward.swift:34 | "Put one task in Later." / "Put 3 tasks in Later." | fix | "Pay rent moved to Later." / "3 tasks moved to Later." | Core |
| RollForward.swift:35 | "Carried 3 into today, put 1 in Later." | fix | "3 tasks carried into today, 1 to Later." | Core |
| Features/Command/BottomChrome.swift:94 | `voice.say(notes.joined(separator: " "))`: overnight notes joined into one line, no undo record | fix | Show one note at a time (or end each with a full stop before joining) so two notes don't run on past 12 words into the 2-line limit. Hide UNDO while a system note is up unless the note carries its own record: today `canUndo` turns true from `lastCapture`, so UNDO beside "3 tasks carried into today." would take back an unrelated capture. The roll itself is not destructive and, per QA D1, needs no UNDO | Builder B |

## 4. Backups

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| Features/Backup/BackupView.swift:48 | "Kept on this iPhone" / "Kept in two places" (two places only while the folder copy saves) | ok | Honest now. If the iPhone copy fails too, the failure line below says so | Builder B |
| BackupView.swift:322 | "Today's copy on this iPhone didn't save. It tries again when you leave the app." | fix | "Today's copy on this iPhone didn't save. Retries when you leave." (11 words; 14 now) | Builder B |
| BackupView.swift:316 | "The last copy to Tessera didn't save. ..." | fix | Name the day: "Tuesday's copy to Tessera didn't save." "The last" doesn't say when | Builder B |
| BackupView.swift:318 | "The folder you chose can't be reached, so copies are only on this iPhone. Choose it again." | fix | "Folder not found. Copies stay on this iPhone. Pick it again?" (11 words, an offer) | Builder B |
| BackupView.swift:297 | "today" / "yesterday" by his 04:00 day | ok | | Builder B |
| Features/Backup/BackupKeeper.swift:44 | Log only: "Daily copy to iPhone failed: ..." | ok | Not shown; carries no key | Builder B |

## 5. Settings: Claude key lines

None of these is reachable yet: master has no Settings: Claude screen calling `ClaudeKeyCheck` (Builder B to wire). Lines match the M series word for word.

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| TesseraCore/Sources/TesseraTess/ClaudeKey.swift:187, :294 | "That doesn't look like a Claude key. Paste it again?" | ok | M31 | Core |
| ClaudeKey.swift:287 | "Key saved. Ends in ...a1B2." | ok | M1. Shows the last 4 characters only, by design; the full key is never echoed | Core |
| ClaudeKey.swift:288 | "That key didn't work. Paste it again?" | ok | M2 | Core |
| ClaudeKey.swift:289 | "That key can't use Claude yet. Check it in the Console?" | ok | M25 | Core |
| ClaudeKey.swift:290 | "No connection. I kept the key and will check it later." | ok | M26 | Core |
| ClaudeKey.swift:291 | "Claude didn't answer in time. I'll check again later." | ok | M27 (the M18 "timed out" wording clash is still open for Design) | Core |
| ClaudeKey.swift:292 | "Claude is busy right now. I'll check again soon." | ok | M29 | Core |
| ClaudeKey.swift:293 | "Key saved. Your Anthropic account is paused for now." | ok | M30 | Core |
| ClaudeKey.swift:295 | "I couldn't check that key. Try again?" | ok | M32 | Core |
| ClaudeKey.swift:298 | "Key saved. Claude paused until Nov 1." | ok | M28, locale short date as decided | Core |
| ClaudeKey.swift:135 | Tess Call object title "keyCheck call" (raw enum value) | fix | Title from a display name: "Key check", "Capture", "Plan". Object pages and search show titles | Core |

## 6. Looks

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| DesignSystem/LookSentence.swift:15 | "Look" (label) | ok | | Builder A |
| LookSentence.swift:27 | "Obsidian always." | ok | | Builder A |
| LookSentence.swift:29 | "Hold it again to follow light and dark mode." | fix | "Hold it to follow light and dark mode." "Again" assumes he just held it; after a relaunch the pin is simply there | Builder A |
| LookSentence.swift:34, :41 (and :51, :60) | "Porcelain by day, Obsidian by night." | ok | | Builder A |
| LookSentence.swift:64 | "Hold a name to keep it day and night." | ok | | Builder A |
| LookSentence.swift:102 | VoiceOver actions "Keep Porcelain day and night" / "Follow light and dark mode" | ok | | Builder A |
| LookSentence.swift:97 | `accessibilityHint(look.line)`: the hint reads the look's description | fix | Put the description in the value ("Porcelain. Pure white. ...") and make the hint say what a tap does: "Changes the day look." | Builder A |
| DesignSystem/Looks.swift:118 to 122 | "Pure white. Colour pools only behind what matters now." and the other four | ok | Descriptions, no claims, 8 to 11 words | Builder A |
| DesignSystem/Theme.swift:247 | Concept name "Porcelain by day, Obsidian by night" | ok | | Builder A |

## 7. Home: Now and Training starts

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| Features/Home/NowPage.swift:377 with TesseraCore/.../Training/RestDay.swift:12 | "today" / "Rest day" | ok | Matches "Rest day." morning line | Builder B |
| NowPage.swift:385 | "Push A is a tap away." | ok | An offer, no guilt | Builder B |
| NowPage.swift:391 | "Start Push A" | ok | | Builder B |
| NowPage.swift:393 | VoiceOver hint "Starts Push A anyway" | fix | "Starts Push A now." "Anyway" second-guesses the rest day | Builder B |
| NowPage.swift:424 (`canStart` hides Start) | Empty routine: no Start and no line | fix | Empty state: "Push A has no exercises yet. Add one?" (the line opens the routine editor) | Builder B |
| Features/Home/TrainingPage.swift:182 | Same: "Start workout" hidden for an empty routine, nothing in its place | fix | Same line as Now, so both screens say it the same way | Builder A |
| TesseraCore/Sources/TesseraCore/Actions/PlanActions.swift:121 | Error reason "the routine has no exercises" (what Siri, Shortcuts or Tess get) | fix | A spoken line from the caller: "Push A has no exercises yet." | Core |

## 8. Home: Review

| file:line | Current line | Verdict | Suggested fix | Owner |
|---|---|---|---|---|
| Features/Home/ReviewPage.swift:38 | "Your first week starts today" / "A quiet week so far" | ok | Empty states, no debt | Builder B |
| ReviewPage.swift:41 | "All six sessions in" | ok | | Builder B |
| ReviewPage.swift:46 | "Four sessions this week" / "Two sessions in your first week" | ok | Counts, not streaks | Builder B |
| ReviewPage.swift:51 | VoiceOver "4 of 6 sessions this week" | ok | | Builder B |
| ReviewPage.swift:158 | "Chest: 4 sets this week, toward a usual 10." | ok | Replaces "is a little behind", which read as a debt | Builder B |
| ReviewPage.swift:140 with :388 | A past day neither due nor rest is marked `.planned`, so VoiceOver says "Monday, planned" for a day already gone | fix | Past days are never "planned": use "open" (or "rest" when the plan had room) | Builder B |
| Features/Review/ReviewView.swift:101 to 104 | "A quiet week so far" / "Something done on four days" / "Something done every day" | ok | | Builder B |
| ReviewView.swift:115 | "Nothing to count this week." (count line under "A quiet week so far") | fix | Say nothing (principle 7); the headline already says it | Builder B |
| ReviewView.swift:280 | VoiceOver "Monday, today, something done" / "rest" / "planned" / "open" | ok | | Builder B |

## Still open from #158, not counted above

These strings did not change in the diff, so they are outside this audit's count. They still break the undo rule and are listed so they are not lost:
- `Features/Plans/RoutineEditor.swift:193` "Undone." (M34: "{name} taken back.").
- `Features/Home/HomeQueue.swift:391` "Done. Pay rent." and `:412` "Moved to tomorrow." / "Moved to next week." (M33, M40: "Pay rent done.", "Pay rent moved to Saturday."). The move target changed in this diff (his 04:00 day), but the line didn't.
- `Features/Home/NowPage.swift:196` "Done. Next one is up." (name the task first).
- `App/AppModel.swift:226` `undoLastCapture()` takes back a capture with no line at all (M34 wants "Set 3 taken back.").
- `Features/Backup/BackupView.swift:139` "Saved a copy there. One a day from now on." (X17).
- `TesseraIntents/Intents.swift:72` "No set to undo." Fine as an empty state; "undo" is the intent's own name.
