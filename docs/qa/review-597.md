# QA review: #597 Builder B 0r, a note opens in NoteEditor only when it is not private

Head d25e88d. Static. Privacy-relevant, reviewed at full depth. Merge-tree clean on master. Two files: ObjectPage.swift (+10), PrivateNoteObjectTests.swift (new).

## What it does
ObjectPage body: `.object(id)` whose record is exactly the Note class and `ObjectPrivacy.label(...) == nil` opens `NoteEditor(noteID:)`; everything else stays on `generic` (Core's #580 mask).

## Checks
- Every private path stays masked: the guard is the same predicate the mask uses (stored isPrivate flag, "Private note" title, SecretWords or PrivateFacts in title or body), so editor and mask cannot disagree on what is private. A walled word in the body alone is also masked.
- Other ways into NoteEditor: NotesView.swift:17 only (the owner's Notes list, by design, unchanged). Linked from rows, refs and ObjectHandle all route `.object(id)` through ObjectPage, so they get the editor only for plain notes. No new route to a private note's words.
- Subclass of Note: the check is the exact class id, so a subclass goes to generic, which masks it by the isA(.note) label. Safe direction.
- No Catalog, migration, flag or copy change; no key-shaped text. Tests: private note stays masked with label "Private note", plain note opens as note.

## Findings (none blocking)
- L1 (UX, privacy-safe): the decision is recomputed on every body pass. A plain note opened from the object page that the user then edits to contain a walled word (a wifi password, "locker 4417", a weight) autosaves, the label turns non-nil, and ObjectPage swaps the editor for the masked page while the user is typing. NoteEditor saves on disappear (NoteEditor.swift:130), so no text is lost, but the keyboard and cursor vanish mid-sentence. Suggest latching the choice once per appearance (a @State set on first evaluation), or leave it and board it; the Notes list path is unaffected.
- L2 (test gap): tests cover flag-private and plain only. Add a plain note whose body alone has a walled word (expect not opensAsNote) and a Note subclass if one exists.

Verdict: PASS at d25e88d. L1 and L2 carried.
