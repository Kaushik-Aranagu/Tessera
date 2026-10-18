# Changing a pinned line on purpose (premerge guard)

`scripts/ops/premerge_check.py` stops any docs or scripts PR that changes a line matching `PIN` or `only SHA`. That stays the rule. A product ruling can change one such line only through this path, and only for lines that are not install-pin or release lines.

## What a PR needs
1. A decisions entry already on the base branch (`docs/product/decisions.md` on master, never added by the same PR). It is a bullet starting `- <stamp>` (for example `- 11:33 AM PT Oct 18 (Product, ...)`) that names the exact file and the OLD line number of the line it changes, written `file-name.md:67`.
2. One line in the PR body per removed pinned line: `PIN-CHANGE: <stamp> | <path>:<old line number>`.
3. Run: `git diff --unified=0 --no-color BASE...HEAD | python3 -B -I scripts/ops/premerge_check.py --pr-body <file with the PR body> --decisions <decisions.md as on the base branch>`.

## What the guard checks
- Each removed pinned line has its own `PIN-CHANGE` line, and the named entry exists with that stamp and names that file and that old line. A body that only cites an entry is not enough; a missing entry, a wrong file or a wrong line stays STOP.
- Lines mentioning install, release, signing, profile, SHA or a hex id of 7 or more characters can never be ruled, and neither can a replacement that adds such text. Files named with pin, release, install, signing or profile are never ruled. The stamp must be the full shape `H:MM AM PT Mon D`.
- The PR may not add more pinned lines than it removes; every other pinned line must stay byte-identical.
- A ruled change prints `REPORT <path>:<old line> pin: changed on purpose under decisions entry '<stamp>' naming <file>:<line>; QA confirm`. QA copies that line into the verdict. Without the two inputs the guard behaves as before.
- Removing a pinned line with no replacement is not covered by this path and is unchanged.

Tests: `python3 -B -I scripts/ops/test_premerge_pin.py`. The decisions entry must be mirrored into the repo before the PR opens (the repo copy lags the project file).
