//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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
@class OLProductTemplate;
@protocol OLPrintJob;

// Main Events - Sent to MixPanel
static NSString *const kOLAnalyticsEventNameKiteLoaded = @"Kite Loaded";
static NSString *const kOLAnalyticsEventNameCategoryListScreenViewed = @"Category List Screen Viewed";
static NSString *const kOLAnalyticsEventNameQualityInfoScreenViewed = @"Quality Info Screen Viewed";
static NSString *const kOLAnalyticsEventNamePrintAtHomeTapped = @"Print At Home Tapped";
static NSString *const kOLAnalyticsEventNameProductDetailsScreenViewed = @"Product Details Screen Viewed";
static NSString *const kOLAnalyticsEventNameProductListScreenViewed = @"Product List Screen Viewed";
static NSString *const kOLAnalyticsEventNameImagePickerScreenViewed = @"Image Picker Screen Viewed";
static NSString *const kOLAnalyticsEventNameReviewScreenViewed = @"Review Screen Viewed";
static NSString *const kOLAnalyticsEventNamePhotobookEditScreenViewed = @"Photobook Edit Screen Viewed";
static NSString *const kOLAnalyticsEventNameContinueShoppingButtonTapped = @"Continue Shopping Button Tapped";
static NSString *const kOLAnalyticsEventNameDeliveryDetailsScreenViewed = @"Delivery Details Screen Viewed";
static NSString *const kOLAnalyticsEventNameAddressSelectionScreenViewed = @"Address Selection Screen Viewed";
static NSString *const kOLAnalyticsEventNameAddEditAddressScreenViewed = @"Add/Edit Address Screen Viewed";
static NSString *const kOLAnalyticsEventNameSearchAddressScreenViewed = @"Search Address Screen Viewed";
static NSString *const kOLAnalyticsEventNameBasketScreenViewed = @"Basket Screen Viewed";
static NSString *const kOLAnalyticsEventNamePaymentCompleted = @"Payment Completed";
static NSString *const kOLAnalyticsEventNamePrintOrderSubmission = @"Print Order Submission";
static NSString *const kOLAnalyticsEventNamePaymentMethodScreenViewed = @"Payment Method Screen Viewed";
static NSString *const kOLAnalyticsEventNameShippingMethodScreenViewed = @"Shipping Method Screen Viewed";
static NSString *const kOLAnalyticsEventNamePaymentMethodSelected = @"Payment Method Selected";
static NSString *const kOLAnalyticsEventNameShippingMethodSelected = @"Shipping Method Selected";
static NSString *const kOLAnalyticsEventNameItemAddedToBasket = @"Item Added To Basket";

