import XCTest

final class LocalizationHelpTests: XCTestCase {
    func testHelpURLForEnglish() {
        let url = LocalizationManager.helpURL(for: "en")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP.md")
    }

    func testHelpURLForFrench() {
        let url = LocalizationManager.helpURL(for: "fr")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP_FR.md")
    }

    func testHelpURLForArabic() {
        let url = LocalizationManager.helpURL(for: "ar")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP_AR.md")
    }

    func testHelpURLForGerman() {
        let url = LocalizationManager.helpURL(for: "de")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP_DE.md")
    }

    func testHelpURLForChinese() {
        let url = LocalizationManager.helpURL(for: "zh")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP_ZH.md")
    }

    func testHelpURLForSpanish() {
        let url = LocalizationManager.helpURL(for: "es")
        XCTAssertEqual(url.absoluteString, "https://github.com/Hyp4tia/Osh/blob/main/docs/user/HELP_ES.md")
    }
}
