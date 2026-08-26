import Foundation

/// Minimal ZIP archive writer producing stored (uncompressed) entries.
///
/// DOCX is a ZIP of XML parts; Word and Pages accept uncompressed entries, so a
/// correct central directory + local headers are all we need. Avoids pulling in
/// a dependency (ZIPFoundation etc.) for one write path.
struct ZipWriter {
    private struct Entry {
        let name: String
        let crc32: UInt32
        let data: [UInt8]
    }

    private var entries: [Entry] = []

    mutating func add(_ data: Data, path name: String) {
        let bytes = [UInt8](data)
        entries.append(Entry(name: name, crc32: Self.crc32(bytes), data: bytes))
    }

    func archive() -> Data {
        var out: [UInt8] = []
        var centralDirectory: [UInt8] = []

        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            let offset = UInt32(out.count)

            out.append(contentsOf: Self.localHeader(
                nameBytes: nameBytes, crc32: entry.crc32, size: UInt32(entry.data.count)))

            // Local file header is 30 bytes + filename.
            out.append(contentsOf: entry.data)

            centralDirectory.append(contentsOf: Self.centralDirectoryEntry(
                nameBytes: nameBytes, crc32: entry.crc32, size: UInt32(entry.data.count), offset: offset))
        }

        let cdOffset = UInt32(out.count)
        let cdSize = UInt32(centralDirectory.count)

        out.append(contentsOf: centralDirectory)

        // End of Central Directory record.
        out.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])           // signature
        out.append(contentsOf: Self.le16(0))                        // disk number
        out.append(contentsOf: Self.le16(0))                        // disk with CD
        out.append(contentsOf: Self.le16(UInt16(entries.count)))    // entries this disk
        out.append(contentsOf: Self.le16(UInt16(entries.count)))    // total entries
        out.append(contentsOf: Self.le32(cdSize))
        out.append(contentsOf: Self.le32(cdOffset))
        out.append(contentsOf: Self.le16(0))                        // comment length

        return Data(out)
    }

    // MARK: - Record builders

    private static func localHeader(nameBytes: [UInt8], crc32: UInt32, size: UInt32) -> [UInt8] {
        var b: [UInt8] = []
        b.append(contentsOf: [0x50, 0x4B, 0x03, 0x04])  // local file header signature
        b.append(contentsOf: le16(20))                   // version needed (2.0: no zip64)
        b.append(contentsOf: le16(1 << 11))              // general purpose flags: UTF-8 names
        b.append(contentsOf: le16(0))                    // method 0 = stored
        b.append(contentsOf: le16(0))                    // mod time
        b.append(contentsOf: le16(0x21))                 // mod date (1980-01-01; readers don't care)
        b.append(contentsOf: le32(crc32))
        b.append(contentsOf: le32(size))                 // compressed size
        b.append(contentsOf: le32(size))                 // uncompressed size
        b.append(contentsOf: le16(UInt16(nameBytes.count)))
        b.append(contentsOf: le16(0))                    // extra field length
        b.append(contentsOf: nameBytes)
        return b
    }

    private static func centralDirectoryEntry(nameBytes: [UInt8], crc32: UInt32, size: UInt32, offset: UInt32) -> [UInt8] {
        var b: [UInt8] = []
        b.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])  // central directory signature
        b.append(contentsOf: le16(20))                   // version made by
        b.append(contentsOf: le16(20))                   // version needed
        b.append(contentsOf: le16(1 << 11))              // UTF-8 flag
        b.append(contentsOf: le16(0))                    // method stored
        b.append(contentsOf: le16(0))                    // mod time
        b.append(contentsOf: le16(0x21))                 // mod date
        b.append(contentsOf: le32(crc32))
        b.append(contentsOf: le32(size))
        b.append(contentsOf: le32(size))
        b.append(contentsOf: le16(UInt16(nameBytes.count)))
        b.append(contentsOf: le16(0))                    // extra length
        b.append(contentsOf: le16(0))                    // comment length
        b.append(contentsOf: le16(0))                    // disk number start
        b.append(contentsOf: le16(0))                    // internal attrs
        b.append(contentsOf: le32(0))                    // external attrs
        b.append(contentsOf: le32(offset))
        b.append(contentsOf: nameBytes)
        return b
    }

    private static func le16(_ v: UInt16) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8(v >> 8)]
    }

    private static func le32(_ v: UInt32) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8(v >> 24)]
    }

    // MARK: - CRC-32 (IEEE 802.3, the variant ZIP requires)

    static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var table: [UInt32] = (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 == 1) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
        var crc: UInt32 = 0xFFFFFFFF
        for byte in bytes {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}
