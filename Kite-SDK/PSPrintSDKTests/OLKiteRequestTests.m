//
//  OLKiteRequestTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 08/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLKitePrintSDK.h"
#import "OLKiteTestHelper.h"

@interface OLKiteRequestTests : XCTestCase <OLAssetUploadRequestDelegate>

@property (strong, nonatomic) XCTestExpectation *expectation;
@property (assign, nonatomic) BOOL shouldFail;

@end

@implementation OLKiteRequestTests

- (void)setUp {
    [super setUp];
    self.shouldFail = NO;
}

- (void)tearDown {
    // Put teardown code here. This metho is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didSucceedWithAssets:(NSArray<OLAsset *> *)assets{
    [self.expectation fulfill];
    
    for (OLAsset *asset in assets){
            XCTAssert([asset isUploaded], @"Asset not really uploaded");
            XCTAssert([asset assetId], @"Invalid Asset ID");
    }
}

- (void)assetUploadRequest:(OLAssetUploadRequest *)req didFailWithError:(NSError *)error{
    if (!self.shouldFail){
        XCTFail(@"Failed to upload asset");
    }
    else{
        [self.expectation fulfill];
    }
}

- (void)testImageUpload{
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKiteSDKEnvironmentSandbox];
    self.expectation = [self expectationWithDescription:@"Upload photo Completed"];
    
    OLAssetUploadRequest *req = [[OLAssetUploadRequest alloc] init];
    req.delegate = self;
    [req uploadImageAsJPEG:[UIImage imageWithData:[OLKiteTestHelper testImageData]]];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testOLAssetsUpload{
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKiteSDKEnvironmentSandbox];
    self.expectation = [self expectationWithDescription:@"Upload OLAssets Completed"];
    
    OLAssetUploadRequest *req = [[OLAssetUploadRequest alloc] init];
    req.delegate = self;
    [req uploadOLAssets:[OLKiteTestHelper imageAssets]];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testFailedOLAssetsUpload{
    self.shouldFail = YES;
    self.expectation = [self expectationWithDescription:@"Upload OLAssets Completed"];
    
    OLAssetUploadRequest *req = [[OLAssetUploadRequest alloc] init];
    req.delegate = self;
    [req uploadOLAssets:[OLKiteTestHelper imageAssets]];
    
    [self waitForExpectationsWithTimeout:60 handler:nil];
}

- (void)testCancelAssetUpload{
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKiteSDKEnvironmentSandbox];
    OLAssetUploadRequest *req = [[OLAssetUploadRequest alloc] init];
    req.delegate = self;
    [req uploadOLAssets:[OLKiteTestHelper imageAssets]];
    
    [req cancelUpload];
}

@end
