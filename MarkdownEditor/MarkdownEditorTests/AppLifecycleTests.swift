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
    }

    func testMainWindowControllerSetsMinimumContentSize() {
        let controller = MainWindowController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: .titled,
            backing: .buffered,
            defer: false
        )
        controller.setValue(window, forKey: "window")

        controller.windowDidLoad()

        XCTAssertGreaterThanOrEqual(window.contentMinSize.width, 1200.0)
        XCTAssertGreaterThanOrEqual(window.contentMinSize.height, 800.0)
        XCTAssertGreaterThanOrEqual(window.contentView?.frame.size.width ?? 0, 1200.0)
        XCTAssertGreaterThanOrEqual(window.contentView?.frame.size.height ?? 0, 800.0)
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

    func testMainWindowNotVisibleAtLaunchInStoryboard() {
        let storyboard = mainStoryboardContents()

        XCTAssertTrue(storyboard.contains("visibleAtLaunch=\"NO\""))
        XCTAssertTrue(storyboard.contains("relationship=\"window.shadowedContentViewController\""))
        XCTAssertFalse(storyboard.contains("property=\"mainWindowController\""))
        XCTAssertTrue(storyboard.contains("storyboardIdentifier=\"MainWindowController\""))
        XCTAssertTrue(storyboard.contains("selector=\"showAboutPanel:\""))
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
