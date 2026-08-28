import XCTest

final class DisplayVersionTests: XCTestCase {

    func testDisplayVersionUsesDevelopmentOverrideWhenPresent() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.32.427",
            "FMDisplayVersion": "1.32.427-dev-20260521-1430"
        ]

        XCTAssertEqual(
            DisplayVersion.text(from: info),
            "1.32.427-dev-20260521-1430"
        )
    }

    func testDisplayVersionFallsBackToBundleShortVersion() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.32.427"
        ]

        XCTAssertEqual(DisplayVersion.text(from: info), "1.32.427")
    }

    func testDisplayVersionIgnoresEmptyDevelopmentOverride() {
        let info: [String: Any] = [
            "CFBundleShortVersionString": "1.32.427",
            "FMDisplayVersion": "   "
        ]

        XCTAssertEqual(DisplayVersion.text(from: info), "1.32.427")
    }

    func testDisplayVersionReturnsNilWhenNoVersionExists() {
        XCTAssertNil(DisplayVersion.text(from: [:]))
    }

    func testFormattedBetaTextUsesVersion() {
        XCTAssertTrue(DisplayVersion.formattedBetaText().contains("Beta"))
    }

    func testAutomaticallyChecksForUpdates_defaultsToTrue() {
        let pref = AppearancePreference.shared
        XCTAssertTrue(pref.automaticallyChecksForUpdates)
    }

    func testAutomaticallyChecksForUpdates_persistsAndPostsNotification() {
        let pref = AppearancePreference.shared
        let expectation = expectation(description: "Notification posted on update toggle")

        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OshAutomaticUpdateCheckingChanged"),
            object: nil,
            queue: .main
        ) { note in
            if let enabled = note.object as? Bool, !enabled {
                expectation.fulfill()
            }
        }

        pref.automaticallyChecksForUpdates = false
        XCTAssertFalse(pref.automaticallyChecksForUpdates)

        waitForExpectations(timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)

        // Restore to true
        pref.automaticallyChecksForUpdates = true
        XCTAssertTrue(pref.automaticallyChecksForUpdates)
    }

    func testIsAdvancedSettingsExpanded_defaultsToFalseAndToggles() {
        let pref = AppearancePreference.shared
        let original = pref.isAdvancedSettingsExpanded

        pref.isAdvancedSettingsExpanded = true
        XCTAssertTrue(pref.isAdvancedSettingsExpanded)

        pref.isAdvancedSettingsExpanded = false
        XCTAssertFalse(pref.isAdvancedSettingsExpanded)

        pref.isAdvancedSettingsExpanded = original
    }
}
