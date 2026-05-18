//
//  ConverterManagerTests.m
//  MarkdownEditorTests
//
//  Created by Codex on 2026/05/13.
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/ConverterManager.h"

@interface ConverterManagerTests : XCTestCase
@end

@implementation ConverterManagerTests

- (NSString *)sampleMarkdown {
    NSString *testFilePath = [NSString stringWithUTF8String:__FILE__];
    NSString *testsDirectory = [testFilePath stringByDeletingLastPathComponent];
    NSString *samplePath = [[testsDirectory stringByDeletingLastPathComponent]
                            stringByAppendingPathComponent:@"MarkdownEditor/Resources/sample.md"];
    return [NSString stringWithContentsOfFile:samplePath encoding:NSUTF8StringEncoding error:nil];
}

- (void)testConverterTitlesAreExposedInDisplayOrder {
    NSArray<NSString *> *titles = ConverterManager.sharedInstance.converters;

    XCTAssertEqualObjects(titles, (@[
        @"GitHub Flavored Markdown",
        @"Markdown",
        @"PHP Markdown Extra",
        @"Strict Markdown",
    ]));
}

- (void)testSelectedConverterIndexChangesSelectedConverter {
    ConverterManager.sharedInstance.selectedConverterIndex = 1;
    XCTAssertEqualObjects(ConverterManager.sharedInstance.selectedConverter.title, @"Markdown");

    ConverterManager.sharedInstance.selectedConverterIndex = 3;
    XCTAssertEqualObjects(ConverterManager.sharedInstance.selectedConverter.title, @"Strict Markdown");
}

- (void)testSetContentPostsDidChangeNotification {
    XCTestExpectation *expectation = [self expectationWithDescription:@"content changed"];
    id observer = [NSNotificationCenter.defaultCenter addObserverForName:ConverterManagerDidChangeContentNotification
                                                                  object:nil
                                                                   queue:nil
                                                              usingBlock:^(NSNotification *note) {
        [expectation fulfill];
    }];

    [ConverterManager.sharedInstance setContentWithString:@"# Title"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:observer];
}

- (void)testConverterManagerDoesNotExposeEmbeddedPreviewServerURL {
    XCTAssertFalse([ConverterManager.sharedInstance respondsToSelector:@selector(url)]);
}

- (void)testSampleMarkdownIncludesMermaidDiagramBlock {
    NSString *sample = [self sampleMarkdown];

    XCTAssertTrue([sample containsString:@"```mermaid"]);
    XCTAssertTrue([sample containsString:@"graph TD"]);
}

@end
