# Review #666 (Core: a4 walls and injection items)

Head 683b2383, merge-tree clean against master. Static review, package-only (no screen change, so Design is not needed).

**Verdict: QA PASS at 683b2383, with two follow-ups.**

## Checked, correct
- a4-1: ClaudeTessModel.system sends "no workout in focus" and "no last set" when the exercise name is walled (`exerciseIsWalled` uses HomeDonePack.isWalled with the weigh-in).
- a4-3: `run` now checks `sendsMisses()` and `looksLikeClaudeKey(request.text)` itself, then `looksLikeClaudeKey(system)` after building the pack. A direct caller can no longer skip the switch or the key-shape wall.
- Per-phrase cap: cloud path checks before each call and `trim` discards ghosts past 10 from a multi-record call (`discard` cancels pending rows). The on-device CatalogTool checks before each call.
- a4-2: `sendable` cuts secret lines (the pasted-line cut, so "PIN the dough" survives) then drops any line failing looksLikeClaudeKey or PrivateFacts.isWalled. A page that is all private lines sends nothing.
- Output check `outputIsUnsafe`: steering phrase, link or address, markup characters, money, phone number, secret words, login words, and field ranges; a failing reply is dropped whole, never trimmed.
- Home pack: a title or best that talks to a model is walled; TessLineCheck's C9 allowlist leaves out walled or steering names and an unusable title empties the title words.
- Daily ceiling: `callsToday` counts the ledger's lines calls in the house day (04:00), failures included; the cached path returns before the check, so it only gates fresh calls.
- ReceiptTests.aMovedTaskSaysWhen: unrelated. It builds "tomorrow" from Date.now, and this diff touches no receipt or time code. It fails after midnight on clean master too.

## Follow-ups (not blocking)
1. **The cap is not complete on the on-device path.** CatalogTool.perform only checks the count before a call, with no trim. One `addToList` or `createList` call carries an `items` array, so one call can still write more than 10 ghosts. Clamp the items array to the remaining budget inside TessTools.run, or trim after the call as the cloud path does. The doc comment on maxRecordsPerPhrase says both paths stop at 10; it is not yet true for lists.
2. **ClaudeRecipeReader is not constructed anywhere in App or Features yet** (only the `claude:` property on the link reader), so `lastWeightKg` defaults to `{ nil }`. When it is wired, set it to `BodyWeight.lastKg(in: model.store)` (a nil turns the bare-number wall off for that path).

## Lows
- Steering phrases such as "you are now" can appear in honest recipe prose ("you are now ready to serve"); the whole recipe is then dropped. Fail-closed, so acceptable; mention in the follow-up list.
- The phrase list is plain-text only (synonyms, spacing and zero-width characters get past it); the doc comment already says the real limit is that no Claude path has a harmful tool.
- Two-decimal amounts ("1.25 cups") are walled by isMoneyShaped; Core's follow-up exempts cooking units. Fail-closed, accepted.
