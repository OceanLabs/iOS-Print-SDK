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
#import "OLAsset+Private.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteViewController.h"
#import "OLKiteABTesting.h"
#import "NSObject+Utils.h"
#import "OLRemoteImageView.h"
#import "OLKiteUtils.h"
#import "OLPaymentViewController.h"
#import "UIViewController+OLMethods.h"
#import "OLImagePreviewViewController.h"
#import "OLUserSession.h"
#import "OLAsset+Private.h"
#import "UIImageView+FadeIn.h"
#import "OLInfoBanner.h"

static const NSUInteger kTagAlertViewDeletePhoto = 98;

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

@end

@interface OLKiteViewController ()
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

@interface OLOrderReviewViewController () <OLCheckoutDelegate, UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate>

@property (weak, nonatomic) OLAsset *editingPrintPhoto;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (assign, nonatomic) NSUInteger indexOfPhotoToDelete;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[OLKiteABTesting sharedInstance].backButtonText
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    [self setupCtaButton];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left, self.nextButton.frame.size.height, self.collectionView.contentInset.right);
    
    if ([UITraitCollection class] && [self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Edit", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"")];
    });
}

- (void)setupCtaButton{
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [self.nextButton setTitle:NSLocalizedString(@"Add to Basket", @"") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.nextButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [self.nextButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    }
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.frame = CGRectMake(0, self.view.frame.size.height - 40 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width, 40);
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [self.nextButton.titleLabel setFont:font];
    }
    [self.collectionView addSubview:self.nextButton];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.nextButton setTitle:NSLocalizedString(@"Next", @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            self.editingPrintJob = [[OLUserSession currentSession].printOrder.jobs firstObject];
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
        [OLAnalytics trackReviewScreenHitBack:self.product.productTemplate.name numberOfPhotos:[OLUserSession currentSession].userSelectedPhotos.count];
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
    for (OLAsset *photo in [OLUserSession currentSession].userSelectedPhotos){
        res += photo.extraCopies;
    }
    return res;
}

- (void)updateTitleBasedOnSelectedPhotoQuanitity {
    if (self.product.quantityToFulfillOrder > 1){
        NSUInteger numOrders = 1 + (MAX(0, [OLUserSession currentSession].userSelectedPhotos.count - 1 + [self totalNumberOfExtras]) / self.product.quantityToFulfillOrder);
        NSUInteger quanityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
        self.title = [NSString stringWithFormat:@"%lu / %lu", (unsigned long) ([OLUserSession currentSession].userSelectedPhotos.count + [self totalNumberOfExtras]), (unsigned long)quanityToFulfilOrder];
    }
    else{
        self.title = NSLocalizedString(@"Review", @"");
    }
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = [OLUserSession currentSession].userSelectedPhotos.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") ,selectedCount] message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You can add %d more for the same price.", @"KitePrintSDK", [OLKiteUtils kiteBundle], @""), canSelectExtraCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print these", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self doCheckout];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Add more", @"KitePrintSDK", [OLKiteUtils kiteBundle], @"") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    [self preparePhotosForCheckout];
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLAsset *photo in self.checkoutPhotos) {
        [photoAssets addObject:[photo copy]];
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
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    
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
    
    OLPrintOrder *printOrder = [OLUserSession currentSession].printOrder;
    
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
    [[OLUserSession currentSession].userSelectedPhotos removeObjectAtIndex:index];
    
    if ([OLUserSession currentSession].userSelectedPhotos.count == 0){
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
    
    self.editingPrintPhoto = [OLUserSession currentSession].userSelectedPhotos[indexPath.item];
    
    OLImagePreviewViewController *previewVc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePreviewViewController"];
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:NULL completion:^(UIImage *image){
        previewVc.image = image;
    }];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    OLImageEditViewController *cropVc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteBundle]] instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        cropVc.modalPresentationStyle = [OLKiteUtils kiteVcForViewController:self].modalPresentationStyle;
        [self presentViewController:cropVc animated:YES completion:NULL];
    }];
    
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
    
    NSInteger extraCopies = [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] extraCopies] + 1;
    [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] setExtraCopies:extraCopies];
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
    
    NSInteger extraCopies = [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] extraCopies];
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
        }
        return;
    }
    extraCopies--;
    
    [[OLUserSession currentSession].userSelectedPhotos[indexPath.item] setExtraCopies:extraCopies];
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
    
    UIView *printView = [(OLCircleMaskCollectionViewCell *)cell printContainerView];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    self.editingPrintPhoto = [OLUserSession currentSession].userSelectedPhotos[indexPath.item];
    
    [self.editingPrintPhoto imageWithSize:OLAssetMaximumSize applyEdits:NO progress:NULL completion:^(UIImage *image){
        
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 0;
            self.infoBanner.transform = CGAffineTransformMakeTranslation(0, -self.infoBanner.frame.origin.y);
        } completion:^(BOOL finished){
            [self.infoBanner removeFromSuperview];
        }];
        OLImageEditViewController *cropVc = [[UIStoryboard storyboardWithName:@"OLKiteStoryboard" bundle:[OLKiteUtils kiteBundle]] instantiateViewControllerWithIdentifier:@"OLScrollCropViewController"];
        cropVc.borderInsets = self.product.productTemplate.imageBorder;
        cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
        cropVc.delegate = self;
        cropVc.aspectRatio = [self productAspectRatio];
        
        cropVc.previewView = [printView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [printView.superview convertRect:printView.frame toView:nil];
        cropVc.previewSourceView = printView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [cropVc setFullImage:image];
        cropVc.edits = self.editingPrintPhoto.edits;
        [self presentViewController:cropVc animated:NO completion:NULL];
        
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
    [self.checkoutPhotos addObjectsFromArray:[OLUserSession currentSession].userSelectedPhotos];
    for (int i = 0; i < [OLUserSession currentSession].userSelectedPhotos.count; i++) {
        NSInteger numberOfCopies = [[OLUserSession currentSession].userSelectedPhotos[i] extraCopies];
        for (NSInteger j = 0; j < numberOfCopies; j++){
            [self.checkoutPhotos addObject:[OLUserSession currentSession].userSelectedPhotos[i]];
        }
    }
}

