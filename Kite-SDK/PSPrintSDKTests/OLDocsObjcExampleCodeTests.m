//
//  OLDocsObjcExampleCodeTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLKitePrintSDK.h"

@interface OLDocsObjcExampleCodeTests : XCTestCase

@end

@implementation OLDocsObjcExampleCodeTests

- (void)setUp {
    [super setUp];
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
}

- (void)tearDown {
    [super tearDown];
}

/**
 *  https://www.kite.ly/docs/?objective_c#placing-orders
 */
- (void)testSiteExampleOrder{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    NSArray *assets = @[
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]]
                        ];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error){
        id<OLPrintJob> iPhone6Case = [OLPrintJob printJobWithTemplateId:@"i6_case" OLAssets:assets];
        id<OLPrintJob> poster = [OLPrintJob printJobWithTemplateId:@"a1_poster" OLAssets:assets];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:iPhone6Case];
        [order addPrintJob:poster];
        
        OLAddress *a    = [[OLAddress alloc] init];
        a.recipientFirstName = @"Deon";
        a.recipientLastName = @"Botha";
        a.line1         = @"27-28 Eastcastle House";
        a.line2         = @"Eastcastle Street";
        a.city          = @"London";
        a.stateOrCounty = @"Greater London";
        a.zipOrPostcode = @"W1W 8DH";
        a.country       = [OLCountry countryForCode:@"GBR"];
        
        order.shippingAddress = a;
        
        OLPayPalCard *card = [[OLPayPalCard alloc] init];
        card.type = kOLPayPalCardTypeVisa;
        card.number = @"4121212121212127";
        card.expireMonth = 12;
        card.expireYear = 2020;
        card.cvv2 = @"123";
        
        [order costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
            if (error){
                XCTFail(@"Cost request failed with: %@", error);
            }
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                if (error){
                    XCTFail(@"Charging card failed with: %@", error);
                }
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              if (error){
                                                  XCTFail(@"Order submission failed with: %@", error);
                                              }
                                              // If there is no error then you can display a success outcome to the user
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

@end
