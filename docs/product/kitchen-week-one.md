# Kitchen week one: what to watch

*Kitchen lead, 2026-10-15. Kitchen v2 (`kitchen-v2-backlog.md`) is held until Kaushik has cooked and shopped with v1 for a week. This page says what to notice that week, so v2 is scoped from what he actually did, not from the backlog's guesses. Most of it can be read from his data (Cook log, Groceries history, the op log) without asking him anything.*

## What to read from the data (QA or the Kitchen lead, end of the week)

| Watch | Where it shows | What it decides in v2 |
|---|---|---|
| How many recipes he saved, and how (paste, ghost row, or a link he wanted to paste) | Recipe objects; any pasted text that starts with `http` | L1-L3 timing: if he tried to paste links, link fetch goes first |
| Paste corrections: how often he tapped a line to change it, and which kinds | `CreateRecipe.corrections` in the op log | Which parser gaps still hurt after Paste hardening |
| Cooks started and finished; cooks abandoned or suspended | Cook log, ProcessTable | Whether cook mode earns its place, and whether the idle rule holds |
| Timers used per cook, and timers he stopped early | Kitchen Timer objects | Pause and extend (12b) |
| Grocery items by source: recipe swipe, typed, ghost row, meal plan | Item shares and actor | Whether pantry light (P) is worth it: lots of hand-typed staples point to "usually by now" (R) |
| Items he struck and then unstruck, or removed straight after adding | Op log undo pairs | Misreads in the kitchen grammar |
| Shops started with the title hold, versus items just struck at home | StartShop runs | Whether at-the-shop mode is used at all |
| "cook X thursday" tasks, and whether those recipes were cooked | Tasks linking recipes, Cook log | Week of dinners, and whether the meal plan feeds groceries |
| Recipes opened but never cooked | Object views (if logged), Cook log | The shelf and CAN COOK (W) |

## What to notice without counting

- Anything he does outside the app because the app was in the way: a paper list, a note in Messages, a timer on the clock app.
- The first thing he says about the kitchen when asked nothing.

## Three questions for the end of the week (ask in one message, each answerable in a word)

1. Did you ever want to know whether you already had something at home? (Yes or no. Yes starts pantry light, P.)
2. Did you try to save a recipe from a website? (Yes or no. Yes moves link fetch, L1, up.)
3. Was there a moment in the kitchen when you reached for something else instead of Tessera? (Name it, or "no".)

Then scope v2 from the answers and the table above, in one message to Product, with a recommendation.

## Data check against master (02903a0, Kitchen lead 2026-10-15)

| Watch | Recorded? | How to read it |
|---|---|---|
| Recipes saved | Yes | Recipe objects with `sourceText`. The creating op's actor and route say whether it came from the paste screen or the ghost row |
| Paste corrections | **Inferred** | `CreateRecipe.corrections` isn't stored, because the op log keeps field changes, not action arguments. Re-parse `sourceText` and diff it against the saved lines and steps; every difference is a correction. This is good enough, so no new field is needed |
| Cooks started, finished, abandoned | Yes | Cook `createdAt`, `cookedAt`, and the Process's `endReason`/`endedAt` |
| Timers used, stopped early | Yes, via the op log | Kitchen Timer `startedAt`/`endsAt`. The `stopKitchenTimer` op's `createdAt` against `endsAt` tells an early stop |
| Grocery items by source | Yes | Item `shares` (a recipe share means it came from a recipe), plus the creating op's actor and route (user typed or Tess grammar). Meal-plan shares carry the task once that slice lands |
| Struck then unstruck, undo pairs | Yes | `checkedAt` changes in the op log, and the op `state` (undone) |
| Shops with the title hold | Yes | A Process with ownerApp "Kitchen" whose subject is the Groceries list |
| "cook X thursday" tasks, cooked or not | Yes | Tasks linking a recipe, matched against Cook `cookedAt` |
| **Links he tried to paste** | **No** | A URL pasted on the paste screen throws "no ingredients or steps found", and nothing is written. In the ghost row it ends at "Didn't catch that.", also unrecorded |
| **Recipes opened but never cooked** | **No** | Nothing records a recipe page being opened |

**Two gaps for Core (small, before Oct 22 if possible):**
1. **A capture-miss log.** Record any capture or paste that ends with nothing written (the text truncated to 200 characters, the time, the route, and where it came from: ghost row or paste screen). It can be an `OpRecord` with a `failed` state, or a small local table. This answers week-one question 2 from data and also catches grammar misses. It must never leave the phone.
2. **`Recipe.lastOpenedAt`** (`.date`), set when the recipe page opens, written without an op so it doesn't flood the log. Lower priority: if it slips, week one skips that row.
