# Gap hunt 23: the Claude layer (everything that sends a word to Claude or keeps what Claude said) under privacy, Low Power and VoiceOver (static read, origin/master 2b8b135f, Sun Oct 18 PT)

For: Core (TesseraTess, ledger, backup), Builder B (Settings: Claude, Ask band, Paste), Builder A (PowerState, motion policy), AI architecture, QA, Design (new strings). Docs only. Nothing was built or run, and no Claude key was read, used or needed: this is a read of Swift and docs. "Traced" means I read the line and saw what the row says, "inferred" means the row follows from code or a ruling I did not read in full, "gap" means master has nothing for it or contradicts a ruling. Method and row format follow `gap-hunt-22-object-layer.md`. Every file:line below was read in a worktree of origin/master 2b8b135f after checking the file has that many lines. No key, no part of one and no key-shaped text appears in this file; fake inputs are described in words.

**Gap ids.** `git grep -ho "G[0-9]\{3,4\}" origin/master -- docs | sort -u`, with the G4001 to G4015 series ignored (the kitchen lists series), ends at **G646** (gap hunt 22). New gaps here are **G647 to G656**, the ten ranked rows. I did not read the project mirror, so another open research PR may hold G647 or above; renumber at merge (CALL 8). Row ids use the prefix **CL**, unique only inside this file.

Status words: **traced**, **inferred**, **gap** as above. **(not built)** marks a screen, file or job that does not exist: a spec to test when it lands. **(latent)** marks a gap with no caller yet. **(unruled)** marks an Expected that rests on my default, not a Product ruling; each is also in PRODUCT CALLS.

Rulings used (`docs/product/decisions.md` in the repo, line numbers of that file, which has 1063 lines). Entries after line 1063 exist only in the project mirror; I cite them through the design docs that quote them and mark them "mirror only".
- Line 683 (8:28 PM Oct 15): misses go to Claude, default yes, one-time line naming what went. Line 673 area and 69 (2:33 AM Oct 17): a capture phrase the grammar cannot read goes whole, "all but the key"; other Claude jobs keep their walls. Line 67 (2:40 AM): a walled phrase stays out of the miss log, is never queued, and shows on "What was sent" as "Private phrase".
- Line 101 (8:16 PM Oct 16): the $50 month is a hard stop; at $40 the word jobs step aside; resets on the 1st. Line 93 (8:24 PM): the month rolls on house time (4 am). Line 420: the month's spend is also kept in a small file outside the store, the cap takes the higher.
- Line 113 (7:28 PM): failed and timed-out calls count as sent; the key Test does not and writes no row; the sent-job log stays out of backups. Line 77 (9:53 PM): key state is yes or no, never a tail. Lines 1057 item 3 and 4 (11:07 PM Oct 17): receipts stay out of the iCloud copy and shared export; Remove key is a two-step "Remove the Claude key?" with "Remove" and "Keep it", plain receipt, no UNDO, KeyRemoval deleted. Line 1049: removing the key has no UNDO.
- Line 1019 (9:24 PM): until Settings ships, pointer strings say Review ("Turn this off on Review: Claude."). Line 1047: one Core value `ClaudeWhere` builds all six.
- Line 1017 (HS12) and 1023 item 4 (Oct 17): Home's one automatic Claude call does not run in Low Power; a call he asks for runs. Line 1039 item 4 and 1057 item 1: plan wording and the Monday week story wait for power ok; the week story is one gate inside the Claude client (Low Power, 07:00 floor, switch, cap). Lines 991 and 1003: Low Power = Reduce Motion, one reader `App/PowerState.swift`.
- Line 243 and 233: one UNDO slot, 4 s new / 10 s change / 10 s under VoiceOver. Line 929 (4:10 PM Oct 17): cook timer phrases never leave the phone. Line 61 (1): anything sent to Claude drops private items.
- Mirror only, quoted in `docs/design/motion/tess-ruling-index.md` N14 (line 97) and N16 (line 99) and `tess-capture-miss-motion.md`: offline walled miss reads "Couldn't read that offline. Try again online." and nothing is queued or logged; until the inbox is wired an unwalled offline miss reads "No connection."; the "Sent ... to Claude" notice shows on send, not on success; the Claude wait is one line "Asking Claude" with Cancel, capped at 8 s, no retry.

Cross-references not repeated: `claude-requests-audit.md` (CA1 to CA8, several now closed: CA1 and CA2 by the all-but-key rule, CA6 by `TessTools.countable`), `capture-all-but-key.md` (KS01 to KS10), `docs/ai/secret-checklist.md` (items 3, 4, 7, 8 are fixed on master), `docs/ai/offline-retry-table.md`, `docs/ai/settings-claude-page-spec.md`, `docs/ai/what-was-sent-log.md`, `docs/ai/injection-audit.md`, `gap-hunt-home-settings.md` HS12.

## 1. State of master for these areas

