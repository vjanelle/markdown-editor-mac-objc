//
//  EditorViewControllerTests.m
//  MarkdownEditorTests
//

#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/EditorViewController.h"
#import "../MarkdownEditor/Sources/Converter/TextConverter.h"
#import "../MarkdownEditor/Sources/Editor/EditorDialogPresenter.h"

@interface EditorViewController (Testing)
- (void)textDidEndEditing:(NSNotification *)notification;
- (void)textDidChange:(NSNotification *)notification;
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray<NSValue *> *)affectedRanges replacementStrings:(NSArray<NSString *> *)replacementStrings;
- (IBAction)boldButtonClicked:(NSButton *)sender;
- (IBAction)strikeThroughButtonClicked:(NSButton *)sender;
- (IBAction)italicButtonClicked:(NSButton *)sender;
- (IBAction)quoteButtonClicked:(NSButton *)sender;
- (IBAction)codeButtonClicked:(NSButton *)sender;
- (IBAction)insertLinkButtonClicked:(NSButton *)sender;
- (IBAction)listBulletedButtonClicked:(NSButton *)sender;
- (IBAction)listNumberedButtonClicked:(NSButton *)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (EditorDialogPresenter *)dialogPresenter;
- (NSString *)documentBody;
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;
- (void)applyFormat:(TextConverterFormat)format;
- (void)newFile;
- (BOOL)openFile;
- (BOOL)saveFile;
- (NSString *)defaultDirectoryPath;
- (void)promptForOpenURLWithCompletionHandler:(void (^)(BOOL result))handler;
- (void)promptForSaveURLWithCompletionHandler:(void (^)(BOOL result))handler;
- (void)reloadFileFromDiskIfNeeded;
@end

@interface StubEditorDialogPresenter : EditorDialogPresenter
@property (nonatomic) NSUInteger alertCallCount;
@property (nonatomic) NSUInteger confirmCallCount;
@property (nonatomic) NSUInteger openPanelCallCount;
@property (nonatomic) NSUInteger savePanelCallCount;
@property (nonatomic) NSModalResponse confirmationResponse;
@property (nonatomic, strong) NSURL *openURL;
@property (nonatomic, strong) NSURL *saveURL;
@property (nonatomic, copy) NSString *lastAlertTitle;
@property (nonatomic, copy) NSString *lastAlertMessage;
@end

@implementation StubEditorDialogPresenter

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message forWindow:(NSWindow *)window {
    self.alertCallCount += 1;
    self.lastAlertTitle = title;
    self.lastAlertMessage = message;
}

- (void)confirmDiscardingChangesForWindow:(NSWindow *)window
                        completionHandler:(void (^)(NSModalResponse returnCode))handler {
    self.confirmCallCount += 1;
    handler(self.confirmationResponse);
}

- (void)showOpenFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler {
    self.openPanelCallCount += 1;
    handler(self.openURL);
}

- (void)showSaveFilePanelForWindow:(NSWindow *)window
                       initialPath:(NSString *)initialPath
                 completionHandler:(void (^)(NSURL * _Nullable selectedURL))handler {
    self.savePanelCallCount += 1;
    handler(self.saveURL);
}

@end

@interface TestableEditorViewController : EditorViewController
@property (nonatomic) NSUInteger newFileCallCount;
@property (nonatomic) NSUInteger saveFileCallCount;
@property (nonatomic) NSUInteger openFileCallCount;
@property (nonatomic) BOOL saveFileResult;
@end

@implementation TestableEditorViewController

- (void)newFile {
    self.newFileCallCount += 1;
}

- (BOOL)saveFile {
    self.saveFileCallCount += 1;
    return self.saveFileResult;
}

- (BOOL)openFile {
    self.openFileCallCount += 1;
    return YES;
}

@end

@interface EditorViewControllerTests : XCTestCase
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) StubEditorDialogPresenter *dialogPresenter;
@end

@implementation EditorViewControllerTests

