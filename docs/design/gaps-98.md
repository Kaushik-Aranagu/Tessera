# 98. Gap lane: Pantry v2 states, Lacquer roses, error states, side-swipe holes

Product's list of Oct 17 (5:50 PM PT). Specs only; no studies, the Mac is offline. Nothing in the app changes.

## 1. Pantry v2, the front states (R1 to R20, ruled)
Builds on sheet 78 (the front: counts hero, OUT, LOW, USUALLY HAVE) and on Research's pantry v2 spec. The new thing on the front is **what each line can say**, because state is now stored (R1, R2) and unknown is a real state.
| State | The line | Right word | Look |
|---|---|---|---|
| out | "Limes" | **out** (700) | the faint ring from the recipe page, 11 pt; name in ink |
| low | "Rice" | **low** (600) | no ring; name in ink |
| in | "Eggs" | **in** (400, Kitchen lean at 72% with ink) | only under USUALLY HAVE as names, never as lines |
| unknown | "Cilantro" | none | no word, no ring, name at 55%, below the three groups under "NOT SURE" only on the side (see below); on the front it appears nowhere |
- **Unknown has no tap target on the front (R15).** Its first state comes from Tess ("out of cilantro"), a clear or a cook. The line is never a button that asks him to set it.
- **Greyed:** with no state anywhere on the phone (day one), the hero reads "Nothing yet" and CAN COOK on the Kitchen shelf is greyed at 42% (R6); a tap says Tess's empty line, 4 s, no UNDO. Greyed means 42% ink, never a different hue.
- **A private line (a medicine or body ingredient said as out, R7)** reads "Private item" in the same type and place as any line, with its state word, ring included. **It is not tappable and has no reveal (R12, G102).** One tap on its state word still cycles it like any line (the tap changes state, it shows nothing). The receipt is "Private item, out. On Groceries."
- **USUALLY HAVE (R14):** up to four names if they fit one line, else "Rice, coffee and 2 more" with "and 2 more" at 55%.
- **Counts never lie:** hero digits count out and low only; unknown is never counted ("4 out, 2 low").
- **The side declares itself** (sheet 75): OUT AND LOW (AHEAD) as in sheet 78, with a second page NOT SURE (FACTS) listing unknown names at 55%, no counts, no keys. Way in: right edge or the word; Reduce Motion a 150 ms crossfade.
- **Haptics:** `.selection` on a state tap; nothing else. No haptic for greyed.

