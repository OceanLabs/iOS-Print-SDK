//
//  OLDocsObjcExampleCodeTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLKitePrintSDK.h"

@interface OLKitePrintSDK (PrivateMethods)

+ (BOOL)setIsUnitTesting;

@end

@interface OLDocsObjcExampleCodeTests : XCTestCase <OLAddressSearchRequestDelegate>

@property (strong, nonatomic) XCTestExpectation *addressRequestExpectation;

@end

@implementation OLDocsObjcExampleCodeTests

- (void)setUp {
    [super setUp];
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    [OLKitePrintSDK setIsUnitTesting];
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
        XCTAssert(!error, @"Template sync failed with: %@", error);
        
        id<OLPrintJob> iPhone6Case = [OLPrintJob printJobWithTemplateId:@"i6_case" OLAssets:assets];
        id<OLPrintJob> poster = [OLPrintJob printJobWithTemplateId:@"a1_poster" OLAssets:assets];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:iPhone6Case];
        [order addPrintJob:poster];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Charging card failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

/**
 *  https://www.kite.ly/docs/?objective_c#ordering-print-products
 */
- (void)testSiteExamplePrints{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    NSArray *assets = @[
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]]
                        ];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray* templates, NSError *error){
        XCTAssert(!error, @"Template sync failed with: %@", error);
        
        id<OLPrintJob> squarePrints = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:assets];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:squarePrints];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Card charge failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

/**
 *  https://www.kite.ly/docs/?objective_c#ordering-phone-cases
 */
- (void)testSiteExampleCases{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    NSArray *assets = @[
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]]
                        ];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray* templates, NSError *error){
        XCTAssert(!error, @"Template sync failed with: %@", error);
        id<OLPrintJob> ipadAirCase = [OLPrintJob printJobWithTemplateId:@"ipad_air_case" OLAssets:assets];
        id<OLPrintJob> galaxyS5Case = [OLPrintJob printJobWithTemplateId:@"samsung_s5_case" OLAssets:assets];
        [galaxyS5Case setValue:@"matte" forOption:@"case_style"];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:ipadAirCase];
        [order addPrintJob:galaxyS5Case];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Card charge failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

/**
 *  https://www.kite.ly/docs/?objective_c#ordering-apparel
 */
- (void)testSiteExampleApparel{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    NSDictionary *assets = @{
                             @"center_chest": [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]],
                             @"center_back":[OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/2.jpg"]]
                             };
    [OLProductTemplate syncWithCompletionHandler:^(NSArray* templates, NSError *error){
        XCTAssert(!error, @"Template sync failed with: %@", error);
        
        id<OLPrintJob> tshirt = [OLPrintJob apparelWithTemplateId:@"gildan_tshirt" OLAssets:assets];
        [tshirt setValue:@"M" forOption:@"garment_size"];
        [tshirt setValue:@"white" forOption:@"garment_color"];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:tshirt];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Card charge failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

/**
 *  https://www.kite.ly/docs/?objective_c#ordering-photobooks
 */
- (void)testSiteExamplePhotoBook{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    NSArray *assets = @[
                        [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/1.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/2.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/3.jpg"]]
                        ];
    OLAsset *frontCoverAsset = [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray* templates, NSError *error){
        XCTAssert(!error, @"Template sync failed with: %@", error);
        
        id<OLPrintJob> photobook = [OLPrintJob photobookWithTemplateId:@"photobook_small_portrait" OLAssets:assets frontCoverOLAsset:frontCoverAsset backCoverOLAsset:nil];
        [photobook setValue:@"#FFFFFF" forOption:@"spine_color"];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:photobook];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Card charge failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

- (void)testSiteExamplePostcard{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    OLAsset *frontImage = [OLAsset assetWithURL:[NSURL URLWithString:@"http://psps.s3.amazonaws.com/sdk_static/4.jpg"]];
    
    [OLProductTemplate syncWithCompletionHandler:^(NSArray* templates, NSError *error){
        XCTAssert(!error, @"Template sync failed with: %@", error);
        
        id<OLPrintJob> postcard = [OLPrintJob postcardWithTemplateId:@"postcard" frontImageOLAsset:frontImage message:@"Hello World!" address:nil];
        
        OLPrintOrder *order = [[OLPrintOrder alloc] init];
        [order addPrintJob:postcard];
        order.email = @"ios_unit_test@kite.ly";
        
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
            XCTAssert(!error, @"Cost request failed with: %@", error);
            
            [card chargeCard:[cost totalCostInCurrency:order.currencyCode] currencyCode:order.currencyCode description:@"A Kite order!" completionHandler:^(NSString *proofOfPayment, NSError *error) {
                XCTAssert(!error, @"Card charge failed with: %@", error);
                
                // if no error occured set the OLPrintOrder proofOfPayment to the one provided and submit the order
                order.proofOfPayment = proofOfPayment;
                [order submitForPrintingWithProgressHandler:nil
                                          completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                                              XCTAssert(!error, @"Order submission failed with: %@", error);
                                              
                                              // If there is no error then you can display a success outcome to the user
                                              XCTAssert(order.printed, @"Order not printed");
                                              XCTAssert([order.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
                                              [expectation fulfill];
                                          }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

#pragma mark Address Search Tests

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithMultipleOptions:(NSArray *)options {
    [self.addressRequestExpectation fulfill];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didSuceedWithUniqueAddress:(OLAddress *)addr {
    [self.addressRequestExpectation fulfill];
}

- (void)addressSearchRequest:(OLAddressSearchRequest *)req didFailWithError:(NSError *)error {
    XCTFail(@"Address search failed with: %@", error);
}

- (void)testSiteExampleAddressSearch{
    self.addressRequestExpectation = [self expectationWithDescription:@"Address Search Request completed"];
    
    OLCountry *usa = [OLCountry countryForCode:@"USA"];
    [OLAddress searchForAddressWithCountry:usa query:@"1 Infinite Loop" delegate:self];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
}

@end
