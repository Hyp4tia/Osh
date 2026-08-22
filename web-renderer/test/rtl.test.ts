/**
 * RTL (Right-to-Left) detection tests.
 *
 * Covers two layers:
 *
 * 1. `detectRtlContent` — document-level heuristic (kept for backwards
 *    compatibility). Reports whether a whole document contains enough RTL
 *    characters (>30%) to be considered RTL overall.
 *
 * 2. `detectBlockDirection` / `applyBlockDirection` — per-block dominant-
 *    script detection. A paragraph, heading, list or table whose Arabic/
 *    Hebrew letters outnumber Latin/Greek/Cyrillic ones renders
 *    right-to-left; everything else stays left-to-right.
 *
 * Unicode ranges covered:
 *   - Hebrew:               U+0590–U+05FF
 *   - Arabic:               U+0600–U+06FF
 *   - Arabic Supplement:    U+0750–U+077F
 *   - Arabic Extended-A:    U+08A0–U+08FF
 *   - Arabic Presentation:  U+FB50–U+FDFF, U+FE70–U+FEFF
 */
import {
    detectRtlContent,
    detectBlockDirection,
    applyBlockDirection,
} from '../src/rtl';

describe('detectRtlContent', () => {
    // ── Arabic ────────────────────────────────────────────────────────────────
    describe('Arabic text', () => {
        test('returns true for a fully Arabic string', () => {
            // "Hello" in Arabic
            expect(detectRtlContent('مرحبا بالعالم')).toBe(true);
        });

        test('returns true for a paragraph of Arabic prose', () => {
            const arabic = 'هذا نص عربي طويل يحتوي على كلمات وجمل متعددة لاختبار الكشف عن اتجاه النص';
            expect(detectRtlContent(arabic)).toBe(true);
        });

        test('returns true when Arabic chars are >30% of total text', () => {
            // ~50% Arabic, ~50% English
            const mixed = 'Hello مرحبا world كيف حالك';
            expect(detectRtlContent(mixed)).toBe(true);
        });
    });

    // ── Hebrew ────────────────────────────────────────────────────────────────
    describe('Hebrew text', () => {
        test('returns true for a fully Hebrew string', () => {
            // "Hello World" in Hebrew
            expect(detectRtlContent('שלום עולם')).toBe(true);
        });

        test('returns true when Hebrew chars are >30% of total text', () => {
            const mixed = 'Hello שלום world עולם';
            expect(detectRtlContent(mixed)).toBe(true);
        });
    });

    // ── LTR / No RTL ─────────────────────────────────────────────────────────
    describe('left-to-right text', () => {
        test('returns false for purely English text', () => {
            expect(detectRtlContent('Hello, World!')).toBe(false);
        });

        test('returns false for Chinese/CJK text', () => {
            expect(detectRtlContent('你好世界，这是中文文本。')).toBe(false);
        });

        test('returns false for Japanese text', () => {
            expect(detectRtlContent('こんにちは世界')).toBe(false);
        });

        test('returns false for Korean text', () => {
            expect(detectRtlContent('안녕하세요 세계')).toBe(false);
        });

        test('returns false for an empty string', () => {
            expect(detectRtlContent('')).toBe(false);
        });

        test('returns false for whitespace-only string', () => {
            expect(detectRtlContent('   \t\n  ')).toBe(false);
        });

        test('returns false for a string with only numbers and punctuation', () => {
            expect(detectRtlContent('1234567890 !@#$%^&*()')).toBe(false);
        });
    });

    // ── Threshold boundary ────────────────────────────────────────────────────
    describe('RTL ratio threshold (30%)', () => {
        test('returns false when RTL chars are well below 30%', () => {
            // 1 Arabic char in a long English sentence (~2% RTL)
            const text = 'This is a very long English sentence with just one Arabic letter م at the end';
            expect(detectRtlContent(text)).toBe(false);
        });

        test('returns true when RTL chars are clearly above 30%', () => {
            // Roughly half Arabic, half English letters
            const text = 'abc مرحبا def عالم';
            expect(detectRtlContent(text)).toBe(true);
        });
    });
});

