# QA review 343: Return finishes what's typed (Builder B)

*QA, Oct 16, about 1:05 AM Pacific. PR #343, `ios/return-key`, head `f46c997`, from `d55d29c`. Static review (no Swift
toolchain in the cloud) plus the two recordings. Trial merge onto master `73a734d`: clean, 8 files, +82 / -1.*

## Verdict: PASS (fit for the install candidate)

This fixes the REVIEW 1 bug ("Return in a text box = new line, no way to send") on both Notes fields. Ask Tess's key
now reads Send. Data-safe.

## What I checked

1. **The Notes writing line** (`Features/Notes/NotesView.swift:132-145`).
   - It is a vertical-axis `TextField`, so Return types a newline. The new `onChange` treats that newline as Return.
   - It joins the newline into a space, trims, then calls `onSubmit`, which is `write()`.
   - `write()` trims, guards against empty, and clears `draft` synchronously (`:106-115`). So even if the system also
     fired `onSubmit` on the same key, the second call finds an empty draft and writes nothing.
   - A bare Return on an empty line writes nothing.
   - The recording `return-writes-note.mp4` (10 s) shows one row, "Return writes this", and the line clears back to
     its prompt.
2. **A note's first line** (`Features/Notes/NoteEditor.swift:44-49`). A newline moves focus to the body and the
   heading keeps one line.
   - The load sets `heading` from `parts.heading`, which never contains a newline, so opening a note doesn't jump focus.
   - The edit still goes through the existing `noteEdit()` and debounced save (`:119-143`).
3. **DONE above the keyboard** (`DesignSystem/KeyboardDoneWord.swift`). It is applied to the note body (`NoteEditor.swift:59`)
   and the recipe paste (`Features/Recipes/PasteRecipe.swift:73`).
   - It is `.labelWord`, trailing, and it only clears focus. No write, no data path.
   - Return in those two fields stays a newline, as Design's text-entry rule says.
4. **Ask Tess**: `.submitLabel(.go)` became `.send` (`Features/Command/BottomChrome.swift:373`). The `onSubmit(dry)` path
   is unchanged.
5. **Data safety.**
   - `ReturnKeyUITests` is `final class ... : SimulatorOnlyTestCase` (`TesseraUITests/ReturnKeyUITests.swift:5`). It
     launches with `-demo -resetDemo` (and `-openLink notes`), all through LaunchFlags.
   - No new launch flag, no ProcessInfo read, no migration, no project.yml change.
   - The new Swift file is picked up by the XcodeGen folder glob.
6. **Secrets**: none in the diff.

## Lows (none block)

- **L1. A multi-line paste into the Notes line writes at once.** Pasting "milk\neggs" writes one note, "milk eggs", the
  moment it lands. A heading paste with a newline joins it into the heading rather than spilling into the body.
  Neither loses text. Splitting a paste at its first newline into heading and body would be kinder later.
- **L2. DONE draws in the system keyboard toolbar.** On iOS 27 that bar is the system's own glass strip above the
  keyboard. Design should confirm the label word there meets "no button shapes"; it is the system's bar, not ours.
- **L3. Demo clock in the clip.** The note reads "the latest yesterday" in the recording because it was written at
  00:58 real time, which is still the previous day before 04:00 (TesseraDay), under `-demoTime 18:10`. It is
  correct on his phone; it only shows in recordings made after midnight.

## Install-day check (row R1 in the install-day script)

Ask Tess: the key reads **Send** and sends. Notes line: Return writes the note. A note's first line: Return moves to
the body. Note body and recipe paste: Return makes a new line, and DONE puts the keyboard away.
