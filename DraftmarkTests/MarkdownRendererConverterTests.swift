import XCTest
@testable import Draftmark

final class MarkdownRendererConverterTests: XCTestCase {
    func testExposesFormatAndCss() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        XCTAssertEqual(converter.title, "Title")
        XCTAssertEqual(converter.format, "gfm")
        XCTAssertEqual(converter.css, "style.css")
        XCTAssertNil(converter.header)
    }

    func testRendersMarkdownContainingApostrophesWithoutShellEscaping() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "# Bob's Notes")

        XCTAssertTrue(converter.html.contains("Bob"))
        XCTAssertTrue(converter.html.contains("Notes"))
        XCTAssertFalse(converter.html.contains("unexpected EOF"))
    }

    func testRawHTMLIsNotRenderedAsExecutableMarkup() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "<script>alert('x')</script>\n\n<img src=\"https://example.com/tracker.png\">")

        XCTAssertFalse(converter.html.contains("<script>"))
        XCTAssertFalse(converter.html.contains("<img src=\"https://example.com/tracker.png\">"))
        XCTAssertTrue(converter.html.contains("&lt;script&gt;") || converter.html.contains("alert"))
    }

    func testDangerousMarkdownLinksAreRenderedWithoutHref() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "[Run JavaScript](javascript:alert(1))")

        XCTAssertFalse(converter.html.contains("href=\"javascript:"))
        XCTAssertTrue(converter.html.contains("Run JavaScript"))
    }

    func testRemoteMarkdownImagesAreNotRenderedAsImages() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "![Tracker](https://example.com/tracker.png)")

        XCTAssertFalse(converter.html.contains("<img"))
        XCTAssertFalse(converter.html.contains("https://example.com/tracker.png"))
        XCTAssertTrue(converter.html.contains("Tracker"))
    }

    func testAbsoluteFileMarkdownImagesAreNotRenderedAsImages() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "![Secret](file:///Users/random/Documents/secret.png)")

        XCTAssertFalse(converter.html.contains("<img"))
        XCTAssertFalse(converter.html.contains("file:///Users/random/Documents/secret.png"))
        XCTAssertTrue(converter.html.contains("Secret"))
    }

    func testRelativeMarkdownImagesAreRenderedAsImages() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "![Diagram](diagram.png \"Architecture\")")

        XCTAssertTrue(converter.html.contains("<img src=\"diagram.png\""))
        XCTAssertTrue(converter.html.contains("alt=\"Diagram\""))
        XCTAssertTrue(converter.html.contains("title=\"Architecture\""))
    }

    func testInlineCodeLineBreaksAndInlineHTMLAreRenderedSafely() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")

        converter.setContent(with: "`let value = 1`\n\nfirst\\\nsecond\n\n<span>raw</span>")

        XCTAssertTrue(converter.html.contains("<code>let value = 1</code>"))
        XCTAssertTrue(converter.html.contains("first<br />"))
        XCTAssertTrue(converter.html.contains("&lt;span&gt;raw&lt;/span&gt;"))
    }

    func testSymbolLinksRenderAsEscapedCode() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: nil)

        converter.setContent(with: "See ``MarkdownHTMLRenderer``.")

        XCTAssertTrue(converter.html.contains("<code>MarkdownHTMLRenderer</code>"))
    }

    func testInlineFormattingMatchesMarkdownSyntax() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")
        let expectations: [TextConverterFormat: String] = [
            .bold: "**text**",
            .italic: "*text*",
            .strikeThrough: "~~text~~",
            .link: "[text](url)"
        ]

        for (format, expected) in expectations {
            XCTAssertEqual(converter.formattedString(with: "text", format: format), expected)
        }
    }

    func testBlockFormattingMatchesMarkdownSyntax() {
        let converter = MarkdownRendererConverter(title: "Title", format: "gfm", header: nil, css: "style.css")
        let expectations: [TextConverterFormat: String] = [
            .code: "```\none\ntwo\n```",
            .quote: "> one\n> two\n",
            .listBulleted: "- one\n- two\n",
            .listNumbered: "1. one\n1. two\n"
        ]

        for (format, expected) in expectations {
            XCTAssertEqual(converter.formattedString(with: "one\ntwo", format: format), expected)
        }
    }
}