- (void)configureController:(EditorViewController *)controller text:(NSString *)text {
    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200)];
    self.dialogPresenter = [[StubEditorDialogPresenter alloc] init];
    self.textView.string = text;
    [controller setValue:self.textView forKey:@"textView"];
    [controller setValue:self.dialogPresenter forKey:@"dialogPresenter"];
}

- (EditorViewController *)makeControllerWithText:(NSString *)text {
    EditorViewController *controller = [[EditorViewController alloc] init];
    [self configureController:controller text:text];
    return controller;
}

- (TestableEditorViewController *)makeTestableControllerWithText:(NSString *)text {
    TestableEditorViewController *controller = [[TestableEditorViewController alloc] init];
    [self configureController:controller text:text];
    return controller;
}

- (NSString *)temporaryPathWithName:(NSString *)name {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:name];
}

- (void)testDocumentMetadataUsesOutlets {
    EditorViewController *controller = [self makeControllerWithText:@"body"];
    XCTAssertEqualObjects([controller documentBody], @"body");
}

- (void)testDocumentMetadataFallsBackWhenOutletsAreMissing {
    EditorViewController *controller = [[EditorViewController alloc] init];

    XCTAssertEqualObjects([controller documentBody], @"Unknown");
}

- (void)testSetRepresentedObjectIsAccepted {
    EditorViewController *controller = [self makeControllerWithText:@"body"];
    NSObject *object = [[NSObject alloc] init];

    controller.representedObject = object;

    XCTAssertEqual(controller.representedObject, object);
}

- (void)testNewFileResetsContentPathAndDirtyState {
    EditorViewController *controller = [self makeControllerWithText:@"old"];
    [controller setValue:@"/tmp/example.md" forKey:@"filePath"];
    [controller setValue:@YES forKey:@"dirty"];

    [controller newFile];

    XCTAssertEqualObjects(self.textView.string, @"New File");
    XCTAssertNil([controller valueForKey:@"filePath"]);
    XCTAssertFalse([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testOpenFileRejectsMissingPathsAndDirectories {
    EditorViewController *controller = [self makeControllerWithText:@"old"];

    XCTAssertFalse([controller openFile]);

    [controller setValue:@"/tmp/markdown-editor-missing.md" forKey:@"filePath"];
    XCTAssertFalse([controller openFile]);

    [controller setValue:NSTemporaryDirectory() forKey:@"filePath"];
    XCTAssertFalse([controller openFile]);
}

- (void)testOpenFileLoadsMarkdownAndClearsDirtyState {
    EditorViewController *controller = [self makeControllerWithText:@"old"];
    NSString *path = [self temporaryPathWithName:@"markdown-editor-open.md"];
    [@"# Opened" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [controller setValue:path forKey:@"filePath"];
    [controller setValue:@YES forKey:@"dirty"];

    XCTAssertTrue([controller openFile]);

    XCTAssertEqualObjects(self.textView.string, @"# Opened");
    XCTAssertFalse([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testSaveFileWritesMarkdownAndClearsDirtyState {
    EditorViewController *controller = [self makeControllerWithText:@"# Saved"];
    NSString *path = [self temporaryPathWithName:@"markdown-editor-save.md"];
    [@"old" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [controller setValue:path forKey:@"filePath"];
    [controller setValue:@YES forKey:@"dirty"];

    XCTAssertTrue([controller saveFile]);

    NSString *saved = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    XCTAssertEqualObjects(saved, @"# Saved");
    XCTAssertFalse([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testSaveFileRejectsMissingPath {
    EditorViewController *controller = [self makeControllerWithText:@"# Saved"];

    XCTAssertFalse([controller saveFile]);
}

- (void)testMenuActionsUseNonModalBranchesWhenDocumentIsClean {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];

    [controller newDocument:nil];
    XCTAssertEqual(controller.newFileCallCount, 1);

    [controller openDocument:nil];
    XCTAssertEqual(self.dialogPresenter.openPanelCallCount, 1);
}

- (void)testNewDocumentDirtySaveSuccessLeavesDocumentInPlace {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    controller.saveFileResult = YES;
    self.dialogPresenter.confirmationResponse = NSAlertFirstButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller newDocument:nil];

    XCTAssertEqual(controller.saveFileCallCount, 1);
    XCTAssertEqual(controller.newFileCallCount, 0);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 0);
}

- (void)testNewDocumentDirtySaveFailureOpensSavePanel {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    controller.saveFileResult = NO;
    self.dialogPresenter.confirmationResponse = NSAlertFirstButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller newDocument:nil];

    XCTAssertEqual(controller.saveFileCallCount, 1);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 1);
}

- (void)testNewDocumentDirtyDiscardCreatesNewFile {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    self.dialogPresenter.confirmationResponse = NSAlertThirdButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller newDocument:nil];

    XCTAssertEqual(controller.newFileCallCount, 1);
}

- (void)testNewDocumentDirtyCancelDoesNothing {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    self.dialogPresenter.confirmationResponse = NSAlertSecondButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller newDocument:nil];

    XCTAssertEqual(controller.newFileCallCount, 0);
    XCTAssertEqual(controller.saveFileCallCount, 0);
}

- (void)testOpenDocumentDirtySaveSuccessLeavesDocumentInPlace {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    controller.saveFileResult = YES;
    self.dialogPresenter.confirmationResponse = NSAlertFirstButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller openDocument:nil];

    XCTAssertEqual(controller.saveFileCallCount, 1);
    XCTAssertEqual(self.dialogPresenter.openPanelCallCount, 0);
}

- (void)testOpenDocumentDirtySaveFailureOpensSavePanel {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    controller.saveFileResult = NO;
    self.dialogPresenter.confirmationResponse = NSAlertFirstButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller openDocument:nil];

    XCTAssertEqual(controller.saveFileCallCount, 1);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 1);
}

- (void)testOpenDocumentDirtyDiscardOpensOpenPanel {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    self.dialogPresenter.confirmationResponse = NSAlertThirdButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller openDocument:nil];

    XCTAssertEqual(self.dialogPresenter.openPanelCallCount, 1);
}

