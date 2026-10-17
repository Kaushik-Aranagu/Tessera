# Recipe clock start minutes across DST, midnight and the 4 am day (RC1-RC10)

*Kitchen lead, 2026-10-17. Extends K6.1-K6.19 in `kitchen-overnight-acceptance.md` (K6.19 only said "by the rules above"; these rows give the numbers). Sources: `recipe-clock-steps.md` (D3, s11 "overnight" = 480 min, over 3 h = no timer, no countdown), `dst-nov-1.md` (DS1, 25-hour Saturday), `dst-travel.md` (rules 3 and 7), `kitchen-timer-alerts.md` (KT5, KT16), `evening-quiet.md` (EQ20), decisions 1:52 and 1:40 via the time-decisions note. "Default taken" is my inference.*

**Rule.** Step start and end are minute offsets from the cook start, counted in real minutes, so the repeated hour counts twice and the spring gap is skipped. Wall clocks are read off the instant afterward. Wall subtraction (end clock minus start clock) is wrong on both nights. Day filing is by the wall clock's 4 am day, not by seconds (decision 1:52 says day math is calendar-day; DS1: Saturday is 25 h). Quiet hours 23:00-07:00 are wall times: 9 h on Nov 1, 7 h on Mar 14 (EQ20, DS11).

**Steps used (D3 with an 8 h rest, "Rest overnight")**

| Step | Min | Start-end offset |
|---|---|---|
| 1 Stir dough | 2 | 0-2 |
| 2 Rest overnight | 480 | 2-482 (drawn 10 wide; no timer, no countdown) |
| 3 Oven and pot | 30 | 482-512 (timer) |
| 4 Shape, rest | 30 | 512-542 (timer) |
| 5 Bake 30 + 15 | 45 | 542-587 (timer) |
| 6 Cool | 60 | 587-647 (timer) |

Total 647 min = "10 h 47 min". Zone is America/Los_Angeles unless stated (K6 used London, where the change was Oct 25). Fall-back: Sun Nov 1, 2:00 am PDT (9:00Z) to 1:00 am PST. Spring: Sun Mar 14 2027, 2:00 am PST (10:00Z) to 3:00 am PDT.

| # | Fixture | Expected numbers |
|---|---|---|
| RC1 | Start Sat Oct 31, 8:00 pm PDT (3:00Z), D3 as above, across midnight and the repeated hour | Step 2 ends 3:02 am PST (11:02Z). Timers: step 3 at 3:32 am, step 4 at 4:02 am, step 5 at 4:47 am, step 6 at 5:47 am PST. Finish 5:47 am Sun Nov 1. Log: "5:47 am Cooked no-knead bread, 10 h 47 min", on Sun Nov 1 (finish after 4 am). Never "9 h 47 min" (wall subtraction). All four timers sit in quiet hours and ring (K6.9, default taken) |
| RC2 | Steps 3-6 only (dough risen), start Sun Nov 1, 12:40 am PDT (7:40Z) | Offsets 0-30, 30-60, 60-105, 105-165. Timers: step 3 at 1:10 am PDT (8:10Z), step 4 at 1:40 am PDT (8:40Z), step 5 at 1:25 am PST (9:25Z, the clock reads earlier than step 4's), step 6 at 2:25 am PST (10:25Z). Log: "2:25 am Cooked no-knead bread, 2 h 45 min", filed Sat Oct 31 (finish before 4 am, K6.15). Wall subtraction would say 1 h 45 min |
| RC3 | RC1 live; read the key row at 1:30 am PDT (elapsed 330) and 1:30 am PST (elapsed 390) | Finish clock "5:47 am" at both reads (it comes from offset 647, not from now plus wall hours). In step 2: "165 MIN LEFT" at both (the 480 wait is excluded from the key count, per recipe-clock; default taken that the finish clock includes it). Peek count unaffected by the hour |
| RC4 | Start Sat Oct 31, 9:30 pm PDT (4:30Z); the 4 am roll falls inside step 2 | Roll at 4:00 am PST (12:00Z) = offset 450. Step 2 ends 4:32 am PST (12:32Z). Timers 5:02, 5:32, 6:17, 7:17 am PST; 7:17 am is past 7:00, so it rings in normal hours and the others ring in quiet hours (default taken). The cook stays Now through the roll (K6.18). Finish 7:17 am Sun Nov 1, "10 h 47 min" |
| RC5 | Finish at the boundary: start Sat Oct 31, 6:12 pm PDT (1:12Z) | Finish 12:00Z minus 1 min = 3:59 am PST: filed Sat Oct 31. Start 6:13 pm: finish 4:00 am PST, filed Sun Nov 1 (K6.16). Start 6:14 pm: 4:01 am, Sun. Wall subtraction puts the 6:12 start at 4:59 am Sun, wrong |
| RC6 | Spring: start Sat Mar 13 2027, 9:30 pm PST (5:30Z) | Step 2 ends 6:32 am PDT (13:32Z), not 5:32. Timers: step 3 at 7:02 am, step 4 at 7:32, step 5 at 8:17, step 6 at 9:17 am PDT. Finish 9:17 am Sun Mar 14, "10 h 47 min" (wall subtraction: 11 h 47 min). Step 3's alert is after 7:00 and rings as ordinary; a follow-up ask raised at 6:32 am holds to 7:00 am PDT (14:00Z) |
| RC7 | Phone zone changes mid-cook: RC1-style start Mon Oct 26, 8:00 pm PDT (3:00Z); lands 6:45 am EDT (10:45Z, offset 465) | Offsets and fire instants unchanged (KT5, KT16). Finish instant 13:47Z reads 6:47 am before landing and 9:47 am EDT after. Timers read 7:32, 8:02, 8:47, 9:47 am EDT (hold judged in the phone's zone, K6.13). Log row files on Tue Oct 27 in EDT, the zone where it is logged (dst-travel rule 7; default taken). Duration "10 h 47 min" |
| RC8 | Timer set before the change, ending after: user's own 8 h timer, Sat Oct 31, 9:30 pm PDT (4:30Z) | Fires 12:30Z = 4:30 am PST (28,800 s interval trigger), not 5:30 am. Rings in quiet hours (user-started, K6.9). Cook logged "4:30 am Cooked overnight oats, 8 h", filed Sun Nov 1. Never "9 h" |
| RC9 | Same timer in spring: 8 h set Sat Mar 13 2027, 9:30 pm PST (5:30Z) | Fires 13:30Z = 6:30 am PDT. Rings. Log "6:30 am Cooked overnight oats, 8 h", on Sun Mar 14 |
| RC10 | 40 min timer set in the repeated hour: 1:50 am PDT (8:50Z) | Fires 9:30Z, reads "1:30 am" (PST). Reads 40 min left throughout; never negative or 1 h 40 min. 1:50 am is before 4 am, so a log of it files Sat Oct 31 |

## Open, defaults taken

- Which cook-mode rulings are #419 and #461: I could not find those numbers in `cook-mode-acceptance.md`; RC rows rest on its "recipe clock" section.
- Step alerts as timers ring in quiet hours (K6.9 extended to all four step timers); only app-raised follow-ups hold to 7:00 am.
- Finish clock includes the fixed-width wait while "N MIN LEFT" excludes it (RC3).
- Filing zone for a cook that crosses a zone change is the zone at finish (RC7); dst-travel open question 1 (zone stored with the log) is still open.
- Fire-time reads of repeated 1:xx am show the clock only (no PDT/PST label); product may want one.
