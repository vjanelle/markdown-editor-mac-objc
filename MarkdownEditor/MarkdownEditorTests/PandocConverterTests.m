//
//  PandocConverterTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/PandocConverter.h"

@interface PandocConverter (Testing)
- (NSString *)commandWithString:(NSString *)string;
@end

@interface PandocConverterTests : XCTestCase
@end

@implementation PandocConverterTests

- (void)testExposesFormatAndCss {
    PandocConverter *converter = [[PandocConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    XCTAssertEqualObjects(converter.title, @"Title");
    XCTAssertEqualObjects(converter.format, @"gfm");
    XCTAssertEqualObjects(converter.css, @"style.css");
    XCTAssertNil(converter.header);
}

- (void)testBuildsPandocCommand {
    PandocConverter *converter = [[PandocConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    NSString *command = [converter commandWithString:@"# Title"];

    XCTAssertTrue([command containsString:@"echo '# Title' | pandoc"]);
    XCTAssertTrue([command containsString:@"-f gfm"]);
    XCTAssertTrue([command containsString:@"-c style.css"]);
    XCTAssertTrue([command containsString:@"-t html"]);
    XCTAssertTrue([command containsString:@"-s"]);
}

- (void)testInlineFormattingMatchesMarkdownSyntax {
    PandocConverter *converter = [[PandocConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];
    NSDictionary<NSNumber *, NSString *> *expectations = @{
        @(TextConverterFormatBold): @"**text**",
        @(TextConverterFormatItalic): @"*text*",
        @(TextConverterFormatStrikeThrough): @"~~text~~",
        @(TextConverterFormatLink): @"[text](url)",
    };

    for (NSNumber *format in expectations) {
        XCTAssertEqualObjects([converter formattedStringWithString:@"text" format:format.unsignedIntegerValue],
                              expectations[format]);
    }
}

- (void)testBlockFormattingMatchesMarkdownSyntax {
    PandocConverter *converter = [[PandocConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];
    NSDictionary<NSNumber *, NSString *> *expectations = @{
        @(TextConverterFormatCode): @"```\none\ntwo\n```",
        @(TextConverterFormatQuote): @"> one\n> two\n",
        @(TextConverterFormatListBulleted): @"- one\n- two\n",
        @(TextConverterFormatListNumbered): @"1. one\n1. two\n",
    };

    for (NSNumber *format in expectations) {
        XCTAssertEqualObjects([converter formattedStringWithString:@"one\ntwo" format:format.unsignedIntegerValue],
                              expectations[format]);
    }
}

@end
