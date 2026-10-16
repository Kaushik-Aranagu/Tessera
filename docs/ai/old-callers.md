# Old Claude callers onto `ClaudeClient` (ship list AI-13)

The migration map for Core. Read `claude-client.md` first; this note uses its names (`TessJob`, `TessPack`,
`Outcome`, `Failure`). Rule from the ship list: no change in behavior, Tess lines or ledger rows, and each move
happens only when someone is already in that file. Line numbers are this tree's. Paths are under
`TesseraCore/Sources/TesseraTess/` unless given.

## 1. Every place that talks to Claude today

Four callers, each with its own copy of the request (all post to `ClaudeKeyCheck.base`, `ClaudeKey.swift:193`,
with `x-api-key`, `anthropic-version: 2023-06-01`, `content-type`). One retry path and one ledger. Nothing in `App/`
or `Features/` builds a request; the app only constructs two of them.

| Caller | Wired from | Model, max tokens | Tools, tool choice | Timeout |
|---|---|---|---|---|
| `ClaudeTessModel` `ClaudeTessModel.swift:9`, send `:204` | `App/AppModel.swift:129` (not in demos) | Haiku 5.5, 512, up to 3 rounds (`:13`) | all `TessTools`, `auto` (`:215`), no effort | 8 s idle per round (`:21`) |
| `ClaudePlanWording` `PlanWording.swift:403`, send `:563` | tests only | Sonnet 5.5, 1024 | strict `proposePlan`, `auto` (`:580`), effort low | 20 s hard deadline (`:474`, `:548`) |
| `ClaudeRecipeReader` `RecipeLinkReader.swift:310`, request `:362` | tests only (`RecipeLinkReader.claude`, `:94`) | Haiku 5.5, 4096 | none, no `tool_choice`, effort low | 20 s idle (`:318`) |
| `ClaudeKeyCheck` `ClaudeKey.swift:180`, send `:284` | `Features/Settings/ClaudeSection.swift:333` | Haiku 5.5; `count_tokens`, then 1 token with thinking disabled (`:240`) | none | 10 s idle (`:287`) |

Also in scope: `TessInbox.add` (`TessInbox.swift:25`, called from `ClaudeTessModel.swift:111`) and
`readWaiting` (`TessInbox.swift:56`, sets `retrying`, no app caller yet). The router's key and secret checks
(`TessModel.swift:69`, `:74`) stay in the router. `TessUsageLedger` (`ClaudeKey.swift:86`): `reserve` `:131`,
`settle` `:138`, `estimate` `:143`, `record` `:157`.

## 2. Each caller today, and the job it becomes

**Capture, `ClaudeTessModel`.** Gates: `isAvailable` (`:45`: key, `sendsMisses()`, not paused), then
`commitImmediately` returns `.missed` before any money (`:51`). Reserves `estimate(text + system + tools) * 3`
(`:55`); at the cap returns "Claude paused until <date>." with no row (`:61`). One row for the whole run, use
`.capture`, tokens summed over rounds, cost with cache read and write, latest `request-id`; outcome "works",
"nothing", or the `Failure` outcome (`:105`, `:117`). `max_tokens` and `refusal` become `Failure.other` (`:77`).
Errors (`:222` to `:233`): 401/403 badKey, 429 and 5xx busy except 504 timeout, `URLError.timedOut` timeout, any
other `URLError` (cancel included) offline, anything else other; a billed 200 with no content keeps its tokens
(`:240`). Offline and not retrying: `TessInbox.add`, line "No connection. Saved it for Claude." Redirects: followed
by the default session; no guard. Becomes job **"capture"**: Haiku, 512, no effort, `output: nil`,
`writeTools` = every `TessTools` name, `toolChoice: .auto`, priority `.capture`, timeout 8, up to 3 rounds.
Byte-identical: the five `Failure` lines (`:194` to `:201`), the paused line, the inbox line, the one-time
"Sent ... to Claude" line (`:129`), the voice-checked fallback line (`:124`), the fixed tool error lines (`:93`),
discard of pending records on failure, and the row fields above.

**Plan, `ClaudePlanWording`.** Gates: pack, `allowed()`, key (`:433`); a same-pack reuse and a failure remembered
for the day spend nothing (`:435` to `:443`). Reserves `estimate(instructions + schema + pack)` (`:445`); note the
pack term is the parsed object's Swift description, not `pack.json`. Cap line "Claude paused until <date>. Here's
your usual plan." with no row. One row per call in a `defer` (`:458`): use `.plan`, cost from input and output
only, `request-id`; outcomes "works", "late", "max_tokens", "refusal", "rejected V1", "rejected " + codes,
"cancelled", or the `Failure` outcome. Errors (`:588` to `:604`): as capture, but `URLError.cancelled` and
`CancellationError` give "cancelled" and no line. Lines per failure at `:478` to `:482`. Becomes job **"plan"**:
Sonnet, 1024, effort "low", `output` = the strict `proposePlan` tool, `toolChoice: .auto`, priority `.plan`,
timeout 20, `writeTools: []`. The `worded` and `failed` memory (`:417`, `:419`) stays in `ClaudePlanWording`.

**Recipe link, `ClaudeRecipeReader`.** Gates: `allowed()`, key (`:351`), returning the no-recipe line. Reserves
`estimate(instructions + trimmed page)`; cap line `RecipeLinkLine.paused`, no row. One row in a `defer` (`:374`):
use `.paste`, input and output cost only, **`requestID: nil`**; outcomes "works", "nothing", "max_tokens",
"badKey", "busy", "timeout", "offline", else "other". Errors: 401/403 badKey; 429 and every status >= 500,
504 included, busy; other `URLError` offline; a non-`URLError` throw keeps outcome "other" with the no-recipe line;
a 3xx is followed (no guard on this call; `RedirectGuard` `:422` guards only the page fetch). A `refusal` stop
lands as "nothing". Becomes job **"recipeLink"**: Haiku, 4096, effort "low", `output: nil`, no `tool_choice`,
priority `.recipe`, timeout 20. Byte-identical: every `RecipeLinkLine` it returns and the nil `requestID`.

