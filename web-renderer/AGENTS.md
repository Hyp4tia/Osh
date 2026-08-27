# AGENTS.md - web-renderer

## OVERVIEW
TypeScript/Vite-based Markdown and Typst rendering engine for the macOS host app and QuickLook extension.
Transforms Markdown into HTML with KaTeX math, Mermaid/Vega/Graphviz diagrams, syntax highlighting, Typst rendering, visual diffs, search UI, and RTL layout support.

## STRUCTURE
- `src/`: TypeScript source code.
  - `src/index.ts`: Main entry point. Exposes `window.renderMarkdown` and global rendering hooks.
  - `src/typst-renderer.ts`: Typst document compiler and SVG/HTML renderer.
  - `src/diff-engine.ts` & `src/diff-animator.ts`: Visual diffing engine and transition animations.
  - `src/search.ts` & `src/search-ui.ts`: Document search indexing and interactive UI.
  - `src/table-of-contents.ts` & `src/outline.ts`: Heading parser and sidebar outline navigation.
  - `src/rtl.ts`: Directionality detection and Right-to-Left styling.
  - `src/blockquote-collapse.ts`: Interactive blockquote toggle handlers.
  - `src/help-overlay.ts`: Keyboard shortcuts and help modal.
  - `src/styles/`: Modular CSS styling (GitHub themes, callouts, diffs, RTL, finder-pane, print).
- `test/`: Jest test suites for rendering logic and plugins.
- `dist/`: Compiled assets (Single `index.html` with inlined JS/CSS/Fonts).
- `node_modules/`: Project dependencies.
- `index.html`: Base HTML structure and entry point.
- `vite.config.ts`: Vite build configuration.

## CONVENTIONS
- **Renderer**: `markdown-it` pipeline with KaTeX, Mermaid, Vega, Graphviz, Highlight.js, and Typst.
- **Testing**: Jest tests required for all rendering logic and Markdown extensions.
- **Inter-op**: JS-to-Swift via `window.webkit.messageHandlers.logger`.
- **Styling**: GitHub-style CSS; fonts/assets inlined into single HTML via `vite-plugin-singlefile`.
- **Build**: Output to `dist/index.html` is directly referenced by the Xcode project.

## COMMANDS
- `npm install`: Install dev/prod dependencies.
- `npm run build`: Production build (Vite + SingleFile inlining).
- `npm run dev`: Start Vite development server.
- `npm test`: Execute Jest test suites.

