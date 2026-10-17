# Tess: three more soul-motion ideas (13 to 15)

Lab proposal, not a decision. These continue the board in `tess-ideas.html` (1 to 12) and plug into the event
contract (`tess-motion.md` §14, `tess-picks.md` §20). The screen-aware agent stays parked
(`tess-aware-motion-notes.md`); nothing here reads the screen.

## Rules all three keep
- **No new model call.** Each trigger is a count the app already computes: open items today (the `HomeFact`s
  behind the §20 diff), weekly sets (`TrainingLedger`) and today's plan (the schedule). Core's diff emits the
  event, at most one per change, and views never set a mode.
- **No new haptic case, one haptic per moment.** None of these adds a haptic of hers. If the moment already has
  one (the tick of a finished item), that stays the only one.
- **Never a frown at him.** The mouth only goes up or stays at rest here, never below `curve` 0, never on a miss,
  an UNDO or a skipped day.
- **Cobalt is Tess's voice only.** No cobalt is added to any row, number or control. The eyes and mouth use their
  existing dark pigment; the only cobalt that appears is her own line, as built.
- **Eyes off drops the face.** The mouth lives under "Tess has eyes" and never plays without the eyes. With eyes
  off, each idea does nothing, and each sheet says so.
- **Once per trigger, never a loop.** None plays in `.live` (a live workout, cook mode, Speak, a flight own their
  surface), while she is carried, listening or has an ask waiting. They sit at §14's precedence 7 or lower: a
  beat or Done in flight wins, and the idea is dropped, not queued.
- **Private-label rule.** The events carry a count or a date and never a row, a label or a rect. A private-labelled
  item counts exactly like any other, and the gaze is a fixed direction, never toward a row, so she looks the
  same whatever the label is. The same test runs with every item private and with none (see each Test).
- **Quiet hours** are 23:00 to 07:00 (`tess-picks.md` 18d). She is asleep then, so each idea is dropped at night;
  if the trigger is a once-per-day or once-per-week one, it stays unspent and may play on the first waking open.
- **Reduce Motion and Low Power** are listed per sheet. The blink always stays (§13).

Timings are at 60 fps (1 frame = 16.7 ms), rounded to whole frames.

---

## 13. She notices the empty list

| | |
|---|---|
| Idea | When the last open item of today's list is ticked, her lids settle halfway and she gives a small smile. It reads as "that's all of it", with no number and no word. |
| Trigger | The count of open items on the page drops from 1 to 0 by his own tick (swipe, hero, habit, Groceries). Core's diff over the existing facts emits it once the tick's `taskDone` has been handled. Not on a delete, a move, a reschedule or an item that arrives already done. |
| SoulEvent | `.listCleared` (new case, no payload; it carries no row, rect or label). Needs one line in the §14 table and one in §20. |
| Router | Accepted only when mode is idle or resting-not-asleep and a `taskDone` beat has finished or is finishing. If the beat (940 ms) is in flight, `.listCleared` starts at the beat's end, so the two never overlap. Dropped, not queued, if Done is in flight, she is listening, working, carried, asked or in `.live`. |
| Timing | Lids to 0.55 over 18 f (300 ms) ease-in-out, held 78 f (1.3 s), back to 0 over 24 f (400 ms) on the house curve. The mouth `curve` goes 0.2 to +0.8 over 15 f (250 ms), holds with the lids, relaxes over 36 f (600 ms) to rest. Eyes look ahead throughout. One blink at frame 126 (2.1 s), after the lids are back. Total 2.1 s. |
| Haptic | None added. The tick's own haptic is the only one. |
| Reduce Motion | No lid travel and no glance. The mouth crossfades to +0.8 over 9 f (150 ms), holds 1.3 s, crossfades back. The blink stays. |
| Low Power | The same as Reduce Motion. |
| Eyes off | Nothing (no mouth without eyes, and a lid change needs eyes). |
| Quiet hours | Dropped. At night the list clearing is his, not hers to remark on. Not retried. |
| Private-label rule | The count of open items includes private-labelled items. Clearing a list of only private items plays the same 2.1 s. No gaze, no rect. |
| Once | At most once per page per day. Un-ticking and re-clearing in the same day does not replay it. |
| Test | (a) Open count 1 to 0 by a tick emits one `.listCleared`; 2 to 1 emits nothing; a delete 1 to 0 emits nothing. (b) With a beat in flight, the start time equals the beat's end. (c) Clear, un-tick, clear again in one day: one play. (d) At 23:30, no change to `SoulState`. (e) With every item private versus none, the router's resulting `SoulState` sequence is equal. (f) With Reduce Motion, lid stays 0 for all frames and the mouth reaches +0.8 by frame 9. (g) No frame has `curve` below 0. |

## 14. She keeps the week's count

