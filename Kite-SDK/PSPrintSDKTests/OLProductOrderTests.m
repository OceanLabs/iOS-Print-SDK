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
#import "OLKiteTestHelper.h"
#import "OLPhotobookPrintJob.h"


@import Photos;

@interface OLPrintOrder (Private)
- (BOOL)hasCachedCost;
@end

@interface OLKitePrintSDK (PrivateMethods)

+ (NSString *_Nonnull)stripePublishableKey;
+ (BOOL)setIsUnitTesting;

@end

@interface OLProductOrderTests : XCTestCase

@end

@implementation OLProductOrderTests

#pragma mark XCTest methods

- (void)setUp {
    [super setUp];
    
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    [OLKitePrintSDK setIsUnitTesting];
    
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark Kite SDK helper methods

- (void)submitOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
    [self submitStripeOrder:printOrder WithSuccessHandler:handler];
}

- (OLPrintOrder *)submitJobs:(NSArray <id<OLPrintJob>>*)jobs{
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    
    [printOrder addPrintJob:jobs.firstObject];
    [printOrder removePrintJob:jobs.firstObject];
    
    [printOrder setUserData:@{@"Unit Tests" : @YES}];
    
    XCTAssert(printOrder.jobs.count == 0, @"Exptected 0 jobs");
    
    for (id<OLPrintJob> job in jobs){
        [printOrder addPrintJob:job];
    }
    
//    XCTAssert(![printOrder hasCachedCost], @"Should not have cached cost");
    
    [printOrder preemptAssetUpload];
    
    [self submitOrder:printOrder WithSuccessHandler:NULL];
    
    [self waitForExpectationsWithTimeout:120 handler:nil];
    
    XCTAssert(printOrder.printed, @"Order not printed");
    XCTAssert([printOrder.receipt hasPrefix:@"PS"], @"Order does not have valid receipt");
    if (jobs.count == 1){
        XCTAssert(![printOrder.paymentDescription hasSuffix:@"& More"]);
    }
    else if (jobs.count > 1){
        XCTAssert([printOrder.paymentDescription hasSuffix:@"& More"]);
    }
    
    return printOrder;
}


- (void)submitStripeOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Print order submitted"];
    
    OLStripeCard *card = [[OLStripeCard alloc] init];
    card.number = @"4242424242424242";
    card.expireMonth = 12;
    card.expireYear = 2020;
    card.cvv2 = @"111";
    
    [printOrder costWithCompletionHandler:^(OLPrintOrderCost *cost, NSError *error){
        [card chargeCard:nil currencyCode:nil description:nil completionHandler:^(NSString *proofOfPayment, NSError *error){
            XCTAssert([[card numberMasked] isEqualToString:@"24242"]);
            printOrder.proofOfPayment = proofOfPayment;
            XCTAssert(!error, @"Stripe error: %@", error);
            [printOrder submitForPrintingWithCompletionHandler:^(NSString *orderIdReceipt, NSError *error){
                XCTAssert(!error, @"Failed to submit order to Kite with: %@", error);
                
                [printOrder saveToHistory];
                [expectation fulfill];
                if (handler) handler();
            }];
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
        XCTAssert(!error, @"Failed to get order cost with: %@", error);
        
        [card chargeCard:[cost totalCostInCurrency:printOrder.currencyCode] currencyCode:printOrder.currencyCode description:printOrder.paymentDescription completionHandler:^(NSString *proofOfPayment, NSError *error) {
            XCTAssert(!error, @"Failed to charge card with: %@", error);
            
            printOrder.proofOfPayment = proofOfPayment;
            [printOrder submitForPrintingWithCompletionHandler:^(NSString *orderIdReceipt, NSError *error) {
                XCTAssert(!error, @"Failed to submit order to Kite with: %@", error);
                
                [printOrder saveToHistory];
                [expectation fulfill];
                if (handler) handler();
            }];
        }];
    }];
}

#pragma mark Test cases

- (void)DISABLE_testSquaresOrderWithURLOLAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testMultipleJobsOrder{
    OLProductPrintJob *job1 = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    OLProductPrintJob *job2 = [OLPrintJob printJobWithTemplateId:@"magnets" OLAssets:[OLKiteTestHelper urlAssets]];
    [self submitJobs:@[job1, job2]];
}

- (void)DISABLE_testSquaresOrderWithImageOLAssets{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper imageAssets]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithJpgDataOLAssets{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLProductOrderTests class]] pathForResource:@"1" ofType:@"jpg"]];
    XCTAssert(data, @"No data");
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataAsJPEG:data]]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithPngDataOLAssets{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLProductOrderTests class]] pathForResource:@"2" ofType:@"png"]];
    XCTAssert(data, @"No data");
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithDataAsPNG:data]]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithImages{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLProductOrderTests class]] pathForResource:@"1" ofType:@"jpg"]];
    XCTAssert(data, @"No data");
    
    UIImage *image = [UIImage imageWithData:data];
    XCTAssert(image, @"No image");
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" images:@[image]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithFilePaths{
    NSString *path = [[NSBundle bundleForClass:[OLProductOrderTests class]] pathForResource:@"1" ofType:@"jpg"];
    XCTAssert(path, @"No path");
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" imageFilePaths:@[path]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithPHAssetOLAssets{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    XCTAssert(fetchResult.count > 0, @"There are no assets available");
    
    PHAsset *asset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithPHAsset:asset]]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithURLOLAssetPrintPhotos{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLKiteTestHelper urlAssets].firstObject]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithImageOLAssetPrintPhotos{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLKiteTestHelper imageAssets].firstObject]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithImageOLAssetPrintPhotoOLAsset{
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLKiteTestHelper imageAssets].firstObject]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testSquaresOrderWithPHAssetPrintPhotos{
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    XCTAssert(fetchResult.count > 0, @"There are no assets available");
    
    PHAsset *asset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
    
    OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithPHAsset:asset]]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testPhotobookOrderWithURLOLAssets{
    OLPhotobookPrintJob *job = [OLPrintJob photobookWithTemplateId:@"rpi_wrap_300x300_sm" OLAssets:[OLKiteTestHelper urlAssets] frontCoverOLAsset:[OLKiteTestHelper urlAssets].firstObject backCoverOLAsset:[OLKiteTestHelper urlAssets].lastObject];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testPostcardOrderWithURLOLAssets{
    id<OLPrintJob> job = [OLPrintJob postcardWithTemplateId:@"postcard" frontImageOLAsset:[OLKiteTestHelper urlAssets].firstObject backImageOLAsset:[OLKiteTestHelper urlAssets].lastObject];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testGreetingCardOrderWithURLOLAssets{
    id<OLPrintJob> job = [OLPrintJob greetingCardWithTemplateId:@"greeting_cards_a5" frontImageOLAsset:[OLKiteTestHelper urlAssets].firstObject backImageOLAsset:[OLKiteTestHelper urlAssets].lastObject insideRightImageAsset:[OLKiteTestHelper urlAssets][1] insideLeftImageAsset:[OLKiteTestHelper urlAssets][2]];
    [self submitJobs:@[job]];
}

- (void)DISABLE_testPDFOLAssetPhotobook{
    NSData *data1 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"3" ofType:@"pdf"]];
    
    OLPhotobookPrintJob *job = [OLPrintJob photobookWithTemplateId:@"rpi_wrap_300x300_sm" OLAssets:@[[OLAsset assetWithDataAsPDF:data1]] frontCoverOLAsset:nil backCoverOLAsset:nil];
    [self submitJobs:@[job]];
}


@end
