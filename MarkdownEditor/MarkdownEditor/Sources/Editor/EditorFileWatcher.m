//
//  EditorFileWatcher.m
//  MarkdownEditor
//

#import "EditorFileWatcher.h"
#import <fcntl.h>

@implementation EditorFileWatcher {
    dispatch_source_t _source;
    int _fileDescriptor;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileDescriptor = -1;
    }
    return self;
}

- (void)dealloc {
    [self stopWatching];
}

- (void)watchFileAtPath:(nullable NSString *)path changeHandler:(dispatch_block_t)changeHandler {
    [self stopWatching];
    if (!path) {
        return;
    }

    _fileDescriptor = open(path.fileSystemRepresentation, O_EVTONLY);
    if (_fileDescriptor < 0) {
        return;
    }

    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                     (uintptr_t)_fileDescriptor,
                                     DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME,
                                     queue);
    if (!_source) {
        close(_fileDescriptor);
        _fileDescriptor = -1;
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_source, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            changeHandler();
        });
    });
    dispatch_source_set_cancel_handler(_source, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf->_fileDescriptor >= 0) {
            close(strongSelf->_fileDescriptor);
            strongSelf->_fileDescriptor = -1;
        }
    });
    dispatch_resume(_source);
}

- (void)stopWatching {
    if (_source) {
        dispatch_source_cancel(_source);
        _source = nil;
        return;
    }
    if (_fileDescriptor >= 0) {
        close(_fileDescriptor);
        _fileDescriptor = -1;
    }
}

@end
