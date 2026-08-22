/**
 * @jest-environment jsdom
 */

import { transpileTypstToLatex } from '../src/typst-renderer';
import MarkdownIt from 'markdown-it';

describe('Typst transpilation (QuickLook path)', () => {
    test('transpiles basic fraction', () => {
        const result = transpileTypstToLatex('a/b');
        expect(result).toContain('\\frac');
    });

    test('transpiles sum notation', () => {
        const result = transpileTypstToLatex('sum_(i=1)^n i');
        expect(result).toContain('\\sum');
    });

    test('transpiles Greek letters', () => {
        const result = transpileTypstToLatex('alpha + beta');
        expect(result).toContain('\\alpha');
        expect(result).toContain('\\beta');
    });

    test('transpiles sqrt', () => {
        const result = transpileTypstToLatex('sqrt(x)');
        expect(result).toContain('\\sqrt');
    });

    test('handles empty input gracefully', () => {
        expect(() => transpileTypstToLatex('')).not.toThrow();
    });
});

describe('Typst fence detection in markdown-it', () => {
    function createMdWithTypstHighlight(): MarkdownIt {
        return new MarkdownIt({
            highlight: function (str: string, lang: string): string {
                if (lang === 'typst' || lang === 'typst-math') {
                    return '<div class="typst-placeholder" data-typst-source="' +
                        str.replace(/"/g, '&quot;').replace(/\n/g, '&#10;') +
                        '"><div class="typst-loading">Rendering Typst…</div></div>';
                }
                return '';
            }
        });
    }

    test('typst code block produces placeholder div', () => {
        const md = createMdWithTypstHighlight();
        const input = '```typst\nsum_(i=1)^n i = (n(n+1))/2\n```';
        const html = md.render(input);
        expect(html).toContain('typst-placeholder');
        expect(html).toContain('data-typst-source');
        expect(html).toContain('sum_(i=1)^n');
    });

    test('typst-math alias also works', () => {
        const md = createMdWithTypstHighlight();
        const input = '```typst-math\nalpha + beta\n```';
        const html = md.render(input);
        expect(html).toContain('typst-placeholder');
    });

    test('regular code blocks are not affected', () => {
        const md = createMdWithTypstHighlight();
        const input = '```javascript\nconsole.log("hello")\n```';
        const html = md.render(input);
        expect(html).not.toContain('typst-placeholder');
    });

    test('source is properly encoded in data attribute', () => {
        const md = createMdWithTypstHighlight();
        const input = '```typst\n"quoted" text\n```';
        const html = md.render(input);
        expect(html).toContain('&quot;quoted&quot;');
    });

    test('multiline typst source preserves newlines', () => {
        const md = createMdWithTypstHighlight();
        const input = '```typst\nline1\nline2\n```';
        const html = md.render(input);
        expect(html).toContain('&#10;');
    });
});
