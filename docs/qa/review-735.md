# Review #735 at 93f4419c (Builder B, B11 masking on the plain Groceries list)
Static, merges clean, two files.

Passes: the plain list rows (AisleSection) and SHOP rows share `rowLabel` and `shopTap` (first tap on a masked private row reveals, the next strikes). Exits re-mask: leaving SHOP mode (`.onChange(of: shopping)`), leaving the page (`.onDisappear`), lock or app switch (`scenePhase != .active`), all calling `trip.end()`. Receipts: check() says nothing; uncheck says nothing; clearBasket says "Cleared N from the basket." (a count, no names), so striking a revealed item names nothing private. VoiceOver reads the Text, so it says "Private item" while masked, and the "Shows it" hint applies through GroceryRow.

## FIX FIRST
F1. The basket does not stay masked after a reveal. BasketFold gets `label: rowLabel`, which is `trip.label`, and that returns the real words for any id in `revealed`. Reveal an item in the list, strike it (it moves to the basket), open the basket: its real words show until he leaves the page. Spec for this PR is "the basket stays masked, a tap takes it out". Fix: give the basket a label that ignores `revealed` (for example `trip.maskedLabel(for:name:lastWeightKg:)` returning "Private item" for any walled item) and pin it with a test (reveal, then maskedLabel still "Private item").

Lows: L1 `.onDisappear` also fires when a pushed page covers Groceries, which only re-masks (safe). L2 CheckListItem.summary/receipt still name the real title (Core, from #732 L1); nothing shows it from here.

Re-check d23eaddd: F1 closed (BasketFold uses basketLabel -> ShopTrip.maskedLabel, 'Private item' for any walled item whether opened or not; test reveals, strikes, still masked). Pantry swipe adds by name via AddGroceries; the new test shows a walled 'advil' reads Private item in list, SHOP and basket. Product's ruling removes PantryCopy.empty and the empty-page Tess line (no remaining references). PASS.
