import Foundation
import zlib

enum SkillPackageError: LocalizedError {
    case invalidZipArchive
    case noMarkdownFound
    case ambiguousSkillEntries([String])
    case decompressionFailed(String)
    case compressionFailed(String)
    case pathTraversalDetected(String)
    case entryExceedsSizeLimit(String)

    var errorDescription: String? {
        switch self {
        case .invalidZipArchive:
            return NSLocalizedString("The .skill package archive is corrupted or invalid.", comment: "Invalid zip error")
        case .noMarkdownFound:
            return NSLocalizedString("No SKILL.md or Markdown document was found inside the .skill package.", comment: "No markdown found error")
        case .ambiguousSkillEntries(let paths):
            return String(format: NSLocalizedString("Multiple SKILL.md documents found in package: %@", comment: "Ambiguous skill entries error"), paths.joined(separator: ", "))
        case .decompressionFailed(let path):
            return String(format: NSLocalizedString("Failed to decompress entry '%@' in .skill package.", comment: "Decompression error"), path)
        case .compressionFailed(let path):
            return String(format: NSLocalizedString("Failed to compress entry '%@' for .skill package.", comment: "Compression error"), path)
        case .pathTraversalDetected(let path):
            return String(format: NSLocalizedString("Unsafe path traversal detected in .skill package: '%@'.", comment: "Security error"), path)
        case .entryExceedsSizeLimit(let path):
            return String(format: NSLocalizedString("Entry '%@' exceeds allowable size limit.", comment: "Size limit error"), path)
        }
    }
}

struct ZipEntryRecord {
    var versionMadeBy: UInt16
    var versionNeeded: UInt16
    var generalPurposeFlag: UInt16
    var compressionMethod: UInt16
    var lastModTime: UInt16
    var lastModDate: UInt16
    var crc32: UInt32
    var compressedSize: UInt32
    var uncompressedSize: UInt32
    var name: String
    var extraField: Data
    var fileComment: Data
    var diskNumberStart: UInt16
    var internalFileAttributes: UInt16
    var externalFileAttributes: UInt32
    var rawCompressedData: Data
}

enum SkillPackage {

    private static let maxUncompressedEntryBytes: UInt32 = 64 * 1024 * 1024 // 64 MB
    private static let eocdSignature = Data([0x50, 0x4B, 0x05, 0x06])
    private static let centralDirSignature = Data([0x50, 0x4B, 0x01, 0x02])
    private static let localHeaderSignature = Data([0x50, 0x4B, 0x03, 0x04])

    // MARK: - Format Detection

    static func isZipPackage(data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        return data[0] == 0x50 && data[1] == 0x4B && data[2] == 0x03 && data[3] == 0x04
    }

    // MARK: - Extraction

    static func extractPrimaryMarkdown(from data: Data) throws -> (text: String, internalPath: String, entries: [ZipEntryRecord]) {
        let entries = try parseArchive(data: data)
        let primaryEntry = try findPrimaryMarkdownEntry(in: entries)
        let text = try extractText(from: primaryEntry)
        return (text: text, internalPath: primaryEntry.name, entries: entries)
    }

