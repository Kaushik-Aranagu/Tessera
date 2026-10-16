# Install-day script: the 10-minute short path on the Simulator

*Research lab, board item 87, Oct 16. For QA (runs it) and Product (reads the result). Turns the "10-minute
short path" in `product/review-session.md` into numbered steps QA can run on the iOS Simulator before the Oct 22
re-sign. Context: `research/review-refresh-2.md`. All times are Pacific.*

**Install commit:** `444e72b` (#269, launch flags), Product's target once QA's review-269 passes and
`scripts/test.sh` ends "All green" on it. Write the short hash you built here: `________`. This script was first
checked against master `8fc5bd3` (Oct 15, 8:12 PM Pacific), re-checked against `92078ee` (8:52 PM), then against
`444e72b` (9:19 PM), which adds #262 (spoken numbers, step 8a), #266 (the workout on Home's base, steps 6 and 12),
#264 (calm capture, steps 16 and 17) and #269 (launch flags simulator only, the Lock Screen's Cobalt sky in step 10,
and step 23). Line numbers below are `444e72b`'s. `410403c` (master at 9:24 PM) has the same app code. QA's review-269: PASS. If you build
another commit, re-check any line marked with a source and note the new hash.

**How to read a step.** *Do* is what to tap or type. *Expect* is the screen and the exact line, with the master
source as `file:line`. *Sim* says whether it runs on the Simulator: **Yes**, **Part** (the screen runs, one part
needs the phone) or **No** (phone only; the step says what QA checks instead). Tick **P** or **F** in the last
column and write a few words for any F.

## Before you start (2 minutes, not timed)

- Simulator: iPhone 17, iOS 27 runtime, Debug build of the `Tessera` scheme. Since #269 every launch argument is
  read through `LaunchFlags`, which exists only on the Simulator (`App/LaunchFlags.swift:8-14`); most flags are
  also Debug only (`-demoTime`, `-fakeClaudeKey`, `-openLink`), so use Debug.
- Fresh look state: uninstall first (`xcrun simctl uninstall booted com.kaushikaranagu.tessera`), so the look starts
  on Porcelain by day and Obsidian by night (`DesignSystem/Looks.swift:186-187`). The look lives in the App Group,
  not in the demo data, so `-resetDemo` alone does not reset it (`DesignSystem/Looks.swift:118-131`).
- Appearance Light: `xcrun simctl ui booted appearance light`.
- Clock: `-demoTime HH:mm` sets the app's clock to that time today in the Mac's time zone
  (`App/AppClock.swift:18-31`, read through `LaunchFlags` at `:21`). Keep the Mac on Pacific, or launch with
  `SIMCTL_CHILD_TZ=America/Los_Angeles`.
- Launch with arguments through MobileBuildMCP `build_run_sim`, or
  `xcrun simctl launch booted com.kaushikaranagu.tessera -demoTime 18:10 -resetDemo`.
  `-resetDemo` wipes and reseeds the demo history, on the Simulator only (`App/TesseraApp.swift:29`,
  `Features/Demo/DemoData.swift:10-12, 18`). Never on a Simulator holding a restored copy of Kaushik's real backup:
  `resetUserData()` still wipes any store there (it is compiled out only on a device,
  `TesseraCore/Sources/TesseraCore/Engine/ObjectStore+Lifecycle.swift:54-56`).
- Do not use `-theme <name>` for steps 1 to 5: it pins a look in memory, so the LOOK sentence shows
  "*Name* always." instead of the day and night pair (`DesignSystem/Theme.swift:279-287`,
  `DesignSystem/Looks.swift:276-280, 295-296`). It is only used in step 12.
- Useful keys: Lock is Device, Lock (Cmd+L). Home is Cmd+Shift+H. Paste into the app with Cmd+V after
  Edit, Send Pasteboard if needed.
- The Simulator has no haptics. Every "tick" or "clunk" in this script is a phone check (see the phone-only list).

## The script

