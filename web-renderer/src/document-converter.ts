/**
 * Document conversion module powered by Firecrawl AnyDoc (WASM).
 * Converts binary documents (.docx, .pdf, .xlsx, .pptx, .csv) to GitHub-Flavored Markdown.
 */

// @ts-ignore - Vite asset import for WASM module
import wasmUrl from '@firecrawl/anydoc-wasm/anydoc_wasm_bg.wasm?url';

export type ConversionErrorCode =
    | 'needsOcr'
    | 'unsupported'
    | 'malformed'
    | 'encrypted'
    | 'resourceLimit'
    | 'missingPart'
    | 'generic';

export interface ConversionResult {
    success: boolean;
    markdown?: string;
    detectedFormat?: string;
    error?: string;
    errorCode?: ConversionErrorCode;
    pages?: number[];
    pageCount?: number;
}

interface AssetInfo {
    mediaType: string;
    dataUri: string;
}

let anydocInitPromise: Promise<any> | null = null;

/**
 * Lazily loads and initializes the AnyDoc WebAssembly module.
 */
export async function getAnyDocInstance(): Promise<any> {
    if (!anydocInitPromise) {
        anydocInitPromise = (async () => {
            const rawModule = await import('@firecrawl/anydoc-wasm');
            const anydocModule = (rawModule as any).default?.formatFromBytes ? (rawModule as any).default : rawModule;

            const initFn = (rawModule as any).default || (rawModule as any).init;
            if (typeof initFn === 'function') {
                if (typeof wasmUrl === 'string' && wasmUrl.length > 0) {
                    await initFn({ module_or_path: wasmUrl });
                } else {
                    try {
                        await initFn();
                    } catch {
                        // Already initialized
                    }
                }
            }
            return anydocModule;
        })();
    }
    return anydocInitPromise;
}

/**
 * Cleans alt text by removing directory paths (e.g. '/home/claude/auc.png' -> 'auc.png').
 */
function cleanAltText(rawAlt?: string): string {
    if (!rawAlt) return 'image';
    const basename = rawAlt.split(/[/\\]/).pop();
    return basename || rawAlt;
}

/**
 * Encodes Uint8Array or byte dictionary to Base64 in browser and Node environments.
 */
function uint8ArrayToBase64(bytes: Uint8Array | Record<string, number>): string {
    let uint8: Uint8Array;
    if (bytes instanceof Uint8Array) {
        uint8 = bytes;
    } else if (typeof bytes === 'object' && bytes !== null) {
        uint8 = new Uint8Array(Object.values(bytes));
    } else {
        return '';
    }

    if (typeof btoa === 'function') {
        let binary = '';
        const len = uint8.byteLength;
        for (let i = 0; i < len; i++) {
            binary += String.fromCharCode(uint8[i]);
        }
        return btoa(binary);
    } else if (typeof Buffer !== 'undefined') {
        return Buffer.from(uint8).toString('base64');
    }
    return '';
}

function inlineContentToMarkdown(inlines: any[], assetsMap: Map<number, AssetInfo>): string {
    if (!Array.isArray(inlines)) return '';
    let out = '';
    for (const item of inlines) {
        if (!item) continue;
        if (item.kind === 'text') {
            let text = item.text || '';
            if (item.style?.code) text = '`' + text + '`';
            if (item.style?.bold) text = '**' + text + '**';
            if (item.style?.italic) text = '*' + text + '*';
            if (item.style?.strike) text = '~~' + text + '~~';
            out += text;
        } else if (item.kind === 'link') {
            const linkText = inlineContentToMarkdown(item.content, assetsMap);
            const targetUrl = item.target?.value || item.url || '';
            out += `[${linkText}](${targetUrl})`;
        } else if (item.kind === 'image') {
            const alt = cleanAltText(item.alt);
            let src = '';
            if (item.source?.kind === 'asset' && assetsMap) {
                const asset = assetsMap.get(item.source.assetId);
                if (asset) {
                    src = asset.dataUri;
                }
            } else if (item.source?.kind === 'url') {
                src = item.source.url;
            }
            if (src) {
                out += `![${alt}](${src})`;
            } else {
                out += `![${alt}](${cleanAltText(item.alt)})`;
            }
        }
    }
    return out;
}

function tableToMarkdown(tableObj: any, assetsMap: Map<number, AssetInfo>): string {
    if (!tableObj || !Array.isArray(tableObj.grid) || tableObj.grid.length === 0) return '';
    const grid: any[][] = tableObj.grid;
    let out = '';

    const formatRow = (row: any[]) => {
        const cells = row.map(cellWrapper => {
            const cell = cellWrapper?.cell;
            if (!cell || !Array.isArray(cell.blocks)) return '';
            return cell.blocks.map((b: any) => blockToMarkdown(b, assetsMap).trim()).join(' ');
        });
        return '| ' + cells.join(' | ') + ' |';
    };

    const firstRow = grid[0];
    out += formatRow(firstRow) + '\n';
    out += '| ' + firstRow.map(() => '---').join(' | ') + ' |\n';

    for (let r = 1; r < grid.length; r++) {
        out += formatRow(grid[r]) + '\n';
    }
    return out;
}

