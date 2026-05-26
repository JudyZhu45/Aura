#!/bin/bash
# XcodeGen 2.45.4 quirk: it emits the StoreKit configuration path with one extra "../"
# segment, so Xcode resolves it to /Users/judy459/Resources/... instead of the right place.
# This script patches the generated scheme. Run it after every `xcodegen generate`.
#
# Usage: ./scripts/fix-storekit-path.sh

set -euo pipefail
SCHEME="$(dirname "$0")/../Aura.xcodeproj/xcshareddata/xcschemes/Aura.xcscheme"

if grep -q '"../../Aura/Resources/Aura.storekit"' "$SCHEME"; then
    sed -i '' 's|"../../Aura/Resources/Aura.storekit"|"../Aura/Resources/Aura.storekit"|' "$SCHEME"
    echo "✓ Patched StoreKit configuration path in scheme."
else
    echo "✓ Scheme already has the correct StoreKit configuration path."
fi
