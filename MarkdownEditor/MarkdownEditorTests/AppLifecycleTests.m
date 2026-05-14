//
//  AppLifecycleTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/AppDelegate.h"
#import "../MarkdownEditor/Sources/MainWindowController.h"
#import "../MarkdownEditor/Sources/Converter/ConverterManager.h"

@interface AppLifecycleTests : XCTestCase
@end

@implementation AppLifecycleTests

- (void)testMainWindowControllerUpdatesSelectedConverterIndex {
    MainWindowController *controller = [[MainWindowController alloc] init];

    controller.selectedConverterIndex = 2;

    XCTAssertEqual(ConverterManager.sharedInstance.selectedConverterIndex, 2);
}

- (void)testAppDelegateAcceptsTerminationNotification {
    AppDelegate *delegate = [[AppDelegate alloc] init];
    NSNotification *notification = [NSNotification notificationWithName:NSApplicationWillTerminateNotification
                                                                  object:nil];

    [delegate applicationWillTerminate:notification];

    XCTAssertNotNil(delegate);
}

@end
