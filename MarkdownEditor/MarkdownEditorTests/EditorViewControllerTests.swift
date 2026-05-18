import Cocoa
import XCTest
@testable import MarkdownEditorLite

final class StubEditorDialogPresenter: EditorDialogPresenter {
    var alertCallCount = 0
    var confirmCallCount = 0
    var openPanelCallCount = 0
    var savePanelCallCount = 0
    var confirmationResponse: NSApplication.ModalResponse = .cancel
    var openURL: URL?
    var saveURL: URL?
    var lastAlertTitle: String?
    var lastAlertMessage: String?

    override func showAlert(title: String, message: String, for window: NSWindow?) {
        alertCallCount += 1
        lastAlertTitle = title
        lastAlertMessage = message
    }

    override func confirmDiscardingChanges(for window: NSWindow?, completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void) {
        confirmCallCount += 1
        handler(confirmationResponse)
    }

    override func showOpenFilePanel(for window: NSWindow?, initialPath: String, completionHandler handler: @escaping (URL?) -> Void) {
        openPanelCallCount += 1
        handler(openURL)
    }

    override func showSaveFilePanel(for window: NSWindow?, initialPath: String, completionHandler handler: @escaping (URL?) -> Void) {
        savePanelCallCount += 1
        handler(saveURL)
    }
}

class TestableEditorViewController: EditorViewController {
    var newFileCallCount = 0
    var saveFileCallCount = 0
    var openFileCallCount = 0
    var saveFileResult = false

    override func newFile() {
        newFileCallCount += 1
    }

    override func saveFile() -> Bool {
        saveFileCallCount += 1
        return saveFileResult
    }

    override func openFile() -> Bool {
        openFileCallCount += 1
        return true
    }
}

final class EditorViewControllerTests: XCTestCase {
    private var textView: NSTextView!
    private var dialogPresenter: StubEditorDialogPresenter!

    private func configureController(_ controller: EditorViewController, text: String) {
        textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        dialogPresenter = StubEditorDialogPresenter()
        textView.string = text
        controller.textView = textView
        controller.dialogPresenter = dialogPresenter
    }

    private func makeController(text: String) -> EditorViewController {
        let controller = EditorViewController()
        configureController(controller, text: text)
        return controller
    }

    private func makeTestableController(text: String) -> TestableEditorViewController {
        let controller = TestableEditorViewController()
        configureController(controller, text: text)
        return controller
    }

