# When the look goes from "by day" to "by night"

For: Builder A (ThemeStore, root view, Live Activity, widgets), Design, QA. Research lab, board item 64, 2026-10-16.
Checked against `theme-names.md`, `theme-checks.md`, `docs/design/themes.md` on `origin/claude/project-thread-b3tu3f` at **1ccbef7** (sheet, both addenda, the T1/T2 fixes), PR #193 (067daa3, themes part 1), PR #195 (6890f56, Porcelain for everyone, the sentence on Review), and master at **d9411a5**. Line numbers are master's.

## The rule

1. **Day means the phone is in Light appearance; night means Dark.** That is the trait `userInterfaceStyle` (SwiftUI `colorScheme`), whatever set it: the Control Center toggle, Settings, iOS's Automatic schedule (sunset to sunrise or his custom times), a Focus or a Shortcut. The app never reads a clock or computes sunset. `.unspecified` counts as day. His 4 AM day (`TesseraDay`) has nothing to do with this.
2. **Not pinned:** the app shows the day look in Light and the night look in Dark. The default (nothing saved) is Porcelain by day, Obsidian by night, for every install (T2, decided 7:20 PM).
3. **Pinned:** one look in both appearances. The app also forces its own appearance to the pinned look's mode with `.preferredColorScheme(pinned.isDark ? .dark : .light)` on the root, so the status bar, keyboard, sheets, menus and Liquid Glass match the ground. Unpinned, the root passes `nil` and follows the phone.
4. **The workout** stays dark in every look (`.preferredColorScheme(.dark)` on its cover). Its palette is the workout set of the look that is on: the pinned look, else day or night by the phone's appearance.
5. **Other processes follow the phone, never the app's override.** The Live Activity and widgets read their own `colorScheme` and pick from `lookDay` / `lookNight` (same name twice when pinned). The Lock Screen and StandBy use the phone's appearance.

## The edges

