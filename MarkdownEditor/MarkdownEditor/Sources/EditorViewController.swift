import Cocoa

@objc(EditorViewController)
class EditorViewController: NSViewController, NSTextViewDelegate {
    private static let autosaveDelay: TimeInterval = 0.5
    private static let formattingButtonWidth: CGFloat = 32.0
    private static let formattingButtonHeight: CGFloat = 25.0
    private static let formattingButtonGap: CGFloat = 8.0
    private static let formattingToolbarPadding: CGFloat = 6.0
    private static let converterPopupWidth: CGFloat = 170.0
    private static let converterPopupHeight: CGFloat = 25.0

    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var converterPopup: NSPopUpButton!

    @objc var filePath: String?
    @objc var dirty = false
    @objc lazy var dialogPresenter = EditorDialogPresenter()
    private lazy var fileWatcher = EditorFileWatcher()

    private var presentationWindow: NSWindow? {
        viewIfLoaded?.window
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.setAccessibilityIdentifier("EditorTextView")
        converterPopup.setAccessibilityIdentifier("ConverterPopup")
        configureFormattingButtons()
        textView.string = loadSample()
        ConverterManager.shared.setContent(with: textView.string)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        configureFormattingButtons()
        layoutFormattingToolbar()
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        fileWatcher.stopWatching()
    }

    func textDidEndEditing(_ notification: Notification) {
        ConverterManager.shared.setContent(with: textView.string)
        dirty = true
        scheduleAutosave()
    }

    func textDidChange(_ notification: Notification) {
        ConverterManager.shared.setContent(with: textView.string)
        dirty = true
        scheduleAutosave()
    }

    func textView(
        _ textView: NSTextView,
        shouldChangeTextInRanges affectedRanges: [NSValue],
        replacementStrings: [String]?
    ) -> Bool {
        true
    }

    @IBAction func boldButtonClicked(_ sender: NSButton?) {
        applyFormat(.bold)
    }

    @IBAction func strikeThroughButtonClicked(_ sender: NSButton?) {
        applyFormat(.strikeThrough)
    }

    @IBAction func italicButtonClicked(_ sender: NSButton?) {
        applyFormat(.italic)
    }

    @IBAction func quoteButtonClicked(_ sender: NSButton?) {
        applyFormat(.quote)
    }

    @IBAction func codeButtonClicked(_ sender: NSButton?) {
        applyFormat(.code)
    }

    @IBAction func insertLinkButtonClicked(_ sender: NSButton?) {
        applyFormat(.link)
    }

    @IBAction func listBulletedButtonClicked(_ sender: NSButton?) {
        applyFormat(.listBulleted)
    }

    @IBAction func listNumberedButtonClicked(_ sender: NSButton?) {
        applyFormat(.listNumbered)
    }

    @IBAction func newDocument(_ sender: Any?) {
        if !dirty {
            newFile()
            return
        }
        dialogPresenter.confirmDiscardingChanges(for: presentationWindow) { [weak self] returnCode in
            guard let self else {
                return
            }
            switch returnCode {
            case .alertFirstButtonReturn:
                if self.saveFile() {
                    return
                }
                self.promptForSaveURL { result in
                    if result {
                        self.newFile()
                    }
                }
            case .alertThirdButtonReturn:
                self.newFile()
            default:
                break
            }
        }
    }

    @IBAction func openDocument(_ sender: Any?) {
        if !dirty {
            promptForOpenURL(completionHandler: nil)
            return
        }
        dialogPresenter.confirmDiscardingChanges(for: presentationWindow) { [weak self] returnCode in
            guard let self else {
                return
            }
            switch returnCode {
            case .alertFirstButtonReturn:
                if self.saveFile() {
                    return
                }
                self.promptForSaveURL { result in
                    if result {
                        self.promptForOpenURL(completionHandler: nil)
                    }
                }
            case .alertThirdButtonReturn:
                self.promptForOpenURL(completionHandler: nil)
            default:
                break
            }
        }
    }

    @IBAction func saveDocument(_ sender: Any?) {
        if saveFile() {
            return
        }
        promptForSaveURL(completionHandler: nil)
    }

    @IBAction func saveDocumentAs(_ sender: Any?) {
        promptForSaveURL(completionHandler: nil)
    }

    private var formattingButtons: [NSButton] {
        formattingButtonItems.compactMap { formattingButton(in: view, matchingSelectorName: NSStringFromSelector($0.selector)) }
    }

