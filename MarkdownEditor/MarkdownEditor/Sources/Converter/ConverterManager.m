//
//  ConverterManager.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "ConverterManager.h"
#import "TextConverter.h"
#import "GfmConverter.h"
#import "MarkdownConverter.h"
#import "PhpMarkdownConverter.h"
#import "StrictMarkdownConverter.h"
#import "Logger.h"

NSNotificationName ConverterManagerDidChangeContentNotification = @"ConverterManagerDidChangeContentNotification";

@implementation ConverterManager {
    NSString *_string;
    NSUInteger _selectedConverterIndex;
    NSArray<TextConverter *> *_converters;
}

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _converters = @[[[GfmConverter alloc] init],
                        [[MarkdownConverter alloc] init],
                        [[PhpMarkdownConverter alloc] init],
                        [[StrictMarkdownConverter alloc] init],
                        ];
        self.selectedConverterIndex = 0;
    }
    return self;
}

- (NSString *)html {
    @synchronized (self) {
        return self.selectedConverter.html;
    }
}

- (NSArray<NSString *> *)converters {
    @synchronized (self) {
        NSMutableArray *converters = [@[] mutableCopy];
        for (TextConverter *converter in _converters) {
            [converters addObject:converter.title];
        }
        return converters;
    }
}

- (NSUInteger)selectedConverterIndex {
    @synchronized (self) {
        return _selectedConverterIndex;
    }
}

- (void)setSelectedConverterIndex:(NSUInteger)selectedConverterIndex {
    @synchronized (self) {
        _selectedConverterIndex = selectedConverterIndex;
        if (_string) {
            [self reload];
        }
    }
}

- (TextConverter *)selectedConverter {
    @synchronized (self) {
        return _converters[_selectedConverterIndex];
    }
}

- (void)setContentWithString:(NSString *)string {
    @synchronized (self) {
        TextConverter *converter = self.selectedConverter;
        [converter setContentWithString:string];
        LogV(@"*** HTML ***");
        LogV(@"%@", converter.html);
        _string = string;
        [self didChangeContent];
    }
}

- (void)didChangeContent {
    [NSNotificationCenter.defaultCenter postNotificationName:ConverterManagerDidChangeContentNotification
                                                      object:nil];
}

- (void)reload {
    [self setContentWithString:_string];
}

@end
