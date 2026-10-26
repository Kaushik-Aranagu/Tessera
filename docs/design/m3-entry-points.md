# The two M3 doors, in place on Today (Design item 26)

The weigh-in and the Habits word, drawn where he'll meet them: on Today, on the build's own Home frame (tabs, day label, day stroke, context line, hero, `day-seams.md` S2). Copy is from Research's `m3-lines.md`; the pages behind both doors are in `body-weight-and-habits.md`. This sheet only adds how each door looks and moves on Today.
- Board: `mockups/m3-entry-points.png` (source `studies/m3-entry-points.html`), Porcelain, Friday 07:12. It shows three phones: the waiting weigh-in, after it's kept, and Habits.
- Recording: `recordings/m3-entry-points.mp4` (14.6s, 60fps). He writes "78.6" to Tess, the ghost waits at the top of Next, a tap keeps it and it lands on the day stroke, then the Habits word zooms into the page.

## 1 · The weigh-in on Today
**A bare weight written to Tess** ("78.6", from 30 to 250, nothing running) can't be sure it's body weight, so it waits for a tap (`body-weight-and-habits.md` §1).
- **Where it waits:** the capture closes back into the soul, and the ghost sets in as **the first row of Next** (blur 3 → 0, 8pt drop, settle spring, 420ms). The rows under it move down one place, 46pt.
  - It's a Now ghost row (`no-dots.md`): Body 21 in wet cobalt, breathing 0.5 ↔ 0.66, with no dab and no time. It reads "Body weight **78.6** kg?", with the number as a 600 value word.
  - When the weight is more than 3 kg off the trend, a label sits under it: "4.2 KG ABOVE TREND".
  - Tess says "Tap to keep it." beside the soul.
- **From any other page,** the capture closes onto Today (Home pages there along x), so the ghost is in view. On the Body weight page itself, the ghost waits on that page instead, as its sheet says.
- **Tap the row** to keep it:
  1. Its words dry from cobalt into ink, left to right (700ms clip sweep, house curve), as any accepted ghost does.
  2. Then the row lifts toward **now on the day stroke**, shrinking and blurring (620ms, house curve), the way a fling to TOMORROW flies (`today-on-home.md`). The rows close up under it (settle spring).
  3. **The moment:** a sage mark (3 × 14pt, `health`) lands on the stroke at the weigh-in's time, wet at 100%. It dries to the rest tint over `Theme.Motion.dry`. It's data, so it stays for the day (`sweep-19.md`, day-strip row). A second weigh-in the same day moves the mark rather than adding one.
  4. Tess says "Body weight logged. 78.6 kg." with **UNDO** (4s) under it, beside the soul. UNDO says "Body weight taken back.", the mark drains, and nothing comes back into Next.
  - `.impact(.light)` on the landing, as the sheet has it.
- **Tap the value word** to open the weight dial at 78.6 and fix a typo first.
- **Swipe the row away** to drop it. Nothing is written, and Tess says nothing.
- **"bw 78.6", "weighed 78.6" or "78.6 kg"** are clear. They commit from the capture with the usual 2s drying line, and the same mark lands on the stroke as the capture folds away. No ghost.
- **In a workout,** a bare number never becomes body weight (S701). Only "bw 78.6" does.
- **Reduce Motion:** the ghost fades in, the dry is a crossfade, and the row fades out while the mark fades in.

## 2 · The Habits word on Today's foot line
- **Today gains a foot line,** like Review's and Kitchen's: `HomeLinkLine(links: [.habits])`, with **Habits** at Body 21/600 `ink`, at x 22, y 700. That's above Tess's band (about 740 to 820), so her lines never sit on it. The queue window ends above it.
- `HomeLink` gains `.habits` (title "Habits", destination the Habits page).
- **Tap:** the ink line draws under the word (150ms). Then Today lifts away (scale 1.06, blur 3pt, fade, 380ms), and the Habits page grows from the word (scale 0.94 → 1 from its centre, 420ms, 60ms later), as Settings does from its word.
- **The page** is `body-weight-and-habits.md` §2 and §2a, with **‹ TODAY** as its back word (`back-word.md` row 24). Back closes into the word.
- **No count on the word.** "Habits" never reads "Habits · 2 of 5" or turns a colour on Today. The counts live on the page and in Review's week line.
- **With no habits yet** the word still shows, and the page opens on its empty state ("No habits yet.", `empty-states.md`).

## Owners
- **Builder B:** the weigh-in ghost row at the top of Next, its keep, drop and fly-to-stroke, the sage mark on the day stroke (`Features/Home/NowPage.swift`, `DayStrip.swift`), the capture closing onto Today, and Today's foot line with `.habits` (`HomeSpatialView.swift:164` for the pattern, `HomeLink` at `:199`).
- **Core:** `BodyWeight` writes, the bare-number rule, the ghost's pending state (`TessCapture.asking`), and the mark's time for `DayLine`.
- **Research:** check that "Tap to keep it." and "Body weight taken back." are still `m3-lines.md`'s lines, and whether any extra line is needed when the capture closes onto Today from another page. The default here is none.
