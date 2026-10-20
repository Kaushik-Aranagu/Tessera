# Backups restore line (Design item 111)

Product rulings (huddle, Oct 19): plain, date first. One quiet screen under Settings > Backups; no cards, no pills, no red.

## What is shown
- The list of backups, newest first, one line each, 21 pt ink: "20 Oct, 8:14 AM". Under it, one line in `inkSecondary` 16: "412 objects". The newest one carries no extra mark.
- Tap a row: the same page turns to that backup. One sentence, 21 pt: "Restore the 3 Oct backup? This replaces what is on this phone now." Under it, in `inkSecondary` 16, one line each:
  - "In it: your objects, links, views and settings."
  - "Not in it: the Claude key, the bookmark, flags, Claude spend, Health and calendar copies."
  - "Private words stay walled in every copy."
- Two value words at the foot, 44 pt each, `labelWord`: "Restore" and "Not now". "Restore" is not styled differently (no cobalt: it is the only thing here that can lose data, so it is plain ink and needs one more tap: it turns into "Replace what is here" in place; tapping that restores).
- The restore stamps the date on the Day log's footer line: "Restored the 3 Oct backup." (one line, `inkSecondary`).

## Refusals and edge cases
- A backup from a newer app: the row reads "This backup is from a newer Tessera." in `inkSecondary` and has no Restore word; nothing else changes.
- An unreadable backup: "This backup could not be read." Same treatment.
- After a restore the Claude key question returns only if the answer was not given (sheet 106).
- No backups yet: one quiet line, "No backups yet. One is made each night." (only if that is true in the build; else "No backups yet.").
- Never: a progress bar, a count of changes, a "Are you sure?" dialog (the two-step word is the check), a success screen.

## Motion, accessibility
- The page turn is the standard one; Reduce Motion: a 150 ms crossfade. One soft haptic when the restore is done, none on the first tap.
- VoiceOver on the first Restore tap: the word becomes "Replace what is on this phone, button" and VoiceOver announces "Restore the 3 October backup? This replaces what is on this phone now." when the page turns; focus moves to the sentence, then the two words.
- VoiceOver: the row reads "3 October backup, 412 objects"; the replace word reads "Replace what is on this phone, button".
- Dynamic Type: the sentence wraps, the two words stack at accessibility sizes.
