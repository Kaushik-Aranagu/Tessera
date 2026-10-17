# Review #724 at edcffab0 (Builder B, Pantry page + B2)

Static. Merges clean. New: PantryLedger (with the #722 M1 and lows), PantryView, PantryDayWord, two test files; HomeSpatialView adds HomeLink.pantry under Groceries (the only other HomeLink uses match by string, no exhaustive switch elsewhere).

Closed from #722: Entry.isPrivate / label (EngineWall.isHealth on the title; sort and display use label); optional and to-taste lines no longer count; a deleted recipe adds nothing. Read-only still (no engine, no write).

Day word: PantryDayWord uses TesseraDay.day(of:) for both dates, so a 1:20 am check belongs to the day before; today / yesterday / "Sat" (2 to 6 days, English via weekdayName) / "Oct 3" (en_US_POSIX, month first); spoken form uses full names. Future dates read "today". Passes.

## FIX FIRST
F1. PantryView.swift PantryLine is a NavigationLink to Route.object(entry.ingredient.id) for every entry, walled ones included. Spec S15 / K26.16 / K27.19: a private line "opens nothing". ObjectPrivacy.label(of:) has no ingredient branch (returns nil), so ObjectPage opens the ingredient with its real title ("Advil"). The line text is masked but one tap shows the word, and the hint says "Opens Private item". Fix: when entry.isPrivate render the same row without the link (no hint, no destination), or add an ingredient branch to ObjectPrivacy.label. Add a test that an isPrivate entry has no destination (or the label branch).

Lows: L1 the next-lane uses (Tess line, widget, Spotlight, Home) are not in this PR; each must read label (ledger already offers it). L2 the empty-state line "Clear a shop or finish a cook and this fills in." is fine under the copy rules.

Delta c0de5d9a: PantryLine.opens(entry) = !isPrivate; private rows render the same row with no link, no hint, VoiceOver label only; plain rows unchanged. Test asserts both. F1 closed. PASS.