| Area | What master has today | Evidence |
|---|---|---|
| Callers | Four Claude clients are wired: `ClaudeTessModel` (Haiku 5.5, capture), `ClaudeKeyCheck` (Test), `ClaudeHomeDone` (Sonnet 5.5, done lines, live), `ClaudeRecipeReader` (Haiku 5.5, Paste link). `ClaudePlanWording` (Sonnet 5.5) has a getter but `planWordingReady` is false. No shared `ClaudeClient`, no `TessJob`, no `TessSent`. | `AppModel.swift:64-103, 198-207`; `PasteRecipe.swift:261`; `git grep ClaudeClient TessSent` finds no Swift |
| The key | Keychain generic password, this device only, unlocked only, never synced; one `x-api-key` header per request, built from a local; redirects refused by one shared delegate. Settings shows "Key saved" and a status word, no tail. | `ClaudeKey.swift:22-55, 290-304`; `NoRedirects.swift`; `ClaudeSection.swift:220-223` |
| Spend | `TessCall` objects in the main store, one per call; the month is the phone calendar month from 00:00; cap $50 in nano-dollars; reserve before send, settle after; per-store pending map. | `ClaudeKey.swift:88, 111-142` |
| Receipts ("What was sent") | `ClaudeReceipts` lists time, job, model, cost per ledger row. No payload, no phrase, no clear. | `ClaudeSection.swift:447-496, 498-542` |
| Switch | `AppModel.asksClaude` = real settings store and `sendsMissesToClaude` (default yes); every client takes it as a closure; checked at call start only. | `AppModel.swift:58-60`; `ClaudeTessModel.swift:48, 56` |
| First-send notice | One flag in UserDefaults, set on the first handled miss, replaces the receipt line. | `ClaudeTessModel.swift:157-162, 341-344` |
| Offline | Capture: any URLError but a timeout is "offline", text saved to `TessInbox` unless walled. `readWaiting` has no caller. Recipe link: kept on a shelf file, read on his tap. | `ClaudeTessModel.swift:134-139, 273-275`; `TessInbox.swift:58`; `RecipePasteLink.swift:63-72` |
| Memory | `TessMemory` objects in the store (told, noticed, recent, forgotten hash). No Claude job reads them today. | `TessMemory.swift:8-95`; `claude-requests-audit.md` |
| Cached Claude words | Home done words in `home-lines-cache.json`, complete file protection, excluded from device backup. | `HomeDoneWording.swift:83-86, 206-217` |
| Low Power | Read only by the soul. `App/PowerState.swift` does not exist. No Claude client reads Low Power. | `TessSoul.swift:108`; `git grep isLowPowerModeEnabled`; `ls App` |
| VoiceOver | The switch is a Button with a label and value, no toggle trait; no announcement for the switch line, the key lines or the removal; one local "Undo" button. | `ClaudeSection.swift:169-189, 98-110, 378-402` |

## 2. Top 10 gaps, ranked

Ranked by harm first (a private word or the key leaving or lingering), then by how often he meets it.

| Rank | Gap id (row) | Gap | file:line | Owner |
|---|---|---|---|---|
| 1 | G647 (CL19) | Remove key is one tap with a 10 s UNDO, and `KeyRemoval` holds the key in memory for those 10 s. Ruled: two-step "Remove the Claude key?", plain receipt, no UNDO, KeyRemoval deleted. A UI test pins the old flow. | `ClaudeSection.swift:71-72, 378-402, 544-560`; `ClaudeSettingsUITests.swift:10`; decisions 1049, 1057 | Builder B |
| 2 | G648 (CL32) | The offline inbox is never drained: `readWaiting` has no caller, yet the line says "No connection. Saved it for Claude." Phrases sit in the store (so in backups and the iCloud copy) for ever. | `ClaudeTessModel.swift:134-137`; `TessInbox.swift:25-36, 58`; `git grep readWaiting` | Core + Builder B |
| 3 | G649 (CL33) | An offline walled miss says "No connection, so Claude didn't see that." Ruled (mirror only): "Couldn't read that offline. Try again online." with his text left in the box. | `ClaudeTessModel.swift:245`; `TessInbox.swift:29-31`; ruling index N14 | Core + Builder B |
| 4 | G650 (CL23) | The month rolls at midnight on the 1st by the phone calendar; the ruling is house time (4 am), and a test pins midnight. | `ClaudeKey.swift:83-84, 111-115`; decisions 93; `ClaudeKeyTests.swift:285` | Core |
| 5 | G651 (CL42) | No Claude client reads Low Power. Home done words (automatic) run in Low Power; plan wording and the Monday story have no gate; `PowerState.swift` is missing. | `HomeDoneWording.swift:95-113`; `PlanWording.swift:462-481`; decisions 1023, 1039, 1057 | Core + Builder A |
| 6 | G652 (CL37) | The iCloud copy and shared export keep receipts and waiting phrases. Ruled: receipts stay in the local copy only. `leaveOutPrivate` drops private objects and their ops, nothing of the Claude classes. | `PrivateWords.swift:225-260`; `TesseraBackup.swift:93-96`; decisions 1057 item 3 | Core |
| 7 | G653 (CL25) | "What was sent" as ruled (words, handles, Private phrase, Clear what was sent) is not built; Receipts shows cost lines only, and the key Test writes a ledger row although decision 113 says it writes none. | `ClaudeSection.swift:447-496`; `ClaudeKey.swift:279-287`; `what-was-sent-log.md` | Core + Builder B |
| 8 | G654 (CL16) | The first-send notice shows only after a miss that wrote something, so a first phrase that left the phone and wrote nothing (or failed) gets no notice and the flag stays unset; it replaces the receipt; its pointer says Settings, a page that does not exist. | `ClaudeTessModel.swift:141-162`; decisions 683, 1019 | Core |
| 9 | G655 (CL31) | No hard 8 s cap, no "Asking Claude" line, no Cancel: three rounds, each with an idle timeout of 8 s, can hold the Ask slot for about 25 s with nothing to tap. | `ClaudeTessModel.swift:23, 86-124, 255-277`; ruling index N16 | Core + Builder B |
| 10 | G656 (CL24) | The cap lives only in store rows. A restore of an older copy (or any loss of rows) lowers the month's total; the ruled outside spend file (decision 420) is not built. | `ClaudeKey.swift:106-115`; decisions 420 | Core |

