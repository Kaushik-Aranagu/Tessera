# Claude key Test call

> **Update Oct 16, 12:40 pm PT:** the monthly Claude cap is now **$50** (Kaushik's yes at 9:27 am). Read every "$10" cap below as $50, with amber from $40 ("PAUSES AT $50"). Model prices in this file are unchanged. See `cap-math-check.md`.

For: Core (key store, ledger, client), Builder B (the key field on the Settings: Claude sheet). Research lab, board item 40, 2026-10-16.
Read with `tess-model-layer.md` §3 to §4 and §12, `tess-voice.md` M1 to M18, and decisions 5:49 PM PT ("Claude key entry pulled forward").
Code traced on `origin/master` at `3f124ee` (no Swift toolchain). API facts fetched live from platform.claude.com on 2026-10-16 (sources at the end).

**Bottom line.** The Test sends one free `POST /v1/messages/count_tokens` for `claude-haiku-5-5` with the one-word prompt "Hi". It costs $0.000000 and proves the key authenticates.
If that endpoint ever answers with something other than a documented status, the Test falls back to one `POST /v1/messages` with `max_tokens: 1`, about 9 tokens in total, at about $0.000001.
Every Test writes a `TessCall` row like any other call, so the $10 ledger sees it. One test pastes a fake key, runs the Test through a stubbed `URLProtocol`, then scans the op log, the backup file, the export, the log store and `UserDefaults` for it.

## 1. What master has (`3f124ee`)

| Thing | State |
|---|---|
| Key store (`TessKeychain`, `SecItem*`) | None. No Keychain code anywhere |
| Ledger (`TessCall`, `TessUsageLedger`) | None. `OpRoute.claude` and `OpRecord.model` exist (`Models.swift:583`, `TessRouterTests.swift`) |
| Network client (`URLSession`) | None. No call to Anthropic exists yet |
| Logging | No `Logger`, `os_log` or `NSLog` in the app or engine. `print` only in tests and `tools/storage-spike` |
| `UserDefaults` | Two keys: the backup folder bookmark (`BackupKeeper.swift:38-63`) and the launch note (`TesseraSchema.swift:104-112`) |
| Backups | `TesseraBackup.write` copies the whole SQLite store byte for byte (`context.database.backup(to:)`), so anything ever in the database lands in every `.tessera` copy |
| Export | `TesseraExport(context:)` reads every class, object, link and `OpRecord` into JSON |

**Nothing on master leaks a key today, because nothing holds one.** One path would leak it as soon as he has a key, though. If he pastes `<a Claude key>` into the Ask bar instead of Settings, the grammar or the on-device model can turn it into `createNote`.
That puts it in an `ObjectRecord`, an `OpRecord.summary`, the next daily `.tessera` copy and any export, and later it can go out in a Claude context pack. The fix is in §5, rule 1.

## 2. The call

**Primary: count tokens, free.** The token counting page says: "Token counting is **free to use** but subject to requests per minute rate limits" (Start tier 5,000 RPM, separate from Messages limits).
It needs the same key and headers as Messages, and its body names a model, so a 200 proves the key works and may use Haiku 5.5.

```
POST https://api.anthropic.com/v1/messages/count_tokens
Authorization: Bearer <key>            (docs: "x-api-key" is "still supported" as the legacy header)
anthropic-version: 2023-06-01          (latest version on the versioning page; required)
content-type: application/json         (required)

{"model": "claude-haiku-5-5", "messages": [{"role": "user", "content": "Hi"}]}
-> 200 {"input_tokens": 8}             (8 is a guess; the docs say the count may include system-added tokens)
```

**Fallback: the 1-token message.** Use it only when count_tokens returns 404 or 405, or a 200 body that does not decode, which would mean the endpoint moved. Same headers:
`{"model": "claude-haiku-5-5", "max_tokens": 1, "thinking": {"type": "disabled"}, "messages": [{"role": "user", "content": "Hi"}]}`.
`max_tokens` minimum is 0 in the docs, but 0 only warms the cache, so 1 is the smallest real call. Expect `stop_reason: "max_tokens"`; any 200 counts as works.
Model choice: Haiku 5.5 is the cheapest and the "Fastest" on the models overview. The docs give no sizes, so "smallest" means cheapest here.

**Why a raw request, not the package.** The Claude for Foundation Models page lists token counting as not available, and it documents only 429 (`.rateLimited`), timeout and context overflow, not 401, 403 or 529.
The Test needs exact statuses, so Core writes a small `ClaudeKeyCheck` (about 80 lines) on `URLSession(configuration: .ephemeral)`. The raw-client fallback in `tess-model-layer.md` §1 can grow from it later.
Timeout: 10 s. No retries: the Test is something he taps, so a failure shows its line right away.

**Cost (Haiku 5.5, prompts up to 100K tokens: $0.10 in, $0.50 out per million).** Ledger unit: **nano-dollars** (Int64). One Haiku input token costs 100 n$, and micro-dollars, the unit in model-layer §9, can't hold that.
Output is 500 n$ a token and a cache read 10 n$. At the $0.10 rate every price is a whole number of nano-dollars.

| Call | Tokens in / out | Cost | Shown (6 places) |
|---|---|---|---|
| count_tokens | 0 billed | 0 n$ | $0.000000 |
| 1-token message | about 8 / 1 | 8 x 100 + 1 x 500 = 1,300 n$ | $0.000001 |

## 3. Outcomes

The key is saved to the Keychain before any call. Lines follow `tess-voice.md`: one line under 12 words, first person, no "!", no em-dashes. M1, M2 and M10 are reused unchanged.

| # | Outcome | How we know it | Tess line | Key field shows |
|---|---|---|---|---|
| K1 | Works | 200 | Key saved. Ends in ...a1B2. (M1) | `...a1B2 · works`, Use Claude switches on |
| K2 | Bad key | 401 `authentication_error` (malformed, revoked or expired; "expired keys cannot be reactivated") | That key didn't work. Paste it again? (M2) | Empty field; the Keychain item is deleted |
| K3 | Not allowed | 403 `permission_error` | That key can't use Claude yet. Check it in the Console? | `...a1B2 · not allowed`, Use Claude stays off |
| K4 | No network | `URLError` `.notConnectedToInternet`, `.networkConnectionLost`, `.dataNotAllowed`, `.cannotFindHost`, `.cannotConnectToHost` | No connection. I kept the key and will check it later. | `...a1B2 · not checked`; it checks again on the next open when `NWPathMonitor` reports a usable path |
| K5 | Timed out | `URLError.timedOut` after 10 s, or 504 `timeout_error` | Claude didn't answer in time. I'll check again later. | `...a1B2 · not checked` |
| K6 | Cap reached (ours) | `ledger.canSpend` is false. count_tokens costs 0, so it still runs; the 1-token fallback is not sent | Key saved. Claude paused until Nov 1. (M1 + M10) | `...a1B2 · works`, then M10 in place of M8 |
| K7 | Server busy | 529 `overloaded_error`, 500 `api_error`, or 429 `rate_limit_error` with `retry-after` | Claude is busy right now. I'll check again soon. | `...a1B2 · not checked` |
| K8 | Account paused (Anthropic's) | 429 with `error.details.error_code == "enforced_spend_limit_reached"` (tier cap, no `retry-after`); 400 whose message begins "You have reached your specified"; 402 `billing_error` | Key saved. Your Anthropic account is paused for now. | `...a1B2 · account paused`, with a link to the Console |
| K9 | Not a key | The pasted text, after trimming, doesn't start with the Claude key prefix. Nothing is sent | That doesn't look like a Claude key. Paste it again? | Empty field |
| K10 | Anything else | Any other status, or a body that does not decode (after the §2 fallback) | I couldn't check that key. Try again? | `...a1B2 · not checked` |

Notes. The docs don't say whether count_tokens enforces billing or spend limits, so K8 might only show up on the first real call; that call shows the same line (UNVERIFIED).
The 1-token fallback does pass through billing checks. Read the error type from the JSON `error.type` and the `error_code`, never from the message text, except the "specified" prefix the rate-limits page documents.
Keep `request-id` from the response header for support; it isn't secret. Retry K4, K5 and K7 once, on the next app open, never in a loop.

## 4. The ledger

- **Before.** `estimate = (ceil(utf8Bytes / 4) + 10) x inPrice + maxTokens x outPrice`; count_tokens is 0. `canSpend` is true when `monthTotal + estimate <= 10,000,000,000 n$` ($10).
- **After.** Price the `usage` fields: `input_tokens`, `output_tokens` (thinking tokens are counted in it per `output_tokens_details`), `cache_read_input_tokens`, `cache_creation_input_tokens`. Write one `TessCall`:
  use `keyCheck` (add it to `TessUse`), model, route `claude`, tokens, `costNano`, latency, outcome (`works`, `badKey`, `notAllowed`, `offline`, `timeout`, `busy`, `accountPaused`, `other`) and `requestID`.
- **Failures.** An error status (4xx or 5xx) costs 0, because the error JSON carries no usage. A timeout after the request went out records the estimate, so the cap errs high, as model-layer §12 says.
  An offline failure records nothing billable but still writes the row with cost 0.
- **The Test counts like any call.** Its rows add to the month total; at $0.000000 or $0.000001 they never move M8.
- **Month.** The total is a query over `TessCall.createdAt` from 00:00 on the 1st in the phone's calendar and time zone (Los Angeles for him). It is not the 4 AM day, and it isn't Anthropic's 00:00 UTC.
  Anthropic's tier cap lifts at 00:00 UTC on the 1st, which is 5 PM PDT (4 PM PST) on the last day of the month, 7 to 8 hours before ours. Our cap is the stricter one in that gap, so nothing new is needed.

## 5. Keeping the key out of everything

1. **Guard the Ask bar.** In `TessRouter.run`, before any route: if the text contains the Claude key prefix, return line "That looks like a Claude key. Paste it in Settings." with no records and no op. The grammar, on-device and Claude routes never see it.
2. **Keychain item.** `kSecClassGenericPassword`, service `com.kaushikaranagu.tessera.anthropic`, account `api-key`, `kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable = false`.
   This is stricter than the `AfterFirstUnlock` in model-layer §3; Claude runs only with the app open, so WhenUnlocked is enough. It never syncs or restores to another device.
3. **Read once per call.** Read the key into a local `String` and put it only in the `Authorization` header of a `URLRequest`. Never store it on `URLSessionConfiguration.httpAdditionalHeaders`, in a property that outlives the call, or in a `TessCall`.
4. **Never in:** `UserDefaults`, `@AppStorage` or `@SceneStorage` (not even the draft text in the field), `OpRecord`, any `ObjectRecord`, `.tessera` backups, `TesseraExport`, context packs, `Info.plist`, the repo, crash messages (`fatalError`, `precondition`, `assert` strings) or error descriptions.
5. **Logs.** Never pass the key to `Logger` or `print`, not even with `privacy: .private`. Log only the last 4 characters, the status and the `request-id`. Never `print(request)` or `dump(request)`, and never set `CFNETWORK_DIAGNOSTICS`.
6. **The field.** A `SecureField` with `.privacySensitive()`, autocorrection off and no `textContentType`, so iOS doesn't offer to save it as a password. It is cleared after save. It shows only `...{last4}` and a state word, with Replace and Remove. Per model-layer §3, the key is never shown again.
7. **Eval harness.** `swift run tess-eval --route claude` reads `ANTHROPIC_API_KEY` from the environment and never echoes it.

## 6. The test

Engine tests (`swift test`) use an in-memory `TessKeychain` fake. One app-target test reads the real item's attributes back with `kSecReturnAttributes` and checks `kSecAttrAccessible` and `kSecAttrSynchronizable`.

```swift
@Suite(.serialized) @MainActor struct ClaudeKeyLeakTests {
    static let key = "sk-ant-TEST-" + UUID().uuidString          // unique, so a hit can only be ours

    @Test func keyNeverLeavesTheKeychain() async throws {
        let since = Date.now
        let context = try TesseraContext.inMemory(); try SystemCatalog.seed(context)
        let keys = InMemoryKeychain(); let ledger = TessUsageLedger(context: context)
        StubProtocol.reply = (200, #"{"input_tokens": 8}"#)
        let session = URLSession(configuration: .stubbed(StubProtocol.self))
        let check = ClaudeKeyCheck(keys: keys, ledger: ledger, session: session)

        let result = await check.test(pasted: "  \(Self.key)\n")                     // trims whitespace
        #expect(result.outcome == .works && result.line == "Key saved. Ends in ...\(Self.key.suffix(4)).")
        #expect(StubProtocol.last?.value(forHTTPHeaderField: "Authorization") == "Bearer \(Self.key)") // the one place
        #expect(StubProtocol.last?.url?.path == "/v1/messages/count_tokens")

        _ = await TessRouter.testDefault(context).run(TessRequest(text: Self.key, context: .test, use: .capture)) // Ask bar paste
        let backupURL = FileManager.default.temporaryDirectory.appending(path: "leak.tessera")
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        try TesseraBackup.write(from: context, to: backupURL)
        let haystacks: [(String, Data)] = [
            ("backup", try Data(contentsOf: backupURL)),
            ("export", try TesseraExport(context: context).encoded()),
            ("op log", Data(context.all(OpRecord.self).map { "\($0.summary)\($0.ops)" }.joined().utf8)),
            ("objects", Data(context.all(ObjectRecord.self).compactMap(\.valuesData).reduce(Data(), +))),
            ("defaults", Data("\(UserDefaults.standard.dictionaryRepresentation())".utf8)),
            ("logs", Data(try logStore.getEntries(at: logStore.position(date: since)).map(\.composedMessage).joined().utf8)),
        ]
        for (name, bytes) in haystacks {
            #expect(bytes.range(of: Data(Self.key.utf8)) == nil, "key found in \(name)")
            #expect(bytes.range(of: Data("sk-ant-".utf8)) == nil, "key prefix found in \(name)")
        }
        #expect(context.all(TessCall.self).count == 1)                          // the Test counted
        #expect(context.all(TessCall.self).first?.costNano == 0)
    }

    @Test(arguments: [(401, "authentication_error", Outcome.badKey), (403, "permission_error", .notAllowed),
                      (529, "overloaded_error", .busy), (500, "api_error", .busy), (402, "billing_error", .accountPaused)])
    func statusMapsToOutcome(status: Int, type: String, outcome: Outcome) async { /* stub, run, check line and field */ }
}
```

Add one row per `URLError` case in K4 and K5, one for the 429 `enforced_spend_limit_reached` body, and one for K6 with a ledger preloaded to $10.
The backup scan reads raw bytes, so it also catches a key left in SQLite free pages after a delete. If that ever fails, also set `PRAGMA secure_delete = ON`.

## 7. Owners

| Piece | Owner |
|---|---|
| `TessKeychain` (protocol, Keychain, in-memory fake), `ClaudeKeyCheck`, `TessCall` class, `TessUsageLedger` (nano-dollars, month query, `canSpend`), `TessUse.keyCheck`, the Ask bar guard, the leak test | Core (T3) |
| The key field, its state words, Replace and Remove, Use Claude switch, M8 to M10 lines | Builder B, on Design's Settings: Claude sheet |
| Wording of K3 to K10 | Design (copy) to confirm against `tess-voice.md` |

## 8. Open questions (recommended default first)

1. **Run the 1-token message as well, to catch billing at Test time?** Default: no. count_tokens alone; K8 shows on the first real call. The extra call is 1,300 n$ if he wants it.
2. **Header: `Authorization: Bearer` or `x-api-key`?** Default: Bearer, which the authentication page now names for direct HTTP. Both are documented as working.
3. **Ledger unit nano-dollars, not model-layer's micro-dollars?** Default: yes. One Haiku input token is 0.1 µ$.
4. **Keychain WhenUnlocked, not AfterFirstUnlock?** Default: WhenUnlocked. Revisit if the `TessInbox` queue ever runs in the background.
5. **Delete the Keychain item on 401?** Default: yes. The docs say a 401 key is malformed, revoked or expired, and expired keys can't come back.

## Could not verify

- Whether count_tokens enforces credit, billing or spend limits (402, 400, the 429 spend cap). The token counting page says only "free to use".
- Whether GET `/v1/models` is free. Its page is silent on cost, so it isn't used.
- The exact `input_tokens` for "Hi" on Haiku 5.5 (8 is a guess) and whether Haiku 5.5 thinks by default (the fallback disables thinking anyway).
- Whether 4xx and 5xx responses are ever billed. The pricing page bills "actual monthly usage" and says nothing about errors.
- What OSLogStore returns for `.private` values read in-process on iOS 27. The test passes either way, because the key should never reach the log at all.

## Sources

- Messages create, headers, `max_tokens` minimum 0, `usage` fields: https://platform.claude.com/docs/en/api/messages/create
- Count tokens endpoint: https://platform.claude.com/docs/en/api/messages/count_tokens ; "free to use": https://platform.claude.com/docs/en/build-with-claude/token-counting
- Errors (400 to 529, `request-id`, spend-limit 400, 402): https://platform.claude.com/docs/en/api/errors
- Rate limits, `retry-after`, `enforced_spend_limit_reached`, workspace limits: https://platform.claude.com/docs/en/api/rate-limits
- Models and IDs: https://platform.claude.com/docs/en/models/overview (redirected from docs.claude.com) ; pricing: https://platform.claude.com/docs/en/about-claude/pricing
- Required headers, Bearer vs `x-api-key`: https://platform.claude.com/docs/en/api/overview ; https://platform.claude.com/docs/en/manage-claude/authentication ; version: https://platform.claude.com/docs/en/api/versioning
- Models list (cost not stated): https://platform.claude.com/docs/en/api/models/list
- Claude for Foundation Models errors and `.apiKey`: https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/apple-foundation-models
