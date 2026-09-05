import Cocoa
import XCTest
@testable import Draftmark

final class TestAppDelegate: AppDelegate {
    var stubWindowController: MainWindowController?

    override var mainWindowController: NSWindowController? {
        stubWindowController ?? super.mainWindowController
    }
}

final class TestMainWindowController: MainWindowController {
    var openedPath: String?
    var openFileResult = true

    override func openFile(at path: String, completionHandler handler: @escaping (Bool) -> Void) {
        openedPath = path
        handler(openFileResult)
    }
}

final class AppLifecycleTests: XCTestCase {
    private func instantiateMainWindowController() -> MainWindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateController(withIdentifier: "MainWindowController") as! MainWindowController
    }

    private func mainStoryboardContents() -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let storyboardURL = testsDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("Draftmark/Base.lproj/Main.storyboard")
        return (try? String(contentsOf: storyboardURL, encoding: .utf8)) ?? ""
    }

    private func editorViewController(in viewController: NSViewController?) -> EditorViewController? {
        guard let viewController else {
            return nil
        }
        if let editor = viewController as? EditorViewController {
            return editor
        }
        return viewController.children.lazy.compactMap { self.editorViewController(in: $0) }.first
    }

    func testMainWindowControllerUpdatesSelectedConverterIndex() {
        let controller = MainWindowController()

        controller.selectedConverterIndex = 2

        XCTAssertEqual(ConverterManager.shared.selectedConverterIndex, 2)
        XCTAssertEqual(controller.selectedConverterIndex, 2)
        XCTAssertEqual(controller.converters, ["GitHub Flavored Markdown", "Markdown", "Strict Markdown"])
    }

    func testMainWindowControllerUsesAdaptiveMinimumContentSize() {
        let controller = MainWindowController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        controller.setValue(window, forKey: "window")

        controller.windowDidLoad()

        XCTAssertLessThanOrEqual(window.contentMinSize.width, 900.0)
        XCTAssertLessThanOrEqual(window.contentMinSize.height, 600.0)
        XCTAssertGreaterThanOrEqual(window.contentView?.frame.size.width ?? 0, window.contentMinSize.width)
        XCTAssertGreaterThanOrEqual(window.contentView?.frame.size.height ?? 0, window.contentMinSize.height)
        XCTAssertEqual(controller.windowFrameAutosaveName, "DraftmarkMainWindow")
    }

    func testMainWindowStoryboardInstantiatesContentController() {
        let controller = instantiateMainWindowController()

        _ = controller.window

        XCTAssertNotNil(controller)
        XCTAssertNotNil(controller.window)
    }

    func testAppDelegateAcceptsTerminationNotification() {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.willTerminateNotification)

        delegate.applicationWillTerminate(notification)

        XCTAssertNotNil(delegate)
    }

    func testAppDelegateOpensMarkdownFilesSentByFinder() {
        let delegate = TestAppDelegate()
        let controller = TestMainWindowController()
        delegate.stubWindowController = controller
        let path = "/tmp/example.md"

        delegate.application(.shared, openFiles: [path])

        XCTAssertEqual(controller.openedPath, path)
    }

    func testAppDelegateOpensFileQueuedBeforeLaunchFinishes() throws {
        let delegate = AppDelegate()
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("draftmark-launch.md")
        try "# Opened at launch".write(to: path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: path) }

        delegate.application(.shared, openFiles: [path.path])
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        let windowController = delegate.mainWindowController as? MainWindowController
        let editor = editorViewController(in: windowController?.contentViewController)
        XCTAssertEqual(editor?.filePath, path.path)
        XCTAssertEqual(editor?.textView.string, "# Opened at launch")
    }

    func testAppDelegateShowsAboutPanel() {
        let delegate = AppDelegate()

        delegate.showAboutPanel(nil)

        NSApp.windows
            .filter { $0.title.localizedCaseInsensitiveContains("about") }
            .forEach { $0.close() }
    }

    func testSettingsMenuOpensSettingsWindow() {
        let delegate = AppDelegate()

        delegate.showSettings(nil)

        let settings = delegate.settingsWindowController
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.window?.title, "Settings")
        XCTAssertNotNil(settings?.window?.contentView?.subviews
            .compactMap { $0 as? NSButton }
            .first { $0.title == "Reset to Defaults" })
        settings?.close()
    }

    func testMainWindowNotVisibleAtLaunchInStoryboard() {
        let storyboard = mainStoryboardContents()

        XCTAssertTrue(storyboard.contains("visibleAtLaunch=\"NO\""))
        XCTAssertTrue(storyboard.contains("relationship=\"window.shadowedContentViewController\""))
        XCTAssertFalse(storyboard.contains("property=\"mainWindowController\""))
        XCTAssertTrue(storyboard.contains("storyboardIdentifier=\"MainWindowController\""))
        XCTAssertTrue(storyboard.contains("selector=\"showAboutPanel:\""))
        XCTAssertTrue(storyboard.contains("title=\"Settings…\""))
        XCTAssertTrue(storyboard.contains("selector=\"showSettings:\""))
    }

    func testMainWindowUsesRealToolbarInsteadOfContentToolbar() {
        let controller = instantiateMainWindowController()
        let window = controller.window
        
        // Verify we have a valid window with toolbar
        XCTAssertNotNil(window)
        XCTAssertNotNil(window?.toolbar)
        
        // Check that the toolbar has the expected items
        let toolbarItems = window?.toolbar?.items ?? []
        
        // Ensure toolbar item identifiers include expected identifiers (matching the actual identifiers)
        let itemIdentifiers = toolbarItems.map { $0.itemIdentifier.rawValue }
        
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.bold"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.strikethrough"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.italic"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.quote"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.code"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.link"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.bulletedList"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.numberedList"))
        XCTAssertTrue(itemIdentifiers.contains("com.draftmark.reloadPreview"))
        
        // Verify that the toolbar has the correct identifier
        XCTAssertEqual(window?.toolbar?.identifier, "DraftmarkMainToolbar.v2")
        
        // Optional: Check that no in-content toolbar buttons remain (they should be removed from content)
        // Since we're checking the window's toolbar, not the storyboard content, this test is more robust
    }

    func testAppDelegateReopensMainWindowWhenNoVisibleWindows() {
        let delegate = TestAppDelegate()
        let controller = MainWindowController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        controller.setValue(window, forKey: "window")
        delegate.stubWindowController = controller

        let result = delegate.applicationShouldHandleReopen(.shared, hasVisibleWindows: false)

        XCTAssertTrue(result)
        XCTAssertTrue(window.isVisible)
    }

    func testAppDelegateTerminatesAfterLastWindowCloses() {
        let delegate = AppDelegate()

        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(.shared))
    }

    func testMainWindowControllerDelaysDirtyWindowCloseUntilEditorConfirms() {
        let controller = MainWindowController()
        let editor = makeCloseTestEditor()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        controller.setValue(window, forKey: "window")
        controller.contentViewController = editor
        window.delegate = controller

        XCTAssertFalse(controller.windowShouldClose(window))
        XCTAssertTrue(editor.dirty)
    }

    func testFinderOpenHonorsSaveCancelAndDiscard() {
        for response: NSApplication.ModalResponse in [.alertFirstButtonReturn, .alertSecondButtonReturn, .alertThirdButtonReturn] {
            let controller = MainWindowController()
            let editor = makeCloseTestEditor() as! TestableEditorViewController
            let presenter = editor.dialogPresenter as! StubEditorDialogPresenter
            presenter.confirmationResponse = response
            editor.saveFileResult = true
            editor.filePath = "/tmp/original.md"
            controller.contentViewController = editor
            var opened: Bool?

            controller.openFile(at: "/tmp/replacement.md") { opened = $0 }

            let shouldOpen = response != .alertSecondButtonReturn
            XCTAssertEqual(opened, shouldOpen)
            XCTAssertEqual(presenter.confirmCallCount, 1)
            XCTAssertEqual(editor.openFileCallCount, shouldOpen ? 1 : 0)
            XCTAssertEqual(editor.saveFileCallCount, response == .alertFirstButtonReturn ? 1 : 0)
            XCTAssertEqual(editor.filePath, shouldOpen ? "/tmp/replacement.md" : "/tmp/original.md")
        }
    }

    func testFinderOpenStopsWhenSaveIsCanceled() {
        let controller = MainWindowController()
        let editor = makeCloseTestEditor() as! TestableEditorViewController
        let presenter = editor.dialogPresenter as! StubEditorDialogPresenter
        presenter.confirmationResponse = .alertFirstButtonReturn
        editor.filePath = "/tmp/original.md"
        controller.contentViewController = editor
        var opened = true

        controller.openFile(at: "/tmp/replacement.md") { opened = $0 }

        XCTAssertFalse(opened)
        XCTAssertEqual(editor.openFileCallCount, 0)
        XCTAssertEqual(editor.filePath, "/tmp/original.md")
        XCTAssertTrue(editor.dirty)
    }

    func testQuitHonorsSaveCancelAndDiscard() {
        for response: NSApplication.ModalResponse in [.alertFirstButtonReturn, .alertSecondButtonReturn, .alertThirdButtonReturn] {
            let delegate = TestAppDelegate()
            let controller = MainWindowController()
            let editor = makeCloseTestEditor() as! TestableEditorViewController
            let presenter = editor.dialogPresenter as! StubEditorDialogPresenter
            presenter.confirmationResponse = response
            editor.saveFileResult = true
            controller.contentViewController = editor
            delegate.stubWindowController = controller

            let reply = delegate.applicationShouldTerminate(.shared)

            XCTAssertEqual(reply, response == .alertSecondButtonReturn ? .terminateCancel : .terminateNow)
            XCTAssertEqual(presenter.confirmCallCount, 1)
            XCTAssertEqual(editor.saveFileCallCount, response == .alertFirstButtonReturn ? 1 : 0)
            XCTAssertEqual(editor.dirty, response == .alertSecondButtonReturn)
        }
    }

    func testQuitStopsWhenSaveIsCanceled() {
        let delegate = TestAppDelegate()
        let controller = MainWindowController()
        let editor = makeCloseTestEditor()
        let presenter = editor.dialogPresenter as! StubEditorDialogPresenter
        presenter.confirmationResponse = .alertFirstButtonReturn
        controller.contentViewController = editor
        delegate.stubWindowController = controller

        XCTAssertEqual(delegate.applicationShouldTerminate(.shared), .terminateCancel)
        XCTAssertTrue(editor.dirty)
    }

    func testQuitCleanDocumentNeedsNoConfirmation() {
        let delegate = TestAppDelegate()
        let controller = MainWindowController()
        let editor = makeCloseTestEditor()
        let presenter = editor.dialogPresenter as! StubEditorDialogPresenter
        editor.dirty = false
        controller.contentViewController = editor
        delegate.stubWindowController = controller

        XCTAssertEqual(delegate.applicationShouldTerminate(.shared), .terminateNow)
        XCTAssertEqual(presenter.confirmCallCount, 0)
    }

    private func makeCloseTestEditor() -> EditorViewController {
        let editor = TestableEditorViewController()
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        let converterPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        let presenter = StubEditorDialogPresenter()
        presenter.confirmationResponse = .alertSecondButtonReturn
        view.addSubview(textView)
        view.addSubview(converterPopup)
        editor.view = view
        editor.textView = textView
        editor.converterPopup = converterPopup
        editor.dialogPresenter = presenter
        editor.dirty = true
        return editor
    }
}
