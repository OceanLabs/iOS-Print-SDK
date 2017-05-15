//
//  ViewControllerTests.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 13/10/15.
//  Copyright © 2015 Kite.ly. All rights reserved.
//
#import "XCTestCase+OLUITestMethods.h"

@import Photos;

@interface ViewControllerTests : XCTestCase
@property (strong, nonatomic) NSString *kvoValueToObserve;
@property (copy, nonatomic) void (^kvoBlockToExecute)();
@property (weak, nonatomic) id kvoObjectToObserve;
@end

@implementation ViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [self setUpHelper];
}

- (void)tearDown {
    if (self.kvoValueToObserve){
        [[OLKiteABTesting sharedInstance] removeObserver:self forKeyPath:self.kvoValueToObserve];
        self.kvoValueToObserve = nil;
    }
    [self tearDownHelper];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)kvoObserveObject:(id)object forValue:(NSString *)value andExecuteBlock:(void(^)())block{
    self.kvoObjectToObserve = object;
    self.kvoValueToObserve = value;
    self.kvoBlockToExecute = block;
    [self.kvoObjectToObserve addObserver:self forKeyPath:self.kvoValueToObserve options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:self.kvoValueToObserve]){
        [self.kvoObjectToObserve removeObserver:self forKeyPath:self.kvoValueToObserve];
        self.kvoBlockToExecute();
        [self.kvoObjectToObserve addObserver:self forKeyPath:self.kvoValueToObserve options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)testQRCodeViewController{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLKiteViewController class]]];
    XCTAssert(sb);
    OLQRCodeUploadViewController *vc = (OLQRCodeUploadViewController *) [sb instantiateViewControllerWithIdentifier:@"OLQRCodeUploadViewController"];
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [self performUIAction:^{
        [rootVc presentViewController:nvc animated:YES completion:nil];
    }];
    
    [self performUIAction:^{
        [vc onBarButtonItemCancelTapped:nil];
    }];
}

- (void)testProductDescriptionDrawer{
    OLProduct *product = [OLProduct productWithTemplateId:@"squares"];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLKiteViewController class]]];
    XCTAssert(sb);
    
    OLProductOverviewViewController *vc = [sb instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
    XCTAssert(vc);

    vc.product = product;
    
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];

    [self performUIAction:^{
        [vc onLabelDetailsTapped:nil];
    }];
    
    [self performUIAction:^{
        [vc onLabelDetailsTapped:nil];
    }];
}

- (void)testInfoPageViewController{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"qualityBannerType" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].qualityBannerType = @"A";
    }];
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [self performUIAction:^{
        [productHomeVc collectionView:productHomeVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    XCTAssert([productHomeVc.navigationController.topViewController isKindOfClass:[OLInfoPageViewController class]], @"Not showing info page");
    
    [self performUIAction:^{
        [productHomeVc.navigationController popViewControllerAnimated:YES];
    }];
    
    [[OLUserSession currentSession].kiteVc dismiss];
}

- (void)testAddressEditViewController{
    OLAddressEditViewController *vc = [[OLAddressEditViewController alloc] initWithAddress:[OLAddress kiteTeamAddress]];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:vc animated:YES completion:NULL];
    }];
    
}

- (void)testAddressSelection{
    OLAddressSelectionViewController *vc = [[OLAddressSelectionViewController alloc] init];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:vc animated:YES completion:NULL];
    }];
}

- (void)testAddressSearch{
    OLAddressLookupViewController *vc = [[OLAddressLookupViewController alloc] init];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
    }];
    
    vc.searchController.searchBar.text = @"457 Finchley Road, NW3 6HN, London";
    
    [self performUIActionWithDelay:5 action:^{
        [vc updateSearchResultsForSearchController:vc.searchController];
    }];
}


