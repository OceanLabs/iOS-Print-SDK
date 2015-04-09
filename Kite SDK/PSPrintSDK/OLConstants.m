//
//  OLConsttants.m
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLConstants.h"

NSString *const kOLKiteSDKVersion = @"2.0.19";
NSString *const kOLKiteSDKErrorDomain = @"co.oceanlabs.kOLKiteSDKErrorDomain";
NSString *const kNotificationTemplateSyncComplete = @"co.oceanlabs.pssdk.notification.kNotificationSyncComplete";
NSString *const kNotificationKeyTemplateSyncError = @"co.oceanlabs.pssdk.notification.kNotificationKeyTemplateSyncError";
const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed = 99;
const NSInteger kOLKiteSDKErrorCodeServerFault = 100;
const NSInteger kOLKiteSDKErrorCodeUnauthorized = 401;
const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency = 101;

NSString *const kOLKiteSDKErrorMessageUnauthorized = @"Unauthorized Kite Print SDK Request. Did you set your API Key and Environment correctly using [OLKitePrintSDK setAPIKey:withEnvironment:]";

@implementation OLConstants

+ (NSBundle *)bundle {
    NSBundle* bundle;
    
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    return bundle;
}

@end