    static func parseArchive(data: Data) throws -> [ZipEntryRecord] {
        guard let eocdRange = data.range(of: eocdSignature, options: .backwards) else {
            throw SkillPackageError.invalidZipArchive
        }

        let eocdOffset = eocdRange.lowerBound
        guard eocdOffset + 22 <= data.count else {
            throw SkillPackageError.invalidZipArchive
        }

        let totalEntries = Int(data.subdata(in: eocdOffset + 10 ..< eocdOffset + 12).withUnsafeBytes { $0.load(as: UInt16.self) })
        let cdOffset = Int(data.subdata(in: eocdOffset + 16 ..< eocdOffset + 20).withUnsafeBytes { $0.load(as: UInt32.self) })

        var records: [ZipEntryRecord] = []
        records.reserveCapacity(totalEntries)
        var cur = cdOffset

        for _ in 0..<totalEntries {
            guard cur + 46 <= data.count else { throw SkillPackageError.invalidZipArchive }
            let sig = data.subdata(in: cur ..< cur + 4).withUnsafeBytes { $0.load(as: UInt32.self) }
            guard sig == 0x02014b50 else { throw SkillPackageError.invalidZipArchive }

            let verMadeBy = data.subdata(in: cur + 4 ..< cur + 6).withUnsafeBytes { $0.load(as: UInt16.self) }
            let verNeeded = data.subdata(in: cur + 6 ..< cur + 8).withUnsafeBytes { $0.load(as: UInt16.self) }
            let flag = data.subdata(in: cur + 8 ..< cur + 10).withUnsafeBytes { $0.load(as: UInt16.self) }
            let method = data.subdata(in: cur + 10 ..< cur + 12).withUnsafeBytes { $0.load(as: UInt16.self) }
            let modTime = data.subdata(in: cur + 12 ..< cur + 14).withUnsafeBytes { $0.load(as: UInt16.self) }
            let modDate = data.subdata(in: cur + 14 ..< cur + 16).withUnsafeBytes { $0.load(as: UInt16.self) }
            let crc = data.subdata(in: cur + 16 ..< cur + 20).withUnsafeBytes { $0.load(as: UInt32.self) }
            let compSize = data.subdata(in: cur + 20 ..< cur + 24).withUnsafeBytes { $0.load(as: UInt32.self) }
            let uncompSize = data.subdata(in: cur + 24 ..< cur + 28).withUnsafeBytes { $0.load(as: UInt32.self) }
            let nameLen = Int(data.subdata(in: cur + 28 ..< cur + 30).withUnsafeBytes { $0.load(as: UInt16.self) })
            let extraLen = Int(data.subdata(in: cur + 30 ..< cur + 32).withUnsafeBytes { $0.load(as: UInt16.self) })
            let commentLen = Int(data.subdata(in: cur + 32 ..< cur + 34).withUnsafeBytes { $0.load(as: UInt16.self) })
            let diskStart = data.subdata(in: cur + 34 ..< cur + 36).withUnsafeBytes { $0.load(as: UInt16.self) }
            let intAttr = data.subdata(in: cur + 36 ..< cur + 38).withUnsafeBytes { $0.load(as: UInt16.self) }
            let extAttr = data.subdata(in: cur + 38 ..< cur + 42).withUnsafeBytes { $0.load(as: UInt32.self) }
            let localOffset = Int(data.subdata(in: cur + 42 ..< cur + 46).withUnsafeBytes { $0.load(as: UInt32.self) })

            guard cur + 46 + nameLen + extraLen + commentLen <= data.count else {
                throw SkillPackageError.invalidZipArchive
            }

            let nameBytes = data.subdata(in: cur + 46 ..< cur + 46 + nameLen)
            guard let name = String(data: nameBytes, encoding: .utf8) ?? String(data: nameBytes, encoding: .ascii) else {
                throw SkillPackageError.invalidZipArchive
            }

            // Security checks: Reject path traversal and absolute paths
            if name.contains("..") || name.hasPrefix("/") || name.contains("\0") {
                throw SkillPackageError.pathTraversalDetected(name)
            }

            if uncompSize > maxUncompressedEntryBytes {
                throw SkillPackageError.entryExceedsSizeLimit(name)
            }

            let extra = data.subdata(in: cur + 46 + nameLen ..< cur + 46 + nameLen + extraLen)
            let comment = data.subdata(in: cur + 46 + nameLen + extraLen ..< cur + 46 + nameLen + extraLen + commentLen)

            // Extract compressed payload from local file header
            guard localOffset + 30 <= data.count else { throw SkillPackageError.invalidZipArchive }
            let lhNameLen = Int(data.subdata(in: localOffset + 26 ..< localOffset + 28).withUnsafeBytes { $0.load(as: UInt16.self) })
            let lhExtraLen = Int(data.subdata(in: localOffset + 28 ..< localOffset + 30).withUnsafeBytes { $0.load(as: UInt16.self) })
            let dataStart = localOffset + 30 + lhNameLen + lhExtraLen
            guard dataStart + Int(compSize) <= data.count else { throw SkillPackageError.invalidZipArchive }
            let rawData = data.subdata(in: dataStart ..< dataStart + Int(compSize))

            records.append(ZipEntryRecord(
                versionMadeBy: verMadeBy,
                versionNeeded: verNeeded,
                generalPurposeFlag: flag,
                compressionMethod: method,
                lastModTime: modTime,
                lastModDate: modDate,
                crc32: crc,
                compressedSize: compSize,
                uncompressedSize: uncompSize,
                name: name,
                extraField: extra,
                fileComment: comment,
                diskNumberStart: diskStart,
                internalFileAttributes: intAttr,
                externalFileAttributes: extAttr,
                rawCompressedData: rawData
            ))

            cur += 46 + nameLen + extraLen + commentLen
        }

        return records
    }

