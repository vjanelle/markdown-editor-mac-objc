# Apple HIG Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the macOS Draftmark closer to Apple Human Interface Guidelines by replacing content-area toolbar controls with standard macOS affordances, improving adaptive window behavior, fixing menu discoverability, and correcting alert/document wording.

**Architecture:** Keep the existing storyboard-based AppKit architecture. Move command presentation toward standard `NSToolbar`/menu surfaces while preserving the existing `EditorViewController` formatting methods and `ConverterManager` bindings. Use focused XCTest coverage around storyboard structure, window sizing, menu actions, icon configuration, and alert text.

**Tech Stack:** Swift, AppKit, XCTest, storyboard XML, `xcodebuild`.

**HIG References:** Apple HIG: Toolbars, Windows, The Menu Bar, Menus, Icons.

---

## File Structure

- Modify: `Draftmark/Base.lproj/Main.storyboard`
  - Remove fake content toolbar controls from editor/preview panes.
  - Add a real `NSToolbar` to the main window.
  - Add menu items for Markdown formatting commands.
  - Make app/window naming consistent.
- Modify: `Draftmark/Sources/MainWindowController.swift`
  - Reduce and expose adaptive minimum content size.
  - Configure real toolbar behavior if needed after storyboard hookup.
- Modify: `Draftmark/Sources/EditorViewController.swift`
  - Remove manual fake-toolbar layout and custom icon tinting.
  - Add menu/toolbar action aliases with standard selectors where appropriate.
  - Keep formatting behavior in `applyFormat(_:)`.
- Modify: `Draftmark/Sources/PreviewViewController.swift`
  - Remove content-area reload button configuration.
  - Keep `reloadButtonClicked(_:)` as the toolbar/menu action target.
- Modify: `Draftmark/Sources/Editor/EditorDialogPresenter.swift`
  - Fix alert headline/body ordering.
  - Let unsaved-change messages use a passed document display name.
- Modify: `DraftmarkTests/AppLifecycleTests.swift`
  - Replace the old 1200x800 minimum-size assertion.
  - Add storyboard assertions for real toolbar and no fake content toolbar.
- Modify: `DraftmarkTests/EditorViewControllerTests.swift`
  - Add tests for command aliases and unsaved-change document naming.
- Modify: `DraftmarkTests/PreviewViewControllerTests.swift`
  - Add/adjust tests for preview reload command without requiring a content button.
- Modify: `DraftmarkTests/EditorDialogPresenterTests.swift`
  - Add alert text construction tests.

---

### Task 1: Baseline Verification

**Files:**
- Read: `Draftmark/Base.lproj/Main.storyboard`
- Read: `Draftmark/Sources/MainWindowController.swift`
- Read: `Draftmark/Sources/EditorViewController.swift`
- Read: `Draftmark/Sources/PreviewViewController.swift`
- Read: `Draftmark/Sources/Editor/EditorDialogPresenter.swift`

