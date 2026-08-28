#!/bin/bash
set -e

VERSION_FILE=".version"
CHANGELOG_FILE="CHANGELOG.md"
DMG_PATH="build/artifacts/Osh.dmg"

if ! command -v gh &> /dev/null; then
    echo "❌ Error: 'gh' (GitHub CLI) is not installed."
    exit 1
fi

BUMP_TYPE=${1:-patch}

if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi

CURRENT_FULL_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r major minor patch <<< "$CURRENT_FULL_VERSION"
major=${major:-1}
minor=${minor:-0}
patch=${patch:-0}

if [[ "$BUMP_TYPE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    NEW_FULL_VERSION="$BUMP_TYPE"
    echo "🚀 Setting explicit version: $CURRENT_FULL_VERSION -> $NEW_FULL_VERSION"
elif [[ "$BUMP_TYPE" == "major" ]]; then
    major=$((major + 1))
    minor=0
    patch=0
    NEW_FULL_VERSION="$major.$minor.$patch"
    echo "🚀 Bumping Major Version: $CURRENT_FULL_VERSION -> $NEW_FULL_VERSION"
elif [[ "$BUMP_TYPE" == "minor" || "$BUMP_TYPE" == "minus" ]]; then
    minor=$((minor + 1))
    patch=0
    NEW_FULL_VERSION="$major.$minor.$patch"
    echo "🚀 Bumping Minor Version: $CURRENT_FULL_VERSION -> $NEW_FULL_VERSION"
elif [[ "$BUMP_TYPE" == "patch" ]]; then
    patch=$((patch + 1))
    NEW_FULL_VERSION="$major.$minor.$patch"
    echo "🚀 Bumping Patch Version: $CURRENT_FULL_VERSION -> $NEW_FULL_VERSION"
else
    echo "❌ Error: Invalid bump type '$BUMP_TYPE'. Use major, minor, patch, or X.Y.Z."
    exit 1
fi

echo "🎯 Target Version: $NEW_FULL_VERSION"

echo "$NEW_FULL_VERSION" > "$VERSION_FILE"

echo "📝 Extracting user-facing release notes..."
RELEASE_NOTES_FILE="release_notes_tmp.md"

python3 -c "
import sys
import re

BLACKLIST = ['架构', 'Architecture', '内部', 'Internal', '构建', 'Build', '测试', 'Test', 'CI', 'Refactor']

def is_user_facing(line):
    match = re.search(r'\*\*(.*?)\*\*:', line)
    if match:
        scope = match.group(1)
        for b in BLACKLIST:
            if b in scope:
                return False
    return True

try:
    with open('$CHANGELOG_FILE', 'r', encoding='utf-8') as f:
        content = f.read()
    
    pattern = r'## \[Unreleased\]\n(.*?)(\n## \[|$)'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        raw_notes = match.group(1).strip()
        filtered_lines = []
        for line in raw_notes.split('\n'):
            if line.strip().startswith('-'):
                if is_user_facing(line):
                    filtered_lines.append(line)
            else:
                filtered_lines.append(line)
        
        final_notes = re.sub(r'\n{3,}', '\n\n', '\n'.join(filtered_lines)).strip()
        print(final_notes)
    else:
        sys.stderr.write('Warning: No [Unreleased] section found.\n')
except Exception as e:
    sys.stderr.write(f'Error: {e}\n')
    sys.exit(1)
" > "$RELEASE_NOTES_FILE"

if [ ! -s "$RELEASE_NOTES_FILE" ]; then
    echo "⚠️ Warning: Release notes are empty. Continuing..."
    echo "No significant user-facing changes." > "$RELEASE_NOTES_FILE"
else
    echo "✅ Release notes extracted:"
    cat "$RELEASE_NOTES_FILE"
    echo "----------------------------------------"
fi

DATE_STR=$(date "+%Y-%m-%d")
TEMP_CHANGELOG=$(mktemp)
sed "s/^## \[Unreleased\]$/## [Unreleased]\\
_No pending unreleased changes._\\
\\
## [$NEW_FULL_VERSION] - $DATE_STR/" "$CHANGELOG_FILE" > "$TEMP_CHANGELOG"
mv "$TEMP_CHANGELOG" "$CHANGELOG_FILE"

echo "💾 Committing changes..."
git add "$VERSION_FILE" "$CHANGELOG_FILE"
if git ls-files --error-unmatch .build_number >/dev/null 2>&1; then
    git rm .build_number
fi
if git ls-files --error-unmatch scripts/increment_version.sh >/dev/null 2>&1; then
    git rm scripts/increment_version.sh
fi

TAG_NAME="v${NEW_FULL_VERSION}-beta"
git tag "$TAG_NAME"

echo "☁️ Pushing to remote..."
CURRENT_BRANCH=$(git branch --show-current || echo "main")
git push origin "$CURRENT_BRANCH"
git push origin "$TAG_NAME"

echo "🔨 Building project and DMG..."
make dmg

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: DMG not found at $DMG_PATH"
    exit 1
fi

echo "📦 Building MacPorts source tarball..."
MACPORTS_TARBALL="build/artifacts/Osh-${NEW_FULL_VERSION}-macports-source.tar.gz"
if ./scripts/create_macports_tarball.sh "$NEW_FULL_VERSION"; then
    echo "✅ MacPorts tarball created: $MACPORTS_TARBALL"
    if [ -f "macports/Portfile" ]; then
        git add macports/Portfile
        git commit -m "chore(macports): update Portfile checksums for v$NEW_FULL_VERSION" || true
        git push origin "$CURRENT_BRANCH" || true
        echo "✅ macports/Portfile committed"
    fi
else
    echo "⚠️  MacPorts tarball creation failed (non-fatal)"
    MACPORTS_TARBALL=""
fi

echo "📦 Creating GitHub Release $TAG_NAME..."
RELEASE_ASSETS="$DMG_PATH"
if [ -n "$MACPORTS_TARBALL" ] && [ -f "$MACPORTS_TARBALL" ]; then
    RELEASE_ASSETS="$RELEASE_ASSETS $MACPORTS_TARBALL"
fi
gh release create "$TAG_NAME" $RELEASE_ASSETS \
    --title "v$NEW_FULL_VERSION Beta" \
    --notes-file "$RELEASE_NOTES_FILE" \
    --draft=false \
    --prerelease

rm "$RELEASE_NOTES_FILE"

echo ""
echo "✨ Updating Sparkle appcast..."
# Find sign_update tool (keys are stored in Keychain, not as files)
SIGN_UPDATE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -type f -perm +111 2>/dev/null | grep "Sparkle/bin/sign_update" | head -1)
if [ -z "$SIGN_UPDATE_BIN" ] && [ -x "./sign_update" ]; then
    SIGN_UPDATE_BIN="./sign_update"
fi

if [ -f "./scripts/generate-appcast.sh" ] && [ -x "$SIGN_UPDATE_BIN" ]; then
    ./scripts/generate-appcast.sh "$DMG_PATH"
    
    if [ -f "appcast.xml" ]; then
        git add appcast.xml
        git commit -m "chore(sparkle): update appcast.xml for v$NEW_FULL_VERSION" || true
        git push origin "$CURRENT_BRANCH" || true
        echo "✅ Appcast updated and committed"
    fi
else
    echo "⚠️  Skipping appcast update"
    if [ ! -f "./scripts/generate-appcast.sh" ]; then
        echo "   Missing: ./scripts/generate-appcast.sh"
    fi
    if [ -z "$SIGN_UPDATE_BIN" ]; then
        echo "   Missing: sign_update tool (build the project once to download Sparkle via SPM)"
    fi
fi

echo ""
echo "🍺 Updating Homebrew Cask..."
if [ -f "./scripts/update-homebrew-cask.sh" ]; then
    ./scripts/update-homebrew-cask.sh "$NEW_FULL_VERSION" || echo "⚠️  Homebrew update failed (non-fatal)"
else
    echo "⚠️  Skipping Homebrew update (script not found)"
fi

echo ""
echo "🎉 Successfully released v$NEW_FULL_VERSION!"
echo ""
echo "📋 Post-release checklist:"
echo "   ✅ GitHub Release created"
echo "   ✅ DMG uploaded"
echo "   ✅ Sparkle appcast updated (if configured)"
echo "   ✅ Homebrew Cask updated (if configured)"
echo ""
echo "🌐 Release URL: https://github.com/Hyp4tia/Osh/releases/tag/v$NEW_FULL_VERSION"
