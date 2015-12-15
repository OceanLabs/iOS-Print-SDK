//
//  ViewControllerTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 13/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OLKitePrintSDK.h"
#import "OLProductHomeViewController.h"
#import "OLPhotoSelectionViewController.h"
#import "OLCustomNavigationController.h"
#import "OLKiteTestHelper.h"
#import "OLProductGroup.h"
#import "OLProductTypeSelectionViewController.h"
#import "NSObject+Utils.h"

@import Photos;

@interface ViewControllerTests : XCTestCase

@end

@interface OLPhotoSelectionViewController (Private)

-(void)onButtonNextClicked;

@end

@interface OLProductTypeSelectionViewController (Private)

-(NSMutableArray *) products;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface OLProductHomeViewController (Private)

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)productGroups;
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;

@end

@implementation ViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:kOLKitePrintSDKEnvironmentSandbox];
}

- (void)tearDown {
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [rootVc.presentedViewController dismissViewControllerAnimated:NO completion:NULL];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSInteger)findIndexForClass:(NSString *)class inOLProductHomeViewController:(OLProductHomeViewController *)vc{
    class = [class lowercaseString];
    for (NSInteger i = 0; i < vc.productGroups.count; i++) {
        OLProductGroup *group = vc.productGroups[i];
        if ([[group.templateClass lowercaseString] isEqualToString:class]){
            return i;
        }
    }
    XCTFail(@"No such product group");
    return -1;
}

- (NSInteger)findIndexForProductName:(NSString *)name inOLProductTypeSelectionViewController:(OLProductTypeSelectionViewController *)vc{
    name = [name lowercaseString];
    for (NSInteger i = 0; i < vc.products.count; i++) {
        OLProduct *product = vc.products[i];
        if ([[product.productTemplate.name lowercaseString] isEqualToString:name]){
            return i;
        }
    }
    XCTFail(@"No such product");
    return -1;
}

- (void)templateSyncWithSuccessHandler:(void(^)())handler{
    [OLProductTemplate syncWithCompletionHandler:^(NSArray <OLProductTemplate *>* _Nullable templates, NSError * _Nullable error){
        XCTAssert(!error, @"Template Sync Request failed with: %@", error);
        
        XCTAssert(templates.count > 0, @"Template Sync returned 0 templates. Maintenance mode?");
        
        if (handler) handler();
    }];
}

- (OLProductHomeViewController *)loadKiteViewController{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    
    __block OLProductHomeViewController *resultVc;
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[]];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    sleep(2);
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.topViewController isKindOfClass:[OLProductHomeViewController class]]){
                    resultVc = (OLProductHomeViewController *)nav.topViewController;
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show Product Home ViewController");
                }
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:NULL];
    return resultVc;
}

//- (void)testKiteViewControllerSyncsAndLoadsProductHome{
//    [self loadKiteViewController];
//}

- (void)chooseClass:(NSString *)class onOLProductHomeViewController:(OLProductHomeViewController *)productHome{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for vc push"];
    [productHome collectionView:productHome.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:[self findIndexForClass:class inOLProductHomeViewController:productHome] inSection:[productHome numberOfSectionsInCollectionView:productHome.collectionView]-1]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
}

- (void)chooseProduct:(NSString *)name onOLProductTypeSelectionViewController:(OLProductTypeSelectionViewController *)productTypeVc{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for vc push"];
    [productTypeVc collectionView:productTypeVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:[self findIndexForProductName:name inOLProductTypeSelectionViewController:productTypeVc] inSection:0]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
}

- (void)tapNextOnViewController:(UIViewController *)vc{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for vc push"];
    [vc.navigationItem.rightBarButtonItem.target safePerformSelector:vc.navigationItem.rightBarButtonItem.action withObject:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5 handler:NULL];
}

//- (void)testCompleteCaseJourney{
//    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
//    [self chooseClass:@"Snap Cases" onOLProductHomeViewController:productHomeVc];
//    
//    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
//    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
//
//    OLPrintPhoto *printPhoto = [[OLPrintPhoto alloc] init];
//    printPhoto.asset = [OLKiteTestHelper aPHAsset];
//    
//    productTypeVc.userSelectedPhotos = [@[printPhoto, [OLKiteTestHelper aPrintPhoto]] mutableCopy];
//    [self chooseProduct:@"iPhone 6" onOLProductTypeSelectionViewController:productTypeVc];
//    
//    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
//    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
//}

//- (void)testPhotoSelectionScreen{
//    NSData *data1 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"1" ofType:@"jpg"]];
//    NSData *data2 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"2" ofType:@"png"]];
//    
//    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
//    XCTAssert(fetchResult.count > 0, @"There are no assets available");
//    PHAsset *phAsset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
//    
//    NSArray *olAssets = @[
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
//                          [OLAsset assetWithDataAsJPEG:data1],
//                          [OLAsset assetWithDataAsPNG:data2],
//                          [OLAsset assetWithPHAsset:phAsset]
//                          ];
//    
//    NSMutableArray *printPhotos = [[NSMutableArray alloc] initWithCapacity:700];
//    for (int i = 0; i < 100; i++) {
//        for (OLAsset *asset in olAssets){
//            OLPrintPhoto *photo = [[OLPrintPhoto alloc] init];
//            photo.asset = asset;
//            [printPhotos addObject:photo];
//        }
//    }
//    
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Template Sync Completed"];
//    [self templateSyncWithSuccessHandler:^{
//        OLProduct *product = [OLProduct productWithTemplateId:@"squares"];
//        
//        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLPhotoSelectionViewController class]]];
//        XCTAssert(sb);
//        
//        OLPhotoSelectionViewController *vc = [sb instantiateViewControllerWithIdentifier:@"PhotoSelectionViewController"];
//        XCTAssert(vc);
//        
//        vc.product = product;
//        vc.userSelectedPhotos = printPhotos;
//        
//        OLCustomNavigationController *nvc = [[OLCustomNavigationController alloc] initWithRootViewController:vc];
//        
//        UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
//        
//        [rootVc.topViewController presentViewController:nvc animated:YES completion:^{
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                    [vc onButtonNextClicked];
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                        [expectation fulfill];
//                    });
//                    //
//                });
//                
//            });
//        }];
//        
//        
//        
//    }];
//    [self waitForExpectationsWithTimeout:60 handler:NULL];
//}

@end