- [ ] **Step 1: Run the current test suite**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark test
```

Expected: PASS before changes. If this fails, capture the failing test names and fix only unrelated environmental issues before continuing.

- [ ] **Step 2: Inspect the current storyboard controls**

Run:

```bash
rg -n "toolbar|Show Toolbar|Customize Toolbar|roundTextured|texturedRounded|fixedFrame|Draftmark Lite|buttonCell|popUpButtonCell" Draftmark/Base.lproj/Main.storyboard
```

Expected: Output includes fake content buttons, `roundTextured`/`texturedRounded`, and `Draftmark Lite`; these are the targets for later tasks.

- [ ] **Step 3: Commit the known-good baseline if requested**

Run only if the user wants plan execution committed step-by-step:

```bash
git status --short
git commit --allow-empty -m "chore: record HIG cleanup baseline"
```

Expected: Empty baseline commit is created, or skipped if the user does not want commits.

---

### Task 2: Replace the Fake Toolbar With a Real Window Toolbar

**Files:**
- Modify: `Draftmark/Base.lproj/Main.storyboard`
- Modify: `Draftmark/Sources/EditorViewController.swift`
- Modify: `Draftmark/Sources/PreviewViewController.swift`
- Test: `DraftmarkTests/AppLifecycleTests.swift`

- [ ] **Step 1: Write failing storyboard tests**

In `AppLifecycleTests.swift`, add:

```swift
func testMainWindowUsesRealToolbarInsteadOfContentToolbar() {
    let storyboard = mainStoryboardContents()

    XCTAssertTrue(storyboard.contains("<toolbar key=\"toolbar\""))
    XCTAssertTrue(storyboard.contains("selector=\"boldButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"reloadButtonClicked:\""))
    XCTAssertFalse(storyboard.contains("type=\"roundTextured\""))
    XCTAssertFalse(storyboard.contains("bezelStyle=\"texturedRounded\""))
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowUsesRealToolbarInsteadOfContentToolbar test
```

Expected: FAIL because the storyboard currently has no real toolbar and still contains textured rounded content buttons.

- [ ] **Step 3: Move command controls into the window toolbar**

Edit `Main.storyboard`:

```xml
<toolbar key="toolbar" implicitIdentifier="DraftmarkMainToolbar" autosavesConfiguration="YES" allowsUserCustomization="YES" displayMode="iconOnly" sizeMode="regular" id="HIG-main-toolbar">
    <allowedToolbarItems>
        <toolbarItem implicitItemIdentifier="com.draftmark.bold" label="Bold" paletteLabel="Bold" toolTip="Bold" image="bold" catalog="system" id="HIG-toolbar-bold">
            <connections>
                <action selector="boldButtonClicked:" target="Wyk-aA-02j" id="HIG-action-bold"/>
            </connections>
        </toolbarItem>
        <toolbarItem implicitItemIdentifier="com.draftmark.italic" label="Italic" paletteLabel="Italic" toolTip="Italic" image="italic" catalog="system" id="HIG-toolbar-italic">
            <connections>
                <action selector="italicButtonClicked:" target="Wyk-aA-02j" id="HIG-action-italic"/>
            </connections>
        </toolbarItem>
        <toolbarItem implicitItemIdentifier="com.draftmark.link" label="Link" paletteLabel="Insert Link" toolTip="Insert Link" image="link" catalog="system" id="HIG-toolbar-link">
            <connections>
                <action selector="insertLinkButtonClicked:" target="Wyk-aA-02j" id="HIG-action-link"/>
            </connections>
        </toolbarItem>
        <toolbarItem implicitItemIdentifier="com.draftmark.reloadPreview" label="Reload" paletteLabel="Reload Preview" toolTip="Reload Preview" image="arrow.clockwise" catalog="system" id="HIG-toolbar-reload">
            <connections>
                <action selector="reloadButtonClicked:" target="fDo-d1-ebe" id="HIG-action-reload"/>
            </connections>
        </toolbarItem>
    </allowedToolbarItems>
    <defaultToolbarItems>
        <toolbarItem reference="HIG-toolbar-bold"/>
        <toolbarItem reference="HIG-toolbar-italic"/>
        <toolbarItem reference="HIG-toolbar-link"/>
        <toolbarItem reference="HIG-toolbar-reload"/>
    </defaultToolbarItems>
</toolbar>
```

Then remove the editor and preview content-area `button` elements for Bold, Strikethrough, Italic, Quote, Code, Insert Link, Bulleted List, Numbered List, and Reload Preview.

- [ ] **Step 4: Remove manual fake-toolbar layout code**

In `EditorViewController.swift`, delete:

```swift
private static let formattingButtonWidth: CGFloat = 32.0
private static let formattingButtonHeight: CGFloat = 25.0
private static let formattingButtonGap: CGFloat = 8.0
private static let formattingToolbarPadding: CGFloat = 6.0
private static let converterPopupWidth: CGFloat = 170.0
private static let converterPopupHeight: CGFloat = 25.0
```

Delete `configureFormattingButtons()`, `formattingButtons`, `formattingButtonItems`, `toolbarIconColor()`, `tintedNonTemplateImage(from:color:)`, `formattingButton(in:matchingSelectorName:)`, and `layoutFormattingToolbar()`. Update lifecycle methods to:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    textView.setAccessibilityIdentifier("EditorTextView")
    converterPopup.setAccessibilityIdentifier("ConverterPopup")
    textView.string = loadSample()
    ConverterManager.shared.setContent(with: textView.string)
}
```

Remove `viewDidLayout()` if it becomes empty.

- [ ] **Step 5: Remove preview content-button styling**

In `PreviewViewController.swift`, delete `configureReloadButton()`, `toolbarIconColor()`, and `tintedNonTemplateImage(from:color:)`. Update lifecycle methods to:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    replacePreviewWebViewWithLockedDownConfiguration()
    view.setAccessibilityIdentifier("PreviewPane")
    view.setAccessibilityElement(true)
    view.setAccessibilityRole(.group)
    webView.setAccessibilityIdentifier("PreviewWebView")
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(didChangeContentNotification(_:)),
        name: ConverterManager.didChangeContentNotification,
        object: nil
    )

    visibleRect = .zero
    reloadHtml()
}
```

Remove `viewDidLayout()` if it becomes empty.

- [ ] **Step 6: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowUsesRealToolbarInsteadOfContentToolbar -only-testing:DraftmarkTests/EditorViewControllerTests/testFormattingActionsUpdateSelectedText -only-testing:DraftmarkTests/PreviewViewControllerTests/testReloadButtonLoadsCurrentHtml test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Draftmark/Base.lproj/Main.storyboard Draftmark/Sources/EditorViewController.swift Draftmark/Sources/PreviewViewController.swift DraftmarkTests/AppLifecycleTests.swift
git commit -m "fix: use standard macOS toolbar"
```

