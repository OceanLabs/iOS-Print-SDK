//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "OLKitePrintSDK.h"
#import "OLProductTemplate.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"

@import Photobook;

static NSString *apiKey = nil;
static OLKitePrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLStagingEndpointLive = @"https://staging.kite.ly";
static NSString *const kOLStagingEndpointSandbox = @"https://staging.kite.ly";
static NSString *const kOLAPIEndpointVersion = @"v4.1";

static BOOL useStaging = NO;
static BOOL isUnitTesting = NO;
static BOOL isKiosk = NO;
static BOOL allowImageZooming = YES;

static NSString *instagramClientID = nil;
static NSString *instagramSecret = nil;
static NSString *instagramRedirectURI = nil;

@implementation OLKitePrintSDK

+ (void)setUseStaging:(BOOL)staging {
    useStaging = staging;
    [[PhotobookSDK shared] setShouldUseStaging:useStaging];
}

+ (void)setURLScheme:(NSString *_Nonnull)scheme {
    [[PhotobookSDK shared] setKiteUrlScheme:scheme];
}

+ (void)setIsUnitTesting {
    isUnitTesting = YES;
}

+ (BOOL)isUnitTesting {
    return isUnitTesting;
}

+ (void)setAPIKey:(NSString *_Nonnull)_apiKey withEnvironment:(OLKitePrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    [[PhotobookSDK shared] setKiteApiKey:_apiKey];
    if (environment == OLKitePrintSDKEnvironmentLive) {
        [[PhotobookSDK shared] setEnvironment:EnvironmentLive];
    } else {
        [[PhotobookSDK shared] setEnvironment:EnvironmentTest];
    }
}

+ (NSString *_Nullable)apiKey {
    return apiKey;
}

+ (OLKitePrintSDKEnvironment)environment {
    return environment;
}

+ (NSString *)apiEndpoint {
    if (useStaging) {
        switch (environment) {
            case OLKitePrintSDKEnvironmentLive: return kOLStagingEndpointLive;
            case OLKitePrintSDKEnvironmentSandbox: return kOLStagingEndpointSandbox;
        }
    }
    else{
        switch (environment) {
            case OLKitePrintSDKEnvironmentLive: return kOLAPIEndpointLive;
            case OLKitePrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
        }
    }
}

+ (NSString *)apiVersion {
    return kOLAPIEndpointVersion;
}

+ (void)addPushDeviceToken:(NSData *)deviceToken {
    [OLAnalytics addPushDeviceToken:deviceToken];
}

+ (void)setOptInToRemoteAnalytics:(BOOL)optIn {
    [OLAnalytics setOptInToRemoteAnalytics:optIn];
}

+ (void)setApplePayMerchantID:(NSString * _Nonnull)mID {
    [[PhotobookSDK shared] setApplePayMerchantId:mID];
}

+ (void)setApplePayPayToString:(NSString * _Nonnull)name {
    [[PhotobookSDK shared] setApplePayPayTo:name];
}

+ (BOOL)handleUrlCallBack:(NSURL * _Nonnull)url {
    return [[PhotobookSDK shared] handleUrlCallBackWith:url];
}

+ (NSString *)qualityGuaranteeString {
    return NSLocalizedStringFromTableInBundle(@"**Quality Guarantee**\nOur products are of the highest quality and we’re confident you will love yours. If not, we offer a no quibble money back guarantee. Enjoy!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
}

+ (void)setIsKiosk:(BOOL)enabled {
    isKiosk = enabled;
}

+ (BOOL)isKiosk {
    return isKiosk;
}

+ (void)setPromoCode:(NSString *)promoCode {
    [[PhotobookSDK shared] setPromoCode: promoCode];
}

+ (void)setDeliveryDetails:(OLDeliveryDetails *)deliveryDetails {
    [[PhotobookSDK shared] setDeliveryDetails: deliveryDetails];
}

+ (UIViewController *)checkoutViewControllerWithPrintJobs:(NSArray <id<OLPrintJob>>*_Nullable)printJobs {
    return [self checkoutViewControllerWithPrintJobs:printJobs info:nil];
}

+ (UIViewController *)checkoutViewControllerWithPrintJobs:(NSArray <id<OLPrintJob>>*_Nullable)printJobs info:(NSDictionary * _Nullable)info {
    if ([[PhotobookSDK shared] isProcessingOrder]) {
        return [[PhotobookSDK shared] receiptViewControllerWithEmbedInNavigation:YES dismissClosure:^(UIViewController *viewController, BOOL success) {
            [viewController dismissViewControllerAnimated:YES completion:NULL];
        }];
    }
    
    [OLAnalytics setExtraInfo:info];
    [OLAnalytics trackKiteViewControllerLoadedWithEntryPoint:@"Checkout"];
    [[PhotobookSDK shared] clearBasketOrder];
    for (id<OLPrintJob> printJob in printJobs) {
        [[PhotobookSDK shared] addProductToBasket:(id<Product>)printJob];
    }
    
    return (UINavigationController *)[[PhotobookSDK shared] checkoutViewControllerWithEmbedInNavigation:YES dismissClosure:^(UIViewController *viewController, BOOL success) {
        if (![OLUserSession currentSession].kiteVc){
            [viewController dismissViewControllerAnimated:YES completion:NULL];
        }
        else if ([viewController isKindOfClass:[NSClassFromString(@"Photobook.PhotobookViewController") class]]) {
            [viewController.navigationController popViewControllerAnimated:YES];
        } else {
            [viewController.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

+ (BOOL)isProcessingOrder {
    return [[PhotobookSDK shared] isProcessingOrder];
}

+ (void)setQRCodeUploadEnabled:(BOOL)enabled {
}

+ (void)endCustomerSession {
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionAll];
}

+ (void)setAllowsImageZooming:(BOOL)allowZoom {
    allowImageZooming = allowZoom;
}

+ (BOOL)allowsImageZooming {
    return allowImageZooming;
}

@end
