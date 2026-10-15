# Tess model layer: Claude in the foundations

For: Product lead. Builder: Core engine.
Date: 2026-10-15

**Decision driver.** Kaushik said yes to Claude (2026-10-15 18:41) and wants it in the foundations, not bolted on. This brief says how, with a recommendation per question. It updates `tess-routing.md` (Claude is now allowed after the on-device step) and plugs into M3 slices 4 and 7, M4 slices 6b and 12, Kitchen slice 3/11 and Lists slice 3.

**What already exists (origin/master `fcad46c`).** The seam is mostly built:
- `TessCaptureEngine` runs grammar, then `TessModelCapturing` (protocol "on-device model now; Private Cloud Compute or Claude later").
- `TessModelCapture` opens a `LanguageModelSession(model: SystemLanguageModel, tools: [RegistryTool])`. Each `RegistryTool` runs `ActionEngine.perform(named:arguments:by: .tess, pending: true)`, so every model write is already a pending ghost row with undo.
- `ActionRegistry` is the single list of actions; `ActionDescriptor.toolDefinition` already emits Claude-shaped tool JSON (`name`, `description`, `input_schema`), not yet strict.
- `OpRecord` has `actor` (`user`, `tess`, `intent`, `system`) but no record of which route or model produced a Tess op.

**New fact that changes the plan (verified).** Anthropic ships an official Swift package, **Claude for Foundation Models** (`github.com/anthropics/ClaudeForFoundationModels`, beta, iOS 27). `ClaudeLanguageModel` is a server-side `LanguageModel` that drops into the same `LanguageModelSession` API, with streaming, client `Tool`s, `@Generable` guided generation, automatic prompt caching and `session.usage`. So Claude can run through the exact code path the on-device model uses today. It is not a general Messages client: no cache controls, no stop sequences, no token counting, no beta headers. Third-party Swift SDKs exist (SwiftAnthropic, AnthropicSwiftSDK); none are official and we don't need them.

## 1. How the app calls Claude

**Recommendation: direct HTTPS from the phone, his own API key, no proxy.** Use `ClaudeLanguageModel(name:auth: .apiKey(keyFromKeychain))`.

| Option | For | Against |
|---|---|---|
| Direct, own key (pick) | No server to run or pay for; one user; works today | Anthropic's docs call `.apiKey` "development only" because a key bundled in a shipped binary is extractable. Ours is never in the binary; it sits in his Keychain on his phone, so that risk doesn't apply |
| Proxy (Cloudflare Worker etc.) | Key off the device, server-side cap | A server to run, deploy and secure; one more thing to break; no benefit for one user |
| App Attest (`.appAttest(clientID:)`) | No key on device, no server | Needs the App Attest capability, likely not on a free Personal Team (UNVERIFIED), plus Console setup. Revisit if he ever pays for a developer account |

Mitigation for direct: a dedicated workspace and key in the Claude Console with a Console spend limit as a second, server-side cap.

**Client shape.** Generalize `TessModelCapture` from `SystemLanguageModel` to `any LanguageModel`; the Claude route is the same class with a different model. The framework runs the tool loop: Claude calls a `RegistryTool`, the tool runs the action as a pending ghost op, returns "Done: ..." or "Error: ...", Claude continues until it answers.

```swift
@MainActor public final class ClaudeTessModel: TessModel {
    let route = TessRoute.claude
    private let keys: TessKeychain; private let ledger: TessUsageLedger
    func run(_ request: TessRequest, engine: ActionEngine) async -> TessResult {
        guard let key = keys.apiKey(), ledger.canSpend(request.use) else { return .unavailable(.capOrKey) }
        let model = ClaudeLanguageModel(name: request.use.claudeModel, auth: .apiKey(key))
        let session = LanguageModelSession(model: model, tools: TessTools.tools(for: request.use, engine: engine),
                                           instructions: request.use.instructions + request.pack.text)
        let options = GenerationOptions(maximumResponseTokens: request.use.maxTokens)
        for try await partial in session.streamResponse(to: request.text, options: options) { request.onPartial(partial.content) }
        ledger.record(use: request.use, model: model.name, usage: session.usage)   // tokens -> dollars
        ...                                                                         // recorder.records -> ghost rows
    }
}
```

