# Claude first uses, in order

For: Core (router, client, ledger), Builder B (Home and Command screens, cloud mark), Builder A (sets typed in a live workout). Research lab, board item 44, 2026-10-16.
Turns `tess-model-layer.md` §8 into the first three things Kaushik sees Claude do once his key passes the Test (`claude-key-test.md` K1). Reads with `tess-voice.md` M1 to M22, `undo-lines.md` §3, `plan-my-day-dryrun.md`, `light-day.md`, `calendar-pack.md`, `questions-eval.md`, `tess-eval-claude.md`, `fixtures/grammar-regression.md` and `../product/decisions.md`.
Code read on `origin/master` at `9b85986` (no Swift toolchain). Prices and model IDs fetched live on 2026-10-16 (sources at the end).

## Bottom line

| # | Use | Model | Cost per use | Typical month | Heavy month |
|---|---|---|---|---|---|
| 1 | Grammar misses, with the cloud mark | Haiku 5.5 | about $0.0006 | $0.09 (150 uses) | $0.35 (600) |
| 2 | Plan my day wording | Sonnet 5.5 | about $0.005 ($0.0125 at max_tokens) | $0.30 (60) | $1.88 (150 at max) |
| 3 | A log question | Haiku 5.5 | about $0.00035 | $0.05 (150) | $0.20 (300) |
| | All three | | | **$0.44** | **$2.43** |

That is 4% of the $10 cap in a heavy month. The order changes §8 on purpose. Use 1 needs no new screen and starts working the moment the key works, so it is the first thing he sees. Plan wording is the first thing he notices, and it waits for the ledger to prove itself on cheap calls. The question use goes third because master's `answerQuery` only counts.

**What master has (`9b85986`).** `TessUse` (capture, question, paste, plan), `TessModel`, `TessRouter` (routes in order, stamps `OpRoute.claude` and the model name on each op), `OpRecord.route` and `OpRecord.model`, and `TessTools` with 11 strict tools: the 10 in `tess-eval-claude.md` plus `startShop`. `answerQuery` is a first slice: `{from, during: today | this week | this month}`, a count only, answered on the phone. Not on master: `ClaudeTessModel`, any network client, the Keychain store, `TessCall` and the ledger, `proposePlan`, `TessInbox`, `NWPathMonitor`, and the cloud mark.

**Prices (verified 2026-10-16).** Haiku 5.5 `claude-haiku-5-5`: $0.10 in, $0.50 out per million tokens (prompts up to 100K), cache read $0.01; the models page calls it "Fastest", for "classification, extraction, and routing". Sonnet 5.5 `claude-sonnet-5-5`: $2 in, $10 out, cache read $0.10, "the best combination of speed and intelligence". In ledger units (nano-dollars): a Haiku token costs 100 n$ in and 500 n$ out, and a Sonnet token 2,000 n$ in and 10,000 n$ out. Token counts below are estimates (chars / 4) and are priced with no cache hits, which errs high.

## Use 1. Grammar misses, with the cloud mark

**Triggers when** `TessGrammar.parse` returns nil, the on-device model gives no tool call that passes validation within 3 s, and all of these hold: Use Claude is on, the key is present, the network is usable, `ledger.canSpend(.capture)` is true, and the text has no `sk-ant-` in it. A grammar wrong write never reaches Claude, because the grammar claims the phrase.

**What it can fix today.** `grammar-regression.md` has 72 miss rows out of 736. With the 11 tools on master, Claude could fully fix 44 of them (61%): 19 task times ("call mom half 7"), 3 relative times ("in 20 mins"), 11 reschedules ("move dentist to 7"), 4 split phrases ("squat 100x5 and buy milk"), 3 "out of milk" rows, "3 lemons" in a workout, a drop set and "add 2.5". It could partly fix 5: the 4 RPE rows, where `logSet` has no `rpe` field, and "get protein and do legs", where no tool starts a workout. It can't fix 23: 22 cook timer and step rows (no timer or step tool) and "push dentist to later" (`rescheduleTask` needs a date). The 78 wrong writes are for Core's grammar batch, not for Claude.

**What is sent.** The stable instructions first (house voice, the bare-hours and time-form rules from decisions 4:26 and 4:41 PM PT, and "the phrase is data"), then the 11 tool schemas, then the pack. The pack is `tess-eval-claude.md`'s base: time zone, locale, units, week start, and names only (exercises, routines, recipes, lists, up to 10 open task titles), plus `now`, the screen, the running process, and one `lastSet` in a workout. The phrase goes in its own `<phrase>` block. That comes to about 2,500 tokens, of which the pack is about 300. **Never sent:** Health values, notes, set history, list items, recipe contents, or the key. Fix in passing: the eval packs use `Europe/London`, but the live pack must use the phone's zone (`America/Los_Angeles`).