## 3. Full rows

Columns: id; what to check (with the gap id where ranked); expected (with the Swift Testing name to write); status; file:line; the wall, Low Power or VoiceOver angle; owner.

### 3A. The capture-miss route and the walls

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL01 | Key or key-shaped text typed or pasted as a capture phrase, in any case, with spaces round its dashes, or split by a line break. | Refused first by the router with the Ask bar line; no route runs; no miss-log entry; refused again inside the Claude route. Test: `keyShapedPhraseNeverReachesAnyRoute`. | traced | `TessModel.swift:85-87`; `ClaudeTessModel.swift:56`; `ClaudeKeyGuard.swift:18-26` | Wall: the shared guard folds case, spaces and unicode dashes (KS06, KS07 closed). The dictation case with letters spelled apart is not caught (inferred, accepted). | Core |
| CL02 | A phrase the grammar cannot read that holds money, a body fact or a secret word. | Goes whole to Claude (his "all but the key"), once; the answer is never spoken back. Test: `walledMissReachesTheStubOnceAndIsNotSpokenBack`. | traced | `TessModel.swift:89-96, 105-107`; `ClaudeTessModel.swift:64-67, 147-156` | Wall: only the key stays; `ClaudeRouteTests.swift:134`. Low Power: no change (a typed Ask is his act). | Core |
| CL03 | A walled phrase the grammar understood and answered with a question or refusal ("$212.37 at Costco?"). | Stays on the phone: the Claude route is skipped when the grammar's answer is `asked`. Test: `grammarAnsweredWalledPhraseNeverGoes`. | traced | `TessModel.swift:93-94, 106` | Wall: the skip keys on `asked?.source == .grammar`; a walled phrase answered by the on-device model first would not be skipped (inferred, the on-device step returns `handled` and ends the loop). | Core |
| CL04 | Siri and Shortcuts phrases. | Commit at once, never ghost, Claude returns missed before any key read; no inbox write. Test: `siriAndShortcutsNeverReachClaude` exists. | traced | `ClaudeTessModel.swift:53`; `Intents.swift:165, 203`; `ClaudeRouteTests.swift:263` | Wall: also keeps a locked phone from spending. Siri misses are written to the miss log with source "ghost row" (`TessCaptureEngine.swift:25-27`), a small mislabel for week-one reading. | Core |
| CL05 | A cook running, or a phrase containing "timer". | No Claude call; read on the phone or not at all. | traced | `TessModel.swift:98-107` | Wall: only the whole words "timer" and "timers" count; "alarm" or "countdown" phrases outside a cook do go (inferred, decision 929 names timer phrases only). | Core |
| CL06 | A phrase over 600 characters. | "That's too long to send. Say it shorter.", marked a refusal, no row, not in the miss log, no inbox. Test: `aLongPhraseIsRefusedBeforeItLeaves` exists. | traced | `ClaudeTessModel.swift:13, 58-63`; `TessCaptureEngine.swift:59` | VoiceOver: line spoken once in the shared slot; a refusal plays no haptic (N5). The count is characters, not bytes, so 600 emoji is about 2,400 bytes (accepted). | Core |
| CL07 | The exercise name and last set in the system prompt. | A walled exercise name sends "no workout in focus" and no last set. Test: `walledExerciseNameSendsNoWorkout`. | traced | `ClaudeTessModel.swift:186-200`; `TessModelCapture.swift:70-83` | Wall: the system string is also key-checked at :68. | Core |
| CL08 | Tool results sent back to Claude in round 2, "Done" and the fixed error lines. | Fixed words only; no internal error text. Test: `toolErrorsGoBackAsFixedLines` exists. | traced | `ClaudeTessModel.swift:112-120`; `ClaudeRouteTests.swift:281` | Wall: the on-device path prints `"Error: \(error)"` (`TessModelCapture.swift:162`) but that never leaves the phone. | Core |
| CL09 | `answerQuery` count handed back to Claude. | The allow-list drops money, body and his classes (CA6 closed), but a count of notes, tasks or recipes includes private ones and flows to Claude in round 2. Ruling 61 (1): anything sent to Claude drops private items. Test: `answerQueryCountSkipsPrivateObjects`. | gap | `TessTools.swift:273-303`; decisions 61 | Wall: a count of "notes this week" can reveal that a private note exists. The answer line is only used as a tool result, never shown to him (a question-only reply returns missed, :144), so it is also useless; either drop it or filter. | Core |
| CL10 | One phrase writes at most 10 ghosts, three rounds. | Extra ghosts trimmed; a failure mid-way discards every pending ghost. | traced | `ClaudeTessModel.swift:99-111, 125-132, 166-181` | VoiceOver: undo of a trimmed set follows one slot rule. | Core |
| CL11 | Claude's own words kept? | Never stored: the reply text is shown only if it passes the voice checks and no walled phrase was involved; the op log keeps route and model only. | traced | `ClaudeTessModel.swift:146-156` | Wall: for a walled phrase the receipt is the thing-first summary, which for a task reads its masked label. The op summary can still hold the raw title in the op log (decision 931: the log keeps raw). | Core |
| CL12 | The miss log for a phrase Claude read. | Walled phrases never logged; a key never logged; capped at 200 characters and 2,000 lines; excluded from device backup. | traced | `TessCaptureEngine.swift:56-63`; `CaptureMissLog.swift:48-50, 77-84` | Wall: unwalled phrases are logged in clear on the phone, which is the stated purpose. | Core |
| CL13 | `answerQuery` and `remember` as tools Claude can call. | `remember` writes a told memory only through the same screen; the memory screen refuses a key only when the lowercase literal prefix appears (see CL58). | inferred | `TessMemory.swift:139, 195-266` | Wall: Claude can emit a key-shaped string it was never given only by luck; low. | Core |
| CL14 | The model and request shape for Haiku 5.5. | No `thinking`, no `effort`, no sampling fields sent; `tool_choice` auto. Haiku 5.5 thinks by default at medium effort and 400s non-default sampling; auto is allowed. Prices in the ledger match the models page ($0.10 and $0.50 per million for Haiku 5.5 up to 100K tokens; $2 and $10 for Sonnet 5.5). | traced | `ClaudeTessModel.swift:262-267`; `ClaudeKey.swift:93-96` | A prompt over 100K tokens would be priced higher on the API than the ledger shows; no capture reaches that. Decision 421 asks for a recheck of the Sonnet cache-read price: $0.20 per million matches 200 n$. | Core |
| CL15 | The estimate used to reserve money. | Bytes over 4 plus 10, times price, plus `maxTokens` at the output price, times 3 rounds. | traced | `ClaudeKey.swift:150-154`; `ClaudeTessModel.swift:70-71` | A reserve is always more than a real call, so a low month near $50 refuses a call that would have fit; accepted. | Core |
| CL16 | G654. The first-send notice. | Shows when the first phrase leaves, once, even when the call wrote nothing or failed; names the phrase unless walled; does not erase the thing-first receipt of what was done. Test: `noticeShowsOnSendNotOnSuccess`. | gap | `ClaudeTessModel.swift:141-162, 341-344` | Wall: a walled first send reads "Sent that to Claude ...". Today a first send that returns no tool call leaves the flag false and no notice, and a later success shows a notice about a different phrase. VoiceOver: spoken once as the slot line. | Core |
| CL17 | The notice's pointer words. | Review now, Settings later, from one value (`ClaudeWhere`). Master says "Settings" in the notice, in "Claude didn't take the key" and in the kept-link line. The task brief and the design docs use the "Settings" form; decision 1019 says Review until Settings ships. | gap (unruled) | `ClaudeTessModel.swift:160-161, 250`; `RecipeLinkReader.swift:28`; decisions 1019, 1047 | A line that points at a page that does not exist; see CALL 3. | Core |
| CL18 | A key typed into the Ask bar, Notes, a set field or Paste. | Cleared on the spot, the key line said, nothing stored. | traced | `BottomChrome.swift:395-397, 468`; `NoteEditor.swift:134-138`; `PasteRecipe.swift:182-184, 530`; `WorkoutParts.swift:369` | Wall: four doors all use the one guard. The Groceries Add line clears it too (decision 891). | Builder B |

