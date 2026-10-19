# Stretch 4: Home lines and the week story, with the phone-only memory profile (huddle batch 9)

For: Product, then Core (jobs, profile builder, gate) and Builder B (the Review rows and the sources line). From: AI architecture. Docs only: no Claude calls, no key use, nothing built or run. This page sits on `home-lines-job.md` (AI-4), `week-story-job.md` (AI-11), `memory-store.md` (AI-7, AI-8), `memory-experiment-results.md` (AI-0), `home-lines-eval-results.md`, `architecture.md` and `model-effort-cost-table.md`. Tags: **[code]**, **[docs]**, **[unbuilt]**, **[proposed]**, **[unverified]**. Prices: Sonnet 5.5 2,000 n$ in / 10,000 n$ out per token.

## 0. The one-paragraph answer

Claude may word Home's lines (every slot, not only the finished-workout pair) and the week's story, **reading** one compact **profile** of what Tess knows, and **never writing it**. The profile is built on the phone, from his told lines, the noticed patterns the phone counted and the last 7 recent lines, with private, People, About-you and forgotten lines left out. Both jobs are off by default behind **Home lines** (week story is a sub-row). Typical month **$2.76 to $3.30**, capped worst **$5.82 to $6.90** (12% to 14% of $50). I keep the earlier honest finding on the front: the last Home-lines eval said Claude adds little over the rules, so this ships in **shadow mode** first and only shows wording that passes the line checks and a replay (section 7).

## 1. What is built and what is not

| Piece | State |
|---|---|
| `TessUse.lines`: Home's done job (a finished workout's two slots) | Built [code `TessModel.swift:19`] |
| `TessMemory` store, `recomputeNoticed`, recent lines at the 04:00 turnover | Built [code `Tess/TessMemory.swift`, `TessMemory+Turnover.swift`] |
| "remember that ..." grammar phrase and the `remember` tool (AI-8) | Unbuilt [docs `memory-store.md` section 2] |
| `HomeLinesPack` for all slots, the shared `<memory>` builder (shape A) | Unbuilt [docs `home-lines-job.md` section 2] |
| `WeekPack` with handles `w1`.. | Unbuilt [docs `week-story-job.md` 1.1]; `WeekFactsBuilder.facts` exists [docs] |
| Eval verdict on Home | Sonnet, 0 hard fails, but voice failed 3 of 13, memory p95 8.1 s failed; "recommendation: Claude Home off" [docs `model-effort-cost-table.md`, `home-lines-eval-results.md`] |

## 2. The profile (written on the phone only)

`MemoryProfile.build(for: job, area:, now:)` [unbuilt] is **pure and deterministic** and returns the `<memory>` block the packs already specify (shape A, `memory-store.md` section 4):

| Part | Rule |
|---|---|
| Told | Lines he said (area matches the item by title or exercise word); non-private; most recently used first |
| Noticed | Up to 10, Training and Kitchen only, counted on the phone at the Sunday 04:00 turnover; no clock digits (AI-0) |
| Recent | The last 7 `recent` lines (`DayStory` counts and titles, 14-day life) |
| Never | About you, People, any `isPrivate` line, `forgotten` hashes, money, places, body or health values, and any line a wall trips on (`TessMemoryScreen.refusal` is also run on read) |
| Size | At most 18 lines of 80 characters, about 450 tokens; a profile hash (of the included line ids and texts) is the cache key and the "stale" test |

**Claude writes nothing into it.** 31 of 72 self-written notes failed the checks (AI-0), so the only paths in stay: the phone's own counting, his words, and a `remember` ghost he KEEPs. The profile is never stored as a separate object (it is rebuilt from `TessMemory`, so forgetting a line removes it from the next profile at once, with no second copy to clean). The Memory page's source lines and the "What was sent" page show exactly which profile lines left.

This is also the path a **told fact can reach Claude**. Product ruled on Oct 19 that memory in what Tess sends follows the **Home lines switch** and its walls, with no extra row; so the profile goes out only when Home lines is On.

## 3. The two jobs

**homeLines, all slots** (extends the built done job): `TessJob(name: "homeLines", model: "claude-sonnet-5-5", maxTokens: 512, effort: "low", timeout: 6, output: proposeLines, writeTools: [], memory: [.told, .noticed, .recent], priority: .lines, toolChoice: .auto)`. Pack: `<memory>` profile, then `<facts>` per non-fixed item: handle, kind, title, state, hero, day label, rules context and detail, licensed numbers, times as clock words (`home-lines-job.md` section 2). **Ticking values never enter the pack.** Each line is checked by `TessLineCheck` (C1 to C14, `line-check-vectors.md`): handle known, numbers licensed, no fact outside the pack, house voice. A failed line keeps the **rules line** for its slot. `.noLine` is not an error.

