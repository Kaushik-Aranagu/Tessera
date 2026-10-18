# Settings, day one: every row, word, sheet and receipt (Product item AG)

For: Builder B (Settings, Review, Backups), Core (settings storage, the key check, the ledger), Builder A (looks, the flood, Tess's eyes). Research lab, Oct 16, 2026 (Pacific).
Master `dda42e6`, read by hand with `git show` and `git grep`. Nothing was built or run.

**What "day one" means here.** Kaushik opens the next build and goes looking for his settings. There is no Settings page on master yet. LOOK, CLAUDE and the **Backups** word sit at the foot of "The week" (`Features/Review/ReviewView.swift:220-236`), which opens full screen from the Review page's link line on Home (`Features/Home/HomeSpatialView.swift:193`, `:351`). Backups is its own page one layer down (`Features/Backup/BackupView.swift`). This walk covers what he meets where it actually is, and what the rules say should be there instead.

**Rule sources.**
- Product: `docs/product/decisions.md` on master. The brief's `docs/ops/decisions.md` doesn't exist on master; this is the decisions log.
- Design sheets: these are not on master. They live on branch `claude/project-thread-b3tu3f`: `settings-place.md` (item 16, with its Oct 16 addenda), `settings-eyes.md` (Design 70, "Tess has eyes", commit c5d6e7b), `claude-settings.md`, `tess-knows.md` and `copy-pass.md` (Design 62).
- Research: `settings-object.md`, `settings-claude.md` (S1 to S26), `settings-place-check.md` (P, L, C, B and U rows), `receipts-thing-first.md` (RC rows), `undo-windows-audit.md` (X rows), `time-words-sweep.md` (TW rows) and `post-pin-403-407.md`.
- `docs/PRODUCT_VISION.md` (dense information, revealed progressively).

**Statuses.**
- **pass**: master does what was ruled.
- **wrong**: master has it, but not as ruled.
- **miss**: the surface exists on master and a rule applies to it, but nothing on master does it.
- **not built**: the surface the rule lives on doesn't exist on master yet.

Placeholders: a wrong paste is "hunter2"; a captured phrase is "tacocat". Key presence is yes or no only.

## Counts

| Status | Steps |
|---|---|
| pass | 32 |
| wrong | 27 |
| miss | 8 |
| not built | 10 |
| **Total** | **77** |

| Area | pass | wrong | miss | not built |
|---|---|---|---|---|
| The way in (S1 to S3) | 0 | 1 | 0 | 2 |
| LOOK and eyes (S4 to S13) | 4 | 0 | 3 | 3 |
| CLAUDE, adding the key (S14 to S27) | 10 | 3 | 1 | 0 |
| CLAUDE, the switch and the month (S28 to S38) | 5 | 4 | 2 | 0 |
| Receipts (S39 to S42) | 2 | 2 | 0 | 0 |
| The key afterwards (S43 to S51) | 4 | 4 | 1 | 0 |
| BACKUPS (S52 to S73) | 7 | 13 | 1 | 1 |
| UNITS, TESS and leaving (S74 to S77) | 0 | 0 | 0 | 4 |

## Gaps by owner

### Builder B (Settings, Review, Backups)
- **S1, S2, S76, S77 (not built):** no Settings page and no SETTINGS word at Review's foot. LOOK, CLAUDE and Backups still sit at the foot of The week (`ReviewView.swift:220-236`).
- **S52 (not built):** Backups is still a page with its own back word and hero (`BackupView.swift:36-58`). The rule folds it inline under BACKUPS.
- **S11 (not built), Builder B's part:** the "Tess has eyes: **no**." row in LOOK, with its inline answers. It waits on Core's `tessEyes` (#407).
- **S74, S75 (not built):** UNITS as plain text, and the TESS line "Tess remembers **12 things**.".
- **S3 (wrong):** the lines that point him to Settings name three different places: "Settings: Claude" (`TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:133`, `:203`), "Settings" (`Features/Recipes/PasteRecipe.swift:33`), and "Review, under Claude" (`Features/Command/BottomChrome.swift:466`).
- **S18 (wrong):** a short paste that isn't a key ("hunter2") gets no line until Return is pressed (`Features/Settings/ClaudeSection.swift:258`, `:263`).
- **S23 (wrong):** after a 401 at Test, the writing line never reopens. `withKey` only draws it while replacing (`ClaudeSection.swift:235`, `:363-364`).
- **S24 (miss):** there is no CONSOLE word on "not allowed" or "account paused".
- **S30 (wrong):** the yes answer says "and for Plan my day", but no Plan my day surface calls Claude on master (`ClaudeSection.swift:293`).
- **S31 (wrong):** the switch's value-word change is a 0.18 s opacity fade with no haptic (`ClaudeSection.swift:171`, `:188`). The ruled change is the shared value-word transition with a `.selection` tick.
- **S34 (wrong):** at the cap, the line should read "**$50.00** this month. Paused until Nov 1." Master keeps "This month $50.00 of $50." and adds a second line (`ClaudeSection.swift:192-208`).
- **S40, S41 (wrong):** receipt rows always carry the day, and they use the locale's clock and the raw instant's weekday (`ClaudeSection.swift:500-502`).
- **S45, S47, S51 (wrong):** the replace receipt and its UNDO, the both-keys-failed line, and the no-key-after-reinstall line (`ClaudeSection.swift:136`, `:351`, `:359-365`).
- **S49 (miss), S50 (wrong):** the early commit on background doesn't say so, and the key UNDO plays no haptic.
- **BACKUPS copy and placement (wrong):**
  - S53, the status line: `BackupView.swift:51-65`, `:353`.
  - S54, the weekday: `:352`.
  - S57, the folder receipt: `:168`.
  - S58, "These survive deleting the app.": `:120`.
  - S59 and S61, the stop and UNDO lines, the UNDO's place and its window: `:110-116`, `:288-303`.
  - S62, the save receipt: `:184`.
  - S63, the middle dot: `:127-133`.
  - S65, the restore line: `:271`.
  - S67, the cancel receipt: `:221`.
  - S68, the folder failure line: `BackupView.swift:384`.
  - S69, where Tess's lines sit: `:139-146`.
- **S60 (miss):** "Stop using it" leaves `backupFolderName` set, so the page then reads the after-restore line "Your copies were kept in iCloud Drive/Tessera. Choose it again." (`Features/Backup/BackupKeeper.swift:142`, `BackupView.swift:92-93`).

### Core (settings storage, key check, ledger)
- **S11, S13 (not built):** the `tessEyes` field (#407, Catalog v10) isn't on master. Its default is no, and a pre-v10 restore must also read no.
- **S23 (wrong):** a 401 keeps the key (`ClaudeKey.swift:270-271`), against settings-claude S7 ("deleted at once"). This needs a Product call (question 1).
- **S25 (wrong):** the offline line still has a semicolon (`ClaudeKey.swift:332`).
- **S35 (miss):** "Paused" doesn't show when a call is refused below the cap. A refusal leaves no mark (`ClaudeTessModel.swift:60-64`), and Settings checks only spent ≥ cap (`ClaudeSection.swift:163`).
- **S36 (miss):** there is no spend file outside the store. The month is read only from `tessCall` rows (`ClaudeKey.swift:110-114`), so a restore can roll the month back.
- **S37 (wrong):** the month resets on the phone's calendar, not at Pacific midnight on the 1st (`ClaudeKey.swift:112`, `:340`; `ClaudeSection.swift:28-30`).
- **S61 (shared):** the one undo-window constant that pauses in the background and reads VoiceOver. Core owns the constant, and Builder B wires it.

### Builder A (looks and eyes)
- **S7 (miss):** a look change crossfades the ground and never floods from the tapped word (`DesignSystem/LookSentence.swift:118-120`). `PaintFlood` already takes an origin (`Features/Tess/PaintFlood.swift:7`), but only the Tess tap uses it (`App/RootView.swift:41`).
- **S9 (miss):** a look tap never reaches the settings object. `ThemeStore.save()` writes only the App Group keys (`DesignSystem/Looks.swift:294-300`), so a look changed after the one-time migrate never rides in a backup.
- **S10 (miss):** `adoptRestored` (`Looks.swift:140`) still has no caller, so a restore never brings his look back.
- **S11, S12 (not built):** the soul has no eyes or mouth on master. Two things are missing: reading `showsTessEyes`, and the open, blink and fade on a flip.

## The walk

### The way in

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S1 | Opens Review to find his settings | One quiet **SETTINGS** word at Review's foot. LOOK, CLAUDE and the Backups word leave Review (settings-place "The way in", P1) | No Settings word. He has to tap "The week" on the Review page's link line (`HomeSpatialView.swift:193`, `:351`). That opens full screen with CLOSE (`:161-172`), and LOOK, CLAUDE and **Backups** sit at its foot (`ReviewView.swift:220-236`), under the week | not built |
| S2 | Taps SETTINGS | The ink line draws under the word, Review lifts away and Settings grows from the word, with **‹ REVIEW** and a "Settings" Title 44. Reduce Motion gives a crossfade (settings-place) | Nothing to tap | not built |
| S3 | Pastes his key in the wrong place, or reads the first miss notice | Every pointer names the same place. The first-miss notice "Sent “tacocat” to Claude. Turn this off in Settings: Claude." stays as decided (12:35 pm, RC36 a notice). M24 says "Paste it in Settings." | Three different places. The notice and the 401-in-use line say "Settings: Claude" (`ClaudeTessModel.swift:133`, `:203`). Paste a recipe says "It goes in Settings, not a recipe." (`PasteRecipe.swift:33`). Ask says "It goes in Review, under Claude." (`BottomChrome.swift:466`). There is no page called Settings | wrong |

### LOOK (and Tess's face)

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S4 | Reads LOOK | LOOK label, then "**Porcelain** by day, **Obsidian** by night." with each name a value word (L1, L4) | `LookSentence.swift:15-17`, `:31-42` | pass |
| S5 | Reads the hint | "Hold a name to keep it day and night." in inkSecondary (L3) | `LookSentence.swift:64`, `:73-77` | pass |
| S6 | Taps "Porcelain" | The name cycles to the next look with a light `.selection` tick. Looks say nothing, and there is no UNDO (L5) | `LookSentence.swift:83-86`, `:69` | pass |
| S7 | Watches the look change | The flood starts from the tapped word (700 ms, or a 250 ms crossfade under Reduce Motion). Only the name in the active half floods (L6; decision 9:17 pm PT Oct 15) | A 0.7 s crossfade of the ground, with no flood (`LookSentence.swift:118-120`). The comment says "the soul's flood comes with Settings" | miss |
| S8 | Holds "Lacquer" | "**Lacquer** always." with the hint "Hold it again to follow light and dark mode.", and a medium impact (L2, L3) | `LookSentence.swift:19-29`, `:70`, `:91-94` | pass |
| S9 | Changes the look, then a backup runs | The look is his choice, so it lives in the settings object and rides in every copy. The App Group copy is a mirror written in the same `save()` (settings-object U1) | `ThemeStore.save()` writes only the App Group keys (`Looks.swift:294-300`). The object gets the look once, at the launch migrate (`App/AppModel.swift:120-123`), and never again | miss |
| S10 | Restores a backup on a phone where he never chose a look | `adoptRestored(day:night:pinned:)` applies the restored look (settings-object, "Look after a restore") | No caller (`Looks.swift:140`; only `ThemeStoreTests.swift:106`) | miss |
| S11 | Reads LOOK's third sentence | "Tess has eyes: **no**." with a value word that cycles yes and no, and no toggle shape. Tess answers inline in cobalt: "Tess has a face now." or "Tess has no face. She still moves." The sections below slide down 36 pt (Design 70; decision 12:58 pm: the row lives under LOOK, the key in code is `tessEyes`) | No row and no `tessEyes` field on master (`TesseraCore/Sources/TesseraCore/Settings/TesseraSettings.swift:6-38` has none). #407 is unmerged and waits for the pin | not built |
| S12 | Flips it to yes, then back to no | Yes: 220 ms after the tap the lids open from 0.25 over 400 ms with the mouth, and one blink follows 1.6 s later. No: the face fades out in 120 ms. Reduce Motion gives a 150 ms crossfade. The eyes hide while Tess is working (12:58 pm) | No eyes or mouth on the soul (`git grep -i eyes` finds only comments in `Features/Tess/SoulRouter.swift:9`, `:37`) | not built |
| S13 | First open after install, and after restoring an older copy | No by default, and no after restoring a pre-v10 backup. A backup made with yes restores yes (Design 70, QA) | No field | not built |

### CLAUDE: adding the key

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S14 | Reads CLAUDE with no key yet | "Tess thinks on this phone only." Then **Add a Claude key** as an ink 600 value word, not cobalt (S1, C27) | `ClaudeSection.swift:134-147` | pass |
| S15 | Looks for the switch and the spend line | With no key there is no switch, no month line, no key line and no receipts (S1) | `ClaudeSection.swift:87-93`, `:149-153` | pass |
| S16 | Taps Add a Claude key | The writing line opens in place: a 0.5 pt cobalt line with no box, "Paste a key from the Claude Console", no autocorrect, never stored outside the Keychain. The page keeps it above the keyboard (S2, C26) | `ClaudeSection.swift:139-140`, `:245-278`. Keeping it above the keyboard is left to the system's scroll | pass |
| S17 | Taps away with the line empty | The line closes (S2) | `ClaudeSection.swift:264-270` | pass |
| S18 | Pastes "hunter2" by mistake | "That doesn't look like a Claude key. Paste it again?" The line stays open and empty. Nothing is saved or sent (S5) | A paste under 10 characters isn't caught by the paste check (`ClaudeSection.swift:258`), so nothing answers until he presses Return (`:263`). A long non-key paste does get the line (`:321-323`) | wrong |
| S19 | Pastes a key that carries a line break | All whitespace is stripped, then the check runs (S3) | `ClaudeSection.swift:318`; `ClaudeKey.swift:218` | pass |
| S20 | The key lands | "Checking it with Claude." The soul goes into thinking with wisps (S4) | `ClaudeSection.swift:338-339` | pass |
| S21 | The check passes | "Key saved." Then "Key saved · works" with **TEST · REPLACE · REMOVE** (middle dots). The switch, the spend line and the month line unfold. The clipboard is cleared if it still holds the key (S6, C9, C10, QA C5) | `ClaudeKey.swift:327`; `ClaudeSection.swift:220`, `:216-233`, `:366-372` | pass |
| S22 | The Keychain refuses the save | "I couldn't save that key. Try again?" The line stays open (C21) | `ClaudeKey.swift:223-225`; `ClaudeSection.swift:363` (`writing` is true and the no-key view shows the line) | pass |
| S23 | The check gets a 401 | "That key didn't work. Paste it again?" The Keychain item is deleted at once and he is back at the writing line (S7) | The key is kept on purpose (`ClaudeKey.swift:270-271`, QA review-230). The page shows "Key saved · didn't work" and the line, but the writing line stays shut: the key view draws it only while replacing (`ClaudeSection.swift:235`, `:363-364`). He has to find REPLACE | wrong |
| S24 | The check gets a 403, or the account is paused | The line, then "· not allowed" or "· account paused", with **CONSOLE** · TEST · REMOVE (S8, S12) | The lines and status words are there (`ClaudeKey.swift:330`, `:335`; `ClaudeSection.swift:14-16`), but there is no CONSOLE word (`:223-232`) | miss |
| S25 | Tests with no connection | "No connection. I kept the key. Test it again later." (M26, C17) | "No connection. I kept the key; test it again later." (`ClaudeKey.swift:332`) | wrong |
| S26 | Tests while Claude is slow or busy, or gets an odd answer | "Claude didn't answer in time.", "Claude is busy right now. I kept the key.", "I couldn't check that key. Try again?", each with "· not checked" (S10, S11, S13) | `ClaudeKey.swift:333-334`, `:337`; `ClaudeSection.swift:17` | pass |
| S27 | Adds a key in a month already at the cap | "Key saved. Claude paused until Nov 1." (S14) | `ClaudeKey.swift:338-341`, `:271-276` | pass |

### CLAUDE: the switch and the month

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S28 | Reads the first line | "Tess asks Claude: **yes**." in ink, with the value word at 600 and a full stop. It is stored in the settings object, and nil reads as yes (settings-place; decisions 10:29 pm and 8:28 pm PT Oct 15) | `ClaudeSection.swift:166-177`; `AppModel.swift:58-59`; `TesseraSettings.swift:41-43` | pass |
| S29 | Flips it to no | "Tess stays on this phone." appears inline under the switch. The word shows what was stored, read back after the write (copy-pass 11; QA F2) | `ClaudeSection.swift:284-295`, `:179-186` | pass |
| S30 | Flips it back to yes | The yes answer names only jobs the build does (settings-place addendum, Design 50). Third person (copy-pass 11) | "Tess asks Claude when she's unsure, and for Plan my day." (`ClaudeSection.swift:293`). No app surface sends a plan to Claude on master: `git grep -i 'plan my day'` in `App/` and `Features/` finds only comments, this line and the receipt name | wrong |
| S31 | Feels the flip | One value-word transition for every word, through MotionPolicy: blur out 120 ms, blur in 180 ms, a light `.selection` tick (V1) | A 0.18 s opacity fade (`ClaudeSection.swift:171`, `:188`) and no haptic. LOOK's names do tick (`LookSentence.swift:69`), so the two value words feel different | wrong |
| S32 | Reads the spend line | "This month **$0.00** of $50." The amount is the word that opens receipts. Under it, a hairline with a cobalt stroke (S15; cap $50, 9:27 am PT Oct 16) | `ClaudeSection.swift:190-204`; `ClaudeKey.swift:88-90` | pass |
| S33 | Spends past $40 | The stroke turns amber, with **PAUSES AT $50** under it. No notification (S16, C8) | `ClaudeSection.swift:202`, `:209-212` | pass |
| S34 | Hits the cap | "**$50.00** this month. Paused until Nov 1." The amount stays the word that opens receipts (settings-place C3) | "This month **$50.00** of $50." stays, with "Paused until **Nov 1**." added under the month line (`ClaudeSection.swift:192-208`). Receipts are still reachable | wrong |
| S35 | A capture is refused because its hold would pass the cap, at $49.80 | "Paused" shows as soon as a call is refused (12:40 pm) | Tess says "Claude paused until Nov 1." (`ClaudeTessModel.swift:60-64`), but nothing is kept. Settings still reads "This month $49.80 of $50." with PAUSES AT $50, because it pauses only when spent ≥ cap (`ClaudeSection.swift:163`) | miss |
| S36 | Restores an older copy mid-month | The month's spend is also kept in a small file outside the store that restore never touches, and the cap takes the higher of the two (12:40 pm) | The month is summed only from `tessCall` rows in the store (`ClaudeKey.swift:110-114`). No file | miss |
| S37 | Opens Settings while traveling on Oct 31 | The month resets at Pacific midnight on the 1st, wherever he is. Abroad the line reads "Paused until Nov 1" with no PT (12:40 pm, 12:54 pm) | The phone's own calendar (`ClaudeKey.swift:112`, `:340`; `ClaudeSection.swift:28-30`) | wrong |
| S38 | Looks for a privacy line | "Titles and counts only. Never notes, places, health or money." It is due from AI-4 on (settings-place addendum). AI-4's Claude wording hasn't shipped (12:50 pm: Home stays on the rules) | Absent, correctly for now | pass |

### Receipts

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S39 | Taps **$0.00** | Receipts open one layer down with **‹ SETTINGS**, no system chevron, and the edge swipe back (C3, C4) | `ClaudeSection.swift:194`, `:444-492` | pass |
| S40 | Reads today's key check | Today's rows read "6:12 pm · Key check · Haiku · free". Older rows read "Thu Oct 15, 6:12 pm · …" (settings-place C5) | Every row carries the day, today's included: "Fri, Oct 16, 6:12 pm · Key check · Haiku · free" (`ClaudeSection.swift:500-502`) | wrong |
| S41 | Reads a row on a phone set to 24-hour time, or a 1:30 am call | Every clock string is 12-hour with am or pm, from the one formatter, and the weekday comes from his 4 am day (decision 12:35 pm; TW15) | The locale's own clock, lowercased, and the weekday of the raw instant (`ClaudeSection.swift:500-501`). A 24-hour phone shows "18:12" | wrong |
| S42 | Removes his key, then looks for old receipts | A **RECEIPTS** label word under the no-key line while the ledger has rows (C3) | `ClaudeSection.swift:150-153` | pass |

### The key afterwards

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S43 | Taps TEST | The check reruns with "Checking it with Claude." (C5) | `ClaudeSection.swift:224`, `:330-333` | pass |
| S44 | Taps REPLACE | "Paste the new key" opens in place under the key line. The old key keeps working until the new one passes (S21, C26) | `ClaudeSection.swift:226-237`, `:325-326` | pass |
| S45 | The new key passes | "Claude key replaced." A plain receipt with no key content (key state is yes/no only, 10:44 PM Oct 17, item 4), and no UNDO: nothing keeps a copy of the old key (10:47 PM Oct 17). The new key overwrites the old one at once | "Key saved." (`ClaudeKey.swift:327`), not "Claude key replaced.", with no UNDO. Master has no last four to remove: it draws yes/no state only ("Key saved · works", `ClaudeSection.swift:220`). The no-UNDO half already matches. The wording differs from the ruling (`ClaudeSection.swift:359-365`) | wrong |
| S46 | The new key fails and the old one is put back | "That key didn't pass. Your old key still works." (C22) | `ClaudeSection.swift:346-349` | pass |
| S47 | The new key fails and the old one can't be put back | "Neither key works now. Paste one again?" (C22) | "That key failed, and the old one is gone. Add one?" (`ClaudeSection.swift:351`) | wrong |
| S48 | Taps REMOVE | Two steps (11:07 PM Oct 17, #978 item 4, G375): REMOVE asks "Remove the Claude key?" with "Remove" and "Keep it"; "Remove" gives the plain receipt "Claude key removed. Everything stays on this phone." with no key content and NO UNDO (10:47 PM Oct 17: nothing keeps a copy of the key). REMOVE is a tap key and keeps VoiceOver double tap. `KeyRemoval` is deleted so nothing holds the key | `ClaudeSection.swift:380-392`, `:101-104` give one tap, no confirm, and a 10 s vermilion UNDO; Core/Builder B must add the confirm and remove the UNDO and `KeyRemoval` | gap |
| S49 | Leaves the app right after Remove | Nothing to commit later: with no UNDO window the removal is already final, so no "leaving makes it final" line is needed (superseded by the 10:47 PM Oct 17 ruling; the 12:45 pm early-commit rule has nothing left to apply to) | It commits (`ClaudeSection.swift:115-120`) and the line never says leaving makes it final; both go with the UNDO code | gap |
| S50 | Looks for UNDO after Remove | There is none, and no "Claude key is back." line (superseded by the 10:47 PM Oct 17 ruling) | `undoRemove()` (`ClaudeSection.swift:394-399`) says "Claude key is back."; Core/Builder B must delete it | gap |
| S51 | Reinstalled, so receipts exist but no key | "Keys stay on the phone they were added on. Paste it again?" (C25, settings-place) | "No Claude key on this phone. Paste one here." (`ClaudeSection.swift:136`) | wrong |

### BACKUPS

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S52 | Looks for backups | BACKUPS is a section on Settings, with restore inline and no page or back word (B6, B13) | A **Backups** label word at The week's foot (`ReviewView.swift:229-236`) pushes a page with "‹ Review", "your history" and a hero (`BackupView.swift:36-58`) | not built |
| S53 | Reads how safe his history is | "Kept on this iPhone. Last copy today, 4:02 am." or "Kept in two places. …". Before any copy: "The first copy is made when you leave the app today." (B1) | The hero "Kept on this iPhone", then "A copy is made every day, the last one today. Seven are kept." with no time (`BackupView.swift:51-65`, `:345-354`). Before any copy the line is right (`:346`) | wrong |
| S54 | Reads it on a day when the last copy was made at 1:30 am Wednesday, three days back | The weekday comes from his 4 am day, as in the copy's file name (TW24) | The weekday of the raw instant (`BackupView.swift:352`), while `fileDay` (`:398-401`) calls the same copy Tuesday's | wrong |
| S55 | Opens a fresh install with no history | "Reinstalled? Restore brings back your copy from iCloud Drive." Settings writes don't count as history (B9; QA C4) | `BackupView.swift:70-80` | pass |
| S56 | Reads the folder offer | "Also keep them in **a folder you choose**." The value word opens the picker. Then "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." (B4, B11) | `BackupView.swift:92-106`, `:118-119`, `:370-377` | pass |
| S57 | Picks iCloud Drive/Tessera | "Copy saved to iCloud Drive/Tessera. One a day from now on." The display name goes into the settings object, never the bookmark (B12; settings-object U4) | The name is stored right (`BackupKeeper.swift:123`, `:135-138`), but the receipt reads "Saved a copy there. One a day from now on." (`BackupView.swift:168`) | wrong |
| S58 | Reads the folder line now | "Also kept in **iCloud Drive/Tessera**." The line "These survive deleting the app." goes (B3, B11) | The folder line is right (`BackupView.swift:371-375`), but "These survive deleting the app." stays (`:120`) | wrong |
| S59 | Taps STOP USING IT | "iCloud Drive/Tessera dropped. Copies stay on this iPhone." in cobalt under the folder line, with UNDO at its end for 10 s (B8, P5) | "Copies stay on this iPhone only now." (`BackupView.swift:288`) at the foot of the page. UNDO replaces the STOP USING IT word instead of ending the line (`:109-116`) | wrong |
| S60 | Reads the folder line after stopping | The offer comes back. `backupFolderName` and `backupFolderPickedAt` are cleared when `forget` gets a caller (settings-object, design rules) | `forget()` clears only the bookmark and the failure (`BackupKeeper.swift:142-146`). The name stays, so the line reads the after-restore "Your copies were kept in iCloud Drive/Tessera. Choose it again." (`BackupView.swift:92-93`, `:359-368`) | miss |
| S61 | Locks the phone for 15 s, then taps UNDO | The window pauses while the app is backgrounded or the phone is locked, from one shared constant that reads VoiceOver. The line is "iCloud Drive/Tessera is back." (12:45 pm; B8) | `Task.sleep(10 s)` keeps running in the background (`BackupView.swift:290-294`), so UNDO is gone when he comes back. When he does catch it, the line is "The folder is back." (`:303`) | wrong |
| S62 | Taps SAVE A COPY and saves it | "Copy saved." (B12) | "Saved." (`BackupView.swift:184`) | wrong |
| S63 | Reads the two label words | **SAVE A COPY · RESTORE**, separated by a middle dot with 10 pt either side (B5) | Spaced with `Theme.Spacing.xl`, no dot (`BackupView.swift:127-133`) | wrong |
| S64 | Taps RESTORE and picks yesterday's copy | "Replace everything with the copy from Thursday October 15?" with a held **Replace** and "Keep what's here", inline (B6, B7) | `BackupView.swift:190-207` | pass |
| S65 | Holds Replace | "What's here now is kept as a copy, so this can be undone." (B7) | "What's here now is kept in Backups, so this can be undone." (`BackupView.swift:271`), which names a page that is going away | wrong |
| S66 | Reads the waiting restore | "A restore is waiting", inline, with Cancel restore (B6) | `BackupView.swift:208-227` | pass |
| S67 | Taps Cancel restore | Thing first: "Restore, canceled. Nothing will be replaced." (RC6; decision 12:35 pm) | "Cancelled. Nothing will be replaced." (`BackupView.swift:221`): verb first, British spelling | wrong |
| S68 | His folder can't be reached | "Can't reach iCloud Drive/Tessera. Copies are on this iPhone only." (B10) | "The folder you chose can't be reached, so copies are only on this iPhone. Choose it again." (`BackupView.swift:384`): 16 words, no folder name | wrong |
| S69 | Reads where Tess answers | Every Settings line from Tess sits inline under the line it is about. It grows in over 320 ms, stays until the next change, and any UNDO ends it (P5, "Where Tess speaks") | CLAUDE does this (`ClaudeSection.swift:95-107`, `:179-186`). Backups puts every line at the foot of the page, under restore (`BackupView.swift:139-146`) | wrong |
| S70 | Restores a backup made on a newer build | "That copy is from a newer Tessera. Update first." (post-pin, B5/B6 rider) | `BackupView.swift:256-257` | pass |
| S71 | Picks a file that isn't a backup, or a damaged one | No ruled line. Master's "That file isn't a Tessera backup." and "That copy is damaged. Try the day before." pass the voice rules | `BackupView.swift:258-262` | pass |
| S72 | A daily copy failed | "{Today's / The last} copy {to iCloud Drive/Tessera / on this iPhone} didn't save. It tries again when you leave the app." (B10) | `BackupView.swift:381-389` | pass |
| S73 | Opens Backups after changing only a look or the switch | Settings ops don't count as his actions, for the reinstall line or the rolling copy's empty-store guard (settings-object, design rules; QA C4) | `BackupView.swift:70-73` (`WriteSettings` excluded), and S9 means looks don't write ops at all | wrong |

S73 is **wrong** for a narrow reason. The exclusion is right, but the looks never write a settings op (S9). So the test that would catch a look counting as his action has nothing to test until S9 lands. It is counted here and not twice under S9.

### UNITS, TESS and leaving

| id | He does | Ruled | Master | Status |
|---|---|---|---|---|
| S74 | Reads UNITS | "Kilograms. Bar 20 kg, plates from 1.25 kg, dumbbells in 2 kg steps." as **plain 400 text**, until Core reserves bar, plate and dumbbell fields beside `massUnit` (U1 to U3; decision 9:12 pm PT Oct 15) | No section. The unit is a constant, "kg until Kaushik picks" (`App/AppClock.swift:35-36`) | not built |
| S75 | Reads TESS | "Tess remembers **12 things**." The count is the value word that opens What I know one layer down with **‹ SETTINGS**. With none it reads "Nothing yet." and opens the page the same way (tess-knows "Two doors") | No section and no page. The memory store exists in Core (`TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:20`), but no view reads it | not built |
| S76 | Swipes back, or taps ‹ REVIEW | Settings closes into the SETTINGS word, Review returns and the ink line empties. Reduce Motion gives a crossfade (settings-place) | Today he closes The week with CLOSE or a swipe down (`HomeSpatialView.swift:164-172`) | not built |
| S77 | Comes back the next day | The page is the same four (or five, see question 3) sections, in sentences, with no gear, rows, toggles or cards (settings-place "Never") | LOOK, CLAUDE and Backups at The week's foot. No gear, rows or toggles anywhere, so "Never" holds where things are | not built |


## Questions for Product

1. **A 401 at the key check: delete the key, or keep it?** settings-claude S7 says delete at once. Core's #230 keeps it, so a mistake on our side can never destroy a good key, and QA passed that. **My pick: keep it** (Core's reason holds). Then reopen the writing line under "That key didn't work. Paste it again?" and keep REMOVE in reach. S7 and S22 get rewritten to match, and Builder B fixes S23.
2. **What the yes answer says before Plan my day goes through Claude.** Master's line promises plans that nothing sends yet (S30). **My pick:** "Tess asks Claude when she's unsure." until Builder B wires Plan my day, then master's line as it stands. This follows Design 50's rule that the words never promise a job the build doesn't do.
3. **Four sections or five?** Design 70 says Settings keeps four labels (LOOK, CLAUDE, BACKUPS, UNITS). `tess-knows.md` adds a TESS line as the door to What I know. **My pick:** a fifth label, TESS, with its one line, built only when the What I know page is. The eyes row stays under LOOK, as decided.
4. **The save receipts: "Copy saved." or "Backup, saved."?** Design's settings-place says "Copy saved.", and RC5 says "Backup, saved.". Both put the thing first. **My pick: "Copy, saved."** It uses the word the page already uses ("Last copy today") and the house comma shape. The folder receipt then reads "Copy, saved to iCloud Drive/Tessera. One a day from now on."
5. **Until the Settings page ships, where do the pointer lines send him?** Three lines say "Settings" and one says "Review, under Claude" (S3). **My pick:** ship the SETTINGS word and page in the same build as any line that names it. If a build goes out first, all four say "Review, under Claude".
6. **What the early-commit line says** (S49). Withdrawn: with no UNDO there is no window to commit early, so no such line is needed (10:47 PM Oct 17).
7. **The replace UNDO** (S45). Answered by the 10:47 PM Oct 17 ruling: nothing keeps a copy of the key, so replacing has no UNDO either and the old key is not held for 10 s. Product to confirm that the ruling covers Replace as well as Remove.
8. **Units before Core's fields.** The decided plain sentence is ready (S74), but nothing reads bar, plate or dumbbell steps from settings. **My pick:** build UNITS as plain text now, so the page has its four sections. Make it value words only when Core adds the fields.
