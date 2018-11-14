//
//  TSMarkdownParser.m
//  TSMarkdownParser
//
//  Created by Tobias Sundstrand on 14-08-30.
//  Copyright (c) 2014 Computertalk Sweden. All rights reserved.
//

#import "OLMarkdownParser.h"

@interface OLTSExpressionBlockPair : NSObject

@property (nonatomic, strong) NSRegularExpression *regularExpression;
@property (nonatomic, strong) OLMarkDownParserMatchBlock block;

+ (OLTSExpressionBlockPair *)pairWithRegularExpression:(NSRegularExpression *)regularExpression block:(OLMarkDownParserMatchBlock)block;

@end

@implementation OLTSExpressionBlockPair

+ (OLTSExpressionBlockPair *)pairWithRegularExpression:(NSRegularExpression *)regularExpression block:(OLMarkDownParserMatchBlock)block {
    OLTSExpressionBlockPair *pair = [OLTSExpressionBlockPair new];
    pair.regularExpression = regularExpression;
    pair.block = block;
    return pair;
}

@end

@interface OLMarkDownParser ()

@property (nonatomic, strong) NSMutableArray *parsingPairs;
@property (nonatomic, copy) void (^paragraphParsingBlock)(NSMutableAttributedString *attributedString);

@end

@implementation OLMarkDownParser

- (instancetype)init {
    self = [super init];
    if(self) {
        _parsingPairs = [NSMutableArray array];
        _paragraphFont = [UIFont systemFontOfSize:12];
        _strongFont = [UIFont boldSystemFontOfSize:12];
        _emphasisFont = [UIFont italicSystemFontOfSize:12];
        _h1Font = [UIFont boldSystemFontOfSize:23];
        _h2Font = [UIFont boldSystemFontOfSize:21];
        _h3Font = [UIFont boldSystemFontOfSize:19];
        _h4Font = [UIFont boldSystemFontOfSize:17];
        _h5Font = [UIFont boldSystemFontOfSize:15];
        _h6Font = [UIFont boldSystemFontOfSize:13];
        _linkColor = [UIColor blueColor];
        _linkUnderlineStyle = @(NSUnderlineStyleSingle);
        _monospaceFont = [UIFont fontWithName:@"Menlo" size:12];
        _monospaceTextColor = [UIColor colorWithRed:0.95 green:0.54 blue:0.55 alpha:1];
    }
    return self;
}

+ (instancetype)standardParser {
    OLMarkDownParser *defaultParser = [self new];
    
    __weak OLMarkDownParser *weakParser = defaultParser;
    
    [defaultParser addParagraphParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.paragraphFont
                                 range:range];
    }];
    
    /* block parsing */
    
    [defaultParser addHeaderParsingWithLevel:1 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h1Font
                                 range:range];
    }];
    
    [defaultParser addHeaderParsingWithLevel:2 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h2Font
                                 range:range];
    }];
    
    [defaultParser addHeaderParsingWithLevel:3 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h3Font
                                 range:range];
    }];
    
    [defaultParser addHeaderParsingWithLevel:4 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h4Font
                                 range:range];
    }];
    
    [defaultParser addHeaderParsingWithLevel:5 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h5Font
                                 range:range];
    }];
    
    [defaultParser addHeaderParsingWithLevel:6 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h6Font
                                 range:range];
    }];
    
    [defaultParser addListParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString replaceCharactersInRange:range withString:@"•\t"];
    }];
    
    /* bracket parsing */
    
    [defaultParser addImageParsingWithImageFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        // no additional formatting
    }                       alternativeTextFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        // no additional formatting
    }];
    
    [defaultParser addLinkParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSUnderlineStyleAttributeName
                                 value:weakParser.linkUnderlineStyle
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:weakParser.linkColor
                                 range:range];
    }];
    
    /* inline parsing */
    
    [defaultParser addMonospacedParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.monospaceFont
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:weakParser.monospaceTextColor
                                 range:range];
    }];
    
    [defaultParser addStrongParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.strongFont
                                 range:range];
    }];
    
    [defaultParser addEmphasisParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.emphasisFont
                                 range:range];
    }];
    
    return defaultParser;
}

