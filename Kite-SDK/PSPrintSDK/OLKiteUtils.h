//
//  OLKiteUtils.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/30/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OLKiteDelegate;
@class OLProductHomeViewController;
@class OLKiteViewController;
@class OLPrintOrder;
@class OLProduct;
@class OLCheckoutViewController;

@interface OLKiteUtils : NSObject

+ (NSBundle *)kiteBundle;

+ (NSString *)userEmail:(UIViewController *)topVC;

+ (NSString *)userPhone:(UIViewController *)topVC;

+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;

+ (OLProductHomeViewController *)homeViewControllerInNavStack:(NSArray *)viewControllers;

+ (OLKiteViewController *)kiteVcForViewController:(UIViewController *)vc;

#ifdef OL_KITE_OFFER_APPLE_PAY
+(BOOL)isApplePayAvailable;
#endif

+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(id vc))handler;
+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen;
+ (void)shippingControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler;

@end