| | |
|---|---|
| Idea | The first time in a week that his weekly sets reach the target he set, she does one slow blink and looks up and to the side, as if checking the week off. It happens once a week and never says a number. |
| Trigger | The weekly-set total from `TrainingLedger` crosses the weekly target already shown on Training, upward, by a logged set. Core's diff emits it on that change. Editing the target, deleting sets, or opening the app already past it emits nothing. |
| SoulEvent | `.weekMet` (new case, no payload). It arrives after the same set's `setLogged` or `newBest`, and the router orders them: `setLogged`/`newBest` first, `.weekMet` after Done settles. |
| Router | On a page: accepted when idle. Under `.live` the workout's router would receive it, and the rule is that `.live` never plays it: it is held as a flag and plays once on Home's next `appeared` (the first foreground after the workout), if still inside quiet-hours-free time. Dropped if Done is in flight on Home, or if she is listening, working, carried or asked. |
| Timing | Eyes go to (0.5, 0.6) up and right over 21 f (350 ms) ease-out, held 54 f (0.9 s). A slow blink starts at frame 40: lids to 1.0 over 12 f (200 ms), hold 4 f, open over 18 f (300 ms). The eyes return ahead over 24 f (400 ms). The mouth rises to `curve` +0.6 over 15 f (250 ms) with the glance, relaxes over 30 f (500 ms) at the end. Total about 1.7 s. |
| Haptic | None. |
| Reduce Motion | No glance. A single slow blink, same lids, and the mouth crossfade over 9 f. |
| Low Power | The same as Reduce Motion. |
| Eyes off | Nothing. |
| Quiet hours | Dropped. The flag stays unspent, so the first waking open after 07:00 plays it if it is still the same week. |
| Private-label rule | Weekly sets count every logged set, labelled or not. The glance is a fixed direction, never toward a row. Training with private-labelled sets plays identically. |
| Once | Once per ISO week, stored as the week id on the router's side (in memory, rebuilt from the ledger at launch so a relaunch does not replay it). |
| Test | (a) Weekly sets 11 to 12 against a target of 12 emits one `.weekMet`; the next set, 12 to 13, emits none. (b) Dropping a set from 12 to 11 and back to 12 in the same week emits none. (c) Logged during a live workout, it plays once on Home's next `appeared`, not in `.live`. (d) The following Monday it can fire again. (e) At 23:30 the state is unchanged and the flag survives to 07:05. (f) A set that is a new best emits `newBest` then `.weekMet`, with at most one haptic in the pair (the best's). (g) Same `SoulState` sequence with private-labelled sets. |

## 15. She keeps a rest day easy

| | |
|---|---|
| Idea | On a day the plan marks as rest, her first look at him is a long, easy blink and a very small smile. It is the opposite of a nudge: nothing is due, and she says so with her face only. |
| Trigger | The first `foregrounded` of the day (after the 04:00 boundary, outside quiet hours) on a day where Training's schedule has no session. Core reads the same schedule the Training page already reads. A day with a session, or with no plan at all, emits nothing, so she never implies he skipped something. |
| SoulEvent | `.restDayOpened` (new case, no payload). Emitted by the router itself from `AppClock`, beside `firstOpenOfDay` (idea 2). If idea 2's wake plays the same morning, this follows 600 ms after the wake's stretch ends; they never overlap, and only one of the two haptic-free moments is on screen at a time. |
| Router | Idle only. Dropped if she is listening, working, carried, asked, in `.live`, or if Done or a beat is in flight. Never the second thing in a row after a returned line: if a `returnLine` glance is in progress, it waits for it. |
| Timing | Lids to 0.9 over 24 f (400 ms) ease-in-out (not fully shut, so it is a long blink and never a sleep), held 18 f (300 ms), open over 30 f (500 ms). The mouth rises to `curve` +0.45 over 24 f (400 ms) and relaxes over 42 f (700 ms). Eyes look ahead. Total about 1.6 s. |
| Haptic | None. |
| Reduce Motion | No lid travel. Crossfade to the small smile over 9 f, hold 0.9 s, crossfade back. The blink stays at its normal speed. |
| Low Power | The same as Reduce Motion. |
| Eyes off | Nothing. |
| Quiet hours | Dropped, and the first waking open after 07:00 is the first open of the day for this idea (idea 5 already holds that wake for idea 2). |
| Private-label rule | The event reads only "no session scheduled today". Private-labelled sessions are still sessions, so a private session day is not a rest day. Plays identically whether or not any scheduled item is private. |
| Once | Once per day, and only the first open. A later open the same day does nothing. |
| Test | (a) A day with no session emits one `.restDayOpened` on the first foreground after 04:00 and none on the second. (b) A day with a session, or no plan, emits none. (c) A day whose only session is private-labelled emits none. (d) At 06:59 nothing; at 07:00 the first open plays it. (e) After idea 2's wake, the start time is its end plus 600 ms. (f) No frame has `curve` below 0 and lid never exceeds 0.9. (g) Reduce Motion: lid stays 0. |

---

## What the builders need
- Three router cases: `.listCleared`, `.weekMet`, `.restDayOpened`, each with no payload, each with a row in §14 and §20. Any test that exhaustively switches over `SoulEvent` needs the three added.
- No new view: they use `SoulEyes` lids and glance and `SoulMouth` `curve` as already specified (`tess-picks.md` 18c).
- Order if all three are picked: 13, then 15, then 14 (14 needs the live-to-Home flag).
- A shared test: every one of the three, with Reduce Motion on and eyes off, never changes `SoulState` outside the listed fields.
