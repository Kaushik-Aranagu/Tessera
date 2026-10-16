# The v9 pin, one walk against its sheets (Design item 66)

**Kaushik's principle, in one line:** the build he installs looks like the sheets he approved; one walk through its screens, recorded, says whether it does before the install.

Rewritten Oct 16, 12:55 PM PT, for the Catalog v9 pin. It replaces the 9233ca9 brief, which was written against 37aa05c, before #366, #381, #422, #453 and the privacy walls. Design can't run the app from the cloud. This is the brief Builder A records from, and the pass Design holds the clip to.

## The recording
- **Build:** the pin SHA Product names, in the Simulator, iPhone 17. The launch flags are `-demoTime 18:10 -resetDemo -theme porcelain`, with the memory fixture from `tess-knows.md` (49).
- **Clip:** Porcelain, 60 fps, about 3 minutes, one take with no cuts. Name it `docs/recordings/next-build-walk-v9.mp4`. It ends inside the app, on Home. Name the SHA in the PR or message that carries the clip.
- **Holds:** hold each resting screen for 2 s before the gesture, and for 1.5 s after a line dries. Don't scroll faster than a thumb.
- **No real data:** never use his Claude key. The key beat uses the test fixture's fake key-shaped string.
- **The cover:** Builder B's recorder shows the springboard while #381's live-workout cover is up, and Builder A's doesn't. Record on Builder A's setup.

## The beats, in order
| # | Time | What to record | Sheet | Passes when |
|---|---|---|---|---|
| 1 | 0:00 to 0:12 | Home at rest at 18:10: the day label, context line, hero, the Next rows and Tess's band line | 41, `home-lines.md`, 62 | One plain line per thing, nothing cut (no "…"), times as "7 pm", nothing in the band but Tess's line |
| 2 | 0:12 to 0:30 | Tap TRAINING, then TODAY. Hold the tab row until the lens forms, slide across REVIEW and KITCHEN, and let go on TRAINING. Then hold with no slide, to show the cancel | 42 | Pages shrink to 78% with neighbours live at 55%, the lens melts into the ink line, and Tess stays full size over the ground |
| 3 | 0:30 to 1:05 | Training at rest, then START. Log set 1 by holding LOG, skip the rest, then go back to Home and return to the workout | 44, 56 | START wakes the page and the plan sinks. The workout grows from its first exercise with "Push A, set 1 of 4" on top and LOG on the key. "Rest skipped. Set 2 is up." Home names the running workout in one line |
| 4 | 1:05 to 1:15 | FINISH HERE, the done screen, then Home | 56, 62 | The done line names the workout first, there's one Done with its one haptic, and Home shows the day without the hero hiding it |
| 5 | 1:15 to 1:40 | ROUTINES: open a routine (‹ TRAINING). Switch to FIXED DAYS and give Push A Monday ("Push A on Mondays." with UNDO). Drag one routine to reorder, swipe left to DROP and UNDO it, then edge-swipe back | 44, `back-word.md` | The back word sits at 58, receipts name the thing first, UNDO reverts exactly what the line names, and the edge swipe goes back |
| 6 | 1:40 to 2:00 | Review: the week, the three bands and the week's lines. Tap a day, then tap it again | 46 | The hero is the count alone on one line, the bands read TRAINING 3 OF 6 / TASKS DONE 14 / COOK 2 OF 4 with no dot, and the lines say "a best", never "record" |
| 7 | 2:00 to 2:20 | Notes: type "wifi password is tacocat4417", then paste the fake key-shaped string on the writing line | 57, #422, #471 | "Private note, kept." The row reads "Private note", and the key is refused with the key line in cobalt |
| 8 | 2:20 to 2:35 | Kitchen: a recipe's ingredients to Groceries, then a pasted recipe that ends with a wifi line | 47, #454 | Pack sizes kept (" · 15 oz"), staples skipped with the receipt naming the thing first, and the wifi line in tertiary ink as ignored |
| 9 | 2:35 to 3:00 | Review's LOOK: Porcelain → Plein → Celadon → Lacquer → Obsidian → Porcelain, then the tab back to Home | 43, 48 | Each look floods from the soul, each ground and `tess` matches 43's tables, and the clip ends on Porcelain Home |

The Claude cap ($50) and Tess working aren't walked. #422 and #453 each passed on their own clip, and working needs a Claude call that demo mode refuses.

