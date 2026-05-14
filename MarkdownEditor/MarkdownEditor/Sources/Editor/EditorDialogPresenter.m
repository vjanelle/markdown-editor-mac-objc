//
//  EditorDialogPresenter.m
//  MarkdownEditor
//

#import "EditorDialogPresenter.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation EditorDialogPresenter

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                 forWindow:(NSWindow *)window {
    if (!NSThread.isMainThread) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:title message:message forWindow:window];
        });
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = title;
    alert.messageText = message;
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:window completionHandler:nil];
}

- (void)confirmDiscardingChangesForWindow:(NSWindow *)window
                        completionHandler:(void (^)(NSModalResponse returnCode))handler {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = @"Your changes will be lost if you don't save them.";
    alert.messageText = @"Do you want to save the changes you made to New file?";
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Don't Save"];
    [alert beginSheetModalForWindow:window completionHandler:handler];
}

- (void)showOpenFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.directoryURL = [NSURL fileURLWithPath:initialPath];
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    panel.canSelectHiddenExtension = YES;
    [panel beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
        handler(result == NSModalResponseOK ? panel.URL : nil);
    }];
}

- (void)showSaveFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.directoryURL = [NSURL fileURLWithPath:initialPath];
    NSMutableArray<UTType *> *allowedContentTypes = [NSMutableArray array];
    UTType *mdType = [UTType typeWithFilenameExtension:@"md"];
    UTType *markdownType = [UTType typeWithFilenameExtension:@"markdown"];
    if (mdType) {
        [allowedContentTypes addObject:mdType];
    }
    if (markdownType) {
        [allowedContentTypes addObject:markdownType];
    }
    panel.allowedContentTypes = allowedContentTypes;
    panel.canSelectHiddenExtension = YES;
    [panel beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
        handler(result == NSModalResponseOK ? panel.URL : nil);
    }];
}

@end
