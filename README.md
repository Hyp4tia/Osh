<p align="center">
  <img src="docs/assets/icon.png" alt="Osh Icon" width="128" height="128">
  <h1 align="center">Osh <samp>ⲱϣ</samp></h1>
  <p align="center"><strong>A quiet, beautiful Markdown reader & QuickLook extension for macOS.</strong></p>
  <p align="center">
    <a href="https://github.com/Zeyadistired/Osh/releases"><img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?include_prereleases&style=flat-square&color=blue" alt="Release"></a>
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
    <a href="#comparison-with-other-macos-markdown-viewers">Comparison</a> •
    <a href="#shortcuts">Shortcuts</a> •
    <a href="Security_Audit.md">Security Audit</a>
  </p>
</p>

> [!NOTE]
> **Osh is currently in Public Beta (v1.0.4 Beta).**
> Features and polish are evolving rapidly. If you run into anything unexpected or have suggestions, please feel free to [open an issue](https://github.com/Zeyadistired/Osh/issues).

---

## What is Osh?

**Osh** (ⲱϣ) takes its name from the Coptic word for **“to read.”**

A native macOS Markdown reader, editor, and QuickLook extension designed for fast, beautiful, distraction-free reading.

Select any file in Finder, press `Space`, and get an instant, beautifully rendered preview with diagrams, mathematical notation, syntax highlighting, themes, and multilingual text support.

<p align="center">
  <img src="docs/assets/osh-demo.gif" alt="Osh Preview Demo" width="85%">
</p>

---

## ✨ Features

### ⚡ QuickLook & Reader
- **Finder QuickLook** — Preview Markdown instantly with `Space`.
- **Standalone Reader** — Search, zoom, navigate, and read distraction-free.
- **Source Editor** — Edit Markdown directly with `⌘E`.
- **Rendered / Source Views** — Switch between preview and source.

### 🎨 Reading Experience
- **System, Light & Dark Modes**
- **5 Reading Themes** — Default, Sepia, Paper, Midnight, Nord.
- **Adjustable Text Size**
- **High-Contrast Dark Mode**

### 📐 Math & Diagrams
- **Mermaid** — Flowcharts, sequence diagrams, Gantt charts, and more.
- **KaTeX & Typst** — Inline and block mathematical notation.
- **Vega-Lite** — Data visualizations.
- **Graphviz / DOT** — Graph and network diagrams.

### 🌐 Multilingual & RTL
- **Arabic & Hebrew RTL** — Bidirectional text and UI mirroring.
- **6 Languages** — English, Arabic, French, German, Spanish, Chinese.
- **Localized Help** — Guides follow your selected language.

### 🛠️ Writing & Export
- **Native macOS Toolbar**
- **Syntax Highlighting** — Multiple highlight.js themes.
- **GitHub Alerts & Task Lists**
- **Collapsible Blockquotes**
- **PDF, HTML & DOCX Export**

### 🛡️ Security & Privacy
- **HTML Sanitization** — DOMPurify-based sanitization.
- **Hardened CSP** — Restricts scripts and network access.
- **Path & Symlink Containment** — Prevents filesystem boundary escapes.
- **Executable Blocking** — Blocks dangerous application and script targets.
- **No Analytics or Telemetry**
- **Public Security Audit** - Because transparency is one of my core values.

> For implementation details and the current security status, see the [Security Audit](Security_Audit.md).

---

## 📊 How Osh Compares

Osh is designed primarily for **reading Markdown on macOS**, rather than replacing full-featured writing applications.

| | **Osh** | FluxMarkdown | QLMarkdown | MacDown | Marked 2 | Typora |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| Finder Quick Look | **✓** | ✓ | ✓ | — | — | — |
| Standalone reader | **✓** | ✓ | — | ✓ | ✓ | ✓ |
| Markdown editing | **✓** | ~ | — | **✓** | — | **✓** |
| Mermaid | **✓** | ✓ | ✓ | — | ✓ | ✓ |
| Math rendering | **✓** | ✓ | ✓ | ✓ | ✓ | ✓ |
| Typst math | **✓** | **✓** | — | — | — | — |
| RTL / BiDi support | **✓** | — | — | — | ~ | ~ |
| Charts & diagrams | **✓** | **✓** | ~ | — | ✓ | ✓ |
| Reading themes | **5** | 3 | CSS | CSS | Custom | **Extensive** |
| PDF / HTML export | **✓** | ✓ | ✓ | ✓ | **✓** | **✓** |
| DOCX export | **✓** | ~ | — | — | **✓** | **✓** |
| CLI / automation | **✓** | — | ~ | — | **✓** | — |
| Price | **Free** | Free* | Free | Free | Paid | Paid |

### Where Osh Stands Out

- **Finder-first** — Markdown preview directly from `Space`.
- **Reader-first** — Built around reading rather than being a full writing suite.
- **RTL-first** — Arabic and Hebrew are treated as first-class layouts.
- **Scientific Markdown** — Mermaid, KaTeX, Typst, Vega-Lite, and Graphviz.
- **Security-focused** — Sanitization, CSP, path containment, and executable blocking.
- **Open source** — GPL-3.0 and fully inspectable code.

> **Comparison notes:** Features are based on publicly documented capabilities and project releases available at the time of writing. `—` means the capability was not found in the project's public documentation; it does not necessarily mean the software cannot provide it. `~` indicates partial or limited support.
---

## 🚀 Installation

> [!NOTE]
> 🛡️ **Security & Privacy:** A full-codebase security audit is available in [Security_Audit.md](Security_Audit.md), covering static analysis, sandboxing, data handling, and security hardening.

### Download DMG

1. Download the latest **`Osh.dmg`** from the [GitHub Releases](https://github.com/Zeyadistired/Osh/releases) page.
2. Open the disk image and drag **Osh.app** into your **Applications** folder.
3. Launch Osh once from Applications to register the QuickLook extension with macOS.

> [!TIP]
> **Opening Osh on macOS for the first time**
>
> Osh is currently distributed outside the Mac App Store and is not yet notarized with an Apple Developer ID. macOS Gatekeeper may therefore show a warning that the developer cannot be verified.
>
> To open Osh:
>
> 1. Click **Done** on the warning.
> 2. Open **System Settings → Privacy & Security**.
> 3. Scroll to the **Security** section.
> 4. Look for the message indicating that Osh was blocked.
> 5. Click **Open Anyway**.
> 6. Confirm **Open**.
>
> This is normally required only on the first launch.

<details>
<summary><strong>Troubleshooting QuickLook after installation</strong></summary>

If pressing `Space` in Finder still shows plain text after installing:

1. Open **System Settings → Extensions → Quick Look** and ensure **Osh** is enabled.
2. If macOS cached an older QuickLook extension, run:

```bash
qlmanage -r
qlmanage -r cache
killall Finder
```
</details>

---

<p align="center">
  <sub>Inspired by and partially based on <a href="https://github.com/xykong/flux-markdown">Flux-Markdown</a></sub><br>
  <sub>All credit for the original design and implementation goes to the upstream author and its contributors.</sub>
</p>

