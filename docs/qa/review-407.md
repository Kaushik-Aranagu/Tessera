# QA review: #407 Core tessEyes setting (Catalog v9)

Head `9a01a44`. Trial merge is clean. Three files: SystemCatalog.swift, TesseraSettings.swift, SettingsTests.swift. This is a static review.

## Verdict: PASS (additive; the rollback is safe in code, and the gate should cover v9 if the pin carries it)

- **Additive.** One `FieldSpec` row is added on Settings (`tessEyes`, `.bool`, SystemCatalog.swift:242-243), and the package goes 8 → 9. There is no GRDB schema change and no new class. Seeding adds missing fields to existing classes and never removes any (SystemCatalog.swift:388-421). `TesseraSettings.tessEyes: Bool?` decodes as nil from old payloads, and `showsTessEyes` defaults to false.
- **Rollback, traced in code.** A v8 build opening a v9 store doesn't refresh: `needsRefresh` is `packageVersion < package.version`, which is false for a store at 9. The v9 field row stays in place, untouched. v8's `SettingsStore.read()` never reads `tessEyes`. v8's `WriteSettings` writes only the fields it knows, so the stored value survives a write on the older build. This is the same shape as v6, v7 and v8: one field on an existing class.
- Tests: an old payload decodes as nil; an older decoder ignores the key; a store at v8 reseeded at v9 keeps the value; UNDO of the toggle takes the value back. These are decoder-level and in-package checks. No older build was opened over a v9 store.
- **Pin.** The rollback rule says an older build opening a newer store has been shown safe through v7, with v8 to be shown by M4. If Product's next pin carries v9, Builder A's M4 rerun should be over the v9 master, not v8. It's the same run; nothing is added.
- Nothing reads the setting in the app yet. #403's `tessHasEyes` is still LaunchFlags-only, so merging this changes nothing on the phone.
