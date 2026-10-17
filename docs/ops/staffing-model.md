# Staffing model: senior, middle and junior engineers per team

Proposal, Oct 17. Source numbers: `ops/usage-governor.md` (price sheet, cost per task, plan units, thresholds) and the team boards. Labels: **[M]** measured, **[I]** inferred. Kaushik's ask: run each team like a company team, with senior and junior engineers priced differently; each team gets a budget, its lead staffs every job with the best-value engineer, and no team ever runs out of work, around the clock. CPU-only work runs while models wait.

## 1. Tiers

- **Senior**: Opus 5.5 high. Architecture, privacy and walls review, fix-first root causes, design direction, any call that is hard to undo. **Fable 5.1 high** only after Opus high failed twice on the same call, with the coordinator's OK, paid from the reserve, and under 5% of weekly dollars (about $425/week [I]).
- **Middle**: Sonnet 5.5 medium. Feature code PRs, QA review passes, acceptance against a spec, research write-ups. Walls and privacy work never runs below Opus medium (governor rule 3).
- **Junior**: Sonnet low or Haiku 5.5. Docs and sheet PRs, merge workers, memory edits, scans, digests, installs and walks, board upkeep, relays.

**10-second rule for a lead:**
1. Can a wrong answer ship a privacy leak, break the data model, or set direction? Senior.
2. Does it need judgment, but against a written spec or plan? Middle.
3. Is it mechanical, bounded, and checkable by a script or a diff? Junior (Haiku if it is under 25 turns).
4. Pattern for large work: the senior writes the plan and the acceptance list, middles and juniors build it, the senior reviews only the risky diff.
5. **Escalate** one tier when a job fails twice for lack of capability (not lost context; for lost context, restart fresh on the same tier).
6. **Demote** one tier when the hard decision is made and the rest is execution, when the meter is orange, or when a job estimate is over 5% of the 5-hour window while the system is yellow.
7. Restart any worker over 250k tokens of context at its next milestone (re-reading context is about half of the bill [M]).

## 2. Budgets

Project share from the Sun Oct 18 5 AM PT reset: 90% of the weekly limit, about $7.2k to $9.9k list, midpoint $8.5k [I]; of each 5-hour window, about $450 of $500 [I]. One split applies to both limits. The weekly figure is the average pace; the 5-hour figure caps a burst inside one window. If every team spent its full 5-hour share in every window, the week would run out about 1.7 times over [I], so the weekly pace line governs the average.

| Team | Share % | $/week [I] | $/5h window [I] | Why |
|---|---|---|---|---|
| Core (Mac) | 16 | 1,360 | 72 | Blocks the pin (MU2, A2, paste wall); Mac spend unmeasured |
| Builder A (Mac) | 13 | 1,105 | 59 | 12 items in Next; Mac code PRs cost $12 to $30 each [I] |
| Builder B (Mac) | 13 | 1,105 | 59 | 14 items in Next; owns Tess and Settings: Claude |
| QA | 10 | 850 | 45 | $205 in 42 h [M]; review volume rises with three builders |
| Design | 9 | 765 | 41 | $343 [M]; ahead of builders, so recordings and passes only |
| Coordinator | 7 | 595 | 32 | $719 [M], largest; should be broad, mostly middle, junior merge workers |
| Research | 5 | 425 | 23 | $662 [M], but Next is empty and it waits for Mon Oct 19 |
| Product | 5 | 425 | 23 | $131 [M]; refills every board, gap discovery |
| Motion lab | 4 | 340 | 18 | $72 [M]; 20 items in Next, mostly cheap |
| Kitchen | 4 | 340 | 18 | $92 [M]; acceptances as slices land |
| AI arch | 3 | 255 | 14 | $89 [M]; docs-only reviews |
| Ops | 3 | 255 | 14 | New; mostly junior scripts and scans |
| Reserve | 8 | 680 | 36 | Coordinator releases it; Fable and red-zone work come from here |
| **Total** | **100** | **8,500** | **450** | |

Measured cloud spend was $2,312 over about 42 h, Oct 14 11:30 PM to Oct 16 5:22 PM PT [M]. The Mac leads' spend is not visible yet, so their shares are inferred from board load. Refit the split from the Ops ledger every Sunday.

**Rules:**
- **Pace line per team**: share x hours since reset / 168. Ops logs each team's spend against it at each governor check (cloud teams from `get_session` cost [M]; Mac teams once their session ids are in the ledger).
- **Use it or lose it**: unspent budget is lost at the Sunday 5 AM PT reset, so under-spending is a failure just as overshooting is.
- **Below pace by 5 points or more**: the lead pulls the next item from its Next list at once, and if Next is under 3, asks Product for gap-discovery work (acceptance gaps, missing tests, fixture holes, recordings).
- **Reserve**: the coordinator releases it in blocks of 1 to 2 points to a team that is ahead of pace on high-value work, to Fable calls, and to red-zone installs, privacy fixes and merges. From Friday noon PT, any unreleased reserve goes to the teams with the most ready work, so nothing lapses.

