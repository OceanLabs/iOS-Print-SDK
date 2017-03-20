//
//  CompleteJourneyTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 24/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+OLUITestMethods.h"

@interface CompleteJourneyTests : XCTestCase

@end

@implementation CompleteJourneyTests

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

- (void)testCompletePhotobookJourney{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [self chooseClass:@"Photo Books" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Small Square Hardcover" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLEditPhotobookViewController *photobookEditVc = (OLEditPhotobookViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photobookEditVc isKindOfClass:[OLEditPhotobookViewController class]]);
    
    OLPhotobookViewController *photobook = photobookEditVc.childViewControllers[1];
    OLTestTapGestureRecognizer *tap = [[OLTestTapGestureRecognizer alloc] init];
    tap.customLocationInView = CGPointMake(100, 100);
    
    [self performUIAction:^{
        [photobook onTapGestureRecognized:tap];
    }];
    [self performUIAction:^{
        [photobook onTapGestureRecognized:tap];
    }];
    [self performUIAction:^{
        [photobook onTapGestureRecognized:tap];
    }];
    
    tap.customLocationInView = CGPointMake(photobook.view.frame.size.width-100, 100);
    [self performUIAction:^{
        [photobook onTapGestureRecognized:tap];
    }];
    
    tap.customLocationInView = CGPointMake(100, 100);
    
    [self performUIAction:^{
        [photobook onTapGestureRecognized:tap];
    }];
    
    [self performUIAction:^{
        [photobookEditVc editImage];
    }];
    
    OLImageEditViewController *editor = (OLImageEditViewController *)photobook.presentedViewController;
    
    [self performUIAction:^{
        [editor.editingTools.button1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    OLImagePickerViewController *picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editor onButtonDoneTapped:nil];
    }];
    
    [self tapNextOnViewController:photobookEditVc];
    
    photobook = (OLPhotobookViewController *)productHomeVc.navigationController.topViewController;
    
    [self performUIAction:^{
        [photobook openBook:nil];
    }];
    
    OLMockPanGestureRecognizer *leftPan = [[OLMockPanGestureRecognizer alloc] init];
    leftPan.mockTranslation = CGPointMake(-200, 0);
    
    OLMockPanGestureRecognizer *rightPan = [[OLMockPanGestureRecognizer alloc] init];
    rightPan.mockTranslation = CGPointMake(200, 0);
    
    [self performUIAction:^{
        [photobook closeBookBackForGesture:leftPan];
    }];
    
    [self performUIAction:^{
        [photobook openBook:rightPan];
    }];
    
    [self performUIAction:^{
        [photobook closeBookFrontForGesture:rightPan];
    }];
    
    [self performUIAction:^{
        [photobook openBook:leftPan];
    }];
    
    [self performUIAction:^{
        if ([photobook gestureRecognizerShouldBegin:leftPan]){
            [photobook onPanGestureRecognized:leftPan];
        }
    }];
    
    leftPan.mockState = UIGestureRecognizerStateEnded;
    leftPan.mockVelocity = CGPointMake(-100, 0);
    [self performUIAction:^{
        [photobook onPanGestureRecognized:leftPan];
    }];
    
    [self performUIAction:^{
        tap.customLocationInView = CGPointMake(photobook.view.frame.size.width-100, 100);
        [photobook onTapGestureRecognized:tap];
    }];
    
    editor = (OLImageEditViewController *)photobook.presentedViewController;
    
    [self performUIAction:^{
        [editor.editingTools.button1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editor onButtonDoneTapped:nil];
    }];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    UITableViewCell *cell = [paymentVc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self performUIAction:^{
        [(UIButton *)[cell viewWithTag:61] sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    UIViewController *presentedNav = paymentVc.presentedViewController;
    XCTAssert([presentedNav isKindOfClass:[OLNavigationController class]], @"Did not present navigation vc");
    UIViewController *presentedVc = [(OLNavigationController *)presentedNav topViewController];
    XCTAssert([presentedVc isKindOfClass:[OLEditPhotobookViewController class]], @"Did not present editing vc");
    
    [self performUIActionWithDelay:3 action:^{
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft]
                                    forKey:@"orientation"];
    }];
    
    [self performUIActionWithDelay:3 action:^{
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                    forKey:@"orientation"];
    }];
    
    [self tapNextOnViewController:presentedVc];
    presentedVc = [(OLNavigationController *)presentedNav topViewController];
    XCTAssert([presentedVc isKindOfClass:[OLPhotobookViewController class]], @"Did not proceed to photobook vc");
    
    [self performUIActionWithDelay:3 action:^{
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationLandscapeLeft]
                                    forKey:@"orientation"];
    }];
    
    [self performUIActionWithDelay:3 action:^{
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                    forKey:@"orientation"];
    }];
    
    [self performUIAction:^{
        [(OLPhotobookViewController *)presentedVc onCoverTapRecognized:nil];
    }];
    
    [self performUIAction:^{
        [presentedVc.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    [(OLPhotobookViewController *)presentedVc setCoverPhoto:nil];
    
    [self performUIAction:^{
        [(OLPhotobookViewController *)presentedVc onCoverTapRecognized:nil];
    }];
    
    [self tapNextOnViewController:presentedVc];
    XCTAssert(!paymentVc.presentedViewController, @"Did not dismiss photobook screen");
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:240 handler:NULL];
}

- (void)testCompleteCaseJourney{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"Snap Cases" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"iPhone 6s" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLCaseViewController *caseVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([caseVc isKindOfClass:[OLCaseViewController class]]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for case mask to download"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!caseVc.cropView.image || !caseVc.downloadedMask){
            sleep(3);
        }
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    XCTAssert([[caseVc product].selectedOptions[(NSString *)[[caseVc product].productTemplate.options.firstObject code]] isEqualToString:(NSString *)[[[[caseVc product].productTemplate.options.firstObject choices] firstObject] code]], @"Default option not set");
    
    [self performUIAction:^{
        [caseVc.editingTools.button2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    XCTAssert([caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].isSelected, @"Default option (first) should selected");
    
    [self performUIAction:^{
        [caseVc collectionView:caseVc.editingTools.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    }];
    XCTAssert([caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].isSelected, @"Second option should be selected");
    
    XCTAssert([[caseVc product].selectedOptions[(NSString *)[[caseVc product].productTemplate.options.firstObject code]] isEqualToString:(NSString *)[[[[caseVc product].productTemplate.options.firstObject choices] lastObject] code]], @"Second option not set");
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:caseVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    XCTAssert([printOrder isSavedInHistory], @"Print order is not saved in history");
    
    [printOrder deleteFromHistory];
    XCTAssert(![printOrder isSavedInHistory], @"Print order was not deleted from history");
    
}

- (void)DISABLED_testCompleteMugJourney{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"Mugs" onOLProductHomeViewController:productHomeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OL3DProductViewController *reviewVc = (OL3DProductViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OL3DProductViewController class]]);
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for render"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
}

- (void)testCompleteApparelJourney{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"Apparel" onOLProductHomeViewController:productHomeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLCaseViewController *caseVc = (OLCaseViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([caseVc isKindOfClass:[OLCaseViewController class]]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for case mask to download"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!caseVc.cropView.image || !caseVc.downloadedMask){
            sleep(3);
        }
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    
    XCTAssert(![caseVc product].selectedOptions[(NSString *)[[caseVc product].productTemplate.options.firstObject code]] , @"Default option should not set");
    
    [self performUIAction:^{
        [caseVc.editingTools.button2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    XCTAssert(![caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].isSelected, @"Default option (first) should not be selected");
    
    [self performUIAction:^{
        [caseVc collectionView:caseVc.editingTools.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    }];
    XCTAssert([caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].isSelected, @"Second option should be selected");
    
    XCTAssert([[caseVc product].selectedOptions[(NSString *)[[caseVc product].productTemplate.options.firstObject code]] isEqualToString:(NSString *)[[[[caseVc product].productTemplate.options.firstObject choices] objectAtIndex:1] code]], @"Second option not set");
    
    //Wait for the overlay to finish rendering. Can be slow in simulators.
    expectation = [self expectationWithDescription:@"Wait for Payment VC"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self performUIAction:^{
        [caseVc onButtonCropClicked:nil];
    }];
    
    [self performUIAction:^{
        [caseVc exitCropMode];
    }];
    
    if (caseVc.productFlipButton){
        [self performUIAction:^{
            [caseVc onButtonProductFlipClicked:nil];
        }];
    }
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:caseVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    XCTAssert([printOrder isSavedInHistory], @"Print order is not saved in history");
    
    [printOrder deleteFromHistory];
    XCTAssert(![printOrder isSavedInHistory], @"Print order was not deleted from history");
    
}

- (void)testCompletePrintsJourney{
    NSData *data1 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"1" ofType:@"jpg"]];
    NSData *data2 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"2" ofType:@"png"]];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    XCTAssert(fetchResult.count > 0, @"There are no assets available");
    PHAsset *phAsset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
    
    NSArray *olAssets = @[
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [OLUserSession currentSession].appAssets = [olAssets mutableCopy];
    [[OLUserSession currentSession] resetUserSelectedPhotos];
    
    [self chooseClass:@"Prints" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Squares" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    OLPackProductViewController *reviewVc = (OLPackProductViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLPackProductViewController class]]);
    
    UICollectionViewCell *cell = [reviewVc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    UIButton *button = [cell viewWithTag:12];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    button = [cell viewWithTag:13];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self performUIAction:^{
        [reviewVc dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    [self performUIAction:^{
        NSIndexPath* indexPath = [reviewVc.collectionView indexPathForCell:(UICollectionViewCell *)cell];
        [reviewVc deletePhotoAtIndex:indexPath.item];
    }];
    
    button = [cell viewWithTag:11];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    XCTAssert([reviewVc.presentedViewController isKindOfClass:[OLImageEditViewController class]], @"Did not show crop screen");
    
    OLImageEditViewController *editor = (OLImageEditViewController *)reviewVc.presentedViewController;
    
    [self performUIAction:^{
        [editor.editingTools.button1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    OLImagePickerViewController *picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editor onButtonDoneTapped:nil];
    }];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
}

- (void)testCompleteFramesJourney{
    NSData *data1 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"1" ofType:@"jpg"]];
    NSData *data2 = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[OLKiteTestHelper class]] pathForResource:@"2" ofType:@"png"]];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    XCTAssert(fetchResult.count > 0, @"There are no assets available");
    PHAsset *phAsset = [fetchResult objectAtIndex:arc4random() % fetchResult.count];
    
    NSArray *olAssets = @[
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]],
//                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [OLUserSession currentSession].appAssets = [olAssets mutableCopy];
    [[OLUserSession currentSession] resetUserSelectedPhotos];
    
    [self chooseClass:@"Magnet Wall Frames" onOLProductHomeViewController:productHomeVc];
    
//    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
//    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
//    
//    [self chooseProduct:@"Frames 50cm (2x2)" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    OLFrameOrderReviewViewController *reviewVc = (OLFrameOrderReviewViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLFrameOrderReviewViewController class]]);
    
    UICollectionViewCell *outerCollectionViewCell = [reviewVc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:110];
    
    [self performUIAction:^{
        OLTestTapGestureRecognizer *tap = [[OLTestTapGestureRecognizer alloc] init];
        tap.customLocationInView = [reviewVc.collectionView convertPoint:CGPointMake(10, 10) fromView:imageView];
        
        [reviewVc onTapGestureThumbnailTapped:tap];
    }];
    
    OLImageEditViewController *editor = (OLImageEditViewController *)reviewVc.presentedViewController;
    
    [self performUIAction:^{
        [editor.editingTools.button1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    OLImagePickerViewController *picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editor onButtonDoneTapped:nil];
    }];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
}

- (void)testCompleteAccessoryOrder{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"New and Extras" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Speech Bubble Magnets" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
}

- (void)testCompletePosterJourney{
    NSArray *urls = @[@"https://s3.amazonaws.com/psps/sdk_static/1.jpg", @"https://s3.amazonaws.com/psps/sdk_static/2.jpg", @"https://s3.amazonaws.com/psps/sdk_static/3.jpg", @"https://s3.amazonaws.com/psps/sdk_static/4.jpg", @"https://s3.amazonaws.com/psps/sdk_static/5.jpg", @"https://s3.amazonaws.com/psps/sdk_static/6.jpg", @"https://s3.amazonaws.com/psps/sdk_static/7.jpg", @"https://s3.amazonaws.com/psps/sdk_static/8.jpg", @"https://s3.amazonaws.com/psps/sdk_static/9.jpg", @"https://s3.amazonaws.com/psps/sdk_static/10.jpg", @"https://s3.amazonaws.com/psps/sdk_static/11.jpg", @"https://s3.amazonaws.com/psps/sdk_static/12.jpg", @"https://s3.amazonaws.com/psps/sdk_static/13.jpg", @"https://s3.amazonaws.com/psps/sdk_static/14.jpg", @"https://s3.amazonaws.com/psps/sdk_static/15.jpg", @"https://s3.amazonaws.com/psps/sdk_static/16.jpg", @"https://s3.amazonaws.com/psps/sdk_static/17.jpg", @"https://s3.amazonaws.com/psps/sdk_static/18.jpg", @"https://s3.amazonaws.com/psps/sdk_static/19.jpg", @"https://s3.amazonaws.com/psps/sdk_static/20.jpg", @"https://s3.amazonaws.com/psps/sdk_static/21.jpg", @"https://s3.amazonaws.com/psps/sdk_static/22.jpg", @"https://s3.amazonaws.com/psps/sdk_static/23.jpg", @"https://s3.amazonaws.com/psps/sdk_static/24.jpg", @"https://s3.amazonaws.com/psps/sdk_static/25.jpg", @"https://s3.amazonaws.com/psps/sdk_static/26.jpg", @"https://s3.amazonaws.com/psps/sdk_static/27.jpg", @"https://s3.amazonaws.com/psps/sdk_static/28.jpg", @"https://s3.amazonaws.com/psps/sdk_static/29.jpg", @"https://s3.amazonaws.com/psps/sdk_static/30.jpg", @"https://s3.amazonaws.com/psps/sdk_static/31.jpg", @"https://s3.amazonaws.com/psps/sdk_static/32.jpg", @"https://s3.amazonaws.com/psps/sdk_static/33.jpg", @"https://s3.amazonaws.com/psps/sdk_static/34.jpg", @"https://s3.amazonaws.com/psps/sdk_static/35.jpg"];
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (NSString *s in urls){
        OLAsset *asset = [OLAsset assetWithURL:[NSURL URLWithString:s]];
        [assets addObject:asset];
    }
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [OLUserSession currentSession].userSelectedPhotos = [assets mutableCopy];
    
    [self chooseClass:@"Posters" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Poster" onOLProductTypeSelectionViewController:productTypeVc];
    
    productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Poster" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    OLPosterViewController *reviewVc = (OLPosterViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLPosterViewController class]]);
    
    UICollectionViewCell *outerCollectionViewCell = [reviewVc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    UICollectionView* collectionView = (UICollectionView*)[outerCollectionViewCell.contentView viewWithTag:20];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:795];
    
    [self performUIAction:^{
        OLTestTapGestureRecognizer *tap = [[OLTestTapGestureRecognizer alloc] init];
        tap.customLocationInView = [reviewVc.collectionView convertPoint:CGPointMake(10, 10) fromView:imageView];
        
        [reviewVc editPhoto:tap];
    }];
    
    OLImageEditViewController *editor = (OLImageEditViewController *)reviewVc.presentedViewController;
    
    [self performUIAction:^{
        [editor.editingTools.button1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    OLImagePickerViewController *picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editor onButtonDoneTapped:nil];
    }];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [self performUIAction:^{
        [paymentVc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)paymentVc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    if (![creditCardVc isKindOfClass:[OLCreditCardCaptureRootController class]]){
        UIGraphicsBeginImageContextWithOptions(creditCardVc.view.bounds.size, NO, 0.0);
        [[creditCardVc.view layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *ViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *pngData = UIImagePNGRepresentation(ViewImage);
        [pngData writeToFile:@"/Users/distiller/image.png" atomically:NO];
    }
    XCTAssert([creditCardVc isKindOfClass:[OLCreditCardCaptureViewController class]], @"Got %@", [creditCardVc class]);
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [self performUIAction:^{
        [creditCardVc.rootVC onButtonPayClicked];
    }];
    
    [paymentVc onButtonPayClicked:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:240 handler:NULL];
}

@end
