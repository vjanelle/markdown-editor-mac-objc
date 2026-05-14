#import "EditorTextFormatter.h"

@implementation EditorTextFormatter {
    TextConverter *_converter;
}

- (instancetype)initWithConverter:(TextConverter *)converter {
    self = [super init];
    if (self) {
        _converter = converter;
    }
    return self;
}

- (NSString *)stringByApplyingFormat:(TextConverterFormat)format
                              toText:(NSString *)text
                               range:(NSRange)range
                       selectedRange:(NSRange *)selectedRange {
    if (range.length == 0) {
        if (selectedRange) {
            *selectedRange = range;
        }
        return text;
    }

    NSString *selectedString = [text substringWithRange:range];
    NSString *formattedString = [_converter formattedStringWithString:selectedString format:format];
    NSMutableString *mutableText = [text mutableCopy];
    [mutableText replaceCharactersInRange:range withString:formattedString];

    if (selectedRange) {
        *selectedRange = NSMakeRange(range.location, formattedString.length);
    }
    return mutableText;
}

@end
