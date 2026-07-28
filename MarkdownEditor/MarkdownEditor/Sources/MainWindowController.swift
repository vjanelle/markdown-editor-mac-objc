import Cocoa

@objc(MainWindowController)
class MainWindowController: NSWindowController, NSWindowDelegate {
    private static let minimumContentSize = NSSize(width: 720.0, height: 480.0)
    private static let frameAutosaveName = "MarkdownEditorMainWindow"
    private var confirmedCloseInProgress = false

    @objc var converters: [String] {
        ConverterManager.shared.converters
    }

    @objc var selectedConverterIndex: UInt {
        get { UInt(ConverterManager.shared.selectedConverterIndex) }
        set { ConverterManager.shared.selectedConverterIndex = Int(newValue) }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        windowFrameAutosaveName = Self.frameAutosaveName
        window?.contentMinSize = Self.minimumContentSize
        guard let window else {
            return
        }
        let contentSize = window.contentView?.frame.size ?? .zero
        if contentSize.width < Self.minimumContentSize.width ||
            contentSize.height < Self.minimumContentSize.height {
            window.setContentSize(Self.minimumContentSize)
            window.center()
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !confirmedCloseInProgress,
              let editorViewController = findEditorViewController(in: contentViewController),
              editorViewController.dirty else {
            return true
        }

        editorViewController.confirmClosing { [weak self, weak sender] shouldClose in
            guard let self else {
                return
            }
            guard shouldClose else {
                return
            }
            self.confirmedCloseInProgress = true
            sender?.close()
        }
        return false
    }

    private func findEditorViewController(in viewController: NSViewController?) -> EditorViewController? {
        guard let viewController else {
            return nil
        }
        if let editorViewController = viewController as? EditorViewController {
            return editorViewController
        }
        for child in viewController.children {
            if let editorViewController = findEditorViewController(in: child) {
                return editorViewController
            }
        }
        return nil
    }
}
