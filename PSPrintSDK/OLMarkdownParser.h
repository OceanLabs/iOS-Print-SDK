//
//  TSMarkdownParser.h
//  TSMarkdownParser
//
//  Created by Tobias Sundstrand on 14-08-30.
//  Copyright (c) 2014 Computertalk Sweden. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^OLMarkDownParserMatchBlock)(NSTextCheckingResult *match, NSMutableAttributedString *attributedString);
typedef void (^OLMarkDownParserFormattingBlock)(NSMutableAttributedString *attributedString, NSRange range);

@interface OLMarkDownParser : NSObject

@property (nonatomic, strong) UIFont *paragraphFont;
@property (nonatomic, strong) UIFont *strongFont;
@property (nonatomic, strong) UIFont *emphasisFont;
@property (nonatomic, strong) UIFont *h1Font;
@property (nonatomic, strong) UIFont *h2Font;
@property (nonatomic, strong) UIFont *h3Font;
@property (nonatomic, strong) UIFont *h4Font;
@property (nonatomic, strong) UIFont *h5Font;
@property (nonatomic, strong) UIFont *h6Font;
@property (nonatomic, strong) UIFont *monospaceFont;
@property (nonatomic, strong) UIColor *monospaceTextColor;
@property (nonatomic, strong) UIColor *linkColor;
@property (nonatomic, copy) NSNumber *linkUnderlineStyle;

+ (instancetype)standardParser;

- (NSAttributedString *)attributedStringFromMarkdown:(NSString *)markdown;

- (NSAttributedString *)attributedStringFromMarkdown:(NSString *)markdown attributes:(NSDictionary *)attributes;

- (NSAttributedString *)attributedStringFromAttributedMarkdownString:(NSAttributedString *)attributedString;

- (void)addParsingRuleWithRegularExpression:(NSRegularExpression *)regularExpression withBlock:(OLMarkDownParserMatchBlock)block;

- (void)addParagraphParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

/* block parsing */

- (void)addHeaderParsingWithLevel:(int)header formattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

- (void)addListParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

/* bracket parsing */

- (void)addImageParsingWithImageFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock alternativeTextFormattingBlock:(OLMarkDownParserFormattingBlock)alternativeFormattingBlock;

- (void)addLinkParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

/* inline parsing */

- (void)addMonospacedParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

- (void)addStrongParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

- (void)addEmphasisParsingWithFormattingBlock:(OLMarkDownParserFormattingBlock)formattingBlock;

@end