### 3B. The key

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL19 | G647. Remove key. | Tap Remove asks "Remove the Claude key?" with "Remove" and "Keep it"; Remove deletes at once and says a plain receipt; no UNDO; no object holds the key afterwards. Test: `removeKeyIsTwoStepAndHoldsNothing`. | gap | `ClaudeSection.swift:71-72, 232, 378-402, 544-560` | Wall: for 10 s the key sits in a struct on the heap, which is exactly what the ruling removed ("nothing keeps a copy of the key"). VoiceOver: the receipt must be announced; today there is no announcement. Low Power: none. | Builder B |
| CL20 | The key Test on a pasted key. | Whitespace removed, prefix check, saved, one free `count_tokens` call, one line per outcome; the field cleared at once; clipboard cleared if unchanged. | traced | `ClaudeKey.swift:216-277`; `ClaudeSection.swift:314-326, 364-370` | Wall: a failed Test leaves the key on the clipboard (the clear runs only for a saved, non-bad key, :366); a bad key is no secret but a good key with a network failure stays pasteable (inferred). | Builder B |
| CL21 | Retest and Replace save before they check. | A retest must not delete a good key if the save fails: `save` deletes first, then adds. Replace restores the old key when the new one fails; an offline Test on the new key also restores the old and says "didn't pass", which is false (the new key was never judged). Test: `retestNeverDestroysAGoodKey`. | gap | `ClaudeKey.swift:44-50, 223`; `ClaudeSection.swift:328-356` | Wall: a keychain add failure after the delete loses the key (inferred, rare). Copy: offline Replace should say "No connection. Your old key still works." | Core + Builder B |
| CL22 | Key presence on screen and in accessibility. | "Key saved" plus a status word; no tail, length or prefix; the no-key line reads "No Claude key on this phone. Paste one here." Decision 91 accepted "No Claude key yet."; the screen's wording differs. | traced | `ClaudeSection.swift:134-141, 220-223` | VoiceOver: label "Claude key saved, works". Copy drift is CALL 5. | Builder B |
| CL23 | G650. The month boundary. | House time: a use at 2 am on the 1st counts for the old month until 4 am. Test: `monthRollsAtFourAmOnTheFirst`. | gap | `ClaudeKey.swift:83-84, 111-115`; decisions 93 | The Settings amount, the paused date and the cap all use the same function, so one fix moves all. The reset date prints "Nov 1" either way. | Core |
| CL24 | G656. The cap and a restored or lost store. | The month total is the higher of the store and a small file outside the store (decision 420). Test: `restoreOfAnOlderCopyKeepsTheMonthTotal`. | gap (not built) | `ClaudeKey.swift:106-115`; `git grep` finds no spend file | Wall: restore replaces `TessCall` rows with the copy's, so a night's spend can vanish and the $50 stop fails open. | Core |
| CL25 | G653. Does the key Test write a ledger row? | Decision 113: no row. Master writes one (`use` keyCheck) on every outcome, shown as "Key check" in Receipts, and Settings reads the newest one to print the status word. | gap (unruled) | `ClaudeKey.swift:279-287`; `ClaudeSection.swift:298-306, 520-531` | Two rulings pull apart; see CALL 4. A row is cost 0, so the $50 sum is unaffected. | Product |
| CL26 | Keychain access class and reinstall. | Unlocked only, this device only; read returns nil on a locked phone so an automatic job does nothing. Decision 685 says deleting the app loses the key; iOS usually keeps Keychain items across an uninstall, so a reinstall can find a live key, a fresh store (switch default yes) and a reset notice flag. | inferred | `ClaudeKey.swift:22-55`; decisions 685 | Wall: after a reinstall misses could go to Claude with no action from him. See CALL 6. | Core |
| CL27 | Simulator-only fake key. | `-fakeClaudeKey` is read only through `LaunchFlags`, on the simulator, and builds its value from pieces; a demo flag turns every client off. | traced | `ClaudeSection.swift:40-55`; `LaunchFlags.swift:8-21`; `AppModel.swift:85` | Wall: `-theme` also counts as a demo flag, so a pinned look turns Claude off in that run. | Builder B |
| CL28 | Backups, exports, logs and errors. | No key anywhere; the secret checklist items 1 to 9 pass. | traced | `ClaudeKey.swift:7-9`; `secret-checklist.md` items 1, 2, 5, 6, 9 | `AppModel.swift` logs seeding errors as public strings (checklist item 1 watch); recheck if a URLError with request text could reach them. | QA |
| CL29 | Settings screenshots and recordings. | The key field shows dots or "saved" only. | inferred | `ClaudeSection.swift:248-263` | The field is a secure field; manual check (checklist 12). | QA |
| CL30 | The pointer line when the key is refused. | "That looks like a Claude key. It goes in Review, under Claude." from one string used by Ask, Notes, Siri and the workout field. | traced | `ClaudeKeyGuard.swift:4`; `Intents.swift:161` | Moves to Settings only with the page; see CL17. | Core |

