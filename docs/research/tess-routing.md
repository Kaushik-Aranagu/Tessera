# Tess routing: when the grammar runs out

For: Core engine (Tess engine), Product lead
Date: 2026-10-15

## Decision

Grammar first, always. On-device Foundation Models only when the grammar returns no parse or a low-confidence parse. Never PCC or Claude for capture without Kaushik's OK. Every path ends in a ghost row or a "Didn't catch that" line, never a silent write.

## Where the grammar runs out

1. **Free word order and fillers.** "um put down eighty kilos for like seven on bench".
2. **Numbers as words, mixed with digits.** "eighty two and a half for six", "a dozen eggs". Fix in the grammar with a normaliser.
3. **Run-ons with several intents.** "log bench eighty for eight and remind me to call mom tomorrow". Needs splitting into two actions.
4. **Fuzzy references.** "the heavy one", "the thing I made last week", "my usual". Needs world state, not syntax.
5. **Self-correction.** "squat 100 for 5, no wait, 4". Grammar can learn "no wait"; looser forms ("actually make that...") are model work.
6. **Indirect phrasing and fuzzy time.** "I'm out of eggs", "after work", "end of the month", "sometime next week".
7. **Questions and requests outside the tools.** "what should I cook", "book a table". Expected result is a polite refusal, not a guess.

Rule of thumb: if a phrase class shows up often and has a fixed shape, grow the grammar. The model is for the long tail.

## Routing rule

1. Normalise: lowercase, strip fillers (um, uh, like, so, okay), words to digits, "and a half" to .5.
2. Grammar parses. Confidence is high when every required slot is filled and names resolve to one object. Ship it to the ghost row.
3. Low confidence or no parse: send to the on-device model with `@Generable` output that mirrors the action enum (enums with associated values are supported). Use `DynamicGenerationSchema` with `anyOf` for live names (exercises, recipes, lists) so the model can only pick real objects.
4. The kernel validates the result. A failed validation counts as no parse.
5. Model not available (Apple Intelligence off, model downloading, error): show "Didn't catch that" with the grammar's best partial guess.

Prompt budget: instructions plus enum schema plus today's state (current exercise, last set, open cook, list names). Keep it under about 1,500 tokens. Official sources say the on-device window is **4,096 tokens**. That conflicts with the 8,192 in `ai-and-tess.md`; treat 4K as the budget until it is checked on device.

## Latency and failure

- **Ghost row always.** Grammar result shows at once. On the model path the ghost row shows the raw text in a dim "reading" state, then fills in. Commit stays tap or 2 s, starting only once the action is filled in.
- **Prewarm** the session when the Bar is opened or held, not at launch.
- **Budget (not verified, measure on device):** grammar under 50 ms; model target under 1.5 s on iPhone 15 Pro or later. Past 3 s, cancel and show "Didn't catch that."
- **Errors** (`exceededContextWindowSize`, `guardrailViolation`, `unsupportedLanguageOrLocale`, `assetsUnavailable`, `rateLimited`, `concurrentRequests`): all end in one line, "Didn't catch that. Bench 80 x 8?" with a guess where there is one. No retries in the background.
- **Model returns `none`:** "Didn't catch that." plus the nearest action ("Want a task instead?").
- **Multi-intent:** one ghost row per action, committed together, undone together.

## How to measure

- **Eval set:** `tess-eval-phrases.md`, 200 phrases, plus the 50 in `kitchen-phrases.md`. Each row has an expected action and key fields.
- **Pass rule:** action matches and every key field matches. Partial credit is a fail.
- **Report per area** (workouts, tasks and notes, kitchen, lists, messy) and per route: grammar pass rate on rows tagged grammar, model pass rate on rows tagged model, and the false-action rate on negatives (target 0).
- **Targets for v1:** grammar rows 100% (they are regression tests), model rows 80% or better, negatives produce no write. Also log p50 and p95 latency per route.
- **When:** grammar rows on every `swift test`. Model rows with Apple's Evaluations framework on device, on each OS update, since there is no model version pinning.
- **Real traffic:** log "Didn't catch that" phrases locally; weekly, move common shapes into the grammar, the rest into the eval set.

## Unverified or open

- Model latency figures above are targets, not measured.
- `ToolCallingMode` (named in `ai-and-tess.md`) was not found in Apple docs; not used here.
- The 4K vs 8K context window question.

## Sources

- [Foundation Models framework docs](https://developer.apple.com/documentation/foundationmodels)
- [Guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation): enums with associated values, `anyOf`.
- [exceededContextWindowSize](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/exceededcontextwindowsize(_:)): 4,096 tokens.
- [Apple forums: on-device limits](https://developer.apple.com/forums/thread/833642): 4K, no version pinning.
- [WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241/)
- [Atelier Socle API guide](https://www.atelier-socle.com/en/articles/foundation-models-api-guide): `prewarm()`, errors.
