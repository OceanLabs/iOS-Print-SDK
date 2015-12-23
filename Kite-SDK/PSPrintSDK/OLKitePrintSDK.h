//
//  Modified MIT License
//
//  Copyright (c) 2010-2015 Kite Tech Ltd. https://www.kite.ly
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

#ifdef OL_KITE_OFFER_INSTAGRAM
/**
 *  Optionally enable Instagram photo picking functionality (you'll need to take 5 minutes to register your app https://instagram.com/developer/)
 *  After you have registered, call this method to set everything up.
 *
 *  @param clientID    Your Instagram app's clientID
 *  @param secret      Your Instagram app's secret
 *  @param redirectURI Your Instagram app's redirectURI
 */
+ (void)setInstagramEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret redirectURI:(NSString *_Nonnull)redirectURI;
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
/**
 *  Optionally enable Apple Pay in your app. Use this method to set your Apple Pay Merchant ID. However there is an extra step involved to get your certificate to Kite's Stripe account for payment validations. Please get in touch with Kite for this: hello@kite.ly
 *
 *  @param mID Your merchant ID
 */
+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID;

/**
 *  Apple Pay requires a name that appears next to the Total and should be the name of the business that they are paying. This should be recognizable to the user and will appear on their credit card statement. If this is not set it will appear as "Kite.ly (via YOUR_APP_NAME)
 *
 *  @warning This can cause App Store Review rejections if the value set is not proper
 *  @param name The name of the business that you w
 */
+ (void)setApplePayPayToString:(NSString *_Nonnull)name;
#endif

@end
