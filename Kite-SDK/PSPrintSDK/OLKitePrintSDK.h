//
//  PrintStudio.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
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
