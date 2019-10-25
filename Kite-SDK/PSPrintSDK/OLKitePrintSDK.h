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

#import "OLConstants.h"

/**
 *  Use the methods in this class to set up the Kite SDK
 */
@interface OLKitePrintSDK : NSObject

/**
 *  Initialize the Kite SDK with a Kite API key, which you can find at https://kite.ly
 *
 *  @param apiKey      The API key
 *  @param environment Specify Sandbox or Live payment environment
 */
+ (void)setAPIKey:(NSString * _Nonnull)apiKey withEnvironment:(OLKitePrintSDKEnvironment)environment;

/**
 *  The API key previously set
 *
 *  @see +setAPIKey:withEnvironment:
 *
 *  @return The API key
 */
+ (NSString *_Nullable)apiKey;


/**
 Sets up a URL scheme to be used for callbacks at checkout

 @note Set a unique scheme for every single application in which the Kite SDK is used
 @param scheme The scheme
 */
+ (void)setURLScheme:(NSString *_Nonnull)scheme;

/**
 *  The payment environment previously set
 *
 *  @see +setAPIKey:withEnvironment:
 *
 *  @return The payment environment
 */
+ (OLKitePrintSDKEnvironment)environment;

/**
 *  Add a device token for push notifications.
 *
 *  @param deviceToken The device token.
 */
+ (void)addPushDeviceToken:(NSData *_Nonnull)deviceToken;

/**
 Call this method from your app delegate to handle the return from Safari as part of the credit card authorization process

 @param url The return URL passed to the application
 @return Yes if the URL should be handled by the SDK, no otherwise
 */
+ (BOOL)handleUrlCallBack:(NSURL * _Nonnull)url;

/**
 *  Initializer that accepts a ready to checkout array of OLPrintJobs.
 *  This will clear any existing basket items.
 *
 *  @param printJobs The printJobs to checkout
 *
 *  @return A checkout ViewController to present
 */
+ (UIViewController * _Nullable)checkoutViewControllerWithPrintJobs:(NSArray <id<OLPrintJob>>*_Nullable)printJobs;

/**
 *  Initializer that accepts ready to checkout array of OLPrintJobs. Provides an extra argument for extra info.
 *  Notes:
 *  - This will clear any existing basket items.
 *  - If there is a processing order in progress, the print jobs will be discarded in favor of the already processing order and the upload screen will be returned instead of the checkout screen, so you should be prepared for that. See isProcessingOrder.
 *
 *  @param printJobs  The printJobs to checkout
 *  @param info       Extra information that could be useful for analytics
 *
 *  @return A checkout ViewController to present
 */
+ (UIViewController * _Nullable)checkoutViewControllerWithPrintJobs:(NSArray <id<OLPrintJob>>*_Nullable)printJobs info:(NSDictionary * _Nullable)info;


/**
 Returns true if an order is in progress of submission. This is useful to know because in case this is true, if you try to checkout a print job, that print job will be discarded in favor of the already processing order and the upload screen will be returned instead of the checkout screen, so you should be prepared for that. If you present the normal flow Print Shop, the upload screen will be presented on top of that and everything will be handled internally. It might also be useful if you want to let the user know beforehand.

 @return A bool value that indicates if an order is in progress of submission
 */
+ (BOOL)isProcessingOrder;

/**
 Speed up checkout by prepopulating a promo code

 @param promoCode A promo code. You can register codes in the Kite Dashboard
 */
+ (void)setPromoCode:(NSString * _Nullable)promoCode;


/**
 Speed up checkout by prepopulating the user's delivery details

 @param deliveryDetails The user's delivery details
 */
+ (void)setDeliveryDetails:(OLDeliveryDetails * _Nonnull)deliveryDetails;

/**
 Allow the SDK to track events in the SDK for analytics purposes. Default value is false

 @param optIn Allow remote analytics tracking
 */
+ (void)setOptInToRemoteAnalytics:(BOOL)optIn;

/**
 *  Optionally enable Apple Pay in your app. Use this method to set your Apple Pay Merchant ID. However there is an extra step involved to get your certificate to Kite's Stripe account for payment validations. Please get in touch with Kite for this: hello@kite.ly
 *  (Needs the 'ApplePay' subspec or this method won't do anything. See
 *  https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/applepay.md for details)
 *
 *  @param mID Your merchant ID
 */
+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID;

/**
 *  Apple Pay requires a name that appears next to the Total and should be the name of the business that they are paying. This should be recognizable to the user and will appear on their credit card statement. If this is not set it will appear as "Kite.ly (via YOUR_APP_NAME)
 *   (Needs the 'ApplePay' subspec or this method won't do anything. See
 *  https://github.com/OceanLabs/iOS-Print-SDK/blob/master/Kite-SDK/docs/applepay.md for details)
 *
 *  @warning This can cause App Store Review rejections if the value set is not proper
 *  @param name The name of the business that you w
 */
+ (void)setApplePayPayToString:(NSString *_Nonnull)name;

/**
 *  Clear all customer data.
 */
+ (void)endCustomerSession;

/**
 *  Indicate that the app will be used in a kiosk environment
 *
 *  @param enabled Indicate kiosk environment. Default value is NO.
 */
+ (void)setIsKiosk:(BOOL)enabled;

/**
 *  Indicates if the app will be used in a kiosk environment or not
 *
 *  @return Indicate kiosk environment
 */
+ (BOOL)isKiosk;

/**
 *  Allow or disallow the image editing functionality to zoom images (pinch and double tap gestures)
 *  Default value is yes.
 *
 *  @param allowZoom Boolean value to allow or disallow zoom.
 */
+ (void)setAllowsImageZooming:(BOOL)allowZoom;

@end
