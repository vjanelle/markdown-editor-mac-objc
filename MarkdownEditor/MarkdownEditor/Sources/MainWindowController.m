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
    self.window.contentMinSize = NSMakeSize(1000.0, 600.0);
}

@end
