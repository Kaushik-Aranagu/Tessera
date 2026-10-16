# Product decisions log

*Small calls made by Product so that fixtures and builds stay consistent. Newest first. Kaushik's own decisions are in `morning-questions.md`.*

## 2026-10-15, 1:56 PM to 6:44 PM Pacific (newest first)

**4:46 PM PT Oct 16: body-number sweep calls (Research BK, body-number-sweep.md, 43 paths on 56dd028).** DECIDED. (1) As Research picked: isBodyShaped, isWalled and isPrivateTitle take `lastWeightKg: Double?` with no default, so the compiler finds all 13 call sites. TessCaptureEngine.capture fills it once per phrase from a BodyWeight.lastKg(in:) lookup, which reads the newest weigh-in note now and the M3 entry later. (2) Of the 12 paths that bypass PrivateFacts, five are IN the 0ai rider because they feed Tess or Claude: the on-device model's writes, tool writes, RememberFact, memory turnover, and Plan my day threading (PlanWording.swift:37-39). Three are follow-ups after the rider (Core 0an): the Groceries Add line (the 2:09 price strip), Routines' Name it, and what a pasted recipe saves. Four stay exempt because they're his own words in his own place, stored on the phone only and never sent: the Notes page and editor, "note:", backup restore and RenameObject. (3) With a set in focus mid-workout, a number is the bar weight and isn't walled ("is 80 good?" during bench). A number with another unit stays plain ("80 min", "75 g", "85%"). (4) Core adds a body-word list: weight, weigh, weighed, kg, lb, lbs, body fat, BMI. "weight" moves out of dayWords, so BN04 can pass. (5) On the Ask bar, a walled "?" phrase answers "That stays on this phone." and makes no Home task. BN01-BN04 check that, and the live-workout ask (WorkoutModeView.swift:280) is the path tested for Claude.

**3:05 PM PT Oct 16: which word the title accent colors (Research BJ).** DECIDED. Sheet 72, which he approved, wins over the earlier Product table: the key word colored is the MOMENT word after the comma ("Push Day A, bench set 2" colors "bench set 2"), not the thing's name. 0p's title progress reads the same plannedSets source as 0r's progress (#546, NowPage.swift:209), so the two never disagree.