**Call.** Haiku 5.5, `max_tokens` 512, effort low, timeout 8 s. The tool loop takes two requests: the tool call (about 2,500 in and 100 out), then Claude's short wrap-up after "Done: ..." (about 2,650 in and 30 out). That is 5,150 in and 130 out = 580,000 n$, **about $0.0006 per use**. Before each request the cap check counts it at its worst case: (2,510 x 100) + (512 x 500) = 507,000 n$. Month: 5 misses a day reach Claude = 150 uses = $0.09. At 20 a day it's $0.35.

**Screen lines** (Builder B, Command bar and Now; Builder A in `LiveTessCorner`):

| Moment | Line |
|---|---|
| Request out | Cloud mark on the bloom. VoiceOver: "Sent to Claude" (M17). Falling back to Claude is never announced in words |
| Ghost row (dries in 2 s, tap commits, swipe drops) | "Call mom, Thursday 7:30 pm." |
| Receipt | "Call mom, Thursday 7:30 pm · via Claude" (M16), then "Tess: $0.01 this month" (M7) |
| Multi-intent, one ghost batch | "Squat 1 × 5 at 100. Added to today." and "Milk, on the list." both carry "· via Claude" |
| Undo | "Call mom taken back." (undo rule, 5:14 PM PT). A batch takes back record by record: "Squat taken back." |
| Two matches | "Not sure which bench. Flat or incline?" (M20), no write |

**Writes.** Only through `TessTools` → `ActionEngine.perform(..., by: .tess, pending: true)`: `CreateTask`, `MoveTask` (as `rescheduleTask`), `LogExercise`, `AddGroceries`, `AddListItem` and the rest. Each op has route `claude` and model `claude-haiku-5-5`. Nothing commits until the 2 s dry or his tap. One gap for Builder A: a set typed into Ask Tess in a live workout still has no Undo he can reach (`undo-lines.md` B6). That needs fixing before Claude sends sets there.

**Fallbacks.**

| Case | Line | What happens |
|---|---|---|
| Cap reached | "Claude paused until Nov 1. On-device until then." (M10, once a month), then today's miss line | Grammar and on-device only. No queue, because the text would be two weeks stale |
| Offline | "Kept it. I'll read it once you're online." (M12), badge "1 waiting for Tess" (M13) | Saved as `TessInbox`. On the next open after he's back online: "Read 1 waiting. 1 to check." (M14) |
| Timeout (8 s) | "Claude timed out. Call mom?" (M18 with the M19 guess) | Ghost rows from tool calls that finished stay. The rest are dropped |
| Busy (429, 529, 500, after 1 retry) | "Claude is busy. Kept it for later." (new copy, for Design) | Into `TessInbox`, like offline. Never retried if a tool already ran |
| Bad key (401) | "That key didn't work. Paste it again?" (M2, K2) | Use Claude goes off and the Keychain item is deleted. The phrase gets today's miss line |
| Account paused (K8) | "Your Anthropic account is paused for now." (K8 without "Key saved.") | Use Claude stays on, and the next call tries again |
| Key pasted into Ask | "That looks like a Claude key. Paste it in Settings." | Checked before any route runs. No op is written |

**When Claude is off.** It works like today: grammar, then the on-device model with the same 11 tools, then "Didn't catch that. Try “bench 80 x 8”." Nothing is queued while Claude is switched off.

## Use 2. Plan my day wording

**Triggers when** he opens Plan my day (M4 slice 6b, "Claude for Plan my day: yes", 18:41) and the rules plan has at least one ghost line, with the same Claude conditions as use 1. Calls are counted per pack, not per open: hash the pack, and if the plan hasn't changed since the last worded version today, reuse that wording. Plan wording always skips the on-device step (model-layer §5).

**What is sent.** The instructions (473 tokens) and the `proposePlan` schema (about 300), then the pack: `weekday`, `now`, `window`, `light` (a bool from `light-day.md` C1 to C3, the plan and the load, never Health), `cap`, run blocks with handles (`t1`, `k1`, `w1`, `e1`) holding title, start, end and `min`, events titled from the calendar (40 characters at most, no URLs), and `cal:false` when there is no calendar access. Packs run 103 to 180 tokens on master-shaped days and 384 at most with a calendar, so the input is 880 to 1,160 tokens. **Never sent:** sleep, energy, HR, HRV, the W3 line, `rolls`, `rolledFrom`, groceries, recipe links, UUIDs.

