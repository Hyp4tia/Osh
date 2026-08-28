import XCTest

final class HTMLExportInlinerTests: XCTestCase {

    func testInlineSafeLocalImagesInlinesAllowedImageWithDoubleQuotes() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageURL = tempDir.appendingPathComponent("test.png")
        let rawBytes = Data([0x89, 0x50, 0x4E, 0x47])
        try rawBytes.write(to: imageURL)

        let inputHTML = "<p><img src=\"file://\(imageURL.path)\" alt=\"test\"></p>"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: tempDir
        )

        let expectedBase64 = rawBytes.base64EncodedString()
        XCTAssertTrue(result.contains("src=\"data:image/png;base64,\(expectedBase64)\""))
    }

    func testInlineSafeLocalImagesInlinesAllowedImageWithSingleQuotes() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageURL = tempDir.appendingPathComponent("photo.jpg")
        let rawBytes = Data([0xFF, 0xD8, 0xFF, 0xE0])
        try rawBytes.write(to: imageURL)

        let inputHTML = "<p><img src='local-md://\(imageURL.path)' alt='photo'></p>"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: tempDir
        )

        let expectedBase64 = rawBytes.base64EncodedString()
        XCTAssertTrue(result.contains("src=\"data:image/jpeg;base64,\(expectedBase64)\""))
    }

    func testInlineSafeLocalImagesHandlesPercentEncodedPaths() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let spaceDir = tempDir.appendingPathComponent("my images", isDirectory: true)
        try FileManager.default.createDirectory(at: spaceDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageURL = spaceDir.appendingPathComponent("my icon.svg")
        let svgContent = "<svg><circle r='10'/></svg>"
        try Data(svgContent.utf8).write(to: imageURL)

        let encodedPath = imageURL.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        let inputHTML = "<img src=\"file://\(encodedPath)\">"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: tempDir
        )

        let expectedBase64 = Data(svgContent.utf8).base64EncodedString()
        XCTAssertTrue(result.contains("src=\"data:image/svg+xml;base64,\(expectedBase64)\""))
    }

    func testInlineSafeLocalImagesRejectsNonImageExtensions() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let textURL = tempDir.appendingPathComponent("sensitive.txt")
        try Data("secret".utf8).write(to: textURL)

        let inputHTML = "<img src=\"file://\(textURL.path)\">"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: tempDir
        )

        // Must not inline non-image file
        XCTAssertEqual(result, inputHTML)
    }

    func testInlineSafeLocalImagesRejectsDirectoryTraversalOutsideBaseDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let docs = tempDir.appendingPathComponent("docs", isDirectory: true)
        let secrets = tempDir.appendingPathComponent("secrets", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secrets, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let secretImage = secrets.appendingPathComponent("secret.png")
        try Data([0x89, 0x50]).write(to: secretImage)

        let traversalPath = "\(docs.path)/../secrets/secret.png"
        let inputHTML = "<img src=\"local-md://\(traversalPath)\">"

        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: docs
        )

        XCTAssertEqual(result, inputHTML, "Directory traversal outside baseDirectory must not be inlined")
    }

    func testInlineSafeLocalImagesRejectsSymlinkEscape() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let docs = tempDir.appendingPathComponent("docs", isDirectory: true)
        let outside = tempDir.appendingPathComponent("outside", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let outsideImage = outside.appendingPathComponent("escaped.png")
        try Data([0x89, 0x50]).write(to: outsideImage)

        let symlink = docs.appendingPathComponent("symlink.png")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outsideImage)

        let inputHTML = "<img src=\"file://\(symlink.path)\">"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: docs
        )

        XCTAssertEqual(result, inputHTML, "Symlink escaping baseDirectory must not be inlined")
    }

    func testInlineSafeLocalImagesAllowsExplicitlyAllowedURLs() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let docs = tempDir.appendingPathComponent("docs", isDirectory: true)
        let sharedAssets = tempDir.appendingPathComponent("shared", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sharedAssets, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sharedImage = sharedAssets.appendingPathComponent("brand.png")
        let rawBytes = Data([0x89, 0x50, 0x4E, 0x47])
        try rawBytes.write(to: sharedImage)

        let inputHTML = "<img src=\"local-md://\(sharedImage.path)\">"
        let result = HTMLExportInliner.inlineSafeLocalImages(
            html: inputHTML,
            baseDirectory: docs,
            allowedFileURLs: [sharedImage]
        )

        let expectedBase64 = rawBytes.base64EncodedString()
        XCTAssertTrue(result.contains("src=\"data:image/png;base64,\(expectedBase64)\""))
    }
}
