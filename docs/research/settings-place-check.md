# Settings place: every line and state checked

For: Builder B (the Settings page), Design (copy and placement), Core (fields and key-check lines). Research lab, board item 112, 2026-10-16.
Sheet: Design's `docs/design/settings-place.md` at **231b15e** (branch `claude/project-thread-b3tu3f`; the shared `design/settings-place.md` is byte-identical), with its board `studies/settings-place.html`.
Checked against: `tess-voice.md` (M1 to M58), `settings-claude.md` (S1 to S26), the look sentence (`research/theme-names.md` 35-41, `design/themes.md` 96-104, decision 7:22 PM PT, `DesignSystem/LookSentence.swift`), and the Backups lines from #246 (merge c2fd7ad, commit cb68c1f). Code citations are master at **08bcf6b**.
Calls applied: bad key says "That key didn't work. Paste it again?" (M2); timeout says "Claude didn't answer in time." (M18, item 98); at the cap the plan says "Claude paused until {reset}. Here's your usual plan." (8:38 PM PT); the key text is never shown or stored outside the Keychain; misses go to Claude by default (8:28 PM PT); plain words, no coloured bullet dots (8:07 PM PT), ink action words, no button shapes; the undo rule (name the thing, then what happened; destructive writes keep UNDO 10 s; "is back" for undoing a removal, 6:37 PM PT).

