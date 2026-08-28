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

            // 1. Strict traversal protection
            if decodedPath.contains("..") || decodedPath.contains("\0") {
                os_log("HTMLExportInliner: Rejected path traversal sequence: %{public}@", log: logger, type: .error, rawPath)
                continue
            }

            let ext = (decodedPath as NSString).pathExtension.lowercased()
            guard let mimeType = allowedMIMETypes[ext] else {
                os_log("HTMLExportInliner: Rejected non-whitelisted image extension: %{public}@", log: logger, type: .error, ext)
                continue
            }

            // 2. Resolve target URL strictly against canonical base directory or explicitly allowed URLs
            var targetURL: URL?

            let cleanedPath = decodedPath.hasPrefix("/") ? decodedPath : "/" + decodedPath
            let candidateURL = URL(fileURLWithPath: cleanedPath).resolvingSymlinksInPath().standardizedFileURL
            let candidatePath = candidateURL.path

            if let canonicalBase = canonicalBaseDirectory {
                let canonicalBasePath = canonicalBase.path
                if candidatePath == canonicalBasePath || candidatePath.hasPrefix(canonicalBasePath.hasSuffix("/") ? canonicalBasePath : "\(canonicalBasePath)/") {
                    let relativeSuffix = String(candidatePath.dropFirst(canonicalBasePath.count))
                    let cleanComponents = relativeSuffix.split(separator: "/").map(String.init)
                    if !cleanComponents.isEmpty && !cleanComponents.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) {
                        var constructed = canonicalBase
                        for component in cleanComponents {
                            constructed = constructed.appendingPathComponent(component, isDirectory: false)
                        }
                        targetURL = constructed.resolvingSymlinksInPath().standardizedFileURL
                    }
                }
            }

            if targetURL == nil && allowedCanonicalPaths.contains(candidatePath) {
                targetURL = candidateURL
            }

            guard let safeURL = targetURL else {
                os_log("HTMLExportInliner: Rejected image outside permitted base directory: %{public}@", log: logger, type: .error, rawPath)
                continue
            }

            // 3. Coordinated file check & safe read
            var fileData: Data?
            let coordinator = NSFileCoordinator()
            var coordError: NSError?
            coordinator.coordinate(readingItemAt: safeURL, options: [], error: &coordError) { coordinatedURL in
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: coordinatedURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                    return
                }

                if let baseDir = baseDirectory {
                    let hasAccess = baseDir.startAccessingSecurityScopedResource()
                    defer {
                        if hasAccess {
                            baseDir.stopAccessingSecurityScopedResource()
                        }
                    }
                    fileData = try? Data(contentsOf: coordinatedURL)
                } else {
                    fileData = try? Data(contentsOf: coordinatedURL)
                }
            }

            if let data = fileData {
                let base64 = data.base64EncodedString()
                processedHTML.replaceSubrange(fullRange, with: "src=\"data:\(mimeType);base64,\(base64)\"")
            }
        }

        return processedHTML
    }
}