- (void)testImagePickerViewController{
    [[OLUserSession currentSession] logoutOfInstagram];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Template Sync Completed"];
    [self templateSyncWithSuccessHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    OLProduct *product = [OLProduct productWithTemplateId:@"squares"];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLKiteViewController class]]];
    XCTAssert(sb);
    OLImagePickerViewController *vc = [sb instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.product = product;
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];
    
    XCTAssert([[(UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController.presentedViewController topViewController] isKindOfClass:[OLImagePickerViewController class]]);
    
    OLImagePickerPhotosPageViewController *photosPage = (OLImagePickerPhotosPageViewController *)vc.pageController.viewControllers.firstObject;
    
    [self performUIActionWithDelay:5 action:^{
        [photosPage collectionView:photosPage.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    [self performUIAction:^{
        [photosPage userDidTapOnAlbumLabel:nil];
    }];
    
    [self performUIAction:^{
        [photosPage collectionView:photosPage.albumsCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    [self performUIAction:^{
        [vc collectionView:vc.sourcesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
    }];
    
    photosPage = (OLImagePickerPhotosPageViewController *)vc.pageController.viewControllers.firstObject;
    
    XCTAssert([photosPage isKindOfClass:[OLImagePickerLoginPageViewController class]], @"");
    
    [self performUIAction:^{
        [(OLImagePickerLoginPageViewController *)photosPage onButtonLoginTapped:nil];
    }];
    
    [self performUIAction:^{
        [rootVc.topViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
}

- (void)testPaymentViewController{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Template Sync Completed"];
    [self templateSyncWithSuccessHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    XCTAssert([printOrder.shippingAddress.description isEqualToString:@"Kite Team, Eastcastle House, 27-28 Eastcastle St, London, W1W 8DH, United Kingdom"]);
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLKiteViewController class]]];
    XCTAssert(sb);
    
    OLPaymentViewController *vc = [sb instantiateViewControllerWithIdentifier:@"OLPaymentViewController"];
    vc.printOrder = printOrder;
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];
    
    [self performUIAction:^{
        [vc.promoCodeTextField becomeFirstResponder];
        vc.promoCodeTextField.text = @"unit-test-promo-code-2014";
    }];
    
    [self performUIAction:^{
        [vc onBackgroundClicked];
    }];
    
    [self performUIAction:^{
    }];
    
    [self performUIAction:^{
        [vc onShippingDetailsGestureRecognized:nil];
    }];
    
    XCTAssert([[(OLNavigationController *)vc.navigationController topViewController] isKindOfClass:[OLCheckoutViewController class]] ,@"");
    
    [self performUIAction:^{
        [(OLNavigationController *)vc.navigationController popViewControllerAnimated:YES];
    }];
    
    [self performUIAction:^{
        [vc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)vc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
        
        [paymentMethodsVc.navigationController popViewControllerAnimated:YES];
    }];
    
    [self performUIAction:^{
        [vc onButtonPayClicked:nil];
    }];
    
    [self performUIActionWithDelay:3 action:^{
        [vc.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    UITableViewCell *cell =  [vc.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    [self performUIAction:^{
        UIButton *plusButton = [cell.contentView viewWithTag:40];
        [plusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        XCTAssert([job extraCopies] == 1);
    }];
    
    [self performUIAction:^{
        UIButton *minusButton = [cell.contentView viewWithTag:10];
        [minusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        XCTAssert([job extraCopies] == 0);
    }];
    
    [self performUIAction:^{
        UIButton *largeEditButton = (UIButton *)[cell.contentView viewWithTag:61];
        [largeEditButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    UINavigationController *presentedNav = (UINavigationController *)vc.presentedViewController;
    [self tapNextOnViewController:presentedNav.topViewController];
    [self tapNextOnViewController:presentedNav.topViewController];
    
    [self performUIAction:^{
        [vc onButtonAddPaymentMethodClicked:nil];
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)vc.navigationController topViewController];
        XCTAssert([paymentMethodsVc isKindOfClass:[OLPaymentMethodsViewController class]], @"Did not show Payment Methods ViewController");
        
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:2]];
        
        [paymentMethodsVc.navigationController popViewControllerAnimated:YES];
    }];
    
    [self performUIAction:^{
        [vc onButtonPayClicked:nil];
    }];
    
    [self performUIAction:^{
        [vc payPalPaymentDidCancel:vc.presentedViewController];
    }];
    
    [self performUIAction:^{
        UIButton *minusButton = [cell.contentView viewWithTag:10];
        [minusButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        XCTAssert([job extraCopies] == 0);
    }];
    
    [self performUIAction:^{
        [vc.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    XCTAssert([[(OLNavigationController *)vc.navigationController topViewController] isKindOfClass:[OLPaymentViewController class]]);
}

- (void)testStartWithPrintOrderVariantCheckout{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
       [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Checkout";
    }];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.parentViewController isKindOfClass:[OLKiteViewController class]]){
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show KiteViewController");
                }
            });
            
        });
    }];

    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    XCTAssert([nav.topViewController isKindOfClass:[OLPaymentViewController class]], @"Not showing payment vc");
}

- (void)testStartWithPrintOrderVariantOverviewReviewCheckout{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Overview-Review-Checkout";
    }];
    
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
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:olAssets];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.parentViewController isKindOfClass:[OLKiteViewController class]]){
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show KiteViewController");
                }
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    XCTAssert([nav.topViewController isKindOfClass:[OLProductOverviewViewController class]], @"Not showing Overview vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLImagePickerViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPackProductViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPaymentViewController class]], @"Not showing payment vc");
}

- (void)testStartWithPrintOrderVariantReviewCheckout{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Review-Checkout";
    }];
    
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
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:olAssets];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.parentViewController isKindOfClass:[OLKiteViewController class]]){
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show KiteViewController");
                }
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    XCTAssert([nav.topViewController isKindOfClass:[OLImagePickerViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPackProductViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPaymentViewController class]], @"Not showing payment vc");
}

