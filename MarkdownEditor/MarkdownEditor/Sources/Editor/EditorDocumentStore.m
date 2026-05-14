#import "EditorDocumentStore.h"

@implementation EditorDocumentStore

- (NSString *)readStringFromURL:(NSURL *)url error:(NSError **)error {
    return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
}

- (BOOL)writeString:(NSString *)string toURL:(NSURL *)url error:(NSError **)error {
    return [string writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:error];
}

@end
