#!/usr/bin/env bash

# Accept VERSION as first argument or from environment variable VERSION
set -euo pipefail

VERSION="${1:-${VERSION:-}}"

if [[ -z "$VERSION" ]]; then
	echo "Usage: $0 <VERSION>  or set VERSION environment variable" >&2
	exit 2
fi

URL="https://github.com/AmadeusWM/euthymia-releases/releases/download/v${VERSION}/euthymia-electron-linux-x64-${VERSION}.zip"

echo "Fetching SHA256 (SRI) for: $URL" >&2
SRI=$(nix hash to-sri --type sha256 "$(nix-prefetch-url "$URL")")
echo "Got SRI: $SRI" >&2

# Write nix/release.nix with the version and sha256 (SRI)
mkdir -p "$(dirname "$0")/nix"
cat > "$(dirname "$0")/nix/release.nix" <<EOF
{ lib }:

{
	version = "${VERSION}";
	electron_sha256 = "${SRI}";
}
EOF

echo "Wrote nix/release.nix" >&2

echo "$SRI"
