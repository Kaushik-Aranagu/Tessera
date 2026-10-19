# Tess reads the screen: motion sheet (Huddle plan batch 9, draft)

Motion lab draft. Docs only. Every value carries its `file:line`; anything the lab chose is marked (lab default).
Paths are under `docs/`. Short keys: MOT = `design/motion/tess-motion.md`, PICK = `design/motion/tess-picks.md`,
AWARE = `design/motion/tess-aware-motion-notes.md`, MAT = `design/motion/tess-lowpower-reducemotion-matrix.md`,
ARCH = `ai/architecture.md`, CC = `ai/claude-client.md`.

## What it is
- His ask: her motion should "depend on what is on the screen and how he is interacting", and a fast model call
  could "pick her next motion (roam, where the lights go, what she looks at)" (AWARE:7, AWARE:9). No screenshots or
  images, ever (AWARE:11, `ai/private-surfaces-images-failure-lines.md:26`).
- The model only picks among states and places she already has, never invents motion, so every rule in MOT still
  holds (AWARE:14). The input is structured text, not pixels (AWARE:15).
- Switch: "Tess reads the screen", default off, a row in the Review section, group "Tess asks Claude", beside Tess
  experts (Product, Oct 19, mirror only; `ai/parked.md:18` puts the idea under that switch). Effective value = "Tess asks Claude" is effectively on (key saved and stored value on,
  `ai/settings-claude-page-spec.md:13`) AND this row is on (lab default). Off: nothing is sent and she is as built.
- Job `screenRead` (lab default name): Haiku 5.5, the house's fast model (ARCH:152), one strict tool `proposeMotion`
  whose only field is a menu id. An id not in the menu the phone sent is rejected and the as-built choice stands,
  the same rule as `proposeSoul` (ARCH:207).
- Cost: about 350 in / 8 out tokens (lab default) at Haiku's $0.10 / $0.50 per million (ARCH:137) is about $0.00004 a
  call; capped at 150 calls a day (lab default), worst month about $0.18 inside the $50 hard cap
  (`ai/job-trigger-table.md:4`). It only beautifies, so it steps aside at $40 like living colour
  (`ai/job-trigger-table.md:5`, `:19`) (lab default). Receipt word "Screen read" (lab default, pattern of
  `ai/settings-claude-page-spec.md:20`).
- Walls and keys unchanged: switch and demo gate first (CC:61), SecretWords and key-prefix wall (CC:73), then the
  reserve (CC:76). "Nothing ever waits on Claude" (ARCH:8) is the motion rule below.

## 1. Per screen state: what she does differently
"Event" is the existing section 14 event that opens a call (MOT:256-285). No event, no call: a minute at rest has zero
glances, roams and lines (MOT:208), and reading the screen never adds a moment that would not fire as built.

| Screen state | Event that may call | As built (plays at once) | What the answer may change (next moment only) |
|---|---|---|---|
| Home, rows on screen, she starts work | `askClaude(touched:)` | readers on touched words in job order, else section 5 sweep (PICK:38-39) | readers order: job order or sweep; or constellation only, no readers (MOT:92) |
| Home, a row changed not by his hand | `rowChanged(rect)` | roam to that row's free ground (MOT:49) | roam there, or stay home with the line naming the row (MOT:228) |
| Many rows changed in one op | `rowChanged` x n | first row the router gets (MOT:295 retargets) | which declared slot she roams to, by slot index only |
| Scrolled to the last row | `reachedEnd` | the 5 pt peek (PICK:196) | peek, or nothing (calm, PICK:19) |
| Timed item 10 min out, row on screen | `upcoming` | lean 4 pt plus eyes (PICK:171) | lean plus eyes, or eyes only (the RM form, PICK:176) |
| Side turned | `sideTurned` | eyes 0.4 toward the content (PICK:245) | that glance, or none |
| Just cleared, few rows left | as the row's own event | as built | the same menu as that event; the empty count is a fact, not a trigger |
| Training at rest, Review, Routines | as above | page table (MOT:365-369) | only what that page allows; Training and Review have no readers (MOT:365, :368) |
| Settings, What I know | none | never roams (MOT:370-371) | nothing; no call |
| Page with no declared free ground | none for roam | constellation at the dock (MOT:377) | nothing; no call |
| Live workout, cook mode, Speak, a flight | none | live things own their surface (MOT:378); no network while lifting (ARCH:44) | nothing; no call |
| Listening, an ask waiting, carried, Done in flight | none | precedence rows 1 to 4 hold (MOT:288-291) | nothing; an answer arriving now is dropped |
| Quiet hours, asleep | none | sleep as built (PICK:135) | nothing; no call (lab default) |

## 2. Per touch: what his touch tells her
Touch facts are buckets, never points (lab default): last touch kind, tempo (still / steady / quick), and seconds
since the last touch (0-2, 2-10, 10+). Quick = 3 or more touches, or a fling over 1,500 pt/s, in 2 s (lab default).