// block regex
static NSString *const OLMarkDownHeaderRegex    = @"^(#{%i}\\s{1})(?!#).*$";
static NSString *const OLMarkDownListRegex      = @"^(\\*|\\+|\\-)[^\\*].+$";

// bracket regex
static NSString *const OLMarkDownImageRegex     = @"\\!\\[.*?\\]\\(\\S*\\)";
static NSString *const OLMarkDownLinkRegex      = @"(?<!\\!)\\[.*?\\]\\([^\\)]*\\)";

// inline regex
static NSString *const OLMarkDownMonospaceRegex = @"(`+)\\s*([\\s\\S]*?[^`])\\s*\\1(?!`)";
static NSString *const OLMarkDownStrongRegex    = @"([\\*|_]{2}).+?\\1";
static NSString *const OLMarkDownEmRegex        = @"([\\*|_]{1}).+?\\1";

- (void)addParagraphParsingWithFormattingBlock:(void(^)(NSMutableAttributedString *attributedString, NSRange range))formattingBlock {
    self.paragraphParsingBlock = ^(NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, NSMakeRange(0, attributedString.length));
    };
}

#pragma mark block parsing

- (void)addHeaderParsingWithLevel:(int)header formattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock {
    NSString *headerRegex = [NSString stringWithFormat:OLMarkDownHeaderRegex, header];
    NSRegularExpression *headerExpression = [NSRegularExpression regularExpressionWithPattern:headerRegex options:0 | NSRegularExpressionAnchorsMatchLines error:nil];
    [self addParsingRuleWithRegularExpression:headerExpression withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, match.range);
        [attributedString deleteCharactersInRange:[match rangeAtIndex:1]];
    }];
}

- (void)addListParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock {
    NSRegularExpression *listParsing = [NSRegularExpression regularExpressionWithPattern:OLMarkDownListRegex options:0|NSRegularExpressionAnchorsMatchLines error:nil];
    [self addParsingRuleWithRegularExpression:listParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, NSMakeRange(match.range.location, 1));
    }];
}

#pragma mark bracket parsing

- (void)addImageParsingWithImageFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock alternativeTextFormattingBlock:(OLMarkDownParserFormattingBlock)alternativeFormattingBlock {
    NSRegularExpression *headerExpression = [NSRegularExpression regularExpressionWithPattern:OLMarkDownImageRegex options:0 error:nil];
    [self addParsingRuleWithRegularExpression:headerExpression withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        NSUInteger imagePathStart = [attributedString.string rangeOfString:@"(" options:0 range:match.range].location;
        NSRange linkRange = NSMakeRange(imagePathStart, match.range.length+match.range.location- imagePathStart -1);
        NSString *imagePath = [attributedString.string substringWithRange:NSMakeRange(linkRange.location+1, linkRange.length-1)];
        UIImage *image = [UIImage imageNamed:imagePath];
        if(image){
            [attributedString deleteCharactersInRange:match.range];
            NSTextAttachment *imageAttachment = [NSTextAttachment new];
            imageAttachment.image = image;
            imageAttachment.bounds = CGRectMake(0, -5, image.size.width, image.size.height);
            NSAttributedString *imgStr = [NSAttributedString attributedStringWithAttachment:imageAttachment];
            NSRange imageRange = NSMakeRange(match.range.location, 1);
            [attributedString insertAttributedString:imgStr atIndex:match.range.location];
            if(formattingBlock) {
                formattingBlock(attributedString, imageRange);
            }
        } else {
            NSUInteger linkTextEndLocation = [attributedString.string rangeOfString:@"]" options:0 range:match.range].location;
            NSRange linkTextRange = NSMakeRange(match.range.location+2, linkTextEndLocation-match.range.location-2);
            NSString *alternativeText = [attributedString.string substringWithRange:linkTextRange];
            if(alternativeFormattingBlock) {
                alternativeFormattingBlock(attributedString, match.range);
            }
            [attributedString replaceCharactersInRange:match.range withString:alternativeText];
        }
    }];
}

