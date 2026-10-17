# Lane lock for the shared Mac

Several lanes share one Mac, one iOS simulator and one Xcode. Two concurrent `xcodebuild` runs on the same DerivedData, or two lanes driving the same simulator, corrupt each other. A lane takes the lock before any simulator use or Xcode build and releases it after.

## Convention

- **Lock**: the directory `/tmp/tessera-mac-lock.d` on the Mac (`mkdir` is atomic, so only one lane wins). Override with `LOCKDIR` only for testing.
- **Content** (file `info` inside it, `key=value` lines): `lane` (lane name), `pid` (the holder's long-lived shell pid), `start` (epoch seconds), `start_iso` (UTC), `purpose` (short text, e.g. `app tests for PR 312`).
- **Stale after 2 hours** (7200 s), or when the pid is no longer alive. A stale lock may be taken over by the next lane; the helper says so when it does.
- **Package-only runs** (`swift test` in `TesseraCore/`, no simulator, no Xcode) do not need the lock.
- **Never `pkill`/`killall` by pattern** (xcodebuild, Simulator, Xcode, swift). That kills other lanes' work. Kill only a pid you started and recorded yourself. If the lock holder looks hung, ask that lane or the coordinator; do not kill it.
- Always release in the same shell that acquired (`trap '...lane_lock.sh release <lane>' EXIT`). Release only works for the lane named in the lock.

## Helper

`scripts/ops/lane_lock.sh`, POSIX sh:

```sh
scripts/ops/lane_lock.sh acquire <lane> "<purpose>"   # exit 0 acquired, 1 busy
scripts/ops/lane_lock.sh release <lane>               # exit 1 if not held by that lane
scripts/ops/lane_lock.sh status                       # prints the lock content and age_s, or "free"
```

Typical use:

```sh
scripts/ops/lane_lock.sh acquire ios-a "app tests" || exit 1
trap 'scripts/ops/lane_lock.sh release ios-a' EXIT
scripts/test.sh --app-only
```

The recorded pid is the helper's parent (`$PPID`), so call the helper directly from the long-lived shell, not through a throwaway `sh -c`, or the lock looks dead immediately and is taken over.
