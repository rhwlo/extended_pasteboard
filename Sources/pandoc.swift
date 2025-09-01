import Foundation
import Subprocess

enum PandocDestination: String {
    case ANSI = "ansi"
    case AsciiDoc = "asciidoc"
    case AsciiDocPy = "asciidoc_legacy"
    case chunkedHTML = "chunkedhtml"
    case CommonMark = "commonmark"
    case CommonMarkExtended = "commonmark_x"
    case ConTeXt = "context"
    case CSL_JSON = "csljson"
    case CSV = "csv"
    case Djot = "djot"
    case DocBook4 = "docbook"
    case DocBook5 = "docbook5"
    case docx = "docx"
    case DokuWiki = "dokuwiki"
    case DZSlides = "dzslides"
    case EPUB2 = "epub2"
    case EPUB3 = "epub3"
    case FictionBook2 = "fb2"
    case GitHubMarkdown = "gfm"
    case Haddock = "haddock"
    case Haskell = "native"
    case HTML4 = "html4"
    case HTML5 = "html5"
    case ICML = "icml"
    case JATSArchiving = "jats_archiving"
    case JATSArticleAuthoring = "jats_articleauthoring"
    case JATSPublishing = "jats_publishing"
    case Jira = "jira"
    case JSON = "json"
    case Jupyter = "ipynb"
    case LaTeX = "latex"
    case man = "man"
    case Markdown = "markdown"
    case MarkdownPHPExtra = "markdown_phpextra"
    case MarkdownStrict = "markdown_strict"
    case Markua = "markua"
    case MediaWiki = "mediawiki"
    case MultiMarkdown = "markdown_mmd"
    case Muse = "muse"
    case odt = "odt"
    case opendocument = "opendocument"
    case OPML = "opml"
    case orgMode = "org"
    case PDF = "pdf"
    case plain = "plain"
    case pptx = "pptx"
    case reStructuredText = "rst"
    case roffMS = "ms"
    case rtf = "rtf"
    case s5Slides = "s5"
    case Slideous = "slideous"
    case Slidy = "slidy"
    case Texinfo = "texinfo"
    case Textile = "textile"
    case typst = "typst"
    case XWiki = "xwiki"
    case ZimWiki = "zimwiki"
    case BibTeX = "bibtex"
    case BibLaTeX = "biblatex"
}

enum PandocSource: String {
    case BibLaTeX = "biblatex"
    case BibTeX = "bibtex"
    case CommonMark = "commonmark"
    case CommonMarkExtended = "commonmark_x"
    case Creole = "creole"
    case CSL_JSON = "csljson"
    case CSV = "csv"
    case Djot = "djot"
    case DocBook4 = "docbook"
    case docx = "docx"
    case DokuWiki = "dokuwiki"
    case EndNoteXML = "endnotexml"
    case EPUB = "epub"
    case FictionBook2 = "fb2"
    case GitHubMarkdown = "gfm"
    case Haddock = "haddock"
    case Haskell = "native"
    case HTML = "html"
    case JATS = "jats"
    case Jira = "jira"
    case JSON = "json"
    case Jupyter = "ipynb"
    case LaTeX = "latex"
    case man = "man"
    case Markdown = "markdown"
    case MarkdownPHPExtra = "markdown_phpextra"
    case MarkdownStrict = "markdown_strict"
    case mdoc = "mdoc"
    case MediaWiki = "mediawiki"
    case MultiMarkdown = "markdown_mmd"
    case Muse = "muse"
    case odt = "odt"
    case OPML = "opml"
    case orgMode = "org"
    case perlPOD = "pod"
    case reStructuredText = "rst"
    case RIS = "ris"
    case rtf = "rtf"
    case Textile = "textile"
    case TikiWiki = "tikiwiki"
    case TSV = "tsv"
    case TWiki = "twiki"
    case txt2tags = "t2t"
    case typst = "typst"
    case Vimwiki = "vimwiki"
}

enum PandocFlag: String {
    case numberSections = "--number-sections"
    case onlyASCII = "--ascii"
    case preserveTabs = "--preserve-tabs"
    case selfContained = "--self-contained"
    case standalone = "--standalone"
    case stripComments = "--strip-comments"
    case tableOfContents = "--table-of-contents"
}

enum PandocOption: String {
    case shiftHeadingLevelBy = "--shift-heading-level-by"
    case tabStop = "--tab-stop"
    case template = "--template"
}

enum PandocError: Error {
    case NonZeroExit(code: Subprocess.TerminationStatus.Code, stderr: Data)
    case Other(_ error: Error)
}

func runPandoc(
    _ inputData: Data,
    from fromFormat: PandocSource,
    to toFormat: PandocDestination,
    flags: Set<PandocFlag> = Set(),
    options: [PandocOption: String] = [:],
) async -> Result<Data, PandocError> {
    let pandocPath = Executable.path("/opt/homebrew/bin/pandoc")

    let args: [String] = [
        ["--from", fromFormat.rawValue, "--to", toFormat.rawValue],
        flags.map({ $0.rawValue }),
        options.flatMap({ [$0.rawValue, $1] }),
    ].joined().map({ $0 })
    do {
        let result = try await run(
            pandocPath, arguments: .init(args), input: .data(inputData), output: .data(limit: .max),
            error: .data(limit: .max))
        switch result.terminationStatus {
        case .exited(0):
            return .success(result.standardOutput)
        case .exited(let code), .unhandledException(let code):
            return .failure(PandocError.NonZeroExit(code: code, stderr: result.standardError))
        }
    } catch {
        return .failure(.Other(error))
    }
}
