# Claude first run, line by line

For: Builder B (Settings: Claude, cloud mark, ghost row, plan), QA. Research lab, board item 85, 2026-10-16.
Reads with `settings-claude.md` (S1 to S26), `claude-first-uses.md`, `tess-voice.md` (M1 to M58), `tess-model-layer.md`, `fixtures/grammar-miss-claude.md` (use 1), `fixtures/plan-my-day-claude.md` and `plan-my-day-prompt.md` (use 2).
**Master read:** `origin/master` at `4518c48` (Merge PR #222), read with `git show` and `git grep`; nothing was run and no key was used. #218 (`5a24f54`) added `TesseraCore/Sources/TesseraTess/ClaudeKey.swift` (Keychain store, `TessUsageLedger`, `ClaudeKeyCheck` with one line per outcome), the `tessCall` class, the `sk-ant-` guards in `TessRouter` and the miss log, and `TessUse.keyCheck`. Nothing after #218 touches Claude.
**Not on master yet:** any Settings screen, Settings: Claude, the `SecureField` paste line, `ClaudeTessModel`, the cloud mark, "· via Claude", receipts, the month line, `TessInbox`, `NWPathMonitor`, Plan my day, `ProposePlan`. Every such step below gives the expected text only.
Key placeholder in this file: `sk-ant-…`; last four: `a1B2`. No real key appears anywhere here.

## The walk

### 1. He opens Settings, then Claude
- **Does:** taps into Settings, then Claude.
- **Master:** not on master yet. No Settings screen exists (`Features/Review/ReviewView.swift:215`: "The look, until Settings exists"). The only route to Claude is the Ask bar guard, which tells him to go somewhere he can't reach: "That looks like a Claude key. Paste it in Settings." (`TesseraCore/Sources/TesseraTess/TessModel.swift:64`).
- **Expected (S1):** "Tess thinks on this phone only." with the cobalt value line **Add a Claude key**. No month, key or receipts lines.
- **Flag F1:** M24 points at a screen master doesn't have. Fine once Settings: Claude ships; QA should not test M24 as "done" until then.

### 2. He taps Add and pastes a fresh key
- **Does:** taps **Add a Claude key**, long-presses the 0.5pt cobalt writing line, pastes `sk-ant-…`.
- **Master:** not on master yet.
- **Expected (S2):** no Tess line; VoiceOver label "Claude key". A `SecureField`, autocorrect off, no `textContentType`, never in `@AppStorage` or `@SceneStorage`, long-press paste only (C13: no pasteboard read on open, so no iOS paste banner).
- **Key exposure:** the draft must live in `@State` only and be cleared the moment Test returns. No `print`, `Logger`, `dump` or `debugDescription` of the field, the request or `allHTTPHeaderFields`. The scheme must not set `CFNETWORK_DIAGNOSTICS`.
- **Whitespace (S3):** expected: strip all whitespace, anywhere, then go on. Master trims only the ends and then refuses a key with whitespace inside: `pasted.trimmingCharacters(in: .whitespacesAndNewlines)` then `guard key.hasPrefix("sk-ant-"), !key.contains(where: \.isWhitespace)` (`ClaudeKey.swift:185-186`). A key pasted from Notes with a wrapped line break gets S5's "That doesn't look like a Claude key. Paste it again?", which is wrong. **Flag F2.**

### 3. The masking
- **Master:** `ClaudeKeyCheck.Result.last4` is `String(key.suffix(4))` (`ClaudeKey.swift:189`), returned as nil only for a bad key (`:250`). The full key is held only in the `key` local and the request header (`:257`).
- **Expected (S4):** the key drains to its last four as soon as Test starts; after that it is never drawn again. Key line `...a1B2 · works`.
- **VoiceOver:** expected "Claude key, ends in a1B2". The visible "...a1B2" would read as "dot dot dot a 1 B 2" unless the label is set by hand. **Flag F3.**
- **Screenshots:** a `SecureField` is masked in screenshots and recordings; a `TextField` is not. The drained "...a1B2" is the only text a screenshot may show.

### 4. Test runs by itself (waiting)
- **Master:** `test(pasted:)` saves to the Keychain first (`_ = keys.save(key)`, `ClaudeKey.swift:190`), then one `count_tokens` call with a 10 s timeout (`:197`, `:255`). The save result is thrown away, so if the Keychain write fails the line still says "Key saved." **Flag F4.**
- **Expected (S4):** "Checking it with Claude." (new copy, Design to confirm); cloud wisps on the soul, soul in thinking mode (`TessSoul(mode: .thinking)` exists, `DesignSystem/ThinkingIndicator.swift:11`). No action words until it answers.
- **Header:** master sends `Authorization: Bearer <key>` (`:257`, asserted in `ClaudeKeyTests.swift:76`), as `claude-key-test.md` §2 chose. The bundled Claude API reference still shows `x-api-key` in every raw HTTP example. If the API ever rejects Bearer for a plain key, every real key would come back 401, read "That key didn't work." and be deleted. UNVERIFIED; **Flag F5**: QA confirms on the first real Test, before anything else.

### 5. Test outcomes, master line against expected

| Outcome | Master line (`ClaudeKey.swift:285-300`) | Expected (S#, M#) | Status |
|---|---|---|---|
| Works (200) | "Key saved. Ends in ...\(last4)." `:287` | S6, M1 "Key saved. Ends in ...a1B2." | Match. Switch turns to **Claude**; month, misses, receipts lines unfold. One line only, no M5 (C17) |
| Bad key (401) | "That key didn't work. Paste it again?" `:288`; Keychain item deleted `:232-234` | S7, M2 | Match. No UNDO |
| Not allowed (403) | "That key can't use Claude yet. Check it in the Console?" `:289` | S8, M25; key kept, `...a1B2 · not allowed` | Match |
| No network | "No connection. I kept the key and will check it later." `:290` | S9, M26 | Line matches; "will check it later" has no code behind it. **Flag F6** |
| Timed out (10 s, 504) | "Claude didn't answer in time. I'll check again later." `:291` | S10, M27 | Same promise as F6 |
| Busy (429, 500, 529) | "Claude is busy right now. I'll check again soon." `:292` | S11, M29 | Same promise as F6 |
| Anthropic spend limit (K8) | "Key saved. Your Anthropic account is paused for now." `:293` | S12, M30; `...a1B2 · account paused` | Match |
| Our $10 cap already reached | "Key saved. Claude paused until \(next...)." `:296-298` gives "Key saved. Claude paused until Nov 1." | S14, M28; key line still `...a1B2 · works`, then S17 | Line matches. Master turns `.works` into `.capReached` (`:235-239`), so the screen must still draw "works". **Flag F7** |
| Not a key | "That doesn't look like a Claude key. Paste it again?" `:294`; nothing saved or sent | S5, M31 | Match, except the whitespace case (F2) |
| Anything else | "I couldn't check that key. Try again?" `:295` | S13, M32 | Match |

- **Voice:** every master line above passes `TessVoice.violations` (`TessCapturing.swift:88`): under 12 words, no "!", no banned words. The 10-word lines are the longest.
- **Key exposure:** no line, `Result` field or ledger row holds the key. Error bodies are read for `type` and `error_code` only, never shown (`:266-270`). The ledger row stores `requestID`, tokens, cost and outcome (`:135-145`).
- **Ledger row title:** `title: "\(use.rawValue) call"` (`:135`) names the Test row "keyCheck call". The `tessCall` class has `parent: .thing` (`SystemCatalog.swift:211`). If Tess Calls show in any object list or search, that camelCase title breaks voice. UNVERIFIED whether they show. **Flag F8.**

### 6. He leaves the screen
- **Master:** not on master yet.
- **Expected (S15):** "This month **$0.00** of **$10**." (the Test is free); "Misses go to Claude: **yes**."; key line `...a1B2 · works` with TEST · REPLACE · REMOVE; nothing shown beside the soul. After S9 to S11 the screen checks once on the next open with a usable path (F6). Leaving with an empty writing line just closes it (S2).
- **Key exposure:** the app switcher snapshot is taken after the drain, so it can only show "...a1B2". A `SecureField` still focused when he swipes up is masked anyway.

### 7. First grammar miss goes to Claude (use 1)
- **Does:** on Now at Thu 6:10 pm, types `call mom half 7` into Ask and taps Return (fixture A092).
- **Master:** the router holds the grammar and on-device routes only (`TessCaptureEngine.swift:46-50`). A miss ends in "Didn't catch that. Try “bench 80 x 8”." (`TessModel.swift:74`) and goes into the miss log. Nothing reaches Claude: `ClaudeTessModel` is not on master yet.
- **Waiting, expected:** cloud mark on the bloom while the request is out; VoiceOver "Sent to Claude" (M17). Falling back to Claude is never said in words. Master already shows the 2 s drying ghost of his text (`BottomChrome.swift:389-392`) and thinking mode; the mark sits on top of that.
- **Ghost row, expected:** "Call mom, today 7:30 pm." built on the phone (`TessCaptureEngine.when`, `TessCaptureEngine.swift:217`), with the cloud mark and VIA CLAUDE on the row. Master's `GhostRow` draws `Text(item.title)` and `Format.clock(item.start)` (`Features/Home/NowPage.swift:292`) with VoiceOver "Proposed: \(item.title), \(Format.clock(item.start))" (`:330`). There is no slot for the mark or "via Claude", in pixels or in VoiceOver. **Flag F9.**
- **Accept, expected:** a tap or the 2 s stroke commits; receipt "Call mom, today 7:30 pm · via Claude" (M16), then "Tess: $0.01 this month." (M7; $0.0006 rounds up to the cent). Master's reply line fades after 4 s (`BottomChrome.swift:443-447`), so M7 needs its own place.
- **Undo, expected:** "Call mom taken back." (M34). Master's `undoLastCapture()` (`App/AppModel.swift:226`) reverts the records but sets no line, so he gets silence. **Flag F10.**
- **Pause rule, expected (S25):** 3 of 10 Claude ghost rows taken back in a row: "Misses on this phone today. 3 of 10 taken back." and Settings reads "Misses go to Claude: **not today**." Not on master yet.
- **Fallbacks, expected:** offline "Kept it. I'll read it once you're online." (M12) and badge "1 waiting for Tess" (M13); busy "Claude is busy. Kept it for later." (M22); timeout "Claude timed out. Call mom?" (M18); cap "Claude paused until Nov 1. On-device until then." (M10, once a month).
- **Key exposure in Ask:** the router guard runs only for text that reaches `model.ask`. `commit` sends anything with "best", a word "pr"/"prs", or a trailing "?" to `CommandInterpreter` first (`BottomChrome.swift:418-419`). A pasted key followed by "?" ("is this right sk-ant-…?") skips the guard, falls through to `model.capture(title:)` and is saved as a task titled "Is this right sk-ant-…?" (`BottomChrome.swift:637-641`). It then reaches the op log, Now, widgets, backups and exports. A key that starts the text is saved with a capital "Sk-ant-", which defeats every case-sensitive `sk-ant-` check. The leak test (`ClaudeKeyTests.swift:81-98`) only covers `TessCaptureEngine`, not this path. **Flag F11.**
- **Key on screen in Ask:** the Ask field is a plain `TextField` (`BottomChrome.swift:278`), and the drying ghost shows the whole pasted key at 45% for 2 s (`:280`, `:392`). Any screenshot or recording in that window shows the key. **Flag F12.**

### 8. First Plan my day on Claude (use 2)
- **Gate:** use 2 waits for 10 real use-1 calls whose costs match the Console within 10%, no more than 3 of them taken back, and 21 of 23 eval packs passing (`claude-first-uses.md` order 2; `plan-my-day-claude.md` bottom line). His first Plan my day after the key works is still the rules plan.
- **Master:** not on master yet: no Plan my day, `PlanPack`, `ProposePlan` or validator (`git grep` finds none).
- **Waiting, expected:** the rules plan draws at once with its plain lines; cloud mark on the bloom while the call is out (Sonnet 5.5, 20 s). No partial stream: the reply must pass V1 to V12 first.
- **The plan, expected:** the worded lines replace the plain ones in place through `withTesseraAnimation`. Start line, e.g. "Electricity bill first, then the registration."; at most 3 ghost lines; accept "Pay electricity bill, 7:30 am."; Undo "Pay electricity bill taken back."; receipt row "6:12 pm · Plan my day · Sonnet · 0.5¢".
- **Voice:** `claude-first-uses.md` still shows "30 min, done well before 17:00." and "Bike light sorted by 08:30.", which break the 6:37 PM PT time format. The fixture's form ("5 pm", "8:30 am") is the right one. **Flag F13.**
- **Fallback, expected:** offline "Here's your usual plan." (M23, never silence); timeout "Claude timed out. Here's your usual plan."; busy "Claude is busy. Here's your usual plan."; failed validation "Here's your usual plan." (logged as `invalid`); cap M10 once, then M23. Nothing is queued.

## QA checklist

1. Settings, then Claude, with an empty Keychain: exactly "Tess thinks on this phone only." and **Add a Claude key**.
2. Paste a key with a space at each end: works. Paste one with a line break in the middle: should work (S3); fails on master's `ClaudeKey.swift:186` (F2).
3. Paste "hello": "That doesn't look like a Claude key. Paste it again?"; no request in the proxy log; no ledger row.
4. First real Test with a working key: 200, "Key saved. Ends in ...a1B2.", and the request carries the auth header the API accepts (F5).
5. Take a screenshot and a screen recording during Test and after it: neither shows more than the last four.
6. VoiceOver on the key line reads "Claude key, ends in a1B2", never the dots or more characters (F3).
7. Wrong key (revoked in the Console): "That key didn't work. Paste it again?"; Keychain item gone; no UNDO.
8. Airplane mode at Test: "No connection. I kept the key and will check it later."; key line `· not checked`; turn the network on, reopen: it checks once (F6).
9. Ledger seeded at $10: "Key saved. Claude paused until Nov 1."; key line still says "works" (F7).
10. After Test, search a backup, the export, the op log, `UserDefaults`, `capture-misses.jsonl` and the device console for `sk-ant-` and the key: zero hits.
11. In Ask, paste the key alone, then the key plus "?", then "pr sk-ant-…": every case answers "That looks like a Claude key. Paste it in Settings." and writes nothing (F11).
12. First use-1 miss: cloud mark and VoiceOver "Sent to Claude" while out; ghost "Call mom, today 7:30 pm." with VIA CLAUDE; receipt then "Tess: $0.01 this month." (F9).
13. Undo that ghost row: "Call mom taken back." (F10). Undo 3 of 10 in a row: S25 line and "not today".
14. Offline miss: "Kept it. I'll read it once you're online." and "1 waiting for Tess"; back online, next open: "Read 1 waiting. 1 to check."
15. Every line seen above passes `TessVoice.violations`; no "!", no 24-hour times on a line (F13).

## Flags for Builder B

1. **F11, key saved as a task.** `commit` (`BottomChrome.swift:418-419`) sends "?", "best" and "pr" text to `CommandInterpreter` before the router's `sk-ant-` guard. Check `sk-ant-` (case-insensitive) at the top of `commit` and `CommandInterpreter.run`, and add this path to the leak test.
2. **F12, key visible in Ask.** Clear `commandDraft` and show M24 as soon as the draft holds `sk-ant-`, before Return and before the 2 s drying ghost (`BottomChrome.swift:278-294`, `:392`).
3. **F5, auth header.** Master sends `Authorization: Bearer` (`ClaudeKey.swift:257`). Confirm on the first real Test; if it 401s, switch to `x-api-key` before he pastes his key, or a good key is deleted.
4. **F2, whitespace.** Strip all whitespace, not just the ends (`ClaudeKey.swift:185-186`), per S3.
5. **F4, unchecked save.** `_ = keys.save(key)` (`:190`): if it returns false, show S13 "I couldn't check that key. Try again?", not "Key saved."
6. **F6, kept promises.** M26, M27 and M29 promise a later check; nothing schedules one. Run one check on the next open with a usable path, or change the lines.
7. **F7, cap at Test.** For `.capReached` the key line still reads `...a1B2 · works` and the month sentence becomes "Paused until **Nov 1**."
8. **F3, VoiceOver.** Set the key line label to "Claude key, ends in a1B2" by hand.
9. **F9, cloud mark slot.** `GhostRow` (`NowPage.swift:278-331`) needs the mark, VIA CLAUDE, and "via Claude" in its VoiceOver label, read from `OpRecord.route == .claude`.
10. **F10, Undo line.** `undoLastCapture()` (`AppModel.swift:226`) should say "{name} taken back." through `say`.
11. **F8, ledger row title.** Title Tess Call rows in his words ("Key check", "Grammar miss", "Plan my day") or keep the class out of object lists and search.
12. **F1, Settings first.** M24 sends him to Settings; ship Settings: Claude before or with the use-1 route.
13. **F13, plan times.** Use the fixture's "5 pm" form; fix the 24-hour examples in `claude-first-uses.md` use 2.
14. **Never log the key.** No `print`/`Logger` of the field, request or headers; `SecureField` with no `textContentType`; draft in `@State` only; drain at Test start.
