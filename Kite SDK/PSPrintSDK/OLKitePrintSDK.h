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
#import "OLProductPrintJob.h"

@class OLPrintRequest;

typedef void (^OLPrintProgressCompletionHandler)(float progress);
typedef void (^OLPrintCompletionHandler)(NSString  *_Nullable receiptId, NSError  *_Nullable error);
typedef void (^OLProductCostRefreshCompletionHandler)(NSError *_Nullable error);

@interface OLKitePrintSDK : NSObject

+ (void)setAPIKey:(NSString * _Nonnull)apiKey withEnvironment:(OLKitePrintSDKEnvironment)environment;
+ (NSString *_Nullable)apiKey;
+ (OLKitePrintSDKEnvironment)environment;

// optionally enable Instagram photo picking functionality (you'll need to take 5 minutes to register your app https://instagram.com/developer/):
#ifdef OL_KITE_OFFER_INSTAGRAM
+ (void)setInstagramEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret redirectURI:(NSString *_Nonnull)redirectURI;
#endif

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *_Nonnull)paypalEnvironment;
+ (NSString *_Nonnull)paypalClientId;
+ (NSString *_Nonnull)paypalReceiverEmail;
#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
+ (NSString *_Nonnull)stripePublishableKey;
+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID;
+ (NSString *_Nonnull)appleMerchantID;
#endif

@end
