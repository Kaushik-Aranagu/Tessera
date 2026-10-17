# Eval design: would Claude rewording of Tess's side lines add anything? (Task A3)

*Design only. No run, no key, no API call has been made. Sources: `docs/ai/side-jobs.md` section 1, `home-lines-eval-results.md`, `home-lines-eval-scores.md`, `side-line-helpers.md`, `docs/research/fixtures/side-lines.md`, `docs/ai/eval-rubric.md`.*

**Standing rule: no live run without Kaushik's own ask in the running thread.** A dry run (build packs, check payloads, run the checker self-test) needs no ask and makes no call.

## 1. Hypothesis

Side-jobs section 1 says Claude never rewords a side line, because AI-5 showed that rewording a correct rules line adds nothing (Voice 3/13 on Home, and those 3 were a gap the phone can count itself). Side lines differ from Home lines in one way: they are count-first facts about a thing ("7 for 2 cooks"), with no clock and no mood. So the null case is likely to hold harder here.

- **H0 (expected):** a Sonnet 5.5 reword adds no true fact and no better wording than the rules line. Side lines stay phone-only.
- **H1:** a reword is plainer or kinder on a meaningful share of rows without losing a fact or breaking a cap or wall.
- The eval exists to let Kaushik confirm H0 cheaply, or to find the one row kind where H1 holds. It is not a plan to ship rewording.

## 2. Packs from the 75 side-line rows

One pack per row of fixture section 4 (`SL-*` ids). Each pack is built by the phone-side packer from the row's data, never copied by hand.

- **Sendable rows only.** Rows that match E1 to E8 (body or money side, private object, walled line, first day, too little history, a zero, live workout, repeats the front) have an empty rules line. They are never sent; the eval only checks that the packer builds no request for them (a no-call check, like AW1 to AW20).
- **Groups for reporting:** counts (tasks, cooks, buys, class pages), dates (last run, last cooked), comparisons (best, gap since), and glance small facts (the 22 glance rows, context cap). Report each group apart so one kind cannot hide a weak one.
- **The 10 edge cases** run too, each with its filler trap (for example the front-repeat trap SL-G2 and the walled-line trap SL-E4). A reword that lands in a trap is a hard fail.
- **Count:** the exact sendable total is whatever the packer emits from the 75 rows; the runner prints it before any spend.

## 3. What Claude would receive

Only what a public side line already shows, as with Home's pack and Product's 2:52 pm ruling.

- The rules line, the slot (context or detail), the kind word, the numbers present, and the names allowed in the line (titles already on screen, public names only for Ingredient and Exercise).
- A handle per row (`s1`), never the real id.
- **Never sent:** money, body, notes, anything private, secret words, health words, intake, places, people, memory lines, the user's name, or any key-shaped text. Rows that fail `SecretWords.mentions` or `PrivateFacts.isWalled` on the rules line are not packed.
- One strict tool returning `{handle, line}`. Model `claude-sonnet-5-5`, effort low, tool choice auto, same prompt rules as Home (use only these facts, a count leads, "best" not "record", no "usual", no grading, no praise).
- The payload checker runs on every request before it leaves the phone: any walled field, note word, digit not in the pack, or key-shaped text fails the whole run.

## 4. Arms

| Arm | Line shown | Calls |
|---|---|---|
| A (control) | the rules line alone | none |
| B | Sonnet 5.5 low reword of the same rules line | 1 per pack per run |

Three runs of arm B per pack (variance). Scorers see A and B side by side, order shuffled, arm names hidden.

## 5. Scoring

**Checks on the phone (arm B, per line):**
- Caps: context at most 6 words and 32 characters, no stop; detail at most 14 words and 80 characters, one sentence ending in a stop, no "?" or "!".
- C1 to C15 from `eval-rubric.md` and `home-lines-job.md` (ids, caps, stops, digits kept and unadded, number words, capitalised names, grading and praise, "record", health and money words, greetings, no-repeat of the title, C15 house-day words), plus `SecretWords.mentions` and `PrivateFacts.isWalled` false. A line that fails any check falls back to the rules line and counts as caught.

**Person scores (Kaushik-readable, yes or no per line, shown lines only):**
- **True:** every word comes from the pack.
- **Plain:** no riddle, no clipped telegram, no cut-off phrase.
- **Not repeating:** adds something beyond the spine title.
- **Tone:** no scold, praise or greeting.
- **Voice:** passes only if the line adds a true fact the rules line lacks, or is clearly plainer and kinder with every fact kept. A line equal in facts to the rules line, or a pure reword, fails Voice (the AI-5 ruling: reworded rules facts are R, not A).
- Each failure gets a one-phrase reason, as in the AI-5 scores table. Kaushik reads 10 random pairs and says which he would keep.

## 6. Cost bound

Sonnet 5.5 costs 2000 n$ per input token and 10000 n$ per output token. A pack is about 600 input tokens and 40 output tokens, so a call is about 1.6 million n$ (about $0.0016).
- Runs cap: 3 runs of arm B, so at most 3 calls per sendable pack (well under 250 calls, about $0.40 at worst).
- Hard stop: the runner sums spend after each call and aborts at $1 total, even mid-run. It prints the planned worst case before it starts and refuses to start if that exceeds $1.
- No retries on a cut-off or error beyond one; a cut-off counts as a caught line.
- Cost per call (median) is reported against the existing $0.006 bar.

## 7. Pass/fail gate

Rewording is worth shipping only if all hold, otherwise the answer is "no, rules lines stay":
1. Hard fails shown: 0 (any wall, secret, money, body, false fact or trap landing).
2. Caught by checks: 15% or fewer of returned lines.
3. True 100%, Plain 90%+, Not repeating 95%+, Tone 0.
4. **Voice 80%+ of shown lines against arm A, and at least 10 shown lines add a fact the phone cannot already count.** Anything the phone can count itself goes to Core as a new rules helper, not to Claude.
5. p95 latency under 6 s and median cost under $0.006 a call.
6. Kaushik picks B over A on at least 8 of his 10 pairs.

Expected outcome under H0: Voice well under 80%, so the gate fails and `side-jobs.md` section 1 stays as written. A pass changes nothing by itself; it only lets Kaushik decide whether to open an opt-in per class.

## 8. Run rules

- The runner is dry by default (packs, payload checks, self-test, cost forecast). A live run needs Kaushik's own ask in the running thread; no agent, hand-off or earlier approval counts.
- Keys come from the environment only. No key value is printed, logged, stored in results or written to any file.
- Results go to a new section in a results file, newest first, with the prompt hash, tool schema hash, fixture hash, checker version and spend, like the AI-5 tables.