**Fallback if the beta package blocks us** (API churn, `usage` missing a field we need): a thin `actor ClaudeClient` over `URLSession.bytes(for:)` posting to `/v1/messages` with `stream: true`, parsing SSE (`message_start`, `content_block_delta` with `input_json_delta`, `message_delta` carrying final `usage`), and a manual loop `while stop_reason == "tool_use"` that returns all `tool_result` blocks in one user message. About 250 lines; tools come from `ActionRegistry.toolDefinitionsJSON()`, so nothing upstream changes. Note for this path: Sonnet 5.5 and Opus 5.5 reject forced `tool_choice` (`any`/`tool`) with a 400; use `auto` plus `strict: true`.

## 2. Structured writes

**Rule: Claude never writes the database.** It can only call registry tools; each call goes through `ActionRegistry.decode` and `ActionEngine.perform(..., by: .tess, pending: true)`, the same command path as the grammar. Output is a ghost row, commits on tap or after 2 s, and undoes like any Tess op.

**Op log.** Keep `actor = .tess` (so "what Tess did", `undoLatest(by: .tess)` and M3 slice 9 keep working) and add two columns to `OpRecord`: `route` (`grammar`, `onDevice`, `claude`) and `model` (e.g. `claude-haiku-5-5`). Add `.claude` to `TessCapture.Source`. The receipt can then say "via Claude". DEFAULT.

**Names, not ids.** Claude can't know UUIDs. Tools take names (`exercise: "Bench Press"`, `list: "Groceries"`) and the tool resolves them, as `RegistryTool` already does for `classRef`. Today `TessToolCatalog` hides any action with an `.object` parameter (so `addListItem` is invisible to models); the shared registry needs name-resolving variants.

**First 8 tools** (strict-ready: every object `additionalProperties: false`, all fields `required`, optional ones as `["type","null"]`; strict mode allows at most 20 strict tools and 24 optional params per request, and no recursion or min/max constraints):

| Tool | Maps to | Input schema (short) |
|---|---|---|
| `logSet` | `LogSet` / `LogExercise` | `{exercise: string, weight: number, reps: integer, sets: integer, unit: "kg"\|"lb"}` |
| `createTask` | `CreateTask` | `{title: string, startsAt: string(date-time)\|null, about: [string]}` |
| `addGroceries` | `AddGroceries` | `{lines: [string]}` |
| `addToList` | `AddListItem` (by name), many at once | `{list: string, items: [{text: string, section: string\|null, done: boolean}]}` |
| `createList` | `CreateList` + items | `{name: string, items: [same as above]}` |
| `createNote` | `CreateNote` | `{body: string}` |
| `createRecipe` | `CreateRecipe` (structured) | `{title, serves: integer\|null, totalMinutes: integer\|null, ingredients: [{amount: string\|null, unit: string\|null, name: string}], steps: [string]}` |
| `answerQuery` | runs the query AST locally; read-only | `{from: [string], where: [{field, op, value}], during: string\|null, group: string\|null, agg: string, sort: string\|null, limit: integer\|null}` (the AST in `questions-eval.md`; flat, so strict-safe) |

Plus one non-writing tool for plan wording, `proposePlan {lines: [{objectID: string, text: string}], startWith: string}`, validated against the rules plan (same objects, at most 3 lines). Destructive actions (`deleteObject`) stay off every model route.

## 3. Key storage

- Keychain generic password, service `com.kaushikaranagu.tessera.anthropic`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (not synced, not in backups to other devices).
- Entered once: Settings (M3 slice 12) has a "Claude" row. Paste key, Tessera makes one tiny Haiku call to check it, shows "Key saved. Ends in ...a1B2." The key is never shown again, only Replace or Remove.
- Never in the repo, `Info.plist`, `UserDefaults`, the op log, exports or logs. A unit test greps exports and the database file for `sk-ant-`.

## 4. Cost

**Prices (verified on platform.claude.com pricing page, 2026-10-15), per million tokens:**

| Model | Input | Output | Cache read | Use in Tessera |
|---|---|---|---|---|
| Haiku 5.5 `claude-haiku-5-5` | $0.10 (prompts up to 100K) | $0.50 | $0.01 | Parsing, AST, capture |
| Sonnet 5.5 `claude-sonnet-5-5` | $2 | $10 | $0.10 | Plan wording, hard pastes |
| Opus 5.5 `claude-opus-5-5` | $4 | $20 | $0.20 | Not used in M3/M4 |
| Fable 5.1 `claude-fable-5-1` | $10 | $50 | $0.25 | Not used |

**Per-call estimates** (tokens are estimates, measure in slice 3; thinking at `effort: low` included in output):