    private var formattingButtonItems: [(selector: Selector, toolTip: String)] {
        [
            (#selector(boldButtonClicked(_:)), "Bold"),
            (#selector(strikeThroughButtonClicked(_:)), "Strikethrough"),
            (#selector(italicButtonClicked(_:)), "Italic"),
            (#selector(quoteButtonClicked(_:)), "Block Quote"),
            (#selector(codeButtonClicked(_:)), "Code"),
            (#selector(insertLinkButtonClicked(_:)), "Insert Link"),
            (#selector(listBulletedButtonClicked(_:)), "Bulleted List"),
            (#selector(listNumberedButtonClicked(_:)), "Numbered List")
        ]
    }

    private func configureFormattingButtons() {
        let iconColor = toolbarIconColor()
        for item in formattingButtonItems {
            guard let button = formattingButton(in: view, matchingSelectorName: NSStringFromSelector(item.selector)) else {
                continue
            }
            if let image = button.image {
                button.image = tintedNonTemplateImage(from: image, color: iconColor)
            }
            button.imagePosition = .imageOnly
            button.contentTintColor = nil
            button.toolTip = item.toolTip
        }
    }

    private func toolbarIconColor() -> NSColor {
        let appearanceName = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return appearanceName == .darkAqua
            ? NSColor(calibratedWhite: 0.86, alpha: 1.0)
            : NSColor(calibratedWhite: 0.20, alpha: 1.0)
    }

    private func tintedNonTemplateImage(from image: NSImage, color: NSColor) -> NSImage {
        let tintedImage = NSImage(size: image.size)
        tintedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: image.size), from: .zero, operation: .sourceOver, fraction: 1.0)
        color.setFill()
        NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        tintedImage.isTemplate = false
        return tintedImage
    }

    private func formattingButton(in view: NSView, matchingSelectorName selectorName: String) -> NSButton? {
        for subview in view.subviews {
            if let button = subview as? NSButton,
               let action = button.action,
               NSStringFromSelector(action) == selectorName {
                return button
            }
            if let button = formattingButton(in: subview, matchingSelectorName: selectorName) {
                return button
            }
        }
        return nil
    }

    private func layoutFormattingToolbar() {
        let bounds = view.bounds
        guard let scrollView = textView.enclosingScrollView else {
            return
        }

        let top = bounds.maxY - Self.formattingToolbarPadding
        let buttonY = top - Self.formattingButtonHeight
        var x = Self.formattingToolbarPadding
        for button in formattingButtons {
            button.frame = NSRect(
                x: x,
                y: buttonY,
                width: Self.formattingButtonWidth,
                height: Self.formattingButtonHeight
            )
            x += Self.formattingButtonWidth + Self.formattingButtonGap
        }

        if let converterPopup {
            let popupWidth = min(Self.converterPopupWidth, max(0.0, bounds.width - (2.0 * Self.formattingToolbarPadding)))
            let popupX = max(x, bounds.width - popupWidth - Self.formattingToolbarPadding)
            converterPopup.frame = NSRect(
                x: popupX,
                y: buttonY,
                width: popupWidth,
                height: Self.converterPopupHeight
            )
        }

        let scrollViewHeight = max(0.0, buttonY - Self.formattingToolbarPadding)
        scrollView.frame = NSRect(x: 0.0, y: 0.0, width: bounds.width, height: scrollViewHeight)
    }

    private func loadSample() -> String {
        ConverterManager.shared.selectedConverter.sample ?? ""
    }

    @objc func documentBody() -> String {
        textView?.string ?? "Unknown"
    }

    @objc(replaceCharactersInRange:withString:)
    func replaceCharacters(in range: NSRange, with string: String) {
        guard textView.shouldChangeText(in: range, replacementString: string) else {
            return
        }
        textView.replaceCharacters(in: range, with: string)
        textView.didChangeText()
        dirty = true
    }

    @objc func applyFormat(_ format: TextConverterFormat) {
        let range = textView.selectedRange()
        guard range.length > 0 else {
            return
        }

        let formatter = EditorTextFormatter(converter: ConverterManager.shared.selectedConverter)
        var selectedRange = range
        let updatedString = formatter.stringByApplyingFormat(
            format,
            toText: textView.string,
            range: range,
            selectedRange: &selectedRange
        )
        textView.string = updatedString
        textView.setSelectedRange(selectedRange)
        ConverterManager.shared.setContent(with: textView.string)
        dirty = true
        scheduleAutosave()
    }

    @objc var defaultDirectoryPath: String {
        filePath ?? NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
    }

    private func startWatchingCurrentFile() {
        fileWatcher.watchFile(atPath: filePath) { [weak self] in
            self?.reloadFileFromDiskIfNeeded()
        }
    }

    private func scheduleAutosave() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        perform(#selector(autosaveIfNeeded), with: nil, afterDelay: Self.autosaveDelay)
    }

    @objc func autosaveIfNeeded() {
        guard dirty, filePath != nil else {
            return
        }
        _ = saveFile()
    }

    @objc func reloadFileFromDiskIfNeeded() {
        guard !dirty, filePath != nil else {
            return
        }
        if !openFile() {
            fileWatcher.stopWatching()
        }
    }

    @objc(promptForOpenURLWithCompletionHandler:)
    func promptForOpenURL(completionHandler handler: ((Bool) -> Void)?) {
        dialogPresenter.showOpenFilePanel(for: presentationWindow, initialPath: defaultDirectoryPath) { [weak self] selectedURL in
            guard let self else {
                handler?(false)
                return
            }
            var success = false
            if let selectedURL {
                self.filePath = selectedURL.path
                success = self.openFile()
            }
            handler?(success)
        }
    }

    @objc(promptForSaveURLWithCompletionHandler:)
    func promptForSaveURL(completionHandler handler: ((Bool) -> Void)?) {
        dialogPresenter.showSaveFilePanel(for: presentationWindow, initialPath: defaultDirectoryPath) { [weak self] selectedURL in
            guard let self else {
                handler?(false)
                return
            }
            var success = false
            if let selectedURL {
                self.filePath = selectedURL.path
                success = self.saveFile()
            }
            handler?(success)
        }
    }

    @objc func newFile() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        textView.string = "New File"
        ConverterManager.shared.setContent(with: textView.string)
        filePath = nil
        dirty = false
        fileWatcher.stopWatching()
    }

    @objc func openFile() -> Bool {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        guard let filePath else {
            return false
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return false
        }

        let store = EditorDocumentStore()
        guard let string = try? store.readString(from: URL(fileURLWithPath: filePath)) else {
            return false
        }

        dirty = false
        textView.string = string
        ConverterManager.shared.setContent(with: textView.string)
        startWatchingCurrentFile()
        return true
    }

    @objc func saveFile() -> Bool {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        guard let filePath else {
            return false
        }
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                return false
            }
        }

        dirty = false
        let store = EditorDocumentStore()
        do {
            try store.writeString(textView.string, to: URL(fileURLWithPath: filePath))
            startWatchingCurrentFile()
            return true
        } catch {
            return false
        }
    }
}
