# Settings: one place, reached from Review's foot (Design item 16)

This sheet is for Builder B. It gathers what is now spread over Review (LOOK, Claude, Backups) into one Settings page, written as sentences with value words. Fields follow Research's `docs/research/settings-object.md` (on master); the Claude section stays as `claude-settings.md` draws it, with the changes below.
- Board: `mockups/settings-place.png` (source `studies/settings-place.html`): Review's foot, then Settings in Porcelain and Obsidian.
- Recording: `recordings/settings-place.mp4`: tap SETTINGS, Settings grows out of the word, "Misses go to Claude" flips to no and Tess answers inline under it, then back.

## The way in
- Review keeps **one** quiet word at its foot: **SETTINGS**, a Label 16/700 word in `inkSecondary`, under the link lines (y 744 in `review-week-line.md`). LOOK, Claude **and the Backups word** leave Review. [P1]
- Tap: the ink line draws under the word (150ms), then Review lifts away (scale 1.06, blur 3pt, fade, 380ms, house curve) while Settings grows from the word (scale 0.94 → 1 from the word's centre, 420ms, 60ms later). Sections rise 10pt, 40ms apart.
- **Back** (‹ REVIEW or the edge swipe) is the same in reverse: Settings closes into the word, Review returns, the ink line empties.
- Reduce Motion: a crossfade, no scale, no blur.

## The page (y in pt)
| y | Element |
|---|---|
| 58 | **‹ REVIEW** (`back-word.md`) |
| 84 | "Settings", Title 44/500 |
| 158 | The sections, a column with 22pt between sections. Each section is its label (Label 16/700 `inkSecondary`, 12pt above its first line), then Body 21 lines 8pt apart. The page scrolls if Dynamic Type needs it; the bottom 72pt stays clear for Tess's line. |

## The sections
Research checked this sheet line by line (`research/settings-place-check.md`, item 112). Every answer below settles one of its rows; the row id is in brackets.

### LOOK
- "**Porcelain** by day, **Obsidian** by night." Each name is a value word that cycles the looks (`lookDay`, `lookNight`). Pinned: "**Lacquer** always." [L2]
- **The hint line** under it, Body 21 `inkSecondary`, as master has it: "Hold a name to keep it day and night." When pinned: "Hold it again to follow light and dark mode." [L3]
- **A look change floods from the tapped word**, not from the soul: Builder A's `PaintFlood` gains an origin point, and Settings passes the name's centre. It keeps its 700ms, and a 250ms crossfade under Reduce Motion. Only the name in the active half floods; cycling the other half just swaps the word. Looks say nothing. [L6]

### CLAUDE
`claude-settings.md` holds for every state, with these changes.
- **Receipts open from the spend word.** The "Receipts" line goes, and **$1.20** opens the receipts one layer down, with a **‹ SETTINGS** back word (no system chevron). [C3, C4]
  - At the cap: "**$10.00** this month. Paused until Nov 1." The amount is the word.
  - With no key but a ledger that has rows: a **RECEIPTS** label word under the no-key line.
- **Receipt rows:** today's rows read "6:12 pm · Plan my day · Sonnet · 1.2¢". Older rows read "Thu Oct 15, 6:12 pm · …", with the day and month capitalised and "pm" in lower case. [C5]
- **"Add a Claude key"** is an `ink` 600 value word, not cobalt. Cobalt is Tess speaking, and an offer at rest isn't speech. [C27, N3]
- **Lines confirmed:**
  - "Checking it with Claude." [C12]
  - "Misses stay on this phone." / "Misses go to Claude." [C8]
  - The writing-line placeholders "Paste a key from the Claude Console" and "Paste the new key". [C26]
- **New lines:**
  - S27, the Keychain write fails: "I couldn't save that key. Try again?" [C21]
  - A replace where neither key works: "Neither key works now. Paste one again?" "That key didn't pass. Your old key still works." stays. [C22]
  - No key after a reinstall, when the ledger has rows (this is also S23): "Keys stay on the phone they were added on. Paste it again?" With no rows, S1's line stands. [C25]
- **Pasting** (S2, S3): the writing line opens under "Add a Claude key" in place, and the page scrolls to keep it above the keyboard.

### BACKUPS
Folded in from the Backups page. **Restore stays inline under BACKUPS**, as on master (the Replace question and "A restore is waiting" included). There's no separate page, so no back word. [B6]
- **The status line:** [B1]
  - "Kept in two places. Last copy today, 4:02 am."
  - With no folder, or a failing one: "Kept on this iPhone. Last copy today, 4:02 am."
  - No copy yet: "The first copy is made when you leave the app today."
  - Keep "4:02 am" together with a no-break space.
- **The folder line:** [B3, B4]
  - "Also kept in **iCloud Drive/Tessera**." The name is a value word that opens the picker, read from `backupFolderName` and never from the bookmark.
  - With no folder: "Also keep them in **a folder you choose**." This is master's offer, not an order.
- **STOP USING IT**, a label word under the folder line. Tess: "iCloud Drive/Tessera dropped. Copies stay on this iPhone." with UNDO 10s, which answers "iCloud Drive/Tessera is back." [B8]
- **Label words SAVE A COPY · RESTORE.** [B5]
- **Kept from #246:** [B7, B9 to B12]
  - The reinstall line, with no history: "Reinstalled? Restore brings back your copy from iCloud Drive."
  - The no-folder reason: "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." "These survive deleting the app." goes.
  - Failures:
    - "{Today's / The last} copy {to iCloud Drive/Tessera / on this iPhone} didn't save. It tries again when you leave the app."
    - "Can't reach iCloud Drive/Tessera. Copies are on this iPhone only."
  - Saves:
    - "Copy saved."
    - "Copy saved to iCloud Drive/Tessera. One a day from now on."
    - "Couldn't use that folder. Try another one."
    - "Couldn't make a copy just now."
  - The restore line: "What's here now is kept as a copy, so this can be undone."

### UNITS
"Kilograms. Bar 20 kg, plates from 1.25 kg, dumbbells in 2 kg steps." **Plain 400 text**, per Product's 9:12 PM call, until Core reserves bar, plate and dumbbell fields beside `massUnit`. A 600 word would promise a tap that does nothing. [U1 to U3]

Label words are separated by a middle dot with 10pt either side. No toggles, rows, cards, chevrons or switches.

## Where Tess speaks: inline, next to what it's about
Every Settings line from Tess sits **inline, under the line it's about**: the key outcomes under the key line, misses under the misses line, backups lines under BACKUPS' status line. This replaces this sheet's earlier rule of Tess speaking at the foot. [P5]
- The line opens in place (it grows from 0 to 28pt, 320ms, house curve).
- It's cobalt, because it's speech. It stays until the next change in that section.
- An UNDO sits at its end as a `liveInk` label word.
- The page has no foot reserve beyond the soul's corner. It scrolls when Dynamic Type or a long state needs it.

## Value words
- A tap cycles the word: the old word blurs out (3pt, 120ms), the new word blurs in (180ms), with a light `.selection` haptic. It's one transition for every word, through `MotionPolicy`. [V1]
- A word that opens something (the folder, the spend) has no press colour. It opens one layer down, or in place for the folder picker.

## Never
A gear icon, a list of rows, a toggle, a section in a card, the key or its bookmark-style path drawn, coloured resting text.

## Owners
- **Builder B** (`Features/Review/`, `Features/Settings/`, `Features/Backup/`):
  - the Settings page and the SETTINGS word on Review;
  - moving LOOK, Claude and Backups in;
  - moving `@AppStorage("tess.missesGoToClaude")` onto the settings object, so it rides in backups [C28];
  - the master fixes Research lists: the full stop after the misses word [C7], middle dots between label words [C10, B5], the switch value word [C1].
- **Core:** the settings-object fields are already on master (5455f14). The unit fields are still to come.
- **Builder A:** `PaintFlood`'s origin point.
