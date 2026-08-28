import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Osh launch window: wordmark, one quiet open/drop hero, recent files, footer.
/// Designed as a clean, quiet open/drop zone without unnecessary clutter.
/// The document is the product; the window just gets out of the way.
struct WelcomeView: View {
    @AppStorage("oshHasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var isTargeted = false
    @State private var window: NSWindow?
    @State private var openErrorMessage: String?
    @State private var isOpening = false
    @State private var recents: [RecentFile] = []
    @State private var hasAppeared = false

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let settingsWindowManager = SettingsWindowManager.shared

    @Environment(\.colorScheme) private var colorScheme
    private let allowedContentTypes: [UTType] = {
        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") {
            types.append(md)
        }
        if let pdf = UTType.pdf as UTType? {
            types.append(pdf)
        }
        if let csv = UTType.commaSeparatedText as UTType? {
            types.append(csv)
        }
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
        let skillTypes = UTType.types(tag: "skill", tagClass: .filenameExtension, conformingTo: nil)
        for st in skillTypes {
            if !types.contains(st) {
                types.append(st)
            }
        }
        if let skill = UTType(filenameExtension: "skill"), !types.contains(skill) {
            types.append(skill)
        }
        if let oshSkill = UTType("com.osh.skill"), !types.contains(oshSkill) {
            types.append(oshSkill)
        }
        if let codexSkill = UTType("com.openai.codex.skill"), !types.contains(codexSkill) {
            types.append(codexSkill)
        }
        types.append(.plainText)
        return types
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            if !hasCompletedOnboarding {
                onboardingContent
                    .opacity(hasAppeared || reduceMotion ? 1 : 0)
                    .offset(y: hasAppeared || reduceMotion ? 0 : 6)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 4)),
                        removal: .opacity.combined(with: .offset(y: -4))
                    ))
            } else {
                VStack(spacing: 0) {
                    hero
                    if !recents.isEmpty {
                        recentsList
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 4)),
                    removal: .opacity.combined(with: .offset(y: -4))
                ))
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
        .onAppear {
            loadRecents()
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.22)) {
                hasAppeared = true
            }
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            closeIfAnyDocumentIsOpen()
        }
        .alert(isPresented: Binding(
            get: { openErrorMessage != nil },
            set: { if !$0 { openErrorMessage = nil } }
        )) {
            Alert(
                title: Text(NSLocalizedString("Cannot Open Document", comment: "Error title")),
                message: Text(openErrorMessage ?? ""),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "OK button")))
            )
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

    private var onboardingContent: some View {
        VStack(spacing: 16) {
            // Grouped Feature Card
            VStack(spacing: 12) {
                OnboardingFeatureRow(
                    icon: "doc.text.magnifyingglass",
                    title: NSLocalizedString("Quiet Reading & Quick Look", comment: "Onboarding feature 1 title"),
                    description: NSLocalizedString("Preview instantly with Spacebar in Finder or read distraction-free.", comment: "Onboarding feature 1 description")
                )

                Divider()

                OnboardingFeatureRow(
                    icon: "function",
                    title: NSLocalizedString("Rich Markdown & Math", comment: "Onboarding feature 2 title"),
                    description: NSLocalizedString("Render Mermaid diagrams, KaTeX & Typst equations, tables, and themes.", comment: "Onboarding feature 2 description")
                )

                Divider()

                OnboardingFeatureRow(
                    icon: "square.and.pencil",
                    title: NSLocalizedString("Quick Editing & Export", comment: "Onboarding feature 3 title"),
                    description: NSLocalizedString("Edit source with ⌘E, undo/redo changes, and export to HTML, PDF, or Word.", comment: "Onboarding feature 3 description")
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isTargeted ? Color.accentColor.opacity(0.85) : Color.secondary.opacity(0.18),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 44)
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
                hasCompletedOnboarding = true
                return handleDrop(providers: providers)
            }

            // Primary & Secondary Actions
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.20)) {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text(NSLocalizedString("Get Started", comment: "Onboarding get started button"))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor)
                        )
                        .foregroundColor(.white)
                        .contentShape(Rectangle())
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())

                Button(action: {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.20)) {
                        hasCompletedOnboarding = true
                    }
                    openFilePicker()
                }) {
                    Text(NSLocalizedString("Open Markdown File…", comment: "Onboarding open file button"))
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .foregroundColor(.primary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(OnboardingSecondaryButtonStyle())
            }
            .padding(.horizontal, 44)
            .padding(.top, 4)
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Button(action: openFilePicker) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(isTargeted ? Color.accentColor : Color.secondary)

                    Text(NSLocalizedString("Open Markdown File…", comment: "Open file button"))
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.primary)

                    Text(NSLocalizedString("or drop Markdown, PDF, Office, or CSV files here", comment: "Drop hint"))
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
                hasCompletedOnboarding = true
                return handleDrop(providers: providers)
            }
            .accessibilityHint(Text(NSLocalizedString("Drag & drop .md/.skill/.docx/.pdf/.xlsx/.pptx/.csv here", comment: "Drop hint")))

            Button(action: {
                DocumentImportController.shared.importAndConvertDocument()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath.doc")
                        .font(.system(size: 12, weight: .medium))
                    Text(NSLocalizedString("Convert Document to Markdown… (PDF, Office, CSV)", comment: "Convert document action button"))
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(ConvertDocumentButtonStyle())
            .disabled(isOpening)
        }
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

            Text(DisplayVersion.formattedDisplayVersion())
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

        hasCompletedOnboarding = true
        var remaining = urls.count

        let finishOne: (Error?) -> Void = { error in
            DispatchQueue.main.async {
                if let error {
                    openErrorMessage = error.localizedDescription
                }
                remaining -= 1
                if remaining <= 0 {
                    isOpening = false
                }
            }
        }

        for url in urls {
            if DocumentConverter.isSupported(url: url) {
                DocumentConverter.shared.convert(fileURL: url) { result in
                    switch result {
                    case .success(let markdown):
                        DocumentImportController.shared.openConvertedDraft(markdown: markdown, sourceURL: url)
                        finishOne(nil)
                    case .failure(let error):
                        finishOne(error)
                    }
                }
            } else {
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                    finishOne(error)
                }
            }
        }
    }

    private func closeIfAnyDocumentIsOpen() {
        guard window != nil else { return }
        if !NSDocumentController.shared.documents.isEmpty {
            hasCompletedOnboarding = true
            window?.close()
            window = nil
        }
    }
}

// MARK: - Welcome View Supporting Styles & Components

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : (isHovered ? 0.92 : 1.0))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

private struct OnboardingSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.08) : (isHovered ? Color.primary.opacity(0.05) : Color.primary.opacity(0.02)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isHovered ? Color.secondary.opacity(0.40) : Color.secondary.opacity(0.22), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

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

private struct ConvertDocumentButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isHovered ? .primary : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? Color.primary.opacity(0.08)
                            : (isHovered ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isHovered ? Color.secondary.opacity(0.35) : Color.secondary.opacity(0.14),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1.0)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.12), value: isHovered)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.08), value: configuration.isPressed)
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
