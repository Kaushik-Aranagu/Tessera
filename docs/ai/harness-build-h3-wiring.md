HARNESS BUILD TEXT, H3 + APP WIRING FOR H1/H2 (Oct 23, for Core and the builders; relay word for word)

Base: Core's #1364 (Brain, ClaudeBrain, AppleBrain, RunTrace, LatencyBench), #1365 (Door, DoorPolicy, BrainRouter, flag tessLabPolicy), #1367 (PlaybookDirector, PlaybookStore, PlaybookJob, flag tessDirectorPlaybook) and TessConversation from #1346. Kaushik's rules hold: everything ships On, experiments included; lab policy On; smallest model that fits; no Opus; the key never leaves ClaudeBrain.

PART A. APP WIRING FOR H1 AND H2 (Builder A, app target)

A1 One harness per app run. New file App/AppModel+Harness.swift:
  let session = ClaudeBrain.makeSession()   // one for the run, shared by both models
  let haiku = ClaudeBrain(model: .haiku, session: session)
  let sonnet = ClaudeBrain(model: .sonnet, session: session)
  let apple = AppleBrain()
  router = BrainRouter { id in switch id { case .haiku: haiku; case .sonnet: sonnet; case .appleOnDevice: apple; default: nil } }
  door = Door(ledger: TessUsageLedger(store: store, classes: classes), sentLog: TessSentLog(store: store, classes: classes), trace: RunTrace(), router: router,
              policy: { DoorPolicy(labFlagIsOn: FeatureFlags.isOn("tessLabPolicy", off: FeatureFlagStore.off(), asksClaude: self.asksClaude)) },
              asksClaude: { self.asksClaude })
  Keep door, playbookStore = PlaybookStore() and playbookJob = PlaybookJob(door: door, store: playbookStore, enabled: { FeatureFlags.isOn(PlaybookJob.flag, off: FeatureFlagStore.off(), asksClaude: self.asksClaude) }) as stored properties on AppModel, built lazily on first use. A throwaway or demo store (settingsAreReal false, -demo) gets no ClaudeBrain rungs: the provider returns nil for .haiku and .sonnet.

A2 The Director. AppModel exposes var director: any TessDirector { PlaybookDirector(playbook: playbookStore.playbook(day: playbookJob.day())) }. Every layer that asks TessDirection.decide passes model.director, never RuleDirector() directly. Where no layer calls it yet (the 215 Tess layer, the mosaic burst and palette), the new code calls it with model.director. A playbook that fails to load is nil, and PlaybookDirector then answers with the rules.

A3 Filling the playbook. In TesseraApp's scenePhase .active branch: Task(priority: .utility) { await model.fillPlaybookIfNeeded() }. It returns at once unless no playbook is stored for today's TesseraDay (the 4 am edge) and PlaybookStore.runs(day:) < 3. It is skipped in Low Power, while a live workout is presented, and on a throwaway store. It waits 2 s after becoming active so the first frame never waits on it. Inputs: part of day and weekday from TesseraDay, quiet from quiet hours, reduceMotion, the app accents, and the last 10 DirectorContext.recent keys. A .filled result needs no UI; the next decide reads it.

A4 Developer mode. Add three rows under a "Harness" group: "Run latency bench" (runs LatencyBench through the same brains, then shows RunTrace.bench()), "Trace" (the last 50 TraceSpan rows as plain lines: name, brain, model, ttft, total, tokens, cost, outcome; no request text exists in them), and "Today's playbook" (each entry with its why, or "Rules today"). All three read only.

A5 Accept (app): a cold launch after 4 am fills one playbook (one director-playbook span in Trace, one sent-log row); a second foreground the same day sends nothing; with tessDirectorPlaybook Off or Tess asks Claude Off nothing is sent and the layers look as before; the bench runs on his phone and its table shows; scripts/test.sh All green.

PART B. H3, TESS STREAMING LOOP (Core, TesseraCore/Sources/TesseraTess/Harness/)

B1 TessRun.swift. public final class TessRun, one per ask.
  public enum TessRunEvent: Sendable { case waiting; case words(String); case ghost(UUID); case finished(String); case failed(String) }
  public func ask(_ text: String, about: [ObjectRecord], screen: String?) -> AsyncStream<TessRunEvent>
  .waiting fires at once, so the layer can show her hearing or thinking state. .words carries text deltas as they arrive. .ghost carries each pending row a tool made. .finished carries her whole reply. .failed carries a phone-made line, never a raw error.

B2 Which brain (smallest that fits). Phone first: the capture grammar (TessCaptureEngine) gets the text first and a phrase it can do never reaches TessRun. Then a rule picks the rung:
  open (a question with why, should, plan, how am I, compare, what do you think, or over 18 words) -> ladder [.sonnet, .haiku, .appleOnDevice], effort low, thinking off, maxTokens 400, hedge on (Haiku after 1.5 s with no first token);
  everything else (lookups, counts, small actions) -> ladder [.haiku, .appleOnDevice], toolChoice auto, maxTokens 300, hedge off.
  The rule is one function, pickRung(_:), so a typed net can replace it later. No Opus.

