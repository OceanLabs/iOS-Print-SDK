//
//  PS_SDKTests.m
//  Kite SDKTests
//
//  Created by Deon Botha on 18/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ViewController.h"
#import "NSString+Formatting.h"
#import "OLKitePrintSDK.h"
#import <PayPal-iOS-SDK/PayPalMobile.h>

@interface ViewController (Private)
- (NSString *)liveKey;
- (NSString *)sandboxKey;
@end

@interface OLKitePrintSDK (Private)

+ (void)setUseJudoPayForGBP:(BOOL)use;
+ (BOOL)useJudoPayForGBP;
+ (void)setCacheTemplates:(BOOL)cache;
+ (BOOL)cacheTemplates;
+ (NSString *_Nonnull)paypalEnvironment;
+ (NSString *_Nonnull)paypalClientId;
+ (NSString *_Nonnull)stripePublishableKey;
+ (NSString *_Nonnull)appleMerchantID;
+ (NSString *)applePayPayToString;
+ (NSString *)instagramRedirectURI;
+ (NSString *)instagramSecret;
+ (NSString *)instagramClientID;

@end

@interface OLCountry (Private)
+ (BOOL)isValidCurrencyCode:(NSString *)code;
@end

@interface OLSDKModelTests : XCTestCase

@end

@implementation OLSDKModelTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testSampleAppAPIKeyIsNotSet {
    ViewController *vc = [[ViewController alloc] init];
    if (![[vc liveKey] isEqualToString:@"REPLACE_WITH_YOUR_API_KEY"] || ![[vc sandboxKey] isEqualToString:@"REPLACE_WITH_YOUR_API_KEY"]){
        XCTFail(@"API Key is set in ViewController.m, this is undesirable for third party developers when commiting & pushing codes.");
    }
}

- (void)testCreditCardFormatter {
    NSString *input = @"";
    NSString *expected = @"";
    NSString *actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"123";
    expected = @"123";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"1234";
    expected = @"1234";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"12345";
    expected = @"1234 5";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"123456789abcdefg";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"123456789abcdefgh";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
    
    input = @"123456789abcdefghijk";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    if (![actual isEqualToString:expected]){
        XCTFail(@"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    }
}

- (void)testOLCountries{
    OLCountry *country = [OLCountry countryForCode:@"GBR"];
    if (![country isInEurope]){
        XCTFail(@"UK should be in Europe");
    }
    
    country = [OLCountry countryForName:@"United States"];
    if ([country isInEurope]){
        XCTFail(@"US should not be in Europe");
    }
    
    country = [OLCountry countryForCode:@"ABC"];
    if (country){
        XCTFail(@"No such country should exist");
    }
    country = [OLCountry countryForName:@"FOOBAR"];
    if (country){
        XCTFail(@"There should be no such country");
    }
    
    if ([OLCountry isValidCurrencyCode:@"ABC"]){
        XCTFail(@"There should be no such currency code");
    }
    if (![OLCountry isValidCurrencyCode:@"EUR"]){
        XCTFail(@"There should be such a currency code");
    }
}

- (void)testOLKitePrintSDK{
    //Live
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentLive];
    if ([OLKitePrintSDK environment] != kOLKitePrintSDKEnvironmentLive){
        XCTFail(@"Environment fail");
    }
    if (![[OLKitePrintSDK paypalEnvironment] isEqualToString:PayPalEnvironmentProduction]){
        XCTFail(@"PayPal environment fail");
    }
    if (![OLKitePrintSDK paypalClientId] || [[OLKitePrintSDK paypalClientId] isEqualToString:@""]){
        XCTFail(@"No PayPal client ID");
    }
    
    if(![OLKitePrintSDK stripePublishableKey] || [[OLKitePrintSDK stripePublishableKey] isEqualToString:@""]){
        XCTFail(@"Stripe key fail");
    }
    
    
    //Sandbox
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    if (![[OLKitePrintSDK paypalEnvironment] isEqualToString:PayPalEnvironmentSandbox]){
        XCTFail(@"PayPal environment fail");
    }
    if (![OLKitePrintSDK paypalClientId] || [[OLKitePrintSDK paypalClientId] isEqualToString:@""]){
        XCTFail(@"No PayPal client ID");
    }
    
    if(![OLKitePrintSDK stripePublishableKey] || [[OLKitePrintSDK stripePublishableKey] isEqualToString:@""]){
        XCTFail(@"Stripe key fail");
    }
    
    [OLKitePrintSDK setUseJudoPayForGBP:NO];
    if ([OLKitePrintSDK useJudoPayForGBP]){
        XCTFail(@"Judopay fail");
    }
    
    [OLKitePrintSDK setCacheTemplates:NO];
    if ([OLKitePrintSDK cacheTemplates]){
        XCTFail(@"Cache templates fail");
    }
    
    [OLKitePrintSDK setApplePayMerchantID:@"merchant"];
    if (![[OLKitePrintSDK appleMerchantID] isEqualToString:@"merchant"]){
        XCTFail(@"Merchant fail");
    }
    
    if (![[OLKitePrintSDK applePayPayToString] isEqualToString:@"Kite.ly (via Kite.ly)"]){
        XCTFail(@"Pay to test fail");
    }
    [OLKitePrintSDK setApplePayPayToString:@"Kite Test"];
    if (![[OLKitePrintSDK applePayPayToString] isEqualToString:@"Kite Test"]){
        XCTFail(@"Pay to test fail");
    }
    
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"client" secret:@"secret" redirectURI:@"redirect"];
    if (![[OLKitePrintSDK instagramClientID] isEqualToString:@"client"]){
        XCTFail(@"Instagram Fail");
    }
    if (![[OLKitePrintSDK instagramSecret] isEqualToString:@"secret"]){
        XCTFail(@"Instagram Fail");
    }
    if (![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@"redirect"]){
        XCTFail(@"Instagram Fail");
    }
    
}

@end
