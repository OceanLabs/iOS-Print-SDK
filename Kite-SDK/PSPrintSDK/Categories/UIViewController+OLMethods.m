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

#import "UIViewController+OLMethods.h"
#import "UIImage+ImageNamedInKiteBundle.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPrintJob.h"
#import "OLAnalytics.h"
#import "NSObject+Utils.h"
#import "OLNavigationController.h"
#import "OLKiteABTesting.h"
#import "UIView+RoundRect.h"
#import "OLUserSession.h"
#import "OLImageDownloader.h"
#import "OLKitePrintSDK.h"
#import "UIView+AutoLayoutHelper.h"

@import Photobook;

@interface OLKiteViewController ()
- (void)kioskLogout;
@end

@implementation UIViewController (OLMethods)

- (void)addBasketIconToTopRight{
    UIColor *color;
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        color = [OLKiteABTesting sharedInstance].lightThemeColor1;
    }
    else{
        color = self.view.tintColor;
    }
    
    CGFloat buttonHeight = MIN(44, self.navigationController.navigationBar.frame.size.height);
    if (buttonHeight == 0){
        buttonHeight = 44;
    }
    
    UIButton *basketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 0, 44, buttonHeight)];
    imageView.tag = 10;
    imageView.contentMode = UIViewContentModeRight;
    [basketButton addSubview:imageView];
    basketButton.frame = CGRectMake(0,0,50,buttonHeight);
    [basketButton addTarget:self action:@selector(onButtonBasketClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    NSInteger count = [[PhotobookSDK shared] numberOfItemsInBasket];
    
    if (count != 0){
        [imageView setImage:[UIImage imageNamedInKiteBundle:@"cart-full"]];
        
        UILabel *qtyLabel = [[UILabel alloc] initWithFrame:CGRectMake(37, buttonHeight / 2 - 10.5, 13, 13)];
        qtyLabel.tag = 20;
        qtyLabel.font = [UIFont systemFontOfSize:9];
        qtyLabel.textAlignment = NSTextAlignmentCenter;
        qtyLabel.textColor = [UIColor whiteColor];
        qtyLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
        qtyLabel.minimumScaleFactor = 0.5;
        qtyLabel.adjustsFontSizeToFitWidth = YES;
        qtyLabel.backgroundColor = color;
        [qtyLabel makeRoundRectWithRadius:6.5];
        
        [basketButton addSubview:qtyLabel];
        imageView.tintColor = [UIColor colorWithRed:0.349 green:0.361 blue:0.365 alpha:1.000];
    }
    else{
        [imageView setImage:[UIImage imageNamedInKiteBundle:@"cart-empty"]];
        imageView.tintColor = [UIColor colorWithRed:0.349 green:0.361 blue:0.365 alpha:1.000];
    }
    
    if (self.isPushed){
        self.parentViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:basketButton];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:basketButton];
    
    if ([OLKitePrintSDK isKiosk]){
        UIView *buttonView = [[UIView alloc] init];
        [buttonView makeRoundRectWithRadius:2];
        buttonView.backgroundColor = color;
        UIButton *startAgain = [[UIButton alloc] init];
        startAgain.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 20);
        startAgain.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10);
        [startAgain setTitle:NSLocalizedStringFromTableInBundle(@"End Session", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        
        [buttonView addSubview:startAgain];
        startAgain.translatesAutoresizingMaskIntoConstraints = NO;
        
        [startAgain.superview addConstraint:[NSLayoutConstraint constraintWithItem:startAgain attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:startAgain.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [startAgain.superview addConstraint:[NSLayoutConstraint constraintWithItem:startAgain attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:startAgain.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [startAgain setImage:[UIImage imageNamedInKiteBundle:@"endsession"] forState:UIControlStateNormal];
        startAgain.tintColor = [UIColor whiteColor];
        
        [startAgain sizeToFit];
        CGRect frame = startAgain.frame;
        frame.size.height = 32;
        buttonView.frame = frame;
        
        [startAgain addTarget:self action:@selector(kioskLogoutButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.navigationItem.rightBarButtonItem){
            self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, [[UIBarButtonItem alloc] initWithCustomView:buttonView]];
        }
        else{
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonView];
        }
    }
}

- (void)kioskLogoutButtonTapped{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Are you sure?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") message:NSLocalizedStringFromTableInBundle(@"This will log out of any accounts, clear selected photos and start over", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"End Session", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDestructive handler:^(id action){
        [[OLUserSession currentSession].kiteVc kioskLogout];
    }]];
    [self presentViewController:ac animated:YES completion:NULL];
}

- (IBAction)onButtonBasketClicked:(UIBarButtonItem *)sender {    
    UIViewController *checkoutVc = [[PhotobookSDK shared] checkoutViewControllerWithEmbedInNavigation:YES dismissClosure:^(UIViewController *viewController, BOOL success){
        [viewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    if (checkoutVc) {
        checkoutVc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:checkoutVc animated:YES completion:NULL];
    }
}

- (BOOL)isPushed{
    for (UIViewController *vc in self.navigationController.viewControllers){
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return YES;
        }
    }
    return NO;
}

@end
