# QA review: #544 0ah, command interpreter walls (Core)

Head reviewed: fe389be (merge-tree on master clean). Static review. **FIX FIRST** (one small item).

Checked against Research AU (walls-ui-test-spec.md §1, walls-ui-phrases.json):
- A06 "what's my wifi password?" now gets "It's in your private notes." and saves nothing (CaptureParts.swift:190-192).
- A07 "door code 4417?" gets the same line. The value is never in a task title.
- A walled line without "?" that reaches the interpreter (one with "best" or "pr") becomes a private note, as in the
  Bar (CaptureParts.swift:194-198). A key gets `claudeKeyLine`.
- A10, A12 and P04: the miss logs now skip `PrivateFacts.isWalled` (TessCaptureEngine.swift:58-61,
  PasteRecipe.swift:205-206). The TessCaptureEngine hunk is identical to #534's, so either order merges cleanly.
- AppModelTests checks the lines and that no title holds 4417, password or 2100.
- No launch flags, Catalog or migration changes.

FIX FIRST
- **F1** The new test types a key-shaped literal (the Claude key prefix plus six characters; AppModelTests.swift:117).
  #534 just rebuilt its fake the same way #487 did, at run time and plainly fake, after the merge secret scan.
  Do the same here, e.g. `["sk", "ant", "TEST"].joined(separator: "-") + "-FAKE"`.

Lows
- **R1** "That stays on this phone." is a new line for a money or body question. It is in no fixture row and no
  decision. Design or Product should confirm it.
- **R2** (inferred) The interpreter's private note returns a line with no record, so it may get no UNDO slot, unlike
  the Bar's "Private note, kept." Check BottomChrome's handling.

## Re-review at 6a04f07 (Core): **PASS on code; needs a master merge first**
- F1 fixed: the test key is built at run time and plainly fake (AppModelTests). There's no key-shaped literal in
  the diff. Both "Couldn't save that." strings now use a straight apostrophe.
- The PR is NOT based past #534. Its merge base is 2c62eaf (#545), and merge-tree on master shows one conflict in
  TessCaptureEngine.swift:58. The conflict is comment-only: both sides add the same `!PrivateFacts.isWalled(phrase)`
  check. Master's comment says "(Product P14, 12:30 PM PT)" and this PR's says "(board 0ah)". Keep either one; the
  code is identical. Merge master in (no rebase on a frozen branch) and it is clean.
- R1 ("That stays on this phone." wording) and R2 (UNDO slot on the interpreter's note) still stand as lows.