---

### Task 3: Make Window Sizing Adaptive

**Files:**
- Modify: `Draftmark/Sources/MainWindowController.swift`
- Modify: `Draftmark/Base.lproj/Main.storyboard`
- Test: `DraftmarkTests/AppLifecycleTests.swift`

- [ ] **Step 1: Replace the failing minimum-size test**

In `AppLifecycleTests.swift`, replace `testMainWindowControllerSetsMinimumContentSize()` with:

```swift
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
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowControllerUsesAdaptiveMinimumContentSize test
```

Expected: FAIL because the current minimum is 1200x800.

- [ ] **Step 3: Lower the minimum content size**

In `MainWindowController.swift`, change:

```swift
private static let minimumContentSize = NSSize(width: 1200.0, height: 800.0)
```

to:

```swift
private static let minimumContentSize = NSSize(width: 720.0, height: 480.0)
```

In `Main.storyboard`, change the main window content rect from:

```xml
<rect key="contentRect" x="196" y="240" width="1200" height="800"/>
```

to:

```xml
<rect key="contentRect" x="196" y="240" width="960" height="640"/>
```

- [ ] **Step 4: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowControllerUsesAdaptiveMinimumContentSize -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowStoryboardInstantiatesContentController test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Draftmark/Sources/MainWindowController.swift Draftmark/Base.lproj/Main.storyboard DraftmarkTests/AppLifecycleTests.swift
git commit -m "fix: make main window size adaptive"
```

---

### Task 4: Add Discoverable Markdown Menu Commands

**Files:**
- Modify: `Draftmark/Base.lproj/Main.storyboard`
- Modify: `Draftmark/Sources/EditorViewController.swift`
- Test: `DraftmarkTests/AppLifecycleTests.swift`
- Test: `DraftmarkTests/EditorViewControllerTests.swift`

- [ ] **Step 1: Add failing menu/storyboard test**

In `AppLifecycleTests.swift`, add:

```swift
func testStoryboardExposesMarkdownFormattingMenuCommands() {
    let storyboard = mainStoryboardContents()

    XCTAssertTrue(storyboard.contains("title=\"Markdown\""))
    XCTAssertTrue(storyboard.contains("selector=\"boldButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"italicButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"insertLinkButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"quoteButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"listBulletedButtonClicked:\""))
    XCTAssertTrue(storyboard.contains("selector=\"listNumberedButtonClicked:\""))
}
```

- [ ] **Step 2: Add failing command alias tests**

In `EditorViewControllerTests.swift`, add:

```swift
func testStandardFormattingCommandAliasesApplyMarkdown() {
    let controller = makeController(text: "alpha")

    textView.setSelectedRange(NSRange(location: 0, length: 5))
    controller.boldButtonClicked(nil)
    XCTAssertEqual(textView.string, "**alpha**")

    textView.string = "alpha"
    textView.setSelectedRange(NSRange(location: 0, length: 5))
    controller.italicButtonClicked(nil)
    XCTAssertEqual(textView.string, "*alpha*")
}
```

This passes with the current methods, but protects the menu wiring target methods during storyboard cleanup.

- [ ] **Step 3: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardExposesMarkdownFormattingMenuCommands -only-testing:DraftmarkTests/EditorViewControllerTests/testStandardFormattingCommandAliasesApplyMarkdown test
```

