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
#import "OLPrintOrderCost.h"
#import <SDWebImage/SDWebImageManager.h>

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
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark Image helper methods

- (NSArray *)urlAssets{
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    return assets;
}

- (NSArray *)imageAssets{
    return @[[OLAsset assetWithImageAsJPEG:[self downloadImage]]];
}

- (UIImage *)downloadImage{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download image complete"];
    __block UIImage *downloadedImage;
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
        downloadedImage = image;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
    
    return downloadedImage;
}

#pragma mark Kite SDK helper methods

- (void)submitOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
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

- (void)testSquaresOrderWithURLAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[self urlAssets]];
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    [printOrder addPrintJob:job];
    
    [self submitOrder:printOrder WithSuccessHandler:NULL];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testSquaresOrderWithImageAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[self imageAssets]];
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    [printOrder addPrintJob:job];
    
    [self submitOrder:printOrder WithSuccessHandler:NULL];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

@end
