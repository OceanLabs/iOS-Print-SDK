//
//  Modified MIT License
//
//  Copyright (c) 2010-2015 Kite Tech Ltd. https://www.kite.ly
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
#import "OLPrintOrder.h"
#import "OLPrintJob.h"
#import "OLAnalytics.h"
#import "NSObject+Utils.h"
#import "OLPaymentViewController.h"
#import "OLNavigationController.h"
#import "OLKiteABTesting.h"
#import "UIView+RoundRect.h"
#import "OLUserSession.h"
#import "OLImageDownloader.h"

@interface OLPaymentViewController ()
- (void)onBarButtonOrdersClicked;
- (void)dismiss;
@property (assign, nonatomic) BOOL presentedModally;
@end

@implementation UIViewController (OLMethods)

- (void)addBasketIconToTopRight{
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        return;
    }
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    UIButton *basketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 3, 44, 44)];
    imageView.contentMode = UIViewContentModeRight;
    [basketButton addSubview:imageView];
    basketButton.frame = CGRectMake(0,0,50,50);
    [basketButton addTarget:self action:@selector(onButtonBasketClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (printOrder.jobs.count != 0){
        [imageView setImage:[UIImage imageNamedInKiteBundle:@"cart-full"]];
        
        NSUInteger count = printOrder.jobs.count;
        for (id<OLPrintJob> job in printOrder.jobs){
            count += [job extraCopies];
        }
        
        UILabel *qtyLabel = [[UILabel alloc] initWithFrame:CGRectMake(37, 14, 13, 13)];
        qtyLabel.font = [UIFont systemFontOfSize:9];
        qtyLabel.textAlignment = NSTextAlignmentCenter;
        qtyLabel.textColor = [UIColor whiteColor];
        qtyLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
        qtyLabel.minimumScaleFactor = 0.5;
        qtyLabel.adjustsFontSizeToFitWidth = YES;
        if ([OLKiteABTesting sharedInstance].lightThemeColor1){
            qtyLabel.backgroundColor = [OLKiteABTesting sharedInstance].lightThemeColor1;
        }
        else{
            qtyLabel.backgroundColor = [UIColor colorWithRed:0.231 green:0.686 blue:0.855 alpha:1.000];
        }
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
}

- (IBAction)onButtonBasketClicked:(UIBarButtonItem *)sender {
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    
#ifndef OL_NO_ANALYTICS
    NSUInteger count = printOrder.jobs.count;
    for (id<OLPrintJob> job in printOrder.jobs){
        count += [job extraCopies];
    }
    [OLAnalytics trackBasketIconTappedWithNumberBadged:count];
#endif
    
    [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
        [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
        [(OLPaymentViewController *)vc setPresentedModally:YES];
        
        NSURL *cancelUrl = [NSURL URLWithString:[OLKiteABTesting sharedInstance].cancelButtonIconURL];
        if (cancelUrl && ![[OLImageDownloader sharedInstance] cachedDataExistForURL:cancelUrl]){
            [[OLImageDownloader sharedInstance] downloadImageAtURL:cancelUrl withCompletionHandler:^(UIImage *image, NSError *error){
                if (error) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(UIViewController *)vc navigationItem].leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithCGImage:image.CGImage scale:2.0 orientation:UIImageOrientationUp] style:UIBarButtonItemStyleDone target:vc action:@selector(dismiss)];
                });
            }];
        }
        else{
            [(UIViewController *)vc navigationItem].leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:vc action:@selector(dismiss)];
        }
        
        OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
        nvc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
        [self presentViewController:nvc animated:YES completion:NULL];
    }];
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
