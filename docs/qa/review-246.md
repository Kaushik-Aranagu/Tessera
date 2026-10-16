# Review #246: Backups after a reinstall, plus #241 fixes (c2fd7ad, head cb68c1f)

Builder B. 10 app files, +132/-8, no Core changes, plus backups-reinstall.mp4. Static review (no Swift toolchain here). The merge's diff against fdcaee4 touches only the announced files.

**Verdict: PASS.** N1 is closed, as are the Receipts day, the ink link and the WetTip comment. One should-fix (R3: the "Reinstalled?" line can show on his own long-used phone) and two lows.

## Restore-walk items
- **3, the "Reinstalled? Restore brings back your copy from iCloud Drive." line:** shows while the last 50 ops hold none by `.user`. See R3.
- **7, naming the copy's day:** the confirm line and "A restore is waiting" both name the copy by `BackupCopy.fileDay`. That's his 4 AM day (`TesseraDay().day(of:)` + 12 h, then the weekday-day-month format), so a 01:30 Wednesday copy reads Tuesday, matching its file name. `BackupCopyTests` covers it. ✓
- **8, a damaged copy:** `BackupError.damaged` (TesseraBackup.swift:47) now says "That copy is damaged. Try the day before.", separate from "isn't a Tessera backup". ✓
- **6, the key after a reinstall:** with no key and Tess Call rows in the ledger (they come back with the restore), ClaudeSection says "Your key stays on the phone it was added on. Paste it again to let Tess ask Claude." ✓ (see L5)
- **"Stop using it":** forgets the bookmark, holds it in `@State` for 10 s, and UNDO writes it back. The UNDO uses `InkLabelWordStyle.undo`. Nothing touches the copies in the folder. ✓

## #241 items
- **N1 closed:** `bloom()` runs on `.onAppear` when the row arrives new into Next, and on `onChange(of: arrives)` for a row already drawn. The wash eases in over 0.5 s and dries on `Motion.dry`, and is skipped under Reduce Motion. The first draw doesn't bloom, because `seenNext` is nil then. (It uses plain `withAnimation` behind a Reduce Motion guard, which is fine in effect but not the house helper.)
- **Receipts:** rows now carry the day ("thu, 16 oct, 6:12 pm"), and the link rests in ink. ✓
- **WetTip comment:** fixed, though it now says "3.6 s" for a breath that's 1.8 s each way. That's the full cycle, so it's right.
- **NotesView:** now passes the real `reduceMotion`. ✓

## PasteRecipe:355, `dry(reduceMotion: false)` inside `.tesseraAnimation`: doesn't matter
`TesseraAnimationModifier` reads Reduce Motion from the environment and swaps the whole animation for the 0.15 s fade (MotionPolicy.swift:8-20), whatever animation it was given. So with Reduce Motion on, he gets the short fade either way. Passing the real value would only make the code read honestly. Leave it, or tidy it next time the file is touched.

## Should-fix
- **R3: the "Reinstalled?" line keys on `actor == .user` in the last 50 ops (BackupView.swift:69).**
  - Sets and captures Tess writes are `.tess`, and Siri and Lock Screen writes aren't `.user` either. After a workout-heavy stretch logged through Tess, his last 50 ops can hold no `.user` op at all.
  - The line then tells him "Reinstalled?" on his own phone, which reads as if something's wrong.
  - Fix: use Core's meaning, any op not by `.system` (the same test `TesseraBackup.userOps` uses).
  - Better still, ask whether any user op exists at all, not just among the last 50.

## Lows
- **L4:** B8 from review-211 is still open. `BackupKeeper.forget()` doesn't clear a remembered folder failure. Now that "Stop using it" is a visible action, a folder that had failed will keep showing "The folder you chose can't be reached… Choose it again" after he stops using it, until he next leaves the app. Fix: clear the `.folder` failure in `forget()` (and put it back on UNDO if wanted).
- **L5:** the key-missing line also shows after he taps REMOVE himself on the same phone (the ledger still has calls). "Your key stays on the phone it was added on" is then a little off. A simpler line covers both cases: "No Claude key on this phone. Paste one to let Tess ask Claude."
