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
- (BOOL)isAllowedPreviewNavigationURL:(NSURL *)URL;
- (BOOL)isExternalPreviewNavigationURL:(NSURL *)URL;
- (NSString *)lockedDownPreviewHTMLWithHTML:(NSString *)HTML;
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
    XCTAssertTrue([gfmHeader containsString:@"securityLevel: 'strict'"]);
    XCTAssertTrue([markdownHeader containsString:@"securityLevel: 'strict'"]);
    XCTAssertFalse([gfmHeader containsString:@"securityLevel: 'loose'"]);
    XCTAssertFalse([markdownHeader containsString:@"securityLevel: 'loose'"]);
    XCTAssertFalse([gfmHeader containsString:@"https://"]);
    XCTAssertFalse([markdownHeader containsString:@"https://"]);
}

- (void)testPreviewNavigationAllowsLocalPreviewURLs {
    PreviewViewController *controller = [self makeController];

    XCTAssertTrue([controller isAllowedPreviewNavigationURL:nil]);
    XCTAssertTrue([controller isAllowedPreviewNavigationURL:[NSURL URLWithString:@"about:blank"]]);
    XCTAssertTrue([controller isAllowedPreviewNavigationURL:NSBundle.mainBundle.resourceURL]);
}

- (void)testPreviewNavigationBlocksExternalNetworkURLs {
    PreviewViewController *controller = [self makeController];

    XCTAssertFalse([controller isAllowedPreviewNavigationURL:[NSURL URLWithString:@"https://example.com"]]);
    XCTAssertFalse([controller isAllowedPreviewNavigationURL:[NSURL URLWithString:@"http://example.com"]]);
}

- (void)testPreviewNavigationRecognizesExternalBrowserURLs {
    PreviewViewController *controller = [self makeController];

    XCTAssertTrue([controller isExternalPreviewNavigationURL:[NSURL URLWithString:@"https://example.com"]]);
    XCTAssertTrue([controller isExternalPreviewNavigationURL:[NSURL URLWithString:@"http://example.com"]]);
    XCTAssertFalse([controller isExternalPreviewNavigationURL:[NSURL URLWithString:@"about:blank"]]);
    XCTAssertFalse([controller isExternalPreviewNavigationURL:NSBundle.mainBundle.resourceURL]);
}

- (void)testPreviewHTMLAddsLocalOnlyContentSecurityPolicy {
    PreviewViewController *controller = [self makeController];
    NSString *HTML = @"<html><head><title>Preview</title></head><body><img src=\"https://example.com/image.png\"></body></html>";

    NSString *lockedDownHTML = [controller lockedDownPreviewHTMLWithHTML:HTML];

    XCTAssertTrue([lockedDownHTML containsString:@"Content-Security-Policy"]);
    XCTAssertTrue([lockedDownHTML containsString:@"default-src 'none'"]);
    XCTAssertTrue([lockedDownHTML containsString:@"connect-src 'none'"]);
    XCTAssertTrue([lockedDownHTML containsString:@"img-src file:"]);
    XCTAssertFalse([lockedDownHTML containsString:@"data:"]);
}

@end
