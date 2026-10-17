# QA review: #606 Builder A 0n, exercise span counts calendar days (DS35, DS18 pins)

Head bfb1a26. Static, low risk. Merge-tree clean. Two files.

- ExerciseDigest.trend: days = calendar days between `TesseraDay.day(of:)` keys of the first value and now, minimum 1, "90 days" at 85+ unchanged. Uses the passed calendar, so the zone is the caller's.
- Hand check of the tests (America/Los_Angeles): Oct 25 6 pm PDT to Nov 1 6 pm PST is day keys Oct 25 and Nov 1, gap 7, reads "7 days" (was 8 by 24 h blocks). Both instants before 4 am on Nov 1 (1 am first pass and 2:30 am) share a day key, gap 0, floors to "1 day". DS18 pins: dayLine exists on master (WorkoutFinishView.swift:101); 12:50 am PDT to 1:10 am PST and to 2:10 am PST both read "Saturday, ..." as the fixture expects.
- Behavior note: a span no longer rounds a partial day up (3 pm Monday to 5 pm Wednesday was 3, is 2). That is the intended calendar-day reading, same as the Day log.
- No Catalog, migration, flag or copy change beyond the digit; clocks lowercase via existing dayLine.

Low: add a spring-forward case (Mar 8) to pin the other transition.

Verdict: PASS at bfb1a26. Design not needed (a number on an existing line).
