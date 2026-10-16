# Claude spend cap math check (Product item W)

For: Product, Core. Read on origin/master at `76be1c0` (Oct 16, 2026). Code reading and arithmetic only; no calls made.
Projection checked: `docs/ai/spend-projection.md` (#464). Ledger: `TesseraCore/Sources/TesseraTess/ClaudeKey.swift` (CK).
Units: the ledger counts nano-dollars (n$), Int64. Tally: **12 pass, 9 fail, 3 partial**.

| id | What | file:line | Expected | Today | Result |
|---|---|---|---|---|---|
| W1 | Cap constant | CK:88-90 | $50 | `capNano = 50_000_000_000`, `capDollars = 50` | pass |
| W2 | Settings copy | ClaudeSection.swift:191, 196-197, 203, 460 | $50 | all read `capDollars`; no literal | pass |
| W3 | Code comments | CK:7, CK:83 | $50 | both still say "the $10 month" | fail |
| W4 | Tests pin the cap | ClaudeKeyTests.swift:186-246 | a test fails if the cap changes | tests use `capNano` symbolically; nothing asserts 50 or "of $50." | fail |
| W5 | Docs | tess-voice.md:151-166 (M8, M9), settings-claude.md:22, 47-48, tess-model-layer.md:98, 176, claude-first-uses.md:16, claude-key-test.md:81 | $50 | still $10 (spend-projection.md:78 lists some) | fail |
| W6 | Input/output prices vs doc | CK:93-96; spend-projection.md:6-7 | same | Haiku 100/500 n$, Sonnet 2,000/10,000 n$ in both: the doc took them from code (`TessUsageLedger.prices`) | pass |
| W7 | Cache prices vs research | CK:94-95; tess-model-layer.md:85, claude-first-uses.md:20, plan-my-day-prompt.md:340 | same | Sonnet cache read is 200 n$ in code, 100 n$ ($0.10/M) in all three research docs (code follows QA review-298 P4's ratio). Cache write 125 / 2,500 n$ appears in no doc. Projection assumes no cache, so totals are unaffected | fail (unsure which is right) |
| W8 | Spend from response usage | ClaudeTessModel.swift:238-241; PlanWording.swift:625-626; RecipeLinkReader.swift:419-420; CK:251-256 | `usage` counts | all four read `input_tokens`/`output_tokens`; only ClaudeTessModel also reads both cache counts | partial: Plan and Recipe would drop cache tokens if caching is ever turned on |
| W9 | Billed but unanswered | ClaudeTessModel.swift:226; PlanWording.swift:572; RecipeLinkReader.swift:403 | never under-count | a client timeout (8 s capture, 20 s plan and recipe) writes a row with 0 tokens, though the server may still bill | fail |
| W10 | Rounding | CK:156-160; ClaudeSection.swift:21-25, 518-521 | up, never under | cost is exact integer n$ (no rounding needed); month shown rounded up to the cent, one call up to 0.1 cent | pass |
| W11 | Integer vs Double drift | CK:114, 174; SystemCatalog.swift:230 | no drift | Int64 sums; each row stored as a Double number field, exact below 2^53 n$ ($9M) | pass |
| W12 | VoiceOver amount | ClaudeSection.swift:196 | same as the visible amount | `%.2f` rounds to nearest, not up ("0.00" while the screen says "$0.01") | fail (minor) |
| W13 | Month calendar and zone | CK:83-84, 111-112 | Pacific | `Calendar.current`: the phone's zone, 00:00 on the 1st, not the 4 AM day (comment says so). Not pinned to Los Angeles; claude-first-uses.md:122 says LA | fail |
| W14 | Nov 1 DST | CK:112 | no double or lost hour | DST ends Nov 1 at 2:00 am, after the 00:00 boundary; `dateInterval(of: .month)` gives Oct as 31 days and Nov as 30 days 1 hour. Fine | pass |
| W15 | Trip zone (Oct 26) | CK:111; ClaudeTessModel.swift:25; PlanWording.swift:430 | stable month | `createdAt` is absolute, so mid-month nothing moves. If he is in Eastern time on Oct 31, Nov opens at 9 pm PDT. The capture model keeps the zone from launch (`calendar` stored at init) while Settings reads the current zone, so the two can disagree for a few hours at a boundary | partial |
| W16 | Check before each call | CK:137-142; callers ClaudeTessModel:58-60, PlanWording:462-464, RecipeLinkReader:373-375, CK:240-242 | reserve before send | every call reserves on the main actor, with in-flight holds (`pending`); unknown model estimates 0 and is refused | pass |
| W17 | Worst case reserved | CK:150-154; ClaudeTessModel.swift:58-59 | max cost held | output held at `max_tokens`; input is bytes/4 + 10, a guess, not a bound. Capture holds 3 rounds of round-one input, but rounds 2-3 resend more (assistant turns, tool results). A call can pass $50 by a few cents at most | partial |
| W18 | 80% | ClaudeSection.swift:195, 202-206 | warm line | month line turns warm and "PAUSES AT $50" shows at $40. No step-aside of any job (docs only, spend-projection.md:83) | pass for what is built |
| W19 | 100% | ClaudeSection.swift:156, 198-201; ClaudeTessModel.swift:62-64; PlanWording.swift:467; CK:339-341 | stop with the date | "Paused until Nov 1." and each job's "Claude paused until Nov 1." Settings only says paused at `spent >= cap`, while calls are refused once spent + hold passes $50 (from about $49.99), so he can be refused without the paused line | fail (minor) |
| W20 | Cap hit mid-batch | TessInbox.swift:74-84; PlanWording.swift:449-468 | stop cleanly, lose nothing | inbox drain stops at the first refusal and keeps the rest queued; plan is one call per `word`. AI-12 groceries linking has no code on master (no job to check) | pass (AI-12 n/a) |
| W21 | Survives restart | SystemCatalog.swift:222-234; CK:162-179 | kept | spend is `TessCall` rows in the GRDB store; restart keeps them | pass |
| W22 | Backup/restore | TesseraBackup.swift:4-8, 317 | not reset, not doubled | a restore swaps in the whole SQLite copy: never doubles, but every row after that copy is gone. A restore from last month's copy reads $0 this month | fail |
| W23 | Never stores the key | SystemCatalog.swift:222-236; CK:20-55 | yes/no only | rows hold tokens, cost, outcome, request id; key in Keychain, this device only, not synced, so not in backups. Key presence: yes/no only | pass |
| W24 | `asksClaude` gates all use | AppModel.swift:58-60, 129-136 | one switch | gates capture; Plan and Recipe take `allowed` but are not wired in the app yet (spend-projection.md:89) | pass for what is built |

## Recomputed projection (doc's counts and tokens, code's prices, 30-day month)

Per call = in x price + out x price. Home lines 1,500 x 2,000 + 150 x 10,000 = 4.5M n$ = $0.0045. Week story 4M + 3M = $0.007.
Plan 1,000 x 2,000 + 300 x 10,000 = $0.005; max 1,270 x 2,000 + 1,024 x 10,000 = $0.01278. Recipe 700k + 600k = $0.0013; max 700k + 2.048M = $0.00275.
Groceries $0.00022 (measured). Misses 515k + 65k = $0.00058. Ask 300k + 50k = $0.00035. Living colour 120k + 30k = $0.00015.

Typical: 600 x 0.0045 = 2.70; 8 x 0.007 = 0.056; 60 x 0.005 = 0.30; 10 x 0.0013 = 0.013; 60 x 0.00022 = 0.013; 150 x 0.00058 = 0.087; 150 x 0.00035 = 0.053; 30 x 0.00015 = 0.0045. Sum **$3.23**: matches.
Worst: 1,200 x 0.0045 = 5.40; 60 x 0.01 (the gate) = 0.60; 150 x 0.01278 = 1.92; 30 x 0.00275 = 0.082; 120 x 0.00022 = 0.026; 600 x 0.00058 = 0.348; 300 x 0.00066 (two turns) = 0.198; 0.0045. Sum $8.58 unrounded, **$8.59** from the doc's rounded rows: matches.
Checks: misses at the held ceiling 600 x 3 x 507,000 n$ = $0.91, so $9.15 matches; Home lines share 2.70 / 3.23 = 84%, 5.40 / 8.59 = 63%; measured case $1.61; 8,889 calls to $40; 144 a day $19.44; 5,000-token pack $13.80; plan 104 a day. All match.

## Top fails

1. **Headroom rows are off by $0.04** (spend-projection.md:44-45): $40 - $8.59 = **$31.41** (doc $31.45), $50 - $8.59 = **$41.41** (doc $41.45).
2. **"Past the cap in under a week"** (spend-projection.md:69): 1,440 x $0.0045 = $6.48 a day reaches $40 in 6.2 days and $50 in **7.7 days**.
3. **Week story worst uses the $0.01 gate**, not its own $0.007 ($0.42, not $0.60); the doc says so in its note, but the row reads as per-call. Same for Ask worst (two-turn $0.00066).
4. **Restore lowers the month** (W22): spend can only go down after a restore, never up; the cap then allows more than $50 in that month.
5. **Month zone is the phone's** (W13, W15), not Pacific as the research docs say.
6. **Timeouts count $0** (W9) and **input holds are guesses** (W17): both can let real spend run a little past the ledger.
7. **$10 left in comments and voice/settings research docs** (W3, W5); no test pins $50 (W4).

## Questions for Product

1. Pin the month to America/Los_Angeles, or keep the phone's zone? (If pinned, also the "paused until" date.)
2. After a restore, keep this month's spend? One fix: keep `TessCall` rows out of the swap, or a device-only month total in UserDefaults beside the "Not today" pause.
3. Sonnet cache read: 200 n$ in code vs 100 n$ in three research docs. Which source should Research re-verify? (No effect while nothing is cached.)
4. Should Settings say "Paused" as soon as a call is refused (spent + smallest hold over $50), not only at $50.00?
5. Should a timed-out call hold its full reservation as spend until its real usage is known?
