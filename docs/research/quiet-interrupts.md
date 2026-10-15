# Quiet interrupts: what iOS allows for slice 4

For: Core engine, Product lead · 2026-10-15 · Research lab

**Bottom line.** Hold Tessera's own low-priority notifications in the engine (never hand them to iOS while a workout, cook or focus block runs), then post one grouped notification when the process ends. Timers go out as normal. No entitlement, no Focus reading, works on the free Personal Team.

## What iOS gives us

| Thing | What it does | Needs |
|---|---|---|
| `interruptionLevel = .passive` | Goes to the list silently, no light, no sound [1] | Nothing |
| `.active` (default) | Normal banner and sound; held by Focus and Scheduled Summary | Nothing |
| `.timeSensitive` | Breaks through Focus and Summary; user can switch it off per app [2] | Time Sensitive capability (entitlement `com.apple.developer.usernotifications.time-sensitive`, unverified whether Personal Team can sign it) |
| `.critical` | Bypasses mute and Do Not Disturb [3] | Apple-approved entitlement on request. Not for us |
| `relevanceScore` 0 to 1 | Highest one is featured in the Scheduled Summary [4] | Nothing |
| `threadIdentifier` | Groups notifications into one stack | Nothing |
| Pending requests | `pendingNotificationRequests()`, `removePendingNotificationRequests(withIdentifiers:)` remove only our own local ones [5]; adding with the same identifier replaces | Nothing. Limit 64 pending per app (unverified for iOS 27) |
| `SetFocusFilterIntent` | Our intent runs when a Focus the user attached it to turns on or off [6] | Nothing, but the user must add the filter in Settings |
| `INFocusStatusCenter.focusStatus.isFocused` | Only a yes/no "is some Focus on", never which one [7] | Communication Notifications capability plus user permission (unverified on Personal Team) |
| `Activity.update(_:alertConfiguration:)` | Updates a Live Activity; with no alert config it is silent [8] | Nothing paid; `NSSupportsLiveActivities` in Info.plist |

Limits: we can only hold our own local notifications. Other apps, calls and messages are out of reach. Scheduled Summary is a user setting we can't turn on or read.

## Smallest design for slice 4

1. **Priority on every Tessera notification**, three values: `timer` (rest, cook, focus end), `normal`, `low`. Stored on the notification object, not inferred.
2. **Masking process.** When a workout, cook or focus block process starts, the engine marks a mask as active. New `low` and `normal` items go into an in-memory, written-through queue instead of `UNUserNotificationCenter.add`. Already pending ones due inside the block are pulled out with `removePendingNotificationRequests` and queued.
3. **Release at the context switch.** When the process ends (always an in-app tap, so the app is awake), post one notification: `.active`, `threadIdentifier = "tessera.digest"`, body like "3 things waited: …". If the day's one non-timer notification is already used, post nothing and show the queue on Now instead.
4. **Timers are never held.** `.active` by default; `.timeSensitive` only if the capability signs on the free account.
5. **Quiet channel during the block** is the Live Activity: update it silently (`alertConfiguration: nil`) with a small "2 waiting" count.
6. **Foreground:** in `userNotificationCenter(_:willPresent:)` return `[]` for masked items so nothing pops over the workout screen.
7. **Safety net.** On mask start, schedule one fallback digest with a time trigger at the expected end plus 30 min (cap 3 h). Cancel it on normal release. Covers a killed or forgotten session.

Skip for now: Focus filters and `INFocusStatusCenter`. Slice 8's focus block is our own process, so we don't need iOS Focus to know it.

## API list

`UNMutableNotificationContent`, `UNUserNotificationCenter` (`add`, pending get/remove), `UNUserNotificationCenterDelegate.willPresent`, `UNTimeIntervalNotificationTrigger`, `Activity.update`. Later: Focus filter and status.

## Gotchas

- A suspended app runs no code, so release must happen on the in-app "end" tap or via the pre-scheduled fallback. Never rely on a background wake.
- iOS shows a prompt suggesting the user turn off Time Sensitive for apps that overuse it. Use it for timers only.
- Passive and active notifications can land in Scheduled Summary at its fixed time, so "arrive at the next context switch" is not guaranteed if the user has Summary on. Give the digest a high `relevanceScore`.
- Live Activity updates from the app need the app running; a long workout with the app backgrounded may freeze the count. Set a `staleDate`.
- Moving pending requests out and back loses nothing only if the engine stores the full content, not just the identifier.

## Yes/no for Kaushik

None blocking. Optional later: should held items ever skip the one-a-day cap? Default taken: no.

## Sources (developer.apple.com/documentation/…)

1. usernotifications/unnotificationinterruptionlevel/passive
2. …/timesensitive
3. …/critical
4. usernotifications/unnotificationcontent/relevancescore
5. usernotifications/unusernotificationcenter/removependingnotificationrequests(withidentifiers:)
6. appintents/setfocusfilterintent
7. intents/infocusstatuscenter
8. activitykit/activity/update(_:alertconfiguration:)
