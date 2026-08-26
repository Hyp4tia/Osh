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
    var onSave: (() -> Void)?

    init(text: Binding<String>, appearanceMode: AppearanceMode, onSave: (() -> Void)? = nil) {
        self._text = text
        self.appearanceMode = appearanceMode
        self.onSave = onSave
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = EditorTextView()
        let coordinator = context.coordinator
        textView.delegate = coordinator
        textView.onSave = { [weak coordinator] in
            if let customSave = coordinator?.parent.onSave {
                customSave()
            } else {
                NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
            }
        }
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

        textView.string = text
        textView.alignment = .natural
        textView.baseWritingDirection = LocalizationManager.isRTL(AppearancePreference.shared.uiLanguage) ? .rightToLeft : .natural
        textView.appearance = appearanceMode.nsAppearance
        scrollView.appearance = appearanceMode.nsAppearance

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        scrollView.appearance = appearanceMode.nsAppearance
        guard let textView = scrollView.documentView as? EditorTextView else { return }
        textView.appearance = appearanceMode.nsAppearance
        textView.baseWritingDirection = LocalizationManager.isRTL(AppearancePreference.shared.uiLanguage) ? .rightToLeft : .natural

        // Only update text from binding if changed externally (never stomp active user edits)
        if !context.coordinator.isUpdatingFromTextView && textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceEditorView
        var isUpdatingFromTextView = false

        init(_ parent: SourceEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true
            if parent.text != textView.string {
                parent.text = textView.string
            }
            isUpdatingFromTextView = false
        }
    }
}

/// Text view that routes Cmd+S to the document save action instead of beeping.
final class EditorTextView: NSTextView {
    var onSave: (() -> Void)?

    override func doCommand(by selector: Selector) {
        if selector == #selector(save(_:)) {
            onSave?()
            return
        }
        super.doCommand(by: selector)
    }

    @objc func save(_ sender: Any?) {
        onSave?()
    }
}
