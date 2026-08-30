import XCTest

final class DraftmarkUITests: XCTestCase {
    private func launchApplication() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testExample() {
        let app = launchApplication()
        let window = app.windows["Draftmark"]
        let editorTextView = app.textViews["EditorTextView"]
        let converterPopup = app.popUpButtons["ConverterPopup"]
        let previewPane = app.descendants(matching: .any).matching(identifier: "PreviewPane").firstMatch
        let previewHeading = app.staticTexts["Draftmark Markdown Sample"]

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertEqual(app.windows.count, 1)
        XCTAssertTrue(editorTextView.waitForExistence(timeout: 5))
        XCTAssertTrue(converterPopup.waitForExistence(timeout: 5))
        XCTAssertTrue(previewPane.waitForExistence(timeout: 5))
        XCTAssertTrue(previewHeading.waitForExistence(timeout: 10))
        XCTAssertTrue(editorTextView.isHittable)
        XCTAssertTrue(converterPopup.isHittable)
        XCTAssertFalse(previewPane.frame.isEmpty)
        XCTAssertGreaterThan(previewPane.frame.width, 100.0)
        XCTAssertGreaterThan(previewPane.frame.height, 100.0)
        XCTAssertGreaterThan(app.buttons.count, 1)
    }
}
