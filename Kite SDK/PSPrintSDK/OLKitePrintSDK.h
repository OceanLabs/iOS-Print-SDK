//
//  PrintStudio.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OLCheckoutViewController.h"
#import "OLPrintEnvironment.h"
#import "OLAddressPickerController.h"
#import "OLAddress.h"
#import "OLAddress+AddressBook.h"
#import "OLCountry.h"
#import "OLCountryPickerController.h"
#import "OLPayPalCard.h"
#import "OLAsset.h"
#import "OLPrintJob.h"
#import "OLPrintOrder.h"
#import "OLPrintOrder+History.h"
#import "OLProductTemplate.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "OLKiteViewController.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"

@class OLPrintRequest;

typedef void (^OLPrintProgressCompletionHandler)(float progress);
typedef void (^OLPrintCompletionHandler)(NSString *receiptId, NSError *error);
typedef void (^OLProductCostRefreshCompletionHandler)(NSError *error);

@interface OLKitePrintSDK : NSObject

+ (void)setAPIKey:(NSString *)apiKey withEnvironment:(OLKitePrintSDKEnvironment)environment;
+ (NSString *)apiKey;
+ (OLKitePrintSDKEnvironment)environment;
+ (NSString *)apiEndpoint;
+ (NSString *)apiVersion;

// optionally enable Instagram photo picking functionality (you'll need to take 5 minutes to register your app https://instagram.com/developer/):
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (void)setInstagramEnabledWithClientID:(NSString *)clientID secret:(NSString *)secret redirectURI:(NSString *)redirectURI;
#endif

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *)paypalEnvironment;
+ (NSString *)paypalClientId;
+ (NSString *)paypalReceiverEmail;
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
+ (void)setStripeKey:(NSString *)stripeKey;
+ (NSString *)stripePublishableKey;
+ (void)setApplePayMerchantID:(NSString *)mID;
+ (NSString *)appleMerchantID;
#endif

@end
