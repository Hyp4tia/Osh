/**
 * Integration tests: per-block RTL auto-detection in renderMarkdown.
 *
 * The renderer stamps `dir` on individual blocks (paragraphs, headings,
 * lists, tables) whose dominant script is Arabic/Hebrew, so mixed
 * documents keep LTR blocks untouched while RTL blocks render
 * right-to-left per the Unicode Bidirectional Algorithm.
 */
jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('per-block RTL auto-detection in renderMarkdown', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview" class="markdown-body"></div>';
    });

    test('marks Arabic paragraphs and headings as rtl', async () => {
        const arabicDoc = `# مرحبا بالعالم

هذا مستند مكتوب باللغة العربية ويحتوي على محتوى طويل بما يكفي للكشف.
`;
        await window.renderMarkdown(arabicDoc);

        const preview = document.getElementById('markdown-preview')!;
        expect(preview.querySelector('h1')!.getAttribute('dir')).toBe('rtl');
        expect(preview.querySelector('p')!.getAttribute('dir')).toBe('rtl');
    });

    test('keeps English blocks untouched inside a mixed document', async () => {
        const mixedDoc = `# Mixed document

This paragraph is entirely in English and should stay left-to-right.

هذه الفقرة مكتوبة باللغة العربية بالكامل ويجب أن تُعرض من اليمين إلى اليسار.

Another English paragraph closes the document with enough words to be detected properly.
`;
        await window.renderMarkdown(mixedDoc);

        const preview = document.getElementById('markdown-preview')!;
        const paragraphs = preview.querySelectorAll(':scope > p');
        expect(paragraphs.length).toBe(3);

        expect(preview.querySelector('h1')!.getAttribute('dir')).toBeNull();
        expect(paragraphs[0].getAttribute('dir')).toBeNull();
        expect(paragraphs[1].getAttribute('dir')).toBe('rtl');
        expect(paragraphs[2].getAttribute('dir')).toBeNull();

        // Container itself stays directionless; blocks decide individually.
        expect(preview.getAttribute('dir')).toBeNull();
    });

    test('RTL paragraph containing embedded LTR runs keeps one base direction', async () => {
        const doc = `هذه فقرة عربية تذكر \`inline_code\` و [رابط](https://example.com) و React داخل النص العربي الطويل بما يكفي.`;
        await window.renderMarkdown(doc);

        const p = document.querySelector('#markdown-preview p')!;
        // One paragraph, one base direction — the UBA orders the embedded
        // code/link/English runs within it.
        expect(p.getAttribute('dir')).toBe('rtl');
        expect(p.querySelectorAll('code, a').length).toBeGreaterThan(0);
    });

    test('mirrors list bullets/numbering for Arabic lists', async () => {
        const doc = `قائمة عربية:

1. العنصر الأول
2. العنصر الثاني
3. العنصر الثالث
`;
        await window.renderMarkdown(doc);

        const ol = document.querySelector('#markdown-preview ol')!;
        expect(ol.getAttribute('dir')).toBe('rtl');
    });

    test('mirrors table column order for Arabic tables', async () => {
        const doc = `| الاسم | العمر |
|-------|-------|
| أحمد  | ٣٠    |
| سارة  | ٢٥    |
`;
        await window.renderMarkdown(doc);

        const table = document.querySelector('#markdown-preview table')!;
        expect(table.getAttribute('dir')).toBe('rtl');
    });

    test('leaves English tables and lists untouched', async () => {
        const doc = `| Name | Age |
|------|-----|
| Alice | 30 |

- first item
- second item
`;
        await window.renderMarkdown(doc);

        const table = document.querySelector('#markdown-preview table')!;
        expect(table.getAttribute('dir')).toBeNull();

        const ul = document.querySelector('#markdown-preview ul')!;
        expect(ul.getAttribute('dir')).toBeNull();
    });

    test('code blocks never receive a dir attribute', async () => {
        const doc = '```js\nconst greeting = "مرحبا";\n```\n';
        await window.renderMarkdown(doc);

        const pre = document.querySelector('#markdown-preview pre')!;
        expect(pre.getAttribute('dir')).toBeNull();
    });

    test('clears block-level dir when re-rendering with LTR content', async () => {
        const arabicDoc = '# عنوان\n\nهذا نص عربي طويل بما يكفي للكشف عن الاتجاه.';
        await window.renderMarkdown(arabicDoc);
        expect(document.querySelector('#markdown-preview p')!.getAttribute('dir')).toBe('rtl');

        const englishDoc = '# Hello\n\nThis is English content now.';
        await window.renderMarkdown(englishDoc);

        const preview = document.getElementById('markdown-preview')!;
        expect(preview.querySelector('p')!.getAttribute('dir')).toBeNull();
        expect(preview.getAttribute('dir')).toBeNull();
    });

    test('renders English content correctly without RTL interference', async () => {
        const englishDoc = '# Test\n\nSome **bold** and *italic* text.';
        await window.renderMarkdown(englishDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.querySelector('h1')?.textContent).toBe('Test');
        expect(preview?.querySelector('strong')?.textContent).toBe('bold');
        expect(preview?.querySelector('h1')?.getAttribute('dir')).toBeNull();
    });
});
