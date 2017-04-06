//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
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

#import "NSObject+Utils.h"
#import "OLAnalytics.h"
#import "OLAsset+Private.h"
#import "OLCheckoutDelegate.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLConstants.h"
#import "OLImagePickerViewController.h"
#import "OLImagePreviewViewController.h"
#import "OLInfoBanner.h"
#import "OLIntegratedCheckoutViewController.h"
#import "OLKiteABTesting.h"
#import "OLKitePrintSDK.h"
#import "OLKiteUtils.h"
#import "OLKiteViewController.h"
#import "OLPackProductViewController.h"
#import "OLPaymentViewController.h"
#import "OLProduct.h"
#import "OLProductPrintJob.h"
#import "OLProductTemplate.h"
#import "OLRemoteImageView.h"
#import "OLUserSession.h"
#import "UIImageView+FadeIn.h"
#import "UIViewController+OLMethods.h"
#import "OLKiteViewController+Private.h"
#import "UIView+RoundRect.h"

@interface OLPaymentViewController (Private)

-(void)saveAndDismissReviewController;

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

@interface OLPackProductViewController () <OLCheckoutDelegate, UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate, OLImagePickerViewControllerDelegate, OLInfoBannerDelegate>

@property (weak, nonatomic) OLAsset *editingAsset;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) OLInfoBanner *infoBanner;

@end

@implementation OLPackProductViewController

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
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)] && self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
        [self registerForPreviewingWithDelegate:self sourceView:self.collectionView];
    }
    [self addInfoBanner];
}