- (void)testOpenDocumentDirtyCancelDoesNothing {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    self.dialogPresenter.confirmationResponse = NSAlertSecondButtonReturn;
    [controller setValue:@YES forKey:@"dirty"];

    [controller openDocument:nil];

    XCTAssertEqual(self.dialogPresenter.openPanelCallCount, 0);
    XCTAssertEqual(controller.saveFileCallCount, 0);
}

- (void)testSaveMenuActionsUseSaveAndPanelBranches {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    controller.saveFileResult = YES;

    [controller saveDocument:nil];
    XCTAssertEqual(controller.saveFileCallCount, 1);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 0);

    controller.saveFileResult = NO;
    [controller saveDocument:nil];
    XCTAssertEqual(controller.saveFileCallCount, 2);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 1);

    [controller saveDocumentAs:nil];
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 2);
}

- (void)testPromptForOpenAndSaveUseDialogPresenter {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    NSString *openPath = [self temporaryPathWithName:@"markdown-editor-selected-open.md"];
    NSString *savePath = [self temporaryPathWithName:@"markdown-editor-selected-save.md"];
    self.dialogPresenter.openURL = [NSURL fileURLWithPath:openPath];
    self.dialogPresenter.saveURL = [NSURL fileURLWithPath:savePath];

    [controller promptForOpenURLWithCompletionHandler:nil];
    [controller promptForSaveURLWithCompletionHandler:nil];

    XCTAssertEqual(self.dialogPresenter.openPanelCallCount, 1);
    XCTAssertEqual(self.dialogPresenter.savePanelCallCount, 1);
    XCTAssertEqual(controller.openFileCallCount, 1);
    XCTAssertEqual(controller.saveFileCallCount, 1);
}

