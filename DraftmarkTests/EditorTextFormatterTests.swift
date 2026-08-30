import XCTest
@testable import Draftmark

final class EditorTextFormatterTests: XCTestCase {
    func testReturnsOriginalTextWhenRangeIsEmpty() {
        let formatter = EditorTextFormatter(converter: MarkdownConverter())

        let result = formatter.stringByApplyingFormat(.bold, toText: "hello", range: NSRange(location: 0, length: 0), selectedRange: nil)

        XCTAssertEqual(result, "hello")
    }

    func testAppliesFormatToSelectedRange() {
        let formatter = EditorTextFormatter(converter: MarkdownConverter())
        var selectedRange = NSRange(location: NSNotFound, length: 0)

        let result = formatter.stringByApplyingFormat(.bold, toText: "hello world", range: NSRange(location: 6, length: 5), selectedRange: &selectedRange)

        XCTAssertEqual(result, "hello **world**")
        XCTAssertEqual(selectedRange.location, 6)
        XCTAssertEqual(selectedRange.length, 9)
    }

    func testAppliesBlockFormatToMultilineSelection() {
        let formatter = EditorTextFormatter(converter: MarkdownConverter())
        var selectedRange = NSRange(location: NSNotFound, length: 0)

        let result = formatter.stringByApplyingFormat(.quote, toText: "one\ntwo", range: NSRange(location: 0, length: 7), selectedRange: &selectedRange)

        XCTAssertEqual(result, "> one\n> two\n")
        XCTAssertEqual(selectedRange.location, 0)
        XCTAssertEqual(selectedRange.length, 12)
    }
}