- (void)testStartWithPrintOrderVariantOverviewCheckout{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Overview-Checkout";
    }];
    
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
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:olAssets];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.parentViewController isKindOfClass:[OLKiteViewController class]]){
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show KiteViewController");
                }
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    XCTAssert([nav.topViewController isKindOfClass:[OLProductOverviewViewController class]], @"Not showing Overview vc, but: %@", [nav.topViewController class]);
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPaymentViewController class]], @"Not showing payment vc");
}

- (void)testStartWithPrintOrderVariantReviewOverviewCheckout{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Review-Overview-Checkout";
    }];
    
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
                          [OLAsset assetWithDataAsJPEG:data1],
                          [OLAsset assetWithDataAsPNG:data2],
                          [OLAsset assetWithPHAsset:phAsset]
                          ];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:olAssets];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                if ([nav.parentViewController isKindOfClass:[OLKiteViewController class]]){
                    [expectation fulfill];
                }
                else{
                    XCTFail(@"Did not show KiteViewController");
                }
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    XCTAssert([nav.topViewController isKindOfClass:[OLImagePickerViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPackProductViewController class]], @"Not showing Review vc");
    
    [self tapNextOnViewController:nav.topViewController];
    
    XCTAssert([nav.topViewController isKindOfClass:[OLProductOverviewViewController class]], @"Not showing Overview vc, but: %@", [nav.topViewController class]);
    
    [self tapNextOnViewController:nav.topViewController];
    XCTAssert([nav.topViewController isKindOfClass:[OLPaymentViewController class]], @"Not showing payment vc");
}