### 3C. Offline, retry and the inbox

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL31 | G655. The 8 s wait. | One hard 8 s limit across rounds, an "Asking Claude" line with Cancel, nothing retried. Test: `captureCallStopsAtEightSeconds`. | gap | `ClaudeTessModel.swift:23, 86-124, 255-277` | Today the timeout is per request idle time, up to three rounds. VoiceOver: "Asking Claude. Cancel." as one element, spoken once. Low Power: the wait is his act, so it runs. | Core + Builder B |
| CL32 | G648. The inbox drain. | Until `readWaiting` is wired, an offline unwalled miss says "No connection." and queues nothing (mirror only, N16); once wired, it reads only on open, online, live phrases, never in Low Power. | gap | `ClaudeTessModel.swift:134-137`; `TessInbox.swift:25-36, 58-90`; `git grep readWaiting` | Wall: the queue holds phrases in clear in the store; they ride in backups and the iCloud copy (CL37). A waiting phrase never shows to him, so "Saved it for Claude" is a promise nobody keeps. | Core |
| CL33 | G649. Offline walled miss. | "Couldn't read that offline. Try again online." (mirror only), his text left in the box, nothing queued or logged. Test: `offlineWalledMissSaysTheRuledLineAndKeepsTheBox`. | gap | `ClaudeTessModel.swift:245`; `TessInbox.swift:29-31`; ruling index N14 | The wall at the inbox holds (a walled phrase is not queued); only the words and the box differ. VoiceOver: spoken once. | Core + Builder B |
| CL34 | What counts as offline. | Every URLError except a timeout is offline in capture, including cancelled and TLS failures; a cancel (leaving the screen) would queue the phrase. | gap | `ClaudeTessModel.swift:273-275` | The key Test and plan wording split these (plan treats cancelled as no row); the table in `offline-retry-table.md` item 9 lists it as open. | Core |
| CL35 | Recipe link offline, busy, timeout, paused, bad key. | The link stays on the shelf with the ruled "kept" lines; firm refusals drop it; no self-retry. | traced | `RecipePasteLink.swift:33-72`; decisions 901 | Wall: the shelf file holds the link only, complete file protection; it is not marked excluded from device backup (CL36). | Builder B |
| CL36 | Where the kept-link shelf lives. | Marked excluded from backup like the miss log and the Home cache; erased by "Delete everything" (not built). | gap (inferred) | `RecipePasteLink.swift:83-97, 147-152`; `CaptureMissLog.swift:80-83` | A link can carry a private token in its path; stripped of tracking only. | Core |
| CL37 | G652. What a copy that leaves the phone contains. | Receipts (`TessCall`) and waiting phrases out of the iCloud copy and the shared export; in the local copy. Test: `iCloudCopyHoldsNoClaudeRows`. | gap | `PrivateWords.swift:225-260`; `TesseraBackup.swift:93-96`; decisions 1057 item 3 | Wall: private memories already leave via the `isPrivate` flag; told lines that are not private still go (accepted by decision 53 item 2 only for recipes). | Core |
| CL38 | Retry and duplicate spend. | A failed call writes its row once; no hidden retry; same-pack reuse for plan; Home done asked once per workout. | traced | `ClaudeTessModel.swift:125-132`; `PlanWording.swift:465-472`; `HomeDoneWording.swift:101-109` | A timeout is final for Home done (offline-retry-table item 10). | Core |
| CL39 | Recipe reader 504 and cancel. | 504 maps to busy here and to timeout elsewhere; a cancelled request maps to "offline" and offers to keep the link. | gap | `RecipeLinkReader.swift:574-581, 587-590` | Table item 2 lists the 504 split; cancel is new. Both only change which kept-line he reads. | Core |
| CL40 | A failed write never says done. | A failed ghost write shows "Didn't save. Try again." (decision 139). Inbox and ledger writes use `try?` and fail silently by design. | inferred | `ClaudeKey.swift:167-177`; `TessInbox.swift:32-35` | A lost ledger row means a lost cost, which feeds CL24. | Core |
| CL41 | The Claude step when the phone is in airplane mode. | No call; `.notConnectedToInternet` maps at once, so the 8 s is not waited. | traced | `ClaudeTessModel.swift:273-275` | VoiceOver: one spoken line. | Core |

