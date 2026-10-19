# Stretch 1: Tess reads the screen (huddle batch 9)

For: Product, then Core (director, pack, gate), Motion lab (rules and the replay reel) and Builder A (router wiring). From: AI architecture. Docs only: no Claude calls, no key use, no key content, nothing built. Read against master at the time of writing. Source: Kaushik, Oct 16, 8:53 AM PT (`parked.md`, `design/motion/tess-aware-motion-notes.md`), lifted for research and design by Product on Oct 19 (no spend until he asks in the running thread). **[code]** = read in Swift; **[docs]** = from a docs page; **[unbuilt]**; **[proposed]** = my call; **[unverified]** = needs a measurement nobody has run. Prices: Haiku 5.5 100 n$ in / 500 n$ out per token; Sonnet 5.5 2,000 / 10,000 (`model-effort-cost-table.md`).

## 0. The one-paragraph answer

Tess picks her next roam, glance or rest from a **text description of the screen and his last touch**, never pixels and never his words. She still moves only through states the router already has (`SoulEvent` to `SoulRouter.handle`, `Features/Tess/SoulRouter.swift` [code]). The answer is **one id from a closed menu the phone sends** (the Motion lab's sheet, `design/motion/tess-reads-the-screen-motion.md`, PR #1101): no coordinates, no durations, no text. Three tiers, cheapest first, each falling back to the one below: **tier 0** rules plus smooth noise (motion idea 11, no model); **tier 1** the on-phone Apple model picking from the same menu; **tier 2** Claude Haiku 5.5. Product ruled (Oct 19): build tiers 0 and 1 first; whether tier 2 runs at all is decided after latency is measured. If tier 2 ships, the one number set is in section 5: **$0.078 typical, $0.29 capped worst a month** (0.6% of $50).

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

Superseded by the Motion lab's closed menu (agreed with the lab, Oct 19). One interface for all tiers:

```swift
// new [unbuilt]. Pure, Sendable, in the app target (the router lives in Features/Tess).
protocol SoulDirector: Sendable {
    func choose(_ menu: [MotionID], pack: ScreenPack, deadline: Duration) async -> MotionID?   // nil = no opinion
}
```

`MotionID` is the lab's menu (`asBuilt`, `readersJobOrder`, `readersSweep`, `constellationOnly`, `roamSlot1`..`roamSlot4`, `stayHome`, `peek`, `nudgeLean`, `nudgeEyes`, `sideGlance`, `dropGlance`, `none`). The phone sends only the subset that is **legal right now** (eyes setting, page, Reduce Motion, Low Power and precedence applied first), `asBuilt` is always in it, and Done and opacity, grade or halo are never on it. An id not in the menu that was sent is rejected and the as-built choice stands (the same rule as `proposeSoul`). Slots are the page's declared free ground; the model never sees their positions.

**Latency (the lab's rules; they are the contract):** the first frame always plays as built and never waits. At most one `screenRead` call is in flight; an event during the flight opens no call. An answer by 300 ms may steer the next beat of the moment running; at 300 to 1,200 ms it may change only the next moment of the same kind and only if the snapshot hash (page, state, slot list) still matches; later, or after a state change, it is dropped. The request is cancelled at 1,500 ms (outcome `late`). No retry and no queue. An answer is a router event at precedence 8 or lower, so it never cuts a mode above it.

**Validator (`MotionChoiceValidator`, pure, every tier):** id is in the sent menu; snapshot hash matches (for answers after 300 ms); not while listening, an ask waiting, carried, Done in flight, live workout or cook, Speak, Settings or quiet hours; minimum gap 2 s between calls. **No call in Low Power or Reduce Motion** (the lab: automatic calls skip in Low Power, and nothing travels under Reduce Motion), so the menu in those states is `asBuilt` only. Anything else decodes to `nil`.

## 3. Tier 0, no model (ships first, free)

Drive the lights from the page itself: go to the words that just changed, wander on smooth noise seeded by page and minute instead of a fixed loop (idea 11, `tess-picks.md`). This is Motion lab's, not a Claude job. The tier-1 and tier-2 choosers must beat it on the replay reel (section 7) or they stay off.

## 4. Tier 1, on the phone (the model is Apple's)

`LanguageModelSession` with guided generation into `MotionID` (the same closed menu, so the validator is shared) [proposed; the same Foundation Models stack as `TessModelCapture.swift` [code]]. The prompt is the pack and a 400-token instruction block. No network, no cost, nothing leaves the phone. **[unverified]:** latency per choice on an iPhone 17 and whether it fits 300 ms; the replay harness measures it and the switch stays off if the median misses 300 ms. If the model is unavailable, the row reads "Not on this phone" and tier 0 runs.

## 5. Tier 2, Claude (opt-in on top): the one number set

This replaces the earlier plan-ahead design (a list of 3 choices per page appear, 200 a day, one call per 20 s) and the lab's draft numbers (350 in / 8 out, 150 a day, $0.00004 a call). Core builds to **this table**.

| Item | Value |
|---|---|
| Job | `TessUse.screenRead` [unbuilt]; `TessJob(name: "screenRead", model: "claude-haiku-5-5", maxTokens: 16, effort: nil, timeout: 1.5, writeTools: [], memory: [], priority: .lines, toolChoice: .forced)` |
| Output tool | `proposeMotion` strict: `{ "id": enum[<menu ids>] }`, nothing else: no text, no coordinates, no duration |
| Pack | `ScreenPack` (section 1) about 250 tokens plus the sent menu, plus about 350 of static instructions and the tool. **600 in / 10 out** (A). The lab's 350 in was an estimate with no instruction block; the first live run is measured and this row is corrected from it |
| Cost per call | 600 x 100 + 10 x 500 = 65,000 n$ = **$0.000065** |
| When it is asked | Only on a router event that already fires as built (the lab's section 1 table). No event, no call. At most one in flight, **2 s minimum gap**, no retry, no queue |
| Caps | **150 calls a day** (in code), the lab's number, replacing my 200; the $40 step-aside applies (decoration, like living colour); none in Low Power or Reduce Motion |
| Offline, busy, refused, cap, bad key | Silent: tier 1 or 0 answers, no line on screen; a Sent row only when a request really left |

**Budget against the $50 cap.**
- Typical: about 40 calls a day (events that fire a call on a normal day) x 30 x $0.000065 = **$0.078 a month** (0.2%).
- Capped worst: 150 a day x 30 x $0.000065 = **$0.29 a month** (0.6%). At the lab's draft numbers it was $0.18; the difference is the instruction block.
- **Runaway with no cap in code:** one call every 2 s for 16 waking hours is 28,800 a day = $1.87 a day = **$56 a month**, over the cap in about 27 days. That is why 150 a day is part of the job. With the other stretch jobs and the base month (about $14 worst) the app stays under $15.

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
| `lowPowerAndReduceMotionSendNoScreenRead` and `validatorRefusesIdOutsideTheSentMenu` | The safety table and the closed menu |
| `lateChoiceIsDroppedAndTheRuleDecides` | The 300 ms budget |
| `answerAfterStateChangeIsDropped` and `onlyOneScreenReadInFlight` | Snapshot hash and the single flight |
| `screenReadStopsAtOneHundredFiftyCallsADay` and `motionJobStepsAsideAtFortyDollars` | Caps |
| `masterOffOrRowOffMakesNoRequest` | Gate |
| `tierFallsBackSilentlyWhenOfflineOrUnavailable` | Fallback |

**Replay reel (free, on the phone or the simulator):** Motion lab records 30 screen traces (page, rows, events, touches) as JSON; each tier is scored by the validator and by a short list of must-not rules (never under words, never toward a private row, never twice in 6 s). Only after tiers 0 and 1 are scored does anyone ask Kaushik whether to run tier 2 on the same traces (about 30 x $0.000065 = **$0.002**). The fine-tune or local-RL idea he named stays in `parked.md`: v1 only writes a phone-local log of (pack hash, choice, whether he touched within 3 s) so a later trainer has data; nothing trains.

## 8. Open questions for Product

Ruled Oct 19: tiers 0 and 1 first; tier 2 decided after latency is measured; the phone-local choice log is yes (never in backups, no private words). Still open, for the lab's Asks: (1) the row goes in the Review section under "Tess asks Claude", not on sheet 93 page 1 (the 6-row limit is full: Key, This month, Receipts); (2) the earlier doc lines "Claude is never asked how she should move" (`soul-signals.md`) and "Nothing here adds a model call" (`tess-picks.md`) are amended by this batch 9 go, with the switch-off half unchanged (with the switch off she reacts exactly the same); (3) cap line: `screenRead` stays silent at the cap, like Home lines.
