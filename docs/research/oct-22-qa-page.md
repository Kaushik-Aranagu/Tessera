# Thu Oct 22, 9:30 am: QA page (what each open rider needs before the call)

Written Sat Oct 17, 2026. Status refreshed Fri Oct 16, 5:41 pm PT against master ab7d3bf. Read only from `oct-22-riders-checklist.md` and `next-build-v9r.md` section 3. Nothing was run.
On his phone now: release 56dd028 (QA and Design clear, qa.md 4:52 pm). Open: 10 rows below. "Owner PR" is the PR that
must exist; "none" means no PR number is on file yet, so the owner opens it. Release: the next release SHA after the merge
(releases go out on merge), so each row must merge and install by Wed Oct 21 night to be read as "in" on Thu.

## One line per open rider
- **R2** (Core 0ac): PR needed: a follow-up to #534 changing the reply to "Body weight logged." (`Intents.swift:166-169`). QA: gate row P14 at the merged head, Sim Siri "weighed 82.2" speaks no number. Design: none. Release: any before Thu. Risk: the row stays open, #407 waits.
- **R6** (Core 0aa): PR none. QA: row NP2 at the merged head (7b321d2 note, a36b161, then the release; second launch writes nothing). Design: none. Release: any before Thu. Risk: old notes with a secret word show in plain text.
- **R8** (Core 0ad, Builder B 0r): Core half is #551, in 56dd028. Builder B half has no PR of its own; it ships inside R18 (part 1 is merged in master, #580, 553ad19, not yet in a release). QA: MN1 now, PF1 with R18. Design: none. Release: R18's. Risk: ticks only when R18 is in.
- **R12** (Core 0af): PR none. QA: row SC1 (suggested name "Before update <day>.tessera"; rolling seven never prune it). Design: none. Release: any before Thu. Risk: a daily copy can delete his Step 0 copy.
- **R13** (Builder B 0t): PR none, after R12. QA: row SC2 (Backups warning, one tap to save elsewhere). Design: PASS at the merged head (new warning line). Release: same as R12 or later. Risk: he saves into Backups and loses the copy.
- **R14** (Core 0ag): PR #576 merged (4757aef), not yet in a release on his phone (QA PASS e068e14, merged-head check pending). QA: row DS1 (suggested): `oneThirtyInTheRepeatedHourIsTheSecondPass` (DS8), `datedLiftSundayIsNoon` (DS29), `twoWeeksAcrossTheFallBackNightAreTwo` (DS36) pass on the release SHA, plus Simulator `bins 1:30am` with the clock at 1:10 am on Nov 1 saying the second 1:30 (`fixtures/dst-nov-1.md`). Design: no design surface. Release: must be on his phone before the Oct 31 night. Risk: DS8, DS29 and DS36 fail on master today; a wrong date on the fall-back night.
- **R15** (Builder B 0x): PR #583 merged (36927f3, merge ab7d3bf), not yet in a release on his phone. QA: row FB1 (Sim `-demoTime 18:10 -resetDemo`, plus largest Dynamic Type; foot line above Tess's band). Design: PASS at the merged head (Design v9 walk, must land). Release: any before Thu. Risk: overlap stays; Design holds it.
- **R16** (Builder A 0q): PR none. QA: row FB2 (Routines, 84 pt inset, end of scroll, largest type). Design: PASS at the merged head. Release: any before Thu. Risk: same as R15.
- **R18** (Core 0ai): PR #580 part 1 merged (553ad19), not yet in a release on his phone; PM7, PM18 and PM19 deferred. Part 2 has no PR on master. QA: row PF1 (`WallsUITests/testObjectPageMask` with `-wallsSeedPrivate`, PM1 to PM34 in `testObjectPageMask`, PM35 in the package suite, PM36 in `testLiveWorkoutWalls`, then VoiceOver on Push A). Design: PASS at the merged head. Release: after R19 in 0ai; the latest one that can still be installed Wed night. Risk: private notes, tasks and workout notes show on object pages; also keeps R8 open.
- **R19** (Core 0ai, first): PR #564 held, not merged (QA PASS bf0ba93, Design FIX FIRST, conflicts with master). QA: row BW1 (BN01 to BN11, BM01 to BM31). Design: FIX FIRST, PASS needed. Release: first in 0ai, before R18. Risk: "is 82.4 good?" still makes a Home task with the number.

## 5-minute call script (Product reads, QA answers)
1. 0:00 Product states the base: 56dd028 is on his phone; 9 rows in, 10 open. QA confirms the SHA.
2. 0:30 Hard date first: R14. Core 0ag answers PR, merged head, release. QA confirms row DS1.
3. 1:30 Core 0ai: R19, then R18 (R8 closes with it). Core answers PR and ETA; QA answers BW1 and PF1; Design answers the PASS.
4. 2:45 Builder B: R15, R13. Builder A: R16. Design answers each PASS SHA; QA answers FB1, FB2, SC2.
5. 3:45 Core: R6, R12, R2. QA answers NP2, SC1, P14.
6. 4:30 Product asks one question per row not answered: owner and release SHA, or the row stays open. Anything with no PR is named aloud.
- **"All in" means:** the row has a merged PR, QA and Design cleared at the merged head, and that release SHA is installed on his phone (the "In release" column shows a SHA). Half in is not in.
- **#407 merges only when every one of the 19 rows is in a release on his phone.** Until then it waits, and R14 still beats Oct 31.
