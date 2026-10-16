# AI-5: Home lines eval (rubric and fixture)

For: AI architecture (runner and verdict), Core (AI-3 checks, AI-4 `homeLines` job), QA. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Built on master 450a0c0: `docs/ai/home-lines.md` (slots and caps), `docs/ai/ship-list.md` AI-5 row (the gate), `first-features.md` 1b (H1-H12), `scripts/ai/memory_experiment.py` (runner house style).

**Fixture:** [`fixtures/home-lines-eval.json`](fixtures/home-lines-eval.json), 20 Home moments (E1-E20) with 44 probe lines. E1-E12 are H1-H12 re-slotted to context line and SO FAR detail; E13-E20 add the cases the gate has to prove: planned cook count, a pack leak, memory used as an instruction, three truth traps, a whole-screen reply, detail digits, and the 4 AM day boundary. Each probe carries the verdict the phone's checks must reach, and a `human` note when the checks pass a line that is still false.

Its purpose is that AI-5 runs the day AI-4's pack lands, with nothing left to decide but the open questions at the end.

## 1. What the eval sends and gets back

One call per moment, built exactly as AI-4 will build it: house voice, the Home lines instructions, the pack (items with `hero`, `rules.context`, `rules.detail`, `numbers`, `names`, plus `memory`), and the strict `proposeLines` tool returning `{id, context, detail}` per item. Items marked `fixed` (live workout, workout with no sets) are never in the pack. E4 and E10 must build no request at all (every item is fixed).

The hero is never sent for rewording and never comes back. A returned hero is ignored.

## 2. Machine checks (each line, on the phone; any fail keeps that item's rules line)

| # | Check | Context line | SO FAR detail |
|---|---|---|---|
| C1 | Ids | every sent id once, no unknown, no duplicate; a missing id keeps its rules line, the others still swap | same |
| C2 | Words | 6 or fewer (split on spaces; "8:05" is one word) | 14 or fewer |
| C3 | Characters | 32 or fewer | 80 or fewer |
| C4 | Stop | none at the end (no `.`, `:` or `;`) | exactly one sentence, ending in `.` |
| C5 | Marks | no `!`, `…`, ` · `, newline or emoji | same |
| C6 | Digits licensed | every digit group is in that item's `numbers` | same |
| C7 | Digits survive | every digit group in the rules line appears in Claude's line as many times; the one exception is D2 | every digit group survives, no exception |
| C8 | No number words | one (before a count noun), two to twelve, couple, dozen, half | same |
| C9 | Names | a capitalised word (other than the line's first) must be in `allowedNamesAlways`, the item's `names` or its title | same |
| C10 | Grading | missed, behind, overdue, late, again, only, still, yet, finally, skipped, streak, should, must | same |
| C11 | Praise | great, awesome, nice, strong, solid, crushed, proud, amazing, job, well | same |
| C12 | Off limits | sleep, slept, tired, exhausted, fatigue, energy, rested, sore, pain, weight, body, kg, lb, lbs, money, spent, dollars, bucks, `$`, mom; "legs" unless the title is Legs | same |
| C13 | US English | mom, never mum; no British spellings (apologise, colour) in Claude lines | same |
| C14 | Fixed items | any line returned for a `fixed` item is rejected, even one identical to the rules line | same |

**D2, the clock-time drop.** On a done item only, the context line may drop its clock time ("done at 8:05 pm" to "a bench best"), because `home-lines.md` section 2 lets Claude drop the time when the state makes it plain. Every other digit survives. If Claude keeps any part of the time, all of it must survive. See Q1.

All word checks run on whole lowercase word tokens, never substrings, so "paint" never trips "pain" and "bulb" never trips "lb".

The probes prove the checks: run the checker over all 44 probes with no key; every probe must get its `expect` verdict. A reference checker written against this table gets 44 of 44.

## 3. Human scores (Research reads every shown line before Kaushik does)

| Score | Question | Bar |
|---|---|---|
| T, true | Does the line say only what the facts and memory hold? | **100%.** One false line shown fails the model. E16 ("first in a while" after 3 days), E17 ("after work" on a Saturday when memory says weekdays) and E20 ("done last night" at 12:40 am, still his Thursday) are the traps the checks can't catch |
| A, adds | Is it better than the rules line, or identical to it? | Report only. Identical is fine; worse is a voice miss |
| V, voice | Brief, warm, a little dry, plain words, no grading | 80% or more of shown lines |

## 4. The gate (from the ship-list AI-5 row)

1. Haiku 5.5 and Sonnet 5.5, 3 runs each over E1-E20, temperature as AI-4 will ship it.
2. **0 lines shown that fail a check** (C1-C14), and every probe gets its expected verdict.
3. Truth 100% and voice 80% on shown lines (section 3).
4. Cost per call under the model's line (Q2): Haiku under $0.0004 median; Sonnet under $0.006 median.
5. **Kaushik reads 10 and says 8 sound like Tess.** The 10: lines from the model that would ship, one per kind first (done, paused, planned, rest, cook, shop, planned cook), then the ones that differ most from rules. Shown to him as two plain lines each, rules then Claude, and he answers yes or no per pair.

If Haiku fails and Sonnet passes, ship Sonnet. If both pass, ship the one with more of his yeses, Haiku on a tie.

## 5. Results

The runner writes `docs/ai/home-lines-eval-results.md`: per model and run, lines sent, shown, caught by check (with the check number), truth and voice scores, median and p90 cost, and the 10 for Kaushik. The runner follows `memory_experiment.py`: key from `ANTHROPIC_API_KEY` only, never printed or written; api.anthropic.com only; bounded calls (18 moments that send, x 2 models x 3 runs = 108 calls, under $1 with Sonnet at $0.0045 a call; E4 and E10 send nothing); `--dry` runs every check on the probes with no key and no spend; writes only under docs/.

## 6. Open questions (defaults in place, AI architecture decides)

- **Q1, digits survive.** The coordinator's summary says every digit from the rules line survives; `home-lines.md` section 2 and its table let a done line become "a bench best" or "first in 9 days". Default here: D2 (clock time may drop on a done item, nothing else). Strict survival would also make "done at 7:40, first in 9 days" (7 words) the only way to say E2, and it doesn't fit.
- **Q2, cost line.** $0.0004 a call fits Haiku ($0.0002 at 1,500 in and 150 out). Sonnet at the same pack is about $0.0045 a call, so the AI-5 row's single number fails Sonnet before it is read. Default: a line per model; Sonnet at 20 calls a day is about $2.70 a month, inside the $10 cap today.
- **Q3, 40 fixtures.** The ship-list asks for 40. These 20, plus the 27 moments in `fixtures/memory-days.json` (same item shape, no detail line yet), make 47. Default: run E1-E20 for the gate, and memory-days as a second pass for truth and voice only.
- **Q4, the runner's word checks.** `memory_experiment.py` `check_line` matches health words as substrings ("pain" in "paint", "weight" in "bodyweight"), has no stop, detail, number-word or digit-survival checks, and allows only bench, press and record as names. Fine for AI-0, but the AI-5 runner and AI-3's `TessLineCheck` should use section 2.
