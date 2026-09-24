# Debug Log: v1.0.10 Review Findings (QuickLook teardown, DOCX export, renderer settings)

**Date:** 2026-09-24
**Status:** §2 fixes landed on `fix/v1.0.10` with tests; release blocked on distribution signing (§4.2)
**Reviewed revision:** `e8e616c` (v1.0.9 release tip, `main`)
**Baseline:** `npm test` 354/354 pass, XCTest 304 tests / 1 skipped / 0 failures

## 0. Progress

| Item | State |
|---|---|
| §2.1 DOCX image loss | Fixed, `test/docx-export-model.test.ts` (4 tests) |
| §2.2 QuickLook nil-web-view traps | Fixed, `Tests/OshTests/QuickLookTeardownSafetyTests.swift` (4 tests). Both reported traps were reproduced as real `Fatal error` crashes before the fix |
| §2.3 Renderer settings dropped on fast path | Fixed, `Sources/Shared/RenderFastPath.swift` + `Tests/OshTests/RenderFastPathTests.swift` (10 tests) |
| §2.4 Inert reload suppression | Fixed, `Tests/OshTests/EditingReloadSuppressionTests.swift` (3 source-assertions) |
| §4.1 Deployment target | Bumped to 12.0 in `project.yml`, appcast generator aligned, docs updated |
| §4.2 Distribution signing | Open, needs a Developer ID certificate |
| §4.3 Homebrew docs | Docs corrected to state that no cask is published |

## 1. Scope and method

Three independent reviewers (no shared context) each read a slice of the codebase in full and
returned findings with `file:line` evidence. Every finding below marked **confirmed** was then
re-read in the source by a second pass before being recorded here; findings marked **reported**
come from the reviewer pass only and still need confirmation before being acted on.

- Slice A: `Sources/OshQuickLook/PreviewViewController.swift` + scheme handlers, `SkillPackage.swift`
- Slice B: `Sources/OshApp/MarkdownWebView.swift`, `Sources/OshApp/MarkdownDocument.swift`
- Slice C: `web-renderer/src/*.ts` (renderer pipeline, export paths, search, TOC, diff)

Result: no XSS hole, no ReDoS pattern, and no path-traversal gap in the renderer, the scheme
handlers, or the export inliner. The bugs below are lifecycle/state bugs plus one silent data-loss
bug in DOCX export.

## 2. In scope for v1.0.10

### 2.1 DOCX export silently drops images larger than the argument limit (confirmed)

`web-renderer/src/index.ts:1478`

```ts
images[key] = `data:${mime};base64,` + btoa(String.fromCharCode(...bytes));
```

`String.fromCharCode(...bytes)` spreads every byte as a call argument. Past roughly 65k elements the
engine throws `RangeError: Maximum call stack size exceeded`. The surrounding `catch`
(`index.ts:1480-1482`) logs and continues, so `exportDocxModel` resolves successfully with the image
missing from the `.docx`. Any real photo exceeds the limit.

Acceptance metric: a DOCX export model built from a document containing an image larger than 1 MB
must contain that image's `data:` URI in the returned `images` map (Jest).

### 2.2 QuickLook can trap on a nil `webView` after teardown (confirmed)

`Sources/OshQuickLook/PreviewViewController.swift:69` declares `var webView: InteractiveWebView!`
and `cleanupWebView()` (`:557-578`) sets `self.webView = nil`. Four later entry points deref it with
no teardown check:

| Site | Path |
|---|---|
| `:1113-1117` | `preparePreviewOfFile`'s `DispatchQueue.main.async` block (`self.webView.pageZoom = savedZoom`) |
| `:1270-1276` | `renderPendingMarkdown`'s detached task completion (`callAsyncJavaScript`) |
| `:1289` | the 0.1 s `asyncAfter` scroll restore (`evaluateJavaScript`) |
| `:906` | `applyThemeToWebView`, reachable from the `AppleInterfaceThemeChangedNotification` observer because `isWebViewLoaded` is never reset by `cleanupWebView()` |

Trigger: close the QuickLook panel while a render is in flight (document with images), or a system
appearance change after teardown while the extension process is reused.

Acceptance metric: after teardown, the deferred blocks return early instead of dereferencing
`webView`; a test drives `preparePreviewOfFile` → teardown → deferred block and observes no trap.

### 2.3 Five renderer settings are silently dropped on the fast path (confirmed)

