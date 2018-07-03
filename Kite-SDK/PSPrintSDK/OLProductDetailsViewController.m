//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLProductDetailsViewController.h"
#import "OLMarkdownParser.h"
#import "OLAnalytics.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"

@interface OLMarkDownParser ()

- (void)addParsingRuleWithRegularExpression:(NSRegularExpression *)regularExpression block:(OLMarkDownParserMatchBlock)block;

@end

@interface OLProductDetailsViewController ()


@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *line;
@property (weak, nonatomic) IBOutlet UITextView *detailsTextView;
@property (assign, nonatomic) BOOL hasSetupProductDetails;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.detailLabel.text = NSLocalizedStringFromTableInBundle(@"Details", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Product Details");
    
    if ([OLKiteABTesting sharedInstance].hidePrice){
        self.priceLabel.text = nil;
    }
    else{
        self.priceLabel.text = self.product.unitCost;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    if (!self.hasSetupProductDetails){
        self.hasSetupProductDetails = YES;
        [self setupProductDetails];
    }
}

- (void)setupProductDetails{
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font) {
        self.detailsTextView.font = font;
    }
    
    OLMarkDownParser *mdParser = [OLMarkDownParser standardParser];
    font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:13];
    if (font){
        mdParser.strongFont = font;
    }
    
    font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:12];
    if (font) {
        mdParser.paragraphFont = font;
    }
    
    NSMutableAttributedString *attributedString = [[mdParser attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    [attributedString addAttribute:NSForegroundColorAttributeName value:self.detailsTextView.tintColor range:NSMakeRange(0, attributedString.length)];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentNatural;
    paragraphStyle.lineSpacing = 2;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];
    
    NSRange strikeThroughRange = [[attributedString string] rangeOfString:@"\\~.*\\~" options:NSRegularExpressionSearch];
    if (strikeThroughRange.location != NSNotFound){
        [attributedString addAttributes:@{NSStrikethroughStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle], NSForegroundColorAttributeName : [UIColor colorWithWhite:0.627 alpha:1.000]} range:strikeThroughRange];
        [attributedString deleteCharactersInRange:NSMakeRange(strikeThroughRange.location, 1)];
        [attributedString deleteCharactersInRange:NSMakeRange(strikeThroughRange.location + strikeThroughRange.length-2, 1)];
    }
    
    self.detailsTextView.attributedText = attributedString;
}

- (CGFloat)recommendedDetailsBoxHeight{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 340 : 450;
    }
    else{
        return 340;
    }
}

- (IBAction)onDetailsAreaTapped:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(onLabelDetailsTapped:)]){
        [self.delegate performSelector:@selector(onLabelDetailsTapped:) withObject:nil];
    }
}


@end
