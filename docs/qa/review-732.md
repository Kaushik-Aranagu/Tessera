# Review #732 at c645dee3 (Builder B, B8 SHOP mode private rows)

Static. Merges clean; GroceriesView (+28), ShopTrip.swift, ShopTripTests.

Passes: the wall is the full one (ObjectPrivacy.isPrivateRecipeTitle: secret word, money with an amount, body, medicine). Masked row reads "Private item" in the Text, and the row is `.accessibilityElement(.combine)` over that Text, so VoiceOver says it too. First tap reveals that row only (a Set of ids), the next strikes; other private rows stay masked; `trip.end()` clears everything on leaving SHOP mode. Reveal lives in view @State of GroceriesPage, never stored, never sent: check() does no say(), so no Tess line or receipt is produced from this view, and nothing in the widgets or Live Activities reads the reveal. The walk-order test matches K7.3.

## FIX FIRST
F1. No reset on backgrounding. `trip.end()` runs only from `.onChange(of: shopping)`; nothing watches scenePhase, so a row he opened stays open across lock or app switch while SHOP mode stays on (the Face-ID-protected words show again on return). FW18/K46.24 and the ask are "masks again when he leaves it". Fix: `@Environment(\.scenePhase)` and `.onChange(of: scenePhase) { if $0 != .active { trip.end() } }`; add a test-free one-liner or a ShopTrip.end() call-site test.
F2. The long-press "for <recipes>" line (and the dab) under a masked row prints raw recipe titles, `groceries.recipes(for:).map(\.title)` (GroceriesView.swift:205). A private recipe's title (secret word, money, medicine) shows beside a "Private item" row. Map titles through ObjectPrivacy.isPrivateRecipeTitle to ObjectPrivacy.recipeLabel (do it for both modes, it is one line), with a test.

Lows: L1 CheckListItem.summary/receipt (Lists.swift) name the real title ("Got Advil", "Advil, got") unlike AddGroceries, which masks via `shown`; nothing shows it from this view today, but any later surface that prints a Groceries check receipt would leak. Core to mask like AddGroceries. L2 reveal is per row for the whole trip, not "until he leaves the row"; fine if Product reads FW18 as the trip. L3 the test uses lastWeightKg nil only.

Re-check da41df30: F1 closed (scenePhase != .active calls trip.end(); .inactive also masks, which is the safer side), F2 closed (ShopTrip.recipeNames maps private recipe titles to 'Private recipe', test), hint reads 'Shows it' while masked. PASS.
