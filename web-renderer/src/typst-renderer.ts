/**
 * Typst math rendering module.
 *
 * Two-tier architecture:
 * - QuickLook/Finder: transpile Typst→LaTeX via tex2typst, render with KaTeX
 * - Host App: compile Typst→SVG via typst.ts WASM (lazy-loaded)
 */

import { typst2tex } from 'tex2typst';

// --- Transpilation path (QuickLook) ---

export function transpileTypstToLatex(typstCode: string): string {
    return typst2tex(typstCode, { blockMathMode: true });
}

/**
 * Render a Typst math block using transpilation → KaTeX.
 * Used in QuickLook/Finder context where bundle size matters.
 */
export async function renderTypstViaTranspilation(
    typstCode: string
): Promise<string> {
    // @ts-ignore — katex has no bundled type declarations
    const katexModule = await import('katex');
    const katex = (katexModule as any).default ?? katexModule;
    const latex = transpileTypstToLatex(typstCode);
    return katex.renderToString(latex, {
        displayMode: true,
        throwOnError: false,
        output: 'htmlAndMathml',
    });
}

// --- Native WASM path (Host App) ---

let typstInitPromise: Promise<any> | null = null;

async function getTypstInstance(): Promise<any> {
    if (!typstInitPromise) {
        typstInitPromise = (async () => {
            const { $typst } = await import(
                '@myriaddreamin/typst.ts/dist/esm/contrib/snippet.mjs'
            );
            // Vite resolves these URLs at build time; use eval to bypass ts-jest's es6 parser
            const meta = new Function('return import.meta')() as { url: string };
            const compilerWasmUrl = new URL(
                '@myriaddreamin/typst-ts-web-compiler/pkg/typst_ts_web_compiler_bg.wasm',
                meta.url
            ).href;
            const rendererWasmUrl = new URL(
                '@myriaddreamin/typst-ts-renderer/pkg/typst_ts_renderer_bg.wasm',
                meta.url
            ).href;
            $typst.setCompilerInitOptions({ getModule: () => compilerWasmUrl });
            $typst.setRendererInitOptions({ getModule: () => rendererWasmUrl });
            return $typst;
        })();
    }
    return typstInitPromise;
}

/**
 * Render a Typst math block natively to SVG via WASM.
 * Used in Host App context where full fidelity is desired.
 */
export async function renderTypstViaNative(
    typstCode: string
): Promise<string> {
    const $typst = await getTypstInstance();
    const mainContent = `#set page(width: auto, height: auto, margin: 0pt)\n$ ${typstCode} $`;
    const svg = await $typst.svg({ mainContent });
    return `<div class="typst-math-block typst-native">${svg}</div>`;
}

// --- Public API ---

/**
 * Render a Typst math block. Strategy depends on context:
 * - context === "app" → native WASM (high fidelity)
 * - otherwise → transpilation to KaTeX (lightweight)
 *
 * Falls back to transpilation if WASM fails.
 */
export async function renderTypstBlock(
    typstCode: string,
    context: string
): Promise<string> {
    if (context === 'app') {
        try {
            return await renderTypstViaNative(typstCode);
        } catch (err) {
            // Fallback to transpilation if WASM fails to load
            console.warn('Typst WASM failed, falling back to transpilation:', err);
        }
    }
    try {
        const html = await renderTypstViaTranspilation(typstCode);
        return `<div class="typst-math-block typst-transpiled">${html}</div>`;
    } catch (err) {
        return `<div class="typst-math-block typst-error">
            <div class="typst-error-title">⚠️ Typst Render Error</div>
            <pre class="typst-error-source">${typstCode}</pre>
            <pre class="typst-error-message">${String(err)}</pre>
        </div>`;
    }
}
