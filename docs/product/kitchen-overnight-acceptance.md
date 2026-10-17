# Overnight cook (K6): finish-time row, quiet hours and the 4 am day, acceptance rows

*Kitchen lead, 2026-10-17. Extends O1-O4 in `cook-mode-acceptance.md` (decision 2:38 PM Oct 16, Core #552) with one testable row per rule. Sources: `decisions.md` (2:38 PM overnight row; 2:00 PM quiet hours; 1:22 PM default times; 6:20 PM notifications; 1:40 cook day, via the time-decisions memory note), `recipe-clock-steps.md` (s11 "Rest overnight" = 8 h). A row marked "default taken" is my inference, not a found rule. Product can overrule any of them.*

Fixture zone Europe/London (ASSUMED-12), phone local time throughout.

## Finish-time row (O1-O4 restated, with digits)

| # | State / input | Pass when |
|---|---|---|
| K6.1 | Overnight oats, 8 h rest started 9:30 pm Mon, finished 5:30 am Tue | Log row sits on Tue and reads "5:30 am Cooked overnight oats, 8 h" (finish time, not start; O1) |
| K6.2 | Cook of 415 min (2:10 am to 9:05 am) | Reads "6 h 55 min"; never "415 min" (O2) |
| K6.3 | Cook of exactly 60 min | Reads "1 h", never "1 h 0 min" (O2) |
| K6.4 | Cook of 59 min | Reads "59 min" (under 60 stays in minutes; O2) |
| K6.5 | Cook of 61 min | Reads "1 h 1 min" (default taken: same h + min form, no zero-padding) |
| K6.6 | Finish at 9:05 am | Clock is lowercase "9:05 am", with no "at" before it: "9:05 am Cooked overnight oats", never "at 9:05 am" or "9:05 AM" (lowercase is house style, decision 2:38; no "at" before a time is the app-wide rule of decisions 5:11 and copy-pass rule 6) |
| K6.7 | Two rows on Tue: 5:30 am overnight oats, 8:10 am toast | Sorted by finish time: 5:30 am row above 8:10 am row (O3) |
| K6.8 | Same-day cook, 6:00 pm to 6:45 pm | Row reads "6:45 pm Cooked soup, 45 min"; one rule for both kinds (O4) |

## Quiet hours 23:00-07:00 (notifications)

| # | State / input | Pass when |
|---|---|---|
| K6.9 | Cook timer for the 8 h rest, started 9:30 pm, ends 5:30 am (inside quiet hours) | Ending is still scheduled as `kitchen-timer.<id>` and rings at 5:30 am: a time he started himself is kept, not snapped (decision 2:00 (9): a time he typed still rings; default taken that a cook timer counts as one) |
| K6.10 | App-raised ask (not a timer) due at 23:30 | Held until 7:00 am, not shown at 23:30 (asks hold 23:00-07:00) |
| K6.11 | Task given only a day, default time would land at 2:00 am | Time becomes 7:00 am and the receipt names the day (1:22 PM, 2:00 PM (5)) |
| K6.12 | Boundary clocks 22:59 and 23:00 | A held-type alert at 22:59 shows; at 23:00 it holds. At 7:00 it releases and at 6:59 it still holds |
| K6.13 | Traveling: phone zone changes to a zone where it is 23:30 | Quiet hours follow the phone's local time (2:00 PM (6)) |
| K6.14 | Notifications not allowed, overnight timer started | Permission ask fires once, on the first cook timer if none before, within the one-ask-a-day rule (6:20 PM); no ask is raised between 23:00 and 07:00 (default taken from the ask-hold rule) |

## The 4 am day

| # | State / input | Pass when |
|---|---|---|
| K6.15 | Cook finished 3:59 am Tue | Filed on the day before (Mon); the Day log and Home weekday use the 4 am day |
| K6.16 | Cook finished 4:00 am Tue | Filed on Tue (boundary is 04:00 inclusive; default taken) |
| K6.17 | Overnight cook started 9:30 pm Mon, finished 5:30 am Tue | Filed on Tue, its finish day, not Mon (cook day rule, decision 1:40) |
| K6.18 | Cook running across 4 am | The roll at 4 am does not end or move the cook; it stays Now (default taken; consistent with "a workout past 4 am stays on the day it started", but the cook rule files on finish) |
| K6.19 | Night of Nov 1, repeated hour | Durations come from clock-day math, not seconds: a 8 h cook across the change reads by the rules above (default taken; decisions 1:52 say day math uses calendar days and the 4 am day) |

## Open, defaults taken

- Whether a cook timer counts as "a time he typed" for K6.9. Default: yes, it rings in quiet hours. The decisions say task times he typed ring; they do not name cook timers.
- "1 h 1 min" form for K6.5 follows the "6 h 55 min" form; no found rule for odd minutes beyond 6 h 55 min.
- Exactly 4:00 am belongs to the new day (K6.16).
- A cook that crosses 4 am keeps running (K6.18).
- Hours copy over 90 min is slice 12b (ASSUMED-11) for the live timer face; K6.1-K6.5 cover only the Day log row.
