# Release Process

This document records the complete version release process, including PR handling, CHANGELOG generation, and Homebrew distribution.

## Overview

The release process is divided into three phases:
1. **Before PR merge**: Collect and record changes
2. **Version release**: Automated build and release
3. **After release**: Update the Homebrew Cask and verify

---

## Phase 1: Handling before PR merge

### 1.1 PR Review and analysis

When a PR is received, you need to:

1. **Get PR metadata**:
   ```bash
   gh pr view <PR_NUMBER> --json title,body,author,number
   ```

2. **Analyze the code changes**:
   ```bash
   # View all commits in the PR
   gh pr view <PR_NUMBER> --json commits
   
   # View the specific code changes
   git log --oneline <BASE_COMMIT>..<PR_COMMIT>
   git show <PR_COMMIT> --stat
   git show <PR_COMMIT>
   ```

3. **Extract PR information**:
   - PR number
   - PR title
   - PR author's GitHub username
   - PR description
   - Modified files and line counts
   - Specific code changes

### 1.2 Generate the CHANGELOG entry

Based on the PR analysis, generate a CHANGELOG entry that follows the format:

**Format template**:
```markdown
### [Added|Fixed|Changed|Removed]
- **[Scope]**: [Brief description]. (Thanks to [@username](https://github.com/username) for the contribution [#PR_NUMBER](https://github.com/Hyp4tia/Osh/pull/PR_NUMBER))
  - [Technical implementation detail 1]
  - [Technical implementation detail 2]
  - [Technical implementation detail 3]
```

**Example**:
```markdown
### Fixed
- **QuickLook**: Fix the problem where double-clicking a Markdown file unexpectedly triggers "Open with the default app". (Thanks to [@sxmad](https://github.com/sxmad) for the contribution [#2](https://github.com/Hyp4tia/Osh/pull/2))
  - Intercept mouse events through a custom `InteractiveWebView` subclass to prevent events from bubbling up to the QuickLook host.
  - Add an `NSClickGestureRecognizer` to intercept the double-click gesture, ensuring that interactions inside the WebView (such as text selection) are unaffected.
  - Implement the `acceptsFirstMouse(for:)` method to allow the WebView to respond to the first click event directly.
```

### 1.3 Update the CHANGELOG

**Important**: After the PR is merged, immediately add the generated entry to the `## [Unreleased]` section of `CHANGELOG.md`:

```bash
# Edit CHANGELOG.md and add new entries under [Unreleased]
vim CHANGELOG.md

# Commit the update
git add CHANGELOG.md
git commit -m "docs(changelog): add PR #<NUMBER> to unreleased section"
git push origin master
```

---

## Phase 2: Version release

### 2.1 Run the release command

Use the `make release` command to publish a new version:

```bash
# Patch version (1.2.69 -> 1.2.70)
make release patch

# Minor version (1.2.69 -> 1.3.70)
make release minor

# Major version (1.2.69 -> 2.0.70)
make release major
```

### 2.2 Steps the release script performs automatically

`scripts/release.sh` automatically performs:

1. **Update the version number**:
   - Read the `.version` file
   - Update major/minor based on the bump type
   - Calculate the new full version number (base_version.commit_count)

2. **Extract the release notes**:
   - Extract content from the `[Unreleased]` section of `CHANGELOG.md`
   - Filter out internal changes (architecture, build, tests, etc.)
   - Generate `release_notes_tmp.md`

3. **Update the CHANGELOG**:
   - Replace `[Unreleased]` with the new version number and date
   - Keep an empty `[Unreleased]` section for next time

4. **Commit and tag**:
   ```bash
   git add .version CHANGELOG.md
   git commit -m "chore(release): bump version to <VERSION>"
   git tag "v<VERSION>"
   git push origin master
   git push origin "v<VERSION>"
   ```

5. **Build the DMG**:
   - Build the TypeScript renderer
   - Generate the Xcode project
   - Compile the macOS app
   - Create the DMG installer

6. **Create the GitHub Release**:
   ```bash
   gh release create "v<VERSION>" build/artifacts/Osh.dmg \
        --title "v<VERSION>" \
        --notes-file release_notes_tmp.md
   ```

### 2.3 Verify the release

Check the following:

- [ ] GitHub Release has been created: https://github.com/Hyp4tia/Osh/releases/tag/v<VERSION>
- [ ] DMG file has been uploaded
- [ ] Release Notes include the thanks for all PRs
- [ ] Git tag has been pushed
- [ ] CHANGELOG.md has been updated

---

## Phase 3: Homebrew update after the release

### 3.1 Calculate the DMG's SHA256

```bash
shasum -a 256 build/artifacts/Osh.dmg
```

Example output:
```
ca72b7201410962f0f5d272149b2405a5d191a8e692d9526f23ecad3882cd306  build/artifacts/Osh.dmg
```

### 3.2 Update the Homebrew Cask

Edit `../homebrew-tap/Casks/osh.rb`:

