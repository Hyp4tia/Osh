<p align="center">
  <img src="docs/assets/icon.png" alt="Osh Icon" width="128" height="128">
  <h1 align="center">Osh <samp>ⲱϣ</samp></h1>
  <p align="center"><strong>Un lector de Markdown y extensión QuickLook elegante y ligero para macOS.</strong></p>
  <p align="center">
    <a href="https://github.com/Hyp4tia/Osh/releases"><img src="https://img.shields.io/github/v/release/Hyp4tia/Osh?include_prereleases&style=flat-square&color=blue" alt="Versión"></a>
    <a href="https://github.com/Hyp4tia/Osh/stargazers"><img src="https://img.shields.io/github/stars/Hyp4tia/Osh?style=flat-square&color=gold" alt="Estrellas"></a>
    <a href="https://github.com/Hyp4tia/Osh/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Hyp4tia/Osh?style=flat-square" alt="Licencia"></a>
    <img src="https://img.shields.io/badge/platform-macOS%2011%2B-lightgrey?style=flat-square" alt="macOS">
  </p>
  <p align="center">
    <a href="README.md">English</a> •
    <a href="README_ES.md">Español</a> •
    <a href="README_AR.md">العربية</a> •
    <a href="INSTALLATION.md">Instalación</a> •
    <a href="FEATURES.md">Características</a> •
    <a href="COMPARISON.md">Comparación</a> •
    <a href="SHORTCUTS.md">Atajos</a> •
    <a href="Security_Audit.md">Auditoría de Seguridad</a>
  </p>
</p>

