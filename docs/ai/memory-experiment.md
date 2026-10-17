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

Oct 16: Research added days 15 to 20 (39 moments) for the AI-5 `--job done` rerun. The counts above describe the 14-day run; a rerun of `memory_experiment.py` now reads 20 days, so its baselines shift.

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

## Result and decision (AI team, Oct 16, 10:00 AM PT)

Results: `docs/ai/memory-experiment-results.md` (#410; 570 calls, about $0.60). The decision:

- **Shape A, one profile block, wins.** On Sonnet it used memory best (9 of 33 aware chances, against 8 for B and 7 for C) and failed fewest lines (37 of 81, against 60 and 40). The whole memory is about 120 tokens, so picking lines per area (B) saves nothing and cost it truth: B's noticed line "6 to 8 pm" leaked into "usual 6 pm slot", a digit the item never licensed. Every job that reads memory gets the same block: told lines, then noticed lines, then the last 7 recent lines, all in the second person, private lines never.
- **Claude writes no memory (C is out).** 31 of its 72 self-written notes failed the phone's checks, and it was the dearest shape ($1.33 a month against $1.05). Noticed lines stay computed on the phone, as section 4 of `architecture.md` already says.
- **Noticed lines carry no clock digits.** "You usually train after work.", not "6 to 8 pm". Words the slot can use as they are, and no digit to leak.
- **Sonnet 5.5 stays the Home model for now.** Haiku answered without calling the line tool for 118 items, because the run let it choose (`tool_choice` auto). That says nothing about its wording. AI-5 re-runs Haiku with the tool forced before the model is settled; Sonnet refuses a forced tool, so it keeps auto, and a reply with no tool call means the rules line stays.
- **Most failures were the old frame, not untruth.** The run asked for a whole line ("Push A done, 3 of 3 exercises.", 7 words). Under Design 41 the hero and its counts are the phone's and Claude words only the context line, so that class of failure goes away by construction. AI-5 scores the context line alone.
- **Cost holds.** Sonnet at 20 Home calls a day is about $1.05 a month on shape A, p95 at most 4.8 s, inside the $10 cap.

## Fixes this asks for

| Fix | Owner |
|---|---|
| The names check skips a capitalised word at the start of a sentence, weekdays and months ("Cook day.", "Your usual slot." were flagged as invented names) | Core, in `TessLineCheck` (AI-3); the runner's `check_line` gets the same rule when next touched |
| Tool choice per model in `TessJob`: forced for Haiku, auto for Sonnet; no tool call means the rules line stays and the ledger row says so | Core, AI-2 |
| Noticed-line templates without clock digits | Core, AI-7 follow-up |

Builder B has nothing to change: the swap-in already keeps the rules line when Claude's line fails or doesn't come.

