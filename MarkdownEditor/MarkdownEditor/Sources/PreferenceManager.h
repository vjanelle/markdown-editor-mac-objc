//
//  PreferenceManager.h
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/04/11.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferenceManager : NSObject

@property (class, readonly, strong) PreferenceManager *sharedManager;

@property BOOL autoReloadEnabled;

- (void)resetToDefaults;

@end

NS_ASSUME_NONNULL_END
