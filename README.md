# Osh

<p align="center">
  <em>Beautiful Markdown previews in macOS Finder QuickLook</em><br>
  Mermaid • KaTeX • GFM • TOC • Charts • Export
</p>

<p align="center">
  <a href="https://github.com/Zeyadistired/Osh/stargazers">
    <img src="https://img.shields.io/github/stars/Zeyadistired/Osh?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?style=flat-square" alt="Latest release">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/downloads/Zeyadistired/Osh/total?style=flat-square" alt="Downloads">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/Zeyadistired/Osh?style=flat-square" alt="License">
  </a>
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README_ES.md">Español</a> •
  <a href="README_AR.md">العربية</a> •
  <a href="#-quick-install-30-seconds">Install</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

> [!NOTE]
> **Osh is currently in Public Beta (v1.0.0 Beta).** Features and functionality are actively being polished. If you encounter any issues or have feedback, please [open an issue](https://github.com/Zeyadistired/Osh/issues)!

---

## 📖 The Name

**Osh** (ⲱϣ) is Coptic for **“to read”** — minimal and sharp. It reflects the pure reading/viewing experience, without editor clutter.

---

## ✨ Demo

![Osh Demo](docs/assets/demo.gif)

<p align="center">
  <strong>Press <code>Space</code> in Finder → Instant preview with diagrams, math, and more.</strong>
</p>

<p align="center">
  <em>👋 If Osh helps you, consider giving it a</em>
  <a href="https://github.com/Zeyadistired/Osh/stargazers">⭐ star on GitHub</a>!
</p>

---

## 🚀 Quick Install (30 seconds)

### Manual (DMG)

1. Download the latest `Osh.dmg` from [Releases](https://github.com/Zeyadistired/Osh/releases)
2. Open the DMG
3. Drag **Osh.app** to **Applications**

### Homebrew

> Coming soon — a dedicated tap for this fork is not published yet.
> In the meantime, you can also install the original upstream build:
> ```bash
> brew install --cask xykong/tap/flux-markdown
> ```

---

## 💡 Why Osh?

| Feature | Description |
|---------|-------------|
| 📊 **Mermaid Diagrams** | Architecture diagrams, flowcharts, sequence diagrams |
| 🧮 **KaTeX & Typst Math** | Inline and block mathematical expressions |
| 📝 **GFM Support** | Tables, task lists, strikethrough, and GitHub Alerts |
| 🌍 **RTL & Multilingual** | Full Arabic & Hebrew RTL layout and text direction, multi-language UI |
| 🎨 **Code Highlighting** | Syntax highlighting for 40+ languages (GitHub, Monokai, Atom One Dark) |
| 📊 **Charts & Graphs** | Vega, Vega-Lite, and Graphviz (DOT) support |
| 📑 **TOC Panel** | Interactive table of contents with section tracking |
| 📄 **YAML Metadata** | Auto-parses frontmatter into a clean table |
| 📤 **Export** | PDF (Cmd+Shift+P) / HTML (Cmd+Shift+E) / DOCX Word |
| 🔍 **Zoom & Pan** | Cmd +/-/0, Cmd+scroll, pinch gestures |
| 💾 **Position Memory** | Remembers scroll position and last-viewed file |
| 🌓 **Themes & Palettes** | Light, Dark, and System modes + 5 reading palettes (Default, Sepia, Paper, Midnight, Nord) |
| 📂 **File Formats** | Supports .md, .mdx, .rmd, .qmd, .mdoc, .mdc, .mmd, .livemd, .mkd, .mkdn, .mkdown, .mdwn, .mdown, .markdown |

---

## ⚙️ Settings (Cmd+,)

Osh includes a dedicated Settings window to customize your experience:

- **Appearance**: Switch between Light, Dark, or System themes, change interface language, and select reading palettes.
- **Rendering**: Toggle Mermaid, KaTeX, Typst math, line numbers, or Emoji support.
- **Editor**: Adjust base font size, Finder preview font size, and code syntax highlighting themes.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space` | Open QuickLook preview (Finder) |
| `Cmd` + `+` / `-` / `0` | Zoom in / out / reset |
| `Cmd` + `Shift` + `E` | Export as HTML |
| `Cmd` + `Shift` + `P` | Export as PDF |
| `Cmd` + `,` | Open Settings |

---

## 🛠️ Troubleshooting

<details>
<summary><strong>"App is damaged" / "Unidentified developer"</strong></summary>

Run this in Terminal:
```bash
xattr -cr "/Applications/Osh.app"
```
</details>

<details>
<summary><strong>QuickLook not showing updates</strong></summary>

Reset QuickLook cache:
```bash
qlmanage -r
```
</details>

<details>
<summary><strong>Preview not working at all</strong></summary>

1. Check if the app is in `/Applications/`
2. Try restarting Finder: `killall Finder`
3. Check `pluginkit -m -v` for active QuickLook extensions
</details>

**📚 More help:** See [`docs/user/TROUBLESHOOTING.md`](docs/user/TROUBLESHOOTING.md) and [`docs/user/AUTO_UPDATE.md`](docs/user/AUTO_UPDATE.md)

**📖 Documentation index:** [`docs/README.md`](docs/README.md)

---

## Comparison (QuickLook Markdown plugins)

| Feature | Osh | [QLMarkdown](https://github.com/sbarex/QLMarkdown) | [qlmarkdown](https://github.com/whomwah/qlmarkdown) | [PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) |
| --- | --- | --- | --- | --- |
| Install | brew cask / DMG | brew cask / DMG | manual | App Store / DMG |
| Mermaid | Yes | Yes ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mermaid-diagrams)) | Not mentioned | Not mentioned |
| KaTeX / Math | Yes | Yes ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mathematical-expressions)) | Not mentioned | Not mentioned |
| GFM / Alerts | Yes | Yes (cmark-gfm; [ref](https://github.com/sbarex/QLMarkdown/releases/tag/1.0.18)) | Partial (Discount; [ref](https://github.com/whomwah/qlmarkdown#introduction)) | Not mentioned |
| TOC panel | Yes | Not mentioned | No | Not mentioned |
| Charts (Vega/DOT) | Yes | Not mentioned | No | No |
| Export (PDF/HTML) | Yes | No | No | No |
| YAML Frontmatter | Yes | Yes | No | No |
| Themes | Light/Dark/System | CSS-based ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#extensions)) | Not mentioned | Basic controls ([ref](https://github.com/smittytone/PreviewMarkdown#adjusting-the-preview)) |
| Zoom | Yes | Not mentioned | No | Not mentioned |
| Scroll restore | Yes | Not mentioned | No | Not mentioned |

> Notes:
> - Entries are based on public README/release notes at the cited links.
> - If a feature isn't mentioned in sources, we mark it as "Not mentioned".

---

## Build from source

```bash
git clone https://github.com/Zeyadistired/Osh.git
cd Osh
make install
```

## 📄 License

**Osh is licensed under GPL-3.0:**
- ✅ **Free** for personal, educational, and open-source use
- ✅ Any modifications must also be open-sourced under GPL-3.0
- 📜 See [`LICENSE`](LICENSE) for full terms

The original upstream project is dual-licensed by its author; commercial licensing for the original FluxMarkdown is handled by **@xykong** — see [`LICENSE.COMMERCIAL`](LICENSE.COMMERCIAL) or contact **xy.kong@gmail.com**.

---

## 🙏 Attribution

This project is based on [FluxMarkdown](https://github.com/xykong/flux-markdown) by [@xykong](https://github.com/xykong), licensed under GPL-3.0. All credit for the original design and implementation goes to the upstream author and its contributors ([@timokox](https://github.com/timokox), [@marko-cancar](https://github.com/marko-cancar), [@withsivram](https://github.com/withsivram), [@TeroRERO](https://github.com/TeroRERO)).

---

<p align="center">
  <sub>Inspired by and partially based on <a href="https://github.com/shd101wyy/markdown-preview-enhanced">markdown-preview-enhanced</a></sub>
</p>
