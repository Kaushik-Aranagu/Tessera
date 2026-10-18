# 103. Pantry the first time, and the sheet 75 sweep closed

Product's refill (Oct 18, 1:10 AM PT). Docs only; nothing in the app changes. Two parts: the Pantry on its first day, and the four screens sheet 75 still had without a side.

## 1. Pantry, first use (nothing known yet)
The Pantry learns; it is never set up. There is no "add your pantry" form, no scan prompt, no checklist of staples. Before anything is known the page is the quiet form of sheet 78, and each way it fills is a thing the phone already counts.

**Frame (sheet 78):** PANTRY at 52, the day word at 138, the context line at 186, the hero at 212. No title, no back word.
- **Context** is empty on day one (a context line with nothing to say is not drawn; the hero moves up to 186, never a gap).
- **Hero** "Nothing yet" in digits-tier type at `ink` (not `inkSecondary`; it is the answer, not a placeholder).
- **Under it, one plain line** at 55%: "A shop or a cook fills this in." (replaces sheet 78's two-sentence version; one line, no "Clear", and it names both ways in).
- **Groups are not drawn.** No OUT, LOW or USUALLY HAVE labels over nothing. The first label appears with its first line, so the page grows by adding words, never by revealing a skeleton.
- **No illustration, no band, no image.** The page is white space and two lines, with Tess's band holding the only invitation.
- **Tess's line (736 to 820):** `Say "out of milk" and I'll keep it.` It stays until the first thing is known, then gives way to the phone's fact line. It is never repeated after that.

**How it fills (what the user sees, in order):**
1. **Saying it.** "out of milk" lands a ghost row: the label OUT draws in at 296 with "Milk" and its state word, receipt "Milk, out." (thing first), UNDO in the one app-wide UNDO slot (4 s, a new thing). The hero changes to "1 out" and the quiet line leaves. `.made` once; the hero digit just changes (nothing counts up).
2. **Finishing a shop.** Items bought become IN, never listed one by one: the first shop adds a single group, USUALLY HAVE, as one line of names under sheet 78's cap rule ("Rice, coffee and 2 more"). Receipt: "Pantry, 6 kept." with UNDO.
3. **Finishing a cook.** The ingredients it used move to LOW or OUT only where the recipe quantity exceeds what shops added; with no shop history nothing moves and nothing is guessed ("not sure" is a state, not a default). Tess: "Tacos took the cilantro and limes." only when a line moved.
4. **NOT SURE** appears as a group only after the first line exists, and only for things named in a cook the phone has no shop for.
Nothing in this order ever asks a question the phone could answer, and no state is invented: an unknown thing is absent, not "in".

**The side (OUT AND LOW) before anything is out:** at the glance the big fact reads "0" with "out", then "Nothing low"; the full side shows context "Nothing to buy", the key hidden (a key that adds nothing is not drawn), and Tess's band empty (sheet 75 rule 8: a side with nothing to say leaves the band empty). The side word still works; a dead side is never shown, so it opens to the single line "Nothing out or low." and the front word as the way back.

**Index line (sheet 99 section 4):** "Pantry" in Kitchen `areaLean` once Builder A's pass lands (ink until then); its value line reads "Nothing yet" at `inkSecondary`, then "4 out, 2 low" once known.

**Private:** a private item reads "Private item" at 100% ink in every group, the context, the hero count and VoiceOver (G102, sheet 100). The first-use page names nothing, so there is nothing to mask on day one; "Private item, out." is the receipt if the first thing is private. Bare words never mask.

**Motion:** the first group draws in with the house settle (320 ms), the quiet line crossfades out in 150 ms. Reduce Motion and Low Power: a 150 ms crossfade for both. One `.made` for a said item, one `.selection` for a state tap, no haptic when the page fills from a shop or cook (the finishing surface owns that haptic).

**VoiceOver:** order is area word, day, hero ("Pantry, nothing yet"), the quiet line, then groups as they appear. When the first line arrives focus does not move; the receipt is announced once ("Milk, out"). Dynamic Type AX3: one column; the hero wraps; the quiet line may take 3 lines; rows at least 44 pt.

**Acceptance (PF1 to PF6):**
- PF1 With no history, no group label is drawn and the hero reads "Nothing yet" at full ink.
- PF2 The only invitation is Tess's `Say "out of milk" and I'll keep it.`; no form, scan prompt or staples list exists.
- PF3 Saying "out of milk" draws OUT with "Milk" and the receipt "Milk, out." with UNDO.
- PF4 A first shop adds one USUALLY HAVE line, capped per sheet 78; a first cook with no shop history moves nothing.
- PF5 The side on an empty pantry opens to "Nothing out or low." with no key and an empty band.
- PF6 Under Reduce Motion everything crossfades at 150 ms; a private first item reads "Private item" everywhere.

## 2. Sheet 75 sweep: the four screens that had no side
Gap hunt 98 section 5 proposed them; this settles them and extends the table in `every-side.md` (rows 28 to 31). All keep the sheet 75 rules: the word works, the spine stays, no controls on the side, Tess's line only if the phone counted a fact.

| # | Screen | Side (kind) | What it holds | Settled how |
|---|---|---|---|---|
| 28 | Lists shelf | ON THEM (PARTS), as drawn in sheet 87 | RUNNING, OPEN, REUSABLE, EMPTY, one line each with its count; a tap opens the list | Sheet 87 wins over gaps-98's "LAST RUNS". A list's past rides on each line ("Packing, Thursday") so BEFORE is not lost |
| 29 | A list page | WHAT IT HOLDS (FACTS) | its sections with counts ("Clothes 5, Tech 3"), reusable as a word, "last run Thursday" | Private list reads "Private list", sections show counts only, no item words |
| 30 | Put away page | WHAT WENT BACK (BEFORE) | each thing put away and when, thing first ("Dune, put away Tuesday"), newest first, 6 per page by sheet 90 | Reading and processes only; no restore control on the side (restore stays on the front) |
| 31 | Settings page 2 (Your day) | WHAT IS STORED (FACTS) | backups, size, last backup, in plain lines | The front keeps every control; the side only explains. Page 4 Data keeps Back up and Export |

Two notes. Settings' row 21 side (WHAT LEAVES THE PHONE) stays on page 1; page 2's side is the stored half of the same question, so a person asking "what does it keep" and "what does it send" finds one on each. The Put away side takes the R9 wording (audit-ui-bar.md): "X, put away".
