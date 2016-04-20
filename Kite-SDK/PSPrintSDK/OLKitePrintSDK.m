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

#import "OLKitePrintSDK.h"
#import "OLPayPalCard.h"
#import "OLProductTemplate.h"
#import "OLStripeCard.h"
#ifdef OL_KITE_OFFER_PAYPAL
#ifdef COCOAPODS
#import <PayPal-iOS-SDK/PayPalMobile.h>
#else
#import "PayPalMobile.h"
#endif

#endif

#ifdef OL_OFFER_JUDOPAY
#import "OLJudoPayCard.h"
#endif
#import "OLProductHomeViewController.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteABTesting.h"
#import "OLAddressEditViewController.h"
#ifdef OL_KITE_OFFER_APPLE_PAY
#ifdef COCOAPODS
#import <Stripe/Stripe+ApplePay.h>
#else
#import "Stripe+ApplePay.h"
#endif

#endif
#import "OLPaymentViewController.h"
#import "OLKiteUtils.h"

static NSString *const kJudoClientId      = @"100170-877";
static NSString *const kJudoSandboxToken     = @"oLMiwCPBeLs0iVX4";
static NSString *const kJudoSandboxSecret  = @"3bf983df93ceb422bc81fd0289c3eb95ea1d39d990ba27306679ed069826805c";
static NSString *const kJudoLiveToken     = @"JjOZ49Z9XCYy2FAc";
static NSString *const kJudoLiveSecret  = @"b8d5950ec68e27e7dfdb314dbd7160e7421c3bddd4d883d9aef5e94788def934";

static NSString *apiKey = nil;
static NSString *const kOLStripePublishableKeyTest = @"pk_test_FxzXniUJWigFysP0bowWbuy3";
static NSString *const kOLStripePublishableKeyLive = @"pk_live_o1egYds0rWu43ln7FjEyOU5E";
static NSString *applePayMerchantID = nil;
static NSString *applePayPayToString = nil;
static OLKitePrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLStagingEndpointLive = @"https://staging.kite.ly";
static NSString *const kOLStagingEndpointSandbox = @"https://staging.kite.ly";
static NSString *const kOLPayPalClientIdLive = @"ASYVBBCHF_KwVUstugKy4qvpQaPlUeE_5beKRJHpIP2d3SA_jZrsaUDTmLQY";
static NSString *const kOLPayPalClientIdSandbox = @"AcEcBRDxqcCKiikjm05FyD4Sfi4pkNP98AYN67sr3_yZdBe23xEk0qhdhZLM";
static NSString *const kOLPayPalRecipientEmailLive = @"hello@kite.ly";
static NSString *const kOLPayPalRecipientEmailSandbox = @"sandbox-merchant@kite.ly";
static NSString *const kOLAPIEndpointVersion = @"v2.0";

#ifdef OL_OFFER_JUDOPAY
static BOOL useJudoPayForGBP = NO;
#endif
static BOOL useStripeForCreditCards = NO;
static BOOL cacheTemplates = NO;
static BOOL useStaging = NO;
static BOOL isUnitTesting = NO;
static BOOL QRCodeUploadEnabled = NO;
static BOOL isKiosk = NO;

static NSString *instagramClientID = nil;
static NSString *instagramSecret = nil;
static NSString *instagramRedirectURI = nil;

#ifdef OL_KITE_OFFER_ADOBE
static NSString* creativeSDKClientId = nil;
static NSString* creativeSDKClientSecret = nil;
#endif

@implementation OLKitePrintSDK

#ifdef OL_OFFER_JUDOPAY
+ (BOOL)useJudoPayForGBP {
    return useJudoPayForGBP;
}

+ (void)setUseJudoPayForGBP:(BOOL)use {
    useJudoPayForGBP = use;
}
#endif

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
    return NO;
}

