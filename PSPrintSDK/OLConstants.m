//
//  OLConsttants.m
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLConstants.h"

NSString *const kOLKiteSDKVersion = @"1.0.0";
NSString *const kOLKiteSDKErrorDomain = @"co.oceanlabs.kOLKiteSDKErrorDomain";
const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed = 99;
const NSInteger kOLKiteSDKErrorCodeServerFault = 100;
const NSInteger kOLKiteSDKErrorCodeUnauthorized = 401;
const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency = 101;

NSString *const kOLKiteSDKErrorMessageUnauthorized = @"Unauthorized Kite Print SDK Request. Did you set your API Key and Environment correctly using [OLKitePrintSDK setAPIKey:withEnvironment:]";

@implementation OLConstants

+ (NSBundle *)bundle {
    NSBundle* bundle;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"UserVoice" withExtension:@"bundle"];
    if (url) {
        bundle = [NSBundle bundleWithURL:url];
    }
    
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    return bundle;
}

@end