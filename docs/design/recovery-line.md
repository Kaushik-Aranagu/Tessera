# Recovery line and the Health line on Now (build sheet, W3)

Just enough to build the two quiet lines from Research's `docs/research/recovery-line.md` (the rule, the copy, the 20 fixtures) and `healthkit-reads.md` §4 (asking in context). The rule is Core's (`RecoveryRule`, `HealthReading`). This sheet places the lines in the Now hero's type and space. Builder B owns `NowPage`.

Recording: `recordings/recovery-line.mp4` (source `studies/recovery-line.html`):
1. The first training-day morning shows the one-time Health line. A tap opens the system sheet, and Allow turns the line into L1.
2. Holding the line gets Tess's "why".
3. Start: the line stays under the running process.

## Where it sits
- **Under the action row,** never between the hero and its action. On a training day, Now reads top down:
  1. The context line ("today's training"),
  2. the hero ("Push day A"),
  3. the action row (Start with "5 EXERCISES / 18 SETS"),
  4. then this line, 28pt under the meta.
- **Running workout:** the same slot under the Resume row ("REST / 1:22"). It never replaces the running process (F15), and it goes once the workout finishes (F16).
- **Type:** Body 21/400 in `inkSecondary` (60%), one line, no weight, no wash, no dab, no icon. The sleep figure is plain text in the line, not a value word. It's quieter than everything above it, by design.
- **Never** on a rest day ("Rest day" stays alone), and never in a notification, widget, Live Activity, the Lock Screen, the Day log or a context pack.

## The lines, exactly
| Case | Line | When |
|---|---|---|
| L1 | Slept 5h 40m, take it lighter | `short` with `hrvLow` or `rhrUp` (F02, F08, F15) |
| L2 | Slept 5h 40m. Lighter is fine today | `short` alone (F03, F04, F09, F13, F17; "Slept 6h." when minutes are 0) |
| L3 | Still recovering. Lighter is fine | `hrvLow` and `rhrUp`, sleep in range (F05, F19) |
| none | (nothing, and the slot closes) | Every other fixture. A good night says nothing |
| Ask, once | Add last night's sleep from Health? | The first training-day morning after W3 ships, before any read permission was asked |

Minutes round to 5. VoiceOver reads "Slept 5 hours 40 minutes, take it lighter".

## Motion
- **Arrival:** computed once on the first foreground after the night closes, then frozen for the day. It arrives after the hero and the action row settle: it rises 6pt and fades in (360ms, house curve), as entrance 4. It never flickers in later: if the reading isn't ready when Now first draws, the line waits for the next visit to Now that day, rather than pushing in under his thumb.
- **Leaving** (the workout finishes, or the day ends): it fades (220ms), and the slot closes up with the house curve.

## Hold for why
- **Hold the line 0.5s:** a 1.5pt hairline in `inkSecondary` fills under it, left to right. Then Tess answers beside the soul, in cobalt, with no UNDO:
  - L1 and L2: "Short night against your usual."
  - L3: "Heart signs off your usual."
- No numbers, no "HRV", "bpm", "ms", "score" or "%". A tap does nothing; the line isn't an action.
- `.selection` fires when the hairline completes.

## The one-time Health line
- It sits in the same slot, the same type, and the same arrival: "Add last night's sleep from Health?"
- **Tap:** the 1.5pt hairline draws under it (150ms) with `.selection`, then the system's Health sheet rises. The sheet is system UI, so it's exempt from the no-shapes rule. It carries the share string from `healthkit-reads.md` §5.
- **After the sheet:**
  - With data, the question crossfades through a 4pt blur (160ms out, 220ms in) into the day's line (L1, L2 or L3).
  - With no line to show, or with access denied (HealthKit can't tell the two apart), the question just fades and the slot closes.
  - Either way it never shows again, and nothing ever says "denied" or "no data".
- **Swipe it left** to dismiss: it follows the finger and fades (200ms), with no confirm. It never shows again.
- Check `statusForAuthorizationRequest` first. If the sheet was already shown, this line never appears.

## Reduce Motion and accessibility
- No rise; the line fades in place, and the swap is a plain crossfade.
- The hold-for-why also works as a VoiceOver custom action, "Why is this here?", which speaks Tess's answer.
- At the largest text sizes the line wraps; it never truncates.

## Never
Red or amber, a dot or badge, "low", "poor", "bad", "missed", "should", a number other than sleep hours, or a notification.

## Owners
| Part | Where | Owner |
|---|---|---|
| `RecoveryRule`, `HealthReading`, `HealthKitReader`, the share string | `TesseraCore/Health/`, `App/Health/`, `project.yml` | Core |
| The line, its slot, the hold for why, the one-time Health line | `Features/Home/NowPage.swift` (`RoutineHero`, `RunningHero`) | Builder B |
