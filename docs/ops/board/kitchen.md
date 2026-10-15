# Recipes and groceries, then Lists (Kitchen lead)

**Now:** accept each kitchen screen as Core lands it, in `docs/product/kitchen-acceptance.md`. Engine 1-9 and Groceries #58 done (10 fixes relayed). Recipe page and Paste #86 accepted: pass, 3 polish fixes, corpus gaps ranked for Paste hardening (#88).

**Next:** (Work that needs nothing from Core. Acceptance of Core's slices still happens whenever one lands.)
1. Meal plan feeds groceries spec. Done when `meal-plan-groceries.md` is ready for Core's idle slice. It covers "carbonara thursday" putting its ingredients on Groceries the evening before, linked to the task; merging with items already on the list; servings; undo; what happens when the task moves or is deleted; and 15 acceptance rows.
2. Cook mode phone script. Done when `cook-mode-script.md` is a 10-minute, step-by-step test Kaushik or QA can run on the phone for slice 12. It covers two timers, the lock screen, killing the app mid-timer, the idle rule, and finishing with a Cook entry, built from `cook-mode-scenarios.md`.
3. Lists screens 9 to 12 acceptance for Builder B. Done when `lists-screens-acceptance.md` has a pass/fail row for each screen in `docs/design/lists-9-12.md`, plus Research's `lists-daily.md` moments once they land.
4. Kitchen week-one watch list. Done when `kitchen-week-one.md` lists what to notice in Kaushik's first week of real use (what he cooks, what he adds to Groceries, what he pastes, what he skips) so kitchen v2 can be scoped from evidence, plus 3 questions for the end of the week.
1. Kitchen v2 build sheets with Design, for L1 to L3 (recipe from a link) and the top 3 backlog items. Done when each has a sheet on Design's branch, ready the week v2 opens. Include slice P (pantry light) from Research's `../research/pantry-light.md`, so v2 can start on Oct 22 if he says yes.
2. Accept cook mode when Builder A lands it (kitchen slices 12 and 12b, against #127 and `cook-mode-script.md`). Until then, the next item.
3. Kitchen rows for the grammar misfire sweep. Done when 40 kitchen and grocery phrases that must stay on Groceries, and 20 that look like groceries but are tasks or gifts ("get mum a card"), go to Research for `fixtures/grammar-misfires.md`, so Core's grammar fix batch can't break kitchen.
4. Paste hardening acceptance (Core Next 8). Done when `paste-hardening-acceptance.md` has a pass/fail row for each corpus gap, ready when Core's PR lands.

**Done:** (#140) meal plan feeds groceries acceptance `meal-plan-groceries-acceptance.md`; (#137) cook mode phone script `cook-mode-script.md`; Lists G1-G13 decisions + screens 9-12 acceptance `lists-screens-acceptance.md`; week-one watch list `kitchen-week-one.md`; Packing starter list. Next 1 = #129, Next 5 = #136. Cook mode cut, defaults and acceptance script `cook-mode-acceptance.md` (#127; screen now Builder A's); meal plan feeds groceries defaults + script `meal-plan-groceries-acceptance.md` (#129); Lists ship list `ship-list-lists.md` (#61); Lists acceptance checks `lists-acceptance.md` and starter lists `starter-lists.md` (#62); 10 seed recipes `kitchen-seed-recipes.md`; 50-phrase test set `kitchen-phrases.md`; Kitchen v2 backlog `kitchen-v2-backlog.md` (held for a week of use); Lists aligned with Design sheet d134bf0 (#74) and Product's Copy/skip/preview (#75).

**Later:**
- Kitchen v2 scope from the backlog, after a week of use; recipe from a link is scheduled as L1-L3 (#93); Design sheet folded in, pantry/rhythm/can-cook are slices P, R, W (#136). Nutrition only if Kaushik asks.