- (void)testImageEditor{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"promoBannerText" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].promoBannerText = @"<header>Hello Inspector!</header><para>This message will self-destruct in [[2115-08-04 18:05 GMT+3]]</para>";
    }];
    
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    NSArray *olAssets = [[OLAsset userSelectedAssets] subarrayWithRange:NSMakeRange(0, 11)];
    
    [OLUserSession currentSession].appAssets = [olAssets mutableCopy];
    [[OLUserSession currentSession] resetUserSelectedPhotos];
    
    [self chooseClass:@"Stickers" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Circle Stickers" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    OLPackProductViewController *reviewVc = (OLPackProductViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLPackProductViewController class]]);
    
    UICollectionViewCell *cell = [reviewVc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    UIButton *button = [cell viewWithTag:11];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    OLImageEditViewController *editVc = (OLImageEditViewController *)reviewVc.presentedViewController;
    XCTAssert([editVc isKindOfClass:[OLImageEditViewController class]], @"Did not show edit screen");
    
    [self performUIAction:^{
        [editVc.editingTools.button4 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    XCTAssert(editVc.editingTools.collectionView.tag == 40/*kOLEditTagCrop*/, @"Crop mode not shown");
    
    [self performUIAction:^{
        [editVc.editingTools.drawerDoneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self performUIAction:^{
        [editVc.editingTools.button3 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 30/*kOLEditTagImageTools*/, @"Image Tools not shown");
    
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 34/*kOLEditTagFilters*/, @"Filters not shown");
    
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.edits.filterName && ![editVc.edits.filterName isEqualToString:@""], @"Filter not selected");
    
    [self performUIAction:^{
        [editVc.editingTools.drawerDoneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 30/*kOLEditTagImageTools*/, @"Image Tools not restored");
    
    [self performUIActionWithDelay:5 action:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.edits.flipVertical || editVc.edits.flipHorizontal, @"Image not flipped");
    
    [self performUIActionWithDelay:5 action:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.edits.counterClockwiseRotations > 0, @"Image not rotated");
    
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.textFields.count == 1, @"Textfield not inserted");
    
    [self performUIAction:^{
        editVc.textFields.firstObject.text = @"👦🏻💍🌋?";
    }];
    [self performUIAction:^{
        [editVc onTapGestureRecognized:nil];
    }];
    
    [self performUIAction:^{
        [editVc.editingTools.button3 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 30/*kOLEditTagImageTools*/, @"Image Tools not shown");
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.textFields.count == 2, @"Textfield not inserted");
    [self performUIAction:^{
        [editVc.textFields.firstObject resignFirstResponder];
    }];
    
    [self performUIAction:^{
        [editVc onButtonDoneTapped:nil];
    }];
    
    [self performUIAction:^{
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    editVc = (OLImageEditViewController *)reviewVc.presentedViewController;
    XCTAssert([editVc isKindOfClass:[OLImageEditViewController class]], @"Did not show edit screen");
    
    editVc.textFields.firstObject.text = @"Lord of the Rings";
    
    [self performUIAction:^{
        [editVc textFieldShouldBeginEditing:editVc.textFields.firstObject];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 31/*kOLEditTagTextTools*/, @"Text Tools not shown");
    
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 33/*kOLEditTagFonts*/, @"Fonts not shown");
    
    [self performUIAction:^{
        [editVc collectionView:editVc.editingTools.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:[editVc.editingTools.collectionView numberOfItemsInSection:0] - 1 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editVc.editingTools.drawerDoneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 31/*kOLEditTagTextTools*/, @"Text Tools not restored");
    
    ///
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 32/*kOLEditTagTextColors*/, @"Font Colors not shown");
    
    [self performUIAction:^{
        [editVc collectionView:editVc.editingTools.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:14 inSection:0]];
    }];
    
    [self performUIAction:^{
        [editVc.editingTools.drawerDoneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    XCTAssert(editVc.editingTools.collectionView.tag == 31/*kOLEditTagTextTools*/, @"Text Tools not restored");
    
    [self performUIAction:^{
        [editVc onBarButtonCancelTapped:nil];
    }];
    
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
    
    [self tapNextOnViewController:reviewVc];
}

- (void)testContinueShopping{
    NSArray *urls = @[@"https://s3.amazonaws.com/psps/sdk_static/1.jpg", @"https://s3.amazonaws.com/psps/sdk_static/2.jpg", @"https://s3.amazonaws.com/psps/sdk_static/3.jpg", @"https://s3.amazonaws.com/psps/sdk_static/4.jpg", @"https://s3.amazonaws.com/psps/sdk_static/5.jpg", @"https://s3.amazonaws.com/psps/sdk_static/6.jpg", @"https://s3.amazonaws.com/psps/sdk_static/7.jpg", @"https://s3.amazonaws.com/psps/sdk_static/8.jpg", @"https://s3.amazonaws.com/psps/sdk_static/9.jpg", @"https://s3.amazonaws.com/psps/sdk_static/10.jpg", @"https://s3.amazonaws.com/psps/sdk_static/11.jpg", @"https://s3.amazonaws.com/psps/sdk_static/12.jpg", @"https://s3.amazonaws.com/psps/sdk_static/13.jpg", @"https://s3.amazonaws.com/psps/sdk_static/14.jpg", @"https://s3.amazonaws.com/psps/sdk_static/15.jpg", @"https://s3.amazonaws.com/psps/sdk_static/16.jpg", @"https://s3.amazonaws.com/psps/sdk_static/17.jpg", @"https://s3.amazonaws.com/psps/sdk_static/18.jpg", @"https://s3.amazonaws.com/psps/sdk_static/19.jpg", @"https://s3.amazonaws.com/psps/sdk_static/20.jpg", @"https://s3.amazonaws.com/psps/sdk_static/21.jpg", @"https://s3.amazonaws.com/psps/sdk_static/22.jpg", @"https://s3.amazonaws.com/psps/sdk_static/23.jpg", @"https://s3.amazonaws.com/psps/sdk_static/24.jpg", @"https://s3.amazonaws.com/psps/sdk_static/25.jpg", @"https://s3.amazonaws.com/psps/sdk_static/26.jpg", @"https://s3.amazonaws.com/psps/sdk_static/27.jpg", @"https://s3.amazonaws.com/psps/sdk_static/28.jpg", @"https://s3.amazonaws.com/psps/sdk_static/29.jpg", @"https://s3.amazonaws.com/psps/sdk_static/30.jpg", @"https://s3.amazonaws.com/psps/sdk_static/31.jpg", @"https://s3.amazonaws.com/psps/sdk_static/32.jpg", @"https://s3.amazonaws.com/psps/sdk_static/33.jpg"];
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (NSString *s in urls){
        OLAsset *asset = [OLAsset assetWithURL:[NSURL URLWithString:s]];
        [assets addObject:asset];
    }
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [OLUserSession currentSession].userSelectedAssets = [assets mutableCopy];
    
    [self chooseClass:@"Prints" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Squares" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    UIViewController *reviewVc = productHomeVc.navigationController.topViewController;
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [paymentVc paymentMethodsViewController:nil didPickPaymentMethod:kOLPaymentMethodPayPal];
    
    [self performUIAction:^{
        [paymentVc onButtonPayClicked:nil];
    }];
    
    [self performUIAction:^{
        [paymentVc onButtonContinueShoppingClicked:nil];
    }];
}

- (void)testThemeableElements{
    [OLProductTemplate syncWithCompletionHandler:^(id templates, NSError *error){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"https://dl.dropboxusercontent.com/u/3007013/Triforce.png" forKey:kOLKiteThemeHeaderLogoImageURL];
        [defaults synchronize];
    }];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[NSBundle bundleForClass:[OLKiteViewController class]]];
    XCTAssert(sb);
    
    OLProductHomeViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ProductHomeViewController"];
    XCTAssert(vc);
    
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];
}

- (void)testPromoView{
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    OLKiteViewController *kvc = [[OLKiteViewController alloc] initWithAssets:@[] info:@{@"Entry Point" : @"OLPromoView"}];
    [kvc startLoadingWithCompletionHandler:^{}];
    
    UIView *containerView = [[UIView alloc] init];
    containerView.tag = 1000;
    containerView.backgroundColor = [UIColor clearColor];
    [rootVc.topViewController.view addSubview:containerView];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(containerView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    float height = 200;
    
    NSArray *visuals = @[@"H:|-0-[containerView]-0-|",
                         [NSString stringWithFormat:@"V:[containerView(%f)]-0-|", height]];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [containerView.superview addConstraints:con];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] init];
    activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activity startAnimating];
    [containerView addSubview:activity];
    activity.translatesAutoresizingMaskIntoConstraints = NO;
    [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [activity.superview addConstraint:[NSLayoutConstraint constraintWithItem:activity attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activity.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    NSArray *assets = @[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]],
                        [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]]];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"Promo View Expectation failed"];
    [OLPromoView requestPromoViewWithAssets:assets templates:@[@"i6s_case", @"i5_case"] completionHandler:^(OLPromoView *view, NSError *error){
        [activity stopAnimating];
        if (error){
            NSLog(@"ERROR: %@", error.localizedDescription);
            return;
        }
        
        [containerView addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        NSMutableArray *con = [[NSMutableArray alloc] init];
        
        NSArray *visuals = @[@"H:|-0-[view]-0-|",
                             @"V:|-0-[view]-0-|"];
        
        
        for (NSString *visual in visuals) {
            [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
        }
        
        [view.superview addConstraints:con];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [exp fulfill];
        });
    }];
    
    [self waitForExpectationsWithTimeout:240 handler:NULL];
}

- (void)testVideoDescription{
    [OLKiteTestHelper mockTemplateRequest];
    
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"Retro Prints" onOLProductHomeViewController:productHomeVc];
    
    [self performUIActionWithDelay:7 action:^{
        //Just wait for the video to load
    }];
    
    [OLKiteTestHelper undoMockTemplateRequest];
}

- (void)testBasket{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [self performUIActionWithDelay:3 action:^{
        [productHomeVc onButtonBasketClicked:nil];
    }];
}

- (void)testAddingPhotosToPhotobook{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    
    [[OLAsset userSelectedAssets] removeAllObjects];
    
    [self chooseClass:@"Photo Books" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Small Square Hardcover" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLEditPhotobookViewController *photobookEditVc = (OLEditPhotobookViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photobookEditVc isKindOfClass:[OLEditPhotobookViewController class]]);
    
    OLPhotobookViewController *photobook = photobookEditVc.childViewControllers[1];
    OLArtboardView *artboard = [(OLPhotobookPageContentViewController *)photobook.pageController.viewControllers.firstObject artboardView];
    
    [self performUIAction:^{
        for (UIGestureRecognizer *gesture in artboard.assetViews.firstObject.gestureRecognizers){
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]){
                [artboard handleTapGesture:(UITapGestureRecognizer *)gesture];
                return;
            }
        }
    }];
    
    XCTAssert([[(UINavigationController *)photobookEditVc.presentedViewController topViewController] isKindOfClass:[OLImagePickerViewController class]], @"Did not show image picker");
    
    OLImagePickerViewController *picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:6 inSection:0]];
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:7 inSection:0]];
    }];
    
    [self performUIAction:^{
        [picker onButtonDoneTapped:nil];
    }];
    
    OLAsset *asset1 = [OLAsset userSelectedAssets].nonPlaceholderAssets[0];
    XCTAssert(asset1, @"Asset1 missing");
    OLAsset *asset2 = [OLAsset userSelectedAssets].nonPlaceholderAssets[1];
    XCTAssert(asset2, @"Asset2 missing");
    
    CGSize cellSize = [(id<UICollectionViewDelegateFlowLayout>)photobookEditVc.collectionView.delegate collectionView:photobookEditVc.collectionView layout:photobookEditVc.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    [self performUIAction:^{
        OLMockLongPressGestureRecognizer *mockLongPress = [[OLMockLongPressGestureRecognizer alloc] initWithTarget:artboard action:@selector(handleLongPressGesture:)];
        mockLongPress.mockState = UIGestureRecognizerStateBegan;
        [artboard.assetViews.firstObject addGestureRecognizer:mockLongPress];
        
        [artboard handleLongPressGesture:mockLongPress];
    }];
    
    [self performUIAction:^{
        OLMockPanGestureRecognizer *mockPan = [[OLMockPanGestureRecognizer alloc] initWithTarget:artboard action:@selector(handlePanGesture:)];
        [artboard.assetViews.firstObject addGestureRecognizer:mockPan];
        mockPan.mockState = UIGestureRecognizerStateChanged;
        mockPan.mockTranslation = CGPointMake(cellSize.width / 3.0, cellSize.height);
        
        [artboard handlePanGesture:mockPan];
    }];
    
    [self performUIAction:^{
        OLMockLongPressGestureRecognizer *mockLongPress = [[OLMockLongPressGestureRecognizer alloc] initWithTarget:artboard action:@selector(handleLongPressGesture:)];
        mockLongPress.mockState = UIGestureRecognizerStateEnded;
        
        [artboard handleLongPressGesture:mockLongPress];
    }];
    
    XCTAssert([OLAsset userSelectedAssets].nonPlaceholderAssets[0] == asset2 && [OLAsset userSelectedAssets].nonPlaceholderAssets[1] == asset1, @"Did not move asset");
    
    [self tapNextOnViewController:photobookEditVc];
    
    photobook = (OLPhotobookViewController *)productHomeVc.navigationController.topViewController;
    
    [self performUIAction:^{
        [photobook openBook:nil];
    }];
    
    [self performUIAction:^{
        for (UIGestureRecognizer *gesture in artboard.assetViews.firstObject.gestureRecognizers){
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]){
                [artboard handleTapGesture:(UITapGestureRecognizer *)gesture];
                return;
            }
        }
    }];
    
    picker = (OLImagePickerViewController *)[(UINavigationController *)[OLUserSession currentSession].kiteVc.presentedViewController topViewController];
    
    [self performUIAction:^{
        OLImagePickerPhotosPageViewController *pageVc = (OLImagePickerPhotosPageViewController *)picker.pageController.viewControllers.firstObject;
        [pageVc collectionView:pageVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:0]];
    }];
    
    [self performUIAction:^{
        [picker onButtonDoneTapped:nil];
    }];
    
    XCTAssert([OLAsset userSelectedAssets].nonPlaceholderAssets.count == 3, @"Did not pick an image");
}

