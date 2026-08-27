import Foundation

enum LinkNavigation {

    private static let blockedExecutableExtensions: Set<String> = [
        "app", "command", "sh", "bash", "zsh", "csh", "ksh", "tool",
        "terminal", "workflow", "action", "pkg", "mpkg", "dmg",
        "exe", "bat", "cmd", "vbs", "scpt", "applescript", "cflow", "osax"
    ]

    static func resolveLocalURLWithFragment(href: String, relativeTo fileURL: URL) -> (URL?, String?) {
        let hrefPath: String
        let fragment: String?
        if let hashRange = href.range(of: "#") {
            hrefPath = String(href[href.startIndex..<hashRange.lowerBound])
            fragment = String(href[hashRange.upperBound...])
        } else {
            hrefPath = href
            fragment = nil
        }
        return (resolveLocalURL(href: hrefPath, relativeTo: fileURL), fragment)
    }

    static func resolveLocalURL(href: String, relativeTo fileURL: URL) -> URL? {
        let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            return nil
        }

        // Reject non-file URL schemes (http, https, mailto, tel, javascript, data, etc.)
        if let colonIndex = trimmed.firstIndex(of: ":") {
            let scheme = String(trimmed[..<colonIndex]).lowercased()
            if scheme != "file" {
                return nil
            }
        }

        guard let decoded = trimmed.removingPercentEncoding else {
            return nil
        }

        if decoded.contains("\0") {
            return nil
        }

        let baseDir = fileURL.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath()
        let targetCandidate: URL

        if decoded.hasPrefix("file://") {
            guard let parsedURL = URL(string: decoded), parsedURL.isFileURL else {
                return nil
            }
            targetCandidate = parsedURL
        } else if decoded.hasPrefix("/") {
            targetCandidate = URL(fileURLWithPath: decoded)
        } else {
            targetCandidate = baseDir.appendingPathComponent(decoded)
        }

        let standardized = targetCandidate.standardizedFileURL
        let resolvedTarget = standardized.resolvingSymlinksInPath()

        // Verify containment within the document base directory
        guard isContained(standardized, in: baseDir) && isContained(resolvedTarget, in: baseDir) else {
            return nil
        }

        // Reject executable / application bundles and dangerous scripts
        let ext = resolvedTarget.pathExtension.lowercased()
        if blockedExecutableExtensions.contains(ext) || resolvedTarget.path.hasSuffix(".app") || resolvedTarget.path.contains(".app/") {
            return nil
        }

        return resolvedTarget
    }

    private static func isContained(_ url: URL, in baseDirectory: URL) -> Bool {
        let basePath = baseDirectory.resolvingSymlinksInPath().standardizedFileURL.path
        let filePath = url.resolvingSymlinksInPath().standardizedFileURL.path
        if filePath == basePath { return true }
        return filePath.hasPrefix(basePath.hasSuffix("/") ? basePath : "\(basePath)/")
    }
}
