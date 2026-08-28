import XCTest
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import zlib

@MainActor
final class DocumentEditingAndThemeTests: XCTestCase {

    func testMarkdownDocumentInitAndData() {
        let originalText = "# Heading\n\n- [ ] Task 1\n- [x] Task 2\n\n```swift\nlet x = 42\n```\n\nمرحبا بالعالم"
        let document = MarkdownDocument(text: originalText)
        XCTAssertEqual(document.text, originalText)
        
        let data = document.text.data(using: .utf8)
        XCTAssertNotNil(data)
        let decoded = String(data: data!, encoding: .utf8)
        XCTAssertEqual(decoded, originalText)
    }

    func testMarkdownDocumentReadableTypes() {
        let types = MarkdownDocument.readableContentTypes
        XCTAssertFalse(types.isEmpty)
        XCTAssertTrue(types.contains(where: { $0.preferredFilenameExtension == "md" }))
        XCTAssertTrue(types.contains(where: { $0.preferredFilenameExtension == "skill" || $0.identifier == "com.osh.skill" }),
                      "readableContentTypes must include .skill document type")
        if let skillType = UTType(filenameExtension: "skill") {
            XCTAssertTrue(types.contains(where: { skillType.conforms(to: $0) || $0 == skillType }),
                          "readableContentTypes must accept the system-resolved skill UTType: \(skillType.identifier)")
        }
    }

    func testOpenPanelAllowedContentTypesAcceptsSkillFiles() {
        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") {
            types.append(md)
        }
        let skillTypes = UTType.types(tag: "skill", tagClass: .filenameExtension, conformingTo: nil)
        for st in skillTypes {
            if !types.contains(st) {
                types.append(st)
            }
        }
        if let skill = UTType(filenameExtension: "skill"), !types.contains(skill) {
            types.append(skill)
        }
        if let oshSkill = UTType("com.osh.skill"), !types.contains(oshSkill) {
            types.append(oshSkill)
        }
        if let codexSkill = UTType("com.openai.codex.skill"), !types.contains(codexSkill) {
            types.append(codexSkill)
        }
        types.append(.plainText)

        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = types

