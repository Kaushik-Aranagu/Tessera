# Review 325: Core lows (#316 S1, "1 lb cake flour", the 401 key test)
PR #325 at 6240a52, from 0167046. Trial merge onto master 4011570 clean. TesseraCore only (5 files, +48/−3); no app files, no catalog or schema change. Static review, Oct 16 PT.

**Verdict: PASS.**

## #316 S1: "already on Groceries" makes no record: closed
- `TessCaptureEngine.grammarCapture` (TessCaptureEngine.swift:231-239) short-circuits before any perform. When the parse is one groceries line with no amount and no unit, and `Groceries.isOn(name)` finds an open, undeleted item linked `about` the same ingredient, it returns `TessCapture(records: [], line: "Chickpeas, already on Groceries.", asking: .line)`. No record means no pending ghost and no UNDO.
- A checked-off item doesn't count, so re-adding something already bought still adds it. Anything with an amount still goes through `AddGroceries` (tested).
- `alreadyOnGroceriesMakesNoRecordWithoutCommitImmediately` runs on the default context and checks the op count is unchanged.
- Low: the old fallback in `performKitchen` (:321-330) stays. When `IngredientBook.find` misses a name that `AddGroceries`' merge still matches (a spelling the book doesn't resolve), that path can still return a record that changed nothing, with UNDO. That's rare, since `AddGroceries` files new names in the book. If it shows up, have that branch drop a record whose ops are empty.

## "1 lb cake flour": closed
`Quantities.swift:217-223` keeps "pound cake" only when the name is exactly "cake" and the text says the word "pound" right before "cake". The tests cover all four cases: "1 lb cake flour" (flour), "1 pound cake flour" (flour), "1 lb cake" (a pound of cake) and "1 pound cake" (the cake).
- Low: "1 pound cake mix" now reads as a pound of cake mix, because the name is "cake mix". The old `hasPrefix("cake ")` caught it. It's harmless on a list ("cake mix · 1 lb"); leave it unless he says it.

## The 401 key test: closed
`RecipeLinkTests.swift:237-243` now uses one reader for both the call and the check, and confirms the request reached `api.anthropic.com`. So it does prove that a 401 leaves the key in place. The test key is the `sk-ant-TEST-link` fixture, and the secret check pattern doesn't match it as a real key.

## Data safety
No LaunchFlags, ProcessInfo, UI tests, or `project.yml` changes. The engine writes nothing new.