- (void)testCountryPicker{
    OLCountryPickerController *vc = [[OLCountryPickerController alloc] init];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:vc animated:YES completion:NULL];
    }];
}

- (void)testPrintOrderHistory{
    UINavigationController *nvc = [OLKiteViewController orderHistoryViewController];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];
}

- (void)testMockCostRequest{
    [OLKiteTestHelper mockCostRequest];
    
    [self launchKiteToBasket];
    
    [OLKiteTestHelper undoMockCostRequest];
}

- (void)testMockPrintOrderRequest{
    [OLKiteTestHelper mockPrintOrderRequest];
    
    OLPaymentViewController *paymentVc = [self launchKiteToBasket];
    
    [self performUIAction:^{
        [paymentVc submitOrderForPrintingWithProofOfPayment:@"PAUTH-🤑" paymentMethod:@"😉" completion:^(NSInteger i){}];
    }];
    
    [self performUIAction:^{
        NSLog(@"Done");
    }];
    
    [OLKiteTestHelper undoMockPrintOrderRequest];
}

#pragma mark Failing requests

- (void)testFailedTemplateSync{
    [OLKiteTestHelper mockTemplateServerErrorRequest];
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]]]];
    vc.delegate = (id<OLKiteDelegate>)self;
    
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"]]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]] name:@"Cats"];
    [vc addCustomPhotoProviderWithCollections:@[catsCollection, dogsCollection] name:@"Pets" icon:[UIImage imageNamed:@"dog"]];
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionBasket];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:vc animated:YES completion:NULL];
    }];
    
    XCTAssert([vc.presentedViewController isKindOfClass:[UIAlertController class]], @"Did not show alert");
    
    [OLKiteTestHelper undoMockTemplateServerErrorRequest];
}