    static func findPrimaryMarkdownEntry(in entries: [ZipEntryRecord]) throws -> ZipEntryRecord {
        let fileEntries = entries.filter { !$0.name.hasSuffix("/") && $0.uncompressedSize > 0 }
        guard !fileEntries.isEmpty else { throw SkillPackageError.noMarkdownFound }

        // 1. Locate all SKILL.md entries (case-insensitive)
        let skillEntries = fileEntries.filter {
            let last = URL(fileURLWithPath: $0.name).lastPathComponent
            return last.caseInsensitiveCompare("SKILL.md") == .orderedSame
        }

        if skillEntries.count == 1 {
            return skillEntries[0]
        } else if skillEntries.count > 1 {
            // Pick by shortest path depth
            let sortedByDepth = skillEntries.sorted { entryA, entryB in
                let depthA = entryA.name.split(separator: "/").count
                let depthB = entryB.name.split(separator: "/").count
                return depthA < depthB
            }
            let minDepth = sortedByDepth[0].name.split(separator: "/").count
            let atMinDepth = sortedByDepth.filter { $0.name.split(separator: "/").count == minDepth }
            if atMinDepth.count == 1 {
                return atMinDepth[0]
            } else {
                throw SkillPackageError.ambiguousSkillEntries(atMinDepth.map(\.name))
            }
        }

        // 2. Fallback: Check for README.md (case-insensitive)
        let readmeEntries = fileEntries.filter {
            let last = URL(fileURLWithPath: $0.name).lastPathComponent
            return last.caseInsensitiveCompare("README.md") == .orderedSame
        }
        if readmeEntries.count == 1 {
            return readmeEntries[0]
        }

        // 3. Fallback: Check for any single .md file
        let mdEntries = fileEntries.filter { $0.name.lowercased().hasSuffix(".md") }
        if mdEntries.count == 1 {
            return mdEntries[0]
        } else if mdEntries.count > 1 {
            throw SkillPackageError.ambiguousSkillEntries(mdEntries.map(\.name))
        }

        throw SkillPackageError.noMarkdownFound
    }

    static func extractText(from entry: ZipEntryRecord) throws -> String {
        let decompressedData: Data
        if entry.compressionMethod == 0 {
            decompressedData = entry.rawCompressedData
        } else if entry.compressionMethod == 8 {
            guard let decomp = inflate(entry.rawCompressedData, uncompressedSize: Int(entry.uncompressedSize)) else {
                throw SkillPackageError.decompressionFailed(entry.name)
            }
            decompressedData = decomp
        } else {
            throw SkillPackageError.decompressionFailed(entry.name)
        }

        guard let string = String(data: decompressedData, encoding: .utf8) ?? String(data: decompressedData, encoding: .isoLatin1) else {
            throw SkillPackageError.decompressionFailed(entry.name)
        }
        return string
    }

    // MARK: - Rebuilding & Preserving Package Archive

