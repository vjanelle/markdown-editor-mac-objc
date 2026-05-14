#import <Foundation/Foundation.h>
#import "../Converter/TextConverter.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditorTextFormatter : NSObject

- (instancetype)initWithConverter:(TextConverter *)converter;

- (NSString *)stringByApplyingFormat:(TextConverterFormat)format
                              toText:(NSString *)text
                               range:(NSRange)range
                       selectedRange:(nullable NSRange *)selectedRange;

@end

NS_ASSUME_NONNULL_END
