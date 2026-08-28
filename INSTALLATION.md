# Installation Guide

Osh is distributed as a standalone macOS application with an integrated QuickLook extension.

---

## 📦 Direct DMG Download (Recommended)

1. Download the latest **`Osh.dmg`** from the [GitHub Releases](https://github.com/Hyp4tia/Osh/releases) page.
2. Double-click the downloaded disk image to open it.
3. Drag **Osh.app** into your **Applications** folder.
4. Launch Osh once from Applications to register the QuickLook extension with macOS.

---

## 🛡️ Opening Osh for the First Time (macOS Gatekeeper)

Osh is currently in public beta and distributed independently outside the Mac App Store. When opening the app for the first time, macOS Gatekeeper may display a dialog stating that the developer cannot be verified.

### Standard macOS Permission Flow:
1. Click **Done** or **Cancel** on the Gatekeeper alert.
2. Open **System Settings** → **Privacy & Security**.
3. Scroll down to the **Security** section.
4. Look for the prompt: *"Osh was blocked from use because it is not from an identified developer."*
5. Click **Open Anyway**.
6. When prompted, click **Open** to confirm.

### Terminal Shortcut (Alternative):
If you prefer using the command line, you can clear the quarantine attribute directly:
```bash
xattr -cr /Applications/Osh.app
```

---

## 🛠️ Building from Source

If you prefer compiling Osh locally from source:

### Prerequisites:
- **macOS 11.0 (Big Sur)** or higher
- **Xcode 14.0+** and Command Line Tools (`xcode-select --install`)
- **XcodeGen** (`brew install xcodegen`)
- **Node.js 18+** and **npm**

### Build Steps:
```bash
# Clone the repository
git clone https://github.com/Hyp4tia/Osh.git
cd Osh

# Build rendering engine, generate Xcode project, and install Release build
make install
```

This will automatically:
1. Build the TypeScript rendering bundle with Vite.
2. Generate the Xcode project using `xcodegen`.
3. Compile the native host app and QuickLook extension in Release mode.
4. Install `Osh.app` directly into `/Applications`.

---

## 🔍 QuickLook Troubleshooting

If pressing `Space` on Markdown or `.skill` files in Finder still shows plain text or fails to render after installing:

1. **Verify Quick Look Extension is Enabled**:
   - Open **System Settings** → **Extensions** (or **Privacy & Security** → **Extensions**).
   - Click **Quick Look**.
   - Ensure **Osh** (or **OshQuickLook**) is checked and active.

2. **Reset the macOS QuickLook Daemon Cache**:
   If macOS cached an older plugin, run the following commands in Terminal:
   ```bash
   qlmanage -r
   qlmanage -r cache
   killall Finder
   ```
3. Re-open Finder, select any `.md` or `.skill` document, and press `Space`.
