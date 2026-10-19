# Stretch 1: Tess reads the screen (huddle batch 9)

For: Product, then Core (director, pack, gate), Motion lab (rules and the replay reel) and Builder A (router wiring). From: AI architecture. Docs only: no Claude calls, no key use, no key content, nothing built. Read against master at the time of writing. Source: Kaushik, Oct 16, 8:53 AM PT (`parked.md`, `design/motion/tess-aware-motion-notes.md`), lifted for research and design by Product on Oct 19 (no spend until he asks in the running thread). **[code]** = read in Swift; **[docs]** = from a docs page; **[unbuilt]**; **[proposed]** = my call; **[unverified]** = needs a measurement nobody has run. Prices: Haiku 5.5 100 n$ in / 500 n$ out per token; Sonnet 5.5 2,000 / 10,000 (`model-effort-cost-table.md`).

## 0. The one-paragraph answer

Tess picks her next roam, glance or rest from a **text description of the screen and his last touch**, never pixels and never his words. She still moves only through the states the router already has (`SoulEvent` to `SoulRouter.handle`, `Features/Tess/SoulRouter.swift` [code]); a chooser only picks **which allowed move and which place**. Three tiers, cheapest first, each falling back to the one below: **tier 0** rules plus smooth noise (motion idea 11, no model, ships regardless); **tier 1** the on-phone Apple model picking from an enum; **tier 2** Claude Haiku 5.5, only for choices that can wait a second. My recommendation: build tier 0 and the director interface now, tier 1 behind the switch, tier 2 last and only if a measured latency says it can steer anything. Typical month for tier 2: **$0.19**; capped worst: **$0.84** (1.7% of $50).

## 1. What "reads the screen" means (the pack)

A `ScreenPack` is built on the phone by the page's existing free-ground preference (`rowChanged(rect)`, `tess-motion.md` section 14) [docs]. It holds **kinds, places and counts, never titles**:

| Part | Content | Never |
|---|---|---|
| Page | Page id word (`today`, `training`, `exercise`, `groceries`, `cook`, ...) and whether it is live (`workout`, `cook`) | Object ids, names |
| Free ground | Named regions the page declares (`top-right`, `below-hero`, ...) as cells of a 6 by 10 grid | Pixels, screenshots, images (Kaushik: never images) |
| Rows | Handles `r1`..`r8`, each a **kind word** (`task`, `set`, `ingredient`, `habit`, `line`), a state word (`open`, `done`, `running`), and its grid cell | Row text, titles, numbers, weights, any value |
| Event | The router event that woke the chooser (`rowChanged`, `scrolled`, `appeared`, `idle5s`) | Free text |
| Touch | Last touch kind (`tap`, `swipe`, `hold`, `none`), seconds since, where (cell) | Touch coordinates beyond a cell |
| Tess | Her current mode and place; time-of-day bucket (`morning`, `day`, `evening`, `night`) | Clock digits |

This is stricter than a Home pack (no titles at all), so there is nothing for the money, body and secret walls to trip on. The pack still goes through `ClaudeClient` like every job, so the switch, the cap and the key checks apply [docs `claude-client.md`]. **A private surface sends nothing:** a masked page (Private exercise, a private workout) builds an empty pack and the chooser answers from tier 0 only [proposed; same rule as `ObjectPrivacy`].

## 2. The director interface (tiers share it)

```swift
// new [unbuilt]. Pure, Sendable, in the app target (the router lives in Features/Tess).
protocol SoulDirector: Sendable {
    func choose(_ pack: ScreenPack, deadline: Duration) async -> SoulChoice?   // nil = "no opinion"
}
struct SoulChoice: Equatable {
    enum Action { case stay, roam, glance, nudge, rest }
    var action: Action
    var target: String?          // a row handle r1..r8 or a region name from the pack; nil for stay and rest
    var dwellMs: Int             // 400...4000
}
```

The router asks the director on a `rowChanged`, a long idle, or a page appear. A reply that arrives after the **300 ms** budget is dropped and the rules decide (`tess-aware-motion-notes.md`: "a late one is dropped and the rule decides"). A reply that is earlier than its beat is held until the beat. `SoulChoice` is then turned into the **same events the router already handles**, so every motion safety rule in `tess-motion.md` section 14 holds by construction: never over words, never while listening, asked or carried, never in Low Power, one haptic per moment, Done never changes.

**Validator (`SoulChoiceValidator`, pure, runs on every choice from every tier)** [proposed]:

