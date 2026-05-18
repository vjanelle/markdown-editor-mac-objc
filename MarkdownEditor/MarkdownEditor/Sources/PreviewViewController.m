//
//  PreviewViewController.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "PreviewViewController.h"
#import "ConverterManager.h"

@interface PreviewViewController () <WKNavigationDelegate, WKUIDelegate>

@property (weak) IBOutlet WKWebView *webView;

@end

@implementation PreviewViewController {
    WKNavigation *_navigation;
    NSRect _visibleRect;
}

static NSString * const PreviewAboutScheme = @"about";
static NSString * const PreviewHTTPScheme = @"http";
static NSString * const PreviewHTTPSScheme = @"https";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self replacePreviewWebViewWithLockedDownConfiguration];
    self.view.accessibilityIdentifier = @"PreviewPane";
    self.view.accessibilityElement = YES;
    self.view.accessibilityRole = NSAccessibilityGroupRole;
    self.webView.accessibilityIdentifier = @"PreviewWebView";
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didChangeContentNotification:)
                                               name:ConverterManagerDidChangeContentNotification
                                             object:nil];
    
    _visibleRect = NSZeroRect;
    [self reloadHtml];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self.webView scrollRectToVisible:_visibleRect];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated &&
        [self isExternalPreviewNavigationURL:URL]) {
        [NSWorkspace.sharedWorkspace openURL:URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler([self isAllowedPreviewNavigationURL:URL] ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}

#pragma mark - WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
forNavigationAction:(WKNavigationAction *)navigationAction
                  windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *URL = navigationAction.request.URL;
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated &&
        [self isExternalPreviewNavigationURL:URL]) {
        [NSWorkspace.sharedWorkspace openURL:URL];
    }
    return nil;
}

#pragma mark - Notification Handler

- (void)didChangeContentNotification:(NSNotification *)notification {
    [self reloadHtml];
}

#pragma mark - Private Methods

- (void)replacePreviewWebViewWithLockedDownConfiguration {
    WKWebView *storyboardWebView = self.webView;
    NSView *superview = storyboardWebView.superview;
    if (!superview) {
        return;
    }

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;

    WKWebView *lockedDownWebView = [[WKWebView alloc] initWithFrame:storyboardWebView.frame
                                                      configuration:configuration];
    lockedDownWebView.autoresizingMask = storyboardWebView.autoresizingMask;
    lockedDownWebView.translatesAutoresizingMaskIntoConstraints = storyboardWebView.translatesAutoresizingMaskIntoConstraints;
    lockedDownWebView.navigationDelegate = self;
    lockedDownWebView.UIDelegate = self;

    NSInteger index = [superview.subviews indexOfObject:storyboardWebView];
    [storyboardWebView removeFromSuperview];
    NSView *relativeView = (index != NSNotFound && index < superview.subviews.count) ? superview.subviews[index] : nil;
    [superview addSubview:lockedDownWebView positioned:NSWindowBelow relativeTo:relativeView];
    self.webView = lockedDownWebView;
}

- (void)reloadHtml {
    _visibleRect = self.webView.visibleRect;
    NSString *HTML = [self lockedDownPreviewHTMLWithHTML:ConverterManager.sharedInstance.html];
    _navigation = [self.webView loadHTMLString:HTML
                                       baseURL:NSBundle.mainBundle.resourceURL];
}

- (NSString *)lockedDownPreviewHTMLWithHTML:(NSString *)HTML {
    NSString *contentSecurityPolicy = @"<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src file:; style-src file: 'unsafe-inline'; script-src file: 'unsafe-inline'; font-src file:; connect-src 'none'; frame-src 'none'; media-src file:\">";
    NSRange headEndRange = [HTML rangeOfString:@"</head>" options:NSCaseInsensitiveSearch];
    if (headEndRange.location == NSNotFound) {
        return [contentSecurityPolicy stringByAppendingString:HTML ?: @""];
    }

    NSMutableString *lockedDownHTML = [HTML mutableCopy];
    [lockedDownHTML insertString:contentSecurityPolicy atIndex:headEndRange.location];
    return lockedDownHTML;
}

- (BOOL)isAllowedPreviewNavigationURL:(NSURL *)URL {
    if (!URL) {
        return YES;
    }

    if ([URL.scheme isEqualToString:PreviewAboutScheme]) {
        return YES;
    }

    if (!URL.isFileURL) {
        return NO;
    }

    NSURL *resourceURL = NSBundle.mainBundle.resourceURL.URLByStandardizingPath;
    NSURL *standardizedURL = URL.URLByStandardizingPath;
    NSString *resourcePath = resourceURL.path;
    NSString *URLPath = standardizedURL.path;
    return [URLPath isEqualToString:resourcePath] ||
           [URLPath hasPrefix:[resourcePath stringByAppendingString:@"/"]];
}

- (BOOL)isExternalPreviewNavigationURL:(NSURL *)URL {
    NSString *scheme = URL.scheme.lowercaseString;
    return [scheme isEqualToString:PreviewHTTPScheme] ||
           [scheme isEqualToString:PreviewHTTPSScheme];
}


#pragma mark - Handler

- (IBAction)reloadButtonClicked:(NSButton *)sender {
    [self reloadHtml];
}

@end
