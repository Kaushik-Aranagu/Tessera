# 84. One error and offline sheet (E4)

**Kaushik's principle, in one line:** when something doesn't go through, the phone says one plain thing in one place, once, and never makes it sound like his fault or an emergency.

Board `mockups/errors-84.png` (matrix of areas by error kind, then eight frames, Porcelain and Obsidian), recording `recordings/errors-84.mp4` (19 s: a set that doesn't save and its retry, "Claude is busy. Kept it for later." with "1 waiting for Tess", Tess with no key and the tap into Settings), study `studies/errors-84.html` (`?play` records). Builds on `claude-settings.md`, `settings-80.md`, `one-ask.md`, `list-remove.md` (the UNDO slot), `widget-states.md`, `lockscreen.md`, `copy-pass.md`. Product's copy used as given: "Didn't save. Try again." and "Claude is busy. Kept it for later."

## Where it lives: the UNDO slot
- **One app-wide slot, the UNDO slot at Tess's band (736 to 820).** Her band holds only her line, so a failure is not hers. A notice is an **ink** sentence, Body 19, right-aligned beside the soul exactly where her line sits, so the band never changes height. It replaces her line for its window and her line returns after (as UNDO does). A new notice replaces the old one; there is never a stack.
- **Cobalt stays Tess's voice.** Only what she herself says is cobalt: "No Claude key yet.", "Claude is off.", "Claude paused until Nov 1.", "That key didn't work. Paste it again?", "That stays on this phone." Failures and kept-for-later receipts are ink and carry no coloured word. UNDO keeps `liveInk`; nothing else here does. Never red or amber, not even in Obsidian.
- **Windows:** "Kept it for later." lines 4 s (a new receipt). "Didn't save. Try again." 10 s (it asks something of him). Both 10 s under VoiceOver. An open ask (one-ask.md) is not evicted: the notice holds the slot and the ask returns, nothing dries.
- **Standing trouble is not a notice.** Backups "didn't save" and a key that is "not checked" stay inline on their page (Settings), as built. The slot is for moments.
- Keys up (Notes, Groceries): the slot rides where Tess's line sits with the keys up. AX3: up to three lines, bottom-anchored at 820, nothing truncates.

## The words
- **Didn't save:** "Didn't save. Try again." everywhere. One exception: the live workout names the set, "Set 4 didn't save. Try again.", because the dial moves on. A private note is "Private note didn't save. Try again.", the name first and never its words.
- **Kept for later** names the thing first when it has a short, public name: "Recipe link, kept for later." (never the URL), "Call mom, kept for later." Otherwise "Kept it for later." Claude trouble keeps its cause first: "Claude is busy. Kept it for later." and "Claude didn't answer in time. Kept it for later." Where a job has a fallback it stays "Here's your usual plan."
- **Offline is not a state.** No banner, icon or "offline" word. On-device work shows nothing. Offline speaks only when something needed the connection, as a kept receipt ("Kept it for later."), or "Needs a connection." when nothing can be kept. The older "Kept it. I'll read it once you're online." is replaced by the above; the drain receipt "Read 1 waiting. 1 to check." and the "1 waiting for Tess" context line stand.
- No "…", no apology, no "Sorry", "Oops", "Unfortunately", "Please", "Error", "Failed", "!", no guilt, no retry counter, no "at" before a time.

## One haptic
- **One `.warning`, once per moment,** when something he just did with his finger or voice did not save ("Didn't save."). Nothing else here has one: kept-for-later receipts (nothing was lost), Tess's key and off lines, background work (backups, inbox drain, widget refresh), a repeated failure on retry (same moment; no second tick). A retry that works plays the area's own success haptic, not both.
- A failure plays no success haptic or reward animation and shows no success line; the screen returns to what is stored (a check springs back, the set stays in the number row, typed words stay in the field). Tess's line and the data never disagree.
- Quiet hours (23:00 to 07:00) keep it, because it follows his own finger. No sound.

## Retry: tap the line
- Tap anywhere on the notice (the whole band, 44 pt minimum) to run the same write again. No button word: the sentence is the instruction. The line dims to 60% and a 0.5 pt ink line draws under it over 150 ms. Success: the line crossfades into the normal receipt ("Set 4 logged." with UNDO) and the area's own landing. Fail again: the line returns to full ink, no second haptic.
- "Kept it for later." is not tappable (it retries itself). Tess's key and off lines: a tap opens CLAUDE in Settings, with the origin's back word.
- Reduce Motion: no rise or ink line; the line, the dim and the receipt are 150 ms crossfades. The haptic stays.

## What never shows
No raw errors (error text, codes, 401, 429, 529), no model name, no request id, no key or fragment of one (the key line in Settings keeps "...a1B2" as built), no URL, no recipe text, no money or body figure ("Didn't save." never says $12 or 82.5 kg), no secret-word task title, and a private note stays "Private note". A money or body question is still "That stays on this phone."

## Key missing and Claude off (from claude-settings.md, settings-80.md)
- **No key:** the phone answers what it can with no line. A Claude-only ask gets Tess, cobalt: "No Claude key yet." (tap opens CLAUDE with its writing line). A job with a fallback just uses it: "Here's your usual plan." A background job doesn't run and says nothing.
- **"Tess asks Claude: no":** "Claude is off." (tap opens CLAUDE). Nothing is queued or sent; Settings' inline "Tess stays on this phone." stands. Not "Kept it for later": it would never drain.
- **Cap and bad key** keep Settings' lines ("Claude paused until Nov 1.", "That key didn't work. Paste it again?"), Tess's, cobalt.

## Widgets and Lock Screen
Home Screen and Lock Screen widgets never show an error: they keep the last good timeline (widget-states.md) and never call Claude. The rest Live Activity and a Siri snippet can fail a set log: the line under the rest reads "Set 4 didn't save. Try again." in ink in the place UNDO takes after a good log; tap retries. Island: nothing.

## Access
- **VoiceOver:** the slot is one live region. A failure is announced once at high priority as its words; a kept receipt at default priority. The failure is a button, label the line, hint "Opens to try again"; custom action "Try again". Focus doesn't move. Window 10 s. The failed row reads its stored state ("Set 4, not logged"). Tess's cobalt lines are buttons with the hint "Opens Claude settings".
- **Dynamic Type:** grows up from 820, three lines, no truncation. **Contrast:** ink on both looks is 245,242,236 on #121014 or 18,16,22 on #FBFAF7; the only colour is Tess's.

## Rows for builders' acceptance
1. Every failure and kept receipt goes through one slot; none draws elsewhere; a new one replaces the old.
2. Ink, Body 19, soul place; cobalt only for Tess's own lines.
3. One `.warning` per failed finger action; none for kept receipts, background work or a second failure.
4. A failing store (injected throw) makes finish, grocery check, set log, pantry word, routine edit, note and habit tick each show the line with no reward animation, haptic or success line.
5. Tap retries; success shows the area's receipt.
6. No raw error, key, URL, money, body or private text on any notice (strings test).
7. Offline: on-device work shows nothing; Claude-needing work keeps and says so.
8. Reduce Motion crossfades; VoiceOver as above.

## Unresolved
1. Whether Tess's key and off lines opening Settings from a slot line fits "no controls on a line" (proposed yes, a tap on her line).
2. "Set 4 didn't save." naming the set (the one named exception).
3. "Claude is off." and "No Claude key yet." as proposed words for Product to rule.
4. Core: do widget intents report a failed write to the Live Activity?
