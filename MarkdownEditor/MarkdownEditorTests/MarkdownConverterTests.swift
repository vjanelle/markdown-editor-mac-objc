import XCTest
@testable import MarkdownEditorLite

final class MarkdownConverterTests: XCTestCase {
    func testConverterProperties() {
        let converter = MarkdownConverter()

        XCTAssertEqual(converter.title, "Markdown")
        XCTAssertEqual(converter.format, "markdown")
        XCTAssertEqual(converter.header, "markdown-header.txt")
        XCTAssertEqual(converter.css, "markdown.css")
    }

    func testRendersMarkdownWithStandardFormat() {
        let converter = MarkdownConverter()
        converter.setContent(with: "# Title")

        XCTAssertTrue(converter.html.contains("<h1>"))
        XCTAssertTrue(converter.html.contains("Title"))
    }

    func testAppliesStandardFormatting() {
        let converter = MarkdownConverter()

        let result = converter.formattedString(with: "text", format: .bold)
        XCTAssertEqual(result, "**text**")
    }
}