+ (void)setAPIKey:(NSString *_Nonnull)_apiKey withEnvironment:(OLKitePrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    [OLStripeCard setClientId:[self stripePublishableKey]];
    if (environment == kOLKitePrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentLive];
#ifdef OL_OFFER_JUDOPAY
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoLiveToken secret:kJudoLiveSecret withEnvironment:kOLJudoPayEnvironmentLive];
#endif
    } else {
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentSandbox];
#ifdef OL_OFFER_JUDOPAY
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoSandboxToken secret:kJudoSandboxSecret withEnvironment:kOLJudoPayEnvironmentSandbox];
#endif
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
            case kOLKitePrintSDKEnvironmentLive: return kOLStagingEndpointLive;
            case kOLKitePrintSDKEnvironmentSandbox: return kOLStagingEndpointSandbox;
        }
    }
    else{
        switch (environment) {
            case kOLKitePrintSDKEnvironmentLive: return kOLAPIEndpointLive;
            case kOLKitePrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
        }
    }
}

+ (NSString *)apiVersion{
    return kOLAPIEndpointVersion;
}

+ (void) addPushDeviceToken:(NSData *)deviceToken{
    [OLAnalytics addPushDeviceToken:deviceToken];
}

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *_Nonnull)paypalEnvironment {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return PayPalEnvironmentProduction;
        case kOLKitePrintSDKEnvironmentSandbox: return PayPalEnvironmentSandbox;
    }
}
#endif

+ (NSString *_Nonnull)paypalClientId {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLPayPalClientIdLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLPayPalClientIdSandbox;
    }
}

+ (void)setApplePayMerchantID:(NSString *_Nonnull)mID{
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayMerchantID = mID;
#endif
}

+ (void)setApplePayPayToString:(NSString *_Nonnull)name{
#ifdef OL_KITE_OFFER_APPLE_PAY
    applePayPayToString = name;
#endif
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
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLStripePublishableKeyLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLStripePublishableKeyTest;
    }
}

+ (NSString *)qualityGuaranteeString{
    return NSLocalizedString(@"**Quality Guarantee**\nOur products are of the highest quality and we’re confident you will love yours. If not, we offer a no quibble money back guarantee. Enjoy!", @"");
}

#ifdef OL_KITE_OFFER_ADOBE
+ (void)setAdobeCreativeSDKEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret{
    creativeSDKClientSecret = secret;
    creativeSDKClientId = clientID;
}

+ (NSString *)adobeCreativeSDKClientSecret{
    return creativeSDKClientSecret;
}

+ (NSString *)adobeCreativeSDKClientID{
    return creativeSDKClientId;
}
#endif

+ (void)setIsKiosk:(BOOL)enabled{
    isKiosk = enabled;
}

+ (BOOL)isKiosk{
    return isKiosk;
}

+ (void)setQRCodeUploadEnabled:(BOOL)enabled{
    QRCodeUploadEnabled = enabled;
}

+ (BOOL)QRCodeUploadEnabled{
    return QRCodeUploadEnabled;
}

#pragma mark - Internal


+ (void)setInstagramEnabledWithClientID:(NSString *_Nonnull)clientID secret:(NSString *_Nonnull)secret redirectURI:(NSString *_Nonnull)redirectURI {
#ifdef OL_KITE_OFFER_INSTAGRAM
    instagramSecret = secret;
    instagramClientID = clientID;
    instagramRedirectURI = redirectURI;
#endif
}

+ (NSString *)instagramRedirectURI {
#ifdef OL_KITE_OFFER_INSTAGRAM
    return instagramRedirectURI;
#else
    return nil;
#endif
}

+ (NSString *)instagramSecret{
#ifdef OL_KITE_OFFER_INSTAGRAM
    return instagramSecret;
#else
    return nil;
#endif
}

+ (NSString *)instagramClientID{
#ifdef OL_KITE_OFFER_INSTAGRAM
    return instagramClientID;
#else
    return nil;
#endif
}

@end
