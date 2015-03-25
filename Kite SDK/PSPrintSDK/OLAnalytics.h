//
//  OLAnalytics.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/27/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLPrintOrder;

@interface OLAnalytics : NSObject

+ (void)trackKiteViewControllerLoaded;
+ (void)trackProductSelectionScreenViewed;
+ (void)trackProductDescriptionScreenViewed:(NSString *)productName;
+ (void)trackProductTemplateSelectionScreenViewed:(NSString *)productName;
+ (void)trackProductTypeSelectionScreenViewedWithTemplateClass:(NSString *)templateClassString;
+ (void)trackReviewScreenViewed:(NSString *)productName;
+ (void)trackShippingScreenViewedForOrder:(OLPrintOrder *)printOrder;
+ (void)trackPaymentScreenViewedForOrder:(OLPrintOrder *)printOrder;
+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder;
+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder;

@end
