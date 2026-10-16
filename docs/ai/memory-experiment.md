# Memory experiment (AI-0)

For: AI team to run; Core reads the result. Date: Oct 16, 2026 (Pacific).
Runner: `scripts/ai/memory_experiment.py` (Python 3, no packages). Fixture: `docs/research/fixtures/memory-days.json`.

**Question.** Which memory shape makes Tess's lines more aware of him, at what cost, without a single untrue word? Kaushik's steer (Oct 16, 12:13 AM PT): explore memory, profile and context first; the graph is small, so choose the shape to suit; he has $200 a month of credits.

**What it decides.** The fields of `TessMemory` (ship list AI-7), what goes in every pack, and whether Claude may write its own noticed notes.

## The three shapes

| Shape | What every call carries | Who writes memory | Bet |
|---|---|---|---|
| **A. Profile** | One stable block: told facts plus the last 14 recent day lines, identical for every job | The phone (day lines from `DayStory`) | Simplest; stable bytes cache well; the model sees everything and picks |
| **B. Per-area** | Told facts for the job's area, up to 10 noticed lines for that area, last 7 recent lines | The phone (noticed lines from a weekly job) | Smaller, more pointed; the architecture's current default |
| **C. Self-notes** | As B, but the noticed lines are Claude's own, written at each day's end through a `noteMemory` tool and checked on the phone | Claude proposes, the phone checks (licensed digits, no health or money words, 80 characters) | Most alive; the risk is notes that drift from the facts |

All three run with the same instructions, the same `proposeLines` tool and the same checks as `first-features.md` section 1b. Only the `<memory>` block differs.

## The fixture

`memory-days.json`: 14 days in the demo shape (Push A, Pull A, Legs A twice through; tasks; three cooks; one rest day; one skipped day; a bench record on day 9; training drifting from 6 pm to 8 pm in week two). Each day has its facts (what the phone would know) and 1 to 3 Home moments with the item packs from `first-features.md`, 27 moments in all. Twelve moments carry an **aware target**: a memory-only fact that a good line could use (H5's "your usual slot", "first push day in 9 days", "third cook this week"). Told facts in the fixture: "Trains after work on weekdays." "Cooks on Sunday and Wednesday." "Call mom means his mother."

## Scoring, per shape, 3 runs

| Score | How | Bar |
|---|---|---|
| **Truth** | Every line passes shape, licensed numbers, names from the pack, voice and health words (the AI-3 checks, in the script) | 0 lines shown that fail (failing lines fall back to rules; count them) |
| **Aware** | On the 12 target moments (34 lines over 3 runs), does the line use the memory fact (keyword match, then a read by a person) | Report the count; this is the number the shapes compete on |
| **Flat** | On the 22 other moments, does the line equal or merely restate the rules line | Lower is not better: restating is fine when nothing is worth adding |
| **Drift (C only)** | Notes Claude wrote that the phone rejected, and notes that are true but say nothing | Rejected notes must be caught 100%; report both counts |
| **Cost** | From `usage` per call, priced from `TessUsageLedger.prices`; cache-read tokens counted | Per call and per month at 20 Home calls a day |
| **Latency** | Wall time per call, p50 and p95 | Under the 6 s Home timeout at p95 |

Both models run: `claude-haiku-5-5` and `claude-sonnet-5-5` at effort low. That is 3 shapes × 2 models × 3 runs × 27 moments = 486 line calls plus 84 note calls for shape C, about 1,500 tokens each, under $2 all in.

## Output

The script writes `docs/ai/memory-experiment-results.md`: one table per model with the six scores per shape, the 12 aware moments' lines side by side, every line that failed a check and why, and the token size of each shape's memory block. The team adds a five-line recommendation at the top and the fields Core should build.

## Where the key comes from

The script reads `TESSERA_CLAUDE_KEY` (falling back to `ANTHROPIC_API_KEY`) from the environment only. It refuses to run if the variable is missing, never prints it, and writes no request bodies to disk. On a Mac that is `ANTHROPIC_API_KEY=... python3 scripts/ai/memory_experiment.py`; in a cloud session it is the variable `TESSERA_CLAUDE_KEY` on the Tess environment, because cloud sessions withhold `ANTHROPIC_API_KEY`. The key is never in the repo, the results file, a thread or memory.
