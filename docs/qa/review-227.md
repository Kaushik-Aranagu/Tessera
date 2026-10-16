# Review #227: Settings, Claude key field (8fc5bd3, head c884384)

Builder B. Static review against review-218.md (app notes) and research/claude-first-run.md (14 flags). No Swift toolchain here, so read, not run.

**Verdict: PASS. Safe for Kaushik to type a real key on the next install, before Core's key-hardening PR lands.** Two should-fix lows (C1, C2), the rest are notes.

## Why a real key is safe now
- **Field:** SecureField; `submit()` strips whitespace and clears `draft` before anything else (ClaudeSection.swift:240-242), so the key isn't held in view state or drawn. Only `...last4` is shown.
- **Storage:** Core's device-only Keychain item (#218). No op, no object, no backup, no export. REMOVE with UNDO is in-memory state only (`removed` flag + a 10 s Task); the Keychain item stays until `finishRemoval()` (:312). This is exactly review-218's app note.
- **Check:** free `count_tokens` with `Authorization: Bearer`, which is Anthropic's documented header (x-api-key is legacy). A good key won't 401, so Core's "delete on first 401" can't bite a good key. If it ever did, the cost is a re-paste; nothing leaks.
- **Ask bar:** `looksLikeClaudeKey` is case-insensitive and runs on the draft (BottomChrome.swift:297), in `dry()` (:410) and `commit()` (:441). Before any interpreter, no ghost row, no task.
- **Workout LiveAskField (Builder A's guard still queued):** it goes through AppModel.ask to `TessRouter.run`, which refuses the Claude key prefix before any route. Real keys start with the Claude key prefix in lowercase, so the router's case-sensitive check catches a real paste. Only a hand-uppercased key would slip, which won't happen by accident.
- **Recipe paste:** cleared on arrival with a line pointing to Settings (PasteRecipe.swift:118).
- **Spend:** today only the Test spends (free, or a 1-token fallback). K11 (cap under concurrent calls) still has to land before planner/Ask use Claude, not before he types the key.

So the Core hardening PR is good tidying but not a safety gate for the key.

## Research flags (claude-first-run.md)
| Flag | State |
|---|---|
| F1 Settings first | Done: under the LookSentence on Review |
| F2 whitespace | Done: all whitespace stripped before Core |
| F3 VoiceOver | Done: field label, month line label |
| F4 `keys.save` result unchecked | Open (C3) |
| F5 auth header | OK: Bearer is documented |
| F6 "I'll check again later" lines | Open: no re-check code behind them (C4) |
| F7 cap at Test reads "works" | As specified: shows "paused until" line |
| F8 Tess Call rows in object lists | Open, belongs to the lists work |
| F9/F10 ghost mark, Undo line | N/A until Claude writes ghost rows |
| F11 commit guard | Done |
| F12 clear the Ask draft | Done |
| F13 plan times | N/A here |
| Rule 14 "SecureField, no textContentType" | **Not followed (C1)** |

## Should-fix (small)
- **C1:** `.textContentType(.password)` (ClaudeSection.swift:192). Research rule 14 says no content type. `.password` invites Password AutoFill suggestions and can trigger iOS's "Save Password?" sheet after the field is cleared, which would offer to put the key in Passwords (iCloud Keychain, synced). Fix: remove the line (or `.textContentType(nil)`). Phone smoke: paste a key, confirm no Save Password sheet.
- **C2:** removal pending when the app is killed. If he taps REMOVE and the app is killed or suspended within 10 s, `onDisappear` may not run (backgrounding doesn't fire it), so the key quietly stays while he believes it's gone. Fix: also finish on `scenePhase` going to background, or persist a "remove after" date and finish it on launch.

## Lows
- **C3 (F4):** `keys.save(previous)` result is ignored on a failed Replace (:270). If the save fails, the old key is gone and the line still implies it's kept. Rare (Keychain write while unlocked).
- **C4 (F6):** a failed Replace that was offline or busy (not a bad key) restores the old key, and the line is the new key's outcome line. Wording only; the state is right.
- **C5:** the key stays on the clipboard after paste. Suggest clearing `UIPasteboard.general` when it holds the pasted key, or a Tess line "You can clear it from your clipboard."
- **C6:** PasteRecipe's guard is case-sensitive (`contains("<key prefix>")`); BottomChrome's is not. Use the same helper.

## Phone smoke for the install
1. Review > Claude: paste the key. Expect "Checking it with Claude." then works, `...last4` only, no Save Password sheet.
2. Paste the key into Ask: cleared, refusal line, no ghost.
3. REMOVE, UNDO within 10 s: "Claude key is back", Test still works.
