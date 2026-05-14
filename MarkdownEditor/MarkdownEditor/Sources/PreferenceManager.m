//
//  PreferenceManager.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/04/11.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "PreferenceManager.h"

static NSString *const AutoReloadEnabledKey = @"AutoReloadEnabled";

@implementation PreferenceManager

+ (PreferenceManager *)sharedManager {
    static PreferenceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (BOOL)autoReloadEnabled {
    @synchronized (self) {
        NSNumber *storedValue = [NSUserDefaults.standardUserDefaults objectForKey:AutoReloadEnabledKey];
        if (!storedValue) {
            return YES;
        }
        return storedValue.boolValue;
    }
}

- (void)setAutoReloadEnabled:(BOOL)value {
    @synchronized (self) {
        [NSUserDefaults.standardUserDefaults setBool:value forKey:AutoReloadEnabledKey];
    }
}

- (void)resetToDefaults {
    @synchronized (self) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:AutoReloadEnabledKey];
    }
}

@end
