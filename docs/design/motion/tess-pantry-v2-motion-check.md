# Pantry v2 motion check against Kitchen's PE rows (board item 61)

For: Kitchen lead (rows to fix), Builder B (Pantry screens), Builder A (haptics), QA. Written Oct 17, PM (Pacific). I checked my Pantry motion (`tess-pantry-lean-notice-motion.md`, items 36, 37, 41, 42, now corrected) and Design's sheets 78 and 98 against Kitchen's PE group (`kitchen-pantry-v2-acceptance-pe.md`, PE01 to PE29) and the walk script's PD, PW, PP, PO and PR groups (`kitchen-pantry-v2-walk-script-oct18.md`). Static read; the code read is master `eaa4c305` (`PantryView.swift`, `PantryFront.swift`), which has the v1 front only: name tap, left swipe, no state-word tap yet. Rules checked: ink state words (G175 Reading B), a tap that changes nothing writes nothing (G178), one UNDO slot (U3, PG55).

## Result in one line
The motion holds against the PE rows. Three things in my own spec were wrong or loose and are corrected in the same PR; five Kitchen rows still read the superseded ochre/lean wording and need a rewrite; one haptic question is open for Product.

## Rows that bind motion, and how each reads
| Row | What it says | My motion | Result |
|---|---|---|---|
| PE02, PR06 | greyed CAN COOK, tap: Tess's empty line 4 s, no UNDO, no haptic, word stays greyed, nothing re-sorts | item 41: the page wakes only when a first state lands (420 ms rise); a greyed tap is a line only | Pass |
| PE15 (G178) | a tie that changes nothing writes nothing, no receipt, no haptic | item 36: a real change only; nothing plays on a tie | Pass. Plain list of "nothing" cases below |
| PE21 | `out` becomes `in` while the page is open: the line leaves with `.tesseraAnimation` | item 36: closes up 320 ms; in Reduce Motion and Low Power one 150 ms crossfade | Pass |
| PE22 | Reduce Motion on the swipe and the leave: no spring, value just changes | 150 ms crossfade (the house number, `MotionPolicy.reducedMotionFade`) | Pass, wording: "just changes" means the 150 ms fade, not a hard cut. Kitchen to word it so |
| PE09 | a mixed phrase is one op, one UNDO slot, state per item | the slot is one; the receipt is the first changed name ("Milk and 2 more, out. On Groceries.", PE11) | Pass |
| PW01, PW02 | cycle in, low, out, in; one op per tap; receipt "Limes, low." etc. | corrected: the receipt carries no UNDO word of its own | Fixed (was "Limes, low. Undo") |
| PW04 | UNDO after a tap: the row returns and Tess's cook line returns | item 36 now says the row opens its slot over 320 ms and her line blurs back in 300 ms | Fixed (was unspecified) |
| PW06 | hero "4 out, 2 low", never "0 out" | corrected: the digits just change (sheet 78: "nothing counts up"); my sheet had them roll one step at a time, which is counting | Fixed. A segment appearing or leaving, or "Nothing out", crossfades the hero string 220 ms |
| PW08 | an empty group draws nothing, not even its label | line and label leave together (320 ms, label fade 200 ms); a first line opens both | Added |
| PG53, PG55 | UNDO 4 s for a row added, 10 s for a state change, 10 s under VoiceOver for both; a second receipt replaces the first note and its UNDO, the first op stays done | one slot, in-place crossfade, never stacked | Pass (windows now stated in item 36) |
| PP01 to PP03 | private line: same type and place, no tap target on the name, no reveal; a swipe still adds, receipt "Private item, on Groceries." | identical motion and haptic; the state word still cycles (sheet 98); a name tap opens nothing | Pass. One honest difference: only the non-opening of a tap, ruled (R12) |
| PW14, PG20, PG22 | already on Groceries or in the basket: an information line, no UNDO | no haptic (master plays `.made` only for a real add, `PantryView.swift:104`), the swiped line settles back 320 ms on the house spring (150 ms crossfade in RM and LP), no row appears | Pass |
| PW15 | failed write: "Didn't save that. Try again.", one soft warning, not on an immediate repeat | item 42 | Pass |
| PW19 | recipe page peek words: `have` 42% ink, `low`, `out` ink, `used` during a cook | a word that changes while the page is open crossfades 160 ms in place; nothing animates for unknown or a staple | Added to item 36's rules |

## The cases where nothing plays (one list, so a builder can test it)
No motion, no receipt, no haptic: (1) a tie between a clear and a phrase that changes no field (PE15); (2) a backdated check older than the stored state (PE16); (3) a phrase for something already in that state with its row open and nothing to add (PG20, an information line only: "Milk, already on Groceries.", no UNDO, no haptic); (4) an unknown line, which has no tap target (R15, PW05); (5) a tap on a private name (nothing opens). A greyed CAN COOK tap is an information line only (4 s, no UNDO, no haptic).

## Kitchen rows that still read the superseded wording (for Kitchen to fix)
G175 closed Reading B (6:39 PM): state words are ink; `areaLean` colors only caps labels and the index line. The walk script's PO group still grades the old reading:
- **PO01, PO02**: "state word equals `areaLean(.kitchen)`" should read "state word is ink (the look's ink); `areaLean` appears only on caps labels and the index line".
- **PO03**: fine as written (no ochre literal), keep.
- **PO05**: "resting colour of text only" is true for the labels; the out ring stays ink at 42% (kept).
- **PO06**: "index line ink unless Design says otherwise" is the current state; no change.
- **PO07**: the 4.5:1 contrast check applies to the lean on caps labels now, and to ink words trivially.
- **PO08**: keep (weight and position, never colour alone).
- Sheets 78 and 98 still describe the "in" word as the pantry colour at 72% with ink; Design amends (sheet 99 is the ruling).

## Open for Product
The Pantry swipe on a line and a tap on a name in USUALLY HAVE both add a grocery. Sheet 98 says "Haptics: `.selection` on a state tap; nothing else", while master plays `.made` for a real swipe add (`PantryView.swift:104-161`, "Design on #727"), and the haptic map says a grocery that lands is `.made`. Lab recommendation: keep `.made` once for a real add, none for the already-on lines; Design's "nothing else" reads as "no other haptics on the state tap". One word from Product.

## Tests (names for Builder B)
`aTieWritesNoReceiptAndPlaysNoHaptic`, `heroDigitsChangeWithoutCounting`, `aSecondReceiptReplacesTheFirstUndoInPlace`, `undoReturnsTheRowAndTessLine`, `anEmptyGroupLeavesWithItsLabel`, `aLineMidCloseHasNoTapTarget`, `aPrivateLineMovesLikeAnyOther`, `alreadyOnGroceriesPlaysNoHaptic`.
