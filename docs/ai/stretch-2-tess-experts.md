# Stretch 2: Tess experts, the chief of staff (huddle batch 9)

For: Product, then Core (expert jobs, router, gate) and Builder B (the Review rows and the sources line). From: AI architecture. Docs only: no Claude calls, no key use, nothing built. Source: Kaushik, Oct 16, 11:27 AM PT (`parked.md`, "Tess as chief of staff"), lifted for design by Product on Oct 19; no spend until he asks in the running thread. Tags as in `stretch-1-tess-reads-the-screen.md`: **[code]**, **[docs]**, **[unbuilt]**, **[proposed]**, **[unverified]**. Prices from `model-effort-cost-table.md`: Haiku 5.5 100 n$ in / 500 n$ out per token; Sonnet 5.5 2,000 / 10,000.

## 0. The one-paragraph answer

An **expert** is a bounded `TessJob` with its own pack, one strict output tool, and a validator, for one area (Training, Kitchen, Day). It returns **facts**, never screen changes and never prose to show. **One router on the phone** (the Chief) merges the facts with the rules' own facts, and decides what shows, using the Home slots and the existing line checks. Experts write nothing, read only the memory slice their area needs, and can all be off without changing what Home says. My honest read: Claude's measured value on Home is small (`home-lines-eval-results.md`: voice 3/13 failed, "the only added fact is the day gap, which rules can say free"), so experts ship in **shadow mode first**: they run, the Chief compares, and nothing shows until a replay on real history says they add something rules cannot. Typical month **$0.05**; capped worst **$0.08** at 12 a day (0.2% of $50), $0.27 if the cap were 40 (0.5%).

## 1. The shape (how the project's own hierarchy maps)

| Project | Tess |
|---|---|
| Coordinator | `TessChief`: on the phone, deterministic (a ranker and the existing `TessLineCheck`s), no Claude of its own in v1 |
| Leads | Expert jobs: `expertTraining`, `expertKitchen`, `expertDay` [unbuilt] (Money, Reading, People, Upkeep join when those areas ship) |
| Board | The area's pack: the same `HomeFact` / `WeekFacts` / `DayStory` fields the phone already computes [code] |
| Report | `reportFacts`, a list of typed facts the Chief can verify against the pack |

Mapping to what exists: `TessJob` is already "one bounded ask with its own model, tool, budget and outcome", `ClaudeClient` the only door, so experts inherit the walls (`parked.md`, "How today's pieces leave room for it"; `claude-client.md`).

## 2. An expert job

```swift
// new [unbuilt]. Static like every TessJob.
TessJob(name: "expertTraining", model: "claude-haiku-5-5", maxTokens: 400, effort: nil, timeout: 8,
        instructions: TessVoice.house + ExpertRules.training, output: ExpertTools.reportFacts,
        writeTools: [], memory: [.told, .noticed], priority: .lines, toolChoice: .forced)
```

**Pack (`ExpertPack.build(area:)`, handles `x1`..):** the area's items and counts exactly as `HomeLinesPack` already allows (titles, states, counts, days-since, bests by short name). Training adds the week's plan vs done; Kitchen the cooked and planned meals by title and the shop state; Day the tasks due/done counts and the free blocks. **Never** weights, reps, volume, notes, places, health, money, people, private items, or another area's pack. Memory slice: told and noticed lines of **this area only**, up to 10, never About you, People or a private line; none writes (AI-0).

**Output tool `reportFacts` (strict):** `{ "facts": [ { "handle": "x1", "kind": enum, "n": integer|null, "state": enum|null } ] }` with `kind` from a closed list per area, for example Training: `gap_days`, `skipped_planned`, `best_near`, `volume_up_week`, `rest_due`; Kitchen: `plan_unshopped`, `repeat_soon`, `pantry_low`; Day: `tight_day`, `free_block`, `overdue_pile`. No free text field. This is how "facts come back" stays checkable.

