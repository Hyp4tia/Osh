<p align="center">
  <img src="docs/assets/icon.png" alt="Osh Icon" width="128" height="128">
  <h1 align="center">Osh <samp>ⲱϣ</samp></h1>
  <p align="center"><strong>Un lector de Markdown y extensión QuickLook elegante y ligero para macOS.</strong></p>
  <p align="center">
    <a href="https://github.com/Zeyadistired/Osh/releases"><img src="https://img.shields.io/github/v/release/Zeyadistired/Osh?include_prereleases&style=flat-square&color=blue" alt="Versión"></a>
    <a href="https://github.com/Zeyadistired/Osh/stargazers"><img src="https://img.shields.io/github/stars/Zeyadistired/Osh?style=flat-square&color=gold" alt="Estrellas"></a>
    <a href="https://github.com/Zeyadistired/Osh/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Zeyadistired/Osh?style=flat-square" alt="Licencia"></a>
    <img src="https://img.shields.io/badge/platform-macOS%2011%2B-lightgrey?style=flat-square" alt="macOS">
  </p>
  <p align="center">
    <a href="README.md">English</a> •
    <a href="README_ES.md">Español</a> •
    <a href="README_AR.md">العربية</a> •
    <a href="#instalación">Instalación</a> •
    <a href="#características">Características</a> •
    <a href="#atajos-de-teclado">Atajos</a>
  </p>
</p>

