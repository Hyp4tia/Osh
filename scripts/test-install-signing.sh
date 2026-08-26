#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/scripts/install.sh"

fail() {
    echo "❌ $1" >&2
    exit 1
}

require_text() {
    local needle="$1"
    local description="$2"

    if ! grep -Fq -- "$needle" "$INSTALL_SCRIPT"; then
        fail "$description"
    fi
}

if grep -Eq '/usr/bin/codesign .*--force.*--deep|/usr/bin/codesign .*--deep.*--force' "$INSTALL_SCRIPT"; then
    fail "install.sh must not repair-sign the app with codesign --deep; it strips nested appex entitlements"
fi

require_text 'APP_ENTITLEMENTS="$PROJECT_ROOT/Sources/OshApp/Osh.entitlements"' \
    "install.sh must point APP_ENTITLEMENTS at Sources/OshApp/Osh.entitlements"
require_text 'QUICKLOOK_ENTITLEMENTS="$PROJECT_ROOT/Sources/OshQuickLook/OshQuickLook.entitlements"' \
    "install.sh must point QUICKLOOK_ENTITLEMENTS at Sources/OshQuickLook/OshQuickLook.entitlements"

require_text 'QUICKLOOK_EXTENSION_PATH="$INSTALLED_APP_PATH/Contents/PlugIns/OshQuickLook.appex"' \
    "install.sh must sign the embedded QuickLook extension explicitly"

require_text 'TEMP_QUICKLOOK_ENTITLEMENTS=$(mktemp)' \
    "install.sh must create a temporary entitlements file for expanded QuickLook paths"

require_text '/usr/bin/sed "s|\$HOME|$HOME|g" "$QUICKLOOK_ENTITLEMENTS" > "$TEMP_QUICKLOOK_ENTITLEMENTS"' \
    "install.sh must expand $HOME before manual codesign; raw $HOME is not expanded by codesign"

require_text '/usr/bin/codesign --force --sign - --entitlements "$TEMP_QUICKLOOK_ENTITLEMENTS" "$QUICKLOOK_EXTENSION_PATH"' \
    "install.sh must sign OshQuickLook.appex with expanded OshQuickLook.entitlements"

require_text '/usr/bin/codesign --force --sign - --entitlements "$APP_ENTITLEMENTS" "$INSTALLED_APP_PATH"' \
    "install.sh must sign Osh.app with Osh.entitlements after nested code"

require_text '/usr/bin/codesign --verify --strict --deep --verbose=2 "$INSTALLED_APP_PATH"' \
    "install.sh must verify the final app signature after explicit signing"

echo "✅ install.sh development signing preserves nested QuickLook entitlements"
