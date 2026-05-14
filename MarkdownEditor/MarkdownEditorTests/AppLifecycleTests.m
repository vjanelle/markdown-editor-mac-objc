//
//  AppLifecycleTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/AppDelegate.h"
#import "../MarkdownEditor/Sources/MainWindowController.h"
#import "../MarkdownEditor/Sources/Converter/ConverterManager.h"

@interface TestAppDelegate : AppDelegate
@property (nonatomic, strong) MainWindowController *stubWindowController;
@end

@implementation TestAppDelegate

- (NSWindowController *)mainWindowController {
    return self.stubWindowController ?: [super mainWindowController];
}

- (void)setMainWindowController:(MainWindowController *)mainWindowController {
    self.stubWindowController = mainWindowController;
}

@end

@interface AppLifecycleTests : XCTestCase
@end

@implementation AppLifecycleTests

- (NSString *)mainStoryboardContents {
    NSString *testFilePath = [NSString stringWithUTF8String:__FILE__];
    NSString *testsDirectory = [testFilePath stringByDeletingLastPathComponent];
    NSString *storyboardPath = [[testsDirectory stringByDeletingLastPathComponent]
                                stringByAppendingPathComponent:@"MarkdownEditor/Base.lproj/Main.storyboard"];
    return [NSString stringWithContentsOfFile:storyboardPath encoding:NSUTF8StringEncoding error:nil];
}

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

- (void)testMainWindowNotVisibleAtLaunchInStoryboard {
    NSString *storyboard = [self mainStoryboardContents];

    XCTAssertTrue([storyboard containsString:@"visibleAtLaunch=\"NO\""]);
}

- (void)testAppDelegateReopensMainWindowWhenNoVisibleWindows {
    TestAppDelegate *delegate = [[TestAppDelegate alloc] init];
    MainWindowController *controller = [[MainWindowController alloc] init];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 100, 100)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [controller setValue:window forKey:@"window"];
    delegate.stubWindowController = controller;

    BOOL result = [delegate applicationShouldHandleReopen:NSApplication.sharedApplication hasVisibleWindows:NO];

    XCTAssertTrue(result);
    XCTAssertTrue(window.isVisible);
}

@end
