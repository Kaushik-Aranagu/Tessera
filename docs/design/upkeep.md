# Upkeep: a chore on Now, the Upkeep page, the chore page (M5 screens 7, 6 and 5, steer)

For Builder B, after Core's `Chore`, `UpkeepLedger` and the NowPicker chore rule (ship-list-m5-upkeep slices 1 to 3). It is drawn to `no-buttons.md`. Recording: `recordings/upkeep.mp4` (source `studies/upkeep.html`).

Shared: **chores never run, so there's no vermilion,** and cobalt is only for Tess. Never red, never a filling bar. Age is words in tabular figures, and staleness shows only as position and ink weight.

## 7 · A chore on Now
- **It arrives in grey (`#8E8798`), never vermilion:** the name at Hero 56, and "6 days, usually 7" in Body, also grey.
- **It slides in from below the Next list** when it crosses its interval (440ms, house curve). From twice its interval it steps above the untimed tasks, by the same slide.
- **Hold to log it done (0.6s):** the grey fills to full ink left to right, like the stroke word's repaint. Then the slot drops 30pt and fades, and the next Now rises in its place. There's no celebration, and `.impact(medium, 0.8)` plays. Tess says "Watered plants." with UNDO.
- **Flick down** snoozes it to tomorrow: it slides down out of the slot, and Tess says "Plants tomorrow."

## 6 · The Upkeep page (height is staleness)
- **Label:** UPKEEP. A **NOW** label (16/700, ink) sits on a hairline at the top (1pt at 40% ink, y 156).
- **One column of chore names** at 28/500, each followed by its age as a label ("13 D", "TODAY").
  - **Vertical position is staleness** (age ÷ interval): 0 sits at the foot (y 640) and 1 sits just under the hairline (y 190). Past 1, chores stack under the hairline in staleness order.
  - **Ink follows height:** 28% at the foot rising to full ink at the hairline.
- **Arrival:** the names rise 40pt into their heights (560ms, 50ms stagger).
- **Hold a name (0.6s)** to log it done: its ink turns sage as it fills, then it **sinks to the foot on the settle spring** `cubic-bezier(.3,1.3,.5,1)` over 760ms, fading to the foot's pale ink. A chore already at the foot moves up 40pt to make room. Tess says "Changed the bed sheets." with UNDO.
- **After a holiday** the whole column has risen together. Nothing turns red, and nothing is counted.
- **No interval yet:** a quiet footnote with the label "NO RHYTHM YET" and the names in one Body line ("Oil the bike chain · Smoke alarm").
- **Tapping the NOW hairline** shows the week line under it in Body: "3 chores this week".
- **New chore:** say it ("watered plants"). **Empty:** Tess says "Tell me what you just did. Try: watered plants."

## 5 · The chore page (tap a name)
- **Label:** UPKEEP. **Hero:** the name at 56 (two lines is fine).
- **Context line in Body:** "descaled 25 days ago · usually every 60".
- **The interval is a day drum,** the reps drum's sibling: "every" and "days" at 34 Light in the subdued colour around a 96 Light tabular drum (100pt rows, masked). A flick coasts and ticks per day. On release it writes `SetChoreInterval`, and Tess says "Descale the kettle, every 45 days." The context line follows live.
- **The rhythm, not a streak:** the label "THE LAST FEW TIMES", then one short 6pt rule per gap, whose length is the gap (1.6pt per day), at 55% ink. A fine check-in is drawn **hollow**, and the open gap since the last one is **dashed**. The day counts sit under the rules as one label line ("58 · 62 · 47 DAYS · NOW 25"). The rules draw in left to right (700ms).
- **Done is the verb as a stroke word** in sage ("Descaled"), held for 0.6s.
- **FINE** is a label word beside it (`ChoreFine`): the open gap closes as a hollow rule, the context line reads "looked today, fine", and Tess says "Kettle: looked, fine. Counting from today." It doesn't count toward the week.
- **One level deeper** (swipe up): the place, "Pause upkeep until…" as a value word that opens the date drum, and the links.

## Accessibility and Reduce Motion
- Each chore reads "Change the bed sheets, 13 days, usually every 14", with done and fine as actions. The column order for VoiceOver is stalest first.
- The day drum is adjustable: "Every 45 days".
- **Reduce Motion:** names fade to their heights instead of rising or sinking, the fill is instant, and the rhythm appears whole.
