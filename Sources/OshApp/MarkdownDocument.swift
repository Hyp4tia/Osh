import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    struct PackageContext {
        let internalPath: String
        let originalEntries: [ZipEntryRecord]
    }

    var text: String
    var packageContext: PackageContext?

    init(text: String = "", packageContext: PackageContext? = nil) {
        self.text = text
        self.packageContext = packageContext
    }

    static var readableContentTypes: [UTType] {
        var types: [UTType] = [.plainText]
        let skillTypes = UTType.types(tag: "skill", tagClass: .filenameExtension, conformingTo: nil)
        for st in skillTypes {
            if !types.contains(st) {
                types.insert(st, at: 0)
            }
        }
        if let skill = UTType(filenameExtension: "skill"), !types.contains(skill) {
            types.insert(skill, at: 0)
        }
        if let oshSkill = UTType("com.osh.skill"), !types.contains(oshSkill) {
            types.insert(oshSkill, at: 0)
        }
        if let codexSkill = UTType("com.openai.codex.skill"), !types.contains(codexSkill) {
            types.insert(codexSkill, at: 0)
        }
        if let md = UTType(filenameExtension: "md"), !types.contains(md) {
            types.insert(md, at: 0)
        }
        return types
    }

    static var writableContentTypes: [UTType] {
        readableContentTypes
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        if SkillPackage.isZipPackage(data: data) {
            let extracted = try SkillPackage.extractPrimaryMarkdown(from: data)
            self.text = extracted.text
            self.packageContext = PackageContext(
                internalPath: extracted.internalPath,
                originalEntries: extracted.entries
            )
        } else {
            guard let string = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            self.text = string
            self.packageContext = nil
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let outputData: Data
        if let context = packageContext {
            outputData = try SkillPackage.rebuildArchive(
                originalEntries: context.originalEntries,
                targetEntryPath: context.internalPath,
                updatedMarkdown: text
            )
        } else {
            outputData = text.data(using: .utf8) ?? Data()
        }
        return FileWrapper(regularFileWithContents: outputData)
    }
}