| His touch | As built (never changed) | Sent as a fact | Effect on the menu |
|---|---|---|---|
| Tap, double tap, hold on her | open, Home, talk (MOT:64) | no call | none; his touch on her is rule 1 and drops any answer in flight (MOT:288) |
| Drag her | carry and dock (MOT:66-72) | no call | none; an answer in flight is dropped |
| Stroke across her | ripple and the one tick (PICK:64-66) | kind "stroke" | none; the tick is his touch, not the model's |
| Scroll | roam rides, releases at y 130 / 700 (MOT:58) | kind "scroll", tempo | quick tempo: the phone removes roam and peek from the menu (lab default) |
| Lift, move, drop a row | eyes follow the row (PICK:148) | kind "row" | none while held; the next moment may pick the drop glance or none |
| Typing in capture | one pulse per word, 180 ms floor (PICK:184-186) | kind "type", never the words | none; no call while listening (MOT:289) |
| Glass tab hold | she stays put (MOT:304) | no call | none |
| No touch for 10 s+ | at rest | "still" | none; rest makes no call (MOT:208) |

## 3. Latency: she never waits
1. At the event (t = 0) the router plays the as-built choice on the first frame. No frame waits on a call
   (ARCH:8) (lab default: test pins "first frame unchanged").
2. A call opens at t = 0 only if no `screenRead` call is in flight: one in flight at most (lab default). Events
   during the flight open no call and play as built.
3. Answer by t + 300 ms: it may steer the next beat of the moment already running (AWARE:16), for example which
   reader order the lights take when the 900 ms split ends (MOT:84).
4. Answer at 300 to 1,200 ms (lab default cutoff): it may only change the NEXT moment of the same kind, and only if
   the snapshot hash (page, state, slot list) still matches; else dropped.
5. Answer after 1,200 ms, or after the state or page changed: dropped, the rule decides (AWARE:16). The request is
   cancelled at 1,500 ms (lab default); a late reply is dropped with outcome "late" (CC:103-104).
6. Minimum gap 2 s between calls and 150 a day (lab default). Nothing retries and nothing queues: a motion chosen
   later describes a moment that is gone (ARCH:132).
7. Offline, refused (switch, demo, no key, wall, cap, $40 step-aside), timeout or a bad id: as built, no line, no
   receipt line on screen (silent like Home lines, `ai/private-surfaces-images-failure-lines.md:52`). A row is
   written only when a request really left (`ai/offline-inbox-drain-and-eight-second-cap.md:36-39`).
8. The answer is a router event (`screenReadAnswered(id, requestId)`, lab default); the router stays the only timer
   (MOT:299) and the answer sits at precedence 8 or lower, so it can never cut a mode above it (MOT:287-297).

## 4. Normal / Reduce Motion / Low Power
House rule: LP = RM = one 150 ms crossfade (MAT:3), except the soul's own LP form (MAT:62). Calls stop in Low Power:
automatic Claude calls skip in LP, asked calls run (MAT:13, MAT:65); `screenRead` is automatic.

| | Normal | Reduce Motion | Low Power |
|---|---|---|---|
| Calls | on events in section 1 | none: nothing travels and there is no glance to steer (MOT:227-228, MOT:339) (lab default) | none (MAT:13, MAT:65) |
| Roam choice | roam or stay home | stays home, line names the row (MOT:228) | no roam (MOT:243) |
| Readers choice | job order, sweep or none | no readers (PICK:43) | no readers, six lights, noise frozen (PICK:44, MOT:230) |
| Peek / nudge / side glance | chosen from the menu | peek none (PICK:200); nudge eyes only (PICK:176); no side glance (PICK:247) | = RM (PICK:177) |
| A choice landing | on the beat's own curve | 150 ms crossfade (MAT:3) | 150 ms crossfade (MAT:3) |
| Switch flips mid-state | applied at the next mode change, never mid-animation (MOT:247) | same | same |

## 5. What she may choose (closed menu)
The phone sends, per event, the subset that is legal right now (eyes setting, page, RM, LP, precedence applied
first). The model returns one id. No coordinates, no rects, no text, no durations (lab default).

| Id (lab default) | Existing motion | Source |
|---|---|---|
| `asBuilt` | whatever the rule picks; always in the menu | MOT:256-285 |
| `readersJobOrder` | readers hop to touched words, 340 ms hop, 380 ms dwell | PICK:38 |
| `readersSweep` | section 5 sweep under the rows | PICK:39, MOT:85 |
| `constellationOnly` | lights at the dock, no readers | MOT:92, MOT:377 |
| `roamSlot1` to `roamSlot4` | `SoulTravel` 760 ms to a declared slot | MOT:49, MOT:377 |
| `stayHome` | no roam, the line names the row | MOT:228 |
| `peek` / `none` | idea 9 rise, or nothing | PICK:196, PICK:19 |
| `nudgeLean` / `nudgeEyes` | idea 7 lean plus eyes, or eyes only | PICK:171, PICK:176 |
| `sideGlance` / `none` | sheet 75 glance, or nothing | PICK:245 |
| `dropGlance` / `none` | idea 6's drop blink and look back, or nothing | PICK:148 |

