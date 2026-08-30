import WebKit
import XCTest
@testable import Draftmark

final class PreviewViewControllerTests: XCTestCase {
    private var webView: WKWebView!

    private func resourceText(named name: String) -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let resourceURL = testsDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("Draftmark/Resources/\(name)")
        return (try? String(contentsOf: resourceURL, encoding: .utf8)) ?? ""
    }

    private func makeController() -> PreviewViewController {
        let controller = PreviewViewController()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        controller.webView = webView
        return controller
    }

    func testSetRepresentedObjectIsAccepted() {
        let controller = makeController()
        let object = NSObject()

        controller.representedObject = object

        XCTAssertTrue(controller.representedObject as AnyObject === object)
    }

    func testReloadButtonLoadsCurrentHtml() {
        let controller = makeController()

        controller.reloadButtonClicked(nil)

        XCTAssertNotNil(controller.navigation)
    }

    func testAutoReloadPreferenceControlsNotificationReload() {
        let controller = makeController()

        controller.didChangeContentNotification(nil)

        XCTAssertNotNil(controller.navigation)
    }

    func testDidFinishNavigationRestoresVisibleRect() {
        let controller = makeController()

        controller.webView(webView, didFinish: nil)

        XCTAssertNotNil(controller)
    }

    func testPreviewHeadersIncludeMermaidSupport() {
        let gfmHeader = resourceText(named: "gfm-header.txt")
        let markdownHeader = resourceText(named: "markdown-header.txt")

        XCTAssertTrue(gfmHeader.contains("mermaid.min.js"))
        XCTAssertTrue(markdownHeader.contains("mermaid.min.js"))
        XCTAssertFalse(gfmHeader.contains("cdn.jsdelivr.net/npm/mermaid"))
        XCTAssertFalse(markdownHeader.contains("cdn.jsdelivr.net/npm/mermaid"))
        XCTAssertTrue(gfmHeader.contains("securityLevel: 'strict'"))
        XCTAssertTrue(markdownHeader.contains("securityLevel: 'strict'"))
        XCTAssertFalse(gfmHeader.contains("securityLevel: 'loose'"))
        XCTAssertFalse(markdownHeader.contains("securityLevel: 'loose'"))
        XCTAssertFalse(gfmHeader.contains("https://"))
        XCTAssertFalse(markdownHeader.contains("https://"))
    }

    func testPreviewNavigationAllowsLocalPreviewURLs() {
        let controller = makeController()

        XCTAssertTrue(controller.isAllowedPreviewNavigationURL(nil))
        XCTAssertTrue(controller.isAllowedPreviewNavigationURL(URL(string: "about:blank")))
        XCTAssertTrue(controller.isAllowedPreviewNavigationURL(Bundle.main.resourceURL))
    }

    func testPreviewNavigationBlocksExternalNetworkURLs() {
        let controller = makeController()

        XCTAssertFalse(controller.isAllowedPreviewNavigationURL(URL(string: "https://example.com")))
        XCTAssertFalse(controller.isAllowedPreviewNavigationURL(URL(string: "http://example.com")))
    }

    func testPreviewNavigationRecognizesExternalBrowserURLs() {
        let controller = makeController()

        XCTAssertTrue(controller.isExternalPreviewNavigationURL(URL(string: "https://example.com")))
        XCTAssertTrue(controller.isExternalPreviewNavigationURL(URL(string: "http://example.com")))
        XCTAssertFalse(controller.isExternalPreviewNavigationURL(URL(string: "about:blank")))
        XCTAssertFalse(controller.isExternalPreviewNavigationURL(Bundle.main.resourceURL))
    }

    func testPreviewHTMLAddsLocalOnlyContentSecurityPolicy() {
        let controller = makeController()
        let html = "<html><head><title>Preview</title></head><body><img src=\"https://example.com/image.png\"></body></html>"

        let lockedDownHTML = controller.lockedDownPreviewHTML(withHTML: html)

        XCTAssertTrue(lockedDownHTML.contains("Content-Security-Policy"))
        XCTAssertTrue(lockedDownHTML.contains("default-src 'none'"))
        XCTAssertTrue(lockedDownHTML.contains("connect-src 'none'"))
        XCTAssertTrue(lockedDownHTML.contains("img-src file:"))
        XCTAssertFalse(lockedDownHTML.contains("data:"))
    }
}
