# Low Power and Reduce Motion matrix, every screen and surface (board 79)

One page for Builder A's Low Power flag PR: what each screen does in Normal, Reduce Motion (RM) and Low Power (LP), who owns the code, and where the code does not match yet. Built from the lab specs listed under "Spec keys", not from new rulings. Checked at master `bc35f8b` for code cites (the stagger comment is at `Editorial.swift:57`). Rulings in force: LP = RM = one 150 ms crossfade, no stagger, blur or travel (G317/G318, DEC:1039(6)); the soul keeps her own LP form; RM keeps Tess at full opacity (G225); his own touches' haptics play in LP and in quiet hours; widgets and Live Activities are system-owned motion; Low Power is read in one place, `App/PowerState.swift`.

## Builder A's checklist for the flag PR
Tick in this order; each line names the cite in (b) below.
1. Add `App/PowerState.swift` (it does not exist yet): one cached `isReduced`, refreshed on `NSProcessInfoPowerStateDidChange`, the only reader of Low Power (premerge allowlist entry).
2. `MotionPolicy.resolve` takes LP as well as Reduce Motion (`DesignSystem/MotionPolicy.swift:8-10`), so every `withTesseraAnimation` / `.tesseraAnimation` becomes the 150 ms crossfade in LP.
3. `TessSoul.swift:109` reads `PowerState`, not `ProcessInfo`; delete the raw `.sensoryFeedback(.success)` at `:143`. The soul keeps her own LP form (30 fps, six lights, no readers, halo held, no roam, no repaint).
4. Pause or gate the continuous timelines that read nothing or RM only: `Machined.swift:189`, `ThemeLayers.swift:128`, `ThinkingIndicator.swift:20`, `Workout/ExerciseStrip.swift:40`, `LiveSetStrokes.swift:119`, `SwapPanel.swift:137`, and the ungated repeat-forever wash at `Paint.swift:123`.
5. Move the raw animations onto the policy: `Paint.swift:296,303,421`, `Editorial.swift:77`, `BottomChrome.swift` (list in (b)), `SpeakLayer.swift:49,53`, `CaptureParts.swift:74,78,96`, `WeightReel.swift:88`.
6. Ghost wait: add the VoiceOver 10 s branch at `BottomChrome.swift:653`; LP keeps the full 3 s as four ~0.75 s steps.
7. Automatic Claude calls (plan wording, Monday week story, `readWaiting`) read `PowerState` and skip in LP; his asked calls run.
8. Settings does not ship before this PR (Product gate, recorded on `ios-a.md`).
9. Test: with LP on, no screen below slides, springs, staggers or blurs; every moment is the 150 ms crossfade; haptics for his own touches still play.


**Spec keys** (all `tess-*.md` in that folder): IDX ruling-index; HMT haptics-migration-table; DAY day-screens-motion-pass; TRN training-motion-lowpower-pass; GRO groceries-lists-and-home-settings-lowpower; SPD speak-plan-daylog-copylist-lowpower-pass; MRA money-reading-motion-amended; CCK cook-clock-lowpower-and-timer-end; LAW live-activity-lockscreen-widget-motion; SET settings-motion; BHR backups-health-review-motion; PGT page-turn-motion; PAN pantry-lean-notice-motion; HAB habits-shutdown-quiet-private-pass; LRB look-settings-rotate-budget-check; QV quiet-versions; MOT motion (soul, section 13); SID sides-motion; TTP title-progress; AWN aware-motion-notes. Cites are file:line unless marked "s." (section).

"LP" column says "= RM" unless LP differs from the 150 ms crossfade. Owners: A / B / Core / Design.

## Matrix

