import Cocoa

@objc(EditorViewController)
class EditorViewController: NSViewController, NSTextViewDelegate {
    private static let autosaveDelay: TimeInterval = 0.5

    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var converterPopup: NSPopUpButton!

    @objc var filePath: String?
    @objc var dirty = false
    @objc lazy var dialogPresenter = EditorDialogPresenter()
    var documentStore = EditorDocumentStore()
    private lazy var fileWatcher = EditorFileWatcher()

    private var presentationWindow: NSWindow? {
        viewIfLoaded?.window
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.setAccessibilityIdentifier("EditorTextView")
        converterPopup.setAccessibilityIdentifier("ConverterPopup")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(editorFontSettingsDidChange),
            name: PreferenceManager.editorFontSettingsDidChange,
            object: PreferenceManager.shared
        )
        applyEditorFont()
        textView.string = loadSample()
        ConverterManager.shared.setContent(with: textView.string)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
        fileWatcher.stopWatching()
    }

    @objc private func editorFontSettingsDidChange() {
        applyEditorFont()
    }

    private func applyEditorFont() {
        let preferences = PreferenceManager.shared
        textView.font = NSFontManager.shared.font(
            withFamily: preferences.editorFontName,
            traits: [],
            weight: 5,
            size: preferences.editorFontSize
        ) ?? NSFont.systemFont(ofSize: preferences.editorFontSize)
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

    @IBAction func boldButtonClicked(_ sender: Any?) {
        applyFormat(.bold)
    }

    @IBAction func strikeThroughButtonClicked(_ sender: Any?) {
        applyFormat(.strikeThrough)
    }

    @IBAction func italicButtonClicked(_ sender: Any?) {
        applyFormat(.italic)
    }

    @IBAction func quoteButtonClicked(_ sender: Any?) {
        applyFormat(.quote)
    }

    @IBAction func codeButtonClicked(_ sender: Any?) {
        applyFormat(.code)
    }

    @IBAction func insertLinkButtonClicked(_ sender: Any?) {
        applyFormat(.link)
    }

    @IBAction func listBulletedButtonClicked(_ sender: Any?) {
        applyFormat(.listBulleted)
    }

    @IBAction func listNumberedButtonClicked(_ sender: Any?) {
        applyFormat(.listNumbered)
    }

    @IBAction func newDocument(_ sender: Any?) {
        confirmReplacingDocument { [weak self] shouldReplace in
            if shouldReplace {
                self?.newFile()
            }
        }
    }

    @IBAction func openDocument(_ sender: Any?) {
        confirmReplacingDocument { [weak self] shouldReplace in
            if shouldReplace {
                self?.promptForOpenURL(completionHandler: nil)
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

    func confirmClosing(completionHandler handler: @escaping (Bool) -> Void) {
        confirmReplacingDocument { [weak self] shouldClose in
            if shouldClose, let self {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
                self.dirty = false
            }
            handler(shouldClose)
        }
    }

    func confirmReplacingDocument(completionHandler handler: @escaping (Bool) -> Void) {
        guard dirty else {
            handler(true)
            return
        }

        dialogPresenter.confirmDiscardingChanges(for: presentationWindow) { [weak self] returnCode in
            guard let self else {
                handler(false)
                return
            }
            switch returnCode {
            case .alertFirstButtonReturn:
                if self.saveFile() {
                    handler(true)
                } else {
                    self.promptForSaveURL(completionHandler: handler)
                }
            case .alertThirdButtonReturn:
                handler(true)
            default:
                handler(false)
            }
        }
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
                success = self.openFile(at: selectedURL.path)
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
                let previousPath = self.filePath
                self.filePath = selectedURL.path
                success = self.saveFile()
                if !success {
                    self.filePath = previousPath
                }
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

    func openFile(at path: String) -> Bool {
        let previousPath = filePath
        filePath = path
        guard openFile() else {
            filePath = previousPath
            return false
        }
        return true
    }

    @objc func openFile() -> Bool {
        guard let filePath else {
            return false
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return false
        }

        guard let string = try? documentStore.readString(from: URL(fileURLWithPath: filePath)) else {
            return false
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(autosaveIfNeeded), object: nil)
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
        do {
            try documentStore.writeString(textView.string, to: URL(fileURLWithPath: filePath))
            dirty = false
            startWatchingCurrentFile()
            return true
        } catch {
            return false
        }
    }
}
