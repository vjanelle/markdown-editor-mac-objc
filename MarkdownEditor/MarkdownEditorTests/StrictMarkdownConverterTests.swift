import XCTest
@testable import MarkdownEditorLite

final class StrictMarkdownConverterTests: XCTestCase {
    func testConverterProperties() {
        let converter = StrictMarkdownConverter()

        XCTAssertEqual(converter.title, "Strict Markdown")
        XCTAssertEqual(converter.format, "markdown_strict")
        XCTAssertNil(converter.header)
        XCTAssertEqual(converter.css, "markdown.css")
    }

    func testRendersMarkdownWithStrictFormat() {
        let converter = StrictMarkdownConverter()
        converter.setContent(with: "# Title")

        XCTAssertTrue(converter.html.contains("<h1>"))
        XCTAssertTrue(converter.html.contains("Title"))
    }

    func testAppliesStrictFormatting() {
        let converter = StrictMarkdownConverter()

        let result = converter.formattedString(with: "text", format: .bold)
        XCTAssertEqual(result, "**text**")
    }
}