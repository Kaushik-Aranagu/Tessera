# Tess-built rooms: prior art and frontier ideas

Research survey, 27 Oct 2026. Docs only. Web content was read as data. Anything marked **[unverified]** came from secondary sources, or I could not confirm it from a primary page.

## Bottom line

- **One shape works wherever it has shipped.** The phone owns a fixed set of native components; a document composes them and binds them to data. Anything beyond composition runs in an interpreter (JavaScript, wasm) or waits for a new build. True of Airbnb, Lyft, Shopify, DoorDash, DivKit, rfw, A2UI and json-render.
- **Tessera's limits come from the OS, not App Review.** iOS will not load native code from outside the signed bundle and gives apps no JIT. So tier 3 always means a new build; anything changed without an install must be data, shaders or interpreted code.
- **Each tier has a precedent.** Tier 1: A2UI and json-render plus constrained decoding. Tier 2: Metal compiles shader source at runtime (the SwiftUI bridge is the open risk). Tier 3: UICoder-style compile, render and critique loops on the edge Mac.
- **Add a tier 2.5:** logic compiled to wasm on the Mac, interpreted on the phone.

## 1. Server-driven UI in production

**Airbnb Ghost Platform** ([InfoQ](https://www.infoq.com/news/2021/07/airbnb-server-driven-ui/), [Airbnb post](https://medium.com/p/842244c5f5)). Three nouns: sections (independent component groups), screens (a layout plus "placements" saying where sections go) and actions. *Steal:* exactly these nouns. Places are screens, elements are sections, actions are verbs Tess can see. *Avoid:* a giant section library every client version must support forever.

**Lyft** ([eng.lyft.com](https://eng.lyft.com/the-journey-to-server-driven-ui-at-lyft-bikes-and-scooters-c19264a0378e)). The server returns view models, not business models, and the same system feeds Live Activities ([post](https://eng.lyft.com/crafting-seamless-journeys-with-live-activities-abe82e98546f)). *Steal:* one document drives room, widget and Live Activity. *Avoid:* copying data into the payload; bind elements to objects by `ObjectPath` so data stays live and on the phone.

**DoorDash** ([2021 post](https://careersatdoordash.com/?p=5364)) and **Shopify Shop** ([post](https://shopify.engineering/server-driven-ui-in-shop-app)). DoorDash's first attempt tied components to data models, so every change touched several services; the redo used generic UI primitives owned by the client. Shopify's server picks sections and a layout (grid or shelf) to dodge a weekly release. *Steal:* primitives over domain widgets, and "element" and "arrangement" as separate fields.

**Yandex DivKit** ([GitHub](https://github.com/divkit/divkit)). One JSON schema generates every platform's API; layouts carry `@{}` expressions with variables, operators and functions ([resolver docs](https://pub.dev/documentation/div_expressions_resolver/latest/)). *Steal:* schema first. Write the room schema once and generate the Swift types and the JSON Schema for constrained decoding. *Avoid:* its own rendering engine and component set (a competitor's description, **[unverified]**); rendering must go through `ThemeConcept`.

**Flutter Remote Flutter Widgets** ([pub.dev](https://pub.dev/packages/rfw)). The app registers a local widget library; remote blobs can only compose it. The README warns against moving a whole app onto it and lists poor fits (page transitions, drag and drop, custom painters); logic can optionally ship as wasm. *Steal:* that boundary and that warning list. *Avoid:* events wired to hard-coded results.

**Cash App Redwood + Zipline ("Treehouse")** ([Fragmented episode](https://fragmentedpodcast.com/episodes/245-treehouse-redwood-and-zipline-with-colin-white/)). Shared Compose code drives native widgets; logic is downloaded and run in an embedded JavaScript engine (reportedly QuickJS, **[unverified]**). *Steal:* the legal over-the-air split of native widgets plus interpreted logic. *Avoid:* a second toolchain for a one-person app.

**Thoughtworks Radar** ([entry](https://www.thoughtworks.com/radar/techniques/server-driven-ui)) warns the schema can become a "god-protocol". *Avoid:* one schema that says everything; keep the tiers.

**Apple's own surfaces.** App Clips are signed binaries capped at 15 MB (50 MB for digital invocation on iOS 17+, [forum](https://developer.apple.com/forums/thread/740061)); widgets are compiled SwiftUI on a timeline, interactive only through App Intents. Apple's light surfaces are compiled code with dynamic data.

## 2. LLM generative UI

**Vercel AI SDK.** RSC `streamUI` development is paused; the docs cite remount flicker and no multi-step tool calls, and move rendering to the client ([migration guide](https://ai-sdk.dev/docs/ai-sdk-rsc/migrating-to-ui)). *Steal:* the model emits a typed tool call; the client renders. *Avoid:* streaming rendered components. v0's full React output is a tier-3 analogue.

**Google "Generative UI"** ([blog, 18 Nov 2025](https://research.google/blog/generative-ui-a-rich-custom-visual-interactive-user-experience-for-any-prompt/)). Gemini 3 Pro writes whole interactive pages with tools, long instructions and post-processing fixers. Raters put it just below human experts, but it can take a minute or more. *Steal:* the post-processors and an expert-made reference set for evaluation. *Avoid:* full code per request as the fast path.

**A2UI** ([spec v0.8](https://a2ui.org/specification/v0.8-a2ui/)). Google's catalog of trusted native components. Components travel as a flat list linked by string IDs (transformers emit flat lists better than deep trees), data updates travel separately, and the client buffers until `beginRendering` to avoid a flash of incomplete content. *Steal:* nearly all of it as the room document's shape. *Avoid:* tying it to an agent transport.

**MCP Apps, MCP-UI, OpenAI Apps SDK** ([SEP-1865](https://modelcontextprotocol.io/seps/1865-mcp-apps-interactive-user-interfaces-for-mcp), [Apps SDK launch](https://techcrunch.com/2025/10/06/openai-launches-apps-inside-of-chatgpt/)). `ui://` HTML in sandboxed iframes, deny-by-default CSP, host reachable only by JSON-RPC over postMessage. *Steal:* the host-mediated bridge; a room has no network and every effect is a request. *Avoid:* web views for core rooms (they break the polish bar).

**Anthropic artifacts** ([help](https://support.claude.com/en/articles/9487310-what-are-artifacts-and-how-do-i-use-them)). Sandboxed pages that can call Claude from inside ([Willison](https://simonwillison.net/2025/jun/25/ai-powered-apps-with-claude)). *Steal:* an element that can "ask Tess" at run time. *Avoid:* regenerating the whole file for a small edit.

**json-render** ([GitHub](https://github.com/vercel-labs/json-render)). A Zod-validated catalog of components and actions, streamed as JSON Patch ops. *Steal:* patches as the unit of change; they map one-to-one onto the op log.

**Galileo AI** (now Google Stitch, [summary](https://uxmagic.ai/blog/galileo-ai-is-now-google-stitch)) and **Uizard** (Miro, 2024, [post](https://miro.com/blog/uizard-joins-miro/)). *Steal:* several variants to choose from. *Avoid:* output that is a design file, not a running room.

**Papers:**
- **UICoder** ([Apple ML](https://machinelearning.apple.com/research/uicoder), NAACL 2024). About a million self-generated SwiftUI programs, filtered by the Swift compiler and a vision-language model comparing each render to its description. The template for tier-3 checks on the edge Mac.
- **Jelly** ([arXiv 2503.04084](https://arxiv.org/abs/2503.04084), CHI 2025). The LLM writes an object-relational task model first, then the UI from it. Matches Tessera: class first, room second.
- **Generative Interfaces for Language Models** ([arXiv 2508.19227](https://arxiv.org/abs/2508.19227)). A structured interface-specific intermediate form plus iterative refinement beat plain-language specs.
- **Constrained decoding.** Claude structured outputs and strict tools ([docs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)); Apple guided generation, with `DynamicGenerationSchema` for schemas built at run time ([WWDC25 301](https://developer.apple.com/videos/play/wwdc2025/301/)); [XGrammar](https://arxiv.org/abs/2411.15100). *Avoid:* reasoning inside the schema. "Let Me Speak Freely?" ([arXiv 2408.02442](https://arxiv.org/abs/2408.02442)) found strict formats hurt reasoning, so plan in prose, then emit a small schema.
- **Critique by rendering.** [UIClip](https://arxiv.org/abs/2404.12500) scores design quality from a screenshot plus text; [Owl Eyes](https://arxiv.org/abs/2009.01417) finds overlap and missing images.

## 3. Live, malleable systems

**Smalltalk, Squeak, Morphic** ([Maloney & Smith, UIST '95](https://uist.acm.org/uist1995/abstracts/Maloney.html)). Every on-screen thing is a live object you can point at and change, layout included, while it runs. *Steal:* a halo on any element so Tess sees exactly what he points at. *Avoid:* image-based state with no diffable history.

**Self** ([papers](https://bibliography.selflanguage.org/)). Objects are copied from prototypes, not made from classes. *Steal:* new rooms as copies ("like Kitchen, but for plants").

**HyperCard** ([HyperTalk](https://en.wikipedia.org/wiki/HyperTalk)). Scripts live on objects; an unhandled message climbs from button to card, background and stack; cards inherit from backgrounds. *Steal:* that message path as the reaction model (element, room, app), and the background/card split, which is Tessera's place/data split. *Avoid:* free-form scripts with global reach.

**Dynamicland / Realtalk** ([progress report](https://dynamicland.org/2022/Progress_report/)). Programs coordinate by stating facts, not calling each other: `Claim`, `Wish`, `When`. *Steal:* coordination through visible facts. *Avoid:* untraceable cascades; every reaction needs a "because".

**Bret Victor** ([Inventing on Principle](https://vimeo.com/36579366)). Creators need an immediate connection to what they make. *Steal:* every change visible at once and adjustable by hand.

**Ink & Switch.** The *Malleable software* essay (2025, [essay](https://www.inkandswitch.com/essay/malleable-software/), [announcement](https://buttondown.com/geoffreylitt/archive/new-essay-malleable-software)) argues for a gentle slope from using to changing tools, and says AI coding alone is not enough (the site would not load for me, so this is from summaries). *Potluck* ([project](https://www.inkandswitch.com/project/potluck/)) adds structure to free text gradually; *Embark* ([project](https://www.inkandswitch.com/project/embark/)) puts a dynamic document in place of siloed apps. *Steal:* a blank-frame room that gains structure only when asked, over data shared across rooms.

**The Elm architecture** ([guide](https://guide.elm-lang.org/architecture/)). *Steal:* room logic as a pure `update(message, state)` that returns new state plus requested effects, which makes undo, replay and tests nearly free.

## 4. iOS constraints and runtimes

**App Review guideline 2.5.2** ([guidelines](https://developer.apple.com/app-store/review/guidelines/)) says apps may not "download, install, or execute code which introduces or changes features or functionality of the app". Guideline 4.7 allows HTML5 and JavaScript mini apps, with conditions, including "explicit user consent in each instance" before data is shared (4.7.3).

**Developer Program License Agreement 3.3.1(B)** ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)) says "an Application may not download or install executable code". Interpreted code is allowed if it does not change the app's primary purpose, does not "bypass signing, sandbox, or other security features of the OS", and creates no storefront.

**What this means for a sideloaded personal app:**
- **App Review never sees it,** so 2.5.2 does not gate it. Whether the DPLA binds a free Personal Team account is **[unverified]**.
- **The OS enforces the real line.** Apple DTS: you can only `dlopen` "a library that's either built in to the OS or embedded within your app"; Developer Mode's holes "are tightly constrained to the requirements of Xcode"; the goal "is quite feasible for interpreted code" ([thread, Jan 2025](https://developer.apple.com/forums/thread/773210)). The same thread reports out-of-bundle loading with Xcode attached worked on iOS 17, not iOS 18. There is no JIT; in-process JavaScriptCore is interpreter-only ([Lucid](https://lucid.co/techblog/2019/01/03/javascriptcore-10-months-later)). Avoid debugger-based JIT tricks (StikDebug, `get-task-allow`).
- **Free profiles expire after 7 days** and reportedly allow 3 apps per device ([forum](https://developer.apple.com/forums/thread/724896); **[unverified]** against Apple docs). The app is reinstalled weekly anyway.

**React Native over-the-air updates** are allowed because the JavaScript bundle is interpreted code on an already-signed engine; native changes still need a build ([Expo](https://docs.expo.dev/eas-update/codepush/)). CodePush retired with App Center on 31 March 2025.

**Interpreters:**
- **JavaScriptCore:** a system framework with Swift bridging; interpreter-only.
- **wasm3** ([GitHub](https://github.com/wasm3/wasm3)): by its own CoreMark figures about 4–5× slower than JIT wasm and about 12× slower than native; in minimal maintenance since 2023 ([report](https://gigazine.net/gsc_news/en/20231222-wasm3-russians-destroyed-house-ukraine)).
- **WasmKit** ([GitHub](https://github.com/swiftwasm/WasmKit)): an embeddable Swift runtime that lists iOS support. With SwiftWasm on the Mac, it is the Swift-native pick.
- **Wasmer's Swift SDK** reportedly runs wasm in a hidden WKWebView on iOS 27 (experimental, **[unverified]**). **Lua** is a small embeddable C interpreter.

**Metal and SwiftUI shaders.** `MTLDevice.makeLibrary(source:options:)` compiles shader source on the device ([docs](https://developer.apple.com/documentation/metal/shader-libraries)); it is GPU code, so outside the executable-code rules (my reading). SwiftUI's `ShaderLibrary(url:)` and `ShaderLibrary(data:)` take only a precompiled metallib ([docs](https://developer.apple.com/documentation/swiftui/shaderlibrary)). No documented path turns a runtime `MTLLibrary` into one: a forum question went unanswered ([thread](https://developer.apple.com/forums/thread/733414)), and a dynamic-library attempt hung in Playgrounds ([thread](https://developer.apple.com/forums/thread/774771)). *Practical path:* the edge Mac compiles `.metal` to `.metallib` and the phone loads it with `ShaderLibrary(data:)` (downloaded metallibs on a device **[unverified]**). Source compiled on the phone renders through `MTKView`. Functions must be `[[ stitchable ]]`.

**SwiftUI limits** ([Demystify SwiftUI, WWDC21](https://developer.apple.com/videos/play/wwdc2021/10022/)). `AnyView` hides the structure SwiftUI uses to diff and animate. Use a recursive `enum Node` inside a `@ViewBuilder`, and `ForEach` keyed by the document's node IDs, so edits animate instead of remounting. Give each node its own `@Observable` state so one change does not redraw the room.

## 5. Safety and robustness

**Three gates, in order:**
1. **Shape.** Constrained decoding: Claude strict tools, or Foundation Models guided generation.
2. **Sense.** An engine validator inside `apply`, the same pattern as the planned `ClassProposalValidator` in `docs/ai/stretch-3-build-with-tess.md`.
3. **Sight.** Render lint:
   - on the phone: overlap computed from element frames, hit targets of at least 44 pt, WCAG 4.5:1 contrast on resolved token pairs, and a render at the largest Dynamic Type in both themes;
   - on the edge Mac: XCUITest `performAccessibilityAudit` checks contrast, hit region, Dynamic Type and clipped text ([Apple](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app)), plus a UIClip- or Owl Eyes-style screenshot critique.

**Undo and versioning.** Room edits go into the existing `OpRecord` log as op groups with inverses. Make undo a new "restore" op so the stacks survive a reload ([Stewen & Kleppmann 2024](https://arxiv.org/abs/2404.11308)). [Automerge](https://automerge.org/) earns its place only with a second device or editor. Each document names its schema version and minimum renderer build; a renderer that is too old shows the last good version.

**Sandboxing scripts.** A JavaScriptCore or WasmKit instance has no ambient authority: it can call only the functions it is handed. Add step and time budgets and a memory cap, and run it off the main actor (WasmKit fuel metering **[unverified]**).

**Capabilities.** Use the object-capability model ([Miller, *Robust Composition*](http://www.erights.org/talks/thesis/)): the handle is the permission, as in [WASI](https://wasi.dev/) and MCP Apps' bridge. For Tessera that means `read(Class)`, `write(Class)` (always as a pending op group), `timer`, `haptic` and `notify`. Network goes only through Tess, and money is never grantable to a room.

## 6. Frontier ideas for Tessera

1. **The room is an object, and its history is the op log.** Store each room as objects in `TesseraContext`, with bindings expressed as `ObjectPath` queries rather than copied values. UI then becomes linkable, searchable and undoable like any data. "Last Tuesday's version of this room" becomes a query, and Claude sees structure without ever seeing his objects.

2. **Speak in traits, tune with a dial.** Tier-1 edits are deltas on the look catalogue's axes (density, size, motion) and its tokens, never literal values, so they survive a theme swap. After each spoken change, the axis that moved shows as a scrubbable dial for a few seconds, so "a bit calmer" can be fine-tuned by thumb.

3. **Ghost variants.** A vague ask produces two or three ghost variants stacked in place, which he swipes between and picks by voice, with the house 2-second drying line. Picks become local preference data the on-device model uses to rank future variants.

4. **Facts, wishes and reactions.** Elements coordinate through a room-local fact bus in the Dynamicland style. For example, "rest timer: 90 s left" is a claim and "glow the next set" is a wish. Tess can then answer "why is this glowing?" by tracing facts, and the edge Mac can replay a week of real facts against a new room version as a regression test drawn from real life.

5. **A reach diff on consent.** Every element declares the capabilities it needs, and the validator adds them up into the room's reach. When an edit widens that reach, the ghost carries a separate one-line diff ("can now write Sets") that needs its own tap, apart from the look change.

6. **Tier 2.5: signed interpreted packs.** The edge Mac compiles Swift logic to wasm and Metal to metallib, then signs both with a key whose public half ships in the app. The phone verifies the signature and runs them in WasmKit or `ShaderLibrary(data:)`. Most "code" changes land with no reinstall. Only new native primitives wait for the weekly re-sign, which becomes the release train.

7. **Primitive promotion.** The phone logs which compositions, scripts and shaders he keeps. The edge Mac proposes promoting the most-used ones into native SwiftUI components under the same type name in the next weekly build. Documents stay the same but get faster and more polished, like a tracing JIT working at the product level.

8. **Render, check, then show.** Before a ghost appears, the phone renders it offscreen at the extremes (largest Dynamic Type, both themes) and runs geometry and contrast lint. It then asks the on-device model whether a text summary of the layout matches the request. Failures retry once or quietly fall back, so he only ever sees changes that passed.
