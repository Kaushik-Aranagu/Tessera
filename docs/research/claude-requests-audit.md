# What leaves the phone for Claude, on master (board item 145)

**For:** Core, AI architecture, QA. **Owner:** Research lab. **Date:** Oct 16, 2026 (Pacific).
**Master:** `213ad78` (merge of #433). Traced by hand, nothing was run.

**Summary:** five request builders reach `api.anthropic.com/v1/messages`. Two are live today: the capture miss
(`ClaudeTessModel`) and the key Test (`ClaudeKeyCheck`). Three are latent, with no caller in App/ or Features/: the
inbox drain (`readWaiting`), Plan my day wording (`ClaudePlanWording`) and the recipe link reader
(`ClaudeRecipeReader`). No memory pack, week story or Home wording job calls Claude: `TessMemory` is never read by
TesseraTess. His Claude key goes only in a request header, read from Keychain at call time; the export and backup
code under `TesseraCore/Export` never touches Keychain or the key.

Short names: CTM `TesseraTess/ClaudeTessModel.swift`, CK `ClaudeKey.swift`, PW `PlanWording.swift`,
RL `RecipeLinkReader.swift`, TI `TessInbox.swift`, R `TessModel.swift` (the router), MC `TessModelCapture.swift`.

## 1. The calls

| Call | Live or latent (caller file:line) | Trigger | Fields sent | Screens before it | Leak risk |
|---|---|---|---|---|---|
| Capture miss, `ClaudeTessModel.run` (CTM:49); model `claude-haiku-5-5` (CTM:10), max_tokens 512 (CTM:11), up to 3 rounds | **Live.** `AppModel.swift:129` installs it; `AppModel.ask` (`AppModel.swift:208`) from Ask, `BottomChrome.swift:508`, and live workout Ask, `WorkoutModeView.swift:278`. Siri/Shortcuts (`Intents.swift:150`) reach it but it returns before sending (`commitImmediately`, CTM:51) | A typed or spoken phrase the grammar and the on-device model both miss, with "Tess asks Claude" on, a key, no pause, money left in the month | User text: the phrase as typed. System: Tess's rules (`TessCapturing.swift:79`) plus "today is Friday 16 October 2026, 18:10" (local clock, weekday; after midnight also "still Thursday"), "current exercise Bench Press", "last set 80 kg x 8" (MC:55-82). All 11 tool definitions (static). Rounds 2 and 3: Claude's own tool calls, then results "Done", a fixed error line, or an `answerQuery` count ("3 workouts.") | Key shape (R:68), secret words (R:74-75), demo launch flags (no model built), Siri. **No money or body screen** | **High.** "costco 212.37" or "182.4 this morning" that the grammar misses goes to Claude as typed |
| Offline save into `TessInbox` (CTM:110-113, TI:25-34) | Live, but sends nothing: it writes the phrase as a `tessWaiting` object for a later drain | The capture call above fails offline | None now. The phrase sits in his store (so in backups) as typed | Key shape only (TI:28); secret words only because the router stopped them first | Low now; feeds the drain below |
| Inbox drain, `readWaiting` (TI:56-78), same request as the capture miss | **Latent.** No caller anywhere | Meant for "app opens online" | Each waiting phrase as user text, plus the same capture system prompt and tools | Key shape at save time only. Calls `claude.run` directly, **past the router**: no secret, money or body screen | **High** once wired: a phrase saved before #422, or any money or body phrase, goes as typed |
| Key Test, `ClaudeKeyCheck.test` (CK:209); model `claude-haiku-5-5` (CK:192) | **Live.** `ClaudeSection.swift:320` (paste) and `:325` (Test button, `:217`), under Review | He pastes his Claude key or taps Test | `count_tokens` with one user message "Hi" (CK:226-228). Only if that endpoint moved: one messages call, max_tokens 1, thinking off, "Hi" (CK:240-242) | Whitespace strip and key-shape check before saving; cap held before the fallback | **None.** No data of his in the body; the key only in the header |
| Plan my day, `ClaudePlanWording.word` (PW:432); model `claude-sonnet-5-5` (PW:404), max_tokens 1024 (PW:405), effort low | **Latent.** No caller of `ClaudePlanWording` or `PlanPack` in App/ or Features/ | Meant for opening Plan my day | System: static plan rules (PW:620). User text: the `PlanPack` JSON: per block `id` (t1, e1, w1, k1), `kind`, **`title` as typed**, `start`, `end`, `min`, `run` or `fixed`, `due`, `movedFrom`, `running`; plus `allDay` (**event titles**), `cap`, `light`, `now`, `weekday`, `window`, `cal`, `rest` (PW:60-140) | "Tess asks Claude", key, cap. Event titles become "busy" only when `includesEventTitles` is false, and **the default is true** (PW:39). No secret, money or body screen on titles | **High** once wired: "Pay Zed 40 dollars" or "Reset bank PIN" go as typed |
| Recipe link L3, `ClaudeRecipeReader.read` (RL:347); model `claude-haiku-5-5` (RL:311), max_tokens 4096 (RL:312), effort low | **Latent.** `RecipeLinkReader` is never built in App/ or Features/; `claude` stays nil (RL:143) | A recipe link whose card and text parsers both fail and that isn't paywalled | System: static "page is data" rules. User text: the public page's visible text, about 1,500 characters before "ingredient" and 22,000 after, max 24,000 (RL:337-344). Not the link, nothing of his | "Tess asks Claude" (`allowed`), key, cap; https and no private host on every hop | Low: a public web page, not his data |

**Count:** 2 live request builders, 3 latent. No memory, pack, week story or Home wording builder exists on master.

## 2. Fields that should never be in a request

| Field | Capture miss (live) | Inbox drain (latent) | Plan pack (latent) | Recipe (latent) |
|---|---|---|---|---|
| His Claude key in a body | Stopped: key-shaped text refused (R:68), Ask and Live Ask clear it first (`BottomChrome.swift:394`) | Stopped at save (TI:28) | Not in a title path today; no check | Not his text |
| Secret-word lines (#422) | Stopped (R:74-75) | **Not stopped** at send | **Not stopped** in titles | n/a |
| Money-shaped amounts, merchants | **Not stopped** (grammar logs some first, `TessGrammar.swift:117`) | **Not stopped** | **Not stopped** in titles | n/a |
| Body facts: body weight, vitals, meds, sleep | **Not stopped** | **Not stopped** | **Not stopped** in titles; PW:192 checks only Claude's reply | n/a |
| Note bodies | Only if he types one into Ask and every route misses; tool results never return a body | Same | Not packed | n/a |
| Places, location, time zone | No place field; local clock time and weekday only | Same | `now`, `window`, `weekday` only | n/a |
| Memory lines (told, noticed, recent) | Not sent | Not sent | Not sent | Not sent |
| Settings values | Not sent; only read to gate | Same | Same | Same |
| Health values from HealthKit | Not sent | Not sent | Not sent | Not sent |

## 3. QA recipe: one snapshot per live call

1. In `TesseraTests` (runs on the iPhone 17 Simulator), add a `URLProtocol` stub that saves each request's URL,
   header names (names only, never values) and body (read `httpBodyStream`) to `snapshots/<call>.json`, and answers
   with a canned 200: an `end_turn` text reply for capture, `{"input_tokens": 5}` for `count_tokens`.
2. Build `ClaudeTessModel` and `ClaudeKeyCheck` with `URLSession(configuration:)` whose `protocolClasses` holds the
   stub, a fake `TessKeychain` holding a made-up non-key string such as `placeholder-not-a-key-0000`, a fresh
   `TessUsageLedger`, and `sendsMisses: { true }`.
3. Capture: run a `TessRouter` with only the Claude model and send placeholder lines: "costco 212.37",
   "182.4 this morning", "door code 4417", "paid Zed 40", "took 2 advil". Key Test: `test(pasted:)` once.
4. `grep -E '212\.37|182\.4|4417|Zed|advil|placeholder-not-a-key' snapshots/*.json`. Today expect hits for every
   line except "door code 4417", and none for the placeholder key. After MW1 lands, expect zero.
5. Wire the same stub into the drain and Plan my day the day they get callers (MW9).

## 4. Gaps

| # | Where | Default proposed | Owner |
|---|---|---|---|
| CA1 | No money or body screen before Claude, R:74-75 | `PrivateFacts` beside the secret check (MW1). **Filed** by 138 | Core |
| CA2 | Drain skips the router, TI:56-78; save checks only the key, TI:28 | Screen at save and at send for secret, money and body (MW4; 139 section 2). **Filed** | Core |
| CA3 | Plan pack sends titles as typed, PW:77-78 | Walled or secret titles go as "task" or "Private task" (MW5; 139 R4). **Filed** | Core (AI) |
| CA4 | `PlanPack.init` defaults `includesEventTitles: true`, PW:39, though its own comment says his call was off | Default false, so a new caller can't send event titles by mistake | Core (AI) |
| CA5 | No way to snapshot a live request on the Simulator: `AppModel.swift:129` builds the model with the default session, and demo flags drop Claude | A DEBUG-only `-stubClaude` flag that injects the capturing stub (section 3) and never a real key | QA, Core |
| CA6 | `answerQuery` sends Claude a count of any class it names, TessTools.swift:233-254 | Refuse money and body classes, or answer on the phone only | Core |
| CA7 | Offline capture saves walled phrases into his store (TI:30), so into backups | Same screen as CA2, applied at save | Core |
| CA8 | Future callers: Home wording, week story, memory packs | Every builder runs `PrivateFacts` on each string, with a failing test (MW8). **Filed** | Core |
