//
//  Modified MIT License
//
//  Copyright (c) 2010-2016 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAsset.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "UIViewController+TraitCollectionCompatibility.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteViewController.h"
#import "OLKiteABTesting.h"
#import "NSObject+Utils.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLImagePreviewViewController.h"

#ifdef OL_KITE_OFFER_ADOBE
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#endif

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;
static const NSUInteger kTagAlertViewDeletePhoto = 98;

@interface OLKitePrintSDK (Private)
#ifdef OL_KITE_OFFER_ADOBE
+ (NSString *)adobeCreativeSDKClientSecret;
+ (NSString *)adobeCreativeSDKClientID;
#endif
@end

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLKiteViewController ()

@property (strong, nonatomic) OLPrintOrder *printOrder;
- (void)dismiss;

@end

@interface OLPrintOrder (Private)

- (void)saveOrder;

@end

@interface OLProduct ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLProductPrintJob ()
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*declinedOffers;
@property (strong, nonatomic) NSMutableSet <OLUpsellOffer *>*acceptedOffers;
@property (strong, nonatomic) OLUpsellOffer *redeemedOffer;
@end

@interface OLOrderReviewViewController () <OLCheckoutDelegate, UIAlertViewDelegate, UICollectionViewDelegateFlowLayout,
#ifdef OL_KITE_OFFER_ADOBE
AdobeUXImageEditorViewControllerDelegate,
#endif
UIViewControllerPreviewingDelegate>

@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (assign, nonatomic) NSUInteger indexOfPhotoToDelete;
@property (strong, nonatomic) UIButton *nextButton;

@end

@implementation OLOrderReviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenViewed:self.product.productTemplate.name];
#endif
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.nextButton.frame.size.height, self.collectionView.contentInset.right);
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
}

- (void)setupCtaButton{
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [self.nextButton setTitle:NSLocalizedString(@"Add to Basket", @"") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.frame = CGRectMake(0, self.view.frame.size.height - 40 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width, 40);
    [self.collectionView addSubview:self.nextButton];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            OLKiteViewController *kiteVc = [OLKiteUtils kiteVcForViewController:self];
            self.editingPrintJob = [kiteVc.printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.nextButton setTitle:NSLocalizedString(@"Save", @"") forState:UIControlStateNormal];
            [self.nextButton removeTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.nextButton addTarget:paymentVc action:@selector(saveAndDismissReviewController) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
#ifndef OL_NO_ANALYTICS
    if (!self.navigationController){
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:self.userSelectedPhotos.count];
    }
#endif
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, -self.nextButton.frame.origin.x + self.view.frame.size.height - self.nextButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.nextButton.frame.origin.x, self.nextButton.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *presentingVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if (![presentingVc isKindOfClass:[OLPaymentViewController class]]){
            [self addBasketIconToTopRight];
        }
    }
    else{
        [self addBasketIconToTopRight];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    NSArray *visibleCells = [self.collectionView indexPathsForVisibleItems];
    NSIndexPath *maxIndexPath = [visibleCells firstObject];
    for (NSIndexPath *indexPath in visibleCells){
        if (maxIndexPath.item < indexPath.item){
            maxIndexPath = indexPath;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinator> context){
        [self.collectionView.collectionViewLayout invalidateLayout];
        for (NSIndexPath *indexPath in visibleCells){
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            [cell setNeedsDisplay];
        }
        
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, -self.nextButton.frame.origin.x + self.view.frame.size.height - self.nextButton.frame.size.height + self.collectionView.contentOffset.y, self.view.frame.size.width - 2 * self.nextButton.frame.origin.x, self.nextButton.frame.size.height);
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGRect frame = self.nextButton.frame;
    frame.origin.y = self.view.frame.size.height - self.nextButton.frame.size.height + scrollView.contentOffset.y ;
    self.nextButton.frame = frame;
}

-(NSUInteger) totalNumberOfExtras{
    NSUInteger res = 0;
    for (OLPrintPhoto *photo in self.userSelectedPhotos){
        res += photo.extraCopies;
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if (self.product.quantityToFulfillOrder > 1){
        NSUInteger numOrders = 1 + (MAX(0, self.userSelectedPhotos.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
        NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
        self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long) (self.userSelectedPhotos.count + [self totalNumberOfExtras]), (unsigned long)quanityToFulfilOrder];
    }
    else{
        self.title = NSLocalizedString(@"Review", @"");
    }
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = self.userSelectedPhotos.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"You've selected %d photos.", @""),selectedCount] message:[NSString stringWithFormat:NSLocalizedString(@"You can add %d more for the same price.", @""), canSelectExtraCount] delegate:nil cancelButtonTitle:NSLocalizedString(@"Add more", @"") otherButtonTitles:NSLocalizedString(@"Print these", @""), nil];
        av.tag = kTagAlertViewSelectMorePhotos;
        av.delegate = self;
        [av show];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    [self preparePhotosForCheckout];
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.checkoutPhotos) {
        [photoAssets addObject:[OLAsset assetWithDataSource:[photo copy]]];
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    
#ifdef OL_VERBOSE
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
#endif
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    
    OLProductPrintJob *job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            if ([existingJob extraCopies] > 0){
                [existingJob setExtraCopies:[existingJob extraCopies]-1];
            }
            else{
                [printOrder removePrintJob:existingJob];
            }
            job.uuid = self.product.uuid;
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    if ([printOrder.jobs containsObject:self.editingPrintJob]){
        id<OLPrintJob> existingJob = printOrder.jobs[[printOrder.jobs indexOfObject:self.editingPrintJob]];
        [existingJob setExtraCopies:[existingJob extraCopies]+1];
        for (NSString *option in self.product.selectedOptions.allKeys){
            [job setValue:self.product.selectedOptions[option] forOption:option];
        }
    }
    else{
        [printOrder addPrintJob:self.editingPrintJob];
    }
    
    [printOrder saveOrder];
    
    if (handler){
        handler();
    }
}

