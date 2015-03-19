//
//  PrintStudio.m
//  Kite SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLKitePrintSDK.h"
#import "OLPayPalCard.h"
#import "OLProductTemplate.h"
#ifdef OL_KITE_OFFER_PAYPAL
#import <PayPalMobile.h>
#endif
#import "OLJudoPayCard.h"
#import "OLProductHomeViewController.h"

static NSString *const kJudoClientId      = @"100170-877";
static NSString *const kJudoSandboxToken     = @"oLMiwCPBeLs0iVX4";
static NSString *const kJudoSandboxSecret  = @"3bf983df93ceb422bc81fd0289c3eb95ea1d39d990ba27306679ed069826805c";
static NSString *const kJudoLiveToken     = @"JjOZ49Z9XCYy2FAc";
static NSString *const kJudoLiveSecret  = @"b8d5950ec68e27e7dfdb314dbd7160e7421c3bddd4d883d9aef5e94788def934";

static NSString *apiKey = nil;
static NSString *StripePublishableKey = nil;
static NSString *kApplePayMerchantID = nil;
static NSArray *enabledProducts = nil;
static OLKitePrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLPayPalClientIdLive = @"ASYVBBCHF_KwVUstugKy4qvpQaPlUeE_5beKRJHpIP2d3SA_jZrsaUDTmLQY";
static NSString *const kOLPayPalClientIdSandbox = @"AcEcBRDxqcCKiikjm05FyD4Sfi4pkNP98AYN67sr3_yZdBe23xEk0qhdhZLM";
static NSString *const kOLPayPalRecipientEmailLive = @"hello@kite.ly";
static NSString *const kOLPayPalRecipientEmailSandbox = @"sandbox-merchant@kite.ly";

static BOOL useJudoPayForGBP = NO;

static NSString *instagramClientID = nil;
static NSString *instagramSecret = nil;
static NSString *instagramReturnURI = nil;

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
@end

@implementation OLKitePrintSDK

+ (BOOL)useJudoPayForGBP {
    return useJudoPayForGBP;
}

+ (void)setUseJudoPayForGBP:(BOOL)use {
    useJudoPayForGBP = use;
}

+ (void)setAPIKey:(NSString *)_apiKey withEnvironment:(OLKitePrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    if (environment == kOLKitePrintSDKEnvironmentLive) {
#ifdef OL_KITE_OFFER_PAYPAL
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentLive];
#endif
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoLiveToken secret:kJudoLiveSecret withEnvironment:kOLJudoPayEnvironmentLive];
    } else {
#ifdef OL_KITE_OFFER_PAYPAL
        [OLPayPalCard setClientId:[self paypalClientId] withEnvironment:kOLPayPalEnvironmentSandbox];
#endif
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoSandboxToken secret:kJudoSandboxSecret withEnvironment:kOLJudoPayEnvironmentSandbox];
    }
}

+ (NSString *)apiKey {
    return apiKey;
}

+ (OLKitePrintSDKEnvironment)environment {
    return environment;
}

+ (NSString *)apiEndpoint {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLAPIEndpointLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
    }
}

+ (NSArray *)enabledProducts{
    if (enabledProducts && [enabledProducts count] == 0){
        return nil;
    }
    return enabledProducts;
}

+ (void)setEnabledProducts:(NSArray *)products{
    enabledProducts = products;
}

#ifdef OL_KITE_OFFER_PAYPAL
+ (NSString *)paypalEnvironment {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return PayPalEnvironmentProduction;
        case kOLKitePrintSDKEnvironmentSandbox: return PayPalEnvironmentSandbox;
    }
}

+ (NSString *)paypalClientId {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLPayPalClientIdLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLPayPalClientIdSandbox;
    }
}

+ (NSString *)paypalReceiverEmail {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLPayPalRecipientEmailLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLPayPalRecipientEmailSandbox;
    }
}

#endif

#ifdef OL_KITE_OFFER_APPLE_PAY
+ (void)setApplePayMerchantID:(NSString *)mID{
    kApplePayMerchantID = mID;
}

+ (void)setStripeKey:(NSString *)stripeKey{
    StripePublishableKey = stripeKey;
}

+ (NSString *)stripePublishableKey {
    return StripePublishableKey;
}

+ (NSString *)appleMerchantID {
    return kApplePayMerchantID;
}
#endif

#pragma mark - Internal Kite Utils (May be better to move these to their own source file longer term

+ (NSString *)userEmail:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteViewControllerInNavStack:topVC.navigationController.viewControllers];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.userEmail;
    } else if (homeVC) {
        return homeVC.userEmail;
    }
    
    return nil;
}

+ (NSString *)userPhone:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteViewControllerInNavStack:topVC.navigationController.viewControllers];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.userPhone;
    } else if (homeVC) {
        return homeVC.userPhone;
    }
    
    return nil;
}

+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteViewControllerInNavStack:topVC.navigationController.viewControllers];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.delegate;
    } else if (homeVC) {
        return homeVC.delegate;
    }
    
    return nil;
}

+ (OLKiteViewController *)kiteViewControllerInNavStack:(NSArray *)viewControllers {
    for (UIViewController *vc in viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

+ (OLProductHomeViewController *)homeViewControllerInNavStack:(NSArray *)viewControllers {
    for (UIViewController *vc in viewControllers) {
        if ([vc isMemberOfClass:[OLProductHomeViewController class]]) {
            return (OLProductHomeViewController *) vc;
        }
    }
    
    return nil;
}

+ (void)setInstagramEnabledWithReturnURI:(NSString *)URI clientID:(NSString *)clientID secret:(NSString *)secret{
    instagramReturnURI = URI;
    instagramSecret = secret;
    instagramClientID = clientID;
}

+ (NSString *) instagramReturnURI{
    return instagramReturnURI;
}

+ (NSString *) instagramSecret{
    return instagramSecret;
}

+ (NSString *) instagramClientID{
    return instagramClientID;
}

@end