Expected: Storyboard test FAILS until the Markdown menu is added.

- [ ] **Step 4: Add a Markdown menu**

In `Main.storyboard`, add a top-level menu after `Format` and before `View`:

```xml
<menuItem title="Markdown" id="HIG-markdown-menu-item">
    <modifierMask key="keyEquivalentModifierMask"/>
    <menu key="submenu" title="Markdown" id="HIG-markdown-menu">
        <items>
            <menuItem title="Bold" keyEquivalent="b" id="HIG-menu-bold">
                <connections>
                    <action selector="boldButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-bold"/>
                </connections>
            </menuItem>
            <menuItem title="Italic" keyEquivalent="i" id="HIG-menu-italic">
                <connections>
                    <action selector="italicButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-italic"/>
                </connections>
            </menuItem>
            <menuItem title="Strikethrough" keyEquivalent="s" id="HIG-menu-strike">
                <modifierMask key="keyEquivalentModifierMask" control="YES" command="YES"/>
                <connections>
                    <action selector="strikeThroughButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-strike"/>
                </connections>
            </menuItem>
            <menuItem isSeparatorItem="YES" id="HIG-menu-separator-inline"/>
            <menuItem title="Insert Link" keyEquivalent="k" id="HIG-menu-link">
                <connections>
                    <action selector="insertLinkButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-link"/>
                </connections>
            </menuItem>
            <menuItem title="Code" keyEquivalent="`" id="HIG-menu-code">
                <modifierMask key="keyEquivalentModifierMask" control="YES" command="YES"/>
                <connections>
                    <action selector="codeButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-code"/>
                </connections>
            </menuItem>
            <menuItem title="Block Quote" keyEquivalent="'" id="HIG-menu-quote">
                <modifierMask key="keyEquivalentModifierMask" command="YES"/>
                <connections>
                    <action selector="quoteButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-quote"/>
                </connections>
            </menuItem>
            <menuItem isSeparatorItem="YES" id="HIG-menu-separator-block"/>
            <menuItem title="Bulleted List" keyEquivalent="8" id="HIG-menu-bulleted">
                <modifierMask key="keyEquivalentModifierMask" shift="YES" command="YES"/>
                <connections>
                    <action selector="listBulletedButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-bulleted"/>
                </connections>
            </menuItem>
            <menuItem title="Numbered List" keyEquivalent="7" id="HIG-menu-numbered">
                <modifierMask key="keyEquivalentModifierMask" shift="YES" command="YES"/>
                <connections>
                    <action selector="listNumberedButtonClicked:" target="Ady-hI-5gd" id="HIG-menu-action-numbered"/>
                </connections>
            </menuItem>
        </items>
    </menu>
