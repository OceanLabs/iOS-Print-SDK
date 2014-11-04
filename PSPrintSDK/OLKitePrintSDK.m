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
#import <PayPalMobile.h>
#import "OLJudoPayCard.h"

static NSString *const kJudoClientId      = @"100170-877";
static NSString *const kJudoSandboxToken     = @"oLMiwCPBeLs0iVX4";
static NSString *const kJudoSandboxSecret  = @"3bf983df93ceb422bc81fd0289c3eb95ea1d39d990ba27306679ed069826805c";
static NSString *const kJudoLiveToken     = @"JjOZ49Z9XCYy2FAc";
static NSString *const kJudoLiveSecret  = @"b8d5950ec68e27e7dfdb314dbd7160e7421c3bddd4d883d9aef5e94788def934";

static NSString *apiKey;
static NSString *StripePublishableKey;
static NSString *kApplePayMerchantID;
static OLPSPrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.kite.ly";
static NSString *const kOLAPIEndpointSandbox = @"https://api.kite.ly";
static NSString *const kOLPayPalClientIdLive = @"AT2JfBAmXD-CHGJnUb05ik4J-GrCi4XxjY9_grfCFjreYaLrNswj8uzhuWyj";
static NSString *const kOLPayPalClientIdSandbox = @"Aa5nsBDntBpozWQykoxQXoHFOqs551hTNt0B8LQXTudoh8bD0nT1F735c_Fh";
static NSString *const kOLPayPalRecipientEmailLive = @"deon@oceanlabs.co";
static NSString *const kOLPayPalRecipientEmailSandbox = @"hello-facilitator@psilov.eu";

static BOOL useJudoPayForGBP = NO;

@implementation OLKitePrintSDK

+ (BOOL)useJudoPayForGBP {
    return useJudoPayForGBP;
}

+ (void)setUseJudoPayForGBP:(BOOL)use {
    useJudoPayForGBP = use;
}

+ (void)setAPIKey:(NSString *)_apiKey withEnvironment:(OLPSPrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    if (environment == kOLKitePrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:kOLPayPalClientIdLive withEnvironment:kOLPayPalEnvironmentLive];
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoLiveToken secret:kJudoLiveSecret withEnvironment:kOLJudoPayEnvironmentLive];
    } else {
        [OLPayPalCard setClientId:kOLPayPalClientIdSandbox withEnvironment:kOLPayPalEnvironmentSandbox];
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoSandboxToken secret:kJudoSandboxSecret withEnvironment:kOLJudoPayEnvironmentSandbox];
    }
    
    [OLProductTemplate sync];
}

+ (void) setApplePayMerchantID:(NSString *)mID{
    kApplePayMerchantID = mID;
}

+ (void) setStripeKey:(NSString *)stripeKey{
    StripePublishableKey = stripeKey;
}

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

+ (NSString *)apiKey {
    return apiKey;
}

+ (OLPSPrintSDKEnvironment)environment {
    return environment;
}

+ (NSString *)apiEndpoint {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLAPIEndpointLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
    }
}

+ (NSString *)paypalReceiverEmail {
    switch (environment) {
        case kOLKitePrintSDKEnvironmentLive: return kOLPayPalRecipientEmailLive;
        case kOLKitePrintSDKEnvironmentSandbox: return kOLPayPalRecipientEmailSandbox;
    }
}

+ (NSString *)stripePublishableKey {
    return StripePublishableKey;
}

+ (NSString *)appleMerchantID {
    return kApplePayMerchantID;
}

@end
