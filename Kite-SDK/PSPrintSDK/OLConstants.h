//
//  OLConsttants.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

#import "OLCheckoutViewController.h"
#import "OLPrintEnvironment.h"
#import "OLAddressPickerController.h"
#import "OLAddress.h"
#import "OLAddress+AddressBook.h"
#import "OLCountry.h"
#import "OLCountryPickerController.h"
#import "OLPayPalCard.h"
#import "OLStripeCard.h"
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
#import "OLPhotobookPrintJob.h"
#import "OLPostcardPrintJob.h"
#import "OLPrintOrderCost.h"
#import "OLAssetUploadRequest.h"
#import "OLPrintPhoto.h"
#import "OLAnalytics.h"

#ifdef OL_KITE_AT_LEAST_IOS8
static BOOL definesAtLeastiOS8 = YES;
#else
static BOOL definesAtLeastiOS8 = NO;
#endif

extern NSString *_Nonnull const kOLKiteSDKErrorDomain;
extern NSString *_Nonnull const kOLKiteSDKVersion;
extern const NSInteger kOLKiteSDKErrorCodeRequestInProgress;
extern const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed;
extern const NSInteger kOLKiteSDKErrorCodeServerFault;
extern const NSInteger kOLKiteSDKErrorCodeUnauthorized;
extern const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency;
extern const NSInteger kOLKiteSDKErrorCodeMaintenanceMode;
extern const NSInteger kOLKiteSDKErrorCodeOrderValidationFailed;

extern NSString *_Nonnull const kOLKiteSDKErrorMessageUnauthorized;
extern NSString *_Nonnull const kOLKiteSDKErrorMessageMaintenanceMode;
extern NSString *_Nonnull const kOLKiteSDKErrorMessageRequestInProgress;

@interface OLConstants : NSObject

+ (NSBundle *_Nonnull)bundle;

@end