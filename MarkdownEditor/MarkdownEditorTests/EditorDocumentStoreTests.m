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
