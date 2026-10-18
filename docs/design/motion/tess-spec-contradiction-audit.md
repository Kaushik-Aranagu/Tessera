# Contradiction audit: lab specs 26-51 against rulings since 4 PM PT Oct 17 (board 54)

Checked against product/decisions.md (master) entries from 12:29 PM Oct 17 on. Result: two fixes made, three items for Design or Product, the rest consistent.

## Fixed in this PR
1. **Lead-change auto-turn haptic.** tess-page-turn-motion.md kept sheet 90 rule 7's `.selection` on an automatic lead-change turn. The 5:30 PM QA contradiction review removed it (R2, no haptic on any page turn; the check's own finish haptic is the only cue). Both lines now say none.
2. **Sides under Low Power.** Already fixed in #927 (Low Power = Reduce Motion, D5).

## For Design or Product (not changed here)
A. **The soul under Low Power.** tess-motion.md section 13 and tess-quiet-versions.md keep a separate Low Power soul (30 fps, six lights, no readers) while D5 says Low Power = Reduce Motion "everywhere". Lab reading: D5 covers screen and side motion; the soul keeps its own Low Power form (cheaper, not still). One yes/no for Design.
B. **Pantry state change receipt.** Spec 36 shows the receipt "Limes, low. Undo". G178 (6:39 PM) says a change that changes nothing writes nothing and shows no receipt and no haptic. Lab reading: spec 36 applies only when the state really changes; a no-op tap plays nothing. Needs one line in the Pantry build note.
C. **CopyList sheet 102.** The lab relayed 240 ms fade + 8 pt rise and a `.made` haptic from Product; the sheet file was not readable. Design to confirm the section in tess-groceries-finish-copylist-motion.md.

## Checked and consistent
Page turn timings (Design's Rotate 460 ms), whose-swipe order (12:46 PM), crisp pockets and never-diffused (12:46 PM, 3:30 PM audit rulings), `.warning` once per failed save and none for information lines (12:45 PM), Pantry state words in ink and lean only on caps labels (Design pantry-lean-99), greyed 42% and "Private item" with no reveal (gaps-98 accepted 5:57 PM), Lacquer Review lean on `sky`, tie rule (4:32 PM, no motion implied), Private workout finish identical (sheet 95), 4 s / 10 s UNDO windows, one `.success` per finish.
