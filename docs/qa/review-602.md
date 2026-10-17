# QA review: #602 Builder A, launch flags only through LaunchFlags (DATA SAFETY)

Head 2c38ade. Static. Merge-tree clean. Three files, 5 lines.

- AppClock.configure() and Theme.configure() drop their `arguments: ProcessInfo...` default and read through `LaunchFlags.value(after:)`, which returns nil unless `targetEnvironment(simulator)`. No caller passes arguments (grep: TesseraApp.swift:18-19 only).
- DemoData.swift:19 `-resetDemo` now `LaunchFlags.has(..., in: arguments)`; the guard above it is still `allowed, LaunchFlags.allowed`, so off the simulator nothing runs.
- Sweep of master+PR for raw reads in app code: only LaunchFlags.swift:18/25 (the gate itself), DemoData.swift:14 (the known default, still gated), TessSoul.swift:95 (isLowPowerModeEnabled, unrelated). Remaining ProcessInfo/CommandLine are in tests and tools/storage-spike (not app). The audit item Theme.swift:282 is closed; AppClock:18 is closed too, so the exception list can shrink to DemoData:14 alone.
- Every `-flag` in app code goes through LaunchFlags.has/value (about 35 sites, checked by grep). LaunchFlagsTests unchanged and still apply.

Verdict: PASS at 2c38ade. Suggest H8's allow list in the D1 lint is now just LaunchFlags.swift and DemoData.swift:14.
