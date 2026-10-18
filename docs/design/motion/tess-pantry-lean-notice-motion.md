# Motion for board 36, 37, 41, 42 (Oct 17, PM). Specs only; values marked (lab) are defaults for Design to overrule

Sources: design/gaps-98.md (Pantry v2 states, error states), design/area-motion-97.md (area lean), Theme.Motion.house (the 380 ms house spring / 320 ms colour mix). All motion goes through MotionPolicy. Low Power = Reduce Motion everywhere here.

## 36 Pantry state change (out / low / in), one haptic
A tap on the right-hand state word cycles the state. The line itself never moves except where the group changes.
- Word: the old word crossfades to the new in place, 160 ms (lab), same width slot so nothing reflows. Weight follows the state (out 700, low 600, in 400); the weight change rides the same 160 ms.
- Ring (out only, 11 pt faint ring): draws in 220 ms from 0 to full stroke when going to out; erases 160 ms when leaving out. Nothing else on the line changes.
- Group move: out and low lines belong to OUT and LOW; going to "in" leaves the line: it closes up over 320 ms (sheet 78 close-up) while the name joins USUALLY HAVE as a name, which opens its slot over 320 ms. The hero digits just change (sheet 78: nothing counts up): the changed digit crossfades 160 ms with the word, never rolling through the values between; unknown is never counted. When a segment appears or goes ("2 low" joining, "Nothing out"), the whole hero string crossfades 220 ms.
- Haptic: `.selection` once at the tap. Nothing at the group move. A private line ("Private item") runs the identical motion and haptic (no reveal, nothing hints).
- A tap that changes nothing (a tie, G178 at 6:39 PM Oct 17) writes nothing and plays no receipt, no haptic and no word motion; the motion above is for a real change only.
- The receipt names the thing first and carries no UNDO word of its own: "Limes, low." (the UNDO is the slot's button, PW02). One app-wide slot, 10 s for a pure state change (4 s only when the op adds a row; 10 s under VoiceOver for both, PG53); a second receipt replaces the first note and its UNDO in place with a crossfade and the first op stays done (PG55). UNDO returns the row: it opens its slot over 320 ms (the line comes back to its group) and Tess's cook line blurs back in 300 ms; no extra haptic beyond the map's `.undo`.
- The cycle is in, low, out, in on the front's state word and on the Ingredient page's (PW01); on the Ingredient page the word crossfades 160 ms and the page's sentence under it crossfades with it ("Out since you cooked dal on Tuesday."), no other motion.
- A group that empties closes up with its label (PW08: an empty group draws nothing, not even its label): line and label leave together over 320 ms, the label's own fade 200 ms. A group that gains its first line opens label and line together over 320 ms.
- A line mid-close (320 ms) has no tap target, so a quick second tap never lands on the leaving line.
- A Pantry line has no press highlight (a private line has no tap target by ruling, R12; the only difference is that a tap on its name opens nothing).
- Reduce Motion / Low Power: word and ring, group move and digits are one 150 ms crossfade together; haptic unchanged.

## 41 Pantry greyed 42% to live (day one to first state)
- Greyed = 42% ink, same hue. When the first state lands (from Tess, a clear or a cook) the hero and CAN COOK rise from 42% to 100% ink over 420 ms (house curve), hero first, CAN COOK 80 ms later (lab). "Nothing yet" crossfades to the counts, 220 ms. No haptic for the wake itself (the state change's own haptic, if it came from a tap, is the only one).
- While greyed, a tap on CAN COOK shows Tess's empty line for 4 s with no UNDO and no haptic; the line blurs in 300 ms like her other lines.
- Reduce Motion / Low Power: one 150 ms crossfade, all together.

## 37 Area lean colour crossfade between areas (72% mix)
- Per Design (pantry-lean-99 section 4): Pantry state words are INK, never areaLean, so the state-word motion in 36 has no colour mix and the 72% lean never follows it. areaLean sits only on caps labels and the Pantry index line (ink until the area-colour pass lands). On a side swipe or area change those labels crossfade from the old area's lean (ink mixed 72% toward the area colour) to the new one over the 420 ms word roll (area-motion-97); nothing else recolours. Mix is done in the look's colour space per frame; no step through grey: interpolate the two lean colours directly, never via ink.
- Lacquer: Review's lean uses `sky` (gaps-98 section 2), so the Training-to-Review crossfade there moves rose to blue; check it never passes through a muddy mid (lab: it passes through violet, acceptable).
- Arrival on first appearance stays 320 ms ink to lean, hairline to 34% over 420 ms, 60 ms later.
- No haptic. Never on scroll or on a page turn.
- Reduce Motion / Low Power: 150 ms crossfade of the colours, no roll.

## 42 "Didn't save that. Try again." notice, and the offline line
- Arrival: the line appears under the row, blur-in 300 ms (150 ms crossfade in Reduce Motion), ink, no red, no icon (matches tess-error-notice.md). Exactly one `.warning` haptic at arrival (Haptic.notSaved), never on repeat: a second failed retry while the line is up re-uses the line and plays no haptic; the haptic can fire again only after the line has cleared.
- Tap = retry: the line dims to 60% for 150 ms with the 0.5 pt ink line (as the error notice); success crossfades it away 150 ms and the row shows the new value; failure leaves it, no second haptic.
- Clears after 10 s or on a good write, fading 200 ms.
- Offline "No connection. Tess works on your phone.": same arrival as an information line, no haptic, no retry, nothing queued; it clears when the connection returns, 200 ms fade.
- Acceptance for QA: count of .warning plays per failed save = 1; zero for the offline line.

Clips: render with the prototype in the next lab slot (pantry state, lean crossfade, notice) if Product still wants them; these specs are enough for Builder B to build from.
