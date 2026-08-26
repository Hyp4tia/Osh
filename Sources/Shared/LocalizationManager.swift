import Foundation

/// Runtime-switchable localization for `NSLocalizedString`.
///
/// macOS normally resolves `NSLocalizedString` against the bundle's preferred
/// localization, picked once at launch from the system language list. To let
/// the in-app Settings picker change the UI language without restarting the
/// process, we swap `Bundle.main`'s class to a subclass that consults a
/// per-language sub-bundle stored in `SwizzleBundleStorage`.
///
/// Call `LocalizationManager.bootstrap(initialPreference:)` once at app launch
/// (before any UI is built), and `LocalizationManager.apply(languageCode:)`
/// whenever the user changes the language. Existing `NSLocalizedString(...)`
/// call sites continue to work unchanged.
public enum LocalizationManager {
    /// Maps the picker's preference value (e.g. `"de"`, `"zh"`, `"system"`) to
    /// the directory name of the matching `.lproj` resource.
    private static func lprojName(for preference: String) -> String? {
        switch preference {
        case "system": return nil          // fall back to OS resolution
        case "zh":     return "zh-Hans"    // picker value vs. bundle dir
        default:       return preference   // "en", "de", "fr", "ar", ...
        }
    }

    /// True when the active preference is an RTL language; drives SwiftUI
    /// layout mirroring in the host app.
    public static func isRTL(_ preference: String) -> Bool {
        if preference == "ar" || preference == "he" {
            return true
        }
        if preference == "system" {
            let current = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return current.hasPrefix("ar") || current.hasPrefix("he")
        }
        return false
    }

    /// Returns the appropriate GitHub Help document URL corresponding to the
    /// active UI language preference (or system language if set to "system").
    public static func helpURL(for preference: String) -> URL {
        let code: String
        if preference == "system" {
            let primary = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if primary.hasPrefix("fr") {
                code = "fr"
            } else if primary.hasPrefix("ar") {
                code = "ar"
            } else if primary.hasPrefix("de") {
                code = "de"
            } else if primary.hasPrefix("zh") {
                code = "zh"
            } else if primary.hasPrefix("es") {
                code = "es"
            } else {
                code = "en"
            }
        } else {
            code = preference.lowercased()
        }

        switch code {
        case "fr":
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP_FR.md")!
        case "ar":
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP_AR.md")!
        case "de":
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP_DE.md")!
        case "zh", "zh-hans", "zh-hant":
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP_ZH.md")!
        case "es":
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP_ES.md")!
        default:
            return URL(string: "https://github.com/Zeyadistired/Osh/blob/main/docs/user/HELP.md")!
        }
    }

    /// The preference that was active when `bootstrap` first ran. Used by the
    /// Settings UI to detect "needs restart for system menus" situations,
    /// because `AppleLanguages` is only honored at process start by AppKit,
    /// SwiftUI's `Settings` scene, and Sparkle.
    public private(set) static var launchPreference: String = "system"
    private static var didBootstrap = false

    /// Install the bundle subclass, persist `AppleLanguages` so AppKit /
    /// SwiftUI / Sparkle pick up the chosen language on this process run, and
    /// apply the initial preference to our own `NSLocalizedString` lookups.
    /// Safe to call multiple times — only the first call seeds the AppKit
    /// language and the launch preference.
    public static func bootstrap(initialPreference: String) {
        if !didBootstrap {
            didBootstrap = true
            launchPreference = initialPreference
            applyAppleLanguages(for: initialPreference)
        }
        object_setClass(Bundle.main, LocalizationBundle.self)
        apply(languageCode: initialPreference)
    }

    /// Pin AppleLanguages for this app's domain so AppKit / SwiftUI / Sparkle
    /// honor the picker on next launch. Pass `"system"` to clear the override
    /// and fall back to the OS-level setting.
    public static func applyAppleLanguages(for preference: String) {
        let key = "AppleLanguages"
        let defaults = UserDefaults.standard
        if let dir = lprojName(for: preference) {
            defaults.set([dir], forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    /// Activate the given preference value. Pass `"system"` to revert to the
    /// OS-resolved localization.
    public static func apply(languageCode preference: String) {
        guard let dir = lprojName(for: preference),
              let path = Bundle.main.path(forResource: dir, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            SwizzleBundleStorage.activeBundle = nil
            return
        }
        SwizzleBundleStorage.activeBundle = bundle
    }
}

/// Holds the currently-selected sub-bundle. Module-private so only
/// `LocalizationManager` mutates it.
fileprivate enum SwizzleBundleStorage {
    static var activeBundle: Bundle?
}

/// Subclass installed on `Bundle.main` so every `NSLocalizedString` lookup
/// is routed through `localizedString(forKey:value:table:)` here first.
private final class LocalizationBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let active = SwizzleBundleStorage.activeBundle {
            return active.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
