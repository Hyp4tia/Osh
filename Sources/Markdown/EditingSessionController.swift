import Foundation
import AppKit
import os.log

/// Owns an editing session for the currently open document: holds the draft,
/// tracks dirty state, writes UTF-8 atomically back to the original file.
///
/// Lives outside SwiftUI so both the toolbar button and menu commands drive the
/// same state, and so saving is testable without UI.
@MainActor
final class EditingSessionController: ObservableObject {
    static let shared = EditingSessionController()

    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "EditingSession")

    @Published private(set) var isEditing = false
    /// True when the draft differs from the on-disk content at last save/load.
    @Published private(set) var hasUnsavedChanges = false

    /// The file being edited. nil in editing sessions started without a document.
    private(set) var fileURL: URL?

    /// Draft text shown in the editor.
    @Published var draftText: String = "" {
        didSet {
            if !isUpdatingDraftInternally {
                hasUnsavedChanges = draftText != savedBaseline
            }
        }
    }

    /// Content as it exists on disk (or did when editing began).
    private var savedBaseline: String = ""
    /// Suppresses dirty tracking while programmatically setting the draft.
    private var isUpdatingDraftInternally = false

    /// Called before entering edit mode with unsaved changes from a previous
    /// session. Returning false cancels the transition.
    var confirmUnsavedChanges: ((URL?) -> Bool)?

    func beginEditing(currentContent: String, fileURL: URL?) {
        if hasUnsavedChanges && !fileURLsMatch(fileURL, previous: self.fileURL) {
            guard confirmUnsavedChanges?(self.fileURL) ?? true else { return }
        }
        isEditing = true
        setDraft(currentContent)
        savedBaseline = currentContent
        self.fileURL = fileURL
        hasUnsavedChanges = false
    }

    func endEditing(discardingChanges: Bool) {
        if !discardingChanges && hasUnsavedChanges {
            // Keep state; caller decides (e.g. shows confirmation). Only a save
            // or explicit discard clears the session.
            return
        }
        isEditing = false
        if discardingChanges {
            setDraft("")
            savedBaseline = ""
            fileURL = nil
            hasUnsavedChanges = false
        }
    }

    enum SaveError: LocalizedError {
        case noFile
        case writeFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .noFile:
                return NSLocalizedString("No file is open to save.", comment: "Save error")
            case .writeFailed(let underlying):
                return underlying.localizedDescription
            }
        }
    }

    /// Writes the draft to disk as UTF-8, preserving content byte-for-byte apart
    /// from the user's own edits. Atomic replace avoids partial files on failure.
    @discardableResult
    func save() throws -> URL {
        guard let url = fileURL else { throw SaveError.noFile }
        let data = Data(draftText.utf8)
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw SaveError.writeFailed(underlying: error)
        }
        savedBaseline = draftText
        hasUnsavedChanges = false
        os_log("Saved edits to %{public}@ (%lu bytes)", log: logger, type: .default, url.path, data.count)
        NotificationCenter.default.post(name: .editsSaved, object: url)
        return url
    }

    /// Disk changed underneath us since editing began (external modification).
    func externalModificationDetected(newDiskContent: String) -> Bool {
        newDiskContent != savedBaseline && hasUnsavedChanges
    }

    private func setDraft(_ text: String) {
        isUpdatingDraftInternally = true
        draftText = text
        isUpdatingDraftInternally = false
    }

    private func fileURLsMatch(_ a: URL?, previous b: URL?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x?, y?): return x.standardizedFileURL == y.standardizedFileURL
        default: return false
        }
    }
}