| # | Item | Do | Expect (exact line, master source) | Sim | P / F |
|---|---|---|---|---|---|
| 1 | 1 | Launch with `-demoTime 13:00 -resetDemo` in Light. Wait on Home. | White ground (Porcelain, `#FFFFFF`), ink text, colour only behind what is live. Not the cream paper. `DesignSystem/Looks.swift:52-58` (ground at `:54`), default at `:186`. | Yes | [ ] P [ ] F |
| 2 | 3 | Swipe to Review, tap the link word **The week** (`Features/Home/HomeSpatialView.swift:212`). Scroll to the foot. | Label **LOOK** (written "Look", drawn in caps by the label role, `DesignSystem/LookSentence.swift:15`, `DesignSystem/Theme.swift:228`), then "Porcelain by day, Obsidian by night." (`LookSentence.swift:33-41`) and under it "Hold a name to keep it day and night." (`LookSentence.swift:64`). Below it the CLAUDE section, then BACKUPS (`Features/Review/ReviewView.swift:221-232`). | Yes | [ ] P [ ] F |
| 3 | 4 | Tap **Porcelain**. Tap again. Tap again. Then tap **Obsidian**, then tap **Lacquer** once more to put it back. | Porcelain becomes **Plein** and the page crossfades to cream in 0.7 s; then **Celadon** (pale green); then **Porcelain** (`Looks.swift:91, 224-227`; fade `LookSentence.swift:119`). Obsidian becomes **Lacquer** and the page does not change by day (`Looks.swift:92, 229-232`); the next tap brings back Obsidian. Light tick: phone only. | Part | [ ] P [ ] F |
| 4 | 5 | Hold **Obsidian** for half a second. Then hold it again. | Page turns black. Sentence reads "Obsidian always." with "Hold it again to follow light and dark mode." (`LookSentence.swift:27-29`, hold time `:91`). Second hold: back to "Porcelain by day, Obsidian by night." with Obsidian in the night slot (`Looks.swift:258-274`). Watch for: the name also stepping to Lacquer on release (the tap and the hold share the word, `LookSentence.swift:83-94`); if it does, mark F. Firmer haptic: phone only. | Part | [ ] P [ ] F |
| 5 | 2 | `xcrun simctl ui booted appearance dark`, look, then `... appearance light`. | Page swaps at once to true black (Obsidian, `#000000`, `Looks.swift:60-65`), no paint flood, status bar text turns light. Back to white on Light. The switch by sunset (Automatic) is phone only; the look never reads the clock, so `-demoTime` does not change it. | Part | [ ] P [ ] F |
| 6 | 6 | Relaunch with `-demoTime 18:10` (no reset). Training, **Start workout** on Push Day A (`Features/Home/TrainingPage.swift:186`). | Since #266 the workout stands on Home's base in the look on screen: with Porcelain by day (Light), a white ground (`#FFFFFF`) with ink keys and numerals (`#17141F`) you can read, status bar text dark (`DesignSystem/Theme.swift:258-262`, `Features/Workout/WorkoutModeView.swift:140`). The rest timer and "Go" are ink, not amber (`WorkoutModeView.swift:418, 443`). **Not** the old plum-black (`#14111A`), which is gone from the code. If the workout opens dark on a Light Simulator, mark F. | Yes | [ ] P [ ] F |
| 7 | 10 | On Bench Press, tap Tess's soul (bottom right). The writing line shows "log bench 80x8, or ask" (`Features/Workout/WorkoutParts.swift:323`). Type `81 for 8`, Return. | "Set N logged. 80 × 8, nearest load to 81." with N the set number (#248; `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:263-274`). On the white workout (step 6) the line reads in ink. | Yes | [ ] P [ ] F |
| 8 | 11 | Tess: `100 for 5 at 8`, Return. Then `same at 9`, Return. | "Set N logged. 100 × 5, RPE 8." then "Set N logged, same again, RPE 9." (#248; `TessCaptureEngine.swift:263-274`). | Yes | [ ] P [ ] F |
| 8a | #262 | Tess: `same at nine`, Return. Then `a hundred, five`, Return. | `same at nine`: number words are read as digits first in a workout (`TesseraCore/Sources/TesseraTess/TessGrammar.swift:115-124`), so "Set N logged, same again, RPE 9." (`TessCaptureEngine.swift:271`; test row N11, `SpokenNumbersTests.swift:85`). `a hundred, five`: no set and nothing on Groceries or Now (K885, `SpokenNumbersTests.swift:104-118`); any line Tess says is fine. If a set is logged or a grocery item appears, mark F. Last set stays 100 × 5 for step 9. | Yes | [ ] P [ ] F |
| 9 | 12 | Tess: `81`, Return. Then `+5`, Return. Then `call mom at 7`, Return. | `81` and `+5`: no set and no task. Since #248 Tess asks herself, with no model call: `81` gives "81 for how many reps?" (the last set is 100, `TesseraCore/Sources/TesseraTess/TessGrammar+Live.swift:56-71`, line at `:70`) and, since #254 (`e7a5be4`), `+5` gives the statement "Say the set, like 105 × 5." (`TessGrammar+Live.swift:113-117`), not a question, so there is nothing to answer. `call mom at 7` (before 7 PM): "Call mom, today 7 pm." (`TessCaptureEngine.swift:276-279, 363-385`) and the task is on Now. | Yes | [ ] P [ ] F |
| 9a | #251 | Still in the workout. Tess: `bench 80x8 mon`, Return (use `sun` if the run day is a Monday). Then `log it`, Return. Then `bench 80x8 mon` again and `not now`, Return. | "Bench 80 × 8 for Monday?" and nothing written (`TesseraCore/Sources/TesseraTess/TessSetCountAsk.swift:102`). After `log it`: "Bench 80 × 8 logged for Monday." (`TessSetCountAsk.swift:107`), one op, so UNDO takes back the set and any workout it made (`review-251.md`). Since #262 the set joins Monday's workout that already has Bench, stamped at its end (P1, P2). After `not now`: no line and nothing written. Never a task. The LOG and NOT NOW words are still not drawn (#264 drew tap answers only for the 2 × 10 ask; QA C5), and nothing in the app calls the dated `answer(_:)` (`TessCaptureEngine.swift:68`), so type the answers. The typed answers are tested outside a workout only (`DatedLiftAskTests.swift:47-54`); if `log it` is read as something else here, mark F. Phone check: Monday's dab shows trained on Review and the set is in Bench's history under Monday. | Yes | [ ] P [ ] F |
| 10 | 9 | Log a set with the hold key, then lock (Cmd+L). | Since #269 the rest card on the Lock Screen is Kaushik's Cobalt sky in every look, Light or Dark (`Widgets/RestLiveActivity.swift:107`): a dark violet tint (`#120E1A` at 46%) over the material, a cobalt wash (`#3F7FC0`) strong at the top left and violet (`#7A5CA0`) at the top right, countdown in cream (`#F6EFE4`) (`Shared/LookTable.swift:31-33`, timer colour `RestLiveActivity.swift:255`). Not white, even on Porcelain. Dynamic Island black, the Obsidian set, whatever the look (`RestLiveActivity.swift:51-52`). The countdown running out to "Go" and later "set aside" (`Widgets/RestLiveActivity.swift:78, 215`) is a timing check: phone only. | Part | [ ] P [ ] F |
| 11 | 8 (QA smoke) | Unlock. Tap an exercise name to open its page, go back, then finish or close the workout. | Home is white with no glow around Tess's soul or the seams (#215). Free while you are here; not in the short path list. | Yes | [ ] P [ ] F |
| 12 | 6 (second half) | Relaunch with `-demoTime 18:10 -theme porcelain`, start the workout again, look, close it. Relaunch without `-theme`. | The workout looks the same as step 6 (white ground, ink keys), since Porcelain is already the day look (#266). `-theme porcelain` pins in memory only (`Theme.swift:281`, `Looks.swift:276-280, 295-296`), so nothing is saved: after the relaunch without `-theme`, the LOOK sentence still reads "Porcelain by day, Obsidian by night.", not "Porcelain always." | Yes | [ ] P [ ] F |
| 13 | 15 | Plans: make a routine with no exercises (or empty one). Look at Now, the rest day and Training. | No Start word anywhere for it: Now's "Start *name*" and "Start" (`Features/Home/NowPage.swift:409, 447-449`), Training's "Start workout" (`TrainingPage.swift:184-186`) all hidden by `canStart` (`App/AppModel.swift:550-552`). Siri's Start refusing it ("the routine has no exercises", `TesseraCore/Sources/TesseraCore/Actions/PlanActions.swift:121`) is phone only. | Part | [ ] P [ ] F |
| 14 | 24 | Swipe to Review (the Home page). | A headline that counts sessions, such as "Four sessions this week", "All six sessions in", "Two sessions in your first week" or "A quiet week so far" (`Features/Home/ReviewPage.swift:34-48`). Never "good", never "of seven", never one word alone on a line (`ReviewPage.swift:288-310`). Weeks count from Monday, so a Monday run reads "A quiet week so far" (QA L3, `review-234.md`). The number depends on the run date. | Yes | [ ] P [ ] F |
| 15 | 25 | Same page: the week row, Monday first. | Trained days marked, planned rest as a dry ink stroke in the lower half, a ring only on a past day that was due, nothing on days ahead, nothing before first use (`ReviewPage.swift:57-61`). Two sessions in one day count as one day. | Yes | [ ] P [ ] F |
| 16 | 29 | The week, foot, tap **BACKUPS** (`Features/Review/ReviewView.swift:228-232`). If the body says "The first copy is made when you leave the app today." go Home (Cmd+Shift+H), reopen, and look again. | Headline "Kept on this iPhone" (`Features/Backup/BackupView.swift:51`). Body "A copy is made every day, the last one today. Seven are kept." (`BackupView.swift:349`); the first-copy line is `BackupView.swift:342`. "Kept in two places" needs an iCloud Drive folder: phone only. "Reinstalled? Restore brings back your copy from iCloud Drive." (`BackupView.swift:71`) shows only when none of the last 2000 ops is by anyone but `.system` (`:70`, #264 closed R3). Steps 7 to 9a logged sets by Tess, so here it should **not** show; if it does, mark F. | Part | [ ] P [ ] F |
| 17 | 32 | Back to Home. Tap Tess, **Write** (`Features/Command/BottomChrome.swift:35`). Since #264 the open sheet asks "What’s on your mind?" and the field says "Write anything" (`BottomChrome.swift:227, 299`). Type `sk-ant-test` (a made-up prefix, never a real key). | The line clears itself the moment "sk-ant-" is typed (`BottomChrome.swift:316-323`), no ghost row and no task, and Tess says "That looks like a Claude key. It goes in Review, under Claude." for 4 s (`BottomChrome.swift:406`). **Not** the guide's "Paste it in Settings." Core's router now says the same line (`TessModel.swift:60`, closed by #248). | Yes | [ ] P [ ] F |
| 18 | 33 | Review, **The week**, scroll to CLAUDE (below LOOK, `ReviewView.swift:221-225`). | Header "CLAUDE" (`Features/Settings/ClaudeSection.swift:73`), "Tess thinks **on this phone** only." (`ClaudeSection.swift:126`) and **Add a Claude key** (`ClaudeSection.swift:133`). The LOOK sentence stays where it was, just above. | Yes | [ ] P [ ] F |
| 19 | 34 | Tap **Add a Claude key**, type `hello`, press Return. | "That doesn't look like a Claude key. Paste it again?" (`ClaudeSection.swift:285`), nothing saved, still "Add a Claude key" after you leave the field. A short paste like "hello" does not check by itself; only 10 or more characters landing at once do (`ClaudeSection.swift:237`), so Return is needed. | Yes | [ ] P [ ] F |
| 20 | 35 | **Real key: phone only.** On the Simulator instead: relaunch with `-demoTime 18:10 -openLink review -fakeClaudeKey`, scroll to CLAUDE. Do not tap TEST. Optional: tap REMOVE, then UNDO. | With the fake in-memory key (`ClaudeSection.swift:41-46`, read through `LaunchFlags` at `:43`, never the Keychain): "Tess can ask **Claude**." (`:150`), "This month **$0.00** of $10." (`:159`), "Key ends in **...a1B2** · not checked" (`:188`), and TEST, REPLACE, REMOVE (`:194-199`). REMOVE: "Claude key removed. Everything stays on this phone." with UNDO (`:346`); UNDO: "Claude key is back." (`:360`). On the phone, Kaushik's own key gives "Checking it with Claude." (`:301`), then "Key saved. Ends in ...*last four*." (`TesseraCore/Sources/TesseraTess/ClaudeKey.swift:317`) and "Key ends in ...*last four* · works". | No (sim stand-in) | [ ] P [ ] F |
| 21 | 20 | *Late night, faked.* Relaunch with `-demoTime 00:30` (no reset). Tess, Write: `coffee at 3`, Return. Then `remind me tomorrow at 9 to call mom`, Return. | "Coffee, *Weekday* 3 pm." where *Weekday* is the run's calendar day (on Oct 22: "Coffee, Thursday 3 pm."), never "tomorrow" (`TessCaptureEngine.swift:363-375`, test `TesseraCore/Tests/TesseraCoreTests/DayBoundaryTests.swift:77`). Then "Call mom, *Weekday* 9 am. On Now then." (`TessCaptureEngine.swift:233`, day words `:363-385`). If "coffee at 3" lands on Groceries, mark F (no test covers that exact phrase). | Yes | [ ] P [ ] F |
| 22 | 26 | Same launch (00:30). Swipe to Review. | Today (still the evening's day until 4 AM, `TesseraCore/Sources/TesseraCore/Engine/TesseraDay.swift:10`) has no ring even with no workout yet. | Yes | [ ] P [ ] F |
| 23 | #269 | *The device-only guards.* Nothing to tap: the guards switch on only in a device build, and on the Simulator every flag is meant to work, so they can't be seen failing here. Confirm two things instead. (1) On the Simulator: steps 1, 12, 20 and 21 already showed `-resetDemo`, `-theme`, `-openLink`, `-fakeClaudeKey` and `-demoTime` working, which is the Simulator half. (2) By code read at the hash you built (`git show <hash>:App/LaunchFlags.swift`, then `git grep -n 'ProcessInfo.processInfo.arguments' <hash> -- '*.swift'`). | (1) Every flag in this script worked on the Simulator. (2) `LaunchFlags.allowed` is `true` only under `#if targetEnvironment(simulator)` (`App/LaunchFlags.swift:8-14`), and `has` / `value(after:)` check it first (`:17-30`). The grep finds only `LaunchFlags.swift:18, 25` and the default parameters at `AppClock.swift:18`, `Theme.swift:279`, `DemoData.swift:14`. `resetUserData()` is `return` on a device (`ObjectStore+Lifecycle.swift:55-56`). `TesseraUITests/SimulatorOnly.swift:8-9` throws `XCTSkip` off the Simulator. There is **no** on-screen message for ignored flags on a phone (not built; nothing to look for). Never try a flag on his phone to check. | No (code read) | [ ] P [ ] F |

**Timing.** Steps 1 to 5 about 2.5 minutes, 6 to 12 (with 8a and 9a) about 5, 13 to 16 about 2.5, 17 to 20 about
1.5, 21 and 22 about 1, 23 about 1. About 13 minutes with the relaunches.

## Not on the Simulator: what QA checks instead

| What | Step | Why not | QA checks instead |
|---|---|---|---|
| Lock Screen and Live Activity timing (rest running out to "Go", "set aside" after 10 minutes locked, the Lock Screen Undo) | 10 | Needs real minutes on a locked phone and the real Lock Screen | Colours of the rest card and the Island on the Simulator lock (step 10). Kaushik does items 16 and 17 on the phone. |
| Dark Mode by day and night (Automatic, after sunset, about 6:15 PM Pacific this week) | 5 | The Simulator has no sunset switch | Manual flip with `simctl ui ... appearance` (step 5). |
| Haptics (the light tick on a tap, the firmer one on a hold, the hold-to-log clunk) | 3, 4, 10 | The Simulator has no Taptic Engine | Code check: `.selection` on tap and `.impact(weight: .medium, intensity: 0.8)` on hold (`LookSentence.swift:69-70`). Feel is Kaushik's. |
| Real Siri ("Start *empty routine*") | 13 | No real Siri on the Simulator | No Start word on screen (step 13); the engine refusal is `PlanActions.swift:121`. |
| Real dictation (item 13, "same at nine") | 8a | No keyboard mic on the Simulator | Type `same at nine` (step 8a): since #262 typed number words go through the same normaliser in a workout (`TessGrammar.swift:115-124`). `Same at 9.` with the full stop also works (`TessGrammar+Live.swift:15-17`). |
| Speak, real speech (#273, if in the build) | phone section below | No mic on the Simulator | Kaushik's one-minute phone check after the install (below). |
| The launch-flag guards on a device (#269) | 23 | They only exist in a device build; on the Simulator the flags are meant to work | Code read at the built hash (step 23). On the phone, never tick a flag to test it. |
| iCloud Drive folder pick (item 31, "Kept in two places") | 16 | No iCloud Drive account on a test Simulator | Only "Kept on this iPhone" on the Simulator. |
| Keychain Claude key (item 35, a real key and the check with Claude) | 20 | Needs a real key and a real call; a key must never be pasted by QA | `-fakeClaudeKey` stand-in (step 20). Kaushik types his own key on the phone, never in chat. |

**Counts.** 25 steps (23 plus 8a and 9a). 17 run fully on the Simulator. 6 run there with one part left for the phone
(steps 3, 4, 5, 10, 13 and 16). 2 do not run there: step 20 (the real Claude key; the `-fakeClaudeKey` stand-in runs
instead) and step 23 (a code read). Steps 21 and 22 fake the clock with `-demoTime 00:30`, which is enough for these
two lines; a real after-midnight session is still worth one look on the phone.

## After the install: Speak on the phone (about 1 minute)

**Only if the installed build contains Builder B's Speak PR #273.** At 9:24 PM PT #273 is open, not merged, so
`444e72b` has no Speak: tapping Speak there just says "Speak comes next." (`BottomChrome.swift:283-285`) and this section is skipped. If #273 merges
first and goes into the install, Kaushik runs this on his iPhone right after the install. Expected lines are from
`speak-first-use.md` (row in brackets); if #273's line differs, mark F and write what it said. For a test capture
he doesn't want kept, tap UNDO under Tess's line.

| # | Do | Expect | P / F |
|---|---|---|---|
| S1 | Tap Tess's soul, tap **Speak**. On the mic alert tap **Don't Allow**. | Before the alert: "Tess needs the mic to hear you." (1a). After Don't Allow: "Mic is off for Tessera. Open Settings" (3a), and no second alert. | [ ] P [ ] F |
| S2 | Tap **Open Settings**, turn **Microphone** on, then go back to Tessera (top-left "Tessera"). | Settings opens on Tessera's own page (6a). Back in the app: Home, Tess at rest, no line. **Open check (a), row 6b:** did the app start fresh (a cold launch) when the switch changed? Yes [ ] No [ ] | [ ] P [ ] F |
| S3 | Tap the soul, tap **Speak**. Say "buy milk", then stop talking. | "Mic is on." this once, in place of "Listening" (6c, micBack). Then the clean words, the voice ghost draining for 3 s with "Heard: buy milk" under it (2c), then Tess's line beside the soul with UNDO. Tap UNDO. | [ ] P [ ] F |
| S4 | Tap Speak and say nothing for 5 s. | "Didn't hear anything." and nothing saved (10a). | [ ] P [ ] F |
| S5 | Tap Speak, then tap the dimmed page outside the bloom. | Listening stops; nothing saved and no line (2a). | [ ] P [ ] F |
| S6 | Only if a workout is running: hold the soul, say "eighty by eight", let go. | "Set N logged. 80 × 8." with UNDO; the set's numerals dry into ink (7a, 11c). | [ ] P [ ] F |
| S7 | **Open check (b), row 8c**, on the first Speak listen above (phone set to English (India), en-IN). | Plain "Listening" means an **exact match**; "Listening in English (UK)." on the first open only means a **near match**. Exact [ ] Near [ ]. Fail: the near-match line shows on every open. | [ ] P [ ] F |

## Next build with #317's haptics: one phone check

| # | Do | Expect | Result |
|---|---|---|---|
| H1 | Turn off Settings > Sounds & Haptics > System Haptics, then finish a task or a workout. | No three-tap done pattern. If it still buzzes, tell Builder A, who switches to `.success` because that one respects the switch. | [ ] P [ ] F |

## Master strings that look wrong or stale

1. **Closed by #248 (`fdcaee4`).** Item 32's two Claude-key lines now agree: Core's router uses
   `TessRouter.keyLine`, "That looks like a Claude key. It goes in Review, under Claude."
   (`TesseraCore/Sources/TesseraTess/TessModel.swift:60`, test `ClaudeKeyTests.swift:85`), the same as the Ask bar
   (`Features/Command/BottomChrome.swift:406`). Only the guide still says "Paste it in Settings." and needs the new line.
2. **Item 33's place.** There is no Settings: Claude screen; the section is "CLAUDE" on the full week, under LOOK
   (`ReviewView.swift:221-225`). The guide's "The LOOK sentence may move there" did not happen.
3. **Item 34 needs Return.** Typing or pasting "hello" does nothing until Return, because only 10 or more characters
   landing at once start the check (`ClaudeSection.swift:237`).
4. **Item 20's second phrase.** "remind me tomorrow at 9" has no title once "remind me" and the date are taken out,
   so the grammar returns nothing (`TessGrammar.swift:543-546`) and no task is made. The guide's "lands Saturday
   9 am ... On Now then." only holds with a title, as in step 21 ("... to call mom").
5. **Minor, not on screen.** The comment above `BackupCopy.local` says "The last one was today."
   (`BackupView.swift:340`) but the line drawn is "..., the last one today." (`:349`), which matches the guide.
