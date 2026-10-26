# Living colours: Tess's soul, chosen by AI (Design item 48)

**Kaushik's principle, in one line:** Tess's colours should keep changing, chosen by AI from what's going on, so she feels alive rather than painted once.

From the Design thread (16 Oct, 12:08 AM PT). Product's rules (12:10 AM): Tess only; the app's base and resting colours stay fixed per look and Obsidian stays; the on-phone picker chooses by default; Claude only under "Tess asks Claude", cached, at most once a day; changes stay inside each look's soul palette, arrive through motion, and text contrast never depends on them. The choosing side is the AI thread's (`docs/ai/architecture.md` section 9: a rule table picks a palette name and two nudges; Claude may replace the day's pick once). This sheet owns the rest: **the palette space, the nudge ranges, what fits when, the cadence, how a change arrives, and the fallback.**
- Board: `mockups/living-colours.png` (source `studies/living-colours.html`). Every palette on every look at 2.4×, and the two nudge ranges on Lagoon in Obsidian.
- Recording: `recordings/living-colours.mp4` (18s). On Obsidian Home she moves Today, Lagoon ("night after a push day"), Kiln ("a cook evening"), Ember ("a bench best today") and back, each as a wet bloom that dries.

## The palette space
Six named palettes, from `soul-explore.md`. Each is three pigments for her three dabs (cool, warm, bright), in one set for light looks and one for dark looks.

| Palette | Light looks (Porcelain, Plein, Celadon) | Dark looks (Obsidian, Lacquer) | Feels like |
|---|---|---|---|
| **Today** | the look's own `tess`, `live`, `now` | the same | her own colours, the app's moment colours |
| Kiln | #2F3C9E #C4553B #D79A2B | #7C8BF2 #EB7A5C #E9B14E | warm, earthen, evening |
| Lagoon | #0E8C86 #F0624D #EDB730 | #4FD8CF #FF8A75 #FFD563 | fresh, cool, morning |
| Orchard | #6E3A8E #E2557A #F29A5B | #C39BFF #FF86A6 #FFBC86 | soft, quiet, a rest day |
| Aurora | #2F6FE0 #14A37F #8C5BD6 | #7FB0FF #4FE0B5 #BC97FF | cool, clear, late night |
| Ember | #3433D6 #D6266E #F2B21B | #9A98FF #FF5C9A #FFD24A | bright, lit, a best |

- **Today is the resting default and the fallback.** It's the look's own pigments (after item 43 these differ per look), so with nothing ever picked she is exactly what she is now.
- The dabs keep their shape, their 65% spread, their blur and the look's blend (multiply on light, screen on dark). Only the three pigments change.

## The nudges (what Claude or the rules may do inside a palette)
| Nudge | Range | What it does |
|---|---|---|
| `warmth` | −0.2 to +0.2 | Rotates all three hues together, up to 12° toward warm (+) or cool (−). Never past the next palette's hues |
| `weight` | −0.2 to +0.2 | Lifts (+) or lowers (−) lightness by up to 6 L, and chroma by up to 10%, on all three together |

- **Bounds the phone enforces after a nudge:** on light looks each pigment stays between L 35 and L 62; on dark looks between L 62 and L 86; chroma never under 40% of the palette's own. Anything outside is clamped, never refused.
- No nudge moves one dab alone, and none touches her resting opacity (the look's rest tint).

## What fits when (Design's guide for the rule table)
The picker should read like weather, not a mood ring: slow, plausible, never a comment on him.
| Signal | Lean |
|---|---|
| Morning (04:00 to 11:00) | Lagoon or Aurora, weight +0.1 |
| Midday | Today |
| Evening (18:00 on) | Kiln, warmth +0.1 |
| Late night | Aurora, weight −0.1, carried by the 04:00 turnover (see the addendum) |
| A rest day | Orchard |
| A record today | Ember, for the rest of the day |
| A cook day (a planned recipe) | Kiln |
| A look change | Today on the new look, then the day's pick after 2 h |
| Autumn and winter | warmth +0.05 on whatever's picked; spring and summer −0.05 |

Ember and Orchard are the two that mean something; the rest are time of day. Nothing ever reads as "behind", "missed" or "late".

## Cadence
- **At most three changes a day,** and never within two hours of the last. The 04:00 turnover is one; a change of kind in the day (first workout finished, evening, a look change) may be another.
- **Only when she's idle:** no capture, ask, ghost row, workout set, cook step or UNDO in flight; never in a live workout; never in quiet hours (23:00 to 07:00) except at the 04:00 turnover.
- **And never while something is drying:** a repaint waits for the end of any `Theme.Motion.dry` in flight (the done fleck on the day label, a hero that just changed), so two arrivals never share a moment (seam 2 of `day-reel.md`).
- A pick made while she's busy waits for idle. If she's not idle within 30 minutes it's dropped, and the next moment picks again.
- Claude's once-a-day pick, if any, replaces the 04:00 pick for the day; later changes that day come from the rules inside Claude's palette.

## How a change arrives
Not a crossfade. The new colour arrives as paint, through her own dabs:
1. Each dab, 120ms after the last (cool, warm, bright), **pools its new pigment from its centre outward** (a radial reveal to the edge, 900ms, house curve).
2. While it pools the dab is wet: it swells to 1.12 and brightens by a third, then **dries back** to its size and the rest tint over 2.8s in all.
3. No haptic, no line from Tess, no sound. The blur doesn't change. Her halo (dark looks) takes the new pigments as each dab dries.
- Reduce Motion: a 600ms crossfade of the three pigments.
- Done, UNDO, Cobalt sky on the Lock Screen, the Dynamic Island, the icon, and her voice colour (`tess` as text) never follow. Done's own colour and motion stay fixed.

## Fallback
Offline, at the spend cap, switch off, the demo, a late or bad reply, an unknown name: nothing visible happens. She stays on the palette she's on, or Today if none was ever picked. `-theme` and `-demoTime` recordings pin Today.

## Settings
Nothing new. The "Tess asks Claude: yes." line in Settings › Claude already covers Claude's pick (`settings-place.md`). If he wants her to stop changing, that's a one-line ask for later ("keep her colours"), not a control now.

## For Builder A and Core
- Builder A: `SoulPalette.look(_:living:)` resolves the palette name and nudges to three pigments for the look, with the clamps; `TessSoul` gets a `repaint(to:)` that runs the pooling bloom per dab; the idle gate reads `TessSoul.Mode` and the process table.
- Core: the rule table from the "What fits when" guide, the cadence gate, the `LivingPalette` store (name, warmth, weight, chosenAt, by rules or Claude), and the contrast clamp.
- AI thread: the `proposeSoul` tool returns only names from the table above and nudges in range.

## Owners
- **Core:** the rules, cadence and store. **Builder A:** the pigments and the bloom. **AI architecture:** Claude's pick.

## Addendum (16 Oct, 12:50 AM PT): Research's four conflicts, settled
Research read this sheet against what the phone knows (`research/living-colours-learning.md`). The answers, so the sheet and the brief agree:
- **K1, the late lean inside quiet hours.** The 04:00 turnover carries it: the turnover's pick is Aurora at weight −0.1, and the morning lean (Lagoon or Aurora, +0.1) arrives at his first write of the day, which is past the two-hour gap by then. Nothing is picked between 23:00 and 04:00.
- **K2, bloom or crossfade.** The bloom, as this sheet draws it. `architecture.md` section 9's crossfade is the Reduce Motion case only.
- **K3, when leans collide.** A best beats a rest day beats a cook day beats the time of day. A best holds for the rest of the day as before.
- **K5, three changes spent before evening.** One of the three is held for the evening lean. The turnover is the first; the day's one event (a best, a cook, a rest day, a look change) is the second; evening is the third. A second event in a day waits for tomorrow.
- Also taken from Research: morning starts at his median first write, evening at his usual training slot, late night at his median last write; the same palette three days running flips to the other lean for that time; a FORGET on a palette keeps it off for 30 days; Claude picks only among the rules' candidates, so it can't paint Ember without a best.

## Addendum, Oct 16, from the motion lab's item 7 clips
- **The wet lift is 20%** (the lab's value stands; a third blows three screened washes out to white on dark looks).
- **On dark looks only the mid alpha lifts while wet; the core alpha never does.** Three screened cores already meet near white where the dabs overlap, so a lift there only adds white. On light looks (multiply) both lift, as the lab has it.
- **Kiln's dark pigments deepen by about 8%** (the table above: `#7C8BF2 #EB7A5C #E9B14E`, was `#8E9BFF #F08A6E #F2C062`), because the lacquer clip showed the pool reading pale at its wettest even at 20%: the fault was the pigments' lightness, not the lift. Orchard stays; its plum carries enough depth. Builder A: `SoulPalette` table.
