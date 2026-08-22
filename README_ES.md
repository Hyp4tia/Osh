# Osh

<p align="center">
  <em>Hermosas previsualizaciones de Markdown en QuickLook de macOS Finder</em><br>
  Mermaid • KaTeX • GFM • TOC • Gráficos • Exportar
</p>

<p align="center">
  <a href="https://github.com/Zeyadistired/Osh/stargazers">
    <img src="https://img.shields.io/github/stars/Zeyadistired/Osh?style=social" alt="Estrellas en GitHub">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?style=flat-square" alt="Última versión">
  </a>
  <a href="https://github.com/Zeyadistired/Osh/releases">
    <img src="https://img.shields.io/github/downloads/Zeyadistired/Osh/total?style=flat-square" alt="Descargas">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/Zeyadistired/Osh?style=flat-square" alt="Licencia">
  </a>
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README_ES.md">Español</a> •
  <a href="README_AR.md">العربية</a> •
  <a href="#-instalación-rápida-30-segundos">Instalación</a> •
  <a href="#-solución-de-problemas">Solución de problemas</a>
</p>

---

## ✨ Demo

![Demo de Osh](docs/assets/demo.gif)

<p align="center">
  <strong>Presiona <code>Space</code> (Espacio) en Finder → Previsualización instantánea con diagramas, matemáticas y más.</strong>
</p>

<p align="center">
  <em>👋 Si Osh te ayuda, ¡considera darle una</em>
  <a href="https://github.com/Zeyadistired/Osh/stargazers">⭐ estrella en GitHub</a>!
</p>

---

## 🚀 Instalación rápida (30 segundos)

### Manual (DMG)

