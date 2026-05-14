#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Editor/EditorTextFormatter.h"
#import "../MarkdownEditor/Sources/Converter/MarkdownConverter.h"

@interface EditorTextFormatterTests : XCTestCase
@end

@implementation EditorTextFormatterTests

- (void)testReturnsOriginalTextWhenRangeIsEmpty {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatBold
                                                  toText:@"hello"
                                                   range:NSMakeRange(0, 0)
                                           selectedRange:NULL];

    XCTAssertEqualObjects(result, @"hello");
}

- (void)testAppliesFormatToSelectedRange {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatBold
                                                  toText:@"hello world"
                                                   range:NSMakeRange(6, 5)
                                           selectedRange:&selectedRange];

    XCTAssertEqualObjects(result, @"hello **world**");
    XCTAssertEqual(selectedRange.location, 6);
    XCTAssertEqual(selectedRange.length, 9);
}

- (void)testAppliesBlockFormatToMultilineSelection {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatQuote
                                                  toText:@"one\ntwo"
                                                   range:NSMakeRange(0, 7)
                                           selectedRange:&selectedRange];

    XCTAssertEqualObjects(result, @"> one\n> two\n");
    XCTAssertEqual(selectedRange.location, 0);
    XCTAssertEqual(selectedRange.length, 12);
}

@end
