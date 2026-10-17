# Review #726 at 171fdbfe (Builder B, B6 EXPORT row and masked-restore warning)

Static. Merges clean; new ExportRow.swift (ExportFile, MaskedRestoreWarning, ExportRow), ExportFileTests, and 6 lines in BackupView.

- Flag: `ExportFile.ready` is `static let false`, and the only reference to ExportRow in the app is the `if ExportFile.ready` in BackupView (grep: no other use, no other entry such as a menu, Settings row or Shortcut). With it false the row, its hint and its line do not exist. A test pins it false.
- Restore: nothing calls `restoreStep` or `MaskedRestoreWarning` yet, and no Features/Backup path restores a JSON file today (Backups restore .tessera stores). So today there is no export file to restore and no path that could skip the warning; the helpers are inert. `isMasked` reads a top-level `masked: true`; Core's TesseraExport writes no `masked` key yet (it masks by `maskingPrivate`).
- Safe on the data side: no write, no launch path, no migration. Strings: no ellipsis, no em dash, no "at"; labelWord buttons.

PASS. M1 (for the flip PR, not this one): the PR that sets `ready = true` must (a) have Core write `masked: true` into the export, (b) route any JSON restore through `restoreStep` before it replaces anything, with a test that a masked file reaches `.warn` at the call site, and (c) change the test pinning `ready` false. Low: a hand-edited masked file with the key removed restores without the warning (the restore already keeps the before-restore copy, G26).