Verdicts: **match**, **differs** (sheet or code disagrees with its source), **missing source** (the line has no source to check against), **sheet missing a state** (a line or state the source or master has that the sheet doesn't place).

## Line by line

### The way in and the page

| # | Sheet text or element | Source it should match | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| P1 | **SETTINGS**, one quiet word at Review's foot; "LOOK and Claude leave Review" | Board item 16; master Review foot holds LookSentence, ClaudeSection and a **Backups** word (`Features/Review/ReviewView.swift:220-236`) | sheet missing a state | Say the **Backups** word leaves Review too (the board mockup already shows only SETTINGS). Review keeps one word | Design, then Builder B |
| P2 | Tap: ink line draws, Review lifts, Settings grows from the word; Reduce Motion crossfade | `DESIGN_MOTION.md`, MotionPolicy | match | No copy. Build through `withTesseraAnimation` | Builder B |
| P3 | **‹ REVIEW** back word | `design/back-word.md` 10-11 (Label 16/700 uppercase, U+2039) | match | None | Builder B |
| P4 | "Settings", Title 44/500 | Board item 16 | match | Receipts, one layer down, then carries **‹ SETTINGS** (see C4) | Builder B |
| P5 | Bottom 72pt kept clear for Tess's line | Sheet's own value-word rule | differs | Master shows Claude lines inline under the section (`Features/Settings/ClaudeSection.swift:86-97`) and Backups lines at the page bottom (`Features/Backup/BackupView.swift:130-135`). Say where every Settings Tess line goes: one place, the foot, for value words, key outcomes and Backups alike | Design |

### LOOK

| # | Sheet text | Source | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| L1 | "**Porcelain** by day, **Obsidian** by night." | theme-names.md 35; themes.md 97; decision 7:22 PM PT; `DesignSystem/LookSentence.swift:33-41` | match | None | Builder B (moves LookSentence as is) |
| L2 | Pinned: "**Lacquer**, day and night." | theme-names.md 36 and themes.md 99 ("**Obsidian** always."); `LookSentence.swift:27` (" always.") | differs | "**Lacquer** always." | Design |
| L3 | (no hint line) | theme-names.md 35-36; `LookSentence.swift:29`, `:64`: "Hold a name to keep it day and night." / "Hold it again to follow light and dark mode." | sheet missing a state | Keep both hint lines under the sentence, inkSecondary, as master does | Design |
| L4 | Label **LOOK** | `LookSentence.swift:15` ("Look", Label role, uppercase) | match | None | Builder B |
| L5 | "Looks say nothing (the page itself changes look)." | `LookSentence.swift:5-6` (no Tess line, no UNDO) | match | None | None |
| L6 | (no flood) | Board item 16 asks for "the paint flood on a look change"; themes.md 103 (`PaintFlood` from Tess's soul, 700ms, Reduce Motion 250ms crossfade); `LookSentence.swift:117` ("the soul's flood comes with Settings") | sheet missing a state | Draw the flood on the Settings page: where the soul sits (the foot line?) and that it floods from there | Design (Builder A owns `PaintFlood`) |

### CLAUDE

| # | Sheet text or state | Source | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| C1 | "Tess can ask **Claude**." (board), cycling to **only this phone** (by reference) | settings-claude switch sentence, S19; M5, M6 | match (sheet); master not built | `ClaudeSection.swift:150` draws "Claude" as plain bold text, not a value word. Build the cycle with M6 on off and M5 on back on | Builder B |
| C2 | "This month **$1.20** of **$10**." | S15; `ClaudeSection.swift:159` | match | Keep $10 plain, not a value word (settings-claude C6). The sheet's prose bolds only $1.20, which is right | Builder B |
| C3 | The spend word **$1.20** opens receipts | Sheet's one change | sheet missing a state | At the cap (S17) the sentence becomes "Paused until **Nov 1**." (`ClaudeSection.swift:157`), so no spend word is left and receipts can't be reached. Proposed: "**$10.00** this month. Paused until Nov 1." With no key (S1, S20, S22, S23) the ledger rows stay but nothing opens them: show a **RECEIPTS** label word under the no-key line when the ledger has rows (the same test #246 uses, `ClaudeSection.swift:124`) | Design |
| C4 | "Receipts" line goes | settings-claude "Receipts" row; Design `claude-settings.md` 63 | differs (intended) | Remove the NavigationLink (`ClaudeSection.swift:206-216`). The receipts page gets the **‹ SETTINGS** back word per `back-word.md`, not the system back chevron | Builder B |
| C5 | Receipt rows (by reference) "6:12 pm · Plan my day · Sonnet · 1.2¢" | settings-claude; Design `claude-settings.md` 63 | differs | #246 changed the time to weekday, day, month and time, all lowercased (`ClaudeSection.swift:447-448`), so day and month names come out lowercase. Keep "6:12 pm" lowercase only; capitalise the day ("Thu Oct 15, 6:12 pm") | Design (form), Builder B |
| C6 | Month line, amber at 80%, **PAUSES AT $10** (S16) | S16; settings-claude C8; `ClaudeSection.swift:162-169` | match | None | None |
| C7 | "Misses go to Claude: **yes**." (board) | settings-claude; decision 8:28 PM PT (default yes) | differs (master) | `ClaudeSection.swift:174-175` has no full stop after the value word. Add it. S25's **not today** isn't built | Builder B; Core (the pause rule) |
| C8 | Tess at the foot: "Misses stay on this phone." / "Misses go to Claude." | No M id; not in settings-claude | missing source | Wording passes the voice rules (name first, under 12 words). Research adds them as new M lines once Design confirms. Keep the 8:28 PM PT one-time line "Sent “{phrase}” to Claude. Turn this off in Settings: Claude." valid: CLAUDE stays the section name | Design |
| C9 | "Key ends in **...a1B2** · works" | settings-claude key line; M1; `ClaudeSection.swift:188` | match | Master also has a "didn't work" status (`ClaudeSection.swift:15`) that no state uses: S7 deletes the key at once. Check that a 401 leaves no key line | Builder B |
| C10 | TEST · REPLACE · REMOVE, middle dot, 10pt either side | settings-claude S6 | differs (master) | `ClaudeSection.swift:193-201` spaces the words 22pt with no middle dot. Add " · " | Builder B |
| C11 | The key never drawn | 5:49 PM PT; settings-claude; settings-object.md 33-34 | match | Nothing in the settings object holds the key or its last four (`TesseraSettings.swift` header). Keep it that way | Core |
| C12 | S4 "Checking it with Claude." | settings-claude S4 (new copy, open item 3) | match | Code `ClaudeSection.swift:301`. Design confirms the copy | Design |
| C13 | S5 "That doesn't look like a Claude key. Paste it again?" | M31 | match | `TesseraCore/Sources/TesseraTess/ClaudeKey.swift:325`, `ClaudeSection.swift:285` | None |
| C14 | S6 "Key saved. Ends in ...a1B2." | M1 | match | `ClaudeKey.swift:317` | None |
| C15 | S7 and S22 "That key didn't work. Paste it again?" | M2 (call) | match | `ClaudeKey.swift:318`. S22 (401 in use) isn't built | Builder B, Core |
| C16 | S8 "That key can't use Claude yet. Check it in the Console?" | M25 | match | `ClaudeKey.swift:319`. CONSOLE word not checked on master | Builder B |
| C17 | S9 offline | M26 "No connection. I kept the key and will check it later." | differs | `ClaudeKey.swift:321` "No connection. I kept the key; test it again later." (no retry exists, `:320`). Either build the check on next open, or keep the honest line without the semicolon: "No connection. I kept the key. Test it again later." Research then updates M26. **Applied:** M26 in `tess-voice.md` now reads "No connection. I kept the key. Test it again later." | Core (semicolon) |
| C18 | S10 timeout | M27 "Claude didn't answer in time. I'll check again later."; M18 (call) | differs from M27, matches M18 | `ClaudeKey.swift:322` "Claude didn't answer in time." Keep it until a retry exists; Research drops the retry clause from M27. **Applied:** M27 in `tess-voice.md` now reads "Claude didn't answer in time." | Core (no change) |
| C19 | S11 busy | M29 "Claude is busy right now. I'll check again soon." | differs | `ClaudeKey.swift:323` "Claude is busy right now. I kept the key." Same as C17: keep master's line until a retry exists; Research updates M29. **Applied:** M29 in `tess-voice.md` now reads "Claude is busy right now. I kept the key." | Core |
| C20 | S12, S13, S14 | M30, M32, M28 | match | `ClaudeKey.swift:324`, `:327`, `:330` ("Nov 1" form) | None |
| C21 | (no state) "I couldn't save that key. Try again?" | None: no S state for a Keychain write that fails | missing source | `ClaudeKey.swift:326`. Honest and short; add it as S27 and an M line | Design |
| C22 | S21 replace, a new key that fails | settings-claude S21 (shows S5 to S13, old key stays) | differs | Master swaps the outcome line for "That key didn't pass. Your old key still works." (`ClaudeSection.swift:311`, fine, no source) or "That key didn't pass, and I couldn't keep the old one. Add it again?" (`:313`, 14 words, over 12). Proposed: "Neither key works now. Paste one again?" | Design, then Builder B |
| C23 | S20 "Claude key removed. Everything stays on this phone." UNDO "Claude key is back." | settings-claude S20, C2; 6:37 PM PT | match | `ClaudeSection.swift:346`, `:360`; UNDO in vermilion (`:93-94`), 10 s (`:349-353`) | None |
| C24 | S17 "Paused until **Nov 1**." on the page; M10 at the blocked use | S17; M10; plan line "Claude paused until {reset}. Here's your usual plan." (8:38 PM PT) | match | The plan variant belongs to Plan my day, not Settings. Settings never says "On-device until then." itself | None |
| C25 | (no line) #246's no-key line after a reinstall: "Your key stays on the phone it was added on. Paste it again to let Tess ask Claude." | M4 / S23 "No key yet. Paste one to use Claude."; rule 3 (one line, under 12 words) | differs | `ClaudeSection.swift:127`: 17 words in two sentences. Proposed: "Keys stay on the phone they were added on. Paste it again?" (11) | Design, then Builder B |
| C26 | (no line) writing-line prompts "Paste a key from the Claude Console", "Paste the new key" | S2 (VoiceOver label "Claude key" only) | missing source | `ClaudeSection.swift:131`, `:204`. Fine as placeholders; Design confirms | Design |
| C27 | (no line) **Add a Claude key** | S1 "(cobalt, 21)"; sheet "Never: coloured resting text" | differs | Master draws it in `Theme.Colors.tess` (`ClaudeSection.swift:133-135`) at rest. Decide: an ink 600 value word, or S1's cobalt as Tess's offer. Default ink, to obey the sheet's own Never line | Design |
| C28 | Owners: "Core: the settings object fields" | Master 5455f14 already has `missesGoToClaude`, `lookDay`, `lookNight`, `lookPinned`, `backupFolderName` (`TesseraCore/Sources/TesseraCore/Settings/TesseraSettings.swift:77-81`, `:134-139`) | differs (stale) | Core's part is done. Builder B moves `@AppStorage("tess.missesGoToClaude")` (`ClaudeSection.swift:59`) onto the settings object, so it rides in backups | Builder B |

### BACKUPS

| # | Sheet text | Source (#246 and master) | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| B1 | "Two copies. Last one today, 4:02 am." | Hero "Kept in two places" / "Kept on this iPhone" (`BackupView.swift:51-52`); "A copy is made every day, the last one today. Seven are kept." (`BackupView.swift:348`) | differs | "Two copies" is wrong: seven are kept on the phone, plus the folder's. Proposed: "Kept in two places. Last copy today, 4:02 am." and "Kept on this iPhone. Last copy today, 4:02 am." with no folder or a failing folder; none yet: "The first copy is made when you leave the app today." (`:341`). The time is new: master shows the day only. **Applied:** recorded in `tess-voice.md` as a proposal for Design | Design, then Builder B |
| B2 | No-break space in "4:02 am" | 6:37 PM PT ("6:12 pm" form) | match | None | Builder B |
| B3 | "Folder **iCloud Drive/Tessera**." | "Also kept in **iCloud Drive/Tessera**." (`BackupView.swift:351-359`); display name only (settings-object.md 33-34, 99-100) | differs | Either works. Read the name from `backupFolderName`, never the bookmark | Design (wording), Builder B |
| B4 | "Folder **pick one**." | "Also keep them in **a folder you choose**." (`BackupView.swift:356`); principle 4 (offer, never instruct); M53 | differs | Keep master's line; "pick one" reads as an order | Design |
| B5 | **SAVE A COPY · RESTORE** | `BackupView.swift:123-125` | match | Add the middle dot (master spaces them with no dot) | Builder B |
| B6 | Restore "keeps its own flow and confirm from the backups sheet; its back word becomes **‹ SETTINGS**" | Master's restore is inline in BackupView (`restoreSection`, `BackupView.swift:186-221`), not its own page | differs | Say whether the Replace question and "A restore is waiting" sit inline under BACKUPS or one layer down. Only a page one layer down gets ‹ SETTINGS | Design |
| B7 | (kept by reference) restore lines | `BackupView.swift:188-269` | match, one line stale | `:266` "What's here now is kept in Backups, so this can be undone." names a page that goes away. Proposed: "What's here now is kept as a copy, so this can be undone." | Design, then Builder B |
| B8 | (no line) **STOP USING IT**, UNDO 10 s, "Copies stay on this iPhone only now." / "The folder is back." | #246: `BackupView.swift:103-110`, `:283`, `:298` | sheet missing a state | Place it after the folder line. Undo rule: name the thing first. Proposed: "iCloud Drive/Tessera dropped. Copies stay on this iPhone." and UNDO "iCloud Drive/Tessera is back." (the "is back" exception for a removal) | Design, then Builder B |
| B9 | (no line) "Reinstalled? Restore brings back your copy from iCloud Drive." | #246: `BackupView.swift:68-76` | sheet missing a state | Keep it under BACKUPS when there is no user history | Design |
| B10 | (no line) failure lines: "{Today's / The last} copy {to iCloud Drive/Tessera / on this iPhone} didn't save. It tries again when you leave the app." and "The folder you chose can't be reached, so copies are only on this iPhone. Choose it again." | `BackupView.swift:362-370` | sheet missing a state | Keep both. The second one is 16 words: "Can't reach iCloud Drive/Tessera. Copies are on this iPhone only." | Design |
| B11 | (no line) "These survive deleting the app." / "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." | `BackupView.swift:113-115` | sheet missing a state | Say keep or drop. Default: keep the no-folder line, since it's the reason to pick a folder | Design |
| B12 | (no line) "Saved a copy there. One a day from now on.", "Couldn't use that folder. Try another one.", "Saved.", "Couldn't make a copy just now." | `BackupView.swift:163`, `:165`, `:179`, `:227` | sheet missing a state | Undo rule: name it first. "Copy saved." for `:179`; "Copy saved to iCloud Drive/Tessera. One a day from now on." for `:163` | Design, then Builder B |
| B13 | (no line) "your history" and **‹ Review** on Backups | `BackupView.swift:38`, `:46` | match (they go) | Remove with the fold | Builder B |

### UNITS

| # | Sheet text | Source | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| U1 | "**Kilograms**, bar **20 kg**, plates **1.25 kg**." | `product/morning-questions.md` 8 and `product/workouts.md` 3, 23: 20 kg bar, 1.25 kg smallest plate, dumbbells in 2 kg steps | differs | "plates 1.25 kg" reads as every plate; dumbbells are missing. Proposed: "Kilograms. Bar 20 kg, plates from 1.25 kg, dumbbells in 2 kg steps." | Design |
| U2 | Words in 600 that don't cycle | Decision 9:12 PM PT: "UNITS as plain text until Core adds unit fields" | differs | Regular weight until the fields exist; 600 promises a tap that does nothing | Design |
| U3 | Core adds unit fields | settings-object.md 169, 215: only `massUnit` is reserved | differs | Core reserves bar and plate fields beside `massUnit`, or the sentence stays text | Core |

### Value words, Never, owners

| # | Sheet text | Source | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| V1 | Cycle: blur out 120ms, blur in 180ms, light haptic | LookSentence `.selection` haptic (`LookSentence.swift:69`); misses uses a 0.18 s fade (`ClaudeSection.swift:182`) | differs (master) | One value-word transition for all words, through MotionPolicy | Builder B |
| V2 | "A word that opens something (folder, $1.20) has no press colour" | Master folder word in ink 600 (`BackupView.swift:89-90`) | match | None | None |
| N1 | Never: gear, rows, toggles, cards, chevrons, switches | 8:07 PM PT (no coloured dots); ink action words | match | Receipts now push with a system back button (C4). Middle dots between label words are separators, not bullet dots | Builder B |
| N2 | Never: the key or its bookmark path drawn | 5:49 PM PT; settings-object.md 33-34 | match | None | None |
| N3 | Never: coloured resting text | 8:07 PM PT | differs | Clashes with S1's cobalt **Add a Claude key** (C27). Tess's lines in cobalt are speech, not resting text; say so | Design |

## settings-claude states the sheet doesn't show

The sheet covers the CLAUDE section "as `claude-settings.md` (every state)", and its board draws one state only (S6/S15: works, $1.20, misses yes). These states need an answer specific to the new place, or aren't on master yet:

| State | What's open | Owner |
|---|---|---|
| S1 No key | Where receipts go with no key (C3); the colour of **Add a Claude key** (C27); #246's reinstall line (C25) | Design |
| S2, S3 Pasting | Where the writing line opens on the new page and whether it scrolls above the 72pt foot | Design |
| S4 to S14 Test outcomes | Inline under CLAUDE (master) or at the foot (sheet's value-word rule) (P5); C17, C19 lines differ | Design, Core |
| S17 Paused at the cap | No spend word left, so receipts can't be reached (C3) | Design |
| S19 Switched off | Not built: no value word on master (C1) | Builder B |
| S20 Key removed | Where UNDO sits relative to the foot line | Design |
| S22 Key revoked later | Not on master; "line on top" of S1 needs a place on the new page | Builder B, Core |
| S23 Key missing | Not on master; collides with #246's reinstall line (C25): both cover "no key, the ledger has rows" | Design |
| S24 Busy in use | No Settings change; nothing to do | None |
| S25 Misses paused for today | Not on master: no **not today**, no line "Misses on this phone today. 3 of 10 taken back." | Builder B, Core |
| S26 Key pasted into Ask | Says "Paste it in Settings." (M24): still right, Settings now exists by that name | None |
| (new) Keychain write fails | `ClaudeKey.swift:326`, no S number (C21) | Design |