**Validator (`ExpertFactValidator`, pure):** handle in the pack; `kind` in the area's list; `n` equals the number the pack licensed for that handle (the `HomeFact` licensing the home-lines checks already use, `line-check-vectors.md`); at most 6 facts; duplicate (handle, kind) dropped. Any failed fact is dropped; a reply with none valid is `.noLine`.

## 3. The Chief (one router decides what shows)

1. Collect rule facts (computed on the phone, always) and expert facts (when on and fresh).
2. Keep an expert fact only if the rules do **not** already state it (dedupe on (handle, kind)) and it fits an open Home slot.
3. Rank by the existing Home slot rules; one winner per slot; the winning fact is worded by the **rules line** for that kind (no Claude prose). Optionally, Home lines (stretch 4) may reword it, under its own switch.
4. Source line: "From your training this week" (area, not "Claude"), plus the cloud mark when an expert contributed, per the Sent log convention.

"Tess's line and Home never disagree" holds because facts are typed numbers the rules can also print, and the Chief shows one thing per slot.

**Shadow mode (default for 14 days after the build, then Product's call):** experts run and are logged to the phone-local Sent log, the Chief computes what it would have shown and records "same as rules / better / worse" as a count (no text), and shows nothing. The replay on the seeded 5-year demo history (`-resetDemo`, `scripts/test.sh --scale`) is the first measurement and costs nothing.

## 4. Triggers and caps

| Trigger | Calls |
|---|---|
| 04:00 turnover, once per area that changed since last run (hash of its pack) | up to 3 |
| A finish (workout, cook, shop) | 1 for the area, debounced 10 min |
| He opens Review on a week with a new pack hash | 1 per area |

Daily cap **12 expert calls** [proposed, in code], per-area cap 6; the $40 step-aside applies (experts are decoration, like Home lines); offline or busy keeps the rules facts and drops the expert call silently.

## 5. Budget against the $50 cap

Per call Haiku, 1,500 in / 150 out (A) = 150,000 + 75,000 = 225,000 n$ = **$0.000225**.

- Typical: 8 calls a day x 30 x $0.000225 = **$0.054 a month** (0.1%).
- Capped worst: 12 a day = **$0.081**, plus the cost of the other batches; a cap of 40 a day would be **$0.27** (0.5%).
- **Runaway with no cap in code:** one pack-changing tick per minute across 3 areas for 16 h = 2,880 calls = $0.65 a day = **$19.4 a month** (39% of $50); the daily cap is what stops that, and it is part of the job.
- If an expert is moved to Sonnet 5.5 low for quality (decision for after the shadow replay): 1,500 in / 150 out = 3,000,000 + 1,500,000 = $0.0045 a call; 8 a day = **$1.08 a month**, capped 12 a day **$1.62**.

## 6. Review switch (off by default)

Name: **Tess experts** (under the Review group "Tess asks Claude"). Off = today's behavior (rules only). On shows three sub-rows, one per area (Training, Kitchen, Day), each default On once the master row is On, so he can turn one expert off. Before/after line: "Off: Home shows what the rules see. On: area experts add facts the rules miss, in the same one line per slot." Needs the master "Tess asks Claude" switch and a key; rows keep their values through master Off and Remove key.

## 7. Tests (none needs a key)

`expertPackHoldsOnlyItsAreaAndNoPrivateOrMoneyOrBodyValue`; `expertRejectsFactWhoseNumberThePackDidNotLicense`; `expertRejectsUnknownHandleOrKind`; `chiefDropsAnExpertFactTheRulesAlreadyState`; `chiefShowsOneWinnerPerSlot`; `homeAndTessLineNeverDisagree`; `expertsInShadowModeShowNothing`; `expertCallsStopAtTwelveADay`; `expertsStepAsideAtFortyDollars`; `masterOffOrRowOffMakesNoRequest`; `expertWritesNoMemory`.

## 8. Rulings I need

1. Ship in shadow mode first, 14 days, then decide? (my recommendation)
2. Haiku 5.5 forced for experts, Sonnet only if the shadow replay says wording quality needs it?
3. Areas for v1: Training, Kitchen, Day only?
