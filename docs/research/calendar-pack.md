# Calendar events in the Plan my day pack

For: Core engine (T4 pack, M4 slice 1), Builder B (plan surface). Owner: Research lab.
Date: 2026-10-16. Board item 35. No Swift toolchain; code traced by hand on origin/master `ca30b08`, sizes counted with a small script.
Inputs: `plan-my-day-dryrun.md` (pack style, base sizes), `plan-my-day-prompt.md` §2 (event block shape, "Out, always"), `plan-my-day-scenarios.md` (R2, R3, R8), `calendar-health-fixtures.md` (C01 to C17), `context-packing.md`, `tess-voice.md`, `../product/decisions.md`, `../product/ship-list-m4.md`.

## Bottom line

- **The read:** one `EKEventStore.events(matching:)` call over today's logical day (04:00 to 04:00), all event calendars but Birthdays. Keep `startDate`, `endDate`, `isAllDay`, `title`; drop everything else after filtering.
- **The pack:** timed events become `{"end","fixed":true,"id":"eN","kind":"event","min","start","title"}` blocks, exactly as in the prompt pack; all-day events become titles in `allDay` (3 at most). Titles are cleaned and capped at 40 characters.
- **Size:** across 10 fixture days the largest pack is **384 tokens** (8 back-to-back meetings on top of the dry run's heaviest Friday). A 12-event conference day is 501 raw and comes back to **374** through the merge rule. Nothing ships over 400.
- **No access:** no event blocks, plus `"cal":false` so Tess never calls the day clear. Builder B shows one plain line with a Settings link (decision: never an error).
- **Gaps on master:** no EventKit code, no `Event` class, no `PlanPack`, and **no `NSCalendarsFullAccessUsageDescription`** in `project.yml` (the Health keys are there as `INFOPLIST_KEY_*` build settings). Core adds the key with the read.

## 1. The smallest read

```swift
// Core, TesseraCore. One store, kept for the app's life.
let store = EKEventStore()
let dayStart = RollForward.logicalDay(of: now, calendar: cal)          // today 04:00
let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!          // tomorrow 04:00 (not +86400: Nov 1 is 25 h)
let calendars = store.calendars(for: .event).filter { $0.type != .birthday }
let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: calendars)
let raw = store.events(matching: predicate)                              // one EKEvent per occurrence, overlapping the range
```

- **Range.** Today's logical day only, from `RollForward.dayStartHour` (4). `logicalDay(of:calendar:)` is `static` and internal, so Core can call it inside TesseraCore. A 01:30 event after midnight belongs to yesterday's plan, which matches Day log and the roll.
- **Overlap, not start.** The predicate returns events that overlap the range, so multi-day events and an event that started yesterday come back (C06, C07). Recurrence is already expanded by EventKit; never expand rules ourselves (C01).
- **Fields kept** (the only ones that reach `PackEvent`): `startDate`, `endDate`, `isAllDay`, `title`.
- **Read only to filter, then thrown away:** `status` (cancelled), `availability` (free), `calendar.type` (birthday), and the current user's `participantStatus`. The last needs one walk of `attendees` for the participant with `isCurrentUser`; no name, email or count is kept or sent. Dedupe uses `calendarItemExternalIdentifier` plus `occurrenceDate` (C15).
- **Never read:** `notes`, `location`, `structuredLocation`, `url`, `organizer`, `alarms`, attendee names, the calendar's title or colour.
- **Same source as Now.** When M4 slice 1 lands, the same function reads the `/calendar` mirror instead of EventKit and returns the same `[PackEvent]`; the fixtures below pin the output, not the source. Until then, the one-day read is all Plan my day needs.

## 2. From events to pack lines

Applied in this order. "Window" is the dry run's `[now, 21:00]`.

| # | Rule | Why |
|---|---|---|
| 1 | Drop declined (`participantStatus == .declined`) and cancelled (`status == .canceled`) | R2; "Out, always" lists declined; C03, C16 |
| 2 | Drop timed events with `availability == .free` | Never busy (C11), so the planner may use that time. "Focus time" marked free is fair game |
| 3 | Keep tentative and pending | They count as busy (C04) |
| 4 | Dedupe: same external id and occurrence, or same cleaned title, start and end | Same event in two calendars (C15), a subscribed copy of an iCloud event |
| 5 | Drop timed events that end at or before `now`, or start at or after the window end | R2; nothing can be planned past 21:00 |
| 6 | Keep an event in progress or starting within 15 min with its real start | It is what Now shows (decision R05, `NowRanker.overrideWindow` 15). R8 then starts the first run after it ends. Fixed blocks are exempt from V5 |
| 7 | All-day events, and timed events that cover the whole window, go to `allDay` as titles, at most 3, earliest start first | Never busy (C05); a 3-day timed conference reads as a label on its middle day |
| 8 | Multi-day all-day: listed on every day it overlaps, title only, no "day 2 of 3" | C06; the count would be an unlicensed number for V11 |
| 9 | Zero-minute events stay as blocks with `min` 0 | C13, a marker such as "Visa form due" |
| 10 | Handles `e1..eN` in start order, then the blocks sort with the rest of the pack | `plan-my-day-prompt.md` §2 |

**Title cleaning**, in order:

1. Remove URLs (`http://`, `https://`, `zoom.us/...` tokens). Meeting links are often pasted into titles.
2. Remove emoji: scalars with `isEmojiPresentation`, pictographs, ZWJ (U+200D), variation selector 16, skin-tone modifiers. Keep digits, `#` and `*` (they also count as `isEmoji`).
3. Collapse whitespace and newlines to one space; trim spaces and stray leading or trailing `:`, `-`, `|`.
4. Cap at 40 characters, cut back to the last space, no ellipsis (one fewer token, and Tess quotes the cut title cleanly).
5. Empty after cleaning: `"Untitled event"` (the C10 view string; the stored title stays null).

**Pack line format** (sorted keys, one line, as the dry run sends it):

```json
{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"}
```

`min` is `end - start` in minutes after clipping to the logical day. Each block costs about 95 to 120 chars (24 to 30 tokens). `allDay` is `["Title", ...]`.

**Over budget.** The builder measures the finished pack. Events are fixed, so the planner must see every busy minute; nothing is dropped. Instead, while the pack is over 1,600 chars (400 tokens):

1. Merge events that touch or overlap into one block: earliest start, latest end, `min` the span, title `"<first title> +N"`.
2. Cut every event title to 20 characters.
3. Merge events with gaps of 15 min or less (no task fits there anyway).
4. Still over: log it and send without `allDay`. No fixture reaches this step.

Merging keeps busy time identical (the union of intervals, as C14 does for day load), so the rules plan does not change.

## 3. Permission

**Key.** iOS 17 split calendar access into full and write-only. Reading needs full access: `try await store.requestFullAccessToEvents()`, status from `EKEventStore.authorizationStatus(for: .event)`. Write-only access cannot read, so it counts as no access. EventKit needs no entitlement, so free Personal Team signing is fine; only the usage string is required. Without `NSCalendarsFullAccessUsageDescription` the request does not show the prompt (UNVERIFIED whether it fails quietly or traps on iOS 27; check on the device once).

Add to `project.yml`, beside the Health keys (Core, in the read PR):

```yaml
INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription: Tessera reads the times and titles of your events to plan your day around them. It never changes your calendar.
```

**The ask, in Tess voice** (a line on the plan surface before the system prompt, with two text words, no buttons):

> Plan around your calendar? Times and titles only.
> **Connect** · Not now

- **When:** the first time he opens Plan my day and the status is `.notDetermined`. Never at launch, never in onboarding. If slice 1's mount asks first somewhere else, this line never appears.
- **Connect** calls `requestFullAccessToEvents()`; the system alert shows the usage string. The plan builds after the answer.
- **Not now:** the plan builds without events (`"cal":false`) and the ask line comes back once, 7 days later, then never; after that only the no-access line below.

## 4. No access

| Status | Pack | Line on the plan (UI string, not Tess output) |
|---|---|---|
| `.fullAccess`, no events today | `allDay: []`, no `e` blocks, no `cal` key | none (silence is fine) |
| `.notDetermined` | `"cal":false` | the ask line above |
| `.denied` | `"cal":false` | "Planned without your calendar. **Settings**" (opens `UIApplication.openSettingsURLString`) |
| `.writeOnly` | `"cal":false` | same as denied; Settings can raise it to Full Access |
| `.restricted` | `"cal":false` | "Planned without your calendar." (no link: he can't change it) |

`"cal":false` costs 3 tokens and needs one line in the prompt's instructions: "cal false means the calendar is unknown. Never call the day clear, open or free." Without it, a quiet pack on a no-access day reads as an empty day, and a note like "Nothing until 17:00" would be a lie. The key is absent whenever access is granted, so it costs nothing on normal days.

## 5. Token estimate

Same method as the dry run: UTF-8 characters of the one-line sorted-keys JSON, divided by 4, rounded. Base is the dry run's heaviest master-shaped pack (Fri 23 Oct, 3 run tasks, 2 timed tasks, the workout, 719 chars, 180 tokens), held constant so each row shows the calendar's cost on the worst ordinary day. Total = 719 + event blocks (each plus its comma) + `allDay` titles (+ 12 chars for `,"cal":false`). The "at 3 chars" column is the tighter tokenizer check the dry run used; the on-device route still has 2,000 tokens of input room (instructions 473, schema about 300).

## 6. Ten fixture days

Zone `America/Los_Angeles` unless noted. Each "out" lists the exact event blocks; the rest of the pack is the base.

**F1 Mon 19 Oct, plain workday, now 08:00.** In: Standup 09:30 to 09:45 (recurring, accepted); Design review 11:00 to 12:00; 1:1 Priya 15:00 to 15:30 with 3 attendees, notes "agenda doc", location "Room 4", a Meet URL. Out (attendees, notes, location, URL gone):
```json
{"end":"09:45","fixed":true,"id":"e1","kind":"event","min":15,"start":"09:30","title":"Standup"}
{"end":"12:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"11:00","title":"Design review"}
{"end":"15:30","fixed":true,"id":"e3","kind":"event","min":30,"start":"15:00","title":"1:1 Priya"}
```

**F2 Tue 20 Oct, messy titles, now 07:30.** In: "🚀 Sprint planning 🚀 " 09:00 to 10:00; "  Weekly sync w/ Design + Eng + PM leadership team (please read doc beforehand) " 11:00 to 11:30; "🎉" 13:00 to 13:30; "Vendor call https://zoom.us/j/123456" 14:00 to 14:45. Out:
```json
{"end":"10:00","fixed":true,"id":"e1","kind":"event","min":60,"start":"09:00","title":"Sprint planning"}
{"end":"11:30","fixed":true,"id":"e2","kind":"event","min":30,"start":"11:00","title":"Weekly sync w/ Design + Eng + PM"}
{"end":"13:30","fixed":true,"id":"e3","kind":"event","min":30,"start":"13:00","title":"Untitled event"}
{"end":"14:45","fixed":true,"id":"e4","kind":"event","min":45,"start":"14:00","title":"Vendor call"}
```

**F3 Wed 21 Oct, replies, now 08:00.** In: Dentist 08:30 to 09:00 cancelled; Focus time 09:00 to 11:00 `availability` free; "Lunch w/ Sam?" 12:00 to 13:00 tentative; QBR 13:00 to 14:00 declined; Client call 15:00 to 16:00 pending. Out (Dentist, Focus time and QBR dropped):
```json
{"end":"13:00","fixed":true,"id":"e1","kind":"event","min":60,"start":"12:00","title":"Lunch w/ Sam?"}
{"end":"16:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"15:00","title":"Client call"}
```

**F4 Sat 31 Oct, all-day and markers, now 09:00.** In: "Rhea's visit" all-day; "Halloween" all-day from the subscribed US Holidays calendar; "Anya's Birthday" from Birthdays; "Visa form due" 17:00 to 17:00; Dinner with Rhea 19:00 to 20:30. Out (birthday never read, C12):
```json
"allDay":["Rhea's visit","Halloween"]
{"end":"17:00","fixed":true,"id":"e1","kind":"event","min":0,"start":"17:00","title":"Visa form due"}
{"end":"20:30","fixed":true,"id":"e2","kind":"event","min":90,"start":"19:00","title":"Dinner with Rhea"}
```

**F5 Tue 27 Oct, travelling, device zone `America/New_York`, now 08:00.** In: "NYC trip" all-day Oct 26 to 28; "Swift Summit" timed Mon 09:00 to Wed 17:00; "Flight SFO-JFK" Mon 22:30 PT to 06:45 ET today (ended); Client meeting 10:00 to 11:00 ET. Out (times in the device zone, C08; the summit covers the window, so it is a label):
```json
"allDay":["NYC trip","Swift Summit"]
{"end":"11:00","fixed":true,"id":"e1","kind":"event","min":60,"start":"10:00","title":"Client meeting"}
```

**F6 Thu 29 Oct, duplicates and an edited occurrence, now 08:00.** In: Standup moved to 11:00 to 11:15 (detached, EventKit returns only the moved copy, C02); Offsite planning 14:00 to 15:00 in "Team (shared)" and in Work (same id, C15); Gym 18:00 to 19:00 in iCloud and again in a subscribed Google copy (different ids). Out:
```json
{"end":"11:15","fixed":true,"id":"e1","kind":"event","min":15,"start":"11:00","title":"Standup (moved)"}
{"end":"15:00","fixed":true,"id":"e2","kind":"event","min":60,"start":"14:00","title":"Offsite planning"}
{"end":"19:00","fixed":true,"id":"e3","kind":"event","min":60,"start":"18:00","title":"Gym"}
```

**F7 Fri 30 Oct, late open, now 10:50.** In: Standup 09:30 to 09:45 (ended); Design review 10:30 to 11:30 (in progress); Vendor call 11:00 to 11:30 (within 15 min, overlaps); Gym class 18:00 to 19:00; Call with Tokyo 21:30 to 22:00 (after the window). Out (the first task run starts at 11:30; Now shows the same meeting):
```json
{"end":"11:30","fixed":true,"id":"e1","kind":"event","min":60,"start":"10:30","title":"Design review"}
{"end":"11:30","fixed":true,"id":"e2","kind":"event","min":30,"start":"11:00","title":"Vendor call"}
{"end":"19:00","fixed":true,"id":"e3","kind":"event","min":60,"start":"18:00","title":"Gym class"}
```

**F8 Mon 2 Nov, back to back (the prompt pack's d-heavy day), now 08:00.** First day after DST ends; the read uses calendar days, so the 04:00 bounds hold. In and out are the same 8 events: Prep call 08:30 to 09:00, Board prep 09:00 to 10:30, Roadmap workshop 10:30 to 12:00, Lunch 1:1 Dev 12:30 to 13:00, Customer workshop 13:00 to 15:30, Sync with Lee 15:30 to 16:00, Exec review 16:00 to 17:30, Wrap-up 17:30 to 18:00. Under budget without merging, so each stays its own block (`e1` to `e8`, same shape as F1).

**F9 Tue 3 Nov, conference, now 07:30.** In: "Conference" all-day plus 12 sessions: Breakfast panel 08:00 to 08:45, Keynote 09:00 to 10:00, Talk: SwiftData at scale 10:00 to 10:45, Talk: Liquid Glass deep dive 11:00 to 11:45, Lunch with Nikhil 12:00 to 13:00, Talk: App Intents 13:00 to 13:45, Lab: Foundation Models 14:00 to 15:00, Talk: Widgets 15:00 to 15:45, Hallway sync 16:00 to 16:30, Closing keynote 16:30 to 17:30, Speaker dinner 18:00 to 20:00, Drinks 20:00 to 21:00. Raw pack 2,005 chars (501 tokens), so merge step 1 runs. Out:
```json
"allDay":["Conference"]
{"end":"08:45","fixed":true,"id":"e1","kind":"event","min":45,"start":"08:00","title":"Breakfast panel"}
{"end":"10:45","fixed":true,"id":"e2","kind":"event","min":105,"start":"09:00","title":"Keynote +1"}
{"end":"11:45","fixed":true,"id":"e3","kind":"event","min":45,"start":"11:00","title":"Talk: Liquid Glass deep dive"}
{"end":"13:45","fixed":true,"id":"e4","kind":"event","min":105,"start":"12:00","title":"Lunch with Nikhil +1"}
{"end":"15:45","fixed":true,"id":"e5","kind":"event","min":105,"start":"14:00","title":"Lab: Foundation Models +1"}
{"end":"17:30","fixed":true,"id":"e6","kind":"event","min":90,"start":"16:00","title":"Hallway sync +1"}
{"end":"21:00","fixed":true,"id":"e7","kind":"event","min":180,"start":"18:00","title":"Speaker dinner +1"}
```
V11 note: "+1" puts a 1 in the title, which licenses that number only. Events are header-line material, not ghost lines (decision), so Tess rarely quotes them.

**F10 Wed 4 Nov, access denied, now 08:00.** In: the calendar holds Standup and Design review, but `authorizationStatus` is `.denied`, so nothing is read. Out: no `e` blocks, `allDay: []`, and `,"cal":false` at the top level. Plan line: "Planned without your calendar. Settings".

| Day | Case | Events in | Blocks / all-day out | Calendar chars (tokens) | Pack chars | **Pack tokens** | At 3 chars | Under 400 |
|---|---|---|---|---|---|---|---|---|
| F1 | Plain workday | 3 | 3 / 0 | 299 (75) | 1,018 | **254** | 339 | yes |
| F2 | Messy titles | 4 | 4 / 0 | 432 (108) | 1,151 | **288** | 384 | yes |
| F3 | Declined, cancelled, free, tentative | 5 | 2 / 0 | 204 (51) | 923 | **231** | 308 | yes |
| F4 | All-day, birthday, marker | 5 | 2 / 2 | 234 (58) | 953 | **238** | 318 | yes |
| F5 | Multi-day, travel zone | 4 | 1 / 2 | 129 (32) | 848 | **212** | 283 | yes |
| F6 | Duplicates, edited occurrence | 5 | 3 / 0 | 304 (76) | 1,023 | **256** | 341 | yes |
| F7 | In progress, within 15, after window | 5 | 3 / 0 | 303 (76) | 1,022 | **256** | 341 | yes |
| F8 | 8 back to back | 8 | 8 / 0 | 817 (204) | 1,536 | **384** | 512 | yes |
| F9 | 12 sessions, merged | 13 | 7 / 1 | 776 (194); raw 1,286 | 1,495; raw 2,005 | **374**; raw 501 | 498 | yes, after merge |
| F10 | Denied | 2 (unread) | 0 / 0 | 12 (3) | 731 | **183** | 244 | yes |

At 3 chars a token F8 and F9 pass 400 (512, 498). That is the same caveat the dry run had for its 283-token day: the chars/4 count is the contract, and both routes still sit far under 2,000 input tokens. If evals show the real tokenizer is nearer 3, change the trigger to 1,200 chars and F8 merges like F9.

## 7. Owners

| Piece | Owner | Notes |
|---|---|---|
| `TodayEvents.read(store:now:)` returning `[PackEvent]` (start, end, allDay, title), filters, dedupe, title cleaning | Core | TesseraCore; EventKit has no UI, so it fits the engine. Fixtures F1 to F10 as Swift Testing cases on `PackEvent` input (no live store) |
| Event blocks, `allDay`, `cal`, the merge rule, the 1,600-char check in `PlanPack` | Core | T4 |
| `INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription` in `project.yml` | Core | Same PR as the read; run `xcodegen generate` |
| One prompt line for `"cal":false` | Core (T6 prompt) | Plus one eval case: no-access day, Tess never says "clear" |
| Ask line, Connect / Not now words, the 7-day re-ask flag, no-access lines with the Settings link | Builder B | Plan my day lives on Home/Now. Words follow `no-buttons.md`; copy check by Design |
| Now override for events within 15 min | Core | `NowRanker` covers timed tasks only today; events join when the `Event` class lands (context-packing stage 3) |

## 8. Open questions (with recommended defaults)

1. **Read EventKit directly or wait for the slice 1 mirror?** Default: ship the one-day read behind `TodayEvents`; swap the source to `/calendar` when slice 1 lands. Same fixtures.
2. **Which calendars count?** Default: all event calendars except Birthdays. Other people's busy-only shared calendars (C11) are excluded later by slice 1's ownership rule; a calendar picker is not worth it for one user.
3. **Birthdays in `allDay`?** The dry run's Friday variant packed "Ana's birthday"; C12 says birthdays never reach Plan my day. Default: follow C12 (the People area owns birthdays).
4. **Free-availability events:** dropped by default. If he marks real commitments as free, revisit with one eval.
5. **Title cap:** 40 characters. Raise only if evals show Tess misnaming cut titles.
6. **`"cal":false` vs sending nothing:** default `cal:false`, 3 tokens, prevents "your day is clear" on a no-access day.
7. **Re-ask after Not now:** default once, 7 days later. Then only the plain line.
8. **Merge trigger:** 1,600 chars (chars/4). Move to 1,200 if the measured tokenizer runs near 3 chars a token.
