# QA review: #534 privacy parity, P14 + 0j + 0ac slice 1 (Core)

Head reviewed: d8048c3 (4 commits on master c36845e; merge-tree clean). Static review: no Swift toolchain here.
Verdict: **FIX FIRST** (two items below). Everything else passes.

## Checked and passing
- One privacy rule on three paths: `TessGrammar.privateParse` (TessGrammar+Privacy.swift:18-40) is shared by Add a Task
  (Intents.swift:161-176). Tell Tess goes through the Bar's capture pipeline (Intents.swift:197).
- "paid rent 2100 fri" becomes a private note dated that day on every path: `parsePrivateLog` (TessGrammar.swift:325-330),
  the Bar's money branch (TessGrammar.swift:117-126) and Siri (TessGrammar+Privacy.swift:39).
- A private note is always "Private note": it is saved with `isPrivate: true` (TessCaptureEngine.swift:304-310,
  Intents.swift:166) and read back as "Private note, kept." Private task titles are read back as "Task added." or
  "Task added for Friday." (TessCaptureEngine.swift:299-302, :409-414).
- Money and body facts stay off Claude: the router, ClaudeTessModel.swift:54, the inbox and PlanWording.swift:38
  still use `isWalled`. The miss log now checks `isWalled` too (TessCaptureEngine.swift:58-60). The one gap is F2.
- HW19 adds "sick" and "unwell" to the symptoms list (PrivateFacts.swift:73). The CR1 mask covers "sick of", slang
  after a noun and slang before a noun (PrivateFacts.swift:52-57, :84-87).
- 0j follow-ups: split keys come out whole (ClaudeKeyGuard.swift:9). The Notes key line stays until his next edit
  (NoteEditor.swift:136-146). A dated body fact is private (TessGrammar.swift:134-140). "Something to do" wins
  (TessGrammar.swift:155-159).
- No Catalog or migration change. The added lines have no ProcessInfo or CommandLine reads and no UITests.
  Test files hold fake key literals; never copy them into docs.

## FIX FIRST
- **F1** `.requiresAuthentication` is set on `LogNextSetIntent` and `UndoLastSetIntent` (Intents.swift:40, :68). Both
  are `LiveActivityIntent`s (Intents.swift:210-211), so the Lock Screen's Done and the Lock Screen's undo
  (TesseraRuntime.swift:50) would need Face ID mid-set. Board 0l P16 names only Tell Tess and Add a Task.
  Fix: drop the policy from those two intents and update SiriParityTests:275. LogSet, StartRoutine and FinishWorkout
  go beyond P16; keeping their policy is Product's call, but it is not a regression.
- **F2** Taking "bought" out of `moneyWords` and out of the spent regex (PrivateFacts.swift:26, :38) un-walls a spend
  that has a bare amount. "bought a tv for 800" is no longer `isWalled`, so ClaudeTessModel.swift:54 lets it through
  to Claude. With a day, the Bar files it as a plain dated note (parsePastLog), not a private one. On master both
  are walled. "bought 2 lemons" is fine.
  Fix: treat "bought … for N" as spent, for example `\bbought\b.*\bfor\s+\d` alongside paid/spent with an amount.
  Add one test: `isWalled("bought a tv for 800")`, plus a dated case that becomes a private note.
  Whether "bought shoes 120" with no "for" is money is a question for Product.

## Lows (not blocking)
- **R1** Tell Tess turns "Private note, kept. I don't keep passwords." into "Saved." because the check is equality
  (Intents.swift:200). Use `hasPrefix("\(SecretWords.title), kept.")`.
- **R2** `privateTaskLine` sits between `when()` and its doc comment, so the "today 3 pm" comment now documents the
  wrong function (TessCaptureEngine.swift:406-408).
- **R3** The 0ac 10% weight rule (core.md:187, "82.4 this morning" is a weight only within 10% of the last one) is
  not in this PR. It rides with 0ac HW9 per the rider order. HW13 ("Body weight logged." from Siri) would read
  "Saved." through Tell Tess today; settle it in the P14+HW13 rider.
- **R4** NoteEditor's `keyEdits` assumes one onChange per changed field. If SwiftUI coalesces the two field changes,
  the key line clears one edit early. This is cosmetic; the key is gone either way.

## Re-review at d45600e (one commit on d8048c3; merge-tree clean): **PASS**
- F1 fixed: `LogNextSetIntent` and `UndoLastSetIntent` no longer set `authenticationPolicy` (Intents.swift:40, :68), so
  they use the AppIntent default. SiriParityTests.theLockScreenSetButtonsNeverAskForFaceID checks both are
  `.alwaysAllowed`. TessTests still requires Face ID for the five Siri writes. The 2:08 PM live-workout Face ID rule
  is in a later 0ac PR.
- F2 fixed: "bought … for N" with an amount counts as spent (PrivateFacts.swift:39-40). A dated money log becomes a
  private dated note before parsePastLog (TessGrammar.swift:135-139). A test covers isWalled("bought a tv for 800"), and
  "bought a tv for 800 sat" gives "Private note, kept.", a single createNote, and Claude hears nothing. "bought 2 lemons"
  stays plain. The 2:10 PM purchase-amount rule is in a later 0ac PR.
- R1 fixed: Tell Tess checks `hasPrefix("Private note, kept")` (Intents.swift:200), so the password line survives.
- R5 (low, inferred, not run): an undated "bought a tv for 800" no longer takes the miss line. If parseTask reads
  it, it becomes a task whose title holds the amount. It is walled from Claude (`isWalled`), and its readback says
  "Task added." The stored title waits on the 0ai engine wall.
- R2 and R4 stand as cosmetic. No Catalog or migration change. Nothing new for data safety. No key literals.

## Delta at dfe5801 (tests and one comment; merge-tree clean): **PASS**
- The split-key test builds a fake prefix at run time with FAKE filler. The new regex still removes the
  digit-holding run after the line break. ClaudeKeyGuard.swift:12-13 says "the Claude key prefix" in words, though
  the comment wraps oddly mid-sentence (cosmetic). No source behaviour changed.
