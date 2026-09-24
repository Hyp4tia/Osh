import XCTest

final class RenderFastPathTests: XCTestCase {

    private let baseOptions = RendererOptions(
        enableMermaid: true,
        enableKatex: true,
        enableEmoji: true,
        enableTypst: true,
        codeHighlightTheme: "default"
    )

    private func signature(
        content: String = "# Hello",
        isPreviewMode: Bool = true,
        collapseBlockquotes: Bool = false,
        showLineNumbers: Bool = true,
        options: RendererOptions? = nil
    ) -> RenderSignature {
        RenderSignature(
            content: content,
            isPreviewMode: isPreviewMode,
            collapseBlockquotesByDefault: collapseBlockquotes,
            showLineNumbers: showLineNumbers,
            rendererOptions: options ?? baseOptions
        )
    }

    func testUnchangedRenderInputsTakeFastPath() {
        XCTAssertTrue(
            RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: signature())
        )
    }

    func testTogglingMermaidForcesFullRender() {
        let toggled = signature(options: RendererOptions(
            enableMermaid: false,
            enableKatex: true,
            enableEmoji: true,
            enableTypst: true,
            codeHighlightTheme: "default"
        ))
        XCTAssertFalse(RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: toggled))
    }

    func testTogglingKatexForcesFullRender() {
        let toggled = signature(options: RendererOptions(
            enableMermaid: true,
            enableKatex: false,
            enableEmoji: true,
            enableTypst: true,
            codeHighlightTheme: "default"
        ))
        XCTAssertFalse(RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: toggled))
    }

    func testTogglingEmojiForcesFullRender() {
        let toggled = signature(options: RendererOptions(
            enableMermaid: true,
            enableKatex: true,
            enableEmoji: false,
            enableTypst: true,
            codeHighlightTheme: "default"
        ))
        XCTAssertFalse(RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: toggled))
    }

    func testTogglingTypstForcesFullRender() {
        let toggled = signature(options: RendererOptions(
            enableMermaid: true,
            enableKatex: true,
            enableEmoji: true,
            enableTypst: false,
            codeHighlightTheme: "default"
        ))
        XCTAssertFalse(RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: toggled))
    }

    func testChangingCodeHighlightThemeForcesFullRender() {
        let toggled = signature(options: RendererOptions(
            enableMermaid: true,
            enableKatex: true,
            enableEmoji: true,
            enableTypst: true,
            codeHighlightTheme: "github-dark"
        ))
        XCTAssertFalse(RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: toggled))
    }

    func testContentChangeForcesFullRender() {
        XCTAssertFalse(
            RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: signature(content: "# Changed"))
        )
    }

    func testSourceViewModeForcesFullRender() {
        XCTAssertFalse(
            RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: signature(isPreviewMode: false))
        )
    }

    func testBlockquoteCollapseChangeForcesFullRender() {
        XCTAssertFalse(
            RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: signature(collapseBlockquotes: true))
        )
    }

    func testLineNumberChangeForcesFullRender() {
        XCTAssertFalse(
            RenderFastPath.isAppearanceOnlyChange(previous: signature(), current: signature(showLineNumbers: false))
        )
    }
}
