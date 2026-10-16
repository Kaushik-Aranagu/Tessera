# Settings: one place, reached from Review's foot (Design item 16)

This sheet is for Builder B. It gathers what is now spread over Review (LOOK, Claude, Backups) into one Settings page, written as sentences with value words. Fields follow Research's `docs/research/settings-object.md` (on master); the Claude section stays exactly as `claude-settings.md` draws it, with one change below.
- Board: `mockups/settings-place.png` (source `studies/settings-place.html`): Review's foot, then Settings in Porcelain and Obsidian.
- Recording: `recordings/settings-place.mp4`: tap SETTINGS, Settings grows out of the word, "Misses go to Claude" flips to no, then back.

## The way in
- Review keeps **one** quiet word at its foot: **SETTINGS**, a Label 16/700 word in `inkSecondary`, under the link lines (y 744 in `review-week-line.md`). LOOK and Claude leave Review.
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
1. **LOOK**: "**Porcelain** by day, **Obsidian** by night." Each look name is a value word that cycles through the looks (`look.day`, `look.night`). When a look is pinned, the line reads "**Lacquer**, day and night." and a hold on the name unpins it (the existing hold-to-pin).
2. **CLAUDE**: as `claude-settings.md` (every state, the month line, the key line, TEST · REPLACE · REMOVE, "Misses go to Claude"). **One change:** the "Receipts" line goes. The spend value word **$1.20** opens the receipts one layer down instead, so the spend and its record are one thing.
3. **BACKUPS**: what the Backups page holds today, folded in.
   - "Two copies. Last one today, 4:02 am." (keep the time and "am" together with a no-break space).
   - "Folder **iCloud Drive/Tessera**." The folder name is a value word that opens the folder picker. Only the display name is shown (the bookmark never travels, per Research's list).
   - Label words **SAVE A COPY · RESTORE**. Restore keeps its own flow and confirm from the backups sheet; its back word becomes **‹ SETTINGS**.
   - No folder picked yet: "Folder **pick one**." in place of the folder line.
4. **UNITS**: "**Kilograms**, bar **20 kg**, plates **1.25 kg**." These are Product's training decisions. Until Core adds unit fields, the words are 600 but don't cycle (no press state).

Label words are separated by a middle dot with 10pt either side. No toggles, rows, cards, chevrons or switches.

## Value words
- A tap cycles the word: the old word blurs out (3pt, 120ms), the new word blurs in (180ms). A light haptic.
- When a change needs saying, Tess says it once at the foot, in cobalt: "Misses stay on this phone." / "Misses go to Claude." Looks say nothing (the page itself changes look).
- A word that opens something (folder, $1.20) has no press colour; it opens one layer down.

## Never
A gear icon, a list of rows, a toggle, a section in a card, the key or its bookmark-style path drawn, coloured resting text.

## Owners
Builder B: the Settings page, the SETTINGS word on Review, moving LOOK, Claude and Backups in (`Features/Review/`, `Features/Settings/`). Core: the settings object fields (`look.*`, `tess.missesGoToClaude`, the folder display name). Builder A: nothing here, though the looks they own are what LOOK cycles.
