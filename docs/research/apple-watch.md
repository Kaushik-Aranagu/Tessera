# Apple Watch in Tessera

For: Product lead, iOS Builder (Health mount, rest Live Activity). 2026-10-15. Research lab.

**Bottom line.** No Watch app for now. The Watch already writes everything we want to Health (sleep stages, resting HR, HRV, heart rate) and already mirrors our rest Live Activity into the Smart Stack. Read the first after the fact, and fix the second, which today shows only the compact tick and countdown on the wrist, with no Done or +15. A free Personal Team can most likely install a Watch app, but it costs one more install slot and App ID, a weekly re-sign of both, and a slow Watch deploy loop. Revisit when live heart rate during a set is something Kaushik actually asks for.

## 1. What we get with no Watch app (HealthKit, read after the fact)

Today `App/Health/HealthExporter.swift` only writes: `requestAuthorization(toShare: [workoutType], read: [])`, a `.traditionalStrengthTraining` workout built with `HKWorkoutBuilder(device: .local())`. The entitlement (`App/Tessera.entitlements`) has `com.apple.developer.healthkit` and an empty `healthkit.access`, which is correct for these types (no clinical records). Both usage strings say "saves your finished workouts" and must be reworded when we read.

| What | HK type | How to read | Notes |
|---|---|---|---|
| Sleep with stages | `HKCategoryType(.sleepAnalysis)`, values `asleepCore`, `asleepDeep`, `asleepREM`, `asleepUnspecified`, `awake`, `inBed` | Sample query, 18:00 to 14:00 window, Watch source wins | Already specified in `calendar-health-fixtures.md` H01 to H12 |
| Resting HR | `HKQuantityType(.restingHeartRate)` (count/min) | Latest sample | One a day, Watch only; hide if older than 36 h (slice 2) |
| HRV | `HKQuantityType(.heartRateVariabilitySDNN)` (ms) | Latest sample, or the average of last night's samples | Sparse (a few a day, mostly at night); use as a trend against his own 30-day baseline, never as an absolute |
| Heart rate in a workout | `HKQuantityType(.heartRate)` | `HKStatisticsQuery` with `.discreteAverage` and `.discreteMax`, predicate `predicateForSamples(withStart: workout.start, end: workout.end)` | See density caveat below |
| Workout effort | `HKQuantityType(.workoutEffortScore)` (1 to 10) and `.estimatedWorkoutEffortScore` (iOS 18+) | Write our own from RPE and relate it with `relateWorkoutEffortSample(_:with:activity:)` | Watch estimates effort for some activity types; for strength, **unverified** |
| Also there, later | `appleSleepingWristTemperature`, `respiratoryRate`, `vo2Max` | Latest | Not in M4 |

**Does writing our workout make the Watch's data attach?** No, not automatically. Our `HKWorkout` is a time range plus metadata; Watch heart-rate samples are not linked to it. But we don't need a link: querying `heartRate` over the workout's start and end returns whatever the Watch recorded in that window, from any source. The catch is density. With no workout running on the Watch, it samples HR in the background every few minutes (**unverified** exact rate), so a 60-minute session gives roughly 10 to 20 points: enough for an average and a rough max, not for per-set curves. If Kaushik starts the Watch's own Workout app (Traditional Strength Training), HR is recorded every few seconds and the max is real, but Health then holds two workouts for one session. Fix: when saving, look for an overlapping Apple Watch workout (source productType starts with "Watch") and skip our own save, or keep ours and show the duplicate as one in Tessera. Pick one in the slice.

**iOS 26/27 worth knowing.**
- iOS 26 added a Workout app on iPhone and HealthKit workout sessions on iPhone (`HKWorkoutSession` on iOS, WWDC25). An iPhone session gets heart rate from Bluetooth sensors and AirPods Pro 3, not from the Watch (**unverified** that it never pulls Watch HR). Not a path to wrist HR.
- watchOS 26 Workout Buddy: Apple Intelligence spoken coaching inside Apple's Workout app (strength included, needs an Apple Intelligence iPhone and headphones). It does not see Tessera's sets. It is a reason Kaushik might already start a Watch workout, which makes the overlap rule above matter.
- watchOS 26 Sleep Score: no public HK type found (**unverified**). Compute our own from stages if wanted.
- Health is unreadable while the phone is locked: read on foreground only, as slice 2 says.

## 2. The rest Live Activity on the wrist

- **It shows up with no Watch app.** watchOS 11+ puts every iPhone Live Activity in the Smart Stack automatically ("Live Activities work on Apple Watch even if you don't have a Watch App", WWDC24 10068). Verified.
- **What it shows today.** `Widgets/RestLiveActivity.swift` has no `.supplementalActivityFamilies`, so the Watch uses the default: the compact leading and trailing views, i.e. the vermilion tick and the countdown (or "Go"). That has no buttons. Tapping it opens a full-screen view with "Open on iPhone".
- **Getting Done and +15 on the wrist.** Add `.supplementalActivityFamilies([.small])` and branch on `@Environment(\.activityFamily)`. Without a `.small` branch the Watch gets the 150 pt Lock Screen view, which is too big. A `.small` layout: countdown, planned set as the Done button, one "+15". Buttons in Smart Stack Live Activities are supported (MacStories watchOS 11 review: "add buttons for actions like pausing audio"; Apple suggests one button). Our intents are `LiveActivityIntent`s, which run on the iPhone; that they fire from the wrist with the phone locked in a pocket is **unverified**: test it on device.
- **Go on the wrist.** "Go" comes from `staleDate`, which changes the face silently; nothing taps the wrist. A rest-end buzz needs either a Live Activity update with an `AlertConfiguration` (needs the app awake or a push; push is not available on a free team) or a local notification scheduled at rest end, which the Watch mirrors when the phone is locked. Use the notification, at time-sensitive level, through slice 4's priorities.
- Always On on the Watch forces dark and reduced luminance; the existing `isLuminanceReduced` "Ready at 18:26" branch covers it.

