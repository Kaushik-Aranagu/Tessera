# Claude key secret checklist (C4)

Scope: origin/master. Run from /home/claude/Tessera as `git grep -nE '<pattern>' origin/master -- <paths>`.
S = TesseraCore/Sources/TesseraTess. "Prefix" below means the Claude key prefix (hyphenated vendor tag, 7 chars).
Never paste a real key into a grep, a ticket or a screenshot.

1. Key never logged or printed.
   Grep: `os_log|Logger\(|NSLog|print\(|dump\(|privacy:` in App, Features, S.
   Expect: no hit has the key, a request, a header dict or a raw Error in its arguments.
   Found: App/AppModel.swift:136 (seeding error), Features/Backup/BackupKeeper.swift:47,60 (backup error),
   S/PlanWording.swift:437,528 (plan reject codes only). PASS (none touch the key).
   Watch: String(describing: error) is public in AppModel:136 and BackupKeeper:60; PASS today, recheck if a URLError
   with request text ever reaches them.
2. Key not in error strings or crash text.
   Grep: `"\\\(error\)"|describing: error|localizedDescription` in S.
   Expect: errors carry only the Outcome or Failure enum.
   Found: S/TessModelCapture.swift:160 ("Error: \(error)"), S/TessTools.swift:74 (TessToolError("\(error)")).
   These are tool errors, not Claude client errors. PASS, but QA reads both once to confirm no request object.
   Claude client failures (ClaudeKey.swift:260-269, PlanWording.swift:609-624) map to enums. PASS.
3. No part of the key is kept: no length, no prefix, no last 4.
   Grep: `suffix\(|prefix\(|\.count > ` and the name `last4` in S and Features/Settings.
   Expect: zero hits on key values.
   Found: ClaudeKey.swift:222 (suffix(4)), :195-196 (last4 field), :219 (key.count > 12 length check),
   :328 ("Key saved. Ends in ...last4"), Features/Settings/ClaudeSection.swift:57,87-88,218,222,303,361 (shown on
   screen and read aloud in an accessibility label). FAIL: last 4 chars are kept in state, shown, and spoken;
   key length is tested. Fix: show "Key saved" plus yes/no only; drop last4.
4. Presence is yes/no only.
   Test: with a stored key and with none, Settings text and accessibility labels say only saved or not saved.
   Found: ClaudeSection.swift:218 prints the last 4. FAIL (same fix as 3).
5. Key lives only in Keychain or env.
   Grep: `UserDefaults|AppStorage|SceneStorage|ProcessInfo.*environment` near `key` in S, Features, App.
   Expect: only SystemKeychain (ClaudeKey.swift:22-55: this device only, when unlocked, not synced) and
   InMemoryKeychain (:59, tests). Found: PASS. -fakeClaudeKey (AppModel.swift:146, ClaudeSection.swift:50) is
   in-memory, simulator only. PASS.
6. Only api.anthropic.com.
   Grep: `https?://` in S excluding RecipeLinkReader's user-link fetch (RecipeLinkReader.swift:191-211).
   Expect: one base URL, ClaudeKeyCheck.base (ClaudeKey.swift:200); header set only at ClaudeKey.swift:298,
   ClaudeTessModel.swift:217, PlanWording.swift:586, RecipeLinkReader.swift:384, all using that base. PASS.
7. Redirects refused on every Claude request.
   Grep: `willPerformHTTPRedirection|delegate:` in S. Expect a refuse-all delegate on each Claude call.
   Found: only RedirectGuard (RecipeLinkReader.swift:442-451) on the user-link fetch (:197). The four Claude
   calls (ClaudeKey.swift:302, ClaudeTessModel.swift ~:215, PlanWording.swift ~:584, RecipeLinkReader.swift ~:382)
   use session.data(for:) with no delegate and a default .ephemeral session. FAIL: URLSession drops sensitive
   headers on cross-host redirects only by convention; refusal is not enforced. Fix: a delegate that completes
   the redirect with nil.
8. Header comment accuracy. ClaudeKey.swift:9 says "Authorization header"; the code uses x-api-key (:298).
   FAIL (doc only): fix the comment.
9. Op log, objects, backups, exports hold no key.
   Test: ClaudeKeyTests.swift:117 scans stored files for the prefix. Run `swift test --filter ClaudeKey` in
   TesseraCore. Expect pass. Also open a backup copy and run `grep -c` for the prefix text; expect 0. PASS (test).
   Input guards: looksLikeClaudeKey in Notes.swift:111,166, TessInbox.swift:29, CaptureMissLog.swift:39,
   Intents.swift:161. PASS.
10. TessSent log holds no key. Grep `TessSent` in all swift: no hit on origin/master in code. N/A today; rerun
    when it lands and check its fields hold no header or body from Claude requests.
11. Test fixtures and docs are not key-shaped.
    Grep: the prefix text, case-insensitive, over tests, docs, scripts, fixtures. Expect zero outside the guards
    (ClaudeKeyGuard.swift:9,16, TessMemory.swift:139, ClaudeKey.swift:219, ClaudeSection.swift:321).
    Found in tests: ClaudeKeyTests.swift:63,90,117,170,171; ClaudeRouteTests.swift:65,278; PlanWordingTests.swift:191;
    PrivacyFollowupTests.swift:100,103. FAIL: fixtures start with the real prefix plus random text. Fix: use a
    made-up phrase like "test-claude-phrase-1" and pass it to the guard tests through a constant that is not
    key-shaped (guard tests need the prefix only to prove refusal; build it at run time, never as a literal).
12. Screenshots and snapshots.
    Test: after a Settings run with -fakeClaudeKey, open every image in docs/recordings and any snapshot
    folder; the key field must show dots or "saved" only. Expect no characters of a key. Manual: QA signs off.
13. Docs wording: grep docs for the prefix text; expect only "the Claude key prefix" in words. Not run on docs
    here beyond docs/research (excluded); QA runs it.

Result today: FAIL on 3, 4, 7, 8, 11. PASS on 1, 2, 5, 6, 9. 10 N/A. 12, 13 manual.

**Capture misses (Oct 17, Core #860).** Item 9's input guards are unchanged: a key or key-shaped text is refused in `TessRouter` first and again in the Claude route, so it never reaches Claude. Money, body, health and secret words in a capture phrase the grammar can't read are now allowed to go (his "yes, all but the key"); a walled phrase the grammar answered stays on the phone, and Siri and Shortcuts never send.
