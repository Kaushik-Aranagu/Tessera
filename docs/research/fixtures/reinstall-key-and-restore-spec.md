# Build spec: the reinstall key question, the restore offer, the first Before-restore copy

Static spec for Core and Builder B (G687, G688, G689; hunt 28 rows FL36-FL38, hunt 27 rows BK45/BK46). Read from master f5fd3a86. No code run. Mirror = `/mnt/project-files/tessera/product/decisions.md` (1,117 lines, lines past 1064 are mirror-only; the five calls are ruled at line 1117); repo copy not cited for those lines. Every code cite was read on master.

## 0. Order and owners

1. **Core first: G687 gate** (blocker, mirror 1111). One PR: the answer field, `sendsMissesToClaude`, the save-key write, tests 1.1-1.6. Nothing else may merge ahead of it that sends text.
2. **Core: G689** (small, independent of 1, same file area as hunt 27 CALL 6 B work).
3. **Builder B: G687 question line, then G688 offer line** (both read Core's new reads; Builder B starts after Core's read API is merged, or against the API in section 1.5 as a stub).
4. Core supplies the G688 condition (`isFreshStore`) in PR 1 or 2; Builder B owns the strings and views.

## 1. G687: found key asks once (BLOCKER)

Ruled: mirror 1099 CALL 6 B (3:58 PM Oct 18, hunt 23): "a key found on a fresh store asks once, 'Use the Claude key still on this phone?', and nothing goes to Claude until he answers"; mirror 1111 (10:27 AM Oct 19): a found key must not read as "asks Claude" yes on a reinstalled phone.

### 1.1 Cause (verified)
- `TesseraSettings.swift:41-43`: `sendsMissesToClaude` = `missesGoToClaude ?? true`; field comment `:11` says typing the key opts in (Oct 15 8:28 PM).
- `AppModel.swift:58-60`: `asksClaude` = `settingsAreReal && ...sendsMissesToClaude`. No key test there.
- `ClaudeTessModel.swift:48`: gate is `use == .capture && keys.read() != nil && sendsMisses() && !paused`. A reinstall keeps the Keychain item (`ClaudeKey.swift:22-55`, `SystemKeychain`, service/account fixed; survival is inferred, hunt 23 CL26, not run), the fresh store has the field nil, so yes.
- Other readers of the same gate (all inherit the fix): `PlanWording.swift:439` (`allowed`), `AppModel.swift:75, 96, 206`, `HomePlan.swift:115`, `PasteRecipe.swift:263, 267`, `RecipePasteLink.swift:55-59`.

### 1.2 Design (my default where marked)
Reuse the existing field `missesGoToClaude: Bool?` (no catalog change, `SystemCatalog.swift:241`), and make nil mean "not asked yet":
- `sendsMissesToClaude` becomes `missesGoToClaude ?? false` (ruled, mirror line 1117 CALL 1 A). Stored `true` / `false` are his answers.
- A new Core read `claudeQuestionDue: Bool` = key present AND `missesGoToClaude == nil` AND settings real AND not later-snoozed (see Later). Key presence is a Bool only; the key text is never read into settings, logs or ops.
- Typing or pasting a key in Settings (ClaudeSection save path, `ClaudeSection.swift:357` area) writes `missesGoToClaude = true` if nil (preserves the Oct 15 "typing the key opts in" rule; he acted). If he already said no, saving a new key leaves no (my default).
- Remove key (ruled two-step, 1099 CALL 1 A) leaves the field as it is; the question is only due when a key exists.
- Existing upgraded phones: a store with the old UserDefaults value migrates in (`TesseraSettings.swift:111-113`) and keeps its answer; a store with a key and no stored answer is the only case that asks.

### 1.3 States
| State | When | He sees | Sent / written |
|---|---|---|---|
| Unasked | key found, field nil | the question line (1.4) in Settings: Claude and once on Today (Builder B places; see 1.7) | nothing to Claude; no op |
| Yes | taps "Yes" | line goes; receipt "Claude on. Turn this off in Settings: Claude." | op: `missesGoToClaude = true`, actor him |
| No | taps "No" | line goes; receipt "Claude off. Turn this on in Settings: Claude." | op: `missesGoToClaude = false`; key stays on the phone |
| Later | taps "Later" or ignores | line stays quiet in Settings: Claude only (Today line hides for this launch) | nothing; no op |
| No key | no Keychain item | no question; "No Claude key yet." (`docs/ai/private-surfaces-images-failure-lines.md:45`) | nothing goes (no key) |