#pragma mark UICollectionView data source and delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [[OLUserSession currentSession].userSelectedPhotos count];
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
        
    [cell.activityView startAnimating];
    
    cell.imageView.userInteractionEnabled = YES;
    if (cell.imageView.gestureRecognizers.count == 0){
        [cell.imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonEnhanceClicked:)]];
    }
    
    UIButton *enhanceButton = (UIButton *)[cell.contentView viewWithTag:11];
    [enhanceButton addTarget:self action:@selector(onButtonEnhanceClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor2){
        [enhanceButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor2];
    }
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%ld", (long)[[OLUserSession currentSession].userSelectedPhotos[indexPath.item] extraCopies]+1]];
    if ([OLKiteABTesting sharedInstance].lightThemeColor3){
        [countLabel setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        [upButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        [downButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
    }
    
    OLAsset *printPhoto = (OLAsset*)[[OLUserSession currentSession].userSelectedPhotos objectAtIndex:indexPath.item];
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    cell.imageViewTopCon.constant = b.top * (cellSize.height - [self heightForButtons]);
    cell.imageViewRightCon.constant = b.right * cellSize.width;
    cell.imageViewBottomCon.constant = b.bottom * (cellSize.height - [self heightForButtons]);
    cell.imageViewLeftCon.constant = b.left * cellSize.width;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    [cell.imageView setAndFadeInImageWithOLAsset:printPhoto size:cell.imageView.frame.size applyEdits:YES placeholder:nil progress:^(float progress){
        [cell.imageView setProgress:progress];
    } completionHandler:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.activityView stopAnimating];
        });
    }];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUICircle){
        cell.enableMask = YES;
        [cell setNeedsDisplay];
    }
    
    cell.printContainerView.backgroundColor = printPhoto.edits.borderColor ? printPhoto.edits.borderColor : [UIColor whiteColor];
    
    return cell;
}

- (CGFloat)heightForButtons{
    return 51;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    CGFloat margin = [self collectionView:collectionView layout:collectionView.collectionViewLayout minimumInteritemSpacingForSectionAtIndex:indexPath.section];
    
    UIEdgeInsets sectionInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    CGFloat width = self.view.frame.size.width;
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && self.view.frame.size.height > self.view.frame.size.width){
        width = self.view.frame.size.width;
    }
    else{
        width = MIN(width, 340);
    }
    width -= sectionInsets.left + sectionInsets.right;
    width -= (NSInteger)((self.view.frame.size.width / width)-1) * margin;
    
    CGFloat height = (width * (1.0 - b.left - b.right)) * [self productAspectRatio];
    height = height / (1 - b.top - b.bottom);
    height += [self heightForButtons];
    
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
    
    NSInteger numberOfCellsPerRow = collectionView.frame.size.width / cellSize.width;
    CGFloat margin = MAX((collectionView.frame.size.width - (cellSize.width * numberOfCellsPerRow))/(numberOfCellsPerRow+1), 5);
    
    return UIEdgeInsetsMake(10, margin, 0, margin);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 20;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 35;
}

#pragma mark - OLImageEditorViewControllerDelegate methods

- (void)scrollCropViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }];
}

- (void)scrollCropViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [UIView animateWithDuration:0.25 animations:^{
        self.nextButton.alpha = 1;
        self.navigationController.navigationBar.alpha = 1;
    }];
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)scrollCropViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    self.editingPrintPhoto.edits = cropper.edits;
    
    [self.collectionView reloadData];
    
    //Find the new previewSourceView for the dismiss animation
    for (NSInteger i = 0; i < [OLUserSession currentSession].userSelectedPhotos.count; i++){
        if ([OLUserSession currentSession].userSelectedPhotos[i] == self.editingPrintPhoto){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            if (indexPath){
                OLCircleMaskCollectionViewCell *cell = (OLCircleMaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                if (!cell){
                    continue;
                }
                UIView *containerView = cell.printContainerView;
                containerView.hidden = YES;
                cropper.previewSourceView = containerView;
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

- (void)scrollCropViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.editingPrintPhoto];
    [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
    self.editingPrintPhoto = asset;
}

@end
