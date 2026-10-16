# Money and body wall (board item 138, MU2)

For: Core and QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Product decided: money-shaped facts and body facts never go to Claude. MU2: "$212.37 at Costco" is screened before any
Claude route, and Tess asks "$212.37 at Costco?" with LOG / NOT NOW on the phone. Body facts stay on the phone too.

The "Master today" column is a hand trace of master bb7f082. Nothing was run. Every value below is made up.
"G:" is `TesseraTess/TessGrammar.swift`, "R:" is `TesseraTess/TessModel.swift`, "C:" is
`TesseraTess/ClaudeTessModel.swift`, "P:" is `TesseraTess/PlanWording.swift`, "M:" is `TesseraCore/Tess/TessMemory.swift`.

**Summary of master today:**
- `TessRouter.run` (R:67-95) checks two things before the routes: a pasted Claude key (R:69) and a secret word (R:74).
  There is no money or body check. `ClaudeTessModel.isAvailable` (C:45-47) checks only the key, the switch and the pause.
- The grammar's money guard (G:116-120) misses on purpose for a leading spend verb or a leading sign. A miss goes to
  the router, so "$212.37 at Costco" reaches Claude whenever "Tess asks Claude" is on. The guard sends money on, it does not stop it.
- Offline, a Claude miss is saved in `TessInbox` (C:111) and sent later (`TessInbox.swift:61`).
- Three Claude callers exist: `ClaudeTessModel` (capture), `ClaudePlanWording` (P:403) and `ClaudeRecipeReader`
  (`RecipeLinkReader.swift:310`). Only capture is wired in `App/AppModel.swift:129`. Home wording and the week story
  have no Claude call on master. `TessMemory.pack` (M:470) has no caller outside tests.
- `TessMemoryScreen` (M:96-170) already refuses money words and measured health for memory lines. Capture never uses it.

## 1. The rule

| # | Part | Default proposed |
|---|---|---|
| W1 | **Money-shaped** | A currency sign or word with a number ("$40", "40 bucks"). A money word with a number: paid, spent, rent, salary, venmo, zelle, paypal, balance, checking, savings, owe, refund, tip ("paid 40", "rent 2100", "venmo'd sam 25"). A shop or food word with a two-decimal number ("costco 212.37"). Account balances and pay ("checking is at 3,412", "got paid 4k") |
| W2 | **Body-shaped** | His body weight: a weigh word (weigh, weighed, weigh-in, bw, scale) with a number, or a lone number with lb or kg and only day words ("182.4 lb this morning", "182.4 this morning"). Vitals: bp, blood pressure, hr, heart rate, resting, hrv, spo2, temp with a number. Sleep as a fact ("slept 5h"). Meds and doses (mg, ml, pill, a drug name, "took 2 advil"). Symptoms (migraine, nausea, fever, rash, a pain word) |
| W3 | **Not body-shaped** | A lift: an exercise word or the live workout with a weight, kg or lb (the load on the bar, not his body). Food and grocery amounts ("rice 2 lb", "500 g flour"). Distances ("5k run"). A plan about sleep with a clock time ("sleep by 11") |
| W4 | **A number is needed** | A money or body word with no number passes ("call mom about money", "budget meeting 3pm", "pay rent friday"). A clock time is not an amount. This matches MU1: no amount means a task |
| W5 | **Where it runs** | One check, `PrivateFacts` in TesseraCore, run in `TessRouter.run` beside the secret check (R:74), before any route's `isAvailable`. A hit may use the grammar and the on-device model. It never reaches `ClaudeTessModel`, the `TessInbox`, or a pack |
| W6 | **What it guards** | Every Claude call: capture misses, Plan my day packs, Home wording, the week story, the recipe reader. Memory lines (told, noticed, recent). Every context pack built from his data |
| W7 | **Packs** | A task or event title that is money- or body-shaped goes as "task" or "busy", like events with titles off (P:77). The block keeps its times |
| W8 | **Tess line** | Money: "$212.37 at Costco?" with LOG / NOT NOW. Body: the body weight ghost where one exists, else a private note "Kept, on this phone only." She never says "Claude didn't see that" for a walled line |

## 2. Rows

Verdict **wall** means it stays on the phone. **passes** means it may go to Claude when the switch is on.

