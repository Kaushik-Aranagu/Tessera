HARNESS BUILD TEXT, H0 to H2 (Oct 23, for Core; relay word for word)

Goal: Tess's agent harness, first three slices. Kaushik's rules for it: everything ships ON, experiments included; lab policy is on (Claude may see health, body, calendar, calories and money in calls from his phone; never the key); smallest model that fits each job, no Opus. Branch from master. TessDirector from #1350 is the seam for H2.

ORDER
H1a ClaudeBrain + RunTrace -> H0 bench (uses ClaudeBrain) -> H1b Door, router, policy -> H2 Director playbook. One PR per step is fine; H0 may ride in H1a's PR.

H1a  BRAIN SEAM (TesseraCore/Sources/TesseraTess/Harness/)
Brain.swift:
  public enum BrainID: String, Sendable { case rules, typedNet, appleOnDevice, mlx, mac, haiku, sonnet }
  public struct BrainRequest: Sendable { system: [TextBlock]; messages: [Message]; tools: [ToolSpec]; toolChoice: ToolChoice (auto | any | tool(name) | none); maxTokens: Int; effort: Effort? (low | medium | high); cacheAfter: [Int] (block indexes that get a cache breakpoint); deadline: Duration }
  public enum BrainEvent: Sendable { case text(String); case toolUse(id: String, name: String, input: Data); case done(BrainUsage, stop: String); case failed(ClaudeOutcome) }
  public struct BrainUsage: Sendable { inTokens, outTokens, cacheReadTokens, cacheWriteTokens: Int; costNano: Int64 }
  public protocol Brain: Sendable { var id: BrainID { get }; var isAvailable: Bool { get async }; func stream(_ r: BrainRequest) -> AsyncThrowingStream<BrainEvent, Error>; func warm(_ prefix: BrainRequest) async }
ClaudeBrain.swift: raw Messages API, stream: true (SSE), one long-lived URLSession per app run (pre-connected on foreground). Models: "claude-haiku-5-5", "claude-sonnet-5-5" only. No temperature or top_p. Tool use: start the local tool as soon as its content block closes. warm(): same system + tools prefix, max_tokens 0, same effort, breakpoint on the last shared block; if the API refuses max_tokens 0, use 1 and note it in the PR. Key: read from SystemKeychain inside ClaudeBrain into a local used only for the x-api-key header. Never log, print, trace or store a request, a header or any part of the key. Refuse every redirect with a URLSessionTaskDelegate that completes with nil (fixes secret checklist item 7).
AppleBrain.swift: adapter over Foundation Models LanguageModelSession (the on-device model), same BrainEvent stream; tools via its Tool protocol. Verify the iOS 27 API with DocumentationSearch; do not guess.
RunTrace.swift: one span per brain call and per tool call: brain, model, ttftMs, totalMs, tokens (in, out, cache read, cache write), costNano, outcome. Stored on the phone in Application Support (harness-trace.json, last 2,000 spans), never in a backup, never sent.

H0  LATENCY BENCH (Developer mode row "Run latency bench", on his phone)
Five repeats each, report p50 and p95 time to first token and total:
  1 Haiku 5.5 cold (new session) and warm (reused connection), 300-token prompt, 50 out
  2 Same with a cached 3,000-token prefix after warm()
  3 Sonnet 5.5 effort low, same four cases
  4 Apple on-device model, 300-token prompt, 50 out
  5 Optional, skipped when not set up: Mac server round trip on Wi-Fi
Writes a plain table into the trace file and shows it in Developer mode. Spend goes through TessUsageLedger (well under $0.10 a run).
Accept: runs on the phone; table appears; ledger rows match; a grep of the trace file finds no header, request body or key text.

H1b  DOOR, ROUTER, POLICY
Door.swift: actor Door. run(_ job: DoorJob) -> AsyncThrowingStream<BrainEvent, Error>. Steps in order: policy -> pack -> key-shape scan (always, both policies; reuse looksLikeClaudeKey) -> TessUsageLedger.reserve -> route -> stream -> check (job's validator) -> settle -> trace -> sent log.
  public struct DoorJob: Sendable { name: String; ladder: [BrainID]; request: BrainRequest; fragments: [PackFragment]; estimateNano: Int64; hedge: Bool; validator: @Sendable (Data) -> Bool }
  public struct PackFragment: Sendable { text: String; taint: Taint (claudeSafe | deviceOnly) }
DoorPolicy.swift: enum DoorPolicy { case lab, strict }. Lab = all fragments may go to Claude, and every sent pack is recorded in the What was sent log. Strict = deviceOnly fragments go only to phone or Mac brains (today's walls). Read from a new flag: .init("tessLabPolicy", "Lab mode for Claude", .everywhere, claude: true). On = lab. Ships On.
BrainRouter.swift: walk the job's ladder, skip brains that are not available, Claude off, or over the cap. Hedge: when hedge is true and the first rung is Sonnet with no first token after 1.5 s, start Haiku with the same request, take whichever streams first, cancel the other, settle both reservations.
Model defaults: classify, route, Director, room work = Haiku 5.5. Tess turns = Sonnet 5.5 effort low. No Opus.
Existing callers (ClaudeTessModel, PlanWording, RecipeLinkReader, ClaudeKeyCheck) are not moved in this slice.
Accept (swift test with a FakeBrain): router skips a downed rung; hedge returns the first streamer and settles both; reserve happens before send and settle after; the $50 cap refuses before any network; a key-shaped string in any fragment is refused under both policies; strict drops deviceOnly fragments from a Claude request and lab keeps them and writes a sent-log row; a redirect is refused; no trace span holds text from the request. App build green, scripts/test.sh All green.

H2  DIRECTOR PLAYBOOK (needs #1350)
PlaybookDirector.swift (TesseraCore/Sources/TesseraCore/Director/): struct PlaybookDirector: TessDirector. Reads today's DirectorPlaybook; any ask with no entry falls through to RuleDirector().decide. TessDirection.decide stays the only entry point, so scene asks still go to the rules and the clamps still run after every choice.
  struct DirectorPlaybook: Codable, Sendable { day: String; tessPalette: [String: Entry] (key = sorted page accent ids); burst: [BurstKind: Entry] (shape, count, seconds); reaction: [AwayBucket: Entry] (under 1 h, 1 to 8 h, over 8 h, first open after 4 am); each Entry carries the choice and a one-line why for the Explain screen }
  Stored as Application Support/Tessera/director-playbook.json, keyed by day, not in a backup.
PlaybookJob.swift (TesseraTess): fills the playbook through the Door. Haiku 5.5, effort low, one strict tool setPlaybook whose schema uses the enums from TessDirector.swift (BurstShape, OpenReactionKind, PaletteCurve). Input: part of day, weekday, quiet, reduceMotion, the app accents, the last 10 recent keys. Runs at the first open after 4 am and at most 3 times a day. About $0.0002 a call. Every entry is clamped when stored and again when read; a bad entry is dropped alone.
Flag: .init("tessDirectorPlaybook", "Tess picks her looks", .everywhere, claude: true). Ships On.
Accept: with no playbook, every existing TessDirectorTests case gives the same choice as RuleDirector; with an entry, the choice and its why come from the playbook; an out-of-range entry (count 99, 9 s) comes back clamped to TessDirection's maxima; Claude off, offline, over the cap or flag Off -> rules; the fill call shows in the trace and the sent log.

NOT IN THESE SLICES: Desk and room agents (H4), typed nets, Mac edge, memory changes (a separate memory spec follows).
