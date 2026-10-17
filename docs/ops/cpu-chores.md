# CPU chores

Checks that need a CPU and no model, so idle hours still produce results at zero tokens. One script, `scripts/ops/cpu_chores.sh`:

| Flag | What it runs | Where | Cost |
|---|---|---|---|
| `--docs` | `docs_index_check.py` (docs missing from an index, broken links) and `staleness.py` (board lines naming merged PRs) | anywhere with python3 and git | seconds |
| `--package` | `swift test` in `TesseraCore/` | macOS with swift; skipped elsewhere | minutes; no simulator, so no lane lock |
| `--scale` | with `--package`, the 5-year history test | same | longer |

No flag runs `--docs --package`. The report lands in `/tmp/tessera-chores/last.txt`; the terminal gets one summary line per step. It exits 1 only when the package tests fail: docs and staleness findings are counted, not failed.

## First run (master dcdeda47)

- Docs index: 594 docs, **269 MISSING-INDEX**, 0 broken links. Most are under `docs/research/` and `docs/design/`; the new fixtures and sheets were never linked from a README.
- Staleness: **46 lines** in the boards name merged PRs while still under Now, Next or Later (QA and Motion boards hold most).

## Running it on a schedule (proposal, not installed)

On the Mac, a `launchd` agent or a cron line can run `scripts/ops/cpu_chores.sh` every few hours from a clean clone of master and leave `last.txt` for the leads to read. That changes a Mac's setup, so it goes to the coordinator first. A package-only run does not touch the simulator, so it is safe to run while the screen is locked.
