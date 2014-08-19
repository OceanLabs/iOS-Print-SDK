//
//  OLConsttants.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const kOLKiteSDKErrorDomain;
NSString *const kOLKiteSDKVersion;
const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed;
const NSInteger kOLKiteSDKErrorCodeServerFault;
const NSInteger kOLKiteSDKErrorCodeUnauthorized;
const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency;

NSString *const kOLKiteSDKErrorMessageUnauthorized;

@interface OLConstants : NSObject

+ (NSBundle *)bundle;

@end