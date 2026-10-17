# Review #711 (head a282e53a): PASS (static; no app run needed to pass, a Design clip once the simulator is up)
- NowPage hero computes the fact once; the GROCERIES key shows only when showsGroceriesKey(toBuy:) (> 0, nil = hidden). The hero is rebuilt from facts on every body pass, and body reads model.revision, so adding an item (which bumps the revision, as every Groceries write does) rebuilds the fact with toBuy > 0 and the key returns; the line text and the key come from the same fact, so they never disagree ("nothing to buy" and no key together).
- Nothing else on Home shifts: only the trailing key slot is conditional, the same empty-slot shape as the done-workout hero (EmptyView) that already ships; the hero line, its tap target (the recipe) and the transition are untouched.
- VoiceOver: with the key gone the hero is the one element ("Tacos tonight, nothing to buy", opens the recipe); with it, the order is unchanged (line, then GROCERIES with the hint "Opens Groceries").
- Tests: the show and hide cases, including nil.
- Note (carried from #700): a recipe task has no Finish hold on Home at all, so with the key hidden the hero has no action key; finishing lives in cook mode.
