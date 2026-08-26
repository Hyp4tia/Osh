import SwiftUI
import AppKit

/// Full-surface source editor shown when the user toggles edit mode.
///
/// Uses NSTextView via NSViewRepresentable instead of SwiftUI's TextEditor so
/// the text system's native bidi handling applies: Arabic and Hebrew paragraphs
/// get correct direction from their first strong character without extra work.
struct SourceEditorView: NSViewRepresentable {
    @Binding var text: String
    var appearanceMode: AppearanceMode
    var onSave: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSave: onSave)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = EditorTextView()
        let coordinator = context.coordinator
        textView.delegate = coordinator
        textView.onSave = { coordinator.onSave() }
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        // Smart punctuation silently replaces quotes/dashes and corrupts Markdown.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        textView.string = coordinator.text.wrappedValue
        textView.alignment = .natural
        textView.baseWritingDirection = LocalizationManager.isRTL(AppearancePreference.shared.uiLanguage) ? .rightToLeft : .natural
        textView.appearance = appearanceMode.nsAppearance
        scrollView.appearance = appearanceMode.nsAppearance

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onSave = onSave
        scrollView.appearance = appearanceMode.nsAppearance
        guard let textView = scrollView.documentView as? EditorTextView else { return }
        textView.appearance = appearanceMode.nsAppearance
        textView.baseWritingDirection = LocalizationManager.isRTL(AppearancePreference.shared.uiLanguage) ? .rightToLeft : .natural
        let current = context.coordinator.text.wrappedValue
        // Only replace content when it changed outside the editor (e.g. new
        // document opened). Never stomp in-flight typing.
        if textView.string != current && scrollView.window?.firstResponder !== textView {
            textView.string = current
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onSave: () -> Void

        init(text: Binding<String>, onSave: @escaping () -> Void) {
            self.text = text
            self.onSave = onSave
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

/// Text view that routes Cmd+S to the editing session instead of beeping.
final class EditorTextView: NSTextView {
    var onSave: (() -> Void)?

    override func doCommand(by selector: Selector) {
        if selector == #selector(save(_:)) {
            onSave?()
            return
        }
        super.doCommand(by: selector)
    }

    @objc func save(_ sender: Any?) {}
}
