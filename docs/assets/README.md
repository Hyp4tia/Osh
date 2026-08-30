# Osh Documentation & Marketing Assets

This directory houses official visual assets and demonstration materials referenced by [`README.md`](../../README.md), [`README_AR.md`](../../README_AR.md), [`README_ES.md`](../../README_ES.md), and online documentation.

---

## 📁 Asset Catalog

| File | Type | Description | Target Dimensions / Size | Referenced By |
| :--- | :--- | :--- | :--- | :--- |
| **`icon.png`** | PNG | Official Osh application icon (transparent background). | 512×512 or 1024×1024 px (< 500 KB) | `README.md`, `README_AR.md`, `README_ES.md` |
| **`osh-demo.gif`** / **`demo.gif`** | GIF | Animated preview showcasing Finder QuickLook & key features. | ~1200×800 px, 10–15s (< 6–8 MB) | `README.md`, `README_AR.md`, `README_ES.md` |
| **`osh-welcome.png`** | PNG | MacBook mockup of the Osh welcome launcher screen. | 1024×768 px (< 1 MB) | `README.md`, `README_AR.md`, `README_ES.md` |
| **`osh-reader.png`** | PNG | MacBook mockup of the Osh document reader / editor preview. | 1024×768 px (< 1 MB) | `README.md`, `README_AR.md`, `README_ES.md` |
| **`demo.md`** | Markdown | Showcase file used for demo recordings & rendering validation. | Plain text Markdown | Testing & recording |
| **`demo-light.png`** *(optional)* | PNG | High-DPI screenshot of QuickLook preview in Light Mode. | 2× Retina (@2x) | Documentation |
| **`demo-dark.png`** *(optional)* | PNG | High-DPI screenshot of QuickLook preview in Dark Mode. | 2× Retina (@2x) | Documentation |
| **`themes.png`** *(optional)* | PNG | Side-by-side comparison of the 5 reading themes. | 2× Retina (@2x) | Documentation |

---

## 🎬 `demo.gif` Recording Workflow

Use [`demo.md`](./demo.md) as the standard script to record clean, consistent demo GIFs.

### Recommended Capture Setup
1. **Screen Area**: Capture a 1440×900 or 1280×800 window region (clean desktop background).
2. **App State**: Ensure Osh QuickLook extension is active (`qlmanage -r` if needed).
3. **Appearance**: Switch to macOS Dark Mode or Sepia/Nord theme for high visual appeal.

### Step-by-Step Recording Sequence (10–15 Seconds)
1. **0:00 – 0:02 (Finder Trigger)**: Select `demo.md` in Finder and press `Space` to bring up the QuickLook preview.
2. **0:02 – 0:05 (Navigation & TOC)**: Smoothly click a Table of Contents item to jump down the document.
3. **0:05 – 0:08 (Diagrams & Math)**: Pause briefly at the **Mermaid architecture diagram** and **Typst / KaTeX math blocks**.
4. **0:08 – 0:11 (RTL & Multi-language)**: Scroll through the **Arabic RTL section** and syntax-highlighted code blocks.
5. **0:11 – 0:14 (Interaction / Editor)**: Toggle the In-App Source Editor (`⌘E`) or switch reading themes.
6. **0:14 – 0:15 (Wrap up)**: Smooth stop.

### Optimization Tips
- **Frame Rate**: Record at 30 fps or 60 fps, downsample to 20–25 fps for GIF conversion.
- **Conversion Tool**: Use [`gifski`](https://gif.ski) or `ffmpeg` with palettegen for smooth gradients and crisp text:
  ```bash
  ffmpeg -i recording.mov -vf "fps=20,scale=1000:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" docs/assets/demo.gif
  ```
- **Size Budget**: Keep `demo.gif` under **8 MB** (ideally < 5 MB) for instant loading on GitHub.

---

## 🖼️ Icon Asset Guidelines

- Always export `icon.png` directly from [`Sources/OshApp/Assets.xcassets/AppIcon.appiconset`](../../Sources/OshApp/Assets.xcassets/AppIcon.appiconset).
- Use sRGB color profile with an alpha transparency channel.
