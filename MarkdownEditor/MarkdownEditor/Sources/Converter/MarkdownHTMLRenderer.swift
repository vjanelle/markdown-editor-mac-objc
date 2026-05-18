//
//  MarkdownHTMLRenderer.swift
//  MarkdownEditor
//

import Foundation
import Markdown

@objcMembers
@objc(MarkdownHTMLRenderer)
public final class MarkdownHTMLRenderer: NSObject {
    @objc(htmlStringFromMarkdown:css:header:)
    public func htmlString(fromMarkdown markdown: String, css: String?, header: String?) -> String {
        let document = Document(parsing: markdown)
        var renderer = SafeHTMLRenderer()
        let body = renderer.visit(document)
        let cssLink = css.map { "<link rel=\"stylesheet\" href=\"\(Self.escapeAttribute($0))\" />\n" } ?? ""
        let headerHTML = header ?? ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
        \(cssLink)\(headerHTML)
        </head>
        <body>
        \(body)</body>
        </html>
        """
    }

    private static func escapeAttribute(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private struct SafeHTMLRenderer: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitDocument(_ document: Document) -> String {
        defaultVisit(document)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(defaultVisit(blockQuote))</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let languageClass = codeBlock.language.map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
        return "<pre><code\(languageClass)>\(escapeText(codeBlock.code))</code></pre>\n"
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        "<h\(heading.level)>\(defaultVisit(heading))</h\(heading.level)>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr />\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        escapeText(html.rawHTML)
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        "<li>\(defaultVisit(listItem))</li>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let start = orderedList.startIndex == 1 ? "" : " start=\"\(orderedList.startIndex)\""
        return "<ol\(start)>\n\(defaultVisit(orderedList))</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        "<ul>\n\(defaultVisit(unorderedList))</ul>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(defaultVisit(paragraph))</p>\n"
    }

    mutating func visitTable(_ table: Table) -> String {
        "<table>\n\(defaultVisit(table))</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        "<thead>\n<tr>\n\(defaultVisit(tableHead))</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        tableBody.isEmpty ? "" : "<tbody>\n\(defaultVisit(tableBody))</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        "<tr>\n\(defaultVisit(tableRow))</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        "<td>\(defaultVisit(tableCell))</td>\n"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeText(inlineCode.code))</code>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(defaultVisit(emphasis))</em>"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(defaultVisit(strong))</strong>"
    }

    mutating func visitImage(_ image: Image) -> String {
        guard let source = image.source, isRelativeLocalResource(source) else {
            return defaultVisit(image)
        }

        let title = image.title.map { " title=\"\(escapeAttribute($0))\"" } ?? ""
        let alt = escapeAttribute(defaultVisit(image))
        return "<img src=\"\(escapeAttribute(source))\" alt=\"\(alt)\"\(title) />"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        escapeText(inlineHTML.rawHTML)
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br />\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLink(_ link: Link) -> String {
        let label = defaultVisit(link)
        guard let destination = link.destination, isAllowedLink(destination) else {
            return label
        }

        return "<a href=\"\(escapeAttribute(destination))\">\(label)</a>"
    }

    mutating func visitText(_ text: Text) -> String {
        escapeText(text.string)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(defaultVisit(strikethrough))</del>"
    }

    mutating func visitSymbolLink(_ symbolLink: SymbolLink) -> String {
        symbolLink.destination.map { "<code>\(escapeText($0))</code>" } ?? ""
    }

    private func isAllowedLink(_ destination: String) -> Bool {
        guard let components = URLComponents(string: destination), let scheme = components.scheme?.lowercased() else {
            return isLocalResource(destination)
        }

        return scheme == "http" || scheme == "https" || scheme == "file"
    }

    private func isLocalResource(_ source: String) -> Bool {
        guard !source.hasPrefix("//"),
              let components = URLComponents(string: source),
              let scheme = components.scheme?.lowercased()
        else {
            return !source.hasPrefix("//")
        }

        return scheme == "file"
    }

    private func isRelativeLocalResource(_ source: String) -> Bool {
        guard !source.hasPrefix("/"), !source.hasPrefix("//") else {
            return false
        }

        guard let components = URLComponents(string: source),
              let scheme = components.scheme?.lowercased()
        else {
            return true
        }

        return scheme.isEmpty
    }

    private func escapeText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func escapeAttribute(_ value: String) -> String {
        escapeText(value)
    }
}
