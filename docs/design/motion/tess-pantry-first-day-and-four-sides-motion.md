# Pantry on its first day, and the four sides of sheet 103 (board 83)

Motion rows for Design sheet 103 (`docs/design/pantry-first-use-103.md`, on branch `claude/project-thread-b3tu3f`, Oct 18 1:10 AM). Two parts: the Pantry before anything is known, and rows 28 to 31 of the sheet 75 side table, which sheet 103 settles. Builds on `tess-pantry-lean-notice-motion.md`, `tess-pantry-v2-motion-check.md`, `tess-side-peeks-and-builder-a-decisions.md` (board 43) and the Low Power matrix. Rulings are cited as `DEC:<line>`; lab defaults are marked *(lab default)* and listed in §5. Sheet 103 changes no app code; neither does this one.

Ground rules: LP = RM = one 150 ms crossfade, no stagger, blur or travel; one haptic per moment through `tesseraFeedback`; UNDO 4 s for a new write, 10 s for a change, flat 10 s under VoiceOver, one app-wide slot; receipts name the thing first; a private item reads "Private item" in the same type and motion; the soul behaves identically.

## 1. Pantry, first day
The page is the quiet form of sheet 78: PANTRY at 52, the day word at 138, the context line at 186, the hero at 212, no title and no back word. Nothing is drawn that is not known: no group label over nothing, no skeleton, no illustration. The page grows by adding words.

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Open on day one | the hero "Nothing yet" (digits-tier, full `ink`) and the one line "A shop or a cook fills this in." (55%) arrive with the shared first-visit entrance (35 ms stagger, 14 pt rise; only two elements); the context line is not drawn and the hero sits at 186; Tess's band holds `Say "out of milk" and I'll keep it.` | opacity only | "Pantry, nothing yet", then the quiet line, then groups as they appear | none |
| Say "out of milk" | the label OUT draws in at 296 with "Milk" and its state word, house spring 0.42 s; the quiet line crossfades out in 150 ms; the hero changes to "1 out" with no count-up; Tess "Milk, out." with UNDO **4 s**; Tess's day-one invitation never returns | one 150 ms crossfade for the group, the line and the hero | the receipt is announced once ("Milk, out"); focus does not move; UNDO flat 10 s | **`.made` once** (his touch); UNDO `.undo` alone |
| A private first item | the same, with "Private item" for the word | same | "Private item, out" | same to the frame |
| A first shop finishes | the first group, USUALLY HAVE, draws in as one line of names under sheet 78's cap rule ("Rice, coffee and 2 more"), house spring 0.42 s; the quiet line leaves in 150 ms. Receipt "Pantry, 6 kept." only if he is on the Pantry page when the shop lands, with **no UNDO** (the shop's Done line owns the slot; ruled, lane 83) | one 150 ms crossfade | announced once if he is on the page | **none**: the finishing surface owns the haptic (Groceries Done plays `.done`) |
| A first cook finishes | nothing moves with no shop history; where a line moved, Tess "Tacos took the cilantro and limes." and the line moves group with the 160 ms word crossfade | same | announced once | none (the cook's finish owns it); Tess-initiated, so no haptic or sound after 23:00 and the words wait until he opens the page |
| NOT SURE appears | the group draws in at the foot only once a first line exists and only for things a cook named with no shop for them; house spring 0.42 s | crossfade | read after the other groups | none |
| State tap on a line | the word crossfades 160 ms (as the pantry v2 check) | 150 ms | the word is a button | `.selection` once |
| The Index line | "Pantry" in Kitchen `areaLean` once Builder A's pass lands (ink until then); the value crossfades "Nothing yet" (`inkSecondary`) to "4 out, 2 low" in 150 ms, no roll | same | spoken as the line | none |
| The side before anything is out | opens straight to the full side (a side too small for two stops skips the glance): "Nothing out or low."; context "Nothing to buy"; the key is not drawn; the band is empty. Glance, if shown by the host: "0" with "out", then "Nothing low" | 150 ms crossfade | "Nothing out or low" | `.selection` once on the full side, none for a glance |

Never on the first day: a form, a scan prompt, a staples checklist, a question the phone could answer, an invented state (an unknown thing is absent, not "in"), or a haptic when the page fills from a shop or cook.

## 2. The four sides (rows 28 to 31 of sheet 75)
All ride `SideHost` with no motion of their own. Shared rules (board 43 and `every-side.md` "Two stops"): the body moves 1:1 under the thumb and settles on the house spring over 380 ms; the glance arrives with a 300 ms blur-in and **no count-up**; one `.selection` on the full side, none for the glance; her line is `sideTurned` into stop 1 only and is the same line at both stops; RM and LP are a 150 ms crossfade with no settle and no edge shadow; a count that changes while a side is open just changes; a private item reads "Private item" in the same type and motion. A list row's own horizontal swipe stays its own; the side swipe is the edge zone or a swipe on a name or empty space.

| # | Side | Kind | Arrival | Glance's big fact | Notes |
|---|---|---|---|---|---|
| 28 | Lists shelf: **ON THEM** (sheet 87; ruled: supersedes board 43's LAST RUNS, which is stale) | PARTS | RUNNING, OPEN, REUSABLE, EMPTY arrive with the page, one line each with its count, no stagger | the count and the top part, one glance fact (ruled; the running count first, e.g. the count with "running") | a tap on a line opens that list (the shared open transition, 150 ms crossfade under RM); a list's past rides on its own line ("Packing, Thursday") so BEFORE is not lost |
| 29 | A list page: **WHAT IT HOLDS** | FACTS | sections with counts arrive with the page ("Clothes 5, Tech 3"); "reusable" is a word, no toggle motion | the item count at Hero 56 (board 43) | a private list reads "Private list" and the sections show counts only, no item words |
| 30 | Put away page: **WHAT WENT BACK** | BEFORE | rows arrive with the page, newest first, 6 a page (sheet 90) | the last thing put back, one line, "Dune, put away Tuesday" ("X, put away", audit R9) | reading only: no restore control on the side, restore stays on the front |
| 31 | Settings page 2 (Your day): **WHAT IS STORED** | FACTS | backups, size and last backup in plain lines arrive with the page | the last backup, one glance fact (ruled; the day and time as a plain day word, no relative counting) | every control stays on the front; the side only explains; Settings page 1's side (WHAT LEAVES THE PHONE) stays on page 1; Settings does not ship before Builder A's Low Power flag PR (Product gate) |

- **Paging on a side.** Row 30 is the one side with more than 6 rows, so it pages. Its pages turn with the Settings Page turn word (ruled; default Turn, Rotate only if the side declares its slots) and follow R2 and R3: no haptic on a turn, and under RM or LP a 150 ms crossfade.
- **Tess's line** appears only if the phone counted a fact; a side with nothing to say leaves the band empty (sheet 75 rule 8).

## 3. Quiet hours
Everything here that he touches plays: `.made` for a said item, `.selection` for a state tap and for the full side, `.undo` for UNDO. Everything the phone raises is words only after 23:00: the fill from a shop or cook, the "took the cilantro" line, and any side glance's Tess line. No timer or poll is needed for any of it.

## 4. Tests
1. With no history no group label is drawn, the hero reads "Nothing yet" at full ink, and there is no form, scan prompt or staples list.
2. Saying "out of milk" plays `.made` once and shows "Milk, out." with UNDO 4 s; the hero changes with no count-up.
3. A first shop adds one USUALLY HAVE line and plays no Pantry haptic; a first cook with no shop history moves nothing and says nothing.
4. The side on an empty pantry opens to "Nothing out or low." with no key and an empty band; one `.selection`, no glance haptic.
5. Under RM and LP every moment above is a 150 ms crossfade; a private first item reads "Private item" in the receipt, the hero, the groups and VoiceOver.
6. Sides 28 to 31: no glance haptic, one `.selection` on the full side, no count-up, and the same line at both stops.
7. Grep: none of these screens uses a raw `.sensoryFeedback`.

## 5. Asks
Product and Design ruled asks 1 to 4 (lane 83): row 28 is ON THEM and `tess-side-peeks-and-builder-a-decisions.md` is stale on LAST RUNS; "Pantry, 6 kept." shows only on the Pantry page with no UNDO; rows 28 and 31 each get one glance fact; row 30 uses the Settings Page turn word; the house spring (0.42 s) wins over the sheet's "320 ms". The list is kept as the record.

1. **Product:** row 28 is ON THEM. Done.
2. **Product:** "Pantry, 6 kept." Done.
3. **Product:** glance facts for rows 28 and 31, and row 30's page turn word. Done.
4. **Design:** 320 ms against the house spring. Done: the spring wins.
5. **Builder B (when built):** the Pantry day-one page and the four sides; Settings page 2's side waits for the flag PR.
