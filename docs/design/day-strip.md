# The day strip (M2 slices 11 and 13): tasks on the stroke, the now marker, and "full"

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

For iOS Builder B. The day strip is Home's **day stroke** (`home-v1.md`, item 1): one watercolour brushstroke from morning to night, painted up to now, with a dashed ink guide for the rest of the day. These two slices put things on it and let it say when the day is full. M4's calendar events use the same marks (`m4-steers.md`, Plan my day).

Recording: `recordings/day-strip.mp4` (source `studies/day-strip.html`): the tip sliding and a done item soaking, tapping a dab, the day filling to "full", and Make room reopening the gaps.

## What sits on the stroke (slice 11)
- **x is the clock** across the stroke's 342pt, from the day's start (07:00, or the first item if earlier) to its end (23:00, or the last item if later).
- **A timed task** is a dab in its area colour (14×12, the dab shape, blurred 0.4pt) sitting **on the stroke's centre line** at its time.
- **The workout** is a short segment, not a dab: 6pt tall, round caps, vermilion at 85%, as long as its planned duration (60 min ≈ 21pt), laid over the stroke.
- **Calendar events** (M4) are ink segments at 55% in the same way, so busy time reads as marks on the line.
- **When it's past:** a finished item is **painted over**. As the stroke grows past it, the dab soaks into the stroke and is gone (its colour tints the stroke there for the rest of the day). An unfinished past item stays as a faint dab at 40%. Never red, and never counted.
- **Crowding:** items closer than 10pt stack vertically like layered paint (each 5pt higher than the last, at most 3). Past 3, the rest hide under the top one.
- **Tap a dab:** the label above the stroke changes for 2.5s to that item ("Call the dentist, 15:40"), with a 160ms crossfade and `.selection`. Tapping the label while it shows zooms into the object. The x lane of the stroke (swipe for yesterday and tomorrow) still works; a tap isn't a swipe.

## The now marker
- It's the **wet amber tip** that already breathes at now. It moves for real: its x comes from the clock through a `TimelineView(.periodic(from: .now, by: 60))`, with a 600ms linear slide each minute, and the painted stroke grows to it at the same time.
- When the tip reaches a dab, the soak happens: if the item is done, the dab blurs out into the stroke (400ms). If it isn't, nothing happens (it'll fade to 40% once the tip has passed it).
- When it reaches a timed task's time, that task becomes Now through the NowPicker (as specified), with the promotion motion from `today-on-home.md`.

## "Full" (slice 13): the gaps are your slack
The dashed guide for the rest of the day is drawn from **free time**: the gaps between dashes are free minutes.
- **As the day fills,** the dash gaps close where time is booked (the dash is solid ink at 22% across planned spans), so a busy afternoon reads as a nearly solid line. You can see your slack before anything says so.
- **Over capacity:** the whole guide past now becomes solid, and the day label reads "**Thursday, full**" (21/400, ink, no colour change). At the right end of the label line sits one text control: **Make room** (21/600, ink). The colour stays neutral: no red and no amber warning.
- **Make room:** the items the engine would move (slice 7's list) get a cobalt wash in the queue window, and Ask Tess shows a ghost line in cobalt, "Moving 2 to Later", with the 2s drying stroke under it (the capture grammar). When it commits, their dabs lift off the stroke and drop down into Later (y: they go later in the sequence), the queue closes up, and the **gaps open back up in the guide** (the dashes re-space over 600ms). That's the living moment: you watch your slack come back. Undo for 4s.
- Tap the ghost line to commit early, or swipe it away to keep the day as is (then "full" stays, and Make room stays available).

## Reduce Motion
The soak becomes a 200ms fade, the tip jumps per minute without the slide, and the dashes re-space with a crossfade. Every haptic stays.
