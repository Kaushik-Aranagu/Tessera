# What's new (Design item 68)

For: the next install message. Owner: Design. Clip: `recordings/whats-new.mp4` (52.8 s, 450 × 1076, 30 fps, no sound).

One clip, eleven things, in the order he reviewed them on Oct 15 at 11:58 PM: Home, tabs, routines by day, Training plan first, Field 18, Review week, the icon, Return, the looks recut, then what Tess knows and trip zones. Each thing gets a caption bar (Label 16/700 on the board grey, "3 OF 11" at the right) over the screen it changes, cut from the builders' own recordings on master where one exists, from Design's recordings where not, and drawn as a frame in the house grammar for the two with nothing to show (the icon, trip zones). It opens on a "What's new" card and ends inside the app's grammar, on a Day log frame.

## The cut
| # | Caption | Source | In to out | Length |
|---|---|---|---|---|
| open | "What's new", next build | card, `studies/whats-new-cards.html?k=open` | | 1.8 s |
| 1 | Home, one plain line | Design `recordings/looks-flood.mp4` at rest (one still, 0.3 s) | still | 2.4 s |
| 2 | Tabs | master `docs/recordings/39-tab-lens.mp4` | 0.8 to 6.8 | 6.0 s |
| 3 | Routines by day | master `docs/recordings/42-routines-fixed-days.mp4` | 1.0 to 8.0 | 7.0 s |
| 4 | Training, plan first | master `docs/recordings/40-training-rise.mp4` (the plan page, START to PAUSE to RESUME), then `docs/recordings/44-live-workout-frame.mp4` (#381: set 1, the stamp, "Set 1 logged. 82.5 × 7.", the rest starting) | 0 to 2.9, then 1.6 to 4.6 | 5.9 s |
| 5 | Field 18, for your typing | master `docs/recordings/field-18.mp4` ("Call the bank at 4" to "Call the bank, tomorrow 4 pm.") | 4.0 to 9.5 | 5.5 s |
| 6 | Review, the week | master `docs/recordings/review-week.mp4` | 0 to 4.0 | 4.0 s |
| 7 | The icon | card: `AppIcon` 1024 at 236 pt, "Today's colours, drawn by the system." | | 2.2 s |
| 8 | Return | master `docs/recordings/return.mp4`: leaving with the receipt up, then back to "Hold me to talk." | 1.5 to 3.5, then 11.6 to 13.3 | 3.7 s |
| 9 | The looks, recut | Design `recordings/looks-flood.mp4` (Porcelain, Plein, Obsidian, Lacquer floods) | 3.0 to 10.0 | 7.0 s |
| 10 | What Tess knows | Design `recordings/tess-knows-v2.mp4` ("remember that I rest on Sundays", "Kept. You rest on Sundays.") | 5.0 to 9.6 | 4.6 s |
| 11 | Trip zones | card: a Day log frame, "Wednesday, in New York", "6:30 AM THERE", "A moment files under the day where you were, not the night before at home." | | 2.8 s |

Builder clips (590 × 1282) scale to 450 × 978 under the 98 pt caption; Design clips lose their own caption (crop from 84) and sit on the board grey. Hard cuts, no fades: each caption is the cut.

## To recut before it goes out
- **1 Home** is Design's frame, not the build. When #366 (Home one plain line) lands, replace the still with 2.4 s of Builder B's clip at rest, same caption.
- **4 Training** took set 1 from #381's clip once it merged (c17ca66); the old workout page in `40-training-rise.mp4` stays out.
- Anything else that reaches the build after this cut gets a row here and a segment at its place in his order.

## Rebuild
Captions and cards render from `studies/whats-new-cards.html` (`?k=cap&i=N`, `?k=open`, `?k=icon`, `?k=trip`; `whats-new-appicon.png` beside it is the 1024 icon from `Resources/Assets.xcassets`). Segments are ffmpeg `vstack` of the caption over the scaled clip, then a concat; the in and out points above are the whole edit.
