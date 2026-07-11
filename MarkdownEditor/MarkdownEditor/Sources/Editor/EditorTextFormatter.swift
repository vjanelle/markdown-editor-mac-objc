import Foundation

@objc(EditorTextFormatter)
class EditorTextFormatter: NSObject {
    private let converter: TextConverter

    @objc(initWithConverter:)
    init(converter: TextConverter) {
        self.converter = converter
        super.init()
    }

    @objc(stringByApplyingFormat:toText:range:selectedRange:)
    func stringByApplyingFormat(
        _ format: TextConverterFormat,
        toText text: String,
        range: NSRange,
        selectedRange: UnsafeMutablePointer<NSRange>?
    ) -> String {
        guard range.length > 0, let swiftRange = Range(range, in: text) else {
            selectedRange?.pointee = range
            return text
        }

        let selectedString = String(text[swiftRange])
        let formattedString = converter.formattedString(with: selectedString, format: format)
        var mutableText = text
        mutableText.replaceSubrange(swiftRange, with: formattedString)
        selectedRange?.pointee = NSRange(location: range.location, length: (formattedString as NSString).length)
        return mutableText
    }
}