- (void)doCheckout {
    [self saveJobWithCompletionHandler:NULL];
    
    OLPrintOrder *printOrder = [OLKiteUtils kiteVcForViewController:self].printOrder;
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder && [[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLProductOverviewViewController"];
        [vc safePerformSelector:@selector(setUserEmail:) withObject:[(OLKiteViewController *)vc userEmail]];
        [vc safePerformSelector:@selector(setUserPhone:) withObject:[(OLKiteViewController *)vc userPhone]];
        [vc safePerformSelector:@selector(setKiteDelegate:) withObject:self.delegate];
        [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
            [vc safePerformSelector:@selector(setKiteDelegate:) withObject:[OLKiteUtils kiteDelegate:self]];
            
            [self.navigationController pushViewController:vc animated:YES];
        }];
    }
}

- (void) deletePhotoAtIndex:(NSUInteger)index{
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDeletedPhotoForProductName:self.product.productTemplate.name];
#endif
    [self.userSelectedPhotos removeObjectAtIndex:index];
    
    if (self.userSelectedPhotos.count == 0){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
}

- (CGFloat) productAspectRatio{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    if (b.top < b.bottom){ //This is for polaroids, since we don't know its pixel dims
        return 1;
    }
    else{
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:10];
    if (!imageView.image){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:imageView.frame toView:self.collectionView]];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.item];
    
    OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        previewVc.image = image;
    }];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
#ifdef OL_KITE_OFFER_ADOBE
    [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
    [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:[NSNumber numberWithDouble:[self productAspectRatio]]}]];
    [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
    [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
    [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
        [editorController setDelegate:self];
        [self presentViewController:editorController animated:YES completion:nil];
    }];
#else
    OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [self.editingPrintPhoto getImageWithProgress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
    }];
#endif
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
}

#pragma mark Button Actions

- (IBAction)onButtonUpArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSInteger extraCopies = [self.userSelectedPhotos[indexPath.item] extraCopies] + 1;
    [self.userSelectedPhotos[indexPath.item] setExtraCopies:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenIncrementedPhotoQtyForProductName:self.product.productTemplate.name];
