import XCTest
@testable import Draftmark

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

    func testFileWatcherStillReceivesChangesAfterRepeatedRestarts() throws {
        let url = temporaryFileURL(name: UUID().uuidString)
        try Data().write(to: url)
        let watcher = EditorFileWatcher()
        defer {
            watcher.stopWatching()
            try? FileManager.default.removeItem(at: url)
        }
        for _ in 0..<100 {
            watcher.watchFile(atPath: url.path) {}
        }
        let changed = expectation(description: "Current watcher receives write")
        changed.assertForOverFulfill = false
        watcher.watchFile(atPath: url.path) { changed.fulfill() }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.write(contentsOf: Data("changed".utf8))
            } catch {
                XCTFail("Write failed: \(error)")
            }
        }

        wait(for: [changed], timeout: 3)
    }
}