</menuItem>
```

- [ ] **Step 5: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardExposesMarkdownFormattingMenuCommands -only-testing:DraftmarkTests/EditorViewControllerTests/testFormattingActionsUpdateSelectedText -only-testing:DraftmarkTests/EditorViewControllerTests/testBlockFormattingActionsUpdateSelectedText test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Draftmark/Base.lproj/Main.storyboard DraftmarkTests/AppLifecycleTests.swift DraftmarkTests/EditorViewControllerTests.swift
git commit -m "fix: add markdown formatting menu"
```

---

### Task 5: Use System Symbols and Remove Manual Icon Tinting

**Files:**
- Modify: `Draftmark/Base.lproj/Main.storyboard`
- Modify: `Draftmark/Sources/EditorViewController.swift`
- Modify: `Draftmark/Sources/PreviewViewController.swift`
- Test: `DraftmarkTests/AppLifecycleTests.swift`

- [ ] **Step 1: Add failing storyboard asset test**

In `AppLifecycleTests.swift`, add:

```swift
func testStoryboardDoesNotUseBundledMaterialFormattingIcons() {
    let storyboard = mainStoryboardContents()

    XCTAssertFalse(storyboard.contains("ic_format_"))
    XCTAssertFalse(storyboard.contains("ic_insert_link_"))
    XCTAssertFalse(storyboard.contains("ic_refresh_"))
    XCTAssertTrue(storyboard.contains("catalog=\"system\""))
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardDoesNotUseBundledMaterialFormattingIcons test
```

Expected: FAIL until storyboard toolbar/menu icon references use SF Symbols only.

- [ ] **Step 3: Replace icon references**

In `Main.storyboard`, replace bundled image names with SF Symbol references on toolbar items:

```xml
image="bold" catalog="system"
image="italic" catalog="system"
image="strikethrough" catalog="system"
image="quote.opening" catalog="system"
image="chevron.left.forwardslash.chevron.right" catalog="system"
image="link" catalog="system"
image="list.bullet" catalog="system"
image="list.number" catalog="system"
image="arrow.clockwise" catalog="system"
```

Do not manually tint these images in Swift. Use AppKit defaults so disabled/high-contrast/accent states are inherited from the system.

- [ ] **Step 4: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardDoesNotUseBundledMaterialFormattingIcons -only-testing:DraftmarkTests/AppLifecycleTests/testMainWindowUsesRealToolbarInsteadOfContentToolbar test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Draftmark/Base.lproj/Main.storyboard Draftmark/Sources/EditorViewController.swift Draftmark/Sources/PreviewViewController.swift DraftmarkTests/AppLifecycleTests.swift
git commit -m "fix: use system toolbar symbols"
```

---

### Task 6: Fix Alert Copy and Document Names

**Files:**
- Modify: `Draftmark/Sources/Editor/EditorDialogPresenter.swift`
- Modify: `Draftmark/Sources/EditorViewController.swift`
- Test: `DraftmarkTests/EditorDialogPresenterTests.swift`
- Test: `DraftmarkTests/EditorViewControllerTests.swift`

- [ ] **Step 1: Write failing alert text tests**

In `EditorDialogPresenterTests.swift`, add:

```swift
func testUnsavedChangesMessageUsesDocumentDisplayName() {
    let presenter = EditorDialogPresenter()

    let message = presenter.unsavedChangesMessage(forDocumentDisplayName: "Notes.md")

    XCTAssertEqual(message.messageText, "Do you want to save the changes you made to Notes.md?")
    XCTAssertEqual(message.informativeText, "Your changes will be lost if you don't save them.")
}
```

- [ ] **Step 2: Write failing controller document-name test**

In `EditorViewControllerTests.swift`, add:

```swift
func testDocumentDisplayNameUsesFileNameOrFallback() {
    let controller = makeController(text: "body")

    XCTAssertEqual(controller.documentDisplayName, "Untitled")

    controller.filePath = "/tmp/Notes.md"
    XCTAssertEqual(controller.documentDisplayName, "Notes.md")
}
```

- [ ] **Step 3: Run failing tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/EditorDialogPresenterTests/testUnsavedChangesMessageUsesDocumentDisplayName -only-testing:DraftmarkTests/EditorViewControllerTests/testDocumentDisplayNameUsesFileNameOrFallback test
```