## What Design checks, frame by frame
- **Frame:** the top of every page is its sheet's (back word at 58, Title 44 at 84, context at 146; Home's day label at 138, context at 186, hero at 220). Nothing sits in Tess's band (736 to 820) but her line and UNDO.
- **Words:** each line matches `copy-pass.md`'s "Now" column (digits, "6 pm", "Oct 12", receipts thing first, "best" never "record").
- **Marks:** no dots, seams or hairlines between rows. Nothing is coloured at rest but the context line, Tess and the data marks.
- **Motion:** the house curve and the settle spring where the sheets name them. Moments land wet and dry over 2 s. Haptics are QA's log, not the clip.
- **Ending:** inside the app.

## PASS, FIX FIRST and known rows
- **FIX FIRST** means something on a sheet in this pin is drawn wrong: a covered word, something in Tess's band, a stock control on a live surface, a receipt naming the wrong thing, a crash, or a blank page. FIX FIRST rows go to the owning builder before the install.
- **Known rows** are already on the boards, so they never fail the walk; Design lists any it sees as follow-ups. They are:
  - the 25 findings in `audit-ui-bar.md` (for example R1 "Done. Next one is up.", D1's spelled times on Now, S1 "HOLD · 24 MIN LEFT");
  - H1, a paused workout's context reading "now";
  - the paste screen's spelled counts and the doubled step number;
  - LOOK and the Claude section still in Review, until the Settings page moves them (sheet 16).
- **Design answers** PASS or FIX FIRST with the pin SHA, one line per beat, as soon as the clip lands.

## Owners
- **Builder A:** after the v9 gate (M0 to M4) passes on the pin, record the walk on the pin.
- **Design:** the pass.
- **QA:** the haptic and frame-rate rows, which stay in `next-build-script-v9.md`. This walk is the visual pass only.

## Daily pins: the short walk (from Oct 16, 4 pm pin)

Kaushik, 2:46 PM Oct 16: he wants what Design draws on his phone as soon as it works. A pin is named at 4 pm each day something he can see has landed, and this walk gates it. It covers only what's new since the build on his phone, so it stays short. The full walk above is for catalog pins only.

- **Recording:** same build rules as above (pin SHA, iPhone 17, Porcelain, 60 fps, one take). Launch flags `-demoTime 18:10 -resetDemo -freshDay -theme porcelain`. About 60 to 90 s. Name it `docs/recordings/pin-walk-<MMDD>.mp4` and put the SHA in the message that carries it.
- **Beats:** one per merged PR he can see, in the order he'd meet them, ending on Home. Pure engine or wall changes that already passed with tests aren't walked; list them in the message instead.
- **Verdict:** Design answers PASS or FIX FIRST on the SHA within the hour. Known rows never fail it.

### Oct 16, 4 pm pin (new since a36b161)
| # | What to record | PR, sheet | Passes when |
|---|---|---|---|
| 1 | Cold launch onto Home and hold 5 s | #558, #403, motion picks idea 2 | Her eyes stay shut for 1 s, open, she stretches once and blinks once, all inside the band. Nothing else on Home moves |
| 2 | Home at rest with the plan offered (18:10 is inside its 8 am to 9 pm window) | #529, 53, #507 | The hero is digits ("3 tasks"), the context reads "from 8 am", and every time looks like "7 pm" |
| 3 | Skip one proposed row, then UNDO; then keep the plan | #529, 53 | The receipt names the row first, UNDO puts back exactly that row, and keeping it turns the plan into Home's day with one haptic |
| 4 | TRAINING, ROUTINES: give Push A Monday, drop a routine and UNDO it, then edge-swipe back | #547 | "Push A on Mondays." and "Pull A, dropped." name the thing first, and UNDO restores it |
| 5 | START, swap an exercise in the swap panel, log one set, then FINISH HERE | #547, 56 | The swap receipt names the new exercise first. Her eyes never hide (nothing here asks Claude) |
| 6 | REVIEW: the week's lines | #504 | A best reads "best", never "record" |
| 7 | NOTES: scroll the list past the fixture's private note and stop on Home | #508, #551 | The row reads "Private note" and nothing else on the page names its words |

Not walked, covered by their tests: #534 (Siri and Lock Screen privacy), #512 (receipt text in the engine), #548 (key-guard comment). Nothing secret-shaped is typed into the simulator.
