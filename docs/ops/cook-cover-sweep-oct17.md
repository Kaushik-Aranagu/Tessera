# Sweep: does any ops doc say the cook cover replaces or sits beside the clock page? (Ops, 9:25 PM PT Oct 17)

Rule: G228 ruled the clock page IS the cook (recipe-clock.md: "replaces sheet 12's cook mode"; Design 69). No cook claim stands until `RecipePage.cookModeReady` flips (false on master; no cook view).

Searched docs/ops (repo) and tessera/ops (project folder) for: cook cover, cook mode, clock page, cookModeReady, replaces the clock, beside the clock.
Result: no ops doc says the cover replaces or sits beside the clock page.

Lines that describe cook mode in sheet-12 terms (live steps, two timers, Lock Screen timers, idle rule, Cook entry on finish), owned by other teams, so reported and not edited:
- docs/ops/board/ios-a.md line 70, item 5 "Cook mode screen (kitchen slices 12 and 12b...)": written before Design 69. Builder A should read it as the clock page (one lane, lit steps, bead, ingredient peek).
- docs/ops/board/design.md lines 165 and 187: sheet 12 as the cook screen (done items).
- docs/ops/board/kitchen.md lines 29 and 37: line 37 already names sheet 69 PASS; line 29 "Accept cook mode when Builder A lands it" is fine.
- docs/ops/board/core.md line 241 and board.md lines 53 and 55: "cook mode screen" wording only; no cover-versus-clock claim.
Fixed in Ops files: release-14-walk-draft.md step 12 no longer asks the tester to run a cook ("8 mins" while a timer runs); it says the cook-running rule is code-checked only until cook mode lands. Release 14 Step 0 (release-14-checklist.md line 13) has no cook claims.
Owners to tidy the board lines: Builder A (ios-a.md 70) via the coordinator; Design (design.md 165, 187).
