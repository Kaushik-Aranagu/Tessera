# Review #730 at f704e3b6 (Builder B, B7 SAVE A COPY gate)

Static. Merges clean; BackupKeeper, BackupView, SaveCopyGateTests.

- No path reaches the share sheet without the gate: `saving = BackupFile(...)` (the only thing the `.fileExporter` presents) is set at one place, the `.copy` case of `savedCopy`; `copyForSaving` is called only from `savedCopy`, after the gate. `TesseraBackup.savedCopyGate` returns requiresAuth true always (the line only changes with private words), so every saved copy goes passcode then Face ID. Local rolling backups and the iCloud copy use `TesseraBackup.write` and never come here.
- Order is right: `hasPasscode` first (nothing built, Face ID never asked), then `authenticate`, then the copy. `.declined` returns silently; `.needsPasscode` says the one line. `hasPasscode` is `LAContext.canEvaluatePolicy(.deviceOwnerAuthentication)`, false only with no passcode (true under biometric lockout, where the passcode fallback still works).
- Injection: `hasPasscode` and `authenticate` are internal static vars, assigned only in SaveCopyGateTests (grep: no other assignment), each test restores in a defer; the suite is `.serialized`. Same pattern as the #710 authenticate.
- Tests: the store holds a plain note, and since the gate always requires auth all three cases hit the gate (needsPasscode with `asked` false, declined, copy exists).

PASS. Lows: L1 the no-passcode line says "this copy has your private words" even when the store holds none (the gate always asks); Product may want the line only when `gate.line != nil`, else "Set a passcode first." L2 the three-case test covers a store without private words only; add one with a private note to prove the `.copy` line is carried.
