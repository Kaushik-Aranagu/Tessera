# QA review 353: Field 18 for his typing (Builder B)

*QA, Oct 16, about 1:45 AM Pacific. PR #353, `ios/field-18`, head `1666ebd`, from `94b69cc`. Static review. Trial
merge onto master: clean, 8 Swift files (+24 / -12) and the clip `field-18.mp4` (29.5 s, 590×1282). Design passes
the recording.*

## Verdict: PASS

It matches calm-capture.md's addendum (`2e7cf32`) row for row:

- **The new role.** `TypeScale.field` is Inter Tight 18/400, line height 1.33, `textStyle: .callout`
  (`DesignSystem/Theme.swift:74-76`). `TextRole.field` maps to it (`DesignSystem/Editorial.swift:8, 24`).
  - It goes through the same font path, so it scales with Dynamic Type up to accessibility5.
  - 18 sits above the 16 pt floor and is one step under Body 21.
  - The field has a default in the struct, so all three concepts' `TypeScale(...)` calls (`Theme.swift:146, 194,
    225`) pick it up unchanged.
- **Field 18, everywhere he types:**
  - Ask Tess's field, with its placeholder and ghost in the same `TextField` (`Features/Command/BottomChrome.swift:375`).
    The ghost keeps inkSecondary. The bottom padding goes from 8 to 6, moving the drying line up 2 pt as the
    addendum's 7 → 5 asks; Design should confirm the exact gap on the clip.
  - The Notes writing line (`NotesView.swift:133`).
  - A note's first line, which was Title before (`NoteEditor.swift:39`), and the note body (`:54`).
  - The recipe paste (`PasteRecipe.swift:68`).
  - `LiveAskField` in a workout (`WorkoutParts.swift:297`), still in cream.
  - The key `SecureField` (`ClaudeSection.swift:242`).
- **Tess's lines stay Body 21.** The question line, Tess's replies and the mode words are untouched.
- **The Receipts back word** is now "‹ SETTINGS": the label role, which draws caps, in inkSecondary, 44 pt tall,
  with `HandleButtonStyle`, the same as #347's "‹ TRAINING" (`ClaudeSection.swift:445-452`).
- **Safety.** Type and one label only: no LaunchFlags or ProcessInfo reads, no store writes, no project.yml change.
  No secrets; the key field's handling is unchanged apart from its font.

## Lows

- **L1. Receipts has no edge swipe back.** It hides the system back button and bar (`ClaudeSection.swift:478-479`)
  but has no `EdgeSwipeBack()`. That predates this PR (it came with #320), but it's the same one-liner as #347 F1:
  `.background { EdgeSwipeBack() }`. It's worth carrying here, or in the next Settings PR.
- **L2.** A note's first line drops from Title to Field 18 by Design's rule. The note's hero on its own page is now
  the context line above an 18 pt first line. Design's call on the recording.

## Addendum: re-read at `d941e8d` (Oct 16, about 2:25 AM Pacific): PASS

The delta is three lines in `ClaudeSection.swift`, plus the clip trimmed. The Receipts back word adds
`.textCase(.uppercase)`, which is Design's fix, so it reads "‹ SETTINGS". `.background { EdgeSwipeBack() }` is added
to Receipts (`:479-480`), the same K1 pattern as Backup and Routines, which closes L1. Nothing else changed.
