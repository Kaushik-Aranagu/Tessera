# 106. The Claude gate: the key question, the Sent rows, the willSend line and the restore offer

**Ask (Product, Oct 19, release 22 gate):** draw the four places where Tess and Claude meet the user's consent, in this order: (1) the key question, (2) the Sent rows, (3) the willSend line, (4) the restore offer. Builds on 80 (what was sent, D1 and D2), 93 (Settings), 99 reading layouts (`read` 21, 330 pt), 100 (Today words), 75 (every screen has a side). Spec only. Rulings from Product that bind this sheet: a key found on a fresh store asks once and nothing goes to Claude until he taps Yes; an unanswered setting always reads No; Later writes nothing and the question returns on the next cold launch with one Now line; the words are Builder B's ("Claude key found. Not used yet." and "Use the Claude key still on this phone?" with Yes, No, Later). **No key text ever shows: only yes or no that a key is present.**

## 1. The key question (shown once; gates the release)
- **Where:** Settings, Claude section, first line. And on the next cold launch, while the answer is unanswered, ONE Now line from Tess in cobalt `voice` 21: "Use the Claude key still on this phone?" It carries no buttons of its own: the three words are on the Settings line, and the Now line opens it on a tap (the page turns to Settings, Claude, per ClaudeWhere).
- **The Settings block** (top to bottom, no card, a hairline above):
  - Status line, 21 ink: "Claude key found. Not used yet."
  - The question, 21 ink, one line more: "Use the Claude key still on this phone?"
  - Three ink words on one row, 44 pt each, 21 strong: **Yes**  **No**  **Later**. Yes in ink, No and Later in inkSecondary; no pills, no filled button. Order is fixed (Yes, No, Later) so the thumb finds them.
- **After the answer:**
  - Yes: the block becomes the normal Claude section; one soft `.success` haptic; Tess line "Using the Claude key." once; "Tess asks Claude" reads Yes.
  - No: the block becomes "Claude key found. Not used." and a single ink word **Use it** (so No is never a dead end); nothing is sent; the question never returns by itself.
  - Later: nothing is written. The block stays as is; the question returns on the next cold launch with the one Now line, and not before (no nag inside a session).
- **Unanswered always reads No** in the Tess asks Claude row and in every gate (SecretWords refusal, capture-miss, plan wording): until Yes, every Claude path is closed, and the row's value says "No" in inkSecondary with the sentence "Waiting on your answer." under it.
- **Never shown:** any character of the key, its length, its prefix, a masked run of dots. The only key word is "found" or "No Claude key yet.". VoiceOver reads the same lines; the three words are buttons with the hints "Uses the Claude key", "Does not use it", "Asks again next time you open Tessera".
- **Side (sheet 75):** WHAT THIS DOES: "Yes lets Tess ask Claude about phrases she cannot read. Notes, places, health and money never go. You can turn it off any time." Plain, `read` 21, 330 pt.
- **States:** no key (the old line "No Claude key yet." and the field hint), found and unanswered (above), yes, no, later. AX: the three words stack, one per row, 44 pt. Reduce Motion: the block crossfades 150 ms.

## 2. The Sent rows (receipts as built in #1110, plus what ships)
- **The row:** the receipt line ("6:12 pm - Plan my day - Sonnet - 1.2c") then, under it, the words that went, in inkSecondary `read` 21, in curly quotes; a walled phrase reads **Private phrase** plain, unquoted, at 100% ink (a Private label rule). One VoiceOver element per row.
- **Long phrase:** the words stop at 4 lines; the rest is on the row's side (tap opens the full words in `read`, 330 pt, with the date and job). Never more than 4 lines in a list.
- **Held back:** one line above the list when above zero, inkSecondary: "3 requests held back on this phone". Never a count of misses elsewhere.
- **Clear what was sent:** an ink word, inkSecondary, 44 pt, below the list; it deletes the words and keeps the spend. One soft haptic; the word fades into "Cleared what was sent." in cobalt under the house spring (150 ms crossfade under Reduce Motion). No UNDO (ruling G653). The list then reads "Nothing has gone to Claude yet." only if the spend rows are gone too; otherwise the rows stay without words.
- **Empty:** "Nothing has gone to Claude yet." with no Clear word.
- **Side:** WHAT EACH JOB SENDS (from 80): the job names with what each sends.

## 3. The willSend line (the moment before a phrase goes)
- One Now line from Tess in cobalt `voice` 21: "Asking Claude." with one ink word **Cancel** at the right, 44 pt, while the call runs. The call has a hard 8 s cap; at 8 s the line becomes "Couldn't reach Claude." and Cancel goes.
- It appears only for a phrase that is going (never for a walled one, which stays on the phone and says so: the capture-miss line). A pasted recipe page says "Reading <host>." first, then "Asking Claude to read the recipe." at the handoff (sheet on link fetch).
- On success the line becomes the answer and the receipt "Sent that to Claude. Turn this off in Settings: Claude." appears once, with the masked words ("Private phrase" for a walled one, which never sends).
- Cancel: the line says "Cancelled." and nothing is recorded as sent. Reduce Motion: the line swaps by a 150 ms crossfade. One haptic at the answer, none at the start.
- Offline: "Couldn't read that offline. Try again online." with his text left in the box (never queued for a walled phrase).

## 4. The restore offer (second priority)
- **When:** the first launch after a reinstall that finds a backup copy in iCloud Drive/Tessera and an empty store. One Now line from Tess: "A copy from <date> is on this phone's iCloud Drive. Restore it?" with the ink word **Restore** and **Not now**; both 44 pt.
- **Restore:** goes to Review, Backups, with the copy already picked, shows the existing "A restore is waiting" page (it replaces everything the next time Tessera opens) and the existing Cancel restore word. The Claude key does not come back with a copy (it never leaves the keychain), so after a restore the key question in section 1 appears if a key is found, else "No Claude key yet.".
- **Not now:** the line goes; Settings, Backups keeps a **Restore** word. It is not asked again by itself.
- **Never:** the offer never restores without a tap, never lists file names or sizes in the Now line (the date only), and never shows anything private.
- **Side:** WHAT A RESTORE DOES: replaces everything, keeps the current store as "Before restore <date>", never includes the Claude key, your flags or the folder bookmark.

## Never (all four)
Pills or boxes around Yes, No, Later; a key character or its length on any screen; a count of misses; "Enabled/Disabled"; a sound; a toast; italics; a faded Tess; a fourth size on these screens (21, 16 labels, 44 for a page title only).
