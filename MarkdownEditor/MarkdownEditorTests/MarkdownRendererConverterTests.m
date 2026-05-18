//
//  MarkdownRendererConverterTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/MarkdownRendererConverter.h"

@interface MarkdownRendererConverterTests : XCTestCase
@end

@implementation MarkdownRendererConverterTests

- (void)testExposesFormatAndCss {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    XCTAssertEqualObjects(converter.title, @"Title");
    XCTAssertEqualObjects(converter.format, @"gfm");
    XCTAssertEqualObjects(converter.css, @"style.css");
    XCTAssertNil(converter.header);
}

- (void)testRendersMarkdownContainingApostrophesWithoutShellEscaping {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"# Bob's Notes"];

    XCTAssertTrue([converter.html containsString:@"Bob"]);
    XCTAssertTrue([converter.html containsString:@"Notes"]);
    XCTAssertFalse([converter.html containsString:@"unexpected EOF"]);
}

- (void)testRawHTMLIsNotRenderedAsExecutableMarkup {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"<script>alert('x')</script>\n\n<img src=\"https://example.com/tracker.png\">"];

    XCTAssertFalse([converter.html containsString:@"<script>"]);
    XCTAssertFalse([converter.html containsString:@"<img src=\"https://example.com/tracker.png\">"]);
    XCTAssertTrue([converter.html containsString:@"&lt;script&gt;"] ||
                  [converter.html containsString:@"alert"]);
}

- (void)testDangerousMarkdownLinksAreRenderedWithoutHref {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"[Run JavaScript](javascript:alert(1))"];

    XCTAssertFalse([converter.html containsString:@"href=\"javascript:"]);
    XCTAssertTrue([converter.html containsString:@"Run JavaScript"]);
}

- (void)testRemoteMarkdownImagesAreNotRenderedAsImages {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"![Tracker](https://example.com/tracker.png)"];

    XCTAssertFalse([converter.html containsString:@"<img"]);
    XCTAssertFalse([converter.html containsString:@"https://example.com/tracker.png"]);
    XCTAssertTrue([converter.html containsString:@"Tracker"]);
}

- (void)testAbsoluteFileMarkdownImagesAreNotRenderedAsImages {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"![Secret](file:///Users/random/Documents/secret.png)"];

    XCTAssertFalse([converter.html containsString:@"<img"]);
    XCTAssertFalse([converter.html containsString:@"file:///Users/random/Documents/secret.png"]);
    XCTAssertTrue([converter.html containsString:@"Secret"]);
}

- (void)testRelativeMarkdownImagesAreRenderedAsImages {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    [converter setContentWithString:@"![Diagram](diagram.png)"];

    XCTAssertTrue([converter.html containsString:@"<img src=\"diagram.png\""]);
    XCTAssertTrue([converter.html containsString:@"alt=\"Diagram\""]);
}

- (void)testInlineFormattingMatchesMarkdownSyntax {
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
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
    MarkdownRendererConverter *converter = [[MarkdownRendererConverter alloc] initWithTitle:@"Title"
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
