# QA review: #652 (Core 0t, TessLineCheck + pack numbers)

Head: 56e7deff. Merge-tree clean on master. 4 files, +835/-3: TessLineCheck.swift (new, pure, no clock, network or store), HomeDonePack.numbers (+rules-detail digits), tests (L-rows, HD rows, house-day cases). Nothing calls TessLineCheck yet, so no Claude wording can show from this PR.

## Verdict: PASS at 56e7deff to merge (engine only, no surface), with four items that must land before Claude Home wording turns on

### What I checked and found sound
- Shape C2-C5 from HomeLines caps (6 words/32 chars, no stop on context; 14/80 with one stop on detail); marks `!`, `…`, ` · `, newline, emoji; empty line is `.noLine`, not a failure; a fixed item fails C14 even for the rules words.
- Digits are compared as values (C6) and must survive (C7), with D2's whole-clock drop only on a done context and never a partial clock. HomeDonePack.numbers now adds the digits of HomeLines.detail (counts of exercises, sets, "1 new best"), which are facts, never title digits (W14 still holds: test row updated to add 1 only).
- C9 capitalised names, C10 grading, C11 praise, C12 off limits (health, money, places, "$£€", title words excepted, "steps" for a cook), HOUSE ("record"), GREET, NOREPEAT, SECRET (secret word or key shape). C15: "usual", "usually", "after work", "before work" refused outright; a done line may name only the finish's house-day weekday (4 am turnover, so 12:30 am Friday is Thursday); relative-day words are checked against the house-day gap and the finish's part of day ("tonight" needs an evening or night finish, "yesterday" and "last night" only once the day has turned, "tomorrow" never). A word the rules line itself uses is always allowed. HD1-HD21 and the relative-day tests assert these.
- The only data in a prompt is the pack, so a returned line cannot leak what the pack lacks; C6 and C12 stop invented numbers and words.

### Must-fix before Claude Home wording turns on (none blocks merging this unwired check)
1. Part-of-day words are unchecked. C15 verifies the weekday and "this morning/afternoon/evening", "tonight", "last night", but a bare "morning", "afternoon", "evening", "night", "noon", "midnight", "early" or "late" is not compared with the finish. Label "Thursday evening", line "Thursday morning, a bench best" passes. Add: any part-of-day word must match the day label's part or appear in the rules line.
2. Other time phrases are unchecked: "last week", "this week", "next week", "weekend", "the other day", "recently", "lately", "earlier this week". With since = 6 days, "first since last week" can be right or wrong depending on the weekday; the facts do not support it. Refuse them on a done line unless the rules line holds them.
3. House copy rules the check does not enforce: no em dash or en dash in strings (Product 5:57 PM; C5 lists only `!`, `…`, ` · `, newline, emoji), no "at" before a time, lowercase "pm"/"am" only, no "a.m.", "p.m." or uppercase. Add "—" and "–" to C5 and a clock-format code (a digit-clock must match HouseTime.clock's shape: "7:40 pm").
4. C13 is a short whole-word list (mum, colour, favourite, organise, realise, apologise, centre, programme, flavour, honour, behaviour). "organised", "realised", "colours", "favourites", "metre", "litre", "grey", "whilst" pass. Extend, or match -ise/-ised/-our/-ours stems.

### Lows
1. Add PrivateFacts.isWalled(text, lastWeightKg:) on the returned line as a last belt (the check is pure, so thread the weight in as an optional).
2. Licensed numbers are values, so a stray "1" anywhere is licensed once "1 new best" is in the pack ("1 day"); C7 and C9 bound it. Acceptable.
3. C9 only reads capitalised words; a hallucinated lowercase name ("squat best" when the pack has only Bench) passes. A correctness, not privacy, gap; add if the eval shows it.
4. Context lines ending in "?" pass C4 (only `.`, `:`, `;`). Fold into C5.
