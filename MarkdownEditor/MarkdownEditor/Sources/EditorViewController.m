//
//  EditorViewController.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "EditorViewController.h"
#import "ConverterManager.h"
#import "TextConverter.h"
#import "Editor/EditorDialogPresenter.h"
#import "Editor/EditorFileWatcher.h"
#import "Editor/EditorDocumentStore.h"
#import "Editor/EditorTextFormatter.h"

@interface EditorViewController () <NSTextViewDelegate> {
    NSString *_filePath;
    BOOL _dirty;
}

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet NSPopUpButton *converterPopup;
@property (nonatomic, strong) EditorDialogPresenter *dialogPresenter;
@property (nonatomic, strong) EditorFileWatcher *fileWatcher;

@end

@implementation EditorViewController

static const NSTimeInterval EditorAutosaveDelay = 0.5;
static const CGFloat EditorFormattingButtonWidth = 32.0;
static const CGFloat EditorFormattingButtonHeight = 25.0;
static const CGFloat EditorFormattingButtonGap = 8.0;
static const CGFloat EditorFormattingToolbarPadding = 6.0;
static const CGFloat EditorConverterPopupWidth = 170.0;
static const CGFloat EditorConverterPopupHeight = 25.0;

- (EditorDialogPresenter *)dialogPresenter {
    if (!_dialogPresenter) {
        _dialogPresenter = [[EditorDialogPresenter alloc] init];
    }
    return _dialogPresenter;
}

- (EditorFileWatcher *)fileWatcher {
    if (!_fileWatcher) {
        _fileWatcher = [[EditorFileWatcher alloc] init];
    }
    return _fileWatcher;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.textView.accessibilityIdentifier = @"EditorTextView";
    self.converterPopup.accessibilityIdentifier = @"ConverterPopup";
    self.textView.string = [self loadSample];
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutFormattingToolbar];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosaveIfNeeded) object:nil];
    [self.fileWatcher stopWatching];
}

#pragma mark - NSTextDelegate

- (void)textDidEndEditing:(NSNotification *)notification {
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
    _dirty = YES;
    [self scheduleAutosave];
}

- (void)textDidChange:(NSNotification *)notification {
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
    _dirty = YES;
    [self scheduleAutosave];
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray<NSValue *> *)affectedRanges replacementStrings:(nullable NSArray<NSString *> *)replacementStrings {
    return YES;
}

#pragma mark - Formatter Handler

- (IBAction)boldButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatBold];
}

- (IBAction)strikeThroughButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatStrikeThrough];
}

- (IBAction)italicButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatItalic];
}

- (IBAction)quoteButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatQuote];
}

- (IBAction)codeButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatCode];
}

- (IBAction)insertLinkButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatLink];
}

- (IBAction)listBulletedButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatListBulleted];
}

- (IBAction)listNumberedButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatListNumbered];
}

#pragma mark - Menu Handler

- (IBAction)newDocument:(id)sender {
    if (!_dirty) {
        [self newFile];
        return;
    }
    [self.dialogPresenter confirmDiscardingChangesForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {  // Save
                if ([self saveFile]) {
                    return;
                }
                [self promptForSaveURLWithCompletionHandler:^(BOOL result) {
                    if (result) {
                        [self newFile];
                    }
                }];
                break;
            }
            case NSAlertThirdButtonReturn:  // Don't Save
                [self newFile];
                break;
            case NSAlertSecondButtonReturn: // Cancel
            default:
                break;
        }
    }];
}

- (IBAction)openDocument:(id)sender {
    if (!_dirty) {
        [self promptForOpenURLWithCompletionHandler:nil];
        return;
    }
    [self.dialogPresenter confirmDiscardingChangesForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {  // Save
                if ([self saveFile]) {
                    return;
                }
                [self promptForSaveURLWithCompletionHandler:^(BOOL result) {
                    if (result) {
                        [self promptForOpenURLWithCompletionHandler:nil];
                    }
                }];
                break;
            }
            case NSAlertThirdButtonReturn:  // Don't Save
                [self promptForOpenURLWithCompletionHandler:nil];
                break;
            case NSAlertSecondButtonReturn: // Cancel
            default:
                break;
        }
    }];
}

