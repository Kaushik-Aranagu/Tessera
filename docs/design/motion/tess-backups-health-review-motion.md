# Backups, Health export and Review's week story: motion (board 74)

Lab spec to pair with Kitchen's gap hunt 22 (no hunt 22 file exists yet; this is written against decisions.md up to line 1053 and master). Docs only. Columns: **Normal / Reduce Motion (RM) / Low Power (LP)**; LP = RM (D5): 150 ms crossfade, no offset, blur, scale or stagger. Haptic names are the map in `DesignSystem/Haptics.swift`. Defaults the lab picked are marked *(lab default)* and listed in §6. The key, its tail and its length never appear anywhere here (DEC:77); a backup never holds the key (DEC:51, 1049), and the folder bookmark lives in UserDefaults, outside the store (`BackupKeeper.swift:17`).

## 0. What exists on master
- **Backups** (`Features/Backup/BackupView.swift`, pushed from Review's foot, `ReviewView.swift:232-238`): entrance order 0 to 5 through `EntranceModifier` (`Editorial.swift:60-82`), a private `say()` line (`BackupView.swift:332`) that is not the shared Tess line, a folder UNDO that is a bare 10 s `Task.sleep` (`:316-320`), a raw `.sensoryFeedback(.selection)` on the folder tap (`:104`), a Restore hold key through `PaintKey` (`:210`) that plays the raw medium 0.8 at completion (`Paint.swift:309-311`) and completes on one VoiceOver double tap (`Paint.swift:314`).
- **Export** (`ExportRow.swift`): built but dark. `ExportFile.ready = false` (`:453`), `onExport: {}` is a stub (`BackupView.swift:130`), `MaskedRestoreWarning` is not referenced from `restore(from:)`.
- **Health** (`App/Health/HealthExporter.swift`): writes a finished workout, no UI, swallows every error (`:69-71`).
- **Review**: the live page is `Features/Home/ReviewPage.swift` (tap a day plays `.selection` at `:312`); `ReviewView.swift` is the older week page with Look, Rest and Claude inline. There is **no week story in the app**: only the Core pack (`WeekFacts.swift`); no Claude call, no power gate, no Monday trigger.
- Low Power is read only by the soul (`TessSoul.swift:109`); `EntranceModifier` and the page animations do not read it. The Low Power flag PR via `PowerState` is what makes LP = RM true here.

## 1. Backups

| Moment | Normal | Reduce Motion and Low Power | Haptic | Notes |
|---|---|---|---|---|
| Page arrives | rows rise in order 0 to 5 (smooth 0.28, 35 ms stagger, 14 pt; hero blur 4 pt) | 150 ms fade, no rise, no stagger | none | as built; LP needs the flag |
| Hero word flips "Kept on this iPhone" / "Kept in two places" | crossfade 150 ms (today no animation) | same | none | `BackupView.swift:52` |
| Choose a folder (tap the folder word) | system folder sheet; no custom motion | same | none on the tap; `.selection` once when a folder is **picked** (today it fires on the tap, `:104`) | fix: move to the pick result |
| Folder picked, first copy written | shared Tess line: "Saved a copy there. One a day from now on." with UNDO, 10 s | 150 ms fade | `.made` once *(lab default)* | his write; UNDO plays `.undo` alone |
| Stop using the folder | folder sentence folds (220 ms, house); line "Copies stay on this iPhone only now." with UNDO 10 s | crossfade | `.selection` (his tap) | change, so 10 s; VoiceOver flat 10 s |
| UNDO the stop | "The folder is back." and the folder line returns | crossfade | `.undo` alone | clears the stop line (today it stays) |
| Save a copy | system share sheet; then "Copy saved." | fade | `.made` once when it lands | needs Face ID when whole (DEC:45/51) |
| Copy fails (his action) | line "Couldn't make a copy just now." stays until replaced | fade | **one** `.notSaved`, once per failure | `errors-84.md:21`: only for what he just did |
| Daily copy by itself (first background move) | nothing on screen; if it failed, the quiet failure line shows next open | same | **none** (background work never warns) | `BackupKeeper.runDaily` |
| Pick a restore file | system picker; then "Replace" appears under a "What's here now is kept in Backups, so this can be undone." line | 150 ms fade | none | `confirming` already animates (`:277`); `pending` appears with no animation today (`:167`, `:233`, `:295`): wrap in the house animation |
| Hold REPLACE (0.9 s) | the key fills along the line; release early drains in 220 ms | linear fill without the bead; same 0.9 s | **`.made` once at completion** *(lab default)*; the raw press-begin tick and medium 0.8 are deleted | PaintKey default is medium 0.8 today (`Paint.swift:309`), not "none" as the migration table says (row 21 region) |
| Restore staged | "A restore is waiting" + CANCEL; Tess "Restore waiting. It happens when you reopen." *(wording for Design)* | fade | none (staged, not done) | |
| Cancel restore | line "Cancelled. Nothing will be replaced." | fade | `.selection` (his tap) | |
| Bad file / newer file / damaged | the existing lines ("That file isn't a Tessera backup.", "That copy is from a newer Tessera. Update first.", "That copy is damaged. Try the day before.") | fade | one `.notSaved` per refusal (he just did it) | each once, never on an immediate repeat |

- **One Tess line, one slot.** Backups falls under the shared line with UNDO (DEC:1023): it sits directly above the key row, UNDO at its right (GL19, DEC:1043 U2), and with no key row above the bottom chrome. `BackupView.say()` is a private copy of that idea and should become the shared call; until Settings ships the Backups page keeps its local line and the lab spec describes the target. `settings-place.md`'s "line grows under the line it is about" is superseded.
- **VoiceOver.** REPLACE is a hold key that writes: it speaks "Hold to restore" on double tap and completes only through the named action **"Restore"** *(lab default)* with no hold fill and the same single haptic. Every line above is announced when it appears; UNDO is an action on that line, flat 10 s.
- **Quiet hours.** Everything on this screen is his touch, so haptics play in quiet hours and Low Power. The daily copy makes no sound or line at 23:00 to 07:00.
- **Tests.** Folder tap plays no haptic, folder pick plays `.selection` once; UNDO plays `.undo` and not `.selection`; REPLACE completion plays one haptic however it completes (hold or action); a failed background copy plays none; a refused restore plays one `.notSaved`; with RM or LP every transition lasts 150 ms.

## 2. Export row (unbuilt; written for the build)
| Moment | Normal | RM and LP | Haptic |
|---|---|---|---|
| The row | "Export" label word + "This file hides your private things." (as built), arrives with order 5 | fade | none |
| Tap EXPORT | the system share sheet (as SAVE A COPY, `BackupView.swift:184`); no custom progress (a file this size needs none) | same | none |
| Written | shared line "Export, saved." with no UNDO (a file already shared cannot be taken back) *(lab default: receipts name the thing first)* | fade | `.made` once |
| Write fails | "Didn't save that. Try again." | fade | one `.notSaved` |
| Opening an export file to restore | the masked warning: "This file hides your private things, so they will not come back. Restore from Backups to keep them." with RESTORE / CANCEL; opens in place, 150 ms | fade | none; RESTORE is a tap key (not a hold) |
Private words never appear in the row, the receipt or a VoiceOver label; the file is the masked one (DEC:35, 1041, G196/G198).

## 3. Health export
- **No screen, no motion, no haptic, no line.** `HealthExporter` is a silent mirror (`errors-84.md:21`, `lockscreen.md:65`): a failed Health write is background work, so no `.notSaved`; the next finish retries.
- The one system permission sheet is the system's; it is asked once, from a place he chose, not from a background finish. Today `authorize()` runs from the finish observer (`HealthExporter.swift:16-22, 36`), which conflicts with "one ask a day, never from a background finish" (DEC:741): a Builder A / Product call, listed in §6.
- Undoing a finished workout should delete the Health workout (DEC:415, 756); there is no delete path in the code. When built it is silent and adds no word to the UNDO line.

## 4. Review's week story (unbuilt)
The story of the week that just ended shows Monday morning and stays under the new week until Tuesday 04:00 (DEC:352); an empty or notes-only week skips the Claude call.
| Moment | Normal | RM and LP | Haptic |
|---|---|---|---|
| Review opens and the story is being written (he opened it) | the soul works (mains move apart in place, full opacity) while the plain count lines already show | position only, same opacity (G225); no swell | none |
| Story lands | the Tess line blur-fades in over 300 ms under the hero; the three plain count lines stay | 150 ms fade | none (information; a Tess-initiated landing) |
| Automatic write, Monday 04:00 | waits for power OK and for **07:00**; in LP it does not run and retries on the next open with power OK (G316, DEC:1039/1023); his own "read this week" still runs | same | none, no sound, no line before 07:00 |
| The call fails or times out | the plain rules line stays; nothing says the call failed (it was automatic) | same | none |
| Tuesday 04:00 | gone on the next open; no exit animation | same | none |
| VoiceOver | the story is spoken once as the Tess line when Review is in front, never as a live announcement while it is not | same | |
- Tap a day keeps `.selection` (`ReviewPage.swift:312`); returning by tapping away plays none. The page swaps are `.contentTransition(.opacity)` plus the house spring (`ReviewPage.swift:241-311`) and are already RM-safe.
- Sheet-vs-code gaps for `review-week.md` (Design): arrival is specified at 22 ms and 8 pt but built as the shared 35 ms and 14 pt (`EntranceModifier`); the custom action "Read Tuesday" is not built; `WeekDabs` uses a raw `.animation` that is simply off under RM (`ReviewView.swift:282`), which is acceptable but not through `tesseraAnimation`.
- Tests: no automatic Claude call before 07:00 or in LP; his own request runs in LP; the plain lines show with no network; the story never plays a haptic.

## 5. Where sheets and rulings disagree
| Line | Ruling or code | Owner |
|---|---|---|
| `settings-place.md:77-80` Tess line grows under the line it is about, UNDO at its end | one shared line above the key row, UNDO at right (DEC:1023, 1029, 1043) | Design |
| `settings-place.md` "Restore stays inline" with no hold detail | Restore is a hold key that writes: named-action VoiceOver, single haptic | Design |
| Migration table row for the Restore key says PaintKey default "none" | PaintKey completes with medium 0.8 today (`Paint.swift:309`) | Lab, next PR |
| `settings-80.md` D2 line "A copy holds everything, Private note, weight and money included." | absent from `BackupView.swift` | Design and Builder B |
| Copy: sheet "Copy saved to iCloud Drive/Tessera. One a day from now on." | code "Saved a copy there. One a day from now on." | Design |

## 6. Asks
1. **Product:** Restore's haptic (lab default `.made` at completion) and its VoiceOver action name ("Restore").
2. **Product:** move Backups' line onto the shared Tess slot now, or when the Settings Data page ships (lab recommendation: now, one rule).
3. **Product:** the export receipt "Export, saved.", share sheet vs folder, and whether export needs Face ID like SAVE A COPY.
4. **Product / Builder A:** the Health permission is asked from the finish observer today; move it to a place he chose.
5. **Design:** `review-week.md` arrival numbers vs the shared entrance; "Read Tuesday"; the "A restore is waiting" Tess line wording.
