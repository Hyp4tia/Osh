# Osh Features & Capabilities

Osh is a native macOS Markdown and AI `.skill` reader, editor, and QuickLook extension built for fast, distraction-free reading with scientific and multilingual typography.

---

## ⚡ QuickLook & Document Reader

- **Finder Spacebar QuickLook**: Preview `.md`, `.markdown`, and `.skill` documents instantly in Finder without opening an external application.
- **Finder Column View Previews**: Native dynamic layout adapted for Finder preview sidebars with adjustable typography.
- **Standalone Document Viewer**: Dedicated window mode with in-document search (`⌘F`), continuous zoom (`⌘+` / `⌘-` / `⌘0`), table of contents navigation, and recent files browser.
- **Integrated Markdown Editor**: Toggle editing mode at any time (`⌘E`) to view or edit raw source Markdown with AppKit text support and live rendering preview.
- **Document Restoration**: Remembers window size, zoom preferences, and scroll positions across sessions.

---

## 📦 AI Agent `.skill` Support

- **ZIP-Based Skill Packages**: Transparently inspects, decompresses, and renders packaged AI agent skill bundles (such as OpenAI Codex / agent skills containing `SKILL.md` or subfolder `<skill-name>/SKILL.md`).
- **Lossless Archive Modification**: When editing and saving a packaged `.skill` document, only the targeted `SKILL.md` is rewritten. All other archive files (images, PDFs, JSON configurations, scripts, and directory structures) are preserved byte-for-byte with original compression.
- **Plain-Text Compatibility**: Full support for plain UTF-8 `.skill` documents, preserving the original file extension without renaming to `.md`.
- **Security Validation**: Archive safety inspections rejecting directory traversal (`../`), absolute paths, and oversized files.

---

## 🎨 Reading Experience & Themes

- **Dynamic macOS Appearance**: Automatically adapts to system light and dark mode appearances.
- **5 Curated Color Themes**:
  - **Default**: Clean high-contrast modern typography.
  - **Sepia**: Warm, relaxed tone for reading long documents.
  - **Paper**: Subtle warm editorial style resembling physical paper.
  - **Midnight**: Deep OLED dark theme with calibrated contrast.
  - **Nord**: Arctic-inspired cool blue palette.
- **Adjustable Text Size**: Per-window and global font scaling.

---

## 📐 Scientific Math & Diagrams

- **KaTeX**: Fast, offline LaTeX mathematical expression rendering for inline (`$...$`) and display (`$$...$$`) math blocks.
- **Typst Math**: Support for modern Typst syntax (`$ ... $`).
- **Mermaid Diagrams**: Native rendering for Flowcharts, Sequence diagrams, Gantt charts, Class diagrams, State diagrams, and Entity Relationship diagrams.
- **Vega & Vega-Lite**: Interactive statistical charts and data visualizations.
- **Graphviz / DOT**: Graph and network layout diagrams.

---

## 🌐 Multilingual & RTL Support

- **First-Class Arabic & Hebrew RTL**: True right-to-left layout mirroring for Arabic and Hebrew documents with mixed LTR/RTL bidirectional embedding.
- **6 Localized Languages**: Full user interface localization in English, Arabic (`ar`), Spanish (`es`), French (`fr`), German (`de`), and Simplified Chinese (`zh-Hans`).
- **Localized Help Guides**: Built-in help documentation automatically delivered in your chosen interface language.

---

## 🛠️ Formatting & Export

- **GitHub Flavored Markdown (GFM)**: Tables, task lists (`- [x]`), strikethrough, autolinks, and footnotes.
- **GitHub Alerts**: Visual callouts (`NOTE`, `TIP`, `IMPORTANT`, `WARNING`, `CAUTION`).
- **Syntax Highlighting**: 40+ programming languages with multiple theme choices (GitHub, Monokai, Atom One Dark).
- **Document Exporting**: Export documents cleanly to **PDF**, standalone self-contained **HTML**, and formatted **DOCX** files (`⇧⌘E`).

---

## 🔄 Document Conversion

- **Local Document to Markdown**: Convert `.pdf`, `.docx`, `.xlsx`, `.pptx`, and `.csv` files directly into clean Markdown using Firecrawl AnyDoc WebAssembly.
- **Excel & Spreadsheet Support**: Automatically parses multiple worksheets into distinct Markdown sections and tables with column headers and cell values.
- **PowerPoint & Presentation Support**: Extracts slide titles, body text, lists, and tables into structured Markdown slides.
- **CSV Support**: Formats tabular data into clean GitHub-Flavored Markdown tables with quote handling and full Unicode support.
- **In-Memory Draft Editing**: Converted files open immediately as new, unsaved documents in Osh, leaving the original source documents untouched.
- **Offline & Private**: Conversion runs 100% locally on your Mac with zero network calls or cloud dependencies.

---

## 🛡️ Security & Privacy

- **App Sandbox**: Sandboxed execution with read-only file permissions and security-scoped bookmark protection.
- **DOMPurify Sanitization**: Strict HTML sanitization on all rendered output, preventing XSS vectors.
- **Strict Content Security Policy (CSP)**: Blocks inline script injections and unauthorized outbound network telemetry.
- **Symlink & Path Containment**: Resolves filesystem symlinks and blocks path traversal attempts.
- **Executable Blocking**: Prevents Markdown links from opening binary applications (`.app`, `.sh`, `.command`, etc.).
- **Zero Telemetry**: Completely private with zero user tracking or data collection.
