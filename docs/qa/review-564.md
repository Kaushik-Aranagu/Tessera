# QA review: #564 0v question walls + WallsUITests (Builder B)

Head reviewed: bf0ba93 (on current master; merge-tree clean). Static review. **PASS**

- A06/A07: a secret, money or body phrase skips the "?"/"best"/"pr" shortcut and goes to Tess
  (BottomChrome.swift:509-513). Her grammar answers "It's in your private notes." or files a private note, never a
  plain task. P04: the PasteRecipe miss log skips `PrivateFacts.isWalled` (PasteRecipe.swift:205-206).
- Check 1, `-wallsSpy`: read only through `LaunchFlags.has` (AppModel.swift:168, RootView.swift:73), and also behind
  `#if DEBUG`. The spy is a URLProtocol on an ephemeral session (App/Debug/WallsSpy.swift), so every Claude request is
  answered in memory and nothing reaches the network. Its fake key is the existing `ClaudeSection.fakeKey`; there's
  no new key-shaped literal anywhere in the diff or the fixture. The probe is invisible, passes touches through, and
  is DEBUG-only.
- Check 2, fixture: added as a resource of the TesseraUITests target only (project.yml:117-121). The app target's
  sources don't include docs/.
- WallsUITests subclasses SimulatorOnlyTestCase. The launch arguments are the spec's.
- No Catalog or migration change.

Notes
- **N1 (Research's call)**: the suite runs about 12 min against the spec's 6-min budget (walls-ui-test-spec.md).
  Not a blocker. Research decides whether to raise the budget, split the surfaces, or run the suite only at a gate.
- **N2 (merge order)**: #544 (Core 0ah) adds the same `!PrivateFacts.isWalled(text)` line at PasteRecipe.swift:205
  with a different comment, so #544 and #564 conflict on that line and on TessCaptureEngine.swift:58. Both are
  comment-only. The second to merge takes either comment. With both merged the walls hold twice: #564 keeps walled
  text away from the interpreter, and #544 makes the interpreter safe anyway.
- **N3**: `-wallsSpy` deletes the miss log beside the store at launch (AppModel.swift:176-178). That's simulator-only
  through LaunchFlags, but anyone running it by hand loses the demo store's miss log.

## Design FIX FIRST at bf0ba93 (Design studio, Oct 16): QA agrees, HOLD
- Design is right, and QA missed it. Walled questions now go to Tess, but only her secret path answers questions
  (TessGrammar.swift:508). So "was $12 too much?" or "is 82.4 good?" becomes a private note made from the question,
  or "Didn't catch that.". The answer should be "That stays on this phone." (decisions 2:30). It also skips #544's
  interpreter answer (CaptureParts.swift:192), which already returns that line.
- Simplest fix: send only secret-word questions to Tess, and let money or body questions keep the interpreter path
  that #544 made safe. Or teach the grammar the money/body question line. Plus the master merge
  (PasteRecipe.swift:205, comment-only).
