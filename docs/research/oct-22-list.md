# Thursday 22 Oct: Kaushik's one morning message (board item 91)

*Research, 2026-10-16, for the coordinator's Thu 22 Oct 9:50 AM PT send. Drawn from `../product/kitchen-week-one.md`
(the three end-of-week questions), `../product/ship-list-m5-money.md` (the five open questions, 4:10 PM PT list) and
`training-week-one-questions.md` (Monday's five). All times Pacific (PDT). Checked against `origin/master` at
`c5d7193`.*

**Shape.** One message, one word per answer, the recommended answer marked with ★. Replying "defaults" takes every ★.
Kitchen first (it is about his week, so it reads warmest), then Money (it is about how the next slice behaves), then
whatever Monday left open.

**Before sending (coordinator, 5 minutes).**
- Kitchen Q2 can be read from data now: `CaptureMissLog` is on master
  (`TesseraCore/Sources/TesseraCore/Diagnostics/CaptureMissLog.swift:1-15`), one JSON line per miss in
  `Application Support/Tessera/capture-misses.jsonl`, with the text cut to 200 characters and its source ("paste" or
  "ghost row"). If the Mac session's copy shows a miss whose text starts with `http`, swap Q2 for the "seen" wording
  below. The log never leaves the phone, so this needs the Mac session's read, not a backup file (backups leave it
  out).
- Fill "Still open from Monday" from his Monday reply. If he answered all five on Monday, delete the whole section and
  its line in the opener.
- If nothing is still open, the message has 8 questions; if Monday is untouched, 13. Above 10, keep Monday's in a
  second short message at 6:00 PM PT instead, so the morning one stays light. Change "8 quick ones" in the opener to
  the real count.

## The message (ready to paste)

```
Morning! 8 quick ones, one word each. Reply "defaults" to take every ★. Nothing changes until you answer.

Kitchen, after your first week:
1. Did you ever want to know if you already had something at home? Yes / ★No
2. Recipe links (yes, already decided) come in Kitchen v2. Want them first? Yes / ★No
3. Was there a moment in the kitchen you reached for something else instead of Tessera? Name it, or ★No

Money, before it's built:
4. A shop name on a spend ("38.20 at Trader Joe's")? Its own field / ★Keep it in the text
5. Currencies: just €, £, $ and ₹? ★Yes / Add one (say which)
6. After a shop, Tess asks "Groceries total?" Can you answer with just "38"? ★Yes / No
7. Does "paid 650 rent" work like "spent"? ★Yes / No
8. "Split 60 with Sam": log your half or the full 60? ★Half / Full

Still open from Monday:
[paste the unanswered ones here, same wording and ★ as Monday's message, numbered on from 9]
```

**Q2 "seen" wording** (use only if the capture-miss log shows a pasted link):
`2. You pasted a link as a recipe on [day] and I couldn't read it. Want link fetch first in v2? ★Yes / No`
Fill [day] from the miss's `at` (his 4 AM day, Pacific, written "Tue"). Here the recommendation flips to Yes, because
the data already says he tried. Quote only the day, never the link itself.

**"Still open from Monday" lines, in Monday's wording** (copy only the ones he did not answer):
```
9. Sat Push A: 17 sets. All of them? ★All / Most / Few
10. If you miss a day, pick up where you left off? ★Yes / No
11. When you say "2 x 10", I ask "sets or kg?". Keep asking? ★Keep / Less / Never
12. Rest day: Sunday? ★Yes / another day / Any
13. Do the app's weights match your gym? ★Yes / Dumbbells / Plates
```
Use Monday's filled-in wording for 9 and 10 (the routine name and set count from his copy) if it went out that way.
Q1 about the warm-up weekend is stale by Thursday: drop it unless Monday's copy showed fewer sets than he trained.

**Note on "defaults".** Replying "defaults" accepts every ★ in this message, including any of Monday's lines pasted in.
Nothing is decided by silence: until he replies, the shipped defaults keep running as they are, and only an answer is
logged.

**Rest day: Sunday is new.** It is not a decision yet. The starter plan has no rest day today
(`starter-content.md` M2). It is logged in `decisions.md` only if he answers "defaults" or "Yes" to it. Silence leaves
the plan as it is (a missed day rolls on, Now never says "Rest day").

## For the coordinator: what each answer changes, and who it goes to

| # | Answer | What changes | Goes to |
|---|---|---|---|
| 1 | **No** (★) | Nothing. Pantry light (P) stays in the v2 backlog, not first | Kitchen lead |
| 1 | Yes | Pantry light (P) moves into Kitchen v2 scope | Kitchen lead, then Product |
| 2 | **No** (★) | L1 keeps its place in v2 (link fetch is already a yes; No only means not first) | Kitchen lead |
| 2 | Yes | Link fetch (L1) moves to the front of Kitchen v2 | Kitchen lead, then Product, then Core |
| 3 | **No** (★) | Nothing new; v2 is scoped from the data table alone | Kitchen lead |
| 3 | A named thing ("clock timer", "paper list", "Notes") | That gap is the first v2 item the Kitchen lead looks at: timer means pause and extend (12b), a list means the shop flow, Notes means capture | Kitchen lead, then Product |
| 4 | **Keep it in the text** (★) | Nothing. "at Trader Joe's" stays in the spend's text; a field can be filled from it later | Core (no change) |
| 4 | Its own field | Slice 1 gains a `shop` text field and slice 4 reads "at X" into it; a small board item | Product logs it; Core |
| 5 | **Yes** (★) | Nothing. EUR, GBP, USD, INR and their symbols only; anything else goes to the model as typed | Core (no change) |
| 5 | Add one | `MoneyAmount.parse` gains that code and symbol, plus one eval row | Core |
| 6 | **Yes** (★) | Nothing. A bare whole number answers only while "Groceries total?" is on screen and no workout is running | Core (no change) |
| 6 | No | A total needs two decimals or a currency mark; eval row 7 keeps "38.20", add a "38" row expecting no spend | Core; Research (eval row) |
| 7 | **Yes** (★) | "paid" joins "spent" as a prefix when an amount follows; a named chore ticks in the same ghost row | Core; Research adds a `grammar-collisions.md` guard row for "paid rent" |
| 7 | No | "paid" stays upkeep only; no change to slice 4 | Core (no change) |
| 8 | **Half** (★) | "split 60 with Sam" logs 30, with "split, 60 total" kept in the text | Core |
| 8 | Full | Logs 60, with "split with Sam" in the text | Core |
| 9-13 | Monday's | As in `training-week-one-questions.md`, Q1 to Q5 tables | As listed there |
| 12 | **Yes** (★) or "defaults" | Logged as a new decision: Sunday off, 6 sessions a week, Now shows "Rest day" | Product logs; Core; Builder B (the line) |

**After he replies.**
- "defaults": log one line in `decisions.md` with the time (PT), naming each question it covered, and the Sunday rest
  day as new. Money questions 4 to 8 then read as approved in the ship list ("Kaushik took every default, <time> PT").
- Kitchen answers go to the Kitchen lead in one message; per `kitchen-week-one.md` the lead then scopes v2 in one
  message to Product, with a recommendation.
- Money answers go to Product (to log) and Core (who builds slices 1 and 4). None of them blocks Core's start: the
  defaults are already in the ship list.
- A reply that answers only some questions: log those, carry the rest to Friday's list unchanged. Never re-ask an
  answered one.
