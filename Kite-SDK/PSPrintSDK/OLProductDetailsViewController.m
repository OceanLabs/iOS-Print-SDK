//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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
#import "OLProductOptionsViewController.h"
#import "TSMarkdownParser.h"
#import "OLAnalytics.h"
#import "OLKiteABTesting.h"

@interface OLProductDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIView *moreOptionsView;
@property (weak, nonatomic) IBOutlet UILabel *selectedOptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *optionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chevron;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@end

@interface OLProductOverViewViewController

- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender;
@property (strong, nonatomic) UILabel *detailsTextLabel;

@end

@implementation OLProductDetailsViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if ([OLKiteABTesting sharedInstance].darkTheme){
        self.detailsLabel.textColor = [UIColor whiteColor];
        self.optionLabel.textColor = [UIColor whiteColor];
        self.selectedOptionLabel.textColor = [UIColor whiteColor];
        self.priceLabel.textColor = [UIColor whiteColor];
    }
    
    NSMutableAttributedString *attributedString = [[[TSMarkdownParser standardParser] attributedStringFromMarkdown:[self.product detailsString]] mutableCopy];
    
    if ([OLKiteABTesting sharedInstance].darkTheme){
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, attributedString.length)];
    }
    else{
        [attributedString addAttribute:NSForegroundColorAttributeName value:self.detailsTextLabel.tintColor range:NSMakeRange(0, attributedString.length)];
    }
    self.detailsTextLabel.attributedText = attributedString;
    
    if (self.product.productTemplate.options.count == 0){
        [self.moreOptionsView removeFromSuperview];
    }
    else if (self.product.productTemplate.options.count != 1){
        [self.selectedOptionLabel removeFromSuperview];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (self.product.productTemplate.options.count == 1){
        OLProductTemplateOption *option = self.product.productTemplate.options.firstObject;
        self.optionLabel.text = option.name;
        self.selectedOptionLabel.text = [option nameForSelection:self.product.selectedOptions[[option code]]];
    }
}

- (CGFloat)recommendedDetailsBoxHeight{
    if ([self respondsToSelector:@selector(traitCollection)]){
        return self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 340 : 450;
    }
    else{
        return 340;
    }
}

- (IBAction)onOptionsClicked:(UIButton *)sender {
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackDetailsViewProductOptionsTappedForProductName:self.product.productTemplate.name];
#endif
    
    OLProductOptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOptionsViewController"];
    options.product = self.product;
    [UIView animateWithDuration:0.25 animations:^{
        [self.navigationController pushViewController:options animated:YES];
    }];
    
    if ([self.delegate respondsToSelector:@selector(optionsButtonClicked)]){
        [self.delegate optionsButtonClicked];
    }
}

- (IBAction)onDetailsAreaTapped:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(onLabelDetailsTapped:)]){
        [self.delegate performSelector:@selector(onLabelDetailsTapped:) withObject:nil];
    }
}


@end
