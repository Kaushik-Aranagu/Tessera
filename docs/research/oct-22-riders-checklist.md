# Thu Oct 22, 9:30 am: every rider in? (the check before #407)

For: Product, Core, Builder A, Builder B, QA. Owner: Research lab. Written Fri Oct 16, 2026, about 5 pm PT.
Sources: `next-build-v9r.md` section 0 (rider status, with the "in 56dd028" column read Fri 4:50 pm PT) and section 3
(gate rows), `decisions.md` 3:03 pm, 4:50 pm and 2:49 pm, `docs/ops/board/qa.md` RELEASE GATE line (4:52 pm),
`fixtures/dst-nov-1.md`. Nothing was built or run for this page.

**Refreshed Sun Oct 18 8 AM PT, master c2193077.** Status read from git only (ancestry of the rider commits against
bbadf141, release 13, on his phone since 8:25 PM Oct 17, and a852d5bb, release 14, gating to install, plus greps of the
master tree). Nothing was built or run for this refresh.

**What changed (decisions 3:03 pm).** Releases go out on merge, so the 9:30 am call no longer names a pin. It checks
that every rider below is in a release **on his phone**. Release 1 is
56dd02889727e2dec8adf249eda7e9fb320e363e (56dd028, master at #544), installed over a36b161, which is what his phone has
now. QA and Design cleared 56dd028 at 4:52 pm, and it went onto his phone at 5:07 pm PT Fri Oct 16 (Product 5:10 pm); its nine rows are ticked. Each later release adds its own SHA in the "In release" column.

**Rules that hold at every release.** Only a named release SHA installs, never master by itself and never anything
older than a36b161. Before each install, the Step 0 copy "Before <release sha> (from <sha on his phone>) <time>" is
saved outside Backups and checked; the Mac keeps the last 3, and the a36b161 copy is never deleted. The Fri Oct 23,
10:00 am re-sign fallback stays, and each install re-signs anyway.

## The checklist (19 rows)

"In release" is the release SHA that carries the rider, or **not yet**. "Gate row" is from `next-build-v9r.md`
section 3; "none yet" means that section has no row for it, so the check line is the proof until QA adds one.

| Done | # | What it is | Owner | PR | In release | Gate row | Check (phone or Simulator) |
|---|---|---|---|---|---|---|---|
| [x] | R1 | HW19: "sick", "unwell", "feeling sick" walled, with the CR1 sick-slang mask | Core 0ac | #534 | 56dd028 | HP1 | Sim with the Claude spy: `feeling sick, no gym` and `unwell today` make zero requests; `sick of this traffic` stays plain. |
| [ ] | R2 | HW13: Siri Add a Task "weighed 82.2" saves a private note and never reads the number back | Core 0ac | #534 (half) | 56dd028, **half** (still half at c2193077 and in bbadf141, a852d5bb: no "Body weight logged." in the tree; Siri still says "Private note, kept.") | P14 (gains the phrase) | Sim Siri, Add a Task "weighed 82.2": a private note, no number spoken. **Open:** the reply is "Private note, kept." (`Intents.swift:166-169`); the row stays open until it reads "Body weight logged." (Product 4:50 pm (1)). |
| [x] | R3 | HW9: `requiresAuthentication` on Tell Tess and Add a Task | Core 0ac | #534 | 56dd028 | HP2 | Lock the Sim; Siri Add a Task and Tell Tess both ask for Face ID before writing. |
| [x] | R4 | HW11: the body check runs before `parsePastLog` | Core 0ac | #534 | 56dd028 | HP3 | Type `weighed 82.3 yesterday`: private, never "Noted for Thursday." with the number in a plain note. |
| [x] | R5 | N13: a private note's row shows only "Private note" | Builder B 0p | #508 | 56dd028 | NP1 | Notes: add "gate code 4417" as a private note's second line; the row reads "Private note" and the time, and VoiceOver reads the same. |
| [ ] | R6 | N15: one-time launch pass marks notes from before #422 private when they hold a secret word with a value | Core 0aa | none yet | **not yet** (still none on master at c2193077 or in a852d5bb: no N15 launch pass found in the tree) | NP2 | Sim: on 7b321d2 write "wifi password is hunter2", install a36b161, then the release: Notes and the Day log read "Private note"; a second launch writes nothing. |
| [x] | R7 | P14: Siri Add a Task checks `PrivateFacts.isWalled(title)` | Core 0l | #534 | 56dd028 | P14 | Sim Siri, Add a Task "pay rent 2100 friday": no plain task with 2100 in its title. |
| [x] | R8 | PN-MENTION: "@Private note" never resolves to a private note (Core half); the object page never shows its body (Builder B half) | Core 0ad, Builder B 0r | #551 (Core half) | Core half 56dd028; Builder B half in e149e66 (#580, #597) | MN1, then PF1 | Plain note "see @Private note", tap it: no private note opens. Done only when R18 is in. Old links saved before 56dd028 stay (2:32 pm, no migration); R18's mask covers what they open. |
| [x] | R9 | ", best" in the Day log and Review's tapped day | Core 0w | #504 | 56dd028 | DB1 | Log a set that beats his best (kg), open the Day log, then Review on that day: "Bench 85 × 8, best." and the hero says "Bench best". |
| [x] | R10 | #403 Tess's eyes, inert | Builder A 0j | #403 | 56dd028 | EY0 | Phone build, no flags: no eyes on Home or the live workout corner, and no setting for them. |
| [x] | R11 | Trip bands: Review counts each item by its own op zone (with G1 The week, G2 cook day) | Core 0ae | #552 | 56dd028 | TB1 | `ReviewTripWeekTests` (13) pass; Sim `-demoTime` on a trip week: a task done 9 pm Pacific and a cook finished after midnight land on their own zone's day. |
| [x] | R12 | SAVE A COPY default name "Before update <day>.tessera"; rotation touches only the rolling prefix | Core 0af | none yet | bbadf141 (183966a, `isRollingName`; also in a852d5bb; read from git, not run) | SC1 | SAVE A COPY: the suggested name is "Before update <day>.tessera"; background past the daily copy and the rolling seven never prune it. |
| [ ] | R13 | SAVE A COPY warns when he picks the Backups folder (after R12) | Builder B 0t | none yet | **not yet** (still none on master at c2193077 or in a852d5bb: no "This is the Backups folder" string in the Swift tree) | SC2 | SAVE A COPY into Backups: "This is the Backups folder. Daily copies here get replaced. Save somewhere else?"; saving elsewhere is one tap. |
| [x] | R14 | DST fall-back: DS8 repeated 1:30 am, with DS29 and DS36 | Core 0ag | none yet | e149e66 (#576, 8332d0e; in bbadf141 and a852d5bb). Master has DS8 (`oneThirtyInTheRepeatedHourIsTheSecondPass`, renamed from the check's test name), DS29 (`datedLiftSundayIsNoon`) and DS36 (`TessMemoryTests` line 154); not run, so re-read before the Oct 31 night | none yet (fixture DS8, DS29, DS36) | `TessGrammarFallBackTests` `oneThirtyInFirstPassIsSecondPass` (DS8: "bins 1:30am" at 1:45 am PDT is 1:30 am PST that night, not Mon Nov 2) and `datedLiftSundayIsNoon` (DS29), plus `noticedWeeksSameClockIsTwo` (DS36) pass (`fixtures/dst-nov-1.md`). |
| [x] | R15 | Review foot line out of Tess's band (Design v9 walk, must land) | Builder B 0x | none yet | e149e66 (#583) | **FB1** | Sim: Home's link line (`HomeSpatialView` HomeLinkLine) sits clear of Tess's band. |
| [x] | R16 | Routines Tess line and "Add an exercise" out of the band, 84 pt inset (Design v9 walk, must land) | Builder A 0q | none yet | e149e66 (#601) | **FB2** | Sim: Routines' Tess line and "Add an exercise" sit clear of the band at the 84 pt inset. |
| [x] | R17 | Resume key progress reads targetSets (nothing writes "sets") | Builder A 0r | #546 | 56dd028 | **RK1** | Sim: start an exercise planned for 4 sets, log one, leave and resume: progress counts toward 4, not 3. |
| [x] | R18 | Private-field mask: a private object shows only "Private note", "Private task" or "Private memory" on the generic page, `PropertyList` and the class page's newest row; closes R8's Builder B half; a workout's notes show only "Note kept private" on its front (decisions 5:07 pm, PM21 to PM36) | Core 0ai | none yet | e149e66 (#580, #597) | PF1 | `WallsUITests/testObjectPageMask` with `-wallsSeedPrivate` (PM1 to PM34; PM35 and PM36 in the package and live suites), then VoiceOver on Push A's Linked from and its front: no field names, values or counts, and no words of the workout's notes ("left knee sore", "weighed 82.4 before", "felt strong") anywhere. |
| [ ] | R19 | Bare-number body wall ("is 82.4 good?" near his last weight); **first in Core's 0ai** (Product 4:50 pm (3)) | Core 0ai | none yet (with #564) | code in e149e66 (PrivateFacts bare-number wall, #627); still no `WallsUITests` file on master at c2193077 and none in bbadf141 or a852d5bb (#564 not merged), so the row stays open | BW1 | `WallsUITests` BN01 to BN11: "is 82.4 good?" makes no Claude call and no Home task with the number; "is 3.5 good?", "is 120 good?", "bench 82.5 x 5 good?" stay plain. |

## Open items to read out at 9:30 am

- **R2 wording.** Accepted half done (Product 4:50 pm (1)): the number is walled, but the row stays open for
  "Body weight logged." It counts as not in until a release carries that reply.
- **R8 is inside R18.** The Core half shipped in 56dd028 (#551); the Builder B half is R18's mask. Tick R8 when R18
  is in a release on his phone.
- **R19 is first in 0ai.** "is 82.4 good?" still becomes a Home task with the number, and the new-on-your-phone page
  says "Not yet fixed" until R19 lands with #564 (held: Design FIX FIRST, and it conflicts with master).
- **R14 has a hard date.** The fall-back night is Sat Oct 31 into Sun Nov 1. R14 must be in a release **on his phone
  before the Oct 31 night**, even if #407 is ready earlier. DS8, DS29 and DS36 fail on master today.
- **Before Oct 26.** R11 (trip bands) is already in 56dd028, so the trip week is covered once 56dd028 is on his phone.

## Count at Fri 5:10 pm PT (56dd028 on his phone)

19 rows. In 56dd028: R1, R3, R4, R5, R7, R9, R10, R11, R17 (9 rows). Half in: R2 (wording open), R8 (Builder B half
folded into R18). Not yet in any release: R6, R12, R13, R14, R15, R16, R18, R19 (8 rows).

## Release 8 (e149e66), read Sat Oct 17 from the git history

Release 8 e149e66 went onto his phone at 9:50 PM PT Oct 16 (Product). Checked by which rider PRs are ancestors of it
and by greps of its tree; nothing was run. Newly in: R14 (the DST fall-back DS8 fix, #576; DS29 and DS36 not re-read,
so re-check them before the Oct 31 night), R15 (#583), R16 (#601), R18 (#580, #597), and with R18 the Builder B half
of R8. R19's code is in (the bare-number wall in `PrivateFacts`), but its proof, `WallsUITests` BN01 to BN11, rides
#564, which has not merged, so R19 stays open. Still not in any release: R6 (no N15 launch pass found in the tree),
R12, R13. R2 still waits on the "Body weight logged." wording. The 9:30 AM Thu call therefore has R2, R6, R12, R13 and
R19 left, plus the DS29 and DS36 re-read.

## Release 13 (bbadf141), prepared before its install

Not ticked until Builder A logs the install on his phone. Read from the git history between e149e66 and bbadf141;
nothing was run. When it lands, tick R12 (SAVE A COPY is named "Before update <day>", apart from the rolling backups,
and pruning goes through `isRollingName`; commit 183966a, board 0af). Still not in it: R13 (no "This is the Backups
folder" warning in the tree), R6 (no N15 launch pass found), R2 (no "Body weight logged." reply) and R19's proof
(no `WallsUITests` BN rows in the tree; the code wall is in since release 8). Also still to do before Oct 31: re-read
DS29 and DS36 for R14. The call on Thu Oct 22 9:30 AM therefore has R2, R6, R13 and R19 left if bbadf141 installs, and
the DS29/DS36 re-read.

## The rule

**#407 merges only when every row above is in a release on his phone.** Then the v10 gate and the v10 rollback drill
run (`next-build-v10.md` section 2), with the last v9 release on his phone as the rollback, and only then does the v10
release install.
