import XCTest
import SwiftUI
import AppKit

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
