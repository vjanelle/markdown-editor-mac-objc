//
//  MarkdownRendererConverter.m
//  MarkdownEditor
//
//  Created by Iwaki Satoshi on 2018/02/27.
//  Copyright © 2018 Satoshi Iwaki and 2026 Vincent Janelle. All rights reserved.
//

#import "MarkdownRendererConverter.h"
#import "Logger.h"
#import "MarkdownEditorLite-Swift.h"

@implementation MarkdownRendererConverter {
    NSString *_html;
    NSString *_title;
    NSString *_format;
    NSString *_header;
    NSString *_css;
}

- (instancetype)initWithTitle:(NSString *)title
                       format:(NSString *)format
                       header:(nullable NSString *)header
                          css:(nullable NSString *)css {
    self = [super initWithTitle:title];
    if (self) {
        _format = [format copy];
        _header = [header copy];
        _css = [css copy];
        _html = @"<html><body></body></html>";
    }
    return self;
}

- (NSString *)html {
    return _html;
}

- (NSString *)formattedStringWithString:(NSString *)string format:(TextConverterFormat)format {
    switch (format) {
        case TextConverterFormatBold:
            return [NSString stringWithFormat:@"**%@**", string];
        case TextConverterFormatItalic:
            return [NSString stringWithFormat:@"*%@*", string];
        case TextConverterFormatStrikeThrough:
            return [NSString stringWithFormat:@"~~%@~~", string];
        case TextConverterFormatCode: {
            return [NSString stringWithFormat:@"```\n%@\n```", string];
        }
        case TextConverterFormatLink: {
            return [NSString stringWithFormat:@"[%@](url)", string];
        }
        case TextConverterFormatQuote: {
            NSArray<NSString *> *lines = [string componentsSeparatedByString:@"\n"];
            NSMutableString *formattedString = [@"" mutableCopy];
            for (NSString *line in lines) {
                [formattedString appendString:@"> "];
                [formattedString appendString:line];
                [formattedString appendString:@"\n"];
            }
            return formattedString;
        }
        case TextConverterFormatListBulleted: {
            NSArray<NSString *> *lines = [string componentsSeparatedByString:@"\n"];
            NSMutableString *formattedString = [@"" mutableCopy];
            for (NSString *line in lines) {
                [formattedString appendString:@"- "];
                [formattedString appendString:line];
                [formattedString appendString:@"\n"];
            }
            return formattedString;
        }
        case TextConverterFormatListNumbered: {
            NSArray<NSString *> *lines = [string componentsSeparatedByString:@"\n"];
            NSMutableString *formattedString = [@"" mutableCopy];
            for (NSString *line in lines) {
                [formattedString appendString:@"1. "];
                [formattedString appendString:line];
                [formattedString appendString:@"\n"];
            }
            return formattedString;
        }
        default:
            break;
    }
    return string;
}

- (void)setContentWithString:(NSString *)string {
    @synchronized (self) {
        NSString *headerHTML = nil;
        if (_header) {
            NSString *path = [NSBundle.mainBundle pathForResource:_header ofType:@""];
            headerHTML = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        }

        MarkdownHTMLRenderer *renderer = [[MarkdownHTMLRenderer alloc] init];
        _html = [renderer htmlStringFromMarkdown:string css:self.css header:headerHTML];

        LogD(@"*** HTML ***");
        LogD(@"%@", _html);
    }
}

@end