// Secondary Events - Not Sent to MixPanel
static NSString *const kOLAnalyticsEventNameProductListScreenHitBack = @"Product List Screen Hit Back";
static NSString *const kOLAnalyticsEventNameKiteDismissed = @"Kite Dismissed";
static NSString *const kOLAnalyticsEventNameKitePhotoProviderSelected = @"Photo Provider Selected";
static NSString *const kOLAnalyticsEventNameKiteQualityInfoScreenHitBack = @"Quality Info Screen Hit Back";
static NSString *const kOLAnalyticsEventNameOrderHistoryViewed = @"Order History Viewed";
static NSString *const kOLAnalyticsEventNameOrderHistoryDismissed = @"Order History Dismissed";
static NSString *const kOLAnalyticsEventNameBasketItemQuantityDown = @"Basket Item Quantity Down";
static NSString *const kOLAnalyticsEventNameReviewScreenHitBack = @"Review Screen Hit Back";
static NSString *const kOLAnalyticsEventNameBasketItemQuantityUp = @"Basket Item Quantity Up";
static NSString *const kOLAnalyticsEventNameEditPhotoTapped = @"Edit Photo Tapped";
static NSString *const kOLAnalyticsEventNameEditScreenFinishedEditingPhoto = @"Edit Screen Finished Editing Photo";
static NSString *const kOLAnalyticsEventNameReviewScreenDecrementedPhotoQuantity = @"Review Screen Decremented Photo Quantity";
static NSString *const kOLAnalyticsEventNameBasketScreenDeleteItem = @"Basket Screen Delete Item";
static NSString *const kOLAnalyticsEventNameBasketScreenDidEditItem = @"Basket Screen Did Edit Item";
static NSString *const kOLAnalyticsEventNameProductDetailsOpened = @"Product Details Opened";
static NSString *const kOLAnalyticsEventNameProductDetailsClosed = @"Product Details Closed";
static NSString *const kOLAnalyticsEventNameBasketScreenHitBack = @"Basket Screen Hit Back";
static NSString *const kOLAnalyticsEventNameBasketScreenSuccessfullyAppliedPromoCode = @"Basket Screen Successfully Applied Promo Code";
static NSString *const kOLAnalyticsEventNameBasketScreenPromoCodeFailed = @"Basket Screen Promo Code Failed";
static NSString *const kOLAnalyticsEventNameBasketScreenDidTaponPromoCodeBox = @"Basket Screen Did Tap on Promo Code Box";
static NSString *const kOLAnalyticsEventNameBasketScreenPaymentMethodHitBack = @"Basket Screen Payment Method Hit Back";
static NSString *const kOLAnalyticsEventNameReviewScreenIncrementedPhotoQuantity= @"Review Screen Incremented Photo Quantity";
static NSString *const kOLAnalyticsEventNameBasketScreenHitEditItem = @"Basket Screen Hit Edit Item";
static NSString *const kOLAnalyticsEventNameShippingScreenHitBack = @"Shipping Screen Hit Back";
static NSString *const kOLAnalyticsEventNameReviewScreenDeletedPhoto = @"Review Screen Deleted Photo";
static NSString *const kOLAnalyticsEventNameProductDescriptionScreenHitBack = @"Product Description Screen Hit Back";
static NSString *const kOLAnalyticsEventNameImagePickerScreenHitBack = @"Image Picker Screen Hit Back";
static NSString *const kOLAnalyticsEventNamePhotobookEditScreenHitBack = @"Photobook Edit Screen Hit Back";
static NSString *const kOLAnalyticsEventNameUpsellScreenViewed = @"Upsell Screen Viewed";
static NSString *const kOLAnalyticsEventNameUpsellScreenDismissed = @"Upsell Screen Dismissed";
static NSString *const kOLAnalyticsEventNameBasketIconTapped = @"Basket Icon Tapped";
static NSString *const kOLAnalyticsEventNamePaymentMethodScreenHitBack = @"Payment Method Screen Hit Back";
static NSString *const kOLAnalyticsEventNameShippingMethodScreenHitBack = @"Shipping Method Screen Hit Back";
static NSString *const kOLAnalyticsEventNameEditScreenDidCancel = @"Edit Screen Did Cancel";
static NSString *const kOLAnalyticsEventNameEditScreenButtonTapped = @"Edit Screen Button Tapped";

// Property Names
static NSString *const kOLAnalyticsEventName = @"Event Name";
static NSString *const kOLAnalyticsProductCategory = @"Product Category";
static NSString *const kOLAnalyticsProductName = @"Product Name";
static NSString *const kOLAnalyticsProductId = @"Product ID";
static NSString *const kOLAnalyticsApplePayAvailable = @"Apple Pay Available";
static NSString *const kOLAnalyticsPaymentMethod = @"Payment Method";
static NSString *const kOLAnalyticsPhotoSource = @"Photo Source";
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
static NSString *const kOLAnalyticsOrderId = @"Order ID";
static NSString *const kOLAnalyticsItemPrice = @"Item Price";
static NSString *const kOLAnalyticsPromoCode = @"Promo Code";
static NSString *const kOLAnalyticsError = @"Error";
static NSString *const kOLAnalyticsEventLevel = @"Event Level";
static NSString *const kOLAnalyticsButtonName = @"Button Name";

@interface OLAnalytics : NSObject

