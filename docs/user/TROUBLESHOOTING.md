# Troubleshooting Guide

> Everyday users should start with [`HELP.md`](HELP.md) (gentle, step-by-step, no internal knowledge required).

## Extension Not Registered

### Issue
Running `qlmanage -m | grep -i markdown` or `pluginkit -m -A -D -p com.apple.quicklook.preview | grep markdownquicklook` finds no extension.

### Root Cause 1: Host app wasn't run through Xcode
The Quick Look extension registration mechanism requires:
1. The extension to be run via **Xcode Run**, not a bare `open` command
2. macOS caches the extension list and needs a special refresh flow

### Root Cause 2: Extension is not sandboxed
If you see something like this in the logs:

```bash
Ignoring mis-configured plugin ... plug-ins must be sandboxed
```

the extension itself doesn't have App Sandbox enabled. `pkd` will refuse to register the plugin even though it is packaged inside the `.app`.

Fix (already done in this repository):

1. Added Entitlements files for both the host app and the extension:
   - `Sources/OshApp/Osh.entitlements`
   - `Sources/OshQuickLook/OshQuickLook.entitlements`

2. Enabled sandboxing in both targets, with read-only access to user-selected files:

   ```xml
   <!-- Required: enable App Sandbox -->
   <key>com.apple.security.app-sandbox</key>
   <true/>

   <!-- Recommended: allow reading the markdown file selected in Finder -->
   <key>com.apple.security.files.user-selected.read-only</key>
   <true/>

   <!-- Development only: allow debugger attach -->
   <key>com.apple.security.get-task-allow</key>
   <true/>
   ```

3. Pointed both targets at their entitlements in `project.yml` (already configured in this repo):

   ```yaml
   Osh:
     settings:
       configs:
         Debug:
           CODE_SIGN_ENTITLEMENTS: Sources/OshApp/Osh.entitlements

   OshQuickLook:
     settings:
       configs:
         Debug:
           CODE_SIGN_ENTITLEMENTS: Sources/OshQuickLook/OshQuickLook.entitlements
   ```

4. Regenerate and build the project:

   ```bash
   make app
   ```

5. Check that the plugin is registered again:

   ```bash
   pluginkit -m -A -D -p com.apple.quicklook.preview | grep -i markdownquicklook
   ```

   Under normal circumstances you should see:

   ```bash
   com.markdownquicklook.app.MarkdownPreview(1.0)
   ```

### Solution: Use Xcode Debugger

#### Method 1: Run via Xcode (recommended)
```bash
# 1. Generate the project
make generate

# 2. Open it in Xcode
open Osh.xcodeproj

# 3. In Xcode:
#    - Select the Markdown scheme
#    - Press Cmd+R to run
#    - Keep the app running

# 4. In a new terminal window:
qlmanage -r
qlmanage -r cache
killall Finder

# 5. Test
#    Select Tests/fixtures/feature-validation.md in Finder and press Space
```

#### Method 2: Test with qlmanage from the CLI
```bash
# Invoke the extension directly through qlmanage (bypasses registration)
qlmanage -p Tests/fixtures/feature-validation.md
```

### Additional Checks

#### View system logs
```bash
# Terminal 1: start log streaming
log stream --predicate 'subsystem contains "QuickLook" OR subsystem contains "MarkdownPreview"' --level debug

# Terminal 2: open a file to trigger Quick Look
# Press Space on a file in Finder
```

#### Verify extension file integrity
```bash
APP_PATH=~/Library/Developer/Xcode/DerivedData/Osh-*/Build/Products/Debug/Osh.app

# Check that the extension exists
ls -la "$APP_PATH/Contents/PlugIns/OshQuickLook.appex/Contents/MacOS"

# Check that web resources were copied correctly
ls -la "$APP_PATH/Contents/PlugIns/OshQuickLook.appex/Contents/Resources/dist"
```

## Known Limitations

### Debug vs Release Build
- **Debug builds** use development signing; the system may impose extra restrictions
- **Workaround**: create a Release build via Product → Archive in Xcode

### Sandbox Restrictions
The macOS App Sandbox restricts file access. If a Markdown file references local images, extra entitlements may be required.

## Plain Text Preview Even Though Extension Is Registered

### Issue
`pluginkit -m -A -D -p com.apple.quicklook.preview | grep -i osh` shows:

```bash
com.zeyadistired.osh.QuickLook(1.0)
```

so the Quick Look extension is recognized and registered. But selecting a `.md` file in Finder and pressing Space still shows only **plain text**, with no Markdown rendering at all (it looks like an ordinary text preview).

### Root Cause: The host app is not the default owner of the Markdown UTI

When macOS picks a Quick Look Preview Extension, it prefers the app that **owns the UTI by default**.

If the host app (`Osh.app`) merely declares itself as an `Alternate` handler
(`LSHandlerRank = Alternate`), the system keeps preferring the built-in
Markdown/plain-text previewer and bypasses our
`com.zeyadistired.osh.QuickLook` extension entirely — making Quick Look
appear "plain-text only" as if the plugin were broken.

**Already fixed in this repository:**

In `Sources/OshApp/Info.plist`, the `CFBundleDocumentTypes`
`LSHandlerRank` was changed to:

```xml
<key>LSHandlerRank</key>
<string>Owner</string>
```

with a comment explaining that we deliberately make the host app the default Owner of the Markdown UTI so Quick Look actually uses our preview extension for `.md` files.

### Fix Steps (to apply in your local environment)

1. **Update your code** (if upgrading from an older version):
   - Make sure `LSHandlerRank` in your local `Sources/OshApp/Info.plist` is `Owner`.

2. **Regenerate and build the project**:

   ```bash
   make app
   ```

   ```bash
   open ~/Library/Developer/Xcode/DerivedData/Osh-*/Build/Products/Debug/Osh.app
   ```

   Or select the **Osh** scheme in Xcode and press `Cmd+R`.

4. **Refresh the Quick Look cache**:

   ```bash
   qlmanage -r
   qlmanage -r cache
   killall Finder
   ```

5. **Test the `.md` preview again**:
   - Select `Tests/fixtures/feature-validation.md` in Finder (see `docs/testing/TESTING.md` for examples)
   - Press Space to trigger Quick Look
   - Expected behavior:
     - Headings, subtitles, code blocks, math formulas, Mermaid diagrams, and task lists all render richly
     - No more plain-text-only display

6. **Optional: confirm the extension is being invoked via system logs**:

   ```bash
   log stream --style compact --predicate 'process == "OshQuickLook"'
   ```

   Then press Space on a `.md` file in Finder; the log should show lines like:

   ```text
   OshQuickLook: viewDidLoad called
   OshQuickLook: preparePreviewOfFile called for: /path/to/file.md
   ```

   That means:
   - Quick Look no longer uses the built-in plain-text previewer
   - Our `PreviewViewController` and bundled web renderer are actually part of the render pipeline
