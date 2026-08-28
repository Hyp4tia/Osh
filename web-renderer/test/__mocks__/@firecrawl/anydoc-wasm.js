const fs = require('fs');
const path = require('path');
const { TextDecoder, TextEncoder } = require('util');

if (typeof global.TextDecoder === 'undefined') {
    global.TextDecoder = TextDecoder;
}
if (typeof global.TextEncoder === 'undefined') {
    global.TextEncoder = TextEncoder;
}

const wasmPath = path.resolve(__dirname, '../../../node_modules/@firecrawl/anydoc-wasm/anydoc_wasm_bg.wasm');
const wasmBuffer = fs.readFileSync(wasmPath);

let code = fs.readFileSync(path.resolve(__dirname, '../../../node_modules/@firecrawl/anydoc-wasm/anydoc_wasm.js'), 'utf8');
code = code.replace(/import\.meta\.url/g, '""');
code = code.replace(/export function ([a-zA-Z0-9_]+)\s*\(/g, 'function $1(');
code = code.replace(/export\s*\{\s*initSync\s*,\s*__wbg_init\s+as\s+default\s*\};/g, '');
code += '\nexports.formatFromBytes = formatFromBytes;\nexports.formatFromExtension = formatFromExtension;\nexports.formatFromPath = formatFromPath;\nexports.toDocument = toDocument;\nexports.toMarkdownBytes = toMarkdownBytes;\nexports.initSync = initSync;\nexports.default = __wbg_init;\n';

const mod = { exports: {} };
const fn = new Function('exports', 'module', code);
fn(mod.exports, mod);
mod.exports.initSync({ module: wasmBuffer });

module.exports = mod.exports;
