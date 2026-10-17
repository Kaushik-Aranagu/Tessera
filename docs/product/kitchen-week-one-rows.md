# Kitchen week one: the Oct 22 counts, by state

*Kitchen lead, 2026-10-17. For the Oct 22 message in `kitchen-v2-scope.md`. Each row says where a count is read (`scripts/kitchen-week-one.py`, run read-only on a copy of the store) and what the script prints, so the brackets fill the same way on a full, empty or thin week. Anything marked "default taken" is my inference, not a ruling.*

## Where each count comes from

| ID | State / data | Pass when |
|---|---|---|
| WK1 | Real week: [n] saved. Read from live Recipe objects created in the window. Script prints `Recipes saved: N (X ghost row, Y pasted or from a link)`. | [n] equals N. |
| WK2 | [p] pasted and [l] from links. The store keeps no URL and a link recipe is saved as text, so the script cannot split them; it prints one "pasted or from a link" figure. Links that failed to read show only in the capture-miss log. | Message uses the combined figure ("N pasted or from links"). Default taken: no p/l split until a source field exists. |
| WK3 | [g] typed = recipes made through the ghost row (creating op route `claude` or actor `tess`). | [g] equals the "ghost row" figure. |
| WK4 | [c] cooked = Cook objects started in the window. Script prints `Cooks: S started, F finished`. | [c] equals F, finished cooks (default taken; started-only cooks are not "cooked"). |
| WK5 | [t] timers = Kitchen Timer objects in the window. Prints `Timers: N (E stopped early)`. | [t] equals N. |
| WK6 | [e] stopped early = `stopKitchenTimer` op earlier than `endsAt` minus 30 s. | [e] equals E and never exceeds [t]. |
| WK7 | [s] shopped = `startShop` ops (title hold). Prints `Shops: S started ... F finished`. | [s] equals S. Items struck at home without a hold do not count. |
| WK8 | [i] items = live list items on the Groceries list (stable id) created in the window. [r] from recipes = items with a recipe share; [y] typed = the rest. Prints `Grocery items: I (R from recipes, Y typed, Z typed staples)`. | R + Y = I. Z is for the one-third staples signal only, not in the message. |

## States

| ID | State / data | Pass when |
|---|---|---|
| WK9 | Empty week: store has the Recipe class, nothing saved, cooked or shopped. Script prints `Recipes saved: 0 (none)`, `Cooks: 0 started, 0 finished; cook processes by end: none`, `Timers: 0 (0 stopped early); per cook: none`, `Shops: 0 started ..., 0 finished`, `Grocery items: 0 (0 from recipes, 0 typed, 0 typed staples)`. | The message does not fill the template. It reads "Kitchen week one: nothing saved, cooked or shopped yet." then the 3 questions. Never "saved 0 recipes". Default taken. |
| WK10 | Partly empty (recipes saved, no cook, no shop). | Zero clauses drop out: "you saved 3 recipes (3 pasted)." No "cooked 0 times" and no "0 timers". Default taken. |
| WK11 | Thin week: 1 recipe, 1 cook. Script prints `Recipes saved: 1 (1 pasted or from a link)`, `Cooks: 1 started, 1 finished`. | Singular forms: "saved 1 recipe", "cooked 1 time". The timer and shop clauses drop if 0. |
| WK12 | Thin week, 1 cook with 1 timer stopped early. | "cooked 1 time (1 timer, 1 stopped early)". The 1-in-4 rule is not applied under 4 cooks. Default taken. |
| WK13 | Only private recipes. Counts include them (live Recipe objects). | [n] counts them, no title appears. The script prints titles in one place, `Recipes opened but never cooked` (up to 8), so that line is dropped from anything sent on; it never goes in the message. Default taken: no flag for private exists in the script, so titles are never printed in the shared output at all. |
| WK14 | Capture-miss log absent (`capture-misses.jsonl` beside the store; a `.tessera` backup never carries it). Script prints `Capture misses: no capture-misses.jsonl beside the store (it never rides in a backup)`. | The message does not mention misses at all. The line reads as "unknown", never as 0 misses. Q2 still stands; no count is inferred from the absence. |

## What the Kitchen shows

| ID | State / data | Pass when |
|---|---|---|
| WK18 | Kitchen week side. None exists. `sides-77-lines.md` has no Kitchen week row; its "The week" is Settings, WHAT LEAVES THE PHONE (WK-1 to WK-4), which counts Claude calls, not cooks. Design 67 draws Kitchen week with no page of its own. | No Kitchen week side is built. The counts live only in the Oct 22 message. Default taken. |
| WK19 | Real week, in the app. Kitchen shows what Design 67 shows: Groceries count line ("12 to get, for tacos") and Home ("Tacos tonight, 2 to buy"). | Neither line shows a week count. |
| WK20 | Empty week, in the app. Tess has no week line. The Settings week rule applies in spirit: a zero is not a Tess line (E6). | Tess says nothing about the Kitchen week. Default taken. |
| WK21 | Thin week, in the app. | Same as WK19: no line from Tess. The Oct 22 message is the only place the 1 and 1 appear. |

## What no count may contain

| ID | State / data | Pass when |
|---|---|---|
| WK23 | Money. The script reads no price field; items are counted, not summed. The message carries no amount. | No "$" in the message or the script output. The `$3.20` on the Settings glance is Claude's own cost and stays there. |
| WK24 | Body. The script reads Recipe, Cook, Timer, Process, List item, Task, Op and Link only. | No weight, no measure, no body number in output. |
| WK25 | Private titles. Counts include private recipes; titles are never printed in the message. | No recipe, task or note title in the message. Item names are not printed by the script either. |

## Open, defaults taken

1. **p and l are one figure.** Needs a source field on Recipe to split. Default: "pasted or from links".
2. **"Cooked" means finished.** A cook started and abandoned is in the Process end reasons, not in [c].
3. **Zero clauses drop out.** An all-zero week gets one plain sentence.
4. **Private titles.** The script has no private flag, so it should not print titles at all. Core or QA: remove the title list from `Recipes opened but never cooked`, or print the count only.
5. **No Kitchen week side, no Tess line.** If Product wants one later, it gets its own rows in `sides-77-lines.md`, counts only.