### 3D. Low Power and the off switch

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL42 | G651. Home done words in Low Power. | Skipped in Low Power; a call he asks for runs. Test: `homeDoneWaitsOutLowPower`. | gap | `HomeDoneWording.swift:95-113`; `AppModel.swift:57-62`; decisions 1023 item 4 | HS12's wording ("the Home ask runs in Low Power") covers the ask he taps, not this automatic call; the two rulings agree only if the job counts as automatic. | Core + Builder A |
| CL43 | `App/PowerState.swift`. | One cached flag, the only reader of Low Power, refreshed on the power-state notification; Claude clients take it as a closure like `allowed`. | gap (not built) | `ls App`; `TessSoul.swift:108` | A closure keeps Core free of UIKit. | Builder A |
| CL44 | Plan wording and the Monday story. | Wait for power ok and retry on the next open; the story is gated once inside the Claude client. | gap (not built, latent) | `PlanWording.swift:462-481`; decisions 1039, 1057 | Plan wording has no caller (CL45), the story has no code. | Core |
| CL45 | Plan wording off. | `planWordingReady` false means no request, no row, no key read. Test: `thePlanMakesNoClaudeCall` exists. | traced | `AppModel.swift:64`; `HomePlan.swift:115`; `PlanWordingOffTests.swift:19` | When turned on, its privacy labels lack "Private workout" and "Private list" (decision 959): `PlanWording.swift:39-42`. See CL46. | Core |
| CL46 | Plan pack labels. | A title that already reads a private label goes as "task"; the set must include every label the app prints, including "Private workout", "Private list". Test: `planPackTreatsAllPrivateLabelsAsPrivate`. | gap (latent) | `PlanWording.swift:39-48`; decisions 959 | Wall: a masked workout title would go to Claude as the label text, which is harmless but not as ruled. | Core |
| CL47 | The off switch stops everything. | Capture, recipe reads, Home words and plan all check `asksClaude` at call time; the key Test is the only call that runs with it off. | traced | `ClaudeTessModel.swift:56`; `RecipeLinkReader.swift:540`; `HomeDoneWording.swift:97`; `PlanWording.swift:463` | Wall: a call already in flight keeps going when the switch flips (the check is at start); acceptable but unstated. | Core |
| CL48 | A throwaway store. | `asksClaude` is false when the real store did not open. Test: `aThrowawayStoreNeverAsksClaude` exists. | traced | `AppModel.swift:58-60, 170-178` | Wall: the default of "yes" can never apply to a memory fallback. | Core |
| CL49 | The switch row for VoiceOver. | Announced as a switch with value on or off; flipping announces Tess's answer line once. | gap | `ClaudeSection.swift:169-189, 285-296` | Today a Button with label "Tess asks Claude" and value yes or no; the answer line appears but nothing is posted. Test: `claudeSwitchPostsItsAnswer`. | Builder B |
| CL50 | Turning the switch off. | Waiting phrases are released (`clearWaiting`) and any cached Claude words keep or go per ruling; nothing calls `clearWaiting`. | gap (latent) | `TessInbox.swift:49-53`; `ClaudeSection.swift:285-296` | QA L4 on #305 asked for it; with no drain it matters only when CL32 lands. | Core |
| CL51 | The "Not today" pause. | A setting in Settings sets `pauseUntilTomorrow`; there is no caller. | gap (not built) | `ClaudeTessModel.swift:318-339`; `git grep pauseUntilTomorrow` | Decision 558 area: the pause was parked; either build it or remove the dead flag. See CALL 7. | Product |

