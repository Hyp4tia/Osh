import SwiftUI
import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: UpdateDelegate.shared,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {

        if CommandLine.arguments.contains("--register-only") {
            NSApplication.shared.terminate(nil)
        }

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        UpdateRestorationManager.shared.restoreLastOpenedFile()
        AppearancePreference.shared.applyAppAppearance(AppearancePreference.shared.currentMode)
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }


        if url.scheme == "markdownpreview",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let path = components.queryItems?.first(where: { $0.name == "path" })?.value {
            let fileURL = URL(fileURLWithPath: path)
            NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { _, _, error in
                if let error = error {
                } else {
                }
            }
        }
    }

    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        let fileURL = URL(fileURLWithPath: filename)
        UpdateRestorationManager.shared.saveLastOpenedFile(url: fileURL)
        RecentFilesStore.shared.record(url: fileURL)
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let docs = NSDocumentController.shared.documents
        let hasEdited = docs.contains { $0.isDocumentEdited }
        if hasEdited {
            NSDocumentController.shared.closeAllDocuments(withDelegate: self, didCloseAllSelector: #selector(documentController(_:didCloseAll:contextInfo:)), contextInfo: nil)
            return .terminateLater
        }
        return .terminateNow
    }

    @objc func documentController(_ docController: NSDocumentController, didCloseAll didCloseAllFlag: Bool, contextInfo: UnsafeMutableRawPointer?) {
        NSApplication.shared.reply(toApplicationShouldTerminate: didCloseAllFlag)
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppearancePreference.shared.flushSharedPreferences()
    }
}

