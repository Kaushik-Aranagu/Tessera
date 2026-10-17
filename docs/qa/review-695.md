# Review #695 (head 183966af): PASS (static; app build waits for the simulator)
- Both prune/rotate filters (newest-copy scan and the keep-N pass) now use isRollingName (prefix "Tessera-", suffix ".tessera"); the saved-copy name "Before update <day>.tessera" fails the prefix, so it can't be pruned or counted. The `old != file` guard and the clockBehind guard are untouched.
- Test: 8 rolling days + a saved copy: oldest rolling day goes, 7 remain, saved copy stays; name checks incl. ".zip".
- M1, key/bookmark/flags: not touched by the diff (no change to the in-memory guard or the payload). App line only changes the export file name.
- Lows: an old-style saved copy already named "Tessera-<day>.tessera" in the Backups folder is still prunable; a saved copy a user renames to start with "Tessera-" is too.
