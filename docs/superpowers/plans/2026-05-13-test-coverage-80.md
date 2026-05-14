# Test Coverage 80 Percent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Raise `Markdown Editor.app` code coverage from 31.51% to at least 80% while keeping tests deterministic and avoiding fragile UI automation.

**Architecture:** Add unit coverage for pure models and managers first, then introduce small test seams for network/auth and editor workflows. Keep AppKit-heavy classes thin by extracting file/formatting logic into testable Objective-C collaborators instead of relying on UI tests.

**Tech Stack:** Objective-C, XCTest, Xcode schemes, CocoaPods, `xcodebuild`, `xcrun xccov`.

---

## Current Baseline

Latest coverage command:

```sh
cd MarkdownEditor
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData -enableCodeCoverage YES test -quiet
xcrun xccov view --report --only-targets /private/tmp/MarkdownEditorDerivedData/Logs/Test/Test-MarkdownEditor-2026.05.13_13-53-06--0700.xcresult
```

Baseline:

```text
Markdown Editor.app        31.51% (398/1263)
MarkdownEditorTests.xctest 100.00% (37/37)
```

Files with the largest useful gaps:

```text
EditorViewController.m    1.90% (8/420)
GitHubGistsClient.m       0.00% (0/264)
PreferenceManager.m       0.00% (0/27)
GitHubGistsContent.m      0.00% (0/9)
TextConverter.m          47.37% (18/38)
PandocConverter.m        47.31% (44/93)
```

Coverage target math: app target needs about `1011/1263` covered lines for 80%. Current covered lines are `398`, so the plan must add roughly `613` covered lines or reduce uncovered UI-heavy code by extracting tested collaborators.

## File Structure

Create:

- `MarkdownEditor/MarkdownEditorTests/ContentAndPreferencesTests.m`: model and preference tests.
- `MarkdownEditor/MarkdownEditorTests/ConverterManagerTests.m`: manager state, notification, and converter selection tests.
- `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorTextFormatter.h`
- `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorTextFormatter.m`
- `MarkdownEditor/MarkdownEditorTests/EditorTextFormatterTests.m`
- `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorDocumentStore.h`
- `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorDocumentStore.m`
- `MarkdownEditor/MarkdownEditorTests/EditorDocumentStoreTests.m`
- `MarkdownEditor/MarkdownEditor/Sources/GitHub/GitHubGistsRequestBuilder.h`
- `MarkdownEditor/MarkdownEditor/Sources/GitHub/GitHubGistsRequestBuilder.m`
- `MarkdownEditor/MarkdownEditorTests/GitHubGistsRequestBuilderTests.m`
- `MarkdownEditor/MarkdownEditorTests/PandocConverterTests.m`

Modify:

- `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`: add new source/test files to the correct targets.
- `MarkdownEditor/MarkdownEditor/Sources/EditorViewController.m`: delegate text formatting and file IO to extracted collaborators.
- `MarkdownEditor/MarkdownEditor/Sources/GitHubGistsClient.m`: delegate request construction to `GitHubGistsRequestBuilder`.
- `MarkdownEditor/MarkdownEditorTests/MarkdownEditorTests.m`: keep existing converter formatting tests.

## Task 1: Add Model And Preference Coverage

**Files:**
- Create: `MarkdownEditor/MarkdownEditorTests/ContentAndPreferencesTests.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write failing tests**

Create `ContentAndPreferencesTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/GitHubGistsContent.h"
#import "../MarkdownEditor/Sources/PreferenceManager.h"

@interface ContentAndPreferencesTests : XCTestCase
@end

@implementation ContentAndPreferencesTests

- (void)setUp {
    [super setUp];
    [PreferenceManager.sharedManager resetToDefaults];
}

- (void)tearDown {
    [PreferenceManager.sharedManager resetToDefaults];
    [super tearDown];
}

- (void)testGitHubGistsContentCopiesInitializerValues {
    NSMutableString *content = [@"body" mutableCopy];
    NSMutableString *title = [@"title" mutableCopy];
    NSMutableString *fileName = [@"note.md" mutableCopy];

    GitHubGistsContent *gist = [[GitHubGistsContent alloc] initWithContent:content
                                                                     title:title
                                                                  fileName:fileName];
    [content appendString:@" changed"];
    [title appendString:@" changed"];
    [fileName appendString:@" changed"];

    XCTAssertEqualObjects(gist.content, @"body");
    XCTAssertEqualObjects(gist.title, @"title");
    XCTAssertEqualObjects(gist.fileName, @"note.md");
}