- (void)addInfoBanner{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Change", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    else{
        self.infoBanner = [OLInfoBanner showInfoBannerOnViewController:self withTitle:NSLocalizedStringFromTableInBundle(@"Tap Image to Edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"")];
    }
    self.infoBanner.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 50, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (void)infoBannerWillDismiss{
    self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top - self.infoBanner.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
}

- (void)setupCtaButton{
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton setTitle:NSLocalizedStringFromTableInBundle(@"Add to Basket", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onButtonNextClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor1){
        [self.nextButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor1];
    }
    else{
        [self.nextButton setBackgroundColor:[UIColor colorWithRed:0.125 green:0.498 blue:0.655 alpha:1.000]];
    }
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.frame = CGRectMake(5, self.view.frame.size.height - 55 - ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height), self.view.frame.size.width-10, 50);
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeHeavyFont1WithSize:17];
    if (!font){
        font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    }
    if (font){
        [self.nextButton.titleLabel setFont:font];
    }
    else{
        [self.nextButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    
    NSNumber *cornerRadius = [OLKiteABTesting sharedInstance].lightThemeButtonRoundCorners;
    if (cornerRadius){
        [self.nextButton makeRoundRectWithRadius:[cornerRadius floatValue]];
    }
    
    [self.collectionView addSubview:self.nextButton];
    
    if ([OLKiteABTesting sharedInstance].launchedWithPrintOrder){
        if ([[OLKiteABTesting sharedInstance].launchWithPrintOrderVariant isEqualToString:@"Review-Overview-Checkout"]){
            [self.nextButton setTitle:NSLocalizedStringFromTableInBundle(@"Next", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
        }
        
        if(!self.editingPrintJob){
            self.editingPrintJob = [[OLUserSession currentSession].printOrder.jobs firstObject];
            self.product.uuid = self.editingPrintJob.uuid;
        }
    }
    
    if ([self.presentingViewController respondsToSelector:@selector(viewControllers)]) {
        UIViewController *paymentVc = [(UINavigationController *)self.presentingViewController viewControllers].lastObject;
        if ([paymentVc respondsToSelector:@selector(saveAndDismissReviewController)]){
            [self.nextButton setTitle:NSLocalizedStringFromTableInBundle(@"Save", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") forState:UIControlStateNormal];
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
        self.title = NSLocalizedStringFromTableInBundle(@"Review", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Title of a screen where the user can review the product before ordering");
    }
}

-(BOOL) shouldGoToCheckout{
    NSUInteger selectedCount = [OLUserSession currentSession].userSelectedPhotos.count + [self totalNumberOfExtras];
    NSUInteger numOrders = 1 + (MAX(0, selectedCount - 1) / self.product.quantityToFulfillOrder);
    NSUInteger quantityToFulfilOrder = numOrders * self.product.quantityToFulfillOrder;
    if (selectedCount < quantityToFulfilOrder) {
        NSUInteger canSelectExtraCount = quantityToFulfilOrder - selectedCount;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You've selected %d photos.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") ,selectedCount] message:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You can add %d more for the same price.", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @""), canSelectExtraCount] preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Print these", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self doCheckout];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Add more", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Add more [photos]") style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:ac animated:YES completion:NULL];
        return NO;
    }
    return YES;
}

- (void)saveJobWithCompletionHandler:(void(^)())handler{
    [self preparePhotosForCheckout];
    
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
    
    OLProductPrintJob *job;
    if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
        job = [OLPrintJob postcardWithTemplateId:self.product.templateId frontImageOLAsset:photoAssets.firstObject backImageOLAsset:photoAssets.lastObject];
    }
    else{
        job = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    }
    NSArray *jobs = [NSArray arrayWithArray:printOrder.jobs];
    for (id<OLPrintJob> existingJob in jobs){
        if ([existingJob.uuid isEqualToString:self.product.uuid]){
            job.dateAddedToBasket = [existingJob dateAddedToBasket];
            job.extraCopies = existingJob.extraCopies;
            job.uuid = self.product.uuid;
            [printOrder removePrintJob:existingJob];
        }
    }
    [job.acceptedOffers addObjectsFromArray:self.product.acceptedOffers.allObjects];
    [job.declinedOffers addObjectsFromArray:self.product.declinedOffers.allObjects];
    job.redeemedOffer = self.product.redeemedOffer;
    self.product.uuid = job.uuid;
    self.editingPrintJob = job;
    [printOrder addPrintJob:self.editingPrintJob];
    
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
        [vc safePerformSelector:@selector(setProduct:) withObject:self.product];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else{
        [OLKiteUtils checkoutViewControllerForPrintOrder:printOrder handler:^(id vc){
            [vc safePerformSelector:@selector(setUserEmail:) withObject:[OLKiteUtils userEmail:self]];
            [vc safePerformSelector:@selector(setUserPhone:) withObject:[OLKiteUtils userPhone:self]];
            
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
    else if (CGSizeEqualToSize(self.product.productTemplate.sizeCm, CGSizeZero)){
        return 1;
    }
    else{
        return self.product.productTemplate.sizeCm.height / self.product.productTemplate.sizeCm.width;
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location{
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        return nil;
    }
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    OLCircleMaskCollectionViewCell *cell = (OLCircleMaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.imageView.image){
        return nil;
    }
    
    [previewingContext setSourceRect:[cell convertRect:cell.imageView.frame toView:self.collectionView]];
    
    self.editingAsset = [OLUserSession currentSession].userSelectedPhotos[indexPath.item];
    
    OLImagePreviewViewController *previewVc = [[OLImagePreviewViewController alloc] init];
    __weak OLImagePreviewViewController *weakVc = previewVc;
    [previewVc.imageView setAndFadeInImageWithOLAsset:self.editingAsset size:self.view.frame.size applyEdits:YES placeholder:nil progress:^(float progress){
        [weakVc.imageView setProgress:progress];
    }completionHandler:NULL];
    previewVc.providesPresentationContextTransitionStyle = true;
    previewVc.definesPresentationContext = true;
    previewVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return previewVc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == OLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    cropVc.product = self.product;
    
    [self.editingAsset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:^(float progress){
        [cropVc.cropView setProgress:progress];
    }completion:^(UIImage *image, NSError *error){
        [cropVc setFullImage:image];
        cropVc.edits = self.editingAsset.edits;
        cropVc.modalPresentationStyle = [OLUserSession currentSession].kiteVc.modalPresentationStyle;
        [self presentViewController:cropVc animated:NO completion:NULL];
    }];
    
#ifndef OL_NO_ANALYTICS
    [OLAnalytics trackEditPhotoTappedForProductName:self.product.productTemplate.name];
#endif
}

- (void)setupBottomBorderTextFieldOnView:(OLCircleMaskCollectionViewCell *)cell{
    CGFloat heightFactor = cell.imageView.frame.size.height / 212.0;
    UITextField *tf = [[UITextField alloc] init];
    tf.userInteractionEnabled = NO;
    tf.textAlignment = NSTextAlignmentCenter;
    tf.adjustsFontSizeToFitWidth = YES;
    tf.minimumFontSize = 1;
    tf.font = [UIFont fontWithName:@"HelveticaNeue" size:35 * heightFactor];
    tf.textColor = [UIColor blackColor];
    tf.tag = 1556;
    
    [cell.imageView.superview addSubview:tf];
    
    UIView *imageView = cell.imageView;
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(tf, imageView);
    NSMutableArray *con = [[NSMutableArray alloc] init];
    
    NSArray *visuals = @[@"H:|-5-[tf]-5-|",
                         [NSString stringWithFormat:@"V:[imageView]-%f-[tf(%f)]", 8.0 * heightFactor, 40.0 * heightFactor]];
    
    
    for (NSString *visual in visuals) {
        [con addObjectsFromArray: [NSLayoutConstraint constraintsWithVisualFormat:visual options:0 metrics:nil views:views]];
    }
    
    [tf.superview addConstraints:con];
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
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTableInBundle(@"Remove?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Remove [photo]?") message:NSLocalizedStringFromTableInBundle(@"Do you want to remove this photo?", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"") preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"Yes, remove it", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Yes, remove [the photo]") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
            [self deletePhotoAtIndex:indexPath.item];
        }]];
        [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTableInBundle(@"No, keep it", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"No, keep [the photo]") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}]];
        [self presentViewController:ac animated:YES completion:NULL];
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

- (void)replacePhoto:(id)sender{
    OLImagePickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OLImagePickerViewController"];
    vc.delegate = self;
    vc.selectedAssets = [[NSMutableArray alloc] init];
    vc.maximumPhotos = 1;
    vc.product = self.product;
    [self presentViewController:[[OLNavigationController alloc] initWithRootViewController:vc] animated:YES completion:NULL];
}

- (void)editPhoto:(id)sender {
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
    
    self.editingAsset = [OLUserSession currentSession].userSelectedPhotos[indexPath.item];
    
    if ([OLUserSession currentSession].kiteVc.disableEditingTools){
        [self replacePhoto:sender];
        return;
    }
    
    [self.editingAsset imageWithSize:[UIScreen mainScreen].bounds.size applyEdits:NO progress:NULL completion:^(UIImage *image, NSError *error){
        
        OLImageEditViewController *cropVc = [[OLImageEditViewController alloc] init];
        cropVc.borderInsets = self.product.productTemplate.imageBorder;
        cropVc.enableCircleMask = self.product.productTemplate.templateUI == OLTemplateUICircle;
        cropVc.delegate = self;
        cropVc.aspectRatio = [self productAspectRatio];
        cropVc.product = self.product;
        
        cropVc.previewView = [printView snapshotViewAfterScreenUpdates:YES];
        cropVc.previewView.frame = [printView.superview convertRect:printView.frame toView:nil];
        cropVc.previewSourceView = printView;
        cropVc.providesPresentationContextTransitionStyle = true;
        cropVc.definesPresentationContext = true;
        cropVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [cropVc setFullImage:image];
        cropVc.edits = self.editingAsset.edits;
        [self presentViewController:cropVc animated:NO completion:NULL];
        
        [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
            self.nextButton.alpha = 0;
            self.infoBanner.transform = CGAffineTransformMakeTranslation(0, -self.infoBanner.frame.origin.y);
            self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top - self.infoBanner.frame.size.height, self.collectionView.contentInset.left, self.collectionView.contentInset.bottom, self.collectionView.contentInset.right);
        } completion:^(BOOL finished){
            [self.infoBanner removeFromSuperview];
            self.infoBanner = nil;
        }];
        
#ifndef OL_NO_ANALYTICS
        [OLAnalytics trackEditPhotoTappedForProductName:self.product.productTemplate.name];
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
    [self editPhoto:sender];
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
    OLCircleMaskCollectionViewCell *cell;
    if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"doubleSidedCell" forIndexPath:indexPath];
        UILabel *label = (UILabel *)[cell viewWithTag:10];
        label.text = indexPath.item == 0 ? NSLocalizedStringFromTableInBundle(@"FRONT", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Front of the photo") : NSLocalizedStringFromTableInBundle(@"BACK", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Back of the photo");
        
    }
    else{
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"reviewPhotoCell" forIndexPath:indexPath];
    }
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
        [cell.imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editPhoto:)]];
    }
    
    UIButton *editButton = (UIButton *)[cell.contentView viewWithTag:11];
    [editButton addTarget:self action:@selector(editPhoto:) forControlEvents:UIControlEventTouchUpInside];
    if ([OLKiteABTesting sharedInstance].lightThemeColor2){
        [editButton setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor2];
    }
    [editButton setTitle:NSLocalizedStringFromTableInBundle(@"Edit", @"KitePrintSDK", [OLKiteUtils kiteLocalizationBundle], @"Edit image") forState:UIControlStateNormal];
    UIFont *font = [[OLKiteABTesting sharedInstance] lightThemeFont1WithSize:17];
    if (font){
        [editButton.titleLabel setFont:font];
    }
    
    UIButton *upButton = (UIButton *)[cell.contentView viewWithTag:12];
    [upButton addTarget:self action:@selector(onButtonUpArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *downButton = (UIButton *)[cell.contentView viewWithTag:13];
    [downButton addTarget:self action:@selector(onButtonDownArrowClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:30];
    [countLabel setText: [NSString stringWithFormat:@"%ld", (long)[[OLUserSession currentSession].userSelectedPhotos[indexPath.item] extraCopies]+1]];
    if ([OLKiteABTesting sharedInstance].lightThemeColor3){
        [upButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
        [downButton setTintColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
    }
    if ([OLKiteABTesting sharedInstance].lightThemeColorReviewCounter){
        [countLabel setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColorReviewCounter];
    }
    else if ([OLKiteABTesting sharedInstance].lightThemeColor3){
        [countLabel setBackgroundColor:[OLKiteABTesting sharedInstance].lightThemeColor3];
    }
    
    OLAsset *asset = (OLAsset*)[[OLUserSession currentSession].userSelectedPhotos objectAtIndex:indexPath.item];
    CGSize cellSize = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    
    UIEdgeInsets b = self.product.productTemplate.imageBorder;
    
    cell.imageViewTopCon.constant = b.top * (cellSize.height - [self heightForButtons]);
    cell.imageViewRightCon.constant = b.right * cellSize.width;
    cell.imageViewBottomCon.constant = b.bottom * (cellSize.height - [self heightForButtons]);
    cell.imageViewLeftCon.constant = b.left * cellSize.width;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    [cell.imageView setAndFadeInImageWithOLAsset:asset size:cell.imageView.frame.size applyEdits:YES placeholder:nil progress:^(float progress){
        [cell.imageView setProgress:progress];
    } completionHandler:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.activityView stopAnimating];
        });
    }];
    
    if (self.product.productTemplate.templateUI == OLTemplateUICircle){
        cell.enableMask = YES;
        [cell setNeedsDisplay];
    }
    
    cell.printContainerView.backgroundColor = asset.edits.borderColor ? asset.edits.borderColor : [UIColor whiteColor];
    
    [[cell.imageView.superview viewWithTag:1556] removeFromSuperview];
    if (asset.edits.bottomBorderText.text){
        [self setupBottomBorderTextFieldOnView:cell];
        [(UITextView *)[cell.imageView.superview viewWithTag:1556] setText:asset.edits.bottomBorderText.text];
    }
    
    return cell;
}

- (CGFloat)heightForButtons{
    if (self.product.productTemplate.templateUI == OLTemplateUIDoubleSided){
        return 30;
    }
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
    
    return UIEdgeInsetsMake(10, margin, 10, margin);
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

- (void)imageEditViewControllerDidCancel:(OLImageEditViewController *)cropper{
    [self.editingAsset unloadImage];
    [cropper dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.25 animations:^{
            self.nextButton.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }];
}

- (void)imageEditViewControllerDidDropChanges:(OLImageEditViewController *)cropper{
    [self.editingAsset unloadImage];
    [UIView animateWithDuration:0.25 animations:^{
        self.nextButton.alpha = 1;
        self.navigationController.navigationBar.alpha = 1;
    }];
    [cropper dismissViewControllerAnimated:NO completion:NULL];
}

-(void)imageEditViewController:(OLImageEditViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingAsset unloadImage];
    self.editingAsset.edits = cropper.edits;
    
    //Find the new previewSourceView for the dismiss animation
    for (NSInteger i = 0; i < [OLUserSession currentSession].userSelectedPhotos.count; i++){
        if ([OLUserSession currentSession].userSelectedPhotos[i] == self.editingAsset){
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            if (indexPath){
                [UIView animateWithDuration:0 animations:^{
                    [self.collectionView performBatchUpdates:^{
                        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    } completion:nil];
                }];
                OLCircleMaskCollectionViewCell *cell = (OLCircleMaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                if (!cell){
                    continue;
                }
                cropper.previewSourceView = cell.printContainerView;
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
    [OLAnalytics trackEditScreenFinishedEditingPhotoForProductName:self.product.productTemplate.name];
#endif
}

- (void)imageEditViewController:(OLImageEditViewController *)cropper didReplaceAssetWithAsset:(OLAsset *)asset{
    NSUInteger index = [[OLUserSession currentSession].userSelectedPhotos indexOfObjectIdenticalTo:self.editingAsset];
    [[OLUserSession currentSession].userSelectedPhotos replaceObjectAtIndex:index withObject:asset];
    self.editingAsset = asset;
}

#pragma mark Image Picker Delegate

- (void)imagePickerDidCancel:(OLImagePickerViewController *)vc{
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePicker:(OLImagePickerViewController *)vc didFinishPickingAssets:(NSMutableArray *)assets added:(NSArray<OLAsset *> *)addedAssets removed:(NSArray *)removedAssets{
    OLAsset *asset = addedAssets.lastObject;
    if (asset){
        [self imageEditViewController:nil didReplaceAssetWithAsset:asset];
        
        //Find the new previewSourceView for the dismiss animation
        for (NSInteger i = 0; i < [OLUserSession currentSession].userSelectedPhotos.count; i++){
            if ([OLUserSession currentSession].userSelectedPhotos[i] == self.editingAsset){
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                if (indexPath){
                    [UIView animateWithDuration:0 animations:^{
                        [self.collectionView performBatchUpdates:^{
                            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                        } completion:nil];
                    }];
                    OLCircleMaskCollectionViewCell *cell = (OLCircleMaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    if (!cell){
                        continue;
                    }
                }
            }
        }
    }
    
    [vc dismissViewControllerAnimated:YES completion:NULL];
}

@end
