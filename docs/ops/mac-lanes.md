# Mac lanes: parallel builds and tests on the one Mac

`lane_lock.sh` hands the Mac to one lane at a time. That is safe but slow, and in practice lanes ignore it for package
tests, so the Mac ends up oversubscribed anyway (Oct 24: 10 cores, 24 GB RAM, load average 170, 8 GB of disk free).
`scripts/ops/mac_lanes.sh` replaces the single lock for heavy jobs with a small number of slots, and gives each slot its own
private build folders so concurrent runs cannot collide.

## What a slot is

- At most `MAC_LANES_SLOTS` (default **3**) heavy jobs run at once: `xcodebuild test`, `swift test`, UI tests. Size by memory,
  not cores: about 6 to 8 GB per run, so 24 GB holds three with room for the system.
- Slot `N` has its own `$LANE_DERIVED` (`-derivedDataPath`), its own `$LANE_SPM` (`-clonedSourcePackagesDirPath`), and, with
  `--sim`, its own simulator `$LANE_SIM`, a clone of the base device named `Tessera Lane N` (`xcrun simctl clone`). Pass it as
  `-destination "id=$LANE_SIM"`. Run each lane in its own git worktree.
- Waiting is first come, first served. A hold is freed when its pid is dead, it is older than 2 h, or it has had no
  heartbeat for 10 minutes (same rules as `lane_lock.sh`). A simulator job does not start while the screen is locked.
- It refuses to start (exit 3) when the data disk has less than `MAC_LANES_MIN_GB` (default 6) free. Free build folders first.
- Never `pkill` by pattern. The script stops only the process tree of the job it started.

## Use

```sh
# package tests: a slot, no simulator
scripts/ops/mac_lanes.sh run core-ai "swift test #1394" -- sh -c 'cd TesseraCore && swift test'

# app and UI tests: a slot, its own simulator and DerivedData
scripts/ops/mac_lanes.sh run ios-a "UI tests" --sim -- sh -c \
  'xcodebuild -scheme TesseraUITests -destination "id=$LANE_SIM" -derivedDataPath "$LANE_DERIVED" \
   -clonedSourcePackagesDirPath "$LANE_SPM" -parallel-testing-enabled YES test'

# putting the app on the phone: one install at a time
scripts/ops/mac_lanes.sh device ios-a -- xcodebuild ... install

scripts/ops/mac_lanes.sh status     # the slots, the device lock, free disk
scripts/ops/mac_lanes.sh sim 2      # prints (and creates) slot 2's simulator id
```

`scripts/ops/test_mac_lanes.sh` is the self-test (no Xcode, no simulator).

## With lane_lock.sh

`lane_lock.sh` is unchanged. A lane that still takes it serialises against other `lane_lock` users, but not against slot
jobs, which use their own simulators and folders. Move to slots as lanes are ready; the old lock then only guards the shared
default simulator.

## Disk

A debug `swift test` build is about 1 GB per worktree and a DerivedData folder several GB, so a dozen idle worktrees fill the
disk. Delete `.build` and DerivedData of finished worktrees; both regenerate.
