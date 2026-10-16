# AI-5 eval rubric: Claude-worded Home lines

For: Research (scores the Haiku rerun), Product (sets the bars), Core (AI-3, AI-4). Owner: AI architecture team.
Date: Oct 16, 2026 (Pacific). Gate for AI-4 (ship list AI-5 row).

Built on: `docs/ai/line-check-vectors.md` (AI-3 checks, vectors L1-L54, P1-P7, exemptions), `docs/ai/home-lines.md`
(slots, caps, no-repeat), `docs/ai/memory-experiment.md` "Result and decision" (AI-0), and Research's
`docs/research/ai5-home-lines-eval.md` (checks C1-C14, fixture E1-E20, human scores). This sheet does not replace
Research's: it fixes what a scored item is, splits hard fails from judged rows, and sets the bars and the record.

## 1. What the run is

- **Haiku 5.5, tool forced:** `tool_choice` names `proposeLines`. **Sonnet 5.5 keeps auto** (AI-0: it refuses a
  forced tool). Effort low on both, as AI-4 will ship it.
- **Shape A memory** in every pack: one profile block (told lines, noticed lines, last 7 recent lines), second
  person, private lines never. Noticed lines carry no clock digits ("You usually train after work.").
- **Claude words two slots only:** the context line and the SO FAR detail. The hero, Next rows and the day label
  are the phone's and are never scored.
- **Fixture:** E1-E20 gate the release; the 27 memory-days moments are a second pass for truth and voice.
- **The pack never holds money or body and health facts.** A pack that does is a pack bug: stop the run, fix AI-4.

## 2. What a scored item is

One scored item is **moment + pack + line**:

| Part | What is recorded |
|---|---|
| Moment | fixture id (E7, d9m2), the phone time, day label, hero per item |
| Pack | the item as sent: id, `rules.context`, `rules.detail`, `numbers`, `names`, memory block hash. Never the request body |
| Line | model, run (1-3), item id, slot (context or detail), Claude's text or "no line", the verdict |

So one moment with two items and both slots gives four scored items per run. A missing line (`.noLine`) is scored
on the tool-call row only, never as a check failure: the rules line stays and nothing visible happens.

## 3. Hard fails (mechanical, any one keeps the rules line)

Run by the AI-3 checker, never by eye. Codes are Research's C-codes; the vectors prove each one.

| Code | Fails when | Vectors |
|---|---|---|
| C1 | an id is missing, unknown or duplicated | Research probes |
| C2, C3 | context over 6 words or 32 characters; detail over 14 words or 80 characters | L2-L4, L39-L42 |
| C4 | a stop ends a context line; a detail is not one sentence ending in `.` | L5, L43, L44 |
| C5 | `!`, `…`, ` · `, newline or emoji | L25, L26 |
| C6, C7 | a digit not in `numbers`; a rules digit lost (except D2: a done item's context may drop its whole clock) | L6-L10, L45, L46 |
| C8 | a number word | L29 |
| C9 | a capitalised word not in the pack's names (sentence start, weekdays, months exempt) | L33-L36, L47-L53 |
| C10, C11 | grading (missed, behind, late, again, only, still, streak, should, finally) or praise | L11-L19, P7 |
| House word | "record" for a best. The word is "best", never "record" | L20, L50 |
| C12 | health, body, sleep, energy, money, places, people | L21-L24, L49 |
| Greeting | hi, hello, hey, "good morning" at the start; sorry, oops, apologize | L27, L28 |
| No-repeat | the context line carries the day label's weekday, the title as a phrase, or a hero state word | L30-L32 |
| Secret wall | a stored secret word, or anything shaped like the Claude key prefix | L37, L54 |
| C14 | any line returned for a `fixed` item | Research probes |

Before any call, the checker runs every vector and probe with no key: L1-L54 and Research's 45 probes must all
get their expected verdict. The AI-0 runner's `check_line` is not the scorer (substring health words, no stop,
detail, number-word, survival, greeting, no-repeat or "record" checks).

## 4. Judged rows (a person reads every line that passed section 3)

| Row | Question | Fails when |
|---|---|---|
| Plain | Would he read it once and know where the thing stands? | jargon, a riddle, a clipped telegram, a word he would not say |
| True to the pack | Does every word come from the facts, the counts or the memory block? | "first in a while" after 3 days (E16), "after work" on a Saturday when memory says weekdays (E17), "last night" before 4 am (E20), "usual" when today does not fit the rule |
| Not repeating the page | Does it add to what the hero and day label already say, or rest at the rules line? | it restates the hero in other words ("all finished" under "Push A done") |
| Tone | Brief, warm, a little dry. Never scolds, never greets | a soft scold the list misses ("no rush this time"), a hello in any form, cheerleading |

"Adds" (better than the rules line, or equal) is reported, never failed: a line equal to the rules line is fine.

## 5. Scoring sheet and gate

All numbers below are **proposals for Product**. Per model, over 3 runs, on shown lines unless noted.

| Row | Bar (proposed) |
|---|---|
| Probes and vectors | 100% expected verdicts, before any call |
| Hard fails shown | 0. A failing line is caught and falls back; count catches per code |
| Caught by checks | 15% or fewer of returned lines (more means the prompt is wrong, even if safe) |
| Tool called | Haiku forced: 99% or more of items get a line. Sonnet auto: 90% or more |
| True to the pack | 100%. One false line shown fails the model |
| Tone: scolds or greets | 0 shown |
| Plain | 90% or more |
| Not repeating the page | 95% or more |
| Voice (Research V) | 80% or more |
| Cost per call, median | Haiku under $0.0004, Sonnet under $0.006 |
| Latency p95 | under the 6 s Home timeout |
| Kaushik reads 10 | 8 or more sound like Tess (rules line, then Claude's, yes or no per pair) |

**Overall gate:** a model passes when every row passes. If Haiku fails and Sonnet passes, ship Sonnet. If both
pass, ship the one with more of his yeses, Haiku on a tie. The second pass (memory-days) must meet the truth and
tone rows; it does not gate on cost or tool calls.

## 6. How a run is recorded

- The runner writes `docs/ai/home-lines-eval-results.md`, one section per run, newest first. Never a request
  body, the key, the env var's value or any key prefix.
- Section header: date and time PT, model ids, tool choice, effort, prompt hash, tool schema hash, fixture hash,
  checker version, commit, calls, total spend.
- Then: the section 5 sheet filled in; every caught line with its code; every judged fail with its row and a
  one-line why; the 10 pairs and his answers; the scorer's name.
- Research adds a three-line verdict at the top (pass or fail per model, the model that ships, what changes).
- The ship list AI-5 row links the section that decided.

## 7. What reruns it

A full rerun (both models, 3 runs, both passes) on any change to:

- a model id or snapshot, tool choice or effort;
- the prompt (house voice, Home lines instructions) or the `proposeLines` schema;
- the pack shape (AI-4, AI-10 fields), the memory block or the noticed-line templates;
- the AI-3 checker's word lists, caps or exemptions, or the fixture.

A change to the checker alone may rescore the last run's saved lines with no calls, then rerun before ship.