| Use | Model | max_tokens | In / out tokens | Per call | Typical month |
|---|---|---|---|---|---|
| Plan my day wording | Sonnet 5.5 | 1,024 | 2,000 / 400 | ~$0.008 | 30 calls, ~$0.25 |
| Question to AST | Haiku 5.5 | 512 | 3,000 / 200 | ~$0.0004 | 300 calls, ~$0.12 |
| Recipe or list paste | Haiku 5.5 (Sonnet on retry) | 4,096 | 2,500 / 1,000 | ~$0.001 (Sonnet ~$0.015) | 20 calls, ~$0.05 |
| Free-form capture | Haiku 5.5 | 512 | 2,500 / 150 | ~$0.0003 | 150 calls, ~$0.05 |

Realistic use is under $1 a month. **Cap: $10 a month, hard stop** (DEFAULT, inside the $100 overall budget). At the cap every use falls back to the rules or on-device path, and Tess says once: "Claude paused until 1 Nov." At 80% the Settings line turns amber; no notification.

**Counting.** After each call, read `session.usage` (raw client: the `usage` field: `input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`) and price it from a small table in code. If the package doesn't split cache tokens, price all input at the base rate; that overestimates, which is the safe side for a cap. Show one calm line on Settings and the receipt: "Tess: $1.20 this month."

## 5. Routing (updates `tess-routing.md`)

Order stays grammar, then on-device, then Claude. What decides each step:

1. **Grammar.** Takes it if `TessGrammar.parse` returns a parse and every name resolves to one object. Free, under 50 ms, offline.
2. **Task type.** Some tasks skip the on-device step because 4K context is too small or quality matters: plan wording, question to AST (the class catalog alone is ~2K tokens), and pastes the deterministic parser can't read. Capture goes on-device first.
3. **On-device.** Accepted if a tool call passes kernel validation within 3 s. Otherwise falls through.
4. **Claude.** Only if all hold: Claude switched on, key present, online (`NWPathMonitor`), under the cap. Timeout 8 s for capture and questions, 20 s for paste and plan (streamed, so the ghost row fills in as it reads).
5. **Nothing worked.** "Didn't catch that" with the best partial guess, as today.

Change to `tess-routing.md`: replace "Never PCC or Claude for capture without Kaushik's OK" with "Claude after on-device, within the cap, when switched on". PCC stays unused for now; Claude covers that tier.

## 6. Privacy

**Anthropic API policy (verified, privacy.claude.com):** API inputs and outputs are deleted from Anthropic's backend within 30 days by default, and are not used for training by default on commercial products, which includes the API. Zero data retention is not needed for a personal key.

**Context pack: only what the use needs, never the whole database.**

| Use | Leaves the phone | Never sent |
|---|---|---|
| Plan my day | The rules plan (up to 8 candidate titles with object ids, due, size), today's event titles and times, free minutes, "light day: yes/no" | Notes, health values, sleep hours, past days |
| Question | The question, class and field names, names of exercises, routines, recipes, lists | Any values, sets, weights. The AST runs locally and the answer line is built locally |
| Paste | The pasted text, list or recipe names for matching | Anything else |
| Capture | The phrase, today's date, current exercise and last set, list and recipe names | History |

**Health is off by default.** The rules plan already applies the sleep and energy cap on the phone, so Claude only sees "light day". **One switch** in Settings: "Use Claude" (off until a key is pasted). A small cloud mark on the bloom whenever a request leaves the phone (from `ai-and-tess.md` idea 4). The `TessContextPack` builder has a unit test per use that snapshots exactly what is sent.

## 7. Offline

**Never block capture.** Offline or capped, the grammar and on-device paths run as today.
- Capture the grammar and on-device both miss: keep the raw text as a `TessInbox` object ("1 waiting for Tess"). When back online, Claude reads it and proposes ghost rows the next time the app is open. Never commit on its own; ghost rows need him there.
- Plan my day: the rules plan shows; no queue (the wording would be stale).
- Questions: grammar answers if it can, else "Needs a connection." No queue.
- Paste: the deterministic parser result shows; a "Read again" link appears when back online.

## 8. First uses, in order