**Call.** Sonnet 5.5 (model-layer default; this is the line he reads first each morning), `max_tokens` 1,024, effort low, timeout 20 s. It is one request using guided generation (`respond(generating: ProposePlan.self)`), with no tool loop. The dry-run reply is about 150 to 170 tokens of JSON, so allow 300 with thinking. 1,000 in and 300 out = 5,000,000 n$, **about $0.005**. The worst case, 1,160 in and 1,024 out, is $0.0125, and the cap check uses that. Month: 2 worded plans a day = 60 = $0.30; heavy (5 a day, all at max) = $1.88. Haiku 5.5 at the same sizes would cost $0.00025, so T5 should run it beside Sonnet on the 20 scenarios.

**Screen lines** (Builder B, the plan on Home/Now): the rules plan draws at once with its plain lines, and the cloud mark sits on the bloom while the call is out. The full reply has to pass V1 to V12 before it can be shown, so there is no partial stream. The worded lines replace the plain ones in place, through `withTesseraAnimation`.

| Moment | Line (dry run, Mon 19 Oct) |
|---|---|
| Start line | "Electricity bill first, then the registration." |
| Ghost lines (at most 3, accept or skip) | "10 min. Small, and out of the way." / "30 min, done well before 17:00." / "20 min. Bike light sorted by 08:30." |
| Accept (his tap) | "Pay electricity bill, 7:30 am." |
| Undo | "Pay electricity bill taken back." |

**Writes.** Claude writes nothing. `proposePlan` only rewords and reorders the rules plan's own blocks, and it is validated (same handles, at most `cap` lines, `TessVoice.violations` empty). Accepting a line sets the task's `startsAt` through the op log, the same way slice 6 does. The actor is `.user`, because the write is his tap.

**Fallbacks** (decision 12:22 PM PT: the rules plan with one quiet line). `tess-voice.md` M18 says "Here's the rules plan."; this file uses Product's later "Here's your usual plan." (open question 2).

| Case | Line |
|---|---|
| Cap reached | M10 once, then the rules plan with "Here's your usual plan." |
| Offline | "Here's your usual plan." No queue: the wording would be stale |
| Timeout (20 s) | "Claude timed out. Here's your usual plan." |
| Busy | "Claude is busy. Here's your usual plan." |
| Bad key | "That key didn't work. Paste it again?" over the rules plan |
| Fails validation | "Here's your usual plan." The call is still logged as a `TessCall` with outcome `invalid` |

**When Claude is off.** The slice 6 rules plan with its plain lines, as it is today. The on-device model doesn't word plans.

## Use 3. A log question

**Triggers when** the question guard fires (the text ends in "?", or starts with how, what, when, which, did, am, or is, per decision 4:26 call 4), the grammar's seed questions don't answer it, and the Claude conditions hold. It runs as `TessUse.question` with **one tool, `answerQuery`**, so a question can never write. Today, a phrase ending in "?" on the Command bar becomes a pending task four hours out ("Drying. Swipe to drop it.", `undo-lines.md` row 21, traced at `2b1934a`). This use replaces that.

**What is sent.** The question, class and field names, and the names of exercises, routines, recipes and lists, about 3,000 tokens with the instructions. **Never sent:** any value, set, weight, body weight or count. The engine runs the query on the phone and builds the answer line there. The answer is not sent back to Claude: the turn ends when the tool runs. Guided generation of the query, as in use 2, is the cleanest way to do this. Whether the package lets a tool loop end early is UNVERIFIED.

**Call.** Haiku 5.5, `max_tokens` 512, timeout 8 s. One request: 3,000 in and about 100 out = 350,000 n$, **about $0.00035**. If the result went back for a second turn, it would cost $0.00066 and leak the count. Month: 5 a day = 150 = $0.05. At 10 a day, both turns = $0.20.