function blockToMarkdown(block: any, assetsMap: Map<number, AssetInfo>, isPptx = false): string {
    if (!block) return '';
    switch (block.kind) {
        case 'heading': {
            const hashes = '#'.repeat(Math.min(Math.max(block.level || 2, 1), 6));
            const headingText = inlineContentToMarkdown(block.content, assetsMap).trim();
            return `${hashes} ${headingText}\n\n`;
        }
        case 'paragraph': {
            const text = inlineContentToMarkdown(block.content, assetsMap).trim();
            return text ? `${text}\n\n` : '';
        }
        case 'blockQuote': {
            const inner = (block.blocks || []).map((b: any) => blockToMarkdown(b, assetsMap, isPptx)).join('').trim();
            const quoted = inner.split('\n').map((line: string) => `> ${line}`).join('\n');
            return `${quoted}\n\n`;
        }
        case 'codeBlock': {
            const lang = block.lang || '';
            const code = block.text || '';
            return `\`\`\`${lang}\n${code}\n\`\`\`\n\n`;
        }
        case 'table': {
            return tableToMarkdown(block.table, assetsMap) + '\n';
        }
        default:
            return '';
    }
}

/**
 * Converts AnyDoc AST document into faithful, clean Markdown with embedded assets.
 */
function astDocumentToMarkdown(doc: any, format?: string): string {
    const assetsMap = new Map<number, AssetInfo>();
    if (Array.isArray(doc.assets)) {
        for (const asset of doc.assets) {
            if (asset && asset.id !== undefined && asset.data) {
                const base64 = uint8ArrayToBase64(asset.data);
                if (base64) {
                    const mediaType = asset.mediaType || 'image/png';
                    assetsMap.set(asset.id, {
                        mediaType,
                        dataUri: `data:${mediaType};base64,${base64}`
                    });
                }
            }
        }
    }

    let md = '';
    const isPptx = format === 'pptx';
    let slideHeadingCount = 0;

    if (Array.isArray(doc.blocks)) {
        for (const block of doc.blocks) {
            if (isPptx && block.kind === 'heading') {
                slideHeadingCount++;
                if (slideHeadingCount > 1) {
                    md += '---\n\n';
                }
            }
            md += blockToMarkdown(block, assetsMap, isPptx);
        }
    }

    if (Array.isArray(doc.notes) && doc.notes.length > 0) {
        md += '\n---\n\n### Notes\n\n';
        for (const note of doc.notes) {
            if (typeof note === 'string' && note.trim()) {
                md += `> ${note.trim()}\n\n`;
            }
        }
    }

    return md.trim() + '\n';
}

/**
 * Converts document bytes to GitHub-Flavored Markdown.
 *
 * @param bytes - Uint8Array containing raw file bytes.
 * @param formatHint - Optional format extension hint (e.g. 'docx', 'pdf', 'xlsx', 'pptx', 'csv').
 */
export async function convertDocumentToMarkdown(
    bytes: Uint8Array,
    formatHint?: string
): Promise<ConversionResult> {
    try {
        if (!bytes || bytes.length === 0) {
            return {
                success: false,
                error: 'The provided document file is empty.',
                errorCode: 'malformed',
            };
        }

        const anydoc = await getAnyDocInstance();
        
        let detectedFormat: string | undefined;
        if (typeof anydoc.formatFromBytes === 'function') {
            detectedFormat = anydoc.formatFromBytes(bytes);
        }
        if (!detectedFormat && formatHint) {
            const cleanHint = formatHint.toLowerCase().replace(/^\./, '');
            if (typeof anydoc.formatFromExtension === 'function') {
                detectedFormat = anydoc.formatFromExtension(cleanHint) || cleanHint;
            } else {
                detectedFormat = cleanHint;
            }
        }

        let markdown: string | undefined;

        // Try rich AST conversion first (preserves assets, images, and slide structures)
        if (detectedFormat !== 'pdf' && typeof anydoc.toDocument === 'function') {
            try {
                const doc = anydoc.toDocument(bytes, (detectedFormat as any) || null);
                if (doc && (Array.isArray(doc.blocks) || Array.isArray(doc.assets))) {
                    markdown = astDocumentToMarkdown(doc, detectedFormat);
                }
            } catch {
                // Fallback to toMarkdownBytes if AST generation is not available for this format
            }
        }

        // Direct Markdown serializer fallback (or primary for PDF)
        if (!markdown && typeof anydoc.toMarkdownBytes === 'function') {
            markdown = anydoc.toMarkdownBytes(
                bytes,
                (detectedFormat as any) || null
            );
        }

        if (typeof markdown !== 'string') {
            return {
                success: false,
                error: 'Conversion failed to produce markdown output.',
                errorCode: 'generic',
            };
        }

        return {
            success: true,
            markdown,
            detectedFormat,
        };
    } catch (err: any) {
        const code: ConversionErrorCode = err?.code || 'generic';
        let errorMessage = err?.message || 'Document conversion failed.';

        if (code === 'needsOcr') {
            const pageList = Array.isArray(err?.pages) && err.pages.length > 0
                ? ` (pages ${err.pages.join(', ')})`
                : '';
            errorMessage = `This PDF contains scanned or image-only pages that require OCR${pageList}. Osh only converts text-based documents offline.`;
        } else if (code === 'encrypted') {
            errorMessage = 'This document is encrypted or password-protected and cannot be converted.';
        } else if (code === 'unsupported') {
            errorMessage = 'The file format is not supported for document conversion.';
        } else if (code === 'malformed') {
            errorMessage = 'The document is corrupted or malformed and cannot be parsed.';
        } else if (code === 'resourceLimit') {
            errorMessage = 'The document exceeded safe size, decompression, or nesting limits.';
        } else if (code === 'missingPart') {
            errorMessage = 'A required part of the document package is missing.';
        }

        return {
            success: false,
            error: errorMessage,
            errorCode: code,
            pages: err?.pages,
            pageCount: err?.pageCount,
        };
    }
}

/**
 * Detects the document format from binary bytes.
 */
export async function detectDocumentFormat(
    bytes: Uint8Array
): Promise<string | undefined> {
    try {
        const anydoc = await getAnyDocInstance();
        return anydoc.formatFromBytes(bytes);
    } catch {
        return undefined;
    }
}
