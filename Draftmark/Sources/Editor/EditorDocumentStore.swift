import Foundation

@objc(EditorDocumentStore)
class EditorDocumentStore: NSObject {
    @objc(readStringFromURL:error:)
    func readString(from url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    @objc(writeString:toURL:error:)
    func writeString(_ string: String, to url: URL) throws {
        try string.write(to: url, atomically: true, encoding: .utf8)
    }
}