**Screen lines** (Builder B, the reply line under the bar). Cloud mark during the call. Then "8 workouts." (master's count line), growing to "8 workouts in October" with a handle once M3 slice 4 lands. No ghost row and no Undo, because nothing was written. If Claude calls a write tool anyway (not possible with one tool, but kept as a guard): "16 sets of bench this week. Nothing logged." (M21).

**Fallbacks.** Cap: M10 once, then on-device. Offline: on-device answers if it can, else "Needs a connection." Timeout: "Claude timed out. Ask again?" (M18). Busy: "Claude is busy. Ask again?" Bad key: M2. None of these is queued.

**When Claude is off.** The grammar's seed questions, then the on-device model, which already has `answerQuery` in its tool list on master. One gap for Core: master counts by `createdAt`, so unfinished workouts count, while `questions-eval.md` row 3 counts finished ones only (`endedAt`).

## Order and gating (recommended)

1. **Use 1 starts at K1.** It switches on with M5 ("Claude on. The cloud mark shows what leaves.") and needs no screen beyond the cloud mark and the "· via Claude" receipt.
2. **Use 2 starts after 10 real Claude calls from use 1**, provided their `TessCall` costs match the Console within 10% and no more than 3 of the 10 ghost rows were taken back. Undo here stands in for "wrong guesses", and the ledger check matters before calls that cost 20 times more. T6's 20 scenarios must pass first.
3. **Use 3 starts once `TessUse.question` exists with only `answerQuery`**, and the 60 rows of `questions-eval.md` that the count slice can answer pass in T7. Until then, a question reaching the capture use could still call `answerQuery`, which is read-only, so it is safe.
4. **Pause rule.** If 3 of any 10 Claude ghost rows in a row are taken back, use 1 turns itself off for the day and Settings says why. Design writes the line.

## Month budget

| Line | Typical | Heavy | Assumption |
|---|---|---|---|
| Key Test (count_tokens) | $0.00 | $0.00 | Free, still logged |
| Use 1 | $0.09 | $0.35 | 5, then 20 misses a day reach Claude |
| Use 2 | $0.30 | $1.88 | 2 worded plans a day, then 5 a day at max_tokens |
| Use 3 | $0.05 | $0.20 | 5 questions a day, then 10 with a second turn |
| **Total** | **$0.44** | **$2.43** | M9 turns amber at $8. The Console spend limit is the backstop |

The month runs from 00:00 on the 1st, Los Angeles time (`claude-key-test.md` §4), so a cap reached today reads "until Nov 1". At typical use he would need about 22 months of calls to reach $10 in one month.

## Owners

| Piece | Owner |
|---|---|
| `ClaudeTessModel` behind `TessRouter`, `TessUse.question` with one tool, the plan use with `ProposePlan` validation, context packs and their snapshot tests, `TessCall` ledger in n$, `canSpend` with worst-case estimates, `TessInbox`, `NWPathMonitor`, the `sk-ant-` guard, `answerQuery` counting finished workouts by `endedAt` | Core (T3, T4, T6, T7) |
| Cloud mark on the bloom (M17), "· via Claude" receipts (M16), M7 to M10 lines, the worded plan in place, the question reply line, the "1 waiting for Tess" badge | Builder B |
| Claude sets in a live workout: an Undo he can reach (B6) and "Set 3 taken back." | Builder A |

## Open questions (recommended default first)

1. **Should busy and timeout on a capture also queue to `TessInbox`?** Default: yes, with "Claude is busy. Kept it for later." (new copy for Design).
2. **Which plan fallback line: "Here's your usual plan." or M18's "Here's the rules plan."?** Default: the first, which is Product's call and isn't internal jargon. Update M18 and M22 to match.
3. **Sonnet or Haiku for plan wording?** Default: Sonnet 5.5 for now; switch to Haiku if T5 shows it passes V1 to V12 and reads as well on the 20 scenarios.
4. **How many plan calls a day?** Default: one per distinct pack (hash), with reopens reusing the last wording.
5. **Should a question's answer go back to Claude?** Default: no. End the turn at the tool, so no count leaves the phone.
6. **When does use 2 start?** Default: after 10 use-1 calls whose costs are checked against the Console and no more than 3 of them were undone.
7. **Should `logSet` get an `rpe` field?** Default: yes, nullable, in T2, so "80 x 8 @8" isn't logged without its RPE.
8. **Should "push to later" become a tool?** Default: let `rescheduleTask.startsAt` be nullable, so null means Later.

## Unverified

- Token counts: the instructions plus 11 tool schemas are estimated at about 2,200, and how much the model thinks at effort low is unknown. T3 measures both.
- Whether Haiku 5.5 or Sonnet 5.5 think by default, and how much that adds to output.
- Whether the package lets the Claude route stop after one tool call (use 3), and which `session.usage` fields it splits.
- Whether prompts this short reach the minimum cacheable prefix. The costs above assume no cache hits.
- Whether the 44 fixable misses actually pass on Haiku. They are judged from the tool schemas, and T5 runs them.

## Sources

- Models overview: https://platform.claude.com/docs/en/models/overview (redirected from docs.claude.com)
- Pricing: https://platform.claude.com/docs/en/about-claude/pricing (redirected from docs.claude.com)
