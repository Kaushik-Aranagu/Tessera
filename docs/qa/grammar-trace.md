# Tess grammar trace: kitchen phrases and phrases the kitchen rules take over

*Repo maintainer, 2026-10-15. I traced each phrase by hand through `TessGrammar.parse` on master after #62, with the 10 seed recipes plus Carbonara and Weeknight dal present. This was a static read, so nothing was run. Phrase numbers refer to `docs/product/kitchen-phrases.md`. "K:" means `TessGrammar+Kitchen.swift` and "G:" means `TessGrammar.swift`.*

**Parse order (current, since #70 and #80):** `parseNote`, then the pasted recipe, then the relative set (only with an exercise in focus), then comma sets, then `parseLift`, then `parseKitchen` (list, shop, timer, buy/get, comma list, cook), then `parseTask`. *When this trace was written, every kitchen rule ran before the set, lift and task rules; most rows below were fixed by moving `parseKitchen` after `parseLift`. The current dispatch, with line references, is in [research/grammar-collisions.md](../research/grammar-collisions.md).*

## Kitchen phrases that don't match the doc

Phrases 1–8, 13–17, 19, 21–26, 28–36, 38–40, 48 and 49 match the doc.

| # | Phrase | Expected | Actual | Cause |
| --- | --- | --- | --- | --- |
| 9, 10, 50 | `buy present for mum fri`, `get haircut thu 3pm`, `buy milk tomorrow` | dated task | groceries, with the date kept in the item text | K1: buy/get has no date check (K:25–29) |
| 11 | `call mum, dentist` | not groceries | groceries | K2: comma rule (K:32–39) |
| 12 | `bench 80x8, 82.5x6` | two sets | groceries | K2 |
| 18 | `cook lasagne` (no such recipe) | task "Cook lasagne" | nothing ("Didn't catch that") | **T1** |
| 20 | `cook carbonara` while cooking it | resume the open cook | a second cook | Fix 5 in kitchen-acceptance.md (`Cooking.swift:92`) |
| 27 | `timer 90 seconds` | 1.5 min timer | a 90-**minute** timer called "Seconds" | **T2** |
| 41 | `packing: charger, socks` | add to Packing | groceries `packing: charger`, `socks` | K2, plus Lists slice 8 isn't built yet |
| 42–47 | `add charger to packing`, `run packing`, `pack`, `reset packing`, `pick from films`, `add milk to groceries` | list actions | nothing | Lists slice 8 isn't built yet. Row 43 needs an `add X to groceries` form (K:26 only accepts `add to groceries: X`) |

## New findings

- **T1 (medium): `cook <unknown recipe>` returns nothing.**
  - **Where:** K:67, with the `explicit || date != nil` guard.
  - **Failure:** an explicit "cook" with no matching recipe returns nil, and `parseTask` then needs a date or a task word, so the phrase is dropped.
  - **Fix:** when the phrase is explicitly "cook"/"make" and no recipe matches, return a task "Cook X".
- **T2 (high): timers have no seconds and read bare numbers as minutes.**
  - **Where:** K:46–56.
  - **Failure:** "rest timer 90" (gym rest) starts a 90-minute timer, and "plank timer 60 sec" a 60-minute timer called "Plank sec". If a cook is running, the timer is also linked to it.
  - **Fix:** add `s|secs?|seconds?` to the unit group. With no unit, treat numbers of 30 or more next to "rest" or "plank" as seconds, or require a unit for anything that isn't a cook step.
- **T3 (medium): "today" counts for the same weekday even after its time has passed.**
  - **Where:** G:297–300 (`nextDate`). This predates the kitchen grammar and also affects tasks.
  - **Failure:** on a Thursday evening, "cook carbonara thu" or "call mum thu" gives a task for today at 09:00, which is already in the past. The doc comment says "today counts only if it hasn't passed", but the code never checks.
  - **Fix:** when the weekday is today and the resolved time is at or before now, add 7 days.
- **T4 (medium): `list …` takes over phrases that start with the verb "list".**
  - **Where:** K:15–17.
  - **Failure:** "list the car on ebay sat" creates a new list called "The car on ebay sat" instead of a Saturday task.
  - **Fix:** require "list:" or "new list", or skip the rule when the phrase holds a date.
- **T5 (high, part of K2): explicit task words lose to the comma rule.**
  - **Failure:** "todo call mum, book dentist" becomes groceries. "knee a bit sore, skip lunges" and "email Sam, Priya and Jo" do too.
  - **Fix:** this is covered once `parseKitchen` runs after `parseLift` and the comma rule skips phrases that start with a task word.
- **T6 (medium, part of K4): substring recipe matching with the seed recipes.**
  - **Failure:** "tom 6pm" becomes "Cook tomato and basil pasta" at 18:00, and "make a cake sat" becomes "Cook protein pancakes" on Saturday.
  - **Fix:** match whole words.

## Non-kitchen phrases the kitchen rules take over

Add these as regression rows in `KitchenCaptureTests` so each one stays out of the kitchen.

| Phrase | Intended | Actual on master |
| --- | --- | --- |
| `Squat 100, 5` (dictated) | lift 100 × 5 | groceries |
| `bench 80, 8` | lift 80 × 8 | groceries |
| `80x8, 80x8, 80x6` | three sets | groceries |
| `get 5x5 squats done` | task | groceries |
| `get the car serviced friday` | Friday task | groceries |
| `get up at 6am` | 06:00 task | groceries "up at 6am" |
| `get bloods done and pick up prescription thu` | Thursday task | two grocery items |
| `todo call mum, book dentist` | task | groceries |
| `email Sam, Priya and Jo` | task or nothing | groceries |
| `knee a bit sore, skip lunges` | note or nothing | groceries |
| `rest timer 90` | 90 s rest | a 90-minute timer |
| `plank timer 60 sec` | 60 s timer | a 60-minute timer |
| `boiler timer reset at 6` | task at 6 | a 6-minute timer |
| `tom 6pm` | task "Tom" at 18:00 | Cook tomato and basil pasta |
| `make a cake sat` | task or nothing | Cook protein pancakes |
| `list the car on ebay sat` | Saturday task | a new list |

These stay correct: `call mum friday`, `80 for 8`, `same`. `pay rent on the 1st` isn't taken by the kitchen, but it fails anyway because `TessDates` doesn't read ordinals like "1st".
