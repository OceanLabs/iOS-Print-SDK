//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

#import <Foundation/Foundation.h>

@class OLPrintOrder;
@protocol OLPrintJob;
@protocol OLKiteDelegate;

static NSString *const kOLAnalyticsEventName = @"Event Name";
static NSString *const kOLAnalyticsProductCategory = @"Product Category";
static NSString *const kOLAnalyticsProductName = @"Product Name";
static NSString *const kOLAnalyticsApplePayAvailable = @"Apple Pay Available";
static NSString *const kOLAnalyticsPaymentMethod = @"Payment Method";
static NSString *const kOLAnalyticsPhotoSource = @"Photo Source";
static NSString *const kOLAnalyticsFeedbackResult = @"Feedback Result";
static NSString *const kOLAnalyticsSelectedOption = @"Selected Option";
static NSString *const kOLAnalyticsNumberOfPhotos = @"Number of Photos";
static NSString *const kOLAnalyticsNumberOfPhotosInItem = @"Number of Photos in Item";
static NSString *const kOLAnalyticsNumberOfPhotosInOrder = @"Number of Unique Photos in Order";
static NSString *const kOLAnalyticsNumberOnBadge = @"Number of Items on Basket Icon Badge";
static NSString *const kOLAnalyticsQuantity = @"Quantity";
static NSString *const kOLAnalyticsItemsInOrder = @"Items In Order";
static NSString *const kOLAnalyticsOrderCost = @"Order Cost";
static NSString *const kOLAnalyticsOrderShippingCost = @"Order Shipping Cost";
static NSString *const kOLAnalyticsCurrencyCode = @"Currency Code";
static NSString *const kOLAnalyticsItemPrice = @"Item Price";
static NSString *const kOLAnalyticsPromoCode = @"Promo Code";
static NSString *const kOLAnalyticsError = @"Error";

@interface OLAnalytics : NSObject

+ (void)addPushDeviceToken:(NSData *)deviceToken;
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
+ (void)trackDetailsViewProductOptionsTappedForProductName:(NSString *)productName;
+ (void)trackDetailsViewProductOptionsHitBackForProductName:(NSString *)productName;
+ (void)trackDetailsViewProductOptionsSelectedOption:(NSString *)option forProductName:(NSString *)productName;
+ (void)trackOrderHistoryScreenViewed;
+ (void)trackOrderHistoryScreenDismissed;
+ (void)trackQualityScreenHitBack;
+ (void)trackFeedbackButtonTapped;
+ (void)trackFeedbackScreenFinishedWithResult:(NSInteger)result;
+ (void)trackContinueShoppingButtonPressed:(OLPrintOrder *)printOrder;
+ (void)trackShippingScreenHitBackForOrder:(OLPrintOrder *)printOrder;
+ (void)trackShippingScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField;
+ (void)trackChooseAddressScreenViewed;
+ (void)trackAddAddressScreenViewed;
+ (void)trackSearchAddressScreenViewed;
+ (void)trackPaymentScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitItemQtyUpForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitItemQtyDownForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenHitEditItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenSuccessfullyAppliedPromoCode:(NSString *)code forOrder:(OLPrintOrder *)order;
+ (void)trackPaymentScreenUnsuccessfullyAppliedPromoCode:(NSString *)code withError:(NSError *)error forOrder:(OLPrintOrder *)order;
+ (void)trackPaymentScreenDidTapOnPromoCodeBoxforOrder:(OLPrintOrder *)order;
+ (void)trackPaymentScreenPaymentMethodHit:(NSString *)method forOrder:(OLPrintOrder *)order applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentScreenPaymentMethodDidCancel:(NSString *)method forOrder:(OLPrintOrder *)order applePayIsAvailable:(NSString *)applePayIsAvailable;
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
