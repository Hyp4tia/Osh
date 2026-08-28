import Foundation
import WebKit
import UniformTypeIdentifiers
import AppKit
import os.log

public enum DocumentConversionError: LocalizedError, Equatable {
    case needsOcr(pages: [Int], pageCount: Int)
    case encrypted
    case unsupported(String)
    case malformed(String)
    case resourceLimit
    case missingPart
    case conversionFailed(String)
    case emptyFile
    case webViewUnavailable

    public var errorDescription: String? {
        switch self {
        case .needsOcr(let pages, _):
            let pageText = pages.isEmpty ? "" : " (pages \(pages.map(String.init).joined(separator: ", ")))"
            return "This PDF contains scanned or image-only pages that require OCR\(pageText). Osh only converts text-based documents offline."
        case .encrypted:
            return "This document is encrypted or password-protected and cannot be converted."
        case .unsupported(let format):
            return "The format '\(format)' is not currently supported for document conversion."
        case .malformed(let reason):
            return "The document is malformed or corrupted: \(reason)"
        case .resourceLimit:
            return "The document exceeded safe size or complexity limits."
        case .missingPart:
            return "A required part of the document package is missing."
        case .conversionFailed(let message):
            return "Document conversion failed: \(message)"
        case .emptyFile:
            return "The selected document is empty."
        case .webViewUnavailable:
            return "The conversion renderer engine is unavailable."
        }
    }
}

