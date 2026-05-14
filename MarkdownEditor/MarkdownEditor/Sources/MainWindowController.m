//
//  MainWindowController.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/03/03.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "MainWindowController.h"

@interface MainWindowController () {
}

@end

@implementation MainWindowController

static const NSSize MainWindowMinimumContentSize = {1200.0, 800.0};

- (NSArray<NSString *> *)converters {
    return ConverterManager.sharedInstance.converters;
}

- (NSUInteger)selectedConverterIndex {
    return ConverterManager.sharedInstance.selectedConverterIndex;
}

- (void)setSelectedConverterIndex:(NSUInteger)selectedFormatIndex {
    ConverterManager.sharedInstance.selectedConverterIndex = selectedFormatIndex;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.contentMinSize = MainWindowMinimumContentSize;
    if (self.window.contentView.frame.size.width < MainWindowMinimumContentSize.width ||
        self.window.contentView.frame.size.height < MainWindowMinimumContentSize.height) {
        [self.window setContentSize:MainWindowMinimumContentSize];
        [self.window center];
    }
}

@end
