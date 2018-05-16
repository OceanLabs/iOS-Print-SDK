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

#import <UIKit/UIKit.h>
#import "OLViewController.h"
#import "OLImagePickerProviderCollection.h"

@class OLPrintOrder;
@class OLKiteViewController;
@class OLAsset;
@protocol OLCustomPickerController;

/**
 *  The delegate object if available will be asked for information
 */
@protocol OLKiteDelegate <NSObject>

@optional
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


/**
 Asks the delegate for a UIViewController image picker to show

 @param name The name of the image picker
 @return A UIViewController that conforms to the OLCustomPickerController protocol to be shown immediately.
 */
- (UIViewController<OLCustomPickerController> *_Nonnull)imagePickerViewControllerForName:(NSString *_Nonnull)name;



/**
 For internal use
 */
- (UIView *_Nonnull)viewForHeaderWithWidth:(CGFloat)width;
- (UIViewController *_Nonnull)infoPageViewController;


- (BOOL)kiteControllerShouldAllowUserToAddMorePhotos:(OLKiteViewController * _Nullable)controller __deprecated_msg("This method will no longer work. Use the OLKiteViewController property disallowUserToAddMorePhotos.");
- (BOOL)kiteControllerShouldDisableCameraRoll:(OLKiteViewController * _Nullable)controller __deprecated_msg("This method will no longer work. Use the OLKiteViewController property disableCameraRoll.");
- (BOOL)shouldShowPhoneEntryOnCheckoutScreen __deprecated_msg("This method will no longer work.");
- (BOOL)shouldShowContinueShoppingButton __deprecated_msg("This method will no longer work. Use the OLKiteViewController property hideContinueShoppingButton.");
- (BOOL)shouldStoreDeliveryAddresses __deprecated_msg("This method will no longer work. Use the OLKiteViewController property discardDeliveryAddresses.");
- (BOOL)shouldShowOptOutOfEmailsCheckbox __deprecated_msg("This method will no longer work. Use the OLKiteViewController property showOptOutOfEmailsCheckbox.");

@end

/**
 *  This is the main interface ViewController of the Kite SDK. Create and present an instance of this class and the SDK will take care of the rest.
 */
@interface OLKiteViewController : OLViewController

/**
 *  Set to disallow the user  to add more photos to their products (other than the ones provided by the host app). Defaults to NO.
 */
@property (assign, nonatomic) BOOL disallowUserToAddMorePhotos;

/**
 *  Set to disallow access to camera roll photos. The default value is NO.
 */
@property (assign, nonatomic) BOOL disableCameraRoll;

/**
 *  Set to disable the recent photos tab. The default value is NO.
 */
@property (assign, nonatomic) BOOL disableRecents;

/**
 *  Set to disallow Facebook if available. The default value is NO.
 */
@property (assign, nonatomic) BOOL disableFacebook;

/**
 *  Set to enable uploading from other devices via QR code scan. The default value is NO.
 */
@property (assign, nonatomic) BOOL qrCodeUploadEnabled;

/**
 *  Set to hide the phone entry field at checkout.
 */
@property (assign, nonatomic) BOOL hidePhoneEntryOnCheckoutScreen __deprecated;

/**
 *  Set to hide the Continue Shopping button on the payment screen. The default value is NO.
 */
@property (assign, nonatomic) BOOL hideContinueShoppingButton;

/**
 *  Set to discard delivery addresses after the order is placed. The default value is NO.
 */
@property (assign, nonatomic) BOOL discardDeliveryAddresses;

/**
 *  Set to show a checkbox that allows the user to opt out of emails. The default value is NO.
 */
@property (assign, nonatomic) BOOL showOptOutOfEmailsCheckbox;

/**
 Set to hide the promo code field on the basket screen
 */
@property (assign, nonatomic) BOOL hidePromoCodeField;

/**
 Show the Print at Home tile if the HP SDK is installed
 */
@property (assign, nonatomic) BOOL showPrintAtHome;

/**
 *  The delegate object that will be notified about certain events
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
 Set to disable things like filters and text-on-photo editing tools while preserving basics like crop and rotate.
 */
@property (assign, nonatomic) BOOL disableAdvancedEditingTools;

/**
 *  Set to disable the ability to edit images.
 */
@property (assign, nonatomic) BOOL disableEditingTools;


/**
 *  Set an album name to show when the user first sees the photo library section of the image picker. If not set, the image picker will show the "All Photos" album.
 */
@property (strong, nonatomic) NSString *_Nullable defaultPhotoAlbumName;


/**
 By default when OLKiteViewController launches it deletes any previously downloaded product templates and downloads them again. Set this property to true to prevent this behavior. 
 */
@property (assign, nonatomic) BOOL preserveExistingTemplates;


/**
 Request a view controller that shows the user's complete order history

 @return A UINavigationController that is ready to be presented
 */
+ (UINavigationController *_Nonnull)orderHistoryViewController;

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
 Start loading the products in the background

 @param handler Completion handler that is called when all network requests are finished and the Kite View Controller is ready to be shown.
 */
- (void)startLoadingWithCompletionHandler:(void(^_Nonnull)(void))handler;


/**
 Set the assets to use. Use this if you've previously initialized the Kite View Controller. Otherwise use initWithAssets:

 @param assets The assets
 */
- (void)setAssets:(NSArray *_Nonnull)assets;

/**
 Returns the printOrder object that is used to handle the active basket
 
 Note: A new object may be created when the user has successfully paid for and submitted their basket.

 @return the basket print order object
 */
- (OLPrintOrder *_Nonnull)basketOrder;

/**
 *  Add a custom source for the photo picker
 *  See https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/custom_photo_sources.md for details
 *
 *  @param collections An array of photo collections(albums)
 *  @param name        The name for the source
 *  @param image       An image to be used as an icon (where applicable)
 */
- (void)addCustomPhotoProviderWithCollections:(NSArray <OLImagePickerProviderCollection *>*_Nonnull)collections name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)image;

/**
 *  Add your own photo picker View Controller.
 *  See https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/custom_photo_sources.md for details
 *
 *  @param vc   Your view controller
 *  @param name The name for the source
 *  @param icon An image to be used as an icon (where applicable)
 */
- (void)addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *_Nonnull)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon;


/**
 *  Add your own photo picker View Controller.
 *  See https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/custom_photo_sources.md for details
 *
 *  @param vc Your view controller. This can be nil, in which case you can return it in the imagePickerViewControllerForName: delegate call, which is called when it's needed.
 *  @param name The name for the source
 *  @param icon An image to be used as an icon (where applicable)
 *  @param assets An array of assets that will be prepopulated
 */
- (void)addCustomPhotoProviderWithViewController:(UIViewController<OLCustomPickerController> *_Nullable)vc name:(NSString *_Nonnull)name icon:(UIImage *_Nullable)icon prepopulatedAssets:(NSArray <OLAsset *>*_Nullable)assets;

/**
 Provide a set of font names to be used in image editing (text on photo);

 @param fontNames The font names array
 */
- (void)setFontNamesForImageEditing:(NSArray<NSString *> *_Nullable)fontNames;
@end
