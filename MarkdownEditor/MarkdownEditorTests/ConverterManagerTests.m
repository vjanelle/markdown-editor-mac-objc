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

- (void)testURLPointsToIndexHtml {
    NSURL *url = ConverterManager.sharedInstance.url;

    XCTAssertNotNil(url);
    XCTAssertEqualObjects(url.path, @"/index.html");
    XCTAssertGreaterThan(url.port.integerValue, 0);
}

@end
