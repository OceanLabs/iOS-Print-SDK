//
//  XCTestCase+OLUITestMethods.h
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 24/01/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
#import "OLPosterViewController.h"
#import "OLBaseRequest.h"
#import "OLImagePickerLoginPageViewController.h"
#import "OLMockPanGestureRecognizer.h"
#import "OL3DProductViewController.h"
#import "OLAddressLookupViewController.h"
#import "OLAddressSelectionViewController.h"
#import "OLKiteViewController+Private.h"

@interface XCTestCase (OLUITestMethods)
- (NSInteger)findIndexForProductName:(NSString *)name inOLProductTypeSelectionViewController:(OLProductTypeSelectionViewController *)vc;
- (OLProductHomeViewController *)loadKiteViewController;
- (void)chooseClass:(NSString *)class onOLProductHomeViewController:(OLProductHomeViewController *)productHome;
- (void)chooseProduct:(NSString *)name onOLProductTypeSelectionViewController:(OLProductTypeSelectionViewController *)productTypeVc;
- (void)performUIAction:(void(^)())action;
- (void)performUIActionWithDelay:(double)delay action:(void(^)())action;
- (void)setUpHelper;
- (void)tapNextOnViewController:(UIViewController *)vc;
- (void)tearDownHelper;
- (void)templateSyncWithSuccessHandler:(void(^)())handler;
@end

@interface UIViewController ()
- (IBAction)onButtonBasketClicked:(UIBarButtonItem *)sender;
@end

@interface OLPosterViewController ()
- (IBAction)editPhoto:(id)sender;
@end

@interface OLFrameOrderReviewViewController ()
- (void)onTapGestureThumbnailTapped:(UITapGestureRecognizer*)gestureRecognizer;
@end

@interface OLAddressLookupViewController ()
@property (strong, nonatomic) UISearchController *searchController;
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController;
@end

@interface OLImagePickerLoginPageViewController ()
- (IBAction)onButtonLoginTapped:(UIButton *)sender ;
@end

@interface OLUpsellViewController ()
- (IBAction)acceptButtonAction:(UIButton *)sender;
- (IBAction)declineButtonAction:(UIButton *)sender;
@end

@interface OLKitePrintSDK ()
+ (BOOL)setUseStripeForCreditCards:(BOOL)use;
+ (void)setUseStaging:(BOOL)staging;
@end

@interface OLProductTypeSelectionViewController (Private)
-(NSMutableArray *) products;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface OLButtonCollectionViewCell ()
- (void)onButtonTouchUpInside;
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

@interface OLEditPhotobookViewController ()
- (void)deletePage;
- (void)editImage;
@end

@interface OLPhotobookViewController ()
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
- (void)onTapGestureRecognized:(UITapGestureRecognizer *)sender;
- (void)onCoverTapRecognized:(UITapGestureRecognizer *)sender;
- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer;
- (void)openBook:(UIGestureRecognizer *)sender;
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
- (void)closeBookFrontForGesture:(UIPanGestureRecognizer *)sender;
- (void)closeBookBackForGesture:(UIPanGestureRecognizer *)sender;
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
- (IBAction)onButtonProductFlipClicked:(UIButton *)sender;
- (void)exitCropMode;
- (void)onButtonCropClicked:(UIButton *)sender;
@property (assign, nonatomic) BOOL downloadedMask;
@property (weak, nonatomic) IBOutlet UIButton *productFlipButton;
@end

@interface OLPaymentViewController () <UITableViewDataSource>
- (IBAction)onButtonAddPaymentMethodClicked:(id)sender;
- (IBAction)onButtonContinueShoppingClicked:(UIButton *)sender;
- (IBAction)onButtonEditClicked:(UIButton *)sender;
- (IBAction)onButtonPayClicked:(UIButton *)sender;
- (IBAction)onShippingDetailsGestureRecognized:(id)sender;
- (void)onBackgroundClicked;
- (void)payPalPaymentDidCancel:(id)paymentViewController;
- (void)paymentMethodsViewController:(OLPaymentMethodsViewController *)vc didPickPaymentMethod:(OLPaymentMethod)method;
- (void)submitOrderForPrintingWithProofOfPayment:(NSString *)proofOfPayment paymentMethod:(NSString *)paymentMethod completion:(id)handler;
@property (strong, nonatomic) OLPrintOrder *printOrder;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *promoCodeTextField;
@end


@interface OLKiteABTesting ()
@property (strong, nonatomic, readwrite) NSString *qualityBannerType;
@property (strong, nonatomic, readwrite) NSString *launchWithPrintOrderVariant;
@property (strong, nonatomic, readwrite) NSString *checkoutScreenType;
@property (strong, nonatomic, readwrite) NSString *promoBannerText;
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

@interface OLImagePickerPhotosPageViewController () <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (IBAction)userDidTapOnAlbumLabel:(UITapGestureRecognizer *)sender;
- (void)onButtonLogoutTapped;
@end