Expected: FAIL because these APIs do not exist yet.

- [ ] **Step 4: Add alert text model**

In `EditorDialogPresenter.swift`, add:

```swift
@objc(EditorAlertText)
class EditorAlertText: NSObject {
    @objc let messageText: String
    @objc let informativeText: String

    init(messageText: String, informativeText: String) {
        self.messageText = messageText
        self.informativeText = informativeText
    }
}
```

Add:

```swift
@objc(unsavedChangesMessageForDocumentDisplayName:)
func unsavedChangesMessage(forDocumentDisplayName displayName: String) -> EditorAlertText {
    EditorAlertText(
        messageText: "Do you want to save the changes you made to \(displayName)?",
        informativeText: "Your changes will be lost if you don't save them."
    )
}
```

Update `warningAlert(title:message:)` to:

```swift
private func warningAlert(title: String, message: String) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    return alert
}
```

Change `confirmDiscardingChanges` signature to:

```swift
@objc(confirmDiscardingChangesForDocumentDisplayName:window:completionHandler:)
func confirmDiscardingChanges(
    forDocumentDisplayName displayName: String,
    window: NSWindow?,
    completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void
) {
    let text = unsavedChangesMessage(forDocumentDisplayName: displayName)
    let alert = NSAlert()
    alert.messageText = text.messageText
    alert.informativeText = text.informativeText
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    alert.addButton(withTitle: "Don't Save")
    if let window {
        alert.beginSheetModal(for: window, completionHandler: handler)
    } else {
        handler(.cancel)
    }
}
```

- [ ] **Step 5: Add document display name and update call sites**

In `EditorViewController.swift`, add:

```swift
@objc var documentDisplayName: String {
    guard let filePath, !filePath.isEmpty else {
        return "Untitled"
    }
    return URL(fileURLWithPath: filePath).lastPathComponent
}
```

Replace both calls to:

```swift
dialogPresenter.confirmDiscardingChanges(for: presentationWindow) { [weak self] returnCode in
```

with:

```swift
dialogPresenter.confirmDiscardingChanges(
    forDocumentDisplayName: documentDisplayName,
    window: presentationWindow
) { [weak self] returnCode in
```

Update `StubEditorDialogPresenter` in `EditorViewControllerTests.swift` to override the new signature:

```swift
override func confirmDiscardingChanges(
    forDocumentDisplayName displayName: String,
    window: NSWindow?,
    completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void
) {
    confirmCallCount += 1
    handler(confirmationResponse)
}
```

Update `EditorDialogPresenterTests.testConfirmDiscardingChangesWithoutWindowCancels()` to call:

```swift
presenter.confirmDiscardingChanges(forDocumentDisplayName: "Untitled", window: nil) { response = $0 }
```

- [ ] **Step 6: Run focused tests**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/EditorDialogPresenterTests -only-testing:DraftmarkTests/EditorViewControllerTests/testDocumentDisplayNameUsesFileNameOrFallback -only-testing:DraftmarkTests/EditorViewControllerTests/testNewDocumentDirtyDiscardCreatesNewFile -only-testing:DraftmarkTests/EditorViewControllerTests/testOpenDocumentDirtyDiscardOpensOpenPanel test
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Draftmark/Sources/Editor/EditorDialogPresenter.swift Draftmark/Sources/EditorViewController.swift DraftmarkTests/EditorDialogPresenterTests.swift DraftmarkTests/EditorViewControllerTests.swift
git commit -m "fix: improve document alert copy"
```

---

### Task 7: Align App and Window Naming

**Files:**
- Modify: `Draftmark/Base.lproj/Main.storyboard`
- Test: `DraftmarkTests/AppLifecycleTests.swift`

- [ ] **Step 1: Add failing naming test**

In `AppLifecycleTests.swift`, add:

```swift
func testStoryboardUsesConsistentAppName() {
    let storyboard = mainStoryboardContents()

    XCTAssertTrue(storyboard.contains("title=\"Draftmark\""))
    XCTAssertFalse(storyboard.contains("Draftmark Lite"))
}
```

- [ ] **Step 2: Run failing test**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardUsesConsistentAppName test
```

