#!/bin/bash
# Submits release artifacts to Apple's notary service and staples the tickets.
#
# One-time setup (secrets never belong in the repo; this stores them in your login keychain):
#   xcrun notarytool store-credentials "osh-notary" --apple-id <email> --team-id <TEAM_ID>
# Override the profile name with NOTARY_PROFILE.
#
# Usage:
#   ./scripts/notarize.sh app <path/to/Osh.app>   # zip, notarize, staple, verify the bundle
#   ./scripts/notarize.sh dmg <path/to/Osh.dmg>   # notarize, staple, verify the disk image
set -euo pipefail

PROFILE="${NOTARY_PROFILE:-osh-notary}"
MODE="${1:-}"
TARGET="${2:-}"

fail() { echo "❌ $1" >&2; exit 1; }

usage() {
    echo "Usage: $0 {app|dmg} <path>" >&2
    exit 1
}

[ -n "$MODE" ] && [ -n "$TARGET" ] || usage
case "$MODE" in
    app | dmg) ;;
    *) usage ;;
esac
[ -e "$TARGET" ] || fail "Artifact not found: $TARGET"

# Fail fast when the keychain profile is missing instead of after a long upload.
if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    fail "Notary credential profile '$PROFILE' is unavailable. Create it with:
   xcrun notarytool store-credentials \"$PROFILE\" --apple-id <email> --team-id <TEAM_ID>"
fi

# Cleanup runs on every exit path. These live outside the functions on purpose:
# a trap referencing a function-local variable hits "unbound variable" under set -u.
WORK_DIR=""
MOUNT_DIR=""

cleanup() {
    if [ -n "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
    if [ -n "$MOUNT_DIR" ]; then
        hdiutil detach "$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
        rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

submit_and_wait() {
    local archive="$1" output submission_id status
    echo "☁️  Submitting $(basename "$archive") to Apple's notary service (usually a few minutes)..."
    output=$(xcrun notarytool submit "$archive" --keychain-profile "$PROFILE" --wait 2>&1) || true
    printf '%s\n' "$output"
    submission_id=$(printf '%s\n' "$output" | awk '/^ *id: /{print $2; exit}')
    status=$(printf '%s\n' "$output" | awk '/^ *status: /{s = $2} END{print s}')
    if [ "$status" != "Accepted" ]; then
        if [ -n "$submission_id" ]; then
            echo "--- notary log for $submission_id ---"
            xcrun notarytool log "$submission_id" --keychain-profile "$PROFILE" || true
        fi
        fail "Notarization failed (status: ${status:-unknown})"
    fi
    echo "✅ Accepted by the notary service (submission $submission_id)"
}

notarize_app() {
    local app="$1" zip
    [ -d "$app" ] || fail "App bundle not found: $app"

    echo "🔐 Verifying signature before upload..."
    codesign --verify --strict --verbose=2 "$app"

    WORK_DIR=$(mktemp -d)
    zip="$WORK_DIR/$(basename "$app").zip"
    ditto -c -k --keepParent "$app" "$zip"

    submit_and_wait "$zip"

    echo "📎 Stapling the ticket to the app..."
    xcrun stapler staple "$app"
    xcrun stapler validate "$app"

    echo "🛡️  Gatekeeper assessment (app)..."
    spctl --assess --type execute --verbose=4 "$app"
    echo "✅ App notarized and stapled: $app"
}

notarize_dmg() {
    local dmg="$1" app
    [ -f "$dmg" ] || fail "DMG not found: $dmg"

    submit_and_wait "$dmg"

    echo "📎 Stapling the ticket to the disk image..."
    xcrun stapler staple "$dmg"
    xcrun stapler validate "$dmg"

    echo "🛡️  Gatekeeper assessment (disk image)..."
    spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg"

    # Verify the app inside the packaged image, not just the image itself.
    MOUNT_DIR=$(mktemp -d)
    hdiutil attach "$dmg" -mountpoint "$MOUNT_DIR" -nobrowse -readonly >/dev/null

    app="$MOUNT_DIR/Osh.app"
    [ -d "$app" ] || fail "Osh.app not found inside $dmg"
    echo "🛡️  Gatekeeper assessment (app inside the DMG)..."
    spctl --assess --type execute --verbose=4 "$app"
    xcrun stapler validate "$app"
    echo "✅ DMG notarized, stapled, and verified: $dmg"
}

case "$MODE" in
    app) notarize_app "$TARGET" ;;
    dmg) notarize_dmg "$TARGET" ;;
esac
