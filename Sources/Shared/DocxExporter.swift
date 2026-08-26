import Foundation

/// Builds a minimal, valid .docx (Office Open XML WordprocessingML) from the
/// typed block model extracted from the rendered DOM.
///
/// Scope: headings, paragraphs with inline formatting, lists, tables, code
/// blocks, blockquotes, embedded images. Mermaid/KaTeX render as fallback code
/// in the DOM, so they export as code blocks (documented limitation).
struct DocxExporter {

    // MARK: - Content model

    struct InlineRun {
        var text: String
        var bold = false
        var italic = false
        var code = false
        /// Absolute URL for hyperlinks; nil for plain text.
        var linkURL: String?
    }

    struct Block {
        enum Kind {
            case heading(level: Int)
            case paragraph
            case listItem(listTag: String)
            case codeBlock
            case blockquoteParagraph
            case tableRow(isHeader: Bool)
        }
        var kind: Kind
        var runs: [InlineRun] = []
        var cells: [[InlineRun]] = []
        /// Relationship id of an embedded image (image paragraphs only).
        var imageRID: String?
        var directionRTL = false
    }

    private var imageRelationships: [(rid: String, path: String, ext: String)] = []
    private var hyperlinkRelationships: [(rid: String, url: String)] = []
    private var nextRID = 1

