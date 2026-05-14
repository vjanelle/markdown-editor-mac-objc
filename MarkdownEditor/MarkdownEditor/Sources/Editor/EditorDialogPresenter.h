//
//  EditorDialogPresenter.h
//  MarkdownEditor
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorDialogPresenter : NSObject

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                 forWindow:(NSWindow *)window;

- (void)confirmDiscardingChangesForWindow:(NSWindow *)window
                        completionHandler:(void (^)(NSModalResponse returnCode))handler;

- (void)showOpenFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler;

- (void)showSaveFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler;

@end

NS_ASSUME_NONNULL_END
