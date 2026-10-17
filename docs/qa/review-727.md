# Review #727 at c6710066 (Builder B, Pantry front to sheet 78; stacked on #724 c0de5d9a)

Static. Reviewed the delta from #724's head (5 files). Reads only through ObjectStore; the one write is the swipe add.

Passes:
- Swipe add: one `AddGroceries(lines: [name])` perform = one op = one UNDO, `TessVoice.say(PantryCopy.added(entry.label), undo: record, holds: .seconds(4))` (4 s new; TessVoice.hold lifts it to 10 s under VoiceOver). Receipt is label-first, so a walled item reads "Private item, on Groceries."; Groceries masks the added line itself. VoiceOver custom action "Add to Groceries" is the same path. Failure line is the house phrase.
- Tess's names: lastCookUsedUp drops private entries (`!$0.isPrivate`) and `have` ones, lowercases labels, cap three names then "and N more".
- Context line: TesseraDay (4 AM), weekday via weekdayName (English), month-first, nil with no shop. Hero "Nothing out" / "Nothing yet" digits, IN leaves the page. No ellipsis, em dash or "at".
- Private row still opens nothing (#724 F1 intact); swipe is a simultaneousGesture limited to a left, mostly horizontal drag, 72 pt threshold.

## FIX FIRST
F1. `lastCookUsedUp` only guards the recipe title with `EngineWall.isHealth`. Tess says "\(recipe) took the ...", and a recipe titled with a secret word or money (for example "Wifi password zebra99 stew", "Pay 120.50 dinner") passes isHealth, so Tess speaks the private title. The house rule for recipes is `ObjectPrivacy.isPrivateRecipeTitle` (secret word, money, body, medicine; `recipeLabel` "Private recipe"). Fix: return nil (or say "Private recipe took the ...") when `ObjectPrivacy.isPrivateRecipeTitle(title, lastWeightKg:)`; add a test with a secret-word recipe title.

Lows: L1 `Entry.isPrivate` is EngineWall.isHealth only, so an ingredient or grocery line with a secret word or money would show on the page (same rule as AddGroceries today; Product's call whether pantry names need PrivateFacts too). L2 `speak()` runs on every appear and replaces any held UNDO note; skip it while TessVoice holds an undo. L3 the left swipe on a row will collide with the OUT AND LOW side swipe (sheet 78) when Core's SideHost lands; decide which owns the left drag then.

## Re-check 2e87db13 (merge of #724 and master 1f6952f0, plus the fixes)
Merges clean. F1 closed: lastCookUsedUp uses ObjectPrivacy.isPrivateRecipeTitle and shows recipeLabel, so Tess says "Private recipe took the ..."; test "Wifi code lasagna" works ("code" is a secret word, SecretWords.mentions). L1 closed: Entry.isPrivate uses the same full wall (secret word, money with an amount or sign, body, medicine); plain names like "pound cake flour" stay plain (money needs an amount). L2 closed: speak() returns while TessVoice holds a note with undo or takeBack. Design notes in: ghost "Groceries" word fades with the pull (accessibility hidden); one `.made` haptic on the add (SilentRows aside, say() adds none, so one per moment). Low L4: the haptic trigger increments before onAdd, so a failed add still ticks once.
PASS.