- (void)testPreferenceManagerStoresAutoReloadEnabled {
    XCTAssertFalse(PreferenceManager.sharedManager.autoReloadEnabled);

    PreferenceManager.sharedManager.autoReloadEnabled = YES;
    XCTAssertTrue(PreferenceManager.sharedManager.autoReloadEnabled);

    PreferenceManager.sharedManager.autoReloadEnabled = NO;
    XCTAssertFalse(PreferenceManager.sharedManager.autoReloadEnabled);
}

- (void)testPreferenceManagerResetToDefaultsClearsAutoReload {
    PreferenceManager.sharedManager.autoReloadEnabled = YES;

    [PreferenceManager.sharedManager resetToDefaults];

    XCTAssertFalse(PreferenceManager.sharedManager.autoReloadEnabled);
}

@end
```

- [ ] **Step 2: Run test to verify it fails before target membership**

Run:

```sh
cd MarkdownEditor
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: tests are not compiled until the new file is added to `MarkdownEditorTests` in `project.pbxproj`.

- [ ] **Step 3: Add the test file to `MarkdownEditorTests`**

In `project.pbxproj`, add a `PBXFileReference`, `PBXBuildFile`, group child under `MarkdownEditorTests`, and source build phase entry for `ContentAndPreferencesTests.m`.

- [ ] **Step 4: Run tests**

Run:

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: PASS.

## Task 2: Add Converter Manager Coverage

**Files:**
- Create: `MarkdownEditor/MarkdownEditorTests/ConverterManagerTests.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write failing tests**

Create `ConverterManagerTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/ConverterManager.h"

@interface ConverterManagerTests : XCTestCase
@end

@implementation ConverterManagerTests

- (void)testConverterTitlesAreExposedInDisplayOrder {
    NSArray<NSString *> *titles = ConverterManager.sharedInstance.converters;

    XCTAssertEqualObjects(titles, (@[
        @"GitHub Flavored Markdown",
        @"Markdown",
        @"PHP Markdown Extra",
        @"Strict Markdown",
    ]));
}

- (void)testSelectedConverterIndexChangesSelectedConverter {
    ConverterManager.sharedInstance.selectedConverterIndex = 1;
    XCTAssertEqualObjects(ConverterManager.sharedInstance.selectedConverter.title, @"Markdown");

    ConverterManager.sharedInstance.selectedConverterIndex = 3;
    XCTAssertEqualObjects(ConverterManager.sharedInstance.selectedConverter.title, @"Strict Markdown");
}

