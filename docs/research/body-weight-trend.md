# Body weight trend: smoothing daily swings calmly

For: Core engine, Product lead, Design studio
Date: 2026-10-15

## What others do
- **Hacker's Diet / Libra:** trend = exponentially smoothed moving average, 10% smoothing. `T = T_prev + 0.1 * (W - T_prev)`. Seed: first day's trend is that day's weight. Libra is built on this method. [1][2]
- **MacroFactor:** "trend weight" is a moving average that counts recent weigh-ins more. It fills missing days by straight-line interpolation. It draws the raw scale weight as a pale line under a strong trend line. Exact formula not published. [3]
- **Happy Scale:** moving-average "trend", weekly loss from the trend, projections and milestones. [4]
- **Apple Health / Withings:** mostly raw points with day/week/month averages (Health) or a trend line over the points (Withings). No published smoothing. [5]

## The math, simply
EWMA: each new weigh-in nudges the trend 10% of the way toward it. One salty day of +1 kg moves the trend 0.1 kg. Half of any change shows up in about 7 days.
- **Missing days:** apply the decay for the days that passed: `a = 1 - 0.9^g`, where g = days since the last entry. A 2-day gap gives a = 0.19. Same result as if the trend had waited.
- **Seeding:** first entry is the trend. Hide the weekly rate until 7 days have passed since the first entry.
- **Long gap (over 30 days):** reseed from the new weight.
- **Outliers:** cap the step: use `clamp(W - T, -2, +2)` kg in the formula. Keep the raw entry as is. At capture, if a value is more than 3 kg off the trend, show it back plainly ("87.4 kg, 9 kg above trend") so a typo of 78.4 is caught. No warning colour.

## Recommended formula
```
g = days since last entry (1 if yesterday)
a = 1 - 0.9^g          (reseed if g > 30)
T = T_prev + a * clamp(W - T_prev, -2, +2)
rate per week = T(today) - T(7 days ago)
```
One value per calendar day: last entry of the day wins, whether typed or from HealthKit. Recompute the series from the first day on any edit (cheap; a few thousand rows).

## Worked example
| Day | Weight | Trend |
|---|---|---|
| 1 | 80.0 | 80.00 (seed) |
| 2 | 80.6 | 80.00 + 0.1 * 0.6 = 80.06 |
| 3 | 79.6 | 80.06 - 0.1 * 0.46 = 80.01 |
| 4 | none | |
| 5 | 79.8 | g = 2, a = 0.19: 80.01 - 0.19 * 0.21 = 79.97 |

Shown: **80.0 kg**. The day-2 jump of 0.6 kg barely moves it.

## What to show
- Trend in big type, 0.1 kg. Today's raw weight smaller, beside it.
- Weekly rate as a plain count: "0.3 kg less than last week" or "about the same" (under 0.1 kg).
- One quiet line: trend line strong, raw points as faint dots. Last 90 days by default.

## What not to show
- Day-to-day deltas, arrows, red or green.
- Goal pressure: no target line, countdown or "behind plan" until the user asks for a goal.
- Projections ("goal by March") in v1.

## Smallest first version
1. `BodyWeight` entries, one per day, later replaces.
2. Trend by the formula above, computed on read in `TrainingLedger` style.
3. Screen: trend number, today's weight, weekly rate sentence, quiet 90-day line.
4. Later: HealthKit body mass merge, goal (opt-in), tuning alpha.

## Sources
1. John Walker, The Hacker's Diet, "Trend" section: https://fourmilab.ch/hackdiet/www/subsection1_4_1_0_1.html
2. Withings on Libra (Hacker's Diet based): https://blog.withings.com/2011/03/09/withings-synchs-with-libra-an-android-app-for-weight-monitoring-2/
3. MacroFactor help, Weight Trend: https://help.macrofactorapp.com/dashboard/weight_trend/
4. Happy Scale, App Store: https://apps.apple.com/app/id532430574
5. Withings community, Health graphs: https://support.withings.com/hc/en-us/community/posts/360014441297-Health-graphs-explained (Apple Health from use; no published method)