- **A tap in the sentence (in-app change):** the new ground floods in from Tess's soul (PaintFlood 700 ms, house curve), 250 ms crossfade under Reduce Motion, selection haptic; a hold adds the firmer haptic. A tap on the slot that isn't showing changes the word only. One `WidgetCenter.shared.reloadAllTimelines()` after the flood settles, and one Live Activity update with the new names.
- **A system appearance change while the app is open:** swap at once, with iOS's own appearance crossfade and no PaintFlood. Every `Color(light:dark:)` is a dynamic UIColor, and the status bar and keyboard flip with the trait, so the app can't hold the old ground back without forcing the old scheme, which would leave the chrome and the page split. Proposed default; themes.md says otherwise (C1).
- **Mid-workout:** the workout palette is latched when the workout opens and kept until it closes; a change of appearance or look during it lands when he is back on a page (the cover's dismissal is the transition). This is how "never during set entry" is met without timers. The Live Activity flips with the Lock Screen right away, because it is a separate surface.
- **Mid-animation (a flood is running, or a gesture is held):** the store changes now; the flood keeps going and ends on whatever look is current when it ends. A second tap during a flood restarts it from the soul. No queueing.
- **Launch, before the first frame:** the saved keys are read synchronously in `ThemeStore.init` (Looks.swift:146-148), so the ground is right. `systemIsDark` must also be right on the first pass: seed it from the window scene's trait collection, not from the background's first `onChange`.
- **Reduce Motion:** same rule, same timing of the swap; only the flood becomes the 250 ms crossfade. The Lacquer band holds still.
- **`-theme <name>` (DEBUG):** pins in memory for the run; never written. Any tap during that run also stays in memory.
- **Backup restore:** a restore doesn't touch the look when this phone has saved keys. With no keys (fresh install after free signing ran out), the backup's `lookDay` / `lookNight` / `lookPinned` are applied (theme-names.md, rule 4). Older backups carry none; keep the defaults.
- **Lock Screen and StandBy:** the Live Activity ground is the workout `ground` of the look for the Lock Screen's scheme; the Dynamic Island is always the Obsidian workout set; StandBy night mode tints red, so meaning rides on luminance and shape. Removable backgrounds use the night look's ink, or Obsidian's if the night slot holds a light look (T3).
- **Smart Invert / Increase Contrast:** not a day or night signal. Ignore for the schedule.

## Fixtures

Day/night = saved slots. Sys = phone appearance. App = ground and chrome in the app; LA = Lock Screen Live Activity ground; W = Home Screen widget (none exist on master yet).

| # | Day / Night / Pin, Sys, event | Expected (App / LA / W) | Master at d9411a5 | |
|---|---|---|---|---|
| 1 | nothing saved, Light, launch | Porcelain, light chrome / Porcelain workout #14111A / Porcelain | Defaults Porcelain, Obsidian (Looks.swift:146-147); LA fixed #120E1A at 46% (RestLiveActivity.swift:13,83) | App pass, LA fail |
| 2 | nothing saved, Dark, launch, first frame | Obsidian; halo and screen blend from frame 1 | Ground right via `colorScheme` (ThemeLayers.swift:22-24), but `systemIsDark` starts false (Looks.swift:123) and is set in `onChange(initial:)` (ThemeLayers.swift:17), so `soulBlend`, `halo`, `actionBloom` read Porcelain for one pass (Theme.swift:359,364; ThemeLayers.swift:85) | Fail (one frame) |
| 3 | P / O / none, Light to Dark by Automatic at sunset, app open on Home | Obsidian at once, no flood / LA flips with Lock Screen / W Obsidian | Dynamic colours flip (Theme.swift:562-572), store rebuilds (Looks.swift:123-129); no flood | Pass (proposed rule) |
| 4 | P / O / none, Dark to Light, app in background | Porcelain on return | Same path | Pass |
| 5 | P / O / none, Light, tap "Porcelain" | Plein floods in 700 ms | Cycles (Looks.swift:168-171), 0.7 s crossfade, flood not built (LookSentence.swift:61-64) | Partial |
| 6 | as 5, Reduce Motion | 250 ms crossfade | 0.25 s (LookSentence.swift:63) | Pass |
| 7 | P / O / none, Light, tap "Obsidian" | Word becomes Lacquer, page unchanged | `cycleNight` (Looks.swift:173-176); page ground reads day | Pass |
| 8 | P / O / none, Light, hold "Obsidian" | "Obsidian always", black ground, dark status bar and keyboard | Pin saved (Looks.swift:179-182); no `preferredColorScheme` at the root (RootView.swift:62, TesseraApp.swift), so status bar ink is dark on #000 | Fail |
| 9 | P / O / Porcelain pinned, Dark | White ground, light chrome | Same gap: light status text, dark keyboard and sheets on white | Fail |
| 10 | P / O / Obsidian pinned, Dark to Light | Stays Obsidian | `current` = pinned (Looks.swift:159), pair = (O, O) (Looks.swift:164) | Pass (page) |
| 11 | Pinned Obsidian, tap name | Lacquer always, then Plein, Celadon, Porcelain | `cycle(pinned:)` walks `Look.all` (LookSentence.swift:69-73) | Pass |
| 12 | P / O, pinned Obsidian, cycled to Celadon pinned, hold to unpin | "Celadon by day, Obsidian by night" (pinned look back in its own slot) | `togglePin` clears only `pinned` (Looks.swift:180); day stays Porcelain | Fail |
| 13 | P / O / none, Light, workout open, Sys to Dark mid set entry | Workout palette unchanged until it closes; LA flips | Root `ThemedBackground` stays mounted under the cover (RootView.swift:58-62), so `systemIsDark` flips and `concept.workout` swaps at once (Theme.swift:263-266) | Fail (by proposed rule; cover behaviour UNVERIFIED) |
| 14 | Any look, workout open | Workout ground is the look's workout `ground` (Obsidian #000) | Cover draws `PleinGround()` dark #1C1828 in every look (WorkoutModeView.swift:130; Paint.swift:29) | Fail |
| 15 | Workout open | Cover forces dark; root stays on the phone's scheme | `.preferredColorScheme(.dark)` (WorkoutModeView.swift:131, WorkoutParts.swift:338) | Pass if it scopes to the cover (UNVERIFIED on iOS 27) |
| 16 | P / O / none, Sys Light, rest running, LA on Lock Screen | LA ground #14111A, rest #F0A500 | No look in `ContentState` (RestActivityAttributes.swift:10-46); fixed palette (RestLiveActivity.swift:9-16) | Fail |
| 17 | as 16, Sys Dark | LA ground #000, rest #FFC23D | Same fixed palette | Fail |
| 18 | Pinned Lacquer, Sys Light, LA | LA Lacquer #0C0812 | Same | Fail |
| 19 | Any, look tapped while LA is running | LA takes new names on its next update; W reload once after the flood | No reload, no names sent | Fail |
| 20 | Any, StandBy or Dynamic Island | Island: Obsidian workout set; StandBy red tint by luminance | Fixed palette, close to Obsidian set | Pass (by accident) |
| 21 | Home Screen widget, any | Look's ground per Sys | No widgets (TesseraWidgetsBundle.swift has only `RestLiveActivity`) | N/A |
| 22 | Saved Celadon by day, launch with `-theme obsidian`, tap name | Lacquer for this run; saved keys still Celadon / O / none | `pin` is memory only (Looks.swift:185-188), but the tap runs `togglePin` twice and `save()` writes `look.pinned` (LookSentence.swift:71-72, Looks.swift:190-195) | Fail |
| 23 | Saved Plein by day, restore a backup | Plein stays | Restore swaps the store only; keys in `UserDefaults.standard` untouched | Pass |
| 24 | Fresh install, no keys, restore backup made on Lacquer pin | Lacquer always | No look in `backupInfo` (TesseraBackup.swift); Porcelain / Obsidian | Fail (not built) |
| 25 | Widget extension reads the look | App Group suite `group.com.kaushikaranagu.tessera` | `UserDefaults.standard` (Looks.swift:142) | Fail (App Groups on the free team UNVERIFIED) |

Fails: 2, 8, 9, 12, 13, 14, 16-19, 22, 24, 25 (5 is partial: no flood yet). 21 isn't built.

## Contradictions, with a proposed default

| # | What disagrees | Sources | Default |
|---|---|---|---|
| C1 | "Changing the system appearance swaps the same way" (PaintFlood) and "never switch mid-gesture" vs dynamic UIColors and system chrome that flip with the trait, out of the app's hands | themes.md "Switching" vs Theme.swift:562-572 | Pages swap at once with iOS's crossfade, no flood. Only the workout latches its palette until it closes |
| C2 | A pin "whatever the phone's appearance", but master pins only the palette, not the scheme | theme-names.md "The pin" vs no root `preferredColorScheme` | Root `.preferredColorScheme` from the pinned look's mode; `nil` unpinned |
| C3 | "The workout follows the theme"; its background is `Workout.ground` plus the look's field | themes.md "Workout tokens" vs WorkoutModeView.swift:130 | Replace `PleinGround()` there with the look's workout field |
| C4 | Unpin puts "the pinned look back in its own slot" vs `togglePin` leaving day and night as they were | theme-names.md vs Looks.swift:179-182 | On unpin, a light pinned look goes to day, a dark one to night |
| C5 | `-theme` "pins in memory only, never saved" vs `save()` writing every key on any tap | theme-names.md T8 vs Looks.swift:190-195 | A `transient` flag set by `pin(_:)`; `save()` returns early while it's set |
| C6 | App Group suite vs `UserDefaults.standard` | theme-names.md rule 1 vs Looks.swift:142 | App Group if the free team allows it (one build to check); else standard, and widgets draw the defaults |
| C7 | One `look` in `ContentState` vs `lookDay` + `lookNight` | themes.md step 6 vs theme-names.md T4 | Both names; the extension picks by its `colorScheme` |
| C8 | VoiceOver actions "Keep always" / "Follow day and night" vs "Keep Porcelain day and night" / "Follow light and dark mode" | LookSentence.swift:55-56 vs theme-names.md | theme-names.md wording, with the name in the action |
| C9 | "The soul's flood comes with the Settings page", but the sentence ships on Review now | LookSentence.swift:61 vs ReviewView (6890f56) | Wire PaintFlood into `change()` now, since Review is the live home |
