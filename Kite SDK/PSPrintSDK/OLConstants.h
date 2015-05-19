//
//  OLConsttants.h
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kOLKiteSDKErrorDomain;
extern NSString *const kOLKiteSDKVersion;
extern const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed;
extern const NSInteger kOLKiteSDKErrorCodeServerFault;
extern const NSInteger kOLKiteSDKErrorCodeUnauthorized;
extern const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency;
extern const NSInteger kOLKiteSDKErrorCodeMaintenanceMode;

extern NSString *const kOLKiteSDKErrorMessageUnauthorized;
extern NSString *const kOLKiteSDKErrorMessageMaintenanceMode;

@interface OLConstants : NSObject

+ (NSBundle *)bundle;

@end