describe('detectBlockDirection (dominant script per block)', () => {
    test('rtl for a purely Arabic paragraph', () => {
        expect(detectBlockDirection('هذا نص عربي قصير')).toBe('rtl');
    });

    test('rtl for a Hebrew paragraph', () => {
        expect(detectBlockDirection('זהו משפט בעברית')).toBe('rtl');
    });

    test('rtl when Arabic slightly outweighs embedded English words', () => {
        const text = 'هذه فقرة عربية تتحدث عن React و TypeScript بشكل عام مع تفاصيل كثيرة إضافية';
        expect(detectBlockDirection(text)).toBe('rtl');
    });

    test('ltr when English dominates despite some Arabic words', () => {
        const text = 'This English paragraph mentions السلام عليكم once but keeps flowing in English throughout.';
        expect(detectBlockDirection(text)).toBe('ltr');
    });

    test('neutral for numbers and punctuation only', () => {
        expect(detectBlockDirection('123 + 456 = 789!')).toBe('neutral');
    });

    test('neutral for empty and whitespace-only text', () => {
        expect(detectBlockDirection('')).toBe('neutral');
        expect(detectBlockDirection('   ')).toBe('neutral');
    });

    test('neutral for CJK text (no strong direction)', () => {
        expect(detectBlockDirection('这是没有强方向性的文本。')).toBe('neutral');
    });

    test('Arabic digits are neutrals, not strong RTL', () => {
        // Eastern Arabic numerals ١٢٣ are AN (Arabic number) class — the
        // surrounding letters decide direction.
        expect(detectBlockDirection('في عام ٢٠٢٤ حدث شيء')).toBe('rtl');
        expect(detectBlockDirection('٢٠٢٤')).toBe('neutral');
    });
});

describe('applyBlockDirection (DOM stamping)', () => {
    let root: HTMLElement;

    beforeEach(() => {
        document.body.innerHTML = '<div id="root"></div>';
        root = document.getElementById('root')!;
    });

    test('stamps dir="rtl" on an Arabic paragraph only', () => {
        root.innerHTML = '<p>هذا نص عربي</p><p>English paragraph here</p>';
        applyBlockDirection(root);

        const [arabic, english] = root.querySelectorAll('p');
        expect(arabic.getAttribute('dir')).toBe('rtl');
        expect(english.getAttribute('dir')).toBeNull();
    });

    test('stamps headings, list items and table cells independently', () => {
        root.innerHTML = `
            <h1>عنوان عربي</h1>
            <ul><li>بند أول</li><li>بند ثانٍ بالإنجليزية English</li></ul>
            <table><tr><td>خلية</td></tr></table>
            <pre><code>const x = 1;</code></pre>
        `;
        applyBlockDirection(root);

        expect(root.querySelector('h1')!.getAttribute('dir')).toBe('rtl');
        // The list as a unit is RTL-dominant (Arabic outweighs the one
        // embedded English word).
        expect(root.querySelector('ul')!.getAttribute('dir')).toBe('rtl');
        expect(root.querySelector('td')!.getAttribute('dir')).toBe('rtl');
        // Code blocks are never touched.
        expect(root.querySelector('pre')!.getAttribute('dir')).toBeNull();
        expect(root.querySelector('code')!.getAttribute('dir')).toBeNull();
    });

    test('mirrors list bullets/numbering via dir on the list element', () => {
        root.innerHTML = '<ol><li>أولاً</li><li>ثانياً</li><li>ثالثاً</li></ol>';
        applyBlockDirection(root);

        const ol = root.querySelector('ol')!;
        expect(ol.getAttribute('dir')).toBe('rtl');
    });

    test('leaves LTR lists untouched', () => {
        root.innerHTML = '<ol><li>first</li><li>second</li></ol>';
        applyBlockDirection(root);

        expect(root.querySelector('ol')!.getAttribute('dir')).toBeNull();
    });

    test('mirrors table column order via dir on the table element', () => {
        root.innerHTML = `
            <table>
                <thead><tr><th>الاسم</th><th>العمر</th></tr></thead>
                <tbody><tr><td>أحمد</td><td>٣٠</td></tr></tbody>
            </table>
        `;
        applyBlockDirection(root);

        expect(root.querySelector('table')!.getAttribute('dir')).toBe('rtl');
    });

    test('an English table stays untouched', () => {
        root.innerHTML = `
            <table>
                <thead><tr><th>Name</th><th>Age</th></tr></thead>
                <tbody><tr><td>Alice</td><td>30</td></tr></tbody>
            </table>
        `;
        applyBlockDirection(root);

        expect(root.querySelector('table')!.getAttribute('dir')).toBeNull();
    });

    test('clears stale dir attributes on re-application (re-render)', () => {
        root.innerHTML = '<p dir="rtl">Now English content instead</p>';
        applyBlockDirection(root);

        expect(root.querySelector('p')!.getAttribute('dir')).toBeNull();
    });
});
