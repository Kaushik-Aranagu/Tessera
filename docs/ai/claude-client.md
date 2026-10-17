# `ClaudeClient` and `TessJob` (ship list AI-2)

One page for Core's PR. It follows `architecture.md` sections 5 and 7 and the code on this tree. "New" marks
anything that doesn't exist yet. Where the docs and the code differ, this note follows the code (list at the end).

## 1. The shape

```swift
/// new. Static: the same bytes every call (caching, snapshot tests).
public struct TessJob: Sendable {
    let name: String                    // "homeLines", "weekStory", "plan", "recipeLink", "capture", "keyCheck"
    let model: String                   // a key of TessUsageLedger.prices
    let maxTokens: Int
    let effort: String?                 // sent as "output_config": ["effort": ...], as ClaudePlanWording does
    let timeout: TimeInterval           // a hard deadline, not URLRequest's idle timeout
    let instructions: String            // TessVoice house voice, then the job's rules
    let output: ToolDefinition?         // one strict "propose..." tool; nil for a plain-text job (recipe link)
    let writeTools: [String]            // TessTools names; [] for word-only jobs
    let memory: Set<TessMemory.Kind>    // which memory kinds go in the pack
    let priority: Priority              // .capture > .plan > .recipe > .lines
    let toolChoice: ToolChoice          // new: .forced (Haiku 5.5) or .auto (Sonnet 5.5), see section 2
}

/// new. What a pack builder returns.
public struct TessPack: Sendable {
    let text: String                    // the user message: <memory>, <facts>, the ask
    let touched: [UUID]                 // section 5; stays on the phone
}

@MainActor public final class ClaudeClient {   // new
    func send(job: TessJob, pack: TessPack) async -> Outcome
}

public enum Outcome: Sendable {          // new
    case words(String)                   // a plain-text reply (no output tool)
    case toolInput(Data)                 // the output tool's input, already through TessLineCheck
    case toolCalls([ToolCall])           // write jobs (capture) run them through TessTools, pending
    case noLine(reason: String)          // no tool call, or a failed check: the rules line stays
    case refused(Wall)                   // switch off, demo, no key, money, secret, cap: nothing was sent
    case failed(ClaudeTessModel.Failure) // offline, timeout, busy, badKey, other, each with its line
}
```

`.noLine` is not a failure. The caller shows its rules line exactly as if Claude had not been asked, and the
ledger row's outcome says why ("no tool call", "rejected V1", or the check's codes, as `ClaudePlanWording` writes
"rejected " + codes today). `Failure` is the existing `ClaudeTessModel.Failure` (outcome plus line); move it next
to `ClaudeClient` and keep the five lines word for word.

## 2. Tool choice per model

- **Haiku 5.5: forced**, `"tool_choice": {"type": "tool", "name": <output tool>}`. In the memory experiment Haiku
  answered without calling the line tool for 118 items under auto (`memory-experiment.md`, "Result and decision").
- **Sonnet 5.5: auto**, `{"type": "auto"}`. Sonnet 5.5 refuses a forced tool (seen in the groceries runner).
  A Sonnet reply with no tool call is `.noLine`.
- Write jobs (capture) keep auto, as `ClaudeTessModel` does. A job with no output tool sends no `tool_choice`.

## 3. The call path, in order

Every wall refuses with no network call and before any money is held.

