import XCTest

@MainActor
final class EditingSessionControllerTests: XCTestCase {

    private func tempFileURL(content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("osh-edit-test-\(UUID().uuidString).md")
        try Data(content.utf8).write(to: url)
        return url
    }

    func testBeginEditingCapturesBaseline() {
        let session = EditingSessionController()
        session.beginEditing(currentContent: "# Hello", fileURL: nil)
        XCTAssertTrue(session.isEditing)
        XCTAssertEqual(session.draftText, "# Hello")
        XCTAssertFalse(session.hasUnsavedChanges)
    }

    func testDirtyTracking() {
        let session = EditingSessionController()
        session.beginEditing(currentContent: "line", fileURL: nil)
        XCTAssertFalse(session.hasUnsavedChanges)

        session.draftText = "line changed"
        XCTAssertTrue(session.hasUnsavedChanges)

        // Returning to the exact baseline clears dirty state.
        session.draftText = "line"
        XCTAssertFalse(session.hasUnsavedChanges)
    }

    func testSaveWritesUtf8AndClearsDirty() throws {
        let url = try tempFileURL(content: "original")
        defer { try? FileManager.default.removeItem(at: url) }

        let session = EditingSessionController()
        session.beginEditing(currentContent: "original", fileURL: url)
        session.draftText = "# مرحبا\n- שלום\nEnglish line"

        _ = try session.save()

        let saved = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(saved, "# مرحبا\n- שלום\nEnglish line")
        XCTAssertFalse(session.hasUnsavedChanges)
    }

    func testSaveWithoutFileThrows() {
        let session = EditingSessionController()
        session.beginEditing(currentContent: "x", fileURL: nil)
        XCTAssertThrowsError(try session.save())
    }

    func testSavePreservesExactFormatting() throws {
        // Trailing whitespace, CRLF, and trailing newline must survive a save.
        let tricky = "| A | B |\r\n|---|---|\r\n| 1 | 2 |   \n\n```swift\nlet x = 1  \n```\n"
        let url = try tempFileURL(content: "")
        defer { try? FileManager.default.removeItem(at: url) }

        let session = EditingSessionController()
        session.beginEditing(currentContent: "", fileURL: url)
        session.draftText = tricky
        _ = try session.save()

        let saved = try Data(contentsOf: url)
        XCTAssertEqual(saved, Data(tricky.utf8))
    }

    func testDiscardResetsSession() {
        let session = EditingSessionController()
        session.beginEditing(currentContent: "a", fileURL: nil)
        session.draftText = "b"
        session.endEditing(discardingChanges: true)
        XCTAssertFalse(session.isEditing)
        XCTAssertNil(session.fileURL)
        XCTAssertFalse(session.hasUnsavedChanges)
    }
}
