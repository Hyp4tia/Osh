# Change: Add .skill File Support

## Why

`.skill` files (used by AI agent skill definitions and instructions) are text/Markdown-compatible documents that developers frequently read, review, and edit. Users need Osh to open, preview, edit, save, and QuickLook `.skill` files as first-class documents while preserving the `.skill` file extension on disk.

## What Changes

- Register `com.osh.skill` UTI in `Sources/OshApp/Info.plist` and `Sources/OshQuickLook/Info.plist` conforming to `public.plain-text`.
- Add `com.osh.skill` to `CFBundleDocumentTypes` in `Sources/OshApp/Info.plist` and `QLSupportedContentTypes` in `Sources/OshQuickLook/Info.plist`.
- Update `MarkdownDocument.readableContentTypes` to recognize `.skill` files.
- Update `WelcomeView.allowedContentTypes` to allow opening `.skill` files via `NSOpenPanel` and drag-and-drop.
- Maintain extension preservation invariant (`example.skill` → edit → save → `example.skill`).
- Maintain export naming behavior (`example.skill` → export PDF/HTML/DOCX → `example.pdf` / `example.html` / `example.docx`).
- Add comprehensive unit and integration tests verifying `.skill` UTI registration, read/write/edit flows, QuickLook support, and Unicode/RTL preservation.

## Impact

- Affected specs: `skill-file-support` (new)
- Affected code:
  - `Sources/OshApp/Info.plist`
  - `Sources/OshQuickLook/Info.plist`
  - `Sources/OshApp/MarkdownDocument.swift`
  - `Sources/OshApp/WelcomeView.swift`
  - `Tests/fixtures/test.skill`
  - `Tests/OshTests/FileExtensionTests.swift`
  - `Tests/OshTests/DocumentEditingAndThemeTests.swift`
