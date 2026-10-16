# Ask lines: every permission and one-time ask

For: Core, Builder A, Builder B, Design (copy), Product lead. Research lab, board item 37, 2026-10-16.
Traced by hand on `origin/master` at `f933dd1` (no Swift toolchain). Sources: `calendar-pack.md`, `speak-first-use.md`, `speech-capture.md`, `speech-test-script.md`, `healthkit-reads.md`, `photo-field.md`, `capture-modes.md`, `widget-states.md`, `lockscreen-lines.md`, `quiet-interrupts.md`, `empty-states.md`, `fixtures/hint-ledger.md`, `fixtures/cook-mode-scenarios.md`, `tess-voice.md`, `restore-drill.md`, `../product/decisions.md`, `../product/ship-list-m5-people.md`, `notifications.md` (A7, A8 and Q5 updated, board item 45).

**Bottom line.** Tessera will show 10 asks: 8 it starts itself, 1 conditional (speech, only on the legacy path) and 1 that iOS owns (Live Activities). Photos, Siri and Shortcuts, Contacts and restore need no ask. Master ships 2 of them (Health write, the Live Activity key) and is missing 4 usage keys (calendar, mic, speech, camera). Its Health read string is present but wrong. Today the first workout can stack two asks: the Live Activity choice at the first rest and the Health sheet at the finish. The fix is one ask per logical day, a priority order and a small queue, below.

Two layers per ask, never mixed:
- **Tess pre-ask line**: her one line in the app, in her voice, with two text words (`no-buttons.md`), shown before the system alert. First person or no subject.
- **System usage string**: the Info.plist text Kaushik reads inside the iOS alert. It names Tessera, never "Tess" or "I" (rule from `healthkit-reads.md` §5), says what is read and where it stays.

## 1. What master has (`f933dd1`)

| Thing | Where | State |
|---|---|---|
| `NSHealthUpdateUsageDescription` | `project.yml:73` | "Tessera saves your finished workouts to Apple Health." |
| `NSHealthShareUsageDescription` | `project.yml:74` | "Tessera reads your workouts, heart rate and body weight from Apple Health to show them beside your training." Not shown yet: the request reads nothing |
| Health request | `App/Health/HealthExporter.swift:37` | `requestAuthorization(toShare: [workoutType()], read: [])` on the first finished workout with sets, from any path (in-app, Siri, Lock Screen, 6 h wrap-up). No Tess line before or after |
| `NSSupportsLiveActivities` | `project.yml:31`, `App/Info.plist:47` | true. `RestActivityController.swift:57` checks `areActivitiesEnabled` and silently skips when off |
| Backup folder picker | `Features/Backup/BackupView.swift:117` | `fileImporter` for a folder, only from the Backups screen value word "a folder you choose". No Tess ask |
| App Shortcuts | `App/AppIntentsPackageLink.swift:13` | 6 shortcuts, no Siri authorization call (none is needed) |
| Not on master | `git grep` | No EventKit, `AVAudioApplication`, `SpeechAnalyzer`, `SFSpeech`, `AVCaptureDevice`, `PhotosPicker`, `UNUserNotificationCenter`, `CNContactStore`. No calendar, mic, speech or camera key |

## 2. The asks

