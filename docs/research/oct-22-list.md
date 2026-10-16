# Thursday 22 Oct: Kaushik's one morning message (board items 91 and 121)

*Research, refreshed 2026-10-16 (item 121), for the coordinator's Thu 22 Oct 9:50 AM PT send. All times Pacific (PDT).*

*Sources:*
- *the Kitchen lead's `../product/kitchen-v2-scope.md` (#349), which replaces the old three kitchen questions;*
- *`../product/ship-list-m5-money.md` (the five money questions);*
- *`decisions.md`: the $50 cap (12:14 AM PT Oct 16, waiting on his yes), calendar titles to Claude (10:29 PM PT Oct 15), recipe layouts (12:32 AM PT Oct 16, C if he says nothing) and `restWeekday` (8:58 PM PT Oct 15, empty until he answers);*
- *`training-week-one-questions.md` (Monday's five).*

**Shape.** One message, one word per answer, with the recommended answer marked ★. Replying "defaults" takes every ★.

Order:
1. Kitchen first: it is about his week, so it reads warmest.
2. Money: how the next slice behaves.
3. Claude.
4. Recipes and training.

Monday's leftovers go in a second short message at 6:00 PM PT, because the morning one already has 12.

**Before sending (coordinator, 5 minutes).**
- **Kitchen numbers.** The Kitchen lead fills the brackets in the kitchen lead-in from his week's data and sends the filled line to Product by 9 AM PT (`kitchen-v2-scope.md`, "What I'll do on Oct 22"). Paste that line as it comes.
- **Drop answered questions.**
  - If he has already answered the $50 cap (10), the recipe layout (11) or the rest day (12) by Thursday, delete that line and renumber.
  - If he answered Monday's rest-day question (Monday's Q4), drop 12.
  - Check `decisions.md` for "Kaushik" after Oct 16 before sending.
- **The opener's count.** Change "12 quick ones" to the real count.

## The message (ready to paste)

```
Morning! 12 quick ones, one word each. Reply "defaults" to take every ★. Nothing changes until you answer.

Kitchen week one: you saved [n] recipes ([p] pasted, [l] from links, [g] typed), cooked [c] times ([t] timers, [e] stopped early), and shopped [s] times with [i] items ([r] from recipes, [y] typed).
1. Did you ever want to know whether you already had something at home? Yes / ★No
2. Did you fix a recipe after saving it, or want to? ★Yes / No
3. Was there a kitchen moment you reached for something else instead of Tessera? Name it, or ★No

Money, before it's built:
4. A shop name on a spend ("38.20 at Trader Joe's")? Its own field / ★Keep it in the text
5. Currencies: just €, £, $ and ₹? ★Yes / Add one (say which)
6. After a shop, Tess asks "Groceries total?" Can you answer with just "38"? ★Yes / No
7. Does "paid 650 rent" work like "spent"? ★Yes / No
8. "Split 60 with Sam": log your half or the full 60? ★Half / Full

Claude:
9. Plan my day sends Claude your task and calendar titles (never notes, places or health). OK? ★Yes / Leave calendar out
10. Raise the monthly Claude limit from $10 to $50, so Tess can remember things and word Home? ★Yes / Keep $10

Recipes and training:
11. Recipe page: the clock (steps by the minute), prose, or two columns? ★Clock / Prose / Columns
12. Rest day: Sunday? ★Yes / Another day (say which)
```

**Why each ★ (for the coordinator, not sent):**
- **2 ★Yes:** recipe edit in place is the Kitchen lead's first default slice. A yes confirms it; a no lets the data decide (the re-parse diff).
- **10 ★Yes:** the coordinator's recommendation. $50 leaves room for memory, Home wording and the week story, about $4 a month at Sonnet prices (architecture 5.6), while a runaway loop still stops. He has $200 of credits a month.
- **11 ★Clock:** Design's recommendation (C, `recipe-layouts.md`). It is also the default if he says nothing, so a "defaults" reply changes nothing built.
- **12 ★Yes:** Sunday is the engine's current placement, and the Day log, Review and Training already read "Rest day" from it. A "defaults" reply logs `restWeekday` = 1 (Sunday).

## Second message, 6:00 PM PT (only if Monday left any open)

Copy only the ones he didn't answer on Monday, with Monday's wording and ★, numbered from 1.

```
Four more from Monday, one word each. "defaults" takes every ★.
1. Sat Push A: 17 sets. All of them? ★All / Most / Few
2. If you miss a day, pick up where you left off? ★Yes / No
3. When you say "2 x 10", I ask "sets or kg?". Keep asking? ★Keep / Less / Never
4. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
```

