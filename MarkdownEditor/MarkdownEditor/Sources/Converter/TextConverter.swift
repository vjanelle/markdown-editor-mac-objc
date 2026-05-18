import Foundation

@objc enum TextConverterFormat: UInt {
    case bold
    case italic
    case strikeThrough
    case quote
    case code
    case link
    case listBulleted
    case listNumbered
}

@objc(TextConverter)
class TextConverter: NSObject {
    @objc let title: String

    @objc var sample: String? {
        guard let path = Bundle.main.path(forResource: "sample", ofType: "md"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @objc var html: String {
        "<!DOCTYPE html><html lang=\"ja\"><head><meta charset=\"utf-8\"><title></title></head><body></body></html>"
    }

    @objc var data: Data {
        html.data(using: .utf8) ?? Data()
    }

    @objc var format: String {
        "markdown"
    }

    @objc var css: String? {
        nil
    }

    @objc var script: String? {
        nil
    }

    @objc(initWithTitle:)
    init(title: String) {
        self.title = title
        super.init()
    }

    @objc(formattedStringWithString:format:)
    func formattedString(with string: String, format: TextConverterFormat) -> String {
        string
    }

    @objc(setContentWithString:)
    func setContent(with string: String) {
    }
}
