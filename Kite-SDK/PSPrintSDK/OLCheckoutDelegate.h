//
//  OLCheckoutDelegate.h
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 07/08/2014.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLCheckoutViewController;

@protocol OLCheckoutDelegate <NSObject>

@optional
- (void)userDidTapContinueShoppingButton;
- (BOOL)receiptViewControllerShouldBeDismissable;
- (BOOL)shouldDismissPaymentViewControllerAfterPayment;

- (void)checkoutViewControllerDidCancel:(OLCheckoutViewController *)controller;

@end
