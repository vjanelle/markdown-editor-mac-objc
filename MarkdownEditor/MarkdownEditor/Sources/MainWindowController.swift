import Cocoa

@objc(MainWindowController)
class MainWindowController: NSWindowController {
    private static let minimumContentSize = NSSize(width: 1200.0, height: 800.0)
    private static let frameAutosaveName = "MarkdownEditorMainWindow"

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
}
