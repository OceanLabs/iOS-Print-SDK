//
//  OLProductOrderTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 06/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLProductTemplate.h"
#import "OLKitePrintSDK.h"
#import <SDWebImage/SDWebImageManager.h>
#import <Stripe/Stripe.h>
#import "OLPrintPhoto.h"
#import "OLKiteTestHelper.h"

@import Photos;

@interface OLKitePrintSDK (PrivateMethods)

+ (NSString *_Nonnull)stripePublishableKey;

@end

@interface OLProductOrderTests : XCTestCase

@end

@implementation OLProductOrderTests

#pragma mark XCTest methods

- (void)setUp {
    [super setUp];

    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
    
    
    [self templateSyncWithSuccessHandler:NULL];
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark Kite SDK helper methods

- (void)submitOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
    [self submitStripeOrder:printOrder WithSuccessHandler:handler];
}

- (void)submitJobs:(NSArray <id<OLPrintJob>>*)jobs{
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    for (id<OLPrintJob> job in jobs){
        [printOrder addPrintJob:job];
    }
    
    [self submitOrder:printOrder WithSuccessHandler:NULL];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
    
    if (![printOrder.receipt hasPrefix:@"PS"]){
        XCTFail(@"Order does not have valid receipt");
    }
}

- (void)submitStripeOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:[OLKitePrintSDK stripePublishableKey]];
    
    STPCard *card = [STPCard new];
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2020;
    card.cvc = @"123";
    [client createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        if (error) {
            XCTFail(@"Failed to create Stripe token with: %@", error);
        }
        printOrder.proofOfPayment = token.tokenId;
        
        
        [printOrder submitForPrintingWithProgressHandler:NULL completionHandler:^(NSString *orderIdReceipt, NSError *error) {
            if (error) {
                XCTFail(@"Failed to submit order to Kite with: %@", error);
            }
            [printOrder saveToHistory];
            [expectation fulfill];
            if (handler) handler();
        }];
    }];
}

- (void)submitPayPalOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    OLPayPalCard *card = [[OLPayPalCard alloc] init];
    card.type = kOLPayPalCardTypeVisa;
    card.number = @"4242424242424242";
    card.expireMonth = 12;
    card.expireYear = 2020;
    card.cvv2 = @"111";
    
    [printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        if (error) {
            XCTFail(@"Failed to get order cost with: %@", error);
        }
        [card chargeCard:[cost totalCostInCurrency:printOrder.currencyCode] currencyCode:printOrder.currencyCode description:printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            if (error) {
                XCTFail(@"Failed to charge card with: %@", error);
            }
            printOrder.proofOfPayment = proofOfPayment;
            [printOrder submitForPrintingWithProgressHandler:NULL completionHandler:^(NSString *orderIdReceipt, NSError *error) {
                if (error) {
                    XCTFail(@"Failed to submit order to Kite with: %@", error);
                }
                [printOrder saveToHistory];
                [expectation fulfill];
                if (handler) handler();
            }];
        }];
    }];
}

- (void)templateSyncWithSuccessHandler:(void(^)())handler{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Template Sync Completed"];
    [OLProductTemplate syncWithCompletionHandler:^(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error){
        if (error){
            XCTFail(@"Template Sync Request failed with: %@", error);
        }
        if ([templates count] == 0){
            XCTFail(@"Template Sync returned 0 templates. Maintenance mode?");
        }
        [expectation fulfill];
        if (handler) handler();
    }];
}

#pragma mark Test cases

- (void)testSquaresOrderWithURLOLAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithImageOLAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper imageAssets]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithDataOLAssets{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kite_corrupt" ofType:@"jpg"]];
    
    if (!data){
        XCTFail(@"No data");
    }
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataAsJPEG:data]]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithPHAssetOLAssets{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    if (fetchResult.count == 0){
        XCTFail(@"There are no assets available");
    }
    
    PHAsset *asset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];

    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithPHAsset:asset]]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithURLOLAssetPrintPhotos{
    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
    printPhoto.asset = [OLKiteTestHelper urlAssets].firstObject;
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataSource:printPhoto]]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithImageOLAssetPrintPhotos{
    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
    printPhoto.asset = [OLKiteTestHelper imageAssets].firstObject;
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataSource:printPhoto]]];
    [self submitJobs:@[job]];
}

- (void)testSquaresOrderWithPHAssetPrintPhotos{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
    if (fetchResult.count == 0){
        XCTFail(@"There are no assets available");
    }
    
    PHAsset *asset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
    
    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
    printPhoto.asset = asset;
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataSource:printPhoto]]];
    [self submitJobs:@[job]];
}

- (void)testPhotobookOrderWithURLOLAssets{
    OLPhotobookPrintJob *job = [OLPrintJob photobookWithTemplateId:@"rpi_wrap_300x300_sm" OLAssets:[OLKiteTestHelper urlAssets] frontCoverOLAsset:[OLKiteTestHelper urlAssets].firstObject backCoverOLAsset:[OLKiteTestHelper urlAssets].lastObject];
    [self submitJobs:@[job]];
}

- (void)testPostcardOrderWithURLOLAssets{
    id<OLPrintJob> job = [OLPrintJob postcardWithTemplateId:@"postcard" frontImageOLAsset:[OLKiteTestHelper urlAssets].firstObject backImageOLAsset:[OLKiteTestHelper urlAssets].lastObject];
    [self submitJobs:@[job]];
}

@end
