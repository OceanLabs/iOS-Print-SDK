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
#import "OLNavigationController.h"
#import "OLKiteTestHelper.h"
#import "OLProductGroup.h"
#import "OLProductTypeSelectionViewController.h"
#import "NSObject+Utils.h"
#import "OLPackProductViewController.h"
#import "OLPhotobookViewController.h"
#import "OLProductOverviewViewController.h"
#import "OLCaseViewController.h"
#import "OLKiteUtils.h"
#import "OLPrintOrder.h"
#import "OLPaymentViewController.h"
#import "OLCreditCardCaptureViewController.h"
#import "OLEditPhotobookViewController.h"
#import "OLKiteABTesting.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLAddressEditViewController.h"
#import "OLTestTapGestureRecognizer.h"
#import "OLCustomViewControllerPhotoProvider.h"
#import "OLUpsellViewController.h"
#import "OLPrintOrder+History.h"
#import "OLFrameOrderReviewViewController.h"
#import "OLInfoPageViewController.h"
#import "OLImagePreviewViewController.h"
#import "OLUserSession.h"
#import "OLPhotoEdits.h"
#import "OLImagePickerViewController.h"
#import "OLPaymentMethodsViewController.h"
#import "OLImagePickerPhotosPageViewController.h"
#import "OLButtonCollectionViewCell.h"
#import "OLPhotoTextField.h"

@import Photos;

@interface ViewControllerTests : XCTestCase

@property (strong, nonatomic) NSString *kvoValueToObserve;
@property (copy, nonatomic) void (^kvoBlockToExecute)();
@property (weak, nonatomic) id kvoObjectToObserve;

@end

@interface OLKitePrintSDK ()
+ (BOOL)setUseStripeForCreditCards:(BOOL)use;
+ (void)setUseStaging:(BOOL)staging;
+ (void)setCacheTemplates:(BOOL)cache;
@end

@interface OLProductTypeSelectionViewController (Private)
-(NSMutableArray *) products;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface OLButtonCollectionViewCell ()
- (void)onButtonTouchUpInside;
@end

@interface OLKiteViewController ()
- (void)dismiss;
@property (strong, nonatomic) NSMutableArray <OLImagePickerProvider *> *customImageProviders;
@end

@interface OLProductHomeViewController (Private)

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)productGroups;
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
@end

@interface OLPackProductViewController ()
@property (strong, nonatomic) UIButton *nextButton;
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location;
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit;
- (void) deletePhotoAtIndex:(NSUInteger)index;
@end

@interface OLPhotobookViewController ()
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender;
- (void)onCoverTapRecognized:(UITapGestureRecognizer *)sender;
@end

@interface OLProductOverviewViewController ()
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
- (IBAction)onLabelDetailsTapped:(UITapGestureRecognizer *)sender;
@end

@interface OLImageEditViewController () <UICollectionViewDelegate, UITextFieldDelegate>
- (void)onButtonClicked:(UIButton *)sender;
@property (strong, nonatomic) NSMutableArray<OLPhotoTextField *> *textFields;
- (IBAction)onButtonDoneTapped:(UIBarButtonItem *)sender;
- (IBAction)onBarButtonCancelTapped:(UIBarButtonItem *)sender;
- (void)onTapGestureRecognized:(id)sender;
@end

@interface OLCaseViewController ()
@property (assign, nonatomic) BOOL downloadedMask;
@end

@interface OLPaymentViewController () <UITableViewDataSource>
- (IBAction)onButtonPayWithCreditCardClicked;
- (IBAction)onButtonMoreOptionsClicked:(id)sender;
- (IBAction)onButtonBackToApplePayClicked:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UITextField *promoCodeTextField;
@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)onBackgroundClicked;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)onButtonEditClicked:(UIButton *)sender;
- (IBAction)onShippingDetailsGestureRecognized:(id)sender;
- (IBAction)onButtonPayWithApplePayClicked;
- (IBAction)onButtonAddPaymentMethodClicked:(id)sender;
@end


