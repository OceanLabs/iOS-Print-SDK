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
#import "OLCustomNavigationController.h"
#import "OLKiteABTesting.h"

@interface OLKiteViewController (Private)
@property (strong, nonatomic) OLPrintOrder *printOrder;
@end

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
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    UIButton *basketButton = [UIButton buttonWithType:UIButtonTypeCustom];
    basketButton.frame = CGRectMake(0,0,44,44);
    [basketButton addTarget:self action:@selector(onButtonBasketClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (printOrder.jobs.count != 0){
        [basketButton setImage:[UIImage imageNamedInKiteBundle:@"cart-full"] forState:UIControlStateNormal];
        
        NSUInteger count = printOrder.jobs.count;
        for (id<OLPrintJob> job in printOrder.jobs){
            count += [job extraCopies];
        }
        
        UILabel *qtyLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 12.5, 10, 10)];
        qtyLabel.font = [UIFont systemFontOfSize:9];
        qtyLabel.textAlignment = NSTextAlignmentCenter;
        qtyLabel.textColor = [UIColor whiteColor];
        qtyLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
        qtyLabel.minimumScaleFactor = 0.5;
        qtyLabel.adjustsFontSizeToFitWidth = YES;
        
        [basketButton addSubview:qtyLabel];
    }
    else{
        [basketButton setImage:[UIImage imageNamedInKiteBundle:@"cart-empty"] forState:UIControlStateNormal];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:basketButton];
}

- (IBAction)onButtonBasketClicked:(UIBarButtonItem *)sender {
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    
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
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
        [(OLPaymentViewController *)vc setPresentedModally:YES];
        
        [(UIViewController *)vc navigationItem].leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:vc action:@selector(dismiss)];
        
//        if ([self isMemberOfClass:[OLPaymentViewController class]]){
//            [(UIViewController *)vc navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamedInKiteBundle:@"menu_button_orders"] style:UIBarButtonItemStylePlain target:vc action:@selector(onBarButtonOrdersClicked)];
//        }
        
        OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
        nvc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:nvc animated:YES completion:NULL];
    }];
}

@end
