//
//  MarkdownEditorTests.m
//  MarkdownEditorTests
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/GfmConverter.h"
#import "../MarkdownEditor/Sources/Converter/MarkdownConverter.h"
#import "../MarkdownEditor/Sources/Converter/PhpMarkdownConverter.h"
#import "../MarkdownEditor/Sources/Converter/StrictMarkdownConverter.h"

@interface TextConverter (Testing)
- (NSString *)format;
- (NSString *)css;
- (NSString *)script;
@end

@interface MarkdownEditorTests : XCTestCase

@end

@implementation MarkdownEditorTests

- (NSArray<TextConverter *> *)markdownConverters {
    return @[
        [[MarkdownConverter alloc] init],
        [[GfmConverter alloc] init],
        [[StrictMarkdownConverter alloc] init],
        [[PhpMarkdownConverter alloc] init],
    ];
}

- (void)testInlineMarkdownFormatting {
    NSDictionary<NSNumber *, NSString *> *expectations = @{
        @(TextConverterFormatBold): @"**text**",
        @(TextConverterFormatItalic): @"*text*",
        @(TextConverterFormatStrikeThrough): @"~~text~~",
        @(TextConverterFormatLink): @"[text](url)",
    };

    for (TextConverter *converter in self.markdownConverters) {
        for (NSNumber *format in expectations) {
            NSString *actual = [converter formattedStringWithString:@"text" format:format.unsignedIntegerValue];
            XCTAssertEqualObjects(actual, expectations[format], @"%@", converter.title);
        }
    }
}

- (void)testBlockMarkdownFormatting {
    NSDictionary<NSNumber *, NSString *> *expectations = @{
        @(TextConverterFormatCode): @"```\none\ntwo\n```",
        @(TextConverterFormatQuote): @"> one\n> two\n",
        @(TextConverterFormatListBulleted): @"- one\n- two\n",
        @(TextConverterFormatListNumbered): @"1. one\n1. two\n",
    };

    for (TextConverter *converter in self.markdownConverters) {
        for (NSNumber *format in expectations) {
            NSString *actual = [converter formattedStringWithString:@"one\ntwo" format:format.unsignedIntegerValue];
            XCTAssertEqualObjects(actual, expectations[format], @"%@", converter.title);
        }
    }
}

- (void)testBaseTextConverterDoesNotFormatText {
    TextConverter *converter = [[TextConverter alloc] initWithTitle:@"Text"];

    XCTAssertEqualObjects([converter formattedStringWithString:@"text" format:TextConverterFormatBold], @"text");
}

- (void)testBaseTextConverterDefaultProperties {
    TextConverter *converter = [[TextConverter alloc] initWithTitle:@"Text"];

    XCTAssertEqualObjects([converter format], @"markdown");
    XCTAssertNil([converter css]);
    XCTAssertNil([converter script]);
    XCTAssertTrue([converter.html containsString:@"<html lang=\"ja\">"]);

    [converter setContentWithString:@"# Title"];

    XCTAssertTrue([converter.html containsString:@"<body></body>"]);
}

@end
