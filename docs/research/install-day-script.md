# Install-day script: the 10-minute short path on the Simulator

*Research lab, board item 87, Oct 16. For QA (runs it) and Product (reads the result). Turns the "10-minute
short path" in `product/review-session.md` into numbered steps QA can run on the iOS Simulator before the Oct 22
re-sign. Context: `research/review-refresh-2.md`. All times are Pacific.*

**Install commit:** latest master at run time. Write the short hash here: `________`. This script was checked
against master `8fc5bd3` (Oct 15, 8:12 PM Pacific), which already includes Settings: Claude (#227). If master has
moved, re-check any line marked with a source and note the new hash.

**How to read a step.** *Do* is what to tap or type. *Expect* is the screen and the exact line, with the master
source as `file:line`. *Sim* says whether it runs on the Simulator: **Yes**, **Part** (the screen runs, one part
needs the phone) or **No** (phone only; the step says what QA checks instead). Tick **P** or **F** in the last
column and write a few words for any F.

## Before you start (2 minutes, not timed)

- Simulator: iPhone 17, iOS 27 runtime, Debug build of the `Tessera` scheme (the `-demo...` arguments only work in
  Debug).
- Fresh look state: uninstall first (`xcrun simctl uninstall booted com.kaushikaranagu.tessera`), so the look starts
  on Porcelain by day and Obsidian by night (`DesignSystem/Looks.swift:207-208`). The look lives in the App Group,
  not in the demo data, so `-resetDemo` alone does not reset it (`DesignSystem/Looks.swift:137-151`).
- Appearance Light: `xcrun simctl ui booted appearance light`.
- Clock: `-demoTime HH:mm` sets the app's clock to that time today in the Mac's time zone
  (`App/AppClock.swift:18-31`). Keep the Mac on Pacific, or launch with `SIMCTL_CHILD_TZ=America/Los_Angeles`.
- Launch with arguments through MobileBuildMCP `build_run_sim`, or
  `xcrun simctl launch booted com.kaushikaranagu.tessera -demoTime 18:10 -resetDemo`.
  `-resetDemo` wipes and reseeds the demo history (`App/TesseraApp.swift:30`, `Features/Demo/DemoData.swift:9`).
- Do not use `-theme <name>` for steps 1 to 5: it pins a look in memory, so the LOOK sentence shows
  "*Name* always." instead of the day and night pair (`DesignSystem/Theme.swift:277-285`,
  `DesignSystem/Looks.swift:297-300`). It is only used in step 12.
- Useful keys: Lock is Device, Lock (Cmd+L). Home is Cmd+Shift+H. Paste into the app with Cmd+V after
  Edit, Send Pasteboard if needed.
- The Simulator has no haptics. Every "tick" or "clunk" in this script is a phone check (see the phone-only list).

## The script

| # | Item | Do | Expect (exact line, master source) | Sim | P / F |
|---|---|---|---|---|---|
| 1 | 1 | Launch with `-demoTime 13:00 -resetDemo` in Light. Wait on Home. | White ground (Porcelain, `#FFFFFF`), ink text, colour only behind what is live. Not the cream paper. `DesignSystem/Looks.swift:63-65`, default at `:207`. | Yes | [ ] P [ ] F |
| 2 | 3 | Swipe to Review, tap the link word **The week** (`Features/Home/HomeSpatialView.swift:207`). Scroll to the foot. | Label **LOOK** (written "Look", drawn in caps by the label role, `DesignSystem/LookSentence.swift:15`, `DesignSystem/Theme.swift:228`), then "Porcelain by day, Obsidian by night." (`LookSentence.swift:33-41`) and under it "Hold a name to keep it day and night." (`LookSentence.swift:64`). Below it the CLAUDE section, then BACKUPS. | Yes | [ ] P [ ] F |
| 3 | 4 | Tap **Porcelain**. Tap again. Tap again. Then tap **Obsidian**, then tap **Lacquer** once more to put it back. | Porcelain becomes **Plein** and the page crossfades to cream in 0.7 s; then **Celadon** (pale green); then **Porcelain** (`Looks.swift:112, 245-247`; fade `LookSentence.swift:119`). Obsidian becomes **Lacquer** and the page does not change by day (`Looks.swift:250-253`); the next tap brings back Obsidian. Light tick: phone only. | Part | [ ] P [ ] F |
| 4 | 5 | Hold **Obsidian** for half a second. Then hold it again. | Page turns black. Sentence reads "Obsidian always." with "Hold it again to follow light and dark mode." (`LookSentence.swift:27-29`, hold time `:91`). Second hold: back to "Porcelain by day, Obsidian by night." with Obsidian in the night slot (`Looks.swift:279-295`). Watch for: the name also stepping to Lacquer on release (the tap and the hold share the word, `LookSentence.swift:83-94`); if it does, mark F. Firmer haptic: phone only. | Part | [ ] P [ ] F |
| 5 | 2 | `xcrun simctl ui booted appearance dark`, look, then `... appearance light`. | Page swaps at once to true black (Obsidian, `#000000`, `Looks.swift:73-75`), no paint flood, status bar text turns light. Back to white on Light. The switch by sunset (Automatic) is phone only; the look never reads the clock, so `-demoTime` does not change it. | Part | [ ] P [ ] F |
| 6 | 6 | Relaunch with `-demoTime 18:10` (no reset). Training, **Start workout** on Push Day A (`Features/Home/TrainingPage.swift:186`). | Workout ground plum-black (`#14111A`), cream keys you can read (`Looks.swift:68-69`). Not the old purple paper. | Yes | [ ] P [ ] F |
| 7 | 10 | On Bench Press, tap Tess's soul (bottom right). The writing line shows "log bench 80x8, or ask" (`Features/Workout/WorkoutParts.swift:321`). Type `81 for 8`, Return. | "Set N. 80 x 8. 81 isn't loadable." with N the set number (`TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:123, 127`). | Yes | [ ] P [ ] F |
| 8 | 11 | Tess: `100 for 5 at 8`, Return. Then `same at 9`, Return. | "Set N. 100 x 5 @8." then "Same again @9, logged." (`TessCaptureEngine.swift:119-123`). | Yes | [ ] P [ ] F |
| 9 | 12 | Tess: `81`, Return. Then `+5`, Return. Then `call mum at 7`, Return. | `81` and `+5`: no set and no task (`TesseraCore/Sources/TesseraTess/TessGrammar+Live.swift:40-41, 69-76`). The line is then the model's: on a Mac without Apple Intelligence it is "Didn't catch that. Try “bench 80 x 8”." (`TessModel.swift:74`), drawn with curly quotes; a question is also fine. `call mum at 7` (before 7 PM): "Call mum, today 7 pm." (`TessCaptureEngine.swift:133, 217-239`) and the task is on Now. | Yes | [ ] P [ ] F |
| 10 | 9 | Log a set with the hold key, then lock (Cmd+L). | Rest card on the Lock Screen: plum-black (`#14111A`) with an amber (`#F0A500`) timer in Light (`Shared/LookTable.swift:14, 37-38`). Dynamic Island black. In Dark the card is pure black with `#FFC23D` (`LookTable.swift:16`), optional here. The countdown running out to "Go" and later "set aside" (`Widgets/RestLiveActivity.swift:78, 215`) is a timing check: phone only. | Part | [ ] P [ ] F |
| 11 | 8 (QA smoke) | Unlock. Tap an exercise name to open its page, go back, then finish or close the workout. | Home is white with no glow around Tess's soul or the seams (#215). Free while you are here; not in the short path list. | Yes | [ ] P [ ] F |
| 12 | 6 (second half) | Relaunch with `-demoTime 18:10 -theme porcelain`, start the workout again, look, close it. Relaunch without `-theme`. | Keys still cream on plum-black. `-theme porcelain` pins in memory only (`Looks.swift:297-300`), so nothing is saved. | Yes | [ ] P [ ] F |
| 13 | 15 | Plans: make a routine with no exercises (or empty one). Look at Now, the rest day and Training. | No Start word anywhere for it: Now's "Start *name*" and "Start" (`Features/Home/NowPage.swift:390-391, 427-429`), Training's "Start workout" (`TrainingPage.swift:184-186`) all hidden by `canStart` (`App/AppModel.swift:533-535`). Siri's Start refusing it ("the routine has no exercises", `TesseraCore/Sources/TesseraCore/Actions/PlanActions.swift:121`) is phone only. | Part | [ ] P [ ] F |
| 14 | 24 | Swipe to Review (the Home page). | A headline that counts sessions, such as "Four sessions this week", "All six sessions in", "Two sessions in your first week" or "A quiet week so far" (`Features/Home/ReviewPage.swift:34-47`). Never "good", never "of seven", never one word alone on a line (`ReviewPage.swift:286-308`). The number depends on the run date. | Yes | [ ] P [ ] F |
| 15 | 25 | Same page: the week row, Monday first. | Trained days marked, planned rest as a dry ink stroke in the lower half, a ring only on a past day that was due, nothing on days ahead, nothing before first use (`ReviewPage.swift:54-58`). Two sessions in one day count as one day. | Yes | [ ] P [ ] F |
| 16 | 29 | The week, foot, tap **BACKUPS** (`Features/Review/ReviewView.swift:227`). If the body says "The first copy is made when you leave the app today." go Home (Cmd+Shift+H), reopen, and look again. | Headline "Kept on this iPhone" (`Features/Backup/BackupView.swift:48-49`). Body "A copy is made every day, the last one today. Seven are kept." (`BackupView.swift:300`); the first-copy line is `BackupView.swift:293`. "Kept in two places" needs an iCloud Drive folder: phone only. | Part | [ ] P [ ] F |
| 17 | 32 | Back to Home. Tap Tess, **Write** (`Features/Command/BottomChrome.swift:32`). Type `sk-ant-test` (a made-up key, never a real one). | The line clears itself the moment "sk-ant-" is typed (`BottomChrome.swift:297-301`), no ghost row and no task, and Tess says "That looks like a Claude key. It goes in Review, under Claude." for 4 s (`BottomChrome.swift:405`). **Not** the guide's "Paste it in Settings." (see the end). | Yes | [ ] P [ ] F |
| 18 | 33 | Review, **The week**, scroll to CLAUDE (below LOOK, `ReviewView.swift:216-221`). | Header "CLAUDE" (`Features/Settings/ClaudeSection.swift:67`), "Tess thinks **on this phone** only." (`ClaudeSection.swift:111`) and **Add a Claude key** (`ClaudeSection.swift:117`). The LOOK sentence stays where it was, just above. | Yes | [ ] P [ ] F |
| 19 | 34 | Tap **Add a Claude key**, type `hello`, press Return. | "That doesn't look like a Claude key. Paste it again?" (`ClaudeSection.swift:244-245`), nothing saved, still "Add a Claude key" after you leave the field. A short paste like "hello" does not check by itself; only 10 or more characters landing at once do (`ClaudeSection.swift:196-202`), so Return is needed. | Yes | [ ] P [ ] F |
| 20 | 35 | **Real key: phone only.** On the Simulator instead: relaunch with `-demoTime 18:10 -openLink review -fakeClaudeKey`, scroll to CLAUDE. Do not tap TEST. Optional: tap REMOVE, then UNDO. | With the fake in-memory key (`ClaudeSection.swift:39-47`, never the Keychain): "Tess can ask **Claude**." (`:134`), "This month **$0.00** of $10." (`:143`), "Key ends in **...a1B2** · not checked" (`:159`), and TEST, REPLACE, REMOVE. REMOVE: "Claude key removed. Everything stays on this phone." with UNDO (`:294`); UNDO: "Claude key is back." (`:308`). On the phone, Kaushik's own key gives "Checking it with Claude." (`:261`), then "Key saved. Ends in ...*last four*." (`TesseraCore/Sources/TesseraTess/ClaudeKey.swift:287`) and "Key ends in ...*last four* · works". | No (sim stand-in) | [ ] P [ ] F |
| 21 | 20 | *Late night, faked.* Relaunch with `-demoTime 00:30` (no reset). Tess, Write: `coffee at 3`, Return. Then `remind me tomorrow at 9 to call mum`, Return. | "Coffee, *Weekday* 3 pm." where *Weekday* is the run's calendar day (on Oct 22: "Coffee, Thursday 3 pm."), never "tomorrow" (`TessCaptureEngine.swift:217-233`, test `TesseraCore/Tests/TesseraCoreTests/DayBoundaryTests.swift:77`). Then "Call mum, *Weekday* 9 am. On Now then." (`TessCaptureEngine.swift:86-88`). If "coffee at 3" lands on Groceries, mark F (no test covers that exact phrase). | Yes | [ ] P [ ] F |
| 22 | 26 | Same launch (00:30). Swipe to Review. | Today (still the evening's day until 4 AM, `TesseraCore/Sources/TesseraCore/Engine/TesseraDay.swift:10`) has no ring even with no workout yet. | Yes | [ ] P [ ] F |

**Timing.** Steps 1 to 5 about 2.5 minutes, 6 to 12 about 4, 13 to 16 about 2.5, 17 to 20 about 1.5, 21 and 22
about 1. Just over 11 minutes with the relaunches.

## Not on the Simulator: what QA checks instead

| What | Step | Why not | QA checks instead |
|---|---|---|---|
| Lock Screen and Live Activity timing (rest running out to "Go", "set aside" after 10 minutes locked, the Lock Screen Undo) | 10 | Needs real minutes on a locked phone and the real Lock Screen | Colours of the rest card and the Island on the Simulator lock (step 10). Kaushik does items 16 and 17 on the phone. |
| Dark Mode by day and night (Automatic, after sunset, about 6:15 PM Pacific this week) | 5 | The Simulator has no sunset switch | Manual flip with `simctl ui ... appearance` (step 5). |
| Haptics (the light tick on a tap, the firmer one on a hold, the hold-to-log clunk) | 3, 4, 10 | The Simulator has no Taptic Engine | Code check: `.selection` on tap and `.impact(weight: .medium, intensity: 0.8)` on hold (`LookSentence.swift:69-70`). Feel is Kaushik's. |
| Real Siri ("Start *empty routine*") | 13 | No real Siri on the Simulator | No Start word on screen (step 13); the engine refusal is `PlanActions.swift:121`. |
| Real dictation (item 13, "same at nine") | outside the short path | No keyboard mic on the Simulator | Type `Same at 9.` with the full stop: same line as `same at 9` (`TessGrammar+Live.swift:15-18`). |
| iCloud Drive folder pick (item 31, "Kept in two places") | 16 | No iCloud Drive account on a test Simulator | Only "Kept on this iPhone" on the Simulator. |
| Keychain Claude key (item 35, a real key and the check with Claude) | 20 | Needs a real key and a real call; a key must never be pasted by QA | `-fakeClaudeKey` stand-in (step 20). Kaushik types his own key on the phone, never in chat. |

**Counts.** 22 steps. 15 run fully on the Simulator. 6 run there with one part left for the phone (steps 3, 4,
5, 10, 13 and 16). 1 does not run there (step 20, the real Claude key; the `-fakeClaudeKey` stand-in runs instead).
Steps 21 and 22 fake the clock with `-demoTime 00:30`, which is enough for these two lines; a real after-midnight
session is still worth one look on the phone.

## Master strings that look wrong or stale

1. **Item 32's line changed.** The guide expects "That looks like a Claude key. Paste it in Settings." In the app
   the Ask bar now refuses first and says "That looks like a Claude key. It goes in Review, under Claude."
   (`Features/Command/BottomChrome.swift:405`). The old line is still in Core's router
   (`TesseraCore/Sources/TesseraTess/TessModel.swift:64`) and its test (`TesseraCore/Tests/TesseraCoreTests/ClaudeKeyTests.swift:84`), so the two
   copies disagree, and there is no Settings screen to point to. Product: pick one line and update the guide.
2. **Item 33's place.** There is no Settings: Claude screen; the section is "CLAUDE" on the full week, under LOOK
   (`ReviewView.swift:216-221`). The guide's "The LOOK sentence may move there" did not happen.
3. **Item 34 needs Return.** Typing or pasting "hello" does nothing until Return, because only 10 or more characters
   landing at once start the check (`ClaudeSection.swift:196-202`).
4. **Item 20's second phrase.** "remind me tomorrow at 9" has no title once "remind me" and the date are taken out,
   so the grammar returns nothing (`TessGrammar.swift:453-456`) and no task is made. The guide's "lands Saturday
   9 am ... On Now then." only holds with a title, as in step 21 ("... to call mum").
5. **Minor, not on screen.** The comment above `BackupCopy.local` says "The last one was today."
   (`BackupView.swift:291`) but the line drawn is "..., the last one today." (`:300`), which matches the guide.
