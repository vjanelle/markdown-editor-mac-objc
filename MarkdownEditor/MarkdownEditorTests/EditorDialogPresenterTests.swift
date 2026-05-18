import Cocoa
import XCTest
@testable import MarkdownEditorLite

final class EditorDialogPresenterTests: XCTestCase {
    func testShowAlertWithoutWindowReturnsSynchronously() {
        let presenter = EditorDialogPresenter()

        presenter.showAlert(title: "Title", message: "Message", for: nil)

        XCTAssertNotNil(presenter)
    }

    func testConfirmDiscardingChangesWithoutWindowCancels() {
        let presenter = EditorDialogPresenter()
        var response: NSApplication.ModalResponse?

        presenter.confirmDiscardingChanges(for: nil) { response = $0 }

        XCTAssertEqual(response, .cancel)
    }

    func testOpenAndSavePanelsWithoutWindowReturnNil() {
        let presenter = EditorDialogPresenter()
        var openURL: URL?
        var saveURL: URL?

        presenter.showOpenFilePanel(for: nil, initialPath: NSTemporaryDirectory()) { openURL = $0 }
        presenter.showSaveFilePanel(for: nil, initialPath: NSTemporaryDirectory()) { saveURL = $0 }

        XCTAssertNil(openURL)
        XCTAssertNil(saveURL)
    }
}