### 1.4 Strings (one line each, thing first, plain US English)
- Question: `Use the Claude key still on this phone?` (exact, ruled).
- Buttons: `Yes`, `No`, `Later`.
- Yes receipt: `Claude on. Turn this off in Settings: Claude.`
- No receipt: `Claude off. Turn this on in Settings: Claude.` (my default wording; the first matches the ruled "Turn this off in Settings: Claude." style, already in `ClaudeTessModel.swift:162-163`).
- Settings row while unasked: `Claude key found. Not used yet.` (my default).
- VoiceOver on the question: the question, then "Yes, No or Later." (my default).

### 1.5 Where each string reads
Question and buttons: new `ClaudeKeyQuestion` view in `Features/Settings/ClaudeSection.swift` (Settings: Claude, always) and one line on Today under the top bar, first foreground only (Builder B; one line, never a modal, never a sheet). Receipts: the standard receipt line used by the switch (`ClaudeSection.swift:297-310`, `switchLine`). Core read API for Builder B: `SettingsStore.claudeQuestionDue(keyPresent: Bool) -> Bool` and `SettingsStore.answerClaudeQuestion(_ answer: Bool)` (one op).

### 1.6 Default when he does not answer
Nothing goes to Claude, ever, until Yes. The question stays available (Settings: Claude shows it on every visit; Today line returns at most once per cold launch while unasked, ruled, mirror line 1117 CALL 2 A). Later = not answering; no timer, no auto-yes.