- (void)testFailedCostRequest{
    [OLKiteTestHelper mockCostServerErrorRequest];
    
    UIViewController *vc = [self launchKiteToBasket];
    
    XCTAssert([vc.presentedViewController isKindOfClass:[UIAlertController class]], @"Did not show alert");
    
    [OLKiteTestHelper undoMockCostServerErrorRequest];
}

- (void)testFailedPrintOrderRequest{
    [OLKiteTestHelper mockPrintOrderServerErrorRequest];
    
    OLPaymentViewController *paymentVc = [self launchKiteToBasket];
    
    [self performUIAction:^{
        [paymentVc submitOrderForPrintingWithProofOfPayment:@"PAUTH-🤑" paymentMethod:@"😉" completion:^(NSInteger i){}];
    }];
    
    [self performUIAction:^{
        NSLog(@"Done");
    }];
    
    [OLKiteTestHelper undoMockPrintOrderServerErrorRequest];
}

- (void)testFailedPrintOrderValidationRequest{
    [OLKiteTestHelper mockPrintOrderValidationServerErrorRequest];
    
    OLPaymentViewController *paymentVc = [self launchKiteToBasket];
    
    [self performUIAction:^{
        [paymentVc submitOrderForPrintingWithProofOfPayment:@"PAUTH-🤑" paymentMethod:@"😉" completion:^(NSInteger i){}];
    }];
    
    [self performUIAction:^{
        NSLog(@"Done");
    }];
    
    [OLKiteTestHelper undoMockPrintOrderValidationServerErrorRequest];
}