+ (void)addPushDeviceToken:(NSData *)deviceToken;
+ (void)setOptInToRemoteAnalytics:(BOOL)optIn;
+ (void)trackKiteViewControllerLoadedWithEntryPoint:(NSString *)entryPoint;
+ (void)trackKiteDismissed;
+ (void)trackCategoryListScreenViewed;
+ (void)trackProductDetailsScreenViewed:(OLProductTemplate *)productTemplate hidePrice:(BOOL)hidePrice;
+ (void)trackProductDetailsViewOpened:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductDetailsViewClosed:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductDescriptionScreenHitBack:(NSString *)productName hidePrice:(BOOL)hidePrice;
+ (void)trackProductListScreenViewedWithTemplateClass:(NSString *)templateClassString;
+ (void)trackProductListScreenHitBackTemplateClass:(NSString *)templateClassString;
+ (void)trackImagePickerScreenViewed:(NSString *)productName;
+ (void)trackImagePickerScreenHitBack:(NSString *)productName;
+ (void)trackPhotoProviderPicked:(NSString *)provider forProductName:(NSString *)productName;
+ (void)trackReviewScreenViewed:(NSString *)productName;
+ (void)trackPhotobookEditScreenViewed:(NSString *)productName;
+ (void)trackReviewScreenHitBack:(NSString *)productName numberOfPhotos:(NSInteger)numberOfPhotos;
+ (void)trackPhotobookEditScreenHitBack:(NSString *)productName;
+ (void)trackReviewScreenDeletedPhotoForProductName:(NSString *)productName;
+ (void)trackEditScreenFinishedEditingPhotoForProductName:(NSString *)productName;
+ (void)trackReviewScreenIncrementedPhotoQtyForProductName:(NSString *)productName;
+ (void)trackReviewScreenDecrementedPhotoQtyForProductName:(NSString *)productName;
+ (void)trackItemAddedToBasket:(id<OLPrintJob>)item;
+ (void)trackEditPhotoTappedForProductName:(NSString *)productName;
+ (void)trackOrderHistoryScreenViewed;
+ (void)trackOrderHistoryScreenDismissed;
+ (void)trackQualityScreenHitBack;
+ (void)trackContinueShoppingButtonPressed:(OLPrintOrder *)printOrder;
+ (void)trackShippingScreenHitBackForOrder:(OLPrintOrder *)printOrder;
+ (void)trackDeliveryDetailsScreenViewedForOrder:(OLPrintOrder *)printOrder variant:(NSString *)variant showPhoneEntryField:(BOOL)showPhoneEntryField;
+ (void)trackAddressSelectionScreenViewed;
+ (void)trackAddEditAddressScreenViewed;
+ (void)trackSearchAddressScreenViewed;
+ (void)trackBasketScreenViewedForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketItemQtyUpForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketItemQtyDownForItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenHitEditItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenHitBackForOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenSuccessfullyAppliedPromoCode:(NSString *)code forOrder:(OLPrintOrder *)order;
+ (void)trackBasketScreenUnsuccessfullyAppliedPromoCode:(NSString *)code withError:(NSError *)error forOrder:(OLPrintOrder *)order;
+ (void)trackBasketScreenDidTapOnPromoCodeBoxforOrder:(OLPrintOrder *)order;
+ (void)trackBasketScreenPaymentMethodDidCancel:(NSString *)method forOrder:(OLPrintOrder *)order applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenHitEditItemDone:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketScreenDidDeleteItem:(id<OLPrintJob>)item inOrder:(OLPrintOrder *)printOrder applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackPaymentCompletedForOrder:(OLPrintOrder *)printOrder paymentMethod:(NSString *)method applePayIsAvailable:(NSString *)applePayIsAvailable;
+ (void)trackBasketIconTappedWithNumberBadged:(NSInteger)number;
+ (void)trackOrderSubmission:(OLPrintOrder *)printOrder;
+ (void)trackQualityInfoScreenViewed;
+ (void)trackPrintAtHomeTapped;
+ (void)trackPaymentMethodScreenViewed:(OLPrintOrder *)printOrder;
+ (void)trackPaymentMethodSelected:(OLPrintOrder *)printOrder methodName:(NSString *)methodName;
+ (void)trackPaymentMethodScreenHitBack:(OLPrintOrder *)printOrder;
+ (void)trackShippingMethodScreenViewed:(OLPrintOrder *)printOrder;
+ (void)trackShippingMethodSelected:(OLPrintOrder *)printOrder methodName:(NSString *)methodName;
+ (void)trackShippingMethodScreenHitBack:(OLPrintOrder *)printOrder;
+ (void)trackEditScreenDidCancel;
+ (void)trackEditScreenButtonTapped:(NSString *)buttonName;

// upsell events
+ (void)trackUpsellShown:(BOOL)shown;
+ (void)trackUpsellDismissed:(BOOL)optedIn;

+ (void)incrementLaunchSDKCount;
+ (void)setExtraInfo:(NSDictionary *)info;
+ (NSString *)userDistinctId;

+ (NSDictionary *)extraInfo;
@end