1. **Switch and demo gate.** Read the switch at call time through a closure, as `ClaudePlanWording.allowed` and
   `ClaudeTessModel.sendsMisses` do. The app passes `AppModel.asksClaude` (`settingsAreReal` and
   `SettingsStore.read().sendsMissesToClaude`). Demo: the app already skips wiring Claude when `-demo`,
   `-resetDemo`, `-theme` or `-fakeClaudeKey` is set; `ClaudeClient` takes that as an injected flag too (Core
   can't read `LaunchFlags`). Then the key: `keys.read()` nil means `.refused(.noKey)`.
2. **Money and body wall.** A money-shaped pack is refused (`.refused(.money)`). One exception by job: the
   recipe-link job strips money-shaped spans (prices, costs) from the page text before sending and never refuses
   the page (Product, decisions.md 11:52 AM PT Oct 16); his own words still pass every wall unchanged. Use the same word and currency
   list as `TessMemoryScreen.moneyWords` and the currency signs. Body and health facts are never packed: that is
   the pack builder's job, and its snapshot test proves it. For capture, the first wall is new in `TessRouter.run`:
   a money screen next to the existing `SecretWords.mentions` check, before any `isAvailable`, so a money-shaped
   phrase never reaches `ClaudeTessModel`, whatever the switch says.
3. **SecretWords wall.** A pack where `SecretWords.mentions` is true, or that holds the Claude key prefix
   (`looksLikeClaudeKey`, any case), is refused (`.refused(.secret)`). Same reason as the router's check today.
4. **Reserve.** `TessUsageLedger.estimate` from instructions, tools and pack text, times rounds for write jobs,
   then `ledger.reserve`. Nil means `.refused(.cap)` with today's "Claude paused until <date>." line. The cap is
   the one constant `TessUsageLedger.capNano`, $50 in code today (see the list at the end). New: at 80% of the
   month, a job whose `priority` is `.lines` steps aside before reserve. `defer { ledger.settle(reservation) }`.
5. **Send.** One `URLRequest` to `ClaudeKeyCheck.base`, headers as today (`x-api-key`, `anthropic-version:
   2023-06-01`, `content-type`). The key is read into a local and goes only in that header. Body order per
   section 5.2: system, tools, then the pack.
6. **Parse.** Usage (input, output, cache read, cache write), `request-id`, `stop_reason`. `max_tokens` or
   `refusal` is `.failed(.other)`, as both callers do today. A billed 200 with no content still counts.
7. **Check.** `TessLineCheck` (AI-3, new; lifted from `PlanProposalValidator`) on the tool input. Any code means
   `.noLine`.
8. **Settle the row.** Every outcome from step 4 on writes one `TessCall` row through `ledger.record`, failures
   and `.noLine` included. New: a `job` field on `TessCall` (`SystemCatalog` `.tessCall`), set to `job.name`.
   `use` stays as it is, so old rows read the same. Walls in steps 1 to 3 send nothing and write no row, as the
   cap refusal writes none today; a DEBUG count of money and secret refusals is enough to catch a leaky builder.

## 4. Errors

| What comes back | `Failure` | Note |
|---|---|---|
| 401, 403 | `.badKey` | Never clears the key, never turns the switch off (`ClaudeKeyCheck`: "A 401 keeps the key") |
| 429, 500 to 599 except 504 | `.busy` | 529 is busy |
| 504, `URLError.timedOut`, the hard deadline | `.timeout` | |
| other `URLError` | `.offline` | |
| `URLError.cancelled`, `CancellationError` | outcome "cancelled", no line | as `ClaudePlanWording` |
| any other status, unreadable JSON | `.other` | |

- **Late reply.** Use `ClaudePlanWording`'s `withDeadline` race, and the caller's `stale` closure. A reply after
  the deadline or after `stale()` turns true is dropped; its cost is still on the row, with outcome "late".
- **Redirects** (new). A session delegate whose `willPerformHTTPRedirection` returns nil, so the key header never
  follows a 3xx to another host. A 3xx then lands as `.other`. Today's Claude calls have no such delegate;
  `RedirectGuard` only guards the recipe page fetch.
- **Retries.** None today. If Core adds one, at most one, only for `.busy`, inside the same reservation and the
  same deadline.

## 5. `touched`

The pack builder returns `touched: [UUID]` in `TessPack`: the ids of objects it packed, in the order the job uses
them. It rides on the call, not on the static `TessJob`. It lists only ids already in that pack. It is never put
in the request body. `ClaudeClient` hands it to the app through a closure (new, for example
`onAsk: ([UUID]) -> Void`), because `SoulEvent` lives in the app (`Features/Tess/SoulRouter.swift`, today a bare
`.askClaude`). Builder A adds the `touched` payload there. Jobs with no objects (the key check) pass `[]`.

## 6. Migration (AI-13)

`ClaudeTessModel`, `ClaudePlanWording`, `ClaudeRecipeReader` and `ClaudeKeyCheck` move onto `ClaudeClient` only
when someone is already in that file. No change in behaviour, lines or ledger rows (same `use`, model and outcome
strings). The AI-2 PR leaves all four untouched. `ClaudeKeyCheck` keeps its own `Outcome` enum and its
`count_tokens` path; it would use only the headers, the status mapping and the row.

## 7. Tests Core should write

Stub `URLSession` with a `URLProtocol`, as `StubProtocol` in `ClaudeKeyTests.swift` does.
1. Each status: 200, 401, 403, 429, 500, 504, 529, a 3xx, and a URL timeout map to the table above, one row each.
2. A 401 leaves the key in `InMemoryKeychain` and the switch closure's value unchanged.
3. A money-shaped pack is refused before reserve: no request reaches the stub, `pendingNano` unchanged, no row.
4. A pack with a secret word, and one with the Claude key prefix in any case, are refused the same way.
5. Switch off sends nothing; the demo flag sends nothing; no key sends nothing.
6. Tool choice per model: a Haiku job's body has `{"type": "tool"}` with the tool name; a Sonnet job's has auto.
7. A Sonnet reply with no tool call, and a reply that fails the check, give `.noLine` and a row that says so.
8. `touched` ids never appear in the request body (decode the stub's captured body and search it).
9. A reply after the deadline is dropped and its row says "late", with its cost.
10. At 80% of the month a `.lines` job steps aside; a `.capture` job still runs.

## Where code and docs differ

- **The cap.** The brief and `ship-list.md` say $10 today, $50 proposed. The code has `capNano = 50_000_000_000`
  ("$50 (Kaushik, decisions.md Oct 16)"), and `docs/product/decisions.md` records his yes at 9:27 AM PT Oct 16.
  No raise is left for AI-2.
- **The money screen.** `architecture.md` section 7 says `TessRouter` runs one before `isAvailable`. It doesn't
  yet: `TessRouter.run` checks only `looksLikeClaudeKey` and `SecretWords.mentions`. Ship list AI-2 adds it.
- **The 80% step-aside.** Described in section 5.5; no code for it yet.
- **Late-reply drop and hard deadline.** Section 5.1 lists them as shared parts of "the four copies"; only
  `ClaudePlanWording` has them. `ClaudeTessModel` and `ClaudeRecipeReader` rely on `URLRequest`'s idle timeout.
- **Redirect refusal.** Not in any Claude call today. **Ledger rows.** `ClaudeRecipeReader` writes `requestID: nil` and records 401/403 and busy without a `Failure`.
  The key check reserves only on its fallback path.
- **Types.** The docs say `TessMemoryKind` and `ObjectID`; the code has `TessMemory.Kind` and `UUID` ids.
  `ClaudeReply` and `run(_:pack:)` in section 5.1 are renamed `Outcome` and `send(job:pack:)` here.
- **Callers wired.** Only `ClaudeTessModel` (from `AppModel`) and `ClaudeKeyCheck` (from `ClaudeSection`) are
  built in the app; `ClaudePlanWording` and `ClaudeRecipeReader` appear only in tests on this tree.
- **The switch name.** It reads `sendsMissesToClaude` but gates plans and links too (`ClaudePlanWording.allowed`).
