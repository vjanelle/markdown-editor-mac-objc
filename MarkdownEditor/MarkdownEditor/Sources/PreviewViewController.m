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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
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

#pragma mark - Notification Handler

- (void)didChangeContentNotification:(NSNotification *)notification {
    [self reloadHtml];
}

#pragma mark - Private Methods

- (void)reloadHtml {
    _visibleRect = self.webView.visibleRect;
    _navigation = [self.webView loadHTMLString:ConverterManager.sharedInstance.html
                                       baseURL:NSBundle.mainBundle.resourceURL];
}


#pragma mark - Handler

- (IBAction)reloadButtonClicked:(NSButton *)sender {
    [self reloadHtml];
}

@end
