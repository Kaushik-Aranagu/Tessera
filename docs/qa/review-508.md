# Review: #508 N13, a private note's row (Builder B)

QA, Oct 16 2026, ~1:30 PM PT. Head **ed30430**: one commit, two files. Merges cleanly onto master. Static review.

## Verdict: PASS (one medium follow-up on a different path)

### The row
- `NoteRow` takes its second line from `NotesCopy.preview(of:isPrivate:)`, which is empty for a private note (NotesView.swift:186, :290).
- The title is already `SecretWords.title` ("Private note"). CreateNote and EditNote set it (Notes.swift:113, :172).
- Before this change, lines 2 and later of a multi-line private note showed under the title.
- With the preview empty, the row is "Private note" plus its time. `.accessibilityElement(children: .combine)` reads only those two.
- The test pins both cases.

### Other paths checked at ed30430
- **Spotlight:** no `CoreSpotlight`, `CSSearchable` or `IndexedEntity` anywhere in the app or engine.
- **Search:** there is no search over notes.
- **Context menus:** the row has none. It is a Button that opens the editor.
- **Body reads:** only NoteEditor.swift:119/161 (the editor itself, which is meant to show it) and NotesView.swift:185 (this row) read a note's `"body"` for display.
- **Links:** a private note never links its own mentions (CreateNote, Notes.swift:115-118). EditNote clears `about` when a note turns private (:164-166). So a private note never shows up as a backlink.
- **Claude, the plan pack and Home:** walled already (#451, #469).

### Medium follow-up, M1: another note can link *to* a private note, and its object page shows the body
- `NoteList.resolve` (Notes.swift:35-43) matches any titled object, private notes included. A plain note that says "@Private note" therefore links to the oldest private note.
- That handle routes to `.object(id)`, which lands on `ObjectPage.generic` → `InstanceBody` (RootView.swift:22, ObjectPage.swift:39).
- `InstanceBody` lists every field except `notes` (ObjectPage.swift:348). For a note, that includes **body** (shown in full, :397-416) and "Private: yes".
- The path needs a deliberate "@Private note", so it's rare. The result is the whole private text on screen.
- Fix, one or both:
  - have `resolve` skip objects with `isPrivate == true`;
  - have ObjectPage route a note to NoteEditor (or drop `body` from InstanceBody for a private note).
- Owner: Core for `resolve`, Builder B for ObjectPage. Not a blocker for this PR.

## What he sees (for Design)
- **Notes index:** a private note's row is one line, "Private note", with its time. No second line.