- (IBAction)saveDocument:(id)sender {
    if ([self saveFile]) {
        return;
    }
    [self promptForSaveURLWithCompletionHandler:nil];
}

- (IBAction)saveDocumentAs:(id)sender {
    [self promptForSaveURLWithCompletionHandler:nil];
}

#pragma mark - Private Methods

- (NSArray<NSButton *> *)formattingButtons {
    NSArray<NSString *> *selectorNames = @[
        NSStringFromSelector(@selector(boldButtonClicked:)),
        NSStringFromSelector(@selector(strikeThroughButtonClicked:)),
        NSStringFromSelector(@selector(italicButtonClicked:)),
        NSStringFromSelector(@selector(quoteButtonClicked:)),
        NSStringFromSelector(@selector(codeButtonClicked:)),
        NSStringFromSelector(@selector(insertLinkButtonClicked:)),
        NSStringFromSelector(@selector(listBulletedButtonClicked:)),
        NSStringFromSelector(@selector(listNumberedButtonClicked:)),
    ];
    NSMutableArray<NSButton *> *buttons = [NSMutableArray array];
    for (NSString *selectorName in selectorNames) {
        NSButton *button = [self formattingButtonInView:self.view matchingSelectorName:selectorName];
        if (button) {
            [buttons addObject:button];
        }
    }
    return buttons;
}

- (NSButton *)formattingButtonInView:(NSView *)view matchingSelectorName:(NSString *)selectorName {
    for (NSView *subview in view.subviews) {
        if ([subview isKindOfClass:[NSButton class]]) {
            NSButton *button = (NSButton *)subview;
            if (NSStringFromSelector(button.action) && [NSStringFromSelector(button.action) isEqualToString:selectorName]) {
                return button;
            }
        }
        NSButton *button = [self formattingButtonInView:subview matchingSelectorName:selectorName];
        if (button) {
            return button;
        }
    }
    return nil;
}

- (void)layoutFormattingToolbar {
    NSRect bounds = self.view.bounds;
    NSScrollView *scrollView = self.textView.enclosingScrollView;
    if (!scrollView) {
        return;
    }

    NSArray<NSButton *> *buttons = [self formattingButtons];
    CGFloat top = NSMaxY(bounds) - EditorFormattingToolbarPadding;
    CGFloat buttonY = top - EditorFormattingButtonHeight;
    CGFloat x = EditorFormattingToolbarPadding;
    for (NSButton *button in buttons) {
        button.frame = NSMakeRect(x,
                                  buttonY,
                                  EditorFormattingButtonWidth,
                                  EditorFormattingButtonHeight);
        x += EditorFormattingButtonWidth + EditorFormattingButtonGap;
    }

    if (self.converterPopup) {
        CGFloat popupWidth = MIN(EditorConverterPopupWidth, MAX(0.0, NSWidth(bounds) - (2.0 * EditorFormattingToolbarPadding)));
        CGFloat popupX = MAX(x, NSWidth(bounds) - popupWidth - EditorFormattingToolbarPadding);
        self.converterPopup.frame = NSMakeRect(popupX,
                                               buttonY,
                                               popupWidth,
                                               EditorConverterPopupHeight);
    }

    CGFloat scrollViewHeight = MAX(0.0, buttonY - EditorFormattingToolbarPadding);
    scrollView.frame = NSMakeRect(0.0, 0.0, NSWidth(bounds), scrollViewHeight);
}

- (NSString *)loadSample {
    return ConverterManager.sharedInstance.selectedConverter.sample;
}

- (NSString *)documentBody {
    NSString *body = self.textView.string;
    if (!body) {
        body = @"Unknown";
    }
    return body;
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
    if ([self.textView shouldChangeTextInRange:range replacementString:string]) {
        [self.textView replaceCharactersInRange:range withString:string];
        [self.textView didChangeText];
        _dirty = YES;
    }
}

