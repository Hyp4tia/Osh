import Foundation

extension Notification.Name {
    static let toggleSearch = Notification.Name("toggleSearch")
    static let exportHTML   = Notification.Name("exportHTML")
    static let exportPDF    = Notification.Name("exportPDF")
    static let exportDOCX   = Notification.Name("exportDOCX")
    static let toggleHelp   = Notification.Name("toggleHelp")
    static let zoomIn       = Notification.Name("zoomIn")
    static let zoomOut      = Notification.Name("zoomOut")
    static let resetZoom    = Notification.Name("resetZoom")
    static let reloadFile   = Notification.Name("reloadFile")
    static let reloadFileSucceeded = Notification.Name("reloadFileSucceeded")
    static let reloadFileFailed    = Notification.Name("reloadFileFailed")
    static let resetZoomCompleted  = Notification.Name("resetZoomCompleted")
    static let openInExternalEditor = Notification.Name("openInExternalEditor")

    // Editing session
    static let toggleEditing = Notification.Name("toggleEditing")
    static let saveEdits     = Notification.Name("saveEdits")
    /// Posted after a successful save. object = file URL. The WebView coordinator
    /// listens for this to re-render from disk and refresh its watch baseline.
    static let editsSaved    = Notification.Name("editsSaved")
}