@interface OLKiteABTesting ()
@property (strong, nonatomic, readwrite) NSString *qualityBannerType;
@property (strong, nonatomic, readwrite) NSString *launchWithPrintOrderVariant;
@property (strong, nonatomic, readwrite) NSString *checkoutScreenType;
@end

@class OLCreditCardCaptureRootController;
@interface OLCreditCardCaptureViewController ()
@property (nonatomic, strong) OLCreditCardCaptureRootController *rootVC;
@end

@interface OLCheckoutViewController ()
- (void)onButtonDoneClicked;
@end

@interface OLCreditCardCaptureRootController : UITableViewController
@property (nonatomic, strong) UITextField *textFieldCardNumber, *textFieldExpiryDate, *textFieldCVV;
- (void)onButtonPayClicked;
@end

@interface OLUpsellViewController ()
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@end

@interface OLPaymentMethodsViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end

@interface OLImagePickerViewController ()
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@property (weak, nonatomic) IBOutlet UICollectionView *sourcesCollectionView;
@property (strong, nonatomic) UIPageViewController *pageController;
@end

@interface OLImagePickerPhotosPageViewController ()
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (IBAction)userDidTapOnAlbumLabel:(UITapGestureRecognizer *)sender;
@end

@implementation ViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [OLKitePrintSDK setAPIKey:@"a45bf7f39523d31aa1ca4ecf64d422b4d810d9c4" withEnvironment:OLKitePrintSDKEnvironmentSandbox];
    [OLKitePrintSDK setIsKiosk:NO];
    [OLKitePrintSDK setUseStripeForCreditCards:YES];
    [OLKitePrintSDK setUseStaging:NO];
    [OLKitePrintSDK setCacheTemplates:NO];
    [OLKitePrintSDK setApplePayPayToString:@"JABBA"];
    [OLStripeCard clearLastUsedCard];
}