#endif
}

- (IBAction)onButtonDownArrowClicked:(UIButton *)sender {
    UIView* cellContentView = sender.superview;
    UIView* cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    NSInteger extraCopies = [self.userSelectedPhotos[indexPath.item] extraCopies];
    if (extraCopies == 0){
        if ([UIAlertController class]){
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove?", @"") message:NSLocalizedString(@"Do you want to remove this photo?", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, remove it", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self deletePhotoAtIndex:indexPath.item];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, keep it", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remove?", @"") message:NSLocalizedString(@"Do you want to remove this photo?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Yes, remove it", @"") otherButtonTitles:NSLocalizedString(@"No, keep it", @""), nil];
            self.indexOfPhotoToDelete = indexPath.item;
            av.tag = kTagAlertViewDeletePhoto;
            [av show];
        };
        return;
    }
    extraCopies--;
    
    [self.userSelectedPhotos[indexPath.item] setExtraCopies:extraCopies];
    UILabel* countLabel = (UILabel *)[cellContentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%lu", (unsigned long)extraCopies + 1]];
    
    [self updateTitleBasedOnSelectedPhotoQuanitity];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDecrementedPhotoQtyForProductName:self.product.productTemplate.name];
#endif
}

- (IBAction)onButtonEnhanceClicked:(id)sender {
    UIView *cellContentView;
    if ([sender isKindOfClass: [UIButton class]]){
        cellContentView = [(UIButton *)sender superview];
    }
    else if ([sender isKindOfClass:[UITapGestureRecognizer class]]){
        cellContentView = [(UITapGestureRecognizer *)sender view];
    }
    UIView *cell = cellContentView.superview;
    while (![cell isKindOfClass:[UICollectionViewCell class]]){
        cell = cell.superview;
    }
    
    OLRemoteImageView *imageView = (OLRemoteImageView *)[cell viewWithTag:10];
    if (!imageView.image){
        return;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.item];
    
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        
#ifdef OL_KITE_OFFER_ADOBE
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:[OLKitePrintSDK adobeCreativeSDKClientID] clientSecret:[OLKitePrintSDK adobeCreativeSDKClientSecret] enableSignUp:true];
        [AdobeImageEditorCustomization setCropToolPresets:@[@{kAdobeImageEditorCropPresetName:@"", kAdobeImageEditorCropPresetWidth:@1, kAdobeImageEditorCropPresetHeight:[NSNumber numberWithDouble:[self productAspectRatio]]}]];
        [AdobeImageEditorCustomization setCropToolCustomEnabled:NO];
        [AdobeImageEditorCustomization setCropToolInvertEnabled:NO];
        [AdobeImageEditorCustomization setCropToolOriginalEnabled:NO];


        AdobeUXImageEditorViewController *editorController = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
        [editorController setDelegate:self];
        [self presentViewController:editorController animated:YES completion:nil];
#else
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 0;
        }];
        OLScrollCropViewController *cropVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
        cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
        cropVc.delegate = self;
        cropVc.aspectRatio = [self productAspectRatio];
        
        cropVc.previewView = [imageView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [cell convertRect:imageView.frame toView:nil];
        cropVc.previewSourceView = imageView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        [self presentViewController:cropVc animated:NO completion:NULL];
#endif
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackReviewScreenEnteredCropScreenForProductName:self.product.productTemplate.name];
#endif
    }];
    
}

- (IBAction)onButtonNextClicked:(UIBarButtonItem *)sender {
    if (![self shouldGoToCheckout]){
        return;
    }
    
    [self doCheckout];
}

- (IBAction)onButtonImageClicked:(UIButton *)sender {
    [self onButtonEnhanceClicked:sender];
}

