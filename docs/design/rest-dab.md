# The rest dab and the Review headline (build sheet, board item 12)

This sheet covers just enough for Builder B's Review week fix. It works on Research's `docs/research/fixtures/review-sentence.md` (#155): the copy, the three dab states and the 30 fixture weeks are all there. Here they get their marks and their type. Core supplies the week data.

Mockup: `mockups/rest-dab.png` (source `studies/rest-dab.html`). It shows F27 in Plein light and dark, plus F01, F16, F30 and F28 as dab rows.

## The four day marks (both Review surfaces)
Every mark sits in the same 34×30 slot, with the day letter 8pt under it.

| State | Mark | Letter |
|---|---|---|
| Trained (Home) or something done (Review) | The sage `PaintDab`, as today. | `inkSecondary`, or ink for today |
| **Rest** | **A short dry stroke lying across the slot's lower half.** It's 32×5 at y 15 to 21, ink at 50%, with a rough edge and a dry-brush break-up, and no outline. It's the same horizon the rest timer and the Rest Live Activity use, so rest reads as rest, not as an empty dab. | the same |
| Open (a real miss) | The faint ink ring at 25%, as today. It's never red and never a colour. | the same |
| Before first use | Nothing: the slot stays empty. | `inkTertiary` (38%) |

- **Drawing it:** a `RestStroke` shape next to `PaintDab`, with the same seed per index, so each day's stroke is a little different. It's a filled path of 5pt at the middle, tapering to 3.5pt at the ends. Use `Theme.Colors.ink.opacity(0.5)` with the rough-edge treatment the paint strokes already use. It's ink, never the class colour, so it holds in every theme.
- **Arrival:** it draws left to right (280ms, house curve) in the dab row's entrance stagger, where the dabs pop.
- **A day that becomes rest while he looks** (he finishes the week's last session, so an earlier miss is caught up, as in F30 and F09): that ring fades (200ms) and the stroke draws in its place 120ms later. Nothing else moves. With Reduce Motion it's a plain crossfade.
- **VoiceOver:** "Tuesday, rest", "Wednesday, trained", "Thursday, open". Days before first use are skipped.

## The headline
- **Type:** the Hero role, unchanged (56/500 ink). Every count is a plain word. No word gets extra weight or colour, and the hero never says "good", "of seven", "behind" or "only".
- **Wrapping:** never leave one word alone on the last line. "All six sessions in" breaks as "All six / sessions in". Build it with `ViewThatFits`: try one line first, then the version broken after the number phrase.
- **Copy:** use Research's §4 exactly:
  - Home: "All six sessions in", "{N} sessions this week", "{N} sessions in your first week", "Your first week starts today" and "A quiet week so far".
  - Full Review: "Something done on {n} days", "Something done every day".
  - Counts line: "Nothing to count this week." (or "Nothing to count yet.").
- **When the count changes** on the page (a workout finishes behind it), the old sentence fades out with a 4pt blur (160ms) and the new one fades in (220ms). The dab for the day pops after that, as in entrance 2. There's no celebration on "All six sessions in": the sentence is the reward.
- **Thin weeks** read as a fact in the same type and the same place: "Two sessions this week" sits exactly where "All six sessions in" would. The rings stay faint.

## Tess's line (optional, cheap)
Research's Q8 suggests "Two records this week: Bench Press and Squat." (tess cobalt, Body 21, in the existing Tess slot). It wins over the sets line when both exist. The sets line becomes "{Muscle}: {n} sets this week, toward a usual 10." and stays silent when the week has 3 sessions or fewer.

## Owners
| Part | Where | Owner |
|---|---|---|
| Week data: sessions, past rest days, first-use date, set-aside workouts that count | `TrainingLedger` / `WeekView` | Core |
| `RestStroke`, the three-state dabs, the headline and its wrap, the swaps | `Features/Home/ReviewPage.swift` (`DayDabs`), `Features/Review/ReviewView.swift` (`WeekDabs`) | Builder B |