| # | What he types or what a pack would carry | Verdict | Must never reach | Master today |
|---|---|---|---|---|
| MB1 | `$212.37 at Costco` | wall. Ask "$212.37 at Costco?" LOG / NOT NOW | Claude, inbox, memory | Grammar nil (sign first, G:118). Router runs on-device, then Claude (R:75, C:45). **Reaches Claude** |
| MB2 | `costco 212.37` | wall (shop word, two decimals) | same | Miss, no sign or verb (money-us M-US6). Router, then Claude |
| MB3 | `paid rent 2100` | wall. Ask "Rent 2100?" | same | Grammar nil (verb first, G:117). Claude |
| MB4 | `rent 2100` | wall | same | Miss (no sign, no leading verb). Claude |
| MB5 | `venmo sam 25 for pizza` | wall | same | Miss. `venmo` is a memory money word (M:107) but capture never reads that list. Claude |
| MB6 | `venmo'd sam 25` | wall | same | Miss. Claude |
| MB7 | `checking is at 3,412` | wall (balance) | same | Miss. Claude |
| MB8 | `got paid 4k` | wall (pay) | same | "got" is a past verb with no day, so no note. Router, Claude |
| MB9 | `my salary is 142k` | wall | same | Miss. Claude |
| MB10 | `remember my rent is 2100` | wall. "I don't keep sums of money." said on the phone | Claude, memory | No grammar rule ("remember" is read only after a secret word, G:477). Claude gets the phrase first; then `RememberFact` refuses it (M:223-227). **The words already left** |
| MB11 | `coffee 6.25 today` | wall | Claude, packs | **Wrong write:** task "Coffee 6.25" today (money-us M-US9). The title then rides in a Plan pack (MB24) |
| MB12 | `pay rent 2100 friday` | wall. Task "Pay rent" Fri on the phone, amount kept in the task text only | Claude, packs | Grammar nil (verb first). Claude |
| MB13 | `buy a $5 card` | wall (sign with a number). Task "Buy a $5 card" by the grammar; packs say "task" | Claude, packs | Sign not first, so the guard passes it; the buy rule skips money (`TessGrammar+Kitchen.swift:45`). Router, Claude |
| MB14 | `$38.20 trader joe's` with no signal | wall | inbox, Claude later | Grammar nil. Claude fails offline, then `TessInbox` keeps it (C:111): "No connection. Saved it for Claude." **Sent on the next open** (`TessInbox.swift:61`) |
| MB15 | `182.4 this morning` | wall. Body weight ghost (body-weight.md M851), lb | Claude, inbox, memory | No reps, and "this morning" is no day. Router, Claude |
| MB16 | `182.4 lb this morning` | wall | same | Same as MB15 |
| MB17 | `weighed in at 83 kg` | wall. Body weight 83 kg | same | Past verb, no day: router (body-weight.md M850 traces the shape). Claude |
| MB18 | `bp 128/82` | wall. Private note | same | Miss. Claude |
| MB19 | `resting hr 58` | wall. Private note | same | Miss. Claude |
| MB20 | `slept 5 hours` | wall. Private note | same | Past verb, no day. Router, Claude |
| MB21 | `took 2 advil` | wall. Private note | same | Past verb, no day. Router, Claude |
| MB22 | `10mg lexapro` | wall. Private note | same | Miss. Claude |
| MB23 | `migraine since noon` | wall. Private note | same | "noon" is no time word in `parseTask` (inferred). Miss, Claude |
| MB24 | Plan pack, task block "Coffee 6.25" (MB11) | wall. Row title "task" | Claude | `PlanPack` copies every task title (P:77-78). Latent: `ClaudePlanWording` is not wired in the app yet |
| MB25 | Plan pack, task "Pay Sam back $40" | wall. Row title "task" | Claude | Title sent as is (P:78). Latent, as MB24 |
| MB26 | Plan pack, event "Dentist, copay $35" | wall. "busy" | Claude | Event titles go unless `includesEventTitles` is false (P:39, P:77). Latent |
| MB27 | Plan pack, task "Refill lexapro 10mg" | wall. Row title "task" | Claude | Sent as is. The checker reads health words only in Claude's reply (P:289), never the pack. Latent |
| MB28 | Recent memory line "Thu: paid rent 2100 done." | wall | memory, packs | Holds today: "paid" and "rent" are money words, so the line is dropped (`TessMemory+Turnover.swift:104`) |
| MB29 | Recent line from a note "dinner 64.50" or "182.4 this morning" | wall | memory, packs | **Kept.** No money or health word, and the screen licenses the line's own digits (`TessMemory+Turnover.swift:104`). No pack reads it yet (M:470) |
| MB30 | Week story or Home wording: "down 1.2 lb this week" | wall | Claude | No Claude call on master. `WeekFacts.swift:4` already leaves out body weight and money |
| MB31 | `bench 80 x 8` | passes. A lift weight is the bar, not his body | none | Grammar logs the set. Claude only sees the last set in its capture pack (C:145-149) ✓ |
| MB32 | `new best on deadlift 180 kg` | passes (lift, kg) | none | Router, Claude ✓ |
| MB33 | `rice 2 lb` | passes (food with a unit) | none | Grocery line by the grammar ✓ |
| MB34 | `weigh the flour 500 g` | passes. "weigh" with grams and a food is the kitchen | none | Router, Claude ✓. A screen keyed on "weigh" alone would stop it wrongly |
| MB35 | `Costco run saturday` | passes (a place task, no amount) | none | Task "Costco run" Sat ✓ |
| MB36 | `pay rent friday` | passes. Task "Pay rent" Fri by the grammar (MU1: no amount means a task). Its title may ride in packs | none | **Gap:** "pay" first makes `isMoney` true with no amount (`TessGrammar+Kitchen.swift:80-83`), so the grammar returns nil (G:117). Router, Claude |
| MB37 | `call mom about money` | passes (no number) | none | Router or task ✓ |
| MB38 | `budget meeting 3pm` | passes (3pm is a time) | none | Task ✓ |
| MB39 | `sleep by 11` | passes. A plan with a clock time, not a sleep fact | none | Task at 11 ✓ |
| MB40 | `5k run` / `Push A at 6` / `Tacos at 7` / `dune page 140` | passes. "5k" is distance; "k" is money only beside a money word (MB8) | none | Each as today ✓ |
| MB41 | Recipe reader: page text with "$4.99 per serving" | passes. Public page text, not his money; nothing of his is added | none | `ClaudeRecipeReader` sends the trimmed page only (`RecipeLinkReader.swift:339-345`, `trimmed`). Not wired yet |