**weekStory** (AI-11): `TessJob(name: "weekStory", model: "claude-sonnet-5-5", maxTokens: 400, effort: "low", timeout: 20, memory: [.told, .noticed, .recent], priority: .lines, toolChoice: .auto)`. Pack from `WeekFacts` only (titles, counts, states, weekday words, bests by short name), never `bestLines`, weights, reps, minutes, body weight, money, notes, health, task titles. About 2,000 in / 300 out.

Both run through `ClaudeClient` (switch, key, walls, cap, one door), and each writes a Sent row.

## 4. Triggers and caps (the ones that are docs-only today become code)

| Job | Trigger | Caps [proposed, in code] |
|---|---|---|
| homeLines | A pack **value** change (not a ticking one) with a 10-minute debounce; a finish | **40 a day** (currently doc only), 1 in flight, debounce 10 min |
| weekStory | Sunday 04:00 turnover, once a week, plus on first open of a new week | 2 a day, 8 a month |

Both step aside at the **$40** line (`job-trigger-table.md`); capture, plan, recipe and questions keep running to $50. Offline or busy: rules lines stay, nothing is retried in a loop; the offline retry table decides the one retry.

## 5. Budget against the $50 cap

Numbers from the cost table (Sonnet 5.5 low): Home done line $0.0020 typical / $0.0075 worst a call; the all-slot Home job is $0.0045 a call at 20 a day (**$2.70 a month**, the architecture figure); week story $0.0070 a call.

| Case | Home lines | Week story | Together | Share of $50 |
|---|---|---|---|---|
| Typical: Home 20 a day, week story 8 a month | $2.70 | $0.06 | **$2.76** | 5.5% |
| Typical if the profile block (about 450 tokens in = $0.0009 a call, 600 calls a month = $0.54) is not already inside the $0.0045 | $3.24 | $0.06 | **$3.30** | 6.6% (close to the "$3.23 heavy case" in memory) |
| Capped worst: Home 40 a day (1,200 calls x $0.0045), week story 2 a day (60 x $0.0070) | $5.40 | $0.42 | **$5.82** | 11.6% |
| Capped worst with the profile added (Home +$1.08 at 1,200 x $0.0009) | $6.48 | $0.42 | **$6.90** | 13.8% |
| **Runaway with no cap** (a ticking value, 1,440 calls a day) | $6.48 a day | | **$40 in 6.2 days; $50 in 7.7 days** | why the 40-a-day cap and the debounce are part of the job |

The five jobs in `batch-3-4-claude-jobs.md` ($0.40 typical, $2.35 worst) and the other stretch jobs add under $2; the whole app stays near **$14** worst (about 28% of the cap): $7.05 base, Home lines raised from $0.68 to $6.48, week story at $0.42, plus about $1 of stretch jobs.

## 6. Review switches (off by default)

- **Home lines**: Off (default; today's behavior): "Home uses the words the rules write." On: "Claude words your Home lines from what is on screen and what Tess has learned. Private items and money stay out." Needs the master "Tess asks Claude" switch and a key.
- Sub-row **Week story**: Off/On the same way; default **Off** even when Home lines is On, so each cost is a separate flip [proposed].
- A line under the rows: "Tess has learned 12 things. See what Claude can read." opens the Memory page filtered to what the profile would include (the same builder, so the page cannot disagree with the call).

Rows keep their values through master Off and Remove key.

## 7. The gate before it shows anything (shadow first)

Shadow mode for 14 days after build [proposed]: the jobs run, the line checks run, the Sent rows are written, and **nothing is shown**; the phone records only counts of "passed all checks", "failed check C#" and "same as rules". Show-live needs three things: zero hard fails on the saved eval set, voice at or above the rubric on a **re-run** (the earlier 3 of 13 failed), and Product's yes. The live eval waits for Kaushik's own ask in the running thread; until then only the free parts run (packer snapshot, line-check vectors, offline replay on the seeded history).

## 8. Tests (none needs a key)

`profileExcludesPrivateAboutPeopleAndForgottenLines`; `profileNeverHoldsMoneyPlacesOrBodyValues`; `forgettingALineRemovesItFromTheNextProfile`; `profileHashChangesWhenALineChanges`; `profileIsCappedAtEighteenLines`; `claudeNeverWritesMemory`; `homePackHoldsNoTickingValueNoFixedItemNoPrivateItem`; `weekPackHoldsNoBestLinesWeightsOrTaskTitles`; `failedCheckKeepsTheRulesLine`; `homeLinesStopAtFortyADay`; `homeAndWeekStepAsideAtFortyDollars`; `homeOffMeansNoMemoryLeavesThePhone`; `weekStoryRowOffMakesNoRequest`; `shadowModeShowsNothingAndWritesCountsOnly`.

## 9. Rulings I need

1. Shadow mode for 14 days, then show-live only on a passing re-run and Product's yes?
2. Week story default Off even when Home lines is On?
3. Keep the Home model at Sonnet 5.5 low, with a Haiku forced-tool re-run (untested) only if Kaushik asks for an eval?