B3 The pack (context, in this order so the prefix caches):
  system[0] Tess's voice and rules: fixed text, cacheAfter.
  tools: TessTools.definitionsJSON() plus one read tool, open (below). Fixed order.
  system[1] the TessMemory profile block (shape A), cacheAfter. It changes about once a day.
  messages: TessConversation.forClaude(asksClaude:) (the last 4 turns, never a held-back turn), then the ask.
  fragments on the ask: the screen line (Describe.sentence of what is on screen), today's digest (Home's day facts) and the about objects' shown text. A fragment from a money, health, body, calorie or calendar object (TessAskRouter.isUnnameable) is tagged deviceOnly. Under lab it goes to Claude and the sent log records it. Under strict it doesn't. A key-shaped ask is refused before the Door, under both policies.
  Stored turns don't change: TessConversation still stores placeholders for walled words. Lab changes what is sent live, not what is kept.

B4 The tool: open(handle, depth). Input: a short handle that appears in the pack (never a UUID) and a depth of 1 or 2. Output: the object's Describe.sentence plus the shown names of the objects it links to (depth 2 adds their links too). At most 1,200 characters. Read only.

B5 The loop. At most 3 rounds; each round is one door.run. When a toolUse arrives, start it at once. Reads (open, answerQuery) run in parallel. Writes (every other TessTools tool) run one at a time, through TessTools.run(..., pending: true), within maxRecordsPerPhrase, and each new op becomes a .ghost event. All tool results go back together in one user message. After round 3, or when a round makes no tool call, the reply is final. If round 3 still wants a tool, she says the phone line "That needed more steps than I take. Try it in two." A new ask cancels the run in flight. The same text asked again within 10 s joins the running stream.

B6 Checkpoints. After each settled step (a round's stream ends, a tool finishes), write TessRunState to Application Support/Tessera/tess-runs.json, excluded from backup, last 20 runs, nothing older than a day:
  struct TessRunState: Codable { id: UUID; startedAt: Date; round: Int; messages: [stored as the Brain message JSON]; doneToolIDs: [String]; status: running | finished | failed | dropped }
  The ask's live fragments are not stored, only what was sent as messages. On launch, a run still marked running:
  last step a finished tool -> resume at the next round with the stored messages; a tool in doneToolIDs never runs twice;
  otherwise -> mark dropped, store no half reply; she says nothing about it.
  A ghost row is already safe in the op log, so a kill never loses or repeats a pending change.

B7 Traces. Add runID: UUID? to TraceSpan. The Door's brain spans and TessRun's tool spans (kind .tool: tool name, totalMs, outcome) carry the run's id. No span holds ask text, tool arguments or results.

B8 Warm-ups. When the Tess layer opens, and on foreground if she was asked anything in the last 2 hours: warm() the rung the last ask used, with the B3 prefix (system[0], tools, system[1]). Never more than once per 4 minutes per model, never in Low Power, never with Tess asks Claude Off. Cost goes through the ledger like any call.

B9 Conversation. When the ask is sent, append(role: .user, text:, about:). On .finished, append(role: .tess, text: reply, about: what she named). On .failed, the phone line is shown and not stored. Spoken asks (TessSpeech final text) take the same path.

B10 Flag. .init("tessAsks", "Ask Tess anything", .everywhere, claude: true). Ships On. Off, or Tess asks Claude Off, means the ladder keeps only .appleOnDevice with no tools. When that is unavailable too, she says "I can't think that through right now. The rest still works." Nothing is sent.

B11 Accept (swift test with HarnessFakes):
  words stream in order and .finished equals the joined words;
  pickRung sends "how am I doing on legs?" to Sonnet and "how many sets today" to Haiku;
  two parallel reads return in one tool_result message; two writes run in order and each yields a .ghost pending row;
  a fourth round is never sent and the phone line comes back;
  a kill after a finished tool resumes without running it again; a kill mid-stream drops the run and stores no Tess turn;
  every span of a run carries its runID, and no span contains the ask text;
  a new ask cancels the old run, and the same ask within 10 s makes one Door call;
  with Claude Off, nothing reaches a ClaudeBrain;
  a money object's fragment reaches the request under lab and not under strict, with a sent-log row under lab;
  a key-shaped ask makes no Door call;
  the warm-up runs at most once per 4 minutes.
  App side (Builder A, with 215's layer): the layer shows .waiting, reveals .words word by word, marks .ghost rows, and Undo removes them. scripts/test.sh All green.

NOT IN H3: the Desk and room agents (H4), typed nets, the Mac edge, Belief memory (the memory spec comes separately), and moving the old Claude callers onto the Door.