- (void)testRejectedPrintOrderValidationRequest{
    [OLKiteTestHelper mockPrintOrderValidationRejectedErrorRequest];
    
    OLPaymentViewController *paymentVc = [self launchKiteToBasket];
    
    [self performUIAction:^{
        [paymentVc submitOrderForPrintingWithProofOfPayment:@"PAUTH-🤑" paymentMethod:@"😉" completion:^(NSInteger i){}];
    }];
    
    [self performUIAction:^{
        NSLog(@"Done");
    }];
    
    [OLKiteTestHelper undoMockPrintOrderValidationRejectedErrorRequest];
}

#pragma mark Helper

- (OLPaymentViewController *)launchKiteToBasket{
    [self kvoObserveObject:[OLKiteABTesting sharedInstance] forValue:@"launchWithPrintOrderVariant" andExecuteBlock:^{
        [OLKiteABTesting sharedInstance].launchWithPrintOrderVariant = @"Checkout";
    }];
    
    id<OLPrintJob> job = [OLPrintJob printJobWithTemplateId:@"squares" OLAssets:[OLKiteTestHelper urlAssets]];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    [printOrder addPrintJob:job];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithPrintOrder:printOrder];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Load KiteViewController"];
    [rootVc.topViewController presentViewController:vc animated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (vc.childViewControllers.count == 0) {
                sleep(1);
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [expectation fulfill];
            });
            
        });
    }];
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
    UINavigationController *nav = (UINavigationController *)vc.childViewControllers.firstObject;
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)nav.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    return paymentVc;
}

@end
