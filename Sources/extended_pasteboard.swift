import ArgumentParser
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

@main
struct ExtendedPasteboard: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Extended access for the Mac OS pasteboards",
        subcommands: [XPBCopy.self, XPBList.self, XPBPaste.self]
    )

    struct Options: ParsableArguments {
        @Option(
            wrappedValue: .general,
            help:
                "pasteboard name (default 'general'): \(pasteboardNames.keys.joined(separator: ", "))",
            transform: {
                if let name = pasteboardNames[$0] {
                    return name
                } else {
                    fatalError("invalid pasteboard name: \($0)")
                }
            }
        )
        var name: NSPasteboard.Name
    }
}

func transformTypePathArgs(_ s: String) throws -> (NSPasteboard.PasteboardType, String) {
    guard let match = try /^([^:]+):(.+)$/.wholeMatch(in: s) else {
        fatalError("Couldn't parse format:type argument \"\(s)\"")
    }
    guard let pasteboardType = pasteboardTypes[String(match.1)] else {
        fatalError("Invalid pasteboard type \"\(match.1)\"")
    }
    return (pasteboardType, String(match.2))
}

extension ExtendedPasteboard {
    struct XPBCopy: ParsableCommand {
        @OptionGroup var options: ExtendedPasteboard.Options
        @Option(
            name: .customLong("stdin-format"),
            help:
                "pasteboard format from stdin: \(pasteboardTypes.keys.joined(separator: ", "))",
            transform: {
                if let format = pasteboardTypes[$0] {
                    return format
                } else {
                    fatalError("invalid pasteboard format: \($0)")
                }
            }
        )
        var stdinFormat: NSPasteboard.PasteboardType?

        @Argument(
            help:
                "format and path for pastebin, specified format:path. Valid formats are \(pasteboardTypes.keys.joined(separator: ", "))",
            transform: transformTypePathArgs
        )
        var formatsAndPaths: [(NSPasteboard.PasteboardType, String)]

        func run() {
            let pasteboard = NSPasteboard(name: options.name)
            let formatPathContent: [(NSPasteboard.PasteboardType, String, Data?)] =
                stdinFormat != nil
                ? [(stdinFormat!, "standard input", FileHandle.standardInput.readDataToEndOfFile())]
                : formatsAndPaths.map({
                    (format, path) in
                    (
                        format, path,
                        FileHandle(forReadingAtPath: path).map({ $0.readDataToEndOfFile() })
                    )
                }
                )

            let failed = formatPathContent.filter({ $0.2 == nil })
            if failed.count > 0 {
                fatalError(
                    "Failed to read contents for: \(failed.map({"\($0.1) (\($0.0.rawValue))"}).joined(separator: ", "))"
                )
            }
            pasteboard.clearContents()
            formatPathContent.forEach({
                (format, _, data) in
                if !pasteboard.setData(data!, forType: format) {
                    fatalError("Failed to set pasteboard contents for type \"\(format.rawValue)\"")
                }
            })
        }
    }

    struct XPBPaste: ParsableCommand {
        @OptionGroup var options: ExtendedPasteboard.Options
        @Option(
            wrappedValue: .string,
            help:
                "pasteboard format (default 'string'): \(pasteboardTypes.keys.joined(separator: ", "))",
            transform: {
                if let format = pasteboardTypes[$0] {
                    return format
                } else {
                    fatalError("invalid pasteboard format: \($0)")
                }
            }
        )
        var format: NSPasteboard.PasteboardType

        func run() {
            let pasteboard = NSPasteboard(name: options.name)
            guard let pasteboardData = pasteboard.data(forType: format) else {
                print(
                    "No data of type \"\(format.rawValue)\" for pasteboard \"\(options.name.rawValue)\""
                )
                return
            }
            FileHandle.standardOutput.write(pasteboardData)
        }
    }

    struct XPBList: ParsableCommand {
        @OptionGroup var options: ExtendedPasteboard.Options
        func run() {
            let pasteboard = NSPasteboard(name: options.name)
            for (key, value) in pasteboardTypes {
                if let data = pasteboard.data(forType: value) {
                    let byte_s = data.count == 1 ? "byte" : "bytes"
                    print(
                        "Pasteboard '\(options.name.rawValue)' has \(data.count) \(byte_s) of '\(key)' data"
                    )
                }
            }
        }
    }
}