**Key check, `ClaudeKeyCheck`.** No switch: Settings calls it directly and fires `.askClaude` itself
(`ClaudeSection.swift:332`). Prefix and length check, then `keys.save` (`:212` to `:219`); those two outcomes
write no row. `count_tokens` first, with no reserve and cost 0. Only the fallback (404, 405, or an unreadable 200)
reserves (`:235`); at the cap it records "capReached" at cost 0. Every other result records one row (`:276`):
use `.keyCheck`, outcome `Outcome.rawValue`, `request-id`. Its status map (`:301`) differs from the shared one:
403 notAllowed, 402 and the spend-limit 429 and 400 accountPaused, only 429, 500 and 529 busy, 501 to 503 other;
only five `URLError` codes are offline, the rest other. A 401 keeps the key. Becomes job **"keyCheck"** in name
only: it borrows the headers, the request-id read and the row writer, keeps its own `Outcome`, map, lines,
`count_tokens` path and thinking-disabled body (`TessJob` has no thinking field), and passes `touched: []`.

## 3. Order of moves, smallest risk first

Each move waits until someone is in that file for other work. Before each, run the listed tests green, keep them
unchanged through the move, and add a body test that decodes the request (today's bodies come from `[String: Any]`
through `JSONSerialization`, so key order is not stable and "byte-identical" means rows and lines, not wire bytes).

1. **Recipe link** (no app caller, one round, no tools). Pin: `RecipeLinkTests` `claudeReadsOnlyWhenAllowedAndUnderTheCap`,
   `claudesKeyAndBusyAndCutOffLines`, `aPageWithNoCardIsReadFromItsText`, `theLinesAreTheTable`. Add: a 504 stays
   "busy", the row's `requestID` stays nil, a 3xx is "unreadable" (decided), and a page
   with prices is sent with them stripped, never refused.
2. **Plan** (no app caller; already has the deadline, `stale` and the outcome strings `ClaudeClient` copies).
   Pin: `PlanWordingTests` `claudeWordsItOnceAndTheSamePackIsReused`, `everyFailureShowsTheRulesPlan`,
   `atTheCapNothingIsSent`, `eachFailureHasProductsLine`, `aRejectedPackIsRememberedAndTheSwitchIsOne`,
   `aCutOffReplyShowsTheRulesPlan`, `aMinuteLaterTheWordingIsReusedAndAFailureIsRememberedToday`.
3. **Key check** (wired in Settings, but shares only headers and the row). Pin: all of `ClaudeKeyTests`, chiefly
   `statusMapsToOutcome`, `networkFailuresKeepTheKey`, `aMovedEndpointFallsBackToOneTokenAndIsPriced`,
   `atTheCapAWorkingKeySaysPaused`, `notAKeyIsNeverSent`, `twoCallsAtOnceCannotBothPassTheCap`.
4. **Capture** last (wired, multi-round, writes ghosts, feeds the inbox). Pin: all of `ClaudeRouteTests`, chiefly
   `aMissGoesToClaudeAndLandsAsAPendingGhost`, `everyFailedCallWritesItsRowAndAnEmptyBilledReplyCounts`,
   `aCutOffOrRefusedReplyMakesNoGhost`, `toolErrorsGoBackAsFixedLines`, `anOfflineMissWaitsAndIsReadLater`,
   `nothingWaitsForSiriAndAKeyNeverWaits`, `atTheCapNothingIsSentAndTessSaysUntilWhen`; and
   `LowsTwoTests.waitingPhrasesCanBeLetGo`. Add: a cancelled `URLError` still queues as "offline".

Callers used only in tests: `ClaudePlanWording`, `ClaudeRecipeReader`, `TessInbox.readWaiting`.

## Where code and docs differ

- **Walls change behavior, on purpose.** `claude-client.md` step 2 refuses money-shaped packs using `moneyWords`
  ("$", "cost", "price"); step 3 refuses `SecretWords`. No old caller has either wall. DECIDED (Product, decisions.md 11:52 AM PT Oct 16): the
  recipe-link job strips money-shaped spans from the page text before sending and never refuses the page; his
  own words (capture, plan titles) pass every wall unchanged. The recipe move adds a strip test; plan event
  titles holding a money word are refused as the wall says.
- **Status maps.** The shared table has 504 as timeout; the recipe reader says busy. Key check's map differs in
  five places (section 2). Capture maps a cancelled `URLError` to offline, not "cancelled".
- **Rounds.** Capture runs up to 3 rounds under one reservation of 3 times the estimate; `TessJob` has no rounds
  field yet, though section 3 step 4 assumes one. DECIDED (Product, decisions.md 11:52 AM PT Oct 16): `TessJob` gains `rounds` and a thinking
  flag (on Core's board).
- **Redirect refusal** is new for all four; today each follows a 3xx with the key header. DECIDED (Product, decisions.md 11:52 AM PT Oct 16):
  refuse; a 3xx is "offline" for capture and "unreadable" for the recipe link.
- **Cost.** Capture prices cache tokens; plan and recipe price input and output only. Same today (no cache
  control is sent), but a shared parser must not start pricing cache tokens on those rows.
- **Priorities.** `TessJob.priority` lists `.capture > .plan > .recipe > .lines`; nothing reads it until the 80%
  step-aside lands, so none of these four moves changes order.
- **Key check as a job.** Section 6 says it uses "only the headers, the status mapping and the row"; the status
  mapping must stay its own.
