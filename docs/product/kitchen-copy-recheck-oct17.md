# Kitchen copy recheck, Oct 17 (K69)

*Docs only. Scope: kitchen-*.md, pantry-acceptance.md, lists-*.md, groceries-*.md, recipe-*.md, meal-plan-groceries-acceptance.md, cook-mode-acceptance.md, us-shop-acceptance.md, paste-hardening-acceptance.md, parallel-steps-acceptance.md, including the untracked new files (refill9-lane1, gap-hunt-5, counts-vs-claude, first-use-empty-states). Quoted counter-examples ("Tacos at 7 pm", "9:05 AM", "at 6:40 pm") and code identifiers were left alone.*

## Rules checked

"at" before a clock in expected app copy; uppercase AM/PM clocks (4 AM as the day-start name is fine); "in <list>" receipts; bare "Private"; cobalt on non-Tess things; "record" where "best" is required; money without an amount or sign; 4-digit year, metric or UTC in app copy.

## Edits made

| File | Row | Change |
|---|---|---|
| (none) | | No expected-copy line broke a rule, so no copy line was edited. |

Only edits this pass: the K67 triage tables appended to `kitchen-gap-hunt-4.md` and `kitchen-gap-hunt-5.md`.

## Rule results

| Rule | Result |
|---|---|
| "at" before a clock | Every hit is a scenario line (action column), a day-boundary note, or a quoted counter-example. Clean. |
| Uppercase AM/PM clocks | Hits are decision timestamps in source notes ("2:38 PM Oct 16") and counter-examples. Clean. |
| "in <list>" receipts | Every list receipt reads "on" (Groceries, Packing). Two aisle receipts say "in" (see Open 1). |
| Bare "Private" | Remaining hits are "Private phrase" (sent log, ruled), "marked Private" (the state), and quoted history of the old bare word. Clean. |
| Cobalt | Tess lines, her wet ink, and "never cobalt" rules. One unclear hit (Open 2). |
| "record" for "best" | No app-copy line uses "record". Clean. |
| Money | Every price example is stripped, or has a sign or currency word. Clean. |
| Year, metric, UTC | Metric and year hits are input examples ("82.5 kg") or the file name (Open 3). The UTC/Z times in `recipe-clock-dst-acceptance.md` sit in engine columns beside the PST/PDT app times. Clean. |

## Open items (items 1 and 4 ruled Oct 17, decisions 3:55; items 2 and 3 still open)

1. **Aisle receipts. Ruled Oct 17 (decisions 3:55): saves read "on <list>." ("Milk, on Groceries."), an aisle change reads "Chicken, moved to Dairy and eggs."; both lines edited.** `groceries-ai-acceptance.md` line 67 ("Oat milk, in Dairy and eggs.") and `kitchen-refill7-acceptance.md` K44.4 ("Milk, in Dairy and eggs."). Dairy and eggs is an aisle, not a list, so "in" may be right. Product to say: aisle receipts use "in", or "Milk, on Groceries." for all.
2. **Cobalt on a merge. Still open, no ruling covers it; `us-shop-acceptance.md` K7.9 left as is.** `us-shop-acceptance.md` K7.9 says the merged amount rolls "under the cobalt wash". Fine if the merge is Tess's wet ink; wrong if a hand merge. Product to say which.
3. **File name year. Still open, no ruling covers it.** `kitchen-gap-hunt-5.md` G26 note gives the backup file as "Tessera-2026-10-21.tessera". If that name is shown in the app it carries a 4-digit year; Product to rule whether file names are exempt.
4. **Noon (HouseTime). Ruled Oct 17 (decisions 3:55): clocks write "12 pm", never "noon"; edits listed in `kitchen-noon-recheck-oct17.md`.** `kitchen-refill9-lane1-acceptance.md` F5 (K64.6) and K53.6/K45.17 in refill7 and refill8 said "Dal, noon." while `HouseTime.clock` writes "12 pm".