- Eyes off removes every eyes-only id (PICK:11). Slots are the page's declared free ground, 56 x 44 pt or more
  (MOT:17); the model never sees their positions. Done never changes and is not on the menu (MOT:23).

## 6. Never diffused, no haptic
- Never a diffused or faded Tess (`design/motion/tess-never-diffused-audit.md:3`). In Reduce Motion her group
  opacity stays 1, grade and halo as at rest (MOT:222, audit:24). Asleep, pigment equals Idle's (audit:25). No
  menu id touches opacity, grade, halo or saturation (lab default).
- No haptic from the soul (`design/motion/tess-picks-build-sheets.md:10`, MOT:334, MAT:52). A choice adds none; idea
  3's tick stays his touch's (PICK:66).

## 7. Privacy: what may leave the phone
- May be sent: page kind, the event kind, her mode, counts of rows on screen by kind (task, workout, cook, shop,
  habit), number of declared slots, which slot indices hold changed rows, touch buckets (section 2), part of day,
  light or dark look, eyes setting (lab default).
- Never sent: any title, list text or note (stricter than "titles and counts", ARCH:171), the `touched` list itself
  (`ai/soul-signals.md:37`), rects, coordinates, pixels, images (`ai/private-surfaces-images-failure-lines.md:26`).
  A private-labelled row counts like any other and changes nothing visible (`design/motion/tess-ideas-13-15.md:22-24`).
- Any text field a later revision adds goes through the one `isPrivateText` function and is sent as its kind word
  (`ai/private-surfaces-images-failure-lines.md:7`). The SecretWords and key-prefix refusal runs first, before the
  reserve (CC:73-76); a refused pack sends nothing and she plays as built.
- VoiceOver: no announcement, no focus move, no custom action; her line stays the announcement
  (`design/motion/tess-picks-build-sheets.md:25` pattern) (lab default). The switch row reads "Tess reads the
  screen, off" with the hint "Sends counts, never words or pictures" (lab default). VoiceOver state is not sent.

## 8. Build checks (TesseraTests, lab default names)
- `firstFrameNeverWaitsOnScreenRead`, `answerWithin300msSteersNextBeat`, `answerAfter1200msIsDropped`,
  `answerAfterStateChangeIsDropped`, `onlyOneScreenReadInFlight`, `requestCancelledAt1500msWithOutcomeLate`.
- `lowPowerSendsNoScreenRead`, `reduceMotionSendsNoScreenRead`, `noCallInLiveQuietHoursOrSettings`,
  `offlineOrRefusedPlaysAsBuiltWithNoLine`, `switchOffStateSequenceEqualsAsBuilt`, `stepsAsideAtFortyDollars`.
- `unknownMenuIdIsRejected`, `idOutsideEventMenuIsRejected`, `eyesOffMenuHasNoEyesOnlyIds`, `quickTempoDropsRoamAndPeek`.
- `packHoldsCountsAndKindsOnly`, `privateTitleNeverInPack`, `secretWordPackRefusedBeforeReserve`,
  `noClaudeRequestHoldsAnImageBlock` extended to `screenRead`
  (`ai/private-surfaces-images-failure-lines.md:41`), `sameStateWithEveryRowPrivateOrNone`.
- `screenReadNeverPlaysAHaptic`, `soulOpacityStaysOneInReduceMotionAndSleep`, `voiceOverHearsNoChoice`.
- Grep gate unchanged: no `tessMode =` outside `SoulRouter` (`design/motion/tess-motion-build.md:46`).

## Asks (contradictions only)
1. Docs say no model call moves her: "Claude is never asked how she should move" (`ai/soul-signals.md:6`), "with
   Tess asks Claude off she reacts exactly the same" (`ai/soul-signals.md:43`), "Nothing here adds a model call"
   (PICK:7), and nothing gets calls or spend until he says (`ai/parked.md:3`). Product ruled yes on Oct 19 (mirror only) and asked for a dated "Amended" note under each of those lines; Product: confirm batch 9 is his go
   and amend those lines (the switch-off half still holds).
2. Answered by Product (Oct 19, mirror only): the row lives in the Review section, group "Tess asks Claude", beside Tess experts, default Off; the Claude section stays as is. (The Claude section was at its 6-row limit, `ai/settings-claude-page-spec.md:7`; that is why the row goes to Review.)
3. Sleep: PICK:135 drops saturation 0.35; the never-diffused audit keeps Idle's pigment (audit:25). And
   `ops/board/ios-a.md:19` asks Reduce Motion working at opacity 90%, against full opacity (MOT:222, audit:24). This
   sheet follows the audit and G225; Design to confirm.
4. Cap line: every job shows "Claude paused until <date>." at $50 (`ai/job-trigger-table.md:36`), but background
   jobs show nothing (`ai/private-surfaces-images-failure-lines.md:52`). This sheet keeps `screenRead` silent.
