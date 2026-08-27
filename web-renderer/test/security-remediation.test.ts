/**
 * @jest-environment jsdom
 */

import '../src/index';
import { renderTypstBlock } from '../src/typst-renderer';

describe('Web Renderer Security Hardening Tests', () => {
    let preview: HTMLElement;

    beforeEach(() => {
        document.body.innerHTML = `
            <div id="loading-status"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
            <div id="collapse-btn-container"></div>
            <div id="markdown-preview" class="markdown-body"></div>
            <div id="link-status-bar" aria-hidden="true"></div>
        `;
        preview = document.getElementById('markdown-preview')!;
    });

    describe('DOMPurify XSS Sanitization', () => {
        test('strips <script> tags from Markdown content', async () => {
            const maliciousMd = 'Hello <script>alert("xss")</script> World';
            await window.renderMarkdown(maliciousMd, { enableMermaid: false });

            expect(preview.innerHTML).not.toContain('<script');
            expect(preview.innerHTML).not.toContain('alert("xss")');
            expect(preview.textContent).toContain('Hello  World');
        });

        test('strips event handler attributes like onerror, onload, onclick', async () => {
            const maliciousMd = `
<img src="invalid.jpg" onerror="alert(1)">
<a href="https://example.com" onclick="alert(2)">Click</a>
<div onmouseover="alert(3)">Hover</div>
<details open ontoggle="alert(4)"><summary>Details</summary>Body</details>
`;
            await window.renderMarkdown(maliciousMd, { enableMermaid: false });

            expect(preview.innerHTML).not.toContain('onerror');
            expect(preview.innerHTML).not.toContain('onclick');
            expect(preview.innerHTML).not.toContain('onmouseover');
            expect(preview.innerHTML).not.toContain('ontoggle');
            expect(preview.innerHTML).not.toContain('alert(');
        });

        test('strips javascript: and vbscript: URIs from links and images', async () => {
            const maliciousMd = `
[Malicious Link](javascript:alert(document.cookie))
<a href="javascript:alert(1)">Raw Link</a>
<a href="vbscript:msgbox(1)">VBScript Link</a>
![Malicious Image](javascript:alert(1))
`;
            await window.renderMarkdown(maliciousMd, { enableMermaid: false });

            const links = preview.querySelectorAll('a');
            links.forEach(link => {
                const href = link.getAttribute('href');
                if (href) {
                    expect(href.toLowerCase()).not.toContain('javascript:');
                    expect(href.toLowerCase()).not.toContain('vbscript:');
                }
            });

            const images = preview.querySelectorAll('img');
            images.forEach(img => {
                const src = img.getAttribute('src');
                if (src) {
                    expect(src.toLowerCase()).not.toContain('javascript:');
                    expect(src.toLowerCase()).not.toContain('vbscript:');
                }
            });
        });

        test('strips dangerous embedded tags like iframe, object, embed', async () => {
            const maliciousMd = `
<iframe src="https://example.com"></iframe>
<object data="test.swf"></object>
<embed src="test.swf">
`;
            await window.renderMarkdown(maliciousMd, { enableMermaid: false });

            expect(preview.querySelector('iframe')).toBeNull();
            expect(preview.querySelector('object')).toBeNull();
            expect(preview.querySelector('embed')).toBeNull();
        });

        test('sanitizes SVG content to prevent SVG-based XSS', async () => {
            const maliciousMd = `
<svg><script>alert("svg-xss")</script></svg>
<svg><image href="x" onerror="alert(1)"></image></svg>
`;
            await window.renderMarkdown(maliciousMd, { enableMermaid: false });

            expect(preview.innerHTML).not.toContain('<script');
            expect(preview.innerHTML).not.toContain('alert(');
        });
    });

    describe('Preservation of legitimate Osh features', () => {
        test('preserves MathML and KaTeX rendering', async () => {
            const mathMd = 'Inline math: $\\alpha + \\beta = \\gamma$';
            await window.renderMarkdown(mathMd, { enableMermaid: false });

            expect(preview.innerHTML).toContain('katex');
            expect(preview.querySelector('.katex')).not.toBeNull();
        });

        test('preserves task list checkboxes', async () => {
            const taskMd = `
- [ ] Incomplete task
- [x] Completed task
`;
            await window.renderMarkdown(taskMd, { enableMermaid: false });

            const checkboxes = preview.querySelectorAll('input[type="checkbox"]');
            expect(checkboxes.length).toBe(2);
        });

        test('preserves custom data attributes for source mapping', async () => {
            const md = '# Heading 1\n\nParagraph text';
            await window.renderMarkdown(md, { enableMermaid: false });

            const h1 = preview.querySelector('h1');
            expect(h1).not.toBeNull();
            expect(h1?.getAttribute('data-source-line')).toBe('1');
        });

        test('preserves legitimate HTML tags like details, summary, kbd, mark', async () => {
            const htmlMd = `
<details>
<summary>Summary title</summary>
Press <kbd>Cmd</kbd> + <kbd>C</kbd> to copy <mark>highlighted</mark> text.
</details>
`;
            await window.renderMarkdown(htmlMd, { enableMermaid: false });

            expect(preview.querySelector('details')).not.toBeNull();
            expect(preview.querySelector('summary')).not.toBeNull();
            expect(preview.querySelector('kbd')).not.toBeNull();
            expect(preview.querySelector('mark')).not.toBeNull();
        });

        test('preserves RTL attributes', async () => {
            const arabicMd = 'مرحبا بك في تطبيق Osh';
            await window.renderMarkdown(arabicMd, { enableMermaid: false });

            const p = preview.querySelector('p');
            expect(p).not.toBeNull();
            expect(p?.getAttribute('dir')).toBe('rtl');
        });
    });

    describe('Image URL Resolution and Normalization', () => {
        test('normalizes file:// image paths to local-md:// scheme', async () => {
            const md = '![Alt](file:///Users/username/Pictures/photo.png)';
            await window.renderMarkdown(md, { enableMermaid: false });

            const img = preview.querySelector('img');
            expect(img).not.toBeNull();
            expect(img?.getAttribute('src')).toBe('local-md:///Users/username/Pictures/photo.png');
        });

        test('normalizes file:// image paths with renderVersion cache bust', async () => {
            const md = '![Alt](file:///Users/username/Pictures/photo.png)';
            await window.renderMarkdown(md, { renderVersion: 10, enableMermaid: false });

            const img = preview.querySelector('img');
            expect(img).not.toBeNull();
            expect(img?.getAttribute('src')).toBe('local-md:///Users/username/Pictures/photo.png?v=10');
        });

        test('preserves remote https:// and data: image sources', async () => {
            const md = `
![Remote](https://example.com/logo.png)
![Data](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)
`;
            await window.renderMarkdown(md, { enableMermaid: false });

            const images = preview.querySelectorAll('img');
            expect(images.length).toBe(2);
            expect(images[0].getAttribute('src')).toBe('https://example.com/logo.png');
            expect(images[1].getAttribute('src')).toContain('data:image/png;base64,');
        });
    });

    describe('Error Message HTML Escaping', () => {
        test('escapes malicious HTML in Typst transpilation and error rendering', async () => {
            const maliciousCode = '<img src=x onerror=alert("typst-xss")>';
            const resultHtml = await renderTypstBlock(maliciousCode, 'quicklook');

            expect(resultHtml).not.toContain('<img src=x onerror=alert("typst-xss")>');
            expect(resultHtml).not.toContain('onerror="');
        });

        test('escapes malicious HTML in error handlers', async () => {
            const { escapeHtml } = await import('../src/index');
            const maliciousError = new Error('<img src=x onerror=alert("err-xss")>');
            const escaped = escapeHtml(String(maliciousError));
            expect(escaped).not.toContain('<img');
            expect(escaped).toContain('&lt;img src=x onerror=alert(&quot;err-xss&quot;)&gt;');
        });
    });
});