| Check | Rule |
|---|---|
| Action | Member of the five |
| Target | Exists in this pack; a row target must have a free-ground rect; roam target not under text (the page's declared ground) |
| Dwell | 400 to 4000 ms; roam arcs keep the 760 ms travel |
| State | Refuses `roam`/`nudge` while `listening`, `asked`, `carried`, Low Power or Reduce Motion; allows `stay`/`rest` only |
| Rate | At most one roam per 6 s and 12 an hour; two refusals in a row mean tier 0 for 60 s |
| Shape | Output decodes strictly (below); anything else is `nil` |

## 3. Tier 0, no model (ships first, free)

Drive the lights from the page itself: go to the words that just changed, wander on smooth noise seeded by page and minute instead of a fixed loop (idea 11, `tess-picks.md`). This is Motion lab's, not a Claude job. The tier-1 and tier-2 choosers must beat it on the replay reel (section 7) or they stay off.

## 4. Tier 1, on the phone (the model is Apple's)

`LanguageModelSession` with guided generation into `SoulChoice` (an enum plus a target string checked against the pack) [proposed; the same Foundation Models stack as `TessModelCapture.swift` [code]]. The prompt is the pack and a 400-token instruction block. No network, no cost, nothing leaves the phone. **[unverified]:** latency per choice on an iPhone 17 and whether it fits 300 ms; the replay harness measures it and the switch stays off if the median misses 300 ms. If the model is unavailable, the row reads "Not on this phone" and tier 0 runs.

## 5. Tier 2, Claude (opt-in on top)

| Item | Value |
|---|---|
| Job | `TessUse.motion` [unbuilt]; `TessJob(name: "motion", model: "claude-haiku-5-5", maxTokens: 96, effort: nil, timeout: 1.2, writeTools: [], memory: [], priority: .lines, toolChoice: .forced)` |
| Output tool | `chooseMotion` strict: `{ "action": enum[stay,roam,glance,nudge,rest], "target": string|null, "dwell_ms": integer }`. No `why` or text field: Claude returns no words |
| Pack | `ScreenPack` above, about 350 tokens, plus about 250 of static instructions and the tool (cached prefix). **1,200 in / 40 out** (A) |
| Cost per call | 1,200 x 100 + 40 x 500 = 140,000 n$ = **$0.00014** |
| Why Haiku, forced | Cheapest, and forced tool choice is the rule for Haiku (`claude-client.md` section 2) |
| When it is asked | **Ahead of need:** one call when a page appears or its rows change, returning a list of up to 3 choices good while the page's state hash is unchanged. Choices are consumed on beats; a changed hash discards the rest. Never on the critical path of a touch |
| Latency | Round trip is **[unverified]** (hundreds of ms to over a second). It cannot steer a 300 ms beat, so it only ever supplies the next choices; if the list is not back, tier 1 or 0 answers |
| Caps | 1 call per 20 s, at most **200 a day** [proposed, in code], 8 s idle timeout via the one door; follows the **$40 step-aside** with Home lines, week story and living colour (it is decoration) |
| Offline, busy, cap, bad key | Silent: tier 1 or 0 answers. No Tess line, no Sent noise beyond the normal log row |

**Budget against the $50 cap.** Typical: 40 page appears a day at one call each = 40 x $0.00014 x 30 = **$0.17**, plus changed-row refetches about **$0.19 a month** (0.4%). Capped worst: 200 a day = $0.028 a day = **$0.84**; with the 5 jobs of the other batches still under **$8** (16%). **Runaway with no cap in code:** one call per 2 s for 16 waking hours is 28,800 a day, $4.03 a day, **$121 a month**, so the $50 cap would be hit in about 12 days. That is why the 200-a-day cap is part of the job, not a note.

**Sent log.** Each call writes a Sent row like any job (use `motion`); the "what was sent" page shows the pack, which is kinds and cells only.

## 6. Review switch (off by default)

Name: **Tess reads the screen**. Under the Review group "Tess asks Claude" as a two-part row [proposed]:

- Off (default today's behavior = tier 0 only): "Tess moves by simple rules."
- On this phone: "She picks her moves from what is on the screen. Nothing leaves the phone." (tier 1; needs no key)
- Claude helps: "She also asks Claude, in kinds and places only, never your words or pictures." Needs the master "Tess asks Claude" switch and a key; falls back to on-phone otherwise. Row keeps its value through master Off and Remove key (same rule as `batch-3-4-claude-jobs.md` section 2).

With the master off or no key she moves exactly as with the row Off (`soul-signals.md` section 3: "the phone decides").

## 7. Tests and the free eval (no key, no live call)

| Test | Proves |
|---|---|
| `screenPackHoldsNoTitleNoValueNoImage` | Snapshot: only kind words, state words, cells |
| `privatePageBuildsEmptyPack` | A masked page sends nothing |
| `validatorRefusesRoamWhileListeningAskedCarriedOrLowPower` | The safety table |
| `lateChoiceIsDroppedAndTheRuleDecides` | The 300 ms budget |
| `staleChoiceListDiscardedWhenPageHashChanges` | Plan-ahead lists |
| `motionJobStopsAtTwoHundredCallsADay` and `motionJobStepsAsideAtFortyDollars` | Caps |
| `masterOffOrRowOffMakesNoRequest` | Gate |
| `tierFallsBackSilentlyWhenOfflineOrUnavailable` | Fallback |

**Replay reel (free, on the phone or the simulator):** Motion lab records 30 screen traces (page, rows, events, touches) as JSON; each tier is scored by the validator and by a short list of must-not rules (never under words, never toward a private row, never twice in 6 s). Only after tiers 0 and 1 are scored does anyone ask Kaushik whether to run tier 2 on the same traces (about 30 x $0.00014 = **$0.004**). The fine-tune or local-RL idea he named stays in `parked.md`: v1 only writes a phone-local log of (pack hash, choice, whether he touched within 3 s) so a later trainer has data; nothing trains.

## 8. Open questions for Product

1. Tier 2 is worth building only if the measured Claude latency can supply "next 3 choices" faster than the page changes. OK to build tiers 0 and 1 first and decide tier 2 after the replay reel?
2. Name the row **Tess reads the screen** and keep it under Review (default Off)?
3. The phone-local choice log: yes (no training) or none?