| # | Use | Attaches to | Smallest version |
|---|---|---|---|
| 1 | Plan my day wording | M4 slice 6b | Send the slice 6 rules plan; Sonnet returns `proposePlan`. Validate: same object ids, at most 3 lines, `TessVoice.violations` empty. Any failure shows the rules plan unchanged. Test against the 20 days in `plan-my-day-scenarios.md` |
| 2 | Questions and log answers | M3 slices 4 and 7 | Grammar handles the seed phrases. Everything else: Haiku calls `answerQuery`; the engine validates and runs the AST, builds the one-line answer with handles. Refuse and clarify rows produce no tool call |
| 3 | Paste parsing | Kitchen slice 3/11, Lists slice 3 | Deterministic `RecipeParser` and list parser first. Claude only when the recipe parser finds no ingredients or steps, or he taps "Read again". Output is `createRecipe` / `createList`; the original text is kept verbatim as now |
| 4 | Free-form capture | M4 slice 12 | After on-device fails: Haiku with the same `RegistryTool`s. Multi-intent run-ons become one ghost batch |

## 9. Foundations to build now

1. **`TessModel` protocol** replacing `TessModelCapturing`: `route`, `availability(for: TessUse)`, `run(TessRequest, engine:) async -> TessResult`. Three implementations: `GrammarTessModel` (wraps `TessGrammar`), `OnDeviceTessModel` and `ClaudeTessModel` (both the generalized `TessModelCapture` over `any LanguageModel`). A `TessRouter` owns the order from section 5.
2. **One tool registry for all three.** `TessTools.tools(for: use, engine:)` builds `RegistryTool`s from `ActionRegistry` plus name-resolving variants; `ToolDefinition` gains `strict` and `additionalProperties: false` for the raw client and evals.
3. **`TessContextPack` builder.** Per use, returns the text that leaves the phone and a list of what's in it (for the snapshot test and a future "what was sent" view).
4. **Usage ledger as objects.** System class `TessCall` under `/system/tess`: use, model, route, input, output and cache tokens, cost in micro-dollars, latency, outcome. Month total is a query, never stored. Written by `.system`, outside undo.
5. **Eval harness.** One runner over `tess-eval-phrases.md` (200), `kitchen-phrases.md` (50), `questions-eval.md` (60) and `plan-my-day-scenarios.md` (20), per route. Grammar rows run in `swift test`; Claude rows run from a Mac command (`swift run tess-eval --route claude`) with the key from an environment variable, never in CI-style runs by default. Reports pass rate per area and route, false-write rate (target 0), p50/p95 latency, and cost per 100 calls.

## 10. Proposed slices

| # | Slice | Done when | Type |
|---|---|---|---|
| T1 | **TessModel and router** | `TessModel` replaces `TessModelCapturing`; grammar and on-device run through `TessRouter`; `OpRecord` has `route` and `model` columns (GRDB migration); all existing Tess tests pass unchanged | Engine |
| T2 | **Shared tool registry** | Name-resolving tools for the 8 in section 2; same list feeds on-device and Claude; `toolDefinitionsJSON()` emits strict schemas; tests decode each tool's sample input and perform it pending | Engine |
| T3 | **Claude route, key and ledger** | Package pinned to an exact version; key read from Keychain; `TessCall` objects written per call; cap check blocks calls at $10; `swift test` uses a stub `LanguageModel`; one live smoke test on the Mac | Engine |
| T4 | **Context packs and privacy tests** | One pack per use; snapshot tests prove no health values, notes or set history leave the phone; offline detection and the `TessInbox` queue work | Engine |
| T5 | **Eval harness** | Runs all four eval files per route; Claude capture rows 90% or better, questions 85% or better, false writes 0; prints month-cost estimate | Engine |
| T6 | **Plan wording (6b)** | Sonnet rewords the rules plan; any failure, timeout or cap shows the rules plan; 20 scenarios pass validation | Engine |
| T7 | **Questions via AST (M3 4/7)** | Non-grammar questions go to Haiku `answerQuery`; 60 rows in `questions-eval.md` scored; refuse rows never call a tool | Engine |
| S1 | **Settings: Claude** | Paste key, check it, "Key saved. Ends in ...a1B2"; one switch; one line "Tess: $1.20 this month" with the cap; Replace and Remove. Not a stock Form, per `tessera-design` | Feature screen |
| S2 | **Cloud mark and receipt** | Cloud mark on the bloom during a Claude call; receipt rows say "via Claude"; "1 waiting for Tess" when queued | Feature screen (rough) |

Order: T1, T2, T3, then T4 and S1 together, then T6 (first visible win), T7, T5 alongside.

## Decisions taken as defaults

