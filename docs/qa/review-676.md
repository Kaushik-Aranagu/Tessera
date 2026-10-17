# Review #676 (Core 0ak: SideFacts, the three leak must-fixes)

Head e902f755, merge-tree clean against master 86675392. Engine-only: one new file (SideFacts.swift) and its tests. Nothing calls it yet, so no screen change. Design not needed.

**Verdict: QA PASS.**

## Checked
- **PL1** `setupLines`: splits the notes into trimmed non-empty lines and keeps only those that pass `isShowable` (no secret word, no key shape, not money- or body-shaped via PrivateFacts). Returns what was kept private as a count and "N line(s) kept private". The test row ("left knee sore, locker code 4471" and "wifi is tacocat" taken out; "Handles at 4" and "Seat at 3" kept) traces: "sore" is a symptom and "code" and "wifi" are secret words.
- **PL2** `defaultFields`: nil for a private note, task or memory (ObjectPrivacy.label), a "Private note" title, or an `isPrivate` object; otherwise every field with a value, minus `hidden`, `notes` and `isPrivate`, and any value that fails `isShowable`. A workout's notes are never printed (notes are always excluded). The test covers a note made private by its words (rent 2100) and a task whose notes hold a door code.
- **PL3** `classGlance`: private objects count and show as "N private"; the newest shows its private label, never a private title; the most used is chosen among non-private objects only, ties broken by id, undone edits skipped, deleted objects excluded from the count.
- Every pass-through uses the shared predicates, so tightening PrivateFacts or SecretWords tightens the side too.

## Lows
1. `defaultFields` judges a field's value alone ("2100", "70"), not its name. A numeric field named "Rent" on a user class prints. The front would show it too, and sides stay on the phone, so this is not a leak against the front; judging "\(field.name) \(text)" would make it stricter. Optional.
2. The test's last loop (every catalog class, every seeded object) is circular: it asserts the same predicate on the same values, and a fresh store holds no user data. Fine as a smoke test, not as evidence.
3. `describe`: a `.date` prints only a clock ("3 pm") and loses the day; a `.duration` under 60 s prints "0 min"; a `.mass` prints no unit. Cosmetic, for whoever builds the SideHost.
4. When SideHost lands (0ak), re-check that it reads only these functions (no raw notes, fields or class members), per the file's own header.
