//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
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

NSString *const kOLKiteSDKVersion = @"5.0.5";
NSString *const kOLKiteSDKErrorDomain = @"co.oceanlabs.kOLKiteSDKErrorDomain";
NSString *const kNotificationTemplateSyncComplete = @"co.oceanlabs.pssdk.notification.kNotificationSyncComplete";
NSString *const kNotificationKeyTemplateSyncError = @"co.oceanlabs.pssdk.notification.kNotificationKeyTemplateSyncError";
const NSInteger kOLKiteSDKErrorCodeRequestInProgress = 98;
const NSInteger kOLKiteSDKErrorCodeFullDetailsFetchFailed = 99;
const NSInteger kOLKiteSDKErrorCodeServerFault = 100;
const NSInteger kOLKiteSDKErrorCodeProductNotAvailableInRegion = 50;
const NSInteger kOLKiteSDKErrorCodeUnauthorized = 401;
const NSInteger kOLKiteSDKErrorCodeRegisteredAssetCountDiscrepency = 101;
const NSInteger kOLKiteSDKErrorCodeMaintenanceMode = 503;
const NSInteger kOLKiteSDKErrorCodeUnexpectedResponse = 520;
const NSInteger kOLKiteSDKErrorCodeOrderValidationFailed = 701;
const NSInteger kOLKiteSDKErrorCodeImagesCorrupt = 702;
const NSInteger kOLKiteSDKErrorCodeURLShorteningFailed = 801;

NSString *const kOLKiteSDKErrorMessageUnauthorized = @"Unauthorized Kite Print SDK Request. Did you set your API Key and Environment correctly using [OLKitePrintSDK setAPIKey:withEnvironment:]";

NSString *const kOLKiteSDKErrorMessageMaintenanceMode = @"Our store is currently undergoing maintence so no products are available for purchase at this time. Please try again a little later.";

NSString *const kOLKiteSDKErrorMessageRequestInProgress = @"A request to get costs is already in progress.";

@implementation OLConstants

+ (NSBundle *_Nonnull)bundle {
    NSBundle* bundle;
    
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    return bundle;
}

@end