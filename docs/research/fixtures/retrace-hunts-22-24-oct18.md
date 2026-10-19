# Re-trace of gap hunts 22, 23, 24 against #1022 and #1033

Master fdc75400. Static read, nothing was run. Hunts 22 to 24 were written against master 2b8b135f. Merged since: #1022 (G105b/G607: one private-text check, EditNote runs the CreateNote check, grocery-amount exemption rules) and #1033 (private cook: Timer / Private recipe, ingredients mask, Pantry on the one check, Siri read-backs, capitalized timer label). Method: `git diff 2b8b135f..HEAD` on TesseraCore/Sources and Features, then every row of the three hunts that cites a changed file was re-read against current code. Line numbers were checked with `wc -l` and spot reads.

Files changed by the two PRs that the hunts touch: `ObjectPrivacy.swift` (159 lines now), `Notes.swift` (233), `Intents.swift` (223), `PantryLedger.swift`, `Cooking.swift`, `TimerAlerts.swift`, `NowPicker.swift`, `Lists.swift`. `Entities.swift` did not change, so OL37, OL38, OL42 and OL50 cites stand.

## Rows that changed

| Row | Old status | New status | New cite | Reason |
|---|---|---|---|---|
| Hunt 22, "Which objects mask" map row | traced | traced, claim widened | `ObjectPrivacy.swift:28-61`; ingredient branch `:56-60` | `ObjectPrivacy.label` now also answers for an ingredient ("Private item", title check only). Workout and routine still return nil, so the row's main point holds. |
| Hunt 22, Top gaps #2 (G638) | gap | gap (cite moved) | `ObjectPrivacy.swift:28-61` | `label(of:)` grew by five lines; still no workout or routine branch. |
| OL01 | gap | gap (cite moved) | `ObjectPrivacy.swift:28-61` | Same as above. |
| OL59 | gap (latent) | gap (cite moved) | `ObjectPrivacy.swift:28-61` | Same; `defaultFields` still gets nil for a workout. |
| OL07 | gap | gap, partly fixed | Core: `ObjectPrivacy.swift:56-60`; Pantry: `PantryLedger.swift:119-132, 157-165, 172-175`; page: `ObjectPage.swift:575-578` (unchanged) | The object page now masks a walled ingredient title through Core. Pantry now masks an ingredient a private recipe's cook used (sticky G139). Still open: the page does not mask an ingredient used only by private things (title-only), and there is still no test on the page. |
| OL08 | gap | gap (cite moved) | `ObjectPrivacy.swift:137-146` | `notesLine` moved down 43 lines; class page still prints prototype notes raw. |
| OL12 | traced | traced (cite moved) | `ObjectPrivacy.swift:130-146` | `hidesNotes` and `notesLine` moved; behavior identical. |
| OL41 | gap (not built) | gap (not built), prerequisite met | `Notes.swift:172-175` | The row says EditNote must run the same check as CreateNote (G607). It now does: `CreateNote.isPrivateText` on both body and title. The indexer part is still not built. |
| Hunt 24, Top gaps #4 (G660) | gap | gap (cite moved) | `ObjectPrivacy.swift:64-88` | `isPrivateTitle` is now 25 lines (leading-amount rule, plural title words, Dr names). The recent day line still filters with `SecretWords` and `PrivateFacts` only (`TessMemory+Turnover.swift` not changed). |
| TL26 | gap (inferred) | gap (cite moved) | `ObjectPrivacy.swift:64-88`; doc comment `:64-68` | Doc comment that says one check serves receipts, UNDO, Tess lines, screens and export is now at :64-68. Claim unchanged. |
| TL27 | gap (inferred) | gap (cite moved) | `ObjectPrivacy.swift:64-88` | Cite moved only. |
| TL36 | gap (unruled) | gap (unruled), cite moved, new evidence | `ObjectPrivacy.swift:49-55, 64-88`; `Intents.swift:206-210` | Task branch (:49-52) and recipe branch (:53-55) did not move. `TellTessIntent` now splits the same way on purpose: a task uses `PrivateFacts.isPrivateTitle`, everything else uses `ObjectPrivacy.isPrivateTitle` ("a task keeps its own rules"). The two-checks split is still live and now also reaches Siri read-backs. |
| Hunt 24, CALL 2 recommendation text | n/a | cite moved | `ObjectPrivacy.swift:64-68` | The cite `:59-63` in the Recommended line now points at :64-68. |

Also, in `gap-hunt-23-claude-layer.md`, row CL36 was edited as asked: `CaptureMissLog.swift:50, 70-76` now reads `:48-52` (backup exclusion) and `:68-76` (trim). Checked: the file is 76 lines; the backup exclusion is :48-52 (`var excluded` at :48, the flag at :50, `setResourceValues` at :52), and `trimIfNeeded` is :69-76 with the blank line before it at :68.

## Rows checked and found unchanged

- CL04 (`Intents.swift:165, 203`): `TellTessIntent.perform` capture line is still :203; the read-back change is after it (:204-212) and does not touch the Claude path. Still true.
- CL30 (`Intents.swift:161`) and OL49 / hunt 22 line 37 (`Intents.swift:11, 91, 114, 135, 189`): all above the edit, still true.
- CL05 (timer phrases never reach Claude, `TessModel.swift:98-107`): not touched. #1033 changed what the timer label shows (Timer on a private recipe's cook, capitalized label) in `TimerAlerts.swift` and `NowPicker.swift`, which no row of hunts 22 to 24 cites.
- TL29 (`ObjectPrivacy.swift:11, 45-48`), TL35 (`:49-52`): lines before the new branches did not move. Still true. TL35's "task uses the narrower check" still holds (the task branch still calls `PrivateFacts.isPrivateTitle`).
- TL02, TL11, TL12, TL33, TL38: files not in the diff.
- CL37 / CL06 rows citing `PrivateWords.swift`: not in the diff.

Count: 12 table rows changed or re-cited (of roughly 190 rows in the 3 hunts), 1 further row (CL36) edited in place. Rows read and found unchanged: 10 explicitly listed above; the other rows cite files outside the diff and were not re-read.