```ruby
cask 'osh' do
  version '1.3.73'  # Update the version number
  sha256 'ca72b7201410962f0f5d272149b2405a5d191a8e692d9526f23ecad3882cd306'  # Update the SHA256
  
  # ... keep the rest unchanged
end
```

### 3.3 Commit and push the Homebrew Cask

```bash
cd ../homebrew-tap
git add Casks/osh.rb
git commit -m "chore(cask): update osh to v<VERSION>"
git push origin master
```

### 3.4 Verify the installation package

Osh does not currently distribute a Homebrew cask (the tap is unpublished and the official cask has not been submitted), so post-release verification goes through the DMG:

```bash
# Download the published DMG and check its signature and notarization status
gh release download v<VERSION> --repo Hyp4tia/Osh --pattern "Osh.dmg"
codesign -dv --verbose=4 "Osh.app"      # Expect Developer ID Application (currently adhoc)
spctl -a -vvv -t exec "Osh.app"         # Expect accepted (currently rejected)
xcrun stapler validate "Osh.app"        # Expect ticket stapled
```

---

## Complete example: v1.3.73 release process

### Actual commands executed and their output

```bash
# 1. Analyze the merged PR #2
$ gh pr view 2 --json title,body,author
{
  "author": {"login": "sxmad", "name": "asdfq"},
  "body": "Use NSClickGestureRecognizer to intercept double-click events.",
  "title": "fix double click"
}

$ git show 790e41b --stat
commit 790e41bddc3abfdc0c2ea45702aed24d37424e22
Author: xiaoxin.sun <xiaoxin.sun@happyelements.com>
Date:   Tue Jan 13 12:25:58 2026 +0800

    fix double click

 Sources/MarkdownPreview/PreviewViewController.swift | 31 +++++++++++++++++++---
 1 file changed, 28 insertions(+), 3 deletions(-)

# 2. Manually add to the [Unreleased] section of CHANGELOG.md
# (This step was missed this time, so it had to be backfilled after the release)

# 3. Run the minor version release
$ make release minor
🚀 Bumping Minor Version: 1.2 -> 1.3
🎯 Target Version: 1.3.73
✅ DMG created successfully at: build/artifacts/Osh.dmg
🎉 Successfully released v1.3.73!

# 4. Backfill the CHANGELOG (fix the missed step)
$ vim CHANGELOG.md  # Add the detailed description of and thanks for PR #2
$ git add CHANGELOG.md
$ git commit -m "docs(changelog): backfill v1.3.73 release notes with PR #2 fix"
$ git push origin master

# 5. Update the GitHub Release
$ gh release edit v1.3.73 --notes-file /tmp/release_notes_v1.3.73_updated.md

# 6. Calculate the SHA256
$ shasum -a 256 build/artifacts/Osh.dmg
ca72b7201410962f0f5d272149b2405a5d191a8e692d9526f23ecad3882cd306

# 7. Update the Homebrew Cask
$ cd ../homebrew-tap
$ vim Casks/osh.rb  # Update the version and sha256
$ git add Casks/osh.rb
$ git commit -m "chore(cask): update osh to v1.3.73"
$ git push origin master

# 8. Verify
$ brew upgrade osh
```

---

## Automation improvement suggestions

### Short-term improvements (manual execution, standardize the process)

**Create a post-PR-merge Checklist**:

```bash
# scripts/pr-merged-checklist.sh
#!/bin/bash

PR_NUMBER=$1
if [ -z "$PR_NUMBER" ]; then
    echo "Usage: $0 <PR_NUMBER>"
    exit 1
fi

echo "✅ PR #$PR_NUMBER Merged - Post-Merge Checklist"
echo ""
echo "1. Analyze the PR content:"
echo "   gh pr view $PR_NUMBER --json title,body,author,commits"
echo ""
echo "2. View the code changes:"
echo "   gh pr diff $PR_NUMBER"
echo ""
echo "3. Generate the CHANGELOG entry (manually):"
echo "   - Determine the type: Added/Fixed/Changed/Removed"
echo "   - Determine the scope: QuickLook/Renderer/Build system etc."
echo "   - Extract the author info and PR link"
echo ""
echo "4. Update the [Unreleased] section of CHANGELOG.md"
echo "   vim CHANGELOG.md"
echo ""
echo "5. Commit the update:"
echo "   git add CHANGELOG.md"
echo "   git commit -m 'docs(changelog): add PR #$PR_NUMBER to unreleased section'"
echo "   git push origin master"
```

### Medium-term improvements (script-assisted)

**Create a PR analysis and CHANGELOG generation script**:

```bash
# scripts/analyze-pr.sh
#!/bin/bash
set -e

PR_NUMBER=$1
if [ -z "$PR_NUMBER" ]; then
    echo "Usage: $0 <PR_NUMBER>"
    exit 1
fi

echo "📊 Analyzing PR #$PR_NUMBER..."

# Get the PR information
PR_INFO=$(gh pr view $PR_NUMBER --json title,body,author,files)
PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
PR_AUTHOR=$(echo "$PR_INFO" | jq -r '.author.login')
PR_BODY=$(echo "$PR_INFO" | jq -r '.body')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PR #$PR_NUMBER: $PR_TITLE"
echo "Author: @$PR_AUTHOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Description:"
echo "$PR_BODY"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get the modified files
echo "Modified Files:"
gh pr view $PR_NUMBER --json files --jq '.files[].path'
echo ""

# View the diff
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Code Changes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gh pr diff $PR_NUMBER

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Suggested CHANGELOG Entry:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "### [TODO: Category]"
echo "- **[TODO: Scope]**: $PR_TITLE. (Thanks to [@$PR_AUTHOR](https://github.com/$PR_AUTHOR) for the contribution [#$PR_NUMBER](https://github.com/Hyp4tia/Osh/pull/$PR_NUMBER))"
echo "  - [TODO: Technical implementation detail 1]"
echo "  - [TODO: Technical implementation detail 2]"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Please refine the CHANGELOG entry manually based on the above information, then:"
echo "    1. Edit CHANGELOG.md"
echo "    2. git add CHANGELOG.md"
echo "    3. git commit -m 'docs(changelog): add PR #$PR_NUMBER to unreleased section'"
echo "    4. git push origin master"
```

### Long-term improvements (fully automated)

Use AI assistance or GitHub Actions automation:

1. **Automatically generate a CHANGELOG draft when a PR is merged**:
   - GitHub Action listens for the PR merge event
   - Use the GPT API to analyze the code changes
   - Automatically generate the CHANGELOG entry and create a commit

2. **Automatically update the Homebrew Cask on release**:
   - Add the Homebrew update logic to the end of `scripts/release.sh`
   - Automatically calculate the SHA256
   - Automatically commit to the homebrew-tap repository

---

## FAQ

### Q1: What to do when a PR's CHANGELOG entry was missed after the release?

**Backfill process** (e.g. v1.3.73):

1. Analyze the missed PR
2. Edit CHANGELOG.md and add the entry under the corresponding version
3. Commit: `git commit -m "docs(changelog): backfill v<VERSION> with PR #<NUMBER>"`
4. Update the GitHub Release: `gh release edit v<VERSION> --notes-file <new_notes.md>`
5. Push: `git push origin master`

### Q2: How to determine which type a PR belongs to (Added/Fixed/Changed)?

- **Added**: Brand-new features or capabilities
- **Fixed**: Bug fixes
- **Changed**: Improvements or refactoring of existing functionality
- **Removed**: Removed functionality
- **Deprecated**: Functionality that will be deprecated soon

### Q3: How to determine the Scope of a CHANGELOG entry?

Based on the modified file paths:
- `Sources/MarkdownPreview/` → **QuickLook** or **Extension**
- `Sources/Markdown/` → **App** or **Host App**
- `web-renderer/` → **Renderer** or **Preview**
- `Makefile`, `project.yml`, `scripts/` → **Build**
- `docs/` → **Documentation**

### Q4: What kinds of changes should not appear in the Release Notes?

Based on the filtering logic in `scripts/release.sh`, the following types are filtered out:
- Architecture
- Internal
- Build
- Test
- CI
- Refactor (unless it affects the user experience)

These changes remain in CHANGELOG.md, but do not appear in the GitHub Release notes.

---

## Phase 4: Issue reply guidelines

### 4.1 Core principles

| Rule | Description |
|------|------|
| **Language matching** | **Always reply in the issue's language**. English issue → English reply; Chinese issue → Chinese reply. No need to ask. |
| **Never close issues** | Only add the `done` label + a reply. The issue author decides whether to close it. |
| **Never reopen repeatedly** | If an issue was closed by mistake, reopen it first, then add the label and reply. |

### 4.2 Workflow for handling a fixed issue

```bash
# 1. Confirm the fix is included in a released version
git tag --contains <fix-commit>  # Confirm the tag exists
gh release view v<VERSION>       # Confirm the release is published

# 2. Add the done label
gh issue edit <NUMBER> --add-label "done"

# 3. Reply in the issue's language (English or Chinese, see the templates)
gh issue comment <NUMBER> --body "..."

# Forbidden:
# gh issue close <NUMBER>
```

### 4.3 Reply templates

**English issue**:
```
Fixed in [vX.Y.Z](https://github.com/Hyp4tia/Osh/releases/tag/vX.Y.Z).

**What changed:**
- [specific fix relevant to this issue]

**To update:**
\`\`\`bash
brew update && brew upgrade --cask osh
\`\`\`
Or download the DMG from the [Releases page](https://github.com/Hyp4tia/Osh/releases/tag/vX.Y.Z).
```

**Chinese issue**:
```
Fixed in [vX.Y.Z](https://github.com/Hyp4tia/Osh/releases/tag/vX.Y.Z).

**What was fixed:**
- [specific fix related to this issue]

**How to update:**
\`\`\`bash
brew update && brew upgrade --cask osh
\`\`\`
Or download the DMG directly from the [Releases page](https://github.com/Hyp4tia/Osh/releases/tag/vX.Y.Z).
```

---

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI Manual](https://cli.github.com/manual/)