    static func rebuildArchive(originalEntries: [ZipEntryRecord], targetEntryPath: String, updatedMarkdown: String) throws -> Data {
        let newUncompressedData = Data(updatedMarkdown.utf8)
        let newCrc = crc32Checksum(newUncompressedData)

        var outData = Data()
        var centralDirectory = Data()

        for entry in originalEntries {
            if entry.name.contains("..") || entry.name.hasPrefix("/") || entry.name.contains("\0") {
                throw SkillPackageError.pathTraversalDetected(entry.name)
            }
            let isTarget = (entry.name == targetEntryPath)
            let compData: Data
            let uncompSize: UInt32
            let compSize: UInt32
            let crc: UInt32
            let method: UInt16

            if isTarget {
                uncompSize = UInt32(newUncompressedData.count)
                crc = newCrc
                if entry.compressionMethod == 8 {
                    guard let deflated = deflate(newUncompressedData) else {
                        throw SkillPackageError.compressionFailed(entry.name)
                    }
                    compData = deflated
                    compSize = UInt32(deflated.count)
                    method = 8
                } else {
                    compData = newUncompressedData
                    compSize = UInt32(newUncompressedData.count)
                    method = 0
                }
            } else {
                // Byte-for-byte preservation of all unrelated archive entries
                compData = entry.rawCompressedData
                uncompSize = entry.uncompressedSize
                compSize = entry.compressedSize
                crc = entry.crc32
                method = entry.compressionMethod
            }

            let nameBytes = Data(entry.name.utf8)
            let localOffset = UInt32(outData.count)

            // Local File Header
            outData.append(contentsOf: [0x50, 0x4B, 0x03, 0x04])
            outData.append(le16(entry.versionNeeded == 0 ? 20 : entry.versionNeeded))
            outData.append(le16(entry.generalPurposeFlag | (1 << 11))) // UTF-8
            outData.append(le16(method))
            outData.append(le16(entry.lastModTime))
            outData.append(le16(entry.lastModDate == 0 ? 0x21 : entry.lastModDate))
            outData.append(le32(crc))
            outData.append(le32(compSize))
            outData.append(le32(uncompSize))
            outData.append(le16(UInt16(nameBytes.count)))
            outData.append(le16(UInt16(entry.extraField.count)))
            outData.append(nameBytes)
            outData.append(entry.extraField)
            outData.append(compData)

            // Central Directory Entry
            centralDirectory.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])
            centralDirectory.append(le16(entry.versionMadeBy == 0 ? 20 : entry.versionMadeBy))
            centralDirectory.append(le16(entry.versionNeeded == 0 ? 20 : entry.versionNeeded))
            centralDirectory.append(le16(entry.generalPurposeFlag | (1 << 11)))
            centralDirectory.append(le16(method))
            centralDirectory.append(le16(entry.lastModTime))
            centralDirectory.append(le16(entry.lastModDate == 0 ? 0x21 : entry.lastModDate))
            centralDirectory.append(le32(crc))
            centralDirectory.append(le32(compSize))
            centralDirectory.append(le32(uncompSize))
            centralDirectory.append(le16(UInt16(nameBytes.count)))
            centralDirectory.append(le16(UInt16(entry.extraField.count)))
            centralDirectory.append(le16(UInt16(entry.fileComment.count)))
            centralDirectory.append(le16(entry.diskNumberStart))
            centralDirectory.append(le16(entry.internalFileAttributes))
            centralDirectory.append(le32(entry.externalFileAttributes))
            centralDirectory.append(le32(localOffset))
            centralDirectory.append(nameBytes)
            centralDirectory.append(entry.extraField)
            centralDirectory.append(entry.fileComment)
        }

        let cdOffsetFinal = UInt32(outData.count)
        let cdSizeFinal = UInt32(centralDirectory.count)
        outData.append(centralDirectory)

        // End of Central Directory
        outData.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])
        outData.append(le16(0))
        outData.append(le16(0))
        outData.append(le16(UInt16(originalEntries.count)))
        outData.append(le16(UInt16(originalEntries.count)))
        outData.append(le32(cdSizeFinal))
        outData.append(le32(cdOffsetFinal))
        outData.append(le16(0))

        return outData
    }

    // MARK: - Compression Helpers (zlib)

    private static func inflate(_ data: Data, uncompressedSize: Int) -> Data? {
        guard uncompressedSize > 0 else { return Data() }
        var stream = z_stream()
        let initStatus = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else { return nil }

        var decompressed = Data(count: uncompressedSize)
        var status = Z_OK
        data.withUnsafeBytes { inBytes in
            decompressed.withUnsafeMutableBytes { outBytes in
                stream.next_in = UnsafeMutablePointer(mutating: inBytes.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(data.count)
                stream.next_out = outBytes.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(uncompressedSize)
                status = zlib.inflate(&stream, Z_FINISH)
            }
        }
        inflateEnd(&stream)
        guard status == Z_STREAM_END || status == Z_OK else { return nil }
        return decompressed
    }

    private static func deflate(_ data: Data) -> Data? {
        guard !data.isEmpty else { return Data() }
        var stream = z_stream()
        let initStatus = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else { return nil }

        let maxOutputSize = data.count + 1024 + (data.count / 10)
        var output = Data(count: maxOutputSize)
        var compressedLength = 0

        data.withUnsafeBytes { inBytes in
            output.withUnsafeMutableBytes { outBytes in
                stream.next_in = UnsafeMutablePointer(mutating: inBytes.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(data.count)
                stream.next_out = outBytes.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(maxOutputSize)
                zlib.deflate(&stream, Z_FINISH)
                compressedLength = Int(stream.total_out)
            }
        }
        deflateEnd(&stream)
        return output.prefix(compressedLength)
    }

    private static func crc32Checksum(_ data: Data) -> UInt32 {
        guard !data.isEmpty else { return 0 }
        return UInt32(data.withUnsafeBytes { rawBytes in
            crc32(0, rawBytes.bindMemory(to: Bytef.self).baseAddress, uInt(data.count))
        })
    }

    private static func le16(_ v: UInt16) -> Data {
        var x = v.littleEndian
        return Data(bytes: &x, count: 2)
    }

    private static func le32(_ v: UInt32) -> Data {
        var x = v.littleEndian
        return Data(bytes: &x, count: 4)
    }
}
