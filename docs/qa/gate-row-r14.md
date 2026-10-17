# Gate row for R14 (DST, Core 0ag), ready for the first release that has #576

Source: fixtures/dst-nov-1.md DS8, DS29, DS36. Package tests in #576 (QA PASS e068e14). It must be on his phone before the
night of Oct 31 to Nov 1 (the clocks fall back at 2 am on Sunday Nov 1).

| Row | Do | Expect |
|---|---|---|
| DS1 | `swift test` in TesseraCore on the release SHA: `FallBackNightTests` (`oneThirtyInTheRepeatedHourIsTheSecondPass`, 3 cases; `datedLiftSundayIsNoon`; `anOrdinaryNightHasOnePass`) and `TessMemoryTests.twoWeeksAcrossTheFallBackNightAreTwo`. Then the Simulator, Los Angeles time zone, `-demoTime` set to Sun Nov 1, 1:10 am PST: type `bins 1:30am`, and `bins sun 1:30am`. Then set the day to Mon Nov 2 and type `bench 80x8 sun`. | DS8: both tasks land on 1:30 am PST (9:30Z Nov 1), 20 minutes away, not Nov 2 and not Nov 8. DS29: the lift is stored at 12:00 pm PST on Sun Nov 1 (20:00Z), not 11:00 am. DS36: with the first of 12 starts on Sun Oct 18 6 pm, Tess's memory says "about 6 days a week" on Sun Nov 1 6 pm PST, not "about 4". An ordinary night, no repeated hour, behaves as before. |

Notes
- The Simulator part needs a clock the app takes from `-demoTime`, which is simulator-only through LaunchFlags. If it does
  not reach the Nov 1 date, the package tests alone are the gate and the Simulator steps are marked skipped, not failed.
- The row is a fixture row (`fixtures/dst-nov-1.md`), so a release whose PR isn't in skips it.