- (void)tearDown {
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [rootVc.presentedViewController dismissViewControllerAnimated:NO completion:NULL];
    if (self.kvoValueToObserve){
        [[OLKiteABTesting sharedInstance] removeObserver:self forKeyPath:self.kvoValueToObserve];
        self.kvoValueToObserve = nil;
    }
    
    [self performUIActionWithDelay:5 action:^{
        [[[UIApplication sharedApplication].delegate window].rootViewController dismissViewControllerAnimated:NO completion:NULL];
    }];
    
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
    
    NSArray *urls = @[@"https://s3.amazonaws.com/psps/sdk_static/1.jpg", @"https://s3.amazonaws.com/psps/sdk_static/2.jpg", @"https://s3.amazonaws.com/psps/sdk_static/3.jpg", @"https://s3.amazonaws.com/psps/sdk_static/4.jpg", @"https://s3.amazonaws.com/psps/sdk_static/5.jpg", @"https://s3.amazonaws.com/psps/sdk_static/6.jpg", @"https://s3.amazonaws.com/psps/sdk_static/7.jpg", @"https://s3.amazonaws.com/psps/sdk_static/8.jpg", @"https://s3.amazonaws.com/psps/sdk_static/9.jpg", @"https://s3.amazonaws.com/psps/sdk_static/10.jpg", @"https://s3.amazonaws.com/psps/sdk_static/11.jpg", @"https://s3.amazonaws.com/psps/sdk_static/12.jpg", @"https://s3.amazonaws.com/psps/sdk_static/13.jpg", @"https://s3.amazonaws.com/psps/sdk_static/14.jpg", @"https://s3.amazonaws.com/psps/sdk_static/15.jpg", @"https://s3.amazonaws.com/psps/sdk_static/16.jpg", @"https://s3.amazonaws.com/psps/sdk_static/17.jpg", @"https://s3.amazonaws.com/psps/sdk_static/18.jpg", @"https://s3.amazonaws.com/psps/sdk_static/19.jpg", @"https://s3.amazonaws.com/psps/sdk_static/20.jpg", @"https://s3.amazonaws.com/psps/sdk_static/21.jpg", @"https://s3.amazonaws.com/psps/sdk_static/22.jpg", @"https://s3.amazonaws.com/psps/sdk_static/23.jpg", @"https://s3.amazonaws.com/psps/sdk_static/24.jpg", @"https://s3.amazonaws.com/psps/sdk_static/25.jpg", @"https://s3.amazonaws.com/psps/sdk_static/26.jpg", @"https://s3.amazonaws.com/psps/sdk_static/27.jpg", @"https://s3.amazonaws.com/psps/sdk_static/28.jpg", @"https://s3.amazonaws.com/psps/sdk_static/29.jpg", @"https://s3.amazonaws.com/psps/sdk_static/30.jpg", @"https://s3.amazonaws.com/psps/sdk_static/31.jpg", @"https://s3.amazonaws.com/psps/sdk_static/32.jpg", @"https://s3.amazonaws.com/psps/sdk_static/33.jpg", @"https://s3.amazonaws.com/psps/sdk_static/34.jpg", @"https://s3.amazonaws.com/psps/sdk_static/35.jpg", @"https://s3.amazonaws.com/psps/sdk_static/36.jpg", @"https://s3.amazonaws.com/psps/sdk_static/37.jpg", @"https://s3.amazonaws.com/psps/sdk_static/38.jpg", @"https://s3.amazonaws.com/psps/sdk_static/39.jpg", @"https://s3.amazonaws.com/psps/sdk_static/40.jpg", @"https://s3.amazonaws.com/psps/sdk_static/41.jpg", @"https://s3.amazonaws.com/psps/sdk_static/42.jpg", @"https://s3.amazonaws.com/psps/sdk_static/43.jpg", @"https://s3.amazonaws.com/psps/sdk_static/44.jpg", @"https://s3.amazonaws.com/psps/sdk_static/45.jpg", @"https://s3.amazonaws.com/psps/sdk_static/46.jpg", @"https://s3.amazonaws.com/psps/sdk_static/47.jpg", @"https://s3.amazonaws.com/psps/sdk_static/48.jpg", @"https://s3.amazonaws.com/psps/sdk_static/49.jpg", @"https://s3.amazonaws.com/psps/sdk_static/50.jpg"];
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    for (NSString *s in urls){
        OLAsset *asset = [OLAsset assetWithURL:[NSURL URLWithString:s]];
        [assets addObject:asset];
    }
    
    OLKiteViewController *vc = [[OLKiteViewController alloc] initWithAssets:assets];
    
    OLImagePickerProviderCollection *dogsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/5.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/6.jpg"]]] name:@"Dogs"];
    OLImagePickerProviderCollection *catsCollection = [[OLImagePickerProviderCollection alloc] initWithArray:@[[OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/1.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/2.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/3.jpg"]], [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]] name:@"Cats"];
    [vc addCustomPhotoProviderWithCollections:@[catsCollection, dogsCollection] name:@"Pets" icon:[UIImage imageNamed:@"dog"]];
    [[OLUserSession currentSession] cleanupUserSession:OLUserSessionCleanupOptionBasket];
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
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
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    return resultVc;
}

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
    
    UIButton *button;
    button = (UIButton *)[vc safePerformSelectorWithReturn:@selector(nextButton) withObject:nil];
    if (!button){
        button = (UIButton *)[vc safePerformSelectorWithReturn:@selector(ctaButton) withObject:nil];
    }
    if (!button){
        button = (UIButton *)[vc safePerformSelectorWithReturn:@selector(callToActionButton) withObject:nil];
    }
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:NULL];
}

- (void)performUIActionWithDelay:(double)delay action:(void(^)())action{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for animations"];
    
    action();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:NULL];
}

