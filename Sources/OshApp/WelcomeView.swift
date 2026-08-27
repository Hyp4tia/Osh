import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Osh launch window: wordmark, one quiet open/drop hero, recent files, footer.
/// Designed as a clean, quiet open/drop zone without unnecessary clutter.
/// The document is the product; the window just gets out of the way.
struct WelcomeView: View {
    @State private var isTargeted = false
    @State private var window: NSWindow?
    @State private var openErrorMessage: String?
    @State private var isOpening = false
    @State private var recents: [RecentFile] = []

    @Environment(\.openURL) private var openURL

    private let settingsWindowManager = SettingsWindowManager.shared

    @Environment(\.colorScheme) private var colorScheme
    private let allowedContentTypes: [UTType] = {
        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") {
            types.append(md)
        }
        types.append(.plainText)
        return types
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            hero
            if !recents.isEmpty {
                recentsList
            }
            Spacer(minLength: 0)
            footer
        }
        .frame(width: 560)
        .frame(maxHeight: .infinity)
        .padding(.vertical, 28)
        .background(Color(NSColor.windowBackgroundColor).ignoresSafeArea())
        .background(WelcomeWindowAccessor { window in
            self.window = window
        })
        .onAppear(perform: loadRecents)
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            closeIfAnyDocumentIsOpen()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(Text(NSLocalizedString("Osh App Icon", comment: "App icon accessibility label")))
            }

            // Wordmark with the Coptic name as a quiet companion mark.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Osh")
                    .font(.system(size: 26, weight: .semibold))
                Text("ⲱϣ")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)

            Text(NSLocalizedString("A quiet reader for Markdown.", comment: "Welcome tagline"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }

    private var hero: some View {
        Button(action: openFilePicker) {
            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(isTargeted ? Color.accentColor : Color.secondary)

                Text(NSLocalizedString("Open Markdown File…", comment: "Open file button"))
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(.primary)

                Text(NSLocalizedString("or drop files here", comment: "Drop hint"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                if isOpening {
                    ProgressView()
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
        }
        .buttonStyle(WelcomeDropZoneButtonStyle(isTargeted: isTargeted))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(isOpening)
        .frame(height: 136)
        .padding(.horizontal, 44)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .accessibilityHint(Text(NSLocalizedString("Drag & drop .md/.mdx/.txt here", comment: "Drop hint")))
    }

    @ViewBuilder
    private var recentsList: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(NSLocalizedString("Recent", comment: "Recents section title"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 10)
                .padding(.bottom, 2)

            ForEach(recents) { recent in
                RecentFileRowView(recent: recent) {
                    open(urls: [recent.url])
                }
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 36)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(NSLocalizedString("Settings", comment: "Open settings button")) {
                settingsWindowManager.show()
            }
            .buttonStyle(WelcomeFooterLinkButtonStyle())

            separatorDot

            Button(NSLocalizedString("Help", comment: "Help button")) {
                let url = LocalizationManager.helpURL(for: AppearancePreference.shared.uiLanguage)
                openURL(url)
            }
            .buttonStyle(WelcomeFooterLinkButtonStyle())

            Spacer()

            Text(DisplayVersion.formattedBetaText())
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(Color.secondary.opacity(0.55))
        }
        .padding(.top, 18)
        .padding(.horizontal, 44)
        .font(.system(size: 12, weight: .regular))
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 3, height: 3)
    }

    // MARK: - Recents

    private func loadRecents() {
        recents = RecentFilesStore.shared.recents(limit: 4)
    }

    // MARK: - Opening

    private func openFilePicker() {
        openErrorMessage = nil
        isOpening = true

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = allowedContentTypes
        panel.prompt = NSLocalizedString("Open", comment: "Open file panel prompt")

        if panel.runModal() == .OK {
            open(urls: panel.urls)
        } else {
            isOpening = false
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        openErrorMessage = nil
        isOpening = true

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    DispatchQueue.main.async {
                        openErrorMessage = error.localizedDescription
                        isOpening = false
                    }
                    return
                }

                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let raw = item as? URL {
                    url = raw
                } else if let raw = item as? String {
                    url = URL(string: raw)
                } else {
                    url = nil
                }

                if let url {
                    DispatchQueue.main.async {
                        open(urls: [url])
                    }
                }
            }
        }

        return true
    }

    private func open(urls: [URL]) {
        guard !urls.isEmpty else {
            isOpening = false
            return
        }

        var remaining = urls.count
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error {
                    DispatchQueue.main.async {
                        openErrorMessage = error.localizedDescription
                    }
                }

                DispatchQueue.main.async {
                    remaining -= 1
                    if remaining <= 0 {
                        isOpening = false
                    }
                }
            }
        }
    }

    private func closeIfAnyDocumentIsOpen() {
        guard window != nil else { return }
        if !NSDocumentController.shared.documents.isEmpty {
            window?.close()
            window = nil
        }
    }
}

// MARK: - Welcome View Supporting Styles & Components

