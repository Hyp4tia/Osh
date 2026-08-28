/**
 * @jest-environment jsdom
 */

import { convertDocumentToMarkdown, detectDocumentFormat } from '../src/document-converter';
import '../src/index';
import * as fs from 'fs';
import * as path from 'path';

describe('Document Converter (AnyDoc WASM)', () => {
    const fixturesDir = path.resolve(__dirname, '../../Tests/fixtures');

    function getDocxBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-doc.docx');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getPdfBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-doc.pdf');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getScannedPdfBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-scanned.pdf');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getCsvBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-doc.csv');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getXlsxBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-doc.xlsx');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getPptxBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'sample-doc.pptx');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    function getRichPptxBytes(): Uint8Array {
        const filePath = path.join(fixturesDir, 'rich-presentation.pptx');
        return new Uint8Array(fs.readFileSync(filePath));
    }

    test('getAnyDocInstance resolves successfully', async () => {
        const { getAnyDocInstance } = await import('../src/document-converter');
        const instance = await getAnyDocInstance();
        expect(instance).toBeDefined();
        expect(typeof instance.formatFromBytes).toBe('function');
    });

    // MARK: - Format Detection

    test('detects DOCX format from bytes', async () => {
        const docxBytes = getDocxBytes();
        const format = await detectDocumentFormat(docxBytes);
        expect(format).toBe('docx');
    });

    test('detects PDF format from bytes', async () => {
        const pdfBytes = getPdfBytes();
        const format = await detectDocumentFormat(pdfBytes);
        expect(format).toBe('pdf');
    });

    test('detects XLSX format from bytes', async () => {
        const xlsxBytes = getXlsxBytes();
        const format = await detectDocumentFormat(xlsxBytes);
        expect(format).toBe('xlsx');
    });

    test('detects PPTX format from bytes', async () => {
        const pptxBytes = getPptxBytes();
        const format = await detectDocumentFormat(pptxBytes);
        expect(format).toBe('pptx');
    });

    // MARK: - DOCX & PDF Conversion

    test('converts DOCX to clean Markdown with headings, formatting, and tables', async () => {
        const docxBytes = getDocxBytes();
        const result = await convertDocumentToMarkdown(docxBytes);

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('docx');
        expect(typeof result.markdown).toBe('string');
        expect(result.markdown).toContain('Document Converter Heading');
        expect(result.markdown).toContain('**bold**');
        expect(result.markdown).toContain('*italic*');
        expect(result.markdown).toContain('[link to Osh](https://osh.dev)');
        expect(result.markdown).toContain('| Column A | Column B |');
    });

    test('converts text-based PDF to Markdown', async () => {
        const pdfBytes = getPdfBytes();
        const result = await convertDocumentToMarkdown(pdfBytes);

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('pdf');
        expect(typeof result.markdown).toBe('string');
        expect(result.markdown).toContain('Osh Document Converter Test');
        expect(result.markdown).toContain('First bullet item');
    });

    test('returns needsOcr error for textless or scanned PDF', async () => {
        const textlessPdf = getScannedPdfBytes();
        const result = await convertDocumentToMarkdown(textlessPdf);

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('needsOcr');
        expect(result.error).toContain('OCR');
        expect(result.pages).toBeDefined();
        expect(result.pages?.length).toBeGreaterThan(0);
    });

    // MARK: - CSV Conversion

    test('converts CSV to clean Markdown table preserving quotes, commas, and Unicode', async () => {
        const csvBytes = getCsvBytes();
        const result = await convertDocumentToMarkdown(csvBytes, 'csv');

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('csv');
        expect(typeof result.markdown).toBe('string');
        expect(result.markdown).toContain('| Product | Category | Price | Quantity | Description | Notes |');
        expect(result.markdown).toContain('Widget A');
        expect(result.markdown).toContain('Gadget Pro (جهاز برو)');
        expect(result.markdown).toContain('Standard widget, version 1.0');
        expect(result.markdown).toContain('Unicode Test (Café / العربية)');
    });

    // MARK: - XLSX Conversion

    test('converts multi-sheet XLSX to clean Markdown tables with sheet headings', async () => {
        const xlsxBytes = getXlsxBytes();
        const result = await convertDocumentToMarkdown(xlsxBytes, 'xlsx');

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('xlsx');
        expect(typeof result.markdown).toBe('string');
        expect(result.markdown).toContain('## Sales Q1');
        expect(result.markdown).toContain('| Product | Quarter | Revenue (USD) |');
        expect(result.markdown).toContain('Widget Alpha');
        expect(result.markdown).toContain('Gadget Beta (جهاز بيتا)');
        expect(result.markdown).toContain('45000');
        expect(result.markdown).toContain('## Team Directory');
        expect(result.markdown).toContain('Alice Walker');
    });

    // MARK: - PPTX Conversion

    test('converts multi-slide PPTX to structured Markdown with titles and bullet points', async () => {
        const pptxBytes = getPptxBytes();
        const result = await convertDocumentToMarkdown(pptxBytes, 'pptx');

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('pptx');
        expect(typeof result.markdown).toBe('string');
        expect(result.markdown).toContain('Osh Presentation Test (عرض تقديمي)');
        expect(result.markdown).toContain('Fast & local Markdown conversion');
        expect(result.markdown).toContain('Key Capabilities');
        expect(result.markdown).toContain('Offline WebAssembly execution');
    });

    test('converts rich PPTX embedding images as data URIs and preserving slide boundaries', async () => {
        const richBytes = getRichPptxBytes();
        const result = await convertDocumentToMarkdown(richBytes, 'pptx');

        expect(result.success).toBe(true);
        expect(result.detectedFormat).toBe('pptx');
        expect(typeof result.markdown).toBe('string');
        
        // Slide 1 title & notes
        expect(result.markdown).toContain('## AIJRF Presentation');
        expect(result.markdown).toContain('Brand & Digital Strategy Proposal');
        expect(result.markdown).toContain('> Remember to emphasize market timing and team readiness.');

        // Slide separator
        expect(result.markdown).toContain('---');

        // Slide 2 title, bullets, image
        expect(result.markdown).toContain('## Strategic Objectives');
        expect(result.markdown).toContain('• Enhance brand awareness across digital channels');
        // Sanitized alt text & embedded data URI (no /home/claude/ path leak)
        expect(result.markdown).toContain('![auc.png](data:image/png;base64,');
        expect(result.markdown).not.toContain('/home/claude/auc.png\n');

        // Slide 3 title & table
        expect(result.markdown).toContain('## Timeline & Milestones');
        expect(result.markdown).toContain('| Phase | Target Date |');
        expect(result.markdown).toContain('| Discovery | Q1 2026 |');
    });

    // MARK: - Error Handling

    test('handles empty input gracefully', async () => {
        const empty = new Uint8Array(0);
        const result = await convertDocumentToMarkdown(empty);

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('malformed');
        expect(result.error).toContain('empty');
    });

    test('handles unrecognized/garbage binary data with unsupported error', async () => {
        const garbage = new Uint8Array([0x00, 0x11, 0x22, 0x33, 0x44, 0x55]);
        const result = await convertDocumentToMarkdown(garbage);

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('unsupported');
    });

    test('handles corrupted PDF structure with malformed error', async () => {
        const corrupt = Buffer.from('%PDF-1.4\ncorrupted stream structure');
        const result = await convertDocumentToMarkdown(new Uint8Array(corrupt), 'pdf');

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('malformed');
    });

    test('handles corrupted XLSX structure with malformed error', async () => {
        const corrupt = Buffer.from('PK\x03\x04corrupted excel data');
        const result = await convertDocumentToMarkdown(new Uint8Array(corrupt), 'xlsx');

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('malformed');
    });

    test('handles corrupted PPTX structure with malformed error', async () => {
        const corrupt = Buffer.from('PK\x03\x04corrupted powerpoint data');
        const result = await convertDocumentToMarkdown(new Uint8Array(corrupt), 'pptx');

        expect(result.success).toBe(false);
        expect(result.errorCode).toBe('malformed');
    });

    // MARK: - Window Bridge

    test('window.convertDocumentToMarkdown bridges Base64 data for XLSX and CSV', async () => {
        expect(typeof window.convertDocumentToMarkdown).toBe('function');
        
        const csvBytes = getCsvBytes();
        const base64 = Buffer.from(csvBytes).toString('base64');

        const result = await window.convertDocumentToMarkdown!(base64, 'csv');
        expect(result.success).toBe(true);
        expect(result.markdown).toContain('Widget A');
    });

    test('window.detectDocumentFormat bridges Base64 data', async () => {
        expect(typeof window.detectDocumentFormat).toBe('function');

        const xlsxBytes = getXlsxBytes();
        const base64 = Buffer.from(xlsxBytes).toString('base64');

        const format = await window.detectDocumentFormat!(base64);
        expect(format).toBe('xlsx');
    });
});
