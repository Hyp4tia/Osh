# Osh Competitive Analysis and Gap Report

**Version**: based on v1.16.182  
**Date**: 2026-02-23  
**Scope**: macOS Markdown QuickLook plugins + mainstream Markdown previewers

---

## 1. Our current status (v1.16.182)

| Capability | Status |
|------|------|
| Mermaid diagrams | ✅ Bundled locally, works offline |
| KaTeX math formulas | ✅ Bundled locally, fast rendering |
| GFM (tables, task lists, strikethrough) | ✅ |
| GitHub Alerts (NOTE/WARNING/TIP...) | ✅ |
| Vega / Vega-Lite interactive charts | ✅ Exclusive |
| Graphviz / DOT diagrams | ✅ Exclusive |
| TOC sidebar (interactive) | ✅ Exclusive |
| Export PDF / HTML | ✅ Exclusive |
| YAML Frontmatter table display | ✅ |
| Zoom / scroll position memory | ✅ |
| Syntax highlighting for 40+ languages | ✅ |
| Multiple highlight themes (GitHub / Monokai / Atom One Dark) | ✅ |
| Settings window (Cmd+,) | ✅ |
| File formats .mdx / .rmd / .qmd / .mdoc etc. | ✅ |
| Sparkle auto-updates | ✅ |
| i18n Chinese and English | ✅ |

---

## 2. Competitor overview

### 2.1 Direct competitors: QuickLook plugins

| Feature | Osh | QLMarkdown (sbarex) | PreviewMarkdown | qlmarkdown (toland) |
|------|:---:|:---:|:---:|:---:|
| Rendering engine | In-house TS/Vite | cmark-gfm | Markdown-It | Discount (C) |
| Mermaid | ✅ | ✅ | ❌ | ❌ |
| Math formulas | ✅ KaTeX | ✅ MathJax | ❌ | ❌ |
| Vega / Graphviz diagrams | ✅ | ❌ | ❌ | ❌ |
| TOC sidebar | ✅ | ❌ | ❌ | ❌ |
| Export PDF/HTML | ✅ | ❌ | ❌ | ❌ |
| GitHub Alerts | ✅ | ❌ | ❌ | ❌ |
| YAML Frontmatter | ✅ | ✅ | ✅ | ❌ |
| Multiple highlight themes | ✅ | ❌ | ❌ | ❌ |
| Custom CSS | ❌ | ✅ | ❌ | ❌ |
| Local image sandbox approach | ⚠️ | ✅ base64 inline | ❌ | ❌ |
| Footnotes | ❌ | ✅ | ❌ | ❌ |
| Superscript / subscript | ❌ | ✅ | ❌ | ❌ |
| `==highlight==` syntax | ❌ | ✅ | ❌ | ❌ |
| Automatic code language detection | ❌ | ✅ Linguist/Enry | ❌ | ❌ |
| CLI batch conversion tool | ❌ | ✅ | ❌ | ❌ |
| .textbundle / .apib formats | ❌ | ✅ | ❌ | ❌ |
| In-preview search (Cmd+F) | ❌ | ❌ | ❌ | ❌ |
| Raw source toggle | ❌ | ✅ | ❌ | ❌ |
| Smart quotes / dashes | ❌ | ✅ | ❌ | ❌ |
| Zoom | ✅ | ❌ | ❌ | ❌ |
| Scroll position memory | ✅ | ❌ | ❌ | ❌ |
| Font size setting | ✅ | ❌ | ⚠️ Limited | ❌ |
| Homebrew install | ✅ | ✅ | ❌ | ❌ |
| Signed/notarized | ✅ | ❌ | ✅ App Store | ❌ |

### 2.2 Indirect competitors: dedicated Markdown previewers

| Feature | Osh | Marked 2 | Typora | iA Writer |
|------|:---:|:---:|:---:|:---:|
| How it is used | QuickLook (Space key) | Standalone app | Editor | Editor |
| Mermaid | ✅ | ✅ | ✅ | ❌ |
| Math formulas | ✅ KaTeX | ✅ MathJax | ✅ MathJax | ❌ |
| Custom CSS | ❌ | ✅ Deep support | ✅ Theme system | ✅ Template system |
| Custom processors | ❌ | ✅ Arbitrary scripts | ❌ | ❌ |
| Export formats | PDF / HTML | PDF/HTML/DOCX/RTF/ODT | PDF/HTML/DOCX/LaTeX/Epub | PDF/HTML/DOCX |
| Multi-file merge | ❌ | ✅ transclusion | ❌ | ✅ Content Blocks |
| CriticMarkup review | ❌ | ✅ | ❌ | ❌ |
| Document statistics / readability | ❌ | ✅ Word frequency, readability scores | ❌ | ✅ Part-of-speech highlighting |
| Link validation | ❌ | ✅ | ❌ | ❌ |
| Vega / Graphviz | ✅ | ❌ | ❌ | ❌ |
| Instant QuickLook preview | ✅ | ❌ | ❌ | ❌ |
| No need to open an app | ✅ | ❌ Requires opening Marked 2 | ❌ | ❌ |
| Price | Free/GPL | Paid ($13.99) | Paid ($14.99) | Paid ($49.99/year) |

---

## 3. Gap analysis

### 3.1 High-priority gaps

#### ① In-preview search (Cmd+F)
- **Status**: ❌ Missing
- **User demand**: 🔥🔥🔥 High frequency; it is the core differentiator of the paid product Peek
- **Implementation path**: implement a custom search overlay at the JS layer; WKWebView supports the `findString:` API
- **Effort estimate**: medium (pure JS + Swift bridge)