Expected: FAIL because the window title currently says `Draftmark Lite`.

- [ ] **Step 3: Update the main window title**

In `Main.storyboard`, change:

```xml
<window key="window" title="Draftmark Lite" ...
```

to:

```xml
<window key="window" title="Draftmark" ...
```

- [ ] **Step 4: Run focused test**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark -only-testing:DraftmarkTests/AppLifecycleTests/testStoryboardUsesConsistentAppName test
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Draftmark/Base.lproj/Main.storyboard DraftmarkTests/AppLifecycleTests.swift
git commit -m "fix: align app naming"
```

---

### Task 8: Final HIG Regression Pass

**Files:**
- Verify: `Draftmark/Base.lproj/Main.storyboard`
- Verify: `Draftmark/Sources/MainWindowController.swift`
- Verify: `Draftmark/Sources/EditorViewController.swift`
- Verify: `Draftmark/Sources/PreviewViewController.swift`
- Verify: `Draftmark/Sources/Editor/EditorDialogPresenter.swift`
- Verify: `DraftmarkTests/*.swift`

- [ ] **Step 1: Run style grep for removed patterns**

Run:

```bash
rg -n "roundTextured|texturedRounded|ic_format_|ic_insert_link_|ic_refresh_|Draftmark Lite|minimumContentSize = NSSize\\(width: 1200|configureFormattingButtons|layoutFormattingToolbar|tintedNonTemplateImage" Draftmark/Draftmark Draftmark/DraftmarkTests
```

Expected: No matches.

- [ ] **Step 2: Run full test suite**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark test
```

Expected: PASS.

- [ ] **Step 3: Build the app**

Run:

```bash
cd .
xcodebuild -workspace Draftmark.xcworkspace -scheme Draftmark build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Manual UI check**

Open the workspace:

```bash
open Draftmark.xcworkspace
```

Manual expectations:

- Main window opens at a usable size and can shrink to about 720x480.
- Formatting controls appear in the macOS toolbar, not inside the editor pane.
- `View > Show Toolbar` and `View > Customize Toolbar...` operate on a real toolbar.
- Markdown formatting commands are discoverable in the menu bar.
- Toolbar icons adapt in light/dark appearance.
- Unsaved-changes alert uses the actual file name or `Untitled`.
- Preview reload still works.

- [ ] **Step 5: Final commit**

```bash
git status --short
git add Draftmark docs/superpowers/plans/2026-05-20-apple-hig-alignment.md
git commit -m "docs: plan Apple HIG alignment"
```

Expected: All implementation commits are present, or this plan-only commit is present if execution has not started.

---

## Self-Review

- Spec coverage: The plan covers the previously identified HIG risks: fake toolbar, misleading toolbar menu items, rigid window sizing, fixed/manual content controls, old textured button styling, manual non-template icon tinting, alert headline/body reversal, hardcoded `New file`, missing formatting menu discoverability, and inconsistent app name.
- Placeholder scan: No placeholder markers or unspecified test steps are required for execution.
- Type consistency: New `EditorAlertText`, `unsavedChangesMessage(forDocumentDisplayName:)`, `confirmDiscardingChanges(forDocumentDisplayName:window:completionHandler:)`, and `documentDisplayName` names are used consistently across implementation and tests.
