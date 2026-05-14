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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    self.mainWindowController = (MainWindowController *)[storyboard instantiateControllerWithIdentifier:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
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
