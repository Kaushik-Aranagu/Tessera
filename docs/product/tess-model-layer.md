# Spec: Tess model layer (foundation)

*Planning lead, 2026-10-15 18:55, reconciled with Research at 18:50. Kaushik wants Claude in Tessera's foundations as early as possible, not added late (18:41). This is Core's first item after tonight's release. **The build plan is Research's brief, `../research/tess-model-layer.md` (merged as #83). Its slices T1 to T7, S1 and S2 are the slices, in its order.** This page records the product calls on top of it.*

## What it is

There is one place in the engine where Tess asks a model for help, in a fixed order: grammar first, then on-device, then Claude. Everything that wants a model goes through it: capture beyond the grammar, Plan my day wording (M4 6b), questions about the log (M3 4 and 7), pasted recipes and lists, and later "build me an app". A model never writes directly. It can only call registry tools, which run as pending ghost rows with undo, with `actor = tess` and the new `route` and `model` columns on the op log.

## Build order (from Research)

T1 TessModel and router (with op-log `route` and `model` columns), then T2 shared tool registry, then T3 Claude route, key and usage ledger, then T4 context packs alongside S1 Settings: Claude, then **T6 Plan my day wording (6b), the first visible win**, then T7 questions via the query AST. T5 eval harness and S2 cloud mark and receipt run alongside.

## Product calls (reconciled)

- **Cost cap: $10 a month, hard stop.** This replaces my earlier $5 a month and $0.50 a day; there is no daily cap. Expected use is under $1 a month, so a daily cap only adds a way to fail on a busy paste day. The Settings line turns amber at 80%. At the cap every use falls back to rules or on-device, and Tess says once "Claude paused until 1 Nov." A Console spend limit on his key acts as a second, server-side cap. Kaushik confirms the number at the huddle.
- **Transport is not settled.** Research recommends Anthropic's beta Claude for Foundation Models Swift package, dropped into the existing `LanguageModelSession` path. **Core confirms in T1** that it builds on iOS 27 under free signing and exposes the usage numbers the cap needs. If it doesn't, the fallback is Research's thin `URLSession` client, and nothing upstream changes.
- **Streaming is fine where the package gives it** (plan and paste fill in as they arrive). This replaces my earlier "no streaming".
- **Tools: 10, not 8** (19:12). Add `completeTask {task: string}` and `rescheduleTask {task: string, startsAt: string(date-time)}` to Research's eight. Both are daily verbs, both exist as kernel actions, and both resolve tasks by name. Tick-off, timers and open-list stay as no tool for now. Research's `tess-eval-claude.md` updates those rows, and the pass bar stays at 90% with 0 false writes.
- **Models:** Haiku 5.5 for capture, questions and pastes; Sonnet 5.5 for plan wording and hard pastes. No Opus yet.
- **Key:** pasted once in Settings and stored in the Keychain on this device only. It never goes in the repo, logs, exports or the op log, and a test checks that. With no key, Claude stays off and Tess runs as today.
- **Privacy:** each use sends only its own context pack, never the database. Health values are never sent; Plan my day sees only "light day: yes or no". A cloud mark shows on the bloom whenever data leaves the phone.
- **Offline:** capture never blocks. A missed capture waits as "1 waiting for Tess" and becomes ghost rows when he's back, never committing on its own.

## Waits on Kaushik (huddle)

His API key, plus the three questions in `review-session.md`: the cap, whether Claude may see sleep and energy, and whether grammar misses go to Claude automatically. Defaults are $10 hard stop, no, and yes. T1 and T2 need none of these.
