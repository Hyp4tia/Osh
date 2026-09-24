import XCTest

/// `MarkdownWebView` and `MarkdownApp` are not part of this test target, so the wiring that keeps
/// the edit-overlay reload suppression live is asserted against the sources, matching the existing
/// convention used by `ToolbarButtonHitAreaTests` and `NativeMagnificationTests`.
final class EditingReloadSuppressionTests: XCTestCase {

    private func source(_ relativePath: String) throws -> String {
        try String(
            contentsOf: projectRoot().appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    private func projectRoot() -> URL {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testHostAppPassesEditingStateToWebView() throws {
        let app = try source("Sources/OshApp/MarkdownApp.swift")

        XCTAssertTrue(app.contains("isEditing: isEditing"))
    }

    func testCoordinatorReceivesEditingState() throws {
        let webView = try source("Sources/OshApp/MarkdownWebView.swift")

        XCTAssertTrue(webView.contains("context.coordinator.isEditingPaused = isEditing"))
    }

    func testBothDiskReloadPathsHonourThePause() throws {
        let webView = try source("Sources/OshApp/MarkdownWebView.swift")

        let guards = webView.components(separatedBy: "guard !isEditingPaused else").count - 1
        XCTAssertEqual(guards, 2, "kqueue-triggered and polled reloads must both respect the pause")
    }
}