- (void)applyFormat:(TextConverterFormat)format {
    NSRange range = self.textView.selectedRange;
    if (range.length == 0) {
        return;
    }

    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:ConverterManager.sharedInstance.selectedConverter];
    NSRange selectedRange = range;
    NSString *updatedString = [formatter stringByApplyingFormat:format
                                                         toText:self.textView.string
                                                          range:range
                                                  selectedRange:&selectedRange];
    self.textView.string = updatedString;
    self.textView.selectedRange = selectedRange;
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
    _dirty = YES;
    [self scheduleAutosave];
}

- (NSString *)defaultDirectoryPath {
    NSString *path = _filePath;
    if (!path) {
        path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO).firstObject;
    }
    return path;
}

- (void)startWatchingCurrentFile {
    __weak typeof(self) weakSelf = self;
    [self.fileWatcher watchFileAtPath:_filePath changeHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf reloadFileFromDiskIfNeeded];
    }];
}

- (void)scheduleAutosave {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosaveIfNeeded) object:nil];
    [self performSelector:@selector(autosaveIfNeeded) withObject:nil afterDelay:EditorAutosaveDelay];
}

- (void)autosaveIfNeeded {
    if (!_dirty || !_filePath) {
        return;
    }
    [self saveFile];
}

- (void)reloadFileFromDiskIfNeeded {
    if (_dirty || !_filePath) {
        return;
    }
    if (![self openFile]) {
        [self.fileWatcher stopWatching];
    }
}

- (void)promptForOpenURLWithCompletionHandler:(void (^ _Nullable)(BOOL result))handler {
    [self.dialogPresenter showOpenFilePanelForWindow:self.view.window
                                         initialPath:self.defaultDirectoryPath
                                   completionHandler:^(NSURL * _Nullable selectedURL) {
        BOOL success = NO;
        if (selectedURL) {
            self->_filePath = selectedURL.path;
            success = [self openFile];
        }
        if (handler) {
            handler(success);
        }
    }];
}

- (void)promptForSaveURLWithCompletionHandler:(void (^ _Nullable)(BOOL result))handler {
    [self.dialogPresenter showSaveFilePanelForWindow:self.view.window
                                         initialPath:self.defaultDirectoryPath
                                   completionHandler:^(NSURL * _Nullable selectedURL) {
        BOOL success = NO;
        if (selectedURL) {
            self->_filePath = selectedURL.path;
            success = [self saveFile];
        }
        if (handler) {
            handler(success);
        }
    }];
}

- (void)newFile {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosaveIfNeeded) object:nil];
    self.textView.string = @"New File";
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
    _filePath = nil;
    _dirty = NO;
    [self.fileWatcher stopWatching];
}

- (BOOL)openFile {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosaveIfNeeded) object:nil];
    if (!_filePath) {
        return NO;
    }
    BOOL isDirectory = NO;
    if (![NSFileManager.defaultManager fileExistsAtPath:_filePath isDirectory:&isDirectory]) {
        return NO;
    }
    if (isDirectory) {
        return NO;
    }
    EditorDocumentStore *store = [[EditorDocumentStore alloc] init];
    NSError *error = nil;
    NSString *string = [store readStringFromURL:[NSURL fileURLWithPath:_filePath] error:&error];
    if (!string) {
        return NO;
    }
    
    _dirty = NO;
    self.textView.string = string;
    [ConverterManager.sharedInstance setContentWithString:self.textView.string];
    [self startWatchingCurrentFile];
    return YES;
}

- (BOOL)saveFile {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosaveIfNeeded) object:nil];
    if (!_filePath) {
        return NO;
    }
    if ([NSFileManager.defaultManager fileExistsAtPath:_filePath]) {
        NSError *error = nil;
        if (![NSFileManager.defaultManager removeItemAtPath:_filePath error:&error]) {
            return NO;
        }
    }
    
    _dirty = NO;
    EditorDocumentStore *store = [[EditorDocumentStore alloc] init];
    NSError *error = nil;
    BOOL success = [store writeString:self.textView.string toURL:[NSURL fileURLWithPath:_filePath] error:&error];
    if (success) {
        [self startWatchingCurrentFile];
    }
    return success;
}

@end