**3:03 PM PT Oct 16: release on merge, every new feature to his phone (Kaushik 3:02 PM, project chat: "every time we have some new features, we have to release it to my phone").** HIS CALL. It REPLACES the 2:49 daily 4:00 PM pin. (1) RELEASE ON MERGE. When a PR he can see merges, the coordinator names master at that merge as the release SHA. If more app PRs are about to merge, it waits up to 30 minutes so they share one install. Docs-only and eval-script merges never trigger a release. (2) The gates are all kept: every app PR in the release has QA and Design PASS at its merged head (QA's readiness line in qa.md); there's no Catalog or migration change (v9, V0); test.sh is green on the exact SHA; the walls-ui spec rows pass for any walls change inside; a Step 0 copy "Before <release sha> (from <sha on his phone>) <time>" is saved outside Backups and checked (the Mac keeps the last 3, and the a36b161 copy is never deleted); and Builder A installs in place under his standing approval. Only a named release SHA installs, never master by itself and never anything older than a36b161. (3) Design's walk clip moves to after the install and no longer blocks. A FIX FIRST from the walk becomes a roll-forward fix, the next release (§7). (4) The first release is 56dd02889727e2dec8adf249eda7e9fb320e363e (master at #544). The walls-ui suite isn't on master until #564, so for 56dd028 #544's own tests in test.sh are the walls check. It adds a privacy fix over a36b161 and removes none. From #564 on, walls-ui rows gate every release with a walls change. (5) v10 is unchanged: #407 merges only after every rider is in a release on his phone, with its own v10 gate and drill. The Thu Oct 22 9:30 AM call becomes a check that all riders are in, not a naming. The Fri Oct 23 10:00 AM re-sign fallback stays, and each install re-signs anyway. (6) Approved looks (A 0p, B 0y, Core 0ak) still sit right after each lead's open riders and ride the first release they're ready for. Research refreshes the new-on-your-phone page per release.

**2:59 PM PT Oct 16: one way to show more (Design sheet 76, depth.md 1cab06a; Kaushik's 2:45 PM ask).** ADOPTED. Horizontal moves and goes deeper, and vertical only reads. The left edge (24 pt) goes out, and the right edge (32 pt) goes in, first to the glance and then to the full side. The middle swipe goes along a run (days, weeks, a routine's exercises, a side's pages), or goes in when the screen has no run, and a run's end does not wrap. A swipe right goes one step back the way you came. A side has up to four pages named by facet words. Folded into 75: Review gets THE DAYS from the right edge and pages by week in the middle, which drops THE MONTH and replaces 74's "Review: none". An exercise's HISTORY, REP MAXES, MUSCLES and SETUP become one side with four pages, and the middle goes along the routine's exercises. Plans' WEEK and MONTH become a run. Owners: Core 0ak's SideHost owns the three zones, and each screen declares its run and its side's pages. Review (Builder B 0y rollout) and the exercise side (Builder A 0p rollout) ride after 0ak like the other drawn sides. It doesn't block 0p, 0y or 0ak riding the daily pins.

**2:56 PM PT Oct 16: bare-number body questions (Builder B, from #564).** DECIDED. "is 82.4 good?" is walled. A bare number within 10% of his last logged weight is a body fact whether or not a day word is present, which is the same test as 1:58's "82.4 this morning". With no weight logged, a bare decimal next to a body word (weight, weigh, kg, lb, lbs, body fat, BMI) is walled, and anything else stays plain ("is 3.5 good?" stays plain). This goes in Core 0ai, the engine wall rider, so it gates every path, and #564's BottomChrome answer "That stays on this phone." then covers it. Research adds rows.

**2:49 PM PT Oct 16: daily pins, so approved work reaches his phone fast (Kaushik 2:46 PM, Design thread: "I want to see all of these on the phone as soon as possible").** HIS CALL, boarded. (1) DAILY PINS. Today's pin is named at 4:00 PM PT from whatever has merged and passed QA by then, and it waits for no single PR. After today, a pin is named at 4:00 PM PT every day that something he can see has merged since the last install. The gates are the same as for a36b161: test.sh, the v9 gate V0-V4 plus the walls-ui spec (in place of V5), the next-build-v9r.md rows for each rider inside, a Design walk clip of what is new since the last installed pin, the Step 0 copy outside Backups named "Before <sha>" and checked, then an in-place install by Builder A under his standing approval. Research's new-on-your-phone page lists the new lines for each pin. (2) Every daily pin stays on v9 with no catalog change. The Thu Oct 22 9:30 AM call names the LAST v9 pin with the full rider list, and #407 (v10) still merges only after that pin is on his phone. The Fri Oct 23 10:00 AM re-sign fallback stays as a safety net, and each daily install re-signs anyway, which moves the lapse. (3) Approved looks move up, so "after the pins" no longer applies to them. Builder A 0p (72 title round 2 plus 73 area index A), Builder B 0y (74 Today's side, landing with 0p) and Core 0ak (75 SideHost with the 2:44 must-fixes) each sit directly after their lead's open riders, ahead of new work. Each rides the first daily pin it's ready for, and the drawn sides follow 0ak. The goal is that anything he approves is in a pin within two working days. (4) Rollback for daily pins is in pin-checklist §7.

**2:45 PM PT Oct 16: private fields on the generic object page (Design M4).** DECIDED. The generic object page prints every field (ObjectPage.swift:342-360, PropertyList), so a private Tess memory's rule shows in plain text through the class tree. It's a front leak on the installed build, so it's a RIDER: Core 0ai (the one engine wall) adds a private-field mask, and any object flagged private shows its class's private label ("Private note", "Private task", "Private memory") with its fields hidden. That covers the generic page, PropertyList and the class page's "newest" row. Research adds fixture rows, and QA checks it in the riders gate. AMENDED 2:55 (Research BH): (i) no new field and no catalog change. Task has no isPrivate, so 0ai uses a computed check (SecretWords or PrivateFacts on the title, the same router walls). A medicine name with no number waits on 0ac slice 2. (ii) 2:45 supersedes 2:44's PL3: the newest slot shows "Private note" and never skips, so its date stays true. (iii) The mask also covers the generic page HEADING (ObjectPage.swift:227), InstanceBody (:216-275, closing R8's Builder B half) and Linked from (:261) on other objects' pages. Fixtures: private-field-mask.md (20 rows, R18, gate PF1). Also from Design: a page pushed over the live workout isn't live, so it keeps its normal side, and the peek belongs only to the live surface. Inventory S3 is a stale comment for Builder B.

**2:44 PM PT Oct 16: side lines and the inventory (Research BD/BD2, #561).** DECIDED, all as Research picked. (1) A side line is one sentence: "Moved twice, due today." (2) No thing-first on a side, because the side is already the thing's page. (3) Only his own moves count as moves, never the nightly rolls. (4) A habit named for the body ("weigh in") shows its count only, never a value. (5) Cadence ("about every 9 days") comes from a Core helper that reads the op log, part of 0ak. (6) A two-slot glance with more items shows "and N more". (7) "Most-used field" means the field edited most in the last 30 days. The four private leaks BD found (the exercise's hidden notes, the default side printing hidden fields, the class page's "newest" naming a private object, and @Private note title linking at Notes.swift:41-43) are must-fixes in Core 0ak, with the fixes as listed in screens-inventory-check.md. Research checks at 8 pm whether #551 closed the fourth. Design adds the 4 missing screens and fixes the 3 stale rows in screens-inventory.md.

**2:42 PM PT Oct 16: Claude words on Home, "done" moments only (Kaushik's pick at 2:41 PM on AI architecture's card: "Sonnet on Home").** HIS CALL, boarded. It replaces AI-5's "Claude Home wording off". The scope is AI architecture's spec (docs/ai/home-lines-job.md, its next PR): only a finished workout with a best, or one after a gap of 4+ days on the same routine, gets Sonnet 5.5 with SYSTEM_DONE (scripts/ai/home_lines_eval.py). Every other Home moment stays rules-only. It sits behind "Tess asks Claude" and the $50 cap. The rules line shows first, and Claude's differing words land wet and dry. A 6 s timeout falls back to the rules silently. The phone checks each line (HomeLines caps, C1-C15 including the C15 weekday slip), and a failing line keeps the rules line. There's one call per WORKOUT, ever, cached on it, with no retries (a set added after finish only redraws the rules line; Research BG, 2:52), and money and body facts are never packed. The phone runs its own weekday and "yesterday" check on done lines, because the eval script's C15 never fires on done calls. The script's 5 retries and 30 s timeout are eval-only; the app uses 6 s and none. GATE: Core 0t merges first. Owners: Core 0al (the job), then Builder B 0aa (Home). Not a pin rider; it goes in a build after the riders pin.

**2:40 PM PT Oct 16: four wall calls from Research (BD3/BD4).** DECIDED, all as Research picked. (1) The 11:52 AM recipe-link money strip isn't in master, so Builder B 0z owns it with link fetch: ClaudeRecipeReader strips money-shaped spans (the 2:22 money test) from page text before sending, and a fixture proves it. It's a rider only if it's merged and QA'd by Oct 22 9:30. (2) A bare medicine name ("Advil") must be walled. This goes on Core 0ac slice 2 (medicine names walled), and Research adds the bare-name rows. (3) 2:41's "nothing on a side goes to Claude" applies to EVERY side by default. The only opening is a per-class opt-in for public facts (ingredient nutrition, exercise muscles), and only through an ask-about-this behind AppModel.asksClaude. (4) For those public classes (ingredient, exercise), the object's public name may go to Claude along with its id and class. Never for notes, tasks, habits, money, body, or anything private or SecretWords-flagged. Nothing in (3) or (4) runs or ships until the BD4 eval runs with Kaushik's yes in the running thread.

**2:38 PM PT Oct 16: an overnight cook's row time (Design, from #552).** DECIDED. A cook filed on its finish day (decision 1:40) shows its FINISH time as the row time, so it sorts and reads as that day: "9:05 am Cooked overnight oats, 6 h 55 min". Durations of 60 minutes or more read in hours and minutes ("6 h 55 min", "1 h"), and anything under an hour stays in minutes ("45 min"). Clocks stay lowercase per house style. It rides Core's #552 FIX FIRST push, where the row is built, and Builder B picks up any view-side wording. #552 is a rider, so this ships with it.

**2:37 PM PT Oct 16: sides open in two stops (Kaushik 2:33 PM, Design 75 addendum 254f6d5).** ADOPTED. Stop 1 is a half-screen glance (one big fact, two smaller facts, the side's word at its foot, front dimmed under it). Stop 2 is the full side. A swipe right goes back one stop at a time. Every side declares its glance per kind. SideHost (Core 0ak) owns both stops as one piece. The rollout order from 2:41 is unchanged, and every rollout row (Builder B 0y, Builder A 0p, the drawn sides, the rest) now ships its glance with its side. The 2:41 walls apply to the glance too.

**2:36 PM PT Oct 16: Kitchen's sheet 75 calls (#556).** ADOPTED. (1) Pantry is an area with its own front and side, so row 13's "PANTRY later" leaves the Kitchen tab. (2) The app never sums nutrition numbers anywhere, because intake is a walled body fact; the PER 100 G side shows one ingredient's table values only. (3) Before Core bundles the food table, Research BE confirms the USDA FoodData Central licence, picks the per-100 g subset, and writes a 20-key acceptance fixture.

**2:41 PM PT Oct 16: sheet 75, every screen has a side (Design 25b385e, every-side.md; Kaushik's 2:20 ask).** DECIDED. (a) Yes: Habits gets HOW IT COUNTS (facts only, no history), Settings gets WHAT LEAVES THE PHONE, and money gets WHERE IT CAME FROM. Each holds facts only, with its controls on the front, which keeps the earlier "nothing hides behind a swipe" and "never hide behind a gesture" rulings. A side never shows a private fact in a place the front hides it, and nothing on a side goes to Claude. (b) Yes: the recipe page's column swipe to Groceries becomes the INGREDIENTS side's one key. (c) A screen with no side fails review from the SideHost PR on, but only for screens that PR or a later one adds or changes. Existing screens get their sides in the rollout order and don't block other work. Rollout, all after the pins: Core 0ak (SideHost and the default object side: LINKS plus fields the front doesn't show), then 74's three tab sides (Builder B 0y, Builder A 0p), then the drawn ones (workout THE SETS, ingredient PER 100 G, exercise SETUP, note WHERE IT'S MENTIONED, task ITS STORY, Backups WHAT'S IN ONE), then the rest by owner from screens-inventory.md. Research BD checks the inventory against master now.

**2:32 PM PT Oct 16: old links to private notes (QA on #551).** DECIDED. Links made before #551 stay. There's no cleanup migration, because a store change needs testing on a device. They're safe once Builder B 0r hides a private note's body when it's opened from a link.

**2:30 PM PT Oct 16: answers to private questions (QA on #544).** DECIDED, confirmed. A question about money or a body fact gets "That stays on this phone.", and a question about a secret gets "It's in your private notes." (1:58). Neither one repeats the value. Every private note the interpreter writes gets the UNDO slot like any capture: "Private note, kept.", 4 s, or 10 s under VoiceOver (1:15, 1:35).

**2:29 PM PT Oct 16: receipt lows from Design (#547, #544).** DECIDED. The trailing "e1RM 99.4." comes off set receipts. The estimate lives on the exercise page only, and receipts stay thing-first ("Bench 80 × 8, logged."). A new best still says ", best". The bare "Logged." fallback becomes "Set, logged.". Every app string uses straight apostrophes, so "Couldn't save that." is fixed in #544's follow-up.

**2:28 PM PT Oct 16: title accent table (Research BB, fixtures/title-accent.md).** Accepted. The targetSets bug (NowPage.swift:209 reads "sets", so every exercise shows 3 planned sets) is a riders-pin item, Builder A 0r. Today's tasks don't take Tess's colour; Tess's colour is hers alone (Research's pick). Design rules on Research's remaining questions in sheet 72.

**2:26 PM PT Oct 16: pin installed; new signing fallback.** a36b161 went on his phone at 2:24 PM, and the Step 0 copy is verified. The re-sign moved the lapse to Fri Oct 23 at 2:12 PM PT, which replaces 2:13's Thursday 4 PM fallback. The riders pin is still named at 9:30 AM Thursday. If the riders build isn't installed by 10:00 AM Friday, Builder A re-signs a36b161 before 2:12 PM. #407 (v10) now waits for the riders pin to be on his phone (1:43).

**2:24 PM PT Oct 16: every screen has a side (Kaushik, 2:20:25 PM PT, Design thread).** HIS DECISION, which replaces the 10:00 AM house rule ("a page one tap down may have one side page; never a tab page or a live workout"). A screen is a logical unit, and every screen declares its own side swipe; for now, every screen has one. His examples: a workout shows details about itself, a grocery item shows calorie info, and Review has something else. Everything gets redesigned to fit, with every team consulted and AI worked in. Design 74 is boarded now: Today's side is THE DAY (Builder B), Training's is THE WEEK, drawn after LAST TIMES, and Kitchen's is THE WEEK'S COOKS. Design is drafting sheet 75, "Every screen has a side", with the full inventory. Product will rule on Habits and on Settings and money once 75 lands; the leaning is a side that holds only extra facts and never controls. Not a pin rider.

**2:23 PM PT Oct 16: area index lines (Research BA, fixtures/area-index-lines.md, 66 lines).** DECIDED, all of Research's picks. The index uses the context cap (6 words, 32 characters), and Today reuses Home's widgetWords, so there's one source. A finished workout with a best gets one comma form, shared by the index and the widget. Review counts a session once a set is logged (1:00). Over the cap, the line falls back to the hero, then the title, then the area's quiet line. The selection haptic stays on in quiet hours because he tapped. Opening the index doesn't pause an UNDO window. The index shows no kg. A timed cook shows only its hero. Design fixes sheet 73's two 7-word examples and Home's planned-cook row, which has the same 7-word problem.

**2:22 PM PT Oct 16: three conflicts from Research AZ (fixtures/engine-wall.md).** DECIDED. (1) "pay rent 2100 fri" (an imperative, future money) stays a task, because he needs the reminder, but the amount is stripped and dropped like a grocery price (2:09). The task is "Pay rent" on Friday, with the receipt "Pay rent, Friday." Past tense ("paid rent 2100 fri") is still a private dated note (1:15). This settles 12:11 and 12:30 against 1:15. (2) A medicine reminder is a private task titled "Private task", the one exception to "becomes a note". (3) The money test, which replaces 2:10's digit wording: a currency sign, or an amount with a decimal or 3+ digits, or a money verb next to a bare number with no unit noun. "bought 2 lemons" and "6 eggs" stay plain, while "bought shoes 120", "paid gas 45" and "coffee 6.25" are money. Research's engine notes go on Core 0ai: days live in the grammar, memory and the inbox call the check themselves, the tool runner must not undo the private note, and a generic rename must not retitle a private note.

**2:16 PM PT Oct 16: money with no day (QA on #534).** DECIDED. A money line with no day, such as "bought a tv for 800", becomes a private note ("Private note, kept."), never a task. An amount never sits in a task title. With a day, it's a private dated note (2:06). Core 0ai carries the row, and Research AZ adds it to the engine-wall table.

**2:15 PM PT Oct 16: Siri receipts for hidden writes (Research, tell-tess-receipts.md).** DECIDED, Research's pick. Siri never says a bare "Saved.". #534 (P14) merges now, and Core adds TessCapture.privateLine before the riders pin is named (clarified 2:20), which names the kind of thing from the action names only and never from the phrase or the model's text ("Private note, kept.", "Task moved to Friday 9 am."). Siri says that line instead.

**2:13 PM PT Oct 16: signing deadline for the riders build.** DECIDED. a36b161's profile expires Thu Oct 22 at 7:53 PM PT. The riders pin is still named at 9:30 AM Thursday, but if it hasn't passed the gate and been installed by 4:00 PM PT, Builder A re-signs a36b161 with a fresh profile and installs it, so the app never lapses on his phone. HealthKit is entitled on the free team, so Builder A 0m looks for the export problem elsewhere.

**2:12 PM PT Oct 16: Design 72 and 73 boarded; 74 waits.** Kaushik approved 72, the title accent, at 2:09, and picked option A for 73, the area index, at 2:06. Both go on Builder A's board for after the pins (0p). Design 74, side swipes on tab pages, would change the 10:00 AM house rule ("a page one tap down may have one side page; never a tab page or a live workout"). It stays unboarded until Design confirms Kaushik has seen it and wants it. 73 can ship on its own, since the side rail keeps working until 74.

**2:11 PM PT Oct 16: Health round trip (Research AY, fixtures/health-roundtrip.md, 37 cases: 10 pass, 7 wrong, 19 not built).** DECIDED, all of Research's picks. (1) Never write bodyMass to Health. (2) When Health has two weigh-ins on one day, the first after 4 am counts, and Tessera's own entry still wins (1:23). (3) Health weights are kept in memory only, never copied into Tessera's store, and stay out of WeekFacts, Plan my day, memory and Claude. (4) A weigh-in is filed in the sample's own zone, then where Tessera says he was, then the phone's zone. (5) Exported workouts carry their time zone. (6) Failed finishes are retried from an owed list. (7) If Health saving is off, Settings shows one line. (8) The sync version becomes a change counter. (9) Builder A confirms on his phone that HealthKit works with the free Personal Team before anyone builds the weight read. HR37 rides the next pin: project.yml:74 promises only body weight reads, not workouts or heart rate. Taking back a finish removes the Health workout (12:45). That is HR16, needing the exporter's delete plus undo notifying observers.

**2:10 PM PT Oct 16: "bought shoes 120" (QA on #534).** DECIDED: yes, it's money and walled. After a purchase verb (bought, paid, spent, got ... for), a trailing number counts as an amount: a 2-digit or bigger whole number, or any decimal ("bought shoes 120", "paid gas 45.20"). A count before the thing stays plain ("bought 2 lemons", "got 6 eggs"), and so do units and packs ("bought 2 lb chicken"). Following 1:36, when it's unsure it leans walled. With a day, it's a private dated note (2:06). Core makes this change in a later PR on 0ac.

**2:09 PM PT Oct 16: prices on grocery and list items (Kitchen lead).** DECIDED, Kitchen's pick. A price is stripped and dropped and the item stays: "milk $4", "milk 4.99" and "2 for $5 avocados" give milk and avocados, with no price kept on the row, in a note or in the receipt. The receipt is "Milk, on Groceries." (12:35 and 1:48 wording, not "Milk, added."). Packs and amounts are not prices, so "2 lb chicken", "14 oz can" and "6 eggs" keep their numbers. A line that is only money ("rent 2100 fri", "$40 at costco") never lands as a row; it becomes a private dated note (2:06). On lists, body and health items stay items (a packing list needs its meds) but are walled from Claude. Core 0ai and Builder B 0w follow this, with Kitchen's acceptance rows in groceries-ai-acceptance.md §6 and lists-acceptance.md §8b.

**2:08 PM PT Oct 16: Face ID on Siri workout intents (Core #534).** DECIDED. #534 merges as built. In a later Core PR: while a live workout is running, LogSet and FinishWorkout skip Face ID, because the workout was started on an unlocked phone, a set isn't a private fact, and asking for Face ID between sets breaks training. With no live workout, they ask for Face ID as #534 does. StartRoutine keeps Face ID. The Live Activity Done and UNDO buttons stay without it (12:26). Tell Tess's "Saved." for a hidden write gets a thing-first form later (Research low).

**2:06 PM PT Oct 16: one wall at the engine (Research AX, input-paths-walls.md: 32 paths, 10 walled, 13 leak).** DECIDED. Path-by-path walls keep leaking, so the fix goes where every path lands. Core 0ai, a rider, comes right after 0ah. Every action that writes user text into a title (CreateTask, CreateRoutine, AddGroceries, a list item, and an on-device model write) passes one shared check, PrivateFacts plus secret words, in the engine. Secret text never becomes a title: the action becomes a private note and the receipt says "Private note, kept." Money or body text with a day becomes a private dated note (the 1:15 rule), and so "rent 2100 fri" stops being the task "Rent 2100" (parse order TessGrammar.swift:513-543 vs :141, on 0aa). After that, the views need only one line each. Builder B owns Groceries' Add line (GroceriesView.swift:365) and the PasteRecipe miss log. Builder A owns Routines' Name it (RoutinesPage.swift:108). Speak is covered by 0v. Tess memory turnover skips money and body Day log lines (TessMemory+Turnover.swift:67) on 0ac. Research's 25 new WallsUITests rows join AU's suite, and key rows are built at runtime only.

**2:00 PM PT Oct 16: evenings and quiet hours (Research AW, fixtures/evening-quiet.md, 40 evenings: 9 pass, 10 wrong, 21 not built).** DECIDED. All 11 of Research's picks stand: (1) a Finish after 11 pm closes the day quietly, stamped 10:00 pm, with no Shutdown page; (2) a hold that never ends closes at the 6-hour wrap-up or at 4 am, whichever comes first; (3) "until the clock ends" means the recipe clock's last step, and a timer ending doesn't release the hold; (4) Shutdown has no "not now" and leaving the page is the not now; (5) the 7 am snap covers every time he didn't type, lands on the next 7 am, and the receipt names the day; (6) quiet hours use the phone's local time on trips; (7) a close that waited for Shutdown on screen is stamped 10:00 pm; (8) a task timed later tonight isn't a "moving to tomorrow" row; (9) a time he typed still rings in quiet hours; (10) "tonight" isn't snapped; (11) a cook started over Shutdown takes the hero and holds. EQ26 is therefore wrong: "Not now" at 11:20 pm goes to 7 am. The day log cook (EQ14) is the 1:40 rule, already on Core 0ae G2.

**1:58 PM PT Oct 16: wall gaps from Research AU (walls-ui-test-spec.md, 36 rows, 23 pass).** DECIDED. (1) The "?" leak goes FIRST in the rider order. A phrase ending in "?" skips Tess and CommandInterpreter saves it as a task (BottomChrome.swift:508-509, CaptureParts.swift:184-188), so "door code 4417?" becomes a plain task in Home, the Day log and backups. "?" phrases now pass the secret and private walls before CommandInterpreter. A secret one becomes a private note, and a question about a secret gets "It's in your private notes." Builder B 0v owns it, with Core's interpreter half in 0ah. (2) The miss log checks PrivateFacts.isWalled as well as secret words (TessCaptureEngine.swift:58, PasteRecipe.swift:205). This is Core 0ah too, in the same PR. (3) The Notes page shows "Private note, kept." (NotesView.swift:118-127). That's Builder B, for the next build, with 0p. (4) "82.4 this morning" becomes a body weight entry only when it's within 10% of his last logged weight. Otherwise it's a private note. Either way it never goes to Claude. W5 follows this, and Core 0ac owns it with HW13. AU's spec replaces V5 and walk beats 7-8 (the wifi half). His optional line after install is the Notes "wifi password" check.

**1:56 PM PT Oct 16: rider order for Core and the builders (Research AV, next-build-v9r.md §0).** DECIDED. Core has too many riders for Oct 22, so it works them in this order. Each is a small PR of its own, and none waits for another. (1) 0ad PN-MENTION: a live privacy leak on his phone. (2) 0ae trip bands: the trip is Oct 26. (3) 0ag DS8: it bites on the night of Oct 31. (4) 0ac HW19 with CR1. (5) 0aa N15. (6) P14 and HW13. (7) 0ac HW9. (8) 0af. Builder B does 0r first, then 0t and 0u. Builder A does 0n, then the UNDO slot. The UNDO slot (F1-F4, across all three teams) is not a riders-pin item unless it is merged and has passed QA by the branch call.

**1:52 PM PT Oct 16: Nov 1 DST fixes (Research AR, fixtures/dst-nov-1.md, 42 cases: 25 pass, 6 wrong).** DECIDED. DS8, where a 1:30 am task said in the repeated hour lands a day or a week late, is a riders-pin item (Core 0ag), because it bites on the night of Oct 31. DS29 and DS36 ride with it if there's room. The other three are small PRs whenever they're ready: DS18 and DS35 to Builder A (0n), DS37 to Builder B (0u). Day math everywhere uses calendar days and the 4 am day, never a count of seconds.

**1:51 PM PT Oct 16: riders pin cut-off (Research AT, next-build-v9r.md).** DECIDED. The riders pin is named at the Thu Oct 22 9:30 AM branch call with whatever riders have merged and passed QA by then, because signing lapses around Oct 23 and a new build has to go on anyway. It does not wait for any single rider. 0ae is the most wanted, since the trip starts Oct 26, but if it misses, the trip only gets wrong Review bands with no data loss, and it rides the next pin. HW19 goes in only together with CR1; if CR1 slips, both slip. Once the riders SHA is named, it (not a36b161) becomes the rollback after v10 in §7 and in the drill's Pin column (line proposed in next-build-v10.md §3).

**1:50 PM PT Oct 16: no older-build rollback after the pin.** DECIDED, option (b), which supersedes 12:16. Once a36b161 is on his phone, no older build is installed. 7b321d2 opens the v9 store but would show private notes' text, because it predates #422. If something is wrong, Builder A rolls forward with a fix, or restores the Step 0 copy ("Before a36b161") on a36b161. This is why Step 0 is checked before installing. After v10, the §7 after-v10 rule applies.

**1:48 PM PT Oct 16: UNDO slot words (Research AS, fixtures/undo-slot-voiceover.md, K1-K16).** DECIDED. All of Research's picks stand. C1: undoing a removal says "Thing is back." (deleting a note, dropping a routine, the backup folder, the Claude key), and new things and changes say "Thing, taken back." C3: VO20 and VO40 (pause while focus is on Undo) are struck, and the window is a flat 10 s under VoiceOver. C4: "82.5 kilograms for 8". C5: "Milk, on Groceries." replaces "Milk, on the list." (Builder B). C6: the 4 am roll and the wrap-up are one claim, and UNDO takes back both. The invented strings are approved, including every hint, "Call mom, carried into today.", "Private note, deleted." / "Private note is back.", "Claude key replaced.", "Tacos, partly taken back. 2 stayed on Groceries." and "N seconds left". Q2: a plain note is named by its first 8 words. A private note (isPrivate, secret words, money or body) is ALWAYS named "Private note" on the line, in the label, in the announcement and in the taken-back line, and its text is never spoken (coordinator 1:47). Q3: Magic Tap does not undo (LOG keeps it in a live workout). Q4: a private phrase's ghost reads "Private note". Announcements are high priority, never move focus, and the window closes silently.

**1:43 PM PT Oct 16: next pin stays v9; v10 ships alone (Research AQ).** DECIDED, Research's pick. The next pin carries v9 riders only (PN-MENTION, N15, P14, sick words with CR1, the UNDO slot, the 0ae trip bands, the Step 0 name), so a rollback to a36b161 still opens his data. #407 and the eyes setting come after it as a v10 pin of their own. This replaces 12:58's "#407 once the pin is on his phone". The v10 page's "opens empty" line applies only to that later pin. His v9 page also gets a general "Not yet fixed" line: a note that mentions a private note can still open it, so hold off @mentioning private notes until the next build. Research makes a tiny PR. Builder A sends .backgrounded from scenePhase so #403's settle runs.

**1:41 PM PT Oct 16: Step 0 copy and v10 rollback (Research AN, v10-rollback-drill.md).** DECIDED. (1) Starting with today's install, the Step 0 copy is saved outside the Backups folder and renamed "Before a36b161" and checked before installing, because a "Tessera-<day>" copy in Backups is rotated with the dailies. Core 0af changes the default name to "Before update <day>" and keeps rotation on the rolling prefix only; Builder B 0t adds the Backups-folder warning. (2) Pin-checklist §7 is corrected: restoring Step 0 on a36b161 keeps the v10 store as a Before-restore copy, so only work done during the in-memory rollback is lost. (3) 7b321d2 is never installed again, because it predates #422. (4) Builder A runs the drill (R0-R6) on the named v10 SHA in the Simulator, and QA reads the evidence.

**1:40 PM PT Oct 16: a cook's day (Research AP, trip-week.md G2).** DECIDED. A cook belongs to the day it finished, everywhere: the Day log, WeekFacts, Review's cooking band and Home. The Day log changes (DayStory.swift:241-249), so Tuesday's mark and Tuesday's cook line agree. This rides with Core 0ae before Oct 26.

**1:36 PM PT Oct 16: private health words (Research AO, private-health-words.md).** DECIDED. Slice 2 is yes as Research proposed it. All five picks stand: (1) a bare "PT" stays plain, because it usually means his trainer; (2) a flu shot, a covid booster and "buy covid tests" stay plain, like the dentist; (3) "stressed" stays plain and "anxious" is walled; (4) calories burned stay plain and calories eaten are walled; (5) "pain in the neck" walled is an accepted over-wall. When unsure, the rule leans toward walling, because a miss only keeps a line on the phone. Slice 1 (sick and unwell) ships only with the CR1 slang mask. Core 0ac owns both slices.

**1:35 PM PT Oct 16: one UNDO slot (Research AM, undo-collision.md).** DECIDED, Research's rule stands. The app has one UNDO slot, and the line on screen and the UNDO key are one claim. A newer claim closes the older one. The window opens when the line shows: 4 s for a new thing, 10 s for a change, 10 s for everything under VoiceOver, paused in the background. The receipt is "Thing, taken back." The owners are Core 0s (pure UndoWindow), then Builder B 0i (UndoSlot, BottomChrome, lastCapture at line time) and Builder A 0i (live corner, canUndoLast window). This refines 12:45 and is F1 on next-build-v10.

**1:33 PM PT Oct 16: pin page check (Research AK, pin-page-check.md, PR #516).** DECIDED. (1) Tapping a day's training mark in Review opens that workout (ReviewPage.swift:267-272); that's the drill-in principle, so it stays, and his page says "opens that workout". (2) Review's task and cooking bands count by each item's own zone like training does; Core 0ae, before the Oct 26 trip. (3) " · 15 oz" is cut from his v9 page because packSize(of:) has no caller; Builder B 0s wires it for a later build. The 10 partly-true lines stay as Research corrected them.

**1:27 PM PT Oct 16: rollback after v10 (Research next-build-v10.md asked).** DECIDED. Research's section 7 wording stands. After v10 the rollback is a36b161, which opens in memory and shows none of his data, so the real way back is rolling forward or restoring the Step 0 copy. 7b321d2 is never installed after v10 because it would write to the v10 store. The next build's gate and list are next-build-v10.md. F1 (the capture UNDO taking back a Home "done") is the top fix after the four next-build-first rows. #504 (", best") and #403 are already on master, so the next pin needs #407 rebased with nonisolated kept and the v9-opens-v10 test, then R7 flag-to-setting, then the Design 70 row.

**1:23 PM PT Oct 16: habits and body weight (Research habits-weight-week.md asked).** DECIDED. All six of Research's picks stand.

Body weight:
- Apple Health is read only in v1. One entry a day. Tessera's entry wins, and Health fills the gaps.
- Siri says "Body weight logged." and never says the number.
- Body-shaped questions with no number ("what did i weigh monday", "bw trend") stay on the phone.

Sick days:
- "was sick monday", said on a Thursday, becomes a private note dated Monday. It sets no mark.
- A sick mark holds every habits ask that day. Rest and skip marks don't.
- "sick", "unwell" and "feeling sick" join PrivateFacts first on the next build.

Also: a past-tense log with a past weekday ("meditated monday" said on Thursday) logs to that day. It never becomes next week's task.

**1:22 PM PT Oct 16: default task times never land in quiet hours (QA on #507).** DECIDED, QA's suggestion. If a task given only a day would default to a time inside quiet hours (23:00-07:00), the default snaps to 7 am instead. "call mom thu" typed at 1 am becomes 7 am, not 2 am. A time he types himself is kept as typed.

**1:16 PM PT Oct 16: the pin stays a36b161b (coordinator, on Research's N13/N15 flag).** DECIDED.
- No re-pin mid-gate. 7b321d2 has no private notes at all, so this build is strictly better.
- Two fast follows go at the top of the next build: Builder B's NoteRow isPrivate guard (NotesView.swift:186-216, 0p) and Core's pre-#422 note pass (DayStory.swift:347, 0aa).
- His page gets one honest line about both.

**1:15 PM PT Oct 16: Notes day one (Research notes-day-one.md asked).** DECIDED. Eight of Research's nine picks stand; I changed one.

Changed:
- Pick 3: "paid rent 2100 fri" (past tense with an amount) becomes a PRIVATE dated note, the same as the Siri routing Core is already building (12:26). Money with an amount stays private everywhere.
- "bought 2 lemons sat" stays a plain dated note, since a count is not an amount.

Stand as picked:
- The Notes page gets a receipt with a 4 s UNDO: "Note, kept." or "Private note, kept."
- Body facts typed on the Notes page, or after "note:", go private.
- He can't toggle private by hand in v1.
- A multi-line paste opens a new note in the editor and keeps its lines.
- A bare URL said to Tess becomes a note holding the link, with nothing fetched.
- An account-number line makes the whole note private.
- The 200-note cap is lifted now. Search is parked until Spotlight, and private notes are never indexed.
- VoiceOver announces the key line and the receipt.

Pin: N13 (a private note's row shows its second line) and N15 (notes from before #422 are not marked private) do NOT hold a36b161b. 7b321d2 shows every note in full, so neither is a regression. Both ride the next build first.

**1:13 PM PT Oct 16: Settings day one (Research settings-day-one.md asked).** DECIDED, all eight of Research's picks.

The Claude key:
- A 401 keeps the key and reopens the writing line. settings-claude S7 and S22 get rewritten to match.
- Removing the key reads "Claude key removed. Leaving the app makes it final."
- Replacing the key holds the old one for 10 s with UNDO, the same as REMOVE.

Wording:
- The switch's yes line is "Tess asks Claude when she's unsure." until Plan my day goes through Claude.
- The backup receipt reads "Copy, saved."
- Until the Settings page ships, every pointer line says "Review, under Claude".

Layout:
- Settings has five sections. TESS (What I know) is added only once that page exists.
- UNITS is built now, as plain text.

**1:08 PM PT Oct 16: PIN NAMED, a36b161b7294596848a319c0cc0fc50a3b25f2ee** (master after M1 #498, 1:07 PM PT). DECIDED.

Checked on the SHA:
- Catalog v9 (SystemCatalog.swift:350).
- 0bff60b, 70112f9 and 7b321d2 are ancestors.
- No #403 or #407 merge.

It carries:
- #366 Home lines, with the 4 am day label.
- #451 MU2 + A2.
- #422 secret words and the $50 cap.
- #446 stuck listening.
- #454 paste/link wall and #457 Siri I3.
- #471 B1 and the privacy follow-ups.
- #475 B5/B6 newer-catalog refusal.
- #494 T1/P1.
- #498 M1.
- The trip rows.

Not in: P14 (Siri PrivateFacts), ", best" in DayStory (it still says ", PR" at :225), and the pre-#422 note pass. These ride the next build.

Next steps: Builder A runs the v9 gate (V1-V6, test.sh "All green") and Design's 9-beat walk, then Step 0, then installs in place over Wi-Fi under his standing approval. After that:
- #403 rebased.
- #407 once the pin is on his phone.

**1:06 PM PT Oct 16: Shutdown evening (Research shutdown-evening.md asked).** DECIDED, all six of Research's picks.

The 9 to 10 pm hero:
- Once Shutdown is built, the hero from 9 to 10 pm is Shutdown.
- Until then, Now shows "tomorrow, first" (12:35).
- shutdown-flow.md and Design m4 §7 change "evening" to "night".

What holds Shutdown:
- A paused workout, the same as a live one.
- A running cook, until DONE or the clock ends.

Wording:
- A secret-word task shows as "Private task" on the hero, the widget and the Lock Screen.
- The first-Shutdown line is "Tap any for later."

Trips: the 10 pm close uses the phone's local time.

**1:05 PM PT Oct 16: Kitchen week v1 (Research kitchen-week-day-one.md asked).** DECIDED, all three of Research's picks.
- Kitchen week v1 is Design 67 inside Groceries and Home, with no page of its own.
- "what's for dinner" becomes a grammar rule (Core).
- Move and DONE receipts use short names: "Tacos, Friday." and "Tacos, cooked."
Also decided: a dated cook task ("cook tacos tuesday") adds that recipe's share to Groceries once, and skipping or deleting the meal takes the share back.

**1:00 PM PT Oct 16: Review week story (Research review-week-story.md asked).** DECIDED, all eight of Research's picks.

How the week is counted:
- On Monday morning, the story of the week that just ended stays under the new week until Tuesday 4 am.
- A paused session counts as trained if a set was logged.
- An empty or notes-only week skips the Claude call.
- With a day mark, the figure counts against the marked week ("5 of 5").

How it reads:
- Three plain count lines, such as "4 workouts, 2 new bests, 3 cooks".
- Tapped-day times are 12-hour.
- Trip-day times show in the zone he was in.
- "weight down 0.4 kg" leaves the story and stays on the body page only.

Pin rider (small): DayStory writes ", best" instead of ", PR" (DayStory.swift:225). It goes in if it lands before M1 merges.

**12:58 PM PT Oct 16: eyes and v10 after the pin (Research post-pin-403-407.md asked).** DECIDED, all four of Research's picks.
- The "Tess has eyes" row lives under LOOK (Design 70).
- The eyes hide while Tess is working.
- The .backgrounded-to-rest change ships with #403 if the router and working tests pass.
- The v7 floor test isn't rerun, since v10 only adds a field.
Order after the pin:
1. #403, rebased on #453's working overlay, with MotionPolicy instead of raw animations.
2. #407 once the pin, carrying #475 and M1, is on his phone. Add one test where v9 code opens a v10 store.
3. Builder A swaps the launch flag for the showsTessEyes setting. Builder B adds the Design 70 row. The key name in code, tessEyes, wins over tess.eyes in the doc.

**12:54 PM PT Oct 16: Plan my day before wiring (Research plan-my-day-pack refresh asked).** DECIDED, all nine of Research's picks.

Before Builder B wires Plan my day:
- Core lands G1, G4 and G7 first: includesEventTitles off by default, a check for a running workout, and a correct cost estimate.
- AI-5 doesn't gate Plan my day. It has its own gate.

What goes to Claude:
- Event titles go to Claude as "busy" only in v1, matching Home. The 23 packs rerun with "busy" events. That's a key-using run, so it needs his yes.
- A medicine with no dose is private when the word is a known drug. "Dentist" and "Book physio" go as "task".
- "combination" alone isn't secret, so "Buy combination lock" stays a task.

What he sees:
- One kept row reads "Plan, kept." with a 4 s UNDO.
- Claude's times are re-rendered through the one formatter.
- An open at 6:40 am is silent. He can pull the plan by hand.
- Abroad, the cap line reads "Paused until Nov 1" with no PT.

**12:50 PM PT Oct 16: AI-5 verdict, Home wording stays on the rules (#488).** DECIDED.
- Neither model ships Claude Home wording yet. The rules lines stay the default and the switch stays off.
- Haiku fails True on both passes. Sonnet fails True and Voice on memory ("After work, your usual slot" three times on a Saturday).
- Next steps:
  - Core adds a weekday check on "usual" and "after work".
  - AI architecture narrows the prompt with Research's rule, then reruns Sonnet only. The rerun needs his yes.
- Claude wording only earns its cost on done moments that add a best, a gap or a count change.

**12:45 PM PT Oct 16: undo windows (Research undo-windows-audit.md, #485, asked).** DECIDED, all six of Research's picks.
- Undo windows pause while the app is backgrounded or the phone is locked.
- Removing the key still commits early when the app goes to the background, because the key is safety-critical, and the line says so.
- Recipe to Groceries gets 10 s.
- A capture's window counts from when its line shows.
- Siri undo has no window.
- Plain hold-to-finish gets a 10 s UNDO.

Also decided:
- There is one shared window constant that knows about VoiceOver (10 s for all when VoiceOver is on).
- Every UNDO line names the thing ("X, taken back.").
- Deleting a note gets an UNDO.
- Undoing a finish removes the Health workout.
- At 4 am, an UNDO under the wrap-up and the roll takes back both or shows two UNDOs.

**12:40 PM PT Oct 16: $50 cap math (Research cap-math-check.md, #482, asked).** DECIDED, all five of Research's picks:
- The month resets at Pacific midnight on the 1st, wherever he is.
- This month's spend is also kept in a small file outside the store, which restore never touches, like the forget log. The cap takes the higher of the two.
- AI architecture rechecks the Sonnet cache-read price on the models page, and Core matches it.
- "Paused" shows as soon as a call is refused.
- A timed-out call counts its full held amount.

**12:39 PM PT Oct 16: VoiceOver on the recipe clock and Lists (Research voiceover-recipe-clock-lists.md asked).** DECIDED, all six of Research's picks.
- "425°F" is spoken as "425 degrees".
- The lit step uses the "Now" value.
- A step timer uses only the notification while he's in another app.
- The pause line is "Paprika chicken, paused."
- A finished section announces "Bathroom, all done." once.
- With VoiceOver on, every undo window is 10 s.
Owner: Builder B owns everything on the recipe page, including its cook states and their VoiceOver. Builder A owns the timers, the Live Activity and the notifications (G2, G7's timer, G8's line).

**12:38 PM PT Oct 16: Lists phrases (Research lists-slice-8-phrases.md asked).** DECIDED, all eleven of Research's picks.

How phrases route:
- On a list page, a bare "milk" goes to that list; "buy milk" goes to Groceries.
- "reset gym bag" resets at once, with a 10 s UNDO.
- "new list lisbon fri" drops the day and makes a list named "Lisbon".
- "pack" when two lists start with "Pack": ask "Packing, or Packing, Lisbon?"
- "lisbon" finds the one list whose name holds that word.
- "pick from films" opens the pick moment when Films is on screen; otherwise it says the pick.

What he sees:
- An item already on the list: "Socks, already on Packing." "charger" beside "phone charger" is a new row, not a duplicate.
- A copied list: "Lisbon, copied from Packing."
- "done" with items left: "Packing, Lisbon, done. 3 left."
- A dated add: "Charger, on Packing, tomorrow."
- The context line keeps each list's own case: "6 lists, Gym bag running".
- A name with no matching list: "No list called Costco."

My own calls:
- A label before a colon ("packing:") sends the phrase to that list ahead of the food rule.
- Plural "pins" is not a secret word.
- In "add X to <list>", "sun" is never read as Sunday.

**12:37 PM PT Oct 16: standing install approval (Kaushik, 12:36 PM PT, Builder A's thread).** DECIDED by him. Builder A may install the named pin whenever his phone is reachable over Wi-Fi, without asking. Standing approval removes asking him, not the gates. Only the named pin SHA installs, never master (master is v9 and his phone holds a v5 store). The safety steps all stay: Product names the SHA, the gate, QA and the Design walk pass, Step 0 SAVE A COPY runs, the install is in place, the app is never deleted, and he gets one line after.

**12:35 PM PT Oct 16: time words (Research time-words-sweep.md asked).** DECIDED, all six of Research's picks.
- "early morning" is only the label; lines say "early this morning".
- From 9 to 10 pm the label says "night", to match "tonight".
- At 9 pm Now flips to "tomorrow, first", even before Shutdown is built.
- Now's context line uses digits ("next, at 6:30 pm").
- At 1 am, "tonight" means the coming evening, and Tess's receipt names the day.
- Backup and Settings belong to Builder B.
Also: every clock string is 12-hour with "am"/"pm", from one formatter, including the Live Activity and the Claude receipt. Every weekday comes from the 4 am day. "ago" counts round to the nearest hour everywhere, as HomeLines.ago does, with "1 hour" singular.

**12:35 PM PT Oct 16: receipts name the thing first (Research receipts-thing-first.md asked).** DECIDED, all six of Research's picks.
- RC23: Claude and the on-device fallback get one thing-first line per action. The summaries stay as log text.
- List receipts name the list: "Rice, on Groceries."
- A new list reads "Films, made."
- A private health memory says "Health note, kept on this phone." It names the kind, never the value.
- "Sent … to Claude" on the first miss is a notice and stays as is.
- An undo with several changes names the thing: "Push A, taken back."

**12:30 PM PT Oct 16: Siri parity with the Ask bar (Research siri-privacy-parity.md, #479, asked).** DECIDED, all of Research's picks:
- Money with an amount and no day: Siri says the Ask bar's miss line and saves nothing.
- A walled title that stays a task because a day wins: Siri says "Task added for Fri." and doesn't echo the title.
- "buy milk" on Add a Task stays a task.
- "reset my PIN" is a task, with the title hidden from Siri's reply.
- A medicine reminder with a time is a private task: it keeps the 9 pm reminder and shows "Medicine" as the title.
Two more: money phrases never go into the capture-miss log, and an empty Add a Task title asks for one instead of throwing.

**12:29 PM PT Oct 16: Home lines day one (Research home-lines-day-one.md on #366's head asked).** DECIDED.
- #366 has to fix its day label before it merges, since it's a pin blocker. The label takes its day from the 4 am day (HomeData.lanes), not the wall clock (HomeLineHero.swift:101).
- Part-of-day words follow the line: "tonight" from 9 pm, and "early morning" from 4 to 7 am.
- Research's other picks: after Shutdown, Now reads "tomorrow, first". A running cook or shop takes Now. Calendar events show on Home as "busy" rows only in v1. An empty day says "All quiet." once.
- Now picks only tasks in the current 4 am day, so Sunday's 9 am task never takes Saturday night.
- A workout planned today is never shown as an empty day.

**12:27 PM PT Oct 16: Lists day-one wording (Research lists-day-one.md asked).** DECIDED.
- With lists but nothing running, the context line reads "4 lists, nothing running".
- The add receipt is "Charger, on Packing.", thing first, like every receipt.
- The back word is "< Kitchen" in source, with .textRole(.label) and .textCase(.uppercase), so it shows as < KITCHEN (Design, as RoutinesPage.swift:34). Its accessibilityLabel is "Back to Kitchen".

**12:26 PM PT Oct 16: outside-the-app privacy (Research spotlight-widgets-privacy.md asked).** DECIDED, all four of Research's picks.
- Siri writes (Tell Tess, Add a Task) need Face ID, while the rest Live Activity buttons stay usable on a locked phone.
- The planned set may show on the locked Lock Screen, since training load isn't a body fact.
- Titles that trip the secret-word or money/body checks are hidden from Spotlight, Siri replies and the Live Activity.
- Every free-text field on a future widget gets .privacySensitive.
- P14 joins the pin as a rider: Siri's Add a Task checks PrivateFacts, saves a walled title as a private note, and doesn't read it back.

**12:22 PM PT Oct 16: backup and stale-ask calls (Research #474 asked).** DECIDED, all four of Research's picks.
- B1-11: Notes refuse any text that contains the Claude-key prefix. This uses the shared guard, not only key-length text.
- I-4: restoring an iCloud copy, which leaves out private rows, keeps the phone's private rows; it never wipes them.
- S3: a waiting ask drops when its live line fades.
- S6: after a long time in the background, an ask drops at the same idle limit tidyProcesses uses (rest plus 10 min).

**12:21 PM PT Oct 16: past-tense logs with no amount are ordinary notes (coordinator asked on #471).** DECIDED. "paid rent fri" and "bought milk sat" are ordinary dated notes. They are not private: with no amount there's no money fact, so they can show in Spotlight and reach Claude like any note. "bought 2 lemons" is the same, since a count is not an amount. This is a small Core follow-up (0j) and doesn't hold #471.

**12:16 PM PT Oct 16: rollback after the pin is 7b321d2 (Research oct-22-list asked).** DECIDED, Research's default. Once the pin is on his phone, rollback is 7b321d2, the only older build tested opening the v9 store (gate V4). 444e72b (v5) is the rollback only before the pin. On re-sign day he builds the exact commit and never pulls master.

**12:13 PM PT Oct 16: Tess's wake is at 7 am (Research tess-picks-signals asked).** DECIDED, Research's default. Idea 2's wake waits for the first open outside quiet hours (7 am), not the 4 am day boundary, so resting ends at 7. Idea 4 doesn't swell in quiet hours. A stroke while she sleeps still answers his touch. The motion lab can refine the look.

**12:12 PM PT Oct 16: backups (QA review-backups.md).** DECIDED.
- B1, a Claude key pasted into Notes ending up in every backup, is the first pin rider. It doesn't block the pin, since 7b321d2 already has the gap, but it goes in if it lands before #366.
- B5/B6: the newer-version refusal is a pin rider, second after B1 (coordinator's recommendation, 12:12 PM PT). The v9 build must refuse any store or backup from a newer catalog. If it misses the pin, #407 (v10) waits until a build with the guard is on his phone.
- B8: private memories stay out of the iCloud copy, so "on this phone only" stays true. Local copies keep them.
- B2: cleanup never deletes a manual "Save a copy".
- Everything else goes on the Core and Builder B boards in QA's order.

**12:12 PM PT Oct 16: background Claude jobs and the soul (Research soul-ask fixture asked).** DECIDED, Research's default. The week story shows Tess working, because he opened Review and is waiting for it. Home lines send nothing, because they run while he isn't looking (home-lines-job.md §7). askClaude fires only after the walls and the cap check pass, so a refused ask makes no event. The recipe handoff says "Asking Claude to read the recipe." (Design, G7: a line says Claude when something leaves the phone); the fetch before it stays "Reading nytimes.com.".

**12:11 PM PT Oct 16: a day wins over the money guard (Research group N asked).** DECIDED. When a phrase has both an amount and a day ("pay rent 650 fri", H609, H610, A012), the day wins: it is a task (or a dated note for past tense) on the phone, never the miss line, and the amount never goes to Claude (Plan my day sends it as "task", 12:06). A money verb beats the set shape: "paid 20 for 2 tickets" is money, not a training set (PrivateFacts.isTraining). L1 already stands from 12:02: body and health facts stay on the phone with no number. "get a combination lock" is a grocery row, per the kitchen rules.

**12:06 PM PT Oct 16: recipe clock, running over holds (Kitchen #461 asked).** DECIDED. When a timed step's timer ends, the bead holds at the step's end and the step stays lit until he moves on; the clock never lights the next step itself. Kitchen's ruling stands, same as the 12:05 entry. "5 more" stretches the held step and restarts its own timer; the minutes ahead shift. Gaps G1-G12 are on the Core, Builder A and Builder B boards with the 69 work.

**12:06 PM PT Oct 16. What a screened plan title becomes (Research plan-my-day pack).** A screened task goes to Claude as "task", a screened event as "busy"; any older "busy" for tasks or "Private task" is superseded. Money words with no amount ("Pay electricity bill") go as typed, matching 12:04; a medicine with a dose is a health fact and is screened.

**12:05 PM PT Oct 16. The recipe clock waits for him.** When a timed step runs over, the bead waits at that step's end until he moves on, and the later minutes shift; the clock never walks ahead of the pan. **Why:** the clock should match what's actually happening on the stove.

**12:04 PM PT Oct 16. "pay" with no amount is a task.** The money guard fires only with an amount or a currency sign; "pay rent fri" is a task and "paid rent fri" or "bought milk sat" is a dated note for that day (the past-tense log rule), as before #298. Rides the pin if in time, since he types these weekly.

**12:03 PM PT Oct 16. Secret words widen slightly (#454).** SecretWords now splits on newlines and knows "pw" and "pwd", so "pw for gym locker 4417" becomes a private note too. That is his rule applied, not a new one.

**12:02 PM PT Oct 16. MU2's leftovers (QA lows on #451).** Body and health facts stay on the phone even with no number ("slept badly", "knee hurts") and with a percent ("body fat 18%"), and "paid N for M" is money. Both go in one small Core follow-up, a pin rider. Reading "6.30" as money fails safe and waits.

**11:57 AM PT Oct 16. Shutdown and a live workout (Research 148 ★).** If a workout is live at 9 pm, Shutdown waits for Finish, and the 10 pm close waits too: it runs after Finish, stamped 10:00 pm, with the workout filed on the day it started. The close also waits while Shutdown is on screen and keeps his draft until 4 am. A first open after 10 pm writes the closed mark without moving rows. Rows kept for tomorrow count as rolls. CL10 beats C7 for the check-in only. **Why:** the live workout band stays quiet, and nothing closes under his hands.

**11:55 AM PT Oct 16. Day marks reach back one day (Research 147 ★).** He can mark today, tomorrow, and yesterday ("was sick yesterday"), so Review shows rest instead of a miss for the day he just had; nothing further back, so a week can't be rewritten. Body words in a mark ("sick") stay on the phone (MU2's body screen) and memory only ever says "rest day". **Why:** a miss ring on a sick day grades him for something he couldn't help; one day back covers the real case.

**11:52 AM PT Oct 16. Recipe pages and the money wall; rest-day defaults.** A recipe page's prices are not his money, but the rule "money never goes to Claude" is kept literally anyway: the recipe-link job strips money-shaped spans from the page text before sending rather than refusing the page (a recipe reads fine without prices). His own words still pass every wall. Redirects are refused for all Claude callers. Rest day (Research 146): first launch of the build with the reader writes Sunday as one op with UNDO (his Oct 15 "Sun rest"); a session trained on Sunday anyway advances the roll; changing the rest weekday never redraws past weeks.

**11:50 AM PT Oct 16. Two wording conflicts (Research 143).** Times in heroes carry "pm": "Push A at 6 pm", "Tacos at 7 pm" (the Oct 15 rule "digits with a lower-case pm in heroes" stands; any older "at 6" is superseded; HomeLines.swift:272 changes). The Day log keeps its own grammar ("Done: call the bank", "Added 2 tasks"), as Design drew it in day-log-v1.md: it is a log, not a receipt, so the thing-first rule covers receipts, Siri replies and memory lines, not the Day log. The Review hero count stays in words ("All six sessions in").

**11:47 AM PT Oct 16. Monday's week-two calls (Research 144, for 101 at 8:15 AM PT Oct 19).** Q4 "Yes, Sunday": keep the rolling plan and store `restWeekday`; Core adds its reader (week(), restDay, NowPage); fixed days ignore it. Message B Q1 with no data: "Did every set you lifted this weekend get logged? ★Yes / Most / Didn't train". Q2 "No": he switches to fixed days himself on the Routines page once the next pin (catalog v6 or later) is on his phone; Builder A writes it for him only if he asks. Receipts in week-two.md go thing-first ("Sunday, rest day.", "Plates, two pairs of 25 and 20."). Install timing reads "the next pin, before the Oct 23 9:57 AM lapse".

**11:45 AM PT Oct 16. AI architecture's six calls (spend projection: typical month ~$3.23, worst ~$8.59 of the $50 cap).** All six defaults taken: (1) Home lines on Sonnet until AI-5 says otherwise; (2) Home lines memory areas are Training and Kitchen; (3) a cold launch starts the day on rules lines, never yesterday's Claude lines; (4) the week story tells the week just ended, Monday 04:00; (5) its rules lines are plain counts, not best lines; (6) AI-14 clamps an out-of-range colour nudge instead of rejecting it, and FORGET means Design 48's "this palette off for 30 days". Core adds a 40-a-day Home-lines cap and keeps the forget tools out of Claude's reach.

**11:40 AM PT Oct 16. Groceries check rulings (Research 142).** Changing a recipe's serving size updates its rows in place (same ids) and the receipt reads "Pasta, 2 servings.", never a second "added". At zero, Home shows no Groceries line rather than "nothing to buy" (one line per thing that needs him). Teaspoons get ⅜, ⅝ and ⅞. "1 (16 oz)" and "1 (1 lb)" stay two rows for now, parked until Kitchen v2 normalizes pack sizes (Kitchen lead; corrected 11:43 AM PT). Garlic (G-R15, Kitchen lead): "7 cloves + 1 head" on one row, and a checked garlic row covers later lines.

**11:35 AM PT Oct 16. MU2 and the inbox-retry fix now block the pin; audit rulings.** QA's audit (#428 A1) and Research (#431 MW1) show money, body and health phrases the grammar misses still reach Claude on master, and the switch defaults to yes; A2: the offline inbox retry calls Claude directly and skips every wall, so phrases queued on 7b321d2 would go out unscreened on the next build. His rule is that money-shaped and body facts never go to Claude, so MU2 (money, body and health screen) and the A2 fix (inside MU2 or a tiny PR beside it) block the pin. The paste/link wall stays a rider. Audit rulings: A8, the unused "Not today" pause, comes out of `isAvailable` when AI-2 lands rather than being wired (the switch already does this job). #422 L1, a false positive becoming a private note: no extra warning; the receipt "Private note, kept." is the warning. Audit items (QA #428, Design's UI-bar audit) are on each team's board for the leads to pull.

**11:08 AM PT Oct 16. The refused-hold fix blocks the pin.** Builder B found that on master (#402's BottomChrome conversion) a refused hold (mic off, speech off, no on-device language, busy) leaves Tess in listening for good, and listening refuses the tab lens. #402 is not on his phone yet, so the pin would be the first build to carry it. The fix is one line plus a router test, so it can't cost the pin much. The pin waits on #366 and this fix. MU2 and the paste/link wall still ride only if they land first. **Why:** a known stuck state on a daily-use screen is worse than a short wait.

**10:24 AM PT Oct 16. Pasted recipes and link fetches get the secret-word wall.** QA on #422: both reach Claude with no secret-word check. One small Core PR right after MU2 runs the same SecretWords check before any Claude call. It doesn't hold the pin: the leak needs him to paste a recipe or link that holds a code, and until the pin he keeps "Tess asks Claude" on no or types no secrets. It rides the pin if it lands before #366 merges.

**10:18 AM PT Oct 16. #422 (secret-word wall + $50 cap) goes in the next pin; the pin moves to v9.** The switch is not off on his phone: #320 ships "Tess asks Claude: yes" as the default, and the 7b321d2 review guide (step 2) has him type his key, so misses can reach Claude in the installed build and in the pin. Holding #422 would ship the SW2 leak. So: the pin waits on #366 and #422 (QA pass on #422 first); #422 takes Catalog v9; #407 (tessEyes) moves to v10 and merges after the pin with #403; the migration gate reruns on the pin at v9 (upgrade over the v5 backup copy, 366 rows byte-identical, the timed v5 restore against the +0.7 s before number, older-build-opens-v9 checked). Until the pin is on his phone, he keeps "Tess asks Claude" on no, or types no passwords or secrets to Tess. **Why:** a privacy wall outranks a quieter gate; a v9 gate rerun is one Builder A run.

**10:02 AM PT Oct 16. 7b321d2 installed (Builder A, 9:57 AM PT).** On his iPhone over the existing app, data untouched. Carries #320, #330, #334, #337, #343 only. Signing lapses about Oct 23, 9:57 AM PT; reminder moves to Oct 22, 10 AM PT. Rollback target is now 444e72b (both v5). Everything later waits for the next pin (on #366, at v8).

**10:00 AM PT Oct 16. Recipe clock scope and "swipe for more" (Design 69, ca348ef).** This build: C with lit steps, the bead and stroke, the ingredient peek (swipe left or INGREDIENTS, ADD N TO GROCERIES with a receipt and UNDO), DONE "Paprika chicken, cooked." with a 10 s UNDO; Core gives step start and end minutes, the used set, and one timer per timed step. Parallel steps (the lane fork, several live steps, Claude's ghost overlaps with KEEP / NOT NOW) wait for Kitchen v2 under #414's rule. Pantry is reserved only. House rule: a page one tap down may have one side page; never a tab page or a live workout. **Why:** he called parallel steps secondary; the single-recipe clock and the peek are what he asked for now.

**9:58 AM PT Oct 16. Tess picks: all 11, plus a mouth (his pick, motion thread).** All eleven ideas on the board ship, as small Builder A PRs in the lab's order after eyes and working: 1 + 2, 3 + 4, the mouth, 5 + 6 + 10, 7 + 8 + 9, 11 last (off in Reduce Motion and Low Power). The mouth: one short line under the eyes that rests straight and curves or opens a little with her state; never a frown at him. It sits under the eyes setting, default off: no mouth without eyes, one setting for her face. Idea 10 (rest clock) stays eyes only, mouth still, because a set's rest is the quietest moment in training. Ideas that need eyes drop their eye part when eyes are off. Tess reads only signals the app already computes, the same rules in every area; no new model calls, and the screen-aware Tess stays parked. **Why:** he said "do all of them if possible" and asked for more feeling than eyes allow, while keeping her subtle and stable.

**9:52 AM PT Oct 16. Memory shape taken (AI architecture, #411).** Shape A, one profile block; Claude writes no memory; noticed lines carry no clock digits; Sonnet stays the Home model (about $1.05 a month, inside the $50 cap); Haiku is re-run in AI-5 with the tool forced. Core places two small fixes (TessLineCheck exemptions, per-model tool choice) right after secret words, and the no-digits noticed templates with AI-7. Builder B changes nothing. **Why:** best aware score (9 of 33) and fewest failed lines in the ~$0.60 experiment.

**9:47 AM PT Oct 16. Recipe layout: C, plus an ingredient peek (his pick, Design thread).** Not A. C (the clock: steps in order with a marker) is the base. This build: the current step is set apart by accent and weight, the marker moves with subtly nicer motion, and an "Ingredients" label at the bottom of the cook page shows B's ingredient list on a short swipe up (Design draws whether up or sideways reads better; one gesture, not two). Later, not this build: (1) parallel steps, several threads in one cooking session; Core's step start-minute work is the ground for it, the screen comes after single-recipe C ships. (2) Pantry: his own area that knows what a recipe needs versus what he has and feeds Groceries and Recipes; it grows out of the held kitchen slices R (usually have) then P (pantry light) in kitchen-v2-backlog.md, so Pantry is where those land as a screen, still held for a week of real cooking and shopping. (3) "Swipe for more" as a general pattern for other areas: Design notes it; no screen changes until one area proves it. **Why:** he chose C for sequential cooking and wanted B's list one move away; the rest are his ideas to keep, not this build.

- **The in-app Claude cap is $50 a month** (9:27 AM PT Oct 16, Kaushik: "Make it 50… start with 50 for now. We'll see how it goes"; $100 later is fine with him). This flips the 12:14 AM proposal to decided. The cap stays one constant, and the Settings line ("of $50"), the 80% step-aside and the Nov 1 paused copy follow it. Cloud development spend, like the memory experiment's roughly $2, comes from his $200 a month in credits and is not counted here. Recipe layout: he asked to see A, B and C first, and Design is showing them. C stays the default until he picks.
- **Soul ideas: picks go in a follow-up; idea 9 is allowed as eyes only** (8:58 AM PT Oct 16, motion lab item 17, idea board https://claude.ai/artifact/9TfNx1oW6B2RGXAzLGXaMA). Builder A's soul router PR stays the §14/§15 contract and passes the item 16 check kit as specified. His picks ship in a follow-up PR right after it. If he picks idea 9 (watching the rest clock), it is allowed in a live workout only as eyes resting on the clock, with no roam, no colour change, no sound or haptic, and no ask. It is an exception to the no-glance rule, because the rest clock is his own timer.
- **Tess's soul moves up** (8:48 AM PT Oct 16, Kaushik in the motion lab thread: "it feels like it has life… the movements, the colors, the fading, the eyes… there's only more to improve"). Builder A builds the soul router and motion sheet right after the 56 follow-up PR, ahead of its other rows, so he sees her live in a build soon. The motion lab brainstorms now (more ways to be interactive while staying subtle and stable), as ideas with short clips, not build specs. He picks, then the picks become sheets.
- **The next pin waits for incremental OpZones** (4:11 AM PT Oct 16, Core's S1 number). Day log reads are fine: 33 ms at 1500. Writes are not: OpZones (#377) re-walks the whole op log on every revision, and a backup restore writes in a burst. So the next pin waits for #380, #366 and Core's incremental OpZones PR, which includes the 1500 build budget in ScaleTests. Builder A's v8 gate rerun times the v5 restore on that build.
- **Receipts use the recipe's short name** (3:58 AM PT Oct 16, Design 67 `kitchen-week.md`, aa3d7fb; accepted). Tess's line says "Tacos, 10 added.", never the full title. Core adds a short name (his own, or the title's first noun phrase), and the Kitchen lead's G-R14 example changes to match. The nothing-missing line is "Tacos, nothing to add." (3:43 AM), not #380's "nothing new to buy."
- **Migration gate, demo-store evidence accepted** (3:50 AM PT Oct 16, Builder A's Simulator run). The upgrade from v5 to v7 kept all 364 rows byte-identical, and 7b321d2 opened the v7 store and ran normally. That is enough to pin the next candidate once #380 (v8) and #366 land, on these conditions:
  - Builder A reruns the gate on the v8 master. The rerun also tests the restore path: a v5 backup file restored into the v8 build.
  - The install-day script starts with him tapping a fresh backup in Review > Backups on the phone before installing.
  - No run over his real backup is needed, so nothing is asked of him.
  - Rollback: an older build opening a newer store is shown safe through v7. Restoring a newer backup onto an older build stays forbidden until it is tested.
- **Removing a list row, as drawn** (3:47 AM PT Oct 16, Design 65 `list-remove.md`, 66550d4; accepted). The UNDO line names the list: "Ground beef, back on Groceries." (and "back on Packing" on another list), to match "No rice on Groceries." A removed row never feeds USUALLY.
- **Nights, timers and private notes** (3:46 AM PT Oct 16, Research 134 and 135, #384; QA F2 on #381).
  - **CL9: his own timers ring at any hour, haptic included.** "No haptic after 23:00" covers moments the app raises, not a kitchen timer he set.
  - **CL6: the kitchen timer must fire.** It is a bug that StartKitchenTimer schedules no notification. Core schedules a local notification when the timer starts and cancels it on stop or UNDO.
  - **CL10: the habits check-in** trigger is Shutdown, as drawn in Design 64: "Read today?" with DONE or NOT TODAY.
  - **CL11: "A closed day never asks"** covers only asks the app raises. His own captures still get receipts, and his own timers still ring.
  - **CL1, CL2, CL3, yes.** A pending set ask expires with its workout or at the day's close, so a "2 sets" said at 00:42 never lands in a finished workout. The closed-day state and the quiet-hours gate ship before the first app ask does.
  - **Q1: a private note rides in his iCloud Drive backup,** since the folder is his. It never enters memory, recent lines, packs or the miss log. The NE1 fix includes SW2: the 04:00 turnover skips private notes, so "note: wifi password is …" is private too.
  - **F2: finishing with the last set gets a 10 s UNDO.** AND FINISH shows UNDO on the finish view, and it takes back the set and the finish together ("Push A, back on.").
- **Shutdown and kitchen copy** (3:43 AM PT Oct 16, Design 63 `shutdown-grammar.md` fdaf0d0, QA L2 on #380).
  - **The first Shutdown ever** uses slot C once, "3 moving to tomorrow. Tap any to keep.", then slot B after that.
  - **The said-line receipt** is "Reply to the landlord, tomorrow first."
  - **Slot times use the house form,** "9:30 am" and "8 am". The closed line becomes "Closed. Your line is waiting at 8 am." Labels stay in caps ("THEN PULL A, 7:30 AM").
  - **The habits check-in** is "Read today?" with DONE and NOT TODAY. It runs in Tess's band at Shutdown, before the day closes: one habit at a time, once per habit per day, never on a day a record already counts, and never during a workout.
  - **L2: a recipe that adds nothing** reads "Tacos, nothing to add." It writes nothing, so there is no UNDO.
  - The key-prefix wording sweep of older docs (outside docs/design) is approved after Research 134.
- **Copy pass, asks and wrong writes** (3:34 AM PT Oct 16, Design 62 `copy-pass.md` a127cbc, Research 131 to 133 #379).
  - **Design's picks.** Accepted: digits in heroes ("3 sessions"), lower-case "pm" in heroes ("Tacos at 7 pm"), "Pull A tomorrow, first." and "Dune, set aside." Not accepted: first-person Settings lines. Settings keeps the built, decided copy ("Tess asks Claude: yes.", "Tess stays on this phone."), because the switch is named for Tess and #320 shipped it. Tess's first person stays in her own lines by the soul.
  - **AQ6: asks hold in quiet hours.** App-raised asks hold from 23:00 to 07:00. They also hold from the moment the day is closed (Shutdown complete, or the 22:00 silent close) until 07:00. A closed day never asks.
  - **AQ1.** The set-count ask (Q10) is a worded choice ("2 sets, or 2 kg?"), never yes/no.
  - **AQ15: two UNDO lengths.** A new capture gets a 4 s UNDO. Anything that removes or changes something already there gets 10 s.
  - **Wrong writes (Research 132), all fixed by Core:**
    - "buy a birthday card" and "get gas" are tasks. A grocery row needs a food or household word.
    - "trash night is tuesday" becomes a weekly task "Trash night" on Tuesdays.
    - "shopping list: rice, beans" adds two grocery rows.
  - **NE1/NE2: secret words.** A line with a secret word (password, PIN, passcode, wifi password, code) becomes a private note on the phone. It never reaches the model, Claude, memory or the miss log.
  - **NE11: removing a list item.** List items get a remove: "remove rice from groceries", or a swipe on the row, with a 10 s UNDO ("Rice, removed.").
- **Upkeep and People receipts** (3:33 AM PT Oct 16, Design 61, `upkeep-people-grammar.md`, 1662430; all three confirmed).
  - The done receipt is "Clean the bathroom, done. Was 21 days, usually 14."
  - The pick receipt is "4 chores, kept. Tell me when you do one."
  - On People, a birthday within 14 days takes the value slot over the last talk, e.g. "BIRTHDAY SUN" on Mom's line.
  - Trip zones: T1 to T3 are fixed in #377. R34 (T4, Builder A) is still open before Oct 26.
- **Money and reading on the phone** (3:24 AM PT Oct 16, Research 129 and 130, #376).
  - **MU1, yes.** A money-shaped last amount after words that aren't an exercise is a spend, decided on the phone. "costco 212.37" logs $212.37 at Costco. This replaces M7's route to Claude for word-then-amount. Exercise names and the live-workout guard still win.
  - **MU2, yes.** Anything money-shaped never goes to Claude. If the phone can't place it, Tess asks one on-phone question in the one-ask pattern, for example "$212.37 at Costco?" with LOG or NOT NOW. Ship-list eval 15's "via Claude" route is struck. A money phrase with no amount ("pay the apple card bill mon") stays a task.
  - **Reading rule, yes.** "read 30 pages", "finished the three body problem sunday" and "yesterday" forms are read before parsePastLog and log a reading record on the right day, not a note and a task.
  - **RF18, both, with one write.** "read 20 pages" writes one reading record, and the Read habit counts it for that day, since habits come from logs. There is no separate check-in. The habit's check-in ask is skipped on a day that already has a reading record.
  - **RF15, thing first.** The receipt is "Dune, finished."
  - **Row 49 (split).** It follows the decided split default, not the full amount. Core fixes it with the money rows.
- **The next install carries migrations** (3:20 AM PT Oct 16). Master now has Catalog v6 (#341) and v7 (#356, TessMemoryStore). Before any commit after 7b321d2 is pinned, QA's install script gets a migration row. Builder A runs the v5 → v7 upgrade on the Simulator over a copy of his latest backup: it must open with every record intact, Settings kept, and no crash on launch. Rollback rule: going back to 7b321d2 from a v7 build is only safe by restoring a backup made on 7b321d2. Never restore a v7 backup onto an older build.
- **One word for a best, one shape for a receipt, trip fixes first** (3:15 AM PT Oct 16, Research 125 to 127, #372).
  - **"Best" everywhere.** The Day log moves to "best" too ("Bench 80 × 8, best."). Review, the HomeLines lens and WorkoutSummary use the same word, never "record" or a count of records. The 12:17 AM rule still holds: a past best stays a best.
  - **One task receipt.** It is the thing, a comma, then what happened: "Call mom, done." Never "Done. Next one is up." or "Done. Call the dentist." The next task shows on its own row, not in the receipt.
  - **The groceries receipt follows the same rule.** It becomes "Tacos, 2 added." with UNDO, replacing "Added 2 for tacos." (12:54 AM). The row line "for tacos" stays.
  - **Trip fixes T1 to T3 come next for Core,** right after #369's fixes and ahead of the Kitchen slice. They must be in the build he installs before the Oct 26 trip.
    - T1: WorkoutSummary buckets by each workout's stored zone.
    - T2: done tasks and cooks bucket the same way, through one shared helper.
    - T3: the #356 turnover keys days by the 4 AM logical day, not absolute midnight, and runs once on a 27-hour day.
- **Habits opens from Review** (3:12 AM PT Oct 16, Design 59, cbfc1ee; agreed). Design 41's Home has no foot line, so the Habits page opens from Review in two ways: tapping a habit band, or the HABITS word beside NOTES on Review's link line. Its back word is "< REVIEW". Asking Tess for "habits" opens it too. This replaces the earlier Today foot-line word. Builder B builds it after 53 and 57.
- **A planned session beats a rest day** (3:05 AM PT Oct 16, QA L3 on #366). If a workout is on today's plan with a time (Push A at 19:00), that day is not a rest day: he chose to train. Home shows the planned session as the hero ("Push A at 7 PM", with START PUSH A), never "Rest day" beside a START key. WeekFacts counts the day as due once the session is planned. A rest day only wins when nothing is planned for that day, whether it comes from the rotation, from restWeekday, or from a "rest day today" mark. The mark itself takes the session off today's plan, so the two can never show together. Builder B shows it, and Core's lens decides it.
- **"Rest day today" is a day mark** (2:53 AM PT Oct 16, Design's answer to Research 122 in `training-mode.md`, 7d16c88; agreed). A skip, or "rest day today" said to Tess, marks the day. It is not a plan write. Home matches her line: the hero says "Rest today", the context line says "Legs A waits for tomorrow", and the Start key is gone until 04:00. WeekFacts counts the day as rest, not a miss. A 10 s UNDO says "Legs A, back on today." On a fixed-day routine, the context line names the next fixed day (for example "Legs A waits for Thursday"), since a fixed day doesn't roll. The day mark never changes restWeekday. Principle: Tess's line and Home never disagree. Core builds the mark with the grammar.
- **Forgetting is his, never Claude's** (2:52 AM PT Oct 16, AI thread's call, agreed). There is no forget tool. A fact is forgotten only by his own gesture on the What Tess knows page (FORGET with a 10 s UNDO), or when he says "forget that" to Tess on the phone. Claude can never remove memory. `remember` joins TessTools in AI-8, and plan actions register in AI-13. If he says "rest day Sunday" before Oct 22, that answers question 12 on the list (Research 122 V8). The #354 demo-store run goes to Builder B right after its AI-1 Home push; the output goes back to Kitchen and QA.
- **A late first day isn't due** (2:34 AM PT Oct 16, Research 120 R5, the coordinator's default plus one clause). If his first use of the app is after 17:00, that day's routine isn't due, so the week reads "3 of 3", not "3 of 4". If he trains that evening anyway, the session counts as trained and the day becomes due, so the count never reads more done than due. Core builds this with its WeekFacts lows.
- **Install commit pinned: 7b321d2** (1:09 AM PT Oct 16). This is #343's merge commit. Since 444e72b it carries #330 (icon), #337 (Training at rest), #320 (Tess asks Claude), #334 (HomeLines lens, rules only, no UI), #340 (docs) and #343 (Return). It has no catalog v6 migration. #341 and #344 merge only after the iOS build thread confirms it checked out 7b321d2. It installs only on his own "install it", no later than the Oct 22 re-sign. The build after it targets AI-1 Home, Design 44 part two, 42 the glass tabs and the Ask Tess sizes.
- **Dropping a routine clears its fixed days** (1:05 AM PT Oct 16, QA on #341, coordinator default agreed). Drop clears the routine's weekdays. Add reconciles a clash the same way SetRoutineWeekdays does: the newer pick wins, and the handoff is reported in one line naming the other routine. One routine per weekday always holds. The install candidate becomes #343's merge commit (Return saves in Notes; also carries #334).
- **Training's "tomorrow" line follows the real plan** (12:56 AM PT Oct 16, QA low on #337, agreed). The done label names what tomorrow actually holds. On the eve of his rest day it reads "Rest day tomorrow", using restWeekday or, while that is empty, the engine's current rest placement. After a missed day rolls on, it names the routine the roll lands on. A fixed-day routine names whatever is fixed for tomorrow. It reads Now's own picker, so the two never disagree. Builder A builds it with 44 part two.
- **Groceries AI-12, the Kitchen lead's three changes stand** (12:54 AM PT Oct 16, #335). (1) Grocery rows land when a meal is planned, not at 17:00 the day before, with the line "Added 2 for tacos." and a 10 s UNDO. (2) The sage dab gives way to a "for tacos" line, which fits the no-dots rule. (3) USUALLY shows up to 4 names, up from 3. The install candidate is #320's fixes (QA PASS at f907218) plus #330, waiting only on Design's pass of the re-record.
- **Fixed days and recipe layouts** (12:32 AM PT Oct 16, after Design 44 and 45). Confirming Design's two defaults in `training-mode.md` (7fcbee6). (1) A missed fixed day does not roll on: a fixed routine waits for its next weekday. A rolling plan keeps "missed day rolls on". (2) One routine per weekday: picking a day on one routine takes it off the routine that had it, and the editor says so in one line naming that routine. Recipe layouts (`recipe-layouts.md`, 95a5e81) wait on his pick on Design's card, with C (the clock) as the default if he says nothing. C needs Core to give each step a start minute from the durations the parser already reads.
- **Home after Design 41, the ledger, Groceries reminders and past PRs** (12:17 AM PT Oct 16).
  - **The ledger.** Design 41 (091ddcd) takes the ledger row off Home. In v1 that is fine: only workouts are processes, and the one suspended workout becomes the hero with the Start key's progress line, so nothing goes missing. The whats-running rule stays for later. When Core adds a second kind of process (cook timers, waiting checks), suspended and waiting ones come back as plain Next rows at the top of Next: title and time only, at most 3, in whats-running order, with no detail line.
  - **The glass tab strip** (Design 42) goes to Builder A, after the icon and routines, with living colour after it.
  - **Groceries "remind"** is not a notification; Groceries never notifies. The planned cook's Home line carries the open count through HomeLines, e.g. "Tacos tonight, 2 to buy." (the Kitchen lead's call).
  - **A past PR stays a PR in the Day log.** The Day log is history. A set that was a record when he logged it keeps ", PR" even after a later session beats it. Core keeps the flag as it was at that time. WorkoutSummary for today may keep showing the current best.
- **Claude cap rises to $50 a month; memory moves up** (12:14 AM PT Oct 16, Kaushik in the AI thread: he has $200 of credits a month and wants them used well; cap number is Product's call on the coordinator's recommendation). DECIDED: his yes at 9:27 AM PT Oct 16 ("start with 50"); the cap is $50, carried in #422. (Was: proposed, waiting on his yes.) If he agrees, the in-app ledger cap goes from $10 to $50 a month, so there is room for memory, Home wording and the week while a runaway loop still stops. The Settings spend line ("This month $0.00 of $50."), the 80% step-aside and the Nov 1 paused copy follow the number. The cap stays a single constant. Pick models per job on quality, with AI-5's eval deciding Haiku or Sonnet. Context, profile and memory start now (AI-7 to AI-9 move up), all on the phone as `architecture.md` says.
- **Living colours: rules first** (12:11 AM PT Oct 16, AI architecture's recommendation, agreed). The on-phone picker is a small rule table (time, day, Tess's state and the look go in; one of Design's named soul palettes comes out). It is instant, offline and tested against Design 48's bounds, and the on-device model is not used. Under the switch, Claude may replace the pick at most once a day, sending only a named palette plus a warm-or-cool nudge, never a colour value; the phone checks and clamps it. Spec: `docs/ai/architecture.md` section 9.
- **Tess's colours keep changing, chosen by AI** (12:08 AM PT Oct 16, Kaushik, Design thread). Tess's soul pigments change over time, picked by AI from context (time, the day, what she is doing), within each look's soul palette from `soul-explore.md`. Scope: **Tess only for now.** The app's base and resting colours stay fixed per look (one base rule; Obsidian stays as is); his "could be better" goes through Design 43 by hand. Context colours may follow later only if he asks. Rules: on-phone rules pick by default, and Claude is used only under the "Tess asks Claude" switch and cached (at most once a day). Text contrast never depends on it, and the colour changes only through motion. Design's 65% closer soul applies in the app too, not only the icon (Builder A, with the icon).
- **Return sends in Ask Tess** (12:01 AM PT Oct 16, Kaushik). Return makes a new line with no way to send, so it becomes send. Builder B fixes it first, ahead of #320's fixes. The icon hold ends: Design re-rendered the masters at 65% (90ca9db).
- **His first review of the installed build** (11:58 PM PT Oct 15, Kaushik, on 444e72b). Calls: (1) Home says one plain Tess line per thing ("Workout done.", not "1 of 1 exercise, 2 sets, 1 record" or "Bench press, set 2…" with marks); the detail is one tap down, and with the switch on Claude may word the line, with an on-phone line when it is off or offline. (2) The "Thursday night" bar goes, unless Design makes it carry something he uses; it must earn its space. (3) The top tabs become a glass strip with real hold-and-swipe transitions. (4) Obsidian (pure black) stays as is; Design refines the other looks. (5) Ask Tess text gets smaller (Builder B, now). (6) Training: he creates and edits routines and fixed days; the workout page opens on today's plan in workout mode; Design redraws the Start workout mark. (7) Recipes: Design draws three layouts and he picks one. (8) Groceries gets AI: sort, connect to recipes, suggest, remind. (9) Review shows the week on one page, more than today. (10) The Tess icon ships once Design re-renders the masters. Two new teams: **AI architecture** (data, memory, harness, Tess's awareness; `ops/board/ai.md`) and **Tess motion lab** (dot eyes, roaming, dragging, fading into subtle colour while working, splitting and gathering, all very subtle; `ops/board/motion.md`). Motion keeps the Speak rules: tap opens Tess, double tap goes Home, so dragging starts from a hold; nothing on a page moves for the soul.
- **Next phone build waits for the Claude switch and haptics** (11:51 PM PT, coordinator recommendation agreed). bb57e78 is safe but he installed 444e72b minutes ago, so the next install is the first QA-passed master carrying #320 (the "Tess asks Claude" switch) and #317 (haptics, after its fix), plus Settings: Claude's key field if it lands in time, so he can type his key. It goes on no later than the Oct 22 re-sign, and always on his own "install it".
- **444e72b is on his phone** (11:28 PM PT, iOS build thread). Installed over the existing app with his data kept. The free signing clock restarts tonight, so it lapses around Thu Oct 22, 11:28 PM PT; re-sign before then. The next phone build waits on Builder B's #312 fixes (F1, F2), the Speak fix and Core's weightless-lift rule.
- **An app icon** (11:23 PM PT, Kaushik). Tessera gets a real, well-designed icon. Design draws it from Tess's soul with light, dark and tinted variants; he sees it before Builder A adds it.
- **Creating and finishing a task should feel rewarding** (11:19 PM PT Oct 15, Kaushik). Making a task and finishing one must be easy and also exciting, rewarding and satisfying: aesthetics, effects and haptics. Every interaction gets considered, custom haptics. The reps or sets dial can be a simple counter or a richer dial depending on how much it matters (Design's call), with a haptic on each step. He also said "install it", and yes to Research's Day log pack edits.
- **One Claude switch, and what the plan sends** (10:29 PM PT, after #298). One switch covers both misses and Plan my day: Settings shows it as "Tess asks Claude" (the stored key stays `missesGoToClaude`); off means neither goes. Plan my day keeps sending task titles, times, the workout name and calendar event titles (never notes, attendees, locations or health), and says so once on first use under VIA CLAUDE: "Sends your task and event titles, never notes or places." His yes or no goes on the Oct 22 morning list. Cost from the merge: about $0.005 a plan, roughly $0.15 to $0.50 a month.
- **Plan my day density** (10:25 PM PT, Design item 27 follow-up). On Home, Plan my day shows at most 5 plan rows; the rest are one pull away. No row ever sits under Tess's band. Design redraws Plan my day and Speak on the build's Home frame before Builder B builds the plan screen.
- **Plan my day outcome lines, and no invented names** (10:24 PM PT, QA review-298). A bad key says "That key didn't work. Paste it again?" (M2) and shows the usual plan. Offline or busy says "Here's your usual plan." A rejected plan or a late reply stays silent; the usual plan simply stands. Timeout and cap keep their lines. A validator rule (V13) rejects any plan naming a task, event or exercise that isn't in the pack, so invented names never reach him; the eval gate still checks them too.
- **Two Money rules for a US shop** (10:14 PM PT, Research #296, accepted). M12: a unit price like "$1.29/lb" is never a spend. A shop named with "at" ("spent $23.47 at trader joe's") keeps "trader joe's" whole as the merchant, shown in title case as before ("Trader Joe's"), and leaves the category empty. Core fixes two wrong writes soon: "spent $1,250 on rent" becoming two grocery lines, and "spent $23.47 at trader joe's sat" becoming a task.
- **A set count is never a weight on loaded kit** (10:04 PM PT, coordinator check on #289). On machines, cables, bands, dumbbells and barbells, a bare N×M with N of 10 or less never writes N kg: with no last weight Tess asks at what weight; with a last weight the Q8 rule decides. An "at N" that isn't a loadable weight asks. Kitchen follows a US shop (Design `kitchen/us-shop.md`): US aisles and units, with Core's part after PlanPack.
- **Back words name the tab page** (9:58 PM PT, Design rule S3). A back word names the tab page he came from: < TODAY, < REVIEW, < TRAINING or < KITCHEN, never "< HOME". Also: Core's #287 is QA install-safe, so the weightless-lift half of the install gate is met once it merges; the F2 follow-up (machine, cable and dumbbell lifts still logging 3 kg, undoable) doesn't block the install.
- **Three grammar calls** (9:50 PM PT, QA review-282 and Research K901 to K913, defaults confirmed). A lift named with sets and reps but no weight ("bench 3 sets of 8", "bench 3x8") never logs a weight: Tess asks "Bench 3 × 8 at what weight?" (master writes 3 kg × 8 today, a bug). In a live workout, a named bodyweight lift with one number ("pull-ups 8") logs 8 reps at bodyweight on the lift in focus, the same as "Eight." (a named lift with N x M still asks, 9:40 PM). The wake word "Tess" is stripped only when a comma or colon follows it, or after "okay Tess" or "hey Tess"; "Tess dinner fri" stays a task and "Tess's ideas list" keeps "Tess's".
- **Plan my day order** (9:45 PM PT, Core #283 parked it). Core builds the rules plan engine first (M4 slice 6, the plan without Claude, which "Here's your usual plan." falls back to), then Plan my day through Claude on top of it, with the TessInbox offline queue alongside. Both follow Core's current list (T11, B8 to B10, G2, the empty wrap-up UNDO, the backup settings wiring).
- **Radiators UNDO counts as answered** (9:40 PM PT, Design b8434f7, default kept). After KEEP IT then UNDO, the ask isn't offered again that season.
- **Naming the lift doesn't skip the ask** (9:40 PM PT, QA on #274). In a live workout, a named bodyweight lift in focus ("dips 10x8") asks just like the bare "10x8": "10 × 8: 10 sets, or +10 kg?". With no workout open, "pull ups 3x8" stays 3 sets at bodyweight (A181). Not a blocker for Oct 22.
- **The radiators ask** (9:35 PM PT, Design item 20, 570e7cb). On the first Upkeep open of a day from Oct 1 to Nov 30 (on a first run, only after Keep N or SKIP), Tess asks "Radiators to bleed this autumn?" with KEEP IT and NO RADIATORS. KEEP IT writes Bleed the radiators every 365 days and says "Bleed the radiators, kept. Once a year." with a 4 s UNDO ("Bleed the radiators taken back."). NO RADIATORS says "Okay. I won't ask again." and writes nothing. Leaving without answering asks again on the next open in the window.
- **Resting colour** (9:35 PM PT, Design sweep-19). The one Body 21 context line right above a hero rests in the context colour; every other resting line is ink or inkSecondary. The Lock Screen Live Activity stays Cobalt sky (c34cd39).
- **Oct 22 install target is 444e72b** (9:24 PM PT, QA review-269 PASS), or a later QA-passed master that includes Builder B's Speak fix (9:33 PM PT: QA review-273 found Speak, #273, likely crashes on first use on a real phone; any master after 444e72b stays off his phone until that fix passes QA, and until Core's weightless-lift fix is merged, 9:50 PM PT). The last check passed (QA I1, UI test target builds on the Simulator), so it is fully cleared. Rolling back from a v4 build to b19fb4a or e7a5be4 is safe; just never restore a newer backup on an old build.
- **No evening washes** (9:17 PM PT, Design `evening-on-now.md` a79ce75 row 1). Under the one-base rule the ground never changes for the evening; m4-steers §7's violet evening washes are withdrawn. The evening shows only as the day stroke reaching its vermilion end and the soul resting. Tapping the active half's look name starts the paint flood at that word (b1f03e2).
- **Day log: the faint row, not a faint dab** (9:12 PM PT, Design `day-log-v1.md` 8ceb4e5). Under the 8:07 PM no-dots rule, an unfinished workout in the Day log is a faint row (its text in inkSecondary, no words added), replacing the 7:34 PM "faint dab". The Settings place shows UNITS as plain text until Core adds unit fields.
- **"defaults" logs whatever weekday Q4 shows** (9:06 PM PT, Research 86). If Monday's page pre-fills a rest weekday other than Sunday, a "defaults" reply logs that weekday into `restWeekday`.
- **Habits first use** (9:04 PM PT, Research 105 `habits-first-use.md`, #261; recommendations taken). G1: in the creation week the Habits page shows "0 of 5" (he just set 5); only Review and history call the week new. G3: "read 20 pages" typed alone is a check-in ("Read, 3 of 5 this week."); only a note made as a note ticks by the habits-from-logs rule, and it says the same line, so one phrase never gets two lines. G6: a rule habit made mid-week counts only finishes after it was made; whole weeks after that count every finish. G12: "skip read today" says nothing and clears the field. G19: Core adds a pause flag in M3 slice 2, so a paused workout habit draws no rings. G8 goes to Design, with Product's lean: the count stays in ink at rest, colour only in the moment the target is met. design/habits.md and research/habits.md are marked superseded.
- **A list with one bare weight logs the whole sets, then asks** (9:03 PM PT, Research 102, K874/K875). "bench 80 for 8, 81" logs 80 × 8 and then asks "81 for how many reps?"; a set he fully said is never held back by one he didn't. Suite on master: 895 rows, 721 pass, 102 wrong, 72 miss.
- **Bleed the radiators, offered in autumn** (9:01 PM PT, Research 106, all three defaults). It is not on the pick list (still 25). It is offered once when he first opens Upkeep between Oct 1 and Nov 30; accepting writes Bleed the radiators, every 365 days, with no check-in. If he declines, it is never offered again. Guard S7 puts "bled" on the past-tense list, so "bled the radiators sun" is a check-in, not a task. Upkeep fixtures now assume a US home on Pacific time: the phone's zone, a water bill instead of council tax, no London water.
- **Live-workout statements, and the rest weekday field** (8:58 PM PT, Core #254). During a live workout, a bare yes, no or ok gets "Say the set, like 85 × 8."; a skip says "Skip is on the workout screen." Statements, not asks. The settings object carries `restWeekday` (1 to 7, Sunday = 1). Empty keeps the rest day where the engine places it today; it does not mean Sunday until he answers (8:52 PM PT).
- **Speak's set line** (8:56 PM PT, Design b13d8b4). A spoken set says "Set 3 logged. 80 × 7.", name first, under the undo rule.
- **Day log times print in the current zone** (8:56 PM PT, Research 104 K1). Every time in the Day log prints in the phone's current zone, as `day-log-late-night.md` says; the travel block in `day-log-copy.md` is fixed to match. Which day an item lands on reads its stored zone now (op.zone, #225; nil before v3 means the device zone), so the Oct 26 trip lands on the right day and all 8 wrong-day cases pass (clarified 8:59 PM PT); only the printed times stay in the current zone.
- **Oct 22 install target** (8:56 PM PT, Research 103). Install at Builder A's launch-flags merge, once QA passes it and #251 and test.sh is green. If launch-flags hasn't merged by Wed Oct 21, 6 PM PT, the fallback is the merge of Core's set-loss PR once Research 108 and QA pass it (it carries #254 and #258), else the newest QA-passed master commit that includes #254 (e7a5be4 or later) and, if it is after 444e72b, Builder B's Speak fix (9:33 PM PT), never 92078ee, which still logs "2x10 @8" as 2 kg × 10; always with empty scheme args and no UITests on his phone (fallback changed 9:06 PM PT).
- **Rest days keep showing while Monday's question is open** (8:52 PM PT, Research 101). NowPage and ReviewPage do not pass sessionsPerWeek 0. The PPL x2 plan at 6 sessions a week is decided, so a planned rest day is real and keeps its "Rest day" line. Which weekday it lands on is not decided yet: "Sunday" is only the pre-filled answer in Monday's question and is logged only when he answers. Until then, rest falls where the engine puts it today.
- **Plan my day, four small calls** (8:50 PM PT, Research 98 #250, defaults taken). Nothing goes to Claude for the plan during a workout, so eval pack d22 stays only as a guard. The cap line shows once a month. The plan shows VIA CLAUDE once, an exception to the 8:28 PM cloud mark on every Claude row, matching Design's §6 row 6. The calendar ask appears in Tess's corner.
- **Plan my day §6 settled** (8:46 PM PT, Design `docs/design/m4-steers.md` 041a17d, both departures from Research agreed). Before Health read is granted there is no sleep line at all (not "no sleep data"). A timeout says "Claude didn't answer in time. Here's your usual plan.", and tess-voice M18 changes to match.
- **Demo and reset launch args never touch his data** (8:41 PM PT, Research 96). His phone runs Debug builds, so `#if DEBUG` is not a guard: the -demo, -resetDemo and -theme args run only in the simulator, or refuse a reset when user ops exist. Builder A ships this before any install.
- **Plan my day morning flow** (8:38 PM PT, Research 95 `plan-my-day-flow.md`, #240; all five defaults taken). He can pull the plan from 7:00 AM (the offer itself waits for 8:00). "Plan kept" gets the 10 s UNDO. On a rest day the plan rows sit under the "Rest day" row. No plan offer while a workout runs. A late Claude reply is dropped, but its cost still counts on the ledger. Copy: a bad key says "That key didn't work. Paste it again?" (tess-voice M2); at the cap the plan says "Claude paused until {reset}. Here's your usual plan." instead of "On-device until then."; plan rows wait for a tap and never use the "Saves in two seconds" ghost line.
- **The dated set ask** (8:36 PM PT, Research #238, changed from its proposal "Log bench 80 x 8 for Monday?"). A set phrase with a weekday asks "Bench 80 × 8 for Monday?" (name first, "×" as in the Day log), with LOG and NOT NOW as ink words. LOG says "Bench 80 × 8 logged for Monday." with UNDO; NOT NOW writes nothing. Suite after #238: 698 pass, 110 wrong, 75 miss.
- **After a reinstall: restore first, reopen, then pick the folder** (8:33 PM PT, Research 94, Kaushik's order via coordinator). This applies only if the app was ever deleted; a normal re-sign installs over it. Preferences (folder name, look, "Misses go to Claude") move into one settings object in the database so they ride in every copy; the Claude key and the capture-miss log never do. Backups never writes a copy from an empty store and never replaces a day's copy with one holding fewer ops.
- **Money and Reading first screens go to Builder A** (8:32 PM PT, Design item 8 done, `docs/design/money-reading-first.md`). They stay on Builder A's Later, where they already sat, because Builder B's queue is the longer one (Settings: Claude, calm capture, Day log, Lists, Review with habits). Both wait on Core's engine slices. Review's two link lines ("The week · Day log · Notes", "Reading · Money · Upkeep · People") go to Builder B, which owns Review; each word shows only once its area exists.
- **Misses go to Claude: default yes, with a one-time line** (8:28 PM PT, QA M1 on #234, coordinator recommendation agreed). Typing his key in is the opt-in, and the huddle question already recommended yes. The first miss sent shows one line, once, naming what went: "Sent “{phrase}” to Claude. Turn this off in Settings: Claude." Every Claude ghost row keeps the cloud mark. Core reads `tess.missesGoToClaude` on the router path. Not on the Oct 22 list.
- **The workout follows the look** (8:25 PM PT, Kaushik via coordinator). The workout does not go black in every look. Every area, the workout included, uses the same base as Home in the active look; only the layers on top change. This supersedes the plum-black workout ground from #203 and #207. He also wants the thick PaintKey underline stroke thinner or reworked; Design owns it.
- **Money rows stay on the phone, and the re-sign rule** (8:21 PM PT, Research #232). Money phrases H609 and H610 never go to Claude. The Claude key and the capture-miss log are never backed up, by design; deleting the app loses them, so the re-sign reinstalls over the app, never deletes it. If Xcode refuses the App Group on Thursday, remove it from the entitlements for that install; never rename the group or the bundle id.
- **No coloured bullet dots anywhere** (8:07 PM PT, Kaushik via coordinator). Colour stays subtle at rest and arrives through motion. Design writes a colour addendum with a before and after; every board item that said "dots" now says "a mark per Design's colour addendum".
- **Review with habits and weight** (8:07 PM PT, Research 83, defaults taken with two wording changes). The hero stays the session count. Under it, one week line: "Gym 3 of 3, Cook 2 of 4, weight down 0.4 kg." ("down" or "up", never coloured, never red; changed from "0.4 kg less" so both directions read the same). The weight clause needs 3 or more weigh-ins that week. Each habit gets a day mark under the dabs per Design's colour addendum, not dots (Kaushik, 8:07 PM PT), at most 3 habits on Review (the rest on the full Review and the Habits page), so Review stays one screen. A paused habit reads "Gym, paused this week" and stays out of the week line. A Read logged at Mon 12:05 AM counts for Sunday (4 AM day; corrects m3-1-2-brief).
- **Q8 edges** (8:07 PM PT, Research 81, defaults confirmed). Exactly half the last weight logs (the rule is "under half"). With no last set, only a bodyweight lift asks. N of 7 or more logs, snapped to a loadable weight. Another phrase in the same capture drops the ask. A spoken "kilos" counts as a unit. Also P800 applied: "lunch with ravi" is a task in Later, and A136 to A138 are tasks, not Groceries. Suite 883: 697 pass, 113 wrong, 73 miss.
- **"dinner with Sam friday" and "bench 80x8 mon"** (8:00 PM PT, Research 75). People plus a coming day with no past-tense verb is a plan: it lands as a task for that day with UNDO, no "planning or done?" ask (changed from Research's default; asking adds a tap to the common case, and a past-tense verb already makes it a log). A set phrase with a weekday ("bench 80x8 mon") asks rather than logging, as Research proposed.
- **Settings: Claude goes to Builder B next** (7:58 PM PT, coordinator recommendation, agreed). Core's key store is merged (#218). Builder B builds the Settings: Claude field right after its day-boundary PR and ahead of calm capture, because it is small and it is how he types his key in, which unblocks every Claude feature.
- **Plan my day pack, cook timers, "thu" on a Thursday** (7:55 PM PT, Research, defaults confirmed). The Plan my day pack may name the one focused task or exercise and its last set (32 rows need it). Cook timers stay on the phone and never go to Claude. Suite rows A162 and A163 are fixed to match T647: "thu" said on a Thursday has no time. The suite is 883 rows: 698 pass, 113 wrong, 72 miss (#217).
- **Set counts read as weights, Q8** (7:53 PM PT, QA review-210 and Research, coordinator default confirmed). A bare N x M asks when N is 6 or less and under half the last weight: "2 × 10: 2 sets, or 2 kg?" with SETS and KG ink words. On a bodyweight lift a bare N x M always asks, worded "5 × 5: 5 sets, or +5 kg?" (S706 keeps added load as "+W for R"). A spoken unit, as in "4 kg x 10", always logs. A wrong 2 kg set pollutes history and bests silently; asking costs one tap. Wording follows the undo rule's name-first voice. Shown to him at the next install, so it's on the review guide rather than his Oct 22 list.
- **Spoken numbers** (7:53 PM PT, Research 78, defaults confirmed). "ten ten ten" and "a hundred, five" go to the model, not to sets. The set-phrase normaliser moves up into Core's set-guard follow-up, because "100 for five at 8" becomes an 8 PM task today.
- **Habits from logs** (7:53 PM PT, Research 77, defaults confirmed). A habit week starts Monday at 4 AM. Only a note starting with the habit name plus a number and unit ("read 30 pages") ticks Read. A second log on a day that already ticked gets no habit line. A log in a paused week marks the day, the week stays out of history, and Tess says "The week stays paused." A cook counts on its cookedAt day. A log that meets the target says "done for the week". Undo keeps the count if there's a manual check-in that day. A workout counts only with at least one logged set.
- **Store each record's time zone now, read it later** (7:52 PM PT, Research 80, coordinator default). Core adds a nullable zone column on the op table in a v3 migration, set by ActionEngine.perform, plus an optional export key; about 25 lines in 4 files with 8 tests. Old rows stay empty and mean the device zone, so there's no backfill and no backup version bump. It lands right after the Claude key store and before the 26 Oct trip, because a zone not stored at log time can't be recovered. The read side waits for DayStory.
- **Blind-read scoring** (7:51 PM PT, Research #213, defaults confirmed). Pack d14 makes no call, so it is credited on both counts: on the 22 packs he reads, the bars are 18 of 22 for "sounds like Tess" and 17 of 22 for "Haiku wins or ties". "Haiku wins or ties" is only the bar for swapping Sonnet out for Haiku, not part of use 2's pass gate.
- **Habit and body weight phrases** (7:50 PM PT, Research #212, defaults HP1 to HP7 and BP1 to BP6 confirmed; none changes what he'd notice, so none goes on his Oct 22 list). Habits: "twice" and number words set the target; a target of 0 or more than 7 goes to the model; "skip X today" writes nothing; "delete habit X" needs the word "habit"; mid-workout, only "habit X" checks a habit in. Body weight: "82,4" goes to the model; "yesterday" dates the weigh-in; a spoken unit wins; inside a bodyweight lift, "bw N" is reps for N from 1 to 50. "N reps" skipping the near-weight test was already logged at 7:43 PM and is built in #210. The suite is 873 rows: 692 pass, 109 wrong, 72 miss.
- **Use 2 gate with 23 packs** (7:44 PM PT, Research #209, coordinator took the defaults). Use 2 passes at a raw score of 21 of 23, a human read of 19 of 23, and Haiku winning or tying on 18 of 23; the cost caps stand. The pack gains `rest: true` on a planned rest day and `running: true` on a workout already under way, with end = start + 60 minutes. The birthday drop runs on the title rule only until Contacts matching exists.
- **"N reps" is exempt from S701** (7:43 PM PT, Research 66 rerun of #205, coordinator default). A number followed by "reps" always logs reps, so with dumbbells at 24, "24 reps" logs 24 reps. Group K now passes 38 of 40 (2 miss, 0 wrong); the suite moves to 641 pass, 102 wrong, 71 miss with the 70/71 fold.
- **Day log on late nights** (7:40 PM PT, Research #208, coordinator took the defaults). DayStory folds by TesseraDay on the root item's own start time (a workout's startedAt, a note's createdAt), never OpRecord.createdAt; a calendar-day fold gets 8 cases wrong. A workout running past 4 AM stays on the day it started. Times print in the current zone until a zone is stored per item; a note logged in flight is a known issue until then.
- **Plan my day on Claude, use 2 gate** (7:38 PM PT, Research #206). Use 2 turns on when, on Sonnet 5.5, 18 of 20 packs pass every must check in 3 of 3 runs with no must-not violations, the median cost is under $0.006 a call (p95 under $0.008), and he says at least 16 of 20 sound like Tess. The eval costs about $0.27 and runs on the phone behind a DEBUG -planEval flag. Times go to and from Claude as "7:30 am", parsed in V11. All-day events whose title matches a contact's birthday or contains "birthday" are dropped from the pack, in line with "birthdays stay out of Plan my day". `plan-my-day-scenarios.md` is superseded by `fixtures/plan-my-day-claude.md`.
- **Day log and M3 lines** (7:34 PM PT, Research #204, coordinator took every default). Day log: the time column reads "07:10", while sentences say "6:12 pm". An unfinished workout gets no "not finished" words; the faint dab carries it. A planned rest day opens with a "Rest day" row. Sets use "×" and titles show exactly as stored. The first day reads "Your days write themselves here." M3: the trend number shows after 1 weigh-in, the line after 2 days, and the weekly change after 7 days. Habits read "x of 5" against the weekly target, with no streaks and no red. A weigh-in says "Body weight logged. 82.4 kg." with kg said once, and the change reads "since Sep 3". Undoing a habit delete says "Read is back." Conflict D12 settled: the 7:24 PM S701 call stands, so a bare "82.4" close to the last weight goes to the model, and Design's body-weight sheet changes to match. Creating a habit needs the grammar rule "new habit {name} {n} a week", added to Core's grammar batch. Copy lives in `research/day-log-copy.md` and `research/m3-lines.md`.
- **Live-workout set phrases** (7:24 PM PT, Research #198 question 15, defaults S701 to S706). A bare number counts as reps only from 1 to 50 and when it isn't close to the last weight; anything else goes to the model. "+N" or "-N" alone goes to the model. A weight spoken to Tess snaps to the nearest loadable weight, ties going lighter. In a live workout, "at N" after a set means RPE, never a time. "to failure" and "warmup" set the kind of set. "bodyweight N", "+W for R" and "bar for N" are understood, and "skip" writes nothing. Core ships this as a small guard right after the past-day flags, because today these phrases lose sets mid-workout.
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
- **All times shown to Kaushik are in Pacific time** (Kaushik, 1:56 PM PT; PDT is UTC-7 today), never UTC. Earlier entries in this log are UTC (for example 19:12 UTC is 12:10 PM PT). New entries use PT.

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