- (void)testSetContentPostsDidChangeNotification {
    XCTestExpectation *expectation = [self expectationWithDescription:@"content changed"];
    id observer = [NSNotificationCenter.defaultCenter addObserverForName:ConverterManagerDidChangeContentNotification
                                                                  object:nil
                                                                   queue:nil
                                                              usingBlock:^(NSNotification *note) {
        [expectation fulfill];
    }];

    [ConverterManager.sharedInstance setContentWithString:@"# Title"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
    [NSNotificationCenter.defaultCenter removeObserver:observer];
}

- (void)testURLPointsToIndexHtml {
    NSURL *url = ConverterManager.sharedInstance.url;

    XCTAssertEqualObjects(url.path, @"/index.html");
    XCTAssertEqual(url.port.integerValue, 8080);
}

@end
```

- [ ] **Step 2: Add to test target**

Add the file to the `MarkdownEditorTests` group and source build phase in `project.pbxproj`.

- [ ] **Step 3: Run tests**

Run:

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: PASS. If port `8080` is already occupied, update `ConverterManager` in a later task to accept an injectable port for tests.

## Task 3: Extract And Test Editor Text Formatting

**Files:**
- Create: `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorTextFormatter.h`
- Create: `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorTextFormatter.m`
- Create: `MarkdownEditor/MarkdownEditorTests/EditorTextFormatterTests.m`
- Modify: `MarkdownEditor/MarkdownEditor/Sources/EditorViewController.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write failing tests**

Create `EditorTextFormatterTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Editor/EditorTextFormatter.h"
#import "../MarkdownEditor/Sources/Converter/MarkdownConverter.h"

@interface EditorTextFormatterTests : XCTestCase
@end

@implementation EditorTextFormatterTests

- (void)testReturnsOriginalTextWhenRangeIsEmpty {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatBold
                                                  toText:@"hello"
                                                   range:NSMakeRange(0, 0)
                                           selectedRange:NULL];

    XCTAssertEqualObjects(result, @"hello");
}

- (void)testAppliesFormatToSelectedRange {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatBold
                                                  toText:@"hello world"
                                                   range:NSMakeRange(6, 5)
                                           selectedRange:&selectedRange];

    XCTAssertEqualObjects(result, @"hello **world**");
    XCTAssertEqual(selectedRange.location, 6);
    XCTAssertEqual(selectedRange.length, 9);
}

- (void)testAppliesBlockFormatToMultilineSelection {
    EditorTextFormatter *formatter = [[EditorTextFormatter alloc] initWithConverter:[[MarkdownConverter alloc] init]];
    NSRange selectedRange = NSMakeRange(NSNotFound, 0);

    NSString *result = [formatter stringByApplyingFormat:TextConverterFormatQuote
                                                  toText:@"one\ntwo"
                                                   range:NSMakeRange(0, 7)
                                           selectedRange:&selectedRange];

    XCTAssertEqualObjects(result, @"> one\n> two\n");
    XCTAssertEqual(selectedRange.location, 0);
    XCTAssertEqual(selectedRange.length, 12);
}

@end
```

- [ ] **Step 2: Verify RED**

Run:

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: FAIL because `EditorTextFormatter` does not exist.

- [ ] **Step 3: Implement `EditorTextFormatter`**

`EditorTextFormatter.h`:

```objc
#import <Foundation/Foundation.h>
#import "TextConverter.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditorTextFormatter : NSObject

- (instancetype)initWithConverter:(TextConverter *)converter;

- (NSString *)stringByApplyingFormat:(TextConverterFormat)format
                              toText:(NSString *)text
                               range:(NSRange)range
                       selectedRange:(nullable NSRange *)selectedRange;

@end

NS_ASSUME_NONNULL_END
```

`EditorTextFormatter.m`:

```objc
#import "EditorTextFormatter.h"

@implementation EditorTextFormatter {
    TextConverter *_converter;
}

- (instancetype)initWithConverter:(TextConverter *)converter {
    self = [super init];
    if (self) {
        _converter = converter;
    }
    return self;
}

- (NSString *)stringByApplyingFormat:(TextConverterFormat)format
                              toText:(NSString *)text
                               range:(NSRange)range
                       selectedRange:(NSRange *)selectedRange {
    if (range.length == 0) {
        if (selectedRange) {
            *selectedRange = range;
        }
        return text;
    }

    NSString *selectedString = [text substringWithRange:range];
    NSString *formattedString = [_converter formattedStringWithString:selectedString format:format];
    NSMutableString *mutableText = [text mutableCopy];
    [mutableText replaceCharactersInRange:range withString:formattedString];

    if (selectedRange) {
        *selectedRange = NSMakeRange(range.location, formattedString.length);
    }
    return mutableText;
}

@end
```

- [ ] **Step 4: Refactor `EditorViewController` to use formatter**

Replace repeated formatting action bodies with:

```objc
- (void)applyFormat:(TextConverterFormat)format {
    NSRange range = self.textView.selectedRange;
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
}
```

Then each button method becomes:

```objc
- (IBAction)boldButtonClicked:(NSButton *)sender {
    [self applyFormat:TextConverterFormatBold];
}
```

Repeat with the matching enum for italic, strike-through, quote, code, link, bulleted list, and numbered list.

- [ ] **Step 5: Run tests**

Run:

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: PASS.

## Task 4: Extract And Test Editor File IO

**Files:**
- Create: `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorDocumentStore.h`
- Create: `MarkdownEditor/MarkdownEditor/Sources/Editor/EditorDocumentStore.m`
- Create: `MarkdownEditor/MarkdownEditorTests/EditorDocumentStoreTests.m`
- Modify: `MarkdownEditor/MarkdownEditor/Sources/EditorViewController.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write failing tests**

Create `EditorDocumentStoreTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Editor/EditorDocumentStore.h"

@interface EditorDocumentStoreTests : XCTestCase
@end

@implementation EditorDocumentStoreTests

- (NSURL *)temporaryFileURLWithName:(NSString *)name {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    return [NSURL fileURLWithPath:path];
}

- (void)testWritesAndReadsUTF8Text {
    EditorDocumentStore *store = [[EditorDocumentStore alloc] init];
    NSURL *url = [self temporaryFileURLWithName:@"markdown-editor-store-test.md"];

    NSError *writeError = nil;
    XCTAssertTrue([store writeString:@"# Title" toURL:url error:&writeError]);
    XCTAssertNil(writeError);

    NSError *readError = nil;
    NSString *contents = [store readStringFromURL:url error:&readError];
    XCTAssertEqualObjects(contents, @"# Title");
    XCTAssertNil(readError);
}

- (void)testReadMissingFileReturnsNilAndError {
    EditorDocumentStore *store = [[EditorDocumentStore alloc] init];
    NSURL *url = [self temporaryFileURLWithName:@"missing-markdown-editor-store-test.md"];
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];

    NSError *error = nil;
    NSString *contents = [store readStringFromURL:url error:&error];

    XCTAssertNil(contents);
    XCTAssertNotNil(error);
}