Totals: 30 wall rows (MB1 to MB30), 11 passes rows (MB31 to MB41).

## 3. Gaps for Core

| # | Where | Default proposed | Owner |
|---|---|---|---|
| MW1 | `TessRouter.run` (R:74-75) | Add `PrivateFacts.isWalled(text)` beside the secret check. A hit skips every route whose `route == .claude`, before `isAvailable`. Grammar and on-device still run | Core |
| MW2 | Money ask (MU2) | A walled money phrase that the grammar can't log asks "{amount} at {shop}?" with LOG / NOT NOW, never "Didn't catch that" | Core |
| MW3 | Grammar money guard (G:116-120, `TessGrammar+Kitchen.swift:80-83`) | Money means a sign or money word **with a number** anywhere. "pay rent friday" becomes a task again (MB36) | Core |
| MW4 | `TessInbox.add` (C:111) and `readWaiting` (`TessInbox.swift:61`) | Refuse a walled phrase at add, and screen again at send (old inbox items) | Core |
| MW5 | `PlanPack.init` (P:77-78) | Money- or body-shaped titles go as "task"; events keep "busy" | Core |
| MW6 | Recent memory line (`TessMemory+Turnover.swift:104`) | Run `PrivateFacts` too, so "dinner 64.50" and "182.4 this morning" drop | Core |
| MW7 | Word lists | One list in TesseraCore. Today money and health words live in `TessMemoryScreen` (M:97-108), `PlanWording.healthWords` (P:192) and `isMoney` | Core |
| MW8 | Future Claude callers (Home wording, week story, packs from `TessMemory.pack`) | Every builder runs `PrivateFacts` on each string it adds. A test fails if a pack builder skips it | Core |
| MW9 | `ClaudeRouteTests` | Type MB1 to MB23 with a fake session and assert zero requests; MB31 to MB40 still reach the fake | QA |

## 4. Question for Product

**Q1.** When a walled phrase misses the grammar, may the on-device model read it? ★ Yes: Apple's model runs on the
phone, so the wall still holds. No would send every walled miss straight to a private note.