### 3E. Spend meter, receipts and What was sent

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL52 | The meter line. | "This month $1.20 of $50." rounded up to the cent, a brushstroke to the share, amber from 80%, "Paused until Nov 1." at the cap. | traced | `ClaudeSection.swift:193-217, 415-441` | VoiceOver: the visible text rounds up, the stroke's label prints the exact amount to two decimals (`%.2f`), so $1.196 reads "$1.20" and "1.20" only by luck; round both the same way. Low Power: the stroke draws in 0.5 s unless Reduce Motion; the policy is not Low Power aware (CL43). | Builder B |
| CL53 | Two reserves at once. | The cap holds under concurrency through one reserve step on the main actor. Test: `twoCallsAtOnceCannotBothPassTheCap` exists. | traced | `ClaudeKey.swift:123-147` | The pending map is process-wide and keyed by store, fine for one app. | Core |
| CL54 | Failed and timed-out calls cost. | Counted as sent (decision 113): the row is written with the tokens billed; an empty 200 still bills. | traced | `ClaudeTessModel.swift:125-132, 290-292` | The cap line "Claude paused until Nov 1." writes no row. | Core |
| CL55 | G653. "What was sent". | A list under a receipt row showing the words as sent (handles for names), "Private phrase" for a walled one, a count of held-back requests, "Clear what was sent". | gap (not built) | `what-was-sent-log.md`; `ClaudeSection.swift:447-496` | Wall: the ruled log excludes payloads from every backup (decision 113 item 5). VoiceOver: each row one element, time then job then cost. | Core + Builder B |
| CL56 | A walled phrase on a receipt row. | Job and cost only; never words. Test: `theReceiptsHoldNoWordOfAWalledPhrase` exists. | traced | `ClaudeSection.swift:501-507`; `ClaudeRouteTests.swift:160` | Receipts are number-only today, so the rule holds trivially. | Core |
| CL57 | Job names on receipts. | Every job has a word; today the default branch prints "Tess" for question, ask and later jobs; "A paste" is used for a recipe paste. | gap (latent) | `ClaudeSection.swift:520-531`; `settings-claude-page-spec.md` section 2 | Names for week story and others are proposed, not ruled. | Design |

### 3F. The memory store

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL58 | The key check in the memory screen. | Uses the shared guard (case, spaces, dashes), not only the lowercase literal prefix. Test: `memoryRefusesAKeyInAnyCase`. | gap | `TessMemory.swift:139` | Wall: a told line "SK ..." in upper case passes to the store and then backups. The guard is one function away. | Core |
| CL59 | A memory line sent to Claude. | None today (no job reads memory); when one does, private lines, health, money and places never go. | traced | `claude-requests-audit.md`; `TessMemory.swift:97-168` | Wall: `isPrivate` lines stay on the phone and out of the iCloud copy. | Core |
| CL60 | Forgetting is his, never Claude's. | No forget tool; a forgotten line's hash survives a restore; "Forget everything" is one op with one UNDO. | traced | `TessMemory.swift:297-330`; decisions 631 | Claude "remember" is allowed and writes a told line the same as his words (CL13). | Core |
| CL61 | Cached Claude words (Home done). | A file the app owns, complete protection, excluded from backup, erased by "Delete everything" and cleared when memory is forgotten? Only the first two are built. | gap (inferred) | `HomeDoneWording.swift:83-86, 206-217` | No erase path exists because "Delete everything" is not built; the cache also outlives a removed key. | Core |

