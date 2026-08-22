/**
 * RTL (Right-to-Left) support.
 *
 * Two layers:
 *
 * 1. Document-level detection (`detectRtlContent`) — kept for backwards
 *    compatibility. Reports whether a whole document is predominantly RTL.
 *
 * 2. Block-level detection + application (`detectBlockDirection`,
 *    `applyBlockDirection`) — walks the rendered DOM and stamps `dir` on
 *    individual block elements (paragraphs, headings, list items, table
 *    cells, lists, tables) whose *dominant script* is Arabic/Hebrew, so a
 *    single Arabic paragraph inside an English document renders right-to-
 *    left without flipping the rest of the document.
 *
 * Embedded LTR content (inline code, English words, links) inside an RTL
 * block is handled by the Unicode Bidirectional Algorithm: setting the
 * `dir` attribute establishes the paragraph base direction and isolates
 * it; `styles/rtl.css` additionally isolates inline code runs so their
 * punctuation cannot leak into the surrounding RTL run.
 */

// Strong RTL letters only. Arabic-Indic digits (U+0660–0669, U+06F0–06F9)
// are excluded — they are weak (AN class) under the Unicode Bidi Algorithm
// and must never decide a block's base direction.
const RTL_CHAR_REGEX = /[\u0590-\u05FF\u0600-\u065F\u066A-\u06EF\u06FA-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/g;
const LTR_CHAR_REGEX = /[A-Za-z\u00C0-\u024F\u0370-\u03FF\u0400-\u04FF]/g;

const RTL_RATIO_THRESHOLD = 0.3;

export function detectRtlContent(text: string): boolean {
    if (!text || !text.trim()) return false;

    const totalLetters = text.replace(/\s/g, '').length;
    if (totalLetters === 0) return false;

    const rtlMatches = text.match(RTL_CHAR_REGEX);
    const rtlCount = rtlMatches ? rtlMatches.length : 0;

    return rtlCount / totalLetters > RTL_RATIO_THRESHOLD;
}

/** Direction of a single block of text based on its dominant script. */
export type BlockDirection = 'rtl' | 'ltr' | 'neutral';

/**
 * Returns the dominant direction of `text`.
 *
 * - Strong RTL characters: Arabic + Hebrew families (incl. supplements,
 *   extended Arabic and presentation forms).
 * - Strong LTR characters: Latin, Greek and Cyrillic letters.
 * - Digits, punctuation, whitespace and combining marks are neutrals and
 *   never influence the result (per UBA they resolve from context).
 * - A block is RTL only when strict RTL letters outnumber strong LTR ones.
 * - Blocks with no directional letters are `neutral` (inherit).
 */
export function detectBlockDirection(text: string): BlockDirection {
    if (!text) return 'neutral';

    const rtlCount = (text.match(RTL_CHAR_REGEX) || []).length;
    const ltrCount = (text.match(LTR_CHAR_REGEX) || []).length;

    if (rtlCount === 0 && ltrCount === 0) return 'neutral';
    return rtlCount > ltrCount ? 'rtl' : 'ltr';
}

/** Block-level elements that receive their own base direction. */
const BLOCK_SELECTOR = [
    'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'li', 'dd', 'dt', 'figcaption', 'summary', 'td', 'th',
].join(', ');

function isInCodeContext(el: Element): boolean {
    return el.closest('pre') !== null;
}

/**
 * Stamps `dir` on every block element under `root` whose dominant script
 * differs from neutral. Lists get one direction computed from all their
 * items so bullets/numbering mirror as a unit; tables get one direction
 * computed from all cells so column order mirrors as a unit.
 */
export function applyBlockDirection(root: HTMLElement): void {
    root.querySelectorAll(BLOCK_SELECTOR).forEach((el) => {
        if (isInCodeContext(el)) return;
        setBlockDirection(el as HTMLElement, detectBlockDirection(el.textContent || ''));
    });

    root.querySelectorAll('ul, ol').forEach((el) => {
        if (isInCodeContext(el)) return;
        // Combined item text decides the list's base direction so nested
        // content and the marker side stay consistent.
        const itemsText = Array.from(el.children)
            .map((li) => li.textContent || '')
            .join(' ');
        setBlockDirection(el as HTMLElement, detectBlockDirection(itemsText));
    });

    root.querySelectorAll('table').forEach((el) => {
        if (isInCodeContext(el)) return;
        setBlockDirection(el as HTMLElement, detectBlockDirection(el.textContent || ''));
    });
}

function setBlockDirection(el: HTMLElement, dir: BlockDirection): void {
    if (dir === 'rtl') {
        el.setAttribute('dir', 'rtl');
    } else {
        // Explicitly reset stale attributes from previous renders.
        el.removeAttribute('dir');
    }
}
