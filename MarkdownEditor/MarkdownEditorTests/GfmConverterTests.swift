import XCTest
@testable import MarkdownEditorLite

final class GfmConverterTests: XCTestCase {
    func testConverterProperties() {
        let converter = GfmConverter()

        XCTAssertEqual(converter.title, "GitHub Flavored Markdown")
        XCTAssertEqual(converter.format, "gfm")
        XCTAssertEqual(converter.header, "gfm-header.txt")
        XCTAssertEqual(converter.css, "gfm.css")
    }

    func testRendersMarkdownWithGfmFormat() {
        let converter = GfmConverter()
        converter.setContent(with: "# Title")

        XCTAssertTrue(converter.html.contains("<h1>"))
        XCTAssertTrue(converter.html.contains("Title"))
    }

    func testAppliesGfmFormatting() {
        let converter = GfmConverter()

        let result = converter.formattedString(with: "text", format: .bold)
        XCTAssertEqual(result, "**text**")
    }
}