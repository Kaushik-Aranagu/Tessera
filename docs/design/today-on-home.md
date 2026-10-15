# Today on Home (M2 slices 8 and 9): Next, Later, swipes and the finish moment

For iOS Builder B. Layout and paint stay as in `home-v1.md`; this note adds the **Next** stack, the row gestures and the finish moment, with exact motion. Recording: `recordings/today-on-home.mp4` (source: `studies/today-on-home.html`, plays in any browser).

## The queue window: Next, then Later, in one bounded surface
- The old Later block becomes **the queue**. It's one window, 22pt side insets, from **y 540 to 736** (y 616 to 736 under a ledger row). It's the only thing on TODAY that scrolls on y, with a snap per 48pt row and a 40pt fade at the bottom.
- **A pinned heading** sits at the top of the window: one word at Title 34/500, 40pt tall. Rows scroll under its bottom edge, not under the word.
- **Next** is the first up to 3 items after Now, in NowPicker order. Rows are 48pt: dab (18×15, area colour), name at 21/**500**, time in labels on the right. Ink steps down by position: 100%, 88%, 76%.
- **Later** follows after a 24pt gap, with its own word "Later" in the flow at 34/500. It holds the rest of today (with times) and then undated items (no time). Rows are 21/**400** at 62%.
- **The heading rolls.** When the in-flow "Later" word reaches the pinned heading, the pinned word rolls from Next to Later: the old word goes up 14pt and fades, and the new one comes up from 14pt below, both 260ms on the house curve. The in-flow word fades as it arrives, so you never see two. Scrolling back rolls it the other way. This is how you know where you are in the queue without a second header.
- If there's nothing in Next, the heading reads Later from the start. If the queue is empty, the window holds one line at 21/400 in context colour: "Nothing else today." No illustration.
- **Refill:** when a Next row leaves, the rows below move up one slot (420ms, house spring), and the next item rises into the third slot from 60pt below, fading in. The queue visibly feeds itself.

## Swipe right: done (the strike follows your finger)
- The ink strike (`StrikeRenderer`, 3pt, ink 85%, a slight wave) draws across the name **as you drag**: progress = drag distance / 250pt. The row's content leans 10pt right with it.
- **Threshold 40%** (100pt). Crossing it fires `.selection` once (armed). Dragging back under it un-arms it with no haptic.
- **Release past threshold:** the strike runs out to the end (180ms), the name dims to 45%, and **the finish haptic** fires (slice 9, below). Release under threshold: the strike retracts (220ms ease-out) and nothing happens.
- **Fold:** the struck row stays on screen for 600ms so you see it done, then fades out (280ms) while the queue closes up and refills.
- Tess blooms `done` and her bar says "Done. Call the dentist." with **Undo** in vermilion for 4s.
- **Undo:** the row comes back into its slot (420ms), the strike un-paints right to left (420ms), and `.decrease` plays.

## Swipe left: not now (the row goes where it's going)
- The content follows the finger 1:1 to 150pt, then rubber-bands at 35%.
- **The destination word** sits in the track on the right, in labels at full ink, and rises in only once the row has slid clear of it (from 110pt, over 20pt of travel). **120pt is the commit threshold**, with `.selection` when crossed.
  - A Next row, or any dated row, says **TOMORROW**. A Later row with no date says **NEXT WEEK**.
- **Release past threshold, TOMORROW:** the row's dab lifts out and **flies to the end of the day stroke** (tomorrow lives to the right on the day lane): an arc over 620ms `cubic(.5,0,.2,1)`, scaling 1 → 1.3 → 0.7. When it lands, a soft amber bloom flashes at the stroke's right end (700ms). The rest of the row fades (200ms) and the queue closes up. `.impact(weight: .light)` when it lands.
- **NEXT WEEK:** the row fades and the queue closes up, with the same light impact. No flight (there's nothing on screen for next week).
- Tess's bar says "Moved to tomorrow." with Undo for 4s. Undo is the flight in reverse, then the row slides back into its slot.
- Edge swipes still page Home (`home-v1.md`, nested scrolling): a row gesture only starts more than 24pt from either screen edge and after 12pt of mostly horizontal travel.

## Now: finishing and promotion (slice 9's finish moment)
Now keeps **Hold to finish** (700ms of paint, as specified); the hero itself has no swipe, so x on the hero always belongs to the page.
1. **Commit** (the hold completes): **the finish haptic** fires.
2. **The strike** runs across each hero line in turn: 5pt, ink 85%, 240ms per line, `cubic(.3,.7,.2,1)`. The key's paint drains (220ms).
3. **Lift:** the struck hero goes up 14pt, blurs to 4pt and fades (260ms, ease in).
4. **Promotion:** the first Next row's name **rises into the hero** with matched geometry, from its row (21/500) to the hero slot (56/500, −4% tracking), in 460ms on the house curve. It uses `matchedGeometryEffect` plus a font-size interpolation (`Font.system(size:)` driven by an animatable value, or `.scaleEffect` on a 56pt rendering, whichever stays crisp). The rest of the queue moves up and refills at the same time.
5. The Now line and the key's meta crossfade to the new item's ("next, by half four", "DUE / 16:30"), with the Now line entering 12pt from the right. Tess says "Done. Next one is up."

This replaces `home-v1.md`'s "enters from the right" for the hero: the next thing comes **up from the queue** (y is sequence).

### The finish haptic (one per meaning, `live-polish.md` map)
- **Task finished:** `.impact(weight: .medium, intensity: 0.8)`, fired at the commit moment, whether that's the hold completing or the release past threshold. It's softer than the set stamp (heavy 0.9), which keeps the workout's clunk special.
- Armed: `.selection`. Moved away: `.impact(weight: .light)`. Undo: `.decrease`.
- No `.success` on Home; it stays reserved for finishing a workout.

### Rolls happen silently
Overnight roll-forward (M2 slice 2) has no motion and no marker. Rolled items just sit in today's queue in order. No "from Tuesday", no counts.

## Reduce Motion
- The strike still draws (it's the information), but on release it appears whole in a 150ms fade. A swipe-right row fades out without the 600ms hold.
- Tomorrow: no flight. The row fades and the stroke's end does a 200ms brightness pulse.
- Promotion: crossfade the hero (200ms); no size morph. The heading roll is a crossfade.
- Every haptic stays.

## Accessibility
- Each row exposes two actions, **Done** and **Not now** (`accessibilityAction(named:)`), and the hero keeps "Finish" on the key. VoiceOver never needs a swipe.
- At large Dynamic Type sizes the queue shows fewer rows rather than smaller text. Next can show 1 row; the heading and window keep their positions.
