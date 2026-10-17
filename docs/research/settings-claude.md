# Settings: Claude, every state and its line

> **Update Oct 16, 12:40 pm PT:** the monthly Claude cap is now **$50** (Kaushik's yes at 9:27 am). Read every "$10" cap below as $50, with amber from $40 ("PAUSES AT $50"). Model prices in this file are unchanged. See `cap-math-check.md`.

For: Design (Settings: Claude sheet), Builder B (the screen), Core (key store, `ClaudeKeyCheck`, ledger). Research lab, board item 59, 2026-10-16.
Read with `claude-key-test.md` (K1 to K10), `claude-first-uses.md`, `tess-voice.md` (M1 to M58), `tess-model-layer.md` §3, §4, §7, and decisions 5:14, 5:49, 6:22 and 6:37 PM PT.
Design's sheet is `docs/design/claude-settings.md` on branch `claude/project-thread-b3tu3f` (f1a12e1); there is no copy in the shared `design/` folder, only `claude-settings.mp4`, so this file read the branch copy.
Master (`0a27447`) has no Settings screen, no Keychain code, no `TessCall`, no ledger and no network client. Nothing in this file conflicts with code yet.

## Rules used on every line

- **Voice.** One line under 12 words, first person, no "!", no em-dashes, no banned words. Name the thing, then what happened (5:14 PM PT).
- **Action words, no buttons.** Secondary actions are label words (Label 16/700 uppercase, `LabelActionStyle` in `DesignSystem/InkActions.swift`): TEST, REPLACE, REMOVE, UNDO, CONSOLE. Value words (Design's sentence Settings) are the tappable bold words in a sentence. UNDO is vermilion everywhere (audit row 10).
- **UNDO.** It reverts exactly the record its line names. Removing or replacing the key is a destructive write, so UNDO stays 10 s, and the old Keychain item is only deleted once UNDO expires (Design). Undoing a removal says "is back" (6:37 PM PT exception): "Claude key is back."
- **Time and dates.** 6:37 PM PT: master's format, "6:12 pm", "Saturday 3 pm". Dates come from master's locale formatter (`.dateTime.month(.abbreviated).day()`), which gives "Nov 1" on his phone.
- **Money.** Month total and cap in dollars: total with two decimals, rounded **up** to the cent so any spend shows ("$0.01" after one $0.0006 call, as in `claude-first-uses.md`); a round cap with none ("$10"). One call on a receipt is in cents, one decimal ("1.2¢"), "under 0.1¢" below that, "free" at 0 (the key Test). The ledger itself counts nano-dollars (K §4).
- **Month.** 00:00 on the 1st, Los Angeles time (phone calendar), not the 4 AM day and not Anthropic's UTC.

## What the screen always shows once a key is saved

| Line | Example | Action |
|---|---|---|
| Switch sentence | Tess can ask **Claude**. | Value word cycles **Claude** / **only this phone** (off keeps the key) |
| Month sentence | This month **$1.20** of **$10**. | None. Under it the month line: hairline plus a brushstroke to the share spent |
| Misses sentence | Misses go to Claude: **yes**. | Value word yes / no (use 1) |
| Key line | Key ends in ...a1B2 · works | TEST · REPLACE · REMOVE |
| Receipts | Receipts | Opens the list one layer down: "6:12 pm · Plan my day · Sonnet · 1.2¢", newest first |

The key is never drawn again after the drain, only its last four characters. VoiceOver: "Claude key, ends in a1B2"; month line "1 dollar 20 of 10 dollars this month".

## States

| # | State | Trigger | Tess's line (exact) | Key line / screen | Action words |
|---|---|---|---|---|---|
| S1 | No key | First run, nothing in the Keychain | Tess thinks on this phone only. | No month, key or receipts lines | **Add a Claude key** (cobalt, 21) |
| S2 | Pasting | Add tapped; 0.5pt cobalt writing line opens in place | (none; VoiceOver label "Claude key") | `SecureField`, no autocorrect, no `textContentType`, never in `@AppStorage` | Long-press paste. Tapping away with the line empty closes it |
| S3 | Pasted with whitespace | Spaces, tabs or line breaks anywhere in the text | (none; strip all whitespace, keys have none, then go on) | As S4 | |
| S4 | Testing | Trimmed text starts with the Claude key prefix. Key saved to Keychain first, then one count_tokens call (10 s) | Checking it with Claude. | Key drains to its last four; cloud wisps on the soul, soul in thinking mode | None until it answers |
| S5 | Not a key (K9) | Trimmed text doesn't start with the Claude key prefix; nothing sent, nothing saved | That doesn't look like a Claude key. Paste it again? | Writing line stays open, emptied | Paste again |
| S6 | Works (K1) | 200 | Key saved. Ends in ...a1B2. | `...a1B2 · works`; switch turns to **Claude**; month, misses and receipts lines unfold (40 ms stagger) | TEST · REPLACE · REMOVE |
| S7 | Bad key (K2) | 401 at Test | That key didn't work. Paste it again? | Keychain item deleted at once (no UNDO: not his write, and a 401 key can't come back); back to S2 | Paste again |
| S8 | Not allowed (K3) | 403 | That key can't use Claude yet. Check it in the Console? | `...a1B2 · not allowed`; switch stays **only this phone** | CONSOLE (opens the Claude Console in Safari) · TEST · REMOVE |
| S9 | No network at Test (K4) | `URLError` offline cases | No connection. I kept the key. Test it again later. (M26; matches master 08bcf6b; retry promise returns when something retries (item 112); master still has a semicolon, Core drops it) | `...a1B2 · not checked`; switch stays off; nothing checks again by itself yet, TEST re-checks | TEST · REMOVE |
| S10 | Timed out at Test (K5) | 10 s or 504 | Claude didn't answer in time. (M27, same words as M18; matches master 08bcf6b; retry promise returns when something retries (item 112)) | `...a1B2 · not checked` | TEST · REMOVE |
| S11 | Busy at Test (K7) | 429 with `retry-after`, 529, 500 | Claude is busy right now. I kept the key. (M29; matches master 08bcf6b; retry promise returns when something retries (item 112)) | `...a1B2 · not checked` | TEST · REMOVE |
| S12 | Account paused, Anthropic's (K8) | 429 `enforced_spend_limit_reached`, 400 "You have reached your specified", 402 | Key saved. Your Anthropic account is paused for now. | `...a1B2 · account paused`; switch stays as is; the next call tries again | CONSOLE · TEST · REMOVE |
| S13 | Anything else (K10) | Other status or an undecodable body | I couldn't check that key. Try again? | `...a1B2 · not checked` | TEST · REMOVE |
| S14 | Cap already reached at Test (K6) | `canSpend` false; count_tokens is free so it still runs | Key saved. Claude paused until Nov 1. | `...a1B2 · works`, then S17 | As S17 |
| S15 | On, under 80% | Month total under $8.00 | (none) | "This month **$1.20** of **$10**." Cobalt stroke. Only the Test so far: "$0.00" | TEST · REPLACE · REMOVE |
| S16 | Amber at 80% | Month total $8.00 or more | (none; no notification, no line by the soul) | Amount and stroke amber; label under the month line: PAUSES AT $10 | Same |
| S17 | Paused at the cap | First use blocked by `canSpend` this month | Claude paused until Nov 1. On-device until then. (M10, once a month, beside the soul at the blocked use) | Month sentence becomes "Paused until **Nov 1**."; stroke full, amber, never red | Same; switch still works |
| S18 | Month rollover | First open on or after the 1st | Claude back on for November. (M11, only if last month hit the cap; silent otherwise) | Total back to $0.00, cobalt; amber and pause clear | Same |
| S19 | Switched off | **Claude** cycled to **only this phone** | Claude off. Everything stays on this phone. (M6) | Key kept; month line stays | Value word back on: "Claude on. The cloud mark shows what leaves." (M5) |
| S20 | Key removed | REMOVE tapped | Claude key removed. Everything stays on this phone. | Claude stops at once; S1 shows; Keychain item deleted when UNDO expires (10 s) | UNDO: "Claude key is back." Restores the key and the switch as they were |
| S21 | Key replaced | REPLACE, new key pasted and passes Test | Claude key replaced. Ends in ...c3D4. | New key used at once; old item deleted when UNDO expires (10 s). A new key that fails shows S5 to S13 and the old one stays | UNDO: "Claude key is back. Ends in ...a1B2." |
| S22 | Key revoked later | 401 on any use call | That key didn't work. Paste it again? (M2, once, at the use) | Keychain item deleted, switch off, Settings shows S1 with the same line on top | Add a Claude key |
| S23 | Key missing | Switch was on but the Keychain item is gone (reinstall) | No key yet. Paste one to use Claude. (M4) | S1 with this line; ledger rows stay | Add a Claude key |
| S24 | Rate limited or overloaded in use | 429 with `retry-after` or 529 or 500, after one retry | Per use, at the use (M22): "Claude is busy. Kept it for later." | Settings unchanged; the key stays `works` | |
| S25 | Misses paused for today | 3 of 10 Claude ghost rows in a row taken back (first-uses pause rule) | Misses on this phone today. 3 of 10 taken back. | Misses sentence reads "Misses go to Claude: **not today**."; back at the 4 AM day | Value word **yes** turns it back on |
| S26 | Key pasted into Ask | Ask text holds the Claude key prefix | That looks like a Claude key. Paste it in Settings. (M24) | Nothing written anywhere | |

26 states. S3, S8, S10 to S14 and S20 to S26 are the ones missing from the board list.

## What Tess does elsewhere, per state

| States | Capture (use 1) | Plan my day (use 2) | Questions (use 3) | Marks |
|---|---|---|---|---|
| S1, S2, S5, S7 to S11, S13, S19, S20, S22, S23 | Grammar, then on-device, then "Didn't catch that. Try “bench 80 x 8”." Nothing queued | Rules plan with its plain lines, no fallback line | Grammar seeds, then on-device | No cloud mark, no VIA CLAUDE |
| S6, S15, S16, S21 | Misses go to Haiku after on-device; ghost row; receipt "Call mom, Thursday 7:30 pm · via Claude" | Gated: after 10 use-1 calls checked against the Console, 3 or fewer taken back, 20 scenarios pass (6:22 PM PT). Until then as Claude off | Gated until `TessUse.question` with only `answerQuery` | Wisps while out; VIA CLAUDE on the line and the ghost row |
| S12 | Line "Your Anthropic account is paused for now." then the miss line | Rules plan, "Here's your usual plan." | On-device | None |
| S14, S17 | M10 once, then grammar and on-device; nothing queued | Rules plan, "Here's your usual plan." every time | On-device | None |
| S24 | "Claude is busy. Kept it for later." Text to `TessInbox`, "1 waiting for Tess" | "Claude is busy. Here's your usual plan." | "Claude is busy. Ask again?" | Wisps stop |
| Offline in use (any on state) | "Kept it. I'll read it once you're online." (M12), badge M13, later M14 | "Here's your usual plan." | On-device, else "Needs a connection." | None |
| S25 | Grammar and on-device only, today | Unchanged | Unchanged | Unchanged |

Under any receipt that went via Claude: "Tess: $1.20 this month." (M7), hidden when no Claude call this month. Amber and the cap never send a notification (model layer §4, `notifications.md` sends no Tess notifications).

## Contradictions, with a proposed default

| # | What disagrees | Sources | Default |
|---|---|---|---|
| C1 | Reset date "Nov 1" vs "1 Nov" | M10, M28, K6, first-uses say "Nov 1"; Design sheet, model layer §4, boards say "1 Nov" | "Nov 1", from master's locale date formatter, per 6:37 PM PT (follow master's format) |
| C2 | Remove line "Key removed. Everything stays on this phone." vs "Key forgotten." | M3 vs Design | "Claude key removed. Everything stays on this phone.", UNDO "Claude key is back." (5:14 and 6:37 PM PT) |
| C3 | Remove gesture: hold the key line 0.7 s vs a REMOVE word | Design vs K §5 rule 6, model layer §3 ("Replace or Remove") | REMOVE label word on tap; the 10 s UNDO makes a hold unnecessary and the word is findable |
| C4 | 403 at Test: switch off and M2, vs keep key "not allowed" | M2 trigger "401 or 403" vs K3, M25 | K3: 403 keeps the key; M2 is 401 only. Fix M2's trigger text |
| C5 | Is there a TEST word? | Decision 5:49 and K §2 ("something he taps") vs Design (no Test, the paste just saves) | Test runs by itself on paste; TEST stays on the key line to re-check |
| C6 | Cap is a drum $5 / $10 / $20 | Design vs decisions 18:50 and 5:49 ($10 hard stop) | Plain "$10", not a value word. Raising it is Kaushik's call |
| C7 | "Sees sleep and energy: no" value word | Design vs decision 5:48 PM PT (Health never read) and model layer defaults | Drop it. Receipts already say "Not sent: health" |
| C8 | Amber label "PAUSES AT $10 UNTIL 1 NOV" | Design vs M9 ("Pauses at $10.") | "PAUSES AT $10". Nothing is paused yet, so no date |
| C9 | Usage wording "Tess: $1.20 of $10 this month." vs "This month $1.20 of $10." | M8 vs Design's sentence Settings | Design's sentence on Settings; M7's "Tess: ... this month." stays on receipts. Update M8 |
| C10 | Money per call "1.2¢" vs dollars with two decimals | Design receipts vs `tess-voice.md` {spent} rule | Totals in dollars, rounded up; single calls in cents (a $0.0006 call would read "$0.00") |
| C11 | Last four as "...a1B2" vs "x7Qa" | M1, K1 and the leak test's exact string vs Design | "Ends in ...a1B2."; the test asserts it |
| C12 | Off switch "Use Claude" toggle vs the **Claude** / **only this phone** value word | Model layer §6, K1 vs Design | Design's value word; M5 and M6 lines unchanged |
| C13 | Auto-paste from the clipboard on open, yet "no paste banner" | Design (contradicts itself: reading the pasteboard shows the iOS banner; `UIPasteControl` is a system-drawn control) | Long-press paste only. UNVERIFIED whether `UIPasteControl` can be drawn as an ink word |
| C14 | Amber as hex `#D08A36` / `#B8742A` | Design vs 6:40 PM PT Themes (tokens, never hard-coded) | An amber token per theme; "never red" holds in every theme |
| C15 | Timeout said two ways | M27 "Claude didn't answer in time." vs M18 "Claude timed out." | Keep both for now (Test vs use); Design picks one, as `tess-voice.md` already notes |
| C16 | Keychain WhenUnlocked vs AfterFirstUnlock | Model layer §3 was updated; board item and K agree | No conflict left; listed so Core doesn't reopen it |
| C17 | When the Test works, does M5 also show? | K1 ("Use Claude switches on") vs first-uses ("switches on with M5") | One line only: M1. M5 shows when he turns it on by hand |

## Open, Kaushik or Design

1. Should the misses pause (S25) be on by default? Default: yes, as first-uses proposes; the line above is new copy for Design.
2. Does REPLACE need the old key kept until the new one passes? Default: yes, so a bad paste never leaves him with no key.
3. Testing line "Checking it with Claude." is new copy (no line exists for the wait). Design to confirm.