### 3G. Plan wording and the recipe reader, in short

| ID | What to check | Expected | Status | file:line | Angle | Owner |
|---|---|---|---|---|---|---|
| CL62 | Recipe page text sent. | Lines with a secret, money, a body fact or a key are cut one line at a time; recipe measures like "1.25 cups" are not money. | traced | `RecipeLinkReader.swift:466-498, 542` | Wall: his own pasted text is not subject; only the fetched page. | Core |
| CL63 | Recipe reply output check. | A reply with a link, markup, money, a phone number, a login line or a steering sentence is dropped whole. | traced | `RecipeLinkReader.swift:504-531` | Injection audit item 5 is closed by this check. | Core |
| CL64 | Late plan reply. | Dropped, its cost kept, outcome "late". | traced | `PlanWording.swift:487-492, 524-527` | Latent while plan wording is off. | Core |

## 4. Not found / not read

I did not open `docs/ai/spend-projection.md`, `memory-store.md`, `architecture.md` or `injection-audit.md` beyond their headings and the lines cited, did not read the project mirror of decisions.md (rows marked "mirror only" rest on the design docs that quote it), did not read `TessSoul` beyond its Low Power line, and did not trace the Settings host (`ReviewView`) for the VoiceOver order of the Claude section. No stored key, Keychain item or secrets file was opened.

## PRODUCT CALLS

### CALL 1 (CL19): Remove key after the two-step

| Option | Consequence |
|---|---|
| A. Ship the ruled two-step now; delete `KeyRemoval`; rewrite the UI test | Matches decisions 1049 and 1057; no copy of the key lives after Remove; the 10 s of safety is gone, replaced by the confirm. |
| B. Keep the one tap with UNDO | Keeps a copy of the key in memory for 10 s; contradicts two rulings. |
| C. Two-step and a re-paste hint in the receipt | Same as A with one more sentence; extra copy to approve. |

Recommended: A. Reason: it is already ruled. Owner: Builder B.

### CALL 2 (CL24): Where the outside spend file lives

| Option | Consequence |
|---|---|
| A. Small file beside the store, excluded from backup, higher of the two wins (decision 420) | The cap survives a restore; a reset of the phone resets the month. |
| B. Keychain item with the month's total | Survives a reinstall too; one more secret store to describe. |
| C. Leave it in rows only | A restore can lower the month's spend. |

Recommended: A. Reason: it follows the ruling and needs no new store. Owner: Core.

### CALL 3 (CL17): Which place name the notices say today

| Option | Consequence |
|---|---|
| A. Review now, flip to Settings with the page, from one `ClaudeWhere` value | Follows decisions 1019 and 1047; the first-send notice points at a real place. |
| B. Keep "Settings" in the Core strings | Matches the brief but points at a page that does not exist yet. |
| C. Say neither ("Turn this off in the Claude section") | No flip needed; a new string for Design. |

Recommended: A. Reason: it is ruled. Owner: Core.

### CALL 4 (CL25): Does the key Test write a ledger row?

| Option | Consequence |
|---|---|
| A. No row (decision 113); the status word comes from a small device flag | Receipts list only real requests; Settings needs the flag. |
| B. Keep the row, tell Receipts "Key check" | What he sees is complete; contradicts "Core confirms it writes no row". |
| C. A row without cost, hidden from Receipts | Keeps the status source, hides the line; hides a call that did leave the phone. |

Recommended: B, then amend decision 113. Reason: the Test does send "Hi" to Claude, and the ruling's reason (not counted as sent) is about the cap, not about hiding it. Owner: Product.

### CALL 5 (CL22): The no-key and key lines

| Option | Consequence |
|---|---|
| A. "Key saved" / "No Claude key yet." (decision 91) | One pair of words everywhere; the long no-key sentence goes. |
| B. Keep the screen's longer lines | No change; copy drift stays. |

Recommended: A. Owner: Builder B.

### CALL 6 (CL26): Key found after a reinstall

| Option | Consequence |
|---|---|
| A. A found key is used; the switch and the notice flag restore from the settings object | He is not asked again; nothing new to build; the notice flag lives in UserDefaults, so the notice repeats once. |
| B. A found key asks once: "Use the Claude key still on this phone?" | One extra step; no surprise spend. |
| C. Delete the found key on first launch of a fresh store | Safest; he re-pastes. |

Recommended: B. Reason: the default of yes plus a surviving key sends misses to Claude with no act of his. Owner: Core, Builder B.

### CALL 7 (CL51): The "Not today" pause

| Option | Consequence |
|---|---|
| A. Remove the dead flag and the doc mentions | Less code; the off switch is the only pause. |
| B. Build a "Not today" word under the switch | A way to stop until 4 am without losing the setting. |

Recommended: A. Reason: nobody asked for it since Oct 16. Owner: Product.

### CALL 8 (gap ids): Renumbering

| Option | Consequence |
|---|---|
| A. Keep G647 to G656; renumber at merge if another PR took them | Smallest change. |
| B. Take the next free range from the mirror before merge | Needs the mirror read. |

Recommended: A. Owner: Product.
