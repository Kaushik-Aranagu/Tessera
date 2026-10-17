# #710 delta 5d7cef0c (Core)

Static. PrivateWords.isPrivateTitle now also calls EngineWall.isHealth(title, lastWeightKg:) (case-insensitive medicine words or body-shaped), so bare "lexapro", "take melatonin", "advil" mask. Fed to the history scan too (wordyTitle -> isPrivateTitle), so renamed-away titles are caught.

Tests: shared `secrets` gains lexapro, advil, melatonin; the fixture adds two list items and AddGroceries("advil"). `secrets` is used by the export, default export, local backup (keeps every word), iCloud copy and rolled-blob tests; the raw-bytes test (main, -wal, -shm) gets the same three words. Test count is unchanged because assertions were added to existing tests.

PASS. Low L1: AddGroceries titles the ingredient "Advil" (capitalized, Ingredients.swift:36), and every absence check is case-sensitive, so the grocery row does not prove its mask; the lexapro and melatonin list items do. Add "Advil" to the words lists.
