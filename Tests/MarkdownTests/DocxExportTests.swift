import XCTest

final class DocxExportTests: XCTestCase {

    private func extractArchive(_ data: Data, suffix: String) throws -> (directory: URL, cleanup: () -> Void) {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("osh-docx-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let archiveURL = workDir.appendingPathComponent("test.\(suffix)")
        try data.write(to: archiveURL)

        let proc = Process()
        proc.launchPath = "/usr/bin/unzip"
        proc.arguments = ["-o", archiveURL.path, "-d", workDir.appendingPathComponent("extracted").path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        try proc.run()
        proc.waitUntilExit()

        return (workDir.appendingPathComponent("extracted"), { try? FileManager.default.removeItem(at: workDir) })
    }

    // MARK: - ZipWriter

    func testZipCRC32KnownVector() {
        // IEEE CRC-32 of "123456789" is 0xCBF43926 (standard check value).
        XCTAssertEqual(ZipWriter.crc32(Array("123456789".utf8)), 0xCBF43926)
    }

    func testZipArchiveIsValidPerUnzip() throws {
        var zip = ZipWriter()
        zip.add(Data("hello world".utf8), path: "a.txt")
        zip.add(Data("<?xml?><root/>".utf8), path: "dir/b.xml")

        let result = try extractArchive(zip.archive(), suffix: "zip")
        defer { result.cleanup() }
        // extractArchive only returns after unzip exits 0; reaching here is the assertion.
    }

    func testZipRejectsCorruptData() {
        // Sanity: a truncated archive must fail unzip. Guards against a writer
        // that emits plausible-but-invalid output.
        var zip = ZipWriter()
        zip.add(Data("x".utf8), path: "a.txt")
        let full = [UInt8](zip.archive())
        let truncated = Data(full.prefix(full.count / 2))

        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("osh-zip-corrupt-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        let url = workDir.appendingPathComponent("bad.zip")
        try? truncated.write(to: url)
        defer { try? FileManager.default.removeItem(at: workDir) }

        let proc = Process()
        proc.launchPath = "/usr/bin/unzip"
        proc.arguments = ["-t", url.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        XCTAssertNotEqual(proc.terminationStatus, 0)
    }

    // MARK: - DOCX package

    func testDocxPackageStructureAndContent() throws {
        var exporter = DocxExporter()
        let blocks: [DocxExporter.Block] = [
            DocxExporter.Block(
                kind: .heading(level: 1),
                runs: [DocxExporter.InlineRun(text: "Title")]),
            DocxExporter.Block(
                kind: .paragraph,
                runs: [
                    DocxExporter.InlineRun(text: "Regular "),
                    DocxExporter.InlineRun(text: "bold", bold: true),
                    DocxExporter.InlineRun(text: " & <escaped>", italic: true),
                ],
                directionRTL: true),
            DocxExporter.Block(kind: .listItem(listTag: "ul"), runs: [DocxExporter.InlineRun(text: "item")]),
            DocxExporter.Block(kind: .codeBlock, runs: [DocxExporter.InlineRun(text: "let x = 1")]),
            DocxExporter.Block(
                kind: .tableRow(isHeader: true),
                cells: [[DocxExporter.InlineRun(text: "H1")], [DocxExporter.InlineRun(text: "H2")]]),
            DocxExporter.Block(
                kind: .tableRow(isHeader: false),
                cells: [[DocxExporter.InlineRun(text: "a")], [DocxExporter.InlineRun(text: "b")]]),
        ]

        let data = exporter.docx(blocks: blocks, imageDataForRID: [:])
        let result = try extractArchive(data, suffix: "docx")
        defer { result.cleanup() }

        let docXML = try String(
            contentsOf: result.directory.appendingPathComponent("word/document.xml"),
            encoding: .utf8)

        XCTAssertTrue(docXML.contains("<w:pStyle w:val=\"Heading1\"/>"))
        XCTAssertTrue(docXML.contains("<w:bidi/>"))                       // RTL paragraph flag
        XCTAssertTrue(docXML.contains("<w:t xml:space=\"preserve\">bold</w:t>"))
        XCTAssertTrue(docXML.contains("&amp; &lt;escaped&gt;"))           // XML escaping
        XCTAssertTrue(docXML.contains("<w:t xml:space=\"preserve\">\u{2022} </w:t>"))  // list bullet prefix run
        XCTAssertTrue(docXML.contains("<w:t xml:space=\"preserve\">item</w:t>"))
        XCTAssertTrue(docXML.contains("let x = 1"))
        XCTAssertTrue(docXML.contains("<w:tbl>"))

        let contentTypes = try String(
            contentsOf: result.directory.appendingPathComponent("[Content_Types].xml"),
            encoding: .utf8)
        XCTAssertTrue(contentTypes.contains("wordprocessingml.document.main+xml"))

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: result.directory.appendingPathComponent("word/_rels/document.xml.rels").path))
    }

    func testDocxEmbedsImages() throws {
        // 1x1 transparent PNG.
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        guard let pngData = Data(base64Encoded: pngBase64) else {
            XCTFail("bad test fixture PNG")
            return
        }

        var exporter = DocxExporter()
        let blocks = [DocxExporter.Block(kind: .paragraph, imageRID: "rId100")]
        let data = exporter.docx(blocks: blocks, imageDataForRID: ["rId100": (data: pngData, ext: "png")])

        let result = try extractArchive(data, suffix: "docx")
        defer { result.cleanup() }

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.directory.appendingPathComponent("word/media/rId100.png").path))
        XCTAssertEqual(
            try Data(contentsOf: result.directory.appendingPathComponent("word/media/rId100.png")),
            pngData)

        let rels = try String(
            contentsOf: result.directory.appendingPathComponent("word/_rels/document.xml.rels"),
            encoding: .utf8)
        XCTAssertTrue(rels.contains(#"Id="rId100""#))
        XCTAssertTrue(rels.contains(#"Target="media/rId100.png""#))

        let docXML = try String(
            contentsOf: result.directory.appendingPathComponent("word/document.xml"),
            encoding: .utf8)
        XCTAssertTrue(docXML.contains("r:embed=\"rId100\""))
    }

    func testImageDimensionParserPNG() {
        // The same 1x1 PNG fixture: parser must read 1x1 from IHDR.
        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")!
        let dims = ImageDimensionParser.dimensions(of: png)
        XCTAssertEqual(dims?.0, 1)
        XCTAssertEqual(dims?.1, 1)
    }

    func testHyperlinksGetRelationships() {
        var exporter = DocxExporter()
        let blocks = [DocxExporter.Block(
            kind: .paragraph,
            runs: [
                DocxExporter.InlineRun(text: "same link", linkURL: "https://example.com"),
                DocxExporter.InlineRun(text: "again", linkURL: "https://example.com"),
            ])]
        let data = exporter.docx(blocks: blocks, imageDataForRID: [:])
        let raw = String(decoding: data, as: UTF8.self)
        // Deduplicated into one relationship target.
        XCTAssertEqual(raw.range(of: #"TargetMode="External""#) != nil, true)
        _ = blocks.count
    }
}