- (void)performUIAction:(void(^)())action{
    [self performUIActionWithDelay:1.5 action:action];
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
    
    [self tapNextOnViewController:photobookEditVc];
    
    photobook = (OLPhotobookViewController *)productHomeVc.navigationController.topViewController;
    
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
        [paymentVc onButtonPayWithCreditCardClicked];
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
    
    [creditCardVc.rootVC onButtonPayClicked];
    
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
    
    [self chooseProduct:@"iPhone 6" onOLProductTypeSelectionViewController:productTypeVc];
    
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
    
    
    //TODO: Check product option that default selected is first option
    [self performUIAction:^{
         [caseVc.editingTools.button2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    XCTAssert([caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].isSelected, @"Default option (first) should selected");
    
    [self performUIAction:^{
        [caseVc collectionView:caseVc.editingTools.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    }];
    XCTAssert([caseVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]].isSelected, @"Second option  should selected");
    //TODO: Check product option that second is selected
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:caseVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);

    [paymentVc onButtonPayWithCreditCardClicked];
    
    expectation = [self expectationWithDescription:@"Wait for Payment VC"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [creditCardVc.rootVC onButtonPayClicked];
    
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

- (void)testIntegratedCheckoutViewController{
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    printOrder.phone = @"1234123412";
    
    OLIntegratedCheckoutViewController *vc = [[OLIntegratedCheckoutViewController alloc] initWithPrintOrder:printOrder];
    OLNavigationController *nvc = [[OLNavigationController alloc] initWithRootViewController:vc];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:nvc animated:YES completion:NULL];
    }];
    [self performUIAction:^{
            [vc onButtonDoneClicked];
    }];
}

- (void)testAddressEditViewController{
    OLAddressEditViewController *vc = [[OLAddressEditViewController alloc] initWithAddress:[OLAddress kiteTeamAddress]];
    
    UINavigationController *rootVc = (UINavigationController *)[[UIApplication sharedApplication].delegate window].rootViewController;
    [self performUIAction:^{
        [rootVc.topViewController presentViewController:vc animated:YES completion:NULL];
    }];
    
}

- (void)testImagePickerViewController{
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
    
    [self performUIAction:^{
        [photosPage collectionView:photosPage.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    [self performUIAction:^{
        [photosPage userDidTapOnAlbumLabel:nil];
    }];
    
    [self performUIAction:^{
        [photosPage collectionView:photosPage.albumsCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }];
    
    [self performUIAction:^{
        [vc collectionView:vc.sourcesCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
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
    
    [OLKiteABTesting sharedInstance].checkoutScreenType = @"Integrated";
    
    [self performUIAction:^{
        [vc onShippingDetailsGestureRecognized:nil];
    }];
    
    XCTAssert([[(OLNavigationController *)vc.navigationController topViewController] isKindOfClass:[OLIntegratedCheckoutViewController class]] ,@"");
    
    [self performUIAction:^{
        [(OLNavigationController *)vc.navigationController popViewControllerAnimated:YES];
    }];
    
    [OLKiteABTesting sharedInstance].checkoutScreenType = @"Classic";
    
    [self performUIAction:^{
        [vc onShippingDetailsGestureRecognized:nil];
    }];
    
    XCTAssert([[(OLNavigationController *)vc.navigationController topViewController] isKindOfClass:[OLCheckoutViewController class]] ,@"");
    
    [self performUIAction:^{
        [(OLNavigationController *)vc.navigationController popViewControllerAnimated:YES];
    }];
    
    [self performUIActionWithDelay:5 action:^{
        [vc onButtonPayWithApplePayClicked];
    }];
    
    [self performUIAction:^{
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
    }];
    
    [self performUIAction:^{
        OLPaymentMethodsViewController *paymentMethodsVc = (OLPaymentMethodsViewController *)[(OLNavigationController *)vc.navigationController topViewController];
        [(id<UICollectionViewDelegate>)paymentMethodsVc collectionView:paymentMethodsVc.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
        
        [paymentMethodsVc.navigationController popViewControllerAnimated:YES];
    }];
    
    XCTAssert([[(OLNavigationController *)vc.navigationController topViewController] isKindOfClass:[OLPaymentViewController class]]);
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
    
    [self performUIAction:^{
        [reviewVc dismissViewControllerAnimated:YES completion:NULL];
    }];
    
//    UIViewController *scrollVc = [reviewVc previewingContext:nil viewControllerForLocation:[cell convertPoint:CGPointMake(100, 100) toView:reviewVc.collectionView]];
//    XCTAssert([scrollVc isKindOfClass:[OLImagePreviewViewController class]]);
//    [reviewVc previewingContext:nil commitViewController:scrollVc];
//    
//    XCTAssert([reviewVc.presentedViewController isKindOfClass:[OLImageEditViewController class]], @"Did not show crop screen");
//    
//    [self performUIAction:^{
//        [reviewVc dismissViewControllerAnimated:YES completion:NULL];
//    }];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [paymentVc onButtonPayWithCreditCardClicked];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for Payment VC"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [creditCardVc.rootVC onButtonPayClicked];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
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
    
    [self chooseClass:@"Frames" onOLProductHomeViewController:productHomeVc];
    
    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Frames 50cm (2x2)" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLImagePickerViewController *photoVc = (OLImagePickerViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([photoVc isKindOfClass:[OLImagePickerViewController class]]);
    
    [self tapNextOnViewController:photoVc];
    
    OLFrameOrderReviewViewController *reviewVc = (OLFrameOrderReviewViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([reviewVc isKindOfClass:[OLFrameOrderReviewViewController class]]);
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    [self tapNextOnViewController:reviewVc];
    
    XCTAssert(![printOrder isSavedInHistory], @"Print order should not be in history");
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [paymentVc onButtonPayWithCreditCardClicked];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for Payment VC"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [creditCardVc.rootVC onButtonPayClicked];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
}

- (void)DISABLED_testCompleteAccessoryOrder{
    OLProductHomeViewController *productHomeVc = [self loadKiteViewController];
    [self chooseClass:@"Accessories and Display" onOLProductHomeViewController:productHomeVc];

    OLProductTypeSelectionViewController *productTypeVc = (OLProductTypeSelectionViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([productTypeVc isKindOfClass:[OLProductTypeSelectionViewController class]]);
    
    [self chooseProduct:@"Print Shelves" onOLProductTypeSelectionViewController:productTypeVc];
    
    [self tapNextOnViewController:productHomeVc.navigationController.topViewController];
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    printOrder.shippingAddress = [OLAddress kiteTeamAddress];
    printOrder.email = @"ios_unit_test@kite.ly";
    
    OLPaymentViewController *paymentVc = (OLPaymentViewController *)productHomeVc.navigationController.topViewController;
    XCTAssert([paymentVc isKindOfClass:[OLPaymentViewController class]]);
    
    [paymentVc onButtonPayWithCreditCardClicked];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for Payment VC"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
    
    OLCreditCardCaptureViewController *creditCardVc = (OLCreditCardCaptureViewController *)paymentVc.presentedViewController;
    creditCardVc.rootVC.textFieldCVV.text = @"111";
    creditCardVc.rootVC.textFieldCardNumber.text = @"4242424242424242";
    creditCardVc.rootVC.textFieldExpiryDate.text = @"12/20";
    
    [creditCardVc.rootVC onButtonPayClicked];
    
    expectation = [self expectationWithDescription:@"Wait for order complete"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!printOrder.printed) {
            sleep(3);
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:120 handler:NULL];
    
}

- (void)testImageEditor{
    NSArray *olAssets = @[
                          [OLAsset assetWithURL:[NSURL URLWithString:@"https://s3.amazonaws.com/psps/sdk_static/4.jpg"]]
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
    
    [self performUIAction:^{
        [(OLButtonCollectionViewCell *)[editVc.editingTools.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]] onButtonTouchUpInside];
    }];
    XCTAssert(editVc.edits.flipVertical || editVc.edits.flipHorizontal, @"Image not flipped");
    
    [self performUIAction:^{
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
}

@end