1. Descarga el archivo `Osh.dmg` más reciente desde [Releases](https://github.com/Zeyadistired/Osh/releases)
2. Abre el DMG
3. Arrastra **Osh.app** a **Aplicaciones**

### Homebrew

> Próximamente — el tap dedicado de este fork aún no está publicado.
> Mientras tanto, también puedes instalar la versión original:
> ```bash
> brew install --cask xykong/tap/flux-markdown
> ```

---

## 💡 ¿Por qué Osh?

| Característica | Descripción |
|---------|-------------|
| 📊 **Diagramas Mermaid** | Diagramas de arquitectura, diagramas de flujo, diagramas de secuencia |
| 🧮 **Matemáticas KaTeX** | Expresiones matemáticas en línea y en bloque |
| 📝 **Soporte GFM** | Tablas, listas de tareas, tachado y alertas de GitHub |
| 🎨 **Resaltado de código** | Resaltado de sintaxis para más de 40 lenguajes |
| 📊 **Gráficos y tablas** | Soporte para Vega, Vega-Lite y Graphviz (DOT) |
| 📑 **Panel TOC** | Tabla de contenidos interactiva con seguimiento de secciones |
| 📄 **Metadatos YAML** | Analiza automáticamente el frontmatter en una tabla limpia |
| 📤 **Exportar** | PDF (Cmd+Shift+P) / HTML (Cmd+Shift+E) — ¡Funcionalidad solicitada por usuarios de V2EX! |
| 🔍 **Zoom y paneo** | Cmd +/-/0, Cmd+scroll, gestos de pellizco |
| 💾 **Memoria de posición** | Recuerda la posición de desplazamiento y el último archivo visto |
| 🌓 **Temas** | Modos claro, oscuro y sincronizado con el sistema |
| 📂 **Formatos de archivo** | Soporta .md, .mdx, .rmd, .qmd, .mdoc, .mdc, .mmd, .livemd, .mkd, .mkdn, .mkdown, .mdwn, .mdown, .markdown |

---

## ⚙️ Configuración (Cmd+,)

Osh incluye una ventana de Configuración dedicada para personalizar tu experiencia:

- **Apariencia**: Cambia entre los temas Claro, Oscuro o del Sistema.
- **Renderizado**: Alterna el soporte para Mermaid, KaTeX o Emojis.
- **Editor**: Ajusta el tamaño de fuente base y elige temas de resaltado de código (GitHub, Monokai, Atom One Dark, etc.).

---

## ⌨️ Atajos de teclado

| Atajo | Acción |
|----------|--------|
| `Space` | Abrir previsualización QuickLook (Finder) |
| `Cmd` + `+` / `-` / `0` | Zoom in / out / reset |
| `Cmd` + `Shift` + `E` | Exportar como HTML |
| `Cmd` + `Shift` + `P` | Exportar como PDF |
| `Cmd` + `,` | Abrir Configuración |

---

## 🛠️ Solución de problemas

<details>
<summary><strong>"La aplicación está dañada" / "Desarrollador no identificado"</strong></summary>

Ejecuta esto en la Terminal:
```bash
xattr -cr "/Applications/Osh.app"
```
</details>

<details>
<summary><strong>QuickLook no muestra actualizaciones</strong></summary>

Reinicia la caché de QuickLook:
```bash
qlmanage -r
```
</details>

<details>
<summary><strong>La previsualización no funciona en absoluto</strong></summary>

1. Verifica si la aplicación está en `/Applications/`
2. Intenta reiniciar Finder: `killall Finder`
3. Comprueba `pluginkit -m -v` para extensiones de QuickLook activas
</details>

**📚 Más ayuda:** Consulta [`docs/user/TROUBLESHOOTING.md`](docs/user/TROUBLESHOOTING.md) y [`docs/user/AUTO_UPDATE.md`](docs/user/AUTO_UPDATE.md)

**📖 Índice de documentación:** [`docs/README.md`](docs/README.md)

---

## Comparación (Plugins de Markdown para QuickLook)

| Característica | Osh | [QLMarkdown](https://github.com/sbarex/QLMarkdown) | [qlmarkdown](https://github.com/whomwah/qlmarkdown) | [PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) |
| --- | --- | --- | --- | --- |
| Instalación | brew cask / DMG | brew cask / DMG | manual | App Store / DMG |
| Mermaid | Sí | Sí ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mermaid-diagrams)) | No mencionado | No mencionado |
| KaTeX / Math | Sí | Sí ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mathematical-expressions)) | No mencionado | No mencionado |
| GFM / Alertas | Sí | Sí (cmark-gfm; [ref](https://github.com/sbarex/QLMarkdown/releases/tag/1.0.18)) | Parcial (Discount; [ref](https://github.com/whomwah/qlmarkdown#introduction)) | No mencionado |
| Panel TOC | Sí | No mencionado | No | No mencionado |
| Gráficos (Vega/DOT) | Sí | No mencionado | No | No |
| Exportar (PDF/HTML) | Sí | No | No | No |
| YAML Frontmatter | Sí | Sí | No | No |
| Temas | Claro/Oscuro/Sistema | Basado en CSS ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#extensions)) | No mencionado | Controles básicos ([ref](https://github.com/smittytone/PreviewMarkdown#adjusting-the-preview)) |
| Zoom | Sí | No mencionado | No | No mencionado |
| Restaurar scroll | Sí | No mencionado | No | No mencionado |

> Notas:
> - Las entradas se basan en los README/notas de lanzamiento públicos en los enlaces citados.
> - Si una característica no se menciona en las fuentes, la marcamos como "No mencionado".

---

## Construir desde el código fuente

```bash
git clone https://github.com/Zeyadistired/Osh.git
cd Osh
make install
```

## 📄 Licencia

**Osh se distribuye bajo GPL-3.0:**
- ✅ **Gratis** para uso personal, educativo y de código abierto
- ✅ Cualquier modificación también debe ser de código abierto bajo GPL-3.0
- 📜 Ver [`LICENSE`](LICENSE) para los términos completos

El proyecto original upstream tiene doble licencia por su autor; la licencia comercial del FluxMarkdown original es gestionada por **@xykong** — ver [`LICENSE.COMMERCIAL`](LICENSE.COMMERCIAL) o contactar a **xy.kong@gmail.com**.

---

## 🙏 Atribución

Este proyecto está basado en [FluxMarkdown](https://github.com/xykong/flux-markdown) de [@xykong](https://github.com/xykong), licenciado bajo GPL-3.0. Todo el mérito del diseño e implementación original corresponde al autor upstream y sus colaboradores ([@timokox](https://github.com/timokox), [@marko-cancar](https://github.com/marko-cancar), [@withsivram](https://github.com/withsivram), [@TeroRERO](https://github.com/TeroRERO)).

---

<p align="center">
  <sub>Inspirado y parcialmente basado en <a href="https://github.com/shd101wyy/markdown-preview-enhanced">markdown-preview-enhanced</a></sub>
</p>