struct MarkdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var preference = AppearancePreference.shared

    /// RTL languages mirror the whole SwiftUI layout, not just text alignment.
    private var uiLayoutDirection: LayoutDirection {
        LocalizationManager.isRTL(preference.uiLanguage) ? .rightToLeft : .leftToRight
    }

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .preferredColorScheme(preference.currentMode == .dark ? .dark : preference.currentMode == .light ? .light : nil)
                .environment(\.layoutDirection, uiLayoutDirection)
        }
        .windowStyle(.titleBar)

        DocumentGroup(newDocument: MarkdownDocument()) { file in
            DocumentPreviewScene(
                document: file.$document,
                fileURL: file.fileURL,
                preference: preference
            )
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(action: {
                    DocumentImportController.shared.importAndConvertDocument()
                }) {
                    Text(NSLocalizedString("Convert Document to Markdown…", comment: "Convert document menu item"))
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button(action: {
                    NotificationCenter.default.post(name: .toggleEditing, object: nil)
                }) {
                    Text(NSLocalizedString("Edit Markdown", comment: "Edit markdown menu item"))
                }
                .keyboardShortcut("e", modifiers: [.command])

                Button(action: {
                    NotificationCenter.default.post(name: .reloadFile, object: nil)
                }) {
                    Text(NSLocalizedString("Reload File", comment: "Reload file menu item"))
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button(action: {
                    NotificationCenter.default.post(name: .openInExternalEditor, object: nil)
                }) {
                    Text(NSLocalizedString("Open in External Editor", comment: "Open in external editor menu item"))
                }
                .keyboardShortcut("e", modifiers: [.command, .option])

                Divider()

                Button(action: {
                    NotificationCenter.default.post(name: .exportHTML, object: nil)
                }) {
                    Text(NSLocalizedString("Export as HTML…", comment: "Export HTML menu item"))
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Button(action: {
                    NotificationCenter.default.post(name: .exportPDF, object: nil)
                }) {
                    Text(NSLocalizedString("Export as PDF…", comment: "Export PDF menu item"))
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Button(action: {
                    NotificationCenter.default.post(name: .exportDOCX, object: nil)
                }) {
                    Text(NSLocalizedString("Export as Word…", comment: "Export DOCX menu item"))
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterController: appDelegate.updaterController)
            }

            CommandGroup(after: .textEditing) {
                Divider()
                Button(action: {
                    NotificationCenter.default.post(name: .toggleSearch, object: nil)
                }) {
                    Text(NSLocalizedString("Find...", comment: "Search menu item"))
                }
                .keyboardShortcut("f", modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Button(NSLocalizedString("Osh Help", comment: "Help menu item")) {
                    let url = LocalizationManager.helpURL(for: AppearancePreference.shared.uiLanguage)
                    NSWorkspace.shared.open(url)
                }
                .keyboardShortcut("?", modifiers: [.command])
                
                Divider()
                
                Button(NSLocalizedString("README", comment: "README menu item")) {
                    if let url = URL(string: "https://github.com/Hyp4tia/Osh#readme") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button(NSLocalizedString("Report an Issue", comment: "Report issue menu item")) {
                    if let url = URL(string: "https://github.com/Hyp4tia/Osh/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Divider()
                
                Button(NSLocalizedString("Release Notes", comment: "Release notes menu item")) {
                    if let url = URL(string: "https://github.com/Hyp4tia/Osh/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            CommandGroup(after: .toolbar) {
                Button(action: {
                    NotificationCenter.default.post(name: .toggleViewMode, object: nil)
                }) {
                    Text(NSLocalizedString("Toggle Preview / Source", comment: "Toggle preview or source menu item"))
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Button(NSLocalizedString("Reset Zoom", comment: "Reset zoom menu item")) {
                    NotificationCenter.default.post(name: .resetZoom, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)

                Button(NSLocalizedString("Zoom In", comment: "Zoom in menu item")) {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("=", modifiers: .command)

                Button(NSLocalizedString("Zoom Out", comment: "Zoom out menu item")) {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)

                Divider()

                Menu(NSLocalizedString("Appearance", comment: "Appearance submenu")) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button(action: {
                            preference.currentMode = mode
                        }) {
                            HStack {
                                Text(mode.displayName)
                                if preference.currentMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

private struct DocumentPreviewScene: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?
    @ObservedObject var preference: AppearancePreference

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isEditing: Bool = false
    @State private var viewMode: ViewMode = .preview
    @State private var toolbarToast: ToolbarToastState?
    @State private var hostWindow: NSWindow?

    private let initialContentSize: CGSize
    private let reloadSuccessToastMessage = NSLocalizedString("已重新载入文档", comment: "Reload success toast")
    private let reloadFailureToastMessage = NSLocalizedString("重新载入失败", comment: "Reload failure toast")
    private let resetZoomToastMessage = NSLocalizedString("已重置缩放", comment: "Reset zoom toast")

    init(document: Binding<MarkdownDocument>, fileURL: URL?, preference: AppearancePreference) {
        self._document = document
        self.fileURL = fileURL
        self.preference = preference
        let savedFrame = AppearancePreference.shared.hostWindowFrame
        self.initialContentSize = WindowAccessor.initialDocumentContentSize(savedFrame: savedFrame)
    }

    var body: some View {
        ZStack {
            MarkdownWebView(
                content: document.text,
                fileURL: fileURL,
                appearanceMode: preference.currentMode,
                viewMode: viewMode,
                baseFontSize: preference.baseFontSize,
                enableMermaid: preference.enableMermaid,
                enableKatex: preference.enableKatex,
                enableEmoji: preference.enableEmoji,
                enableTypst: preference.enableTypst,
                codeHighlightTheme: preference.codeHighlightTheme,
                collapseBlockquotesByDefault: preference.collapseBlockquotesByDefault,
                showLineNumbers: preference.showLineNumbers,
                readingTheme: preference.readingTheme
            )
            .opacity(isEditing ? 0 : 1)
            .allowsHitTesting(!isEditing)
            .animation(nil, value: isEditing)

            if isEditing {
                SourceEditorView(
                    text: $document.text,
                    appearanceMode: preference.currentMode,
                    onSave: { saveDocument() }
                )
                .animation(nil, value: isEditing)
            }

            // Document Toolbar
            HStack(spacing: 0) {
                // Leading: Document Source / Preview toggle
                Button(action: {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.18)) {
                        viewMode = (viewMode == .preview) ? .source : .preview
                    }
                }) {
                    Image(systemName: viewMode == .source ? "eye.fill" : "doc.plaintext")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(NativeToolbarItemButtonStyle())
                .foregroundColor(Color(NSColor.labelColor))
                .help(viewMode == .source
                    ? NSLocalizedString("Show Preview", comment: "Show preview tooltip")
                    : NSLocalizedString("Show Markdown Source", comment: "Show source tooltip"))
                .accessibilityLabel(viewMode == .source
                    ? NSLocalizedString("Show Preview", comment: "Show preview tooltip")
                    : NSLocalizedString("Show Markdown Source", comment: "Show source tooltip"))

                Spacer()

                // Trailing toolbar actions
                HStack(spacing: 8) {
                    // 1. Edit / Done (Primary Action)
                    Button(action: {
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.18)) {
                            isEditing.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isEditing ? "checkmark" : "square.and.pencil")
                                .font(.system(size: 11, weight: .semibold))
                            Text(isEditing
                                ? NSLocalizedString("Done", comment: "Done editing button")
                                : NSLocalizedString("Edit", comment: "Edit markdown button"))
                                .font(.system(size: 12, weight: isEditing ? .semibold : .medium))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isEditing ? Color.accentColor : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isEditing ? Color.clear : Color.secondary.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundColor(isEditing ? .white : .primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(NativePrimaryToolbarButtonStyle(isEditing: isEditing))
                    .help(isEditing
                        ? NSLocalizedString("Done Editing (⌘E)", comment: "Done editing tooltip")
                        : NSLocalizedString("Edit Markdown (⌘E)", comment: "Edit markdown tooltip"))
                    .accessibilityLabel(isEditing
                        ? NSLocalizedString("Done Editing", comment: "Done editing accessibility label")
                        : NSLocalizedString("Edit Markdown", comment: "Edit markdown accessibility label"))

                    // 2. Undo
                    Button(action: {
                        performUndo()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(NativeToolbarItemButtonStyle())
                    .foregroundColor(Color(NSColor.labelColor))
                    .help(NSLocalizedString("Undo (⌘Z)", comment: "Undo tooltip"))
                    .accessibilityLabel(NSLocalizedString("Undo", comment: "Undo accessibility label"))

                    // 3. Redo
                    Button(action: {
                        performRedo()
                    }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(NativeToolbarItemButtonStyle())
                    .foregroundColor(Color(NSColor.labelColor))
                    .help(NSLocalizedString("Redo (⇧⌘Z)", comment: "Redo tooltip"))
                    .accessibilityLabel(NSLocalizedString("Redo", comment: "Redo accessibility label"))

                    // 4. Aa Text Size Popover
                    TextSizeToolbarButton(
                        preference: preference,
                        onReset: {
                            showToolbarToast(resetZoomToastMessage)
                        }
                    )

                    // 5. More Menu
                    DocumentMoreMenu(
                        preference: preference,
                        onReload: { reloadDocumentFromDisk() },
                        onHelp: { NotificationCenter.default.post(name: .toggleHelp, object: nil) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .environment(\.layoutDirection, .leftToRight)
            .zIndex(2)

            ToolbarFeedbackToastHost(toast: toolbarToast)
                .allowsHitTesting(false)
                .zIndex(3)
        }
        .onAppear {
            if let fileURL = fileURL {
                UpdateRestorationManager.shared.saveLastOpenedFile(url: fileURL)
                RecentFilesStore.shared.record(url: fileURL)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleEditing)) { _ in
            guard NSApp.keyWindow === hostWindow else { return }
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.18)) {
                isEditing.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleViewMode)) { _ in
            guard NSApp.keyWindow === hostWindow else { return }
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.18)) {
                viewMode = (viewMode == .preview) ? .source : .preview
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reloadFile)) { _ in
            guard NSApp.keyWindow === hostWindow else { return }
            reloadDocumentFromDisk()
        }
        .frame(
            minWidth: WindowAccessor.minimumRestorableWindowSize.width,
            idealWidth: initialContentSize.width,
            maxWidth: .infinity,
            minHeight: WindowAccessor.minimumRestorableWindowSize.height,
            idealHeight: initialContentSize.height,
            maxHeight: .infinity
        )
        .environmentObject(preference)
        .environment(\.layoutDirection, LocalizationManager.isRTL(preference.uiLanguage) ? LayoutDirection.rightToLeft : .leftToRight)
        .preferredColorScheme(preference.currentMode == .dark ? .dark : preference.currentMode == .light ? .light : nil)
        .onChange(of: preference.currentMode) { newMode in
            hostWindow?.appearance = newMode.nsAppearance
        }
        .background(
            WindowAccessor()
        )
        .background(HostWindowCapture { window in
            hostWindow = window
            window.appearance = preference.currentMode.nsAppearance
            if fileURL == nil, let title = document.suggestedTitle, !title.isEmpty {
                let applyDocumentState: () -> Void = {
                    if let doc = window.windowController?.document as? NSDocument {
                        doc.displayName = title
                        doc.updateChangeCount(.changeDone)
                    }
                    window.title = title
                    window.isDocumentEdited = true
                }
                applyDocumentState()
                DispatchQueue.main.async {
                    applyDocumentState()
                }
            }
        })
        .onAppear {
            if fileURL == nil, let title = document.suggestedTitle, !title.isEmpty {
                DispatchQueue.main.async {
                    if let doc = hostWindow?.windowController?.document as? NSDocument {
                        doc.displayName = title
                        doc.updateChangeCount(.changeDone)
                    }
                    hostWindow?.title = title
                    hostWindow?.isDocumentEdited = true
                }
            }
        }
        .background(ToolbarFeedbackObserver { result in
            switch result {
            case .reloadSuccess:
                showToolbarToast(reloadSuccessToastMessage)
            case .reloadFailure:
                showToolbarToast(reloadFailureToastMessage)
            case .resetZoom:
                showToolbarToast(resetZoomToastMessage)
            }
        })
    }

    // MARK: - Document Actions

    private func performUndo() {
        if let textView = hostWindow?.firstResponder as? NSTextView {
            textView.breakUndoCoalescing()
        }
        guard let undoManager = hostWindow?.undoManager ?? NSApp.keyWindow?.undoManager else { return }
        if undoManager.canUndo {
            undoManager.undo()
        }
    }

    private func performRedo() {
        guard let undoManager = hostWindow?.undoManager ?? NSApp.keyWindow?.undoManager else { return }
        if undoManager.canRedo {
            undoManager.redo()
        }
    }

    private func saveDocument() {
        NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
        showToolbarToast(NSLocalizedString("Saved", comment: "Save success toast"))
    }

    private func reloadDocumentFromDisk() {
        guard let url = fileURL else {
            showToolbarToast(reloadFailureToastMessage)
            return
        }
        do {
            let fresh = try String(contentsOf: url, encoding: .utf8)
            document.text = fresh
            showToolbarToast(reloadSuccessToastMessage)
            if let window = hostWindow {
                NotificationCenter.default.post(name: .reloadFileSucceeded, object: window)
            }
        } catch {
            showToolbarToast(reloadFailureToastMessage)
            if let window = hostWindow {
                NotificationCenter.default.post(name: .reloadFileFailed, object: window)
            }
        }
    }

    private func showToolbarToast(_ message: String) {
        NSLog("✅ Toolbar feedback toast requested: %@", message)
        let id = UUID()
        let toast = ToolbarToastState(id: id, message: message)

        withAnimation(.easeOut(duration: 0.16)) {
            toolbarToast = toast
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.18)) {
                if toolbarToast?.id == id {
                    toolbarToast = nil
                }
            }
        }
    }
}

private struct ToolbarToastState: Equatable {
    let id: UUID
    let message: String
}

/// Captures this scene's host window so notification handlers can tell which
/// open document a menu command targets.
private struct HostWindowCapture: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct ToolbarFeedbackToastHost: NSViewRepresentable {
    let toast: ToolbarToastState?

    func makeNSView(context: Context) -> ToolbarFeedbackToastHostView {
        ToolbarFeedbackToastHostView()
    }

    func updateNSView(_ nsView: ToolbarFeedbackToastHostView, context: Context) {
        nsView.update(toast: toast)
    }
}

private final class ToolbarFeedbackToastHostView: NSView {
    private var currentToastID: UUID?
    private weak var toastView: NSView?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func update(toast: ToolbarToastState?) {
        guard let toast else {
            removeToast()
            return
        }

        guard currentToastID != toast.id else { return }
        currentToastID = toast.id
        showToast(message: toast.message)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            removeToast()
        }
    }

    private func showToast(message: String) {
        removeToast()

        let toastContainer = ToolbarToastContainerView()
        toastContainer.setAccessibilityElement(true)
        toastContainer.setAccessibilityLabel(message)

        let messageLabel = NSTextField(labelWithString: message)
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .labelColor
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        toastContainer.addSubview(messageLabel)
        addSubview(toastContainer)

        NSLayoutConstraint.activate([
            toastContainer.topAnchor.constraint(equalTo: topAnchor, constant: 52),
            toastContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -14)
        ])

        toastContainer.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            toastContainer.animator().alphaValue = 1
        }

        toastView = toastContainer
    }

    private func removeToast() {
        toastView?.removeFromSuperview()
        toastView = nil
        currentToastID = nil
    }

    private final class ToolbarToastContainerView: NSView {
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            configure()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }

        private func configure() {
            wantsLayer = true
            translatesAutoresizingMaskIntoConstraints = false
            layerContentsRedrawPolicy = .onSetNeedsDisplay
        }

        override func layout() {
            super.layout()
            applyToastStyle()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyToastStyle()
        }

        private func applyToastStyle() {
            guard let layer else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)

            let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2

            layer.masksToBounds = false
            layer.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.97).cgColor
            layer.cornerRadius = 12
            layer.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
            layer.borderWidth = 1 / scale
            layer.shadowColor = NSColor.black.withAlphaComponent(0.18).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 10
            layer.shadowOffset = NSSize(width: 0, height: -4)
            layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: 12, cornerHeight: 12, transform: nil)

            CATransaction.commit()
        }
    }

}

private struct ToolbarFeedbackToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(NSColor.labelColor))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.94))
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(NSColor.separatorColor).opacity(0.45), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityLabel(message)
    }
}

private struct ToolbarFeedbackObserver: NSViewRepresentable {
    let onResult: (ToolbarFeedbackResult) -> Void

    func makeNSView(context: Context) -> WindowObservingToolbarFeedbackView {
        let view = WindowObservingToolbarFeedbackView()
        view.onWindowAttach = { window in
            context.coordinator.router.monitor(window: window)
        }
        return view
    }

    func updateNSView(_ nsView: WindowObservingToolbarFeedbackView, context: Context) {
        context.coordinator.router.onResult = onResult
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    final class Coordinator: NSObject {
        let router: ToolbarFeedbackNotificationRouter

        init(onResult: @escaping (ToolbarFeedbackResult) -> Void) {
            router = ToolbarFeedbackNotificationRouter(onResult: onResult)
        }
    }
}

private final class WindowObservingToolbarFeedbackView: NSView {
    var onWindowAttach: ((NSWindow) -> Void)?
    private weak var attachedWindow: NSWindow?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, attachedWindow !== window else { return }
        attachedWindow = window
        onWindowAttach?(window)
    }
}

struct CheckForUpdatesView: View {
    let updaterController: SPUStandardUpdaterController

    var body: some View {
        Button(NSLocalizedString("Check for Updates...", comment: "Check for updates menu item")) {
            NSApp.sendAction(#selector(SPUStandardUpdaterController.checkForUpdates(_:)), to: updaterController, from: nil)
        }
        .keyboardShortcut("u", modifiers: [.command])
        Divider()
    }
}

// MARK: - Toolbar Button Styles

struct NativeToolbarItemButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? Color.primary.opacity(0.14)
                            : (isHovered ? Color.primary.opacity(0.08) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct NativePrimaryToolbarButtonStyle: ButtonStyle {
    let isEditing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.84 : (isHovered && !isEditing ? 0.88 : 1.0))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct NativePopoverActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? Color.primary.opacity(0.12)
                            : (isHovered ? Color.primary.opacity(0.06) : Color.clear)
                    )
            )
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

// MARK: - Toolbar Components

struct TextSizeToolbarButton: View {
    @ObservedObject var preference: AppearancePreference
    let onReset: () -> Void
    @State private var isShowingPopover: Bool = false

    var body: some View {
        Button(action: {
            isShowingPopover.toggle()
        }) {
            Image(systemName: "textformat.size")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(NativeToolbarItemButtonStyle())
        .foregroundColor(Color(NSColor.labelColor))
        .help(NSLocalizedString("Text Size", comment: "Text size tooltip"))
        .accessibilityLabel(NSLocalizedString("Text Size", comment: "Text size accessibility label"))
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            TextSizePopoverView(preference: preference, onReset: onReset)
        }
    }
}

struct TextSizePopoverView: View {
    @ObservedObject var preference: AppearancePreference
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(NSLocalizedString("Text Size", comment: "Text size popover title"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text("A")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Slider(
                        value: Binding(
                            get: { preference.baseFontSize },
                            set: { preference.baseFontSize = $0 }
                        ),
                        in: 12...24,
                        step: 1
                    )
                    .accentColor(.accentColor)

                    Text("A")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text("\(Int(round((preference.baseFontSize / 14.0) * 100)))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Divider()

            Button(action: {
                preference.baseFontSize = 14
                onReset()
            }) {
                Text(NSLocalizedString("Reset to Default", comment: "Reset text size to default"))
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NativePopoverActionButtonStyle())
        }
        .padding(16)
        .frame(width: 220)
    }
}

struct DocumentMoreMenu: View {
    @ObservedObject var preference: AppearancePreference
    let onReload: () -> Void
    let onHelp: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Menu {
            Menu(NSLocalizedString("Appearance", comment: "Appearance submenu")) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button(action: {
                        preference.currentMode = mode
                    }) {
                        HStack {
                            Text(mode.displayName)
                            if preference.currentMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Button(action: onReload) {
                Label(NSLocalizedString("Reload Document", comment: "Reload document menu item"), systemImage: "arrow.clockwise")
            }

            Menu(NSLocalizedString("Export", comment: "Export submenu")) {
                Button(action: {
                    NotificationCenter.default.post(name: .exportHTML, object: nil)
                }) {
                    Text(NSLocalizedString("Export as HTML…", comment: "Export HTML menu item"))
                }

                Button(action: {
                    NotificationCenter.default.post(name: .exportPDF, object: nil)
                }) {
                    Text(NSLocalizedString("Export as PDF…", comment: "Export PDF menu item"))
                }

                Button(action: {
                    NotificationCenter.default.post(name: .exportDOCX, object: nil)
                }) {
                    Text(NSLocalizedString("Export as Word…", comment: "Export DOCX menu item"))
                }
            }

            Divider()

            Button(action: {
                SettingsWindowManager.shared.show()
            }) {
                Label(NSLocalizedString("Settings…", comment: "Settings menu item"), systemImage: "gearshape")
            }

            Button(action: onHelp) {
                Label(NSLocalizedString("Help / Feature Guide", comment: "Help / feature guide menu item"), systemImage: "questionmark.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .padding(.horizontal, 2)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .foregroundColor(Color(NSColor.labelColor))
        .help(NSLocalizedString("More Actions", comment: "More actions menu tooltip"))
        .accessibilityLabel(NSLocalizedString("More Actions", comment: "More actions accessibility label"))
    }
}
