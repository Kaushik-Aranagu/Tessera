# AI-5 Home lines eval: person scores

Scored Oct 16, 2026 by AI architecture against the rubric, the fixtures and Research's Oct 16 rulings (time words, receipts, Voice). Research reviewed the Voice column. Raw results: `home-lines-eval-results.md`.

## How each row was scored

- **Memory the model saw (memory pass).** Told: "You train after work on weekdays.", "You cook on Sunday and Wednesday." Noticed from day 2: "You usually train after work." (no clock). Recent: the last 7 day lines. Sessions ran about 6 to 7:05 pm on days 1 to 6 and 8 to 9:05 pm on days 8 to 13. Days 6 and 13 are Saturdays. Days 7 and 14 are rest days with a cook planned tonight.
- **Memory the model saw (gate pass).** Only E5, E6 ("You usually train 6 to 8 pm."), E7, E18 (cooks on Sundays), E9 (shops Saturdays), E15 (told "great job") and E17 (told "after work on weekdays") carry memory. E2, E12, E16, E20 carry none, so any "usual" there is invented.
- **True.** Every word from the pack. "usual" fails when no memory line fits today (Saturday, or no memory at all). Time words per Research: 4 am day, "this evening" until 9 pm, "tonight"/night from 9 pm, 4 to 7 am "early this morning". A done session at 6 to 7:05 pm is "this evening", not "tonight". Cook "tonight" is left alone (the phone's own hero says "Chili tonight" from 5 pm, open in the sweep).
- **Plain.** Fails a riddle, a clipped telegram or a cut-off phrase.
- **Not repeating.** Fails when the line restates the hero (the routine name, "done" in other words, a bare time of day) with nothing added. A line equal in facts to the rules line passes (rubric: equal is fine).
- **Tone.** Fails praise, a judgment, or telling him what to do.
- **Voice (Research ruling, Oct 16).** Passes only if the line adds a true fact the rules line lacks, and is plain and kind. "your usual slot", "as usual" and a restated time of day are filler and fail; a truth slip fails Voice too.
- **Value column (for the added-value count).** A = adds a true fact the rules line lacks; R = rules facts reworded; F = filler; X = false. On planned items, "after work" or "this evening" for a session not yet done is counted as A (it comes from memory); on done items the time of a session already shown as done is F.
- **Research ruling on Voice, Oct 16 (applied).** A half-filler line fails Voice even when the other half is true: every "usual", "as usual" or restated time of day ("this evening") is N, planned or done. A bare "after work", true for that weekday, would pass. Rows flipped by this ruling say so in their Why, and their value is F.

## Summary: rubric rows per model per pass

| Pass | Model | Shown | True (100%) | Tone: scolds or greets (0) | Plain (90%+) | Not repeating (95%+) | Voice (80%+) | Person rows |
|---|---|---|---|---|---|---|---|---|
| memory | claude-haiku-5-5 | 78 | 53/78 (68%) FAIL | 3 FAIL | 61/78 (78%) FAIL | 59/78 (76%) FAIL | 0/78 (0%) FAIL | FAIL |
| memory | claude-sonnet-5-5 | 46 | 43/46 (93%) FAIL | 0 pass | 44/46 (96%) pass | 45/46 (98%) pass | 1/46 (2%) FAIL | FAIL |
| gate | claude-haiku-5-5 | 38 | 25/38 (66%) FAIL | 0 pass | 37/38 (97%) pass | 38/38 (100%) pass | 3/38 (8%) FAIL | FAIL |
| gate | claude-sonnet-5-5 | 7 | 7/7 (100%) pass | 0 pass | 7/7 (100%) pass | 7/7 (100%) pass | 7/7 (100%) pass | pass |

## Added value per model per pass

| Pass | Model | Returned | Equal to rules (not shown) | Caught (not shown) | Shown | Adds a true fact | Rules facts reworded | Filler | False |
|---|---|---|---|---|---|---|---|---|---|
| memory | claude-haiku-5-5 | 99 | 1 | 20 | 78 | 0 | 3 | 50 | 25 |
| memory | claude-sonnet-5-5 | 99 | 52 | 1 | 46 | 1 | 4 | 38 | 3 |
| gate | claude-haiku-5-5 | 118 | 68 | 12 | 38 | 3 | 1 | 21 | 13 |
| gate | claude-sonnet-5-5 | 120 | 110 | 3 | 7 | 7 | 0 | 0 | 0 |

Gate counts for Haiku cover both slots (118 returned lines over 60 items); 118 minus 68 equal minus 12 caught is 38 shown. Sonnet gate: 120 minus 110 minus 3 is 7 shown. Haiku memory: 99 minus 20 caught is 79 returned and kept, of which 1 equals the rules line, so 78 shown.

## Memory pass, claude-haiku-5-5: shown lines scored

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | d1m1 | w1 | context | Push A today. | this evening, after work | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d1m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d2m1 | w1 | context | Pull A today. | after work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d2m2 | w1 | context | Pull A done. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d3m1 | w1 | context | Legs A today. | this morning, before work | N | Y | Y | Y | N | puts the session this morning; told and noticed say after work; Voice: false line |
| 1 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d3m2 | k1 | context | Chili cooked. | tonight, Chili | Y | N | N | Y | N | only the time and the title the hero already shows; Voice: no new fact |
| 1 | d4m1 | w1 | context | Push A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d4m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d5m1 | w1 | context | Pull A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d6m2 | w1 | context | Pull A done. | this evening, after 3 exercises | Y | N | Y | Y | N | "after 3 exercises" is a riddle; Voice: no new fact |
| 1 | d7m1 | w1 | context | Rest day. | Nothing scheduled, no clock time | N | N | N | Y | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; "no clock time" is jargon; Voice: false line |
| 1 | d8m1 | w1 | context | Legs A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d8m2 | w1 | context | Legs A done. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d9m1 | w1 | context | Push A today. | this morning, Push A | N | Y | N | Y | N | puts the session this morning (memory says after work) and repeats the routine name; Voice: false line |
| 1 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best this evening | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 1 | d10m1 | w1 | context | Pull A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d11m1 | w1 | context | Legs A today. | this morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 1 | d11m2 | w1 | context | Legs A done. | Tonight, after work, done | Y | N | N | Y | N | clipped telegram ending in the hero's "done"; Voice: no new fact |
| 1 | d12m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d13m2 | w1 | context | Pull A done. | Tonight, after a clean Pull A | N | Y | N | N | N | "clean" is invented praise; repeats the routine name; Voice: false line |
| 1 | d14m1 | w1 | context | Rest day. | Nothing scheduled, a slow start | N | Y | N | N | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; "a slow start" reads as a judgment; Voice: false line |
| 1 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d1m1 | w1 | context | Push A today. | This evening, after work | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d1m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d2m1 | w1 | context | Pull A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d3m1 | w1 | context | Legs A today. | this morning, before work | N | Y | Y | Y | N | puts the session this morning; told and noticed say after work; Voice: false line |
| 2 | d3m1 | k1 | context | Chili tonight. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d3m2 | k1 | context | Chili cooked. | this evening, Chili | Y | N | N | Y | N | only the time and the title the hero already shows; Voice: no new fact |
| 2 | d4m1 | w1 | context | Push A today. | after work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d4m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d5m1 | w1 | context | Pull A today. | this morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 2 | d6m2 | w1 | context | Pull A done. | tonight, after a full session | N | Y | N | Y | N | session ran 6 to 7:05 pm; "tonight" starts at 9 pm under the time-word rule; restates the hero's "done"; Voice: false line |
| 2 | d7m1 | w1 | context | Rest day. | Nothing scheduled today | N | Y | N | Y | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; Voice: false line |
| 2 | d7m1 | k1 | context | Dal tonight. | This evening, your cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d8m1 | w1 | context | Legs A today. | this morning, before work | N | Y | Y | Y | N | puts the session this morning; told and noticed say after work; Voice: false line |
| 2 | d8m2 | w1 | context | Legs A done. | tonight, after a full session | Y | Y | N | Y | N | restates the hero's "done" in other words; Voice: no new fact |
| 2 | d9m1 | w1 | context | Push A today. | this morning, Push A | N | Y | N | Y | N | puts the session this morning (memory says after work) and repeats the routine name; Voice: false line |
| 2 | d9m2 | w1 | context | Push A done. Bench press best. | Tonight, a bench best | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 2 | d10m1 | k1 | context | Chili tonight. | Tonight, your usual cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d10m2 | w1 | context | Pull A done. | Tonight, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d10m2 | k1 | context | Chili cooked. | Tonight, your usual cook slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d11m1 | w1 | context | Legs A today. | this morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 2 | d11m2 | w1 | context | Legs A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d12m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d12m2 | w1 | context | Push A done. | Tonight, after the session | Y | N | N | Y | N | restates the hero's "done" in other words; says nothing a reader can use; Voice: no new fact |
| 2 | d13m2 | w1 | context | Pull A done. | this evening, your usual slot | N | Y | Y | Y | N | Saturday: told line says after work on weekdays (E17 trap); Voice: false line |
| 2 | d14m1 | w1 | context | Rest day. | Nothing scheduled, rest up | N | Y | N | N | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; "rest up" tells him what to do; Voice: false line |
| 2 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d1m1 | w1 | context | Push A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d1m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d2m1 | w1 | context | Pull A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d2m2 | w1 | context | Pull A done. | Tonight, after work | N | Y | Y | Y | N | session ran 6 to 7:05 pm; "tonight" starts at 9 pm under the time-word rule; Voice: false line |
| 3 | d3m1 | w1 | context | Legs A today. | this morning, before work | N | Y | Y | Y | N | puts the session this morning; told and noticed say after work; Voice: false line |
| 3 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d3m2 | k1 | context | Chili cooked. | this evening | Y | N | N | Y | N | a bare time of day, adds nothing to "Chili cooked" under "Wednesday night"; Voice: no new fact |
| 3 | d4m1 | w1 | context | Push A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d4m2 | w1 | context | Push A done. | this evening, after work | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d5m1 | w1 | context | Pull A today. | this morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 3 | d6m2 | w1 | context | Pull A done. | this evening, your usual slot | N | Y | Y | Y | N | Saturday: told line says after work on weekdays (E17 trap); Voice: false line |
| 3 | d7m1 | w1 | context | Rest day. | Nothing booked, a quiet one | N | Y | N | Y | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; "a quiet one" is invented; Voice: false line |
| 3 | d7m1 | k1 | context | Dal tonight. | This evening, your cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d8m1 | w1 | context | Legs A today. | this evening, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d8m2 | w1 | context | Legs A done. | tonight, after a full session | Y | Y | N | Y | N | restates the hero's "done" in other words; Voice: no new fact |
| 3 | d9m1 | w1 | context | Push A today. | this morning, Push A | N | Y | N | Y | N | puts the session this morning (memory says after work) and repeats the routine name; Voice: false line |
| 3 | d9m2 | w1 | context | Push A done. Bench press best. | this evening, bench best | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 3 | d10m1 | w1 | context | Pull A today. | This morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 3 | d10m1 | k1 | context | Chili tonight. | This evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d10m2 | w1 | context | Pull A done. | Tonight, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d10m2 | k1 | context | Chili cooked. | Tonight, your usual cooking | Y | N | Y | Y | N | clipped, "your usual cooking" is not a phrase; Voice: no new fact |
| 3 | d11m1 | w1 | context | Legs A today. | this morning, after work | N | N | Y | Y | N | "this morning, after work" contradicts itself; memory says after work; Voice: false line |
| 3 | d11m2 | w1 | context | Legs A done. | tonight, after work, done | Y | N | N | Y | N | clipped telegram ending in the hero's "done"; Voice: no new fact |
| 3 | d12m1 | w1 | context | Push A today. | this evening, after work | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d13m1 | w1 | context | Pull A today. | this morning, your usual slot | N | Y | Y | Y | N | Saturday morning: memory says after work on weekdays, so neither morning nor usual fits; Voice: false line |
| 3 | d13m2 | w1 | context | Pull A done. | Tonight, after 3 exercises | Y | N | Y | Y | N | "after 3 exercises" is a riddle; Voice: no new fact |
| 3 | d14m1 | w1 | context | Rest day. | Nothing scheduled, no clock | N | N | N | Y | N | a cook is planned tonight on the same Home, so "nothing scheduled" is false; restates Rest day; "no clock time" is jargon; Voice: false line |
| 3 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |

Value per line (same order): 1/d1m1/w1 F, 1/d1m2/w1 F, 1/d2m1/w1 F, 1/d2m2/w1 F, 1/d3m1/w1 X, 1/d3m2/w1 F, 1/d3m2/k1 F, 1/d4m1/w1 F, 1/d4m2/w1 F, 1/d5m1/w1 F, 1/d6m2/w1 F, 1/d7m1/w1 X, 1/d8m1/w1 F, 1/d8m2/w1 F, 1/d9m1/w1 X, 1/d9m2/w1 R, 1/d10m1/w1 F, 1/d11m1/w1 X, 1/d11m2/w1 F, 1/d12m1/w1 F, 1/d13m2/w1 X, 1/d14m1/w1 X, 1/d14m1/k1 F, 2/d1m1/w1 F, 2/d1m2/w1 F, 2/d2m1/w1 F, 2/d3m1/w1 X, 2/d3m1/k1 F, 2/d3m2/w1 F, 2/d3m2/k1 F, 2/d4m1/w1 F, 2/d4m2/w1 F, 2/d5m1/w1 X, 2/d6m2/w1 X, 2/d7m1/w1 X, 2/d7m1/k1 F, 2/d8m1/w1 X, 2/d8m2/w1 F, 2/d9m1/w1 X, 2/d9m2/w1 R, 2/d10m1/k1 F, 2/d10m2/w1 F, 2/d10m2/k1 F, 2/d11m1/w1 X, 2/d11m2/w1 F, 2/d12m1/w1 F, 2/d12m2/w1 F, 2/d13m2/w1 X, 2/d14m1/w1 X, 2/d14m1/k1 F, 3/d1m1/w1 F, 3/d1m2/w1 F, 3/d2m1/w1 F, 3/d2m2/w1 X, 3/d3m1/w1 X, 3/d3m2/w1 F, 3/d3m2/k1 F, 3/d4m1/w1 F, 3/d4m2/w1 F, 3/d5m1/w1 X, 3/d6m2/w1 X, 3/d7m1/w1 X, 3/d7m1/k1 F, 3/d8m1/w1 F, 3/d8m2/w1 F, 3/d9m1/w1 X, 3/d9m2/w1 R, 3/d10m1/w1 X, 3/d10m1/k1 F, 3/d10m2/w1 F, 3/d10m2/k1 F, 3/d11m1/w1 X, 3/d11m2/w1 F, 3/d12m1/w1 F, 3/d13m1/w1 X, 3/d13m2/w1 F, 3/d14m1/w1 X, 3/d14m1/k1 F

## Memory pass, claude-sonnet-5-5: shown lines scored

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | d1m1 | w1 | context | Push A today. | After work, as usual | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d2m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d2m2 | w1 | context | Pull A done. | After work, as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d3m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d4m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d4m2 | w1 | context | Push A done. | After work, as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | d5m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d8m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d9m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 1 | d10m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d11m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d12m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 1 | d13m1 | w1 | context | Pull A today. | After work, your usual slot | N | Y | Y | Y | N | Saturday: told line says after work on weekdays (E17 trap); Voice: false line |
| 2 | d1m1 | w1 | context | Push A today. | After work, as usual | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d2m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d2m2 | w1 | context | Pull A done. | After work, as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d3m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d4m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d4m2 | w1 | context | Push A done. | After work, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | d5m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d8m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d9m1 | w1 | context | Push A today. | After work, your usual | Y | N | Y | Y | N | cut off mid-phrase |
| 2 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 2 | d10m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d11m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d12m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 2 | d12m2 | w1 | context | Push A done. | Finished tonight | Y | Y | N | Y | N | restates the hero's "done" in other words; Voice: no new fact |
| 2 | d13m1 | w1 | context | Pull A today. | After work, your usual slot | N | Y | Y | Y | N | Saturday: told line says after work on weekdays (E17 trap); Voice: false line |
| 2 | d13m2 | w1 | context | Pull A done. | Pull A done | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 3 | d1m1 | w1 | context | Push A today. | After work, as usual | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d2m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d2m2 | w1 | context | Pull A done. | After work, as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d3m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d4m1 | w1 | context | Push A today. | After work, your usual | Y | N | Y | Y | N | cut off mid-phrase |
| 3 | d4m2 | w1 | context | Push A done. | After work, as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d5m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d8m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d9m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 3 | d10m1 | w1 | context | Pull A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d11m1 | w1 | context | Legs A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d12m1 | w1 | context | Push A today. | After work, your usual slot | Y | Y | Y | Y | N | Voice: half filler ("usual" or a restated time of day) fails (Research ruling) |
| 3 | d12m2 | w1 | context | Push A done. | Tonight, after work as usual | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | d13m1 | w1 | context | Pull A today. | After work, your usual slot | N | Y | Y | Y | N | Saturday: told line says after work on weekdays (E17 trap); Voice: false line |
| 3 | d13m2 | w1 | context | Pull A done. | All 3 exercises ticked off | Y | Y | Y | Y | Y |  |

Value per line (same order): 1/d1m1/w1 F, 1/d2m1/w1 F, 1/d2m2/w1 F, 1/d3m1/w1 F, 1/d4m1/w1 F, 1/d4m2/w1 F, 1/d5m1/w1 F, 1/d8m1/w1 F, 1/d9m1/w1 F, 1/d9m2/w1 R, 1/d10m1/w1 F, 1/d11m1/w1 F, 1/d12m1/w1 F, 1/d13m1/w1 X, 2/d1m1/w1 F, 2/d2m1/w1 F, 2/d2m2/w1 F, 2/d3m1/w1 F, 2/d4m1/w1 F, 2/d4m2/w1 F, 2/d5m1/w1 F, 2/d8m1/w1 F, 2/d9m1/w1 F, 2/d9m2/w1 R, 2/d10m1/w1 F, 2/d11m1/w1 F, 2/d12m1/w1 F, 2/d12m2/w1 F, 2/d13m1/w1 X, 2/d13m2/w1 R, 3/d1m1/w1 F, 3/d2m1/w1 F, 3/d2m2/w1 F, 3/d3m1/w1 F, 3/d4m1/w1 F, 3/d4m2/w1 F, 3/d5m1/w1 F, 3/d8m1/w1 F, 3/d9m1/w1 F, 3/d9m2/w1 R, 3/d10m1/w1 F, 3/d11m1/w1 F, 3/d12m1/w1 F, 3/d12m2/w1 F, 3/d13m1/w1 X, 3/d13m2/w1 A

## Gate pass, claude-haiku-5-5: shown lines scored

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E2 | w1 | context | done at 7:40 pm | Earlier, at 7:40 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E2 | w1 | detail | 6 exercises, 18 sets. | 6 exercises, 18 sets, first in 9 days. | Y | Y | Y | Y | Y |  |
| 1 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E5 | w1 | context | this evening | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E11 | w1 | context | done at 8:15 pm | this evening, 8:15 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot | N | Y | Y | Y | N | E12 memory holds no habit, so "your usual slot" is invented; Voice: false line |
| 1 | E13 | k1 | context | 2 to buy | this evening, 2 to buy | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E15 | w1 | context | done at 7:30 pm | this evening, your usual slot | N | Y | Y | Y | N | E15 memory is only the told "great job" line; nothing supports "your usual slot"; Voice: false line |
| 1 | E16 | w1 | context | done at 6:50 pm | this evening, your usual slot | N | Y | Y | Y | N | E16 memory holds no habit, so "your usual slot" is invented; Voice: false line |
| 1 | E16 | w1 | detail | 5 exercises, 15 sets. | 5 exercises, 15 sets, last Pull A 3 days ago. | Y | Y | Y | Y | Y |  |
| 1 | E18 | w1 | context | done at 4:10 pm | done, this afternoon at 4:10 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E18 | k1 | context | paused 5 min ago | this evening, paused 5 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 1 | E20 | w1 | context | done at 9:05 pm | this evening, 9:05 pm | N | Y | Y | Y | N | 9:05 pm is night under the time-word rule (evening ends 9 pm); Voice: false line |
| 2 | E2 | w1 | context | done at 7:40 pm | this evening, 7:40 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E2 | w1 | detail | 6 exercises, 18 sets. | 6 exercises, 18 sets, first Push A in 9 days. | Y | Y | Y | Y | Y |  |
| 2 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E5 | w1 | context | this evening | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E6 | w1 | context | today | this evening, your usual slot | N | Y | Y | Y | N | 11 pm, the usual 6 to 8 pm slot has passed; "this evening, your usual slot" is wrong on both counts; Voice: false line |
| 2 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E11 | w1 | context | done at 8:15 pm | this evening at 8:15 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot | N | Y | Y | Y | N | E12 memory holds no habit, so "your usual slot" is invented; Voice: false line |
| 2 | E13 | k1 | context | 2 to buy | this evening, 2 to buy | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E15 | w1 | context | done at 7:30 pm | at 7:30 pm, your usual slot | N | Y | Y | Y | N | E15 memory is only the told "great job" line; nothing supports "your usual slot"; Voice: false line |
| 2 | E17 | w1 | context | today | this morning, not after work | N | N | Y | Y | N | Saturday 9 am, plan has no time; "this morning" is invented and "not after work" is a riddle; Voice: false line |
| 2 | E18 | w1 | context | done at 4:10 pm | done, this afternoon | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 2 | E20 | w1 | context | done at 9:05 pm | this evening, 9:05 pm | N | Y | Y | Y | N | 9:05 pm is night under the time-word rule (evening ends 9 pm); Voice: false line |
| 3 | E2 | w1 | context | done at 7:40 pm | this evening at 7:40 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E5 | w1 | context | this evening | this evening, your usual slot | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E11 | w1 | context | done at 8:15 pm | this evening, 8:15 pm | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot | N | Y | Y | Y | N | E12 memory holds no habit, so "your usual slot" is invented; Voice: false line |
| 3 | E13 | k1 | context | 2 to buy | this evening, 2 to buy | Y | Y | Y | Y | N | Voice: filler, no fact the rules line lacks |
| 3 | E15 | w1 | context | done at 7:30 pm | this evening, your usual slot | N | Y | Y | Y | N | E15 memory is only the told "great job" line; nothing supports "your usual slot"; Voice: false line |
| 3 | E16 | w1 | context | done at 6:50 pm | this evening, your usual slot | N | Y | Y | Y | N | E16 memory holds no habit, so "your usual slot" is invented; Voice: false line |
| 3 | E18 | w1 | context | done at 4:10 pm | done, 4:10 pm | Y | Y | Y | Y | N | Voice: same facts as the rules line, reworded |
| 3 | E20 | w1 | context | done at 9:05 pm | at 9:05 pm, your usual slot | N | Y | Y | Y | N | E20 memory holds no habit, so "your usual slot" is invented; Voice: false line |

Value per line (same order): 1/E2/w1 F, 1/E2/w1/detail A, 1/E3/w1 F, 1/E5/w1 F, 1/E8/k1 F, 1/E11/w1 F, 1/E12/w1 X, 1/E13/k1 F, 1/E15/w1 X, 1/E16/w1 X, 1/E16/w1/detail A, 1/E18/w1 F, 1/E18/k1 F, 1/E20/w1 X, 2/E2/w1 F, 2/E2/w1/detail A, 2/E3/w1 F, 2/E5/w1 F, 2/E6/w1 X, 2/E8/k1 F, 2/E11/w1 F, 2/E12/w1 X, 2/E13/k1 F, 2/E15/w1 X, 2/E17/w1 X, 2/E18/w1 F, 2/E20/w1 X, 3/E2/w1 F, 3/E3/w1 F, 3/E5/w1 F, 3/E8/k1 F, 3/E11/w1 F, 3/E12/w1 X, 3/E13/k1 F, 3/E15/w1 X, 3/E16/w1 X, 3/E18/w1 R, 3/E20/w1 X

## Gate pass, claude-sonnet-5-5: shown lines scored

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, bench press best | Y | Y | Y | Y | Y |  |
| 1 | E2 | w1 | context | done at 7:40 pm | 7:40 pm, first in 9 days | Y | Y | Y | Y | Y |  |
| 1 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, Deadlift best | Y | Y | Y | Y | Y |  |
| 2 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, a bench best | Y | Y | Y | Y | Y |  |
| 2 | E2 | w1 | context | done at 7:40 pm | 7:40 pm, first in 9 days | Y | Y | Y | Y | Y |  |
| 3 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, bench press best | Y | Y | Y | Y | Y |  |
| 3 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, a best on Deadlift | Y | Y | Y | Y | Y |  |

Value per line (same order): 1/E1/w1 A, 1/E2/w1 A, 1/E14/w1 A, 2/E1/w1 A, 2/E2/w1 A, 3/E1/w1 A, 3/E14/w1 A
## Failure patterns

1. **"usual" with nothing behind it, or on the wrong day.** Haiku gate: "at 7:50 pm, your usual slot" (E12, x3), "this evening, your usual slot" (E15, E16, E20), all moments with no habit in memory. Sonnet memory: "After work, your usual slot" on Saturday d13m1 (x3), the E17 trap the checks pass. Haiku memory: the same on Saturdays d6m2 and d13m2. Fix: the `fits` flag (home-lines-job AI-10, Research H-M3), so "usual" and "after work" fail with empty `fits`.
2. **Wrong time of day.** Haiku memory: "this morning, after work" (d5, d10, d11, x6), "this morning, before work" (d3, d8, x4), "this morning, Push A" (d9, x3) for sessions memory puts after work. Haiku gate: "this evening, your usual slot" at 11 pm (E6), "this evening, 9:05 pm" (E20, night under the time-word rule), "tonight" for a 6 pm session (d2m2, d6m2). Fix: send the session's part of day, or forbid a part-of-day word on a planned item with no plan time.
3. **Filler and restating the hero.** Haiku: 50 of 78 memory lines and 21 of 38 gate lines add nothing ("this evening, paused 40 min ago", "this evening, Chili", "tonight, after work, done", "Finished tonight"). Rest days get invented or false lines ("Nothing scheduled, rest up" with Dal planned). Sonnet's real additions are narrow: 29 of its 31 memory additions are one template, "After work, your usual slot" / "as usual", repeated every weekday morning.

## The 10 for Kaushik

Rubric (Research section 4.5): lines from the model that would ship, one per kind first (done, paused, planned, rest, cook, shop, planned cook), then the ones that differ most from rules. Neither model passes every row: Haiku fails True on both passes; Sonnet passes the gate but fails True on the memory pass (3 Saturday lines), and the memory pass must meet the truth row. Sonnet is the only candidate, so the 10 are Sonnet's. Sonnet showed lines only for done and planned workouts; for paused, rest, cook, shop and planned cook it returned the rules line every time, so those kinds have no pair to show. The 10 mix its best and worst.

| # | Rules line | Claude's line | Sounds like Tess? |
|---|---|---|---|
| 1 | done at 8:05 pm | 8:05 pm, a bench best |  |
| 2 | done at 7:40 pm | 7:40 pm, first in 9 days |  |
| 3 | done at 7:55 pm | 7:55 pm, Deadlift best |  |
| 4 | Pull A done. | All 3 exercises ticked off |  |
| 5 | Push A today. | After work, your usual slot |  |
| 6 | Push A today. | After work, as usual |  |
| 7 | Pull A today. | After work, your usual slot |  |
| 8 | Push A done. | Finished tonight |  |
| 9 | Push A done. | After work, as usual |  |
| 10 | Push A today. | After work, your usual |  |

Sources: 1 gate E1 run 2 (Thu 9:40 pm); 2 gate E2 run 1 (Thu 9:10 pm); 3 gate E14 run 1 (Tue 8:30 pm); 4 memory d13m2 run 3 (Sat 10:40 pm); 5 memory d12m1 run 1 (Fri 8:10 am); 6 memory d1m1 run 1 (Mon 8:10 am); 7 memory d13m1 run 1 (Sat 8:10 am, false: weekday memory, the E17 trap); 8 memory d12m2 run 2 (Fri 10:40 pm, restates the hero); 9 memory d4m2 run 1 (Thu 8:40 pm, filler on a done item); 10 memory d4m1 run 3 (Thu 8:10 am, cut off). Show #7 as is: whether he notices the Saturday slip is the point.

If Haiku were chosen instead (one per kind it showed, then the most different): done detail "6 exercises, 18 sets, first in 9 days." (E2); paused "this evening, paused 40 min ago" (E3); planned "this evening, your usual slot" (E5); planned cook "this evening, 2 to buy" (E13); cook "Tonight, your usual cook slot" (d10m2); rest "Nothing booked, a quiet one" (d7m1, false); done detail "5 exercises, 15 sets, last Pull A 3 days ago." (E16); "at 7:50 pm, your usual slot" (E12, false, no memory); "this morning, after work" (d11m1, false); "Nothing scheduled, rest up" (d14m1, false and tells him what to do). Haiku showed no shop line (all E9 lines were caught).

Scorer: AI architecture, Voice reviewed by Research.

## Rerun, job done (Oct 16, 1:36 and 1:37 PM PT runs)

Same rules as above, Research's Voice ruling included, and Voice scored against what master's `HomeLines` shows for the moment, not the fixture's thinner rules line (Research, Oct 16). Rules lines are the fixture's: the gate's say only "done at" a time; the memory days' already carry the best or the gap.

### Gate, claude-sonnet-5-5

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, a bench best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 1 | E2 | w1 | context | done at 7:40 pm | First in 9 days | Y | Y | Y | Y | Y |  |
| 1 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, a deadlift best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 1 | E19 | w1 | context | done at 8:00 pm | at 8:00 pm, a bench best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 2 | E1 | w1 | context | done at 8:05 pm | A bench best, 8:05 pm | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 2 | E2 | w1 | context | done at 7:40 pm | First in 9 days | Y | Y | Y | Y | Y |  |
| 2 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, a deadlift best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 2 | E19 | w1 | context | done at 8:00 pm | at 8:00 pm, a bench best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 3 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, a bench best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 3 | E2 | w1 | context | done at 7:40 pm | First in 9 days | Y | Y | Y | Y | Y |  |
| 3 | E12 | w1 | context | done at 7:50 pm | 7:50 pm, bench best | Y | Y | Y | Y | N | true but drops the overhead press best; Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 3 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, a deadlift best | Y | Y | Y | Y | N | Voice: the best is already in master's rules line (HomeLines.swift:248) |
| 3 | E19 | w1 | context | done at 8:00 pm | Done at 8:00 pm | Y | Y | Y | Y | N | Voice: the rules line reworded, no new fact; Voice: the best is already in master's rules line (HomeLines.swift:248) |

Value against master's rules line (Research): 3 add a true fact (the gap, E2), 10 reworded (the best is already shown). Against the fixture's rules line: 12 and 1. Caught (not shown): E12 runs 1 and 2, "7:50 pm, bench and overhead bests", 33 characters (C3).

### Memory, claude-sonnet-5-5

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | d9m2 | w1 | context | Push A done. Bench press best. | Push A done. Bench press best | Y | Y | Y | Y | N | Voice: the rules line minus its stop |
| 1 | d15m2 | w1 | context | 7:40 pm, first in 4 days | First in 4 days | Y | Y | Y | Y | N | Voice: the rules line minus the time |
| 1 | d20m2 | w1 | context | 7:40 pm, first in 5 days | First in 5 days | Y | Y | Y | Y | N | Voice: the rules line minus the time; Saturday, no "usual" (C15 trap passed) |
| 2 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best | Y | Y | Y | Y | N | Voice: the rules line shortened |
| 2 | d15m2 | w1 | context | 7:40 pm, first in 4 days | First in 4 days | Y | Y | Y | Y | N | Voice: the rules line minus the time |
| 2 | d20m2 | w1 | context | 7:40 pm, first in 5 days | First in 5 days | Y | Y | Y | Y | N | Voice: the rules line minus the time |
| 3 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best | Y | Y | Y | Y | N | Voice: the rules line shortened |
| 3 | d15m2 | w1 | context | 7:40 pm, first in 4 days | First in 4 days | Y | Y | Y | Y | N | Voice: the rules line minus the time |
| 3 | d20m2 | w1 | context | 7:40 pm, first in 5 days | First in 5 days | Y | Y | Y | Y | N | Voice: the rules line minus the time |

Value: 0 add a fact, 9 reworded. d16m2, d17m2 and d18m2 came back equal to their rules lines in all 3 runs (9 lines, not shown).