## 3. The 24/7 rule: two lanes, one of them CPU

Every team keeps two lanes. The **model lane** does the thinking. The **CPU lane** runs builds, tests, scans, recordings and benchmarks that spend no model tokens. Whenever the model lane waits (on a review, a merge, an answer, or a cap), the CPU lane has a job running. A lead never ends a turn on "waiting" with an idle CPU lane. To keep wake-ups cheap, a lead batches CPU jobs so one finished batch wakes the thread once, not once per job (a cold wake re-writes the whole context, about $0.50 to $1.50 [I]).

## 4. CPU-only work catalog

**On the Mac** (run by the Mac leads as background shell runs while their model lane works; no new hosting):

| Job | How it runs | Owner | Status |
|---|---|---|---|
| `swift test` in TesseraCore | `scripts/test.sh --package-only`, on every push of a lane | Core | Built |
| App build and app tests | `scripts/test.sh --app-only`, before each PR | Builder A, B | Built |
| 5-year ScaleTests and OnDiskTests | `scripts/test.sh --package-only --scale`, nightly at the lead's last turn | Core | Built |
| Simulator recordings | Launch flags `-demoTime 18:10 -resetDemo`, scripted `simctl` capture | Builder A, Design reviews | Flags built; script to build |
| Stage timing and perf benchmarks | Time each test.sh stage, keep a trend file | Ops writes, Core runs | To build (Ops Next 3) |
| Fixture checks | Each `docs/research/fixtures` file parses and is used by a test | Core | To build |
| swiftformat and swiftlint | Before each commit | Every Mac lead | Built |
| Simulator lane lock | Lock file naming the lane that owns the simulator | Ops | To build (Ops Next 6) |

**In the cloud** (run in a thread's container as background commands, or in a GitHub workflow that runs stdlib scripts with no secrets):

| Job | How it runs | Owner | Status |
|---|---|---|---|
| `scripts/ops/premerge_check.py` (key, data-safety, script rules) | Merge worker, on each diff | Coordinator's merge workers | Built |
| `scripts/ops/tree_check.sh` (stale-tree merge check) | Merge worker, before each merge | Coordinator's merge workers | Built |
| `scripts/ops/verdicts.py` (latest QA verdict per PR) | QA and merge workers, before merges | QA | Built |
| Premerge workflow on each PR | `.github/workflows/premerge.yml`, the two scripts above | Ops | To build (Ops PR 1) |
| PR-status digest | One table of PRs, SHA, verdict, mergeable | Ops | To build (Ops Next 2) |
| Docs index and link checks | `docs/README.md` lists every doc; relative links resolve | Ops | To build (Ops Next 8) |
| Board and memory staleness | Flags board lines naming merged PRs, memory files over 3,000 bytes | Ops, Product acts | To build (Ops Next 4) |

The AI evals in `scripts/ai/` call Claude, so they are model work, not CPU work.

## 5. What each team adopts

- **Core**: senior for wall, privacy and schema calls; middle for slices; junior for fixture and docs PRs. CPU lane: package tests and nightly ScaleTests.
- **Builder A**: middle by default, senior only for root causes after two failed fixes. CPU lane: app build and tests, recordings for Design.
- **Builder B**: same as A; Tess prompts and the Claude key screen get a senior review. Take the simulator lock before any app run.
- **QA**: middle reviews, depth by risk; walls and privacy at Opus medium or above. Junior for verdict lines; run `verdicts.py` instead of re-reading files.
- **Design**: senior for direction only; middle for passes; junior for clip trims and sheet PRs.
- **Coordinator**: middle, stays broad; merges go to junior workers using the three ops scripts. Owns reserve release.
- **Research**: junior while waiting; middle for the Oct 19 week-two plan. If below pace, ask Product for gap discovery.
- **Product**: middle for rulings, junior for board refills and docs mirrors. Answers gap-discovery asks the same day.
- **Motion lab, Kitchen, AI arch**: middle for new ideas and acceptances, junior for everything listed in Next that is upkeep.
- **Ops**: junior builds the to-build scripts above; logs each team against its pace line at every governor check.

## 6. Risks, and the meter overrides everything

- **The governor's meter wins.** A team's remaining budget never licenses spend past the 5-hour thresholds: at 70% of the window every team halves lanes and drops one tier; above 85% only installs, privacy fixes and merges run, paid from the reserve. The 5-hour window is never exceeded.
- **Make-work under "use it or lose it"**: spare budget goes to gap discovery, tests and recordings, never to re-doing finished work. Product rules on whether an item is real.
- **Cold wakes and long contexts** cost more than the tier choice; batch CPU results, restart workers over 250k tokens.
- **Mac contention**: two builds or two simulator runs at once slow both and can kill a run; use the lane lock.
- **Blind spots**: Mac leads' spend, Kaushik's own use, and whether Fable has its own meter are unmeasured, so those numbers stay inferred until the ledger fills in.
- **Junior failures that ship**: anything a junior touches on walls, privacy or the data model is reviewed by a senior before merge.