    private func temporaryPath(name: String) -> String {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name).path
    }

    func testDocumentMetadataUsesOutlets() {
        let controller = makeController(text: "body")
        XCTAssertEqual(controller.documentBody(), "body")
    }

    func testDocumentMetadataFallsBackWhenOutletsAreMissing() {
        let controller = EditorViewController()
        XCTAssertEqual(controller.documentBody(), "Unknown")
    }

    func testSetRepresentedObjectIsAccepted() {
        let controller = makeController(text: "body")
        let object = NSObject()

        controller.representedObject = object

        XCTAssertTrue(controller.representedObject as AnyObject === object)
    }

    func testNewFileResetsContentPathAndDirtyState() {
        let controller = makeController(text: "old")
        controller.filePath = "/tmp/example.md"
        controller.dirty = true

        controller.newFile()

        XCTAssertEqual(textView.string, "New File")
        XCTAssertNil(controller.filePath)
        XCTAssertFalse(controller.dirty)
    }

    func testOpenFileRejectsMissingPathsAndDirectories() {
        let controller = makeController(text: "old")

        XCTAssertFalse(controller.openFile())

        controller.filePath = "/tmp/markdown-editor-missing.md"
        XCTAssertFalse(controller.openFile())

        controller.filePath = NSTemporaryDirectory()
        XCTAssertFalse(controller.openFile())
    }

    func testOpenFileLoadsMarkdownAndClearsDirtyState() throws {
        let controller = makeController(text: "old")
        let path = temporaryPath(name: "markdown-editor-open.md")
        try "# Opened".write(toFile: path, atomically: true, encoding: .utf8)
        controller.filePath = path
        controller.dirty = true

        XCTAssertTrue(controller.openFile())

        XCTAssertEqual(textView.string, "# Opened")
        XCTAssertFalse(controller.dirty)
    }

    func testSaveFileWritesMarkdownAndClearsDirtyState() throws {
        let controller = makeController(text: "# Saved")
        let path = temporaryPath(name: "markdown-editor-save.md")
        try "old".write(toFile: path, atomically: true, encoding: .utf8)
        controller.filePath = path
        controller.dirty = true

        XCTAssertTrue(controller.saveFile())

        let saved = try String(contentsOfFile: path, encoding: .utf8)
        XCTAssertEqual(saved, "# Saved")
        XCTAssertFalse(controller.dirty)
    }

    func testSaveFileRejectsMissingPath() {
        let controller = makeController(text: "# Saved")
        XCTAssertFalse(controller.saveFile())
    }

    func testMenuActionsUseNonModalBranchesWhenDocumentIsClean() {
        let controller = makeTestableController(text: "body")

        controller.newDocument(nil)
        XCTAssertEqual(controller.newFileCallCount, 1)

        controller.openDocument(nil)
        XCTAssertEqual(dialogPresenter.openPanelCallCount, 1)
    }

    func testNewDocumentDirtySaveSuccessLeavesDocumentInPlace() {
        let controller = makeTestableController(text: "body")
        controller.saveFileResult = true
        dialogPresenter.confirmationResponse = .alertFirstButtonReturn
        controller.dirty = true

        controller.newDocument(nil)

        XCTAssertEqual(controller.saveFileCallCount, 1)
        XCTAssertEqual(controller.newFileCallCount, 0)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 0)
    }

    func testNewDocumentDirtySaveFailureOpensSavePanel() {
        let controller = makeTestableController(text: "body")
        controller.saveFileResult = false
        dialogPresenter.confirmationResponse = .alertFirstButtonReturn
        controller.dirty = true

        controller.newDocument(nil)

        XCTAssertEqual(controller.saveFileCallCount, 1)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 1)
    }

    func testNewDocumentDirtyDiscardCreatesNewFile() {
        let controller = makeTestableController(text: "body")
        dialogPresenter.confirmationResponse = .alertThirdButtonReturn
        controller.dirty = true

        controller.newDocument(nil)

        XCTAssertEqual(controller.newFileCallCount, 1)
    }

    func testNewDocumentDirtyCancelDoesNothing() {
        let controller = makeTestableController(text: "body")
        dialogPresenter.confirmationResponse = .alertSecondButtonReturn
        controller.dirty = true

        controller.newDocument(nil)

        XCTAssertEqual(controller.newFileCallCount, 0)
        XCTAssertEqual(controller.saveFileCallCount, 0)
    }

    func testOpenDocumentDirtySaveSuccessLeavesDocumentInPlace() {
        let controller = makeTestableController(text: "body")
        controller.saveFileResult = true
        dialogPresenter.confirmationResponse = .alertFirstButtonReturn
        controller.dirty = true

        controller.openDocument(nil)

        XCTAssertEqual(controller.saveFileCallCount, 1)
        XCTAssertEqual(dialogPresenter.openPanelCallCount, 0)
    }

    func testOpenDocumentDirtySaveFailureOpensSavePanel() {
        let controller = makeTestableController(text: "body")
        controller.saveFileResult = false
        dialogPresenter.confirmationResponse = .alertFirstButtonReturn
        controller.dirty = true

        controller.openDocument(nil)

        XCTAssertEqual(controller.saveFileCallCount, 1)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 1)
    }

    func testOpenDocumentDirtyDiscardOpensOpenPanel() {
        let controller = makeTestableController(text: "body")
        dialogPresenter.confirmationResponse = .alertThirdButtonReturn
        controller.dirty = true

        controller.openDocument(nil)

        XCTAssertEqual(dialogPresenter.openPanelCallCount, 1)
    }

    func testOpenDocumentDirtyCancelDoesNothing() {
        let controller = makeTestableController(text: "body")
        dialogPresenter.confirmationResponse = .alertSecondButtonReturn
        controller.dirty = true

        controller.openDocument(nil)

        XCTAssertEqual(dialogPresenter.openPanelCallCount, 0)
        XCTAssertEqual(controller.saveFileCallCount, 0)
    }

    func testSaveMenuActionsUseSaveAndPanelBranches() {
        let controller = makeTestableController(text: "body")
        controller.saveFileResult = true

        controller.saveDocument(nil)
        XCTAssertEqual(controller.saveFileCallCount, 1)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 0)

        controller.saveFileResult = false
        controller.saveDocument(nil)
        XCTAssertEqual(controller.saveFileCallCount, 2)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 1)

        controller.saveDocumentAs(nil)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 2)
    }

    func testPromptForOpenAndSaveUseDialogPresenter() {
        let controller = makeTestableController(text: "body")
        let openPath = temporaryPath(name: "markdown-editor-selected-open.md")
        let savePath = temporaryPath(name: "markdown-editor-selected-save.md")
        dialogPresenter.openURL = URL(fileURLWithPath: openPath)
        dialogPresenter.saveURL = URL(fileURLWithPath: savePath)

        controller.promptForOpenURL(completionHandler: nil)
        controller.promptForSaveURL(completionHandler: nil)

        XCTAssertEqual(dialogPresenter.openPanelCallCount, 1)
        XCTAssertEqual(dialogPresenter.savePanelCallCount, 1)
        XCTAssertEqual(controller.openFileCallCount, 1)
        XCTAssertEqual(controller.saveFileCallCount, 1)
    }

    func testReloadFileFromDiskIfNeededHonorsDirtyState() {
        let controller = makeTestableController(text: "body")
        controller.filePath = "/tmp/example.md"

        controller.dirty = false
        controller.reloadFileFromDiskIfNeeded()
        XCTAssertEqual(controller.openFileCallCount, 1)

        controller.dirty = true
        controller.reloadFileFromDiskIfNeeded()
        XCTAssertEqual(controller.openFileCallCount, 1)
    }

    func testReplaceCharactersUpdatesTextAndDirtyState() {
        let controller = makeController(text: "Hello world")

        controller.replaceCharacters(in: NSRange(location: 6, length: 5), with: "Markdown")

        XCTAssertEqual(textView.string, "Hello Markdown")
        XCTAssertTrue(controller.dirty)
    }

    func testFormattingActionsUpdateSelectedText() {
        let controller = makeController(text: "alpha\nbeta")

        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.boldButtonClicked(nil)
        XCTAssertEqual(textView.string, "**alpha**\nbeta")

        textView.string = "alpha"
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.italicButtonClicked(nil)
        XCTAssertEqual(textView.string, "*alpha*")

        textView.string = "alpha"
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.strikeThroughButtonClicked(nil)
        XCTAssertEqual(textView.string, "~~alpha~~")

        textView.string = "alpha"
        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.codeButtonClicked(nil)
        XCTAssertEqual(textView.string, "```\nalpha\n```")
    }

    func testBlockFormattingActionsUpdateSelectedText() {
        let controller = makeController(text: "alpha\nbeta")

        textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))
        controller.quoteButtonClicked(nil)
        XCTAssertEqual(textView.string, "> alpha\n> beta\n")

        textView.string = "alpha\nbeta"
        textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))
        controller.listBulletedButtonClicked(nil)
        XCTAssertEqual(textView.string, "- alpha\n- beta\n")

        textView.string = "alpha\nbeta"
        textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))
        controller.listNumberedButtonClicked(nil)
        XCTAssertEqual(textView.string, "1. alpha\n1. beta\n")
    }

    func testLinkFormattingAndEmptySelection() {
        let controller = makeController(text: "alpha")

        textView.setSelectedRange(NSRange(location: 0, length: 5))
        controller.insertLinkButtonClicked(nil)
        XCTAssertEqual(textView.string, "[alpha](url)")
        XCTAssertTrue(controller.dirty)

        controller.dirty = false
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        controller.applyFormat(.bold)
        XCTAssertEqual(textView.string, "[alpha](url)")
        XCTAssertFalse(controller.dirty)
    }

    func testTextDelegateMethodsMarkDocumentDirty() {
        let controller = makeController(text: "changed")

        controller.textDidChange(Notification(name: NSText.didChangeNotification))
        XCTAssertTrue(controller.dirty)

        controller.dirty = false
        controller.textDidEndEditing(Notification(name: NSText.didEndEditingNotification))
        XCTAssertTrue(controller.dirty)
    }

    func testTextViewAllowsAllChanges() {
        let controller = makeController(text: "changed")

        XCTAssertTrue(controller.textView(
            textView,
            shouldChangeTextInRanges: [NSValue(range: NSRange(location: 0, length: 1))],
            replacementStrings: ["x"]
        ))
    }
}
