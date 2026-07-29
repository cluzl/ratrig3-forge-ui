#!/usr/bin/env bash
set -Eeuo pipefail

REPO="cluzl/ratrig3-forge-ui"
TARGET="${FORGE_UI_TARGET:-$HOME/mainsail}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/forge-ui.XXXXXX")"
STAGE="${TARGET}.forge-new"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${TARGET}.backup-${STAMP}"

cleanup() {
    rm -rf "$TMP" "$STAGE"
}
trap cleanup EXIT

for command in tar; do
    command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done

if command -v curl >/dev/null; then
    fetch() { curl -fL --retry 3 --connect-timeout 15 "$1" -o "$2"; }
elif command -v wget >/dev/null; then
    fetch() { wget -q --tries=3 -O "$2" "$1"; }
else
    echo "Install curl or wget first." >&2
    exit 1
fi

BASE="https://github.com/${REPO}/releases/latest/download"
fetch "$BASE/forge-ui.tar.gz" "$TMP/forge-ui.tar.gz"
fetch "$BASE/forge-ui.tar.gz.sha256" "$TMP/forge-ui.tar.gz.sha256"

EXPECTED="$(cut -d ' ' -f 1 "$TMP/forge-ui.tar.gz.sha256")"
if command -v sha256sum >/dev/null; then
    ACTUAL="$(sha256sum "$TMP/forge-ui.tar.gz" | cut -d ' ' -f 1)"
elif command -v shasum >/dev/null; then
    ACTUAL="$(shasum -a 256 "$TMP/forge-ui.tar.gz" | cut -d ' ' -f 1)"
else
    echo "Missing sha256sum or shasum." >&2
    exit 1
fi
[ "$EXPECTED" = "$ACTUAL" ] || { echo "Checksum verification failed." >&2; exit 1; }

mkdir -p "$STAGE"
tar -xzf "$TMP/forge-ui.tar.gz" -C "$STAGE"
[ -f "$STAGE/index.html" ] && [ -d "$STAGE/assets" ] || { echo "Invalid FORGE UI archive." >&2; exit 1; }

if [ -d "$TARGET" ]; then
    [ -f "$TARGET/config.json" ] && cp -a "$TARGET/config.json" "$STAGE/config.json"
    [ -d "$TARGET/oe" ] && cp -a "$TARGET/oe" "$STAGE/oe"
else
    mkdir -p "$(dirname "$TARGET")"
    BACKUP="none (fresh install)"
fi

# Keep printer-local connection settings but select the light mode FORGE was
# designed and contrast-tested against. Klipper hosts already provide Python 3.
if [ -f "$STAGE/config.json" ] && command -v python3 >/dev/null; then
    python3 - "$STAGE/config.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    config = json.load(handle)
config["defaultMode"] = "light"
with open(path, "w", encoding="utf-8") as handle:
    json.dump(config, handle, indent=4)
    handle.write("\n")
PY
fi

if [ -d "$TARGET" ]; then
    mv "$TARGET" "$BACKUP"
fi
mv "$STAGE" "$TARGET"
chmod -R a+rX "$TARGET"

if command -v nginx >/dev/null && command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    sudo -n nginx -t
    sudo -n systemctl reload nginx 2>/dev/null || true
fi

printf '\nFORGE UI installed at %s\nBackup: %s\n' "$TARGET" "$BACKUP"
printf 'Klipper and Moonraker were not restarted. Hard-refresh your browser once.\n'