    mutating func docx(blocks: [Block], imageDataForRID: [String: (data: Data, ext: String)]) -> Data {
        imageRelationships = []
        hyperlinkRelationships = []
        nextRID = 1
        // Preserve caller-provided rIds for images so blocks can reference them.
        for rid in imageDataForRID.keys.sorted() {
            let ext = imageDataForRID[rid]!.ext
            imageRelationships.append((rid: rid, path: "word/media/\(rid).\(ext)", ext: ext))
        }
        if let maxImage = imageDataForRID.keys.compactMap({ Int($0.dropFirst(3)) }).max() {
            nextRID = maxImage + 1
        }

        var bodyXML = ""
        var rowBuffer: [Block] = []

        func flushRows() {
            guard !rowBuffer.isEmpty else { return }
            bodyXML += tableXML(rowBuffer)
            rowBuffer.removeAll()
        }

        for block in blocks {
            if case .tableRow = block.kind {
                // Assign rIds to any hyperlinks inside cells before emitting.
                rowBuffer.append(block)
                continue
            }
            flushRows()
            switch block.kind {
            case .heading(let level):
                bodyXML += paragraphXML(
                    resolvedRuns(block.runs),
                    style: "Heading\(min(max(level, 1), 6))", rtl: block.directionRTL)
            case .paragraph:
                if let rid = block.imageRID {
                    bodyXML += imageParagraphXML(rid: rid)
                } else {
                    bodyXML += paragraphXML(resolvedRuns(block.runs), style: nil, rtl: block.directionRTL)
                }
            case .blockquoteParagraph:
                var runs = block.runs
                for i in runs.indices { runs[i].italic = true }
                bodyXML += paragraphXML(resolvedRuns(runs), style: nil, rtl: block.directionRTL, indent: 720)
            case .listItem(let listTag):
                let bullet = listTag == "ul" ? "\u{2022} " : ""
                bodyXML += paragraphXML(resolvedRuns(block.runs), style: nil, rtl: block.directionRTL, indent: 360, prefix: bullet)
            case .codeBlock:
                let text = block.runs.map(\.text).joined(separator: "\n")
                bodyXML += paragraphXML([InlineRun(text: text, code: true)], style: nil, rtl: false)
            case .tableRow:
                break
            }
        }
        flushRows()

        let document = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" \
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\
        <w:body>\(bodyXML)<w:sectPr/></w:body></w:document>
        """

        let styles = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\
        \(headingStyle(1, sizeHalfPoints: 32))\(headingStyle(2, sizeHalfPoints: 26))\
        \(headingStyle(3, sizeHalfPoints: 22))\(headingStyle(4, sizeHalfPoints: 20))\
        \(headingStyle(5, sizeHalfPoints: 18))\(headingStyle(6, sizeHalfPoints: 16))\
        </w:styles>
        """

        let contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\
        <Default Extension="xml" ContentType="application/xml"/>\
        <Default Extension="png" ContentType="image/png"/>\
        <Default Extension="gif" ContentType="image/gif"/>\
        <Default Extension="jpg" ContentType="image/jpeg"/>\
        <Default Extension="jpeg" ContentType="image/jpeg"/>\
        <Default Extension="webp" ContentType="image/webp"/>\
        <Default Extension="svg" ContentType="image/svg+xml"/>\
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\
        <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>\
        </Types>
        """

        let rootRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\
        </Relationships>
        """

        var docRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        """
        for rel in imageRelationships {
            docRels += "<Relationship Id=\"\(rel.rid)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"media/\(rel.rid).\(rel.ext)\"/>"
        }
        for rel in hyperlinkRelationships {
            docRels += "<Relationship Id=\"\(rel.rid)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink\" Target=\"\(escapeXML(rel.url))\" TargetMode=\"External\"/>"
        }
        docRels += "</Relationships>"

        var zip = ZipWriter()
        zip.add(Data(contentTypes.utf8), path: "[Content_Types].xml")
        zip.add(Data(rootRels.utf8), path: "_rels/.rels")
        zip.add(Data(document.utf8), path: "word/document.xml")
        zip.add(Data(styles.utf8), path: "word/styles.xml")
        zip.add(Data(docRels.utf8), path: "word/_rels/document.xml.rels")
        for rel in imageRelationships {
            if let entry = imageDataForRID[rel.rid] {
                zip.add(entry.data, path: rel.path)
            }
        }
        return zip.archive()
    }

    // MARK: - Runs

    /// Replaces raw URLs in run.linkURL with concrete relationship ids,
    /// deduplicating identical targets.
    private mutating func resolvedRuns(_ runs: [InlineRun]) -> [InlineRun] {
        runs.map { run in
            guard let url = run.linkURL else { return run }
            if let existing = hyperlinkRelationships.first(where: { $0.url == url }) {
                var r = run
                r.linkURL = existing.rid
                return r
            }
            let rid = "rId\(nextRID)"
            nextRID += 1
            hyperlinkRelationships.append((rid: rid, url: url))
            var r = run
            r.linkURL = rid
            return r
        }
    }

    private func headingStyle(_ level: Int, sizeHalfPoints: Int) -> String {
        """
        <w:style w:type="paragraph" w:styleId="Heading\(level)">\
        <w:name w:val="heading \(level)"/>\
        <w:pPr><w:outlineLvl w:val="\(level - 1)"/></w:pPr>\
        <w:rPr><w:b/><w:sz w:val="\(sizeHalfPoints)"/></w:rPr>\
        </w:style>
        """
    }

    // MARK: - XML builders

    private func paragraphXML(
        _ runs: [InlineRun], style: String?, rtl: Bool,
        indent: Int = 0, prefix: String = ""
    ) -> String {
        var allRuns = runs.isEmpty ? [InlineRun(text: "")] : runs
        if !prefix.isEmpty {
            allRuns.insert(InlineRun(text: prefix), at: 0)
        }
        let runsXML = allRuns.map(runXML).joined()
        var pPr = ""
        if rtl { pPr += "<w:bidi/>" }
        if indent > 0 { pPr += "<w:ind w:left=\"\(indent)\"/>" }
        if let style { pPr += "<w:pStyle w:val=\"\(style)\"/>" }
        return "<w:p>\(pPr.isEmpty ? "" : "<w:pPr>\(pPr)</w:pPr>")\(runsXML)</w:p>"
    }

    private mutating func imageParagraphXML(rid: String) -> String {
        let (cx, cy) = imageExtentEMU(for: rid)
        let drawing = """
        <w:r><w:drawing>\
        <wp:inline distT="0" distB="0" distL="0" distR="0" \
        xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">\
        <wp:extent cx="\(cx)" cy="\(cy)"/>\
        <wp:docPr id="\(nextDocPrID())" name="\(escapeXML(rid))"/>\
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">\
        <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">\
        <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">\
        <pic:nvPicPr><pic:cNvPr id="0" name="\(escapeXML(rid))"/><pic:cNvPicPr/></pic:nvPicPr>\
        <pic:blipFill><a:blip r:embed="\(rid)"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>\
        <pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="\(cx)" cy="\(cy)"/></a:xfrm>\
        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>\
        </pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>
        """
        return "<w:p>\(drawing)</w:p>"
    }

    private var docPrCounter = 0
    private mutating func nextDocPrID() -> Int {
        docPrCounter += 1
        return docPrCounter
    }

    /// EMU extents at 96dpi. Width capped at 6 inches; height keeps the source
    /// aspect ratio when the image format exposes dimensions (PNG/GIF).
    private func imageExtentEMU(for rid: String) -> (Int, Int) {
        let maxWidthEMU = 5_486_400   // 6 in
        let defaultSize = (4_572_000, 3_048_000) // 480x320 px equivalent
        guard let rel = imageRelationships.first(where: { $0.rid == rid }) else {
            return defaultSize
        }
        var pixelSize: (Int, Int)?
        if let dims = pixelDimensionsProvider?(rel.path) {
            pixelSize = (dims.widthPx, dims.heightPx)
        }
        guard let (w, h) = pixelSize, w > 0, h > 0 else { return defaultSize }
        let emu = (w * 9_525, h * 9_525)
        if emu.0 <= maxWidthEMU { return emu }
        let scale = Double(maxWidthEMU) / Double(emu.0)
        return (maxWidthEMU, Int(Double(emu.1) * scale))
    }

    /// Caller hook supplying pixel dimensions for a media part path, or nil
    /// when the format is not trivially parseable.
    var pixelDimensionsProvider: ((String) -> (widthPx: Int, heightPx: Int)?)?

    private func tableXML(_ rows: [Block]) -> String {
        let rowsXML = rows.map { row -> String in
            guard case .tableRow(let isHeader) = row.kind else { return "" }
            let cells = row.cells.map { cellRuns -> String in
                let runs = isHeader ? cellRuns.map { r in InlineRun(text: r.text, bold: true, italic: r.italic, code: r.code, linkURL: r.linkURL) } : cellRuns
                return "<w:tc><w:tcPr><w:tcW w:w=\"0\" w:type=\"auto\"/></w:tcPr>" +
                    paragraphXML(runs, style: nil, rtl: row.directionRTL) +
                    "</w:tc>"
            }.joined()
            return "<w:tr>\(cells)</w:tr>"
        }.joined()
        // Single-line border definition on every edge keeps Word/Pages happy.
        return """
        <w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/>\
        <w:tblBorders>\
        <w:top w:val="single" w:sz="4" w:color="999999"/>\
        <w:left w:val="single" w:sz="4" w:color="999999"/>\
        <w:bottom w:val="single" w:sz="4" w:color="999999"/>\
        <w:right w:val="single" w:sz="4" w:color="999999"/>\
        <w:insideH w:val="single" w:sz="4" w:color="999999"/>\
        <w:insideV w:val="single" w:sz="4" w:color="999999"/>\
        </w:tblBorders></w:tblPr>\(rowsXML)</w:tbl>
        """
    }

    private func runXML(_ run: InlineRun) -> String {
        var rPr = ""
        if run.bold { rPr += "<w:b/>" }
        if run.italic { rPr += "<w:i/>" }
        if run.code { rPr += "<w:rFonts w:ascii=\"Menlo\" w:hAnsi=\"Menlo\"/><w:sz w:val=\"20\"/>" }
        let escaped = escapeXML(run.text)

        if let rid = run.linkURL {
            return "<w:hyperlink r:id=\"\(rid)\"><w:r>\(rPr.isEmpty ? "" : "<w:rPr>\(rPr)</w:rPr>")" +
                "<w:t xml:space=\"preserve\">\(escaped)</w:t></w:r></w:hyperlink>"
        }
        return "<w:r>\(rPr.isEmpty ? "" : "<w:rPr>\(rPr)</w:rPr>")<w:t xml:space=\"preserve\">\(escaped)</w:t></w:r>"
    }

    private func escapeXML(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            default: out.append(ch)
            }
        }
        return out
    }
}

enum ImageDimensionParser {
    /// Returns pixel dimensions for formats with trivially parseable headers
    /// (PNG, GIF). Returns nil for anything else; callers fall back to defaults.
    static func dimensions(of data: Data) -> (Int, Int)? {
        let bytes = [UInt8](data.prefix(33))
        // PNG: 8-byte signature, "IHDR" at offset 12, width/height at 16..24 BE.
        if bytes.count >= 24,
           Array(bytes[0...7]) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
           Array(bytes[12...15]) == Array("IHDR".utf8) {
            let w = bytes[16...19].reduce(0) { $0 << 8 | UInt32($1) }
            let h = bytes[20...23].reduce(0) { $0 << 8 | UInt32($1) }
            return (Int(w), Int(h))
        }
        // GIF: "GIF8?a", little-endian width at 6..8, height at 8..10.
        if bytes.count >= 10,
           Array(bytes[0...2]) == Array("GIF".utf8),
           bytes[6...9].allSatisfy({ $0 >= 0 }) {
            let w = UInt16(bytes[6]) | (UInt16(bytes[7]) << 8)
            let h = UInt16(bytes[8]) | (UInt16(bytes[9]) << 8)
            if w > 0 && h > 0 { return (Int(w), Int(h)) }
        }
        return nil
    }
}
