//
//  OrderReviewViewController.m
//  Kite Print SDK
//
//  Created by Kostas Karayannis on 17/07/2014.
//  Copyright (c) 2014 Ocean Labs. All rights reserved.
//

#import "OLOrderReviewViewController.h"
#import "OLPrintPhoto.h"
#import "OLAsset.h"
#import "OLCheckoutViewController.h"
#import "OLProductPrintJob.h"
#import "OLConstants.h"
#import "OLCheckoutDelegate.h"
#import "OLProductTemplate.h"
#import "OLProduct.h"
#import "OLCircleMaskCollectionViewCell.h"
#import "OLAsset+Private.h"
#import "OLAnalytics.h"
#import "OLKitePrintSDK.h"
#import <CTAssetsPickerController.h>
#import "UIViewController+TraitCollectionCompatibility.h"
#import "OLIntegratedCheckoutViewController.h"

static const NSUInteger kTagAlertViewSelectMorePhotos = 99;
static const NSUInteger kTagAlertViewDeletePhoto = 98;

@interface OLKitePrintSDK (InternalUtils)
+ (NSString *)userEmail:(UIViewController *)topVC;
+ (NSString *)userPhone:(UIViewController *)topVC;
+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC;
+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler;
@end

@interface OLOrderReviewViewController () <OLCheckoutDelegate, UIAlertViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) OLPrintPhoto *editingPrintPhoto;
@property (strong, nonatomic) UIView *addMorePhotosView;
@property (strong, nonatomic) UIButton *addMorePhotosButton;
@property (assign, nonatomic) NSUInteger indexOfPhotoToDelete;

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
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil
                                                                            action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Confirm", @"") style:UIBarButtonItemStylePlain target:self action:@selector(onButtonNextClicked:)];
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
    }completion:^(id<UIViewControllerTransitionCoordinator> context){
    }];
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
        self.title = [NSString stringWithFormat:@"%lu", (unsigned long) (self.userSelectedPhotos.count + [self totalNumberOfExtras])];
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

- (void)doCheckout {
    [self preparePhotosForCheckout];
    
    NSUInteger iphonePhotoCount = 0;
    for (OLPrintPhoto *photo in self.checkoutPhotos) {
        if (photo.type == kPrintPhotoAssetTypeALAsset) ++iphonePhotoCount;
    }
    
    // Avoid uploading assets if possible. We can avoid uploading where the image already exists at a remote
    // URL and the user did not manipulate it in any way.
    NSMutableArray *photoAssets = [[NSMutableArray alloc] init];
    for (OLPrintPhoto *photo in self.checkoutPhotos) {
        [photoAssets addObject:[OLAsset assetWithDataSource:photo]];
    }
    
    // ensure order is maxed out by adding duplicates as necessary
    NSUInteger userSelectedAssetCount = photoAssets.count;
    NSUInteger numOrders = (NSUInteger) floor(userSelectedAssetCount + self.product.quantityToFulfillOrder - 1) / self.product.quantityToFulfillOrder;
    NSUInteger duplicatesToFillOrder = numOrders * self.product.quantityToFulfillOrder - userSelectedAssetCount;
    for (NSUInteger i = 0; i < duplicatesToFillOrder; ++i) {
        [photoAssets addObject:photoAssets[i % userSelectedAssetCount]];
    }
    NSLog(@"Adding %lu duplicates", (unsigned long)duplicatesToFillOrder);
        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    OLPrintOrder *printOrder = [[OLPrintOrder alloc] init];
    printOrder.userData = @{@"photo_count_iphone": [NSNumber numberWithUnsignedInteger:iphonePhotoCount],
                            @"sdk_version": kOLKiteSDKVersion,
                            @"platform": @"iOS",
                            @"uid": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                            @"app_version": [NSString stringWithFormat:@"Version: %@ (%@)", appVersion, buildNumber]
                            };
    OLProductPrintJob* printJob = [[OLProductPrintJob alloc] initWithTemplateId:self.product.templateId OLAssets:photoAssets];
    for (id<OLPrintJob> job in printOrder.jobs){
        [printOrder removePrintJob:job];
    }
    [printOrder addPrintJob:printJob];

    
    [OLKitePrintSDK checkoutViewControllerForPrintOrder:printOrder handler:^(OLCheckoutViewController *vc){
        vc.userEmail = [OLKitePrintSDK userEmail:self];
        vc.userPhone = [OLKitePrintSDK userPhone:self];
        vc.kiteDelegate = [OLKitePrintSDK kiteDelegate:self];
        
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

- (OLKiteViewController *)kiteViewController {
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isMemberOfClass:[OLKiteViewController class]]) {
            return (OLKiteViewController *) vc;
        }
    }
    
    return nil;
}

- (void)onUserSelectedPhotoCountChange {
    [self updateTitleBasedOnSelectedPhotoQuanitity];
}

- (void) deletePhotoAtIndex:(NSUInteger)index{
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
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete?", @"") message:NSLocalizedString(@"Do you want to delete this photo?", @"") preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes, delete it", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self deletePhotoAtIndex:indexPath.item];
            }]];
            [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No, keep it", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}]];
            [self presentViewController:ac animated:YES completion:NULL];
        }
        else{
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete?", @"") message:NSLocalizedString(@"Do you want to delete this photo?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Yes, delete it", @"") otherButtonTitles:NSLocalizedString(@"No, keep it", @""), nil];
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
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)cell];
    
    self.editingPrintPhoto = self.userSelectedPhotos[indexPath.item];
    
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"CropViewNavigationController"];
    OLScrollCropViewController *cropVc = (id)nav.topViewController;
    cropVc.enableCircleMask = self.product.productTemplate.templateUI == kOLTemplateUICircle;
    cropVc.delegate = self;
    cropVc.aspectRatio = [self productAspectRatio];
    [self.editingPrintPhoto getImageWithProgress:NULL completion:^(UIImage *image){
        [cropVc setFullImage:image];
        [self presentViewController:nav animated:YES completion:NULL];
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView * cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"reviewHeaderCell" forIndexPath:indexPath];
    return cell;
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
    
    UIImageView *cellImage = [[UIImageView alloc] initWithFrame:borderView.frame];
    cellImage.tag = 10;
    cellImage.translatesAutoresizingMaskIntoConstraints = NO;
    cellImage.contentMode = UIViewContentModeScaleAspectFill;
    cellImage.clipsToBounds = YES;
    [cell.contentView insertSubview:cellImage aboveSubview:activityIndicator];
    
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
    [printPhoto setImageSize:cellImage.frame.size cropped:YES completionHandler:^(UIImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            cellImage.image = image;
        });
    }];
    
    if (self.product.productTemplate.templateUI == kOLTemplateUICircle){
        cell.enableMask = YES;
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
    return 20.0;
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
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)scrollCropViewController:(OLScrollCropViewController *)cropper didFinishCroppingImage:(UIImage *)croppedImage{
    [self.editingPrintPhoto unloadImage];
    
    self.editingPrintPhoto.cropImageFrame = [cropper.cropView getFrameRect];
    self.editingPrintPhoto.cropImageRect = [cropper.cropView getImageRect];
    self.editingPrintPhoto.cropImageSize = [cropper.cropView croppedImageSize];
    
    [self.collectionView reloadData];
    [cropper dismissViewControllerAnimated:YES completion:NULL];
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

- (NSUInteger)supportedInterfaceOrientations {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        return UIInterfaceOrientationMaskAll;
    }
    else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
