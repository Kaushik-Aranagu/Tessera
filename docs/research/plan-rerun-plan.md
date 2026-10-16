# Plan my day on Claude: the rerun plan, for Kaushik's yes

For: Kaushik, AI architecture, Core, Product. Research lab, Product item AB, Oct 16, 2026 (Pacific). No call was made and no key was read to write this.
Reads origin/master `ec47bd3`: `fixtures/plan-my-day-claude.md` (23 packs, the use 2 gate), `fixtures/plan-my-day-pack.md` (P01 to P31, G1 to G14, Q1 to Q9 with Product's 12:54 pm answers), `docs/ai/spend-projection.md`, `ClaudeKey.swift:95` (Sonnet 5.5: 2,000 n$ in, 10,000 out, 200 cache read, 2,500 cache write, per token), `scripts/ai/`, `docs/ai/home-lines-eval-scores.md`.

## What changes in the packs

- **Events go as "busy" (Q2, 12:54 pm).** In 20 of the 21 called packs every event title becomes "busy" and `allDay` becomes [] (d02 has `cal:false` and no events). That is 51 event titles and d23's "Rhea in town". Packs shrink to 120 to 288 tokens (were 122 to 304); d10 drops most (304 to 288).
- **Expected lines lose event names.** d01 "done before Standup", d21 "after Farmers market", d22 "after Design review" and every other line naming an event are rewritten to name times only ("done by 9:25 am"). A line naming an event title is now an unsent fact (N5) and a hard fail.
- **d23** keeps its builder check (the birthday is dropped with no call); its model check becomes `allDay` [] and no birthday words.
- **Times (Q5).** "5 PM", "5:00 pm" or "5pm" is re-rendered through the one formatter as "5 pm" and scored after re-render; it is not a fail. A 24-hour time ("17:00") in a line stays a hard fail.
- **Add 3 packs from the pack fixture.** d01 to d23 hold no screened title, so the gate never sees a "task" block, which v1 ships. Added, as written in `plan-my-day-pack.md`:
  - **P02** (Tue, rest day, `cal:false`, run task t2 "task" from "Reset my PIN"): 132 / 1,002 tokens.
  - **P14** (Mon trip day, run task t2 "task" from "Text sitter the door code"): 152 / 1,022.
  - **P24** (P04, light, cap 2, t1 "task" from "Refill lexapro 10mg", plus timed k2 "task" at 8:00 from "Take lexapro"; a medicine word with no dose is private, Q4): about 225 / 1,095. Research writes its exact line before the run.
- **Not added.** P16 to P20 and P29 make no call; P21, P22, P23, P25, P26 repeat a "task" or typed title already covered; P27 and P28 are reply-side checks the runner applies to every pack; P30 (timeout) and P31 (month reset) are ledger tests, not wording; P05 tests titles on, which v1 does not ship. "combination" alone is not secret (Q8), so no pack is needed for it.

## Runs, calls and cost (Sonnet 5.5 only, `claude-sonnet-5-5`, max_tokens 1,024, 20 s, no retries)

- **Packs:** 26 (23 plus P02, P14, P24). **Called:** 24. d14 (empty day) and d22 (workout running, 8:50 pm Oct 15) make no call and are scored on the app's builder.
- **Runs:** 3 per called pack. **Calls:** 24 x 3 = **72**.
- **Typical** (in = 870 fixed + pack; out from the 23-pack doc, 217 to 322; 250 assumed for P02, P14, P24): one pass is 24,957 in and 5,929 out = 24,957 x 2,000 + 5,929 x 10,000 = 49,914,000 + 59,290,000 = 109,204,000 n$ = **$0.109**. Three passes: **$0.33**, about $0.0046 a call (range $0.0042 to $0.0055).
- **Worst** (every call at 1,270 in and max_tokens 1,024 out): 1,270 x 2,000 + 1,024 x 10,000 = 12,780,000 n$ = $0.0128 a call; x 72 = 920,160,000 n$ = **$0.92**.
- **Cache:** none assumed. If the fixed part were cached it would bill at 200 n$ a token, not 2,000, so the estimate only falls.
- **$1 stop:** before each call the runner adds that call's worst ($0.0128) to what is spent; if the sum would pass $1 it stops and writes what it has. At $0.92 worst, the full 72 calls fit under it.

## Pass bar

- **Gate (unchanged, `plan-my-day-claude.md` section 5):** 21 of 23 d packs pass every must check in 3 of 3 runs (d14 and d22 pass only by making no call in the app); 0 must-nots in all calls; median under $0.006 a call, p95 under $0.008, none over $0.0125; p95 latency under 10 s, 0 timeouts. Plan my day has its own gate, not AI-5 (Q7).
- **Added packs:** P02, P14 and P24 pass in 3 of 3 runs with 0 hard fails. Not counted in the 21 of 23.
- **Hard fails (any one fails the run):** a 24-hour time in a line; a screened title leaking ("PIN", "door code", "sitter", "lexapro" or any word of a screened title in the pack or a line); a private block named (a line guessing what a "task" block is, or a ghost line shown beside one: the app drops it, Design 12:18 pm, G11); an event title sent (every event block must be "busy" and `allDay` [] before sending; one mismatch exits before any call).
- **Person columns, one run per pack, scored as in `home-lines-eval-scores.md`:** True 100%; Plain 90% or more; Not repeating 95% or more; Tone 0 lines that praise, judge or tell him what to do; Voice 80% or more.
- **Voice (Research ruling, Oct 16):** a line passes only if it adds a true fact the rules plan lacks, plainly and kindly. "usual", "as usual" and a restated time of day are filler and fail; a half-filler line fails; a truth slip fails Voice too.
- **His read:** no line he would take back.

## Who runs what

- **AI architecture** builds `scripts/ai/plan_my_day_eval.py`; none exists (`scripts/ai/` holds `home_lines_eval.py`, `groceries_link_eval.py`, `memory_experiment.py`). Model it on `home_lines_eval.py`: key from the environment only (`TESSERA_CLAUDE_KEY`, else `ANTHROPIC_API_KEY`), read only without `--dry`, never printed or written; `api.anthropic.com` only; redirects refused; no request body saved; bounded calls with the $1 stop; no exec, eval or shell; writes only under `docs/`; any sqlite opened read-only (`mode=ro`); instructions and schema read from master's `PlanWording.swift`, not a copy. Before any call, dry or not, the scorer must pass every expected reply in section 4 and catch the 18 known bad variants, or it exits.
- **AI architecture** writes the raw results to `docs/ai/plan-my-day-eval-results.md` and the person scores and verdict to `docs/ai/plan-my-day-eval-scores.md`, in the shape of `home-lines-eval-scores.md`.
- **Research** writes the 26 packs as JSON (`docs/research/fixtures/plan-my-day-eval.json`, events as "busy", P24 exact) and scores the Voice column.
- **Kaushik** sets the key in his own terminal (`read -s`, a placeholder like `<your key>`, never a file) and says the words. **The run waits for his words in the running thread: "Run the Plan my day eval."** No one runs it on anyone else's say.

## What blocks a meaningful run

Core item 0u on master `ec47bd3`: **G1, G4 and G7 are not merged** (`PlanWording.swift:52` still defaults `includesEventTitles` to true; `:106` still sends `running`; `:461` still estimates on `"\(dict)"`).
- **G1 needed.** Without it the app ships titles while the eval tests "busy", so a pass would not describe what ships.
- **G4 needed.** d22 passes only by making no call; on master it would call.
- **G7 not needed** for the run (the runner costs from usage); it matters for the app's held amount.
- **Also needed:** the runner and its dry pass; the eval JSON; G9 (medicine with no dose screened), or P24 tests a pack master would not build.
- **Not blocking:** G11 and G12; the runner applies the drop and the re-render itself.

## The sentence to ask him

"Kaushik, may AI architecture rerun the Plan my day eval on Sonnet 5.5 with your key: 26 packs (24 called), 3 runs each, 72 calls, about $0.33 and never more than $1, once Core's G1 and G4 are merged? If yes, reply in this thread: Run the Plan my day eval."