### 1.7 Edge cases
- **Store restored from a copy that carried an answer:** the field rides in the copy, so the answer is kept and no question shows (key present, field true or false). Restore of a copy with field nil and a key present: asks.
- **Key found, flags absent (`ClaudeMissFlags`, pause/first-send notice state lost on reinstall):** the first-send notice rules (mirror 1099 ranking 8) start clean; Yes does not skip them. Pause flag absent reads as not paused, fine because the gate needs the answer first.
- **Siri/Shortcuts never send:** App Intents run on `runtime` with `commitImmediately` (`ClaudeTessModel.swift:53` returns `.missed` there) so they never reach Claude, answered or not. Test 1.6 pins it.
- **Capture-miss route:** capture asks first; with Unasked it falls to the local "didn't catch that" line as for no key. After Yes the next miss goes through the ruled route, with the first-send notice. The phrase that missed before the answer is not retried or queued (never queued, #987).
- **Offline:** the question shows regardless; Yes writes the local op; nothing sends until online and a real miss. The offline inbox (1099 ranking 2) drains only when Yes holds, rechecked at read time.
- **Plan wording, recipe reader, Home lines:** all read `asksClaude`, so all wait for Yes.
- **Demo/throwaway store:** `settingsAreReal` false stays off; no question.
- **Private mode / walls:** unchanged; the answer does not loosen any wall.

### 1.8 Tests (Swift Testing)
Core (`TesseraCore/Tests/TesseraCoreTests/SettingsTests.swift`, `ClaudeRouteTests.swift`):
- `foundKeyOnAFreshStoreSendsNothingUntilAsked`: key in a fake keychain, fresh settings; capture miss; zero requests on the stub session; `sendsMissesToClaude == false`.
- `foundKeyAsksOnceAndYesSendsNext`: due is true; answer yes writes one op; due false; next miss sends once.
- `noAnswerKeepsClaudeOffAcrossLaunches`: reopen engine; still due, still nothing sent.
- `savingAKeyInSettingsOptsInWhenUnanswered`: save path writes true; a stored no is left alone.
- `restoredCopyKeepsItsClaudeAnswer`: restore a copy with true and one with false; due is false in both.
- `shortcutsAndSiriNeverSendWithAnAnsweredYes`: `commitImmediately` context returns `.missed`, zero requests.
App (`TesseraTests/TessAsksClaudeTests.swift`):
- `asksClaudeIsFalseWhileTheKeyQuestionIsUnanswered` for `AppModel.asksClaude` (also gates plan wording and paste recipe).
Builder B (`TesseraTests`, new `ClaudeKeyQuestionTests.swift`):
- `keyQuestionReadsExactlyAndOffersYesNoLater`: asserts the exact string and three buttons.
- `keyQuestionIsAbsentWithoutAKey` and `laterWritesNothing`.

### 1.9 Must not change
Key never printed, logged, in any backup, export, op, receipt or test output (tests use a fake keychain, never the real item). `SystemKeychain` storage attributes (`ClaudeKey.swift:30-48`) untouched. Walls (money, body, secret words never go, ruling 685) untouched. Ruled strings "Key saved" / "No Claude key yet." (1099 CALL 5 A), Remove key two-step (CALL 1 A), 8 s cap, month spend resets on reinstall (1099 CALL 2 A; 1109 CALL 7 A).

## 2. G688: the quiet restore offer on first launch

Ruled: hunt 28 CALL 1 B, mirror 1111: "first launch with a copy in the folder shows one quiet line offering the restore, never a modal."

### 2.1 Verified starting point
Launch 1 seeds the store and starter lists and writes "Sunday, rest day." (`TesseraApp.swift:16-43`; `AppModel.swift:50-64, 187-192`; `RestWeekday.swift:96-113`). Restore needs Backups, a picked file, a hold, a second cold launch (`TesseraBackup.swift:343-349, 371-445`). A reinstall loses the folder bookmark (UserDefaults) so `BackupKeeper.pickedFolder` (`BackupKeeper.swift:110`) is nil, which is the hunt's condition.

### 2.2 Condition (Core, `isFreshStore`)
All of: settings real; `TesseraBackup.userOps` over the live store is 0 (`TesseraBackup.swift:237-241`, ignores system and settings ops, so the seeded "Sunday, rest day." op does not count); `BackupKeeper.pickedFolder == nil`; no staged restore; line not dismissed. The line vanishes on his first action (userOps > 0) or on picking a folder (my default: also on "Not now").

### 2.3 States
| State | When | He sees | Written |
|---|---|---|---|
| Offered | fresh store, no folder | one quiet line on Today | nothing |
| Opened | taps the line | Backups with the folder picker (`BackupView.swift:183-186`) | nothing until a file is picked and held |
| Dismissed | taps "Not now" | line gone, copy stays reachable in Backups > Restore | a UserDefaults flag only (not an op, not in backups) |
| Gone | first action or folder picked | nothing | none |

### 2.4 Strings
- Line: `Have a copy from before? Backups, Restore.` (ruled text in CALL 1 B; hunt FL36 row words it "Backups > Restore"; the CALL text is the later one, use it).
- Dismiss: `Not now` (ruled, mirror line 1117 CALL 4 A).
- VoiceOver: line text, then "Opens Backups." (my default).

### 2.5 Where it reads
Today, a single quiet line under the bar (Builder B, new view; text style of the Backups failure line, no card, no modal, no sheet, no motion beyond the 150 ms fade through MotionPolicy). Tap target opens `Features/Backup/BackupView.swift` at the restore row.

### 2.6 Default when he does not answer
The line stays until his first action or a picked folder; nothing is restored, nothing is written. Restoring itself is unchanged: pick, hold REPLACE, next cold launch.

### 2.7 Edge cases
- Restore staged but not yet applied: line hides (pending marker exists).
- New phone (FL62): same line; the folder must be picked again; iCloud copies lack private rows (hunt 27 CALL 2 B warning applies at restore).
- Found key plus offer: both lines may be due on a reinstall; show the key question first, the offer second, one at a time (hunt 28 CALL 3 B queue, mirror 1111; order ruled, mirror line 1117 CALL 5).
- A workout or cook open: the line does not show (restore refuses then, hunt 27 CALL 3 A).
- Offline: no dependence on network.
- Siri/Shortcuts: no effect; neither reads nor sends.

### 2.8 Tests
Core: `freshStoreOffersRestoreOnce` (exact name from hunt 28): 0 user ops + no folder is due; one user op, a picked folder, a staged restore or a dismissal each makes it not due; the seeded Sunday op alone does not count.
Builder B: `restoreOfferLineReadsExactlyAndIsNeverAModal` (string equal; the view is not presented via sheet/alert APIs) and `restoreOfferOpensBackups`.

### 2.9 Must not change
Restore stays whole replace, staged and applied at the next cold launch, never merging. Key never in backups. No new first-launch screen (CALL 1 C was not chosen).

## 3. G689: the first Before-restore copy must hold something of his

Ruled: hunt 27 CALL 6 B, mirror 1109 (10:15 AM Oct 19): keep the first-ever Before-restore copy plus the three newest; no set-aside on a clean restore. **Ruled (mirror line 1117 CALL 3 A):** skip the Before-restore copy when the live store has no user ops (hunt 28 FL37 says so; mirror 1111 CALL 1 B rules only the offer line).

### 3.1 Verified starting point
`applyPendingRestore` (`TesseraBackup.swift:371`) sets `hasStore` (`:389`); `if hasStore` (`:390`) writes `Before-restore-<stamp>` and prunes with `dropFirst(keepBeforeRestore)` (`:404`, constant `:41` = 3). On a reinstall the store exists (launch 1 made it), so the first-ever slot would hold only seeded data. If the copy cannot be kept the restore does not happen (launch note `:408-411`).

### 3.2 Behavior
| State | When | What is written |
|---|---|---|
| Empty live store | `userOps(at: storeURL) == 0` (read-only open, `:244`) | no Before-restore copy; store set aside and replaced; launch note below |
| Store with his things | userOps > 0 | copy written as today; the oldest-by-name copy (the first-ever) is never pruned, plus the three newest (hunt 27 CALL 6 B) |
| Count unreadable | open throws | write the copy (safe side, my default) |
| Clean restore | restore succeeds | no set-aside folder (hunt 27 CALL 6 B) |

"First-ever" means the earliest-stamped surviving Before-restore file; once pruning is exempt for it, up to four files stay. Because an empty-store restore writes none, the first-ever slot is spent on his first real data.

### 3.3 Strings
Launch note when no copy was written: `Restored from your backup.` (my default; the existing `:442` text says "What was here before is kept in Backups", which would be false). With a copy: the existing text stays. Read in the launch note line (`TesseraSchema.setLaunchNote`), shown on Today.

### 3.4 Default if unanswered / edge cases
No question. Restore of a copy over a non-empty store is unchanged. The day's rolling copy rewrite after a restore (BK47) is unchanged. The spend rule (BK51/BK53) is untouched here. Reinstall restore never needs the key question first, but both can be due on launch 1.

### 3.5 Tests (Core, `BackupTests.swift`)
- `restoreOverAnEmptyStoreWritesNoBeforeRestoreCopy`: seeded-only store; folder has no Before-restore file after; launch note equals the string above.
- `restoreOverAStoreWithActionsStillWritesTheCopy`.
- `theOriginalStoreSurvivesFourRestores` (name from hunt 27): four restores over a store with actions; the first-ever copy and three newest remain, four files total.
- `unreadableStoreCountStillWritesTheCopy`.
- `cleanRestoreLeavesNoSetAsideFolder`.

### 3.6 Must not change
`inspect` before apply; the restore marker; the failure notes at `:380-388, 417-445`; backups carry no key; privacy walls on the iCloud copy (private rows left out, hunt 27 CALL 2 B warning still comes first).

## 4. PRODUCT CALLS (Kitchen CALL shape)

### CALL 1 RULED A (mirror line 1117) (G687): What an unanswered field means
| Option | Consequence |
|---|---|
| A. nil reads as no; typing a key writes yes; reinstall with a key asks once | Matches the ruling; one default flips from true to false for a key-less nil. |
| B. nil stays yes; add a separate "asked" flag | No change to the old default; a second field and a catalog change. |
Recommended: A. Reason: one field, nothing can send before an answer. Owner: Core.

### CALL 2 RULED A (mirror line 1117) (G687): "Later" and where the question shows
| Option | Consequence |
|---|---|
| A. Settings: Claude always, plus one Today line per cold launch while unasked | He cannot miss it; one extra quiet line at most. |
| B. Settings: Claude only | Quietest; he may never see it and Claude stays off. |
Recommended: A. Reason: a found key is the case the ruling cares about. Owner: Builder B.

### CALL 3 RULED A (mirror line 1117) (G689): Skip the Before-restore copy of an empty store
| Option | Consequence |
|---|---|
| A. Skip when userOps is 0 | The first-ever slot holds his first real data; a restore over nothing has no undo (nothing to undo to). |
| B. Always write it | Simplest; the protected slot holds seeded data only. |
Recommended: A. Reason: it is what CALL 6 B is for. Owner: Core. Ruled (mirror line 1117, 11:08 AM PT Oct 19).

### CALL 4 RULED A (mirror line 1117) (G688): "Not now" on the offer
| Option | Consequence |
|---|---|
| A. Line has "Not now" and stays gone | He is not nagged; Backups > Restore stays. |
| B. No dismiss; line ends only on action or folder | Fewer controls; the line may linger days. |
Recommended: A. Owner: Builder B. Ruled (mirror line 1117).

### CALL 5 RULED (mirror line 1117): Order of the lines on launch 1
Key question first, restore offer second, one at a time. Recommended. Owner: Builder B. Ruled (mirror line 1117).

## 5. Not verified
iOS keeping the Keychain item across a delete (inferred, hunt 23 CL26). No code or tests were run. Line cites for mirror text are mirror-only (1099 and 1109-1111 text read in the mirror, which carries lines past 1064).