`Sources/OshApp/MarkdownWebView.swift:551`

```swift
let onlyAppearanceOrFontChanged = (content == lastRenderedContent) && (viewMode == .preview) && ...
```

`enableMermaid`, `enableKatex`, `enableEmoji`, `enableTypst`, and `codeHighlightTheme` are not part of
the comparison, and the fast path only applies font size (`:553-559`) and theme (`:561-576`) before
returning at `:577`. The `lastEnable*` / `lastCodeHighlightTheme` writes at `:505-509` are never read
back. Result: toggling any of those five settings with unchanged document content does nothing until
the content itself changes.

Acceptance metric: a unit test asserts that a change to any of the five options with unchanged
content does not take the fast path (and that font-size/theme-only changes still do).

### 2.4 "Suppress reloads while editing" is inert (confirmed)

`isEditingPaused` occurs exactly three times in the repository: the declaration
(`MarkdownWebView.swift:139`) and two guards (`:907`, `:922`). Nothing ever sets it to `true`, so the
documented protection against disk reloads during an edit session does not exist.

Acceptance metric: entering an editing session suppresses disk-triggered renders; leaving it
(save or cancel) restores them.

## 3. Backlog, confirmed or reported, not in this release

| # | Finding | Evidence | Status |
|---|---|---|---|
| B1 | TOC active-heading highlight dies after the first document: headings are observed once at singleton construction and `render()` never re-observes | `web-renderer/src/table-of-contents.ts:78-86` | reported |
| B2 | Export failures give no UI feedback (DOCX JSON parse, HTML non-string result, write errors, `NSPrintOperation.run()` failure all only `os_log`) | `MarkdownWebView.swift:345-365, 749-773, 818-822` | reported |
| B3 | Renderer process crash leaves a blank view: `reload()` never resets `isWebViewLoaded`, so the next `rendererReady` skips the queued render | `MarkdownWebView.swift:719-722, 730-741` | confirmed |
| B4 | `NSPrintOperation.run()` on a background queue (AppKit printing is main-thread bound) | `MarkdownWebView.swift:812-824` | reported |
| B5 | File-monitor cancel handler closes the descriptor currently stored in the property instead of the one it owns, and leaks it when `self` is gone | `MarkdownWebView.swift:867-872`, `PreviewViewController.swift:1886-1891` (identical code) | confirmed |
| B6 | Full file is read into memory before the 500 KB cap is checked; `.skill`/zip previews bypass the cap entirely and are parsed on the main thread | `PreviewViewController.swift:1153-1172` | reported |
| B7 | Async renders can land out of order: `renderVersion` is generated and passed to JS but never compared on completion | `PreviewViewController.swift:1242, 1248, 1270` | reported |
| B8 | Mermaid's dynamic import has no `.catch`, so a failed chunk load is an unhandled rejection on every render | `web-renderer/src/index.ts:1058-1062` | confirmed |
| B9 | `decodeURIComponent` on anchor clicks is unguarded and throws on `#%zz` style anchors | `web-renderer/src/index.ts:1237` | confirmed |
| B10 | Fenced-code language is concatenated into the `class` attribute unescaped; DOMPurify strips executables downstream so the injection is inert, but live elements survive inside the code block | `web-renderer/src/index.ts:388-389` | confirmed |
| B11 | A rejected WASM init promise is cached forever, so document conversion never retries after a transient failure | `web-renderer/src/document-converter.ts:38-59` | reported |
| B12 | `.editsSaved` is posted only by `EditingSessionController.save()`, which nothing calls; the real save path never posts it | `MarkdownWebView.swift:302-310`, `EditingSessionController.swift:95` | reported |
| B13 | `WKUserContentController` never removes the main-app script message handler on teardown (the QuickLook twin does) | `MarkdownWebView.swift:43-44` vs `PreviewViewController.swift:567-568` | reported |
| B14 | Stale anchor consumption scrolls on a later unrelated render when the anchor target document is already open | `MarkdownWebView.swift:662-667, 990-994` | reported |
| B15 | Regex search compiles and runs user input with no complexity guard | `web-renderer/src/search.ts:200-203` | reported |
| B16 | Line numbers create one `<span>` per code line in a single `innerHTML` assignment | `web-renderer/src/index.ts:552-580` | reported |

## 4. Build, toolchain, and distribution items

### 4.1 macOS deployment target vs Xcode 27 (confirmed)