#### ② Robustness of local image rendering
- **Status**: ⚠️ Not fully verified whether relative-path images render correctly under sandbox restrictions
- **User demand**: 🔥🔥🔥 One of the most frequent complaints
- **Implementation path**: follow QLMarkdown's base64 inline approach, or handle via a `local-md://` scheme
- **Effort estimate**: small (LocalSchemeHandler foundation already exists)

#### ③ Raw source toggle
- **Status**: ❌ Missing
- **User demand**: 🔥🔥 Used frequently in developer scenarios; one-click toggle between rendering ↔ raw Markdown
- **Implementation path**: switch the displayed content at the JS layer and add a toolbar button on the Swift side
- **Effort estimate**: small

### 3.2 Medium-priority gaps

#### ④ Custom CSS
- **Status**: ❌ Missing; Settings only has built-in themes
- **User demand**: 🔥🔥 A must-have for power users
- **Implementation path**: add a CSS file path input in Settings, read the file from Swift, and inject it into the WebView
- **Effort estimate**: medium

#### ⑤ Footnotes
- **Status**: ❌ Missing
- **User demand**: 🔥🔥 Commonly used by academic writing users
- **Implementation path**: the `markdown-it-footnote` plugin, a one-line integration
- **Effort estimate**: minimal

#### ⑥ Superscript / subscript (`H~2~O`, `x^2^`)
- **Status**: ❌ Missing
- **User demand**: 🔥 Chemistry and math users
- **Implementation path**: the `markdown-it-sub` + `markdown-it-sup` plugins
- **Effort estimate**: minimal

#### ⑦ `==highlight==` syntax
- **Status**: ❌ Missing
- **User demand**: 🔥🔥 High frequency among Obsidian / note-taking users
- **Implementation path**: the `markdown-it-mark` plugin
- **Effort estimate**: minimal

#### ⑧ Smart quotes / dashes (`---` → em dash)
- **Status**: ❌ Missing
- **User demand**: 🔥 Writing-oriented users
- **Implementation path**: `markdown-it-smartarrows` or markdown-it's `typographer` option
- **Effort estimate**: minimal (a single configuration option)

#### ⑨ Auto-refresh (update after an external editor saves)
- **Status**: ❌ Updates only when QuickLook is re-triggered
- **User demand**: 🔥 Pairs with external-editor workflows
- **Implementation path**: watch file changes via `DispatchSourceFileSystemObject` within the QuickLook lifecycle
- **Effort estimate**: medium; needs to handle QuickLook sandbox restrictions

### 3.3 Low-priority gaps

| Feature | Notes |
|------|------|
| CLI batch conversion tool | Large engineering effort, small audience |
| Document statistics (word count, reading time) | Weak demand in the QuickLook context |
| .textbundle / .apib formats | Niche demand |
| Automatic code language detection (Linguist) | Requires integrating a Go library; high cost |
| Multi-file merge (transclusion) | A Marked 2 feature; beyond QuickLook's scope |
| CriticMarkup | Review scenarios don't fit QuickLook's scope |

---

## 4. Our core moat

| Moat | Description |
|--------|------|
| **Vega / Vega-Lite interactive charts** | The only QuickLook plugin supporting them; a killer feature for data science / engineering users |
| **Graphviz / DOT** | Same as above; the standard diagram format for system design documents |
| **TOC sidebar** | Unique among QuickLook plugins; unmatched for navigating long documents |
| **Export PDF/HTML directly within QuickLook** | Normally requires opening Marked 2; we can do it while previewing with the Space key |
| **Multiple highlight themes** | No other QuickLook plugin has this feature |
| **Rendering performance** | After 7 performance optimizations (v1.15), bundle code-splitting + lazy loading; leading competitors in both cold start and hot rendering |
| **Distribution status (to be completed)** | Currently ad-hoc signed and not notarized, and no Homebrew cask published; a Developer ID certificate + notarization are needed before it can become an installation-experience advantage |

---

## 5. Strategic recommendations

### Short term (1-2 releases)

Quickly capture low-effort, high-visibility features:

```
markdown-it-footnote  →  Footnote support
markdown-it-sub/sup   →  Superscript / subscript
markdown-it-mark      →  ==highlight== syntax
typographer: true     →  Smart quotes / dashes
Raw Toggle button     →  Source / rendered view toggle
```

Together these 5 items take no more than 1 day of effort, but they directly close the most visible syntax gaps with QLMarkdown.

### Medium term (3-4 releases)

Invest in "differentiating killer features":

1. **In-preview Cmd+F search** — once implemented it can serve as a core marketing point, directly competing with the paid product Peek
2. **Local image sandbox fix** — eliminates the most frequent user complaints
3. **Custom CSS** — attracts power users migrating from QLMarkdown

### Long term (ongoing direction)

- Continuously optimize rendering performance (our technical moat)
- Explore Finder sidebar Preview Pane compatibility
- Track compatibility with new macOS versions (Sequoia / Tahoe)

---

## 6. References

- [sbarex/QLMarkdown README](https://github.com/sbarex/QLMarkdown/blob/main/README.md)
- [sbarex/QLMarkdown Issues](https://github.com/sbarex/QLMarkdown/issues)
- [Marked 2 Help](https://marked2app.com/help/)
- [Typora official site](https://typora.io)
- [iA Writer official site](https://ia.net/writer)
- User feedback sources: GitHub Issues, Reddit r/MacOS, r/Markdown
