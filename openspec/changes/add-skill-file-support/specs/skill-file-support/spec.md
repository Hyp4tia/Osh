## ADDED Requirements

### Requirement: Support .skill Files as Native Documents
Osh SHALL support `.skill` files as first-class document types across the host application and the QuickLook extension. `.skill` files SHALL be rendered, edited, and saved without modifying their file extension on disk.

#### Scenario: User opens .skill file via Finder or Open Panel
- **WHEN** a user opens a `.skill` file from Finder, the welcome screen drop zone, or the Open File panel
- **THEN** Osh opens the document, displays its content rendered via the Markdown rendering pipeline, and records the file in Recent Files

#### Scenario: User edits and saves .skill file
- **WHEN** a user edits a `.skill` file in the source editor and saves (⌘S)
- **THEN** the updated text is written atomically to the original `.skill` file path in UTF-8 encoding, and the `.skill` file extension is preserved

#### Scenario: User previews .skill file via QuickLook
- **WHEN** a user selects a `.skill` file in Finder and presses Spacebar
- **THEN** the Osh QuickLook extension renders the document using the Markdown rendering pipeline

#### Scenario: Bidirectional and Unicode text support in .skill files
- **WHEN** a `.skill` file contains Arabic, Hebrew, or mixed LTR/RTL text
- **THEN** the editor and renderer display the content with correct base writing direction and character shaping, preserving UTF-8 integrity across save operations

#### Scenario: Document export from .skill file
- **WHEN** a user exports a `.skill` file to PDF, HTML, or Word (DOCX)
- **THEN** the exported document is generated with the corresponding export extension (`.pdf`, `.html`, `.docx`) derived from the base name, and `.skill` is never used as an export extension