public final class DocumentConverter: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    public static let shared = DocumentConverter()

    private let logger = OSLog(subsystem: "com.zeyadistired.osh", category: "DocumentConverter")
    private var webView: WKWebView?
    private var isRendererReady = false
    private var pendingRequests: [([String: Any], (Result<String, DocumentConversionError>) -> Void)] = []
    private var rendererBundleSchemeHandler: RendererBundleSchemeHandler?

    public override init() {
        super.init()
        DispatchQueue.main.async { [weak self] in
            self?.setupWebView()
        }
    }

    // MARK: - Supported Formats

    public static let supportedExtensions: Set<String> = ["docx", "pdf", "csv", "xlsx", "pptx"]

    public static func isSupported(fileExtension: String) -> Bool {
        supportedExtensions.contains(fileExtension.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")))
    }

    public static func isSupported(url: URL) -> Bool {
        isSupported(fileExtension: url.pathExtension)
    }

    // MARK: - Conversion API

    public func convert(fileURL: URL, completion: @escaping (Result<String, DocumentConversionError>) -> Void) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(.failure(.malformed("File does not exist at path: \(fileURL.path)")))
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let ext = fileURL.pathExtension.lowercased()
            convert(data: data, formatHint: ext, completion: completion)
        } catch {
            completion(.failure(.conversionFailed(error.localizedDescription)))
        }
    }

    public func convert(data: Data, formatHint: String?, completion: @escaping (Result<String, DocumentConversionError>) -> Void) {
        guard !data.isEmpty else {
            completion(.failure(.emptyFile))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion(.failure(.webViewUnavailable))
                return
            }

            let base64 = data.base64EncodedString()
            var payload: [String: Any] = ["base64": base64]
            if let hint = formatHint {
                payload["formatHint"] = hint
            }

            if self.isRendererReady, let webView = self.webView {
                self.executeConversion(payload: payload, on: webView, completion: completion)
            } else {
                self.pendingRequests.append((payload, completion))
                if self.webView == nil {
                    self.setupWebView()
                }
            }
        }
    }

    public func convert(fileURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            convert(fileURL: fileURL) { result in
                switch result {
                case .success(let markdown):
                    continuation.resume(returning: markdown)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func convert(data: Data, formatHint: String?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            convert(data: data, formatHint: formatHint) { result in
                switch result {
                case .success(let markdown):
                    continuation.resume(returning: markdown)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private WebView Setup

    private func setupWebView() {
        guard webView == nil else { return }

        let config = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        ucc.add(self, name: "logger")
        config.userContentController = ucc

        let bundle = Bundle(for: Self.self)
        if let rendererHandler = RendererBundleSchemeHandler(bundle: bundle) ?? RendererBundleSchemeHandler(bundle: .main) {
            config.setURLSchemeHandler(rendererHandler, forURLScheme: RendererBundleSchemeHandler.scheme)
            self.rendererBundleSchemeHandler = rendererHandler
        } else {
            os_log("DocumentConverter failed to find web renderer in bundle", log: logger, type: .error)
        }

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        self.webView = wv

        if rendererBundleSchemeHandler != nil {
            let url = RendererBundleSchemeHandler.rendererURL()
            wv.load(URLRequest(url: url))
        }
    }

    private func executeConversion(payload: [String: Any], on webView: WKWebView, completion: @escaping (Result<String, DocumentConversionError>) -> Void) {
        guard let base64 = payload["base64"] as? String else {
            completion(.failure(.malformed("Missing base64 data")))
            return
        }
        let formatHint = payload["formatHint"] as? String

        let args: [String: Any] = [
            "base64": base64,
            "formatHint": formatHint ?? NSNull()
        ]

        let script = "return await window.convertDocumentToMarkdown(base64, formatHint);"

        webView.callAsyncJavaScript(script, arguments: args, in: nil, in: .page) { [weak self] asyncResult in
            switch asyncResult {
            case .failure(let error):
                os_log("JavaScript conversion callAsyncJavaScript failed: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                completion(.failure(.conversionFailed(error.localizedDescription)))
            case .success(let result):
                guard let dict = result as? [String: Any] else {
                    completion(.failure(.conversionFailed("Invalid response format from converter")))
                    return
                }

                let success = dict["success"] as? Bool ?? false
                if success, let markdown = dict["markdown"] as? String {
                    completion(.success(markdown))
                } else {
                    let errorCode = dict["errorCode"] as? String ?? "generic"
                    let errorMessage = dict["error"] as? String ?? "Conversion failed"
                    let pages = dict["pages"] as? [Int] ?? []
                    let pageCount = dict["pageCount"] as? Int ?? 0

                    let conversionError: DocumentConversionError
                    switch errorCode {
                    case "needsOcr":
                        conversionError = .needsOcr(pages: pages, pageCount: pageCount)
                    case "encrypted":
                        conversionError = .encrypted
                    case "unsupported":
                        conversionError = .unsupported(formatHint ?? "unknown")
                    case "malformed":
                        conversionError = .malformed(errorMessage)
                    case "resourceLimit":
                        conversionError = .resourceLimit
                    case "missingPart":
                        conversionError = .missingPart
                    default:
                        conversionError = .conversionFailed(errorMessage)
                    }
                    completion(.failure(conversionError))
                }
            }
        }
    }

    private func flushPendingRequests() {
        guard isRendererReady, let webView = webView else { return }
        let queue = pendingRequests
        pendingRequests.removeAll()

        for (payload, completion) in queue {
            executeConversion(payload: payload, on: webView, completion: completion)
        }
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logger", let body = message.body as? String {
            if body == "rendererReady" {
                isRendererReady = true
                flushPendingRequests()
            }
        }
    }

    // MARK: - WKNavigationDelegate

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Fallback in case rendererReady log was missed
        webView.evaluateJavaScript("typeof window.convertDocumentToMarkdown === 'function'") { [weak self] result, _ in
            if (result as? Bool) == true {
                self?.isRendererReady = true
                self?.flushPendingRequests()
            }
        }
    }
}

public struct ConvertedDocumentDraft: Equatable {
    public let text: String
    public let suggestedFilename: String

    public init(text: String, suggestedFilename: String) {
        self.text = text
        self.suggestedFilename = suggestedFilename
    }
}

public final class ConvertedDocumentDraftStore {
    public static let shared = ConvertedDocumentDraftStore()
    private var pendingDrafts: [ConvertedDocumentDraft] = []
    private let lock = NSLock()

    private init() {}

    public func pushDraft(_ draft: ConvertedDocumentDraft) {
        lock.lock()
        defer { lock.unlock() }
        pendingDrafts.append(draft)
    }

    public func popDraft() -> ConvertedDocumentDraft? {
        lock.lock()
        defer { lock.unlock() }
        if pendingDrafts.isEmpty { return nil }
        return pendingDrafts.removeFirst()
    }

    public func peekDraft() -> ConvertedDocumentDraft? {
        lock.lock()
        defer { lock.unlock() }
        return pendingDrafts.first
    }
}

public final class DocumentImportController {
    public static let shared = DocumentImportController()

    public func openConvertedDraft(markdown: String, sourceURL: URL) {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let suggestedName = baseName.hasSuffix(".md") ? baseName : "\(baseName).md"
        let draft = ConvertedDocumentDraft(text: markdown, suggestedFilename: suggestedName)
        ConvertedDocumentDraftStore.shared.pushDraft(draft)

        DispatchQueue.main.async {
            NSDocumentController.shared.newDocument(nil)
        }
    }

    public func importAndConvertDocument() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        var types: [UTType] = [UTType.pdf, UTType.commaSeparatedText]
        if let docx = UTType(filenameExtension: "docx") {
            types.append(docx)
        }
        if let docxUti = UTType("org.openxmlformats.wordprocessingml.document"), !types.contains(docxUti) {
            types.append(docxUti)
        }
        if let xlsx = UTType(filenameExtension: "xlsx"), !types.contains(xlsx) {
            types.append(xlsx)
        }
        if let xlsxUti = UTType("org.openxmlformats.spreadsheetml.sheet"), !types.contains(xlsxUti) {
            types.append(xlsxUti)
        }
        if let pptx = UTType(filenameExtension: "pptx"), !types.contains(pptx) {
            types.append(pptx)
        }
        if let pptxUti = UTType("org.openxmlformats.presentationml.presentation"), !types.contains(pptxUti) {
            types.append(pptxUti)
        }
        if let csv = UTType(filenameExtension: "csv"), !types.contains(csv) {
            types.append(csv)
        }
        panel.allowedContentTypes = types
        panel.prompt = NSLocalizedString("Convert", comment: "Convert button prompt")

        if panel.runModal() == .OK, let url = panel.url {
            DocumentConverter.shared.convert(fileURL: url) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let markdown):
                        self.openConvertedDraft(markdown: markdown, sourceURL: url)
                    case .failure(let error):
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Cannot Convert Document", comment: "Error title")
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK button"))
                        alert.runModal()
                    }
                }
            }
        }
    }
}

