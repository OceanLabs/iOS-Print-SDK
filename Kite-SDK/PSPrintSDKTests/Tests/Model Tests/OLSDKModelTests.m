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
#import "OLProductGroup.h"

@interface ViewController (Private)
- (NSString *)liveKey;
- (NSString *)sandboxKey;
@end

@interface OLKitePrintSDK (Private)
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
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"123";
    expected = @"123";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"1234";
    expected = @"1234";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"12345";
    expected = @"1234 5";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"123456789abcdefg";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"123456789abcdefgh";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"123456789abcdefghijk";
    expected = @"1234 5678 9abc defg";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
    
    input = @"373456789abcdefghij";
    expected = @"3734 56789a bcdef";
    actual = [NSString stringByFormattingCreditCardNumber:input];
    XCTAssert([actual isEqualToString:expected], @"Credit card number formatter does not work properly. Expected: %@ but got: %@", expected, actual);
}

- (void)testOLCountries{
    OLCountry *country = [OLCountry countryForCode:@"GBR"];
    XCTAssert([country isInEurope], @"UK should be in Europe");
    
    country = [OLCountry countryForName:@"United States"];
    XCTAssert(![country isInEurope], @"US should not be in Europe");
    
    country = [OLCountry countryForCode:@"ABC"];
    XCTAssert(!country, @"No such country should exist");
    
    country = [OLCountry countryForName:@"FOOBAR"];
    XCTAssert(!country, @"No such country should exist");
    
    XCTAssert(![OLCountry isValidCurrencyCode:@"ABC"], @"There should be no such currency code");
    XCTAssert([OLCountry isValidCurrencyCode:@"EUR"], @"There should be such a currency code");
    
}

- (void)testOLKitePrintSDK{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for template sync"];
    //Live
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentLive];
    XCTAssert([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentLive, @"Environment fail");
    XCTAssert([[OLKitePrintSDK paypalEnvironment] isEqualToString:@"live"], @"PayPal environment fail");
    [OLProductTemplate syncWithCompletionHandler:^(id t, id e){
        XCTAssert([OLKitePrintSDK paypalClientId] && ![[OLKitePrintSDK paypalClientId] isEqualToString:@""],@"No PayPal client ID");
        XCTAssert([OLKitePrintSDK stripePublishableKey] && ![[OLKitePrintSDK stripePublishableKey] isEqualToString:@""],@"Stripe key fail");
        
        
        //Sandbox
        [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentSandbox];
        XCTAssert([OLKitePrintSDK environment] == OLKitePrintSDKEnvironmentSandbox, @"Environment fail");
        XCTAssert([[OLKitePrintSDK paypalEnvironment] isEqualToString:@"sandbox"], @"PayPal environment fail");
        [OLProductTemplate syncWithCompletionHandler:^(id t, id e){
            XCTAssert([OLKitePrintSDK paypalClientId] && ![[OLKitePrintSDK paypalClientId] isEqualToString:@""], @"No PayPal client ID");
            XCTAssert([OLKitePrintSDK stripePublishableKey] && ![[OLKitePrintSDK stripePublishableKey] isEqualToString:@""], @"Stripe key fail");
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:nil];
    
    [OLKitePrintSDK setApplePayMerchantID:@"merchant"];
    XCTAssert([[OLKitePrintSDK appleMerchantID] isEqualToString:@"merchant"], @"Merchant fail");
    
    [OLKitePrintSDK setApplePayPayToString:@"Kite Test"];
    XCTAssert([[OLKitePrintSDK applePayPayToString] isEqualToString:@"Kite Test"], @"Pay to test fail");
    
    [OLKitePrintSDK setInstagramEnabledWithClientID:@"client" secret:@"secret" redirectURI:@"redirect"];
    XCTAssert([[OLKitePrintSDK instagramClientID] isEqualToString:@"client"], @"Instagram Fail");
    XCTAssert([[OLKitePrintSDK instagramSecret] isEqualToString:@"secret"], @"Instagram Fail");
    XCTAssert([[OLKitePrintSDK instagramRedirectURI] isEqualToString:@"redirect"], @"Instagram Fail");
}

- (void)testInstantiateOLPrintJobException{
    @try {
        id job = [[OLPrintJob alloc] init];
        XCTAssert(!job, @"Should throw exception");
    }
    @catch (NSException *exception) {
        //All good
    }
}

- (void)testPrintJobProductName{
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Sync Templates"];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error){
        id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" images:@[]];
        XCTAssert([job.productName isEqualToString:[OLProductTemplate templateWithId:@"squares"].name]);
        
        job = [OLPrintJob photobookWithTemplateId:@"rpi_wrap_210x210_sm" OLAssets:@[] frontCoverOLAsset:nil backCoverOLAsset:nil];
        XCTAssert([job.productName isEqualToString:[OLProductTemplate templateWithId:@"rpi_wrap_210x210_sm"].name]);
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
}

- (void)testCreditCardExpiryFormat{
    NSString *s = @"1020";
    s = [NSString stringByFormattingCreditCardExpiry:s];
    XCTAssert([s isEqualToString:@"10/20"]);
}

@end