> [!NOTE]
> **Osh (v1.0.7)** — Si encuentras algún problema o tienes sugerencias, ¡no dudes en [abrir un issue](https://github.com/Hyp4tia/Osh/issues)!

---

## ¿Qué es Osh?

**Osh** (ⲱϣ) proviene de la antigua palabra copta que significa **“leer”**.

A diferencia de los editores pesados o las extensiones de navegador recargadas, Osh fue diseñado específicamente para macOS con un único objetivo: ofrecer una experiencia de lectura y edición de Markdown fluida, hermosa y libre de distracciones.

Seleccione cualquier archivo en Finder, presione la **barra espaciadora** y disfrute de una vista previa instantánea con diagramas interactivos, fórmulas matemáticas y paletas de color cuidadosamente diseñadas.

<p align="center">
  <img src="docs/assets/osh-demo.gif" alt="Demostración de Osh" width="85%">
</p>

---

## ✨ Características Principales

### ⚡ QuickLook y Visor Independiente
- **Vista previa instantánea**: Previsualice archivos en Finder al instante con la barra espaciadora.
- **Vista de columnas de Finder**: Formato adaptado a la columna de vista previa con ajuste de tamaño de fuente.
- **Visor dedicado y archivos recientes**: Navegación completa, zoom, búsqueda y accesos rápidos.
- **Editor de Markdown integrado**: Cambie al modo de edición en cualquier momento (`⌘E`) con soporte nativo de AppKit y escritura bidireccional.
- **Soporte de paquetes y archivos `.skill` para IA**: Visualización, edición y QuickLook de paquetes ZIP de habilidades de agentes (`SKILL.md`) y archivos de texto plano preservando todos los binarios y recursos.

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

### 🛡️ Seguridad Avanzada y Privacidad Total
- **Sanitización HTML con DOMPurify**: Filtra rigurosamente todo el código HTML de Markdown antes de insertarlo en el DOM, neutralizando XSS, scripts maliciosos y controladores de eventos (`onerror`, `onload`).
- **Política de Seguridad de Contenido Estricta (CSP)**: Entorno WebKit blindado que bloquea la ejecución dinámica no autorizada de scripts y la extracción de datos por red.
- **Contención de Rutas y Enlaces Simbólicos**: Resolución canónica de enlaces simbólicos antes de verificar los límites del directorio, impidiendo escapes (`../`) o acceso indebido al sistema de archivos.
- **Bloqueo de Ejecutables y Aplicaciones**: Impide la ejecución de archivos `.app`, `.sh`, `.command`, `.pkg`, `.dmg` o scripts de automatización desde enlaces del documento.
- **100% Offline y Cero Telemetría**: Sin análisis, rastreadores ni conexiones en segundo plano. Completamente documentado y verificado en [Security_Audit.md](Security_Audit.md).

---

## 📊 Comparación con otros visores de Markdown en macOS

| Característica / Métrica | Osh | FluxMarkdown | QLMarkdown | MacDown (3000) | Marked 2 | Typora |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Vista previa QuickLook (`Espacio`)** | 🟢 **Sí** | 🟢 Sí | 🟢 Sí | 🟡 Solo en fork | 🔴 No *(App separada)* | 🔴 No |
| **Modo de vista de columnas en Finder** | 🟢 **Sí** | 🟢 Sí | 🟡 Limitado | 🔴 No | 🔴 No | 🔴 No |
| **Visor de documentos independiente** | 🟢 **Sí** | 🟡 Básico | 🔴 No | 🟢 Sí | 🟢 Sí | 🟢 Sí |
| **Editor de Markdown integrado (`⌘E`)** | 🟢 **Sí** | 🔴 No | 🔴 No | 🟢 Sí | 🔴 No *(Solo externo)* | 🟢 Sí *(WYSIWYG)* |
| **Soporte para fórmulas y sintaxis Typst** | 🟢 **Sí (WASM/KaTeX)** | 🔴 No | 🔴 No | 🔴 No | 🔴 No | 🔴 No |
| **Fórmulas LaTeX / KaTeX** | 🟢 **Sí** | 🟢 Sí | 🟢 Sí | 🟡 MathJax | 🟢 Sí | 🟢 Sí |
| **Diagramas Mermaid y gráficos** | 🟢 **Sí** | 🟢 Sí | 🟡 Básico | 🔴 No | 🟢 Sí | 🟢 Sí |
| **Diseño RTL nativo (Árabe / Hebreo)** | 🟢 **Sí (Motor BiDi)** | 🔴 No | 🔴 No | 🔴 No | 🟡 CSS básico | 🟡 Básico |
| **Paletas de lectura** | 🟢 **5 Integradas** | 🟡 3 (Sistema/C/O) | 🟡 CSS personalizado | 🟡 Solo código | 🟢 CSS personalizado | 🟢 Extensas |
| **Alertas de GitHub (`[!NOTE]`)** | 🟢 **Sí** | 🟢 Sí | 🟡 Básico | 🔴 No | 🟢 Sí | 🟡 Básico |
| **Formatos de exportación** | **PDF, HTML, DOCX** | PDF, HTML | HTML | PDF, HTML | PDF, HTML, DOCX, RTF | PDF, HTML, DOCX, LaTeX |
| **Herramienta CLI de exportación** | 🟢 **`osh export`** | 🔴 No | 🟡 Solo HTML | 🔴 No | 🟢 `marked` CLI | 🔴 No |
| **Sanitización HTML (DOMPurify)** | 🟢 **Sí (Inmune a XSS)** | 🔴 No | 🟡 Básico (cmark) | 🔴 No | 🟢 Sí | 🟡 Chromium |
| **Política de Seguridad Estricta (CSP)** | 🟢 **Sí (Reforzado)** | 🔴 No | 🔴 No | 🔴 No | 🟢 Sí | 🟡 Básico |
| **Protección contra Traversal y Enlaces** | 🟢 **Sí (Auditado)** | 🔴 No | 🟡 Básico | 🔴 No | 🟢 Sí | 🟡 App Sandbox |
| **Bloqueo de Ejecutables (.app, .sh)** | 🟢 **Sí (Estricto)** | 🔴 No | 🔴 No | 🔴 No | 🟢 Sí | 🟡 App Sandbox |
| **Privacidad y telemetría (Offline)** | 🟢 **100% Offline** | 🟢 100% Offline | 🟢 100% Offline | 🟢 100% Offline | 🟢 100% Offline | 🟡 Cuenta/Auth |
| **Informe de Auditoría de Seguridad** | 🟢 **[Sí (Verificado)](Security_Audit.md)** | 🔴 No | 🔴 No | 🔴 No | 🔴 No | 🔴 No |
| **Arquitectura y tamaño** | **Nativo Swift (<25MB)** | Nativo Swift (<25MB) | Nativo Swift (<15MB) | Nativo Obj-C/Swift | Nativo Swift/Obj-C | Electron (~200MB+ RAM) |
| **Licencia y precio** | **Gratis (GPL-3.0)** | Gratis (MIT) | Gratis (GPL-2.0) | Gratis (MIT) | De pago ($14.99–$19.99) | De pago ($14.99) |

---

## 🚀 Instalación

> [!NOTE]
> 🛡️ **Seguridad y privacidad:** Consulte el informe completo de auditoría de seguridad en [Security_Audit.md](Security_Audit.md).

### Descarga directa (DMG)
1. Descargue el archivo **`Osh.dmg`** desde [GitHub Releases](https://github.com/Hyp4tia/Osh/releases).
2. Abra la imagen de disco y arrastre **Osh.app** a su carpeta de **Aplicaciones**.
3. Inicie Osh una vez desde Aplicaciones para registrar la extensión de QuickLook en macOS.

> [!TIP]
> **Abrir Osh por primera vez en macOS (aviso de Gatekeeper):**
> Al distribuirse de forma independiente fuera de la Mac App Store, macOS Gatekeeper puede mostrar un aviso de verificación al abrirlo por primera vez. Para abrir Osh:
> 1. Haga clic en **Aceptar / Listo (Done)** en el aviso.
> 2. Abra **Ajustes del Sistema (System Settings)** → **Privacidad y seguridad (Privacy & Security)**.
> 3. Desplácese hacia abajo hasta la sección **Seguridad (Security)**.
> 4. Verá el mensaje *“Se bloqueó el uso de Osh…”*.
> 5. Haga clic en **Abrir de todos modos (Open Anyway)**.
> 6. Confirme haciendo clic en **Abrir (Open)**.
>
> *(Solo necesita realizar este paso una vez).*

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
git clone https://github.com/Hyp4tia/Osh.git
cd Osh

# Compilar e instalar localmente
make install
```

---

## 📄 Licencia y Reconocimiento

- Osh es software de código abierto distribuido bajo la **[Licencia GPL-3.0](LICENSE)**.
- Basado en [FluxMarkdown](https://github.com/xykong/flux-markdown) por [@xykong](https://github.com/xykong) y colaboradores comunitarios.
- Motor de conversión de documentos a Markdown impulsado por [Firecrawl AnyDoc](https://github.com/firecrawl/anydoc).
