# QA review: #655 (Core, my four 0t must-fixes + lows)

Head: 9dafcb3d. Merge-tree clean on master. 2 files, +169/-7 (TessLineCheck, its tests). Pure function; still unwired.

## Verdict: PASS at 9dafcb3d. All four must-fixes and the lows are in; remaining items are lows.

### Closed, hand-traced
1. Part of day: after judging the relative-day phrases, the line's bare words (morning, afternoon, noon, midday, evening, night) must equal the finish's part (house finish hour, else the day label's) or sit in the rules line; "early" and "late" can never be checked, so they are refused. "Thursday morning, a bench best." on an evening label gives C15; "An evening of 3 exercises..." passes.
2. Unverifiable time: "last week", "this week", "next week", "weekend", "the other day", "recently", "lately", "earlier", "a while", "these days", "this/last month" give C15 unless the rules line holds them.
3. House copy: C5 now catches an em or en dash, "at" before a digit, noon or midnight, uppercase AM/PM and "a.m."/"p.m."; CLOCK enforces "7:40 pm" or "7 pm" (hour 1-12, two-digit minutes under 60, one space, lowercase suffix). "7:40pm", "19:40", "7.40 pm", "8:5 pm" fail; the right clock passes (the 8:5 test row was changed to expect CLOCK, correctly).
4. C13: house list plus a longer list, -ise/-ised/-ises/-ising/-isation stems (US allowlist for exercise, raise, praise, surprise, promise, otherwise...), and -our stems (col, fav, flav, hon, behavi, neighb, lab, harb, hum, rum, vap, arm, endeav, sav, od, parl, splend, vig, ferv, rig). hour, four, pour, your, tour pass.
Lows: a lowercase lift not in the pack's names or title gives C9 ("1 new squat best" with only Bench); "?" at the end of a context line gives C4; PrivateFacts.isWalled on the line is a last belt under C12. L41/L42 now carry the lifts they name (doneWithLifts); that is the right call, since the pack only knows the title and the bests, and a lift outside them was never in Claude's facts.

### Lows (none block enabling)
1. -ising false positives: "promising", "surprising", "praising", "supervised", "devised" end in the stem and are not in iseWords, so a US line using them is refused (fails closed, rules words stay). Add them or restrict the stem rule to -ised/-ises/-isation.
2. Other unverifiable moments pass: midnight, dawn, dusk, sunrise, sunset, lunch, lunchtime, dinner, breakfast, bedtime, "before bed", "this year", "last year". Add them to unverifiable (or midnight to the part words as night).
3. Digits are licensed as values, not by what they count: with 3 exercises and since = 9, "first in 3 days" passes C6. Bind each number to its noun (N days = sinceLastDays, N exercises, N sets, N new best(s)) before Claude Home wording ships widely.
4. "row" (as in "five in a row") and "press" are lift names, so a plain use of them fails C9; fail closed, fine.
5. The final isWalled belt runs with lastWeightKg nil; harmless because C6 already bounds numbers, but pass his weight through when the check is wired.

Note for the enable gate: Core's 0t weekday check is still the condition in memory before Claude Home wording turns on; this PR does not wire anything.
