# Settings: Claude page data and pointer strings (sheet 93, page 1)

For: Product, then Builder B (the page), Core (the settings field and the strings). From: AI architecture. Docs only: no Claude calls, no key use, no key content anywhere. Read against master efb867b: `Features/Settings/ClaudeSection.swift`, `ClaudeTessModel.swift`, `ClaudeKeyGuard.swift`, `docs/research/fixtures/sheets-93-94-95.md` (SP01 to SP10, Q1), `docs/research/settings-claude.md`. **[code]** = read in Swift on master; **[docs]** = from a docs page.

## 1. Where it sits

Sheet 93 page 1 is "Tess": Tess asks Claude, Quiet hours, Page turn (3 rows; SP02 allows at most 6). The sheet has no room for the rest of Claude (fixtures Q1). Recommendation: **"Tess asks Claude" opens in place** (the sheet already lets row 1 expand) and shows three lines under it: Key, This month, Receipts. That is 3 + 3 = 6 rows, inside the limit, and no fifth page. Everything below is the data behind those four lines.

## 2. Data per line

| Line | Shows | Source | Rule |
|---|---|---|---|
| Tess asks Claude | "On" or "Off", under it one line | `TesseraSettings.missesGoToClaude` (Core), plus `hasKey` [code `ClaudeSection.swift:66`] | **Effective value = a key is saved AND the stored value (nil counts as on).** No key: "Off", whatever is stored. Tap with no key opens the key entry in place, no error line (SP09). Tap with a key flips the stored value. Keeping the stored value means removing a key and adding one again restores the choice. |
| Key | "Yes" or "No" only | Keychain presence (`TessKeychain.read() != nil`, not the value) | Yes or no, nothing else on this line: no last four, no prefix, no length (Product 9:53; master already shows none, `ClaudeSection.swift:66`). The Test result words (works, not checked, not allowed, account paused) and TEST, REPLACE, REMOVE sit one layer down, opened by tapping the Key line. REMOVE keeps its 10 s UNDO "Claude key is back." |
| This month | "$1.20 of $50." | `TessUsageLedger.monthTotal(now:)` in nano-dollars, `capDollars` = 50 [code `ClaudeKeyWords.dollars`] | Total rounded **up** to the cent so any spend shows; the cap is a whole dollar. Month = the 1st 00:00 house time, not the 4 AM day. A brushstroke to the share spent. No key: line hidden. |
| This month, at 80% | amber from $40 | share >= 0.8 [code `:213`] | Amber is a theme token, never red. Label under the line, see section 4. |
| This month, at the cap | "Paused until Nov 1." | `monthTotal >= capNano` [code `:209`] | Date from the locale formatter ("Nov 1"). Stroke full, amber. The switch still works; Claude is simply refused until the 1st. |
| Receipts | the month amount is the tap target; if there are old rows and no key, a "Receipts" word | `TessUsageLedger.calls()` [code `:151-155`] | One layer down: newest first, "Thu Oct 16, 12 pm · Plan my day · Sonnet · 1.2¢". Old receipts outlive the key. Cents with one decimal, "under 0.1¢", "free" at zero. |

**What the receipt rows say (job words, `ClaudeReceipts`):** capture "A capture", question "A question", paste "A paste", recipeLink "Recipe link", plan "Plan my day", lines "Home", keyCheck "Key check". Not built, so no row yet: week story, living colour, Ask about this, Facts fill, grocery connect. Proposed words for them, so the screen does not fall back to "Tess" (`default` branch, `:529`): "Week story", "Living colour", "Ask about this", "Facts", "Grocery link".

**A walled phrase's row** names the job and the cost and nothing else: "A capture", never the phrase (gap lane part 2, section 3; masked receipt). The unwalled capture row may show the phrase as the pack showed it.

**What was sent** (`what-was-sent-log.md` section 4) is the layer under a receipt row, not a fifth line on the page: tap a row to read the payload. One list, not two.

## 3. Three checks the page must pass (none needs a key or a call)

