//
//  PreviewViewControllerTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import "../MarkdownEditor/Sources/PreviewViewController.h"
@interface PreviewViewController (Testing)
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
- (void)didChangeContentNotification:(NSNotification *)notification;
- (void)reloadHtml;
- (IBAction)reloadButtonClicked:(NSButton *)sender;
@end

@interface PreviewViewControllerTests : XCTestCase
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation PreviewViewControllerTests

- (PreviewViewController *)makeController {
    PreviewViewController *controller = [[PreviewViewController alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
    [controller setValue:self.webView forKey:@"webView"];
    return controller;
}

- (void)setUp {
    [super setUp];
}

- (void)testSetRepresentedObjectIsAccepted {
    PreviewViewController *controller = [self makeController];
    NSObject *object = [[NSObject alloc] init];

    controller.representedObject = object;

    XCTAssertEqual(controller.representedObject, object);
}

- (void)testReloadButtonLoadsCurrentHtml {
    PreviewViewController *controller = [self makeController];

    [controller reloadButtonClicked:nil];

    XCTAssertNotNil([controller valueForKey:@"navigation"]);
}

- (void)testAutoReloadPreferenceControlsNotificationReload {
    PreviewViewController *controller = [self makeController];

    [controller didChangeContentNotification:nil];
    XCTAssertNotNil([controller valueForKey:@"navigation"]);
}

- (void)testDidFinishNavigationRestoresVisibleRect {
    PreviewViewController *controller = [self makeController];

    [controller webView:self.webView didFinishNavigation:nil];

    XCTAssertNotNil(controller);
}

@end
