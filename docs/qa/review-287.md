# QA review 287: grammar fixes, router follow-ups, backups, settings migration (#287)

PR head f7bc487 on base 41db721; 16 files (+472/-144). Static review; no toolchain here. No deletions or reverts against the base. No raw `ProcessInfo` argument reads and no key material in the diff.

**Verdict: PASS and install-safe, with one should-fix (F2).** The three install checks:
1. **Weightless "bench 3x8" never writes 3 kg. Yes for barbells, no for machines and cables (F2).**
2. **R3 blocks Siri and Shortcuts before any request. Yes.**
3. **The migrate call and the backup/trash changes are data-safe on a device. Yes.**

## 1. Weightless N×M (QA F1 on #282)
- "bench 3 sets of 8" asks "Bench 3 × 8 at what weight?". "bench 3 sets of 8 at 80" logs 3×8 at 80. "dips 3 sets of 10" logs at bodyweight (TessGrammar+Lift.swift:11-16, :50-53; tests F1a-F1d).
- "bench 3x8" with nothing in focus asks. With Bench in focus it logs 3 sets at the last weight, per Research (:40-49; tested at 80 kg).
- **F2 (should-fix): the guard is `first < lightest detent`, and for machines, cables and the default kit the lightest detent is 0.**
  - `FixedLoads(step: 5)` strides from 0 (LoadProfile.swift:69, :102-106), so `detents.first` is 0 and `3 < 0` is false.
  - So "lat pulldown 3x8", "cable row 3x8" and "leg press 3x8" still log a 3 kg set. Dumbbells start at 2, so "curls 3x8" logs 3 kg and "db curl 4x10" logs 4 kg.
  - The "at 7 is a time" guard (:59-62) has the same hole on machines.
  - **Fix:** use the lightest load above zero, `detents.first { $0 > 0 }`, in both places. For dumbbells and kettlebells, also ask when N ≤ 6 and there's no last weight, the same threshold as Product's Q8. Add rows for a machine, a cable and a dumbbell lift.
  - Not data-unsafe: it's one visible set with a receipt and UNDO. But it's the same wrong write F1 was about.

## 2. Router follow-ups (review-283)
- **R3:** `guard !request.context.commitImmediately, let key = keys.read() else { return .missed }` is the first line of `run()` (ClaudeTessModel.swift:49). No reserve, no request and no ledger row happen first. Tool calls are now always `pending: true` (:84), so even a future caller can't commit Claude's writes. Tested by `siriAndShortcutsNeverReachClaude`, which checks that no requests are sent. **Closed.**
- **R1:** `send` turns every non-answer into a `Failure`: bad tool definitions, bad body JSON, cancellation (:202-217). A billed 200 with no content carries its usage (:232-234). The single catch adds `failure.used` and writes the row (:100-108). Tested: three failed calls write three rows and the 900/5 tokens count. **Closed.**
- **Estimate:** it now includes the system prompt and tool definitions, per round (:52-54). **Closed.**
- **L1:** `max_tokens` and `refusal` throw `.other`, which gives "Didn't catch that." with no ghosts and a ledger row (:74-77; tested). **Closed.**
- **Error text:** tool errors return fixed lines (:91-95; tested). **Closed.**

## 3. Data safety on a device
- **SettingsStore.migrate at launch (AppModel.swift:94-99):**
  - The demo guard reads `LaunchFlags.has` only. On a device those are always false, so migrate runs, as intended.
  - It runs after `prepareCatalog`, so the settings class exists. It's `try?`, so it never crashes a launch.
  - It writes as `.system`, and settings ops never count toward the rolling copy.
  - It only fills empty fields. `update` writes nothing when nothing changed, so later launches write no ops.
  - It only adds a settings object; nothing else is touched.
- **M1 (low, for Builder B's SettingsStore wiring):** migrate runs on every launch, not once. Its "no wins" rule ratchets: if `tess.missesGoToClaude` was ever false, the object stays false even after he flips the switch back to yes. ClaudeSection still writes only the UserDefaults key (ClaudeSection.swift:59). The same goes for looks: once filled, the object never follows later look changes. That's harmless today because nothing reads the object yet. Once Builder B moves reads to the object, either move the writes in the same PR or gate migrate with a one-time flag.
- **G2:** `isDamaged` now returns false for anything that isn't a SQLite corruption code (TesseraSchema.swift:77-80). A bug in our own code now runs from memory with the "Your history is untouched" note, instead of moving the store aside. That's strictly safer. Tested.
- **B9:** a bookmark that resolves into `.Trash`, `.Trashes` or Recently Deleted counts as no folder. It shows as a folder failure, so Backups doesn't look safe (BackupKeeper.swift:27-32, :110). No write ever goes there.
- **B10:** a newest copy more than 2 days in the future no longer counts as a clock running behind (TesseraBackup.swift:132-134). Pruning still never deletes the day's copy with fewer ops, so this can't lose a good copy.
- **T11:** `defaults` and `resolve` are injection points for tests only. The app keeps `.standard` and the real resolver.

## Lows
- **L2:** `tidyNotes` returns the UNDO record for "Push A, no sets, not saved.", but AppModel.swift:290 still calls `tidy`, so the app shows the line with no UNDO yet. Builder A or B needs to wire it.
- **L3:** the new wake-word rule keeps "Tess" when a transcript has no comma. "Tess 80 for 8" reaches the grammar as "tess 80 for 8", which matches no exercise, so it becomes a miss. "Okay Tess 80 for 8" still works. Speech transcripts often drop the comma, so allow `tess\s+` when a number follows.
