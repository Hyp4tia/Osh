import XCTest
import WebKit

final class DocumentConverterTests: XCTestCase {

    private var fixturesURL: URL {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("fixtures")
    }

    func testSupportedExtensions_recognizesAllSupportedFormats() {
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "docx"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "DOCX"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: ".docx"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "pdf"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "PDF"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: ".pdf"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "csv"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "CSV"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: ".csv"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "xlsx"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "XLSX"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: ".xlsx"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "pptx"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: "PPTX"))
        XCTAssertTrue(DocumentConverter.isSupported(fileExtension: ".pptx"))

        XCTAssertFalse(DocumentConverter.isSupported(fileExtension: "exe"))
        XCTAssertFalse(DocumentConverter.isSupported(fileExtension: "png"))
        XCTAssertFalse(DocumentConverter.isSupported(fileExtension: "txt"))
    }

    func testSupportedURL_recognizesFileURL() {
        let docxURL = URL(fileURLWithPath: "/path/to/sample.docx")
        let pdfURL = URL(fileURLWithPath: "/path/to/sample.pdf")
        let csvURL = URL(fileURLWithPath: "/path/to/sample.csv")
        let xlsxURL = URL(fileURLWithPath: "/path/to/sample.xlsx")
        let pptxURL = URL(fileURLWithPath: "/path/to/sample.pptx")
        let mdURL = URL(fileURLWithPath: "/path/to/sample.md")

        XCTAssertTrue(DocumentConverter.isSupported(url: docxURL))
        XCTAssertTrue(DocumentConverter.isSupported(url: pdfURL))
        XCTAssertTrue(DocumentConverter.isSupported(url: csvURL))
        XCTAssertTrue(DocumentConverter.isSupported(url: xlsxURL))
        XCTAssertTrue(DocumentConverter.isSupported(url: pptxURL))
        XCTAssertFalse(DocumentConverter.isSupported(url: mdURL))
    }

    func testErrorDescriptions_areInformative() {
        let ocrError = DocumentConversionError.needsOcr(pages: [1, 2], pageCount: 2)
        XCTAssertTrue(ocrError.errorDescription?.contains("OCR") ?? false)
        XCTAssertTrue(ocrError.errorDescription?.contains("pages 1, 2") ?? false)

        let encError = DocumentConversionError.encrypted
        XCTAssertTrue(encError.errorDescription?.contains("password") ?? false)

        let unsuppError = DocumentConversionError.unsupported("xyz")
        XCTAssertTrue(unsuppError.errorDescription?.contains("xyz") ?? false)

        let emptyError = DocumentConversionError.emptyFile
        XCTAssertTrue(emptyError.errorDescription?.contains("empty") ?? false)
    }

    func testConvert_emptyData_returnsEmptyFileError() {
        let expectation = expectation(description: "empty data completion")
        DocumentConverter.shared.convert(data: Data(), formatHint: "docx") { result in
            switch result {
            case .success:
                XCTFail("Empty data conversion must not succeed")
            case .failure(let error):
                XCTAssertEqual(error, .emptyFile)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0)
    }

    func testConvert_nonExistentFile_returnsMalformedError() {
        let nonExistent = URL(fileURLWithPath: "/non/existent/file.docx")
        let expectation = expectation(description: "non existent file completion")
        DocumentConverter.shared.convert(fileURL: nonExistent) { result in
            switch result {
            case .success:
                XCTFail("Non-existent file conversion must not succeed")
            case .failure(let error):
                if case .malformed = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected malformed error, got: \(error)")
                }
            }
        }
        waitForExpectations(timeout: 3.0)
    }

    func testConvert_realDocxFixture_succeedsAndReturnsMarkdown() {
        let docxURL = fixturesURL.appendingPathComponent("sample-doc.docx")
        guard FileManager.default.fileExists(atPath: docxURL.path) else {
            XCTFail("sample-doc.docx fixture missing")
            return
        }

        let expectation = expectation(description: "DOCX conversion")
        DocumentConverter.shared.convert(fileURL: docxURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertTrue(markdown.contains("Document Converter Heading"))
                XCTAssertTrue(markdown.contains("**bold**"))
                XCTAssertTrue(markdown.contains("*italic*"))
                XCTAssertTrue(markdown.contains("[link to Osh](https://osh.dev)"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("DOCX conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_realPdfFixture_succeedsAndReturnsMarkdown() {
        let pdfURL = fixturesURL.appendingPathComponent("sample-doc.pdf")
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            XCTFail("sample-doc.pdf fixture missing")
            return
        }

        let expectation = expectation(description: "PDF conversion")
        DocumentConverter.shared.convert(fileURL: pdfURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertTrue(markdown.contains("Osh Document Converter Test"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("PDF conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_scannedPdfFixture_returnsNeedsOcrError() {
        let scannedURL = fixturesURL.appendingPathComponent("sample-scanned.pdf")
        guard FileManager.default.fileExists(atPath: scannedURL.path) else {
            XCTFail("sample-scanned.pdf fixture missing")
            return
        }

        let expectation = expectation(description: "Scanned PDF conversion")
        DocumentConverter.shared.convert(fileURL: scannedURL) { result in
            switch result {
            case .success:
                XCTFail("Scanned PDF must not convert successfully as text")
            case .failure(let error):
                if case .needsOcr(let pages, _) = error {
                    XCTAssertFalse(pages.isEmpty)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected needsOcr error, got: \(error)")
                }
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_realCsvFixture_succeedsAndReturnsMarkdown() {
        let csvURL = fixturesURL.appendingPathComponent("sample-doc.csv")
        guard FileManager.default.fileExists(atPath: csvURL.path) else {
            XCTFail("sample-doc.csv fixture missing")
            return
        }

        let expectation = expectation(description: "CSV conversion")
        DocumentConverter.shared.convert(fileURL: csvURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertTrue(markdown.contains("Product"))
                XCTAssertTrue(markdown.contains("Widget A"))
                XCTAssertTrue(markdown.contains("Gadget Pro (جهاز برو)"))
                XCTAssertTrue(markdown.contains("Standard widget, version 1.0"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("CSV conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_realXlsxFixture_succeedsAndReturnsMarkdown() {
        let xlsxURL = fixturesURL.appendingPathComponent("sample-doc.xlsx")
        guard FileManager.default.fileExists(atPath: xlsxURL.path) else {
            XCTFail("sample-doc.xlsx fixture missing")
            return
        }

        let expectation = expectation(description: "XLSX conversion")
        DocumentConverter.shared.convert(fileURL: xlsxURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertTrue(markdown.contains("Sales Q1"))
                XCTAssertTrue(markdown.contains("Widget Alpha"))
                XCTAssertTrue(markdown.contains("Gadget Beta (جهاز بيتا)"))
                XCTAssertTrue(markdown.contains("Team Directory"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("XLSX conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_realPptxFixture_succeedsAndReturnsMarkdown() {
        let pptxURL = fixturesURL.appendingPathComponent("sample-doc.pptx")
        guard FileManager.default.fileExists(atPath: pptxURL.path) else {
            XCTFail("sample-doc.pptx fixture missing")
            return
        }

        let expectation = expectation(description: "PPTX conversion")
        DocumentConverter.shared.convert(fileURL: pptxURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                XCTAssertTrue(markdown.contains("Osh Presentation Test (عرض تقديمي)"))
                XCTAssertTrue(markdown.contains("Key Capabilities"))
                XCTAssertTrue(markdown.contains("Offline WebAssembly execution"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("PPTX conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_richPptxFixture_embedsImageDataUrisAndSeparatesSlides() {
        let richPptxURL = fixturesURL.appendingPathComponent("rich-presentation.pptx")
        guard FileManager.default.fileExists(atPath: richPptxURL.path) else {
            XCTFail("rich-presentation.pptx fixture missing")
            return
        }

        let expectation = expectation(description: "Rich PPTX conversion")
        DocumentConverter.shared.convert(fileURL: richPptxURL) { result in
            switch result {
            case .success(let markdown):
                XCTAssertFalse(markdown.isEmpty)
                // Slide 1
                XCTAssertTrue(markdown.contains("## AIJRF Presentation"))
                XCTAssertTrue(markdown.contains("Brand & Digital Strategy Proposal"))
                XCTAssertTrue(markdown.contains("> Remember to emphasize market timing and team readiness."))
                // Slide separators
                XCTAssertTrue(markdown.contains("---"))
                // Slide 2 & Embedded Image (no /home/claude/ path leak)
                XCTAssertTrue(markdown.contains("## Strategic Objectives"))
                XCTAssertTrue(markdown.contains("• Enhance brand awareness across digital channels"))
                XCTAssertTrue(markdown.contains("![auc.png](data:image/png;base64,"))
                XCTAssertFalse(markdown.contains("/home/claude/auc.png\n"))
                // Slide 3 & Table
                XCTAssertTrue(markdown.contains("## Timeline & Milestones"))
                XCTAssertTrue(markdown.contains("| Phase | Target Date |"))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Rich PPTX conversion failed: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 10.0)
    }

    func testConvert_corruptedXlsx_returnsMalformedError() {
        let corruptData = Data("PK\u{03}\u{04}corrupted xlsx".utf8)
        let expectation = expectation(description: "Corrupted XLSX completion")
        DocumentConverter.shared.convert(data: corruptData, formatHint: "xlsx") { result in
            switch result {
            case .success:
                XCTFail("Corrupted XLSX conversion must not succeed")
            case .failure(let error):
                if case .malformed = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected malformed error, got: \(error)")
                }
            }
        }
        waitForExpectations(timeout: 15.0)
    }

    // MARK: - Draft Store & Unsaved Document Tests

    func testDraftStore_pushesAndPopsDraft() {
        let draft = ConvertedDocumentDraft(text: "# Converted Content", suggestedFilename: "report.md")
        ConvertedDocumentDraftStore.shared.pushDraft(draft)

        let popped = ConvertedDocumentDraftStore.shared.popDraft()
        XCTAssertEqual(popped?.text, "# Converted Content")
        XCTAssertEqual(popped?.suggestedFilename, "report.md")

        XCTAssertNil(ConvertedDocumentDraftStore.shared.popDraft())
    }

    func testMarkdownDocument_consumesPendingDraftOnInit() {
        let draft = ConvertedDocumentDraft(text: "# Heading from Conversion", suggestedFilename: "quarterly.md")
        ConvertedDocumentDraftStore.shared.pushDraft(draft)

        let doc = MarkdownDocument()
        XCTAssertEqual(doc.text, "# Heading from Conversion")
        XCTAssertEqual(doc.suggestedTitle, "quarterly.md")

        // Next document should be regular empty document
        let emptyDoc = MarkdownDocument()
        XCTAssertEqual(emptyDoc.text, "")
        XCTAssertNil(emptyDoc.suggestedTitle)
    }
}