- (void)addLinkParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock {
    NSRegularExpression *linkParsing = [NSRegularExpression regularExpressionWithPattern:OLMarkDownLinkRegex options:0 error:nil];
    
    [self addParsingRuleWithRegularExpression:linkParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        NSUInteger linkStartInResult = [attributedString.string rangeOfString:@"(" options:NSBackwardsSearch range:match.range].location;
        NSRange linkRange = NSMakeRange(linkStartInResult, match.range.length+match.range.location-linkStartInResult-1);
        NSString *linkURLString = [attributedString.string substringWithRange:NSMakeRange(linkRange.location+1, linkRange.length-1)];
        NSURL *url = [NSURL URLWithString:linkURLString] ?: [NSURL URLWithString:
                                                             [linkURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
        
        NSUInteger linkTextEndLocation = [attributedString.string rangeOfString:@"]" options:0 range:match.range].location;
        NSRange linkTextRange = NSMakeRange(match.range.location, linkTextEndLocation-match.range.location-1);
        
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange(linkRange.location-2, linkRange.length+2)];
        
        if (url) {
            [attributedString addAttribute:NSLinkAttributeName
                                     value:url
                                     range:linkTextRange];
        }
        
        formattingBlock(attributedString, linkTextRange);
    }];
}

#pragma mark inline parsing

- (void)addMonospacedParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock {
    NSRegularExpression *monoParsing = [NSRegularExpression regularExpressionWithPattern:OLMarkDownMonospaceRegex options:0 error:nil];
    [self addParsingRuleWithRegularExpression:monoParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, match.range);
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange((match.range.location + match.range.length - 2), 1)];
    }];
}

- (void)addStrongParsingWithFormattingBlock:(void(^)(NSMutableAttributedString *attributedString, NSRange range))formattingBlock {
    NSRegularExpression *boldParsing = [NSRegularExpression regularExpressionWithPattern:OLMarkDownStrongRegex options:0 error:nil];
    
    [self addParsingRuleWithRegularExpression:boldParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, match.range);
        
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 2)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-4, 2)];
    }];
}

- (void)addEmphasisParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock {
    NSRegularExpression *emphasisParsing = [NSRegularExpression regularExpressionWithPattern:OLMarkDownEmRegex options:0 error:nil];
    
    [self addParsingRuleWithRegularExpression:emphasisParsing withBlock:^(NSTextCheckingResult *match, NSMutableAttributedString *attributedString) {
        formattingBlock(attributedString, match.range);
        
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange(match.range.location+match.range.length-2, 1)];
    }];
}

#pragma mark -

- (void)addParsingRuleWithRegularExpression:(NSRegularExpression *)regularExpression withBlock:(OLMarkDownParserMatchBlock)block {
    @synchronized (self) {
        [self.parsingPairs addObject:[OLTSExpressionBlockPair pairWithRegularExpression:regularExpression block:block]];
    }
}

- (NSAttributedString *)attributedStringFromMarkdown:(NSString *)markdown attributes:(NSDictionary *)attributes {
    NSAttributedString *attributedString = nil;
    if (! attributes) {
        attributedString = [[NSAttributedString alloc] initWithString:markdown];
    } else {
        attributedString = [[NSAttributedString alloc] initWithString:markdown attributes:attributes];
    }
    
    return [self attributedStringFromAttributedMarkdownString:attributedString];
}

- (NSAttributedString *)attributedStringFromMarkdown:(NSString *)markdown {
    return [self attributedStringFromMarkdown:markdown attributes:nil];
}

- (NSAttributedString *)attributedStringFromAttributedMarkdownString:(NSAttributedString *)attributedString {
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    if (self.paragraphParsingBlock) {
        self.paragraphParsingBlock(mutableAttributedString);
    }
    
    @synchronized (self) {
        for (OLTSExpressionBlockPair *expressionBlockPair in self.parsingPairs) {
            NSTextCheckingResult *match;
            while((match = [expressionBlockPair.regularExpression firstMatchInString:mutableAttributedString.string options:0 range:NSMakeRange(0, mutableAttributedString.string.length)])){
                expressionBlockPair.block(match, mutableAttributedString);
            }
        }
    }
    return mutableAttributedString;
}

@end
