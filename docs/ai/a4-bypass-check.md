# A4: Claude path bypass check (read-only; no key value read or printed)

Paths under /home/claude/Tessera. Rulings: docs/ai/home-pack-walls-audit.md, docs/ai/side-jobs.md.

## Ranked bypass paths

1. **Medium. Exercise name and last-set load ride the capture system prompt unwalled.**
   TesseraCore/Sources/TesseraTess/TessModelCapture.swift:70-82 (`workout`, `lastSet`), used by
   ClaudeTessModel.swift:77-80. A custom exercise name is free text and can hold a secret word, money or a
   body number ("Weigh in 182.4"); only `request.text` is checked (ClaudeTessModel.swift:54), not the
   context strings. `lastSet` sends "NN kg x NN" for the last set in focus, which for a body-weight style
   exercise is a body fact. Fix: wall `exercise.name`; on a hit send "no workout in focus"; drop `lastSet`
   when the exercise name is walled.
   Test: `claudeCapturePackOmitsWalledExerciseNameAndLastSet`.
2. **Medium (latent). ClaudeRecipeReader walls less than the capture path.** RecipeLinkReader.swift:327-376.
   It cuts private lines (`SecretWords.cut`) but never calls `PrivateFacts.isWalled`; `allowed()` is the only
   switch; no demo or Siri guard. Today it is NOT wired: rg finds no `ClaudeRecipeReader(` or `.claude =`
   outside tests (RecipeLinkTests.swift:106), so there is no live path. Risk appears when it is wired.
   Fix: at wire time pass `{ model.asksClaude }`, and drop money or body lines from the page text before send.
   Tests: `recipeReaderNeverSendsWalledLines`, `recipeReaderOffWhenSwitchOff`, `recipeReaderNotConstructedInDemo`.
3. **Low. `ClaudeTessModel.run` has no switch or key-shape check of its own.** ClaudeTessModel.swift:50-54.
   `sendsMisses()` is checked only in `isAvailable` (:46), and `looksLikeClaudeKey` only in TessRouter
   (TessModel.swift:67) and TessInbox.add (:29). Both shipped callers (router, readWaiting at
   TessInbox.swift:63) pass through `isAvailable` first, so no live bypass; a new direct caller would skip
   the switch and the key check. Fix: re-check both at the top of `run`.
   Test: `claudeRunRefusesWhenSwitchOffOrTextIsKeyShaped`.
4. **Low. Tool results go back to Claude.** TessTools.swift:266 returns a count line ("3 tasks.") as a
   `tool_result`. Counts only; the asking text is already walled, so a body or money class count needs a
   walled request. Test: `claudeToolAnswerNeverNamesWalledClass`.
5. **Low. Home done pack and side ask are not built, so they have no wall to bypass yet.** The audit's
   findings 1 to 4 and side-jobs section 2 (`AskSubjectPack`) still stand. When built they must reuse the
   same pair of checks per field, with the Ingredient and Exercise name-only rule (side-jobs section 2).
   Tests: the audit's list (section 4) plus `askSubjectPackSendsNameOnlyForIngredientAndExercise`.

## No bypass found, with evidence

- **Walls before the call (capture).** `SecretWords.mentions` and `PrivateFacts.isWalled` run at
  TessModel.swift:74-79 (router skips Claude on either) and again inside `run`, ClaudeTessModel.swift:54,
  before the key is used, the ledger reserved or any request built. The inbox checks twice: on add
  (TessInbox.swift:30) and on drain (:65).
- **Money and body facts never packed (capture).** The system prompt holds only date, current exercise,
  last set and fixed rules (ClaudeTessModel.swift:77-80), never notes, health, money or history. Exception:
  path 1 above. The miss log also skips walled lines (TessCaptureEngine.swift:59-60).
- **Siri and Shortcuts.** Intents.swift:165 and :197 build `TessContext(commitImmediately: true)`;
  ClaudeTessModel.swift:51 returns `.missed` on it, and `readWaiting` refuses it (TessInbox.swift:59). It
  forces false only for items he typed himself, after the walls (:70).
- **Demo launches.** AppModel.swift:146 treats -demo, -resetDemo, -theme and -fakeClaudeKey as demo; :158
  never attaches `claude` then. `-demoTime` alone only moves the clock and uses his real store (accepted).
  LaunchFlags only work on the simulator per CLAUDE.md.
- **asksClaude gate.** AppModel.swift:58-60 needs `settingsAreReal` and the one settings field; it is the
  closure given to ClaudeTessModel (:159-165) and ClaudePlanWording (:70-76), and read at each call.
  `isAvailable` also needs a key and no pause flag. Plan wording is further held by
  `planWordingReady = false` (AppModel.swift:66) and HomePlan.swift:115.
- **Notes forced private.** Notes.swift:115-117 (create: secret word means private note, title "Private
  note"), :166 (a private note stays private on edit), :45 (a private note is never a mention target).
  Notes are not in any Claude pack. Titles Claude writes go through the same apply.
- **Plan my day pack.** PlanWording.swift:36-47 turns walled titles into "task" or "busy" (gated off
  anyway).
- **Keys.** Presence only: all uses are `keys.read()` into an `x-api-key` header and nothing logs it.
  `looksLikeClaudeKey` blocks a pasted key in the router, the inbox and the miss log.

## Not checked

Swift tests were not run (read-only review). Whether a LaunchFlags-gated demo can ever run on a phone was
taken from CLAUDE.md, not re-verified in LaunchFlags.swift.

## Recheck on master ea53f66 (Oct 17, AI architecture; read-only, no key read or printed)

| # | Path | Status | Evidence |
|---|---|---|---|
| 1 | Exercise name and last set in the capture system prompt | **Closed** (#666) | `ClaudeTessModel.system` sends "no workout in focus" and "no last set" when `HomeDonePack.isWalled(exercise.name, ...)`; test name to look for: `claudeCapturePackOmitsWalledExerciseNameAndLastSet` |
| 2 | `ClaudeRecipeReader` walls less than capture | **Closed in the reader, still not wired** | `RecipeLinkReader.swift` drops lines that are key-shaped or `PrivateFacts.isWalled` (after measures are stripped) and cuts `SecretWords`; `allowed()` gates the call. No app caller constructs it yet (rg in App, Features, Shared), so wiring still needs the demo and switch checks from the original item |
| 3 | `ClaudeTessModel.run` had no switch or key-shape check | **Closed** | `run` guards `sendsMisses()` and `looksLikeClaudeKey` before the key is used, and checks the system prompt for a key shape too |
| 4 | Tool results go back to Claude | **Closed** | `TessTools.countable` lists only training, task, note, list and kitchen classes; no money or body class can be counted |
| 5 | Home done pack and side ask had no walls yet | **Home done closed** (#658); **AskSubjectPack open** | The pack wall also drops health, money, place, care and people words. AskSubjectPack is not built, so its name-only rule is still a review item for when it opens |