- DEFAULT: Direct calls with his own key; no proxy, no App Attest.
- DEFAULT: Transport is Anthropic's Claude for Foundation Models package; raw `URLSession` client only if the beta blocks us.
- DEFAULT: Claude writes only through registry tools as pending ghost ops, `actor = .tess`, `route = claude`.
- DEFAULT: Haiku 5.5 for parsing, AST and capture; Sonnet 5.5 for plan wording and hard pastes; no Opus or Fable yet. `effort: low` everywhere to start.
- DEFAULT: $10 monthly hard cap, 80% amber line, fallback to rules and on-device at the cap.
- DEFAULT: Health data never sent; context packs per use; Claude off until a key is pasted.
- DEFAULT: Offline capture queues as `TessInbox`; nothing commits without him.

## Unverified

- Whether App Attest works on a free Personal Team.
- The exact fields of `session.usage` in the package (cache split) and whether the package uses strict tool use under the hood.
- Token counts in section 4 are estimates; T3 measures them.
- `ai-and-tess.md` says on-device context is 8K, `tess-routing.md` says 4K; still unresolved, and it's why questions skip on-device.

## Questions for Kaushik

1. **Monthly cap?** Recommended: $10, hard stop. Expected use is under $1.
2. **Can Claude see sleep and energy for Plan my day?** Recommended: no; the phone applies the "light day" rule and Claude only sees "light day: yes".
3. **When the grammar misses a capture, can it go to Claude automatically (with the cloud mark), or ask first each time?** Recommended: automatically, since it always lands as an undoable ghost row.

## 11. Tool schemas generated from the action catalog

**Rule: no hand-written Claude tools.** `ActionRegistry.descriptors` is already the one list behind the on-device tools, App Intents and `toolDefinitionsJSON()`. The Claude route reuses it, so declaring an action (descriptor plus decoder entry) is all it takes to become a Claude tool. What exists on origin/master:
- `ActionDescriptor` (name, summary, typed `Parameter`s, `isDestructive`) in `Actions/EngineAction.swift`; `ActionRegistry` in `Actions/ActionRegistry.swift`.
- `RegistryTool` (in `TesseraTess/TessModelCapture.swift`) builds a `DynamicGenerationSchema` per descriptor and calls `ActionEngine.perform(named:arguments:by: .tess, pending:)`. `TessToolCatalog` filters by an allow-list and hides `.object`/`.json` parameters and destructive actions.
- No `@Generable` type exists in code yet; it is only proposed in `ai-and-tess.md` and `tess-routing.md`. Tools use dynamic schemas, which is the right choice because the list is data, not types.

Smallest shape (T2), shared by the on-device and Claude routes:

```swift
public enum TessTools {
    /// Stable for a given app build: registry order, never sorted by use or recency.
    @MainActor static func tools(for use: TessUse, engine: ActionEngine,
                                 recorder: TessToolRecorder, pending: Bool) -> [any Tool] {
        let grammar = TessGrammar(store: engine.store, classes: engine.classes)
        return descriptors(for: use).map {
            RegistryTool(descriptor: $0, engine: engine, grammar: grammar, pending: pending, recorder: recorder)
        }
    }

    static func descriptors(for use: TessUse) -> [ActionDescriptor] {
        ActionRegistry.descriptors.filter { d in
            use.allowedActions.contains(d.name) && !d.isDestructive   // allow-list per use, never deleteObject
                && d.parameters.allSatisfy { $0.kind != .json }       // .object becomes a name, resolved in call()
        }
    }

    /// Raw-client and eval path: same descriptors, strict JSON.
    static func definitionsJSON(for use: TessUse) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]                       // byte-identical across calls
        return try encoder.encode(descriptors(for: use).map { $0.toolDefinition.strict() })
    }
}
// ToolDefinition.strict(): adds "strict": true and "additionalProperties": false, lists every
// property in "required", and turns optional ones into ["type", "null"].
```

**Strict schemas.** Two layers, both generated:
- Package route: tool arguments are generated against the `GenerationSchema` from `RegistryTool.schema(for:)`. Whole-response output (`proposePlan`, the `answerQuery` AST) uses `session.respond(to:generating:)` with a `@Generable` type, which the package sends as Claude structured outputs (verified on the docs page). Whether client `Tool` arguments are sent with `strict: true` is not documented (UNVERIFIED, already listed below); `ActionRegistry.decode` stays the real gate either way.
- Raw route and evals: `strict()` as above. Today `ToolDefinition` lacks `strict` and `additionalProperties`, and maps `.object`/`.classRef` to `format: uuid`; the name-resolving variants change those to plain strings. Keep each use under 20 strict tools and 24 optional parameters.
- A registry test asserts every allowed descriptor produces a valid strict schema and that every tool name has a decoder, so a new action that breaks either fails `swift test`, not a live call.

