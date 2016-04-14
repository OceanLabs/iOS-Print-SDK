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

#import "OLUpsellViewController.h"
#import "UIView+RoundRect.h"
#import "OLProduct.h"
#import "OLProductTemplate.h"
#import "NSDecimalNumber+CostFormatter.h"

@interface OLUpsellViewController ()

@property (weak, nonatomic) IBOutlet UIView *offerContainerView;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) OLProduct *product;

@end

@interface OLProduct ()
-(void)setCoverImageToImageView:(UIImageView *)imageView;
- (NSDecimalNumber*) unitCostDecimalNumber;
- (NSString *)currencyCode;
@end

@implementation OLUpsellViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    [self.offerContainerView makeRoundRectWithRadius:2];
    self.offerContainerView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
    
    [self.acceptButton makeRoundRectWithRadius:2];
    [self.declineButton makeRoundRectWithRadius:2];
    
    self.product = [OLProduct productWithTemplateId:self.offer.offerTemplate];
    [self.product setCoverImageToImageView:self.imageView];
    
    
    NSDecimalNumber *discountedCost = self.product.unitCostDecimalNumber;
    
    NSDecimalNumber *discount = [NSDecimalNumber decimalNumberWithString:@"100.0"];
    discount = [discount decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithDecimal:[self.offer.discountPercentage decimalValue]]];
    discount = [discount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100.0"]];
    discountedCost = [discountedCost decimalNumberByMultiplyingBy:discount];
    
    NSString *discountedString = [discountedCost formatCostForCurrencyCode:[self.product currencyCode]];
    NSString *bodyString;
    
    if (self.offer.text){
        self.headerLabel.text = [self.offer.headerText stringByReplacingOccurrencesOfString:@"[[price]]" withString:[NSString stringWithFormat:@"%@ %@", self.product.unitCost, discountedString]];
        bodyString = [self.offer.text stringByReplacingOccurrencesOfString:@"[[price]]" withString:[NSString stringWithFormat:@"%@ %@", self.product.unitCost, discountedString]];
    }
    else if ([self.triggeredProduct.templateId isEqualToString:self.offer.offerTemplate]){
        if (self.product.quantityToFulfillOrder > 1 && (self.product.productTemplate.templateUI == kOLTemplateUIRectagle || self.product.productTemplate.templateUI == kOLTemplateUICircle)){
            self.headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Add %ld %@!", @""), self.product.quantityToFulfillOrder, self.product.productTemplate.name];
            bodyString = [NSString stringWithFormat:NSLocalizedString(@"Create another pack for\nonly %@ %@", @""), self.product.unitCost, discountedString];
        }
        else{
            self.headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Add another %@!", @""), self.product.productTemplate.name];
            bodyString = [NSString stringWithFormat:NSLocalizedString(@"Create another %@ for\nonly %@ %@", @""), self.product.productTemplate.name, self.product.unitCost, discountedString];
        }
    }
    else{
        if (self.product.quantityToFulfillOrder > 1 && (self.product.productTemplate.templateUI == kOLTemplateUIRectagle || self.product.productTemplate.templateUI == kOLTemplateUICircle)){
            self.headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Add %ld %@!", @""), self.product.quantityToFulfillOrder, self.product.productTemplate.name];
            bodyString = [NSString stringWithFormat:NSLocalizedString(@"Create a pack for\nonly %@ %@", @""), self.product.unitCost, discountedString];
        }
        else{
            self.headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Add a %@!", @""), self.product.productTemplate.name];
            bodyString = [NSString stringWithFormat:NSLocalizedString(@"Create a %@ for\nonly %@ %@", @""), self.product.productTemplate.name, self.product.unitCost, discountedString];
        }
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:bodyString attributes:@{NSFontAttributeName : self.bodyLabel.font}];
    [attributedString addAttribute:NSStrikethroughStyleAttributeName value:@1 range:[bodyString rangeOfString:self.product.unitCost]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.878 green:0.114 blue:0.341 alpha:1.000] range:[bodyString rangeOfString:discountedString]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.878 green:0.114 blue:0.341 alpha:1.000] range:[bodyString rangeOfString:discountedString]];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14] range:[bodyString rangeOfString:discountedString]];
    
    self.bodyLabel.attributedText = attributedString;
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:0.25 animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0.118 alpha:0.800];
    }];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.offerContainerView.transform = CGAffineTransformIdentity;
    }completion:NULL];
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
    [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    } completion:NULL];
    
    [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.offerContainerView.transform = CGAffineTransformMakeTranslation(0, -self.view.frame.size.height);
    }completion:^(BOOL finished){
        [self.delegate userDidAcceptUpsell:self];
    }];
    
}

- (IBAction)declineButtonAction:(UIButton *)sender {
    [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    } completion:NULL];
    
    [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.offerContainerView.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, self.view.frame.size.height), -M_PI_4);
    }completion:^(BOOL finished){
        [self.delegate userDidDeclineUpsell:self];
    }];
}



@end
