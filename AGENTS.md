<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# PROJECT KNOWLEDGE BASE

**Context:** Hybrid macOS Document App & QuickLook Extension (Swift + TypeScript)

## OVERVIEW
Osh is a macOS Markdown & Typst viewer, editor, and QuickLook extension. It uses a hybrid architecture where a native Swift application (SwiftUI/AppKit) and QuickLook extension host a `WKWebView` running a bundled, single-file TypeScript rendering engine (Vite/markdown-it/KaTeX/Mermaid/Typst).

## STRUCTURE
```
.
├── Makefile            # Main build orchestrator (npm + xcodegen + xcodebuild)
├── project.yml         # XcodeGen config (Generates .xcodeproj - DO NOT EDIT PROJECT DIRECTLY)
├── Sources/
│   ├── OshApp/         # Host App (SwiftUI/AppKit) - Standalone document viewer & editor
│   ├── OshQuickLook/   # Extension (AppKit) - WKWebView, QLPreviewingController
│   └── Shared/         # Shared Swift modules (schemes, preferences, export, localization)
├── Tests/
│   └── OshTests/       # Swift XCTest suites and test fixtures
├── web-renderer/       # Rendering Engine (TypeScript/Vite) -> See web-renderer/AGENTS.md
├── scripts/            # Packaging, build, release, Sparkle, and Homebrew scripts
├── docs/               # Centralized documentation, debug logs, design docs, and release guides
└── openspec/           # OpenSpec proposals, specs, and change tracking
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Project Config** | `project.yml` | Add files/targets here. Run `make generate` to apply. |
| **Build Logic** | `Makefile` | `make all` builds everything. |
| **Extension Logic** | `Sources/OshQuickLook/PreviewViewController.swift` | QuickLook lifecycle, File I/O, JS Bridge. |
| **Host App & Editor** | `Sources/OshApp/` | Document app (`MarkdownApp.swift`, `MarkdownDocument.swift`, `SourceEditorView.swift`, `SettingsView.swift`, `CLIExporter.swift`). |
| **Shared Swift Core** | `Sources/Shared/` | Custom URL schemes (`LocalSchemeHandler.swift`), Docx exporter (`DocxExporter.swift`), localization, preferences. |
| **Rendering Engine** | `web-renderer/src/` | Markdown parsing, Typst, Diff engine, Search, TOC, RTL (see `web-renderer/AGENTS.md`). |
| **Swift Unit Tests** | `Tests/OshTests/` | XCTest suite for Swift app, handlers, preferences, and exporter. |
| **Renderer Tests** | `web-renderer/test/` | Jest test suites for rendering logic and plugins. |
| **Release Process** | `docs/release/RELEASE_PROCESS.md` | Complete PR handling and release workflow. |
| **Homebrew Cask (tap)** | `../homebrew-tap/Casks/osh.rb` | Full-featured version. Updated automatically by `update-homebrew-cask.sh`. |
| **Homebrew Cask (official)** | `../homebrew-tap/Casks/osh-official.rb` | Official-compliant draft for homebrew/homebrew-cask submission. No formula deps. |
| **Homebrew Guide** | `docs/release/HOMEBREW_SUBMISSION.md` | How to submit and maintain the official cask. |

## ARCHITECTURE & PATTERNS
- **Hybrid Bridge**: Swift loads `index.html` via custom URL scheme handlers (`osh-bundle://`, `osh-local://`), calls `window.renderMarkdown(content)`. JS logs back via `window.webkit.messageHandlers.logger`.
- **Ephemeral Project**: `.xcodeproj` is generated dynamically from `project.yml`. Never edit or commit `.xcodeproj` directly; always use `xcodegen` (`make generate`).
- **Versioning**: `.version` file stores full version (e.g., `1.13.149`). Build number (third part) aligns with git commit count.
- **Sandbox & Security**: App Sandbox enabled. Read-only access to files with security-scoped bookmarks for opened documents.
- **Auto-Updates**: Integrated Sparkle 2 updater with EdDSA cryptographic signatures.
- **Localization**: Multi-language support (`ar`, `de`, `en`, `es`, `fr`, `zh-Hans`) with full RTL rendering layout in the web view.
- **Release Flow**: 
  1. **PR Merged**: Run `./scripts/analyze-pr.sh <PR_NUMBER>` to generate CHANGELOG entry, add to `[Unreleased]` section.
  2. **Release**: Run `make release [major|minor|patch]` → Updates `.version`, `CHANGELOG.md`, builds DMG, creates GitHub release.
  3. **Homebrew**: Run `./scripts/update-homebrew-cask.sh` to update both tap and official cask files automatically.
  4. See `docs/release/RELEASE_PROCESS.md` for complete workflow.

## CONVENTIONS & DEVELOPMENT RULES

