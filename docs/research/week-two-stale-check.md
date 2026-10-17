# Week two stale check (board item A, "101")

For: the coordinator and Product, before Monday Oct 19 8:15 am PT. Checked Oct 17, 2026 against `origin/master` at
`9ab8ae3` (#608), the rider table in `next-build-v9r.md` section 0, `ops/board.md`, and `product/decisions.md` from
4:00 pm Oct 16 on. The phone build is release 1, `56dd028` (per the caller). It contains `a36b161`, the 2:24 pm phone
line on the board, so the newer build is a superset. Read-only: the three source files are not edited. Nothing run.

| # | File | Line or heading | What it says | What is true now (evidence) | Proposed one-line fix |
|---|---|---|---|---|---|
| 1 | week-two-monday.md | L3 header | Decisions read through 11:08 am Oct 16 | Decisions run to 6:00 pm Oct 16 (decisions.md:13) | Change to "through 6:00 pm Oct 16". |
| 2 | week-two-monday.md | L5 header | Code on `215469f`; phone build `7b321d2` | Master is `9ab8ae3`; phone is release 1, `56dd028` | Say "origin/master at 9ab8ae3; phone build 56dd028". |
| 3 | week-two-monday.md | L8 to L9, fact 1 | Phone runs `7b321d2`; pin waits on #366; lapse "about 9:57 am Oct 23" | `7b321d2` is superseded; #366 is in 56dd028 (ec47bd3); lapse is Fri Oct 23, 2:12 pm PT (decisions.md 2:26 pm) | "His phone runs release 1, 56dd028; signing lapses Fri Oct 23, 2:12 pm PT." |
| 4 | week-two-monday.md | L10 to L12, fact 2 | "Fixed days are built on master, not on his phone" | #341, #359, #363 are ancestors of 56dd028; fixedWeekdays, startsOn, scheduleMode at SystemCatalog.swift:178 to 198 | "Fixed days are built and on his phone; only his plan switch remains." |
| 5 | week-two-monday.md | L23, run order row 1 | "Which build is on his phone: 7b321d2, or a newer pin?" | Release 1, 56dd028 (caller); board's last phone line is a36b161, which 56dd028 contains | "Which build is on his phone: release 1, 56dd028 (check the copy's migrations)." |
| 6 | week-two-monday.md | L78, Q2 "No" row | Builder A writes the fixed-day op, or he does it | Decided 11:47 am Oct 16: he switches on the Routines page; Builder A only if he asks | "He switches on the Routines page; Builder A only if he asks (11:47 am ruling)." |
| 7 | week-two-monday.md | L98 to L99, section 3 bullet | "What remains is switching his plan and pinning days, after a v6+ build is on his phone" | v9 (v6+) is already on his phone | "Only his plan switch and day pins remain, on the Routines page." |
| 8 | week-two-monday.md | L100 to L101, section 3 bullet | Q4 timing: "the next pin, before the Oct 23 signing lapse" | Riders pin is named Thu Oct 22, 9:30 am (decisions 1:51 pm); lapse is Fri Oct 23, 2:12 pm PT | "Ship in the next release; signing lapses Fri Oct 23, 2:12 pm PT." |
| 9 | week-two-monday.md | L113, section 5 heading | "Needs a Product call before Monday 8:15 am" | All three calls were made at 11:47 am Oct 16 (L121) | Retitle to "Decided 11:47 am Oct 16 (Product)". |
| 10 | week-two.md | L7 header | Code re-traced on `d9780e1` (Merge #259) | Master is `9ab8ae3`; setCount (141 to 159), plates (60) and loads (61) still hold | Add "re-checked on 9ab8ae3, Oct 17". |
| 11 | week-two.md | L21 to L32, section 1 fact 1 | Phone runs `b19fb4a`; no ask until the Oct 22 install | #248 (fdcaee4) and #254 (e7a5be4) are ancestors of 56dd028 | "His phone has the ask (#248, #254); Q3 uses the with-data wording." |
| 12 | week-two.md | L37 to L42, section 1 fact 2 | `restWeekday` "not on master yet"; catalog v4 | Stored by #258: SystemCatalog.swift:244, TesseraSettings.swift:25; catalog is v9; no reader in week() or NowPicker.restDay | "restWeekday is stored (catalog v9) but read by nothing yet." |
| 13 | week-two.md | L43 to L44, fact 3; L176, Q2 Yes | `PlanSchedule.swift:3-21` | File is TesseraCore/Sources/TesseraCore/Training/PlanSchedule.swift; fixed branch 11 to 19, rolling 20 to 30 | "Training/PlanSchedule.swift:20-30 (rolling plan)." |
| 14 | week-two.md | L186, Q2 "No" core block | Core adds `startsOn`, a weekday per routine, and a new catalog field | All three fields are built (SystemCatalog.swift:178 to 198) and read by PlanSchedule (11 to 19) | "Drop the field work; keep only tests that Now and Review read fixed days." |
| 15 | week-two.md | L255 to L256, Q4 "Yes" core block | Catalog "v4"; receipt "Rest day: Sunday."; ships in the Oct 22 install | Catalog is v9; receipt is thing-first ("Sunday, rest day.", 11:47 am); ships in the next release on merge (3:03 pm rule) | "Use v9, receipt 'Sunday, rest day.', and the next release, not Oct 22." |
| 16 | week-two.md | L280, L299, L309, L338 | Receipts "Rest day: Wednesday.", "Plates: two pairs of 25 and 20.", "Dumbbells: <2.5> kg steps.", "Rest day: Sunday." | Thing-first receipts ruled 11:47 am Oct 16 ("Plates, two pairs of 25 and 20.", "Sunday, rest day.") | Replace each receipt with its thing-first form. |
| 17 | week-two.md | L209, L222, L232, Q3 "Less" and "Never" | Must merge "before the Oct 22 install, or the 6-or-less ask reaches his phone first" | The ask is already on his phone (#248, #254 in 56dd028); a change rides the next release | Delete that clause; "rides the next release on merge". |
| 18 | week-two.md | L349 to L353 and L398 to L399, section 4 and open question 2 | Message B Q1 is "Did you train this weekend?", no star; open question 2 | Decided 11:47 am: "Did every set you lifted this weekend get logged? Yes / Most / Didn't train" | Use the decided wording; mark open question 2 resolved. |
| 19 | week-two.md | L365, section 5, 7:00 am row | "On `b19fb4a` it is not, so Q3 uses 'Ask / Sets'" | Phone (56dd028) has #248; Q3 uses the with-data wording | "Check the copy's migrations; #248 is on 56dd028, so Q3 uses the with-data wording." |
| 20 | week-two.md | L104 to L105, W4 | "With no ask in his build (`b19fb4a` until Oct 22)" | The ask is on his build; a light Tess set now means the ask missed | "With the ask on his build (#248, #254), a kept light set means the ask missed." |
| 21 | week-two.md | L130 and L388, findings table and section 6 | Confirm the Oct 22 install commit carries #254; the `92078ee` fallback lacks it | #254 (e7a5be4) is on the phone build; the riders pin is named at the Oct 22 9:30 am call (decisions 1:51 pm) | "Drop the #254 check; the riders pin is named at the Oct 22 9:30 am call." |
| 22 | week-two.md | L36 and L41, section 1 fact 2 | `NowPage.swift:64-67` passes `PlanRhythm.perWeek`; ReviewPage at 66, 231 | NowPage passes it at `NowPage.swift:140` (via `sessionsPerWeek`, 130 to 140); ReviewPage calls are at 66, 68, 78 | "Cite NowPage.swift:130-140 and ReviewPage.swift:66, 68, 78." |
| 23 | week-two.md | L70 and L176, path | `Core/Model/TesseraContext.swift:222-230` | Path is TesseraCore/Sources/TesseraCore/Model/TesseraContext.swift; scheduleAutosave is at 222 to 231 | Use the full path with 222-231. |
| 24 | week-two-pulls.md | L4 header and L59, section 2 item 1 | Checked against the phone build `444e72b` (installed 11:28 pm PT Oct 15) | Phone is release 1, 56dd028; 444e72b is superseded (decisions 10:02 am, 12:16 pm); 56dd028 has routine weekdays and fixed days (#341, #359, #363) | "Checked against 56dd028, the phone build (release 1)." |
| 25 | week-two-pulls.md | L28, P5 row | "Not stored: TrainingLedger computes them" | Stored as field `wasRecord` on the set (SystemCatalog.swift:162, #344 in 56dd028) | "Stored as `wasRecord` (#344) on v6+ copies; count it there, keep the query for v5 copies." |

## Monday morning order (given the phone runs release 1, 56dd028)

1. 7:00 am: Confirm the build from the copy's `backupInfo.migrations` (expect v9). Check `decisions.md` for any Kaushik answer since 6:00 pm Oct 16.
2. 7:30 am: Copy the newest `.tessera` and run P0. If P0 fails, send message B.
3. 7:40 am: One pass of P1, P2, P3, P5, P7, P8 and P9. P5 counts the stored best flag (`wasRecord`), names only.
4. 8:15 am: Send message A with the with-data Q3 wording. Q2 "No" is his own tap on the Routines page, not a Builder A op.
5. After his reply: code edits ride the next release on merge (3:03 pm rule, gates kept). Nothing waits for an Oct 22 install; signing lapses Fri Oct 23, 2:12 pm PT.
