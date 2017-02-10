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
#import "OLPayPalCard.h"
#import "OLProductTemplate.h"
#import "OLStripeCard.h"
#import "OLKiteABTesting.h"
#import "OLKiteUtils.h"
#import "OLUserSession.h"

static NSString *apiKey = nil;
static NSString *applePayMerchantID = nil;
static NSString *applePayPayToString = nil;
static OLKitePrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLStagingEndpointLive = @"https://staging.kite.ly";
static NSString *const kOLStagingEndpointSandbox = @"https://staging.kite.ly";
static NSString *const kOLAPIEndpointVersion = @"v3.0";

static BOOL useStripeForCreditCards = YES;
static BOOL cacheTemplates = NO;
static BOOL useStaging = NO;
static BOOL isUnitTesting = NO;
static BOOL isKiosk = NO;
static BOOL allowImageZooming = YES;

static NSString *paypalAccountId = nil;
static NSString *paypalPublicKey = nil;
static NSString *stripeAccountId = nil;
static NSString *stripePublicKey = nil;

static NSString *instagramClientID = nil;
static NSString *instagramSecret = nil;
static NSString *instagramRedirectURI = nil;

@interface OLPrintOrder ()
- (void)saveOrder;
@end

@implementation OLKitePrintSDK

+ (BOOL)useStripeForCreditCards {
    return useStripeForCreditCards;
}

+ (void)setUseStripeForCreditCards:(BOOL)use {
    useStripeForCreditCards = use;
}

+ (void)setCacheTemplates:(BOOL)cache{
    if (!cache){
        [OLProductTemplate deleteCachedTemplates];
    }
    cacheTemplates = cache;
}

+ (BOOL)cacheTemplates{
    return cacheTemplates;
}

+ (void)setUseStaging:(BOOL)staging{
    useStaging = staging;
}

+ (void)setIsUnitTesting{
    isUnitTesting = YES;
}

+ (BOOL)isUnitTesting{
    return isUnitTesting;
}

+ (void)setAPIKey:(NSString *_Nonnull)_apiKey withEnvironment:(OLKitePrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    [OLStripeCard setClientId:[self stripePublishableKey]];
    if (environment == OLKitePrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentLive];
    } else {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentSandbox];
    }
}

+ (NSString *_Nullable)apiKey {
    return apiKey;
}

+ (OLKitePrintSDKEnvironment)environment {
    return environment;
}

+ (NSString *)apiEndpoint {
    if (useStaging){
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

+ (NSString *)apiVersion{
    return kOLAPIEndpointVersion;
}

+ (void) addPushDeviceToken:(NSData *)deviceToken{
    [OLAnalytics addPushDeviceToken:deviceToken];
}

+ (NSString *_Nonnull)paypalEnvironment {
    switch (environment) {
        case OLKitePrintSDKEnvironmentLive: return @"live";/*PayPalEnvironmentProduction*/;
        case OLKitePrintSDKEnvironmentSandbox: return @"sandbox";/*PayPalEnvironmentSandbox*/;
    }
}

+ (NSString *_Nonnull)paypalClientId {
    return paypalPublicKey;
}

+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID{
    applePayMerchantID = mID;
}

+ (void)setApplePayPayToString:(NSString *_Nonnull)name{
    applePayPayToString = name;
}

+ (NSString *)applePayPayToString{
    if (applePayPayToString){
        return applePayPayToString;
    }
    else{
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleName = nil;
        if ([info objectForKey:@"CFBundleDisplayName"] == nil) {
            bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleNameKey];
        } else {
            bundleName = [NSString stringWithFormat:@"%@", [info objectForKey:@"CFBundleDisplayName"]];
        }
        
        return [NSString stringWithFormat:@"Kite.ly (via %@)", bundleName];
    }
}

+ (NSString *_Nonnull)appleMerchantID {
    return applePayMerchantID;
}

+ (NSString *_Nonnull)stripePublishableKey {
    return stripePublicKey;
}

+ (NSString *)qualityGuaranteeString{
    return NSLocalizedStringFromTableInBundle(@"**Quality Guarantee**\nOur products are of the highest quality and we’re confident you will love yours. If not, we offer a no quibble money back guarantee. Enjoy!", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"");
}

+ (void)setIsKiosk:(BOOL)enabled{
    isKiosk = enabled;
}

+ (BOOL)isKiosk{
    return isKiosk;
}

+ (void)setQRCodeUploadEnabled:(BOOL)enabled{
}

+ (void)endCustomerSession{
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionAll];
}

+ (void)setAllowsImageZooming:(BOOL)allowZoom{
    allowImageZooming = allowZoom;
}

+ (BOOL)allowsImageZooming{
    return allowImageZooming;
}

#pragma mark - Internal


+ (void)setInstagramEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret redirectURI:(NSString *_Nonnull)redirectURI {
    instagramSecret = secret;
    instagramClientID = clientID;
    instagramRedirectURI = redirectURI;
}

+ (NSString *)instagramRedirectURI {
    return instagramRedirectURI;
}

+ (NSString *)instagramSecret{
    return instagramSecret;
}

+ (NSString *)instagramClientID{
    return instagramClientID;
}

+ (void)setPayPalAccountId:(NSString *)accountId{
    paypalAccountId = accountId;
}

+ (void)setPayPalPublicKey:(NSString *)publicKey{
    paypalPublicKey = publicKey;
    
    if (environment == OLKitePrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentLive];
    } else {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentSandbox];
    }
}

+ (void)setStripeAccountId:(NSString *)accountId{
    stripeAccountId = accountId;
}

+ (void)setStripePublicKey:(NSString *)publicKey{
    stripePublicKey = publicKey;
    [OLStripeCard setClientId:[self stripePublishableKey]];
}

+ (NSString *)paypalAccountId{
    return paypalAccountId;
}

+ (NSString *)stripeAccountId{
    return stripeAccountId;
}

@end