## 3. What only a Watch app can do

- **Live HR during a set:** an `HKWorkoutSession` plus `HKLiveWorkoutBuilder` on the Watch streams HR every few seconds; the app sends it to the phone (WatchConnectivity or the iOS 17+ mirrored session). Needs a watchOS target with HealthKit.
- **Logging from the wrist:** the Digital Crown as the rep drum, a tap to log; works with the phone in the bag. The Live Activity Done button covers the "same as planned" case without this.
- **Complications:** WidgetKit accessory families (`accessoryCircular`, `accessoryRectangular`, `accessoryCorner`) need a watchOS widget extension. Smart Stack Live Activities do not.
- **Double Tap:** `.handGestureShortcut(.primaryAction)` on a button in our own Watch app or Watch widget. Whether it reaches an iPhone Live Activity's button in the Smart Stack: **unverified**, likely no.
- **Wrist haptics on demand** (rest over) without depending on notification mirroring.

## 4. Free Personal Team and a watchOS target

- **Install: yes, most likely.** Xcode signs and installs companion Watch apps on a free team; Apple forum threads show free-team Watch installs working, with one caveat ("Free accounts may experience issues launching apps on the watch for the first time": open it on the Watch and trust the developer). No Apple page states it outright; the capability table on developer.apple.com did not render for us. **Treat as likely, prove with one build.**
- **Expiry:** free profiles last 7 days; the Watch app expires with the phone app and both must be re-run from Xcode weekly.
- **Pairing and deploy:** the Watch must be paired to the iPhone, have Developer Mode on (watchOS 9+), and be reachable through the iPhone on the same network. First deploys are slow (minutes) and flaky; plan on that.
- **Limits:** free teams can have about 3 apps installed per device and register about 10 App IDs per 7 days (**unverified**, widely reported). A forum report shows the Watch app counting as its own install. We already use two App IDs (app, widgets); a Watch app and a Watch widget extension add two more.
- **HealthKit and App Groups:** an Apple DTS answer says personal teams register explicit App IDs "including those with associated capabilities like App Groups and HealthKit", and HealthKit already signs on the phone, so both are probably fine on the Watch target (**unverified** for watchOS). Push notifications are not available, which rules out pushed Live Activity updates on any target.

## 5. Recommendation and the smallest first version

No Watch app this milestone. Everything Kaushik gets from the Watch today flows through Health and the Smart Stack; a Watch app adds a second weekly re-sign, a slow deploy loop and install-slot pressure for one feature (live HR) that nobody has asked for yet.

**Smallest first version** (fits inside M4 slice 2 plus one Live Activity change):
1. Add `heartRate`, `heartRateVariabilitySDNN` and `restingHeartRate` to the slice 2 read set (sleep already there); reword both usage strings.
2. Workout summary shows "avg 118 · max 152 bpm" from the Watch samples in the workout window, hidden when there are fewer than 3 samples.
3. Rest Live Activity gets a `.small` family for the Smart Stack and a local notification at rest end.

| # | Slice | Done when |
|---|---|---|
| W1 | **Workout heart rate** | Finishing a workout with the Watch on shows average and max HR on the summary from `heartRate` samples in its time range; with no Watch or under 3 samples the line is absent, not "0" or "no data". Fixture: 15 samples in a 55-minute window give the expected avg and max |
| W2 | **Rest on the wrist** | On Kaushik's Watch, the rest activity shows countdown, planned set and +15 in the Smart Stack; tapping the set logs it on the phone with the phone locked; rest end taps the wrist once via a local notification. Verified on device, with a photo in the PR |
| W3 | **Recovery line** | Now's morning line reads last night's sleep, resting HR and HRV against his 30-day median ("HRV 12% under usual"); missing pieces drop out silently |
| W4 | **One session, one workout** | If an Apple Watch strength workout overlaps a Tessera workout by more than half, Tessera does not write a second one, and its summary uses the Watch workout's HR and energy |

**Later, only if asked:** a minimal Watch app (one screen: current set, crown to adjust, tap to log, live HR from an `HKWorkoutSession`). Gate it on one throwaway build that proves free-team install, HealthKit on the Watch target and the weekly re-sign are tolerable.

## Sources

- WWDC24 10068, Bring your Live Activity to Apple Watch: https://developer.apple.com/videos/play/wwdc2024/10068
- Apple, Launching your app from a Live Activity (Smart Stack, watchOS launch key): https://developer.apple.com/documentation/activitykit/launching-your-app-from-a-live-activity
- MacStories, watchOS 11 review (buttons in Smart Stack Live Activities): https://www.macstories.net/stories/watchos-11-the-macstories-review/2/
- Apple DTS on personal teams, App Groups and HealthKit: https://developer.apple.com/forums/thread/834802
- Free-team watch install caveat: https://developer.apple.com/forums/thread/93183
- Free-team install limit with Watch apps: https://developer.apple.com/forums/thread/658196
- Free provisioning limits (archived Microsoft guide): https://learn.microsoft.com/previous-versions/xamarin/ios/get-started/installation/device-provisioning/free-provisioning
- Apple capability table (did not render): https://developer.apple.com/help/account/reference/supported-capabilities-ios
