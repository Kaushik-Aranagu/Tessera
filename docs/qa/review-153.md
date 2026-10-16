# Review #153 (merged 65a6598) — Core grammar hotfix: PASS with should-fixes

Static review only. Checked against Product's 4:26 and 4:30 PM PT calls (product/decisions.md), the 4:41
time-form update, and research/fixtures/grammar-misfires.md. GrammarMisfireTests pins 56 rows; it runs in
`swift test`, so the full scripts/test.sh on the install commit covers it.

## Against the calls
- 4:26 #1 bare hours: met. TessDates.find has 1-6 → PM, 12 → noon, and 7-11 → the next unpassed one today (both
  passed → tomorrow morning). am and pm cue words override.
- 4:26 #2 past logs: met. parsePastLog makes a note, dated noon on that past day, via CreateNote `on`
  (createdAt write-through persists through didChange). It runs after lifts and before kitchen, so "bought milk
  yesterday" is a note.
- 4:26 #3 and 4:30 buy/get non-food → task: mostly met, but see G9.
- 4:26 #4 "is"/"are" questions: met. The raw "?" now counts too. "show" only asks as "show me/my/all".
- 4:26 #5 a passed time today lands tomorrow: met for new tasks. Not for reschedules (G10).
- 4:41 (other day, 7-11 without a cue → AM; "dinner fri at 8" → PM): met.
- G8 drain-back in GroceriesView: OK. The unstructured Task outlives the view, but it only writes to dead @State.
- Shop process: "done", "thanks", "ok", errands and buy/get/add/pick no longer land as grocery items. OK.

## Should-fix
- G9 TessGrammar+Kitchen.swift notGroceries: "a/an" plus anything AisleGuide (about 150 words) and IngredientBook
  don't know is treated as a task. "buy a cake", "get a watermelon", "buy a candle", "buy a lightbulb" all
  become tasks. That inverts the 4:30 call ("unclear stays Groceries, Tess names the list"). Fix: drop the
  `a/an + unknown` branch, and keep tasks to the people, gift-shape, service and errand lists.
- G10 TessGrammar.swift parseReschedule (keep what wasn't said): a time-only move puts the new time on the task's
  old day, and a day-only move keeps the old hour. Either can land in the past ("move dentist to 3pm" at 4 PM on
  an overdue or today task), which breaks 4:26 #5. Fix: if the merged date <= now, fall back to found.date
  (which already rolls a passed time to tomorrow).
- G11 TessDates.find "tonight": with no time it sets 20:00, and after 8 PM the passed-today rule rolls it to
  tomorrow 8 PM. The 4:41 call says "tonight" after 8 PM stays today until 11:30 PM. Before this PR it wrote a
  task in the past, so this is an improvement, but it still doesn't match the call. Fix: for "tonight" with no
  time and now >= 20:00, use the next whole hour today (cap 23:30).

## Lows
- G12 isPastVerb's "5+ letters ending -ed" catches names: "Ahmed bday sat" becomes a note dated last Saturday.
  "booked dentist fri" and "moved gym to fri" also read as past logs dated last Friday. One Undo fixes it.
  Consider requiring the remainder to have no future marker ("to", "for", "next").
- G13 TessCaptureEngine: "Noted for Wednesday." for yesterday. "Noted for yesterday." reads better (when()
  only knows today and tomorrow).
- G14 notGroceries lookahead `(?!(?:a|an|some|us|\d))` isn't word-bounded, so it skips any item starting with
  "a", "us" or "some" ("avocados a bag"). It errs toward Groceries, so it is harmless.
