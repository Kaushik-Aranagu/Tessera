# Item 193: Build order for everything queued (rounds 3 to 15, Home 194 to 201), Oct 23

The queue is deeper than the builders can drain before the trip (Oct 26 to 28). Everything stays
behind Review switches, default Off, so the order is a choice of what to build first, not what to
drop. Rule sheets (171 big text, 175 haptics, 188 calm errors, 192 Tess's voice) cost no build:
they are checks on every PR. Nothing here removes an approval gate or loosens a privacy rule.
Re-tiered in the Oct 23 daily deep pass to Kaushik's Oct 22 evening direction (Home is the
departure board, the living mosaic and Next). What was cut or merged: build-order-cuts-2026-10-23.md.

## Tier 1: before the trip (builders take these first, in this order)
1. Home, one item (194 point 0, 195 parts 1 and 4, 197 parts 1, 2 and 4, 199, 200 Builder B): date
   and the Settings knob and word; the three right-aligned departure-board lines (200 type and
   flips); the mosaic under them (homeMosaic); Next (three swipe rows, Tess's line with Undo).
   Apps list Off by default.
2. 147 occasions, then 187 awayV2 (the trip itself). 187 quiets nights through QuietInterrupts and
   does not wait for 167's page.
3. 164 undoLogV2, one Undo from the op log (makes every later write safe to try).
4. 200 homeMosaicMoods: finer grid, dithered edges, the moods except rain, changeovers, living
   size, MosaicMoodPicker on the phone.
5. 201 homeMosaicMoments without weather: announce, tess (eyes only), timer, finished, best,
   reminder, delivery, and the melt hand-backs.
6. 161 pantryLevelsV2 and 155 shopV2, the grocery side of the trip.
7. 169 backupsV2 (backup before travel; money values and actions are not in a backup).
Already built or in review: homeV2 + fan (edges and fan leave Home under homeMosaic), numberRules,
roomMotion, finishMoments, tasksApp, routinesDayV2 (with 176), weekThreadV2, trainingStats,
trainingLog, linkColours, pagesV2.

## Tier 2: next
Weather scenes on sample data (200 rain, 201 snow, fog, wind, storm, heat; source Off), 153 liveV2,
160 moneyMonthV2, 179 walledPageV2, 154 settingsV2 (with Settings > Home: Apps list and the mosaic
switches), 142 surfacesV2 (no money words and no calendar clauses on any widget or Lock Screen
surface), 157 planV2 (the proposed day as the board's lines, Keep in Next's Tess line, reorder on
the plan page), 156 focusV2, 165 listsV2, 172 moneyAddV2, 173 repeatsV2, 181 notesWriteV2,
189 unitsV2, 190 notifyWordsV2, 143 reviewV2, 149 to 152 pagesV2 rest.

## Tier 3: later
146 oneHands (through Next's Tess line and the tess moment), 144 whyNumbers, 148 makeAKind and
174 noteTasksV2 (they share 152's note margin, one offer at a time), 159 weekReset with 186
weekMealsV2 (offered from its Kitchen line), 158 findV2, 166 askPageV2, 167 quietHoursV2,
170 tessQuietV2, 177 controlsV2, 178 voiceWriteV2 (inside the apps, never on Home), 180 importV2,
182 cookHandsFreeV2, 183 twinsV2, 184 soonSweepV2, 185 dinnerChooserV2, 191 spotlightV2,
163 emptyStatesV2, 196 long lists (other rows go ink 3, no softening), Apps list on Home (195, 197,
198 and 199 merged: 3 rows, Off by default, Words, Number or None per app, Money words only).

## Held for Kaushik
Run mode, Programs, scenarios. Waiting on the paid developer account: the WeatherKit source for the
weather scenes, which stay Off until then.

## Pace note
Design is producing about 4 items per 10 minutes; the build lane drains far fewer. More rounds
add to Tier 3 only. The coordinator can slow the design loop when Tier 1 and 2 are not draining.

## Manager decisions (Oct 22, 7:25 PM, from backlog-summary.md overlaps)
- One Undo: every "10 min Undo" in 169, 172, 174, 178, 180 and 183 means the op-log Undo of 164. Nobody builds a second undo.
- 176 (Pause, Busy, habit marks) ships under the routinesDayV2 switch; it needs no switch of its own.
- "To get" and the lift back to in belong to 161 (Pantry). 155 (shop run) uses them; 165 (Lists) checks off list items only.
- 187 (away) builds on 147 (occasions): same Home trip line, 187 adds "Packing is done." Build 147 first.
- PRs #1251 and #1275 both implement parts of 139: #1251 covers Training, Kitchen, Routines; #1275 covers Lists, the day clause and past days. No overlap in code; Tasks is #1267.

## Deep pass decisions (Oct 23, 7 AM)
- Home is the board, the mosaic and Next; nothing else is queued for Home. Tess's words on the board are never cobalt; her offers (146, 157) go in Next's Tess line.
- One finish on Home: 201's finished moment is 199's flying tile; nobody builds both.
- One Tess budget: 170 counts Next's Tess line and the tess moment; 201's one moment per 10 min stands.
- Backups (169) and 179's backup line: money values and actions are left out with health, body, calendar, calories and walled titles.
- Reduce Motion is a 150 ms crossfade wherever a sheet says "appears" or "no animation" (178, 181, 188, 192).

## Design rulings on the deep pass questions (Oct 23, 7:20 AM)
- Level lines (156, 160, 161) stay; "bars" meant the Home and apps-list drawings.
- Getting into an app from Home: an app word in the board lines, a Next row, or the optional apps list. The fan leaves Home.
- Swipes everywhere: right = Done. Today/Later moves to the left swipe (184 changes).
- A timer ending is rigid (201 wins over 182).
- Next keeps "tap a row for its why" (Pick.why): added back to the Tier 1 Home item.
- Notifications and Siri (190, 191): no money amounts ever. Money notifications use hidden previews on the Lock Screen (iOS shows only "Tessera" until unlocked).
- The 201 reminder light is an edge light inside the mosaic, not a UI band; OK.
- The announce crawl is pixel art (about 56 pt tall on screen), so the 16 pt floor is met.
- No mosaic tile may sit within ΔE 10 of Tess cobalt (2E6DA4 / 9DBFE6) except Tess's eyes; Builder A clamps sky and fog colors.
- Delivery "arrived" = an "Arrived" action on a shop run in Pantry To get (Core defines it with 155/161); his own mark only.
- 157's calendar lines are drafted on the phone only, never via Claude; they reach the board as segments with private items masked.
- 143's day stroke stays on Review only, never on Home.
