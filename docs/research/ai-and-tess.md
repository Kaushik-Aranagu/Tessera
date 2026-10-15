# AI and Tess: scouting report

For: Tess AI (future team) and Product lead
Date: 2026-10-15

Ranked by (daily usefulness x on-device feasibility) / effort. Key facts: the iOS 27 on-device model has an 8,192-token context, better tool calling, image input and `ToolCallingMode`. `PrivateCloudComputeLanguageModel` gives 32K context and reasoning, free under 2M first-time downloads. A new `LanguageModel` protocol lets Claude sit behind the same session API, and Anthropic ships a Swift package for it. The current Claude models are Opus 5.5 (`claude-opus-5-5`), Sonnet 5.5 (`claude-sonnet-5-5`) and Haiku 5.5 (`claude-haiku-5-5`).

1. **Ghost preview, then Stamp.** Quick Capture never writes directly. It returns a proposed batch of syscalls that is drawn as a ghost row (dimmed, bloom in "acting") and commits on tap or after 2 s, with Undo kept afterwards. Why: diff-and-accept plus reversibility marking is the pattern that earns trust in AI edits. How: an `@Generable` struct that maps 1:1 to the syscall enum, validated by the kernel before it is shown. Effort S. [AI UX: reversibility](https://www.aiuxplayground.com/pattern/reversibility-marking)

2. **Gym shorthand by voice.** In live mode, hold the Bar and say "same again", "8", "drop to 70 for 10" or "the 70s". Tess resolves these against the current exercise and last set. Why: voice is about 3 s per set against 15 to 20 s typed, and the phrases that matter are relative ones. How: a deterministic grammar first (instant, offline), with the on-device model as fallback. The current workout state goes in the prompt, which fits easily in 8K. Effort S/M. [Voice logging](https://www.tuffwraps.com/blogs/news/stop-typing-between-sets-how-voice-logging-changed-my-workouts)

3. **One syscall registry, three faces.** Each syscall is declared once. Its declaration generates a Foundation Models `Tool`, an `AppIntent` with its `AppEntity` types, and a Claude tool schema (`strict: true`). Why: Tess, Siri, Shortcuts, the Action button and Claude all stay in sync, and everything stays undoable. Effort M. [WWDC26 FM session](https://developer.apple.com/videos/play/wwdc2026/241/)

4. **Four-step router.** The steps are grammar, then on-device model, then PCC, then Claude. A `DynamicProfile` swaps instructions, tools and model inside one session. Rule: anything that only touches today's objects stays on device, multi-week reasoning goes to PCC, and building and planning go to Claude. Show a small cloud mark on the bloom when data leaves the phone. Effort M. [FM updates](https://developer.apple.com/documentation/updates/foundationmodels)

5. **Ask your log, locally.** Commands like "what did I lift last week" or "best bench at 5 reps" index objects in Core Spotlight and use the new Spotlight search tool for on-device RAG. Answers come back as counts with handles you can tap. Why: this turns history into answers without a network round trip. Effort M. [WWDC26 FM session](https://developer.apple.com/videos/play/wwdc2026/241/)

6. **Tess voice spec, not vibes.** This is a short style guide plus about 40 golden lines that Evaluations tests against: one line, past tense, a number, no greeting, no exclamation marks, and dry humour only on "done" states (and rarely). Why: Humane and Rabbit failed by promising a personality that could do everything, so reliability is the personality. How: write the spec as instructions and test it with Apple's new Evaluations framework on each OS model change. Effort S. [Why the pin and R1 flopped](https://jasondeegan.com/why-humanes-ai-pin-and-rabbit-r1-both-flopped-spectacularly/)

7. **"This" works from Siri.** The open object page is exposed as an App Entity, so Siri onscreen awareness can handle "add this to Push Day" or "log another set of this". Why: Tessera acts like part of the OS for free. The caveat is that the new Siri shipped behind a waitlist. Effort S/M. [Siri in iOS 27](https://macrumors.com/2026/06/02/ios-27-siri-features)

8. **One-line recap on finish.** When a workout ends, Tess writes one line on device, for example "5 exercises, 14 sets, bench e1RM +2.5. 4 of the last 7 weeks." Granola's lesson applies: improve what the user made rather than replace it, and keep their own numbers visible. Effort S. [Granola UX](https://intelligentinterfaces.substack.com/p/how-granola-enhances-note-taking)

9. **Visible memory.** Whatever Tess "knows" (gym days, units, a sore shoulder) becomes a `Fact` object the user can browse, edit or delete, with backlinks to where it was learned. Why: people trust ChatGPT-style memory more when they can see it, and in Tessera it is just another class. Effort M.

10. **Claude for plan, shutdown and build (M4).** These use Sonnet 5.5 for daily plan and shutdown, and Opus 5.5 for "build me an app". The block catalog and schema go first under `cache_control`, outputs are structured, and the result is shown as a ghost app (idea 1) before commit. Haiku 5.5 is the cheap tier for summaries. The Claude Agent SDK is for dev tooling, not the phone. Effort L.

11. **One ambient nudge, max.** No notifications from Tess. At most one suggestion a day appears inside the Now tile (for example "Pull Day is next, 3 days since"). It can be dismissed with "not now" and never returns as guilt. Effort S.

## Top 3 to act on now

1. Ghost preview, then Stamp (1): it defines how every Tess write looks and undoes.
2. One syscall registry, three faces (3): build it alongside the P1 syscalls so App Intents and Tess come almost free.
3. Gym shorthand by voice (2): this is what makes M1's "two weeks of logging" actually stick.
