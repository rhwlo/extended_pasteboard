import ArgumentParser
import AsyncAlgorithms
import Cocoa

let pasteboardNames: [String: NSPasteboard.Name] = [
    "drag": .drag,
    "find": .find,
    "font": .font,
    "general": .general,
    "ruler": .ruler,
]

let pasteboardTypes: [String: NSPasteboard.PasteboardType] = [
    "URL": .URL,
    "color": .color,
    "fileContents": .fileContents,
    "fileURL": .fileURL,
    "findPanelSearchOptions": .findPanelSearchOptions,
    "font": .font,
    "html": .html,
    "multipleTextSelection": .multipleTextSelection,
    "pdf": .pdf,
    "png": .png,
    "rtf": .rtf,
    "rtfd": .rtfd,
    "ruler": .ruler,
    "sound": .sound,
    "string": .string,
    "tabularText": .tabularText,
    "textFinderOptions": .textFinderOptions,
    "tiff": .tiff,
]

enum PasteboardAction {
    case copy
    case copyMarkdown
    case list
    case paste
}

let pasteboardActions: [String: PasteboardAction] = [
    "copy": .copy,
    "copy-markdown": .copyMarkdown,
    "list": .list,
    "paste": .paste,
]

func print(_ str: String, end: String = "\n") {
    FileHandle.standardOutput.write("\(str)\(end)".data(using: .utf8) ?? Data())
}

func print(_ data: Data, end: Data = Data([0x0A] as [UInt8])) {
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(end)
}

func error(_ str: String, end: String = "\n") {
    FileHandle.standardError.write("\(str)\(end)".data(using: .utf8) ?? Data())
}

func fail(_ str: String, end: String = "\n", code: Int32 = 1) -> Never {
    error(str, end: end)
    exit(code)
}

func copyViaPandoc(
    _ pasteboard: NSPasteboard, from source: PandocSource,
    targets: [NSPasteboard.PasteboardType: PandocDestination]
) async throws {
    guard
        let inputData = try FileHandle.standardInput.readToEnd()
    else {
        return
    }
    let outputs = await Dictionary(
        uniqueKeysWithValues:
            targets.async.compactMap({
                (key, value) in
                switch await runPandoc(inputData, from: source, to: value) {
                case .success(let data):
                    (key, data)
                default:
                    nil
                }
            }))
    guard outputs.count != 0 else {
        return
    }
    pasteboard.clearContents()
    outputs.forEach({
        (pasteboardType, data) in
        pasteboard.setData(data, forType: pasteboardType)
    })
}

func handleCopyMarkdown(_ pasteboard: NSPasteboard) async {
    do {
        try await copyViaPandoc(
            pasteboard, from: .Markdown, targets: [.html: .HTML5, .string: .plain])
    } catch {
        return
    }
}

@main
struct ExtendedPasteboard: AsyncParsableCommand {
    @Option(
        wrappedValue: .string,
        help:
            "pasteboard format (default 'string'): \(pasteboardTypes.keys.joined(separator: ", "))",
        transform: { pasteboardTypes[$0]! }
    )
    var format: NSPasteboard.PasteboardType

    @Option(
        wrappedValue: .general,
        help:
            "pasteboard name (default 'general'): \(pasteboardNames.keys.joined(separator: ", "))",
        transform: { pasteboardNames[$0]! }
    )
    var name: NSPasteboard.Name

    @Argument(
        help: "action: \(pasteboardActions.keys.joined(separator: ", "))",
        transform: { pasteboardActions[$0]! }
    )
    var action: PasteboardAction

    func run() async {
        let pasteboard = NSPasteboard(name: name)
        switch action {
        case .copyMarkdown:
            await handleCopyMarkdown(pasteboard)
        case .list:
            for (key, value) in pasteboardTypes {
                if let data = pasteboard.data(forType: value) {
                    let byte_s = data.count == 1 ? "byte" : "bytes"
                    print(
                        "Pasteboard '\(name.rawValue)' has \(data.count) \(byte_s) of '\(key)' data"
                    )
                }
            }
        case .copy:
            pasteboard.clearContents()
            if !pasteboard.setData(
                FileHandle.standardInput.readDataToEndOfFile(), forType: format)
            {
                fail("Failed to set data on pasteboard")
            }
        case .paste:
            guard let pasteboardData = pasteboard.data(forType: format) else {
                // No pasteboard data to print
                return
            }
            switch format {
            case .pdf, .tiff, .png:
                print(pasteboardData.base64EncodedData(), end: Data())
            default:
                print(pasteboardData, end: Data())
            }
        }
    }
}
