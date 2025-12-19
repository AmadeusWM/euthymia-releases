#!/usr/bin/env bash

# Accept VERSION as first argument or from environment variable VERSION
set -euo pipefail

VERSION="${1:-${VERSION:-}}"

if [[ -z "$VERSION" ]]; then
	echo "Usage: $0 <VERSION>  or set VERSION environment variable" >&2
	exit 2
fi

ELECTRON_URL="https://github.com/AmadeusWM/euthymia-releases/releases/download/v${VERSION}/euthymia-electron-linux-x64-${VERSION}.zip"
TAURI_URL="https://github.com/AmadeusWM/euthymia-releases/releases/download/v${VERSION}/Euthymia_${VERSION}_amd64.deb"

echo "Fetching SHA256 (SRI) for Electron: $ELECTRON_URL" >&2
ELECTRON_SRI=$(nix hash to-sri --type sha256 "$(nix-prefetch-url "$ELECTRON_URL")")
echo "Got Electron SRI: $ELECTRON_SRI" >&2

echo "Fetching SHA256 (SRI) for Tauri: $TAURI_URL" >&2
TAURI_SRI=$(nix hash to-sri --type sha256 "$(nix-prefetch-url "$TAURI_URL")")
echo "Got Tauri SRI: $TAURI_SRI" >&2

# Write nix/release.nix with the version and sha256 (SRI)
mkdir -p "$(dirname "$0")/nix"
cat > "$(dirname "$0")/nix/release.nix" <<EOF
{ lib }:

{
	version = "${VERSION}";
	electron_sha256 = "${ELECTRON_SRI}";
	tauri_sha256 = "${TAURI_SRI}";
}
EOF

echo "Wrote nix/release.nix" >&2

echo "Electron: $ELECTRON_SRI"
echo "Tauri: $TAURI_SRI"
