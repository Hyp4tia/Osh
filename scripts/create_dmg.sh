#!/bin/bash
set -e

APP_NAME="Osh"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="${HOME}/Library/Developer/Xcode/DerivedData/Osh-*"
DMG_NAME="Osh.dmg"
OUTPUT_DIR="build/artifacts"

# Distribution signing. Releases must ship Developer ID signed and notarized so
# Gatekeeper lets users open the app without the "Open Anyway" dance.
RELEASE_SIGN_IDENTITY="${RELEASE_SIGN_IDENTITY:-Developer ID Application}"
RELEASE_TEAM_ID="${RELEASE_TEAM_ID:-PSSU5CT8UG}"
export RELEASE_SIGN_IDENTITY RELEASE_TEAM_ID

echo "🚀 Starting DMG creation for ${APP_NAME}..."

# 1. Ensure a signed clean build
echo "📦 Building application (identity: ${RELEASE_SIGN_IDENTITY})..."
make app

# 2. Locate the built app
EXPECTED_VERSION="$(cat .version 2>/dev/null || true)"
APP_PATH=""

if [ -n "$EXPECTED_VERSION" ]; then
    while IFS= read -r candidate; do
        info_plist="$candidate/Contents/Info.plist"
        if [ ! -f "$info_plist" ]; then
            continue
        fi

        candidate_version=$(/usr/bin/defaults read "$info_plist" CFBundleShortVersionString 2>/dev/null || true)
        candidate_build=$(/usr/bin/defaults read "$info_plist" CFBundleVersion 2>/dev/null || true)

        if [ "$candidate_version" = "$EXPECTED_VERSION" ]; then
            APP_PATH="$candidate"
            break
        fi

        expected_build="$(echo "$EXPECTED_VERSION" | awk -F. '{print $3}')"
        if [ -n "$expected_build" ] && [ "$candidate_build" = "$expected_build" ]; then
            APP_PATH="$candidate"
            break
        fi
    done < <(find "$HOME/Library/Developer/Xcode/DerivedData" -name "${APP_BUNDLE}" -path "*/Build/Products/Release/*" 2>/dev/null)
fi

if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "${APP_BUNDLE}" -path "*/Build/Products/Release/*" | head -n 1)
fi

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built ${APP_BUNDLE}"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# 3. Refuse to package anything that is not properly signed for distribution
echo "🔐 Verifying distribution signature..."
SIGN_INFO=$(/usr/bin/codesign -dv --verbose=2 "$APP_PATH" 2>&1)
printf '%s\n' "$SIGN_INFO"

if ! printf '%s\n' "$SIGN_INFO" | grep -q "Authority=Developer ID Application"; then
    echo "❌ Error: ${APP_BUNDLE} is not signed with a Developer ID Application certificate."
    echo "   Expected identity: '${RELEASE_SIGN_IDENTITY}' (team ${RELEASE_TEAM_ID})."
    echo "   Run 'security find-identity -v -p codesigning' to see the identities in your keychain."
    exit 1
fi

if ! printf '%s\n' "$SIGN_INFO" | grep -q "flags=.*runtime"; then
    echo "❌ Error: hardened runtime is not enabled, which notarization requires."
    exit 1
fi

# 4. Notarize and staple the app before it gets packaged (NOTARIZE=1).
# Staple the bundle and not just the image so the app still passes Gatekeeper offline.
if [ "${NOTARIZE:-0}" = "1" ]; then
    ./scripts/notarize.sh app "$APP_PATH"
fi

# 5. Create artifacts directory
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$DMG_NAME"

# 6. Prepare temporary folder
TMP_DIR=$(mktemp -d)
echo "📂 Preparing DMG content in $TMP_DIR..."
/usr/bin/ditto "$APP_PATH" "$TMP_DIR/$APP_BUNDLE"
# 6.5. Pre-seed the background directory with Retina asset for Finder
mkdir -p "$TMP_DIR/.background"
cp assets/dmg/background@2x.png "$TMP_DIR/.background/background@2x.png"

# 7. Create DMG using create-dmg
echo "💿 Creating styled DMG using create-dmg..."

# Volume name must change to bypass Finder cache for the layout
VOLUME_NAME="Install ${APP_NAME}"
create-dmg \
  --volname "${VOLUME_NAME}" \
  --background "assets/dmg/background.tiff" \
  --window-pos 200 120 \
  --window-size 660 468 \
  --icon-size 100 \
  --icon "${APP_BUNDLE}" 180 220 \
  --app-drop-link 480 220 \
  --icon ".background" 120 120 \
  "$OUTPUT_DIR/$DMG_NAME" \
  "$TMP_DIR/"

echo "🔐 Verifying release entitlements..."
./scripts/verify-release-entitlements.sh "$OUTPUT_DIR/$DMG_NAME"

# 8. Notarize and staple the disk image too (NOTARIZE=1)
if [ "${NOTARIZE:-0}" = "1" ]; then
    ./scripts/notarize.sh dmg "$OUTPUT_DIR/$DMG_NAME"
fi

# 9. Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "✅ DMG created successfully at: $OUTPUT_DIR/$DMG_NAME"
echo ""