- **K1. No key content.** No state of this page, its VoiceOver labels or its fixtures holds any part of the key: no last four, no prefix, no length. Fixtures build any fake key from pieces at run time.
- **K2. The line is true.** Design's line under "Tess asks Claude" is "Sends only what you ask her." That is not what the switch does: the same switch gates capture misses, Plan my day, the Home lines and the recipe reader, and a capture miss goes without a per-phrase ask. Proposed replacement, same length, true: **"Sends only what Receipts lists."** (Receipts and the What was sent layer do list every request.) Product to pick.
- **K3. One switch, all jobs.** The switch reads the same value `AppModel.asksClaude` gates, so Off stops capture, plan, Home lines, recipe reads and every later job. The key check on a fresh paste is the only call that should run with the switch off (it tests a key just pasted); I did not trace that path, so Builder B confirms.

## 4. The 80% label

At $40 only Home lines, the week story and living colour step aside. Capture, Plan my day, recipe reads and questions run to $50. Master's amber label "PAUSES AT $50" [code `:213`] stays true for the whole app and is the only place the $40 shows. Recommendation: keep it. No separate "some lines rest" word.

## 5. Notice and pointer strings: now and later

Claude's settings live on Review today (`ReviewView.swift`, `ClaudeSection`) and move to Settings with sheet 93. Strings that name the place need two forms. Rule from `settings-day-one.md` S3: **one place name at a time, flipped in the same build that ships the page.**

| String | Now (Claude on Review) | Later (page 1) | Where in code |
|---|---|---|---|
| Key refused anywhere | "That looks like a Claude key. It goes in Review, under Claude." | "That looks like a Claude key. It goes in Settings, under Claude." | `claudeKeyLine`, `ClaudeKeyGuard.swift:4`; used at `BottomChrome.swift:468`, `WorkoutModeView.swift:158` |
| First send notice, walled phrase | "Sent that to Claude. Turn this off on Review: Claude." | "Sent that to Claude. Turn this off in Settings: Claude." | `ClaudeTessModel.swift:151` |
| First send notice, other phrase | "Sent “{phrase}” to Claude. Turn this off on Review: Claude." | "Sent “{phrase}” to Claude. Turn this off in Settings: Claude." | `:152` |
| Key rejected in use | "Claude didn't take the key. Check it on Review: Claude." | "Claude didn't take the key. Check it in Settings: Claude." | `:241` |
| Kept recipe link, key bad | "Recipe link, kept. Check the Claude key on Review." | "Recipe link, kept. Check the Claude key in Settings." | `RecipeLinkReader.swift:28` |
| Back word on receipts | "‹ Review" | "‹ Settings" | `ClaudeSection.swift:458`, `:465` |

**What master says today (disagrees with "now"):** the three Core strings at `ClaudeTessModel.swift:151`, `:152` and `:241` and the kept-link line at `RecipeLinkReader.swift:28` already say "Settings", a place that has no Claude page. The back word at `ClaudeSection.swift:458` already says "‹ Settings" while its host is Review. The key line and the Ask bar already say Review. So master mixes both forms today (settings-day-one S3).

**How to keep them from drifting:** Core holds one value, `ClaudeWhere` ("Review" now, "Settings" later), and builds all six strings from it. The page build flips the one value. Test `everyClaudePointerNamesOneHost`: build each string, assert none names the other host, and assert the host is the one the app really shows. Docs that quote the strings (`architecture.md` never-leaves bullet, gap lane rows) change when the value flips, by the docs refresh that rides with the page.

## 6. Findings, in priority order

1. The four strings in section 5 that say "Settings" today point at nothing until the page ships. Low harm (the section is findable on Review), but a first-send notice is the line a new user reads; fix with `ClaudeWhere`.
2. "Sends only what you ask her." overclaims (K2).
3. `docs/research/settings-claude.md` still shows "Ends in ...a1B2" (rows S6, S21, C11) against the 9:53 yes-or-no ruling and master. Research to mark those rows stale.
4. The `$10` wording in the same page and in `ClaudeKey.swift` comments is stale ($50). Core for the Swift comments.

## 7. Questions for Kaushik

None needed. Everything above is a recommendation Product can confirm.