**Caching.** Verified: the package caches automatically, and TTL and breakpoints are not configurable. Not stated: what it caches or where it places breakpoints (UNVERIFIED). On the Messages API the cached prefix is tools, then system, then messages, and any byte change invalidates everything after it. So, whatever the package does:
- Tool order is registry order and filters depend only on `TessUse`, so one use always sends the same bytes. Never add live names (exercises, lists) as `anyOf` enums into tool schemas on the Claude route; that idea from `tess-routing.md` stays on-device only.
- Instructions put the stable part first (voice, rules, the compact `ActionRegistry.catalog`) and the context pack last. Today `TessVoice.instructions` takes `today` (to the minute), the workout and the last set as arguments; on the Claude route these move into the pack at the end.
- Short prompts may sit below the model's minimum cacheable prefix and simply not cache; at under $1 a month this is fine. Measure cache-read tokens in T3 before relying on it.

## 12. Pitfalls

| Pitfall | Mitigation |
|---|---|
| Beta package changes its API (docs: "APIs might change during the beta") | Pin an exact version; all package calls live in `ClaudeTessModel`; the raw `URLSession` client in section 1 is the escape hatch |
| Keychain item lost on reinstall under free Personal Team signing (7-day expiry) | Re-running from Xcode installs over the app with the same bundle id and team id, so the item is kept. Deleting the app first also keeps it today, but Apple calls that an undocumented detail. Settings shows "No key" and re-asks instead of failing. Verify on the phone in T3 (UNVERIFIED on iOS 27) |
| Cap passed mid-stream | Check the cap before each call with that use's `maxTokens` priced in; allow the one call to finish; the next call is blocked |
| Rate limits (429), 529 overloaded, retries | Package maps 429 to `LanguageModelError.rateLimited`; 529 surfaces as `ClaudeError` (UNVERIFIED which case). At most one retry with jitter, then fall back to rules or on-device for that turn. Never retry a turn whose tools already ran |
| UI waits on a slow call | Route timeouts from section 5 via the initializer's `timeout`; wrap the run in a `Task` that cancels on timeout or dismiss; ghost rows from completed tool calls stay, the rest are discarded |
| Claude invents names that don't resolve | Tool returns "Error: no exercise called X, closest: Y" so Claude can retry once; never create objects from an unknown name; second miss becomes "Didn't catch that" |
| Prompt injection from pasted recipe text | Paste goes in a delimited block marked as data; the paste use only gets `createRecipe`/`createList`; every write is a pending ghost row; no destructive tools on any route |
| Swift 6 concurrency with streaming | `ClaudeTessModel` and `RegistryTool.perform` are `@MainActor`; stream partials hop to the main actor; only `Sendable` values (strings, `Data`) cross out of `call(arguments:)`, as today |
| Usage missing on a failed or cancelled call | Record a `TessCall` with outcome `failed` and an estimate (input tokens from text length over 4 plus `maxTokens`); the cap errs high |
| Month boundary for the cap | Month total is a query over `TessCall` dates in the phone's calendar and time zone; the reset line reads that same calendar; the Console spend limit is the server-side backstop |
| Testing without spending money | `swift test` and the app tests inject a stub `LanguageModel` returning scripted tool calls; live calls only via `swift run tess-eval --route claude` with an env key |
| Context pack leaks more than intended | Snapshot test per use (section 9); a test greps exports and the database for `sk-ant-` |
| Keychain and cap tests touch real state | Behind protocols (`TessKeychain`, `TessUsageLedger`) with in-memory fakes in tests |

Extra unverified items from these two sections: what the package caches and where it places breakpoints; how a 529 surfaces in the package; Keychain survival on iOS 27 under Personal Team signing.
Keychain source: [Apple DTS on keychain items after app deletion](https://developer.apple.com/forums/thread/36442?page=2).

## Sources

- [Claude for Foundation Models (Claude docs)](https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/apple-foundation-models), [repo](https://github.com/anthropics/ClaudeForFoundationModels)
- [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Structured outputs and strict tool limits](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- [API data retention](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data), [Training on API data](https://privacy.claude.com/en/articles/7996868-is-my-data-used-for-training)
- [Swift Package Index, "anthropic"](https://swiftpackageindex.com/keywords/anthropic) (no other official Swift SDK)
