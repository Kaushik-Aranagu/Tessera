# What reaches the Lock Screen (Design item 36)

This sheet covers everything Tessera puts on the Lock Screen and in the Island: three Live Activities and three local notifications, all in Tess's voice, with quiet hours, and with Cobalt sky for rest in every look. The words are Research's (`tess-voice.md` M49 to M58, `notifications.md`, `lockscreen-lines.md`) as they stand, and the faces follow `live-activity.md`. It supersedes `widget-states.md`'s "the Lock Screen face follows the look": every Live Activity stays Cobalt sky in every look, and the Island is always the system's black.
- Board: `mockups/lockscreen.png` (source `studies/lockscreen.html`), 10 panels. Rest (resting, Go with the rest notification, Always-On, after Done, after the last set), cooking with a timer ringing, a timed task pressed, quiet hours, a focus block, and the Island.
- Recording: `recordings/lockscreen.mp4` (17s). Rest counts down, Go pushes in while the sky warms and "Set 4 is up" arrives, a tap on the set logs it without unlocking ("Set 4 logged." with UNDO and the next rest), then UNDO says "Set 4 taken back.".

## The rules
- **One number, one action** on every face. Nothing below 16pt. Inter Tight bundled in the extension. No italics, no dots, no badges.
- **Cobalt sky** for all three activities: the system's Live Activity material with the cobalt wash top left and the violet wash top right, cream `#F6EFE4` type, and the 2.5pt cream horizon over a 1.5pt guide at 14%. Only the rest Go face warms (cadmium and vermilion), and only the rest tick is vermilion.
- **The words are Tess's**, one line each, under 12 words, naming the thing and then what happened. iOS prints "Tessera" over a notification; we never repeat it.
- **Nothing on the Lock Screen asks.** Asks live in the app (`one-ask.md`). The permission pre-asks (M49, M50) are in-app asks with ALLOW · NOT NOW, never a notification.
- **Activity updates are always silent.** Sound comes only from the three notifications.

## The rest Live Activity (Builder A)
| State | Left | Right column (the Done button) | Bottom row |
|---|---|---|---|
| **Resting** | The countdown, 48 Light, tabular, the colon at 55% | "Bench" 17/400 at 62%, "82.5 × 8" 24/400, the vermilion tick | "Rest, then set 4" · **+15** \| **Skip** |
| **Go** (rest is up, `staleDate`) | "Go" pushes in from below. The washes warm to cadmium and vermilion over 1.4s, and the line empties | The same, with a soft vermilion glow breathing behind the tick | "Rested 2:30" · +15 at 25% \| **Skip** |
| **Always-On** | "Ready at" over "18:12", still, with no ticking | The same, without washes | "Rest, then set 4" |
| **After Done** (a tap on the set, without unlocking) | The next rest, full | "Set 3 logged." Body 21 with **UNDO** in `liveInk` under it (the column is `UndoLastSet` until the rest ends) | "Rest, then set 4" |
| **UNDO tapped** | The rest it came from | "Set 3 taken back." for 2s, then the set again | As before |
| **After the last set**, 60s | "All 22 sets in." Title 34, "Push A, ready to finish" at 62% | none | ENDS IN A MINUTE, horizon full |

- **Rest-up alert:** when notifications are allowed, N2 rings and the activity stays silent. When they aren't, the activity's own alert plays once. Never both (decision 6:30 PM PT).
- **Live Activities off** (M52): "Live Activities are off. Rest shows here." in the app, once ever.

## The cook Live Activity (Builder A)
- **Left:** the lead timer's label in 17/400 at 62% ("Soften"), the countdown under it, and "+1" (or +N) at 21/600 for other running timers.
- **Right column:** the recipe at 17/400 at 62%, then **Stop** at 24/400. The column is `StopKitchenTimer` for the lead timer.
- **Bottom:** "Step 2 of 3". When the lead timer ends, the face flips to "Soften is done" with the horizon flared cadmium, and the next timer takes the lead. Stop clears the flare.
- Tapping elsewhere opens cook mode on this cook (`tessera://cook`).

## The focus block Live Activity (Builder A)
- **Left:** the task at 21/600 ("The deck outline"), with the time left in labels ("18:04 LEFT", `Text(timerInterval:)`).
- **Bottom:** "Focus, 25 min" · **Done**. No +15, no Skip.
- **Stale at the block's end + 15 min**, so a forgotten block leaves the Lock Screen by itself.
- **The halfway check-in never notifies.** "Still on the deck?" is an in-app ask only. This replaces m4-steers §8's "When the app is closed, a local notification asks the same", because a check-in is on Research's never-notify list.

## The three notifications (Core schedules, words from M54 to M58)
| | Title | Body | Long-press actions | On next open (Tess, with UNDO) |
|---|---|---|---|---|
| **N1, a timed task** | "Call mum" | "It's 9 am." or "It's 9 am. 30 min." | **Done** · **Not now** (moves to the same time tomorrow) | "Call mum done." or "Call mum moved to Saturday." UNDO: "Call mum taken back." |
| **N2, rest is up, app not on screen** | "Set 4 is up" | "Bench, 82.5 × 8" | none (the activity has the buttons) | none |
| **N3, a kitchen timer** | "Pasta is done" | "Carbonara, step 3", or "10 min." with no cook | **Stop** | "Pasta stopped." UNDO: "Pasta taken back." |

- The actions are system menu rows, drawn by iOS. We never add a content extension or custom platter.
- Each runs without unlocking, like the activity's buttons.
- N1 only rings for a clock time he gave or a "remind me"; nothing Tessera times by itself rings (Plan my day, roll-forward, model guesses).
- No repeats, no snooze chains, no "still waiting".

## Quiet hours, 23:00 to 07:00
- **Only the timers he started ring:** rest (N2) and kitchen timers (N3), with the default sound.
- **A task timed in quiet hours saves but doesn't ring** (decision 6:44 PM PT). Its ghost row says so when he writes it. That line is Research's to word (proposed: "Call mum, 11:15 pm. No buzz in quiet hours.").
- Live Activities keep counting, silent as always.
- Nothing Tessera would post by itself is shown on the Lock Screen at night. It waits on Now.

## The Island
Always the system's black, in every look; nothing inside it is a pill.
- **Rest:** compact is the vermilion tick and the time (17/400, tabular). Minimal is the tick. Expanded is the countdown in 40 Light, "Bench" (16) over "82.5 × 8" (21) as the Done button, and the horizon along the bottom.
- **Cook:** compact is the lead label and its time. Expanded mirrors the Lock Screen face.
- **Focus:** compact is a short task name and the time left.
- **When two run** (a rest and a cook timer), the system decides; ours is the order rest, cook, focus.

## Never
A badge, a streak, a PR or a count, Review or the week, plan changes, rolled or late tasks, the 04:00 roll, Health saves, backups, Plan my day, a Tess suggestion or check-in, a second alert for the same thing, an ask on the Lock Screen, a sound in quiet hours from anything he didn't time.

## Owners
- **Builder A:** the three activities in Cobalt sky in every look (removing the look-following face), the Undo and 60s faces, the cook activity's flip and Stop, the focus activity with its stale date, the Island regions, and the N2 and N3 calls from the workout and cook mode.
- **Core:** `NotificationPlan` and the scheduler for N1 to N3 with the words above, quiet hours, `alerts` for explicit times only, the actions by `.intent`, and the return lines with UNDO.
- **Builder B:** the in-app pre-asks (M49, M50) as `one-ask.md` asks with ALLOW · NOT NOW, the return lines beside the soul, and the quiet-hours ghost-row line.
- **Research:** the quiet-hours ghost-row line.
