# Kitchen acceptance of #1030, #1031, #1032, #1059, #1060: static read

Static only, against origin/master at the time of writing (nothing built or run; the test runs belong to the Mac). Diffs read with `git diff <merge>^1 <merge>`; "covering test" means a test I read, not one I ran. Merge SHAs: #1059 f2a3b623, #1060 2c0e6eb4, #1030 5c915877, #1031 a4a7cd6a, #1032 aba79265.

Not read here: #1061 (Home private workout), #1063 (raw title sites) and #1065 (class creation with UNDO, `ActionEngine.swift`, `ClassActions.swift`). I did not check who owns them. #1065 is not the Ask-slot fix (G434): it adds createClass/deleteClass ops for "New subclass". G434 is still open.

| PR | Clause | Verdict | Where | Covering test |
|---|---|---|---|---|
| #1059 | Remove key is two steps: "Remove the Claude key?" with Remove and Keep it, no system alert, no UNDO after (G375, G647, Product ruling) | PASS (code) | ClaudeSection.swift `confirmingRemove`, `removeQuestion`, `KeyRemove.question/removeWord/keepWord` | KeyRemoveTests (new, 50 lines); old KeyRemovalTests (30 lines) deleted, which is right since the held-key UNDO is gone |
| #1059 | Receipt "Claude key removed. Everything stays on this phone."; if the Keychain still holds a key, "I couldn't remove the key. Try again?" | PASS | `KeyRemove.remove(from:)` checks `keys.read() == nil` | KeyRemoveTests |
| #1059 | The one soft warning only when a write did not save, once per failure | PASS (code) | `notSaved` counter and `RecipeCopy.playsNotSaved(last:now:)` gate | not read in tests |
| #1059 | Leaving with the question open keeps the key; nothing removed without Remove; VoiceOver announces the receipt and focus goes to the question | PASS (code) | `.onDisappear { confirmingRemove = false }`, `@AccessibilityFocusState`, `UIAccessibility.post(.announcement)` | ClaudeSettingsUITests (19 lines changed); UI tests not run |
| #1060 | A speech start cancelled during the permission prompt shows no hold hint (G447) | PASS (code) | BottomChrome.swift `guard listener.state == .listening` before the hint | no test in the diff |
| #1030 | A private grocery row is always masked in SHOP mode, no tap-to-reveal (G102) | PASS | `name` is now non-optional and already masked at the source; the "until tapped" path is gone | ShopTripTests (+15) |
| #1031 | "Private recipe" in the Kept list draws at full ink, not dimmed (sheet 99) | PASS (code) | the Kept list row's `foregroundStyle(Theme.Colors.ink)` (the diff shows the change, not the file name) | none (visual) |
| #1031 | Removing a kept link says its line with a 10 s UNDO that puts the link back | PASS | `TessVoice.shared.say(..., takeBack:)` restores via `shelf?.keep(link)` | RecipesKeptTests (+60) |
| #1032 | A private recipe's page shows each ingredient as "Private item", opens nothing, VoiceOver too (G182, G183) | PASS (code); not walked | IngredientColumn `isPrivate`, `ShopTrip.privateLabel`, `RecipeCopy.privateRow` | ObjectMaskTests (+11), RecipeTitleWallTests (+6) |
| #1032 | "Private" is judged by the one check used by lists (`ObjectPrivacy.isPrivateWord`) | PASS | RecipePage walled check | RecipeTitleWallTests |
| #1032 | Each ingredient row offers "Add all" as its own VoiceOver action (G230, G68) | PASS (code) | `Button(RecipeCopy.addAllAction, action: onAdd)` per row | none read |

## What this closes and what it does not

- Closed in code: G375 (Remove key two-step), G447, G102 (SHOP mode part), G182 and G183 (ingredient rows on a private recipe), G230 for the ingredient rows.
- Still open: G434 (Ask slot line and UNDO read from two places). The notification text blocker G451 and the list G451-G460 are Core's and are not touched by these five.
- Not walked: the private-recipe page, Remove key flow and Kept list are screens; a walk on the phone or simulator is the only proof, and the Mac test run on the exact head is still owed. The line "private cook names in Pantry" (G139, G184) is #1022 and is covered in the other page.
