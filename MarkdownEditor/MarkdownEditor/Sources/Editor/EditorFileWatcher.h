//
//  EditorFileWatcher.h
//  MarkdownEditor
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditorFileWatcher : NSObject

- (void)watchFileAtPath:(nullable NSString *)path changeHandler:(dispatch_block_t)changeHandler;
- (void)stopWatching;

@end

NS_ASSUME_NONNULL_END
