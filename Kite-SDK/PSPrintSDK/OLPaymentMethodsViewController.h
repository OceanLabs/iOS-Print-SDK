//
//  OLPaymentMethodsViewController.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 16/05/16.
//  Copyright © 2016 Kite.ly. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kOLPaymentMethodNone,
    kOLPaymentMethodCreditCard,
    kOLPaymentMethodApplePay,
    kOLPaymentMethodPayPal
}OLPaymentMethod;

@class OLPaymentMethodsViewController;

@protocol OLPaymentMethodsViewControllerDelegate <NSObject>

- (void)paymentMethodsViewController:(OLPaymentMethodsViewController *)vc didPickPaymentMethod:(OLPaymentMethod)method;

@end

@interface OLPaymentMethodsViewController : UIViewController
@property (weak, nonatomic) id<OLPaymentMethodsViewControllerDelegate> delegate;
@property (assign, nonatomic) OLPaymentMethod selectedPaymentMethod;
@end
