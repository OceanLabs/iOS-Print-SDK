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

@interface ViewController (Private)
- (NSString *)liveKey;
- (NSString *)sandboxKey;
@end

@interface OLSDKModelTests : XCTestCase

@end

@implementation OLSDKModelTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

@end
