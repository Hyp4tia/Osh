import SwiftUI
import AppKit


// MARK: - Models

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance
    case rendering
    case editor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return NSLocalizedString("Appearance", comment: "Appearance settings tab")
        case .rendering: return NSLocalizedString("Rendering", comment: "Rendering settings tab")
        case .editor: return NSLocalizedString("Editor", comment: "Editor settings tab")
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .rendering: return "cpu"
        case .editor: return "textformat"
        }
    }
}

// MARK: - Main View

struct SettingsView: View {
    @ObservedObject private var preference = AppearancePreference.shared
    @State private var selectedTab: SettingsTab = .appearance

    private var isRTL: Bool {
        LocalizationManager.isRTL(preference.uiLanguage)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarRow(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(width: 175)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.45))

            Divider()

            // Content Detail Pane
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .appearance:
                        AppearanceSettingsView(preference: preference)
                    case .rendering:
                        RenderingSettingsView(preference: preference)
                    case .editor:
                        EditorSettingsView(preference: preference)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 480)
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        .preferredColorScheme(preference.currentMode == .dark ? .dark : preference.currentMode == .light ? .light : nil)
    }

    private func SidebarRow(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}

// MARK: - Appearance Tab

struct AppearanceSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(
                title: NSLocalizedString("Theme", comment: "Theme section title"),
                description: NSLocalizedString("Choose your preferred interface style", comment: "Theme section description")
            )

            HStack(spacing: 0) {
                ThemeOptionButton(mode: .light, icon: "sun.max",
                                  label: NSLocalizedString("Light", comment: "Light appearance mode"),
                                  current: preference.currentMode) {
                    preference.currentMode = .light
                }
                Divider()
                ThemeOptionButton(mode: .dark, icon: "moon.fill",
                                  label: NSLocalizedString("Dark", comment: "Dark appearance mode"),
                                  current: preference.currentMode) {
                    preference.currentMode = .dark
                }
                Divider()
                ThemeOptionButton(mode: .system, icon: "circle.lefthalf.filled",
                                  label: NSLocalizedString("System", comment: "System appearance mode"),
                                  current: preference.currentMode) {
                    preference.currentMode = .system
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )

            SettingsSectionHeader(
                title: NSLocalizedString("Language", comment: "Language section title"),
                description: NSLocalizedString("Interface language for the entire app", comment: "Language section description")
            )

            VStack(spacing: 0) {
                LanguageOptionRow(label: NSLocalizedString("System Default", comment: "Follow OS language"),
                                  value: "system", current: preference.uiLanguage) {
                    preference.uiLanguage = "system"
                }
                Divider().padding(.horizontal, 12)
                LanguageOptionRow(label: "English", value: "en", current: preference.uiLanguage) {
                    preference.uiLanguage = "en"
                }
                Divider().padding(.horizontal, 12)
                LanguageOptionRow(label: "Deutsch", value: "de", current: preference.uiLanguage) {
                    preference.uiLanguage = "de"
                }
                Divider().padding(.horizontal, 12)
                LanguageOptionRow(label: "Français", value: "fr", current: preference.uiLanguage) {
                    preference.uiLanguage = "fr"
                }
                Divider().padding(.horizontal, 12)
                LanguageOptionRow(label: "中文", value: "zh", current: preference.uiLanguage) {
                    preference.uiLanguage = "zh"
                }
                Divider().padding(.horizontal, 12)
                LanguageOptionRow(label: "العربية", value: "ar", current: preference.uiLanguage) {
                    preference.uiLanguage = "ar"
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )

            SettingsSectionHeader(
                title: NSLocalizedString("Reading Theme", comment: "Reading theme section title"),
                description: NSLocalizedString("Color palette for the rendered document", comment: "Reading theme section description")
            )

            HStack(spacing: 0) {
                readingThemeButton(preference, id: "default", label: NSLocalizedString("Default", comment: "Default reading theme"))
                Divider()
                readingThemeButton(preference, id: "sepia", label: NSLocalizedString("Sepia", comment: "Sepia reading theme"))
                Divider()
                readingThemeButton(preference, id: "paper", label: NSLocalizedString("Paper", comment: "Paper reading theme"))
                Divider()
                readingThemeButton(preference, id: "midnight", label: NSLocalizedString("Midnight", comment: "Midnight reading theme"))
                Divider()
                readingThemeButton(preference, id: "nord", label: NSLocalizedString("Nord", comment: "Nord reading theme"))
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )

            if preference.uiLanguage != LocalizationManager.launchPreference {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.accentColor)
                    Text(NSLocalizedString("Some menus update only after restarting the app.", comment: "Restart hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(NSLocalizedString("Restart Now", comment: "Restart now button")) {
                        relaunchApp()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func relaunchApp() {
        AppearancePreference.shared.flushSharedPreferences()
        UserDefaults.standard.synchronize()

        let bundleURL = Bundle.main.bundleURL
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", "-a", bundleURL.path]
        try? task.run()
        NSApp.terminate(nil)
    }

    private func LanguageOptionRow(label: String, value: String, current: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Spacer()
                if current == value {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func ThemeOptionButton(mode: AppearanceMode, icon: String, label: String, current: AppearanceMode, action: @escaping () -> Void) -> some View {
        let isSelected = current == mode
        return Button(action: action) {
            ZStack(alignment: .bottom) {
                if isSelected {
                    Color.accentColor.opacity(0.12)
                } else {
                    Color(NSColor.controlBackgroundColor)
                }
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                    Text(label)
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(isSelected ? .accentColor : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Rendering Tab

struct RenderingSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(
                title: NSLocalizedString("Features", comment: "Features section title"),
                description: NSLocalizedString("Enable or disable rendering capabilities", comment: "Features section description")
            )

            VStack(spacing: 0) {
                FeatureToggleRow(
                    title: NSLocalizedString("Mermaid Diagrams", comment: "Mermaid toggle title"),
                    subtitle: NSLocalizedString("Flowcharts, sequence diagrams, and more", comment: "Mermaid toggle subtitle"),
                    icon: "diagram",
                    isOn: Binding(get: { preference.enableMermaid }, set: { preference.enableMermaid = $0 })
                )
                Divider().padding(.horizontal, 12)
                FeatureToggleRow(
                    title: NSLocalizedString("KaTeX Math", comment: "KaTeX toggle title"),
                    subtitle: NSLocalizedString("Mathematical expressions and equations", comment: "KaTeX toggle subtitle"),
                    icon: "function",
                    isOn: Binding(get: { preference.enableKatex }, set: { preference.enableKatex = $0 })
                )
                Divider().padding(.horizontal, 12)
                FeatureToggleRow(
                    title: NSLocalizedString("Emoji Support", comment: "Emoji toggle title"),
                    subtitle: NSLocalizedString("GitHub flavored emoji codes like :smile:", comment: "Emoji toggle subtitle"),
                    icon: "face.smiling",
                    isOn: Binding(get: { preference.enableEmoji }, set: { preference.enableEmoji = $0 })
                )
                Divider().padding(.horizontal, 12)
                FeatureToggleRow(
                    title: NSLocalizedString("Typst Math", comment: "Typst toggle title"),
                    subtitle: NSLocalizedString("Typst math expressions in ```typst code blocks", comment: "Typst toggle subtitle"),
                    icon: "x.squareroot",
                    isOn: Binding(get: { preference.enableTypst }, set: { preference.enableTypst = $0 })
                )
                Divider().padding(.horizontal, 12)
                FeatureToggleRow(
                    title: NSLocalizedString("Collapse Blockquotes by Default", comment: "Blockquote collapse toggle title"),
                    subtitle: NSLocalizedString("Collapse blockquote sections when opening a document", comment: "Blockquote collapse toggle subtitle"),
                    icon: "text.quote",
                    isOn: Binding(get: { preference.collapseBlockquotesByDefault }, set: { preference.collapseBlockquotesByDefault = $0 })
                )
                Divider().padding(.horizontal, 12)
                FeatureToggleRow(
                    title: NSLocalizedString("Show Line Numbers", comment: "Line numbers toggle title"),
                    subtitle: NSLocalizedString("Display source line numbers in rendered preview and source view", comment: "Line numbers toggle subtitle"),
                    icon: "list.number",
                    isOn: Binding(get: { preference.showLineNumbers }, set: { preference.showLineNumbers = $0 })
                )
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func FeatureToggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 16)

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Editor Tab

struct EditorSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Font Size
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(
                    title: NSLocalizedString("Typography", comment: "Typography section title"),
                    description: NSLocalizedString("Adjust the reading experience", comment: "Typography section description")
                )

                VStack(spacing: 0) {
                    HStack {
                        Text(NSLocalizedString("Font Size", comment: "Font size label"))
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(preference.baseFontSize))px")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider()

                    HStack(spacing: 8) {
                        Text("A").font(.system(size: 11)).foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { preference.baseFontSize },
                                set: { preference.baseFontSize = $0 }
                            ),
                            in: 12...24,
                            step: 1
                        )
                        .accentColor(.accentColor)
                        Text("A").font(.system(size: 20)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
 
            // Finder Pane Font Size
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(
                    title: NSLocalizedString("Finder Preview Font Size", comment: "Finder pane font size section title"),
                    description: NSLocalizedString("Font size when previewing in Finder's column view", comment: "Finder pane font size section description")
                )

                VStack(spacing: 0) {
                    HStack {
                        Text(NSLocalizedString("Font Size", comment: "Font size label"))
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(preference.finderPaneFontSize))px")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider()

                    HStack(spacing: 8) {
                        Text("A").font(.system(size: 11)).foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { preference.finderPaneFontSize },
                                set: { preference.finderPaneFontSize = $0 }
                            ),
                            in: 10...24,
                            step: 1
                        )
                        .accentColor(.accentColor)
                        Text("A").font(.system(size: 20)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }

            // Code Theme
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(
                    title: NSLocalizedString("Code Highlighting", comment: "Code theme section title"),
                    description: NSLocalizedString("Syntax highlighting theme for code blocks", comment: "Code theme section description")
                )


                VStack(spacing: 0) {
                    CodeThemeRow(name: NSLocalizedString("Default", comment: "Default code theme"),
                                 id: "default", color: .primary)
                    Divider().padding(.horizontal, 12)
                    CodeThemeRow(name: "GitHub", id: "github", color: Color(red: 0.141, green: 0.161, blue: 0.243))
                    Divider().padding(.horizontal, 12)
                    CodeThemeRow(name: "Monokai", id: "monokai", color: Color(red: 0.153, green: 0.157, blue: 0.133))
                    Divider().padding(.horizontal, 12)
                    CodeThemeRow(name: "Atom One Dark", id: "atom-one-dark", color: Color(red: 0.157, green: 0.173, blue: 0.204))
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func CodeThemeRow(name: String, id: String, color: Color) -> some View {
        Button(action: { preference.codeHighlightTheme = id }) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color(NSColor.separatorColor), lineWidth: 0.5))

                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()

                if preference.codeHighlightTheme == id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shared Components

struct SettingsSectionHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension AppearanceSettingsView {
    fileprivate func readingThemeButton(_ preference: AppearancePreference, id: String, label: String) -> some View {
        Button(action: { preference.readingTheme = id }) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(ReadingThemePalette.swatch(for: id))
                    .frame(width: 34, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(preference.readingTheme == id ? .accentColor : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReadingThemePalette {
    static func swatch(for id: String) -> Color {
        switch id {
        case "sepia": return Color(red: 0.957, green: 0.925, blue: 0.847)
        case "paper": return Color(red: 0.992, green: 0.992, blue: 0.984)
        case "midnight": return Color(red: 0.0, green: 0.0, blue: 0.0)
        case "nord": return Color(red: 0.180, green: 0.204, blue: 0.251)
        default: return Color(red: 0.98, green: 0.98, blue: 0.98)
        }
    }
}
