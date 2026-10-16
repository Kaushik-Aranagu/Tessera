# QA review 283: the Claude router (#283)

Merge 1b5e3d4, head 64ae35a. Package side only (TesseraCore); the route isn't wired into the app yet (Builder B next). Static review; no toolchain here.

**Verdict: PASS for the package. One should-fix before Builder B wires it (R3), one should-fix in the package (R1), two lows.** No reverts against the first parent. No key material in the diff.

## What's right
- **Pricing:** `"claude-haiku-5-5": (100, 500, 10, 125)` nano$/token (ClaudeKey.swift:90-92) matches Haiku 5.5's $0.10 input / $0.50 output per MTok. The model id is correct.
- **The cap:** reserve before send, settle after, record per call (ClaudeKey.swift:113-143). At the cap nothing is sent and Tess says until when (tested).
- **Ghosts:** with `commitImmediately` false, tool writes land pending (ClaudeTessModel.swift:76). A tool that fails midway leaves no ghost (tested).
- **Grammar first:** what the grammar reads never reaches Claude (tested). Switched off, paused or keyless sends nothing (tested).
- **Offline and timeout** say so, write nothing, and still write a ledger row (tested, `ledger.calls().count == 2`).

## The coordinator's four concerns
1. **Confirmed (R1, should-fix).** Three failures fall into the generic catch (ClaudeTessModel.swift:94-97), which returns `.missed` with no Tess Call ledger row:
   - A 200 whose body isn't the expected JSON (:208).
   - `TessTools.definitionsJSON()` failing to parse (:189).
   - `CancellationError`.

   A billed 200 that fails to parse, and the usage of any earlier rounds in the same call, then go uncounted against the $10 cap. **Fix:** inside `send`, map these to `Failure.other`, so the existing catch at :89-93 records the row. At minimum, record a row with the usage gathered so far in the generic catch. Add a test with a 200 and a body of `"{}"`.
2. **Confirmed, negligible.** The estimate (:49) counts the phrase (bytes/4+10) plus 3×512 output tokens. The system prompt and tool definitions are resent each round and aren't counted, so the cap can be overshot. At $0.10 per MTok input, a few thousand uncounted tokens per round is well under a cent per call. No change needed. A fixed per-round allowance for the prompt and tools would close it if wanted.
3. **Stronger than stated (R3, should-fix before wiring).** Intents.swift:150 already captures with `TessContext(commitImmediately: true)` for Siri and Shortcuts. Once `engine.claude` is wired, a Siri miss would reach Claude, and its tool calls would commit straight away, with no ghost and no UNDO. That breaks the "Claude lands as pending ghosts" rule. **Fix:** in `run()`, `guard !request.context.commitImmediately else { return .missed }`. Or Product decides that Siri misses go to Claude and commit, which I don't recommend.
4. **Confirmed (low).** Tool errors go back to Claude as `"Error: \(error)"` (:83). Today's errors carry only Claude's own tool input. A future error type that interpolates user data would send it to Claude. **Fix:** send a fixed string per error case, or a plain "Error", rather than the description.

## Lows
- **L1:** `stop_reason` is never read. A `max_tokens` cut-off or a `refusal` is treated like a normal end turn. Claude's partial text may show as the line, or the turn ends with no line. Check it: `max_tokens` or `refusal` means a plain miss line and no ghosts.
- **L2:** No test covers a 200 with an unexpected body (see R1).
