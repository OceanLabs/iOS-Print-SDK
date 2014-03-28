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