- Monday's rest-day question is now morning question 12, so it isn't repeated here.
- Use Monday's filled-in wording for 1 and 2 (the routine name and set count from his copy) if it went out that way.
- Monday's warm-up weekend question is stale by Thursday: drop it unless Monday's copy showed fewer sets than he trained.
- If Monday is fully answered, send nothing at 6 PM.

**Note on "defaults".** Replying "defaults" accepts every ★ in that message. Nothing is decided by silence: until he replies, the shipped defaults keep running (the cap stays $10, the recipe page is C, the rest day stays where the engine places it), and only an answer is logged.

## For the coordinator: what each answer changes, and who it goes to

| # | Answer | What changes | Goes to |
|---|---|---|---|
| 1 | **No** (★) | Pantry light stays behind recipe edit in v2's default cut | Kitchen lead |
| 1 | Yes | P. Pantry light (engine only), then W. CAN COOK move to the front of v2 | Kitchen lead, then Product |
| 2 | **Yes** (★) | Recipe edit in place goes first in v2 | Kitchen lead |
| 2 | No | v2's order follows the data (re-parse diff, timers, notes) per `kitchen-v2-scope.md` | Kitchen lead |
| 3 | **No** (★) | Nothing new | Kitchen lead |
| 3 | Clock app | Hands-free cook mode moves up | Kitchen lead, then Product |
| 3 | Paper or Messages for the list | At-the-shop mode gets a review before any new slice | Kitchen lead, then Product |
| 4 | **Keep it in the text** (★) | Nothing. "at Trader Joe's" stays in the spend's text | Core (no change) |
| 4 | Its own field | Slice 1 gains a `shop` text field, filled from "at X" | Product logs it; Core |
| 5 | **Yes** (★) | Nothing. EUR, GBP, USD, INR only | Core (no change) |
| 5 | Add one | `MoneyAmount.parse` gains that code and symbol, plus one eval row | Core |
| 6 | **Yes** (★) | Nothing. A bare whole number answers only while "Groceries total?" is on screen and no workout runs | Core (no change) |
| 6 | No | A total needs decimals or a currency mark; add a "38" eval row expecting no spend | Core; Research |
| 7 | **Yes** (★) | "paid" joins "spent" when an amount follows | Core; Research adds a guard row for "paid rent" |
| 7 | No | "paid" stays upkeep only | Core (no change) |
| 8 | **Half** (★) | "split 60 with Sam" logs 30, with "split, 60 total" in the text | Core |
| 8 | Full | Logs 60, with "split with Sam" in the text | Core |
| 9 | **Yes** (★) | Nothing. Plan my day keeps sending task and calendar titles | Product logs it |
| 9 | Leave calendar out | Plan my day sends task titles only | Product; Core (the plan request); Builder B (the VIA CLAUDE line) |
| 10 | **Yes** (★) | `TessUsageLedger.capNano` goes from $10 to $50 in AI-2. The Settings spend line, the 80% step-aside and the Nov 1 copy follow the number. Product flips the 12:14 AM decision from proposed to decided | Product, then Core (AI-2), then the AI thread |
| 10 | Keep $10 | Cap stays $10. The AI thread re-plans which Claude jobs fit (Home wording on Haiku only, the week story monthly) | Product, the AI thread |
| 11 | **Clock** (★) | Builder B builds layout C. Core gives each step a start minute from the parser's durations | Product logs; Core; Builder B |
| 11 | Prose / Columns | Builder B builds A or B instead; no Core change | Product logs; Builder B |
| 12 | **Yes** (★) | `restWeekday` = 1 (Sunday) in the settings object | Product logs; Core (no code, a setting) |
| 12 | Another day | `restWeekday` = that day. Training's "Rest day tomorrow", Now and Review follow it | Product logs; Core |

**After he replies.**
- "defaults": log one line in `decisions.md` with the time (PT), naming each question it covered.
  - Questions 4 to 8 then read as approved in the money ship list.
  - Question 10 flips the cap decision.
- Kitchen answers go to the Kitchen lead in one message, which then writes the acceptance page for the first v2 slice that day.
- A reply that answers only some questions: log those and carry the rest to Friday's list unchanged. Never re-ask an answered one.
- **Never in this message:** his Claude key. If he pastes it in reply, don't quote it anywhere, and tell him once that it goes in Settings › CLAUDE.
