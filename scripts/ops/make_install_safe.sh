#!/usr/bin/env bash
# Writes the guarded phone installer for one gated Release into its build folder.
# Usage: scripts/ops/make_install_safe.sh <build-folder> <full-sha>
#   <build-folder> holds gate.log, gate.exit, release.log, release.exit and app.path for that exact SHA.
# The installer it writes: verifies the green gate, the Release build, the build stamp and the signature offline;
# with --install it also needs the exact-SHA approval record (coordinator-step0-exception.json, written by the
# coordinator, never by this script), takes the device lock, checks the phone is connected and paired with developer
# mode on, and installs in place (no uninstall, phone data kept). Its own variables are all INSTALL_*, so nothing it
# exports can collide with mac_lanes.sh (which keeps its own ROOT); no MAC_LANES_ROOT override is needed.
set -euo pipefail
DIR="${1:?build folder}"
FULL="${2:?full sha}"
[[ "$FULL" =~ ^[0-9a-f]{40}$ ]] || { echo 'the second argument must be the full 40-character sha' >&2; exit 2; }
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sed -e "s/@FULL_SHA@/$FULL/g" -e "s/@SHA8@/${FULL:0:8}/g" -e "s|@MAC_LANES@|$HERE/mac_lanes.sh|g" > "$DIR/install-safe.sh" <<'TEMPLATE'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SHA=@FULL_SHA@
INSTALL_SHA8=@SHA8@
INSTALL_BUNDLE=com.kaushikaranagu.tessera
INSTALL_DEVICE=00008150-000A7C1C2E78C01C
INSTALL_APPROVAL="$INSTALL_DIR/coordinator-step0-exception.json"
INSTALL_LANES=@MAC_LANES@
export INSTALL_DIR INSTALL_SHA INSTALL_SHA8 INSTALL_BUNDLE INSTALL_DEVICE INSTALL_APPROVAL

verify_approval() {
    [[ -f "$INSTALL_APPROVAL" ]] || { echo 'REFUSED: exact-SHA coordinator-recorded user approval is absent' >&2; exit 20; }
    python3 - <<'PY'
import json, os
from pathlib import Path
p = json.loads(Path(os.environ['INSTALL_APPROVAL']).read_text())
assert p['sha'] == os.environ['INSTALL_SHA']
assert p['approvedBy'] == 'user' and p['recordedBy'] == 'coordinator'
assert p['exception'] == 'skip-raw-step0-copy-retain-phone-container'
assert p['noNewMacBackup'] is True
assert p['userApprovalQuote'].strip() and p['approvedAt'].strip()
PY
}

verify_offline() {
    python3 - <<'PY'
import os, plistlib, subprocess
from pathlib import Path
d = Path(os.environ['INSTALL_DIR']); sha8 = os.environ['INSTALL_SHA8']; bundle = os.environ['INSTALL_BUNDLE']
assert (d / 'gate.exit').read_text().strip() == '0'
assert '==> All green' in (d / 'gate.log').read_text().splitlines()
assert '** BUILD SUCCEEDED **' in (d / 'release.log').read_text()
assert (d / 'release.exit').read_text().strip() == '0'
app = Path((d / 'app.path').read_text().strip()).resolve()
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == bundle
assert info['TesseraBuildSHA'] == sha8
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
sign = subprocess.run(['codesign', '-d', '--verbose=4', str(app)], capture_output=True, text=True, check=True).stderr
assert 'Identifier=' + bundle in sign
assert 'TeamIdentifier=WMP2WF3P54' in sign
identity = next(x for x in sign.splitlines() if x.startswith('CDHash='))
pin = d / 'install-artifact.cdhash'
if pin.exists():
    assert pin.read_text().strip() == identity
else:
    pin.write_text(identity + '\n')
print('Offline verified: green gate, Release, stamp ' + sha8 + ' and ' + identity)
PY
}
export -f verify_approval verify_offline

verify_offline
if [[ "${1:-}" != '--install' ]]; then
    echo 'Offline verification only. Phone install requires the exact-SHA approval record and --install.'
    exit 0
fi
verify_approval
MAC_LANES_SLOTS=2 "$INSTALL_LANES" device installer -- bash -c '
    set -euo pipefail
    verify_approval
    verify_offline
    readiness="$(mktemp)"
    trap '\''rm -f "$readiness"'\'' EXIT
    xcrun devicectl device info details --device "$INSTALL_DEVICE" --json-output "$readiness" >/dev/null
    python3 - "$readiness" <<"PY"
import json, sys
p = json.load(open(sys.argv[1]))
assert p["info"]["outcome"] == "success"
d = p["result"]; c = d["properties"]["connection"]
assert c["state"] == "connected" and c["pairingState"] == "paired"
assert d["deviceProperties"]["developerModeStatus"] == "enabled"
PY
    verify_approval
    xcrun devicectl device install app --device "$INSTALL_DEVICE" "$(cat "$INSTALL_DIR/app.path")"
' > "$INSTALL_DIR/install.log" 2>&1
printf 'Installed %s at %s\n' "$INSTALL_SHA" "$(TZ=America/Los_Angeles date '+%Y-%m-%d %H:%M:%S %Z')" > "$INSTALL_DIR/install.receipt"
TEMPLATE
chmod +x "$DIR/install-safe.sh"
echo "wrote $DIR/install-safe.sh"
