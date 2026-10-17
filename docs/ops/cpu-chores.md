# CPU chores

Checks that need a CPU and no model, so idle hours still produce results at zero tokens. One script, `scripts/ops/cpu_chores.sh`:

| Flag | What it runs | Where | Cost |
|---|---|---|---|
| `--docs` | `docs_index_check.py` (docs missing from an index, broken links) and `staleness.py` (board lines naming merged PRs) | anywhere with python3 and git | seconds |
| `--package` | `swift test` in `TesseraCore/` | macOS with swift; skipped elsewhere | minutes; no simulator, so no lane lock |
| `--scale` | with `--package`, the 5-year history test | same | longer |

No flag runs `--docs --package`. Each run writes its report into a private directory made with `mktemp` (the path is the last line printed), so overlapping runs cannot clobber each other or follow a planted symlink. The terminal gets one summary line per step. It exits 1 when the package tests fail or a docs/staleness helper crashes; findings are counted, not failed. Only one package run at a time uses `TesseraCore` (a second one skips). `--package` needs a warmed SwiftPM checkout: run `cd TesseraCore && swift package resolve` once while online, because a clean machine fetches GRDB first.

## First run (master dcdeda47)

- Docs index: 594 docs, **269 MISSING-INDEX**, 0 broken links. Most are under `docs/research/` and `docs/design/`; the new fixtures and sheets were never linked from a README.
- Staleness: **46 lines** in the boards name merged PRs while still under Now, Next or Later (QA and Motion boards hold most).

## Running it

Leads run it when they want it. It is not scheduled on the Mac; the Mac's setup stays as it is (chief of staff, Oct 17).
