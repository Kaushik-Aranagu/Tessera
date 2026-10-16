# AI-11: the week, told (eval rubric and fixture)

For: Core (`WeekFacts` lens, `weekStory` job), AI architecture, QA. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Built on `first-features.md` section 2, `ai5-home-lines-eval.md` (same check style, AI's Q1-Q4 answers) and the Review fixtures `fixtures/review-sentence.md` and `fixtures/review-m3.md`.

**Fixture:** [`fixtures/week-story-eval.json`](fixtures/week-story-eval.json) has 12 weeks (W1-W12) of `WeekFacts`, with the three rules lines Review shows when Claude is off and 32 probe lines carrying expected verdicts. A reference checker built from section 2 gets all 32 right. The weeks are Monday 04:00 to Monday 04:00 Pacific, PPL x2 at 6 a week with Sunday as rest, in kg.

Covered: a full week with bests, 4 of 6, 0 of 6, a first partial week, habits and cooks, a logged body weight (which must never reach the pack), 3 bests, a DST week with a 12:30 am session, two sessions in one day, a told fact that tries to steer, handles, and a plan that has ended.

## 1. The three lines

| Slot | Says | Rules line (Claude off) | Claude may |
|---|---|---|---|
| 1 | what happened | "6 of 6 workouts, 2 new bests." | name the bests, the habits, the days trained |
| 2 | one thing noticed | "14 tasks done, 1 recipe cooked." | replace the counts with one fact from `noticed` or `WeekFacts` |
| 3 | what's next | "Push A is first up Monday." or "Nothing planned for Monday yet." | reword, naming only `facts.next` |

## 2. Machine checks (each line; any fail keeps that line's rules version)

- **K1 shape.** Exactly 3 lines, in order. Each is 14 words or fewer, 80 characters or fewer, one sentence ending in `.`. No `!`, `…`, ` · `, newline or emoji.
- **K2 digits.** Every digit group must be in the week's `numbers`. In slot 1, every digit in the rules line also survives, because slot 1 is the counts. Slots 2 and 3 are licence-only.
- **K3 number words.** Two to twelve, couple, dozen and half are never allowed. "One" is not allowed before a count noun.
- **K4 names.** A capitalised word (other than the first) must come from the handles, `facts.next`, a habit title or a weekday.
- **K5 next.** Slot 3 names `facts.next.title` and no other routine. With no next item, it says nothing is planned.
- **K6 handles.** Every handle id is in the pack, and the line names what the handle points at.
- **K7 words.** Use AI-5's C10-C12 lists (grading, praise, off limits), plus three changes:
  - add `tough`, `fell`, `slacked`, `crushing`, `lighter`, `heavier` and the phrase "best week";
  - drop `yet`, because the rules line "Nothing planned for Monday yet." uses it (AI-5's list keeps it for Home);
  - match whole tokens, never substrings.

## 3. Human scores

The scores and bars are the same as AI-5: truth 100% and voice 80%.

The traps the checks can't catch:
- W5 says both cooks were on a Sunday, which the facts don't say.
- W8 calls a 12:30 am session "Saturday", but it is Friday's under the 4 AM day.
- W3 has two lines the checks pass but voice should reject: "and that's fine" is reassurance he didn't ask for, and "Back at it" points at the gap.

## 4. Gate

1. Sonnet 5.5 (the job's model), 3 runs over W1-W12, with 0 shown lines failing a check.
2. Every probe gets its expected verdict, run keyless with `--dry`.
3. Truth must be 100% and voice 80%.
4. Median cost must be under $0.01 a call (architecture 5.6 puts it at about $0.007).
5. Kaushik reads 4 weeks and says 3 sound like Tess. The 4 weeks are W1, W2, W5 and W7, shown as rules then Claude.

The run is 36 calls, about $0.25. The runner follows `memory_experiment.py`'s key rules and writes `docs/ai/week-story-eval-results.md`.

## 5. Notes for Core's `WeekFacts`

- `planned` counts from first use (W4: 4 since Wednesday, not 6). That matches `review-m3.md`'s "nothing before first use".
- `trainedDays` sits beside `trained` (W9: 6 workouts on 5 days), so slot 1 can say both without inventing a number.
- `next` is null when the plan has ended (W12). The rules line then says "Nothing planned for Monday yet."
- Body weight, money, notes and health never appear in `WeekFacts`, even when logged that week (W6). The pack snapshot test should assert that.
