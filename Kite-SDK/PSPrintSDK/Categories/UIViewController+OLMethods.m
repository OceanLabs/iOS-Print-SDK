//
//  UIViewController+OLMethods.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 11/12/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
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
