//
//  UpsellTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 24/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+OLUITestMethods.h"

@interface UpsellTests : XCTestCase

@end

@implementation UpsellTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [self setUpHelper];
}

- (void)tearDown {
    [self tearDownHelper];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPrintsUpsellDecline{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Prints" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Mini Squares" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)photoVc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc declineButtonAction:nil];
    }];
    
    OLPackProductViewController *reviewVc = (OLPackProductViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLPackProductViewController class]], @"Did not proceed to review");
}

- (void)testPrintsUpsellAccept{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Prints" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Mini Squares" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)photoVc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc acceptButtonAction:nil];
    }];
    
    OLImagePickerViewController *photoVc2 = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc2 isKindOfClass:[OLImagePickerViewController class]] && photoVc != photoVc2, @"Did not proceed to another image picker");
}

- (void)testCaseUpsellDecline{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Snap Cases" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"iPhone 6" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLCaseViewController *photoVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLCaseViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    photoVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLCaseViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)photoVc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc declineButtonAction:nil];
    }];
    
    OLPaymentViewController *reviewVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLPaymentViewController class]], @"Did not proceed to payment");
}


- (void)testCaseUpsellAccept{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Snap Cases" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"iPhone 6" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLCaseViewController *photoVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLCaseViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    photoVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLCaseViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)photoVc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc acceptButtonAction:nil];
    }];
    
    OLCaseViewController *photoVc2 = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc2 isKindOfClass:[OLCaseViewController class]] && photoVc != photoVc2, @"Did not proceed to another phone");
}

- (void)testPhotobookUpsellDecline{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Photo Books" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Medium Square Hardcover" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    UIViewController *vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLEditPhotobookViewController class]]);
    
    [self tapNextOnViewController:vc];
    
    vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLPhotobookViewController class]]);
    
    [self tapNextOnViewController:vc];
    
    vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLPhotobookViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)vc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc declineButtonAction:nil];
    }];
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]], @"Did not proceed to review");
}

- (void)testPhotobookUpsellAccept{
    [OLKiteTestHelper mockTemplateRequest];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [OLKiteTestHelper undoMockTemplateRequest];
    
    [self chooseClass:@"Photo Books" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Medium Square Hardcover" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    UIViewController *vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLEditPhotobookViewController class]]);
    
    [self tapNextOnViewController:vc];
    
    vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLPhotobookViewController class]]);
    
    [self tapNextOnViewController:vc];
    
    vc = productHomeVc.navigationController.topViewController;
    XCTAssert([vc isKindOfClass:[OLPhotobookViewController class]], @"Should not have proceeded");
    
    OLUpsellViewController *upsellVc = (OLUpsellViewController *)vc.presentedViewController;
    XCTAssert([upsellVc isKindOfClass:[OLUpsellViewController class]], @"Did not show upsell");
    
    [self performUIActionWithDelay:5 action:^{
        [upsellVc acceptButtonAction:nil];
    }];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]] && vc != photoVc, @"Did not proceed to another image picker");
}

@end
