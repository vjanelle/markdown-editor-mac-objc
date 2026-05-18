import XCTest
@testable import MarkdownEditorLite

final class EditorDocumentStoreTests: XCTestCase {
    private func temporaryFileURL(name: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }

    func testWritesAndReadsUTF8Text() throws {
        let store = EditorDocumentStore()
        let url = temporaryFileURL(name: "markdown-editor-store-test.md")

        try store.writeString("# Title", to: url)
        let contents = try store.readString(from: url)

        XCTAssertEqual(contents, "# Title")
    }

    func testReadMissingFileReturnsNilAndError() {
        let store = EditorDocumentStore()
        let url = temporaryFileURL(name: "missing-markdown-editor-store-test.md")
        try? FileManager.default.removeItem(at: url)

        XCTAssertThrowsError(try store.readString(from: url))
    }
}
