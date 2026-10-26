# Memory scopes and the recall tools (M2)

Kaushik, Oct 26: "each agent knows exactly what its memory is like, where its memory is like, and there are going to
be common memories across all the agents ... but they are also going to have their own memory per agent or a
coordinator." This is the first slice of that, built on M1 (beliefs) and `RecallScore`.

Code: `TesseraTess/Harness/Recall/` (`MemoryScope.swift`, `MemoryIndex.swift`, `TessRecallTools.swift`), wired in
`TessRun` and `TessOpenTool`. Tests: `RecallToolsTests.swift`.

## 1. Two kinds of memory

| Kind | What | Who reads it |
|---|---|---|
| Shared | His objects (the record) and the beliefs about him | Every agent, through its own slice |
| Private | An agent's notebook, `/memories/<agent>/` | That agent only |

**Slices.**
- A room agent's slice holds its room's classes (`AgentSpec.beliefClasses`), every belief about him, and the beliefs
  about its classes or its things.
- Tess's slice holds every room.
- Strict takes money, body, health and calendar out of every slice. Lab lets them in, as it does for the pack.
- No slice holds her own bookkeeping: turns, sent rows, settings, the profile, memory lines.
- A belief marked "stays on this phone" is in no slice.

**Notebooks.** `MemoryScope.owns(path)` is the wall. Tess reads a room agent's notebook only by asking that agent, the
way she would ask a colleague. The notebook store itself, a class written without ops and never in backups, comes in
the next slice with the persistent agents.

## 2. Paths

Every memory has a path and never a UUID, so the model can follow and cite it.
- **Objects** use `ObjectPath`, for example `/activity/routine/push-a`.
- **Beliefs** use `/beliefs/<slug of the words>`.
- **A private thing** uses its shown label, so its path ends in `private-note`. Its walled title is never part of
  a path, a digest or a match.
- **Two things with the same path:** the oldest keeps it, and the next ones get `-2`, `-3` and so on.
- **Untitled records** (sets, entries) have no path. The `query` tool counts them on the phone.

## 3. The tools

Each tool reads only the run's slice. A path outside the slice is "Nothing there.", whatever the model asks for.

| Tool | Does | Notes |
|---|---|---|
| `recall(query, kinds, limit)` | Finds what scores above the floor (0.4), best first, with path, digest and score | Seeds are the pack's things plus anything his words name exactly. Nearness spreads from them along links. Nothing above the floor gives "Nothing kept on this." |
| `open(handle)` | Reads one thing, now by a path too | A belief reads as she says it, plus the paths of what shows it |
| `links(path)` | What it links to and what links to it | |
| `history(path)` | For a belief, its versions. For a thing, the actions that touched it, with time and who (he or Tess) | Action names only, never op titles: the change story stays off the harness, as Core's wall test intends |
| `remember(words, key, about, evidence)` | Keeps an inferred belief as a maybe: a pending ghost row he keeps or dismisses | Needs 1 to 5 evidence paths from the slice. 80 characters at most. Built from a private thing, it stays on the phone. It counts against the phrase's ghost budget |

`recall` joins `query` and `open` as a read every ask may use (`ToolPicker.reads`). `remember` is offered to Claude
under the same walls as every write: pending, Undo 10 s, screened by `RecordBelief`.

## 4. For Core to review

- `TessRun`:
  - `agent` (default `.tess`), and `memoryIndex(for:)`, built once per run.
  - The recall tools in `toolSpecs()`, and their case in `runTool`.
  - `open` passes the index when the handle is a path.
- `TessOpenTool.run` takes an optional `index`. Handles work as before.
- Nothing in TesseraCore changed.

## 5. Next (same lane)

1. **Persistent agents as objects, with their notebook store.** Each has a personality and its own episode log, and is
   spawned when a room or app is created.
2. **Tess coordinates.** She asks room agents in parallel (`ask_agent`), and each runs with its own scope.
3. **Continuity.** Each call starts from the agent's personality, core beliefs, notebook and recent episodes.
4. **Tests in the test world:** continuity, scope and spawn.
