import XCTest
@testable import MarkdownEditorLite

final class MarkdownEditorTests: XCTestCase {
    private var markdownConverters: [TextConverter] {
        [
            MarkdownConverter(),
            GfmConverter(),
            StrictMarkdownConverter()
        ]
    }

    func testInlineMarkdownFormatting() {
        let expectations: [TextConverterFormat: String] = [
            .bold: "**text**",
            .italic: "*text*",
            .strikeThrough: "~~text~~",
            .link: "[text](url)"
        ]

        for converter in markdownConverters {
            for (format, expected) in expectations {
                XCTAssertEqual(converter.formattedString(with: "text", format: format), expected, converter.title)
            }
        }
    }

    func testBlockMarkdownFormatting() {
        let expectations: [TextConverterFormat: String] = [
            .code: "```\none\ntwo\n```",
            .quote: "> one\n> two\n",
            .listBulleted: "- one\n- two\n",
            .listNumbered: "1. one\n1. two\n"
        ]

        for converter in markdownConverters {
            for (format, expected) in expectations {
                XCTAssertEqual(converter.formattedString(with: "one\ntwo", format: format), expected, converter.title)
            }
        }
    }

    func testBaseTextConverterDoesNotFormatText() {
        let converter = TextConverter(title: "Text")

        XCTAssertEqual(converter.formattedString(with: "text", format: .bold), "text")
    }

    func testBaseTextConverterDefaultProperties() {
        let converter = TextConverter(title: "Text")

        XCTAssertEqual(converter.format, "markdown")
        XCTAssertNil(converter.css)
        XCTAssertNil(converter.script)
        XCTAssertTrue(converter.html.contains("<html lang=\"ja\">"))

        converter.setContent(with: "# Title")

        XCTAssertTrue(converter.html.contains("<body></body>"))
    }
}
