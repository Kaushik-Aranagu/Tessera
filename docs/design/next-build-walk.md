# The next build's merged screens, one recording against their sheets (Design item 66)

**Kaushik's principle, in one line:** the build he installs looks like the sheets he approved; one walk through its screens, recorded, says whether it does before the pin.

Design cannot run the app from the cloud, so this is the recording brief for the iOS build thread (or Builder A) on the candidate, and the pass criteria Design holds the clip to. One clip, Simulator, Porcelain, 60 fps, about three minutes, `docs/recordings/next-build-walk.mp4`, ending inside the app. Design answers PASS or FIX FIRST per screen, naming the candidate's SHA.

## What the build carries that has a sheet (merged since 7b321d2, on master 37aa05c)
| # | PR | Sheet | Screens to walk |
|---|---|---|---|
| 1 | #342 Tab lens | `home-first-review.md` 42 | A plain tap between tabs; a swipe with the ink line stretching; hold the row until the lens forms, slide through REVIEW and KITCHEN with a tick per word, let go on TRAINING; a hold with no slide cancels |
| 2 | #347 Training rise, #359 routines on fixed days | `training-mode.md` 44 (with its addenda) | Training at rest with the plan line `PUSH PULL LEGS, ROLLS ON` and ROUTINES; a routine open with ‹ TRAINING; the editor with FIXED DAYS, a day picked ("Push A on Mondays." with UNDO), the handoff line when a day moves routines, DROP; the edge swipe back; leaving mid-START restores the page |
| 3 | #353 Field 18 | `settings-place.md` 50, `back-word.md` | Settings with the Claude key field at Field 18, ‹ SETTINGS as the back word on Receipts, the edge swipe back |
| 4 | #352 Review week | `review-week.md` 46 | Review with the hero as the count alone on one line, the bands (TRAINING 3 OF 6, TASKS DONE 14, COOK 2 OF 4 with no dot), the week's lines with "a best", a tapped day |
| 5 | #367 Looks recut | `looks-recut.md` 43 (sheet name as in README) | The look switch through Porcelain, Plein, Celadon, Obsidian, Lacquer: the flood from the soul, each look's ground and tokens, Tess's line in each look's `tess` |
| 6 | #356 Tess memory | `tess-knows.md` 49 | Settings' door "Tess remembers N things." / "Nothing yet."; the page; "remember that I rest on Sundays" landing; swipe to FORGET with the 10 s UNDO; FORGET EVERYTHING held |
| 7 | #369 Home lines (Core, through the lens) | `home-first-review.md` 41 rule 1, `copy-pass.md` | Home under a done hero with the clock alone ("7:40 pm"); a planned evening session as the hero ("Push A at 7 pm") with START; the closed day's widget line |

Not in the build and not walked: #366 Home (41), #381 the live workout (56), and sheets 59 to 65 (not built).

## The order and the holds
Walk 7 → 1 → 4 → 2 → 3 → 6 → 5, so the clip opens on Home and ends on a look landing. Hold each resting screen for 2 s before the gesture, and 1.5 s after a line dries. No cuts; the Simulator's `-demoTime 18:10 -resetDemo` seed, with the memory fixture from `tess-knows.md`.

## Pass criteria (what Design checks frame by frame)
- **Frame:** the top of every page is its sheet's (back word 58, Title 44 at 84, context 146; Home's day label 138, context 186, hero 220); nothing sits in Tess's band but her line and UNDO.
- **Words:** every line matches `copy-pass.md`'s "Now" column where the sheet was touched by 62 (digits, "6 pm", "Oct 12", receipts thing first, "best" never "record"). Older words still in the build are a FIX FIRST only where 62 names them; otherwise a follow-up row.
- **Marks:** no dots, no seams, no hairlines between rows; data marks (strokes, bands) at the rest tint; nothing coloured at rest but the context line and Tess.
- **Motion:** the house curve and the settle spring where the sheets say; moments land wet and dry 2 s; one haptic per moment (QA's log, not the clip).
- **Looks:** the five grounds and `tess` tokens as 43's tables (Design samples the clip's pixels).
- **Ending:** inside the app.

## Owners
- **iOS build thread / Builder A:** record the walk on the candidate once Product pins it; name the SHA in the PR that adds the clip.
- **Design:** the pass, one reply per screen; FIX FIRST rows go to the owning builder before the install.
- **QA:** the haptic and frame-rate rows stay in `next-build-script.md`; this walk is the visual pass only.
