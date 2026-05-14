//
//  AppDelegate.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) MainWindowController *mainWindowController;

@end

@implementation AppDelegate

static NSString * const MarkdownEditorRepositoryURLString = @"https://github.com/satoshi-iwaki/markdown-editor-mac-objc";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    self.mainWindowController = (MainWindowController *)[storyboard instantiateControllerWithIdentifier:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
}

- (IBAction)showAboutPanel:(id)sender {
    NSMutableAttributedString *credits = [[NSMutableAttributedString alloc] initWithString:@"Portions Copyright (c) 2026 Vincent Janelle\n"];
    NSAttributedString *prefix = [[NSAttributedString alloc] initWithString:@"Portions Copyright (c) 2018 Satoshi Iwaki, "];
    [credits appendAttributedString:prefix];
    NSDictionary *linkAttributes = @{
        NSLinkAttributeName: [NSURL URLWithString:MarkdownEditorRepositoryURLString],
        NSForegroundColorAttributeName: NSColor.linkColor,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    NSAttributedString *link = [[NSAttributedString alloc] initWithString:@"Github"
                                                               attributes:linkAttributes];
    [credits appendAttributedString:link];

    [NSApp orderFrontStandardAboutPanelWithOptions:@{
        NSAboutPanelOptionCredits: credits
    }];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [self.mainWindowController showWindow:self];
        [self.mainWindowController.window makeKeyAndOrderFront:self];
    }
    return YES;
}


@end
