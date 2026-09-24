import '../src/index';

/**
 * The custom scheme handler returns raw file bytes as a latin1 string, which is what
 * `exportDocxModel` walks to rebuild the image before base64-encoding it.
 */
function schemeHandlerPayload(byteCount: number): string {
    const bytes = Buffer.alloc(byteCount);
    for (let i = 0; i < byteCount; i++) bytes[i] = i % 256;
    return bytes.toString('binary');
}

/** Above the ~65k argument limit that `String.fromCharCode(...bytes)` runs into. */
const LARGE_IMAGE_BYTES = 200_000;

let fakePayload = '';

beforeEach(() => {
    fakePayload = schemeHandlerPayload(LARGE_IMAGE_BYTES);
    (global as any).XMLHttpRequest = class {
        status = 200;
        responseText = '';
        open() {}
        overrideMimeType() {}
        send() {
            this.responseText = fakePayload;
        }
    };
    document.body.innerHTML = '<div id="markdown-preview"></div>';
});

function exportModelWithImage(src: string): { images: Record<string, string> } {
    document.getElementById('markdown-preview')!.innerHTML = `<img src="${src}">`;
    return window.exportDocxModel() as { images: Record<string, string> };
}

describe('exportDocxModel image inlining', () => {
    test('inlines an image larger than the function argument limit', () => {
        const model = exportModelWithImage('local-md:///photos/large.png');

        const dataUri = model.images['local-md:///photos/large.png'];
        expect(dataUri).toBeDefined();
        expect(dataUri.startsWith('data:image/png;base64,')).toBe(true);
    });

    test('round-trips every byte of a large image', () => {
        const model = exportModelWithImage('local-md:///photos/large.png');

        const decoded = Buffer.from(model.images['local-md:///photos/large.png'].split(',')[1], 'base64');
        expect(decoded.length).toBe(LARGE_IMAGE_BYTES);
        expect(decoded[0]).toBe(0);
        expect(decoded[1]).toBe(1);
        expect(decoded[LARGE_IMAGE_BYTES - 1]).toBe((LARGE_IMAGE_BYTES - 1) % 256);
    });

    test('keeps the declared MIME type for other formats', () => {
        const model = exportModelWithImage('local-md:///photos/shot.jpeg');

        expect(model.images['local-md:///photos/shot.jpeg'].startsWith('data:image/jpeg;base64,')).toBe(true);
    });

    test('passes through images that are already data URIs', () => {
        const inline = 'data:image/gif;base64,R0lGODlhAQABAAAAACw=';
        const model = exportModelWithImage(inline);

        expect(model.images[inline]).toBe(inline);
    });
});
