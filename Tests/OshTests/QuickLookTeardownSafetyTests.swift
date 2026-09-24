import AppKit
import XCTest

/// QuickLook can tear the panel down while a queued block is still pending. These tests cover the
/// post-teardown paths that used to dereference the nilled `webView`.
@MainActor
final class QuickLookTeardownSafetyTests: XCTestCase {

    private var markdownFixtureURL: URL {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fixtures/feature-validation.md")
    }

    /// Touching `.view` runs loadView + viewDidLoad, which configures the web view.
    private func makeLoadedController() -> PreviewViewController {
        let controller = PreviewViewController()
        _ = controller.view
        return controller
    }

    func testTeardownClearsWebViewReadinessFlag() {
        let controller = makeLoadedController()
        controller.isWebViewLoaded = true

        controller.viewWillDisappear()

        XCTAssertFalse(controller.isWebViewLoaded)
        XCTAssertNil(controller.webView)
    }

    func testThemeChangeAfterTeardownIsIgnored() {
        let controller = makeLoadedController()
        controller.isWebViewLoaded = true
        controller.viewWillDisappear()

        let previousMode = AppearancePreference.shared.currentMode
        AppearancePreference.shared.currentMode = .system
        defer { AppearancePreference.shared.currentMode = previousMode }

        controller.perform(
            Selector(("systemAppearanceDidChange:")),
            with: Notification(name: Notification.Name("AppleInterfaceThemeChangedNotification"))
        )
    }

    func testQueuedPreviewCompletionSurvivesTeardown() {
        let controller = makeLoadedController()
        let completed = expectation(description: "preparePreviewOfFile completes")

        controller.preparePreviewOfFile(at: markdownFixtureURL) { error in
            XCTAssertNil(error)
            completed.fulfill()
        }

        // Panel closes before the queued block runs.
        controller.viewWillDisappear()

        wait(for: [completed], timeout: 10)
        XCTAssertNil(controller.webView)
    }

    func testQueuedPreviewStillLoadsContentWhenNotTornDown() {
        let controller = makeLoadedController()
        let completed = expectation(description: "preparePreviewOfFile completes")

        controller.preparePreviewOfFile(at: markdownFixtureURL) { error in
            XCTAssertNil(error)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 10)
        XCTAssertNotNil(controller.pendingMarkdown)
        XCTAssertEqual(controller.currentURL, markdownFixtureURL)

        controller.viewWillDisappear()
    }
}
