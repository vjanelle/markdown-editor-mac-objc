import Cocoa

@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    private static let repositoryURLString = "https://github.com/vjanelle/Draftmark"

    private var storedMainWindowController: NSWindowController?
    @objc var settingsWindowController: SettingsWindowController?

    @objc var mainWindowController: NSWindowController? {
        storedMainWindowController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        storedMainWindowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as? MainWindowController
        mainWindowController?.showWindow(self)
        mainWindowController?.window?.makeKeyAndOrderFront(self)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        guard let filename = filenames.first,
              let windowController = mainWindowController,
              let mainWindowController = windowController as? MainWindowController,
              mainWindowController.openFile(at: filename) else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }

        sender.reply(toOpenOrPrint: .success)
    }

    @IBAction func showAboutPanel(_ sender: Any?) {
        let credits = NSMutableAttributedString(string: "Portions Copyright (c) 2026 Vincent Janelle\n")
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: URL(string: Self.repositoryURLString) as Any,
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        credits.append(NSAttributedString(string: Self.repositoryURLString, attributes: linkAttributes))

        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: credits
        ])
    }

    @IBAction func showSettings(_ sender: Any?) {
        if let mainWindowController = mainWindowController as? MainWindowController,
           let currentFont = mainWindowController.currentEditorFont {
            PreferenceManager.shared.editorFontName = currentFont.familyName ?? currentFont.fontName
            PreferenceManager.shared.editorFontSize = currentFont.pointSize
        }
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(self)
        settingsWindowController?.window?.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindowController?.showWindow(self)
            mainWindowController?.window?.makeKeyAndOrderFront(self)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

final class SettingsWindowController: NSWindowController {
    private let fontPopup = NSPopUpButton()
    private let sizePopup = NSPopUpButton()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) {
        fatalError("SettingsWindowController does not support storyboard initialization")
    }

    private func buildContent() {
        let containerView = NSView()
        let tabView = NSTabView()
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults))
        tabView.tabViewType = .topTabsBezelBorder
        let fontTab = NSTabViewItem(identifier: "font-and-size")
        fontTab.label = "Font & Size"

        let fontLabel = NSTextField(labelWithString: "Font")
        let sizeLabel = NSTextField(labelWithString: "Size")
        fontLabel.alignment = .right
        sizeLabel.alignment = .right
        let systemMonospacedFamily = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        ).familyName ?? "Menlo"
        fontPopup.removeAllItems()
        for family in NSFontManager.shared.availableFontFamilies.sorted() {
            fontPopup.addItem(withTitle: family)
            fontPopup.lastItem?.representedObject = family
        }
        if fontPopup.itemArray.allSatisfy({ ($0.representedObject as? String) != systemMonospacedFamily }) {
            fontPopup.insertItem(withTitle: "System Monospaced", at: 0)
            fontPopup.item(at: 0)?.representedObject = systemMonospacedFamily
        }
        sizePopup.addItems(withTitles: ["9", "10", "11", "12", "13", "14", "16", "18", "20", "24", "28", "32", "36", "48"])
        fontPopup.target = self
        fontPopup.action = #selector(fontSelectionChanged)
        sizePopup.target = self
        sizePopup.action = #selector(sizeSelectionChanged)

        let grid = NSGridView(views: [
            [fontLabel, fontPopup],
            [sizeLabel, sizePopup]
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.column(at: 0).width = 44
        fontTab.view = grid
        tabView.addTabViewItem(fontTab)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tabView)
        containerView.addSubview(resetButton)
        window?.contentView = containerView

        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            tabView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            tabView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            tabView.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -12),
            resetButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            resetButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            fontPopup.widthAnchor.constraint(equalToConstant: 330),
            sizePopup.widthAnchor.constraint(equalToConstant: 100)
        ])
        updateSelections()
    }

    override func showWindow(_ sender: Any?) {
        updateSelections()
        super.showWindow(sender)
    }

    @objc private func fontSelectionChanged() {
        guard let fontName = fontPopup.selectedItem?.representedObject as? String else {
            return
        }
        PreferenceManager.shared.editorFontName = fontName
    }

    @objc private func sizeSelectionChanged() {
        guard let size = Double(sizePopup.selectedItem?.title ?? "") else {
            return
        }
        PreferenceManager.shared.editorFontSize = size
    }

    @objc private func resetToDefaults() {
        PreferenceManager.shared.resetToDefaults()
        updateSelections()
    }

    private func updateSelections() {
        let preferences = PreferenceManager.shared
        if let item = fontPopup.itemArray.first(where: {
            ($0.representedObject as? String) == preferences.editorFontName
        }) {
            fontPopup.select(item)
        }
        sizePopup.selectItem(withTitle: String(format: "%g", preferences.editorFontSize))
    }
}
