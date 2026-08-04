import Cocoa

@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
    private static let repositoryURLString = "https://github.com/vjanelle/markdown-editor-mac-objc"

    private var storedMainWindowController: NSWindowController?

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
        credits.append(NSAttributedString(string: "Portions Copyright (c) 2018 Satoshi Iwaki, GitHub: "))
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

    @IBAction func showFontPanel(_ sender: Any?) {
        mainWindowController?.window?.makeKeyAndOrderFront(self)
        NSApp.sendAction(#selector(NSFontManager.orderFrontFontPanel(_:)), to: NSFontManager.shared, from: sender)
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
