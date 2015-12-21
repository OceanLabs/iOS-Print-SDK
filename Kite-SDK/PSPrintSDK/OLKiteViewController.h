//
//  KiteViewController.h
//  Kite Print SDK
//
//  Created by Konstadinos Karayannis on 12/24/14.
//  Copyright (c) 2014 Deon Botha. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLPrintOrder;
@class OLKiteViewController;
@class ALAssetsGroup;
@class OLAsset;

/**
 *  The delegate object if available will be asked for information
 */
@protocol OLKiteDelegate <NSObject>

@optional
/**
 *  Asks the delegate if a group should be set as the default.
 *   Deprecated: If your deployment target is at least 8.0, you should install the 'iOS8' subspec that installs a new PHAsset-based photo picker.
 *
 *  @param controller The active OLKiteViewController
 *  @param group      The group to evaluate
 *
 *  @return A boolean value that shows if this group is default of not.
 */
- (BOOL)kiteController:(OLKiteViewController * _Nullable)controller isDefaultAssetsGroup:(ALAssetsGroup * _Nonnull)group NS_DEPRECATED_IOS(7_0, 8_0);

/**
 *  Asks the delegate if the user should be allowed to add more photos to their products (other than the ones provided by the host app). Default value is YES.
 *
 *  @param controller The active OLKiteViewController
 *
 *  @return A boolean value of whether or not we should allow the user to add more photos
 */
- (BOOL)kiteControllerShouldAllowUserToAddMorePhotos:(OLKiteViewController * _Nullable)controller;

/**
 *  Asks the delegate if we should ask the user for their phone number at checkout. If this is not specified, the behavior is random.
 *
 *  @return A boolean value of whether or not we should ask the user for their phone number at checkout.
 */
- (BOOL)shouldShowPhoneEntryOnCheckoutScreen;

/**
 *  Asks the delegate if we should show a Continue Shopping button on the payment screen.
 *
 *  @return Boolean value for showing the Continue Shooping button or not.
 */
- (BOOL)shouldShowContinueShoppingButton;


/**
 *  Notifies the delegate that KiteViewController has finished and should be dismissed as the delegate sees fit. If this method is not implemented, then KiteViewController dismisses itself.
 *
 *  @param controller The KiteViewController
 */
- (void)kiteControllerDidFinish:(OLKiteViewController * _Nonnull)controller;

/**
 *  Notifies the delegate of an analytics event.
 *
 *  @param info The dictionary containing the information about the event
 */
- (void)logKiteAnalyticsEventWithInfo:(NSDictionary *_Nonnull)info;


@end

/**
 *  This is the main interface ViewController of the Kite SDK. Create and present an instance of this class and the SDK will take care of the rest.
 */
@interface OLKiteViewController : UIViewController

/**
 *  The delegate object that will be asked for information in certain scenarios.
 */
@property (weak, nonatomic) id<OLKiteDelegate> delegate;

/**
 *  Speed up checkout by prepopulating the users email in the Shipping details if you know it
 */
@property (copy, nonatomic, nullable) NSString *userEmail;

/**
 *  Speed up checkout by prepopulating the users phone number in the Shipping details if you know it
 */
@property (copy, nonatomic, nullable) NSString *userPhone;

/**
 *  A set of product template_id strings which if present will restrict which products ultimate show up in the product selection journey
 */
@property (copy, nonatomic, nullable) NSArray/*<NSString>*/ *filterProducts;

/**
 *  Initializer that accepts an array of OLAssets for the user to personalize their products with
 *
 *  @param assets The array of OLAssets for the user to personalize their products with
 *
 *  @return An instance of OLKiteViewController to present
 */
- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets;

/**
 *  Initializer that accepts a ready to checkout OLPrintOrder
 *
 *  @param printOrder The printOrder to checkout
 *
 *  @return An instance of OLKiteViewController to present
 */
- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder;

/**
 *  Initializer that accepts an array of OLAssets for the user to personalize their products with. Provides an extra argument for extra info.
 *
 *  @param assets The array of OLAssets for the user to personalize their products with
 *  @param info   Extra information that could be useful for analytics
 *
 *  @return An instance of OLKiteViewController to present
 */
- (instancetype _Nullable)initWithAssets:(NSArray <OLAsset *>*_Nonnull)assets info:(NSDictionary *_Nullable)info;

/**
 *  Initializer that accepts a ready to checkout OLPrintOrder. Provides an extra argument for extra info.
 *
 *  @param printOrder The printOrder to checkout
 *  @param info       Extra information that could be useful for analytics
 *
 *  @return An instance of OLKiteViewController to present
 */
- (instancetype _Nullable)initWithPrintOrder:(OLPrintOrder *_Nullable)printOrder info:(NSDictionary * _Nullable)info;

/**
 *  Clear all the orders that have been saved in the shopping basket.
 */
- (void)clearBasket;

@end
