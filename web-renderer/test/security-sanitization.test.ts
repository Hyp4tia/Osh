import DOMPurify from 'dompurify';

const SVG_DOMPURIFY_CONFIG: DOMPurify.Config = {
    USE_PROFILES: { svg: true, svgFilters: true },
    ADD_TAGS: ['foreignObject', 'style'],
    ADD_ATTR: ['dominant-baseline', 'text-anchor', 'marker-end', 'target']
};

describe('SVG_DOMPURIFY_CONFIG', () => {
    test('strips malicious script tags from SVG markup', () => {
        const dirtySvg = '<svg><script>alert("xss")</script><text>Safe Label</text></svg>';
        const cleanSvg = DOMPurify.sanitize(dirtySvg, SVG_DOMPURIFY_CONFIG) as string;

        expect(cleanSvg).not.toContain('<script>');
        expect(cleanSvg).not.toContain('alert');
        expect(cleanSvg).toContain('<text>Safe Label</text>');
    });

    test('strips inline event handlers from SVG elements', () => {
        const dirtySvg = '<svg><circle cx="10" cy="10" r="5" onload="alert(1)" onerror="alert(2)"/></svg>';
        const cleanSvg = DOMPurify.sanitize(dirtySvg, SVG_DOMPURIFY_CONFIG) as string;

        expect(cleanSvg).not.toContain('onload');
        expect(cleanSvg).not.toContain('onerror');
        expect(cleanSvg).toContain('<circle');
    });

    test('preserves diagram-essential tags and attributes', () => {
        const diagramSvg = '<svg><style>.cls{fill:red;}</style><g marker-end="url(#arrow)"><text dominant-baseline="middle" text-anchor="middle">Node</text><foreignObject width="100" height="50"><div>Label</div></foreignObject></g></svg>';
        const cleanSvg = DOMPurify.sanitize(diagramSvg, SVG_DOMPURIFY_CONFIG) as string;

        expect(cleanSvg).toContain('<style>');
        expect(cleanSvg).toContain('dominant-baseline="middle"');
        expect(cleanSvg).toContain('text-anchor="middle"');
        expect(cleanSvg).toContain('marker-end="url(#arrow)"');
        expect(cleanSvg).toContain('<foreignObject');
    });
});
