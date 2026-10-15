# Spec: Tess model layer (foundation)

*Planning lead, 2026-10-15 18:55. Kaushik wants Claude in Tessera's foundations as early as possible, not added late. This slice goes early in Core's queue after tonight's release. Research scouts the details first: `../research/tess-model-layer.md`, to come.*

## What it is

There is one place in the engine where Tess asks a model for help. Everything that wants a model goes through it: capture beyond the grammar, Plan my day wording (M4 slice 6b), questions about the log (M3 slice 7), recipe-from-link (kitchen v2), and later "build me an app".

## Slice

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **Model router** | The order is always the same: grammar first, then on-device Foundation Models, then Claude, each step tried only when the one before has no confident answer. One `TessModel` protocol with on-device and Claude implementations. Each call is tagged with the purpose it serves (capture, plan, question, recipe) | Engine |
| 2 | **Claude client** | Calls the Anthropic Messages API directly from the app with structured output (tool use with `strict` schemas generated from the action catalog). Model per purpose: Haiku 5.5 for capture and recipes, Sonnet 5.5 for plan and questions. The catalog and schema go first, with prompt caching | Engine |
| 3 | **Key in the Keychain** | Kaushik pastes his API key once in Settings. It's stored in the Keychain, never in the repo, logs or exports. With no key, Tess quietly stays on-device | Engine + Settings row |
| 4 | **Cost cap** | Token usage and an estimated cost are logged per call. A monthly cap (default $5) and a daily cap (default $0.50) are enforced. Once a cap is hit, the call falls back to on-device or the rules version, with one calm line. Settings shows "this month: $0.84 of $5" | Engine + Settings row |
| 5 | **Writes only through the kernel** | A model returns proposed actions only. The kernel validates them, they show as ghost rows, and they commit on tap or after 2 s with undo. A model never writes directly, and every op records the actor (`tess:claude`, `tess:ondevice`) | Engine |
| 6 | **Privacy line** | The bloom shows a small cloud mark whenever data leaves the phone. A per-class "never send to Claude" flag exists, defaulting to off for every class | Engine + Tess UI |
| 7 | **First uses** | Capture fallback and Plan my day wording (6b) go through the layer. Each has an eval set (`tess-eval-phrases.md`, `plan-my-day-scenarios.md`) run against both on-device and Claude | Engine |

## Defaults taken

- The app calls the API directly, with no proxy server, since this is a personal app.
- Caps are $5 a month and $0.50 a day.
- Haiku handles capture and Sonnet handles planning. Opus waits for "build me an app".
- No streaming in v1 of the layer, since ghost rows fill in when the call finishes.
- It needs Kaushik's API key, which the coordinator will ask for at the huddle.
