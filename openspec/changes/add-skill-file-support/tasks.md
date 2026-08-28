## 1. UTI & Configuration
- [x] 1.1 Add `com.osh.skill` to `CFBundleDocumentTypes` in `Sources/OshApp/Info.plist`
- [x] 1.2 Add `com.osh.skill` to `UTImportedTypeDeclarations` in `Sources/OshApp/Info.plist`
- [x] 1.3 Add `com.osh.skill` to `QLSupportedContentTypes` in `Sources/OshQuickLook/Info.plist`

## 2. Document Handling & UI
- [x] 2.1 Update `MarkdownDocument.readableContentTypes` in `Sources/OshApp/MarkdownDocument.swift`
- [x] 2.2 Update `WelcomeView.allowedContentTypes` in `Sources/OshApp/WelcomeView.swift`

## 3. Test Fixtures & Automated Tests
- [x] 3.1 Create `Tests/fixtures/test.skill` with rich Markdown, code blocks, frontmatter, and Arabic/Hebrew RTL text
- [x] 3.2 Update `Tests/OshTests/FileExtensionTests.swift` with `.skill` UTI declaration and fixture verification tests
- [x] 3.3 Update `Tests/OshTests/DocumentEditingAndThemeTests.swift` with `.skill` read/edit/save/export/RTL test coverage

## 4. Build, Verification & Regeneration
- [x] 4.1 Run `make generate` to regenerate Xcode project
- [x] 4.2 Run Swift test suites and verify all tests pass
- [x] 4.3 Perform manual verification of opening, rendering, editing, saving, and QuickLook previews