- (void)testReloadFileFromDiskIfNeededHonorsDirtyState {
    TestableEditorViewController *controller = [self makeTestableControllerWithText:@"body"];
    [controller setValue:@"/tmp/example.md" forKey:@"filePath"];

    [controller setValue:@NO forKey:@"dirty"];
    [controller reloadFileFromDiskIfNeeded];
    XCTAssertEqual(controller.openFileCallCount, 1);

    [controller setValue:@YES forKey:@"dirty"];
    [controller reloadFileFromDiskIfNeeded];
    XCTAssertEqual(controller.openFileCallCount, 1);
}

- (void)testReplaceCharactersUpdatesTextAndDirtyState {
    EditorViewController *controller = [self makeControllerWithText:@"Hello world"];

    [controller replaceCharactersInRange:NSMakeRange(6, 5) withString:@"Markdown"];

    XCTAssertEqualObjects(self.textView.string, @"Hello Markdown");
    XCTAssertTrue([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testFormattingActionsUpdateSelectedText {
    EditorViewController *controller = [self makeControllerWithText:@"alpha\nbeta"];

    self.textView.selectedRange = NSMakeRange(0, 5);
    [controller boldButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"**alpha**\nbeta");

    self.textView.string = @"alpha";
    self.textView.selectedRange = NSMakeRange(0, 5);
    [controller italicButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"*alpha*");

    self.textView.string = @"alpha";
    self.textView.selectedRange = NSMakeRange(0, 5);
    [controller strikeThroughButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"~~alpha~~");

    self.textView.string = @"alpha";
    self.textView.selectedRange = NSMakeRange(0, 5);
    [controller codeButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"```\nalpha\n```");
}

- (void)testBlockFormattingActionsUpdateSelectedText {
    EditorViewController *controller = [self makeControllerWithText:@"alpha\nbeta"];

    self.textView.selectedRange = NSMakeRange(0, self.textView.string.length);
    [controller quoteButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"> alpha\n> beta\n");

    self.textView.string = @"alpha\nbeta";
    self.textView.selectedRange = NSMakeRange(0, self.textView.string.length);
    [controller listBulletedButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"- alpha\n- beta\n");

    self.textView.string = @"alpha\nbeta";
    self.textView.selectedRange = NSMakeRange(0, self.textView.string.length);
    [controller listNumberedButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"1. alpha\n1. beta\n");
}

- (void)testLinkFormattingAndEmptySelection {
    EditorViewController *controller = [self makeControllerWithText:@"alpha"];

    self.textView.selectedRange = NSMakeRange(0, 5);
    [controller insertLinkButtonClicked:nil];
    XCTAssertEqualObjects(self.textView.string, @"[alpha](url)");
    XCTAssertTrue([[controller valueForKey:@"dirty"] boolValue]);

    [controller setValue:@NO forKey:@"dirty"];
    self.textView.selectedRange = NSMakeRange(0, 0);
    [controller applyFormat:TextConverterFormatBold];
    XCTAssertEqualObjects(self.textView.string, @"[alpha](url)");
    XCTAssertFalse([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testTextDelegateMethodsMarkDocumentDirty {
    EditorViewController *controller = [self makeControllerWithText:@"changed"];

    [controller textDidChange:nil];
    XCTAssertTrue([[controller valueForKey:@"dirty"] boolValue]);

    [controller setValue:@NO forKey:@"dirty"];
    [controller textDidEndEditing:nil];
    XCTAssertTrue([[controller valueForKey:@"dirty"] boolValue]);
}

- (void)testTextViewAllowsAllChanges {
    EditorViewController *controller = [self makeControllerWithText:@"changed"];

    XCTAssertTrue([controller textView:self.textView
              shouldChangeTextInRanges:@[[NSValue valueWithRange:NSMakeRange(0, 1)]]
                     replacementStrings:@[@"x"]]);
}

@end
