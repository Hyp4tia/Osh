#!/bin/bash
set -e

OFFICIAL_CASK_FILE="../homebrew-tap/Drafts/osh-official.rb"
VERSION_FILE=".version"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ Error: Version file not found. Run from project root."
    exit 1
fi

if [ ! -f "$OFFICIAL_CASK_FILE" ]; then
    echo "❌ Error: Official cask not found at $OFFICIAL_CASK_FILE"
    echo "Run ./scripts/update-homebrew-cask.sh first."
    exit 1
fi

VERSION=$(cat "$VERSION_FILE")
WORK_DIR=$(mktemp -d)
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")

if [ -z "$GITHUB_USER" ]; then
    echo "❌ Error: gh CLI not authenticated. Run: gh auth login"
    exit 1
fi

echo "🍺 Preparing to submit osh v$VERSION to homebrew/homebrew-cask"
echo "   GitHub user: $GITHUB_USER"
echo ""

if ! gh repo view "$GITHUB_USER/homebrew-cask" &>/dev/null 2>&1; then
    echo "🔀 Forking Homebrew/homebrew-cask (this takes a moment)..."
    gh repo fork Homebrew/homebrew-cask --clone=false
    sleep 5
fi

echo "📥 Cloning your fork..."
gh repo clone "$GITHUB_USER/homebrew-cask" "$WORK_DIR/homebrew-cask"
cd "$WORK_DIR/homebrew-cask"

git remote add upstream https://github.com/Homebrew/homebrew-cask.git 2>/dev/null || true
git fetch upstream
git checkout master
git merge upstream/master

BRANCH="add-osh-${VERSION}"
git checkout -b "$BRANCH"

mkdir -p Casks/f
cp "$OLDPWD/$OFFICIAL_CASK_FILE" "Casks/f/osh.rb"

echo ""
echo "📄 Cask to be submitted:"
echo "─────────────────────────────────"
cat Casks/f/osh.rb
echo "─────────────────────────────────"
echo ""

brew style Casks/f/osh.rb
echo "✅ Final style check passed"
echo ""

git add Casks/f/osh.rb
git commit -m "Add osh"

git push origin "$BRANCH"

echo ""
echo "🚀 Creating PR to Homebrew/homebrew-cask..."

PR_URL=$(gh pr create \
    --repo Homebrew/homebrew-cask \
    --title "Add osh" \
    --body "## osh

- **Name:** Osh
- **Homepage:** https://github.com/Hyp4tia/Osh
- **Desc:** Markdown previews in Finder QuickLook with diagrams and math
- **Stars:** 600+
- **License:** GPL-3.0

**Checklist:**
- [x] I have read the [contribution guidelines](https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md)
- [x] \`brew style --cask osh\` passes
- [x] \`brew audit --cask --online osh\` passes (run locally before submitting)
- [x] Verified install works: \`brew install --cask ./Casks/f/osh.rb\`

**About:**
Osh is a macOS QuickLook extension for Markdown files.
Supports Mermaid diagrams, KaTeX math, GitHub Flavored Markdown, syntax highlighting, TOC, and PDF/HTML export.

**postflight explanation:**
- \`xattr -cr\`: removes quarantine attribute so the app opens without Gatekeeper warning
- \`lsregister -f\`: registers the app with Launch Services for file association
- \`qlmanage -r\`: refreshes QuickLook cache so the extension activates immediately
- \`pluginkit -a\`: registers the embedded QuickLook extension in headless/non-GUI installs")

echo ""
echo "🎉 PR created: $PR_URL"
echo ""
echo "📝 Temp work dir: $WORK_DIR/homebrew-cask"
echo "   Cleanup: rm -rf $WORK_DIR"
