# Product decisions log

*Small calls made by Product so that fixtures and builds stay consistent. Newest first. Kaushik's own decisions are in `morning-questions.md`.*

## 2026-10-15, 1:56 PM to 6:44 PM Pacific (newest first)

- **Theme default** (7:22 PM PT, coordinator; shipped in Builder A's #195). Every install, his included, starts at Porcelain by day and Obsidian by night, and he can pin Plein. This overrides Research's 63 proposal.
- **The daily .tessera copy follows the 4 AM day** (7:22 PM PT, Research #196). Copies are named and written by the logical day, so late-night changes land in that day's copy.
- **Settings: Claude and Lists copy calls** (7:17 PM PT, Research #192 `settings-claude.md` and `lists-copy.md`, all defaults).
  - Settings: Claude: the cap is a fixed $10, so Design's $5/$10/$20 picker goes. The sleep and energy setting goes too, since Health is never read. Test runs on paste, and TEST stays on the key line. REMOVE is a tap word with a 10 s UNDO ("Claude key is back."), not a hold. A 403 keeps the key. Paste is by long press only, never automatic. Dates read "Nov 1". Amber comes from a theme token.
  - Lists: "put away" everywhere, never "Archive". An empty list's state word is EMPTY. "done" on a reusable list doesn't reset it; it asks, with a hold to reset.
- **Twenty closing grammar calls** (7:06 PM PT, Research #188 `grammar-open-defaults.md`). Every recommended default in that file is taken as written. The suite moves to 597 pass, 104 wrong, 73 miss, with no new wrong writes. The file is the record for each call.
- **Four more grammar calls** (6:50 PM PT, Research #181, all defaults). "tonight" or "this evening" said late with no clock time keeps the next whole hour, tonight only ("remind me tonight" at 9:15 PM can't mean 9 am), and quiet hours still apply. R13e: a reschedule never lands in the past; it rolls to the next occurrence. R13h: a reschedule verb with no task named applies to the task on Now. Confirmed under 6:47: cancel keeps the task and only drops its alert, and "again in N" with no recent alert goes to the model.
- **Reminder and default-time calls** (6:47 PM PT, Research #180, all defaults). "morning" stays 9 am because he said it. The silent next-whole-hour default goes: "call mum thu" on a Thursday gets no time and no alert, and a planned cook with a day follows the same rule. From `reminders.md`: a reminder with no subject is titled "Reminder"; "remind me to buy eggs" puts eggs on Groceries; place reminders ("when I get home") go to Later; repeats take the first occurrence only.
- **Calmer capture and a smaller set logger** (Kaushik, 6:45 PM PT, for the build after tonight's, next to Themes). The Ask Tess capture surface gets calmer, smaller, less cluttered type. In the workout, the weight scale gives way to the number itself, editable in place: scroll on the number, like the side dial. That frees the space for what matters on that screen. The sets round dial gets smaller, with more drama. Design specs all three after the rest dab, with Themes. Builder A builds the workout pieces, and Builder B builds the capture.
- **Three contradictions settled** (6:44 PM PT, Research #178 `decisions-index.md`, all defaults). A task timed between 11 PM and 11:30 PM saves but doesn't ring during quiet hours (11 PM to 7 AM), and its ghost row says so. "Trained" means at least one logged set, everywhere (Review, Plans, Day log). Core's work order lives in one place, the Now line of `ops/board/core.md`, and other docs point there instead of restating it.
- **This log is newest first** (6:44 PM PT). Entries from 1:56 PM PT onward moved into this section in that order; earlier sections are in UTC and say so.
- **Themes** (Kaushik, 6:40 PM PT). He wants a few rich, sophisticated themes he can switch between. His default will likely be a light theme, white with rich colour pops; he'll also switch to a pure black one. Not flat black and white: a real palette with deliberate proportions of background, foreground and accents. No cheap gradients, textures or basic effects. Design makes it its top job (`themes.md`, a preview, a DesignSystem token note). Builder A builds theme tokens plus a switch right after the Siri hotfix, and every later screen uses themed tokens, never hard-coded colours. It ships in the build after tonight's install.
- **Tess voice sync** (6:37 PM PT, Research #175 `tess-voice.md`, all defaults). Tess's times follow master's format: "Saturday 3 pm", "9 am". The examples above now use it; prose in planning docs may still say PM. Undoing a removal says "Set 3 is back.", the one exception to "taken back". The rewrite of principle 1 is confirmed. The 21 lines that disagree go to their owners: Research fixes `undo-lines.md` (drop "Health keeps its copy", since undoing a finish deletes the Health workout) and `empty-states.md` ("All quiet.", "Push day, no sets, not saved."); the Kitchen lead fixes "Simmer stopped." in `cook-mode-acceptance.md`.
- **"remind me" plus a day alerts at 9 AM** (6:30 PM PT). The words "remind me" ask for an alert, so "remind me sat" rings at 9 AM Saturday. A plain "call mum sat" gets no time and no alert, which keeps the 6:20 rule.
- **Ask lines for notifications, final** (6:30 PM PT, Research #173; supersedes the old Q5/A7). The notification ask fires only on his first "remind me", timed task or cook timer. When notifications are allowed, the rest notification rings and the Live Activity alert stays silent, never both.
- **Claude's first three uses and their gates** (6:22 PM PT, Research #172 `claude-first-uses.md`). The estimate is about $0.44 a month, or $2.43 in a heavy month.
  1. Grammar misses go to Haiku with the cloud mark, which fixes 44 of the 72 misses. This turns on when the key Test passes.
  2. Plan my day wording uses Sonnet, with Haiku in the same eval. It turns on after the first 10 use-1 calls have ledger costs within 10% of the Console, 3 or fewer of them were taken back, and all 20 plan scenarios pass.
  3. Log questions use Haiku. They wait for a question mode that can only call answerQuery.
  - Also settled: the fallback line stays "Here's your usual plan." (12:22 decision; tess-voice M18 changes to match). answerQuery counts only finished workouts, as questions-eval does. The live pack uses Los Angeles time; London stays in the eval packs only. New copy for Design: "Claude is busy. Kept it for later."
- **The review guide tags every item with its PR or branch, and every known gap with its fix** (6:20 PM PT), so the coordinator's install check (`install-check.md`) can match the guide to the build.
- **Notifications, first set** (6:20 PM PT, Research #171 `notifications.md`). Three local notifications: a timed task, rest done while the app is closed, and a cook timer done. Quiet hours run 11 PM to 7 AM. When notifications are allowed, they replace the Live Activity rest alert (Q5/A7). The one permission ask fires on his first "remind me", first timed task or first cook timer, whichever comes first, within the one-ask-a-day rule. A task with no time is never saved as 9:00.
- **Late-night rules** (6:07 PM PT, Research #169 `late-night.md`, all defaults). "tomorrow" before 4 AM means the coming daytime, and Tess's reply names the weekday ("Dentist, Saturday 3 pm"). A session that crosses 4 AM belongs to the day it started. Until notifications exist, a reminder ask gets "On Now then."
- **Time zones and DST** (6:06 PM PT, Research #168 `fixtures/dst-travel.md`, all defaults):
  1. Every log stores its zone at log time; a missing zone falls back to the current one.
  2. A workout belongs to the day it started, so a session past 1 AM never marks the next day trained.
  3. "1:30am" on Nov 1 means the first 1:30.
  4. Day caches are keyed by zone, and Now refreshes when the zone changes.
- **Grammar regression calls** (5:58 PM PT, Research #167, all defaults):
  1. "table" is not a meal word.
  2. "tonight" said after 8 PM means tonight, as at 4:41.
  3. "next fri" means the Friday of next week.
  4. The widened reschedule rules R13c, f, g, i and j are taken.
  5. In "paid 12.50 at 12.30", 12.50 is the amount and 12.30 is the time.
  6. "done" while a timer rings ends the timer first.
  7. The test clock runs on Los Angeles time, his own.
- **The 4 AM day comes first for Core after N1** (5:56 PM PT, Research #166). 28 places cut the day at midnight, and 6 of them store a wrong date. He uses the app late at night, so a public `TesseraDay` helper (DST-safe) lands first, then one-line swaps. "dentist tomorrow 3pm" at 1 AM and "Not now" after midnight go in the same PR.
- **One ask a day** (5:56 PM PT, Research #166 `ask-lines.md`). At most one permission or one-time ask per 4 AM day, in Research's priority order, and never from a background finish, so his first workout no longer stacks the Live Activity ask and the Health ask. Core adds the missing calendar, mic, speech and camera usage keys before those features ship, and replaces the Health read string with an honest one.
- **Claude key entry pulled forward** (5:49 PM PT). Kaushik has his key. He types it into the phone himself, and it never goes in the repo, docs, memory, board or any thread. First version: a Claude field in Settings that stores the key in the Keychain (this device only), with a paste-once flow and a "Test" that makes one tiny call and says whether it worked. The $10 a month hard stop ships in this first version. Core builds the Keychain store, the test call and the cap ledger (T3). The screen goes to Builder B, since B owns Tess, right after the Review week fix and on Design's Settings: Claude sheet. Design draws the rest dab first, then that sheet.
- **Light day and calendar** (5:48 PM PT, Research #165). A day is light if the week is squeezed, 480 or more minutes are booked, or there are 5 or more fixed blocks; Health is never read. The calendar is read once, from 4 AM to 4 AM, with titles only (capped at 40 characters). Birthdays stay out of Plan my day. Today's midnight cuts in `TaskList.today`, `week(containing:)` and `DayLoad` move to 4 AM.
- **A rolled-over task is flexible** (5:41 PM PT, Research #164). It lost its time when the day rolled, so Now's ranker and the planner both treat it as flexible, never timed. Core fixes the ranker in a small audit PR. The planner's pack also gains calendar events, a light-day source (plan and load, never Health), and the running workout before T4 ships.
- **Accessibility mostly waits** (5:25 PM PT, Research #160, 80 rows): Kaushik is the only user. Pulled forward at normal priority are Builder A's one MotionPolicy fix, so Reduce Motion really stops slides and scales, and Builder B's Home queue heights, which clip at large text. The rest goes to Later on each board. Tess's rows are Builder B's; Objects rows are Core's (as at 5:14 PM PT).
- **Empty-state open questions, on defaults** (5:14 PM PT, `empty-states.md`).
  - A workout finished with zero sets is not saved. Tess says "Push day, no sets, not saved." with Undo, and it never counts as trained.
  - Plan targets count from the plan's creation day, so a plan made mid-month reads "Session 1 of 13", not "of 26".
  - A "good day" means trained (at least one set logged), on both Review screens.
  - Empty states stay text only, through one shared `EmptyLine` in DesignSystem (Builder A).
  - The PPL x2 starter plan stays.
  - `Features/Objects/` copy is Core's.
- **Undo open questions, on defaults** (5:14 PM PT).
  - Siri's "Undo Last Set" removes one set, as its name promises (Builder A's hotfix).
  - Silent writes stay silent: checking a grocery, autosaving a note, starting a workout. Each is reversed by doing it again.
  - Undoing a finish also deletes the Health workout we wrote.
  - The Live Activity undo strings live in Research's `widget-states.md` until Design puts `live-activity.md` on its branch.
  - `App/Health/HealthExporter.swift` is Core's, and the capture code in `App/AppModel.swift` is Builder B's.
  - Destructive writes (delete a note, finish the shop) keep their UNDO for 10 s, not 4.
- **One rule for undo** (5:14 PM PT Oct 15, Research #158 `undo-lines.md`). Every line names the thing, then what happened to it ("Set 3 logged", "Note deleted"). Undo answers with the same name plus "taken back" ("Set 3 taken back"), and an UNDO key always reverts the record its line names. "taken back" is the house word, so "Undone." goes.
- **Widget and snippet copy** (5:02 PM PT Oct 15, Research #156): "All quiet." over "Nothing else is planned today."; "×" in sets; FinishWorkoutIntent uses the `WorkoutSummary.line` text; "Set 3 taken back" over "Last set removed.". Builder A makes them consistent everywhere. The expired-signing widget timeline check waits until widgets ship (none exist on master), and his phone is never allowed to lapse just to test it.
- **Review week fix goes next for Builder B** (4:58 PM PT, Research #155: 22 of 30 weeks flagged). Review opens with a session count, not a grade, rest days get their own dab, and the miss ring only marks a real miss. Two sessions on one day count as two. Order: Builder B's Now hookup and audit polish, then this. Core supplies the week data after the grammar hotfix, and Design draws the rest dab first.
- **Upkeep starter calls** (4:50 PM PT, `fixtures/upkeep-starters.md`):
  - Take guards S1 to S6.
  - The first screen shows 12 starters plus "more" (the other 13, plus Bleed the radiators).
  - A picked chore never drifts to Now until its first log.
  - Near-misses follow the file's default.
  - Noun-first logs ("bins done", "rent paid") work, with the same limits.
  - "fine" counts as done for check chores (smoke alarm, meters).
  - Rent and council tax stay as starters he can skip.
  - Seasonal chores are plain 30 days, paused by hand.
  - "alarm" stops being an AM cue.
  - "get new sheets" is a task, matching the 4:30 non-food rule.
- **Cook timer calls** (4:50 PM PT, `fixtures/cook-timer-phrases.md`):
  - A bare length is labelled with the current step's verb ("Simmer").
  - With no name: flared timer first, then the soonest, with Undo, never asking.
  - A running label restarts that timer.
  - "step 3" by voice is allowed.
  - Bare-number cap is 180 minutes.
  - "2 onions" mid-cook writes nothing.
  - In cook mode, "done with that" finishes the step (the last step finishes the cook, "dal, done.").
  - Under 2 minutes reads in seconds ("90 sec.").
  - Q1 may run ahead of the question guard.
  - Extend and Pause wait for slice 12b.
- **Hint ledger calls** (4:50 PM PT, Research #154, `research/fixtures/hint-ledger.md` open questions). S and G lines stop on day 15, counting day 1 as the first, at 4 AM. H lines keep going for actions he has never done by hand. Every other choice the file made stands, including the placeholder counting toward 3 a day, one H per action, G lines retiring on use, the build sheet's placement, and lasting instruction lines not counting. Copy: H lines read "Next time, just say it: ...", because "Next time" alone already means progression on the Exercise page. The Speak line uses the build sheet's "Hold me and say it: 80 for 8.", H16 uses the lift form "bench 80x8", and timers and notes get H lines too. In Show the hint sits under the waiting ghost with no dry time; the 4:39 rule wins. A G line has no swipe of its own, so the ghost row owns swipe-to-discard. "once" is added as a retire reason, an empty placeholder is fine, and `RollForward.logicalDay` becomes public.
- **Time-form rules, replacing parts of the 4:26 PM PT calls** (4:41 PM PT, Research #150 rows). "thu 3pm" said on a Thursday after 3 PM means next Thursday, because a named weekday means that weekday. A bare 7 to 11 on another day is PM with a meal or evening word ("dinner fri at 8") and AM otherwise; on today the 4:26 rule stands (the next one that hasn't passed). "tonight" or "this evening" said after 8 PM stays today, until 11:30 PM.
- **Show mode photo calls** (4:39 PM PT, Research #150, `research/fixtures/show-photos.md` open questions). All defaults:
  1. A photo read never commits by itself. A sure receipt waits for a tap, like every OCR result (`capture-modes.md` 1.6), and still does once Money ships. Design's 2 s drying is for typed phrases only.
  2. The store shows in title case ("Tesco" for TESCO). The category is the whole name as printed ("Blue Bottle Coffee"), lower-cased only for matching.
  3. No store row means an empty store. Don't guess from a screenshot's app name.
  4. Symbol-led whole amounts are allowed for ¥, ₩ and ₹, and the Japanese total words are added. ¥ stores as JPY, read from the photo; the four typed currencies are unchanged.
  5. Too blurry reuses "No text in that photo." (one line, not two).
  6. Short text (a dog tag, a slogan) goes nowhere, with "Nothing to save in that photo."
  7. Card numbers are refused before routing, with "That looks like a card, not saved."
  8. No CASH, CARD or CHANGE row and no total keyword is enough to call it a menu, so it becomes a note.
  9. Duplicate check on total plus store plus date. A match still makes the ghost row, with "Already logged today?" on it, and waits for a tap.
  10. The note title comes from Vision's `isTitle`, else the tallest line, else the first line.
  11. `@` in photo text never links: a `linksMentions: false` flag on `CreateNote`, so his text isn't rewritten.
  12. Prose recipes go to a note with the recipe switch, as row 20; no model fallback by default.
  13. An iCloud-only photo offline uses photo-field's line: "That photo is still in iCloud. Try again online."
  14. No ordinal on spend lines from photos, as in the Money fixtures.
  Also: "1,280" reads a comma before exactly 3 digits as a thousands mark.
- **"paid" plus an amount belongs to Money** (4:34 PM PT, confirmed against Research #149). It logs a spend, and if it names a chore, ticks that chore in the same ghost row. Upkeep rows 34 and 40 change to match. Under the agreed M5 order only 5 of 170 rows change, and the guards in `research/fixtures/m5-parse-order.md` go with Core's M5 engine items.
- **Day log v1 rule gaps** (4:30 PM PT, Research #145), so Core builds without waiting: counts use proper singulars ("1 task", "2 tasks"). Captures fold into one line, as the fixtures do; this settles the Oct 6 and Oct 8 examples, and "Also:" counts follow the fixtures. A planned rest day shows a "Rest day" line from the plan, even though it leaves nothing in the op log.
- **"buy" with a clearly non-food object is a task** (4:30 PM PT, Research #145 kitchen rows). "buy train tickets" and "buy new trainers" become tasks; "buy" with food or household groceries stays Groceries. This amends People decision 8 and Lists G7, and call 3 at 4:26 PM PT. When the object is unclear, Groceries stays the default, and Tess names the list so a wrong pick is one Undo.
- **Grammar comes first** (4:26 PM PT, coordinator). Core's order is N1, then a hotfix for the sweep's top 5 root causes, then the polish PR, then the rest of the grammar batch, then Day log v1, then meal plan feeds groceries. Until the hotfix lands, the review guide says typed past-tense or bare-hour phrases can land wrong and Undo fixes them.
- **Grammar sweep calls** (4:26 PM PT, Research #143, `fixtures/grammar-misfires.md` open questions). Defaults, so Core isn't blocked:
  1. Bare hours: 1 to 6 mean PM, and 7 to 11 mean the next one that hasn't passed today; 12 is noon. Tess never asks; the ghost row shows the time, so a wrong pick is one tap or Undo.
  2. Past logs before Upkeep and People land: the grammar writes a note dated that past day ("Watered plants", Sat). It's true, it shows on the Day log, and Upkeep can adopt it later. Not a task.
  3. `buy` stays Groceries (People decision 8 and Lists G7); Tess names the list. Non-food `get` (RC3 a to c) goes to tasks as Research proposes.
  4. "is" questions such as "is the gym open sat" are questions, not captures. They go to the question path (the model), never to a task.
  5. A time today that has already passed: never write a task in the past. It lands tomorrow at that time, and the ghost row says "Tomorrow 7 am" so he sees it.
- **Show and hints split** (4:22 PM PT, Design's `show-and-hints.md`): Builder B builds the Show layer (Photos · Camera · File) and the hint lines. Core builds PageReader, the routes and the hint ledger, right after the photo field type.
- **W3 asks for Health permission with a one-time line on Now he can tap** (4:20 PM PT). No prompt at launch; if he says no, the line never comes back and Now shows no recovery line.
- **Watch W3 recovery line** (4:13 PM PT, Research #138): a 28-day baseline, no HRV percent on screen, and Plan my day's "light day" never comes from these readings. W3 waits for a small HealthKit read layer, which master doesn't have yet.
- **Build A1 calls** (4:13 PM PT, Research #138): a shipped field can be hidden, never deleted, and hiding is undoable. A new field never reuses a retired field's key. A1 starts by clearing its blockers on master: 11 in `build-a1-brief.md` (10 plus one minor). Corrected at 4:20 PM PT from "six". M3 slices 3, 6 and 10, built in that order, clear all but blocker 11 (`m3-3-6-10-brief.md`).
- **Back word order** (4:12 PM PT, Design's `back-word.md`): "< NAME" replaces every system back button, Home covers get "< HOME" in place of "Close", and edge swipe stays. Builder A builds the shared BackWord view right after the #122 hookups. Builder B and Core adopt it in their next polish PRs. The first pass fades the word in; the flight comes later.
- **Live grammar misfires get a Core fix batch right after the ranker** (4:10 PM PT): "watered plants sat", "get mum a card", "coffee with ravi at 7". Research writes a misfire sweep so the batch catches the rest.
- **Money open questions** (4:10 PM PT) go on the coordinator's morning list with defaults that hold until Kaushik answers: no merchant field yet, four currencies, a bare "38" answers a waiting shop total only when no workout runs, "paid" plus an amount is a spend, and a split logs his share (`ship-list-m5-money.md`).
- **One grammar parse order for M5** (4:10 PM PT, Research #135). The approved Upkeep and People ship lists asked for an impossible order, so we take Research's: notes, pasted recipes, relative sets, then reading, money, people, then comma sets, lifts and kitchen, then upkeep, then tasks. People drops its "after upkeep" clause. All three M5 ship lists now state the order.
- **What Now shows on a rest day** (4:01 PM PT, R05). First a running process, then an event or timed task within 15 minutes, and only then the "Rest day" line. The rest-day rule (3:37 PM PT) only replaces the workout suggestion. It never hides time-bound things.
- **Reading grammar collisions** are fixed in Core's first M5 Reading engine slice.
- **Day log v1 brought forward** (3:53 PM PT). Core builds `DayStory` after the ranker, and Builder B builds the page. A started workout with sets shows on the day even if it was never finished.
- **Lists daily-use gaps** (3:53 PM PT): all 13 of Research's defaults are taken (`lists-daily.md`). The engine parts go into Core's Lists engine, and G1 (a "Lists" HomeLink under Groceries) goes to Builder B.
- **Spreading screen work** (3:50 PM PT, from Research's breadth map). The cook mode screen moves from Core to Builder A, since its engine is merged. M5 Reading and Money screens move to Builder A, and Builder B keeps M2, capture, Lists, Upkeep and People. Every area's first screen includes a HomeLink word in HomeSpatialView, so it's never DEBUG-only.
- **On a planned rest day, rest wins on Now** (3:37 PM PT, per QA E2 on #122). Now shows a quiet "Rest day" line, and the next routine stays one tap away (Training, or a pull on Now). Missed days still roll on, so starting it anyway is fine. Core makes this a NowPicker/ranker override, and Builder B shows the line.
- **All times shown to Kaushik are in Pacific time** (Kaushik, 1:56 PM PT; PDT is UTC-7 today), never UTC. Earlier entries in this log are UTC (for example 19:12 UTC is 12:12 PM PT). New entries use PT.

## 2026-10-15 18:41 UTC, 11:41 AM PT (Kaushik)

- **Home rail:** add KITCHEN as a fourth word, next to Review, Today and Training. Yes.
- **Claude for Plan my day:** yes. M4 slice 6b is unparked.
- **Claude as a foundation:** Claude is part of the base, built in as early as possible, not bolted on later. A "Tess model layer" foundation slice goes early in the queue after tonight's release.
- **Fetching a recipe page from a pasted link:** approved. It goes into kitchen v2, which still waits for a week of use.
- **Apple Watch:** yes. Sleep stages and resting HR are in (M4 slice 2), and the "In bed" fallback stays for nights without the Watch.
- **First phone build:** cut at 19:45 UTC, reviewed with `review-session.md`, then a huddle to make the plan concrete.

## 2026-10-15 18:40 UTC, 11:40 AM PT (from Research #78)

**Plan my day (M4 slice 6)**
- The plan window ends at 21:00, when Shutdown takes over. DayLoad counts free time until 23:00.
- Ghost lines in the plan are tasks only. Events and the workout appear in the header line, not as lines.
- On a full day, tasks that would otherwise be offered for Later are left out.
- Priority is ignored, because `Task` has no priority field.

**Health and Calendar (M4 slices 1 and 2)**
- Without an Apple Watch, sleep shows time in bed ("In bed 7h45").
- Resting HR older than 36 hours is hidden.
- If calendar access is denied, Tessera says so plainly in one line with a link to Settings, never as an error.

**Questions and saved queries (M3 slices 4 and 7)**
- Adopt the minimal query AST proposed in `../research/questions-eval.md`.
- Movement pattern is a field filter, not a class lookup.
- List items get a date field (already part of Lists slice 2).

**M5 Reading**
- Approved as `ship-list-m5-reading.md`, with all of its defaults. A book never takes Now from a workout. Books appear in the evening slot from 19:00. The queue is a book state. Books are never put away. Setting a book aside can be undone. Reading is its own small app, and works offline first.

## Earlier (times in UTC unless marked PT)

- **Body weight:** the trend line is the headline.
- **Lists:** "reusable", never "template"; the M3 List shape creates a List; Copy sits next to Reset; a skip is not a pick; a preview appears before saving a paste.
- **Tess:** grammar first, then the on-device model; cloud models need Kaushik's OK.
- **Cook mode:** Core builds it, and Builder A reviews the shared instruments.
- **Tess model layer reconciled with Research (18:50):** Research's T1 to T7, S1 and S2 are the build plan. The cap is $10 a month, hard stop, with no daily cap (replaces $5 and $0.50). Streaming is allowed. The beta Swift package is the planned transport, but Core confirms it in T1. Three Claude questions go to the huddle with defaults.
- **"call mum thu" said on a Thursday means today** (18:58), as people talk. The code changes in Core's grammar collision item.
- **Grammar collision fix goes right after model layer T1/T2, ahead of Groceries polish** (18:58), since Kaushik types into Tess from tomorrow.
- **Cook mode gets its own idle rule** (18:58): never suspended while a timer runs or within 45 minutes of the last step. Paste parser gaps get a paste-hardening slice with `packSize` and `section` fields.
- **No rounded-rectangle, oval or pill buttons anywhere, Apple defaults included** (Kaushik, 19:00). Design writes the replacement language and audit (`docs/design/no-buttons.md`). One sweep after the install: Builder A first puts the shared style in DesignSystem, then Builder A, Builder B and Core each sweep their own screens.
- **M5 Money ship list approved** (19:07) from Research's draft with all seven defaults: no home currency, bare amounts only with two decimals or a currency mark, "total?" asked once after a shop, category is one word, ordinal in feedback, its own small app, bank data parked. It lives at `ship-list-m5-money.md` and comes after Reading.
- **Recipe link fetch uses an honest Tessera user agent** (19:07), not a Safari-like one. When a site blocks it, Tess says so and offers "paste the text". This keeps kitchen-v2's no-spoofing line. Without a Share Extension on free signing, the entry point is an App Intent plus a Shortcut. Recipe needs a `sourceURL` field, and CreateRecipe needs a URL input, both in kitchen v2 L1.
- **Apple Watch: no Watch app yet** (19:11). Read sleep, resting HR, HRV and workout HR from Health. Now: W1 (HR on the summary) and W2 (the rest Live Activity on the Smart Stack). Later: W3 (recovery line with M4 slice 2) and W4 (de-duplicate Watch workouts).
- **M5 Home upkeep ship list approved** (19:11) with all seven defaults (`ship-list-m5-upkeep.md`). It comes after Money and needs M3 slice 2.
- **Model tools: add completeTask and rescheduleTask** (19:12), making 10. Tick-off, timers and open-list stay without a tool for now.
- **Principle: one ground layer, the screen is scarce** (Kaushik, 19:18). Show what matters for the current context and reveal more on demand. This is now section 0 of `spatial-interaction.md`. Ask Tess becomes a small glyph that expands into a capture surface for typing, on-device voice, and later photo, file or video. Builder B owns it, and it absorbs v1 slice 17 (voice). Research scouts context packing.
- **Plan my day fallback** (19:22): on a timeout or failure, the rules plan shows with one quiet line, "Here's your usual plan", rather than silence. This matches tess-voice lines M18 and M22.
- **M5 People approved** (19:22) with all 9 defaults (`ship-list-m5-people.md`). It comes after Upkeep and has no Contacts access.
- **Build list approved** (19:22): make an app from a sentence (`ship-list-build.md`). A1, undo for schema changes in the op log, comes first, after M3 slices 3, 6 and 10 and T1 to T3.
- **Context ranker is backbone work** (19:27). Core rebuilds NowPicker around `rank()` with `Pick.why` as Next 3, after the v1 gaps and the grammar fix. Builder B makes NowPage read it, right after the capture surface.
- **The capture surface ships in three modes** (19:30): Write, Speak (SpeechAnalyzer on the phone, which also covers v1 slice 17), and Show (Vision on the phone; page to note first, receipt total after Money 2 and 3). Images never leave the phone. Core adds a photo field type.
- **Backup and restore jumps to Core Next 1** (19:37), because nothing protects his data from tomorrow. It makes daily .tessera copies (keeping the newest 7) in an iCloud Drive folder he picks, with a checked restore. The year-of-data generator goes in Later.
- **Design goes breadthwise** (Kaushik, Design thread 19:37). Today's design shape is the baseline, so cover every upcoming screen with a "just enough" sheet now and deepen each one after use. Planning follows the same rule: more areas at a first version, then iterate.
- **Money copy stays currency-neutral** ("Groceries, 38.20") until Kaushik answers the home currency question. The default is to store amounts as typed.
- **Research's three questions** (19:47), all answered with the defaults. The Exercise page's main action is history and progress, while logging stays in the live workout. Cook stays hidden until cook mode (slice 12) lands. We keep the newer Review screen, #44's sentence hero.
- **One way back into a running workout** (19:47): the lit top seam plus the Live Activity, replacing the six paths.