| # | Ask | Trigger moment | Tess pre-ask line (exact) | System usage string | Granted | Fallback on deny / Not now | Re-ask rule | Owner | Status on master |
|---|---|---|---|---|---|---|---|---|---|
| A1 | Health write (+ heart rate read once W1 ships) | First workout finished **in the app** with 1+ set, on the finish screen | "Save workouts to Apple Health? Heart rate too." **Save** · Not now (drop "Heart rate too." before W1) | Update: "Tessera saves your finished workouts to Apple Health." (shipped). Share: proposed "Tessera reads heart rate and sleep from Apple Health to show them beside your training. It stays on this iPhone." | Silent if one workout; with a backfill "Saved 3 workouts to Health." | "No health access yet. Workout saved here." | Not now: once more at the next in-app finish on a later day, then never. Denied: never (iOS won't show the sheet again); Settings row only | Core (`App/Health`), Builder A (finish screen line) | Shipped without the line; share string wrong; asks from Siri or Lock Screen finishes too |
| A2 | Health read, W3 (sleep, resting HR, HRV) | First training-day morning after W3 ships, on Now (decision 4:20 PM PT) | "Add last night's sleep from Health?" (the line is the tap) | Same share string as A1 (one string covers both) | Recovery line from the next read | Silence. No recovery line, never "denied" (decision 4:20 PM PT, `healthkit-reads.md` §4) | Never. Answered or dismissed, it is gone | Core (read layer), Builder B (Now line) | Not built |
| A3 | Calendar, full access | First open of Plan my day with status `.notDetermined` | "Plan around your calendar? Times and titles only." **Connect** · Not now | Missing. Proposed (`calendar-pack.md` §3): "Tessera reads the times and titles of your events to plan your day around them. It never changes your calendar." | Plan builds with events, no line | Denied or write-only: "Planned without your calendar. **Settings**". Restricted: "Planned without your calendar." Not now: plan builds with `cal:false`, no line | Not now: once, 7 days later, then only the denied line | Core (key, read), Builder B (line on Home/Now) | Missing key, not built |
| A4 | Microphone | First tap on Speak (never a hold, never at launch) | "I need the mic to hear you." (shown while the alert is up) | Missing. Proposed: "Tessera listens only while you hold to talk, so you can log by voice. Audio stays on this iPhone." | "Hold me to talk. Let go to send." | "Mic is off for Tessera. Open Settings?" Screen Time: "The mic is limited on this iPhone. Write still works." | Never from the app. Back on in Settings: "Mic is on. Hold me to talk." once | Builder B (`Features/Command`) | Missing key, not built ("Speak" is a word only) |
| A5 | Speech recognition | Only if the build calls `SFSpeechRecognizer.requestAuthorization`, right after A4. The `SpeechAnalyzer` path shows no alert | none (A4's line stays up) | Missing. Proposed: "Tessera turns what you say into text on this iPhone. Audio is never sent anywhere." Add the key either way | A4's granted line | "Speech is off for Tessera. Open Settings?" | Never | Builder B | Missing key, not built |
| A6 | Camera | First tap on Camera in Show (Photos · Camera · File) | "I need the camera to read the page." (shown while the alert is up) | Missing. Proposed: "Tessera uses the camera to read pages and receipts and add photos. Photos stay on this iPhone." | Document camera opens | "Camera is off for Tessera. Open Settings?" (Photos stays one tap away) | Never from the app | Builder B (Show layer), Core (`MediaStore`) | Missing key, not built |
| A7 | Notifications (N1 timed task, N2 rest, N3 kitchen timer) | The first of: a kitchen timer start, a "remind me" capture, or a task saved with an explicit clock time. Never at a rest, at launch, in onboarding or from a background path. Pushed, not pulled. Superseded: was "first kitchen timer only". Changed Oct 15 (notifications.md) | Timer trigger: "Want timers to alert you when locked?" **Allow** · Not now. Task trigger: "Want me to buzz you at 9 am?" **Allow** · Not now (his time filled in). Allow shows the iOS sheet, `[.alert, .sound]`, no provisional | No key exists. iOS shows fixed text: "“Tessera” Would Like to Send You Notifications" | Silent; the timer runs or the task is set. Rests now ring by notification and the Live Activity alert goes off (A8) | "remind me" with no permission (pending, Not now or denied): the reply ends "On Now then." ("Call mom, Saturday 9 am. On Now then."). Timer after Not now or denied: "Timers alert in the app only." A plain timed task with no "remind": no extra words | Not now: once more, 7 days later at any trigger. Denied: never. The quiet-interrupts digest never asks on its own | Core (scheduler, delegate, ledger, "On Now then."), Builder A (rest alert off when allowed), Builder B (lines) | Not built (no notification code) |
| A8 | Live Activities | First rest in the first workout. iOS, not Tessera, may show Allow / Don't Allow on the Lock Screen (UNVERIFIED on iOS 27) | none (system owned) | No key text. `NSSupportsLiveActivities` only | Rest face on the Lock Screen. Rest end sound: notifications allowed (A7), the N2 notification rings and the Live Activity alert is off (`restEndAlert` nil); not allowed, the Live Activity alert stays. Never both. Changed Oct 15 (notifications.md) | When `areActivitiesEnabled` is false at a rest, once ever: "Live Activities are off. Rest shows here." | Never | Builder A (Workout, Widgets) | Shipped key; no off line |
| A9 | iCloud Drive folder for backups | First open on day 2 or later, once a local copy exists, no process running | "Keep copies in iCloud Drive too? They survive deleting the app." **Pick a folder** · Not now | None: the Files picker needs no key or entitlement | "Saved a copy there. One a day from now on." (shipped) | Not now or cancel: silence; Backups keeps "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." Bad folder: "Couldn't use that folder. Pick another?" | Never as a line. The Backups screen word stays | Core (Backup), Builder B (Now line) | Picker shipped; Tess ask not built |
| A10 | Health read, later types (W4 workouts) | W4 ships; next in-app finish | "Match Watch workouts from Health?" **Match** · Not now | Same share string, add "and workouts" when W4 lands | Duplicates merge | "No health access yet. Workout saved here." | As A1 | Core | Not planned yet |

**No ask at all** (listed so nobody adds one):
- **Photos (Show).** `PhotosPicker` runs out of process; no permission, no key (`photo-field.md` §9). Offline iCloud-only photo: "That photo is still in iCloud. Try again online."
- **Siri and Shortcuts.** App Shortcuts need no `INPreferences.requestSiriAuthorization` (that needs a SiriKit entitlement we don't use). Siri asks for missing values in its own words.
- **Contacts.** People ships with no Contacts access (`ship-list-m5-people.md`, approved).
- **Restore and Files.** `fileImporter` for `.tessera` and the Files sharing keys need no ask.
- **Speech assets.** "Getting speech ready. Needs a connection once." is a status, not an ask; it never counts.

## 3. Never stack

**Rule 1. One ask per logical day.** A day runs 04:00 to 04:00 (`RollForward.logicalDay`, public per decision 4:50 PM PT). Any shown ask uses the day's slot: a Tess pre-ask line, a system sheet Tessera calls, or the Live Activity choice iOS shows when Tessera starts its first activity.

**Rule 2. Pulled asks always run.** When he taps the thing itself (Speak, Camera, Connect, a folder word, Health in Settings), the system alert follows at once; blocking a tap breaks the feature. A pulled ask uses the slot, so nothing pushed follows that day.

**Rule 3. Pushed asks, in priority order.**
1. A1 Health write (moment: in-app finish; data is lost to Health without it)
2. A3 Calendar (moment: Plan my day)
3. A7 Notifications (moment: a kitchen timer start, a "remind me" or a task with a clock time; never a rest)
4. A9 iCloud folder (floating; data safety)
5. A2 W3 sleep (floating)
6. A10 W4 workouts (moment: finish)

**Rule 4. Queue.** A pushed ask that meets a used slot is marked pending and fires at its next trigger on a later day. Meanwhile the feature runs on its quiet fallback with **no** fallback line (a line for an ask he never saw would read as a refusal). A1 pending: on grant, every finished workout since install is saved (`HKMetadataKeySyncIdentifier` makes it idempotent). A3 pending: plan builds with `cal:false`. A7 pending: timer alerts in the app and on the Live Activity only; rests keep the Live Activity alert. One exception to "no fallback line": a "remind me" reply still ends "On Now then.", which says where the task shows, not that anything was refused.

**Rule 5. Floating asks wait.** A9 and A2 show only when no moment ask is pending, never on day 1, never during a running workout, cook or focus block, and at most one per day.

**Rule 6. Never at launch, never in onboarding, never from a background path.** HealthExporter must not call `requestAuthorization` when the finish came from Siri, the Lock Screen or the 6 h wrap-up; it marks A1 pending and saves on the next in-app finish.

**Ledger.** `TessAskLedger` beside `TessHintLedger` (Core): `tess.asks.v1` with, per ask id, `state` (`unseen`, `pending`, `shown`, `notNow`, `answered`), `shownDay`, `notNowDay`. `-resetAsks` for the demo. Asks do not count toward the 3-a-day hint cap, but no S, G or H line shows while an ask line is on screen.

## 4. First week, fresh install, every slice shipped

Mon 19 Oct to Sun 25 Oct 2026, America/Los_Angeles. Training Mon, Wed, Fri, Sun. W3 is live.

| Day | What he does | Ask that fires | Held back |
|---|---|---|---|
| Mon 19 | Push A at 18:30. First rest at 18:34. 21:10 "remind me to call mom tue 9am" | A8 Live Activity choice (iOS). Slot used | A1 at the 19:25 finish: pending. Finish line as normal, no Health line. A7 at the "remind me": pending; reply "Call mom, Tuesday 9 am. On Now then." |
| Tue 20 | Rest day. 07:40 opens Plan my day. 18:05 "timer rice 12" | A3 Calendar: "Plan around your calendar? Times and titles only." He taps Connect | A7 at the timer start: pending; the timer alerts in the app |
| Wed 21 | Pull A at 18:15. At 18:20 taps Speak mid-workout | A4 Mic (pulled): "I need the mic to hear you." Allow | A1 at the finish: still pending (slot used) |
| Thu 22 | Rest day. 18:10 "timer pasta 10" | A7 Notifications: "Want timers to alert you when locked?" Allow. From Fri 23 rests ring by notification; the Live Activity alert is off | A9 floating: waits (A1 still pending) |
| Fri 23 | Legs at 18:30. Finish 19:30 | A1 Health: "Save workouts to Apple Health? Heart rate too." Save. Then "Saved 3 workouts to Health." | A2 at 07:30: waits for A1 (rule 5) |
| Sat 24 | Rest day. First open 09:00 | A9 Folder: "Keep copies in iCloud Drive too? They survive deleting the app." He picks iCloud Drive/Tessera | none |
| Sun 25 | Push B. 07:30 opens Now | A2 W3: "Add last night's sleep from Health?" | A6 Camera waits for his first Camera tap (pulled, any day) |

One ask a day, seven days, nothing lost: Health still gets all three workouts. The wider A7 trigger (Oct 15) reaches Monday but does not move A7: Mon to Wed slots are used, so it still fires Thu 22. Had his first trigger been a task, Thursday's line would be "Want me to buzz you at 9 am?" If iOS 27 shows no Live Activity choice, A1 fires on Monday instead and the week shifts one ask earlier.

**Today on master the first workout stacks two:** A8 at the first rest and the Health sheet at the finish, in the same session. A Siri or Lock Screen finish also calls `requestAuthorization` from the background, where the sheet may not show at all (UNVERIFIED; it should fail rather than show).

## 5. Voice check

Rules from `tess-voice.md`: one line under 12 words, plain, offer not instruct, no "!", no emoji, no em-dashes, honest about limits, Tess in first person. System strings name Tessera.

| Line | Verdict | Before | After |
|---|---|---|---|
| A1 share string (master) | **Fail, worst.** Promises body weight and workout reads nothing makes; omits sleep (W3); says nothing about where data stays. Kaushik reads it in the iOS sheet | "Tessera reads your workouts, heart rate and body weight from Apple Health to show them beside your training." | "Tessera reads heart rate and sleep from Apple Health to show them beside your training. It stays on this iPhone." |
| A1 pre-ask | Missing on master | (none; the sheet appears cold) | "Save workouts to Apple Health? Heart rate too." |
| A4 mic line | Fail: Tess speaks of herself in third person | "Tess needs the mic to hear you." | "I need the mic to hear you." |
| A4 mic usage string | Fail: names Tess in a system string; two drafts disagree ("hold the bar" is gone) | "Tess listens only while you hold to talk, so you can log by voice. Audio stays on this iPhone." | "Tessera listens only while you hold to talk, so you can log by voice. Audio stays on this iPhone." |
| A5 speech usage string | Fail: same | "Tess turns what you say into text on this iPhone. Audio is never sent anywhere." | "Tessera turns what you say into text on this iPhone. Audio is never sent anywhere." |
| A6 camera usage string | Fail: "objects" is engine jargon; misses pages and receipts | "Tessera uses the camera to add photos to your objects." | "Tessera uses the camera to read pages and receipts and add photos. Photos stay on this iPhone." |
| A9 bad folder (master) | Fail: instruction | "Couldn't use that folder. Try another one." | "Couldn't use that folder. Pick another?" |
| Health Settings hint (`healthkit-reads.md` §4) | Fail: 14 words with a menu path, reads as an instruction | "Tessera sees no sleep or heart data. Health > Profile > Apps > Tessera to check." | "No sleep or heart rate from Health yet. Check in Health?" |
| A7 task ask, A7 "remind me" fallback (new, Oct 15) | Pass: "Want me to buzz you at 9 am?" is 8 words, an offer naming the thing he just did; "On Now then." says what still works | | "Want me to buzz you at 9 am?" · "On Now then." |
| A3 ask, A3 denied, A2, A7, A8 off, A1 fallback, A9 ask, mic off, mic limited, mic back | Pass: under 12 words, plain, offers, no "!" | | |

No line in this file uses "!", an emoji, "should", "must", "sorry", "please" or an em-dash. Every fallback says what still works, not what was refused.

## 6. Open questions (recommended default)

1. **Pulled asks and the cap.** Default: they bypass the cap and use the slot (rule 2).
2. **Health pre-ask line.** The sheet is full screen; a line first matches every other ask. Default: add A1's line on the finish screen and stop asking from background finishes (rule 6).
3. **Health backfill on grant.** Default: save every finished workout since install, by sync id.
4. **Does iOS 27 show a Live Activity choice?** Check once on the phone after a delete and reinstall. Default: count it as the day's ask.
5. **Notification trigger.** ~~Kitchen timer only, or also a rest alert when Live Activities are off? Default: kitchen timer only; rest keeps the ActivityKit alert.~~ Superseded. Changed Oct 15 (notifications.md): the ask fires on the first kitchen timer, "remind me" or timed task; when notifications are allowed the rest notification is the sound and the Live Activity alert is off, otherwise the Live Activity alert stays. Product to confirm (`notifications.md` Q1).
6. **Time Sensitive.** A capability, not a prompt, and unverified on the Personal Team. Default: don't request it.
7. **Proactive folder ask.** Default: one line, once, as A9; Not now means never again as a line.
8. **Speech key with `SpeechAnalyzer`.** Default: add it anyway (`speak-first-use.md` Q5).
9. **Reinstall.** Deleting the app resets iOS permissions and the ledger together, so the week replays. The 7-day re-sign does not reset either. Default: nothing to do.
10. **Who owns the ledger.** Default: Core builds `TessAskLedger` with the hint ledger; Builders A and B only render lines and call `ledger.mayAsk(id)`.