## 2. Lacquer: do Training and Review roses read apart?
No. Mixed 72% with ink on the Lacquer ground, Training (#F4A5B3) is hue 349° and Review (#E0B8C0) is hue 348° at the same lightness: the same pink. **Fix: on Lacquer only, Review's lean uses the look's `sky` pigment** (#A6BCD6) in place of `context`: #BCC8D6, hue 212°, 11.49:1 on #130A0D. Every other look keeps `context`. The Review context line itself stays rose; only the label, key word and numeral take the blue. Sheet 92's watch item is closed.

## 3. Habits front and side (E5)
Already drawn: sheet 85 (`habits-85.md`, board `mockups/habits-85.png`, clip `recordings/habits-85.mp4`): the front, the side LATELY and its second page HOW IT COUNTS. Nothing to add. (Pending the app build only.)

## 4. Error and offline states for Settings (sheet 93)
The rule everywhere: a write that did not save says **"Didn't save that. Try again."** once, with the one soft `.warning` haptic (Haptic.notSaved), and the line is the retry.
- **A setting that did not save** (quiet hours, day starts, page turn, Tess asks Claude): the row keeps its old value and shows it; under the row, one line in ink: "Didn't save that. Try again." A tap on the line retries; it clears after 10 s or on a good write. No red, no icon.
- **Tess asks Claude on, but offline:** the row stays "On". The line under it reads "No connection. Tess works on your phone." (information, not a failure: no haptic, no retry). Nothing is queued or sent later.
- **Back up fails:** "Didn't save that. Try again." under Back up, the old time kept ("Today, 9:02 am"), the one haptic.
- **A key problem** never prints key parts: "That key didn't work." (information, no haptic). The key itself is never shown.
- **Delete everything** has no error state of its own: a failure keeps everything and uses the same line.
- Offline never greys a setting. Only the lines above change.

## 5. Gap hunt: screens with no declared side swipe (sheets 75 and 97)
Sheet 75's table has 27 rows plus the "designed but not built" list. Screens in the app that have **no declared side**, with a proposal for each:
| Screen | Proposed side | Kind |
|---|---|---|
| Lists shelf | LAST RUNS: the lists that were run (checked off) lately, "Packing, Thursday" | BEFORE |
| A list page | WHAT IT HOLDS: sections and counts, "Clothes 5, Tech 3"; reusable flag as a word | FACTS |
| Put away page | WHAT WENT BACK: each thing put away and when | BEFORE |
| Groceries shelf aisle pages | none: the Groceries side (FOR WHAT, 14) already covers it; the paged turn is vertical | (declared) |
| Settings (sheet 93) | WHAT LEAVES THE PHONE already (row 21); add page 2 WHAT IS STORED: backups, size, last backup | FACTS |
| Pantry | OUT AND LOW (sheet 78) with NOT SURE as page 2 | AHEAD / FACTS |
| Habits | LATELY and HOW IT COUNTS (sheet 85) | declared |
| Done hero (sheet 95) | THE SETS (row 12) | declared |
| Day log | THE DAY (sheet 82) | declared |
| Shutdown | TOMORROW (a peek) | declared, not built |
| Body weight, Money, A book, A person, A chore | in the "designed but not built" list | declared |
| Home Now | THE DAY (row 1, 2) | declared |
| Ask slot (the bar open) | none: it is a sheet over the screen; side swipe is not offered | (excluded) |
| Plan my day | THE DAY (row 1, 2) | declared |
Holes: **Lists shelf, a list page and the Put away page** are the three with nothing declared. Settings has its row 21 side but no page 2.

## G175: Pantry colour, one answer (Oct 17, 6:45 PM PT)
- **Ochre is removed from the Pantry spec.** Pantry state words (OUT, LOW, IN, NOT SURE) are plain ink, OUT heavier than LOW by weight (as built in #917), never #A4601A / #E3A857. Kitchen's `areaLean` stays on the caps labels and the index line. This settles G175's Reading A or B: B.
- **Where a fixture row names a colour for a Pantry label or index line, it is the 72% mix, not the pigment.** On Porcelain that is **#126E52** (6.22:1), not #12936A. Obsidian uses #72DCB1 (12.59:1). All five looks are in the table on sheet 92 and sheet 99. Research should fix the fixture rows to the mixed value.

## GL19 and GL15: Groceries with a full basket, and Voice Control names (Oct 17, 9:50 PM PT)
- **GL19: yes to the default.** Tess's one line with UNDO sits in her slot **directly above the key row**, UNDO at its right, and **never over a row**. The rows scroll under a ground fade above the line, so a full basket (any number of struck rows) pushes nothing past the key. The line wraps to two lines at larger sizes and the slot grows upward; the key row never moves. The 64 pt UNDO target (88 pt from AX1) is shared with cook mode.
- **GL15: names yes, with one rule from G229.** A key's accessibility label equals its visible word, so Voice Control's "Tap <word>" works: "Tap Clear the basket" (a tap key) runs it. A **hold key** is named-action-only (clock page ruling in sheet 69): "Tap Done" and "Tap Reset" speak the hint "Hold to finish" / "Hold to reset" and do not complete; Voice Control completes them by the action's name, "Finish" and "Reset". So the fixture's expected results are: "Tap Clear the basket" completes; "Tap Done" and "Tap Reset" do not complete and speak the hold hint; "Finish" and "Reset" complete. Switch Control lists the same actions.
