# Homebrew Official Tap Submission and Maintenance Guide

> **Status: tap published, official cask not submitted.** `Hyp4tia/homebrew-tap` is live and `Casks/osh.rb` tracks the current release, so `brew install --cask Hyp4tia/tap/osh` works today. There is no `osh` cask in `homebrew/homebrew-cask` yet, so the submission steps below are still pending.
> `scripts/update-homebrew-cask.sh` (run automatically by `scripts/release.sh`) rewrites the tap cask's `version` and `sha256` on every release, which makes Phase 3 of `RELEASE_PROCESS.md` mostly a verification pass.

## Dual-track strategy

| Version | File | Installation | Features |
|------|------|----------|------|
| **Feature version (tap)** | `../homebrew-tap/Casks/osh.rb` | `brew install --cask Hyp4tia/tap/osh` | duti default associations, auto_updates, Sparkle livecheck |
| **Official draft** | `../homebrew-tap/Drafts/osh-official.rb` | After submission to homebrew/homebrew-cask: `brew install --cask osh` | Compliant with official standards, no formula dependencies |

---

## First submission to the official tap

### Prerequisites

- `gh` CLI installed and logged in (`gh auth status`)
- The current version has been released and `update-homebrew-cask.sh` has been run
- `./scripts/submit-to-homebrew.sh` copies the draft to the official tap path and then runs `brew style`

### Submission

```bash
./scripts/submit-to-homebrew.sh
```

The script automates: Fork → clone → sync upstream → new branch → copy cask → style check → commit → create PR.

---

## Updating later versions

### On every release (automated)

`update-homebrew-cask.sh` updates both files at the same time:

```bash
./scripts/update-homebrew-cask.sh
```

### Official tap version updates

**Recommended: rely on Homebrew Bot**

After the PR is merged, Homebrew's `BrewTestBot` automatically detects new versions via livecheck and opens a PR.
You only need to approve it (comment `@BrewTestBot approved`).

**Fallback: open a PR manually**

```bash
VERSION="<NEW_VERSION>"
SHA256=$(shasum -a 256 build/artifacts/Osh.dmg | awk '{print $1}')

cd ~/your-fork/homebrew-cask
git fetch upstream && git merge upstream/master
git checkout -b "bump-osh-${VERSION}"

sed -i '' "s/version \".*\"/version \"${VERSION}\"/" Casks/f/osh.rb
sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" Casks/f/osh.rb

brew style Casks/f/osh.rb

git add Casks/f/osh.rb
git commit -m "osh ${VERSION}"
gh pr create --repo Homebrew/homebrew-cask --title "osh ${VERSION}" --body "Version bump."
```

---

## Differences between the two versions

| Field | Feature version (tap) | Official version |
|------|-------------|--------|
| `auto_updates` | ✅ `true` | ❌ Not allowed by Homebrew |
| `depends_on formula: "duti"` | ✅ | ❌ Homebrew forbids casks depending on formulas |
| duti postflight | ✅ Sets default file associations | ❌ Removed |
| livecheck | Sparkle + appcast.xml | GitHub Latest |
| caveats | Includes default-app setup instructions | QuickLook troubleshooting only |

---

## FAQ

**Q: What are the review requirements for an official PR?**

Common review feedback:
- `system_command` in postflight requires justification in the PR description (`submit-to-homebrew.sh` already includes a full explanation)
- You may be asked to add a `brew test` case

**Q: How do the official and tap versions coexist after the official merge?**

Both can coexist once the official cask is submitted. The tap is already live (`Hyp4tia/homebrew-tap`):
- `brew install --cask osh` (official version, after the submission lands): lean
- `brew install --cask Hyp4tia/tap/osh` (tap version): full features

To switch from the official version to the tap version:
```bash
brew uninstall --cask osh
brew install --cask Hyp4tia/tap/osh
```