### 1. Test-Driven Development (TDD)
- **TDD Requirement**: Always write a verifiable test case or define a strict acceptance metric BEFORE writing implementation code.
- **Red-Green-Refactor**: Ensure tests fail before fixing them.
- **Coverage**: Add Swift XCTests in `Tests/OshTests/` and Jest tests in `web-renderer/test/`.

### 2. Ecosystem & Dependencies
- **No Reinventing Wheels**: Prioritize established npm packages or Swift libraries over custom implementations.
- **Dependency Management**: Strictly manage versions in `package.json` and Swift packages in `project.yml`.

### 3. Documentation (Doc-First)
- **Centralized Docs**: All design decisions, architectural changes, and rules must be recorded in the `docs/` directory.
- **Traceability**: Code changes should track back to a documented requirement, OpenSpec proposal, or bug report.

### 4. Debug Process & Rules
- **Documentation First**: Before diving into code for hard problems, create a debug tracking document (e.g., `docs/debug/DEBUG_ISSUE_NAME.md`).
- **Log Current State**: Record the initial symptom, current code version, and reproduction steps in the doc.
- **Automated Observation**: Ensure you can automatically retrieve logs and state (Swift `os_log`, JS console logs bridged to Swift). Do not rely on manual user reporting if automation is possible.
- **Iterative Approach**:
    1. **Hypothesis**: Formulate a hypothesis based on logs/evidence.
    2. **Instrument**: Add specific logging or test code to validate the hypothesis.
    3. **Deploy**: Run the build/install process.
    4. **Verify**: Check the automated logs.
    5. **Record**: Update the debug doc with findings.
    6. **Refine**: If not fixed, repeat. If fixed, clean up debug code.
- **Clean Up**: Remove temporary logging and revert debug-specific configuration changes before final submission.
- **One Step at a Time**: Change one variable at a time to isolate the root cause.

### 5. Commits
- **Automatic Commits**: After completing and verifying each important, self-contained work item, automatically create a Conventional Commit. Do not wait for the user to request the commit unless they explicitly ask not to commit. Stage only files that belong to the completed work item, and leave unrelated worktree changes untouched.

## GITHUB ISSUE MANAGEMENT

### Replying to Issues
- **Language**: Always reply in the same language as the issue. English issue → English reply. Chinese issue → Chinese reply. Never reply in a different language.
- **Label `done`**: When a fix is confirmed released, add the `done` label and post a reply linking the release. Do NOT close the issue — the reporter closes it.
- **Reply format** (confirmed fix):
  - State which version fixed it and link to the release tag.
  - List the specific fixes relevant to that issue.
  - Provide update instructions (Homebrew + DMG link).
- **No closing issues**: Only add `done` label + comment. The issue author decides when to close.

### Workflow for Closing Out Fixed Issues
```bash
# 1. Add done label
gh issue edit <NUMBER> --add-label "done"

# 2. Post reply (in the issue's language)
gh issue comment <NUMBER> --body "..."

# DO NOT run: gh issue close <NUMBER>
```

### Issue Reply Template (English)
```
Fixed in [vX.Y.Z](https://github.com/Zeyadistired/Osh/releases/tag/vX.Y.Z).

**What changed:**
- [specific fix relevant to this issue]

**To update:**
\`\`\`bash
brew update && brew upgrade --cask osh
\`\`\`
Or download the DMG from the [Releases page](https://github.com/Zeyadistired/Osh/releases/tag/vX.Y.Z).
```

### Issue Reply Template (Chinese)
```
已在 [vX.Y.Z](https://github.com/Zeyadistired/Osh/releases/tag/vX.Y.Z) 中修复。

**修复内容：**
- [与此 issue 相关的具体修复]

**更新方式：**
\`\`\`bash
brew update && brew upgrade --cask osh
\`\`\`
或从 [Releases 页面](https://github.com/Zeyadistired/Osh/releases/tag/vX.Y.Z) 直接下载 DMG。
```

## ANTI-PATTERNS
- **Never commit .xcodeproj**: It is generated via `xcodegen`.
- **No manual build numbers**: Use `make` or scripts.
- **Do not edit `dist/` directly**: It is a build artifact of `web-renderer`.

## COMMANDS
```bash
make generate                    # Generate Xcode project from project.yml
make build_renderer              # Build TypeScript engine (npm install && build)
make app                         # Build macOS app
make install                     # Build & install Release app locally
make install-debug               # Build & install Debug app locally
make dmg                         # Create packaged DMG
make release [major|minor|patch] # Release new version
cd web-renderer && npm test      # Run renderer Jest tests
log stream --predicate 'subsystem == "com.zeyadistired.osh"' --level debug
./scripts/analyze-pr.sh <PR_NUM> # Analyze PR and generate CHANGELOG entry
./scripts/update-homebrew-cask.sh # Update both tap and official Homebrew Cask
./scripts/submit-to-homebrew.sh   # Submit official cask to homebrew/homebrew-cask
```