- (void)preparePhotosForCheckout{
    self.checkoutPhotos = [[NSMutableArray alloc] init];
    [self.checkoutPhotos addObjectsFromArray:self.userSelectedPhotos];
    for (int i = 0; i < self.userSelectedPhotos.count; i++) {
        NSInteger numberOfCopies = [self.userSelectedPhotos[i] extraCopies];
        for (NSInteger j = 0; j < numberOfCopies; j++){
            [self.checkoutPhotos addObject:self.userSelectedPhotos[i]];
        }
    }
}

#pragma mark UICollectionView data source and delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.userSelectedPhotos count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    OLCircleMaskCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewPhotoCell" forIndexPath:indexPath];
    UIView *view = cell.contentView;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-0-[view]-0-|",
                         @"V:|-0-[view]-0-|"];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [view.superview addConstraints:con];
    
    UIView *borderView = [cell.contentView viewWithTag:399];
    
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:278];
    [activityIndicator startAnimating];
    
    UIView *oldView = [cell.contentView viewWithTag:10];
    [oldView removeFromSuperview];
    
    OLRemoteImageView *cellImage = [[OLRemoteImageView alloc] initWithFrame:borderView.frame];
    cellImage.tag = 10;
    cellImage.translatesAutoresizingMaskIntoConstraints = NO;
    cellImage.contentMode = UIViewContentModeScaleAspectFill;
    cellImage.clipsToBounds = YES;
    [cell.contentView insertSubview:cellImage aboveSubview:activityIndicator];
    
    if ([self.presentedViewController isKindOfClass:[OLScrollCropViewController class]]){
        OLScrollCropViewController *cropVc = (OLScrollCropViewController *)self.presentedViewController;
        if (oldView == cropVc.previewSourceView){
            cropVc.previewSourceView = cellImage;
            cellImage.hidden = YES;
        }
    }
    
    cellImage.userInteractionEnabled = YES;
    [cellImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonEnhanceClicked:)]];
    
    UIButton *enhanceButton = (UIButton *)[cell.contentView viewWithTag:11];
    [enhanceButton addTarget:self action:@selector(onButtonEnhanceClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%ld", (long)[self.userSelectedPhotos[indexPath.item] extraCopies]+1]];
    
    OLPrintPhoto *printPhoto = (OLPrintPhoto*)[self.userSelectedPhotos objectAtIndex:indexPath.item];
    [printPhoto setImageSize:cellImage.frame.size cropped:YES progress:^(float progress){
        [cellImage setProgress:progress];
    } completionHandler:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityIndicator stopAnimating];
            cellImage.image = image;
        });
    }];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUICircle){
        cell.enableMask = YES;
        [cell setNeedsDisplay];
    }
    
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    NSLayoutConstraint *topCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeTop multiplier:1 constant:b.top];
    NSLayoutConstraint *leftCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeLeft multiplier:1 constant:b.left];
    NSLayoutConstraint *rightCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:borderView attribute:NSLayoutAttributeRight multiplier:1 constant:-b.right];
    NSLayoutConstraint *bottomCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:borderView attribute:NSLayoutAttributeBottom multiplier:1 constant:-b.bottom];
    
    NSLayoutConstraint *aspectRatioCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:cellImage attribute:NSLayoutAttributeWidth multiplier:[self productAspectRatio] constant:0];
    aspectRatioCon.priority = 750;
    NSLayoutConstraint *activityCenterXCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activityIndicator attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *activityCenterYCon = [NSLayoutConstraint constraintWithItem:cellImage attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    [borderView.superview addConstraints:@[topCon, leftCon, rightCon, bottomCon, activityCenterYCon, activityCenterXCon]];
    [cellImage addConstraints:@[aspectRatioCon]];
    
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    //Everything is designed and calculated based on a 320 view width. Scale up as necessary for larger phones.
    CGFloat screenWidthFactor = 1;
    //Only change the scale for portrait phones.
    if ([self isHorizontalSizeClassCompact] && self.view.frame.size.width < self.view.frame.size.height){
        screenWidthFactor = self.view.frame.size.width / 320;
    }
    
    CGFloat margin = 20;
    CGFloat heightForButtons = 51;
    CGFloat imageWidth = 320 - margin * 2  - b.right - b.left;
    CGFloat imageHeight = imageWidth * [self productAspectRatio];
    CGFloat height = (imageHeight + b.top + b.bottom) * screenWidthFactor + margin + heightForButtons;
    CGFloat width = (imageWidth + b.right + b.left) * screenWidthFactor + margin * 2;
    
    return CGSizeMake(width, height);
}

-(CGFloat)marginBetweenCellsForCollectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout{
    CGFloat width = self.view.bounds.size.width;
    CGFloat cellWidth = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].width;
    int cellsPerRow = width / cellWidth;
    CGFloat spaceLeft = width - (cellsPerRow * cellWidth);
    CGFloat margin = spaceLeft / (cellsPerRow + 1);
    return margin;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = [self marginBetweenCellsForCollectionView:collectionView layout:collectionViewLayout];
    return UIEdgeInsetsMake(0, margin, 0, margin);
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;//[self marginBetweenCellsForCollectionView:collectionView layout:collectionViewLayout];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kTagAlertViewSelectMorePhotos) {
        if (buttonIndex == 1) {
            [self doCheckout];
        }
    }
    else if (alertView.tag == kTagAlertViewDeletePhoto) {
        if (buttonIndex == 0){
            [self deletePhotoAtIndex:self.indexOfPhotoToDelete];
        }
    }
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLScrollCropViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    
    self.editingPrintPhoto.edits = cropper.edits;
    
    //Need to do some work to only reload the proper cells, otherwise the cropped image might zoom to the wrong cell.
    for (NSInteger i = 0; i < self.userSelectedPhotos.count; i++){
        if (self.userSelectedPhotos[i] == self.editingPrintPhoto){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            if (indexPath){
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }
        }
    }
    
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackReviewScreenDidCropPhotoForProductName:self.product.productTemplate.name];
#endif
}

#ifdef OL_KITE_OFFER_ADOBE
- (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image{
    [self.editingPrintPhoto unloadImage];
    
    OLPrintPhoto *printPhoto = self.editingPrintPhoto;
    OLPrintPhoto *copy = [printPhoto copy];
    printPhoto.asset = [OLAsset assetWithImageAsJPEG:image];
    
    [self.collectionView reloadData];
    
    [editor dismissViewControllerAnimated:YES completion:NULL];
    
    [copy getImageWithProgress:NULL completion:^(UIImage *image){
        [editor enqueueHighResolutionRenderWithImage:image completion:^(UIImage *result, NSError *error) {
            NSArray * urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSString *documentDirPath = [[(NSURL *)[urls objectAtIndex:0] path] stringByAppendingPathComponent:@"ol-kite-images"];
            
            
            NSFileManager *fileManager= [NSFileManager defaultManager];
            BOOL isDir;
            if(![fileManager fileExistsAtPath:documentDirPath isDirectory:&isDir]){
                [fileManager createDirectoryAtPath:documentDirPath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            NSData * binaryImageData = UIImageJPEGRepresentation(result, 0.7);
            
            NSString *filePath = [documentDirPath stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"]];
            [binaryImageData writeToFile:filePath atomically:YES];
            
            printPhoto.asset = [OLAsset assetWithFilePath:filePath];
        }];
    }];
    
}

- (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor{
    [editor dismissViewControllerAnimated:YES completion:NULL];
}
#endif

#pragma mark - Tear down and restore

- (void)tearDownLargeObjectsFromMemory{
    [super tearDownLargeObjectsFromMemory];
    [self.collectionView reloadData];
}

- (void)recreateTornDownLargeObjectsToMemory{
    [super recreateTornDownLargeObjectsToMemory];
    [self.collectionView reloadData];
}

#pragma mark - Autorotate and Orientation Methods
// Currently here to disable landscape orientations and rotation on iOS 7. When support is dropped, these can be deleted.

- (BOOL)shouldAutorotate {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return YES;
    }
    else{
        return NO;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
