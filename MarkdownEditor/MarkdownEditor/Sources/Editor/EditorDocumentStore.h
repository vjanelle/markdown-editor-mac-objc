#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorDocumentStore : NSObject

- (nullable NSString *)readStringFromURL:(NSURL *)url error:(NSError **)error;
- (BOOL)writeString:(NSString *)string toURL:(NSURL *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
