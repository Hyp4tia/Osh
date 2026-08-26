<p align="center">
  <h1 align="center">Osh <samp>ⲱϣ</samp></h1>
  <p align="center"><strong>A quiet, beautiful Markdown reader & QuickLook extension for macOS.</strong></p>
  <p align="center">
    <a href="https://github.com/Zeyadistired/Osh/releases/latest"><img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?style=flat-square&color=blue" alt="Release"></a>
    <a href="https://github.com/Zeyadistired/Osh/stargazers"><img src="https://img.shields.io/github/stars/Zeyadistired/Osh?style=flat-square&color=gold" alt="Stars"></a>
    <a href="https://github.com/Zeyadistired/Osh/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Zeyadistired/Osh?style=flat-square" alt="License"></a>
    <img src="https://img.shields.io/badge/platform-macOS%2011%2B-lightgrey?style=flat-square" alt="macOS">
  </p>
  <p align="center">
    <a href="README.md">English</a> •
    <a href="README_ES.md">Español</a> •
    <a href="README_AR.md">العربية</a> •
    <a href="#installation">Installation</a> •
    <a href="#features">Features</a> •
    <a href="#shortcuts">Shortcuts</a>
  </p>
</p>

> [!NOTE]
> **Osh is currently in Public Beta (v1.0.0 Beta).** Features and polish are evolving rapidly. If you run into anything unexpected or have suggestions, please feel free to [open an issue](https://github.com/Zeyadistired/Osh/issues)!

---

## What is Osh?

**Osh** (ⲱϣ) takes its name from the Coptic word for **“to read”**. 

Unlike heavy text editors or bloated browser plugins, Osh is built specifically for macOS to do one thing exceptionally well: provide an effortless, distraction-free reading experience for Markdown documents.

Select any file in Finder, press `Space`, and enjoy instant, beautifully rendered Markdown with rich diagrams, crisp mathematical equations, and tailored color palettes.

<p align="center">
  <img src="docs/assets/demo.gif" alt="Osh Preview Demo" width="85%">
</p>

---

## ✨ Features at a Glance

### ⚡ Seamless QuickLook & Standalone Reader
- **Instant Spacebar Preview**: Inspect documents directly in Finder without launching external tools.
- **Finder Column View**: Automatically formats previews inside Finder's preview pane with custom font scaling.
- **Recent Files & Standalone Viewer**: Open documents directly in Osh with full zoom, search, and navigation controls.

### 🎨 5 Refined Reading Themes
- **System, Light & Dark**: Dynamically harmonizes with macOS appearance settings.
- **Tailored Palettes**: Choose between **Default**, **Sepia**, **Paper**, **Midnight**, and **Nord**.
- **High-Contrast Dark Mode**: Carefully calibrated typography ensures optimal contrast across all reading modes.

### 📐 Diagrams & Scientific Math
- **Mermaid Diagrams**: Renders flowcharts, sequence diagrams, state machines, and Gantt charts.
- **KaTeX & Typst Math**: Full inline (`$E=mc^2$`) and block LaTeX equations alongside modern Typst math blocks.
- **Interactive Visualizations**: Built-in support for Vega-Lite charts and Graphviz (DOT).

### 🌐 First-Class Multilingual & RTL
- **Native Right-to-Left Layout**: Dedicated bidirectional text rendering and UI mirroring for **Arabic** and **Hebrew**.
- **Localized Interface**: Complete translations in English, Arabic, French, German, Spanish, and Simplified Chinese.
- **Context-Aware Help**: In-app Help documentation routes directly to beginner guides in your selected language.

### 🛠️ Developer & Writer Comfort
- **Code Syntax Highlighting**: Clean highlighting powered by highlight.js with selectable themes (Default, GitHub, Monokai, Atom One Dark).
- **GitHub Alerts & Task Lists**: Native callout blocks (`[!NOTE]`, `[!TIP]`, `[!WARNING]`) and interactive checklists.
- **Collapsible Blockquotes**: Keep long documents neat with automatic blockquote collapsing.
- **One-Click Export**: Export cleanly formatted **PDF**, **HTML**, and **DOCX** files with all styling embedded.

---

## 🚀 Installation

### Download DMG
1. Download the latest **`Osh.dmg`** or **`Osh 1.0.0 Beta.dmg`** from the [GitHub Releases](https://github.com/Zeyadistired/Osh/releases) page.
2. Open the disk image and drag **Osh.app** into your **Applications** folder.
3. Launch Osh once from Applications to register the QuickLook plugin with macOS.

<details>
<summary><strong>Troubleshooting QuickLook after install</strong></summary>

If pressing `Space` in Finder still shows plain text after installing:
1. Open **System Settings** → **Extensions** → **Quick Look** and ensure **Osh** is enabled.
2. If macOS cached an older plugin, run this in Terminal:
   ```bash
   qlmanage -r
   qlmanage -r cache
   killall Finder
   ```
3. If macOS Gatekeeper shows an unidentified developer dialog:
   ```bash
   xattr -cr /Applications/Osh.app
   ```
</details>

---

## ⌨️ Shortcuts

| Shortcut | Action |
|:---|:---|
| `Space` | Toggle QuickLook preview in Finder |
| `⌘` + `+` | Zoom in document |
| `⌘` + `-` | Zoom out document |
| `⌘` + `0` | Reset zoom to default |
| `⌘` + `,` | Open Settings |
| `⌘` + `F` | Search document contents |
| `⌘` + `⇧` + `P` | Export as PDF |
| `⌘` + `⇧` + `E` | Export as HTML |
| `⌘` + `?` | Open Language-Aware User Guide |

---

## 📁 Supported Extensions

Osh natively recognizes and previews a wide range of Markdown dialects and scientific notes:

```
.md  .markdown  .mdown  .mkdn  .mkd  .mdwn  .mdx  .rmd  .qmd  .mdoc  .mdc  .mmd  .livemd
```

---

## 🛠️ Building from Source

Requirements: macOS 11+, Xcode, Node.js 18+, and `xcodegen` (`brew install xcodegen`).

```bash
# Clone the repository
git clone https://github.com/Zeyadistired/Osh.git
cd Osh

# Build and install locally
make install
```

---

## 📄 License & Attribution

- Osh is open-source software licensed under the **[GPL-3.0 License](LICENSE)**.
- Based upon [FluxMarkdown](https://github.com/xykong/flux-markdown) by [@xykong](https://github.com/xykong) and community contributors.
