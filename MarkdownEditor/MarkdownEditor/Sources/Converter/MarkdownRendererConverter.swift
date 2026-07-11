import Foundation

@objc(MarkdownRendererConverter)
class MarkdownRendererConverter: TextConverter {
    @objc let header: String?

    private let rendererFormat: String
    private let rendererCSS: String?
    private var renderedHTML = "<html><body></body></html>"

    @objc(initWithTitle:format:header:css:)
    init(title: String, format: String, header: String?, css: String?) {
        self.rendererFormat = format
        self.header = header
        self.rendererCSS = css
        super.init(title: title)
    }

    @objc override var format: String {
        rendererFormat
    }

    @objc override var css: String? {
        rendererCSS
    }

    @objc override var html: String {
        renderedHTML
    }

    @objc override func formattedString(with string: String, format: TextConverterFormat) -> String {
        Self.markdownFormattedString(string, format: format)
    }

    @objc override func setContent(with string: String) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let headerHTML: String?
        if let header,
           let path = Bundle.main.path(forResource: header, ofType: "") {
            headerHTML = try? String(contentsOfFile: path, encoding: .utf8)
        } else {
            headerHTML = nil
        }

        let renderer = MarkdownHTMLRenderer()
        renderedHTML = renderer.htmlString(fromMarkdown: string, css: rendererCSS, header: headerHTML)
        logDebug("*** HTML ***")
        logDebug(renderedHTML)
    }

    static func markdownFormattedString(_ string: String, format: TextConverterFormat) -> String {
        switch format {
        case .bold:
            return "**\(string)**"
        case .italic:
            return "*\(string)*"
        case .strikeThrough:
            return "~~\(string)~~"
        case .code:
            return "```\n\(string)\n```"
        case .link:
            return "[\(string)](url)"
        case .quote:
            return string.components(separatedBy: "\n").map { "> \($0)" }.joined(separator: "\n") + "\n"
        case .listBulleted:
            return string.components(separatedBy: "\n").map { "- \($0)" }.joined(separator: "\n") + "\n"
        case .listNumbered:
            return string.components(separatedBy: "\n").map { "1. \($0)" }.joined(separator: "\n") + "\n"
        }
    }
}

@objc(MarkdownConverter)
class MarkdownConverter: MarkdownRendererConverter {
    override init(title: String, format: String, header: String?, css: String?) {
        super.init(title: title, format: format, header: header, css: css)
    }

    @objc init() {
        super.init(title: "Markdown", format: "markdown", header: "markdown-header.txt", css: "markdown.css")
    }
}

@objc(GfmConverter)
class GfmConverter: MarkdownConverter {
    @objc override init() {
        super.init(title: "GitHub Flavored Markdown", format: "gfm", header: "gfm-header.txt", css: "gfm.css")
    }
}

@objc(StrictMarkdownConverter)
class StrictMarkdownConverter: MarkdownConverter {
    @objc override init() {
        super.init(title: "Strict Markdown", format: "markdown_strict", header: nil, css: "markdown.css")
    }
}
