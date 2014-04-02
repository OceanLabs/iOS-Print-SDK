//
//  PrintStudio.m
//  PS SDK
//
//  Created by Deon Botha on 19/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLPSPrintSDK.h"
#import "OLPayPalCard.h"
#import "OLProductTemplate.h"
#import <PayPalMobile.h>

#ifdef USE_JUDOPAY_FOR_GBP // This macro is only really for internal use. No harm in using it but it has no external benefit, default is PayPal REST APIs for credit card payments.
#import "OLJudoPayCard.h"
static NSString *const kJudoClientId      = @"100170-877";
static NSString *const kJudoSandboxToken     = @"oLMiwCPBeLs0iVX4";
static NSString *const kJudoSandboxSecret  = @"3bf983df93ceb422bc81fd0289c3eb95ea1d39d990ba27306679ed069826805c";
static NSString *const kJudoLiveToken     = @"JjOZ49Z9XCYy2FAc";
static NSString *const kJudoLiveSecret  = @"b8d5950ec68e27e7dfdb314dbd7160e7421c3bddd4d883d9aef5e94788def934";
#endif

static NSString *apiKey;
static OLPSPrintSDKEnvironment environment;

static NSString *const kOLAPIEndpointLive = @"https://api.psilov.eu";
static NSString *const kOLAPIEndpointSandbox = @"https://api.psilov.eu";
static NSString *const kOLPayPalClientIdLive = @"AT2JfBAmXD-CHGJnUb05ik4J-GrCi4XxjY9_grfCFjreYaLrNswj8uzhuWyj";
static NSString *const kOLPayPalClientIdSandbox = @"Aa5nsBDntBpozWQykoxQXoHFOqs551hTNt0B8LQXTudoh8bD0nT1F735c_Fh";
static NSString *const kOLPayPalRecipientEmailLive = @"deon@oceanlabs.co";
static NSString *const kOLPayPalRecipientEmailSandbox = @"hello-facilitator@psilov.eu";

@implementation OLPSPrintSDK

+ (void)setAPIKey:(NSString *)_apiKey withEnvironment:(OLPSPrintSDKEnvironment)_environment {
    apiKey = _apiKey;
    environment = _environment;
    if (environment == kOLPSPrintSDKEnvironmentLive) {
        [OLPayPalCard setClientId:kOLPayPalClientIdLive withEnvironment:kOLPayPalEnvironmentLive];
    } else {
        [OLPayPalCard setClientId:kOLPayPalClientIdSandbox withEnvironment:kOLPayPalEnvironmentSandbox];
    }
    
    [OLProductTemplate sync];
    
#ifdef USE_JUDOPAY_FOR_GBP
    if (environment == kOLPSPrintSDKEnvironmentSandbox) {
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoSandboxToken secret:kJudoSandboxSecret withEnvironment:kOLJudoPayEnvironmentSandbox];
    } else {
        [OLJudoPayCard setClientId:kJudoClientId token:kJudoLiveToken secret:kJudoLiveSecret withEnvironment:kOLJudoPayEnvironmentLive];
    }
#endif
}

+ (NSString *)paypalEnvironment {
    switch (environment) {
        case kOLPSPrintSDKEnvironmentLive: return PayPalEnvironmentProduction;
        case kOLPSPrintSDKEnvironmentSandbox: return PayPalEnvironmentSandbox;
    }
}

+ (NSString *)paypalClientId {
    switch (environment) {
        case kOLPSPrintSDKEnvironmentLive: return kOLPayPalClientIdLive;
        case kOLPSPrintSDKEnvironmentSandbox: return kOLPayPalClientIdSandbox;
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
        case kOLPSPrintSDKEnvironmentLive: return kOLAPIEndpointLive;
        case kOLPSPrintSDKEnvironmentSandbox: return kOLAPIEndpointSandbox;
    }
}

+ (NSString *)paypalReceiverEmail {
    switch (environment) {
        case kOLPSPrintSDKEnvironmentLive: return kOLPayPalRecipientEmailLive;
        case kOLPSPrintSDKEnvironmentSandbox: return kOLPayPalRecipientEmailSandbox;
    }
}

@end
