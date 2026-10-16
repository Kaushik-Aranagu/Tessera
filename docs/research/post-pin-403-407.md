# Post-pin merge read: #403 (Tess eyes) and #407 (Catalog v10, tessEyes)

*Research, item AC, Oct 16 (read after 1:00 pm PT). Read-only: test merges in throwaway worktrees, nothing built.*
Master at ec47bd3 (#490). The pin SHA is not yet recorded in `docs/product/pin-checklist.md` section 3; #366 is merged (6047078).

- **#403** (3 commits, base dbc2557 = #402, 9:11 am PT; 246 master commits behind): 9c95408 eyes, off by default; 3099412 E1 one scale, workout look; c053fc7 E2 Done fade, 60 fps. 10 files, +286/-4 (2 clips).
- **#407** (2 commits, base 5af8f2c = #422, 10:52 am PT): 50d4bc4 tessEyes setting; 8f9b6cb catalog v10. 3 files, +47/-1.

## Test merges
| Merge | Result |
|---|---|
| #403 onto master | CONFLICT: `Features/Command/BottomChrome.swift` (soulKey: master's `hostScale: 0.72` vs `eyes:, gaze:`), `Features/Tess/TessSoul.swift` (3 hunks: #453's `hostScale`/`work`/`lowPower` state vs `eyes`/`gaze`/`eyesShown`; `onChange(of: mode)` `now` vs `old`; master's `frame(at:)` vs `eyesLayer`). SoulRouter, AppModel, workout files auto-merge. |
| #407 onto master | CONFLICT: `SystemCatalog.swift:350`, #475 made `package` `nonisolated`; keep `nonisolated` and `version: 10`. |
| #407 onto #403 head | Clean (no shared files). On master the conflict set is the union of the two rows above. |

## #403 Tess eyes
| Check | Result | file:line (pr403) | Fix | Owner |
|---|---|---|---|---|
| Default off | PASS. `eyes = false`; only the simulator `-tessEyes` flag turns them on | App/AppModel.swift:98, TessSoul.swift:35 | After #407, read `settings.showsTessEyes` instead of the flag | Builder A |
| Launch flag simulator-only, no raw ProcessInfo | PASS. `LaunchFlags.has`; master's `isLowPowerModeEnabled` read is not a launch arg | AppModel.swift:99 | None | |
| Soul rules | PASS. `gaze` and `isLookingAtLine` live in SoulRouter, set from `.lineShown`; views only pass `model.soul.gaze` | SoulRouter.swift:51-59, 110-117 | None | |
| `.backgrounded` now `settle(rest)` (QA L6) | Auto-merges over master's `timer?.cancel()`; changes behavior for #453's working mode too (backgrounding mid-ask gathers her) | SoulRouter.swift:167 | Re-run SoulRouter and working tests after the merge | Builder A |
| MotionPolicy | FAIL. Raw `withAnimation` for the Done fade, raw `.animation(.spring)` for the glance | TessSoul.swift:80, 82; SoulEyes.swift:142 | `withTesseraAnimation` / `.tesseraAnimation` | Builder A |
| Reduce Motion | PASS. Dots still, blink kept at 30 fps, glance off | SoulEyes.swift:116-142, TessSoul.swift:97 | None | |
| Working overlay (#453) | Eyes read the ungraded frame, so they will not follow the split/gather or `hostScale` | TessSoul.swift:97-105 vs master `frame(at:)` | Resolve: eyes take `frame(at:).frame`, scaled by `hostScale`; hide eyes while `work != nil` or ask Design | Builder A |
| VoiceOver | PASS. Eyes `accessibilityHidden(true)`; soul label unchanged | SoulEyes.swift:144 | None | |
| Tests | 5 Swift Testing tests (blink cadence, gaze, eye centre, no mid-blink wrap, glance size); no UITest, so no SimulatorOnlyTestCase needed | TesseraTests/SoulEyesTests.swift | Add a working-mode eye test after the resolve | Builder A |
| Mouth (idea 12) | Not in this PR (pick sheet 18c, later) | | Builds as `SoulMouth` under the same setting | Builder A |

## #407 Catalog v10, tessEyes
| Check | Result | file:line (pr407) | Fix | Owner |
|---|---|---|---|---|
| Version is next number | PASS. 9 to 10 exactly; master is 9 at SystemCatalog.swift:350, nothing at v10 | SystemCatalog.swift:352 | Keep `nonisolated` in the resolve | Core |
| Additive only | PASS. One optional `.bool` field on Settings, no GRDB migration, no rename or drop | SystemCatalog.swift:246 | None | |
| Default off | PASS. nil means no, `showsTessEyes` = `tessEyes ?? false` | TesseraSettings.swift:27, 43 | None | |
| Older build (pin) opens a v10 store | Refused by #475 (76be1c0, on master): `isNewer` sees classDef `packageVersion` 10 > 9, store left untouched, session in memory, note "Your data is from a newer Tessera, so I left it untouched. Update the app to open it; ..." | master TesseraSchema.swift:51-56 | Holds only if the pin includes 76be1c0 | Core |
| v10 backup restored on the pin | Refused: "That copy is from a newer Tessera. Update first." | master TesseraBackup.swift:210, BackupView.swift:257 | None | |
| M1: daily backup in the fallback | OPEN on master. `BackupKeeper.runDaily` runs on background even after the in-memory fallback, so a v10 to pin rollback can write empty-store copies over his good ones | master TesseraApp.swift:81-83, BackupKeeper.swift:79 | Skip `runDaily` when `lastOpenOutcome == .inMemoryFallback`, plus a test; must be in the pin | Core |
| Tests | PASS. Off until on, one op and UNDO, old backup decodes, older field set ignores the key, v8 reseed keeps the value | SettingsTests.swift:200 | Add a v10 store opened by v9 code test (catalog stamped 11 vs 10) | Core |
| Key name | `tessEyes` here and in Design 70; `docs/design/motion/tess-motion-build.md:15` says `tess.eyes` | | Fix the build doc | Research |

## Merge order
1. Name the pin (checklist section 3) with #475 and M1 in it; it goes on his phone and the v9 gate passes.
2. #403 (Builder A rebases on master, resolves the 2 files, MotionPolicy fix, re-run tests). No catalog change, so it is safe on any store.
3. #407 (Core rebases, keeps `nonisolated`), only after step 1 is on his phone.
4. Then a small Builder A PR swaps `LaunchFlags.has("-tessEyes")` for `showsTessEyes`, and Builder B adds Design 70's row.

## Before #407 merges
- [ ] Pin SHA named in pin-checklist.md and decisions.md, Catalog v9 at the pin.
- [ ] Pin contains 76be1c0 (#475, B5/B6) and the M1 fix; pin installed on his phone.
- [ ] v9 gate on a device: older build opens v9, v5 upgrade, 366 rows identical, timed v5 restore.
- [ ] On a device: v10 store opened by the pin shows the launch note, writes nothing, and no daily copy is written.
- [ ] On a device: a v10 backup restored on the pin reads "That copy is from a newer Tessera. Update first."
- [ ] Rebased head re-checked by QA; still exactly v10 (nothing else took 10 first).

## Questions for Product
1. Where does "Tess has eyes" live? Design 70 (c5d6e7b, only on branch `claude/project-thread-b3tu3f`, not on master) puts it as LOOK's third sentence, not Review or Claude; tess-motion.md:26 says "under Tess". Confirm LOOK.
2. During the working overlay (#453), should the eyes ride the split lights, or fade out as at Done?
3. Should #403's `.backgrounded` settle change ride with #403, or go as its own small fix since it changes working mode?
4. Is "older build on newer store" now fully covered by #475, or does the pin still need the v7 floor test re-run?
