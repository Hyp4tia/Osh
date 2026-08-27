import XCTest

final class LinkNavigationTests: XCTestCase {

    // MARK: - Legitimate relative resolution tests

    func testResolvesPercentEncodedSpacesInRelativeHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "file%20with%20spaces.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result, "Should resolve a valid percent-encoded relative href")
        XCTAssertEqual(result?.path, "/Users/me/docs/file with spaces.md",
                       "Percent-encoded spaces (%20) must be decoded to actual spaces in the path")
    }

    func testResolvesPercentEncodedSpacesInDirectoryComponent() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "my%20folder/notes.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/my folder/notes.md",
                       "Percent-encoded spaces in directory components must be decoded")
    }

    func testResolvesPlainRelativeHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "notes.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/notes.md")
    }

    func testResolvesRelativeHrefWithDotSlash() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "./subdir/notes.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/subdir/notes.md")
    }

    func testResolvesRelativeHrefWithSubdirParentTraversalStayingWithinBase() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "subdir/../notes.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/notes.md")
    }

    func testResolvesContainedAbsoluteHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "/Users/me/docs/contained.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/contained.md")
    }

    func testResolvesContainedFileURLScheme() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "file:///Users/me/docs/notes.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/notes.md")
    }

    // MARK: - Fragment and special cases

    func testReturnsNilForPureAnchorHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "#section"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "A pure anchor href should return nil (JS handles it)")
    }

    func testReturnsNilForEmptyHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = ""

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Empty href should return nil")
    }

    func testExtractsFragmentFromPercentEncodedHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "my%20notes.md#introduction"

        let (targetURL, fragment) = LinkNavigation.resolveLocalURLWithFragment(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(targetURL)
        XCTAssertEqual(targetURL?.path, "/Users/me/docs/my notes.md",
                       "Path with %20 and fragment must decode correctly")
        XCTAssertEqual(fragment, "introduction")
    }

    func testExtractsFragmentFromPlainHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "notes.md#section-one"

        let (targetURL, fragment) = LinkNavigation.resolveLocalURLWithFragment(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(targetURL)
        XCTAssertEqual(targetURL?.path, "/Users/me/docs/notes.md")
        XCTAssertEqual(fragment, "section-one")
    }

    func testExtractsNilFragmentWhenNoAnchor() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "my%20notes.md"

        let (targetURL, fragment) = LinkNavigation.resolveLocalURLWithFragment(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(targetURL)
        XCTAssertEqual(targetURL?.path, "/Users/me/docs/my notes.md")
        XCTAssertNil(fragment)
    }

    func testResolvesMultiplePercentEncodedCharacters() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "file%20name%20%28version%201%29.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/file name (version 1).md",
                       "All percent-encoded characters must be decoded")
    }

    func testResolvesChineseCharacterInPercentEncodedHref() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "%E8%AE%BE%E8%AE%A1%E6%96%87%E6%A1%A3.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, "/Users/me/docs/设计文档.md",
                       "Percent-encoded non-ASCII characters must be decoded correctly")
    }

    // MARK: - Security & Containment Tests

    func testRejectsDirectoryTraversalOutsideBaseDirectory() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "../../../some-file.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Path traversal escaping base directory must be rejected")
    }

    func testRejectsDeepDirectoryTraversalToTerminalApp() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "../../../../Applications/Utilities/Terminal.app"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Path traversal to Terminal.app must be rejected")
    }

    func testRejectsAbsoluteTerminalAppPath() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "/Applications/Utilities/Terminal.app"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Absolute path outside base directory must be rejected")
    }

    func testRejectsPercentEncodedTraversal() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "%2e%2e/%2e%2e/%2e%2e/etc/passwd"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Percent-encoded ../ path traversal must be rejected")
    }

    func testRejectsAppBundleEvenIfInsideBaseDirectory() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "subfolder/Payload.app"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, ".app bundle targets must always be rejected")
    }

    func testRejectsDangerousScriptExtensions() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let dangerousHrefs = ["script.sh", "run.command", "tool.tool", "installer.pkg", "payload.dmg"]

        for href in dangerousHrefs {
            let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)
            XCTAssertNil(result, "Dangerous extension \(href) must be rejected")
        }
    }

    func testRejectsMalformedPercentEncoding() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "test%ZZfile.md"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Malformed percent-encoding should return nil")
    }

    func testRejectsNullByteInjection() {
        let baseFileURL = URL(fileURLWithPath: "/Users/me/docs/index.md")
        let href = "notes.md%00/../../etc/passwd"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Null-byte injection must return nil")
    }

    func testRejectsSymlinkPointingOutsideBaseDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let docDir = tempDir.appendingPathComponent("docs")
        let outsideDir = tempDir.appendingPathComponent("outside")

        try FileManager.default.createDirectory(at: docDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outsideDir, withIntermediateDirectories: true)

        let secretFile = outsideDir.appendingPathComponent("secret.txt")
        try "secret content".write(to: secretFile, atomically: true, encoding: .utf8)

        let symlinkURL = docDir.appendingPathComponent("outside_symlink")
        try FileManager.default.createSymbolicLink(at: symlinkURL, withDestinationURL: outsideDir)

        let baseFileURL = docDir.appendingPathComponent("index.md")
        let href = "outside_symlink/secret.txt"

        let result = LinkNavigation.resolveLocalURL(href: href, relativeTo: baseFileURL)

        XCTAssertNil(result, "Symlink escaping base directory must be rejected")

        try? FileManager.default.removeItem(at: tempDir)
    }
}
