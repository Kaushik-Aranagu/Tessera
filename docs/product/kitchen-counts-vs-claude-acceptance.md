# Kitchen counts vs Claude: acceptance rows KC1 to KC32

*Kitchen lead, board K68, 2026-10-17. Docs only, no code. One rule, two halves. **On the phone**, a Kitchen count keeps private things and hides only their names (decisions 3:25 #1): a Private recipe is counted as a cook, a Private item is counted as a row to buy, and every surface that prints the thing prints "Private recipe" or "Private item". **To Claude**, nothing private goes at all: no name, no text, no lines, no share, and no count that includes it. So the same Friday can read "4 cooks this week, 18 to buy." on the screen and be worded for Claude as 3 cooks and 15 rows. Rows are runnable on the simulator with a stubbed Claude (see "Test hook"). "Fails today" is read from master's code, not run; most of these have no trigger on master yet because nothing marks a recipe or an item Private (gap hunt 4, G21).*

**Sources.** `kitchen-refill5-acceptance.md` K32 (private recipe walls, K32.15 "a stubbed Claude records nothing about it"), K29 (walled grocery lines, "Private phrase" in the sent log); `kitchen-refill6-lane2-acceptance.md` K39 (the grocery link ask); `kitchen-refill7-acceptance.md` K43 (photo read), K44 (USUALLY, K44.8); `kitchen-refill8-acceptance.md` K51 to K58; `kitchen-first-month-script.md` (the fixture below); `kitchen-v2-acceptance.md` (COOKS, section 7); `never-sums-audit.md` (N rows); `TesseraCore/.../Tess/PrivateFacts.swift` (money and body wall), `TesseraTess/PlanWording.swift` (`PlanPack`), `TesseraTess/RecipeLinkReader.swift`, `Features/Settings/ClaudeSection.swift` (the receipts). Where a copy line is a guess it says "proposed, Product to rule".

**House rules.** Receipts name the thing first and use "on" ("Milk, on Groceries."). No "at" before a time. Clocks lowercase ("9:05 am"). Digits for counts. US English. "Private item", "Private recipe", "Private note". No daily cap on grocery asks (the monthly spend cap is separate and unchanged). Link and reader asks fire only on his tap. Money and body facts never go to Claude. Nutrition is never summed: PER 100 G, one ingredient only. No row, fixture or log holds a key or key-shaped text.

## Fixture (the first-month store, day 23, Tuesday, derived from `kitchen-first-month-script.md`)

- Recipes saved: 5 (Tacos, Weeknight dal, Chili, Overnight oats, and **Passcode stew**, which is Private: PF4 default, a secret word in the title).
- Plans this week: Tacos Thursday, Dal Saturday, Chili Sunday, **Passcode stew Friday 7 pm**. Shown "4 cooks this week, 18 to buy." (15 rows carry a share of Tacos, Dal and Chili; 3 more carry the stew's share).
- Groceries: 17 open rows from day 22 plus the stew's 3 rows (**Private item** each) is **20** open rows (derived). Shown "20 to get".
- Typed: the walled row "Ozempic refill" (**Private item**) is the 21st. Rows that say "with the walled row" show **21 to get**; the others use 20.
- Cooks: Passcode stew cooked 3 times (45, 47, 43 min), median 45. Tacos 4 times, median 45.
- Pantry (build target): Milk, Limes out; **Private item** (the medicine) out; Rice, Lemons low. Shown "3 out, 2 low".
- "Tess asks Claude" yes, a key present on the simulator (a test value held in the harness, never in a file).
- The "private" set for sending is: the Passcode stew recipe and everything linked to it (its steps, its 3 rows, its plan task, its cooks), the walled Groceries row, and the walled Pantry item. Everything else is "ordinary".

## Test hook (proposed, a test seam, no product change)

A stubbed Claude, `RecordingClaude`, replaces the transport under `ClaudeTessModel` and `RecipeLinkReader`. It answers with a canned reply per job and keeps, per call, `job` (the `TessUse`/job name), `body` (the exact request text) and `at` (a Date). The Settings receipts read from the real ledger, which the stub still feeds. Three helpers carry every row:

1. **`assertNoPrivate(calls)`** greps every `body` for a deny list built from the fixture's private set: the title "Passcode stew", each of its ingredient words, its step words, "Ozempic", the medicine word, and the words "Private recipe" / "Private item" themselves (a mask label sent to Claude still tells it a private thing exists, so even the label is out; sent text says nothing, or a neutral handle such as "task").
2. **`assertCounts(calls, shown:, sent:)`** reads the numbers in the `body` and checks each equals the **sent** figure (3 cooks, 15 rows) and never the shown one (4, 18), and that no number in the body equals shown-minus-sent arithmetic that would let Claude subtract (for example the body never carries both 18 and 15).
3. **`assertNoSums(calls)`** fails if any `body` holds a calorie, protein, carbohydrate, fat or fiber figure for more than one ingredient, or a total, per recipe, per day or per week (the never-sums rule, N rows).

Where a row says "zero calls", the stub's list is empty and the sent log gains no row.

## A. On-screen counts keep private, names hidden

| # | Surface (count) | Action | Expected (exact copy) | Fails today? |
|---|---|---|---|---|
| KC1 | Recipe COOKS line, median (`kitchen-v2-acceptance.md` 7.5, Tess cobalt) | Open Tacos, then Passcode stew; open the COOKS side of each | Tacos: "Cooked 4 times, about 45 min." Stew: "Private recipe, cooked 3 times, about 45 min." (proposed, Product to rule the private form; the count and median are real, the name is the mask). The count is never lowered or hidden because the recipe is private | Not built for private: nothing marks a recipe Private (G21). The ordinary line is the ruled one |
| KC2 | Cook finish line, cooks this month (`Kitchen/Cooking.swift:63-67`, `finishLine`) | Finish the stew on a day the second cook of the month | "Private recipe, second time this month." The ordinal counts the stew's own cooks; the title never prints (`finishLine` takes `recipe.title` raw today). Overnight finishes after midnight follow his 4 am day and month (G23) | Yes. `finishLine` prints the recipe's own title; there is no mask branch |
| KC3 | Week side, cooks planned (K38; the first-month fixture) | Open the week side, Tuesday | "4 cooks this week, 18 to buy." The stew's cook and its 3 rows are in both numbers. Friday's row reads "Private recipe, 7 pm." | Not built (week side is a build target) |
| KC4 | Groceries count line (`GroceriesView.swift`, `GroceriesCopy.context`) | Open Groceries | "20 to get, for tacos and 3 more" with the stew's rows counted and, in the FOR WHAT side, the stew named "Private recipe" (K32.14). Never "17 to get" (a count that hides the private rows). With the walled row: "21 to get" | Partly. The count line counts every open row today; the private label is the unbuilt half |
| KC5 | Home "to buy" on a planned cook (`HomeLines.swift:402-404`) | Thursday, open Home with Tacos planned and the stew's rows still open | "Tacos, 7 pm, 2 to buy." counts only Tacos' own rows (the line is about Tacos). A private cook's line reads "Private recipe, 7 pm, 3 to buy." (proposed join, Product to rule). At 0: "nothing to buy" | Home does not draw a planned cook yet (G19) |
| KC6 | Pantry out and low (build target; K26, K28) | Open Pantry | Hero "3 out, 2 low". The private item is one of the 3 and is listed as "Private item, out". The side's key reads "ADD 3 TO GROCERIES"; the receipt for the private one is "Private item, on Groceries." | Build target |
| KC7 | Groceries USUALLY (K44.2, K44.8, K63; Pantry K58) | Buy "Ozempic refill" 4 times a week apart; open Groceries and the Pantry | Both lines name up to 4 and then "and N more". The private name shows as "Private item" in the line and counts as a name (K44.8, ruled Oct 17). Tapping it adds "Private item, on Groceries." and shows its words only after a second tap on that row | Build target. Open flag F1 in `kitchen-refill8-acceptance.md` says Groceries and Pantry differ on whether the mask is drawn; Product to say they agree (the ruling reads as: drawn as "Private item", in both) |
| KC8 | Day-log and Review counts (WK rows; the Oct 22 message) | Run the counts script on a copy of the store | The message says "you saved 5 recipes" and "cooked 4" (the stew counts), and prints no title or line (WK13). Counts on the phone are the same numbers with names hidden | Script exists (PF12); the private case waits on G21 |

## B. Anything sent to Claude drops them

| # | Claude job and input | Action | Expected (exact copy, or what the body holds) | Fails today? |
|---|---|---|---|---|
| KC9 | **Link read** (`RecipeLinkReader`, the one page's text, only on his tap) | Paste a recipe link, tap READ; the page has no card, so Claude reads it | Body holds the page's text and the fixed instruction. It holds no Kitchen figure at all: no recipe count, no shelf title, no Groceries row, no cook, no count of anything on the phone. `assertNoPrivate` and `assertCounts` pass with an empty set of numbers. Receipt row: the job with the time only ("9:05 am", G31) | Likely passes on content (reader sends the page). Receipt names it "A paste" (G31) |
| KC10 | Link read, **no tap** | Paste a link and wait 2 minutes; switch tabs; reopen | Zero calls. A link in the box, a saved link, a background refresh and a restore never send. Line stays "Recipe link, kept for later." where the ruled offline form applies | Passes by the ruling (reader runs on tap) |
| KC11 | **Grocery wording**, the groceries link ask (AI-12, `linkItems`; K39) | Plan tacos and the stew; then tap the link ask for the leftovers | Body holds handles and titles of ordinary rows only (A1 to A5 of `groceries-ai-runnable-rows.md`): the stew's 3 rows and the walled row are not in the handle list, are not "task" or "item" placeholders either, and are not in any count. The ask words ("{Row}, for the {recipe}?") come from the phone. If every leftover is private the ask is not made: zero calls, no line | Build target (private marking, G21) |
| KC12 | Grocery wording, a typed **miss** (a capture to Claude) | Type "oatmilk" (ordinary) then "Ozempic refill" (walled) on Groceries | Oatmilk: one call, body holds the phrase and the fixed instruction, no list rows, no count of rows. The walled phrase: no call, no receipt row (K29.4); if it is stripped and sent as a stripped phrase, the row reads "Private phrase" with the time (K29.5). Never a price or a number from it | Passes in the walls (`PrivateFacts`, `EngineWall`); the Kitchen row text is the build |
| KC13 | **Plan wording** (`PlanPack`, `PlanWording.swift`) | Tuesday, Plan my day with the stew planned Friday and Tacos planned Thursday | Today's pack only. A planned Tacos cook due today goes as its task title "Cook tacos". The stew's task is "Private recipe" on the phone and goes as the neutral handle "task" (the existing rule for a walled title) with its kind and time, never the string "Private recipe", never its three rows, never "cook" as a recipe word. The pack carries no count of cooks and no "to buy" figure for the week | Yes, once a recipe can be Private: `PlanPack.isPrivate` tests `SecretWords.mentions` and the money and body wall, and "Private recipe" is neither, so the label would pass through as a title |
| KC14 | Plan wording, **counts** | Same as KC13, week of 4 cooks and 18 rows | `assertCounts(shown: 18, sent: nil)`: the plan pack never holds the shopping count at all. If a later build sends one, it sends 15, never 18, and not both | Passes today (no Kitchen count in the pack, read) |
| KC15 | **Home lines** (`HomeDonePack`, the `.lines` job: Home's two slots) | Finish a workout after the stew cook and a shop; the job runs for Home | The pack holds the workout's own facts as today. Kitchen enters as an ordinary finished cook's name only if ruled in; a Private cook is absent and does not even raise a "something was cooked" flag. The slots never read "4 cooks" or "18 to buy" | Passes today (no Kitchen fact in the pack, read). Row holds the line when Home's cook lines (G19) are built |
| KC16 | Photo recipe read (K43; on device) | Read a photo of a recipe | No image leaves the phone (K55). Zero Claude calls from the photo; any text step that goes to Claude is the recipe text only, as KC9 | Build target |
| KC17 | Pantry (K28.13, K58.19) | Open Pantry, cycle states, tap ADD 3 TO GROCERIES | Zero calls. The sent log gains no row. The pack snapshot holds no state and no bought date | Build target |
| KC18 | Tess answers a **question** that touches the Kitchen ("how many times did I cook tacos?") | Ask with "Tess asks Claude" yes | The phone answers from the ledger: "Tacos, 4 times." The question goes to Claude only if the phone cannot read it, and then the body carries the question text only, no log, no counts of other recipes. A question naming the stew gets the phone's answer ("Private recipe, 3 times.") and no call | Yes for the stew; ordinary path is as today |
| KC19 | "Tess asks Claude" **no** | Switch to no; repeat KC11, KC12, KC13 | Zero calls on all three. The link-read tap is the one open case (G32, Product to rule). The sent log gains no row | Per G32 |

## C. The pairs (one number, two audiences)

| # | Pair | Action | Expected | Fails today? |
|---|---|---|---|---|
| KC20 | Cooks this week: shown 4, sent 3 | Run KC3, then any job that could carry a cook count | The screen says 4. `assertCounts` over every job's body finds no "4" as a cook count and finds 3 only where a job is allowed to carry a cook count (none today). A body that contained both 4 and 3 for cooks fails | Build target |
| KC21 | Rows to buy: shown 20 (21 with the walled row), sent 15 | Run KC4, KC11 | Same test: no 20, no 21, and 15 only if the job carries a row count. The difference (5 or 6) is never recoverable from the body (no list of what was left out, no "N hidden", no "and 2 more") | Build target |
| KC22 | Pantry "3 out, 2 low": shown 3 and 2, sent none | Run KC6, KC17 | No Claude call ever carries Pantry state. The count lives only on the phone | Build target |
| KC23 | USUALLY: shown 4 names with a mask, sent none | Run KC7 | No Claude call ever carries a usually name or a buy gap. The mask is a view of the phone's own list | Build target |
| KC24 | Receipts in Settings: the log says what was sent, not what was kept back | Run KC11 to KC13, then open Claude, the amount, the receipts | One row per call with time, job, model, cents. A call skipped for a private reason leaves no row. No row says "private", "skipped", "held back" or a count of what was held back (that would tell the log reader what exists). Exception: the walled-phrase row "Private phrase" and the time, as ruled (K29.5) | Partly (G31 job names) |

## D. Never sums, whatever the audience

| # | Surface | Action | Expected | Fails today? |
|---|---|---|---|---|
| KC25 | Any Claude body, any job | Run the whole file with `assertNoSums` on | No body holds a nutrition figure for more than one ingredient, or any total. The grocery ask, the link read and the plan pack carry none at all. A recipe's own nutrition is not read, built or sent | Passes today (no nutrition in any pack, read) |
| KC26 | Recipe page, Groceries, Week, Pantry, Home | Ask Tess "how many calories is this week?" and "how much protein in the tacos?" | "I don't add food up. Ask me about one ingredient." (exact, `kitchen-refill5-pantry-acceptance.md` K28.26, N8). For one ingredient: "Chicken, per 100 g: 165 kcal." as one line, one ingredient, labeled PER 100 G. No sum for a recipe, a day, a week or a shop. No Claude call to produce either line | Build target for the ingredient table; the refusal is ruled |
| KC27 | On-screen counts that look like sums | Read every count in section A | Counts are of things (cooks, rows, names). None is a quantity, a price, a calorie or a macro sum. "18 to buy" counts rows, not units | Passes by construction |

## E. Money and body, always

| # | Surface | Action | Expected | Fails today? |
|---|---|---|---|---|
| KC28 | A grocery row with money ("milk $4") | Type it on Groceries | The row lands as "Milk, on Groceries." The "$4" is dropped before anything is stored (K28.20). No Claude body holds "$", a price word or "4" as a price. The line is not a "Private item" unless it also trips a wall | Passes in the walls |
| KC29 | A body fact in a recipe or row ("protein shake for my 82 kg") | Type it | The row follows the body wall: "Private item" or "Private note" as ruled. It is counted on the phone and absent from every Claude body | Passes in the walls; Kitchen text is the build |

## F. Accessibility and surfaces

| # | Surface | Action | Expected | Fails today? |
|---|---|---|---|---|
| KC30 | VoiceOver on a count that includes a private thing | Focus the Groceries count line, the Week count, the Pantry hero | Reads the count and the mask: "20 to get, for tacos and 3 more." The mask is read as "Private item", never as "hidden" or "redacted", never a letter-by-letter spell-out. No hint says "includes private things" | Build target for the mask |
| KC31 | Dynamic Type AX5 on KC1, KC3, KC6 | Raise the type size | The count wraps; the mask word stays whole; nothing truncates a count to hide the private part | Build target |
| KC32 | Locked-phone surfaces (Siri, widget, Live Activity) | Ask Siri "What's for dinner?" on Friday, locked; read the widget | "Private recipe, 7 pm." with the count words intact where the surface has them ("3 to buy"). Same words as Home (K52, KW-W8) | Build target |

---

## Notes for Product and Builder

1. **The one thing to rule**: the form of a private count line on the phone. Proposed throughout: the thing's own mask, the real number ("Private recipe, cooked 3 times, about 45 min."). Nothing in the file moves if Product picks a different form, because the Claude half never prints a mask.
2. **KC13 is the first real catch**: `PlanPack.isPrivate` only knows the secret word, money and body walls, so a task titled "Private recipe" would be sent as that title. A private cook must go as the neutral handle. This lands with the Mark-a-recipe-Private build (G21, K61).
3. **KC7 and flag F1 are one question**: ruled Oct 17, the mask shows in USUALLY as "Private item" in both places. Product to confirm the Groceries line draws it too (`kitchen-refill8-acceptance.md` F1).
4. **KC24 is a design choice worth a sentence from Product**: a receipts log that says "held back" would itself leak that something private exists. Default taken: it says nothing.
5. **The test hook is a seam, not a feature**: `RecordingClaude` is test-only, holds request bodies in memory, writes no file, and never holds a key.
