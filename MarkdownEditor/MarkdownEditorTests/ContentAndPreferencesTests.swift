import Cocoa
import XCTest
@testable import MarkdownEditorLite

final class ContentAndPreferencesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PreferenceManager.shared.resetToDefaults()
    }

    override func tearDown() {
        PreferenceManager.shared.resetToDefaults()
        super.tearDown()
    }

    func testPreferenceManagerDefaultsAutoReloadEnabled() {
        XCTAssertTrue(PreferenceManager.shared.autoReloadEnabled)
    }

    func testPreferenceManagerStoresAutoReloadEnabled() {
        XCTAssertTrue(PreferenceManager.shared.autoReloadEnabled)

        PreferenceManager.shared.autoReloadEnabled = true
        XCTAssertTrue(PreferenceManager.shared.autoReloadEnabled)

        PreferenceManager.shared.autoReloadEnabled = false
        XCTAssertFalse(PreferenceManager.shared.autoReloadEnabled)
    }

    func testPreferenceManagerResetToDefaultsClearsAutoReload() {
        PreferenceManager.shared.autoReloadEnabled = false

        PreferenceManager.shared.resetToDefaults()

        XCTAssertTrue(PreferenceManager.shared.autoReloadEnabled)
    }

    func testPreferenceManagerDefaultsToMonospacedSystemFont() {
        let expectedFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        XCTAssertEqual(PreferenceManager.shared.editorFontName, expectedFont.familyName)
        XCTAssertEqual(PreferenceManager.shared.editorFontSize, NSFont.systemFontSize)
    }
}
