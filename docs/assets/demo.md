# Osh Demo - "The Finder Markdown HUD"

> This is a *showcase* file for Osh.
> 
> Recording script (10-15s): select `demo.md` -> press Space -> click a TOC item -> pause at Mermaid -> pause at KaTeX -> show code highlight -> zoom once.

---

## Table of contents

- [GFM Showcase](#gfm-showcase)
- [Mermaid: Architecture](#mermaid-architecture)
- [KaTeX: Math](#katex-math)
- [Code: Multi-language](#code-multi-language)
- [Links: External / Local / Anchor](#links-external--local--anchor)

---

## GFM Showcase

### Tables

| Capability | Example | Why it looks good |
| --- | --- | --- |
| Tables | crisp alignment | fast scanning |
| Task lists | done markers | status at a glance |
| Emojis | :rocket: :sparkles: :tada: | visual anchor |
| Blockquotes | callouts | highlight tips |

### Task list

- [x] Mermaid diagram renders
- [x] KaTeX renders
- [x] Code highlighting renders
- [x] TOC highlights current section
- [ ] Record the final GIF (10-15s)

### Callout

> Tip: Keep the demo GIF under ~8MB so GitHub renders quickly.

---

## Mermaid: Architecture

```mermaid
flowchart LR
  A[Finder selection] --> B[Space]
  B --> C[QuickLook]
  C --> D[Osh Preview]

  subgraph Preview[Preview pipeline]
    D --> E[Markdown + GFM]
    E --> F[Mermaid]
    E --> G[KaTeX]
    E --> H[Highlight]
    E --> I[TOC]
  end

  I --> J[Readable docs]
```

---

## KaTeX: Math

Inline:

- $E = mc^2$
- $\sum_{i=1}^{n} i = \frac{n(n+1)}{2}$
- $\nabla \cdot \vec{E} = \frac{\rho}{\varepsilon_0}$

Block:

$$
\left(\frac{a+b}{2}\right)^2 + \left(\frac{a-b}{2}\right)^2 = \frac{a^2+b^2}{2}
$$

$$
\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}
$$

---

## Code: Multi-language

### Swift

```swift
import Foundation

struct Osh {
  let name = "Osh"
  let features = ["GFM", "Mermaid", "KaTeX", "TOC", "Zoom"]
}

print("\(Osh().name) - Ready in Finder")
```

### Shell

```bash
brew install --cask Zeyadistired/tap/osh

# Refresh QuickLook cache
qlmanage -r
```

### JSON

```json
{
  "app": "Osh",
  "platform": "macOS",
  "entry": "QuickLook",
  "features": ["gfm", "mermaid", "katex", "toc", "zoom", "scroll-memory"]
}
```

---

## Links: External / Local / Anchor

- External: https://github.com/Zeyadistired/Osh
- Anchor: [Jump to Mermaid](#mermaid-architecture)
- Local relative (main app): [demo.md](./demo.md)

---

## Smooth scroll section

### Neon paragraphs

Osh makes Finder previews feel like a mini markdown reader: fast, readable, and diagram-ready.

Osh makes Finder previews feel like a mini markdown reader: fast, readable, and diagram-ready.

Osh makes Finder previews feel like a mini markdown reader: fast, readable, and diagram-ready.

Osh makes Finder previews feel like a mini markdown reader: fast, readable, and diagram-ready.

Osh makes Finder previews feel like a mini markdown reader: fast, readable, and diagram-ready.
