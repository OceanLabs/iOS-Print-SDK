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


#import "OLInfoBanner.h"
#import "OLKiteABTesting.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "UIColor+OLHexString.h"

@implementation OLInfoBanner

+ (OLInfoBanner *)showInfoBannerOnViewController:(UIViewController *)vc withTitle:(NSString *)title{
    OLInfoBanner *banner = [[OLInfoBanner alloc] init];
    [vc.view addSubview:banner];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textAlignment = NSTextAlignmentCenter;
    label.minimumScaleFactor = 0.5;
    label.adjustsFontSizeToFitWidth = YES;
    label.numberOfLines = 2;
    [banner addSubview:label];
    
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [label setFont:font];
    }
    
    UIImageView *x = [[UIImageView alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"x"]];
    [banner addSubview:x];
    
    if ([OLKiteABTesting sharedInstance].lightThemeColor4){
        banner.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor4;
        
        UIColor *textColor = [UIColor textColorForBackGroundColor:[OLKiteABTesting sharedInstance].lightThemeColor4];
        label.textColor = textColor;
        x.tintColor = textColor;
    }
    else{
        banner.backgroundColor = [UIColor lightGrayColor];
        label.textColor = [UIColor whiteColor];
        x.tintColor = [UIColor whiteColor];
    }
    
    
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(banner);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[banner]-0-|",
                         @"V:[banner(50)]"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [con addObject:[NSLayoutConstraint constraintWithItem:banner attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:vc.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    [banner.superview addConstraints:con];
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    x.translatesAutoresizingMaskIntoConstraints = NO;
    views = NSDictionaryOfVariableBindings(label, x);
    con = [[NSMutableArray alloc] init];
    
    visuals = @[@"H:[x]-28-|", @"V:|-0-[label]-0-|",
                         @"H:|-50-[label]-50-|"
                         ];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [con addObject:[NSLayoutConstraint constraintWithItem:x attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:x.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [banner addConstraints:con];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:banner action:@selector(dismiss)];
    [banner addGestureRecognizer:tap];
    
    return banner;

}

- (void)dismiss{
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeTranslation(0, -self.frame.origin.y);
        if ([self.delegate respondsToSelector:@selector(infoBannerWillDismiss)]){
            [self.delegate infoBannerWillDismiss];
        }
    } completion:^(BOOL finished){
        [self removeFromSuperview];
    }];
}

@end
