# Week two stale check, Oct 19 morning

For: the coordinator and Product, before Monday Oct 19, 8:15 am PT. Checked Oct 19 2026, 7:5x AM PT, against master
`2c0e6eb4` (1,114 commits since `9ab8ae3`, the Oct 17 check's head), `next-build-v9r.md` and the rider table in
`oct-22-riders-checklist.md`, the pin, and `product/decisions.md` (1,105 lines) from 6:00 PM Oct 16. Corrected 7:5x AM
PT on the coordinator's word: his phone has release 18 `aba79265d07f8246c73c75c598d866654cd9ef3c`, installed 6:36 AM Oct 19;
release 17 `f38bc089` went on at 11:17 PM Oct 18; release 19 `2c0e6eb4` is named and waits on its Mac test run. Signing
lapses Fri Oct 23, 2:12 PM PT. The riders checklist and release 13 and 15 lines in the sources are older than this.
Read the real build from the copy's `backupInfo.migrations`. Read-only: the source files are not edited. Nothing run.

The Oct 17 check's 25 rows are mostly folded into the two files already. These rows are what is still stale.

| # | File | Line or heading | What it says | What is true now (evidence) | Proposed one-line fix |
|---|---|---|---|---|---|
| 1 | week-two-plan.md | L5 to L7, header | Decisions read through 6:44 pm Oct 16; repo copy is "behind master (no restWeekday reader)"; code cited from `9ab8ae3` | Master is `2c0e6eb4`; decisions run to 6:07 PM Oct 18 (decisions.md:1105); the repo copy has the reader | Say "decisions through Oct 18, 6:07 pm; code on 2c0e6eb4". |
| 2 | week-two-plan.md | L14 to L17, section 1 item 1 | Phone: release 1 `56dd028`; "release 7 is `26dde994`" | Release 18 `aba79265` installed 6:36 AM Oct 19 (17 `f38bc089` at 11:17 PM Oct 18); 19 `2c0e6eb4` named, waits on its Mac test run (coordinator, 7:53 AM Oct 19) | "Phone: release 18, aba79265 (confirm from the copy); release 19, 2c0e6eb4, waits on its test run." |
| 3 | week-two-plan.md | L18 to L19, section 1 item 2 | Riders check is the Thu Oct 22, 9:30 am call; fixes ride the next release | Releases go out on merge (decisions.md:229 as changed by 3:03 pm); a fix reaches the phone with the next installed release (19 `2c0e6eb4` waits on its Mac test run) | Add "Release 19 waits on its test run; signing lapses Fri Oct 23, 2:12 pm PT (decisions.md:195)." |
| 4 | week-two-plan.md | L20 to L21, section 1 item 3 | "`restWeekday` is stored and read by nothing"; `week()`, `restDay` and NowPage do not read it | Built: reader `TesseraCore/Sources/TesseraCore/Settings/RestWeekday.swift:1-114` (wc 114); `Training/WeekView.swift:53` reads `RestWeekday.current`; `App/AppModel.swift:187` writes Sunday on first launch; Settings line `Features/Settings/RestDaySentence.swift:17` | "restWeekday is stored and read (RestWeekday.swift; WeekView.swift:53). It is on master and in c2193077's line, not on his phone unless 13 has it." |
| 5 | week-two-plan.md | L27 to L28, section 1 item 5 | "First launch of the build with the reader writes Sunday" as if still to come | Written by `AppModel.swift:185-187` (`writeFirstRestWeekday`); receipt "Sunday, rest day." in `RestWeekday.swift:20` | Mark built; the write happens on his first launch of a build that has it. |
| 6 | week-two-plan.md | L119, section 5, Q4 "Yes" row | Core adds the reader in `week()` and `restDay`, plus one op on first launch | Both built (rows 4 and 5); the only Core work left is a test that Now and Review show Sunday as rest | Replace with "Built. QA checks Sunday as rest on Now, Review and Plans on his copy." |
| 7 | week-two-plan.md | L142 to L144, open question 2 | "No reader is in any release"; "must be in the Oct 22 release for Sunday Oct 25"; hold the receipt until the reader merges | Reader merged (row 4); no Oct 22 release gate now (releases go out on merge); release 18 `aba79265` contains the reader's commit `c3ed6468` (git ancestry, static) | Retire open question 2; release 18 carries the reader (confirm `restWeekday` in `backupInfo`). |
| 8 | week-two-plan.md | L140 to L141, open question 1 | "Decisions log release 7 (`26dde994`)"; confirm newest installed release | Newest installed is release 18 `aba79265`; 19 `2c0e6eb4` waits | Change to "release 18 installed; 19 waits". Q1 is answered by the copy. |
| 9 | week-two-monday.md | L3 to L5 header | Decisions through 11:08 am Oct 16; master `215469f`; phone `7b321d2` | Master `2c0e6eb4`; decisions to Oct 18 6:07 PM (decisions.md:1105); phone release 18 `aba79265` | Mark the whole file superseded by week-two-plan.md and this check. |
| 10 | week-two-monday.md | L8 to L9, fact 1 | Phone runs `7b321d2`; "signing lapses about 9:57 am Oct 23" | Lapse is Fri Oct 23, 2:12 PM PT (decisions.md:195) | "Signing lapses Fri Oct 23, 2:12 pm PT." |
| 11 | week-two-monday.md | L10 to L12, fact 2 | Fixed days "built on master, not on his phone" | On every release since `a36b161` (week-two-plan.md:14 to 17); `PlanSchedule.swift:8-31` reads them | "Fixed days are on his phone." |
| 12 | week-two-monday.md | L13 to L14, fact 3 | `restWeekday` read by nothing | Read (row 4) | Same fix as row 4. |
| 13 | week-two-monday.md | L15 to L16, fact 4 | Day marks decided, not built | Still not built: no "Rest today" string in `App`, `Features` or `TesseraCore/Sources` (only a parse comment at `TessGrammar+RestDay.swift:12`) | Keep "decided, not built"; it is the one item here that is still true. |
| 14 | week-two-monday.md | L23, run order row 1 | Phone build `7b321d2` or a newer pin | Release 18 `aba79265`; 19 waits | "Which build is on his phone: release 18, or newer (check migrations)." |
| 15 | week-two-monday.md | L75 and L112 of plan, Q1 Most cite | `TesseraContext.swift:222-230` / `Model/TesseraContext.swift:222-231` | `scheduleAutosave` is at `Model/TesseraContext.swift:237-247` (file is 278 lines) | Cite `Model/TesseraContext.swift:237-247`. |
| 16 | week-two-monday.md | L82, Q4 Yes row | Core writes `restWeekday` and `week()` and `restDay` read it, still to do | Built (rows 4 and 5) | Replace with "Built; QA only." |
| 17 | week-two-monday.md | L78 and L98 to L99, Q2 No and section 3 bullet | Builder A writes the op, or he does it; remaining work "after a v6+ build is on his phone" | A v6+ build is on his phone; he switches on the Routines page, Builder A only if he asks (decisions.md:546) | "He switches on the Routines page." |
| 18 | week-two-monday.md | L100 to L101, section 3 bullet | Ship "before the Oct 23 signing lapse" in the next pin | No pin: releases go out on merge; it reaches the phone with the next installed release (19 waits on its test run) | "Ships on merge; reaches the phone with the next installed release." |
| 19 | week-two-monday.md | L113, section 5 heading | "Needs a Product call before Monday 8:15 am" | All three decided at 11:47 AM Oct 16 (decisions.md:546; L121 of the same file) | Retitle "Decided 11:47 am Oct 16". |
| 20 | week-two-monday.md and week-two-plan.md | L80 and L117, Q3 Less cite | `TessGrammar+Live.swift:141` | Path is `TesseraCore/Sources/TesseraTess/TessGrammar+Live.swift`; `setCount` is at line 141 (wc 289), so the line holds, the folder is missing | Add the path `TesseraCore/Sources/TesseraTess/`. |

## Still true

- Q1 to Q5 wording, "defaults" logging the Q4 weekday (decisions.md:667), and message B's Q1 (decisions.md:546).
- The window S=1792148400, E=1792407600, the P0 to P10 pulls, and the privacy list (names and counts only).
- Receipts are thing first: "Sunday, rest day.", "Plates, two pairs of 25 and 20." (`RestWeekday.swift:20`).
- Day marks and "Rest today" are decided, not built (row 13). A planned session beats a rest day (decisions.md:629).
- Signing lapses Fri Oct 23, 2:12 pm PT (decisions.md:195). Release 18 `aba79265` is installed; 19 `2c0e6eb4` waits on its test run.
- `PlanSchedule.swift` rolling and fixed branches (lines 8 to 31) and `StarterContent.swift:60-61` are where the files say.
- Q2 Yes keeps a missed day rolling on; fixed days wait for their weekday (decisions.md:637).

## Monday order, given the pin

1. 7:30 am: copy the newest `.tessera`, confirm migrations (expect v9 or v10) and that `restWeekday` is set (release 18 carries the reader).
2. 8:15 am: send message A (or B). If the reader is on his phone, drop Q4 only if the copy shows him already set.
3. Edits ride the next release on merge, but nothing reaches the phone until release 19 or later is installed.
