# Review #234: Home on theme tokens + Claude field fixes (c76d735, head 1683a26)

Builder B. 11 files, +109/-51, plus home-themes.mp4. Static review (no Swift toolchain here). Stale-branch check: the merge's diff against its base f4ab565 touches only these 11 files, so nothing from #225/#231/#232 was reverted.

**Verdict: PASS.** C1, C2, C3, C4, C5, C6 and H1 all closed. One question for Product (M1), two lows. Kaushik's new asks (every area on Home's base, thinner underline stroke) aren't treated as bugs here.

## Claude field
- **C1 closed:** `.textContentType(.password)` removed. Phone smoke still worth one look: no "Save Password?" sheet after pasting.
- **C2 closed:** `scenePhase == .background` with a removal pending cancels the timer and calls `finishRemoval()`. Swiping the app away passes through background first, so REMOVE always ends in a deleted key.
- **C3/C4 closed:** a failed Replace checks `keys.save(previous)`. Success: "That key didn't pass. Your old key still works." Failure: says so and clears `last4`.
- **C5 closed:** the clipboard's `changeCount` is recorded at paste; after a passing check, if it hasn't changed, `UIPasteboard.general.items = []`. Reading `changeCount` and writing the clipboard don't trigger the paste banner. It's skipped for a bad key and on a failed Replace (the clipboard keeps the key he may want to retry), which is reasonable.
- **C6 / N2 closed:** BottomChrome and PasteRecipe call Core's `looksLikeClaudeKey` (case-insensitive). All three app inputs plus the router, capture engine and miss log now share one guard.
- **H1 closed:** `badKey` → "didn't work", tested. `.notSaved` keeps the field open.

### ClaudeSection.swift:270, case-sensitive `hasPrefix("the Claude key prefix")`: doesn't matter
- This is the *accept* check, not the leak guard. Anthropic keys are case-sensitive and always start lowercase `the Claude key prefix`, so an uppercased "SK-ANT-…" isn't a working key; refusing it with "That doesn't look like a Claude key" is the right answer.
- The field sets autocapitalization `.never`, so the keyboard can't capitalise a pasted or typed key.
- Core's `test(pasted:)` uses the same case-sensitive prefix, so the two agree.
- Leak safety doesn't depend on it: anything with "the Claude key prefix" in any case is still blocked everywhere else.

## Home on tokens
- **HomeStroke:** Plein keeps its original five stops; dark looks use `daySpectrum`; Porcelain and Celadon use #509BD5 and #C58700 for sky and amber (stroke only, as approved in theme-contrast-fixes.md), with health, context and live from the look. Reads `paintLook`, so a pinned look and the workout cover resolve correctly.
- **Tokens:** wet tip and DrainBar use `now`, kitchen dabs use `classColor(.kitchen)`, ledger step text uses `inkSecondary`, the ledger rule is one `hairline` (B11), the held queue row's shadow only on light looks (B14). No hex literals left in Home apart from the stroke stops.
- **4 AM tip:** `fraction(of:)` adds 24 to hours before 04:00, so at 01:50 the tip sits at the evening end of the day that's ending, not at the morning end. Matches TesseraDay.
- **Monday-first full Review:** `weekday = (weekday + 5) % 7` gives Mon 0 … Sun 6. The first key is today's key minus that, and the window starts at 04:00 that Monday. At 02:00 Monday (still Sunday's day) it correctly shows the previous week. Days ahead aren't in the interval.
- **Design's #219 notes:** workout day words in `inkSecondary` (not training colour); rest streaks now run lengthwise (six horizontal bristle streaks, softened ends).
- **UNDO fix:** `canUndo` follows the Home line when one is showing (only if it has its own undo), else the last capture. So "Carried 2 tasks" no longer shows an UNDO that would revert an unrelated capture.

## For Product
- **M1:** "Misses go to Claude: yes" is stored in `tess.missesGoToClaude` (default **yes**), but nothing reads it yet. Today it changes nothing. When the miss-to-Claude path lands, the default sends his unparsed captures to Claude without him having turned it on. Product should confirm "yes" is the intended default (it's personal text leaving the phone), and the feature must check this flag.

## Lows
- **L2:** `HomeStroke` picks Plein by `look.name == Look.plein.name`; a field check (`.plein`) would survive a rename. Cosmetic.
- **L3:** the week's "Four sessions this week" headline now counts from Monday, so on Monday morning it reads "A quiet week so far" even after a strong previous week. That's the intended plan-week meaning (Research Q2); just noting it for the install script step 14.