`project.yml:4-5` sets `deploymentTarget.macOS: "11.0"`. Xcode 27 supports a minimum of 12.0, so
`xcodebuild test` / `make app` fail on this machine with:

```
The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 11.0, but the range of
supported deployment target versions is 12.0 to 27.0.x.
```

CI still passes because `macos-latest` currently ships an older Xcode; it will break the same way
when the runner image moves to 27.

### 4.2 Release DMGs are ad-hoc signed, not notarized (confirmed)

Verified against the published `v1.0.9` DMG:

```
Signature=adhoc          flags=0x2(adhoc)
TeamIdentifier=not set
spctl -a -t exec -> rejected
stapler validate -> no ticket stapled
```

`scripts/release.sh` never invokes `codesign`, `notarytool`, or `stapler`; it relies on the Release
build's own signing. This machine holds exactly one code-signing identity,
`Apple Development: ziadm0386@icloud.com (PSSU5CT8UG)`, and no `Developer ID Application`
certificate, so a distributable, notarizable build cannot be produced here as it stands.
`scripts/verify-release-entitlements.sh` passes because `codesign --verify --strict` also accepts an
ad-hoc signature.

What the ad-hoc signature does and does not break (verified against Sparkle 2.8.1 sources on this
machine):

- **In-app updates keep working.** `SUUpdateValidator.m:281-291` only rejects *removal* of code
  signing (`hostIsCodeSigned && !updateIsCodeSigned`). Signed to signed is accepted, and a change of
  signing identity is allowed while the `SUPublicEDKey` is unchanged. Both old and new builds are
  signed (ad-hoc counts as signed), and `Info.plist:389` still carries the same key.
- **Appcast signing works here.** Running Sparkle's `sign_update` against the published `v1.0.9` DMG
  reproduces the exact signature in `appcast.xml`
  (`TAv8sIqC9g18cBJiIaQXAT09lXp2L39idpjnLTohu1nQ2ZtVWPu1IcEzyUxv1FcnTmRERDPfW8GL7b5dYYENBw==`),
  so the EdDSA private key on this machine is the live one.
- **New users are still blocked.** A fresh DMG download is quarantined and `spctl` rejects the app
  (`Installation.md` documents the manual System Settings / `xattr -cr` workaround). Removing that
  friction needs a `Developer ID Application` certificate (paid Apple Developer Program) plus
  notarization credentials, then a `codesign` + `notarytool` + `stapler` step in `release.sh`.

A Release build on this machine also surfaces `WKProcessPool` as deprecated in macOS 12.0
(`Sources/OshApp/MarkdownWebView.swift:43`, `Sources/OshQuickLook/PreviewViewController.swift:319`).
Both assignments are no-ops on 12.0+ per Apple's deprecation note; they are left in place so this
release does not change process-pool behaviour.

### 4.3 Homebrew instructions point at a tap that does not exist (confirmed)

`AGENTS.md` issue-reply template, `docs/release/RELEASE_PROCESS.md:196`,
`docs/assets/demo.md:175`, and `docs/release/HOMEBREW_SUBMISSION.md:7,92,93` document
`brew install --cask Hyp4tia/tap/osh` and `brew update && brew upgrade --cask osh`. There is no
`Hyp4tia/homebrew-tap` repository (HTTP 404), no tap under the other account, and no `osh` cask in
`homebrew/homebrew-cask`. Users following the documented upgrade path get "cask not found".

### 4.4 Stale tracking document

`docs/debug/DEBUG_PREVIEW_LOADING_ISSUE.md` is unchanged since the initial commit and still reads
`Status: Investigation Started` with every checkbox open. It predates the current QuickLook
pipeline and should be closed out or removed.

## 5. Release plan for v1.0.10

1. Fix 2.1 through 2.4 on `fix/v1.0.10`, one conventional commit per fix, each with its test.
2. Run both suites: `cd web-renderer && npm test` and the XCTest suite.
3. Bump `project.yml` deployment target to 12.0 (required to build with Xcode 27; drops macOS 11
   support) and align the version claims in `INSTALLATION.md` and `README*.md`.
4. Build the DMG with `make dmg`.
5. Distribution signing: needs a `Developer ID Application` certificate plus notarization
   credentials before the DMG is worth publishing to new users. Pending decision.
6. Release, then fix the Homebrew documentation (or publish the tap) so the documented upgrade path
   matches reality.