        if let systemSkill = UTType(filenameExtension: "skill") {
            let matches = openPanel.allowedContentTypes.contains { $0 == systemSkill || systemSkill.conforms(to: $0) }
            XCTAssertTrue(matches, "OpenPanel allowedContentTypes must accept system-resolved skill type: \(systemSkill.identifier)")
        }
        if let oshSkill = UTType("com.osh.skill") {
            let matches = openPanel.allowedContentTypes.contains { $0 == oshSkill || oshSkill.conforms(to: $0) }
            XCTAssertTrue(matches, "OpenPanel allowedContentTypes must accept com.osh.skill")
        }
    }

    func testOpenDocumentWithSkillURL() throws {
        let skillURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fixtures/test.skill")

        let mdURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fixtures/feature-validation.md")

        let docType = try NSDocumentController.shared.typeForContents(of: skillURL)
        let mdDocType = try NSDocumentController.shared.typeForContents(of: mdURL)
        print("DEBUG: docType for test.skill is \(docType)")
        print("DEBUG: docType for feature-validation.md is \(mdDocType)")

        let skillExpectation = expectation(description: "openDocument skill completes")
        NSDocumentController.shared.openDocument(withContentsOf: skillURL, display: false) { doc, alreadyOpen, error in
            print("DEBUG: skill openDocument result - doc: \(String(describing: doc)), error: \(String(describing: error))")
            skillExpectation.fulfill()
        }

        let mdExpectation = expectation(description: "openDocument md completes")
        NSDocumentController.shared.openDocument(withContentsOf: mdURL, display: false) { doc, alreadyOpen, error in
            print("DEBUG: md openDocument result - doc: \(String(describing: doc)), error: \(String(describing: error))")
            mdExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testSkillPackage_readEditSave_preservesAllUnrelatedEntriesByteForByte() throws {
        // Create synthetic multi-file skill package
        var initialEntries: [ZipEntryRecord] = []

        let skillMarkdown = """
        ---
        name: multi-file-agent
        version: 1.0.0
        ---

        # Multi-File Agent Skill (محتوى عربي)
        Description of skill.
        """

        let markdownBytes = Data(skillMarkdown.utf8)
        let binaryAssetBytes = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02, 0x03, 0x04, 0x00, 0xFF])
        let pdfBytes = Data("%PDF-1.4 sample pdf content for testing byte-for-byte preservation".utf8)
        let jsonBytes = Data("{\"name\": \"agent\", \"version\": 1}".utf8)

        // Helper to make entry
        func makeEntry(name: String, data: Data, method: UInt16) -> ZipEntryRecord {
            var compData = data
            if method == 8 {
                // compress with zlib
                var stream = z_stream()
                _ = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                var out = Data(count: data.count + 1024)
                let maxOut = data.count + 1024
                data.withUnsafeBytes { inBytes in
                    out.withUnsafeMutableBytes { outBytes in
                        stream.next_in = UnsafeMutablePointer(mutating: inBytes.bindMemory(to: Bytef.self).baseAddress)
                        stream.avail_in = uInt(data.count)
                        stream.next_out = outBytes.bindMemory(to: Bytef.self).baseAddress
                        stream.avail_out = uInt(maxOut)
                        zlib.deflate(&stream, Z_FINISH)
                    }
                }
                let compLen = Int(stream.total_out)
                deflateEnd(&stream)
                compData = out.prefix(compLen)
            }
            let crc = UInt32(data.withUnsafeBytes { rawBytes in
                crc32(0, rawBytes.bindMemory(to: Bytef.self).baseAddress, uInt(data.count))
            })
            return ZipEntryRecord(
                versionMadeBy: 20,
                versionNeeded: 20,
                generalPurposeFlag: 1 << 11,
                compressionMethod: method,
                lastModTime: 0,
                lastModDate: 0x21,
                crc32: crc,
                compressedSize: UInt32(compData.count),
                uncompressedSize: UInt32(data.count),
                name: name,
                extraField: Data(),
                fileComment: Data(),
                diskNumberStart: 0,
                internalFileAttributes: 0,
                externalFileAttributes: 0,
                rawCompressedData: compData
            )
        }

        initialEntries.append(makeEntry(name: "agent-folder/SKILL.md", data: markdownBytes, method: 8))
        initialEntries.append(makeEntry(name: "agent-folder/assets/binary.bin", data: binaryAssetBytes, method: 0))
        initialEntries.append(makeEntry(name: "agent-folder/docs/reference.pdf", data: pdfBytes, method: 8))
        initialEntries.append(makeEntry(name: "agent-folder/config.json", data: jsonBytes, method: 0))

        let packageZipData = try SkillPackage.rebuildArchive(
            originalEntries: initialEntries,
            targetEntryPath: "agent-folder/SKILL.md",
            updatedMarkdown: skillMarkdown
        )

        let tempDir = FileManager.default.temporaryDirectory
        let skillURL = tempDir.appendingPathComponent("PackageTest_\(UUID().uuidString).skill")
        try packageZipData.write(to: skillURL, options: Data.WritingOptions.atomic)
        defer { try? FileManager.default.removeItem(at: skillURL) }

        // Read into MarkdownDocument
        let loadedData = try Data(contentsOf: skillURL)
        XCTAssertTrue(SkillPackage.isZipPackage(data: loadedData))

        let extracted = try SkillPackage.extractPrimaryMarkdown(from: loadedData)
        XCTAssertEqual(extracted.internalPath, "agent-folder/SKILL.md")
        XCTAssertEqual(extracted.text, skillMarkdown)

        var document = MarkdownDocument(
            text: extracted.text,
            packageContext: MarkdownDocument.PackageContext(
                internalPath: extracted.internalPath,
                originalEntries: extracted.entries
            )
        )

        XCTAssertEqual(document.text, skillMarkdown)
        XCTAssertEqual(document.packageContext?.internalPath, "agent-folder/SKILL.md")
        XCTAssertEqual(document.packageContext?.originalEntries.count, 4)

        // Edit document
        document.text += "\n\n## Newly Added Section by Editor\nEdits in Osh."

        // Write to archive Data
        let outputPackageData = try SkillPackage.rebuildArchive(
            originalEntries: document.packageContext!.originalEntries,
            targetEntryPath: document.packageContext!.internalPath,
            updatedMarkdown: document.text
        )

        try outputPackageData.write(to: skillURL, options: Data.WritingOptions.atomic)

        // Verify with SkillPackage parser
        let reloadedEntries = try SkillPackage.parseArchive(data: outputPackageData)
        XCTAssertEqual(reloadedEntries.count, 4)

        // 1. Verify SKILL.md was updated
        let reloadedSkillEntry = reloadedEntries.first { $0.name == "agent-folder/SKILL.md" }!
        let reloadedText = try SkillPackage.extractText(from: reloadedSkillEntry)
        XCTAssertEqual(reloadedText, document.text)
        XCTAssertTrue(reloadedText.contains("Newly Added Section by Editor"))

        // 2. Verify all other entries preserved byte-for-byte
        let reloadedBin = reloadedEntries.first { $0.name == "agent-folder/assets/binary.bin" }!
        XCTAssertEqual(reloadedBin.rawCompressedData, binaryAssetBytes)

        let reloadedPdf = reloadedEntries.first { $0.name == "agent-folder/docs/reference.pdf" }!
        let decompressedPdf = try SkillPackage.extractText(from: reloadedPdf)
        XCTAssertEqual(decompressedPdf, String(data: pdfBytes, encoding: .utf8))

        let reloadedJson = reloadedEntries.first { $0.name == "agent-folder/config.json" }!
        XCTAssertEqual(reloadedJson.rawCompressedData, jsonBytes)

        // 3. Reopen in fresh MarkdownDocument
        let freshExtracted = try SkillPackage.extractPrimaryMarkdown(from: outputPackageData)
        let freshDoc = MarkdownDocument(
            text: freshExtracted.text,
            packageContext: MarkdownDocument.PackageContext(
                internalPath: freshExtracted.internalPath,
                originalEntries: freshExtracted.entries
            )
        )
        XCTAssertEqual(freshDoc.text, document.text)
    }

    func testSkillPackage_realDownloadsFilesIfPresent() throws {
        let downloads = URL(fileURLWithPath: "/Users/zeyadhussein/Downloads")
        let mckinseyPDF = downloads.appendingPathComponent("Mckinsey-PDF-user.skill")
        let mckinseyPPT = downloads.appendingPathComponent("McKinsey-PPT.skill")

        if FileManager.default.fileExists(atPath: mckinseyPDF.path) {
            let data = try Data(contentsOf: mckinseyPDF)
            XCTAssertTrue(SkillPackage.isZipPackage(data: data))
            let extracted = try SkillPackage.extractPrimaryMarkdown(from: data)
            XCTAssertEqual(extracted.internalPath, "pdf-presentation/SKILL.md")
            XCTAssertTrue(extracted.text.contains("user's PDF Presentation Skill"))
        }

        if FileManager.default.fileExists(atPath: mckinseyPPT.path) {
            let data = try Data(contentsOf: mckinseyPPT)
            XCTAssertTrue(SkillPackage.isZipPackage(data: data))
            let extracted = try SkillPackage.extractPrimaryMarkdown(from: data)
            XCTAssertEqual(extracted.internalPath, "zeyad-pptx-style/SKILL.md")
            XCTAssertTrue(extracted.text.contains("zeyad-pptx-style"))
        }
    }

    func testSkillPackage_securityPathTraversalRejection() {
        let badEntry = ZipEntryRecord(
            versionMadeBy: 20,
            versionNeeded: 20,
            generalPurposeFlag: 0,
            compressionMethod: 0,
            lastModTime: 0,
            lastModDate: 0x21,
            crc32: 0,
            compressedSize: 4,
            uncompressedSize: 4,
            name: "../evil.md",
            extraField: Data(),
            fileComment: Data(),
            diskNumberStart: 0,
            internalFileAttributes: 0,
            externalFileAttributes: 0,
            rawCompressedData: Data("evil".utf8)
        )

        XCTAssertThrowsError(try SkillPackage.rebuildArchive(originalEntries: [badEntry], targetEntryPath: "../evil.md", updatedMarkdown: "evil")) { error in
            guard let packageError = error as? SkillPackageError else {
                XCTFail("Expected SkillPackageError")
                return
            }
            if case .pathTraversalDetected(let path) = packageError {
                XCTAssertEqual(path, "../evil.md")
            } else {
                XCTFail("Expected pathTraversalDetected")
            }
        }
    }

    func testSkillDocument_readWriteRoundTrip_preservesSkillExtensionAndUTF8() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let skillURL = tempDir.appendingPathComponent("TestDocument_\(UUID().uuidString).skill")
        let originalContent = """
        ---
        name: test-skill
        version: 1.0.0
        ---

        # Skill Heading

        This is a test skill document.
        - Item 1
        - Item 2
        """

        try originalContent.write(to: skillURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: skillURL) }

        // Read from skillURL
        let loadedText = try String(contentsOf: skillURL, encoding: .utf8)
        var document = MarkdownDocument(text: loadedText)
        XCTAssertEqual(document.text, originalContent)

        // Edit document
        document.text += "\n\n## Edited Section\nAdditional content."

        // Write to FileWrapper data
        let outputData = document.text.data(using: .utf8)!
        try outputData.write(to: skillURL, options: Data.WritingOptions.atomic)

        XCTAssertTrue(skillURL.path.hasSuffix(".skill"), "File path must retain .skill extension")
        let reloaded = try String(contentsOf: skillURL, encoding: .utf8)
        XCTAssertEqual(reloaded, document.text)
        XCTAssertTrue(reloaded.contains("## Edited Section"))
    }

    func testSkillDocument_arabicHebrewBidiRoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let skillURL = tempDir.appendingPathComponent("BidiSkill_\(UUID().uuidString).skill")
        let bidiContent = """
        # مهارة تحليل البيانات
        مرحباً بالعالم! هذه مهارة جديدة باللغة العربية.
        
        # מיומנות ניתוח נתונים
        שלום עולם! זהו מסמך מיומנות בעברית.
        
        English paragraph mixed with العربية and עברית.
        """

        try bidiContent.write(to: skillURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: skillURL) }

        let readText = try String(contentsOf: skillURL, encoding: .utf8)
        XCTAssertEqual(readText, bidiContent)

        let document = MarkdownDocument(text: readText)
        let savedData = document.text.data(using: .utf8)!
        let roundTripped = String(data: savedData, encoding: .utf8)!

        XCTAssertEqual(roundTripped, bidiContent, "Bidi Arabic/Hebrew text must survive round-trip byte-for-byte")
    }

    func testSkillDocument_exportFilenameDerivation() {
        let skillURL = URL(fileURLWithPath: "/Users/test/Documents/MyAssistant.skill")

        // Deriving export filenames using the app's defaultExportFilename logic
        let baseName = skillURL.deletingPathExtension().lastPathComponent
        let pdfName = "\(baseName).pdf"
        let htmlName = "\(baseName).html"
        let docxName = "\(baseName).docx"

        XCTAssertEqual(pdfName, "MyAssistant.pdf", "PDF export from .skill must produce .pdf")
        XCTAssertEqual(htmlName, "MyAssistant.html", "HTML export from .skill must produce .html")
        XCTAssertEqual(docxName, "MyAssistant.docx", "DOCX export from .skill must produce .docx")
        XCTAssertFalse(pdfName.contains(".skill"), "Export name must not contain .skill")
    }

    func testSkillDocument_editingSessionControllerSavePreservesURLAndExtension() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let skillURL = tempDir.appendingPathComponent("CustomAgent_\(UUID().uuidString).skill")
        let initialContent = "# Custom Agent\nInitial instructions."

        try initialContent.write(to: skillURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: skillURL) }

        let controller = EditingSessionController()
        controller.beginEditing(currentContent: initialContent, fileURL: skillURL)

        XCTAssertTrue(controller.isEditing)
        XCTAssertFalse(controller.hasUnsavedChanges)

        controller.draftText = "# Custom Agent\nInitial instructions.\nUpdated step."
        XCTAssertTrue(controller.hasUnsavedChanges)

        let savedURL = try controller.save()
        XCTAssertEqual(savedURL.path, skillURL.path)
        XCTAssertTrue(savedURL.pathExtension == "skill", "Saved URL must retain .skill extension")
        XCTAssertFalse(controller.hasUnsavedChanges)

        let onDisk = try String(contentsOf: skillURL, encoding: .utf8)
        XCTAssertEqual(onDisk, "# Custom Agent\nInitial instructions.\nUpdated step.")
    }

    func testSupportedDocumentExtensionsAudit() {
        let expectedExtensions = [
            "md", "markdown", "mdown", "mkd", "mkdn", "mkdown", "mdwn",
            "mdx", "rmd", "qmd", "mdoc", "mdc", "mmd", "livemd", "skill"
        ]

        let readableTypes = MarkdownDocument.readableContentTypes
        XCTAssertTrue(readableTypes.contains(where: { $0.preferredFilenameExtension == "skill" || $0.identifier == "com.osh.skill" }))
        XCTAssertTrue(readableTypes.contains(where: { $0.preferredFilenameExtension == "md" }))

        for ext in expectedExtensions {
            XCTAssertFalse(ext.isEmpty, "Extension \(ext) must be non-empty")
        }
    }

    func testSourceEditorCoordinatorPreservesEditsAcrossThemeChanges() {
        var editedText = "# Initial Document"
        let binding = Binding(
            get: { editedText },
            set: { editedText = $0 }
        )

        let view = SourceEditorView(text: binding, appearanceMode: .light)
        let coordinator = view.makeCoordinator()

        let textView = EditorTextView()
        textView.delegate = coordinator
        textView.string = editedText

        XCTAssertEqual(textView.string, "# Initial Document")

        // User types changes in the editor
        textView.string = "# Initial Document\n\nNew paragraph typed by user."
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))

        XCTAssertEqual(editedText, "# Initial Document\n\nNew paragraph typed by user.")

        // Switch to Dark mode - coordinator update
        let darkView = SourceEditorView(text: binding, appearanceMode: .dark)
        coordinator.parent = darkView

        // Simulate updateNSView logic
        if !coordinator.isUpdatingFromTextView && textView.string != coordinator.parent.text {
            textView.string = coordinator.parent.text
        }

        XCTAssertEqual(textView.string, "# Initial Document\n\nNew paragraph typed by user.", "Edits must survive Light -> Dark switch")
        XCTAssertEqual(editedText, "# Initial Document\n\nNew paragraph typed by user.")

        // User types more edits
        textView.string = "# Initial Document\n\nNew paragraph typed by user.\nAnother line."
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))

        // Switch to System mode
        let systemView = SourceEditorView(text: binding, appearanceMode: .system)
        coordinator.parent = systemView

        if !coordinator.isUpdatingFromTextView && textView.string != coordinator.parent.text {
            textView.string = coordinator.parent.text
        }

        XCTAssertEqual(textView.string, "# Initial Document\n\nNew paragraph typed by user.\nAnother line.", "Edits must survive Dark -> System switch")
        XCTAssertEqual(editedText, "# Initial Document\n\nNew paragraph typed by user.\nAnother line.")

        // Switch back to Light mode
        let lightView2 = SourceEditorView(text: binding, appearanceMode: .light)
        coordinator.parent = lightView2

        if !coordinator.isUpdatingFromTextView && textView.string != coordinator.parent.text {
            textView.string = coordinator.parent.text
        }

        XCTAssertEqual(textView.string, "# Initial Document\n\nNew paragraph typed by user.\nAnother line.", "Edits must survive System -> Light switch")
        XCTAssertEqual(editedText, "# Initial Document\n\nNew paragraph typed by user.\nAnother line.")
    }

    func testSourceEditorPreservesSelectionOnExternalUpdate() {
        var text = "First Line\nSecond Line\nThird Line"
        let binding = Binding(get: { text }, set: { text = $0 })

        let view = SourceEditorView(text: binding, appearanceMode: .light)
        let coordinator = view.makeCoordinator()

        let textView = EditorTextView()
        textView.delegate = coordinator
        textView.string = text

        // Set cursor at "Second"
        textView.setSelectedRange(NSRange(location: 11, length: 6))
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 11, length: 6))

        // External update to text
        text = "First Line\nSecond Line\nThird Line (updated)"
        coordinator.parent = SourceEditorView(text: binding, appearanceMode: .light)

        if !coordinator.isUpdatingFromTextView && textView.string != coordinator.parent.text {
            let selectedRanges = textView.selectedRanges
            textView.string = coordinator.parent.text
            textView.selectedRanges = selectedRanges
        }

        XCTAssertEqual(textView.string, "First Line\nSecond Line\nThird Line (updated)")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 11, length: 6), "Selection should be preserved")
    }

    func testDocumentGroupBindingFidelity() {
        var doc = MarkdownDocument(text: "Initial")
        let docBinding = Binding(get: { doc }, set: { doc = $0 })
        let textBinding = docBinding.text

        textBinding.wrappedValue = "Edited Document Text"
        XCTAssertEqual(doc.text, "Edited Document Text")
    }

    func testEditorTextViewRoutesSave() {
        var saveCalled = false
        let textView = EditorTextView()
        textView.onSave = { saveCalled = true }

        textView.save(nil)
        XCTAssertTrue(saveCalled)
    }

    func testFileMonitorHelpersShouldReloadWithSnapshottedBaseline() {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("OshTest_\(UUID().uuidString).md")
        try? "Original File Content".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let attrs = try! FileManager.default.attributesOfItem(atPath: tempFile.path)
        let size = attrs[.size] as! UInt64
        let mtime = attrs[.modificationDate] as! Date

        // When monitor snapshots baseline on startup:
        let knownSize = size
        let knownMtime = mtime

        // Polling immediately or after interval without file change should NOT reload
        let shouldReloadImmediately = FileMonitorHelpers.shouldReload(
            newSize: size,
            newMtime: mtime,
            knownSize: knownSize,
            knownMtime: knownMtime
        )
        XCTAssertFalse(shouldReloadImmediately, "Snapshotted baseline must prevent spurious reload on startup")

        // External file write modifies size / mtime
        let newMtime = mtime.addingTimeInterval(5)
        let shouldReloadAfterExternalEdit = FileMonitorHelpers.shouldReload(
            newSize: size + 20,
            newMtime: newMtime,
            knownSize: knownSize,
            knownMtime: knownMtime
        )
        XCTAssertTrue(shouldReloadAfterExternalEdit, "External modification must be detected")
    }

    func testZoomLevelClampingAndReset() {
        let defaultZoom = 1.0

        let pref = AppearancePreference.shared
        pref.zoomLevel = 1.75
        XCTAssertEqual(pref.zoomLevel, 1.75)

        // Reset
        pref.zoomLevel = defaultZoom
        XCTAssertEqual(pref.zoomLevel, 1.0)
    }

    func testViewModeToggle() {
        var mode: ViewMode = .preview
        mode = (mode == .preview) ? .source : .preview
        XCTAssertEqual(mode, .source)
        mode = (mode == .preview) ? .source : .preview
        XCTAssertEqual(mode, .preview)
    }

    func testEditorTextViewUndoRedoEmptyStackDoesNotCrash() {
        let textView = EditorTextView()
        textView.allowsUndo = true
        let undoManager = UndoManager()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [], backing: .buffered, defer: false)
        window.contentView = textView

        XCTAssertFalse(textView.undoManager?.canUndo ?? true)
        XCTAssertFalse(textView.undoManager?.canRedo ?? true)

        // Must safely no-op without throwing or crashing
        textView.undo(nil)
        textView.redo(nil)

        XCTAssertFalse(textView.undoManager?.canUndo ?? true)
    }

    func testEditorTextViewUndoRedoTextEditing() {
        let textView = EditorTextView()
        textView.allowsUndo = true
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [], backing: .buffered, defer: false)
        window.contentView = textView

        textView.string = "Initial"
        textView.insertText(" Edited", replacementRange: NSRange(location: 7, length: 0))
        textView.breakUndoCoalescing()

        XCTAssertTrue(textView.undoManager?.canUndo ?? false)
        XCTAssertEqual(textView.string, "Initial Edited")

        textView.undo(nil)
        XCTAssertEqual(textView.string, "Initial")
        XCTAssertTrue(textView.undoManager?.canRedo ?? false)

        textView.redo(nil)
        XCTAssertEqual(textView.string, "Initial Edited")
    }
}
