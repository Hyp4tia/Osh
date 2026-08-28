import Foundation
import os.log

public enum HTMLExportInliner {
    private static let logger = OSLog(subsystem: "com.zeyadistired.osh", category: "HTMLExportInliner")

    public static let allowedMIMETypes: [String: String] = [
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "ico": "image/x-icon",
        "bmp": "image/bmp",
        "tiff": "image/tiff",
        "tif": "image/tiff"
    ]

    public static func inlineSafeLocalImages(
        html: String,
        baseDirectory: URL?,
        allowedFileURLs: Set<URL> = []
    ) -> String {
        var processedHTML = html

        // Match any src attribute starting with file:// or local-md:// (single or double quotes)
        let pattern = "src=['\"](?:file|local-md)://([^'\"]+)['\"]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }

        let matches = regex.matches(in: processedHTML, options: [], range: NSRange(location: 0, length: processedHTML.utf16.count))
        let allowedCanonicalPaths: Set<String> = Set(allowedFileURLs.map { $0.resolvingSymlinksInPath().standardizedFileURL.path })
        let canonicalBaseDirectory = baseDirectory?.resolvingSymlinksInPath().standardizedFileURL

        for match in matches.reversed() {
            let pathRange = match.range(at: 1)
            guard let swiftPathRange = Range(pathRange, in: processedHTML),
                  let fullRange = Range(match.range, in: processedHTML) else {
                continue
            }

            let rawPath = String(processedHTML[swiftPathRange])
            guard let decodedPath = rawPath.removingPercentEncoding else {
                continue
            }

            let cleanedPath = decodedPath.hasPrefix("/") ? decodedPath : "/" + decodedPath
            let candidateURL = URL(fileURLWithPath: cleanedPath)
            let canonicalURL = candidateURL.resolvingSymlinksInPath().standardizedFileURL
            let ext = canonicalURL.pathExtension.lowercased()

            // 1. Whitelist MIME/extension validation
            guard let mimeType = allowedMIMETypes[ext] else {
                os_log("HTMLExportInliner: Rejected non-whitelisted image extension: %{public}@", log: logger, type: .error, ext)
                continue
            }

            // 2. Canonicalization & containment check
            var isAllowed = false
            if let canonicalBase = canonicalBaseDirectory {
                let basePath = canonicalBase.path
                let filePath = canonicalURL.path
                if filePath == basePath || filePath.hasPrefix(basePath.hasSuffix("/") ? basePath : "\(basePath)/") {
                    isAllowed = true
                }
            }

            if !isAllowed && allowedCanonicalPaths.contains(canonicalURL.path) {
                isAllowed = true
            }

            guard isAllowed else {
                os_log("HTMLExportInliner: Rejected image path outside base directory: %{public}@", log: logger, type: .error, canonicalURL.path)
                continue
            }

            // 3. Regular file check & safe read
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: canonicalURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                continue
            }

            let fileData: Data?
            if let baseDir = baseDirectory {
                let hasAccess = baseDir.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess {
                        baseDir.stopAccessingSecurityScopedResource()
                    }
                }
                fileData = try? Data(contentsOf: canonicalURL)
            } else {
                fileData = try? Data(contentsOf: canonicalURL)
            }

            if let data = fileData {
                let base64 = data.base64EncodedString()
                processedHTML.replaceSubrange(fullRange, with: "src=\"data:\(mimeType);base64,\(base64)\"")
            }
        }

        return processedHTML
    }
}
