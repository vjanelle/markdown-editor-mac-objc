//
//  MarkdownEditorUITests.m
//  MarkdownEditorUITests
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface MarkdownEditorUITests : XCTestCase

@end

@implementation MarkdownEditorUITests

- (XCUIApplication *)launchApplication {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    return app;
}

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    XCUIApplication *app = [self launchApplication];
    XCUIElement *window = app.windows[@"MarkdownEditor Lite"];
    XCUIElement *editorTextView = app.textViews[@"EditorTextView"];
    XCUIElement *converterPopup = app.popUpButtons[@"ConverterPopup"];

    XCTAssertTrue([window waitForExistenceWithTimeout:5]);
    XCTAssertEqual(app.windows.count, 1U);
    XCTAssertTrue([editorTextView waitForExistenceWithTimeout:5]);
    XCTAssertTrue([converterPopup waitForExistenceWithTimeout:5]);
    XCTAssertTrue(editorTextView.isHittable);
    XCTAssertTrue(converterPopup.isHittable);
    XCTAssertGreaterThan(app.buttons.count, 1U);
}

@end
