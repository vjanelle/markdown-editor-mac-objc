import Foundation

extension Notification.Name {
    static let converterManagerDidChangeContent = Notification.Name("ConverterManagerDidChangeContentNotification")
}

@objc(ConverterManager)
class ConverterManager: NSObject {
    @objc(ConverterManagerDidChangeContentNotification)
    static let didChangeContentNotification = Notification.Name.converterManagerDidChangeContent

    @objc(sharedInstance)
    static let shared = ConverterManager()

    private var string: String?
    private let availableConverters: [TextConverter] = [
        GfmConverter(),
        MarkdownConverter(),
        StrictMarkdownConverter()
    ]

    @objc var html: String {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return selectedConverter.html
    }

    @objc var converters: [String] {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return availableConverters.map(\.title)
    }

    @objc var selectedConverterIndex: Int = 0 {
        didSet {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if string != nil {
                reload()
            }
        }
    }

    @objc var selectedConverter: TextConverter {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return availableConverters[selectedConverterIndex]
    }

    @objc(setContentWithString:)
    func setContent(with string: String) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        let converter = selectedConverter
        converter.setContent(with: string)
        logVerbose("*** HTML ***")
        logVerbose(converter.html)
        self.string = string
        didChangeContent()
    }

    private func didChangeContent() {
        NotificationCenter.default.post(name: Self.didChangeContentNotification, object: nil)
    }

    private func reload() {
        guard let string else {
            return
        }
        setContent(with: string)
    }
}
