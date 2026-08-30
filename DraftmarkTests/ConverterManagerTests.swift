import XCTest
@testable import Draftmark

final class ConverterManagerTests: XCTestCase {
    private func sampleMarkdown() -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let sampleURL = testsDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("Draftmark/Resources/sample.md")
        return (try? String(contentsOf: sampleURL, encoding: .utf8)) ?? ""
    }

    func testConverterTitlesAreExposedInDisplayOrder() {
        XCTAssertEqual(ConverterManager.shared.converters, [
            "GitHub Flavored Markdown",
            "Markdown",
            "Strict Markdown"
        ])
    }

    func testSelectedConverterIndexChangesSelectedConverter() {
        ConverterManager.shared.selectedConverterIndex = 1
        XCTAssertEqual(ConverterManager.shared.selectedConverter.title, "Markdown")

        ConverterManager.shared.selectedConverterIndex = 2
        XCTAssertEqual(ConverterManager.shared.selectedConverter.title, "Strict Markdown")
    }

    func testSetContentPostsDidChangeNotification() {
        let expectation = expectation(description: "content changed")
        let observer = NotificationCenter.default.addObserver(
            forName: ConverterManager.didChangeContentNotification,
            object: nil,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }

        ConverterManager.shared.setContent(with: "# Title")

        waitForExpectations(timeout: 1)
        NotificationCenter.default.removeObserver(observer)
    }

    func testConverterManagerDoesNotExposeEmbeddedPreviewServerURL() {
        XCTAssertFalse(ConverterManager.shared.responds(to: Selector(("url"))))
    }

    func testSampleMarkdownIncludesMermaidDiagramBlock() {
        let sample = sampleMarkdown()

        XCTAssertTrue(sample.contains("```mermaid"))
        XCTAssertTrue(sample.contains("graph TD"))
    }
}
