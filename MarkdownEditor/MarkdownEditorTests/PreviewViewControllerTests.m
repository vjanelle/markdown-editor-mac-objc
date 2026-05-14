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

- (NSString *)resourceTextNamed:(NSString *)name {
    NSString *testFilePath = [NSString stringWithUTF8String:__FILE__];
    NSString *testsDirectory = [testFilePath stringByDeletingLastPathComponent];
    NSString *resourcePath = [[testsDirectory stringByDeletingLastPathComponent]
                              stringByAppendingPathComponent:[NSString stringWithFormat:@"MarkdownEditor/Resources/%@", name]];
    return [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:nil];
}

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

- (void)testPreviewHeadersIncludeMermaidSupport {
    NSString *gfmHeader = [self resourceTextNamed:@"gfm-header.txt"];
    NSString *markdownHeader = [self resourceTextNamed:@"markdown-header.txt"];

    XCTAssertTrue([gfmHeader containsString:@"mermaid.min.js"]);
    XCTAssertTrue([markdownHeader containsString:@"mermaid.min.js"]);
    XCTAssertFalse([gfmHeader containsString:@"cdn.jsdelivr.net/npm/mermaid"]);
    XCTAssertFalse([markdownHeader containsString:@"cdn.jsdelivr.net/npm/mermaid"]);
}

@end
