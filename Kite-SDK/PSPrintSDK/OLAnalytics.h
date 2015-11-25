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

+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint;
+ (void)trackProductSelectionScreenViewed;
+ (void)trackProductDescriptionScreenViewed:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductTemplateSelectionScreenViewed:(NSString *)productName;
+ (void)trackProductTypeSelectionScreenViewedWithTemplateClass:(NSString *)templateClassString;
+ (void)trackPhotoSelectionScreenViewed:(NSString *)productName;
+ (void)trackReviewScreenViewed:(NSString *)productName;
+ (void)trackContinueShoppingButtonPressed:(NSNumber *)numberOfJobsInBasket;
+ (void)trackShippingScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField;
+ (void)trackPaymentScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder paymentMethod:(NSString *)method applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder;
+ (void)trackQualityInfoScreenViewed;

+ (void)incrementLaunchSDKCount;
+ (void)setExtraInfo:(NSDictionary *)info;
+ (NSString *)userDistinctId;

@end
