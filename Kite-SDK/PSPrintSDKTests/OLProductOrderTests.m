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
#import <Stripe.h>
#import <SDWebImage/SDWebImageManager.h>

@interface OLKitePrintSDK (PrivateMethods)

+ (NSString *_Nonnull)stripePublishableKey;

@end

@interface OLProductOrderTests : XCTestCase

@property (strong, nonatomic) XCTestExpectation *expectation;

@end

@implementation OLProductOrderTests

- (void)setUp {
    [super setUp];
    self.expectation = [self expectationWithDescription:@"Print order submitted"];
    
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSArray *)urlAssets{
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]];
    return assets;
}

- (void)submitOrder:(OLPrintOrder *)printOrder WithSuccessHandler:(void(^)())handler{
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
            handler();
        }];
    }];
}

- (void)templateSyncWithSuccessHandler:(void(^)())handler{
    [OLProductTemplate syncWithCompletionHandler:^(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error){
        if (error){
            XCTFail(@"Template Sync Request failed with: %@", error);
        }
        if ([templates count] == 0){
            XCTFail(@"Template Sync returned 0 templates. Maintenance mode?");
        }
        
        handler();
    }];
}

- (void)testSquaresOrderWithURLAssets{
    [self templateSyncWithSuccessHandler:^{
        OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[self urlAssets]];
        OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
        printOrder.shippingAddress = [OLAddress kiteTeamAddress];
        [printOrder addPrintJob:job];
        
        [self submitOrder:printOrder WithSuccessHandler:^{
            [self.expectation fulfill];
        }];
        
    }];

    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testSquaresOrderWithImageAsset{
    [self templateSyncWithSuccessHandler:^{
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"] options:0 progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL){
            OLProductPrintJob *job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:@[[OLAsset assetWithImageAsJPEG:image]]];
            OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
            printOrder.shippingAddress = [OLAddress kiteTeamAddress];
            [printOrder addPrintJob:job];
            
            [self submitOrder:printOrder WithSuccessHandler:^{
                [self.expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

@end
