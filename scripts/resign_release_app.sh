#!/bin/bash
# Re-signs Sparkle's nested binaries inside a built app with the release identity.
#
# Xcode signs the framework and the app, but leaves the XPC services and
# Autoupdate with their ad-hoc signature, and Apple's notary service rejects
# ad-hoc code. Sign nested code first, the app last.
#
# Usage: ./scripts/resign_release_app.sh <path/to/Osh.app>
set -euo pipefail

APP="${1:-}"
IDENTITY="${RELEASE_SIGN_IDENTITY:-Developer ID Application}"

[ -n "$APP" ] && [ -d "$APP" ] || { echo "❌ App bundle not found: ${APP:-<none>}" >&2; exit 1; }

SPARKLE_FRAMEWORK="$APP/Contents/Frameworks/Sparkle.framework"
SPARKLE_CURRENT="$SPARKLE_FRAMEWORK/Versions/Current"

[ -d "$SPARKLE_FRAMEWORK" ] || { echo "❌ Sparkle.framework not found in $APP" >&2; exit 1; }

sign() {
    local target="$1"
    /usr/bin/codesign --force --sign "$IDENTITY" --options runtime --timestamp \
        --preserve-metadata=entitlements "$target"
}

echo "🔏 Re-signing Sparkle XPC services..."
for xpc in "$SPARKLE_CURRENT"/XPCServices/*.xpc; do
    [ -e "$xpc" ] || continue
    echo "   $(basename "$xpc")"
    sign "$xpc"
done

if [ -e "$SPARKLE_CURRENT/Autoupdate" ]; then
    echo "   Autoupdate"
    sign "$SPARKLE_CURRENT/Autoupdate"
fi

echo "🔏 Re-signing Sparkle.framework and the app..."
sign "$SPARKLE_FRAMEWORK"
# --preserve-metadata on the app keeps the entitlements Xcode expanded from
# Sources/OshApp/OshRelease.entitlements (they contain build-setting variables).
sign "$APP"

/usr/bin/codesign --verify --strict --verbose=2 "$APP"
echo "✅ Nested Sparkle binaries re-signed with: $IDENTITY"
