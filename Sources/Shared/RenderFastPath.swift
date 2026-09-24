import Foundation

/// Renderer feature toggles. Any change to these alters the rendered output, so they are part of the
/// render signature rather than being folded into the appearance fast path.
struct RendererOptions: Equatable {
    var enableMermaid: Bool
    var enableKatex: Bool
    var enableEmoji: Bool
    var enableTypst: Bool
    var codeHighlightTheme: String
}

/// Everything that decides what the rendered document looks like.
struct RenderSignature: Equatable {
    var content: String
    var isPreviewMode: Bool
    var collapseBlockquotesByDefault: Bool
    var showLineNumbers: Bool
    var rendererOptions: RendererOptions
}

/// Pure-logic helpers for the host app's render fast path.
/// Extracted here so they are testable without a live web view.
enum RenderFastPath {

    /// Returns `true` when the pending update can be applied by updating the theme or font size
    /// alone. A change to any renderer toggle, the content, the view mode, blockquote collapsing or
    /// line numbers requires a full re-render, otherwise the change is silently dropped.
    static func isAppearanceOnlyChange(previous: RenderSignature, current: RenderSignature) -> Bool {
        current.isPreviewMode
            && previous.isPreviewMode
            && previous.content == current.content
            && previous.collapseBlockquotesByDefault == current.collapseBlockquotesByDefault
            && previous.showLineNumbers == current.showLineNumbers
            && previous.rendererOptions == current.rendererOptions
    }
}