> [!NOTE]
> **Osh se encuentra actualmente en fase Beta Pública (v1.0.2 Beta).** Las funciones se están optimizando continuamente. Si encuentra algún problema o tiene sugerencias, por favor [abra un issue](https://github.com/Zeyadistired/Osh/issues).

---

## ¿Qué es Osh?

**Osh** (ⲱϣ) proviene de la antigua palabra copta que significa **“leer”**.

A diferencia de los editores pesados o las extensiones de navegador recargadas, Osh fue diseñado específicamente para macOS con un único objetivo: ofrecer una experiencia de lectura y edición de Markdown fluida, hermosa y libre de distracciones.

Seleccione cualquier archivo en Finder, presione la **barra espaciadora** y disfrute de una vista previa instantánea con diagramas interactivos, fórmulas matemáticas y paletas de color cuidadosamente diseñadas.

<p align="center">
  <img src="docs/assets/demo.gif" alt="Demostración de Osh" width="85%">
</p>

---

## ✨ Características Principales

### ⚡ QuickLook y Visor Independiente
- **Vista previa instantánea**: Previsualice archivos en Finder al instante con la barra espaciadora.
- **Vista de columnas de Finder**: Formato adaptado a la columna de vista previa con ajuste de tamaño de fuente.
- **Visor dedicado y archivos recientes**: Navegación completa, zoom, búsqueda y accesos rápidos.
- **Editor de Markdown integrado**: Cambie al modo de edición en cualquier momento (`⌘E`) con soporte nativo de AppKit y escritura bidireccional.

### 🎨 5 Paletas de Lectura
- **Modos Sistema, Claro y Oscuro**: Se adapta dinámicamente a la apariencia de macOS.
- **Paletas personalizadas**: Elija entre **Default**, **Sepia**, **Paper**, **Midnight** y **Nord**.
- **Alto contraste en modo oscuro**: Tipografía calibrada para garantizar una lectura cómoda y descansada.

### 📐 Diagramas y Matemáticas Científicas
- **Diagramas Mermaid**: Diagramas de flujo, secuencias, estados y diagramas de Gantt.
- **Matemáticas KaTeX y Typst**: Fórmulas LaTeX (`$E=mc^2$`) y bloques de sintaxis moderna Typst.
- **Visualizaciones interactivas**: Soporte para gráficos Vega-Lite y Graphviz (DOT).

### 🌐 Soporte Multilingüe y RTL Nativo
- **Diseño de derecha a izquierda (RTL)**: Representación de texto bidireccional perfecta para **árabe** y **hebreo**.
- **Interfaz localizada**: Disponible en español, inglés, árabe, francés, alemán y chino simplificado.
- **Ayuda contextual**: El botón de ayuda en la aplicación abre guías en su idioma configurado.

### 🛠️ Comodidad para Desarrolladores y Escritores
- **Barra de herramientas simplificada**: Acceso rápido para alternar entre vista previa y código fuente, modo edición, Deshacer/Rehacer, ajuste dinámico de tamaño de letra y exportación.
- **Resaltado de código**: Formato limpio con temas seleccionables (GitHub, Monokai, Atom One Dark).
- **Alertas y listas de GitHub**: Bloques de aviso estilizados (`[!NOTE]`, `[!TIP]`) y listas de tareas interactivas.
- **Citas colapsables**: Opción de contraer citas largas automáticamente.
- **Exportación en un clic**: Exporte documentos a **PDF**, **HTML** y **DOCX** con estilos incrustados.

---

## 🚀 Instalación

### Descarga directa (DMG)
1. Descargue el archivo **`Osh.dmg`** desde [GitHub Releases](https://github.com/Zeyadistired/Osh/releases).
2. Abra la imagen de disco y arrastre **Osh.app** a su carpeta de **Aplicaciones**.
3. Inicie Osh una vez desde Aplicaciones para registrar la extensión de QuickLook en macOS.

<details>
<summary><strong>Solución de problemas con QuickLook</strong></summary>

Si al presionar la barra espaciadora todavía aparece texto plano:
1. Abra **Ajustes del Sistema** → **Extensiones** → **Quick Look** y asegúrese de que **Osh** esté activado.
2. Para reiniciar la caché de QuickLook en Terminal:
   ```bash
   qlmanage -r
   qlmanage -r cache
   killall Finder
   ```
3. Si aparece el diálogo de desarrollador no identificado:
   ```bash
   xattr -cr /Applications/Osh.app
   ```
</details>

---

## ⌨️ Atajos de Teclado

| Atajo | Acción |
|:---|:---|
| `Space` | Abrir vista previa QuickLook en Finder |
| `⌘` + `E` | Entrar / Salir del modo de edición Markdown |
| `⇧` + `⌘` + `M` | Alternar entre Vista Previa y Código Fuente |
| `⌘` + `Z` | Deshacer edición |
| `⇧` + `⌘` + `Z` | Rehacer edición |
| `⌘` + `+` / `⌘` + `-` | Aumentar / Reducir zoom del documento |
| `⌘` + `0` | Restablecer zoom al predeterminado |
| `⌘` + `R` | Recargar documento desde el disco |
| `⌘` + `F` | Buscar en el documento |
| `⌘` + `⇧` + `P` | Exportar como PDF |
| `⌘` + `⇧` + `E` | Exportar como HTML |
| `⌘` + `⇧` + `D` | Exportar como Word (DOCX) |
| `⌘` + `,` | Abrir Ajustes |
| `⌘` + `?` | Abrir Guía de Usuario en su idioma |

---

## 📁 Extensiones Compatibles

Osh reconoce y previsualiza de forma nativa múltiples formatos de Markdown y notas científicas:

```
.md  .markdown  .mdown  .mkdn  .mkd  .mdwn  .mdx  .rmd  .qmd  .mdoc  .mdc  .mmd  .livemd
```

---

## 🛠️ Compilación desde el código fuente

Requisitos: macOS 11+, Xcode, Node.js 18+, y `xcodegen` (`brew install xcodegen`).

```bash
# Clonar el repositorio
git clone https://github.com/Zeyadistired/Osh.git
cd Osh

# Compilar e instalar localmente
make install
```

---

## 📄 Licencia y Reconocimiento

- Osh es software de código abierto distribuido bajo la **[Licencia GPL-3.0](LICENSE)**.
- Basado en [FluxMarkdown](https://github.com/xykong/flux-markdown) por [@xykong](https://github.com/xykong) y colaboradores comunitarios.