private struct WelcomeDropZoneButtonStyle: ButtonStyle {
    let isTargeted: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isTargeted
                            ? Color.accentColor.opacity(0.08)
                            : (isHovered ? Color.primary.opacity(0.03) : Color(NSColor.controlBackgroundColor).opacity(0.55))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isTargeted
                            ? Color.accentColor.opacity(0.85)
                            : (isHovered ? Color.secondary.opacity(0.35) : Color.secondary.opacity(0.18)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isTargeted)
            .onHover { isHovered = $0 }
    }
}

private struct RecentFileRowView: View {
    let recent: RecentFile
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text(recent.name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                Text(recent.folder)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

private struct WelcomeFooterLinkButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isHovered ? .primary : .secondary)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

// MARK: - Recents store

struct RecentFile: Identifiable {
    let url: URL
    var id: String { url.path }
    var name: String { url.lastPathComponent }
    /// Parent folder path, shortened for the right-hand column.
    var folder: String {
        let dir = url.deletingLastPathComponent().path
        return (dir as NSString).abbreviatingWithTildeInPath
    }
}

final class RecentFilesStore {
    static let shared = RecentFilesStore()
    private static let key = "oshRecentMarkdownFiles"
    private let maxEntries = 20

    func recents(limit: Int) -> [RecentFile] {
        let paths = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        return paths.compactMap { path -> RecentFile? in
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else {
                return nil
            }
            return RecentFile(url: URL(fileURLWithPath: path))
        }
        .prefix(limit)
        .map { $0 }
    }

    func record(url: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > maxEntries {
            paths = Array(paths.prefix(maxEntries))
        }
        UserDefaults.standard.set(paths, forKey: Self.key)
    }
}

// MARK: - Window plumbing (kept from previous welcome implementation)

private struct WelcomeWindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.setContentSize(NSSize(width: 560, height: 600))
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class SettingsWindowManager: NSObject {
    static let shared = SettingsWindowManager()

    private var settingsWindow: NSWindow?

    @objc func show() {
        NSApp.activate(ignoringOtherApps: true)

        let keyWindowBefore = NSApp.keyWindow

        _ = tryPerformCmdCommaKeyEquivalent()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.didOpenSettingsWindow(keyWindowBefore: keyWindowBefore) {
                return
            }

            if self.trySendAction(Selector(("showSettingsWindow:"))) {
                return
            }

            if self.trySendAction(Selector(("showPreferencesWindow:"))) {
                return
            }

            if self.tryPerformSettingsMenuItem() {
                return
            }

            self.showFallbackSettingsWindow()
        }
    }

    private func trySendAction(_ selector: Selector) -> Bool {
        NSApp.sendAction(selector, to: nil, from: nil)
    }

    private func tryPerformSettingsMenuItem() -> Bool {
        guard let mainMenu = NSApp.mainMenu else { return false }
        let items = allMenuItems(in: mainMenu)

        if let item = items.first(where: { isSettingsMenuItem($0) }) {
            if let action = item.action {
                return NSApp.sendAction(action, to: nil, from: item)
            }
        }

        return false
    }

    private func tryPerformCmdCommaKeyEquivalent() -> Bool {
        guard let menu = NSApp.mainMenu else { return false }
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            characters: ",",
            charactersIgnoringModifiers: ",",
            isARepeat: false,
            keyCode: 43
        ) else {
            return false
        }

        return menu.performKeyEquivalent(with: event)
    }

    private func didOpenSettingsWindow(keyWindowBefore: NSWindow?) -> Bool {
        if let settingsWindow {
            return settingsWindow.isVisible
        }

        guard let keyAfter = NSApp.keyWindow else { return false }
        if let before = keyWindowBefore, keyAfter === before {
            return false
        }

        let title = keyAfter.title.lowercased()
        if title.contains("settings") || title.contains("preferences") {
            return true
        }

        return keyAfter.identifier?.rawValue.lowercased().contains("settings") == true
    }

    private func isSettingsMenuItem(_ item: NSMenuItem) -> Bool {
        let hasCmdComma = item.keyEquivalent == "," && item.keyEquivalentModifierMask.contains(.command)
        if hasCmdComma {
            return true
        }

        let title = item.title.lowercased()
        if title.contains("settings") || title.contains("preferences") {
            return true
        }

        if item.title.contains("设置") || item.title.contains("偏好") {
            return true
        }

        if let actionName = item.action.map({ NSStringFromSelector($0).lowercased() }) {
            if actionName.contains("showsettings") || actionName.contains("showpreferences") {
                return true
            }
        }

        return false
    }

    private func allMenuItems(in menu: NSMenu) -> [NSMenuItem] {
        var result: [NSMenuItem] = []
        for item in menu.items {
            result.append(item)
            if let submenu = item.submenu {
                result.append(contentsOf: allMenuItems(in: submenu))
            }
        }
        return result
    }

    private func showFallbackSettingsWindow() {
        if let window = settingsWindow {
            window.title = NSLocalizedString("Settings", comment: "Settings window title")
            window.appearance = AppearancePreference.shared.currentMode.nsAppearance
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Settings", comment: "Settings window title")
        window.appearance = AppearancePreference.shared.currentMode.nsAppearance
        window.center()
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
