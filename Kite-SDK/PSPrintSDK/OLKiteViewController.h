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

#import <UIKit/UIKit.h>
#import "OLViewController.h"

@class OLPrintOrder;
@class OLKiteViewController;
@class ALAssetsGroup;
@class OLAsset;

@protocol KITAssetCollectionDataSource;
@protocol KITCustomAssetPickerController;

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
 *  Disallow access to camera roll photos. The default value is NO.
 *
 *  @param controller The active OLKiteViewController
 *
 *  @return A boolean value of whether or not we should allow the user to add more photos from the camera roll.
 */
- (BOOL)kiteControllerShouldDisableCameraRoll:(OLKiteViewController * _Nullable)controller;

/**
 *  Asks the delegate if we should ask the user for their phone number at checkout. If this is not specified, the behavior is random.
 *
 *  @return A boolean value of whether or not we should ask the user for their phone number at checkout.
 */
- (BOOL)shouldShowPhoneEntryOnCheckoutScreen;

/**
 *  Asks the delegate if we should show a Continue Shopping button on the payment screen. The default value is YES.
 *
 *  @return Boolean value for showing the Continue Shooping button or not.
 */
- (BOOL)shouldShowContinueShoppingButton;

/**
 *  Asks the delegate whether or not to store the user's delivery address for future use. The default value is YES
 *
 *  @return Boolean value for whether or not to store the user's delivery address.
 */
- (BOOL)shouldStoreDeliveryAddresses;

/**
 *  Asks the delegate whether or not to show a checkbox that allows the user to opt out of emails
 *
 *  @return Boolean value for showing the checkbox
 */
- (BOOL)shouldShowOptOutOfEmailsCheckbox;


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
@interface OLKiteViewController : OLViewController

/**
 *  The delegate object that will be asked for information in certain scenarios.
 */
@property (weak, nonatomic) id<OLKiteDelegate> _Nullable delegate;

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
@property (copy, nonatomic, nullable) NSArray<NSString *> *filterProducts;

/**
 *  Use a dark visual theme.
 */
//@property (assign, nonatomic) BOOL useDarkTheme;

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

/**
 *  Add a custom source for the photo picker
 *  (Needs the 'ImageProviders' subspec or this method won't do anything. See
 *  https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/custom_photo_sources.md for details)
 *
 *  @param collections An array of photo collections(albums)
 *  @param name        The name for the source
 *  @param image       An image to be used as an icon (where applicable)
 */
- (void)addCustomPhotoProviderWithCollections:(NSArray <id<KITAssetCollectionDataSource>>*_Nonnull)collections name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)image;

/**
 *  Add your own photo picker.
 *  (Needs the 'ImageProviders' subspec or this method won't do anything. See
 *  https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/custom_photo_sources.md for details)
 *
 *  @param vcs   Your view controller
 *  @param name The name for the source
 *  @param icon An image to be used as an icon (where applicable)
 */
- (void)addCustomPhotoProviderWithViewController:(UIViewController<KITCustomAssetPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon;

@end