| Surface | Normal | Reduce Motion | Low Power | Haptics in LP | Owner | Cite |
|---|---|---|---|---|---|---|
| Home: Now hero, queue, day strip | spring/blur lifts; queue finish strike 420 ms + dry 900 ms; row bloom 500 ms | ink strike 150 ms, no wet phase; no bloom | = RM; breathing words paused at mean; day-stroke end still (blur 0.4, op 1); sky ground one frame/hour; seam/clocks 30 s ticks unchanged | his touches yes (`.done` finish, `.selection`) | B (flag A) | GRO:51-62 |
| Home: Claude calls (plan wording, week story) | auto call runs | n/a (state) | automatic call does NOT run; retried next open at power OK; his asked call runs | none | B/Core | DAY:34, BHR:57, IDX M8 |
| Now/Plan my day | keep: 700 ms dry sweep; hold 0.7 s w/ bead, hero lift 24 pt; reply slide 520 ms; rows breathe 0.5-0.66 shared timeline | 150 ms fades; fill no bead; rows still 0.6; no wisps, soul full opacity | = RM; wording not run | `.made` keep/hold once; `.notNow` skip; `.selection` arm; `.undo` | B (soul/haptics A) | DAY:23-41, SPD:42-53 |
| Training / workout (strip, reel, corner) | reel spring, glint 4.5 s, guide breath 2.4 s, corner breath 3.2 s | no pop/droplets/band; glint+breath static 0.9; corner one 150 ms settle | = RM and timelines PAUSED (glint, guide, corner breath, PR glint stop) | `.selection` detents, `.setLogged`, `.newBest`, `.repsBeatLast`, `.undo` | A | TRN:28-40 |
| Set logged / new best / finish | stroke 700 ms; countdown 320 ms; best sweep 900 ms (unbuilt) | whole stroke 150 ms; static cadmium 2 s | = RM; soul LP form | `.setLogged` or `.newBest` (never both); finish `.done`; soul none | A | TRN:47-72, 101-109 |
| Rest end / rest timer | glint 900 ms on flip; Go rises | no glint; Go fades 150 ms; horizon steps 1/s | = RM; tick aligned to `restEndsAt` | `.timeUp` (only if seen live <=2 s; two within 600 ms = one); plays in quiet hours | A | TRN:81-97, IDX H2 |
| Groceries | check: strike 320 ms, dab arc 520 ms, count roll, basket breath; aisle fold 260/340 ms; 60 fps seam | strike 150 ms fade, no dab/breath; aisle one 150 ms crossfade; seam still+lit; wash paused, no sheen/bead | = RM | check light (`.notNow`), `.done` finish, `.aisleCleared`; Clear basket tap key `.success` (IDX H5; GRO:38 stale) | B (flag, origin A) | GRO:11-45 |
| Lists | pick spring 0.52 s; finished section scale 0.96; REMOVE rises 6 pt; page entrance stagger 120 ms | 150 ms in/out (200 ms gap stays); fade only; opacity only | = RM | `.pickedUp`, `.selection` arm, `.aisleCleared` reset | B | GRO:18-21, 41-42 |
| Shared Tess line + UNDO (all full-screen layers) | 300 ms blur-in, 8 pt rise; leaves 240 ms; reserved row grows 320 ms | 150 ms fade, no rise/growth | = RM | line never has a haptic; UNDO `.undo` alone | A (line) / B (screens) | GRO:26-31, SET:65-68 |
| Recipes (non-cook: paste, portion drum) | not specced | INFERRED 150 ms | INFERRED = RM | `.made` on paste save (HMT row 15) | B | HMT:34 (no motion spec) |
| Cook mode / clock page | bead breath x1.14 2.4 s, 30 fps walk; step lights wet 2 s; DrainBar 1 step/5 s | bead still, 1-min steps 150 ms; step lands dry; key figure 150 ms crossfade at minute boundary | = RM; soul LP form; Claude "how long left" by position+size | `.timeUp` yes; bead soft impact YES in LP, NO 23-07 (Tess's); hold-start/Next ruled retired (IDX H8) | B (clock A) | CCK:13-26, 69-77 |
| Cook timer end | flare + ring 600 ms, overlay slide 24 pt | line cadmium 150 ms, no bloom/ring, overlay crossfade | = RM | `.timeUp` once, only if live <=2 s | A/B | CCK:50-65 |
| Pantry | word crossfade 160 ms, ring 220 ms, close-up 320 ms, greyed 42%->100% 420 ms | one 150 ms crossfade together | = RM | `.selection` once at tap; no-change tap none; swipe-add `.made` (DEC:1031); failed save one `.warning` | B | PAN:37-69, IDX H7/H13/H15 |
| Money (dial, Log, Month) | drum coast 620 ms, snap 90 ms; fold 360 ms; ledger 440 ms stagger 30 ms | no coast, no snap, no tick on its own; fold = 150 ms fade; drums jump | = RM (one path) | drum `.selection` (40 ms floor); Log `.made`; UNDO `.undo`; Skip none | A | MRA:29-34, 44-58, 66-73 |
| Reading | coast ~900 ms; resume rise 460 ms + glint 760 ms; flight 620 ms | resume 150 ms; glint -> 150 ms page-number highlight; flight fades | = RM | resume: none normal, `.selection` in RM/LP (replaces glint); Finished `.done`; set aside none | A | MRA:77-93 |
| Habits (not built) | stroke fall 26 pt, wet, dry 2 s; week-met stroke 700 ms; fleck 520 ms | strokes fade in place; no fall/fleck; week-met whole | = RM (G318) | check-in `.done` (his, plays 23-07); fleck/rule-counted none | B (haptic A) | DAY:80-97, HAB:14-34 |
| Shutdown (not built) | hold bead; handoff lift 620 ms/80 ms stagger; fold 420 ms | fill no bead; crossfades no lift | = RM (G317) | close `.done`; UNDO `.undo`; 22:00 close silent, written next open | B | DAY:62-78, HAB:17-34 |
| Notes | NOT specced for motion (INFERRED house policy) | INFERRED 150 ms | INFERRED = RM | note write = landing tick `.made` (IDX H16, unspecced); delete tap + UNDO 10 s | B | IDX:25 only |
| Day log (not built) | lines rise 10 pt/40 ms; scrub dim 200 ms; object reveal 440 ms | 150 ms fades, numeral no travel | = RM | scrub `.selection` per day (25/s cap, landing always), `.pickedUp` per week; Tess-written line none | B | DAY:99-108, SPD:55-72 |
| Speak (listen, ghost, commit) | swell 1.06; bloom x1.4-1.55; ghost dry 3 s (2 s in workout); commit gather 220 ms | no swell; bloom x1.2; dry 0.8 s (0.6 workout); words fade no blur | **soul LP form; mic <=20 samples/s; dry stays 3 s as 4 steps ~0.75 s** | `.selection` touch-down; `.listening`; commit `.made`; UNDO `.undo` alone | B (soul/haptics A) | DAY:45-57, SPD:24-35 |
| Review (week page, story) | entrance 35 ms/14 pt; story blur-in 300 ms | 150 ms fade; soul works by position | = RM; automatic Monday story does not run in LP | tap day `.selection`; story none | B (Core pack) | BHR:51-63 |
| Settings: entry, Claude page, Looks, Your day | Review lifts 380 ms, grows 420 ms; Claude line draw 360 ms; month stroke 500 ms | 150 ms crossfade; no line draw; stroke whole | = RM (Claude section: opacity only, no 6 pt offset) | Haptics-on flip `.selection`; Claude flip `.selection`; REMOVE `.selection` no UNDO; check answers none | B (haptics/Look A, Core settings) | SET:10-17, 35-45, GRO:63-67 |
| Settings: Look (pin, change) | paint flood from soul 700 ms (Review sentence) / 250 ms (Looks swatch, lab) | 150 ms (HS43) | = RM per HS43; GRO:67 says flood "stays" (stale) | `.pinned`; `.selection` word cycle | A | SET:77, LRB s.5.6, GRO:67 |
| Settings: page turn (Slide/Turn/Soften/Rotate) | Slide 520; Turn ~820 @6 rows; Soften 590; Rotate 460 @6 rows | all four words = one 150 ms crossfade, value stays | = RM, choice stored | none on turn (R2), `.selection` on pick | B (tokens A) | PGT:3-13, SET:21-30 |
| Backups / Export / Health | rows rise 0-5, 35 ms; hero flip 150 ms; folder fold 220 ms | 150 ms fade; Replace fill linear, no bead | = RM | folder pick `.selection`; copy `.made`; failure `.notSaved`; Restore `.made`; daily copy none; Health none | B screens / A Health | BHR:14-47 |
| Ask / BottomChrome / capture | swell 130 ms, gather | per Speak | per Speak | `.selection`; `.made`; `.undo` | B | DAY:45-57, HMT:19-21 |
| Tess soul | full 60 fps, six+ lights, roam, repaint, reward beat | still frame; Working = position/size, full opacity, halo, grade (G225); Done still 1.8 s | **own LP form: 30 fps, six lights, no readers, halo held, no roam, no repaint, Done/listening/working keep timing** | none (delete `TessSoul.swift:143`); stroke `.soulStroke` | A | MOT:241-247, CCK:35-42, QV:10-30, IDX M1/M2 |
| Live Activity (rest, cook) | system timers, `.numericText`, Go push | system-owned (we author nothing) | system throttles; `Text(timerInterval:)` costs nothing | none from the activity; N2 notification rings | A | LAW:8-45 |
| Lock Screen | static washes; Always-On: no washes/horizon (unbuilt) | system | system | notification sound/vibration only | A | LAW:30, 100-106 |
| Widgets (home/lock) | `.push(from:.bottom)` word change at `restEndsAt`; no polling | system softens | system; no extra entries; no word change 23-07 except started countdowns | none | A | LAW:80-96 |
| Watch | not specced; audit M15 "nothing to build" | n/a | n/a | n/a | A | haptics-sheet-audit M15 |
| Sides / page turns | 1:1 settle + spring | 150 ms crossfade | = RM | `.selection` on full side only | A/B | SID:33-36, IDX M2/P1 |
| Notifications (N2 rest, timer line) | rest "Rest is up" masked body; kitchen timer line | not ours | not ours | rings at any hour incl. quiet hours and LP (his timers) | A | LAW:39-44, CCK:46, IDX Q3 |

## (a) Places where LP deliberately differs from RM

1. Soul keeps her own LP form (30 fps, six lights, no readers, full opacity/pigment); RM = still frame/position-only: MOT:241-247, QV:10-30, IDX M2.
2. Speak ghost wait: RM 0.8 s (0.6 workout); LP keeps full 3 s with stepped drain (~0.75 s x4): DAY:51, SPD:31, IDX M5. VoiceOver flat 10 s with Cancel, never shortened.
3. Speak mic sampling: LP <=20/s; level smoothed at 30 fps: SPD:27, DAY:48.
4. Automatic Claude calls (plan wording, Monday week story, `readWaiting`) do not run in LP; asked calls do: DAY:34, BHR:57, MRA:104-109, IDX M8. (State, no motion.)
5. Ambient timelines PAUSED in LP, not just reduced: workout strip glint, guide breath, corner breath (TRN:34-39); Home breathing words, day-stroke end, training waiting guide, sky ground (GRO:53-56).
6. Thinking glyph (looks without soul): LP 30 fps; RM no turning but a 0.85-1 pulse over 3.2 s; stays alive in both: GRO:57.
7. Bead step haptic stays in LP, silent in quiet hours: CCK:74, 81.
8. Reading resume under RM/LP: 150 ms highlight + one `.selection` in place of the glint; normal plays no haptic: MRA:82.
9. Drum: RM and LP are one path (no coast, no snap, no self-tick), 420 ms travel to "41.60" in normal only: MRA:31-33, 52, IDX M7.

## (b) Where code today does NOT honor the matrix (wt-cook)

- `DesignSystem/MotionPolicy.swift:8-10` resolves on `reduceMotion` only; no LP input. File is 38 lines (SET:7 cites 5-39). Reads `accessibilityReduceMotion` at `:14`.
- `App/PowerState.swift` does not exist (App/ has none); no `isReduced` symbol anywhere in Swift. Specs (GRO:5, SPD:7) assume one cached `isReduced` updated on `NSProcessInfoPowerStateDidChange`.
- `Features/Tess/TessSoul.swift:109` reads `ProcessInfo...isLowPowerModeEnabled` directly, only on mode change (not notification-driven); `:66` state, `:163`, `:177`, `:200` consumers; `:56`, `:396` read RM; `:194` eye timeline 1/30 when RM or slow. Raw `.sensoryFeedback(.success, trigger: doneCount)` still at `:143` (IDX H9).
- Raw `withAnimation`/`.animation` bypassing the policy: `DesignSystem/Paint.swift:123` (repeatForever wash, ungated), `:296` (own RM), `:303` (no RM), `:421`; `Editorial.swift:77` (own RM ternary); `Features/Command/BottomChrome.swift:76,87,248,262,272,442-443,482,654`; `SpeakLayer.swift:49,53`; `CaptureParts.swift:74,78,96`; `Workout/Instruments/WeightReel.swift:88` (0.18 s).
- `Command/BottomChrome.swift:653` `let seconds = reduceMotion ? 0.8 : 3.0`: no VoiceOver 10 s branch; LP 3 s works by accident of not reading LP.
- Ungated or RM-only continuous timelines: `DesignSystem/Machined.swift:189` (60 fps, paused RM only), `ThemeLayers.swift:128` (15 fps), `ThinkingIndicator.swift:20` (60 fps, `paused: false`), `Workout/ExerciseStrip.swift:40` (60 fps), `LiveSetStrokes.swift:119` and `SwapPanel.swift:137` (20 fps): none read LP.
- Raw `.sensoryFeedback` outside `Haptics.swift`: 25 lines (HMT:3 count still holds); no origin field / quiet-hours gate on `Haptic`; no Haptics on/off gate.
- `Workout/LiveActivity/RestActivityController.swift:149-153` still sends `AlertConfiguration` with unmasked "Set N is up" and exercise name (LAW:39-44, IDX Q3).

## (c) Conflicts and gaps between specs

1. **Ruled (DEC:1069 item 1): `.done`, a tap key; GRO:38 and GRO:43 now say so.** Was: GRO:38 `.done` vs IDX H5 `.success` (tap key); GRO:43 lists it named-action-only vs DEC:1027/1039 (IDX U3).
2. Cook clock matrix CCK:71-75 (Next medium, hold-start medium 0.8, Done `.success`) vs IDX H1/H6/H8 (Next bar retired, no hold-start haptic, Done `.done`).
3. **Ruled (DEC:1069 item 2): title "Timer", body "Rest is up"; TRN:95 now says so.** Was: TRN:95 "Set 3 is up" vs LAW:44 / IDX Q3 "Rest is up", masked body. TRN:97 vs LAW:41 on the activity carrying an alert.
4. Look flood: GRO:67 "stays in LP" vs HS43 150 ms (IDX M4, SET:77); MOT:237 says 250 ms; LRB s.5.6 keeps 250 ms normal / 150 RM+LP and 700 ms on Review's sentence (lab default, unruled).
5. **Ruled (DEC:1069 item 3): 30 fps, full opacity; QV and MOT lines now say so.** Was: QV:12, MOT:242 say 20 fps; ruling 30 fps six lights (IDX M1/M2). QV:29/:35 keep the side spring in LP vs SID:36 (150 ms).
6. Settings numbers: Product ruled (Oct 18, 7:20 AM, #984 calls, `decisions.md`): Rotate 160 / 260 / 24 (460 ms at six rows) is the Rotate turn only; every other Look and Settings motion has a 260 ms ceiling. Still lab defaults: one 24 ms stagger on Settings, 120 ms step crossfade, 250 ms Looks flood. Stale: `tess-settings-motion.md:14` (40 ms, 420 ms grow), `pages-90.md:21` (480 ms / 34 ms), and the board's "Rotate 650 ms".
7. Plan skip haptic: SPD:47 earlier "none" vs DAY:29 / IDX H11 `.notNow`. Day-log week tick: SPD:64 `.impact(.light)` vs DAY:106 `.pickedUp`.
8. Plan hold hint wording: DAY:31/:40/:117/:136 "Keep the plan" vs DEC:1043 "Hold to keep N tasks" (IDX U4).
9. Gaps (no spec): Notes motion, Watch, non-cook Recipes, Money/Reading haptics in SLM/SLR (IDX H10), the Haptics gate in LP.

## Changes from Kitchen's open calls (Oct 18, rows N22 to N59 in `tess-ruling-index.md`)
Not yet merged into the table above; Builder A reads these as the newer cells.

1. First cell "Notes": Normal `page fades 380 ms, context and body draw in, words settle at 128 ms; write flies 420 ms; list entrance opacity only under the flag (G290)`; RM `row crossfades to the page, opacity only (G289)`; LP `= RM`; Haptics `note write .made; delete tap + UNDO 10 s`; Cite `NRM:5-36`. (Replaces "NOT specced for motion (INFERRED house policy)" at MAT:43.)
2. First cell "Speak (listen, ghost, commit)": LP cell becomes `soul LP form; bloom still x1.2 and level not fed (G313); dry stays 3 s as 4 steps ~0.75 s`; RM cell adds `Write dry 0.6 s (G314)`. Fix MAT:64 item 3 to match (drop "mic <=20 samples/s").
3. First cell "Cook mode / clock page": LP cell adds `horizon steps once a minute, every 10 s in the last minute (ruled Oct 17 9:22 PM); Home DrainBar one step a minute (G226)`.
4. First cell "Backups / Export / Health": LP cell becomes `= RM; first daily copy still runs, late-tail and folder re-check wait for power OK (G359)`; Normal cell folder words `Backup folder, ... changed/stopped` with 10 s UNDO (G371).
5. First cell "Widgets (home/lock)": LP cell becomes `system; Go swap is a crossfade and digits do not roll (G339); no extra entries; no word change 23-07 except started countdowns`.
6. First cell "Sides / page turns": Haptics cell becomes `.selection on full side only; none on exercise rail turns or on appear (G386)`.
7. First cell "Ask / BottomChrome / capture": Haptics cell adds `typed "undo" = spoken (G441); receipt line first, first-send notice second (G428)`.
8. New row after "Training / workout": `Plans and Exercise pages (week/month, zooms, Trend tip, Add to routine)`; Normal `day-word stagger, page zoom, wet-tip breath`; RM `tesseraAnimation, no offsets (G387); zooms 150 ms crossfade (G384)`; LP `= RM; Trend tip still at 0.75, no loop (G383)`; Haptics `.made on add (UNDO 4 s, 10 s VoiceOver, G390); .notSaved once on a failed write (G393)`; Owner `A`; Cite `none yet`.
9. First cell "Home: Now hero, queue, day strip": LP cell adds `proposed plan words still at the breath's mean (G267)`; no other change.
