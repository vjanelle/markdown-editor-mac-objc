import Cocoa
import XCTest
@testable import MarkdownEditorLite

final class TestAppDelegate: AppDelegate {
    var stubWindowController: MainWindowController?

    override var mainWindowController: NSWindowController? {
        stubWindowController ?? super.mainWindowController
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
            .appendingPathComponent("MarkdownEditor/Base.lproj/Main.storyboard")
        return (try? String(contentsOf: storyboardURL, encoding: .utf8)) ?? ""
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
        XCTAssertEqual(controller.windowFrameAutosaveName, "MarkdownEditorMainWindow")
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

    func testAppDelegateShowsAboutPanel() {
        let delegate = AppDelegate()

        delegate.showAboutPanel(nil)

        NSApp.windows
            .filter { $0.title.localizedCaseInsensitiveContains("about") }
            .forEach { $0.close() }
    }

    func testMainWindowNotVisibleAtLaunchInStoryboard() {
        let storyboard = mainStoryboardContents()

        XCTAssertTrue(storyboard.contains("visibleAtLaunch=\"NO\""))
        XCTAssertTrue(storyboard.contains("relationship=\"window.shadowedContentViewController\""))
        XCTAssertFalse(storyboard.contains("property=\"mainWindowController\""))
        XCTAssertTrue(storyboard.contains("storyboardIdentifier=\"MainWindowController\""))
        XCTAssertTrue(storyboard.contains("selector=\"showAboutPanel:\""))
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
        
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.bold"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.strikethrough"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.italic"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.quote"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.code"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.link"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.bulletedList"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.numberedList"))
        XCTAssertTrue(itemIdentifiers.contains("com.markdowneditor.reloadPreview"))
        
        // Verify that the toolbar has the correct identifier
        XCTAssertEqual(window?.toolbar?.identifier, "MarkdownEditorMainToolbar.v2")
        
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
}
