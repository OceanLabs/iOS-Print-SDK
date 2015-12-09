//
//  OLAnalytics.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 1/27/15.
//  Copyright (c) 2015 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OLPrintOrder;
@protocol OLPrintJob;
@protocol OLKiteDelegate;

@interface OLAnalytics : NSObject

+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint;
+ (void)trackKiteDismissed;
+ (void)trackProductSelectionScreenViewed;
+ (void)trackProductDescriptionScreenViewed:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductDetailsViewOpened:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductDetailsViewClosed:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductDescriptionScreenHitBack:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductTypeSelectionScreenViewedWithTemplateClass:(NSString *)templateClassString;
+ (void)trackProductTypeSelectionScreenHitBackTemplateClass:(NSString *)templateClassString;
+ (void)trackPhotoSelectionScreenViewed:(NSString *)productName;
+ (void)trackPhotoSelectionScreenHitBack:(NSString *)productName;
+ (void)trackPhotoProviderPicked:(NSString *)provider forProductName:(NSString *)productName;
+ (void)trackPhotoProvider:(NSString *)provider numberOfPhotosAdded:(NSInteger)number forProductName:(NSString *)productName;
+ (void)trackPhotoSelectionScreenNumberOfPhotosRemoved:(NSUInteger)number forProductName:(NSString *)productName;
+ (void)trackReviewScreenViewed:(NSString *)productName;
+ (void)trackReviewScreenHitBack:(NSString *)productName numberOfPhotos:(NSInteger)numberOfPhotos;
+ (void)trackReviewScreenDeletedPhotoForProductName:(NSString *)productName;
+ (void)trackReviewScreenDidCropPhotoForProductName:(NSString *)productName;
+ (void)trackReviewScreenEnteredCropScreenForProductName:(NSString *)productName;
+ (void)trackReviewScreenIncrementedPhotoQtyForProductName:(NSString *)productName;
+ (void)trackReviewScreenDecrementedPhotoQtyForProductName:(NSString *)productName;
+ (void)trackContinueShoppingButtonPressed:(OLPrintOrder *)printOrder;
+ (void)trackShippingScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField;
+ (void)trackPaymentScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitItemQtyUpForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitItemQtyDownForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitEditItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitEditItemDone:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenDidDeleteItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitCheckoutForOrder:(OLPrintOrder *)printOrder;
+ (void)trackPaymentScreenHitBackToApplePayForOrder:(OLPrintOrder *)printOrder;
+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder paymentMethod:(NSString *)method applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketIconTappedWithNumberBadged:(NSInteger)number;
+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder;
+ (void)trackQualityInfoScreenViewed;

+ (void)incrementLaunchSDKCount;
+ (void)setExtraInfo:(NSDictionary *)info;
+ (NSString *)userDistinctId;
+ (void)setKiteDelegate:(id<OLKiteDelegate>)kd;

@end