@end
```

- [ ] **Step 2: Verify RED**

Expected: FAIL because `EditorDocumentStore` does not exist.

- [ ] **Step 3: Implement `EditorDocumentStore`**

`EditorDocumentStore.h`:

```objc
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorDocumentStore : NSObject

- (nullable NSString *)readStringFromURL:(NSURL *)url error:(NSError **)error;
- (BOOL)writeString:(NSString *)string toURL:(NSURL *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
```

`EditorDocumentStore.m`:

```objc
#import "EditorDocumentStore.h"

@implementation EditorDocumentStore

- (NSString *)readStringFromURL:(NSURL *)url error:(NSError **)error {
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
}

- (BOOL)writeString:(NSString *)string toURL:(NSURL *)url error:(NSError **)error {
    return [string writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:error];
}

@end
```

- [ ] **Step 4: Refactor `EditorViewController` file methods**

Replace direct string file reads/writes in `openFile` and `saveFile` with `EditorDocumentStore`. Preserve existing alert behavior and `_dirty` updates.

- [ ] **Step 5: Run tests**

Run:

```sh
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData test -quiet
```

Expected: PASS.

## Task 5: Extract And Test GitHub Gist Request Building

**Files:**
- Create: `MarkdownEditor/MarkdownEditor/Sources/GitHub/GitHubGistsRequestBuilder.h`
- Create: `MarkdownEditor/MarkdownEditor/Sources/GitHub/GitHubGistsRequestBuilder.m`
- Create: `MarkdownEditor/MarkdownEditorTests/GitHubGistsRequestBuilderTests.m`
- Modify: `MarkdownEditor/MarkdownEditor/Sources/GitHubGistsClient.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write failing tests**

Create `GitHubGistsRequestBuilderTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/GitHub/GitHubGistsRequestBuilder.h"
#import "../MarkdownEditor/Sources/GitHubGistsContent.h"

@interface GitHubGistsRequestBuilderTests : XCTestCase
@end

@implementation GitHubGistsRequestBuilderTests

- (void)testBuildsCreateGistRequest {
    GitHubGistsContent *content = [[GitHubGistsContent alloc] initWithContent:@"# Body"
                                                                        title:@"My Gist"
                                                                     fileName:@"note.md"];
    GitHubGistsRequestBuilder *builder = [[GitHubGistsRequestBuilder alloc] init];

    NSURLRequest *request = [builder createGistRequestWithContent:content];

    XCTAssertEqualObjects(request.URL.absoluteString, @"https://api.github.com/gists");
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    XCTAssertEqualObjects(json[@"description"], @"My Gist");
    XCTAssertEqualObjects(json[@"public"], @NO);
    XCTAssertEqualObjects(json[@"files"][@"note.md"][@"content"], @"# Body");
}

@end
```

- [ ] **Step 2: Verify RED**

Expected: FAIL because `GitHubGistsRequestBuilder` does not exist.

- [ ] **Step 3: Implement request builder**

`GitHubGistsRequestBuilder.h`:

```objc
#import <Foundation/Foundation.h>
#import "GitHubGistsContent.h"

NS_ASSUME_NONNULL_BEGIN

@interface GitHubGistsRequestBuilder : NSObject

- (NSURLRequest *)createGistRequestWithContent:(GitHubGistsContent *)content;

@end

NS_ASSUME_NONNULL_END
```

`GitHubGistsRequestBuilder.m`:

```objc
#import "GitHubGistsRequestBuilder.h"

@implementation GitHubGistsRequestBuilder

- (NSURLRequest *)createGistRequestWithContent:(GitHubGistsContent *)content {
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/gists"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{
        @"description": content.title,
        @"public": @NO,
        @"files": @{
            content.fileName: @{
                @"content": content.content,
            },
        },
    };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    return request;
}

@end
```

- [ ] **Step 4: Refactor `GitHubGistsClientUploadTask`**

In `GitHubGistsClient.m`, replace inline request construction in `-[GitHubGistsClientUploadTask execute]` with:

```objc
GitHubGistsRequestBuilder *builder = [[GitHubGistsRequestBuilder alloc] init];
NSURLRequest *request = [builder createGistRequestWithContent:_content];
return [self executeWithRequest:request];
```

Import:

```objc
#import "GitHubGistsRequestBuilder.h"
```

- [ ] **Step 5: Run tests**

Expected: PASS.

## Task 6: Complete Converter Coverage

**Files:**
- Create: `MarkdownEditor/MarkdownEditorTests/PandocConverterTests.m`
- Modify: `MarkdownEditor/MarkdownEditor.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write tests**

Create `PandocConverterTests.m`:

```objc
#import <XCTest/XCTest.h>
#import "../MarkdownEditor/Sources/Converter/PandocConverter.h"

@interface ExposedPandocConverter : PandocConverter
- (NSString *)commandWithString:(NSString *)string;
@end

@implementation ExposedPandocConverter
@end

@interface PandocConverterTests : XCTestCase
@end

@implementation PandocConverterTests

- (void)testExposesFormatAndCss {
    PandocConverter *converter = [[PandocConverter alloc] initWithTitle:@"Title"
                                                                 format:@"gfm"
                                                                 header:nil
                                                                    css:@"style.css"];

    XCTAssertEqualObjects(converter.title, @"Title");
    XCTAssertEqualObjects(converter.format, @"gfm");
    XCTAssertEqualObjects(converter.css, @"style.css");
    XCTAssertNil(converter.header);
}

- (void)testBuildsPandocCommand {
    ExposedPandocConverter *converter = [[ExposedPandocConverter alloc] initWithTitle:@"Title"
                                                                               format:@"gfm"
                                                                               header:nil
                                                                                  css:@"style.css"];

    NSString *command = [converter commandWithString:@"# Title"];

    XCTAssertTrue([command containsString:@"echo '# Title' | pandoc"]);
    XCTAssertTrue([command containsString:@"-f gfm"]);
    XCTAssertTrue([command containsString:@"-c style.css"]);
    XCTAssertTrue([command containsString:@"-t html"]);
    XCTAssertTrue([command containsString:@"-s"]);
}

@end
```

- [ ] **Step 2: Add to target and run tests**

Expected: PASS.

## Task 7: Re-Measure Coverage And Close Remaining Gap

**Files:**
- Modify only if coverage remains below 80%.

- [ ] **Step 1: Run coverage**

Run:

```sh
cd MarkdownEditor
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData -enableCodeCoverage YES test -quiet
LATEST_RESULT=$(ls -td /private/tmp/MarkdownEditorDerivedData/Logs/Test/*.xcresult | head -1)
xcrun xccov view --report --only-targets "$LATEST_RESULT"
```

Expected after Tasks 1-6: `Markdown Editor.app` should be at or near 80%. If below 80%, inspect:

```sh
xcrun xccov view --report "$LATEST_RESULT"
```

- [ ] **Step 2: Add targeted tests for the largest remaining uncovered app files**

Use the report to pick the largest uncovered file. Expected likely remaining candidates:

```text
EditorViewController.m
GitHubGistsClient.m
PreviewViewController.m
```

Do not add UI tests unless unit-testable seams are exhausted. Prefer extracting collaborators from controller code and testing those collaborators.

- [ ] **Step 3: Final acceptance command**

Run:

```sh
git diff --check
cd MarkdownEditor
xcodebuild -workspace MarkdownEditor.xcworkspace -scheme MarkdownEditor -derivedDataPath /private/tmp/MarkdownEditorDerivedData -enableCodeCoverage YES test -quiet
LATEST_RESULT=$(ls -td /private/tmp/MarkdownEditorDerivedData/Logs/Test/*.xcresult | head -1)
xcrun xccov view --report --only-targets "$LATEST_RESULT"
```

Expected:

```text
Markdown Editor.app 80.00% or higher
```

## Risk Notes

- `ConverterManager` starts a web server on port `8080` in `init`. If tests are flaky due to port conflicts, add an initializer that accepts a port and make `sharedInstance` keep using `8080`.
- `GitHubGistsClient` auth flow should not be tested by launching real AppAuth sessions. Keep tests at request construction and task behavior with injected collaborators.
- `EditorViewController` is the biggest coverage sink. Raising coverage cleanly requires extracting pure formatting and file IO logic, not testing every AppKit alert branch.
- The workspace is recognized by `xcodebuild` only outside the current sandbox. Verification commands that use `xcodebuild -workspace` need the approved `xcodebuild` escalation path.

## Self-Review

- Spec coverage: The plan targets at least 80% app coverage and includes measurement gates.
- Placeholder scan: All tasks have explicit files, code snippets, and commands.
- Type consistency: New classes use Objective-C names and imports consistent with the existing project.
